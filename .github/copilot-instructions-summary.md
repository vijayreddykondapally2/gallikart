# GalliKart - Copilot Instructions (Summarized & Rewritten)

## Project Overview
Build GalliKart, a quick-commerce Flutter app for outskirts delivery. Supports two order methods: in-app shopping and WhatsApp orders. Keep it simple, reliable, and beginner-friendly.

## UI Flow (Like BigBasket/Zepto)
- Home: Product list with images, names, prices, "+" buttons.
- Add to cart → Bottom basket bar appears with item count and total.
- View Cart → Cart screen with items and "Place Order".
- Place Order → Order tracking screen showing "Delivery Started".

## Key Components

### Product Model
```dart
class Product {
  final String id, name, imageUrl;
  final double price;
  // Constructor...
}
```

### Sample Products
- Tata Salt 1kg: ₹28
- Aashirvaad Atta 5kg: ₹260
- Etc.

### Product List UI
Vertical ListView with Card, Image, Text, ElevatedButton("+").

### Cart Controller
Manages items, quantities, total price. Uses ChangeNotifier.

### Bottom Basket Bar
Shows when cart has items: "X items | ₹Y" + "View Cart" button.

### Cart Screen
ListView of cart items + "Place Order" button.

### Order Tracking Screen
Simple screen with delivery icon and "Delivery Started" text.

## Technical Requirements
- Flutter app with Firebase (Firestore, Auth).
- Two order methods: App (normal) and WhatsApp (opens chat with pre-filled message).
- Data: Products (id, name, image, price), Cart (in-memory), Orders (status: Placed/Started/Delivered).
- Simple state management (no Bloc/Redux).
- No payments, maps, AI, multi-warehouse, login initially.

## Simplified Copilot Instructions
**Goal:** Build simple quick-commerce app with app and WhatsApp ordering.

**App Flow:**
1. Product list screen with + buttons.
2. Bottom basket bar on add.
3. Cart screen.
4. Order status screen.
5. WhatsApp button to open chat.

**Rules:**
- Simple Flutter code.
- Ask: "Is this the simplest way?" If no, simplify.

**Don't Build:** Payments, maps, AI, complex features.