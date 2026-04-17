import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/beacon_division.dart';
import '../../services/auth_service.dart';
import '../../services/local_database_service.dart';
import '../../services/smart_ai_service.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  _JobsScreenState createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  List<JobOpportunity> _allJobs = [];
  List<JobOpportunity> _filteredJobs = [];
  String _selectedType = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      // Load admin-managed jobs from DB first
      final db = await LocalDatabaseService.database;
      final rows = await db.query('job_postings',
          where: 'is_active = 1', orderBy: 'posted_at DESC');

      final dbJobs = rows.map((row) => JobOpportunity(
        id: row['id'] as String,
        title: row['title'] as String,
        type: row['type'] as String? ?? 'full_time',
        description: row['description'] as String? ?? '',
        requirements: (row['requirements'] as String?)?.split('\n') ?? [],
        location: row['location'] as String? ?? 'Accra',
        isRemote: (row['is_remote'] as int? ?? 0) == 1,
        applicationEmail: row['application_email'] as String? ?? '',
        postedDate: row['posted_at'] != null
            ? DateTime.tryParse(row['posted_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        isUrgent: (row['is_urgent'] as int? ?? 0) == 1,
      )).toList();

      // Append hardcoded fallback jobs
      final hardcodedJobs = SmartAIService.getRelevantJobs(
        userSkills: '',
        location: 'Accra',
      );

      if (mounted) {
        setState(() {
          _allJobs = [...dbJobs, ...hardcodedJobs];
          _filteredJobs = _allJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fall back to hardcoded if DB fails
      if (mounted) {
        setState(() {
          _allJobs = SmartAIService.getRelevantJobs(userSkills: '', location: 'Accra');
          _filteredJobs = _allJobs;
          _isLoading = false;
        });
      }
    }
  }

  void _filterJobs() {
    setState(() {
      _filteredJobs = _allJobs.where((job) {
        bool matchesType = _selectedType == 'all' || job.type == _selectedType;
        bool matchesSearch = _searchQuery.isEmpty ||
            job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            job.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesType && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Job Opportunities',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFF0562D),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFF0562D)))
          : Column(
              children: [
                _buildSearchAndFilter(),
                _buildJobStats(),
                Expanded(child: _buildJobsList()),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF0562D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterJobs();
            },
            decoration: InputDecoration(
              hintText: 'Search jobs...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Volunteer', 'volunteer'),
                _buildFilterChip('Part-time', 'part-time'),
                _buildFilterChip('Full-time', 'full-time'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedType == value;
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFFF0562D),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedType = value;
          });
          _filterJobs();
        },
        backgroundColor: Colors.white,
        selectedColor: Color(0xFFF0562D),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildJobStats() {
    int totalJobs = _allJobs.length;
    int urgentJobs = _allJobs.where((job) => job.isUrgent).length;
    int volunteerJobs = _allJobs.where((job) => job.type == 'volunteer').length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Jobs', totalJobs.toString(), Icons.work, Colors.blue),
          _buildStatItem('Urgent', urgentJobs.toString(), Icons.priority_high, Colors.red),
          _buildStatItem('Volunteer', volunteerJobs.toString(), Icons.volunteer_activism, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildJobsList() {
    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No jobs found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredJobs.length,
      itemBuilder: (context, index) {
        JobOpportunity job = _filteredJobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(JobOpportunity job) {
    Color typeColor = _getTypeColor(job.type);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailScreen(job: job),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: typeColor.withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ),
                    if (job.isUrgent)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  job.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildJobChip(job.type.toUpperCase(), Icons.schedule, typeColor),
                    _buildJobChip(job.location, Icons.location_on, Colors.blue),
                    if (job.isRemote)
                      _buildJobChip('REMOTE', Icons.home, Colors.green),
                    _buildJobChip(
                      'Posted ${_getTimeAgo(job.postedDate)}',
                      Icons.calendar_today,
                      Colors.grey,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailScreen(job: job),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        _quickApply(job);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: typeColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Quick Apply',
                        style: TextStyle(color: typeColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'volunteer':
        return Colors.green;
      case 'full-time':
        return Colors.blue;
      case 'part-time':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Recently';
    }
  }

  void _quickApply(JobOpportunity job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JobApplicationSheet(job: job),
    );
  }
}

class _JobApplicationSheet extends StatefulWidget {
  final JobOpportunity job;

  const _JobApplicationSheet({required this.job});

  @override
  State<_JobApplicationSheet> createState() => _JobApplicationSheetState();
}

class _JobApplicationSheetState extends State<_JobApplicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();

  String? _resumePath;
  String? _resumeName;
  String? _ghanaCardPath;
  String? _ghanaCardName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
  }

  void _prefillFromAuth() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _resumePath = result.files.single.path;
        _resumeName = result.files.single.name;
      });
    }
  }

  Future<void> _pickGhanaCard() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _ghanaCardPath = result.files.single.path;
        _ghanaCardName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final db = await LocalDatabaseService.database;
      await db.insert('job_applications', {
        'id': const Uuid().v4(),
        'job_id': widget.job.id,
        'job_title': widget.job.title,
        'applicant_name': _nameController.text.trim(),
        'applicant_email': _emailController.text.trim(),
        'applicant_phone': _phoneController.text.trim(),
        'cover_letter': _coverLetterController.text.trim(),
        'resume_path': _resumePath,
        'ghana_card_path': _ghanaCardPath,
        'applied_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Color(0xFFF0562D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apply: ${widget.job.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF0562D),
                ),
              ),
              const SizedBox(height: 20),
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              // Cover letter
              TextFormField(
                controller: _coverLetterController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Cover Letter',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              // Resume picker
              OutlinedButton.icon(
                onPressed: _pickResume,
                icon: const Icon(Icons.attach_file),
                label: Text(_resumeName ?? 'Attach Resume (PDF/Doc)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFFF0562D)),
                  foregroundColor: const Color(0xFFF0562D),
                ),
              ),
              const SizedBox(height: 12),
              // Ghana Card picker
              OutlinedButton.icon(
                onPressed: _pickGhanaCard,
                icon: const Icon(Icons.badge),
                label: Text(_ghanaCardName ?? 'Attach Ghana Card (Image/PDF)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFFF0562D)),
                  foregroundColor: const Color(0xFFF0562D),
                ),
              ),
              const SizedBox(height: 24),
              // Submit
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0562D),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Application',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}