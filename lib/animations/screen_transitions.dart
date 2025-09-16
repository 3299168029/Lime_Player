import 'package:flutter/material.dart';

class ScreenTransitions {
  // 创建滑动动画
  static Animation<Offset> createSlideAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  // 创建退出动画
  static Animation<Offset> createExitAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 1.1),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  // 关键修改：使用动画进度值实现平滑缩放
  static Matrix4 getMainTransform(BuildContext context, double animationValue) {
    // 基于动画进度计算缩放比例（0.0→1.0 对应 1.0→0.85）
    final scale = 1.0 - (0.15 * animationValue);
    // 基于动画进度计算位移（0.0→1.0 对应 0→40px）
    final dy = 40.0 * animationValue;
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    final centerX = screenWidth / 2;
    final anchorY = MediaQuery.sizeOf(context).height;

    return Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(centerX, anchorY + dy)
      // ignore: deprecated_member_use
      ..scale(scale)
      // ignore: deprecated_member_use
      ..translate(-centerX, -anchorY);
  }
}
