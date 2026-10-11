import '../models/receipt_data.dart';

enum ValidationSeverity { warning, error }

class ReceiptValidationIssue {
  final ValidationSeverity severity;
  final String message;

  const ReceiptValidationIssue({required this.severity, required this.message});
}

/// Flags inconsistencies in a parsed receipt WITHOUT ever changing any
/// value — it only reports what looks wrong so the user can review and
/// correct it. Never auto-corrects a nominal to match a total.
class ReceiptValidationService {
  static List<ReceiptValidationIssue> validate(ReceiptData data) {
    final issues = <ReceiptValidationIssue>[];

    if (data.totalAmount == null || data.totalAmount! <= 0) {
      issues.add(
        const ReceiptValidationIssue(
          severity: ValidationSeverity.warning,
          message: 'Total transaksi tidak terdeteksi, periksa manual.',
        ),
      );
    } else if (data.totalAmount! < 0) {
      issues.add(
        const ReceiptValidationIssue(
          severity: ValidationSeverity.error,
          message: 'Total transaksi bernilai negatif.',
        ),
      );
    }

    if (data.hasConflictingTotals) {
      issues.add(
        const ReceiptValidationIssue(
          severity: ValidationSeverity.warning,
          message:
              'Ditemukan lebih dari satu nominal total berbeda pada struk, pastikan nominal yang benar.',
        ),
      );
    }

    if (data.date == null) {
      issues.add(
        const ReceiptValidationIssue(
          severity: ValidationSeverity.warning,
          message: 'Tanggal tidak terdeteksi dari struk, periksa manual.',
        ),
      );
    }

    if (data.subtotalAmount != null &&
        data.totalAmount != null &&
        !data.isMathConsistent) {
      issues.add(
        const ReceiptValidationIssue(
          severity: ValidationSeverity.warning,
          message:
              'Perhitungan subtotal, diskon, dan pajak tidak cocok dengan total — periksa nominal manual.',
        ),
      );
    }

    for (final item in data.items) {
      if (item.name.trim().isEmpty) {
        issues.add(
          const ReceiptValidationIssue(
            severity: ValidationSeverity.error,
            message: 'Ada item tanpa nama.',
          ),
        );
      }
      if (item.totalPrice <= 0) {
        issues.add(
          ReceiptValidationIssue(
            severity: ValidationSeverity.error,
            message: 'Item "${item.name}" memiliki nominal tidak valid.',
          ),
        );
      }
      if (data.totalAmount != null && item.totalPrice > data.totalAmount!) {
        issues.add(
          ReceiptValidationIssue(
            severity: ValidationSeverity.warning,
            message:
                'Item "${item.name}" lebih besar dari total transaksi, periksa ulang.',
          ),
        );
      }
    }

    for (final discount in data.discounts) {
      if (discount.amount < 0) {
        issues.add(
          ReceiptValidationIssue(
            severity: ValidationSeverity.error,
            message: 'Diskon "${discount.name}" bernilai negatif.',
          ),
        );
      }
    }

    for (final tax in data.taxes) {
      if (tax.amount < 0) {
        issues.add(
          ReceiptValidationIssue(
            severity: ValidationSeverity.error,
            message: 'Pajak/biaya "${tax.name}" bernilai negatif.',
          ),
        );
      }
    }

    if (data.confidenceScore < 0.5) {
      issues.add(
        const ReceiptValidationIssue(
          severity: ValidationSeverity.warning,
          message:
              'Hasil ekstraksi kurang yakin, periksa seluruh data sebelum disimpan.',
        ),
      );
    }

    return issues;
  }
}
