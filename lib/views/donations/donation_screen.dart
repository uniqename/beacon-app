import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/beacon_division.dart';

class DonationScreen extends StatelessWidget {
  final BeaconDivision division;
  final int? suggestedAmount;

  const DonationScreen({
    super.key,
    required this.division,
    this.suggestedAmount,
  });

  static const String _donationUrl = 'https://beaconnewbeginnings.org/donate';
  static const Color _primary = Color(0xFFF0562D);

  Future<void> _openDonationPage(BuildContext context) async {
    final uri = Uri.parse(_donationUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open donation page. Please visit beaconnewbeginnings.org/donate'),
          ),
        );
      }
    }
  }

  Future<void> _openEmail() async {
    await launchUrl(Uri.parse(
      'mailto:info@beaconnewbeginnings.org?subject=Donation%20Enquiry',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: const Text('Support Beacon'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildImpactText(),
            const SizedBox(height: 32),
            _buildDonateButton(context),
            const SizedBox(height: 8),
            Text(
              'beaconnewbeginnings.org/donate',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 32),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildEmailCard(),
            const SizedBox(height: 32),
            _buildNonprofitDisclaimer(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0562D), Color(0xFFD44010)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 52),
          const SizedBox(height: 14),
          const Text(
            'Your Generosity\nMakes a Difference',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            division.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactText() {
    return Text(
      'Every contribution directly supports survivors of domestic violence '
      'and trauma — providing shelter, counselling, legal aid, and a path '
      'to healing and independence.',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
    );
  }

  Widget _buildDonateButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openDonationPage(context),
      icon: const Icon(Icons.open_in_browser, size: 22),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Donate on Our Website',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Other ways to give',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _primary.withValues(alpha: 0.1),
          child: const Icon(Icons.email_outlined, color: _primary),
        ),
        title: const Text(
          'Contact Us to Give',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('info@beaconnewbeginnings.org'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: _openEmail,
      ),
    );
  }

  Widget _buildNonprofitDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Beacon of New Beginnings is a registered non-profit organisation. '
              'All donations are voluntary and charitable. Donors receive no digital '
              'content or app features in return. All app features are free to all users.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
