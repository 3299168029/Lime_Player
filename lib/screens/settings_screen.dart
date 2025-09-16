import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置', style: TextStyle(fontSize: 24, color: Colors.black87)),
          SizedBox(height: 20),
          // 这里可以添加设置的具体内容
          Text('应用设置、音效设置、主题设置等将显示在这里'),
        ],
      ),
    );
  }
}
