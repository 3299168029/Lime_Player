import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'components/title_bar.dart';
import 'components/sidebar.dart';
import 'screens/music_library_screen.dart';
import 'screens/artists_screen.dart';
import 'screens/albums_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/folders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/new_screen.dart';
import 'animations/screen_transitions.dart';
import 'widgets/bottom_player_bar.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MusicPlayerHome(),
    );
  }
}

class MusicPlayerHome extends StatefulWidget {
  const MusicPlayerHome({super.key});

  @override
  State<MusicPlayerHome> createState() => _MusicPlayerHomeState();
}

class _MusicPlayerHomeState extends State<MusicPlayerHome> 
    with WindowListener, SingleTickerProviderStateMixin {
  String? _currentSongTitle;
  String? _currentArtist;
  Uint8List? _currentAlbumArt; // 存储当前歌曲的专辑封面字节

  // 原有状态
  bool isMaximized = false;
  int _selectedSidebarIndex = 0;

  // 动画相关状态
  bool _showNewScreen = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  // 标题栏高度
  static const double titleBarHeight = 35;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkWindowState();

    // 初始化动画控制器 - 延长一点时间让缩放更明显
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 监听动画状态，在动画结束后更新显示状态
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _showNewScreen = false);
      }
    });

    // 新界面滑动动画
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _controller.dispose();
    super.dispose();
  }

  // 窗口状态检查
  Future<void> _checkWindowState() async {
    isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void onWindowMaximize() => setState(() => isMaximized = true);
  @override
  void onWindowUnmaximize() => setState(() => isMaximized = false);

  // 窗口控制函数
  Future<void> _minimizeWindow() => windowManager.minimize();
  Future<void> _toggleMaximizeWindow() => 
      isMaximized ? windowManager.unmaximize() : windowManager.maximize();
  Future<void> _closeWindow() => windowManager.close();

  // 切换界面方法
  void _toggleNewScreen() {
    if (_showNewScreen) {
      _controller.reverse(); // 退出动画
    } else {
      setState(() => _showNewScreen = true);
      _controller.forward(); // 进入动画
    }
  }

  // 主内容渲染
  Widget _buildMainContent() {
    final screens = [
      const MusicLibraryScreen(),
      const ArtistsScreen(),
      const AlbumsScreen(),
      const PlaylistsScreen(),
      const FoldersScreen(),
      const SettingsScreen(),
    ];
    return screens[_selectedSidebarIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // 1. 主界面内容 - 使用AnimatedBuilder实现平滑动画
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // 获取动画进度值（0.0-1.0）
              final animationValue = _controller.value;
              
              return Transform(
                // 使用动画进度值控制主界面变换
                transform: ScreenTransitions.getMainTransform(
                  context, 
                  animationValue // 传递动画进度而非布尔值
                ),
                child: Opacity(
                  // 基于动画进度的平滑透明度变化
                  opacity: 1.0 - (animationValue * 0.6), // 1.0 → 0.4
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: titleBarHeight),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      MusicSidebar(
                        selectedIndex: _selectedSidebarIndex,
                        onIndexChanged: (index) => setState(() => _selectedSidebarIndex = index),
                        isExpanded: constraints.maxWidth >= 600,
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.grey[100],
                          child: _buildMainContent(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. 新界面
if (_showNewScreen || _controller.status == AnimationStatus.reverse)
  SlideTransition(
    position: _slideAnimation,
    child: Container(
      margin: const EdgeInsets.only(top: titleBarHeight),
      height: MediaQuery.of(context).size.height - titleBarHeight,
      width: MediaQuery.of(context).size.width,
      child: NewScreen(
        onBack: _toggleNewScreen, // 传递返回回调
      ),
    ),
  ),

          // 3. 底部切换按钮
          // 替换原底部切换按钮代码
// 3. 底部音乐控制栏
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: BottomPlayerBar(
            onExpand: _toggleNewScreen, // 传递展开回调
            // 可以根据实际播放状态动态传递歌曲信息
            // songTitle: _currentSong?.title,
            // artistName: _currentSong?.artist,
          ),
),

          // 4. 标题栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: titleBarHeight,
            child: TitleBar(
              title: 'Music_Player',
              isMaximized: isMaximized,
              onMinimize: _minimizeWindow,
              onToggleMaximize: _toggleMaximizeWindow,
              onClose: _closeWindow,
            ),
          ),
        ],
      ),
    );
  }
}
