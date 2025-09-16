import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/audio_service.dart';
import '../widgets/floating_notification.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final AudioService _audioService = AudioService();
  List<String> _selectedFolders = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedFolders();
  }

  Future<void> _loadSelectedFolders() async {
    final folders = await _audioService.getSavedFolders();
    setState(() {
      _selectedFolders = folders;
    });
  }

  Future<void> _selectFolder() async {
    // 打开系统文件夹选择器（参数名修正）
    final String? folderPath = await getDirectoryPath(
      confirmButtonText: '选择音乐文件夹',
    );

    if (folderPath != null && folderPath.isNotEmpty) {
      await _audioService.saveFolder(folderPath);
      await _audioService.scanAudioFiles(folderPath);
      _loadSelectedFolders();
      
      if (mounted) {
        FloatingNotification.show(
    context, 
    '已添加文件夹: $folderPath'
        );
      }
    }



    
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
              const Text('文件夹', style: TextStyle(fontSize: 24, color: Colors.black87)),
              ElevatedButton.icon(
                onPressed: _selectFolder,
                icon: const Icon(Icons.add),
                label: const Text('选取文件夹'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_selectedFolders.isEmpty)
            const Text('尚未选择任何文件夹，点击上方按钮添加音乐文件夹')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _selectedFolders.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_selectedFolders[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _audioService.removeFolder(_selectedFolders[index]);
                        _loadSelectedFolders();
  if (mounted) {
    FloatingNotification.show(
      context, 
      '已删除文件夹: ${_selectedFolders[index]}'
    );
  }


                      },
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
