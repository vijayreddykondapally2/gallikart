"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.propagateOpsStatus = exports.mirrorRecurringStatus = exports.mirrorRecurringToOps = exports.mirrorInstantOrderStatus = exports.mirrorInstantOrderToOps = exports.lowStockAlert = exports.syncVendorOrder = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const opsTopic = 'ops-orders';
const sendNotification = async (token, payload) => {
    if (!token)
        return;
    try {
        await messaging.send({
            token,
            notification: {
                title: payload.title,
                body: payload.body,
            },
            data: payload.data,
        });
    }
    catch (error) {
        console.error('FCM send failed', error);
    }
};
const sendOpsBroadcast = async (payload) => {
    try {
        await messaging.send({
            topic: opsTopic,
            notification: { title: payload.title, body: payload.body },
            data: payload.data,
        });
    }
    catch (error) {
        console.error('FCM ops topic send failed', error);
    }
};
const buildOpsOrderFromInstant = (snap) => {
    const data = snap.data() ?? {};
    const status = data.orderStatus || data.status || 'PLACED';
    return {
        orderId: snap.id,
        sourceRef: snap.ref.path,
        userId: data.userId,
        orderType: 'INSTANT',
        mode: null,
        status,
        amount: data.totalAmount ?? 0,
        address: data.deliveryAddress ?? data.deliveryLabel,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        items: data.items ?? [],
        deliveryDate: data.deliveryDate,
    };
};
const buildOpsOrderFromRecurring = (snap) => {
    const data = snap.data() ?? {};
    const amount = data.currentAmount ??
        data.basePaidAmount ??
        data.paidAmount ??
        0;
    const status = data.status ?? 'ACTIVE';
    return {
        orderId: snap.id,
        sourceRef: snap.ref.path,
        userId: data.userId,
        orderType: 'RECURRING',
        mode: data.frequency?.toUpperCase() ?? null,
        status,
        amount,
        address: data.deliveryAddress ?? data.deliveryAddressId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        items: data.items ?? {},
        nextDeliveryDate: data.next_delivery_date ?? data.nextDeliveryDate,
    };
};
exports.syncVendorOrder = functions.firestore
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
    const customerId = data.customerId;
    const vendorRef = db.collection('vendors').doc(vendorId);
    const vendorSnap = await vendorRef.get();
    const vendorToken = vendorSnap.data()?.fcmToken;
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
    const currentStatus = data.status;
    if (!change.before.exists && vendorToken) {
        await sendNotification(vendorToken, {
            title: `New order #${orderId}`,
            body: `Order received from ${data.customerName ?? 'a customer'}`,
            data: { orderId, type: 'NEW_ORDER' },
        });
    }
    if (customerId &&
        currentStatus &&
        currentStatus !== previousStatus) {
        const customerDoc = await db.collection('users').doc(customerId).get();
        const customerToken = customerDoc.data()?.fcmToken;
        await sendNotification(customerToken, {
            title: `Order ${orderId} is ${currentStatus}`,
            body: `Vendor ${vendorSnap.data()?.name ?? 'has'} marked it ${currentStatus.toLowerCase()}`,
            data: { orderId, status: currentStatus, type: 'ORDER_STATUS' },
        });
    }
    return null;
});
exports.lowStockAlert = functions.firestore
    .document('vendors/{vendorId}/inventory/{productId}')
    .onUpdate(async (change, context) => {
    const { vendorId, productId } = context.params;
    const before = change.before.data();
    const after = change.after.data();
    if (!after)
        return null;
    const newQty = after.stockQty ?? 0;
    const threshold = after.lowStockThreshold ?? 0;
    const prevQty = before?.stockQty ?? 0;
    if (threshold <= 0)
        return null;
    if (newQty >= threshold)
        return null;
    if (prevQty < threshold)
        return null;
    const vendorDoc = await db.collection('vendors').doc(vendorId).get();
    const token = vendorDoc.data()?.fcmToken;
    const itemName = after.name;
    await sendNotification(token, {
        title: `${itemName ?? 'Item'} is running low`,
        body: `Stock is ${newQty.toFixed(1)} and below your threshold of ${threshold.toFixed(1)}`,
        data: { productId, type: 'LOW_STOCK' },
    });
    return null;
});
exports.mirrorInstantOrderToOps = functions.firestore
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
exports.mirrorInstantOrderStatus = functions.firestore
    .document('users/{userId}/orders/{orderId}')
    .onUpdate(async (change, context) => {
    const beforeStatus = change.before.data()?.orderStatus ?? change.before.data()?.status;
    const afterStatus = change.after.data()?.orderStatus ?? change.after.data()?.status;
    if (beforeStatus === afterStatus)
        return null;
    const opsRef = db.collection('opsOrders').doc(context.params.orderId);
    await opsRef.set({
        status: afterStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await sendOpsBroadcast({
        title: `Order #${context.params.orderId} → ${afterStatus}`,
        body: 'Status changed',
        data: { orderId: context.params.orderId, status: afterStatus, type: 'OPS_STATUS' },
    });
    return null;
});
exports.mirrorRecurringToOps = functions.firestore
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
exports.mirrorRecurringStatus = functions.firestore
    .document('recursiveOrders/{recurringId}')
    .onUpdate(async (change, context) => {
    const beforeStatus = change.before.data()?.status;
    const afterStatus = change.after.data()?.status;
    if (!afterStatus || beforeStatus === afterStatus)
        return null;
    const opsRef = db.collection('opsOrders').doc(context.params.recurringId);
    await opsRef.set({
        status: afterStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await sendOpsBroadcast({
        title: `Recurring order #${context.params.recurringId} → ${afterStatus}`,
        body: 'Status changed',
        data: { orderId: context.params.recurringId, status: afterStatus, type: 'OPS_STATUS' },
    });
    return null;
});
exports.propagateOpsStatus = functions.firestore
    .document('opsOrders/{opsId}')
    .onUpdate(async (change, context) => {
    const beforeStatus = change.before.data()?.status;
    const afterStatus = change.after.data()?.status;
    if (!afterStatus || beforeStatus === afterStatus)
        return null;
    const sourceRefPath = change.after.data()?.sourceRef;
    if (sourceRefPath) {
        const sourceRef = db.doc(sourceRefPath);
        await sourceRef.set({
            status: afterStatus,
            orderStatus: afterStatus,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            ...(['CONFIRMED', 'PACKING', 'OUT_FOR_DELIVERY', 'NEAR_YOU', 'DELIVERED'].includes(afterStatus)
                ? { [`${afterStatus.toLowerCase()}At`]: admin.firestore.FieldValue.serverTimestamp() }
                : {}),
        }, { merge: true });
    }
    await sendOpsBroadcast({
        title: `Order #${context.params.opsId} → ${afterStatus}`,
        body: 'Status updated by ops',
        data: { orderId: context.params.opsId, status: afterStatus, type: 'OPS_STATUS' },
    });
    return null;
});
