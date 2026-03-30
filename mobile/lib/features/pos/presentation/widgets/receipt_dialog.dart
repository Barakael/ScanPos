import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../sales/domain/entities/sale_entity.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ════════════════════════════════════════════════════════════════════════════
class _C {
  static const bg        = Color(0xFFF5F6FA);
  static const white     = Color(0xFFFFFFFF);
  static const primary   = Color(0xFF1E3A5F);
  static const primaryLt = Color(0xFF2B527A);
  static const accent    = Color(0xFF00C896);
  static const ink       = Color(0xFF1A2332);
  static const inkMid    = Color(0xFF64748B);
  static const inkLight  = Color(0xFFCBD5E1);
  static const border    = Color(0xFFE8EDF5);

  static Color primaryOp(double o) => primary.withOpacity(o);
  static Color accentOp(double o)  => accent.withOpacity(o);
  static Color whiteOp(double o)   => Colors.white.withOpacity(o);
}

TextStyle _ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _C.ink,
  double? height,
}) =>
    TextStyle(
        fontSize: size, fontWeight: weight, color: color, height: height);

// ════════════════════════════════════════════════════════════════════════════
// PDF RECEIPT BUILDER
// Generates an 80 mm thermal-roll style receipt PDF.
// Uses the `pdf` package (pw.*) — distinct from Flutter widgets.
// ════════════════════════════════════════════════════════════════════════════
Future<Uint8List> _buildReceiptPdf(SaleEntity sale) async {
  final doc = pw.Document();

  // 80 mm wide thermal roll, infinite height (single-page receipt)
  const pageFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 6 * PdfPageFormat.mm,
  );

  // PDF-space colour constants (PdfColor, not Flutter Color)
  const pdfPrimary = PdfColors.indigo900;
  const pdfAccent  = PdfColor.fromInt(0xFF00C896);
  const pdfInkMid  = PdfColor.fromInt(0xFF64748B);
  const pdfBorder  = PdfColor.fromInt(0xFFE8EDF5);

  String payLabel(String? m) {
    switch ((m ?? '').toLowerCase()) {
      case 'cash':   return 'Cash';
      case 'card':   return 'Card';
      case 'mobile': return 'Mobile Money';
      default:       return m ?? '—';
    }
  }

  final dateStr =
      DateFormat('MMM dd, yyyy  HH:mm').format(sale.createdAt);

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Store header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'TERA POS',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: pdfPrimary,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Point of Sale',
                    style: pw.TextStyle(fontSize: 9, color: pdfInkMid),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),
            pw.Divider(color: pdfBorder, thickness: 0.5),
            pw.SizedBox(height: 6),

            // ── Receipt meta
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Receipt #${sale.id}',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(fontSize: 8, color: pdfInkMid),
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Divider(color: pdfBorder, thickness: 0.5),
            pw.SizedBox(height: 6),

            // ── Items column headers
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'ITEM',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: pdfInkMid),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  'QTY',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: pdfInkMid),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'AMOUNT',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: pdfInkMid),
                ),
              ],
            ),

            pw.SizedBox(height: 4),
            pw.Divider(color: pdfBorder, thickness: 0.3),

            // ── Items
            ...sale.items.map((item) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            item.productName,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          '${item.quantity}',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Text(
                      '@ ${CurrencyFormatter.format(item.unitPrice)} each',
                      style: pw.TextStyle(
                          fontSize: 7.5, color: pdfInkMid),
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 6),
            pw.Divider(color: pdfBorder, thickness: 0.5),
            pw.SizedBox(height: 6),

            // ── Subtotal / VAT
            _pdfRow('Subtotal', CurrencyFormatter.format(sale.subtotal),
                pdfInkMid),
            pw.SizedBox(height: 3),
            _pdfRow('VAT (18%)', CurrencyFormatter.format(sale.totalVat),
                pdfInkMid),
            pw.SizedBox(height: 6),

            // ── Total box
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              decoration: pw.BoxDecoration(
                color: pdfPrimary,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(sale.total),
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // ── Payment method pill
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdfBorder, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment',
                    style: pw.TextStyle(
                        fontSize: 9, color: pdfInkMid),
                  ),
                  pw.Text(
                    payLabel(sale.paymentMethod),
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: pdfAccent),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),
            pw.Divider(color: pdfBorder, thickness: 0.5),
            pw.SizedBox(height: 8),

            // ── Footer
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for your purchase!',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: pdfPrimary),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Powered by Tera POS',
                    style: pw.TextStyle(
                        fontSize: 8, color: pdfInkMid),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),
          ],
        );
      },
    ),
  );

  return doc.save();
}

// Helper for PDF summary rows
pw.Widget _pdfRow(String label, String value, PdfColor labelColor) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label,
          style: pw.TextStyle(fontSize: 9, color: labelColor)),
      pw.Text(value,
          style:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    ],
  );
}

// ════════════════════════════════════════════════════════════════════════════
// RECEIPT DIALOG  (StatefulWidget so we can track _isPrinting)
// ════════════════════════════════════════════════════════════════════════════
class ReceiptDialog extends StatefulWidget {
  const ReceiptDialog({
    super.key,
    required this.sale,
    required this.onClose,
  });

  final SaleEntity   sale;
  final VoidCallback onClose;

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  bool _isPrinting = false;

  String get _formattedDate =>
      DateFormat('MMM dd, yyyy  HH:mm').format(widget.sale.createdAt);

  String _payLabel(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':   return 'Cash';
      case 'card':   return 'Card';
      case 'mobile': return 'Mobile Money';
      default:       return method ?? '—';
    }
  }

  IconData _payIcon(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':   return Icons.payments_rounded;
      case 'card':   return Icons.credit_card_rounded;
      case 'mobile': return Icons.smartphone_rounded;
      default:       return Icons.payment_rounded;
    }
  }

  // ── Print via system dialog ────────────────────────────────────────────
  Future<void> _printReceipt() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    HapticFeedback.mediumImpact();

    try {
      final pdfBytes = await _buildReceiptPdf(widget.sale);
      // Opens Android print picker / iOS AirPrint / Windows/macOS print dialog
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Receipt_${widget.sale.id}',
      );
    } catch (e) {
      _showError('Print failed: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  // ── Share as PDF ───────────────────────────────────────────────────────
  Future<void> _sharePdf() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    HapticFeedback.lightImpact();

    try {
      final pdfBytes = await _buildReceiptPdf(widget.sale);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Receipt_${widget.sale.id}.pdf',
      );
    } catch (e) {
      _showError('Share failed: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4D4D),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
        child: Container(
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _C.primaryOp(0.18),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Fixed success header ──────────────────────────
              _Header(
                sale:          widget.sale,
                formattedDate: _formattedDate,
              ),

              // ── Scrollable receipt body ───────────────────────
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _SectionTitle(
                          label:
                              'Items (${widget.sale.items.length})'),
                      const SizedBox(height: 10),
                      ...widget.sale.items
                          .map((item) => _ItemRow(item: item)),
                      const SizedBox(height: 16),
                      const _HRule(),
                      const SizedBox(height: 14),
                      _SummaryLine('Subtotal', widget.sale.subtotal),
                      const SizedBox(height: 6),
                      _SummaryLine('VAT (18%)', widget.sale.totalVat),
                      const SizedBox(height: 10),
                      _TotalLine(total: widget.sale.total),
                      const SizedBox(height: 14),
                      _PaymentMethodRow(
                        label: _payLabel(widget.sale.paymentMethod),
                        icon:  _payIcon(widget.sale.paymentMethod),
                      ),
                      const SizedBox(height: 16),
                      const _HRule(),
                      const SizedBox(height: 16),
                      const _Footer(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Fixed action buttons ──────────────────────────
              _ActionBar(
                isPrinting: _isPrinting,
                onPrint:    _printReceipt,
                onShare:    _sharePdf,
                onClose:    widget.onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COMPOSABLE SUB-WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.sale, required this.formattedDate});
  final SaleEntity sale;
  final String     formattedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.primary, _C.primaryLt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _C.whiteOp(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 12),
          Text('Payment Successful',
              style:
                  _ts(18, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Receipt #${sale.id}',
              style: _ts(12, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(formattedDate,
              style: _ts(11, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: _ts(13, weight: FontWeight.w700, color: _C.inkMid),
      );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.primaryOp(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: _C.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item.productName as String?) ?? '—',
                  style: _ts(13, weight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                  style: _ts(11, color: _C.inkMid),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: _ts(13, weight: FontWeight.w700, color: _C.primary),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.amount);
  final String label;
  final num    amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _ts(13, color: _C.inkMid)),
        Text(CurrencyFormatter.format(amount),
            style: _ts(13, weight: FontWeight.w600)),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.total});
  final num total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.primaryOp(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryOp(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total', style: _ts(15, weight: FontWeight.w700)),
          Text(
            CurrencyFormatter.format(total),
            style: _ts(18, weight: FontWeight.w800, color: _C.primary),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow(
      {required this.label, required this.icon});
  final String   label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.accentOp(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.accentOp(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _C.accent, size: 18),
          const SizedBox(width: 10),
          Text('Paid via', style: _ts(12, color: _C.inkMid)),
          const Spacer(),
          Text(label,
              style:
                  _ts(13, weight: FontWeight.w700, color: _C.accent)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(
            28,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 1,
                color: _C.inkLight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Thank you for your purchase!',
          style: _ts(13, weight: FontWeight.w600, color: _C.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Powered by Tera POS',
          style: _ts(11, color: _C.inkMid),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HRule extends StatelessWidget {
  const _HRule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _C.border);
}

// ── Action bar with real Print + Share + New Sale ─────────────────────────
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isPrinting,
    required this.onPrint,
    required this.onShare,
    required this.onClose,
  });
  final bool         isPrinting;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(top: BorderSide(color: _C.border)),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Print + Share
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPrinting ? null : onPrint,
                  icon: isPrinting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _C.inkMid),
                        )
                      : const Icon(Icons.print_rounded, size: 16),
                  label: Text(isPrinting ? 'Printing…' : 'Print'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: _C.inkMid,
                    side: const BorderSide(color: _C.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPrinting ? null : onShare,
                  icon:
                      const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share PDF'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: _C.primary,
                    side: BorderSide(color: _C.primaryOp(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // New Sale
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.point_of_sale_rounded,
                  size: 16),
              label: const Text('New Sale'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}