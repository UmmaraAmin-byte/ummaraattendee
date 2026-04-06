enum PaymentStatus { pending, paid, refunded }

class PaymentModel {
  final String bookingId;
  PaymentStatus status;
  final double amount;
  DateTime? paidAt;
  DateTime? refundedAt;

  PaymentModel({
    required this.bookingId,
    required this.amount,
    this.status = PaymentStatus.pending,
    this.paidAt,
    this.refundedAt,
  });

  String get statusLabel {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}
