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
            tooltip: '视频学习 - 学习YouTube视频',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none, semanticLabel: '跟读练习'),
            activeIcon: Icon(Icons.mic, semanticLabel: '跟读练习'),
            label: '跟读练习',
            tooltip: '跟读练习 - 练习英语发音',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined, semanticLabel: '生词本'),
            activeIcon: Icon(Icons.book, semanticLabel: '生词本'),
            label: '生词本',
            tooltip: '生词本 - 管理和复习单词',
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
