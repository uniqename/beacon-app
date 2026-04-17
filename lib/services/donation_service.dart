import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/donation.dart';
import '../models/payment_result.dart';
import 'payment_service.dart';
import 'local_database_service.dart';

/// Service for managing donations and receipts
///
/// Handles donation creation, payment processing, receipt generation,
/// and donation history queries
class DonationService {
  static final DonationService _instance = DonationService._internal();
  factory DonationService() => _instance;
  DonationService._internal();

  final PaymentService _paymentService = PaymentService();
  final Uuid _uuid = const Uuid();

  /// Create a new donation record in pending state
  Future<Donation> createDonation({
    required String? userId,
    required String? divisionId,
    required double amount,
    required String currency,
    required DonationFrequency frequency,
    required PaymentMethod paymentMethod,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    bool isAnonymous = false,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      developer.log('💰 [Donation] Creating donation: $currency $amount');

      final donation = Donation(
        id: _uuid.v4(),
        userId: userId,
        divisionId: divisionId,
        amount: amount,
        currency: currency,
        frequency: frequency,
        paymentMethod: paymentMethod,
        paymentGateway: _determinePaymentGateway(paymentMethod),
        status: DonationStatus.pending,
        donorName: isAnonymous ? null : donorName,
        donorEmail: isAnonymous ? null : donorEmail,
        donorPhone: isAnonymous ? null : donorPhone,
        isAnonymous: isAnonymous,
        isRecurring: frequency == DonationFrequency.monthly,
        nextBillingDate: frequency == DonationFrequency.monthly
            ? DateTime.now().add(const Duration(days: 30))
            : null,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Save to database
      final db = await LocalDatabaseService.database;
      await db.insert(
        'donations',
        donation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      developer.log('✅ [Donation] Donation created: ${donation.id}');
      return donation;
    } catch (e) {
      developer.log('❌ [Donation] Failed to create donation: $e');
      rethrow;
    }
  }

  /// Process donation payment through appropriate gateway
  Future<PaymentResult> processDonationPayment({
    required BuildContext context,
    required Donation donation,
  }) async {
    try {
      developer.log('💳 [Donation] Processing payment for donation: ${donation.id}');

      PaymentResult result;

      // Route to appropriate payment method
      switch (donation.paymentMethod) {
        case PaymentMethod.card:
        case PaymentMethod.applePay:
        case PaymentMethod.googlePay:
          // All card-based payments go through Flutterwave
          result = await _paymentService.processCardPayment(
            context: context,
            amount: donation.amount,
            currency: donation.currency,
            customerEmail: donation.donorEmail ?? 'anonymous@beaconnewbeginnings.org',
            customerName: donation.donorName ?? 'Anonymous Donor',
            customerPhone: donation.donorPhone,
            description: 'Donation to Beacon of New Beginnings',
            transactionRef: 'DON-${donation.id}',
          );
          break;

        case PaymentMethod.momo:
          // Mobile Money for Ghana
          if (donation.currency != 'GHS') {
            return PaymentResult.failure(
              message: 'Mobile Money only supports GHS currency',
            );
          }
          if (donation.donorPhone == null || donation.donorPhone!.isEmpty) {
            return PaymentResult.failure(
              message: 'Phone number is required for Mobile Money',
            );
          }
          result = await _paymentService.processMomoPayment(
            context: context,
            amount: donation.amount,
            phoneNumber: donation.donorPhone!,
            network: donation.metadata?['momo_network'] ?? 'MTN',
            customerEmail: donation.donorEmail ?? 'anonymous@beaconnewbeginnings.org',
            customerName: donation.donorName ?? 'Anonymous Donor',
            description: 'Donation to Beacon of New Beginnings',
            transactionRef: 'DON-${donation.id}',
          );
          break;

        case PaymentMethod.paypal:
          // PayPal integration
          result = await _paymentService.processPayPalPayment(
            context: context,
            amount: donation.amount,
            currency: donation.currency,
            description: 'Donation to Beacon of New Beginnings',
            transactionRef: 'DON-${donation.id}',
          );
          break;

        case PaymentMethod.bankTransfer:
          // Bank transfer requires manual processing
          return PaymentResult.failure(
            message: 'Bank transfer requires manual processing. Please contact support.',
          );
      }

      // Update donation status based on payment result
      if (result.success) {
        await updateDonationStatus(
          donation.id,
          DonationStatus.completed,
          transactionId: result.transactionId,
          completedAt: DateTime.now(),
        );

        // Generate receipt
        if (donation.donorEmail != null && donation.donorEmail!.isNotEmpty) {
          try {
            await generateReceipt(donation.id);
          } catch (e) {
            developer.log('⚠️ [Donation] Failed to generate receipt: $e');
            // Don't fail the whole transaction if receipt generation fails
          }
        }
      } else {
        await updateDonationStatus(
          donation.id,
          DonationStatus.failed,
        );
      }

      return result;
    } catch (e) {
      developer.log('❌ [Donation] Payment processing error: $e');
      await updateDonationStatus(
        donation.id,
        DonationStatus.failed,
      );
      return PaymentResult.failure(
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }

  /// Update donation status
  Future<bool> updateDonationStatus(
    String donationId,
    DonationStatus status, {
    String? transactionId,
    DateTime? completedAt,
  }) async {
    try {
      developer.log('📝 [Donation] Updating donation $donationId to status: $status');

      final db = await LocalDatabaseService.database;
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
      };

      if (transactionId != null) {
        updates['transaction_id'] = transactionId;
      }
      if (completedAt != null) {
        updates['completed_at'] = completedAt.toIso8601String();
      }

      final count = await db.update(
        'donations',
        updates,
        where: 'id = ?',
        whereArgs: [donationId],
      );

      developer.log('✅ [Donation] Updated $count donation(s)');
      return count > 0;
    } catch (e) {
      developer.log('❌ [Donation] Failed to update donation: $e');
      return false;
    }
  }

  /// Generate PDF receipt for donation
  Future<String?> generateReceipt(String donationId) async {
    try {
      developer.log('📄 [Donation] Generating receipt for donation: $donationId');

      // Get donation details
      final donation = await getDonation(donationId);
      if (donation == null) {
        developer.log('❌ [Donation] Donation not found');
        return null;
      }

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BEACON OF NEW BEGINNINGS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Donation Receipt',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Receipt Details
                pw.Text(
                  'Receipt Number: ${donation.transactionId ?? donation.id}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Date: ${donation.completedAt?.toLocal().toString().split('.')[0] ?? donation.createdAt.toLocal().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 30),

                // Donor Information
                pw.Text(
                  'Donor Information',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Name: ${donation.isAnonymous ? "Anonymous Donor" : donation.donorName ?? "N/A"}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (!donation.isAnonymous && donation.donorEmail != null)
                  pw.Text(
                    'Email: ${donation.donorEmail}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                pw.SizedBox(height: 30),

                // Donation Details
                pw.Text(
                  'Donation Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Amount:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      donation.formattedAmount,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Method:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      donation.paymentMethod.toString().split('.').last.toUpperCase(),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Frequency:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      donation.frequency.toString().split('.').last,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Thank you message
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Thank You!',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Your generous donation helps us support domestic violence survivors in Ghana. Together, we are making a difference.',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Footer
                pw.Text(
                  'This is an official receipt for your donation to Beacon of New Beginnings NGO.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'For questions, please contact: support@beaconnewbeginnings.org',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to device storage
      final directory = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${directory.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final file = File('${receiptsDir.path}/receipt_${donation.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      final receiptPath = file.path;
      developer.log('✅ [Donation] Receipt generated: $receiptPath');

      // Update donation with receipt URL
      final db = await LocalDatabaseService.database;
      await db.update(
        'donations',
        {'receipt_url': receiptPath},
        where: 'id = ?',
        whereArgs: [donationId],
      );

      // In production, you would also email the receipt here
      // await _emailReceipt(donation, file);

      return receiptPath;
    } catch (e) {
      developer.log('❌ [Donation] Failed to generate receipt: $e');
      return null;
    }
  }

  /// Get single donation by ID
  Future<Donation?> getDonation(String donationId) async {
    try {
      final db = await LocalDatabaseService.database;
      final results = await db.query(
        'donations',
        where: 'id = ?',
        whereArgs: [donationId],
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return Donation.fromMap(results.first);
    } catch (e) {
      developer.log('❌ [Donation] Failed to get donation: $e');
      return null;
    }
  }

  /// Get all donations for a user
  Future<List<Donation>> getUserDonations(String userId) async {
    try {
      final db = await LocalDatabaseService.database;
      final results = await db.query(
        'donations',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => Donation.fromMap(map)).toList();
    } catch (e) {
      developer.log('❌ [Donation] Failed to get user donations: $e');
      return [];
    }
  }

  /// Get all donations (admin only)
  Future<List<Donation>> getAllDonations({
    DonationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final db = await LocalDatabaseService.database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (status != null) {
        whereClause = 'status = ?';
        whereArgs.add(status.toString().split('.').last);
      }

      if (startDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final results = await db.query(
        'donations',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map((map) => Donation.fromMap(map)).toList();
    } catch (e) {
      developer.log('❌ [Donation] Failed to get donations: $e');
      return [];
    }
  }

  /// Get donation statistics
  Future<Map<String, dynamic>> getDonationStats() async {
    try {
      final db = await LocalDatabaseService.database;

      // Total donations
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count, SUM(amount) as total, currency FROM donations WHERE status = ? GROUP BY currency',
        [DonationStatus.completed.toString().split('.').last],
      );

      // Donations by division
      final byDivisionResult = await db.rawQuery(
        'SELECT division_id, COUNT(*) as count, SUM(amount) as total FROM donations WHERE status = ? GROUP BY division_id',
        [DonationStatus.completed.toString().split('.').last],
      );

      // Recent donations (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM donations WHERE status = ? AND created_at >= ?',
        [DonationStatus.completed.toString().split('.').last, thirtyDaysAgo.toIso8601String()],
      );

      return {
        'total_by_currency': totalResult,
        'by_division': byDivisionResult,
        'recent_count': recentResult.isNotEmpty ? recentResult.first['count'] : 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ [Donation] Failed to get donation stats: $e');
      return {};
    }
  }

  /// Open Paystack browser checkout and return a pending PaymentResult
  Future<PaymentResult> processPaystackPayment({
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerName,
    String? description,
    String? transactionRef,
  }) async {
    return _paymentService.processPaystackPayment(
      amount: amount,
      currency: currency,
      customerEmail: customerEmail,
      customerName: customerName,
      description: description,
      transactionRef: transactionRef,
    );
  }

  /// Verify a Paystack transaction by reference
  Future<PaymentResult> verifyPaystackPayment(String reference) async {
    return _paymentService.verifyPaystackPayment(reference);
  }

  /// Determine payment gateway based on payment method
  PaymentGateway? _determinePaymentGateway(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
      case PaymentMethod.momo:
      case PaymentMethod.applePay:
      case PaymentMethod.googlePay:
        return PaymentGateway.flutterwave;
      case PaymentMethod.paypal:
        return PaymentGateway.paypal;
      case PaymentMethod.bankTransfer:
        return null;
    }
  }
}
