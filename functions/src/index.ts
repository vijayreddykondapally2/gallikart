import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const opsTopic = 'ops-orders';

const sendNotification = async (
  token: string | undefined,
  payload: { title: string; body: string; data?: Record<string, string> },
) => {
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
    });
  } catch (error) {
    console.error('FCM send failed', error);
  }
};

const sendOpsBroadcast = async (payload: { title: string; body: string; data?: Record<string, string> }) => {
  try {
    await messaging.send({
      topic: opsTopic,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
    });
  } catch (error) {
    console.error('FCM ops topic send failed', error);
  }
};

const buildOpsOrderFromInstant = (snap: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>) => {
  const data = snap.data() ?? {};
  const status = (data.orderStatus as string) || (data.status as string) || 'PLACED';
  return {
    orderId: snap.id,
    sourceRef: snap.ref.path,
    userId: data.userId as string | undefined,
    orderType: 'INSTANT',
    mode: null,
    status,
    amount: (data.totalAmount as number) ?? 0,
    address: (data.deliveryAddress as string) ?? data.deliveryLabel,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    items: data.items ?? [],
    deliveryDate: data.deliveryDate as string | undefined,
  };
};

const buildOpsOrderFromRecurring = (snap: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>) => {
  const data = snap.data() ?? {};
  const amount =
    (data.currentAmount as number) ??
    (data.basePaidAmount as number) ??
    (data.paidAmount as number) ??
    0;
  const status = (data.status as string) ?? 'ACTIVE';
  return {
    orderId: snap.id,
    sourceRef: snap.ref.path,
    userId: data.userId as string | undefined,
    orderType: 'RECURRING',
    mode: (data.frequency as string | undefined)?.toUpperCase() ?? null,
    status,
    amount,
    address: (data.deliveryAddress as string) ?? data.deliveryAddressId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    items: data.items ?? {},
    nextDeliveryDate: data.next_delivery_date ?? data.nextDeliveryDate,
  };
};

export const syncVendorOrder = functions.firestore
  .document('vendors/{vendorId}/orders/{orderId}')
  .onWrite(async (change, context) => {
    const { vendorId, orderId } = context.params;
    const after = change.after;
    if (!after.exists) {
      return null;
    }
    const data = after.data();
    if (!data) {
      return null;
    }
    const customerId = data.customerId as string | undefined;
    const vendorRef = db.collection('vendors').doc(vendorId);
    const vendorSnap = await vendorRef.get();
    const vendorToken = vendorSnap.data()?.fcmToken as string | undefined;
    const payload = {
      ...data,
      vendorId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (customerId) {
      const userOrderRef = db
        .collection('users')
        .doc(customerId)
        .collection('orders')
        .doc(orderId);
      await userOrderRef.set(payload, { merge: true });
    }

    const previousStatus = change.before.exists ? change.before.data()?.status : null;
    const currentStatus = data.status as string | undefined;

    if (!change.before.exists && vendorToken) {
      await sendNotification(vendorToken, {
        title: `New order #${orderId}`,
        body: `Order received from ${data.customerName ?? 'a customer'}`,
        data: { orderId, type: 'NEW_ORDER' },
      });
    }

    if (
      customerId &&
      currentStatus &&
      currentStatus !== previousStatus
    ) {
      const customerDoc = await db.collection('users').doc(customerId).get();
      const customerToken = customerDoc.data()?.fcmToken as string | undefined;
      await sendNotification(customerToken, {
        title: `Order ${orderId} is ${currentStatus}`,
        body: `Vendor ${vendorSnap.data()?.name ?? 'has'} marked it ${currentStatus.toLowerCase()}`,
        data: { orderId, status: currentStatus, type: 'ORDER_STATUS' },
      });
    }

    return null;
  });

export const lowStockAlert = functions.firestore
  .document('vendors/{vendorId}/inventory/{productId}')
  .onUpdate(async (change, context) => {
    const { vendorId, productId } = context.params;
    const before = change.before.data();
    const after = change.after.data();
    if (!after) return null;
    const newQty = (after.stockQty as number | undefined) ?? 0;
    const threshold = (after.lowStockThreshold as number | undefined) ?? 0;
    const prevQty = (before?.stockQty as number | undefined) ?? 0;

    if (threshold <= 0) return null;
    if (newQty >= threshold) return null;
    if (prevQty < threshold) return null;

    const vendorDoc = await db.collection('vendors').doc(vendorId).get();
    const token = vendorDoc.data()?.fcmToken as string | undefined;
    const itemName = after.name as string | undefined;
    await sendNotification(token, {
      title: `${itemName ?? 'Item'} is running low`,
      body: `Stock is ${newQty.toFixed(1)} and below your threshold of ${threshold.toFixed(1)}`,
      data: { productId, type: 'LOW_STOCK' },
    });
    return null;
  });

export const mirrorInstantOrderToOps = functions.firestore
  .document('users/{userId}/orders/{orderId}')
  .onCreate(async (snap, context) => {
    const opsPayload = buildOpsOrderFromInstant(snap);
    const opsRef = db.collection('opsOrders').doc(context.params.orderId);
    await opsRef.set(opsPayload, { merge: true });
    await sendOpsBroadcast({
      title: 'New order received',
      body: `Order #${context.params.orderId} placed`,
      data: { orderId: context.params.orderId, type: 'OPS_NEW_ORDER' },
    });
    return null;
  });

export const mirrorInstantOrderStatus = functions.firestore
  .document('users/{userId}/orders/{orderId}')
  .onUpdate(async (change, context) => {
    const beforeStatus = (change.before.data()?.orderStatus as string) ?? change.before.data()?.status;
    const afterStatus = (change.after.data()?.orderStatus as string) ?? change.after.data()?.status;
    if (beforeStatus === afterStatus) return null;
    const opsRef = db.collection('opsOrders').doc(context.params.orderId);
    await opsRef.set(
      {
        status: afterStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await sendOpsBroadcast({
      title: `Order #${context.params.orderId} → ${afterStatus}`,
      body: 'Status changed',
      data: { orderId: context.params.orderId, status: afterStatus, type: 'OPS_STATUS' },
    });
    return null;
  });

export const mirrorRecurringToOps = functions.firestore
  .document('recursiveOrders/{recurringId}')
  .onCreate(async (snap, context) => {
    const opsPayload = buildOpsOrderFromRecurring(snap);
    const opsRef = db.collection('opsOrders').doc(context.params.recurringId);
    await opsRef.set(opsPayload, { merge: true });
    await sendOpsBroadcast({
      title: 'New recurring order',
      body: `Recurring ${opsPayload.mode ?? ''} order #${context.params.recurringId}`.trim(),
      data: { orderId: context.params.recurringId, type: 'OPS_NEW_RECURRING' },
    });
    return null;
  });

export const mirrorRecurringStatus = functions.firestore
  .document('recursiveOrders/{recurringId}')
  .onUpdate(async (change, context) => {
    const beforeStatus = change.before.data()?.status as string | undefined;
    const afterStatus = change.after.data()?.status as string | undefined;
    if (!afterStatus || beforeStatus === afterStatus) return null;
    const opsRef = db.collection('opsOrders').doc(context.params.recurringId);
    await opsRef.set(
      {
        status: afterStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await sendOpsBroadcast({
      title: `Recurring order #${context.params.recurringId} → ${afterStatus}`,
      body: 'Status changed',
      data: { orderId: context.params.recurringId, status: afterStatus, type: 'OPS_STATUS' },
    });
    return null;
  });

export const propagateOpsStatus = functions.firestore
  .document('opsOrders/{opsId}')
  .onUpdate(async (change, context) => {
    const beforeStatus = change.before.data()?.status as string | undefined;
    const afterStatus = change.after.data()?.status as string | undefined;
    if (!afterStatus || beforeStatus === afterStatus) return null;
    const sourceRefPath = change.after.data()?.sourceRef as string | undefined;
    if (sourceRefPath) {
      const sourceRef = db.doc(sourceRefPath);
      await sourceRef.set(
        {
          status: afterStatus,
          orderStatus: afterStatus,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          ...(['CONFIRMED', 'PACKING', 'OUT_FOR_DELIVERY', 'NEAR_YOU', 'DELIVERED'].includes(afterStatus)
            ? { [`${afterStatus.toLowerCase()}At`]: admin.firestore.FieldValue.serverTimestamp() }
            : {}),
        },
        { merge: true },
      );
    }
    await sendOpsBroadcast({
      title: `Order #${context.params.opsId} → ${afterStatus}`,
      body: 'Status updated by ops',
      data: { orderId: context.params.opsId, status: afterStatus, type: 'OPS_STATUS' },
    });
    return null;
  });
