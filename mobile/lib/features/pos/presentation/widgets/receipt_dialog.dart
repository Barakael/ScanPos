import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../sales/domain/entities/sale_entity.dart';
import '../../../shops/domain/entities/shop_entity.dart';
import '../../domain/tra_receipt_defaults.dart';
import 'tra_receipt_formatter.dart';

class _C {
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1E3A5F);
  static const primaryLt = Color(0xFF2B527A);
  static const accent = Color(0xFF00C896);
  static const ink = Color(0xFF1A2332);
  static const inkMid = Color(0xFF64748B);
  static const border = Color(0xFFE8EDF5);

  static Color primaryOp(double o) => primary.withOpacity(o);
  static Color accentOp(double o) => accent.withOpacity(o);
  static Color whiteOp(double o) => Colors.white.withOpacity(o);
}

TextStyle _ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _C.ink,
  double? height,
}) =>
    TextStyle(
        fontSize: size, fontWeight: weight, color: color, height: height);

Future<Uint8List> _buildReceiptPdf(SaleEntity sale, ShopEntity shop) async {
  final doc = pw.Document();
  const pageFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 4 * PdfPageFormat.mm,
  );

  final lines = TraReceiptFormatter.buildLines(sale: sale, shop: shop);

  pw.MemoryImage? logo;
  try {
    final data = await rootBundle.load('assets/images/logo/logo.png');
    logo = pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {}

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null) ...[
              pw.Image(logo, width: 100),
              pw.SizedBox(height: 8),
            ],
            ...lines.map(
              (l) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    l,
                    style: pw.TextStyle(
                      fontSize: 7,
                      font: pw.Font.courier(),
                      lineSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

class ReceiptDialog extends StatefulWidget {
  const ReceiptDialog({
    super.key,
    required this.sale,
    this.shop,
    required this.onClose,
  });

  final SaleEntity sale;
  final ShopEntity? shop;
  final VoidCallback onClose;

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  static const String _printerMacKey = 'selected_printer_mac';
  bool _isPrinting = false;
  bool _isConnectingPrinter = false;
  String? _connectedPrinterName;

  ShopEntity get _effectiveShop =>
      widget.shop ?? TraReceiptDefaults.demoShop;

  String get _formattedDate =>
      DateFormat('MMM dd, yyyy  HH:mm').format(widget.sale.createdAt);

  String _payLabel(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'mobile':
        return 'Mobile Money';
      default:
        return method ?? '—';
    }
  }

  IconData _payIcon(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'mobile':
        return Icons.smartphone_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Future<void> _connectPrinter() async {
    if (_isConnectingPrinter || _isPrinting) return;
    setState(() => _isConnectingPrinter = true);
    try {
      final hasPermission =
          await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (!hasPermission) {
        _showError(
            'Bluetooth permission denied. Allow permissions and retry.');
        return;
      }

      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) {
        _showError('Bluetooth is off. Turn it on, then connect printer.');
        return;
      }

      final pairedDevices = await PrintBluetoothThermal.pairedBluetooths;
      if (pairedDevices.isEmpty) {
        _showError(
            'No paired printers found. Pair printer in device settings first.');
        return;
      }

      if (!mounted) return;
      final selected = await showModalBottomSheet<BluetoothInfo>(
        context: context,
        backgroundColor: _C.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pairedDevices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final device = pairedDevices[index];
                return ListTile(
                  leading: const Icon(Icons.print_rounded, color: _C.primary),
                  title: Text(
                      device.name.isEmpty ? 'Unknown Printer' : device.name),
                  subtitle: Text(device.macAdress),
                  onTap: () => Navigator.of(ctx).pop(device),
                );
              },
            ),
          );
        },
      );

      if (selected == null) return;
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: selected.macAdress,
      );
      if (!connected) {
        _showError('Failed to connect to ${selected.name}.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_printerMacKey, selected.macAdress);
      if (!mounted) return;
      setState(() {
        _connectedPrinterName =
            selected.name.isEmpty ? 'Bluetooth Printer' : selected.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer connected successfully.')),
      );
    } catch (e) {
      _showError('Printer connection failed: $e');
    } finally {
      if (mounted) setState(() => _isConnectingPrinter = false);
    }
  }

  Future<bool> _ensurePrinterConnected() async {
    try {
      final isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) return true;

      final prefs = await SharedPreferences.getInstance();
      final savedMac = prefs.getString(_printerMacKey);
      if (savedMac == null || savedMac.isEmpty) return false;

      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: savedMac,
      ).timeout(const Duration(seconds: 10));
      if (!connected) return false;

      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      debugPrint('Bluetooth reconnect error: $e');
      return false;
    }
  }

  Future<List<int>> _buildThermalTicketBytes() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];
    bytes.addAll(generator.reset());

    try {
      final data = await rootBundle.load('assets/images/logo/logo.png');
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded != null) {
        bytes.addAll(generator.image(decoded, align: PosAlign.center));
        bytes.addAll(generator.feed(1));
      }
    } catch (_) {}

    final lines = TraReceiptFormatter.buildLines(
      sale: widget.sale,
      shop: _effectiveShop,
    );
    for (final line in lines) {
      bytes.addAll(generator.text(
        line,
        styles: const PosStyles(align: PosAlign.left),
      ));
    }
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  Future<void> _printSunmiTra() async {
    try {
      final data = await rootBundle.load('assets/images/logo/logo.png');
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded != null) {
        final png = Uint8List.fromList(img.encodePng(decoded));
        await SunmiPrinter.printImage(png, align: SunmiPrintAlign.CENTER);
        await SunmiPrinter.lineWrap(1);
      }
    } catch (_) {}

    final lines = TraReceiptFormatter.buildLines(
      sale: widget.sale,
      shop: _effectiveShop,
    );
    for (final line in lines) {
      await SunmiPrinter.printText('$line\n');
    }
    await SunmiPrinter.lineWrap(2);
    await SunmiPrinter.cutPaper();
  }

  Future<void> _printReceipt() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    HapticFeedback.mediumImpact();

    try {
      try {
        await SunmiPrinter.bindingPrinter();
        await _printSunmiTra();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt printed')),
          );
        }
        return;
      } catch (e) {
        debugPrint('Sunmi print skipped: $e');
      }

      final btOk = await _ensurePrinterConnected();
      if (btOk) {
        final ticket = await _buildThermalTicketBytes();
        final ok = await PrintBluetoothThermal.writeBytes(ticket);
        if (!ok) {
          _showError('Failed to print on Bluetooth printer.');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt printed')),
          );
        }
        return;
      }

      final pdfBytes =
          await _buildReceiptPdf(widget.sale, _effectiveShop);
      final name = widget.sale.serialNumber.isNotEmpty
          ? widget.sale.serialNumber
          : widget.sale.id;
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Receipt_$name',
      );
    } catch (e) {
      _showError('Print failed: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    HapticFeedback.lightImpact();

    try {
      final pdfBytes =
          await _buildReceiptPdf(widget.sale, _effectiveShop);
      final name = widget.sale.serialNumber.isNotEmpty
          ? widget.sale.serialNumber
          : widget.sale.id;
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Receipt_$name.pdf',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  double get _displayExcl => widget.sale.totalExclTax > 0
      ? widget.sale.totalExclTax
      : (widget.sale.total / 1.18);

  double get _displayTax => widget.sale.totalTax > 0
      ? widget.sale.totalTax
      : (widget.sale.total - _displayExcl);

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
              _Header(
                sale: widget.sale,
                formattedDate: _formattedDate,
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        _effectiveShop.name,
                        style: _ts(14, weight: FontWeight.w700),
                      ),
                      Text(
                        '${_effectiveShop.address}\n${_effectiveShop.location} · TIN ${_effectiveShop.tin}',
                        style: _ts(11, color: _C.inkMid),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                          label: 'Items (${widget.sale.items.length})'),
                      const SizedBox(height: 10),
                      ...widget.sale.items.map((item) => _ItemRow(item: item)),
                      const SizedBox(height: 16),
                      const _HRule(),
                      const SizedBox(height: 14),
                      _SummaryLine(
                          'Total excl. tax',
                          CurrencyFormatter.formatTraDecimal(_displayExcl)),
                      const SizedBox(height: 6),
                      _SummaryLine(
                          'Total tax',
                          CurrencyFormatter.formatTraDecimal(_displayTax)),
                      const SizedBox(height: 10),
                      _TotalLine(total: widget.sale.total),
                      const SizedBox(height: 14),
                      _PaymentMethodRow(
                        label: _payLabel(widget.sale.paymentMethod),
                        icon: _payIcon(widget.sale.paymentMethod),
                      ),
                      const SizedBox(height: 16),
                      const _HRule(),
                      const SizedBox(height: 12),
                      Text(
                        'Verification: ${widget.sale.verificationCode.isEmpty ? '—' : widget.sale.verificationCode}',
                        style: _ts(11, color: _C.inkMid),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TRA: 0800750294 / 0800750750',
                        style: _ts(11, color: _C.primary, weight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _ActionBar(
                isPrinting: _isPrinting,
                isConnectingPrinter: _isConnectingPrinter,
                connectedPrinterName: _connectedPrinterName,
                onConnectPrinter: _connectPrinter,
                onPrint: _printReceipt,
                onShare: _sharePdf,
                onClose: widget.onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sale, required this.formattedDate});
  final SaleEntity sale;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final receiptLabel = sale.serialNumber.isNotEmpty
        ? sale.serialNumber
        : 'Receipt #${sale.id}';

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
          Text(receiptLabel, style: _ts(12, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(formattedDate, style: _ts(11, color: Colors.white54)),
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
                  '${item.quantity} × ${CurrencyFormatter.formatTraDecimal(item.unitPrice)}',
                  style: _ts(11, color: _C.inkMid),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.formatTraDecimal(item.subtotal),
            style: _ts(13, weight: FontWeight.w700, color: _C.primary),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.amountText);
  final String label;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _ts(13, color: _C.inkMid)),
        Text(amountText, style: _ts(13, weight: FontWeight.w600)),
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
          Text('Total (incl. tax)', style: _ts(15, weight: FontWeight.w700)),
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
  const _PaymentMethodRow({required this.label, required this.icon});
  final String label;
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

class _HRule extends StatelessWidget {
  const _HRule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _C.border);
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isPrinting,
    required this.isConnectingPrinter,
    required this.connectedPrinterName,
    required this.onConnectPrinter,
    required this.onPrint,
    required this.onShare,
    required this.onClose,
  });
  final bool isPrinting;
  final bool isConnectingPrinter;
  final String? connectedPrinterName;
  final VoidCallback onConnectPrinter;
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
          if (connectedPrinterName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_connected_rounded,
                      size: 16, color: _C.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Connected: $connectedPrinterName',
                      style: _ts(12, color: _C.inkMid, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (isPrinting || isConnectingPrinter)
                  ? null
                  : onConnectPrinter,
              icon: isConnectingPrinter
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _C.inkMid),
                    )
                  : const Icon(Icons.bluetooth_searching_rounded, size: 16),
              label: Text(
                  isConnectingPrinter ? 'Connecting…' : 'Connect Printer'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: _C.inkMid,
                side: const BorderSide(color: _C.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                  icon: const Icon(Icons.share_rounded, size: 16),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.point_of_sale_rounded, size: 16),
              label: const Text('New Sale'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
