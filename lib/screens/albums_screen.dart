import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../models/music_models.dart';
import '../widgets/floating_notification.dart';
import '../widgets/album_cover.dart'; // 导入封面组件

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final AudioService _audioService = AudioService();
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);
    final albums = await _audioService.getAllAlbums();
    setState(() {
      _albums = albums;
      _isLoading = false;
    });
  }

  // 新增：从专辑的歌曲中提取封面字节（取第一首有封面的歌曲）
  Uint8List? _getAlbumCoverBytes(Album album) {
    // 遍历专辑下的所有歌曲，找到第一个有有效封面的
    for (var song in album.songs) {
      if (song.albumArtBytes != null && song.albumArtBytes!.isNotEmpty) {
        return song.albumArtBytes;
      }
    }
    // 所有歌曲都没有封面，返回null（组件会显示默认图标）
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('专辑', style: TextStyle(fontSize: 24, color: Colors.black87)),
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_albums.isEmpty)
            const Text('暂无专辑数据，请先添加音乐文件夹')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  // 提取当前专辑的封面字节
                  final albumCoverBytes = _getAlbumCoverBytes(album);

                  return ListTile(
                    // 关键：用AlbumCover组件替换默认Icon
                    leading: AlbumCover(
                      albumArtBytes: albumCoverBytes, // 传入专辑封面字节
                      size: 50, // 与原Icon尺寸一致（50）
                    ),
                    title: Text(album.name),
                    subtitle: Text('艺术家: ${album.artist} · ${album.songs.length} 首歌曲'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      FloatingNotification.show(context, '查看 《${album.name}》 专辑');
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}