import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // 用于debugPrint

class AlbumCover extends StatelessWidget {
  final Uint8List? albumArtBytes; // 接收封面字节（而非路径）
  final double size;
  final BoxFit fit;

  const AlbumCover({
    super.key,
    this.albumArtBytes, // 改为字节参数
    required this.size,
    this.fit = BoxFit.cover,
  });
@override
  Widget build(BuildContext context) {
    // 检查是否有有效的封面字节
    bool hasValidCover = albumArtBytes != null && albumArtBytes!.isNotEmpty;

    if (!hasValidCover) {
      debugPrint('[AlbumCover Error] 无有效封面字节数据');
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[200],
      ),
      child: hasValidCover
          ? Image.memory(
              albumArtBytes!, // 直接使用内存中的字节数据
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('[封面加载错误] 字节数据无效：$error');
                return const Icon(Icons.music_note, color: Colors.grey);
              },
            )
          : const Icon(Icons.music_note, color: Colors.grey),
    );
  }
}