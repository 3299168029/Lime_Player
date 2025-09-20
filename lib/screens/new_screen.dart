import 'package:flutter/material.dart';

class NewScreen extends StatelessWidget {
  final VoidCallback onBack; // 添加返回回调

  const NewScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 228, 118, 118),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 顶部返回按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.expand_circle_down, color: Colors.white, size: 24),
                onPressed: onBack,
              ),
            ],
          ),
          
          // 原有内容
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('播放界面', style: TextStyle(fontSize: 24, color: Colors.white)),
                SizedBox(height: 20),
                Text('专辑详情，歌词等内容将显示在这里', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}