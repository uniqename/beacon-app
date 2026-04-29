import 'package:flutter/material.dart';

class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  final List<DownloadItem> _downloads = [
    DownloadItem(id: '1', name: 'Safety Plan Guide.pdf', size: '2.5 MB', status: DownloadStatus.completed, progress: 100),
    DownloadItem(id: '2', name: 'Emergency Contacts.pdf', size: '0.8 MB', status: DownloadStatus.completed, progress: 100),
    DownloadItem(id: '3', name: 'Legal Rights Ghana.pdf', size: '3.2 MB', status: DownloadStatus.downloading, progress: 45),
  ];

  @override
  Widget build(BuildContext context) {
    final completed = _downloads.where((d) => d.status == DownloadStatus.completed).toList();
    final inProgress = _downloads.where((d) => d.status == DownloadStatus.downloading).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Download Manager'),
        backgroundColor: Colors.cyan[700],
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _clearCompleted,
            tooltip: 'Clear completed',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (inProgress.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.downloading, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Downloading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                Text('${inProgress.length}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 12),
            ...inProgress.map((download) => _buildDownloadCard(download)),
            SizedBox(height: 24),
          ],
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Spacer(),
              Text('${completed.length}', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 12),
          if (completed.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No completed downloads', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...completed.map((download) => _buildDownloadCard(download)),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyan[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage, color: Colors.cyan[700]),
                    SizedBox(width: 12),
                    Text('Storage Usage', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Offline content:'),
                    Text('12.5 MB', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
                SizedBox(height: 4),
                Text('12.5 MB of 100 MB used', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(DownloadItem download) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFileIcon(download.name),
                  color: _getFileColor(download.name),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        download.size,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (download.status == DownloadStatus.downloading) ...[
                  IconButton(
                    icon: Icon(Icons.pause_circle, color: Colors.blue),
                    onPressed: () => _pauseDownload(download),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelDownload(download),
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.folder_open, color: Colors.grey[600]),
                    onPressed: () => _openDownload(download),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDownload(download),
                  ),
                ],
              ],
            ),
            if (download.status == DownloadStatus.downloading) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: download.progress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('${download.progress}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    if (filename.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (filename.endsWith('.mp3') || filename.endsWith('.m4a')) return Icons.audiotrack;
    if (filename.endsWith('.mp4')) return Icons.video_file;
    if (filename.endsWith('.jpg') || filename.endsWith('.png')) return Icons.image;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String filename) {
    if (filename.endsWith('.pdf')) return Colors.red;
    if (filename.endsWith('.mp3') || filename.endsWith('.m4a')) return Colors.purple;
    if (filename.endsWith('.mp4')) return Colors.blue;
    if (filename.endsWith('.jpg') || filename.endsWith('.png')) return Colors.green;
    return Colors.grey;
  }

  void _pauseDownload(DownloadItem download) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download paused: ${download.name}')),
    );
  }

  void _cancelDownload(DownloadItem download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Download'),
        content: Text('Stop downloading ${download.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _downloads.remove(download));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Download cancelled')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _openDownload(DownloadItem download) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${download.name}...')),
    );
  }

  void _deleteDownload(DownloadItem download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File'),
        content: Text('Delete ${download.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _downloads.remove(download));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearCompleted() {
    final completedCount = _downloads.where((d) => d.status == DownloadStatus.completed).length;
    if (completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No completed downloads to clear')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Completed'),
        content: Text('Remove all $completedCount completed downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _downloads.removeWhere((d) => d.status == DownloadStatus.completed);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$completedCount downloads cleared')),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}

enum DownloadStatus { downloading, paused, completed, failed }

class DownloadItem {
  final String id;
  final String name;
  final String size;
  DownloadStatus status;
  int progress;

  DownloadItem({
    required this.id,
    required this.name,
    required this.size,
    required this.status,
    required this.progress,
  });
}
