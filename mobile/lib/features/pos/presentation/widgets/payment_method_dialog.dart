import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/currency_formatter.dart';

// ════════════════════════════════════════════════════════════════════════════
// LOCAL DESIGN TOKENS
// ════════════════════════════════════════════════════════════════════════════
class _C {
  static const bg        = Color(0xFFF5F6FA);
  static const white     = Color(0xFFFFFFFF);
  static const primary   = Color(0xFF1E3A5F);
  static const primaryLt = Color(0xFF2B527A);
  static const accent    = Color(0xFF00C896);
  static const info      = Color(0xFF3B82F6);
  static const warn      = Color(0xFFFFA726);
  static const ink       = Color(0xFF1A2332);
  static const inkMid    = Color(0xFF64748B);
  static const inkLight  = Color(0xFFCBD5E1);
  static const border    = Color(0xFFE8EDF5);

  // Runtime opacity helpers — never used in const expressions
  static Color primaryOp(double o) => primary.withOpacity(o);
  static Color whiteOp(double o)   => Colors.white.withOpacity(o);
  static Color colorOp(Color c, double o) => c.withOpacity(o);
}

TextStyle _ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _C.ink,
}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color);

// ════════════════════════════════════════════════════════════════════════════
// PAYMENT METHOD DIALOG
// ════════════════════════════════════════════════════════════════════════════
class PaymentMethodDialog extends StatefulWidget {
  const PaymentMethodDialog({
    super.key,
    required this.total,
    required this.onPaymentMethodSelected,
  });

  final double total;
  final void Function(String) onPaymentMethodSelected;

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _animCtrl;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _select(String method) {
    HapticFeedback.selectionClick();
    setState(() => _selected = method);
  }

  void _confirm() {
    if (_selected == null) return;
    HapticFeedback.mediumImpact();
    widget.onPaymentMethodSelected(_selected!);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                // withOpacity is a runtime call — must NOT be in a const
                color: _C.primaryOp(0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header banner ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.primary, _C.primaryLt],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        // withOpacity → runtime helper
                        color: _C.whiteOp(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payment_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Payment Method',
                            style: _ts(16,
                                weight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose how the customer will pay',
                            style: _ts(11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _C.whiteOp(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Amount due row ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                color: _C.bg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount Due',
                      style: _ts(13,
                          color: _C.inkMid, weight: FontWeight.w500),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.total),
                      style: _ts(20,
                          weight: FontWeight.w800, color: _C.primary),
                    ),
                  ],
                ),
              ),

              // ── Payment options ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    _PayOption(
                      icon:        Icons.payments_rounded,
                      label:       'Cash',
                      description: 'Physical currency payment',
                      color:       _C.accent,
                      value:       'cash',
                      selected:    _selected == 'cash',
                      onTap:       () => _select('cash'),
                    ),
                    const SizedBox(height: 10),
                    _PayOption(
                      icon:        Icons.credit_card_rounded,
                      label:       'Card',
                      description: 'Credit or debit card',
                      color:       _C.info,
                      value:       'card',
                      selected:    _selected == 'card',
                      onTap:       () => _select('card'),
                    ),
                    const SizedBox(height: 10),
                    _PayOption(
                      icon:        Icons.smartphone_rounded,
                      label:       'Mobile Money',
                      description: 'M-Pesa, Airtel Money, etc.',
                      color:       _C.warn,
                      value:       'mobile',
                      selected:    _selected == 'mobile',
                      onTap:       () => _select('mobile'),
                    ),
                  ],
                ),
              ),

              // ── Actions ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _C.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: _ts(14,
                              weight: FontWeight.w600, color: _C.inkMid),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _selected == null ? 0.6 : 1.0,
                        child: ElevatedButton.icon(
                          onPressed: _selected == null ? null : _confirm,
                          icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18),
                          label: Text(
                            _selected == null
                                ? 'Select method'
                                : 'Confirm Payment',
                            style: _ts(14,
                                weight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            backgroundColor: _selected == null
                                ? _C.inkLight
                                : _C.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAYMENT OPTION TILE
// ════════════════════════════════════════════════════════════════════════════
class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final IconData     icon;
  final String       label, description, value;
  final Color        color;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          // All withOpacity calls go through the runtime helper
          color: selected ? _C.colorOp(color, 0.07) : _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : _C.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _C.colorOp(color, 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: _C.primaryOp(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? color : _C.colorOp(color, 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Label + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: _ts(14,
                        weight: FontWeight.w700,
                        color: selected ? color : _C.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: _ts(11, color: _C.inkMid)),
                ],
              ),
            ),

            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : _C.inkLight,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}