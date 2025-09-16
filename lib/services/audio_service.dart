import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // 用于debugPrint（调试友好，Release模式自动忽略）
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
  final Uint8List? albumArtBytes; // 改为存储封面字节（而非路径）

  AudioFile({
    required this.path,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.albumArtBytes, // 替换原有的albumArtPath
  });
}

class AudioService {
  // 支持的音频格式（明确标识，方便排查格式不支持问题）
  final List<String> _supportedExtensions = [
    '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg'
  ];

  // 获取所有艺术家（添加日志，排查分组异常）
  Future<List<Artist>> getAllArtists() async {
    try {
      debugPrint('[AudioService] 开始获取所有艺术家');
      final audioFiles = await getAllAudioFiles();
      if (audioFiles.isEmpty) {
        debugPrint('[AudioService] 获取所有艺术家：无音频文件可分组');
        return [];
      }
      final artists = Artist.fromAudioFiles(audioFiles);
      debugPrint('[AudioService] 成功获取 ${artists.length} 个艺术家');
      return artists;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 获取所有艺术家失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 获取所有专辑（添加日志，排查专辑分组异常）
  Future<List<Album>> getAllAlbums() async {
    try {
      debugPrint('[AudioService] 开始获取所有专辑');
      final audioFiles = await getAllAudioFiles();
      if (audioFiles.isEmpty) {
        debugPrint('[AudioService] 获取所有专辑：无音频文件可分组');
        return [];
      }
      final albums = Album.fromAudioFiles(audioFiles);
      debugPrint('[AudioService] 成功获取 ${albums.length} 个专辑');
      return albums;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 获取所有专辑失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 根据艺术家名称获取歌曲（添加筛选日志，排查匹配异常）
  Future<List<AudioFile>> getSongsByArtist(String artistName) async {
    try {
      debugPrint('[AudioService] 开始筛选艺术家「$artistName」的歌曲');
      final audioFiles = await getAllAudioFiles();
      final matchedSongs = audioFiles.where((file) => 
        (file.artist ?? "未知艺术家") == artistName
      ).toList();
      debugPrint('[AudioService] 艺术家「$artistName」匹配到 ${matchedSongs.length} 首歌曲');
      return matchedSongs;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 筛选艺术家「$artistName」歌曲失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 根据专辑和艺术家获取歌曲（添加联合筛选日志）
  Future<List<AudioFile>> getSongsByAlbum(String albumName, String artistName) async {
    try {
      debugPrint('[AudioService] 开始筛选专辑「$albumName」(艺术家：$artistName) 的歌曲');
      final audioFiles = await getAllAudioFiles();
      final matchedSongs = audioFiles.where((file) => 
        (file.album ?? "未知专辑") == albumName && 
        (file.artist ?? "未知艺术家") == artistName
      ).toList();
      debugPrint('[AudioService] 专辑「$albumName」匹配到 ${matchedSongs.length} 首歌曲');
      return matchedSongs;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 筛选专辑「$albumName」歌曲失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 保存文件夹（添加路径校验和重复判断日志）
  Future<void> saveFolder(String folderPath) async {
    try {
      debugPrint('[AudioService] 开始保存文件夹：$folderPath');
      // 先校验文件夹是否存在（避免保存无效路径）
      if (!Directory(folderPath).existsSync()) {
        throw Exception('文件夹不存在：$folderPath');
      }
      final prefs = await SharedPreferences.getInstance();
      List<String> folders = prefs.getStringList('music_folders') ?? [];
      
      if (folders.contains(folderPath)) {
        debugPrint('[AudioService] 文件夹已存在，无需重复保存：$folderPath');
        return;
      }
      folders.add(folderPath);
      await prefs.setStringList('music_folders', folders);
      debugPrint('[AudioService] 成功保存文件夹：$folderPath（当前共 ${folders.length} 个文件夹）');
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 保存文件夹「$folderPath」失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      rethrow; // 如需上层捕获，可保留rethrow；如需静默处理，可删除
    }
  }

  // 获取已保存的文件夹（添加数量日志）
  Future<List<String>> getSavedFolders() async {
    try {
      debugPrint('[AudioService] 开始获取已保存的文件夹');
      final prefs = await SharedPreferences.getInstance();
      final folders = prefs.getStringList('music_folders') ?? [];
      debugPrint('[AudioService] 成功获取 ${folders.length} 个已保存文件夹');
      return folders;
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 获取已保存文件夹失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      return [];
    }
  }

  // 移除文件夹（添加关联音频删除日志）
  Future<void> removeFolder(String folderPath) async {
    try {
      debugPrint('[AudioService] 开始移除文件夹：$folderPath');
      final prefs = await SharedPreferences.getInstance();
      List<String> folders = prefs.getStringList('music_folders') ?? [];
      
      if (!folders.contains(folderPath)) {
        debugPrint('[AudioService] 文件夹不存在，无需移除：$folderPath');
        return;
      }
      folders.remove(folderPath);
      await prefs.setStringList('music_folders', folders);
      // 移除该文件夹下的音频记录（添加子操作日志）
      await _removeAudioFilesFromFolder(folderPath);
      debugPrint('[AudioService] 成功移除文件夹：$folderPath（当前剩余 ${folders.length} 个文件夹）');
    } catch (e, stackTrace) {
      debugPrint('[AudioService] 移除文件夹「$folderPath」失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      rethrow;
    }
  }

  // 扫描音频文件（核心流程：添加逐环节日志，定位扫描/元数据/封面问题）
  Future<List<AudioFile>> scanAudioFiles(String folderPath) async {
  List<AudioFile> audioFiles = [];
  final directory = Directory(folderPath);

  if (!directory.existsSync()) {
    debugPrint('[扫描错误] 文件夹不存在：$folderPath');
    return audioFiles;
  }

  await for (var entity in directory.list(recursive: true)) {
    if (entity is File) {
      final extension = path.extension(entity.path).toLowerCase();
      if (_supportedExtensions.contains(extension)) {
        try {
          // 读取音频元数据（包含封面）
          final metadata = await readMetadata(
            entity,
            getImage: true, // 关键：获取封面
          );

          // 直接提取封面字节（不保存到文件）
          Uint8List? albumArtBytes;
          if (metadata.pictures.isNotEmpty && metadata.pictures.first.bytes != null) {
            albumArtBytes = metadata.pictures.first.bytes;
            debugPrint('[封面提取成功] ${entity.path}（大小：${albumArtBytes.lengthInBytes}字节）');
          } else {
            debugPrint('[封面提取失败] 无封面数据：${entity.path}');
          }

          // 构造AudioFile（使用字节数据）
          final audioFile = AudioFile(
            path: entity.path,
            title: metadata.title ?? path.basenameWithoutExtension(entity.path),
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.duration?.inMilliseconds,
            albumArtBytes: albumArtBytes, // 存储字节数据
          );
          audioFiles.add(audioFile);

        } catch (e) {
          debugPrint('[文件处理错误] ${entity.path}：$e');
        }
      }
    }
  }

  await _saveAudioFiles(audioFiles);
  return audioFiles;
}

  // 保存封面到临时目录（单独抽离，便于定位封面保存问题）
  Future<String?> _saveAlbumArtToTemp(Uint8List albumArtBytes, AudioMetadata metadata, File audioFile) async {
    try {
      debugPrint('[AudioService] 开始保存封面：${audioFile.path}');
      // 1. 获取临时目录
      final tempDir = await getTemporaryDirectory();
      debugPrint('[AudioService] 临时目录：${tempDir.path}');

      // 2. 创建封面存储子目录
      final artDir = Directory(p.join(tempDir.path, 'album_arts'));
      if (!artDir.existsSync()) {
        artDir.createSync(recursive: true);
        debugPrint('[AudioService] 新建封面目录：${artDir.path}');
      }
      if (!artDir.existsSync()) {
        throw Exception('封面目录创建后仍不存在：${artDir.path}');
      }

      // 3. 处理封面文件名（避免非法字符）
      String baseName = metadata.album ?? metadata.title ?? path.basenameWithoutExtension(audioFile.path);
      baseName = baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'); // 过滤Windows非法字符
      if (baseName.length > 50) baseName = baseName.substring(0, 50); // 限制长度
      final fileName = '$baseName.jpg';
      final artFilePath = p.join(artDir.path, fileName);
      debugPrint('[AudioService] 封面保存路径：$artFilePath');

      // 4. 写入封面文件
      final artFile = File(artFilePath);
      await artFile.writeAsBytes(albumArtBytes);
      // 校验写入结果
      if (!artFile.existsSync()) {
        throw Exception('封面写入后文件不存在：$artFilePath');
      }
      if (artFile.lengthSync() != albumArtBytes.lengthInBytes) {
        throw Exception('封面文件大小不匹配（写入：${artFile.lengthSync()} 字节，原始：${albumArtBytes.lengthInBytes} 字节）：$artFilePath');
      }
      debugPrint('[AudioService] 封面保存成功：$artFilePath');
      return artFilePath;

    } catch (e, stackTrace) {
      debugPrint('[AudioService] 封面保存失败：${audioFile.path}\n错误：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      return null;
    }
  }

  // 保存音频文件信息（添加存储数量和异常日志）
  Future<void> _saveAudioFiles(List<AudioFile> audioFiles) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> allAudioPaths = prefs.getStringList('all_audio_files') ?? [];
  
  for (var file in audioFiles) {
    if (!allAudioPaths.contains(file.path)) {
      allAudioPaths.add(file.path);
    }
  }
  
  await prefs.setStringList('all_audio_files', allAudioPaths);
  
  // 仅保存基础信息（不包含封面字节）
  for (var file in audioFiles) {
    await prefs.setString('${file.path}_title', file.title ?? '');
    await prefs.setString('${file.path}_artist', file.artist ?? '');
    await prefs.setString('${file.path}_album', file.album ?? '');
    if (file.duration != null) {
      await prefs.setInt('${file.path}_duration', file.duration!);
    }
  }
}

  // 获取所有音频文件（添加读取数量和异常日志）
  // 获取所有音频文件（适配albumArtBytes，实时读取封面字节）
Future<List<AudioFile>> getAllAudioFiles() async {
  try {
    debugPrint('[AudioService] 开始获取所有音频文件');
    final prefs = await SharedPreferences.getInstance();
    List<String> allAudioPaths = prefs.getStringList('all_audio_files') ?? [];
    debugPrint('[AudioService] 路径列表长度：${allAudioPaths.length}');

    List<AudioFile> audioFiles = [];
    // 关键：将同步循环改为异步for循环（支持await读取元数据）
    for (final path in allAudioPaths) {
      try {
        // 1. 校验文件是否存在（跳过已删除的文件）
        final audioFile = File(path);
        if (!audioFile.existsSync()) {
          debugPrint('[AudioService] 跳过不存在的文件：$path');
          continue;
        }

        // 2. 实时读取音频元数据（获取封面字节，不依赖持久化）
        debugPrint('[AudioService] 读取文件元数据：$path');
        final metadata = await readMetadata(
          audioFile,
          getImage: true, // 必须开启，才能获取封面
        );

        // 3. 提取封面字节（处理空值）
        Uint8List? albumArtBytes;
        if (metadata.pictures.isNotEmpty && metadata.pictures.first.bytes != null) {
          albumArtBytes = metadata.pictures.first.bytes;
          debugPrint('[AudioService] 成功获取封面：$path（大小：${albumArtBytes.lengthInBytes}字节）');
        } else {
          debugPrint('[AudioService] 无封面数据：$path');
        }

        // 4. 构造AudioFile（传入封面字节，替代原albumArtPath）
        final newAudioFile = AudioFile(
          path: path,
          title: prefs.getString('${path}_title'),
          artist: prefs.getString('${path}_artist'),
          album: prefs.getString('${path}_album'),
          duration: prefs.getInt('${path}_duration'),
          albumArtBytes: albumArtBytes, // 传入实时读取的封面字节
        );
        audioFiles.add(newAudioFile);

      } catch (e, stackTrace) {
        // 单个文件处理失败：不中断循环，仅记录错误
        debugPrint('[AudioService] 构造音频对象失败：$path\n错误：$e\n堆栈：$stackTrace', wrapWidth: 1024);
      }
    }

    debugPrint('[AudioService] 成功获取 ${audioFiles.length} 个有效音频文件');
    return audioFiles;

  } catch (e, stackTrace) {
    debugPrint('[AudioService] 获取所有音频文件失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
    return [];
  }
}

  // 移除文件夹下的音频记录（添加删除数量日志）
  Future<void> _removeAudioFilesFromFolder(String folderPath) async {
    try {
      debugPrint('[AudioService] 开始移除文件夹下的音频记录：$folderPath');
      final prefs = await SharedPreferences.getInstance();
      List<String> allAudioPaths = prefs.getStringList('all_audio_files') ?? [];

      // 筛选该文件夹下的音频路径
      final filesToRemove = allAudioPaths.where((path) => 
        path.startsWith(folderPath)
      ).toList();
      if (filesToRemove.isEmpty) {
        debugPrint('[AudioService] 无匹配该文件夹的音频记录：$folderPath');
        return;
      }
      debugPrint('[AudioService] 匹配到 ${filesToRemove.length} 个需删除的音频记录');

      // 1. 更新路径列表
      allAudioPaths.removeWhere((path) => filesToRemove.contains(path));
      await prefs.setStringList('all_audio_files', allAudioPaths);

      // 2. 删除关联元数据
      int removedCount = 0;
      for (var file in filesToRemove) {
        try {
          await prefs.remove('${file}_title');
          await prefs.remove('${file}_artist');
          await prefs.remove('${file}_album');
          await prefs.remove('${file}_duration');
          removedCount++;
          // 可选：删除对应的封面文件（避免临时目录占用）
          final tempDir = await getTemporaryDirectory();
          final artDir = Directory(p.join(tempDir.path, 'album_arts'));
          // 封面文件名生成逻辑需与_saveAlbumArtToTemp保持一致
          String baseName = prefs.getString('${file}_album') ?? prefs.getString('${file}_title') ?? path.basenameWithoutExtension(file);
          baseName = baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          if (baseName.length > 50) baseName = baseName.substring(0, 50);
          final artFilePath = p.join(artDir.path, '$baseName.jpg');
          if (File(artFilePath).existsSync()) {
            await File(artFilePath).delete();
            debugPrint('[AudioService] 删除关联封面：$artFilePath');
          }
        } catch (e) {
          debugPrint('[AudioService] 删除音频记录失败：$file\n错误：$e', wrapWidth: 1024);
        }
      }
      debugPrint('[AudioService] 音频记录删除完成：成功删除 $removedCount / ${filesToRemove.length} 个记录');

    } catch (e, stackTrace) {
      debugPrint('[AudioService] 批量删除音频记录失败：$e\n堆栈信息：$stackTrace', wrapWidth: 1024);
      rethrow;
    }
  }
}