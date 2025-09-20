import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import 'music_models.dart';


class Playlist {
  final String id;
  final String name;
  final List<String> songPaths; // 存储歌曲路径作为唯一标识

  Playlist({
    required this.id,
    required this.name,
    this.songPaths = const [],
  });

  // 复制歌单并修改歌曲列表
  Playlist copyWith({
    String? id,
    String? name,
    List<String>? songPaths,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songPaths: songPaths ?? this.songPaths,
    );
  }

  // 序列化用于存储
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songPaths': songPaths,
    };
  }

  // 从JSON反序列化
  static Playlist fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      songPaths: List<String>.from(json['songPaths']),
    );
  }
}