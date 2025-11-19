import 'package:flutter/material.dart';
import '../../models/user.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> _users = [];
  Map<String, bool> _userAvailability = {}; // Track availability separately since it's final
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    // Simulate loading users - in real app this would come from a database
    setState(() {
      _users = _getDemoUsers();
      _isLoading = false;
    });
  }

  List<AppUser> _getDemoUsers() {
    return [
      AppUser(
        id: 'user_001',
        email: 'admin@beaconnewbeginnings.org',
        displayName: 'System Administrator',
        userType: UserType.admin,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        isAvailable: true,
      ),
      AppUser(
        id: 'user_002',
        email: 'counselor1@beaconnewbeginnings.org',
        displayName: 'Sarah Johnson',
        userType: UserType.counselor,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        isAvailable: true,
      ),
      AppUser(
        id: 'user_003',
        email: 'volunteer1@beaconnewbeginnings.org',
        displayName: 'Michael Chen',
        userType: UserType.volunteer,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        isAvailable: true,
      ),
      AppUser(
        id: 'user_004',
        email: 'survivor1@example.com',
        displayName: 'Anonymous User',
        userType: UserType.survivor,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isAvailable: true,
      ),
      AppUser(
        id: 'user_005',
        email: 'volunteer2@beaconnewbeginnings.org',
        displayName: 'Emily Rodriguez',
        userType: UserType.volunteer,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isAvailable: false,
      ),
      AppUser(
        id: 'user_006',
        email: 'counselor2@beaconnewbeginnings.org',
        displayName: 'Dr. James Wilson',
        userType: UserType.counselor,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isAvailable: true,
      ),
    ];
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
                          fillColor: Colors.white,
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
                                      color: _getUserTypeColor(user.userType).withOpacity(0.2),
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
                                      color: user.isAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
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
            color: Colors.grey.withOpacity(0.1),
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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Text('User creation functionality would typically connect to your authentication system and database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User creation feature coming soon!')),
              );
            },
            child: const Text('Create User'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User: ${user.displayName}'),
        content: const Text('User editing functionality would allow you to modify user details, permissions, and settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User editing saved successfully!')),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(AppUser user) {
    // Since isAvailable is final, we'd typically update this through the backend
    // For demo purposes, we'll show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'User status would be toggled through backend API. Current status: ${user.isAvailable ? "Available" : "Unavailable"}',
        ),
      ),
    );
  }

  void _showDeleteConfirmation(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _users.remove(user);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.displayName} has been deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}