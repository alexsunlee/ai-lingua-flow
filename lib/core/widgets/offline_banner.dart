import 'package:flutter/material.dart';

/// A banner shown at the top of the screen when offline.
class OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return MaterialBanner(
      content: const Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.white),
          SizedBox(width: 8),
          Text(
            '当前处于离线模式，部分功能不可用',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: const [SizedBox.shrink()],
    );
  }
}
