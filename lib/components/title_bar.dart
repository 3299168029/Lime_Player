import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'window_control_button.dart'; // 导入按钮子组件

class TitleBar extends StatelessWidget {
  final String title; // 标题文本
  final bool isMaximized; // 窗口最大化状态
  final VoidCallback onMinimize; // 最小化回调
  final VoidCallback onToggleMaximize; // 最大化/还原回调
  final VoidCallback onClose; // 关闭回调

  const TitleBar({
    super.key,
    required this.title,
    required this.isMaximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 35, // 标题栏固定高度
      child: GestureDetector(
        // 窗口拖动逻辑（仅标题栏区域）
        onPanStart: (details) => windowManager.startDragging(),
        child: Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 标题文本
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // 窗口控制按钮（封装子组件）
              Row(
                children: [
                  WindowControlButton(
                    icon: Icons.remove,
                    onPressed: onMinimize,
                    hoverColor: Colors.grey[300],
                  ),
                  WindowControlButton(
                    icon: isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
                    onPressed: onToggleMaximize,
                    hoverColor: Colors.grey[300],
                  ),
                  WindowControlButton(
                    icon: Icons.close,
                    onPressed: onClose,
                    hoverColor: Colors.red[100],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}