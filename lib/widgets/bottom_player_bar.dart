import 'package:flutter/material.dart';
import 'dart:typed_data'; // 用于处理图片字节数据

class BottomPlayerBar extends StatelessWidget {
  // 回调函数 - 用于展开/收起详情页
  final VoidCallback onExpand;
  
  // 歌曲信息参数
  final String? songTitle;
  final String? artistName;
  final Uint8List? albumArtBytes; // 专辑封面字节数据

  const BottomPlayerBar({
    super.key,
    required this.onExpand,
    this.songTitle = '当前播放歌曲',
    this.artistName = '艺术家',
    this.albumArtBytes, // 可选参数，没有时显示默认图标
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 专辑封面 + 歌曲信息（合并为一个区域）
          _buildAlbumAndInfo(),
          
          // 控制按钮区域
          _buildControlButtons(),
          
          // 展开按钮
          _buildExpandButton(),
        ],
      ),
    );
  }

  // 构建专辑封面和歌曲信息
  Widget _buildAlbumAndInfo() {
    return Row(
      children: [
        // 专辑封面（48x48大小，带圆角）
        _buildAlbumCover(),
        const SizedBox(width: 12), // 间距
        
        // 歌曲信息（标题和艺术家）
        _buildSongInfo(),
      ],
    );
  }

  // 构建专辑封面
  Widget _buildAlbumCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4), // 圆角效果
      child: Container(
        width: 48,
        height: 48,
        color: Colors.grey[200], // 背景色（加载前显示）
        child: _getAlbumContent(),
      ),
    );
  }

  // 根据是否有封面数据显示不同内容
  Widget _getAlbumContent() {
    if (albumArtBytes != null && albumArtBytes!.isNotEmpty) {
      // 有专辑封面时显示图片
      return Image.memory(
        albumArtBytes!,
        fit: BoxFit.cover, // 填充方式
        gaplessPlayback: true, // 切换图片时无闪烁（为动画做准备）
      );
    } else {
      // 无封面时显示默认音乐图标
      return const Icon(
        Icons.music_note,
        color: Colors.grey,
        size: 24,
      );
    }
  }

  // 构建歌曲信息
  Widget _buildSongInfo() {
    // 限制歌曲信息宽度，避免在小屏幕上溢出
    return SizedBox(
      width: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            songTitle!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis, // 文本溢出时显示省略号
            maxLines: 1,
          ),
          Text(
            artistName!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // 构建控制按钮
  Widget _buildControlButtons() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.play_arrow, size: 28),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: () {},
        ),
      ],
    );
  }

  // 构建展开按钮
  Widget _buildExpandButton() {
    return IconButton(
      icon: const Icon(Icons.expand_circle_down),
      onPressed: onExpand,
    );
  }
}
    