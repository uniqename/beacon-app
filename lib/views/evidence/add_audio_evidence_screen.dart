import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AddAudioEvidenceScreen extends StatefulWidget {
  final String evidenceId;
  final Function(List<String>) onAudioAdded;

  const AddAudioEvidenceScreen({
    super.key,
    required this.evidenceId,
    required this.onAudioAdded,
  });

  @override
  State<AddAudioEvidenceScreen> createState() => _AddAudioEvidenceScreenState();
}

class _AddAudioEvidenceScreenState extends State<AddAudioEvidenceScreen> {
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  final List<String> _recordings = [];
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    // Detect iPad/tablet for responsive UI
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final iconSize = isTablet ? 100.0 : 80.0;
    final buttonPadding = isTablet ? 40.0 : 32.0;
    final recordButtonSize = isTablet ? 48.0 : 40.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Audio Evidence'),
        backgroundColor: Colors.red[700],
        actions: [
          if (_recordings.isNotEmpty)
            TextButton.icon(
              onPressed: _saveRecordings,
              icon: Icon(Icons.save, color: Colors.white),
              label: Text('Save (${_recordings.length})', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.red[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Audio Recording Tips:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Find a quiet location', style: TextStyle(fontSize: 13, color: Colors.red[800])),
                Text('• Speak clearly and calmly', style: TextStyle(fontSize: 13, color: Colors.red[800])),
                Text('• Recordings are timestamped', style: TextStyle(fontSize: 13, color: Colors.red[800])),
                Text('• All audio is encrypted', style: TextStyle(fontSize: 13, color: Colors.red[800])),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording) ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red[100],
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: Icon(Icons.mic, size: 40, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Recording...',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ] else ...[
                  Icon(Icons.mic, size: iconSize, color: Colors.grey[400]),
                  SizedBox(height: 24),
                  Text(
                    'Ready to Record',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                ],
                SizedBox(height: 40),
                if (_recordings.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recordings (${_recordings.length})',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        ..._recordings.asMap().entries.map((entry) {
                          final index = entry.key;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red[100],
                                child: Icon(Icons.audiotrack, color: Colors.red[700]),
                              ),
                              title: Text('Recording ${index + 1}'),
                              subtitle: Text(DateTime.now().toString().substring(0, 16)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRecording(index),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(buttonPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording) ...[
                  ElevatedButton(
                    onPressed: _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(buttonPadding),
                    ),
                    child: Icon(Icons.mic, size: recordButtonSize, color: Colors.white),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _stopRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(buttonPadding),
                    ),
                    child: Icon(Icons.stop, size: recordButtonSize, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startRecording() async {
    // Check permission first
    final hasPermission = await _checkMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission required to record audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() => _recordingSeconds++);
    });

    try {
      // Get app directory for storage
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/evidence_audio_$timestamp.m4a';

      // Start recording with iPad-compatible settings
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      developer.log('✅ Audio recording started: $_currentRecordingPath');
    } catch (e) {
      developer.log('❌ Error starting recording: $e');
      _timer?.cancel();
      setState(() => _isRecording = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopRecording() async {
    _timer?.cancel();

    try {
      final path = await _audioRecorder.stop();

      if (path != null && path.isNotEmpty) {
        setState(() {
          _recordings.add(path);
          _isRecording = false;
        });

        developer.log('✅ Recording saved: $path (${_formatDuration(_recordingSeconds)})');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording saved (${_formatDuration(_recordingSeconds)})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isRecording = false);
        developer.log('⚠️ Recording path is null or empty');
      }
    } catch (e) {
      developer.log('❌ Error stopping recording: $e');
      setState(() => _isRecording = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recording. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteRecording(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recording'),
        content: Text('Delete Recording ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _recordings.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveRecordings() {
    widget.onAudioAdded(_recordings);
    Navigator.pop(context);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
