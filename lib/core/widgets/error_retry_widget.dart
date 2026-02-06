import 'package:flutter/material.dart';

/// Reusable error state with retry button.
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Factory for network errors.
  factory ErrorRetryWidget.network({VoidCallback? onRetry}) {
    return ErrorRetryWidget(
      message: '网络连接失败，请检查网络设置后重试',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }

  /// Factory for API key errors.
  factory ErrorRetryWidget.apiKey({VoidCallback? onRetry}) {
    return ErrorRetryWidget(
      message: '请先在设置中配置 Gemini API 密钥',
      onRetry: onRetry,
      icon: Icons.key_off,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
