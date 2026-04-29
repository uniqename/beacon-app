import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../constants/brand_colors.dart';
import '../../models/support_group.dart';
import '../../models/user.dart';
import '../../services/support_group_service.dart';

/// Dialog for creating a new support group room
///
/// Only accessible to approved counselors, volunteers, and admins.
/// Allows creating immediate live rooms or scheduling future sessions.
class CreateRoomDialog extends StatefulWidget {
  final AppUser currentUser;

  const CreateRoomDialog({
    super.key,
    required this.currentUser,
  });

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SupportGroupService _groupService = SupportGroupService();

  GroupType _selectedType = GroupType.general;
  GroupPrivacy _selectedPrivacy = GroupPrivacy.public;
  bool _startNow = true;
  DateTime? _scheduledTime;
  int _maxMembers = 50;
  bool _isCreating = false;

  // Guidelines
  final Map<String, bool> _guidelines = {
    'Respect & Kindness': true,
    'Confidentiality': true,
    'No Judgment': true,
    'Listen Actively': false,
    'Trigger Warnings': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectScheduledTime() async {
    final now = DateTime.now();

    // Pick date
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BeaconColors.vibrantOrange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    // Pick time
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BeaconColors.vibrantOrange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _scheduledTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Prepare guidelines map
      final guidelinesMap = <String, String>{};
      _guidelines.forEach((key, value) {
        if (value) {
          guidelinesMap[key] = _getGuidelineDescription(key);
        }
      });

      // Generate unique Agora channel name
      final channelName = 'room_${const Uuid().v4().substring(0, 8)}';

      // Create group
      final group = SupportGroup(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        privacy: _selectedPrivacy,
        facilitatorId: widget.currentUser.id,
        memberIds: [],
        moderatorIds: [],
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        isActive: true,
        guidelines: guidelinesMap,
        maxMembers: _maxMembers,
        tags: _getDefaultTags(),
        isLive: _startNow,
        hostName: widget.currentUser.displayName,
        scheduledTime: _startNow ? DateTime.now() : _scheduledTime,
        agoraChannelName: channelName,
      );

      // Save to database
      final groupId = await _groupService.createGroup(group);

      if (groupId.isNotEmpty && mounted) {
        Navigator.of(context).pop(group); // Return the created group

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _startNow
                  ? 'Room created successfully! Starting now...'
                  : 'Room scheduled successfully!',
            ),
            backgroundColor: BeaconColors.softSageGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to create room');
      }
    } catch (e) {
      developer.log('CreateRoomDialog: Error creating room: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating room: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  String _getGuidelineDescription(String guideline) {
    switch (guideline) {
      case 'Respect & Kindness':
        return 'Treat all members with respect, compassion, and understanding';
      case 'Confidentiality':
        return 'What is shared here, stays here';
      case 'No Judgment':
        return 'This is a judgment-free zone';
      case 'Listen Actively':
        return 'Give others your full attention when they share';
      case 'Trigger Warnings':
        return 'Provide content warnings when discussing sensitive topics';
      default:
        return guideline;
    }
  }

  List<String> _getDefaultTags() {
    final tags = <String>[_selectedType.toString().split('.').last];

    if (_selectedPrivacy == GroupPrivacy.private) {
      tags.add('private');
    }

    if (_startNow) {
      tags.add('live');
    } else {
      tags.add('scheduled');
    }

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BeaconColors.vibrantOrange,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create Support Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room name
                      Text(
                        'Room Name *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Daily Morning Check-In',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: BeaconColors.vibrantOrange, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a room name';
                          }
                          if (value.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe what this room is about...',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: BeaconColors.vibrantOrange, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Room type
                      Text(
                        'Room Type',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<GroupType>(
                            value: _selectedType,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            icon: Icon(Icons.arrow_drop_down, color: BeaconColors.vibrantOrange),
                            onChanged: (GroupType? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedType = value;
                                });
                              }
                            },
                            items: GroupType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  _getTypeDisplayName(type),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Privacy
                      Text(
                        'Privacy',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPrivacyOption(
                              GroupPrivacy.public,
                              Icons.public,
                              'Public',
                              'Anyone can join',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPrivacyOption(
                              GroupPrivacy.private,
                              Icons.lock,
                              'Private',
                              'Invite only',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Timing
                      Text(
                        'When?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimingOption(
                              true,
                              Icons.play_circle,
                              'Start Now',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimingOption(
                              false,
                              Icons.schedule,
                              'Schedule',
                            ),
                          ),
                        ],
                      ),

                      if (!_startNow) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _selectScheduledTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _scheduledTime == null
                                    ? Colors.red.withValues(alpha: 0.5)
                                    : BeaconColors.softSageGreen,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: BeaconColors.vibrantOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _scheduledTime == null
                                        ? 'Select date and time'
                                        : _formatScheduledTime(_scheduledTime!),
                                    style: TextStyle(
                                      color: _scheduledTime == null
                                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: _scheduledTime != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Max members
                      Text(
                        'Maximum Participants',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _maxMembers.toDouble(),
                              min: 10,
                              max: 100,
                              divisions: 18,
                              activeColor: BeaconColors.vibrantOrange,
                              inactiveColor: BeaconColors.softSageGreen.withValues(alpha: 0.3),
                              label: '$_maxMembers',
                              onChanged: (value) {
                                setState(() {
                                  _maxMembers = value.toInt();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: BeaconColors.softSageGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_maxMembers',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Guidelines
                      Text(
                        'Room Guidelines',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._guidelines.entries.map((entry) {
                        return CheckboxListTile(
                          value: entry.value,
                          onChanged: (value) {
                            setState(() {
                              _guidelines[entry.key] = value ?? false;
                            });
                          },
                          title: Text(
                            entry.key,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          activeColor: BeaconColors.softSageGreen,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BeaconColors.vibrantOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_startNow ? 'Create & Start' : 'Schedule Room'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(
    GroupPrivacy privacy,
    IconData icon,
    String label,
    String description,
  ) {
    final isSelected = _selectedPrivacy == privacy;

    return InkWell(
      onTap: () => setState(() => _selectedPrivacy = privacy),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? BeaconColors.softSageGreen.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BeaconColors.softSageGreen
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? BeaconColors.softSageGreen
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingOption(bool startNow, IconData icon, String label) {
    final isSelected = _startNow == startNow;

    return InkWell(
      onTap: () => setState(() => _startNow = startNow),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? BeaconColors.vibrantOrange.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BeaconColors.vibrantOrange
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? BeaconColors.vibrantOrange
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(GroupType type) {
    switch (type) {
      case GroupType.general:
        return 'General Support';
      case GroupType.survivors:
        return 'Survivors Circle';
      case GroupType.mothers:
        return 'Mothers Support';
      case GroupType.legal:
        return 'Legal Guidance';
      case GroupType.healing:
        return 'Healing Journey';
      case GroupType.skills:
        return 'Skills & Employment';
    }
  }

  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    final dateStr = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    final timeStr = TimeOfDay.fromDateTime(dateTime).format(context);

    if (difference.inDays == 0) {
      return 'Today at $timeStr';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at $timeStr';
    } else {
      return '$dateStr at $timeStr';
    }
  }
}
