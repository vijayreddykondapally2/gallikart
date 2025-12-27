// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

String formatCurrency(double value) {
  return '₹${value.toStringAsFixed(2)}';
}
