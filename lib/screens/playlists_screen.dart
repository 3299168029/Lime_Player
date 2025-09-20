import 'package:flutter/material.dart';
import 'package:music_player/models/playlist_model.dart';
import '../services/playlist_service.dart';
import '../widgets/floating_notification.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  List<Playlist> _playlists = [];
  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _playlistService.getAllPlaylists();
    setState(() => _playlists = playlists);
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新歌单'),
        content: TextField(
          controller: _playlistNameController,
          decoration: const InputDecoration(hintText: '输入歌单名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (_playlistNameController.text.trim().isNotEmpty) {
                await _playlistService.createPlaylist(
                  _playlistNameController.text.trim()
                );
                _playlistNameController.clear();
                Navigator.pop(context);
                _loadPlaylists();
                if (mounted) {
                  FloatingNotification.show(context, '歌单创建成功');
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('歌单', style: TextStyle(fontSize: 24, color: Colors.black87)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('新建歌单'),
                onPressed: _showCreatePlaylistDialog,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_playlists.isEmpty)
            const Text('暂无歌单，点击上方按钮创建')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.songPaths.length} 首歌曲'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _playlistService.deletePlaylist(playlist.id);
                            _loadPlaylists();
                            if (mounted) {
                              FloatingNotification.show(context, '歌单已删除');
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}