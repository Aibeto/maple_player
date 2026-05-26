import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';

class ScanProgressDialog extends StatelessWidget {
  final String status;
  final int progress;
  final int total;
  final String currentFile;
  final List<String> recentFiles;

  const ScanProgressDialog({
    super.key,
    required this.status,
    required this.progress,
    required this.total,
    this.currentFile = '',
    this.recentFiles = const [],
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? progress / total : 0.0;

    return PopScope(
      canPop: false,
      child: Card(
        color: const Color(0xE51C1C1E),
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GlassProgressIndicator.circular(value: ratio),
                    Text(
                      '${(ratio * 100).round()}%',
                      style: AppTheme.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (total > 0)
                Text(
                  '$progress / $total',
                  style: AppTheme.textStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              if (currentFile.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  currentFile,
                  style: AppTheme.textStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (recentFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: recentFiles.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.music_note,
                                size: 14, color: Colors.white30),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recentFiles[index],
                                style: AppTheme.textStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}