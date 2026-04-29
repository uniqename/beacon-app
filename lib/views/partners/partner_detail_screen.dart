import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/partner.dart';
import '../../constants/brand_colors.dart';

class PartnerDetailScreen extends StatelessWidget {
  final Partner partner;

  const PartnerDetailScreen({super.key, required this.partner});

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

  Color get _color => _typeColors[partner.type] ?? const Color(0xFF546E7A);
  IconData get _icon => _typeIcons[partner.type] ?? Icons.business;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: _color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_color, _color.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 8),
                      if (partner.isBeaconPartner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.handshake,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Beacon Partner',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              title: Text(
                partner.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
              ),
              titlePadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type + region chips
                  Row(
                    children: [
                      _chip(partner.typeLabel, _color),
                      const SizedBox(width: 8),
                      _chip(
                        partner.region,
                        BeaconColors.deepCharcoal,
                        icon: Icons.location_on,
                      ),
                      if (partner.isVerified) ...[
                        const SizedBox(width: 8),
                        _chip('Verified',
                            const Color(0xFF1565C0),
                            icon: Icons.verified),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    partner.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // ── Contact Information ─────────────────────────────
                  _sectionTitle('Contact Information'),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _contactRow(
                          icon: Icons.phone,
                          label: partner.phone,
                          color: const Color(0xFF2E7D32),
                          onTap: () => _call(partner.phone),
                          actionLabel: 'Call',
                        ),
                        if (partner.phone2 != null)
                          _contactRow(
                            icon: Icons.phone_forwarded,
                            label: partner.phone2!,
                            color: const Color(0xFF2E7D32),
                            onTap: () => _call(partner.phone2!),
                            actionLabel: 'Call',
                          ),
                        if (partner.whatsapp != null)
                          _contactRow(
                            icon: Icons.chat,
                            label: 'WhatsApp: ${partner.whatsapp}',
                            color: const Color(0xFF25D366),
                            onTap: () => _whatsapp(partner.whatsapp!),
                            actionLabel: 'Open',
                          ),
                        if (partner.email != null)
                          _contactRow(
                            icon: Icons.email,
                            label: partner.email!,
                            color: BeaconColors.vibrantOrange,
                            onTap: () => _email(partner.email!),
                            actionLabel: 'Email',
                          ),
                        if (partner.website != null)
                          _contactRow(
                            icon: Icons.language,
                            label: partner.website!,
                            color: const Color(0xFF1565C0),
                            onTap: () => _url(partner.website!),
                            actionLabel: 'Visit',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Address ─────────────────────────────────────────
                  _sectionTitle('Address'),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.location_on,
                          color: BeaconColors.vibrantOrange),
                      title: Text(partner.address),
                      subtitle: Text(partner.region),
                      trailing: OutlinedButton.icon(
                        onPressed: () => _directions(partner),
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BeaconColors.vibrantOrange,
                          side: const BorderSide(
                              color: BeaconColors.vibrantOrange),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                    ),
                  ),

                  // ── Hours ────────────────────────────────────────────
                  if (partner.hours != null) ...[
                    const SizedBox(height: 20),
                    _sectionTitle('Hours of Operation'),
                    const SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.schedule,
                            color: BeaconColors.vibrantOrange),
                        title: Text(partner.hours!),
                      ),
                    ),
                  ],

                  // ── Services ─────────────────────────────────────────
                  if (partner.services.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle('Services Offered'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: partner.services
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _color.withValues(alpha: 0.25)),
                                ),
                                child: Text(s,
                                    style: TextStyle(
                                        color: _color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // ── Action buttons ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _call(partner.phone),
                      icon: const Icon(Icons.phone),
                      label: Text('Call ${partner.name}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (partner.whatsapp != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _whatsapp(partner.whatsapp!),
                        icon: const Icon(Icons.chat),
                        label: const Text('Message on WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(
                              color: Color(0xFF25D366)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: BeaconColors.deepCharcoal),
      );

  Widget _chip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required String actionLabel,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: color),
        child: Text(actionLabel),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _email(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _url(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _directions(Partner p) async {
    final query = Uri.encodeComponent('${p.name}, ${p.address}, ${p.region}, Ghana');
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
