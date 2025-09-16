import 'package:flutter/material.dart';

class NewScreen extends StatelessWidget {
  const NewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 228, 118, 118),
      padding: const EdgeInsets.all(20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('新界面', style: TextStyle(fontSize: 24, color: Colors.blue)),
          SizedBox(height: 20),
          Text('专辑，歌词界面等内容将显示在这里'),
        ],
      ),
    );
  }
}
