import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class TranslationBubble extends StatelessWidget {
  final String text;
  final String label;
  final bool isOriginal;
  final bool isRTL;

  const TranslationBubble({
    super.key,
    required this.text,
    required this.label,
    required this.isOriginal,
    this.isRTL = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isOriginal ? null : AppColors.primaryGradient,
        color: isOriginal ? AppColors.surfaceCard : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOriginal ? AppColors.border : AppColors.primary.withOpacity(0.3),
        ),
        boxShadow: isOriginal ? null : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isRTL ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
            children: [
              if (!isRTL)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOriginal
                        ? AppColors.textHint.withOpacity(0.15)
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: isOriginal ? AppColors.textHint : Colors.white70,
                      )),
                ),
              Row(children: [
                if (isRTL)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOriginal
                            ? AppColors.textHint.withOpacity(0.15)
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: isOriginal ? AppColors.textHint : Colors.white70)),
                    ),
                  ),
                // Copy button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard'),
                        backgroundColor: AppColors.surfaceCard,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Icon(Icons.copy_rounded, size: 16,
                      color: isOriginal ? AppColors.textHint : Colors.white54),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isOriginal ? FontWeight.w400 : FontWeight.w600,
                color: isOriginal ? AppColors.textPrimary : Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
