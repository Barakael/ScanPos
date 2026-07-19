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
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../sales/domain/entities/sale_entity.dart';
import '../../../shops/domain/entities/shop_entity.dart';
import '../../domain/tra_receipt_defaults.dart';
import 'tra_receipt_formatter.dart';

const String _traLogoAsset = 'assets/images/logo/download.png';

class _C {
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1E3A5F);
  static const accent = Color(0xFF00C896);
  static const ink = Color(0xFF1A2332);
  static const inkMid = Color(0xFF64748B);
  static const border = Color(0xFFE8EDF5);

  static Color primaryOp(double o) =>
      primary.withValues(alpha: o);
}

TextStyle _ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _C.ink,
  double? height,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

String _dec(num v) => CurrencyFormatter.formatTraDecimal(v);

Future<Uint8List> _buildReceiptPdf(SaleEntity sale, ShopEntity shop) async {
  final doc = TraReceiptFormatter.buildDoc(
    sale: sale,
    shop: shop,
    width: TraReceiptWidth.mm58,
  );

  final font = pw.Font.courier();
  final fontBold = pw.Font.courierBold();

  pw.TextStyle ts({
    double size = 9.5,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.TextStyle(
        font: bold ? fontBold : font,
        fontSize: size,
        lineSpacing: 1.2,
      );

  Uint8List? logoBytes;
  try {
    logoBytes =
        (await rootBundle.load(_traLogoAsset)).buffer.asUint8List();
  } catch (_) {}

  pw.Widget divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                width: 0.6,
                style: pw.BorderStyle.dashed,
              ),
            ),
          ),
          height: 1,
        ),
      );

  pw.Widget kv(TraReceiptKv row) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                row.label.toUpperCase(),
                style: ts(size: row.emphasis ? 10.5 : 9.5),
              ),
            ),
            pw.Expanded(
              flex: 7,
              child: pw.Text(
                row.value,
                textAlign: pw.TextAlign.right,
                style: ts(
                  size: row.emphasis ? 11.5 : 9.5,
                  bold: row.emphasis,
                ),
              ),
            ),
          ],
        ),
      );

  final pdfDoc = pw.Document();

  pdfDoc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        58 * PdfPageFormat.mm,
        double.infinity,
        marginLeft: 2 * PdfPageFormat.mm,
        marginRight: 2 * PdfPageFormat.mm,
        marginTop: 2 * PdfPageFormat.mm,
        marginBottom: 2 * PdfPageFormat.mm,
      ),
      build: (ctx) {
        final children = <pw.Widget>[];

        if (logoBytes != null) {
          children.add(
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                width: 34,
              ),
            ),
          );
          children.add(pw.SizedBox(height: 6));
        }

        for (var i = 0; i < doc.headerCenter.length; i++) {
          final line = doc.headerCenter[i];
          final isCompany = i == 2;
          children.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Center(
                child: pw.Text(
                  line,
                  textAlign: pw.TextAlign.center,
                  style: ts(
                    size: isCompany ? 10.5 : 9.5,
                    bold: isCompany,
                  ),
                ),
              ),
            ),
          );
        }

        children.add(divider());
        for (final row in doc.identity) {
          children.add(kv(row));
        }
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
            child: pw.Center(
              child: pw.Text(
                doc.locationLine,
                style: ts(),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        );
        children.add(divider());

        for (final row in doc.buyer) {
          children.add(kv(row));
        }
        children.add(divider());

        final itemColWidths = {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(1.6),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.8),
        };
        children.add(
          pw.Table(
            columnWidths: itemColWidths,
            children: [
              pw.TableRow(
                children: [
                  pw.Text('QTY', style: ts(bold: true)),
                  pw.Text('AMOUNT',
                      style: ts(bold: true),
                      textAlign: pw.TextAlign.right),
                  pw.Text('XR',
                      style: ts(bold: true),
                      textAlign: pw.TextAlign.right),
                  pw.Text('AMOUNT TZS',
                      style: ts(bold: true),
                      textAlign: pw.TextAlign.right),
                ],
              ),
            ],
          ),
        );
        for (final it in doc.items) {
          children.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(it.description, style: ts(size: 8.8)),
            ),
          );
          children.add(
            pw.Table(
              columnWidths: itemColWidths,
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('${it.qty}', style: ts()),
                    pw.Text(
                      _dec(it.unitAmount),
                      style: ts(),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.Text(
                      it.xr,
                      style: ts(),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.Text(
                      _dec(it.amountTzs),
                      style: ts(),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        children.add(divider());
        for (final row in doc.totals) {
          children.add(kv(row));
        }
        children.add(divider());

        for (final row in doc.purpose) {
          children.add(kv(row));
        }
        children.add(divider());

        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('DATE ${doc.deviceDate}', style: ts()),
                pw.Text('TIME ${doc.deviceTime}', style: ts()),
              ],
            ),
          ),
        );
        for (final row in doc.device) {
          children.add(kv(row));
        }
        children.add(divider());

        children.add(
          pw.Center(
            child: pw.Text(
              'RECEIPT VERIFICATION CODE',
              style: ts(bold: true),
            ),
          ),
        );
        children.add(pw.SizedBox(height: 4));
        children.add(
          pw.Center(
            child: pw.Text(
              doc.verificationCode,
              style: ts(size: 11, bold: true),
            ),
          ),
        );
        children.add(pw.SizedBox(height: 8));
        children.add(
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: doc.qrData,
              width: 56,
              height: 56,
            ),
          ),
        );
        children.add(pw.SizedBox(height: 10));

        for (final f in doc.footerCenter) {
          children.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Center(
                child: pw.Text(
                  f,
                  textAlign: pw.TextAlign.center,
                  style: ts(size: 8.8),
                ),
              ),
            ),
          );
        }

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: children,
        );
      },
    ),
  );

  return pdfDoc.save();
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

  TraReceiptDoc get _doc => TraReceiptFormatter.buildDoc(
        sale: widget.sale,
        shop: _effectiveShop,
        width: TraReceiptWidth.mm58,
      );

  Future<Uint8List?> _loadTraLogoBytes() async {
    try {
      final data = await rootBundle.load(_traLogoAsset);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
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

  void _thermalHr(Generator g, List<int> bytes, int len) {
    bytes.addAll(g.hr(ch: '-', len: len));
  }

  void _thermalKv(Generator g, List<int> bytes, TraReceiptKv kv) {
    bytes.addAll(g.row([
      PosColumn(
        text: kv.label.toUpperCase(),
        width: 6,
      ),
      PosColumn(
        text: kv.value,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
  }

  Future<List<int>> _buildThermalTicketBytes() async {
    final doc = _doc;
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];
    bytes.addAll(generator.reset());

    final logoBytes = await _loadTraLogoBytes();
    if (logoBytes != null) {
      final decoded = img.decodeImage(logoBytes);
      if (decoded != null) {
        bytes.addAll(generator.image(decoded, align: PosAlign.center));
        bytes.addAll(generator.feed(1));
      }
    }

    final w = doc.charWidth;
    for (final line in doc.headerCenter) {
      bytes.addAll(generator.text(
        line,
        styles: PosStyles(
          align: PosAlign.center,
          bold: line == doc.headerCenter[2],
        ),
      ));
    }
    _thermalHr(generator, bytes, w);

    for (final kv in doc.identity) {
      _thermalKv(generator, bytes, kv);
    }
    bytes.addAll(generator.text(
      doc.locationLine,
      styles: const PosStyles(align: PosAlign.center),
    ));
    _thermalHr(generator, bytes, w);

    for (final kv in doc.buyer) {
      _thermalKv(generator, bytes, kv);
    }
    _thermalHr(generator, bytes, w);

    bytes.addAll(generator.row([
      PosColumn(text: 'QTY', width: 3),
      PosColumn(
          text: 'AMOUNT',
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: 'XR',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: 'TZS',
          width: 3,
          styles: const PosStyles(align: PosAlign.right)),
    ]));

    for (final it in doc.items) {
      bytes.addAll(generator.text(
        it.description,
        styles: const PosStyles(align: PosAlign.left),
      ));
      bytes.addAll(generator.row([
        PosColumn(text: '${it.qty}', width: 3),
        PosColumn(
            text: _dec(it.unitAmount),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: it.xr,
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: _dec(it.amountTzs),
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    _thermalHr(generator, bytes, w);

    for (final kv in doc.totals) {
      final styles = PosStyles(
        align: PosAlign.left,
        bold: kv.emphasis,
        height: kv.emphasis ? PosTextSize.size2 : PosTextSize.size1,
        width: kv.emphasis ? PosTextSize.size2 : PosTextSize.size1,
      );
      bytes.addAll(generator.row([
        PosColumn(
          text: kv.label.toUpperCase(),
          width: 6,
          styles: styles,
        ),
        PosColumn(
          text: kv.value,
          width: 6,
          styles: PosStyles(
            align: PosAlign.right,
            bold: kv.emphasis,
            height: kv.emphasis ? PosTextSize.size2 : PosTextSize.size1,
            width: kv.emphasis ? PosTextSize.size2 : PosTextSize.size1,
          ),
        ),
      ]));
    }
    _thermalHr(generator, bytes, w);

    for (final kv in doc.purpose) {
      _thermalKv(generator, bytes, kv);
    }
    _thermalHr(generator, bytes, w);

    bytes.addAll(generator.row([
      PosColumn(text: 'DATE ${doc.deviceDate}', width: 6),
      PosColumn(
        text: 'TIME ${doc.deviceTime}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
    for (final kv in doc.device) {
      _thermalKv(generator, bytes, kv);
    }
    _thermalHr(generator, bytes, w);

    bytes.addAll(generator.text(
      'RECEIPT VERIFICATION CODE',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));
    bytes.addAll(generator.text(
      doc.verificationCode,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));
    bytes.addAll(generator.qrcode(
      doc.qrData,
      size: QRSize.size4,
      align: PosAlign.center,
    ));
    bytes.addAll(generator.feed(1));

    for (final f in doc.footerCenter) {
      bytes.addAll(generator.text(
        f,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  Future<void> _printSunmiTra() async {
    final doc = _doc;
    final logoBytes = await _loadTraLogoBytes();
    if (logoBytes != null) {
      await SunmiPrinter.printImage(
        logoBytes,
        align: SunmiPrintAlign.CENTER,
      );
      await SunmiPrinter.lineWrap(1);
    }

    Future<void> sunmiCenter(String text, {bool bold = false}) async {
      await SunmiPrinter.printText(
        '$text\n',
        style: SunmiTextStyle(
          align: SunmiPrintAlign.CENTER,
          bold: bold,
          fontSize: bold ? 26 : 22,
        ),
      );
    }

    Future<void> sunmiKv(TraReceiptKv kv) async {
      await SunmiPrinter.printRow(cols: [
        SunmiColumn(
          text: kv.label.toUpperCase(),
          width: 6,
        ),
        SunmiColumn(
          text: kv.value,
          width: 6,
          style: SunmiTextStyle(
            align: SunmiPrintAlign.RIGHT,
            bold: kv.emphasis,
            fontSize: kv.emphasis ? 28 : 22,
          ),
        ),
      ]);
    }

    for (var i = 0; i < doc.headerCenter.length; i++) {
      await sunmiCenter(doc.headerCenter[i], bold: i == 2);
    }
    await SunmiPrinter.line(type: 'dashed');

    for (final kv in doc.identity) {
      await sunmiKv(kv);
    }
    await sunmiCenter(doc.locationLine);
    await SunmiPrinter.line(type: 'dashed');

    for (final kv in doc.buyer) {
      await sunmiKv(kv);
    }
    await SunmiPrinter.line(type: 'dashed');

    await SunmiPrinter.printRow(cols: [
      SunmiColumn(text: 'QTY', width: 3),
      SunmiColumn(
          text: 'AMOUNT',
          width: 3,
          style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
      SunmiColumn(
          text: 'XR',
          width: 3,
          style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
      SunmiColumn(
          text: 'TZS',
          width: 3,
          style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
    ]);

    for (final it in doc.items) {
      await SunmiPrinter.printText(
        '${it.description}\n',
        style: SunmiTextStyle(fontSize: 22),
      );
      await SunmiPrinter.printRow(cols: [
        SunmiColumn(text: '${it.qty}', width: 3),
        SunmiColumn(
            text: _dec(it.unitAmount),
            width: 3,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
        SunmiColumn(
            text: it.xr,
            width: 3,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
        SunmiColumn(
            text: _dec(it.amountTzs),
            width: 3,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
      ]);
    }
    await SunmiPrinter.line(type: 'dashed');

    for (final kv in doc.totals) {
      await sunmiKv(kv);
    }
    await SunmiPrinter.line(type: 'dashed');

    for (final kv in doc.purpose) {
      await sunmiKv(kv);
    }
    await SunmiPrinter.line(type: 'dashed');

    await SunmiPrinter.printRow(cols: [
      SunmiColumn(text: 'DATE ${doc.deviceDate}', width: 6),
      SunmiColumn(
        text: 'TIME ${doc.deviceTime}',
        width: 6,
        style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
      ),
    ]);
    for (final kv in doc.device) {
      await sunmiKv(kv);
    }
    await SunmiPrinter.line(type: 'dashed');

    await SunmiPrinter.printText(
      'RECEIPT VERIFICATION CODE\n',
      style: SunmiTextStyle(
        align: SunmiPrintAlign.CENTER,
        bold: true,
        fontSize: 22,
      ),
    );
    await SunmiPrinter.printText(
      '${doc.verificationCode}\n',
      style: SunmiTextStyle(
        align: SunmiPrintAlign.CENTER,
        bold: true,
        fontSize: 26,
      ),
    );
    await SunmiPrinter.printQRCode(
      doc.qrData,
      style: SunmiQrcodeStyle(
        qrcodeSize: 6,
        align: SunmiPrintAlign.CENTER,
      ),
    );
    await SunmiPrinter.lineWrap(1);

    for (final f in doc.footerCenter) {
      await sunmiCenter(f);
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
                  padding:
                      const EdgeInsets.fromLTRB(6, 4, 6, 0),
                  child: Center(
                    child: SizedBox(
                      width: 220,
                      child: _ReceiptPreview(doc: _doc),
                    ),
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

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.doc});

  final TraReceiptDoc doc;

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 9.5,
    height: 1.22,
    color: _C.ink,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          _traLogoAsset,
          width: 34,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        ...doc.headerCenter.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: _mono.copyWith(
                fontWeight: l == doc.headerCenter[2]
                    ? FontWeight.w800
                    : FontWeight.w400,
                fontSize: l == doc.headerCenter[2] ? 10.5 : 9.5,
              ),
            ),
          ),
        ),
        _PreviewDivider(),
        ...doc.identity.map((kv) => _PreviewKv(kv)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            doc.locationLine,
            textAlign: TextAlign.center,
            style: _mono,
          ),
        ),
        _PreviewDivider(),
        ...doc.buyer.map((kv) => _PreviewKv(kv)),
        _PreviewDivider(),
        _PreviewItemHeader(),
        ...doc.items.expand((it) => [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(it.description, style: _mono),
              ),
              _PreviewItemRow(it),
            ]),
        _PreviewDivider(),
        ...doc.totals.map((kv) => _PreviewKv(kv, emphasize: kv.emphasis)),
        _PreviewDivider(),
        ...doc.purpose.map((kv) => _PreviewKv(kv)),
        _PreviewDivider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DATE ${doc.deviceDate}', style: _mono),
            Text('TIME ${doc.deviceTime}', style: _mono),
          ],
        ),
        ...doc.device.map((kv) => _PreviewKv(kv)),
        _PreviewDivider(),
        Text(
          'RECEIPT VERIFICATION CODE',
          textAlign: TextAlign.center,
          style: _mono.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          doc.verificationCode,
          textAlign: TextAlign.center,
          style: _mono.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: QrImageView(
            data: doc.qrData,
            version: QrVersions.auto,
            size: 56,
            gapless: true,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ...doc.footerCenter.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              f,
              textAlign: TextAlign.center,
              style: _mono.copyWith(fontSize: 8.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: CustomPaint(
        painter: _DashPainter(),
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.border
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewKv extends StatelessWidget {
  const _PreviewKv(this.kv, {this.emphasize = false});

  final TraReceiptKv kv;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              kv.label.toUpperCase(),
              style: _ReceiptPreview._mono.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                fontSize: emphasize ? 10.5 : 9.5,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              kv.value,
              textAlign: TextAlign.right,
              style: _ReceiptPreview._mono.copyWith(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w500,
                fontSize: emphasize ? 11.5 : 9.5,
                letterSpacing: emphasize ? 0.6 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewItemHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('QTY', style: _ReceiptPreview._mono.copyWith(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 4,
              child: Text('AMOUNT',
                  textAlign: TextAlign.right,
                  style: _ReceiptPreview._mono.copyWith(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 2,
              child: Text('XR',
                  textAlign: TextAlign.right,
                  style: _ReceiptPreview._mono.copyWith(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 5,
              child: Text('AMOUNT TZS',
                  textAlign: TextAlign.right,
                  style: _ReceiptPreview._mono.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _PreviewItemRow extends StatelessWidget {
  const _PreviewItemRow(this.it);

  final TraReceiptItemLine it;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 2,
            child: Text('${it.qty}', style: _ReceiptPreview._mono)),
        Expanded(
            flex: 4,
            child: Text(_dec(it.unitAmount),
                textAlign: TextAlign.right,
                style: _ReceiptPreview._mono)),
        Expanded(
            flex: 2,
            child: Text(it.xr,
                textAlign: TextAlign.right,
                style: _ReceiptPreview._mono)),
        Expanded(
            flex: 5,
            child: Text(_dec(it.amountTzs),
                textAlign: TextAlign.right,
                style: _ReceiptPreview._mono)),
      ],
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Text(
            'TRA LEGAL RECEIPT',
            style: _ts(16, weight: FontWeight.w800, color: _C.primary),
          ),
          const SizedBox(height: 4),
          Text(receiptLabel, style: _ts(12, color: _C.inkMid)),
          const SizedBox(height: 2),
          Text(formattedDate, style: _ts(11, color: _C.inkMid)),
        ],
      ),
    );
  }
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
