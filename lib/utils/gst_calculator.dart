import '../models/invoice_item.dart';

class GstCalculationResult {
  final double subtotal;
  final double loadingCharges;
  final double transportCharges;
  final double taxableBase;
  final double gstRate;
  final bool isIntraState; // true if CGST+SGST, false if IGST
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double totalTax;
  final double discountAmount;
  final double grandTotalBeforeRound;
  final double roundOff;
  final double grandTotal;

  GstCalculationResult({
    required this.subtotal,
    required this.loadingCharges,
    required this.transportCharges,
    required this.taxableBase,
    required this.gstRate,
    required this.isIntraState,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.igstTotal,
    required this.totalTax,
    required this.discountAmount,
    required this.grandTotalBeforeRound,
    required this.roundOff,
    required this.grandTotal,
  });
}

class GstCalculator {
  static GstCalculationResult calculateInvoiceTotals({
    required List<InvoiceItem> items,
    required String? companyStateCode,
    required String? customerStateCode,
    double loadingCharges = 0.0,
    double transportCharges = 0.0,
    double gstRate = 18.0,
    double discountAmount = 0.0,
  }) {
    // 1. Calculate Subtotal from Line Items
    double subtotal = 0.0;
    for (var item in items) {
      subtotal += item.amount;
    }

    // 2. Add Loading + Transport Charges to get Taxable Base
    double taxableBase = subtotal + loadingCharges + transportCharges;

    // 3. Determine Tax Type (Intra-state CGST+SGST vs Inter-state IGST)
    bool isIntraState = true;
    if (companyStateCode != null &&
        customerStateCode != null &&
        companyStateCode.trim().isNotEmpty &&
        customerStateCode.trim().isNotEmpty) {
      isIntraState = companyStateCode.trim() == customerStateCode.trim();
    }

    double cgstTotal = 0.0;
    double sgstTotal = 0.0;
    double igstTotal = 0.0;
    double totalTax = 0.0;

    if (gstRate > 0 && taxableBase > 0) {
      if (isIntraState) {
        final halfRate = gstRate / 2.0;
        cgstTotal = (taxableBase * halfRate) / 100.0;
        sgstTotal = (taxableBase * halfRate) / 100.0;
        totalTax = cgstTotal + sgstTotal;
      } else {
        igstTotal = (taxableBase * gstRate) / 100.0;
        totalTax = igstTotal;
      }
    }

    // 4. Grand Total before Round Off
    double grandTotalBeforeRound = taxableBase + totalTax - discountAmount;
    if (grandTotalBeforeRound < 0) grandTotalBeforeRound = 0.0;

    // 5. Round Off calculation
    double roundedGrandTotal = grandTotalBeforeRound.roundToDouble();
    double roundOff = roundedGrandTotal - grandTotalBeforeRound;

    return GstCalculationResult(
      subtotal: subtotal,
      loadingCharges: loadingCharges,
      transportCharges: transportCharges,
      taxableBase: taxableBase,
      gstRate: gstRate,
      isIntraState: isIntraState,
      cgstTotal: cgstTotal,
      sgstTotal: sgstTotal,
      igstTotal: igstTotal,
      totalTax: totalTax,
      discountAmount: discountAmount,
      grandTotalBeforeRound: grandTotalBeforeRound,
      roundOff: roundOff,
      grandTotal: roundedGrandTotal,
    );
  }
}
