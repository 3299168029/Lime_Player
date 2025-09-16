import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../models/music_models.dart';
import '../widgets/floating_notification.dart';
import '../widgets/album_cover.dart'; // 导入封面组件（关键）

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final AudioService _audioService = AudioService();
  List<Artist> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    final artists = await _audioService.getAllArtists();
    setState(() {
      _artists = artists;
      _isLoading = false;
    });
  }

  // 新增：提取艺术家的封面字节（取第一首有封面的歌曲）
  Uint8List? _getArtistCoverBytes(Artist artist) {
    // 遍历艺术家的所有歌曲，优先用第一首有有效封面的歌曲封面
    for (var song in artist.songs) {
      if (song.albumArtBytes != null && song.albumArtBytes!.isNotEmpty) {
        return song.albumArtBytes;
      }
    }
    // 所有歌曲都无封面，返回null（封面组件会显示默认图标）
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('艺术家', style: TextStyle(fontSize: 24, color: Colors.black87)),
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_artists.isEmpty)
            const Text('暂无艺术家数据，请先添加音乐文件夹')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _artists.length,
                itemBuilder: (context, index) {
                  final artist = _artists[index];
                  // 提取当前艺术家的封面字节
                  final artistCoverBytes = _getArtistCoverBytes(artist);

                  return ListTile(
                    // 关键：用封面组件替换默认的"人物图标"
                    leading: AlbumCover(
                      albumArtBytes: artistCoverBytes, // 传入艺术家封面字节
                      size: 50, // 保持与原图标相同尺寸（50）
                    ),
                    title: Text(artist.name),
                    subtitle: Text('${artist.songs.length} 首歌曲'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      FloatingNotification.show(
                        context, 
                        '查看 ${artist.name} 的歌曲'
                      );
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