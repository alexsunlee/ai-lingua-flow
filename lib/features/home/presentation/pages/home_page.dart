import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomePage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined, semanticLabel: '文本学习'),
            activeIcon: Icon(Icons.article, semanticLabel: '文本学习'),
            label: '文本学习',
            tooltip: '文本学习 - 学习英文文本',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam_outlined, semanticLabel: '视频学习'),
            activeIcon: Icon(Icons.videocam, semanticLabel: '视频学习'),
            label: '视频学习',
            tooltip: '视频学习 - YouTube视频学习',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_outlined, semanticLabel: '图片学习'),
            activeIcon: Icon(Icons.image, semanticLabel: '图片学习'),
            label: '图片学习',
            tooltip: '图片学习 - 图片内容学习',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.replay_outlined, semanticLabel: '练习'),
            activeIcon: Icon(Icons.replay, semanticLabel: '练习'),
            label: '练习',
            tooltip: '练习 - 跟读练习和单词复习',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined, semanticLabel: '学习评估'),
            activeIcon: Icon(Icons.assessment, semanticLabel: '学习评估'),
            label: '评估',
            tooltip: '学习评估 - AI学习分析',
          ),
        ],
      ),
    );
  }
}
