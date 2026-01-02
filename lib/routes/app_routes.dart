// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter/material.dart';

import '../features/auth/home_decider_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/role_select_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/delivery/delivery_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/admin/role_gate_screen.dart';
import '../features/orders/models/order.dart';
import '../features/orders/order_tracking_screen.dart';
import '../features/orders/payment_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/recursive/recursive_orders_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/customer_home_screen.dart';
import '../features/home/vendor_home_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const home = '/home';
  static const customerHome = '/home/customer';
  static const vendorHome = '/home/vendor';
  static const cart = '/cart';
  static const orders = '/orders';
  static const inventory = '/inventory';
  static const delivery = '/delivery';
  static const profile = '/profile';
  static const login = '/login';
  static const otp = '/otp';
  static const roleSelect = '/role-select';
  static const recursive = '/recursive';
  static const payment = '/payment';
  static const admin = '/admin';

  static final routes = <String, WidgetBuilder>{
    splash: (context) => SplashScreen(
      onComplete: () => Navigator.pushReplacementNamed(context, home),
    ),
    home: (context) => const HomeDeciderScreen(),
    customerHome: (context) => const CustomerHomeScreen(),
    vendorHome: (context) => const VendorHomeScreen(),
    cart: (context) => const CartScreen(),
    orders: (context) => const OrderTrackingScreen(),
    inventory: (context) => const InventoryScreen(),
    delivery: (context) => const DeliveryScreen(),
    profile: (context) => const ProfileScreen(),
    login: (context) => const LoginScreen(),
    otp: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as OtpScreenArgs?;
      return OtpScreen(args: args);
    },
    roleSelect: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as RoleSelectArgs?;
      return RoleSelectScreen(args: args);
    },
    recursive: (context) => const RecursiveOrdersScreen(),
    admin: (context) => const RoleGateScreen(),
    payment: (context) {
      final order = ModalRoute.of(context)?.settings.arguments as Order?;
      return PaymentScreen(order: order);
    },
  };
}
