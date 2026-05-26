import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';

class ScanProgressDialog extends StatelessWidget {
  final String status;
  final int progress;
  final int total;

  const ScanProgressDialog({
    super.key,
    required this.status,
    required this.progress,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? progress / total : 0.0;

    return PopScope(
      canPop: false,
      child: GlassCard(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status,
                style: AppTheme.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              GlassProgressIndicator.linear(value: ratio),
              const SizedBox(height: 12),
              if (total > 0)
                Text(
                  '$progress / $total',
                  style: AppTheme.textStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
