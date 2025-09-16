import 'package:flutter/material.dart';

// 侧边栏选项模型（可扩展）
class SidebarItem {
  final String label;
  final IconData icon;

  const SidebarItem({required this.label, required this.icon});
}

class MusicSidebar extends StatelessWidget {
  final int selectedIndex; // 当前选中索引
  final Function(int) onIndexChanged; // 索引变化回调
  final bool isExpanded; // 是否展开（显示文本）

  // 侧边栏选项列表（集中管理）
  final List<SidebarItem> _items = const [
    SidebarItem(label: '音乐', icon: Icons.music_note),
    SidebarItem(label: '艺术家', icon: Icons.person),
    SidebarItem(label: '专辑', icon: Icons.album),
    SidebarItem(label: '歌单', icon: Icons.list),
    SidebarItem(label: '文件夹', icon: Icons.folder),
    SidebarItem(label: '设置', icon: Icons.settings),
  ];

  const MusicSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.isExpanded,
  });

  @override
Widget build(BuildContext context) {
  const double sidebarWidth = 160;          // ① 固定宽度
  return SafeArea(
    child: Container(
      width: sidebarWidth,
      color: Colors.grey[100],
      child: Column(
        children: [
          const SizedBox(height: 8),
          // ② 手动生成每一项
          ...List.generate(_items.length, (i) {
              final selected = i == selectedIndex;
  return _SidebarRow(
    item: _items[i],
    selected: selected,
    onTap: () => onIndexChanged(i),
  );

}),



          const Spacer(),                  // ③ 底部留白
        ],
      ),
    ),
  );
}
}
class _SidebarRow extends StatefulWidget {
  final SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarRow> createState() => _SidebarRowState();
}

class _SidebarRowState extends State<_SidebarRow> {
  bool _hover = false;
  bool _pressing = false;

  Color get bgColor {
    if (widget.selected) return Colors.blue.withValues(alpha: 0.15);
    if (_pressing) return Colors.grey.withValues(alpha:0.25);
    if (_hover) return Colors.grey.withValues(alpha:0.12);
    return Colors.transparent;
  }

  FontWeight get weight =>
      widget.selected || _pressing ? FontWeight.w700 : FontWeight.normal;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon,
                  size: 28,
                  color: widget.selected ? Colors.blue : Colors.black54),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: widget.selected ? Colors.blue : Colors.black87,
                  fontWeight: weight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}