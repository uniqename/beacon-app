import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/accessibility_service.dart';
import '../../constants/app_constants.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
      ),
      body: Consumer<AccessibilityService>(
        builder: (context, accessibilityService, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Card(
                color: const Color(AppConstants.warmOffWhiteValue),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.accessibility_new,
                            color: const Color(AppConstants.primaryColorValue),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Adjust settings for better readability',
                              style: TextStyle(
                                fontSize: 16 * accessibilityService.fontSizeMultiplier,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Font Size Section
              Text(
                'Text Size',
                style: TextStyle(
                  fontSize: 20 * accessibilityService.fontSizeMultiplier,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.darkCharcoalValue),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a comfortable reading size',
                style: TextStyle(
                  fontSize: 14 * accessibilityService.fontSizeMultiplier,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Font Size Options
              _buildFontSizeOption(
                context,
                accessibilityService,
                'Small',
                AccessibilityService.fontSizeSmall,
                'Compact text for more content',
              ),
              _buildFontSizeOption(
                context,
                accessibilityService,
                'Normal',
                AccessibilityService.fontSizeNormal,
                'Standard reading size',
              ),
              _buildFontSizeOption(
                context,
                accessibilityService,
                'Large',
                AccessibilityService.fontSizeLarge,
                'Easier to read',
              ),
              _buildFontSizeOption(
                context,
                accessibilityService,
                'Extra Large',
                AccessibilityService.fontSizeExtraLarge,
                'For low vision',
              ),
              _buildFontSizeOption(
                context,
                accessibilityService,
                'Huge',
                AccessibilityService.fontSizeHuge,
                'Maximum readability',
              ),

              const SizedBox(height: 24),

              // Preview Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 16 * accessibilityService.fontSizeMultiplier,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This is how text will appear throughout the app with your current settings.',
                        style: TextStyle(
                          fontSize: 14 * accessibilityService.fontSizeMultiplier,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Beacon of New Beginnings - Walking the path from pain to power, hand in hand.',
                        style: TextStyle(
                          fontSize: 16 * accessibilityService.fontSizeMultiplier,
                          fontWeight: FontWeight.w500,
                          color: const Color(AppConstants.primaryColorValue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Reset Button
              OutlinedButton.icon(
                onPressed: () async {
                  await accessibilityService.resetToDefaults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to default'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Default'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFontSizeOption(
    BuildContext context,
    AccessibilityService service,
    String label,
    double multiplier,
    String description,
  ) {
    final isSelected = (service.fontSizeMultiplier - multiplier).abs() < 0.01;

    return Card(
      color: isSelected
          ? const Color(AppConstants.primaryColorValue).withOpacity(0.1)
          : null,
      child: RadioListTile<double>(
        value: multiplier,
        groupValue: service.fontSizeMultiplier,
        onChanged: (value) {
          if (value != null) {
            service.setFontSize(value);
          }
        },
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16 * multiplier,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 12 * multiplier),
        ),
        activeColor: const Color(AppConstants.primaryColorValue),
      ),
    );
  }
}
