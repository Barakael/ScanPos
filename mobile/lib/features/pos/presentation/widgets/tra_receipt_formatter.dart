import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../sales/domain/entities/sale_entity.dart';
import '../../../shops/domain/entities/shop_entity.dart';

/// Paper width for monospace character counts and layout.
enum TraReceiptWidth { mm58, mm80 }

class TraReceiptKv {
  const TraReceiptKv(
    this.label,
    this.value, {
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;
}

class TraReceiptItemLine {
  const TraReceiptItemLine({
    required this.description,
    required this.qty,
    required this.unitAmount,
    this.xr = '1.00',
    required this.amountTzs,
  });

  final String description;
  final int qty;
  final double unitAmount;
  final String xr;
  final double amountTzs;
}

/// Single source of truth for EFD/TRA-style receipt (PDF, preview, printers).
class TraReceiptDoc {
  const TraReceiptDoc({
    required this.width,
    required this.headerCenter,
    required this.identity,
    required this.locationLine,
    required this.buyer,
    required this.items,
    required this.totals,
    required this.purpose,
    required this.deviceDate,
    required this.deviceTime,
    required this.device,
    required this.verificationCode,
    required this.qrData,
    required this.footerCenter,
  });

  final TraReceiptWidth width;
  final List<String> headerCenter;
  final List<TraReceiptKv> identity;
  final String locationLine;
  final List<TraReceiptKv> buyer;
  final List<TraReceiptItemLine> items;
  final List<TraReceiptKv> totals;
  final List<TraReceiptKv> purpose;
  final String deviceDate;
  final String deviceTime;
  final List<TraReceiptKv> device;
  final String verificationCode;
  final String qrData;
  final List<String> footerCenter;

  int get charWidth =>
      width == TraReceiptWidth.mm58 ? 32 : 42;

  static String traQrUrl(String uin, String verificationCode) {
    final u = Uri.encodeComponent(uin);
    final v = Uri.encodeComponent(verificationCode);
    return 'https://verification.tra.go.tz/$u/$v';
  }
}

class TraReceiptFormatter {
  TraReceiptFormatter._();

  static String _dec(num v) => CurrencyFormatter.formatTraDecimal(v);

  static String _payInstrument(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':
        return 'CASH';
      case 'card':
        return 'CARD';
      case 'mobile':
        return 'E-MONEY';
      default:
        return (method ?? 'CASH').toUpperCase();
    }
  }

  static String _twoCols(String left, String right, int w) {
    final l = left.trimRight();
    final r = right.trim();
    final gap = w - l.length - r.length;
    if (gap < 1) {
      return '$l $r';
    }
    return l + (' ' * gap) + r;
  }

  static String _center(String text, int w) {
    final t = text.trim();
    if (t.length >= w) return t;
    final left = ((w - t.length) / 2).floor();
    return (' ' * left) + t;
  }

  static String _upper(String? s) => (s ?? '').trim().toUpperCase();

  /// Build structured receipt document (VAT-inclusive totals).
  static TraReceiptDoc buildDoc({
    required SaleEntity sale,
    required ShopEntity shop,
    TraReceiptWidth width = TraReceiptWidth.mm58,
  }) {
    final w = width;
    final receiptNo =
        sale.serialNumber.isNotEmpty ? sale.serialNumber : sale.id;
    final tel = shop.mobile.isNotEmpty ? shop.mobile : shop.phone;

    final totalExcl = sale.totalExclTax > 0
        ? sale.totalExclTax
        : (sale.total / 1.18);
    final totalTax = sale.totalTax > 0
        ? sale.totalTax
        : (sale.total - totalExcl);

    final pay = _payInstrument(sale.paymentMethod);
    final vrn = shop.vrn.trim().isEmpty ? 'NOT REGISTERED' : shop.vrn;

    final locLine = _upper(
      '${shop.location.trim()} / ${shop.address.trim()}',
    );
    final locationDisplay =
        locLine.replaceAll(RegExp(r'\s+/\s*'), ' / ').trim().isEmpty
            ? '-'
            : locLine;

    final items = <TraReceiptItemLine>[];
    for (final i in sale.items) {
      final qty = i.quantity;
      final lineTotal = i.subtotal;
      final unit = qty > 0 ? lineTotal / qty : lineTotal;
      items.add(TraReceiptItemLine(
        description: _upper(i.productName),
        qty: qty,
        unitAmount: unit,
        amountTzs: lineTotal,
      ));
    }

    final ver = sale.verificationCode.isNotEmpty
        ? sale.verificationCode
        : 'VERIFICATION';
    final uin = sale.uin.isNotEmpty ? sale.uin : receiptNo;

    return TraReceiptDoc(
      width: w,
      headerCenter: [
        '*** START OF LEGAL RECEIPT ***',
        'RECEIPT FOR SELLING GOODS/SERVICES',
        shop.name.trim(),
        shop.address.trim().isEmpty ? '-' : shop.address.trim(),
        _upper(shop.location),
        'TEL : $tel',
      ],
      identity: [
        TraReceiptKv('TIN', shop.tin),
        TraReceiptKv('VRN', vrn),
        TraReceiptKv('UIN', uin),
        TraReceiptKv('RECEIPT NO', receiptNo),
      ],
      locationLine: locationDisplay,
      buyer: [
        TraReceiptKv("BUYER'S NAME", sale.customerName ?? ''),
        TraReceiptKv("BUYER'S ID NO", sale.customerId ?? ''),
        TraReceiptKv("BUYER'S ID TYPE", sale.customerIdType ?? ''),
        TraReceiptKv('RECEIPT NUMBER', receiptNo),
        TraReceiptKv('Z NO', sale.znr),
        TraReceiptKv('DOC. NO', sale.id),
      ],
      items: items,
      totals: [
        TraReceiptKv('TOTAL EXCLUSIVE OF TAX', _dec(totalExcl)),
        TraReceiptKv('TOTAL TAX', _dec(totalTax)),
        TraReceiptKv('TOTAL INCLUSIVE OF TAX', _dec(sale.total)),
        TraReceiptKv('PAYMENT', pay),
        TraReceiptKv('TOTAL', _dec(sale.total), emphasis: true),
      ],
      purpose: [
        TraReceiptKv('PURPOSE(S)', 'GOODS/SERVICES'),
        TraReceiptKv('INSTRUMENT(S)', pay),
      ],
      deviceDate: DateFormat('dd-MM-yyyy').format(sale.createdAt),
      deviceTime: DateFormat('HH:mm:ss').format(sale.createdAt),
      device: [
        TraReceiptKv('SERIAL NUMBER', receiptNo),
        TraReceiptKv('EJ SN', uin),
      ],
      verificationCode: ver,
      qrData: TraReceiptDoc.traQrUrl(uin, ver),
      footerCenter: [
        '*** END OF LEGAL RECEIPT ***',
        'CHANGAMOTO KWENYE RISITI HII PIGA',
        'HAPA TRA 0800750294/0800750750',
      ],
    );
  }

  /// Plain monospace lines (thermal / Sunmi text fallback).
  static List<String> buildLines({
    required SaleEntity sale,
    required ShopEntity shop,
    TraReceiptWidth width = TraReceiptWidth.mm58,
  }) {
    final doc = buildDoc(sale: sale, shop: shop, width: width);
    return buildLinesFromDoc(doc);
  }

  static List<String> buildLinesFromDoc(TraReceiptDoc doc) {
    final w = doc.charWidth;
    final lines = <String>[];
    final dash = '-' * w;

    for (final h in doc.headerCenter) {
      lines.add(_center(h, w));
    }
    lines.add(dash);

    for (final kv in doc.identity) {
      lines.add(_twoCols(kv.label.toUpperCase(), kv.value, w));
    }
    lines.add(_center(doc.locationLine, w));
    lines.add(dash);

    for (final kv in doc.buyer) {
      lines.add(_twoCols(kv.label.toUpperCase(), kv.value, w));
    }
    lines.add(dash);

    lines.add(_fourColLine(w, 'QTY', 'AMOUNT', 'XR', 'AMOUNT TZS'));

    for (final it in doc.items) {
      lines.add(it.description);
      lines.add(_fourColLine(
        w,
        '${it.qty}',
        _dec(it.unitAmount),
        it.xr,
        _dec(it.amountTzs),
      ));
    }
    lines.add(dash);

    for (final kv in doc.totals) {
      lines.add(_twoCols(kv.label.toUpperCase(), kv.value, w));
    }
    lines.add(dash);

    for (final kv in doc.purpose) {
      lines.add(_twoCols(kv.label.toUpperCase(), kv.value, w));
    }
    lines.add(dash);

    lines.add(_twoCols(
      'DATE ${doc.deviceDate}',
      'TIME ${doc.deviceTime}',
      w,
    ));
    for (final kv in doc.device) {
      lines.add(_twoCols(kv.label.toUpperCase(), kv.value, w));
    }
    lines.add(dash);

    lines.add(_center('RECEIPT VERIFICATION CODE', w));
    lines.add(_center(doc.verificationCode, w));
    lines.add(dash);

    for (final f in doc.footerCenter) {
      lines.add(_center(f, w));
    }
    return lines;
  }

  /// Four numeric columns: col1 left, others right-aligned within slots.
  static String _fourColLine(
    int totalWidth,
    String c1,
    String c2,
    String c3,
    String c4,
  ) {
    final slots = [8, 10, 6, totalWidth - 24];
    String fit(String s, int max, {bool right = false}) {
      var t = s.trim();
      if (t.length > max) t = t.substring(0, max);
      if (right) {
        return t.padLeft(max);
      }
      return t.padRight(max);
    }
    return fit(c1, slots[0]) +
        fit(c2, slots[1], right: true) +
        fit(c3, slots[2], right: true) +
        fit(c4, slots[3], right: true);
  }
}
