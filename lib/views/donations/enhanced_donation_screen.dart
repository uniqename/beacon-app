import 'package:flutter/material.dart';
import '../../models/beacon_division.dart';
import 'donation_screen.dart';

/// Alias kept for backward compatibility with existing navigation calls.
/// All donation collection now happens via the external website.
class EnhancedDonationScreen extends StatelessWidget {
  final BeaconDivision division;
  final int? suggestedAmount;

  const EnhancedDonationScreen({
    super.key,
    required this.division,
    this.suggestedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return DonationScreen(division: division, suggestedAmount: suggestedAmount);
  }
}
