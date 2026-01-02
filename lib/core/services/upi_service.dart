import 'package:upi_india/upi_india.dart' as upi;

enum UpiPaymentStatus { success, submitted, failure, cancelled }

class UpiTransactionResult {
  const UpiTransactionResult({
    required this.status,
    required this.rawResponse,
    this.transactionId,
  });

  final UpiPaymentStatus status;
  final String rawResponse;
  final String? transactionId;
}

class UpiService {
  static final _upi = upi.UpiIndia();

  static Future<List<upi.UpiApp>> getAvailableApps() async {
    final apps = await _upi.getAllUpiApps(mandatoryTransactionId: false);
    return apps;
  }

  static Future<UpiTransactionResult> startTransaction({
    required String receiverUpiId,
    required String receiverName,
    required double amount,
    required String transactionRefId,
    required String transactionNote,
    upi.UpiApp? app,
  }) async {
    final available = await getAvailableApps();
    final targetApp = app ?? (available.isNotEmpty ? available.first : null);
    if (targetApp == null) {
      return const UpiTransactionResult(
        status: UpiPaymentStatus.failure,
        rawResponse: 'No UPI apps available',
        transactionId: null,
      );
    }
    try {
      final response = await _upi.startTransaction(
      app: targetApp,
      receiverUpiId: receiverUpiId,
      receiverName: receiverName,
      transactionRefId: transactionRefId,
      transactionNote: transactionNote,
      amount: amount,
    );
      return UpiTransactionResult(
        status: _parseStatus(response.status),
        rawResponse: response.toString(),
        transactionId: response.transactionId,
      );
    } on upi.UpiIndiaUserCancelledException {
      return const UpiTransactionResult(
        status: UpiPaymentStatus.cancelled,
        rawResponse: 'User cancelled the payment',
        transactionId: null,
      );
    }
  }

  static UpiPaymentStatus _parseStatus(String? status) {
    final normalized = status?.toLowerCase();
    if (normalized == upi.UpiPaymentStatus.SUCCESS) {
      return UpiPaymentStatus.success;
    }
    if (normalized == upi.UpiPaymentStatus.SUBMITTED) {
      return UpiPaymentStatus.submitted;
    }
    if (normalized == upi.UpiPaymentStatus.FAILURE) {
      return UpiPaymentStatus.failure;
    }
    return UpiPaymentStatus.failure;
  }
}
