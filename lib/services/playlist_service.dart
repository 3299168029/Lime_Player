import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PlaylistService {
  static const _playlistKey = 'saved_playlists';

  // 获取所有歌单
  Future<List<Playlist>> getAllPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_playlistKey);
      
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Playlist.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[PlaylistService] 获取歌单失败: $e');
      return [];
    }
  }

  // 创建新歌单
  Future<void> createPlaylist(String name) async {
    try {
      final playlists = await getAllPlaylists();
      // 生成唯一ID
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newPlaylist = Playlist(id: id, name: name);
      
      playlists.add(newPlaylist);
      await _savePlaylists(playlists);
    } catch (e) {
      debugPrint('[PlaylistService] 创建歌单失败: $e');
      rethrow;
    }
  }

  // 向歌单添加歌曲
  Future<void> addSongToPlaylist(String playlistId, String songPath) async {
    try {
      final playlists = await getAllPlaylists();
      final index = playlists.indexWhere((p) => p.id == playlistId);
      
      if (index == -1) throw Exception('歌单不存在');
      
      // 检查歌曲是否已在歌单中
      if (!playlists[index].songPaths.contains(songPath)) {
        final updated = playlists[index].copyWith(
          songPaths: [...playlists[index].songPaths, songPath]
        );
        playlists[index] = updated;
        await _savePlaylists(playlists);
      }
    } catch (e) {
      debugPrint('[PlaylistService] 添加歌曲到歌单失败: $e');
      rethrow;
    }
  }

  // 删除歌单
  Future<void> deletePlaylist(String playlistId) async {
    try {
      final playlists = await getAllPlaylists();
      playlists.removeWhere((p) => p.id == playlistId);
      await _savePlaylists(playlists);
    } catch (e) {
      debugPrint('[PlaylistService] 删除歌单失败: $e');
      rethrow;
    }
  }

  // 保存歌单列表
  Future<void> _savePlaylists(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = playlists.map((p) => p.toJson()).toList();
    await prefs.setString(_playlistKey, json.encode(jsonList));
  }
}