import 'package:flutter/material.dart';
import 'dart:async';

// 定义通知弹出位置的枚举
enum NotificationPosition {
  topLeft,
  topRight,
  bottomLeft,  // 我们将修改这个位置的行为
  bottomRight,
  topCenter,
  bottomCenter,
  leftCenter,
  rightCenter,
}

class FloatingNotification {
  // 动画时长全局配置（默认400毫秒）
  static Duration animationDuration = const Duration(milliseconds: 400);
  
  // 存储当前显示的通知信息
  static _NotificationData? _currentNotification;

  /// 显示悬浮通知
  /// [message]：通知内容
  /// [showDuration]：通知显示时长（默认2秒）
  /// [position]：通知弹出位置（默认左下）
  static void show(
    BuildContext context, 
    String message, {
    Duration showDuration = const Duration(seconds: 2),
    NotificationPosition position = NotificationPosition.bottomLeft,
  }) {
    // 如果有当前通知，标记为需要替换
    if (_currentNotification != null) {
      _currentNotification!._needsReplacement = true;
      _currentNotification!._entry?.markNeedsBuild();
    }

    late final _NotificationData newNotification;
    
    newNotification = _NotificationData(
      message: message,
      showDuration: showDuration,
      position: position,
      onDismissed: () {
        if (_currentNotification == newNotification) {
          _currentNotification = null;
        }
      },
    );

    // 创建新的OverlayEntry
    final entry = OverlayEntry(
      builder: (context) => _NotificationContent(
        data: newNotification,
        onAnimationComplete: (isEnter) {
          if (isEnter) {
            newNotification.startTimer();
          } else {
            newNotification._entry?.remove();
            newNotification.onDismissed?.call();
          }
        },
      ),
    );

    newNotification._entry = entry;
    _currentNotification = newNotification;

    // 添加到根Overlay
    Overlay.of(context, rootOverlay: true)?.insert(entry);
  }
}

// 通知数据类
class _NotificationData {
  final String message;
  final Duration showDuration;
  final NotificationPosition position;
  final VoidCallback? onDismissed;
  OverlayEntry? _entry;
  Timer? _timer;
  bool _needsReplacement = false;

  _NotificationData({
    required this.message,
    required this.showDuration,
    required this.position,
    this.onDismissed,
  });

  // 开始计时
  void startTimer() {
    _timer?.cancel();
    _timer = Timer(showDuration, () {
      _needsReplacement = true;
      _entry?.markNeedsBuild();
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// 通知内容组件
class _NotificationContent extends StatefulWidget {
  final _NotificationData data;
  final Function(bool isEnterAnimation) onAnimationComplete;

  const _NotificationContent({
    super.key,
    required this.data,
    required this.onAnimationComplete,
  });

  @override
  State<_NotificationContent> createState() => _NotificationContentState();
}

class _NotificationContentState extends State<_NotificationContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: FloatingNotification.animationDuration,
    );

    // 根据位置设置不同的动画
    _animation = Tween<Offset>(
      begin: _getAnimationBeginOffset(),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete(true);
      } else if (status == AnimationStatus.dismissed) {
        widget.onAnimationComplete(false);
      }
    });

    _controller.forward();
  }

  // 根据位置获取动画开始的偏移量
  Offset _getAnimationBeginOffset() {
    switch (widget.data.position) {
      case NotificationPosition.topLeft:
      case NotificationPosition.topCenter:
      case NotificationPosition.topRight:
        return const Offset(0, -1.5); // 从顶部外进入
      case NotificationPosition.bottomLeft:
        // 改为从左侧外进入（侧边滑入效果）
        return const Offset(-1.5, 0); 
      case NotificationPosition.bottomCenter:
      case NotificationPosition.bottomRight:
        return const Offset(0, 1.5); // 从底部外进入
      case NotificationPosition.leftCenter:
        return const Offset(-1.5, 0); // 从左侧外进入
      case NotificationPosition.rightCenter:
        return const Offset(1.5, 0); // 从右侧外进入
    }
  }

  // 根据位置获取定位参数
  Positioned _getPositionedWidget(Widget child) {
    const horizontalMargin = 16.0;
    // 底部距离改为60像素
    const bottomMargin = 60.0;
    const topMargin = 16.0;
    
    switch (widget.data.position) {
      case NotificationPosition.topLeft:
        return Positioned(
          top: topMargin,
          left: horizontalMargin,
          child: child,
        );
      case NotificationPosition.topRight:
        return Positioned(
          top: topMargin,
          right: horizontalMargin,
          child: child,
        );
      case NotificationPosition.bottomLeft:
        // 重点修改：底部距离设为60像素
        return Positioned(
          bottom: bottomMargin,
          left: horizontalMargin,
          child: child,
        );
      case NotificationPosition.bottomRight:
        return Positioned(
          bottom: topMargin,
          right: horizontalMargin,
          child: child,
        );
      case NotificationPosition.topCenter:
        return Positioned(
          top: topMargin,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      case NotificationPosition.bottomCenter:
        return Positioned(
          bottom: topMargin,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      case NotificationPosition.leftCenter:
        return Positioned(
          top: 0,
          bottom: 0,
          left: horizontalMargin,
          child: Center(child: child),
        );
      case NotificationPosition.rightCenter:
        return Positioned(
          top: 0,
          bottom: 0,
          right: horizontalMargin,
          child: Center(child: child),
        );
    }
  }

  @override
  void didUpdateWidget(covariant _NotificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data._needsReplacement) {
      _startExitAnimation();
    }
  }

  void _startExitAnimation() {
    if (_controller.status == AnimationStatus.completed) {
      widget.data.cancelTimer();
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data._needsReplacement && _controller.status == AnimationStatus.completed) {
      _startExitAnimation();
    }

    return _getPositionedWidget(
      SlideTransition(
        position: _animation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  widget.data.message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
    