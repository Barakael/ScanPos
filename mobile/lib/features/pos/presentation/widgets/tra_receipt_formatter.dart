import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../sales/domain/entities/sale_entity.dart';
import '../../../shops/domain/entities/shop_entity.dart';

/// TRA legal receipt text layout (matches official sample ordering).
class TraReceiptFormatter {
  TraReceiptFormatter._();

  static const int lineWidth = 42;

  static String _twoCols(String left, String right, [int width = lineWidth]) {
    final l = left.trimRight();
    final r = right.trim();
    final gap = width - l.length - r.length;
    if (gap < 1) {
      return '$l $r';
    }
    return l + (' ' * gap) + r;
  }

  static String _payRowLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'CASH';
      case 'card':
        return 'CARD';
      case 'mobile':
        return 'MOBILE';
      default:
        return method.toUpperCase();
    }
  }

  /// Plain-text lines for thermal / Sunmi / PDF monospace rendering.
  static List<String> buildLines({
    required SaleEntity sale,
    required ShopEntity shop,
  }) {
    final dec = CurrencyFormatter.formatTraDecimal;
    final receiptNo =
        sale.serialNumber.isNotEmpty ? sale.serialNumber : sale.id;

    final totalExcl = sale.totalExclTax > 0
        ? sale.totalExclTax
        : (sale.total / 1.18);
    final totalTaxAmt =
        sale.totalTax > 0 ? sale.totalTax : (sale.total - totalExcl);

    final lines = <String>[
      '*** START OF LEGAL RECEIPT ***',
      shop.name,
      shop.address,
      'MOBILE',
      shop.location,
      'TEL: ${shop.mobile.isNotEmpty ? shop.mobile : shop.phone}',
      'TIN: ${shop.tin}',
      'VRN: ${shop.vrn}',
      'SERIAL NUMBER: $receiptNo',
      'UIN: ${sale.uin}',
      'TAX OFFICE: ${shop.taxOffice}',
      'CUSTOMER NAME: ${sale.customerName ?? ''}',
      'CUSTOMER ID TYPE: ${sale.customerIdType ?? ''}',
      'CUSTOMER ID: ${sale.customerId ?? ''}',
      'CUSTOMER MOBILE NUMBER: ${sale.customerPhone ?? ''}',
      'CUSTOMER ADDRESS: ${sale.customerAddress ?? ''}',
      'RECEIPT NUMBER: $receiptNo',
      'ZNR: ${sale.znr}',
      'RECEIPT DATE: ${DateFormat('dd/MM/yyyy').format(sale.createdAt)} TIME: ${DateFormat('HH:mm:ss').format(sale.createdAt)}',
    ];

    for (final item in sale.items) {
      lines.add(item.productName);
      final mid =
          '${item.quantity} x ${dec(item.unitPrice)}';
      lines.add(_twoCols(mid, dec(item.subtotal)));
    }

    lines.addAll([
      _twoCols('TOTAL EXCLUSIVE OF TAX', dec(totalExcl)),
      _twoCols('TOTAL TAX', dec(totalTaxAmt)),
      _twoCols('TOTAL INCLUSIVE OF TAX', dec(sale.total)),
      _twoCols(_payRowLabel(sale.paymentMethod), dec(sale.amountTendered)),
      _twoCols('CHANGE', dec(sale.cashChange)),
      'RECEIPT VERIFICATION CODE',
      sale.verificationCode.isNotEmpty
          ? sale.verificationCode
          : 'VERIFICATION',
      '*** END OF LEGAL RECEIPT ***',
      'Changamoto kwenye risiti hii piga',
      'hapa TRA 0800750294/0800750750',
    ]);

    return lines;
  }
}
