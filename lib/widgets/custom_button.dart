import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isSecondary ? null : AppTheme.primaryGradient,
        color: isSecondary ? AppTheme.bgTertiary : null,
        borderRadius: BorderRadius.circular(12),
        border: isSecondary
            ? Border.all(color: AppTheme.borderMedium, width: 2)
            : null,
        boxShadow: isSecondary
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 20,
                          color: isSecondary
                              ? AppTheme.textPrimary
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSecondary
                              ? AppTheme.textPrimary
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

