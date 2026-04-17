import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/user.dart';
import '../../services/local_database_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> _users = [];
  final Map<String, bool> _userAvailability = {}; // Track availability separately since it's final
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final db = await LocalDatabaseService.database;
      final results = await db.query(
        'users',
        where: 'is_anonymous = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );

      if (mounted) {
        setState(() {
          _users = results.map((map) => AppUser.fromMap(map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<AppUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
             user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
             user.userType.toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and stats header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // User stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Users',
                              _users.length.toString(),
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Active',
                              _users.where((u) => u.isAvailable).length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Survivors',
                              _users.where((u) => u.userType == UserType.survivor).length.toString(),
                              Icons.shield,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // User list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getUserTypeColor(user.userType),
                            child: Icon(
                              _getUserTypeIcon(user.userType),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            user.displayName ?? 'Anonymous User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email ?? 'No email'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getUserTypeColor(user.userType).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getUserTypeString(user.userType),
                                      style: TextStyle(
                                        color: _getUserTypeColor(user.userType),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.isAvailable ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.isAvailable ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: user.isAvailable ? Colors.green[700] : Colors.red[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) => _handleUserAction(action, user),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: user.isAvailable ? 'deactivate' : 'activate',
                                child: Row(
                                  children: [
                                    Icon(user.isAvailable ? Icons.block : Icons.check_circle, size: 16),
                                    const SizedBox(width: 8),
                                    Text(user.isAvailable ? 'Deactivate' : 'Activate'),
                                  ],
                                ),
                              ),
                              if (user.userType != UserType.admin)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.red;
      case UserType.counselor:
        return Colors.blue;
      case UserType.volunteer:
        return Colors.green;
      case UserType.survivor:
        return Colors.purple;
    }
  }

  IconData _getUserTypeIcon(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Icons.admin_panel_settings;
      case UserType.counselor:
        return Icons.psychology;
      case UserType.volunteer:
        return Icons.volunteer_activism;
      case UserType.survivor:
        return Icons.shield;
    }
  }

  String _getUserTypeString(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'Admin';
      case UserType.counselor:
        return 'Counselor';
      case UserType.volunteer:
        return 'Volunteer';
      case UserType.survivor:
        return 'Survivor';
    }
  }

  void _handleUserAction(String action, AppUser user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('${password}ngo_support_salt');
    return sha256.convert(bytes).toString();
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserType selectedType = UserType.survivor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'User Type', border: OutlineInputBorder()),
                    items: UserType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_getUserTypeString(t)),
                    )).toList(),
                    onChanged: (t) => setDialogState(() => selectedType = t!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final db = await LocalDatabaseService.database;
                  final id = const Uuid().v4();
                  final now = DateTime.now().toIso8601String();
                  await db.insert('users', {
                    'id': id,
                    'display_name': nameController.text.trim(),
                    'email': emailController.text.trim().toLowerCase(),
                    'password_hash': _hashPassword(passwordController.text),
                    'user_type': selectedType.toString().split('.').last,
                    'is_anonymous': 0,
                    'approval_status': 'approved',
                    'is_available': 1,
                    'created_at': now,
                    'last_updated': now,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameController.text} created'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(AppUser user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.displayName);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();
    UserType selectedType = user.userType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit: ${user.displayName}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password (leave blank to keep current)',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'User Type', border: OutlineInputBorder()),
                    items: UserType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_getUserTypeString(t)),
                    )).toList(),
                    onChanged: (t) => setDialogState(() => selectedType = t!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final db = await LocalDatabaseService.database;
                  final updates = <String, dynamic>{
                    'display_name': nameController.text.trim(),
                    'email': emailController.text.trim().toLowerCase(),
                    'user_type': selectedType.toString().split('.').last,
                    'last_updated': DateTime.now().toIso8601String(),
                  };
                  if (passwordController.text.isNotEmpty) {
                    updates['password_hash'] = _hashPassword(passwordController.text);
                  }
                  await db.update('users', updates, where: 'id = ?', whereArgs: [user.id]);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameController.text} updated'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    try {
      final db = await LocalDatabaseService.database;
      final newStatus = user.isAvailable ? 0 : 1;
      await db.update('users', {'is_available': newStatus, 'last_updated': DateTime.now().toIso8601String()},
          where: 'id = ?', whereArgs: [user.id]);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} ${newStatus == 1 ? "activated" : "deactivated"}'),
            backgroundColor: newStatus == 1 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      developer.log('Error toggling user status: $e');
    }
  }

  void _showDeleteConfirmation(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.displayName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final db = await LocalDatabaseService.database;
                await db.delete('users', where: 'id = ?', whereArgs: [user.id]);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user.displayName} deleted'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}