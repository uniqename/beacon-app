import 'package:flutter/material.dart';
import '../../config/org_config.dart';
import '../../services/app_config_service.dart';

/// Shown once on first launch so the user picks Ghana or United States.
/// After selection the app proceeds to the normal auth flow.
class RegionSelectScreen extends StatefulWidget {
  final VoidCallback onSelected;

  const RegionSelectScreen({super.key, required this.onSelected});

  @override
  State<RegionSelectScreen> createState() => _RegionSelectScreenState();
}

class _RegionSelectScreenState extends State<RegionSelectScreen> {
  String? _selectedKey;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_selectedKey == null) return;
    setState(() => _saving = true);
    await AppConfigService.instance.setConfig(_selectedKey!);
    widget.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Logo / icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0562D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite,
                      color: Color(0xFFF0562D), size: 40),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF221E1F)),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select your country so we can show you the right support resources, emergency numbers, and local services.',
                style: TextStyle(fontSize: 15, color: Colors.grey[600],
                    height: 1.5),
              ),
              const SizedBox(height: 36),
              _OrgCard(
                config: usConfig,
                selected: _selectedKey == 'us',
                onTap: () => setState(() => _selectedKey = 'us'),
                flag: '🇺🇸',
                subtitle: '501(c)(3) Non-profit · United States',
              ),
              const SizedBox(height: 14),
              _OrgCard(
                config: ghanaConfig,
                selected: _selectedKey == 'gh',
                onTap: () => setState(() => _selectedKey = 'gh'),
                flag: '🇬🇭',
                subtitle: 'NGO · Ghana',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_selectedKey == null || _saving) ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0562D),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  final OrgConfig config;
  final bool selected;
  final VoidCallback onTap;
  final String flag;
  final String subtitle;

  const _OrgCard({
    required this.config,
    required this.selected,
    required this.onTap,
    required this.flag,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF0562D).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFF0562D) : Colors.grey[200]!,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[100]!,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.orgName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? const Color(0xFFF0562D)
                          : const Color(0xFF221E1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text(
                    config.orgTagline,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFFF0562D)
                  : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
