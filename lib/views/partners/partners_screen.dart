import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/partner.dart';
import '../../services/partner_service.dart';
import '../../constants/brand_colors.dart';
import 'partner_detail_screen.dart';

class PartnersScreen extends StatefulWidget {
  final bool isAdmin;
  const PartnersScreen({super.key, this.isAdmin = false});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final _service = PartnerService();
  final _searchController = TextEditingController();

  List<Partner> _all = [];
  List<Partner> _filtered = [];
  String _selectedType = 'all';
  bool _isLoading = true;

  static const _typeFilters = [
    ('all', 'All Partners', Icons.handshake),
    ('church', 'Churches', Icons.church),
    ('police', 'Police / DOVVSU', Icons.local_police),
    ('hospital', 'Hospitals', Icons.local_hospital),
    ('counselor', 'Counselors', Icons.psychology),
    ('shelter', 'Shelters', Icons.home),
    ('legal', 'Legal Aid', Icons.gavel),
    ('ngo', 'NGOs', Icons.volunteer_activism),
  ];

  static const _typeColors = {
    'church': Color(0xFF7B1FA2),
    'police': Color(0xFF1565C0),
    'hospital': Color(0xFFC62828),
    'counselor': Color(0xFF2E7D32),
    'shelter': Color(0xFFE65100),
    'legal': Color(0xFF283593),
    'ngo': Color(0xFF00838F),
    'other': Color(0xFF546E7A),
  };

  static const _typeIcons = {
    'church': Icons.church,
    'police': Icons.local_police,
    'hospital': Icons.local_hospital,
    'counselor': Icons.psychology,
    'shelter': Icons.home,
    'legal': Icons.gavel,
    'ngo': Icons.volunteer_activism,
    'other': Icons.business,
  };

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final partners = await _service.getAllPartners();
    if (mounted) {
      setState(() {
        _all = partners;
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        final matchesType =
            _selectedType == 'all' || p.type == _selectedType;
        final matchesSearch = q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.region.toLowerCase().contains(q) ||
            p.services.any((s) => s.toLowerCase().contains(q));
        return matchesType && matchesSearch;
      }).toList();
    });
  }

  Color _colorFor(String type) =>
      _typeColors[type] ?? const Color(0xFF546E7A);

  IconData _iconFor(String type) =>
      _typeIcons[type] ?? Icons.business;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partners Directory'),
        backgroundColor: BeaconColors.vibrantOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTypeFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildPartnerCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showPartnerForm(null),
              backgroundColor: BeaconColors.vibrantOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Partner'),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final beaconPartners = _all.where((p) => p.isBeaconPartner).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: BeaconColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.handshake, color: Colors.white, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Partners',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_all.length} organisations · $beaconPartners Beacon partners',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, service, region...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilter();
                  },
                )
              : null,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _typeFilters.map((filter) {
          final (type, label, icon) = filter;
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(icon,
                  size: 14,
                  color: isSelected ? Colors.white : BeaconColors.deepCharcoal),
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedType = type);
                _applyFilter();
              },
              selectedColor: BeaconColors.vibrantOrange,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPartnerCard(Partner partner) {
    final color = _colorFor(partner.type);
    final icon = _iconFor(partner.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PartnerDetailScreen(partner: partner)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            partner.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            maxLines: 2,
                          ),
                        ),
                        if (partner.isBeaconPartner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: BeaconColors.vibrantOrange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Partner',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        if (partner.isVerified && !partner.isBeaconPartner)
                          const Icon(Icons.verified,
                              color: Color(0xFF1565C0), size: 16),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(partner.typeLabel,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_outlined,
                            size: 11, color: Colors.grey[500]),
                        Text(
                          partner.region,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      partner.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _actionChip(
                          icon: Icons.phone,
                          label: 'Call',
                          color: const Color(0xFF2E7D32),
                          onTap: () => _launchPhone(partner.phone),
                        ),
                        if (partner.whatsapp != null) ...[
                          const SizedBox(width: 6),
                          _actionChip(
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => _launchWhatsApp(
                                partner.whatsapp!),
                          ),
                        ],
                        if (partner.website != null) ...[
                          const SizedBox(width: 6),
                          _actionChip(
                            icon: Icons.language,
                            label: 'Website',
                            color: BeaconColors.vibrantOrange,
                            onTap: () =>
                                _launchUrl(partner.website!),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showPartnerForm(partner),
                      child: const Icon(Icons.edit_outlined,
                          color: BeaconColors.vibrantOrange, size: 18),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _confirmDelete(partner),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No partners found',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Try a different search or filter',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Partner partner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Partner?'),
        content: Text('Remove "${partner.name}" from the directory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deletePartner(partner.id);
      _load();
    }
  }

  void _showPartnerForm(Partner? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PartnerFormSheet(
        existing: existing,
        onSaved: _load,
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Partner Add / Edit Form ──────────────────────────────────────────────────

class _PartnerFormSheet extends StatefulWidget {
  final Partner? existing;
  final VoidCallback onSaved;
  const _PartnerFormSheet({this.existing, required this.onSaved});

  @override
  State<_PartnerFormSheet> createState() => _PartnerFormSheetState();
}

class _PartnerFormSheetState extends State<_PartnerFormSheet> {
  final _service = PartnerService();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  String _type = 'ngo';
  bool _isBeaconPartner = false;
  bool _isVerified = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final p = widget.existing!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _addressCtrl.text = p.address;
      _regionCtrl.text = p.region;
      _phoneCtrl.text = p.phone;
      _whatsappCtrl.text = p.whatsapp ?? '';
      _emailCtrl.text = p.email ?? '';
      _websiteCtrl.text = p.website ?? '';
      _hoursCtrl.text = p.hours ?? '';
      _type = p.type;
      _isBeaconPartner = p.isBeaconPartner;
      _isVerified = p.isVerified;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _regionCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final partner = Partner(
      id: widget.existing?.id ?? _service.generateId(),
      name: _nameCtrl.text.trim(),
      type: _type,
      description: _descCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      region: _regionCtrl.text.trim().isEmpty ? 'Ghana' : _regionCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      hours: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
      services: const [],
      isVerified: _isVerified,
      isBeaconPartner: _isBeaconPartner,
    );
    await _service.addPartner(partner);
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.add_circle,
                    color: BeaconColors.vibrantOrange),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Edit Partner' : 'Add Partner',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Organisation Name *', Icons.business),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _decor('Type', Icons.category),
              items: PartnerService.partnerTypes
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t[0].toUpperCase() + t.substring(1))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'ngo'),
            ),
            const SizedBox(height: 10),
            _field(_phoneCtrl, 'Phone *', Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _field(_whatsappCtrl, 'WhatsApp Number', Icons.chat,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _field(_addressCtrl, 'Address', Icons.location_on),
            const SizedBox(height: 10),
            _field(_regionCtrl, 'Region', Icons.map),
            const SizedBox(height: 10),
            _field(_emailCtrl, 'Email', Icons.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _field(_websiteCtrl, 'Website', Icons.language,
                keyboardType: TextInputType.url),
            const SizedBox(height: 10),
            _field(_hoursCtrl, 'Hours (e.g. Mon–Fri 8am–5pm)', Icons.schedule),
            const SizedBox(height: 10),
            _field(_descCtrl, 'Description', Icons.description,
                maxLines: 3),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Beacon Partner'),
              subtitle: const Text('Officially partnered with Beacon'),
              value: _isBeaconPartner,
              onChanged: (v) => setState(() => _isBeaconPartner = v),
              activeColor: BeaconColors.vibrantOrange,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Verified'),
              subtitle: const Text('Verified and active organisation'),
              value: _isVerified,
              onChanged: (v) => setState(() => _isVerified = v),
              activeColor: const Color(0xFF1565C0),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BeaconColors.vibrantOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Save Changes' : 'Add Partner'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decor(label, icon),
    );
  }

  InputDecoration _decor(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: BeaconColors.vibrantOrange, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: BeaconColors.vibrantOrange, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}
