import 'package:flutter/material.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('歌单', style: TextStyle(fontSize: 24, color: Colors.black87)),
          SizedBox(height: 20),
          // 这里可以添加歌单的具体内容
          Text('用户创建的所有歌单将显示在这里'),
        ],
      ),
    );
  }
}
