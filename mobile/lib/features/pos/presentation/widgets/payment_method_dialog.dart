import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';

class PaymentMethodDialog extends StatelessWidget {
  final double total;
  final Function(String) onPaymentMethodSelected;

  const PaymentMethodDialog({
    super.key,
    required this.total,
    required this.onPaymentMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Icon(
              Icons.payment,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Total Amount: ${CurrencyFormatter.format(total)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Payment Methods
            _PaymentMethodButton(
              icon: Icons.attach_money,
              label: 'Cash',
              description: 'Pay with cash',
              color: AppColors.success,
              onTap: () => onPaymentMethodSelected('cash'),
            ),
            
            const SizedBox(height: 12),
            
            _PaymentMethodButton(
              icon: Icons.credit_card,
              label: 'Card',
              description: 'Pay with credit/debit card',
              color: AppColors.primary,
              onTap: () => onPaymentMethodSelected('card'),
            ),
            
            const SizedBox(height: 12),
            
            _PaymentMethodButton(
              icon: Icons.smartphone,
              label: 'Mobile Money',
              description: 'Pay with mobile money',
              color: AppColors.accent,
              onTap: () => onPaymentMethodSelected('mobile'),
            ),
            
            const SizedBox(height: 24),
            
            // Cancel Button
            AppButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(50)),
          borderRadius: BorderRadius.circular(12),
          color: color.withAlpha(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
