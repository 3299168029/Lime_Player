import 'package:flutter/foundation.dart';
import '../../services/audio_service.dart';// 导入之前的AudioFile模型






// 艺术家模型
class Artist {
  final String name; // 艺术家名称（"未知艺术家"作为默认）
  final List<AudioFile> songs; // 该艺术家的所有歌曲

  Artist({
    required this.name,
    required this.songs,
  });


  

  // 从音频文件列表创建艺术家列表（去重）
  static List<Artist> fromAudioFiles(List<AudioFile> files) {
    final Map<String, List<AudioFile>> artistMap = {};

    for (final file in files) {
      final artistName = file.artist ?? "未知艺术家";
      
      if (!artistMap.containsKey(artistName)) {
        artistMap[artistName] = [];
      }
      artistMap[artistName]!.add(file);
    }

    return artistMap.entries.map((entry) => Artist(
      name: entry.key,
      songs: entry.value,
    )).toList()..sort((a, b) => a.name.compareTo(b.name)); // 按名称排序
  }
}

// 专辑模型
class Album {
  final String name; // 专辑名称（"未知专辑"作为默认）
  final String artist; // 专辑所属艺术家
  final List<AudioFile> songs; // 该专辑的所有歌曲

  Album({
    required this.name,
    required this.artist,
    required this.songs,
  });

  // 从音频文件列表创建专辑列表（去重）
  static List<Album> fromAudioFiles(List<AudioFile> files) {
    final Map<String, Album> albumMap = {};

    for (final file in files) {
      final albumName = file.album ?? "未知专辑";
      final artistName = file.artist ?? "未知艺术家";
      final key = "$albumName|$artistName"; // 用专辑+艺术家作为唯一键（避免不同艺术家同名专辑冲突）

      if (!albumMap.containsKey(key)) {
        albumMap[key] = Album(
          name: albumName,
          artist: artistName,
          songs: [],
        );
      }
      albumMap[key]!.songs.add(file);
    }

    return albumMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name)); // 按名称排序
  }
}
