import '../models/payment_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final Map<String, PaymentModel> _payments = {};

  PaymentModel getOrCreate(String bookingId, double amount) {
    return _payments.putIfAbsent(
      bookingId,
      () => PaymentModel(bookingId: bookingId, amount: amount),
    );
  }

  PaymentModel? get(String bookingId) => _payments[bookingId];

  String? markPaid(String bookingId) {
    final p = _payments[bookingId];
    if (p == null) return 'Payment record not found.';
    if (p.status == PaymentStatus.paid) return 'Already marked as paid.';
    if (p.status == PaymentStatus.refunded) {
      return 'Cannot mark a refunded payment as paid.';
    }
    p.status = PaymentStatus.paid;
    p.paidAt = DateTime.now();
    return null;
  }

  String? markRefunded(String bookingId) {
    final p = _payments[bookingId];
    if (p == null) return 'Payment record not found.';
    if (p.status == PaymentStatus.refunded) return 'Already refunded.';
    if (p.status == PaymentStatus.pending) {
      return 'Cannot refund a payment that has not been paid.';
    }
    p.status = PaymentStatus.refunded;
    p.refundedAt = DateTime.now();
    return null;
  }

  String? resetToPending(String bookingId) {
    final p = _payments[bookingId];
    if (p == null) return 'Payment record not found.';
    p.status = PaymentStatus.pending;
    p.paidAt = null;
    p.refundedAt = null;
    return null;
  }

  void seedPayments(List<PaymentModel> payments) {
    for (final p in payments) {
      _payments.putIfAbsent(p.bookingId, () => p);
    }
  }
}
