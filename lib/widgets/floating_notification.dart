import 'package:flutter/material.dart';
import 'dart:async';

class FloatingNotification {
  // 1. 新增：动画时长全局配置（默认400毫秒）
  static Duration animationDuration = const Duration(milliseconds: 400);
  
  // 存储当前显示的通知信息
  static _NotificationData? _currentNotification;

  /// 显示悬浮通知
  /// [message]：通知内容
  /// [showDuration]：通知显示时长（默认2秒）
  static void show(
    BuildContext context, 
    String message, {
    Duration showDuration = const Duration(seconds: 2),
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

// 通知数据类（新增显示时长参数）
class _NotificationData {
  final String message;
  final Duration showDuration; // 显示时长
  final VoidCallback? onDismissed;
  OverlayEntry? _entry;
  Timer? _timer;
  bool _needsReplacement = false;

  _NotificationData({
    required this.message,
    required this.showDuration,
    this.onDismissed,
  });

  // 开始计时（使用自定义的显示时长）
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
    // 2. 使用全局配置的动画时长
    _controller = AnimationController(
      vsync: this,
      duration: FloatingNotification.animationDuration,
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, 1.5),
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

    return Positioned(
      left: 16,
      bottom: 16,
      child: SlideTransition(
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
