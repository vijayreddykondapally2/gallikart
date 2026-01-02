import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

void routeUser(BuildContext context, String role) {
  final normalized = role.toLowerCase();
  if (normalized == 'vendor') {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.vendorHome,
      (route) => false,
    );
    return;
  }
  Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.customerHome,
    (route) => false,
  );
}
