import 'package:flutter/material.dart';
import 'package:music_player/models/music_models.dart';
import 'package:music_player/services/playlist_service.dart';
import 'package:music_player/widgets/album_cover.dart';
import 'package:music_player/widgets/floating_notification.dart';
import '../services/audio_service.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  final AudioService _audioService = AudioService();
  List<AudioFile> _audioFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    setState(() => _isLoading = true);
    final files = await _audioService.getAllAudioFiles();
    setState(() {
      _audioFiles = files;
      _isLoading = false;
    });
  }

  Future<void> _showSongOptions(BuildContext context, AudioFile audio) async {
  final playlists = await PlaylistService().getAllPlaylists();
  
  if (playlists.isEmpty) {
    FloatingNotification.show(context, '请先创建歌单');
    return;
  }

  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('添加到歌单', style: TextStyle(fontSize: 18)),
        ),
        ...playlists.map((playlist) => ListTile(
          title: Text(playlist.name),
          onTap: () async {
            await PlaylistService().addSongToPlaylist(
              playlist.id, 
              audio.path
            );
            if (mounted) {
              Navigator.pop(context);
              FloatingNotification.show(
                context, 
                '已添加到 ${playlist.name}'
              );
            }
          },
        )),
      ],
    ),
  );
}

  // 格式化时长（毫秒转分:秒）
  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return '0:00';
    final seconds = (milliseconds / 1000).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('音乐库', style: TextStyle(fontSize: 24, color: Colors.black87)),
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_audioFiles.isEmpty)
            const Text('音乐库为空，请前往文件夹页面添加音乐文件夹')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _audioFiles.length,
                itemBuilder: (context, index) {
                  final audio = _audioFiles[index];
                  return ListTile(
                    // 移除封面显示，只用默认音乐图标

  leading: AlbumCover(
    albumArtBytes: audio.albumArtBytes,
    size: 50,
  ),
  title: Text(
    audio.title ?? '未知标题',
    overflow: TextOverflow.ellipsis,
  ),
  subtitle: Text(
    '${audio.artist ?? '未知艺术家'} - ${audio.album ?? '未知专辑'}',
    overflow: TextOverflow.ellipsis,
  ),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_formatDuration(audio.duration)),
      IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showSongOptions(context, audio),
      ),
    ],
  ),
  onTap: () {
    // 原播放逻辑
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
