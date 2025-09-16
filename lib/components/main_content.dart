import 'package:flutter/material.dart';
import 'sidebar.dart';

class MainContent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final double titleBarHeight; // 接收标题栏高度，避免硬编码

  const MainContent({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.titleBarHeight,
  });

  // 主内容渲染（原_buildMainContent逻辑）
  Widget _buildContent() {
    final contentMap = {
      0: const Text('音乐库', style: TextStyle(color: Colors.black87, fontSize: 24)),
      1: const Text('艺术家', style: TextStyle(color: Colors.black87, fontSize: 24)),
      2: const Text('专辑', style: TextStyle(color: Colors.black87, fontSize: 24)),
      3: const Text('歌单', style: TextStyle(color: Colors.black87, fontSize: 24)),
      4: const Text('文件夹', style: TextStyle(color: Colors.black87, fontSize: 24)),
      5: const Text('设置', style: TextStyle(color: Colors.black87, fontSize: 24)),
    };
    return Center(child: contentMap[selectedIndex]!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: titleBarHeight), // 避开标题栏
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // 侧边栏（原逻辑保留）
              MusicSidebar(
                selectedIndex: selectedIndex,
                onIndexChanged: onIndexChanged,
                isExpanded: constraints.maxWidth >= 600,
              ),
              // 主内容区
              Expanded(
                child: Container(
                  color: Colors.grey[100],
                  child: _buildContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}