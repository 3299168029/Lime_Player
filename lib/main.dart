import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'music_player_home.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  
  // 配置窗口属性
  await windowManager.setSize(const Size(800, 600));
  await windowManager.center(); // 窗口居中显示
  await windowManager.setAlwaysOnTop(false);
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setBackgroundColor(Colors.transparent);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music_Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'MiSans',
      ),
      home: const MusicPlayerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}
