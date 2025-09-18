import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:music_player/models/music_models.dart';
import 'package:path_provider/path_provider.dart';

class AudioFile {
  final String path;
  final String? title;
  final String? artist;
  final String? album;
  final int? duration;
  final Uint8List? albumArtBytes;

  AudioFile({
    required this.path,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.albumArtBytes,
  });
}

class AudioService {
  final List<String> _supportedExtensions = [
    '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg'
  ];

  // 1. 精简过程日志，只保留结果和错误
  Future<List<Artist>> getAllArtists() async {
    try {
      final audioFiles = await getAllAudioFiles();
      if (audioFiles.isEmpty) {
        debugPrint('[AudioService] 无音频文件可分组艺术家');
        return [];
      }
      final artists = Artist.fromAudioFiles(audioFiles);
      debugPrint('[AudioService] 成功获取 ${artists.length} 个艺术家');
      return artists;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 获取艺术家失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  Future<List<Album>> getAllAlbums() async {
    try {
      final audioFiles = await getAllAudioFiles();
      if (audioFiles.isEmpty) {
        debugPrint('[AudioService] 无音频文件可分组专辑');
        return [];
      }
      final albums = Album.fromAudioFiles(audioFiles);
      debugPrint('[AudioService] 成功获取 ${albums.length} 个专辑');
      return albums;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 获取专辑失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 2. 筛选结果日志保留，移除"开始筛选"冗余前缀
  Future<List<AudioFile>> getSongsByArtist(String artistName) async {
    try {
      final audioFiles = await getAllAudioFiles();
      final matchedSongs = audioFiles.where((file) => 
        (file.artist ?? "未知艺术家") == artistName
      ).toList();
      debugPrint('[AudioService] 艺术家「$artistName」匹配到 ${matchedSongs.length} 首歌曲');
      return matchedSongs;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 筛选艺术家「$artistName」歌曲失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  Future<List<AudioFile>> getSongsByAlbum(String albumName, String artistName) async {
    try {
      final audioFiles = await getAllAudioFiles();
      final matchedSongs = audioFiles.where((file) => 
        (file.album ?? "未知专辑") == albumName && 
        (file.artist ?? "未知艺术家") == artistName
      ).toList();
      debugPrint('[AudioService] 专辑「$albumName」(艺术家：$artistName) 匹配到 ${matchedSongs.length} 首歌曲');
      return matchedSongs;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 筛选专辑「$albumName」歌曲失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 3. 保存文件夹：合并"开始/成功"日志，保留关键校验信息
  Future<void> saveFolder(String folderPath) async {
    try {
      if (!Directory(folderPath).existsSync()) {
        throw Exception('文件夹不存在');
      }
      final prefs = await SharedPreferences.getInstance();
      List<String> folders = prefs.getStringList('music_folders') ?? [];
      
      if (folders.contains(folderPath)) {
        debugPrint('[AudioService] 文件夹已存在，无需重复保存：$folderPath');
        return;
      }
      folders.add(folderPath);
      await prefs.setStringList('music_folders', folders);
      debugPrint('[AudioService] 保存文件夹成功：$folderPath（当前共 ${folders.length} 个文件夹）');
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 保存文件夹「$folderPath」失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      rethrow;
    }
  }

  // 4. 移除"开始获取"日志，只保留结果统计
  Future<List<String>> getSavedFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final folders = prefs.getStringList('music_folders') ?? [];
      debugPrint('[AudioService] 已保存文件夹数量：${folders.length}');
      return folders;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 获取已保存文件夹失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 5. 移除文件夹：精简过程日志，保留核心操作结果
  Future<void> removeFolder(String folderPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> folders = prefs.getStringList('music_folders') ?? [];
      
      if (!folders.contains(folderPath)) {
        debugPrint('[AudioService] 文件夹不存在，无需移除：$folderPath');
        return;
      }
      folders.remove(folderPath);
      await prefs.setStringList('music_folders', folders);
      await _removeAudioFilesFromFolder(folderPath);
      debugPrint('[AudioService] 移除文件夹成功：$folderPath（剩余 ${folders.length} 个文件夹）');
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 移除文件夹「$folderPath」失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      rethrow;
    }
  }

  // 6. 扫描音频：用批量统计替代逐个文件日志，只保留错误和最终结果
  Future<List<AudioFile>> scanAudioFiles(String folderPath) async {
    List<AudioFile> audioFiles = [];
    final directory = Directory(folderPath);
    int coverSuccessCount = 0; // 封面提取成功计数器

    if (!directory.existsSync()) {
      debugPrint('[AudioService] 扫描失败：文件夹不存在 $folderPath');
      return audioFiles;
    }

    await for (var entity in directory.list(recursive: true)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        if (_supportedExtensions.contains(extension)) {
          try {
            final metadata = await readMetadata(entity, getImage: true);
            
            // 统计封面提取成功数，不逐个打印
            Uint8List? albumArtBytes;
            if (metadata.pictures.isNotEmpty && metadata.pictures.first.bytes != null) {
              albumArtBytes = metadata.pictures.first.bytes;
              coverSuccessCount++;
            }

            audioFiles.add(AudioFile(
              path: entity.path,
              title: metadata.title ?? path.basenameWithoutExtension(entity.path),
              artist: metadata.artist,
              album: metadata.album,
              duration: metadata.duration?.inMilliseconds,
              albumArtBytes: albumArtBytes,
            ));
          } catch (e) {
            // 只保留处理失败的文件日志
            debugPrint('[AudioService] 处理音频文件失败：${entity.path}，原因：$e');
          }
        }
      }
    }

    await _saveAudioFiles(audioFiles);
    // 最终打印扫描统计结果
    debugPrint('[AudioService] 扫描文件夹 $folderPath：找到 ${audioFiles.length} 个音频文件，成功提取 $coverSuccessCount 个封面');
    return audioFiles;
  }

  // 7. 封面保存：移除过程日志，只保留错误信息（成功不打印）
  Future<String?> _saveAlbumArtToTemp(Uint8List albumArtBytes, AudioMetadata metadata, File audioFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final artDir = Directory(p.join(tempDir.path, 'album_arts'));
      
      if (!artDir.existsSync()) {
        artDir.createSync(recursive: true);
      }
      if (!artDir.existsSync()) {
        throw Exception('封面目录创建后仍不存在');
      }

      String baseName = metadata.album ?? metadata.title ?? path.basenameWithoutExtension(audioFile.path);
      baseName = baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      if (baseName.length > 50) baseName = baseName.substring(0, 50);
      final fileName = '$baseName.jpg';
      final artFilePath = p.join(artDir.path, fileName);

      final artFile = File(artFilePath);
      await artFile.writeAsBytes(albumArtBytes);
      if (!artFile.existsSync() || artFile.lengthSync() != albumArtBytes.lengthInBytes) {
        throw Exception('封面写入后校验失败');
      }
      return artFilePath;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 保存封面失败（文件：${audioFile.path}）：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return null;
    }
  }

  // 8. 保存音频信息：无日志（内部操作，失败由上层捕获）
  Future<void> _saveAudioFiles(List<AudioFile> audioFiles) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> allAudioPaths = prefs.getStringList('all_audio_files') ?? [];
    
    for (var file in audioFiles) {
      if (!allAudioPaths.contains(file.path)) {
        allAudioPaths.add(file.path);
      }
    }
    
    await prefs.setStringList('all_audio_files', allAudioPaths);
    
    for (var file in audioFiles) {
      await prefs.setString('${file.path}_title', file.title ?? '');
      await prefs.setString('${file.path}_artist', file.artist ?? '');
      await prefs.setString('${file.path}_album', file.album ?? '');
      if (file.duration != null) {
        await prefs.setInt('${file.path}_duration', file.duration!);
      }
    }
  }

  // 9. 获取所有音频：用批量统计替代逐个日志，失败文件汇总打印
  Future<List<AudioFile>> getAllAudioFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> allAudioPaths = prefs.getStringList('all_audio_files') ?? [];
      if (allAudioPaths.isEmpty) {
        debugPrint('[AudioService] 无已存储的音频文件路径');
        return [];
      }

      List<AudioFile> audioFiles = [];
      List<String> failedFiles = []; // 失败文件记录

      debugPrint('[AudioService] 开始加载 ${allAudioPaths.length} 个音频文件的元数据');
      for (final filePath in allAudioPaths) {
        try {
          final audioFile = File(filePath);
          if (!audioFile.existsSync()) {
            failedFiles.add('$filePath（文件不存在）');
            continue;
          }

          final metadata = await readMetadata(audioFile, getImage: true);
          Uint8List? albumArtBytes;
          if (metadata.pictures.isNotEmpty && metadata.pictures.first.bytes != null) {
            albumArtBytes = metadata.pictures.first.bytes;
          }

          audioFiles.add(AudioFile(
            path: filePath,
            title: prefs.getString('${filePath}_title'),
            artist: prefs.getString('${filePath}_artist'),
            album: prefs.getString('${filePath}_album'),
            duration: prefs.getInt('${filePath}_duration'),
            albumArtBytes: albumArtBytes,
          ));
        } catch (e) {
          failedFiles.add('$filePath（原因：$e）');
        }
      }

      // 打印最终统计，失败文件汇总（避免刷屏）
      debugPrint('[AudioService] 音频文件加载完成：成功 ${audioFiles.length} 个，失败 ${failedFiles.length} 个');
      if (failedFiles.isNotEmpty) {
        debugPrint('[AudioService] 失败文件列表：\n${failedFiles.join('\n')}', wrapWidth: 1024);
      }
      return audioFiles;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 加载所有音频文件失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 10. 移除文件夹音频记录：批量统计替代逐个日志
  Future<void> _removeAudioFilesFromFolder(String folderPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> allAudioPaths = prefs.getStringList('all_audio_files') ?? [];
      final filesToRemove = allAudioPaths.where((path) => path.startsWith(folderPath)).toList();

      if (filesToRemove.isEmpty) {
        debugPrint('[AudioService] 无匹配文件夹 $folderPath 的音频记录');
        return;
      }

      // 更新路径列表
      allAudioPaths.removeWhere((path) => filesToRemove.contains(path));
      await prefs.setStringList('all_audio_files', allAudioPaths);

      // 批量删除元数据和封面，统计结果
      int removedCount = 0;
      int removedCoverCount = 0;
      final tempDir = await getTemporaryDirectory();
      final artDir = Directory(p.join(tempDir.path, 'album_arts'));

      for (var filePath in filesToRemove) {
        try {
          await prefs.remove('${filePath}_title');
          await prefs.remove('${filePath}_artist');
          await prefs.remove('${filePath}_album');
          await prefs.remove('${filePath}_duration');
          removedCount++;

          // 封面删除（统计数量，不逐个打印）
          String baseName = prefs.getString('${filePath}_album') ?? prefs.getString('${filePath}_title') ?? path.basenameWithoutExtension(filePath);
          baseName = baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          if (baseName.length > 50) baseName = baseName.substring(0, 50);
          final artFilePath = p.join(artDir.path, '$baseName.jpg');
          if (File(artFilePath).existsSync()) {
            await File(artFilePath).delete();
            removedCoverCount++;
          }
        } catch (e) {
          debugPrint('[AudioService] 删除音频记录失败：$filePath，原因：$e');
        }
      }

      debugPrint('[AudioService] 批量删除完成：成功删除 $removedCount 条音频记录，$removedCoverCount 个封面文件');
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 批量删除音频记录失败：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      rethrow;
    }
  }
}