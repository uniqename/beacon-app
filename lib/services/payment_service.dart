import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/payment_result.dart';

/// Service for handling payment processing through various gateways
/// Supports: Flutterwave (Cards, Mobile Money), PayPal
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // API Keys (loaded from .env)
  String? _flutterwavePublicKey;
  String? _flutterwaveSecretKey;
  String? _flutterwaveEncryptionKey;
  String? _paypalClientId;
  String? _paypalSecret;
  bool _isInitialized = false;

  /// Initialize payment service and load API keys from environment
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('💳 [Payment] Already initialized');
      return;
    }

    try {
      developer.log('💳 [Payment] Initializing payment service...');

      // Load API keys from .env
      _flutterwavePublicKey = dotenv.env['FLUTTERWAVE_PUBLIC_KEY'];
      _flutterwaveSecretKey = dotenv.env['FLUTTERWAVE_SECRET_KEY'];
      _flutterwaveEncryptionKey = dotenv.env['FLUTTERWAVE_ENCRYPTION_KEY'];
      _paypalClientId = dotenv.env['PAYPAL_CLIENT_ID'];
      _paypalSecret = dotenv.env['PAYPAL_SECRET'];

      // Validate Flutterwave keys
      if (_flutterwavePublicKey == null || _flutterwavePublicKey!.isEmpty) {
        developer.log('⚠️ [Payment] Flutterwave public key not found in .env');
      }
      if (_flutterwaveSecretKey == null || _flutterwaveSecretKey!.isEmpty) {
        developer.log('⚠️ [Payment] Flutterwave secret key not found in .env');
      }

      // Validate PayPal keys
      if (_paypalClientId == null || _paypalClientId!.isEmpty) {
        developer.log('⚠️ [Payment] PayPal client ID not found in .env');
      }

      _isInitialized = true;
      developer.log('✅ [Payment] Payment service initialized successfully');
    } catch (e) {
      developer.log('❌ [Payment] Failed to initialize: $e');
      _isInitialized = false;
    }
  }

  /// Process card payment through Flutterwave
  ///
  /// Supports Visa, Mastercard, Verve cards
  /// Works for both USD and GHS currencies
  Future<PaymentResult> processCardPayment({
    required BuildContext context,
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerName,
    String? customerPhone,
    String? description,
    String? transactionRef,
  }) async {
    try {
      developer.log('💳 [Payment] Processing card payment: $currency $amount');

      // Ensure initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Validate API keys
      if (_flutterwavePublicKey == null || _flutterwavePublicKey!.isEmpty) {
        return PaymentResult.failure(
          message: 'Payment gateway not configured. Please contact support.',
        );
      }

      // Generate transaction reference if not provided
      final String txRef = transactionRef ??
          'TXN-${DateTime.now().millisecondsSinceEpoch}';

      // Create Flutterwave customer
      final customer = Customer(
        name: customerName,
        phoneNumber: customerPhone ?? '',
        email: customerEmail,
      );

      // Create Flutterwave request
      final Flutterwave flutterwave = Flutterwave(
        publicKey: _flutterwavePublicKey!,
        currency: currency,
        redirectUrl: 'https://beaconnewbeginnings.org/payment/callback',
        txRef: txRef,
        amount: amount.toString(),
        customer: customer,
        paymentOptions: 'card',
        customization: Customization(
          title: 'Beacon of New Beginnings',
          description: description ?? 'Donation',
          logo: 'https://beaconnewbeginnings.org/logo.png',
        ),
        isTestMode: _flutterwavePublicKey!.contains('TEST'), // Auto-detect test mode
      );

      // Initiate payment
      developer.log('💳 [Payment] Launching Flutterwave payment UI...');
      final ChargeResponse response = await flutterwave.charge(context);

      // Process response
      if (response.success == true) {
        developer.log('✅ [Payment] Card payment successful: ${response.transactionId}');

        // Verify payment on backend (important for security)
        final bool verified = await verifyFlutterwavePayment(
          response.transactionId ?? '',
        );

        if (verified) {
          return PaymentResult.success(
            transactionId: response.transactionId ?? txRef,
            message: 'Payment completed successfully',
            rawResponse: {
              'tx_ref': response.txRef,
              'transaction_id': response.transactionId,
              'status': response.status,
            },
          );
        } else {
          return PaymentResult.failure(
            message: 'Payment verification failed. Please contact support.',
            rawResponse: {'tx_ref': response.txRef},
          );
        }
      } else {
        developer.log('❌ [Payment] Card payment failed: ${response.status}');
        return PaymentResult.failure(
          message: 'Payment ${response.status ?? "failed"}. Please try again.',
          rawResponse: {
            'tx_ref': response.txRef,
            'status': response.status,
          },
        );
      }
    } catch (e) {
      developer.log('❌ [Payment] Card payment error: $e');
      return PaymentResult.failure(
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }

  /// Process Mobile Money payment through Flutterwave
  ///
  /// Supports: MTN Mobile Money, Vodafone Cash, AirtelTigo Money
  /// Only works for GHS currency
  Future<PaymentResult> processMomoPayment({
    required BuildContext context,
    required double amount,
    required String phoneNumber,
    required String network, // 'MTN', 'VODAFONE', 'TIGO'
    required String customerEmail,
    String? customerName,
    String? description,
    String? transactionRef,
  }) async {
    try {
      developer.log('📱 [Payment] Processing MoMo payment: GHS $amount via $network');

      // Ensure initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Validate API keys
      if (_flutterwavePublicKey == null || _flutterwavePublicKey!.isEmpty) {
        return PaymentResult.failure(
          message: 'Payment gateway not configured. Please contact support.',
        );
      }

      // Generate transaction reference if not provided
      final String txRef = transactionRef ??
          'MOMO-${DateTime.now().millisecondsSinceEpoch}';

      // Validate phone number (Ghana format)
      if (!_isValidGhanaPhone(phoneNumber)) {
        return PaymentResult.failure(
          message: 'Invalid phone number. Please use Ghana format (e.g., 0241234567)',
        );
      }

      // Create Flutterwave customer
      final customer = Customer(
        name: customerName ?? 'Anonymous Donor',
        phoneNumber: phoneNumber,
        email: customerEmail,
      );

      // Create Flutterwave request with Mobile Money
      final Flutterwave flutterwave = Flutterwave(
        publicKey: _flutterwavePublicKey!,
        currency: 'GHS', // MoMo only supports GHS
        redirectUrl: 'https://beaconnewbeginnings.org/payment/callback',
        txRef: txRef,
        amount: amount.toString(),
        customer: customer,
        paymentOptions: 'mobilemoneyghana',
        customization: Customization(
          title: 'Beacon of New Beginnings',
          description: description ?? 'Donation',
          logo: 'https://beaconnewbeginnings.org/logo.png',
        ),
        isTestMode: _flutterwavePublicKey!.contains('TEST'),
      );

      // Initiate payment
      developer.log('📱 [Payment] Launching Flutterwave MoMo UI...');
      final ChargeResponse response = await flutterwave.charge(context);

      // Process response
      if (response.success == true) {
        developer.log('✅ [Payment] MoMo payment successful: ${response.transactionId}');

        // Verify payment
        final bool verified = await verifyFlutterwavePayment(
          response.transactionId ?? '',
        );

        if (verified) {
          return PaymentResult.success(
            transactionId: response.transactionId ?? txRef,
            message: 'Mobile Money payment completed successfully',
            rawResponse: {
              'tx_ref': response.txRef,
              'transaction_id': response.transactionId,
              'status': response.status,
              'network': network,
              'phone': phoneNumber,
            },
          );
        } else {
          return PaymentResult.failure(
            message: 'Payment verification failed. Please contact support.',
            rawResponse: {'tx_ref': response.txRef},
          );
        }
      } else {
        developer.log('❌ [Payment] MoMo payment failed: ${response.status}');
        return PaymentResult.failure(
          message: 'Mobile Money payment ${response.status ?? "failed"}. Please try again.',
          rawResponse: {
            'tx_ref': response.txRef,
            'status': response.status,
          },
        );
      }
    } catch (e) {
      developer.log('❌ [Payment] MoMo payment error: $e');
      return PaymentResult.failure(
        message: 'Mobile Money payment failed: ${e.toString()}',
      );
    }
  }

  /// Process PayPal payment
  ///
  /// Opens PayPal checkout UI in webview
  /// Supports USD and other international currencies
  Future<PaymentResult> processPayPalPayment({
    required BuildContext context,
    required double amount,
    required String currency,
    required String description,
    String? transactionRef,
  }) async {
    try {
      developer.log('🅿️ [Payment] Processing PayPal payment: $currency $amount');

      // Ensure initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Validate API keys
      if (_paypalClientId == null || _paypalClientId!.isEmpty) {
        return PaymentResult.failure(
          message: 'PayPal not configured. Please contact support.',
        );
      }

      // Generate transaction reference if not provided
      final String txRef = transactionRef ??
          'PP-${DateTime.now().millisecondsSinceEpoch}';

      // PayPal will be implemented via a Completer to handle async navigation
      PaymentResult? result;

      // Navigate to PayPal checkout
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => PaypalCheckoutView(
            sandboxMode: _paypalClientId!.contains('sandbox'), // Auto-detect sandbox
            clientId: _paypalClientId!,
            secretKey: _paypalSecret ?? '',
            transactions: [
              {
                "amount": {
                  "total": amount.toStringAsFixed(2),
                  "currency": currency,
                  "details": {
                    "subtotal": amount.toStringAsFixed(2),
                    "shipping": '0',
                    "shipping_discount": 0
                  }
                },
                "description": description,
                "item_list": {
                  "items": [
                    {
                      "name": "Donation to Beacon of New Beginnings",
                      "quantity": 1,
                      "price": amount.toStringAsFixed(2),
                      "currency": currency
                    }
                  ],
                }
              }
            ],
            note: "Thank you for your generous donation!",
            onSuccess: (Map params) async {
              developer.log('✅ [Payment] PayPal payment successful: ${params['paymentId']}');
              result = PaymentResult.success(
                transactionId: params['paymentId'] ?? txRef,
                message: 'PayPal payment completed successfully',
                rawResponse: Map<String, dynamic>.from(params),
              );
            },
            onError: (error) {
              developer.log('❌ [Payment] PayPal payment error: $error');
              result = PaymentResult.failure(
                message: 'PayPal payment failed: $error',
              );
            },
            onCancel: () {
              developer.log('⚠️ [Payment] PayPal payment cancelled by user');
              result = PaymentResult.failure(
                message: 'Payment cancelled',
              );
            },
          ),
        ),
      );

      // Return result or default failure if null
      return result ?? PaymentResult.failure(
        message: 'Payment was cancelled or incomplete',
      );
    } catch (e) {
      developer.log('❌ [Payment] PayPal payment error: $e');
      return PaymentResult.failure(
        message: 'PayPal payment failed: ${e.toString()}',
      );
    }
  }

  /// Verify Flutterwave payment transaction
  ///
  /// SECURITY NOTE: This implementation calls Flutterwave API directly from the client.
  /// For optimal security, verification should be done server-side (backend API).
  /// However, this client-side verification is significantly better than no verification.
  ///
  /// Production-grade approach:
  /// 1. Client initiates payment with Flutterwave
  /// 2. Client receives transaction ID
  /// 3. Client calls YOUR backend: POST /api/verify-payment { transaction_id }
  /// 4. Backend verifies with Flutterwave using SECRET key (never exposed to client)
  /// 5. Backend returns verification status to client
  Future<bool> verifyFlutterwavePayment(String transactionId) async {
    try {
      developer.log('🔍 [Payment] Verifying transaction: $transactionId');

      if (transactionId.isEmpty) {
        developer.log('❌ [Payment] Invalid transaction ID');
        return false;
      }

      // Validate secret key is available
      if (_flutterwaveSecretKey == null || _flutterwaveSecretKey!.isEmpty) {
        developer.log('❌ [Payment] Secret key not configured');
        return false;
      }

      // Call Flutterwave verification endpoint
      final url = Uri.parse(
        'https://api.flutterwave.com/v3/transactions/$transactionId/verify',
      );

      developer.log('🔍 [Payment] Calling Flutterwave verification API...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_flutterwaveSecretKey',
          'Content-Type': 'application/json',
        },
      );

      developer.log('🔍 [Payment] Verification response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check response status
        if (data['status'] == 'success') {
          final transactionData = data['data'];
          final status = transactionData['status'];
          final amount = transactionData['amount'];
          final currency = transactionData['currency'];

          developer.log('🔍 [Payment] Transaction status: $status');
          developer.log('🔍 [Payment] Amount: $currency $amount');

          // Verify payment was successful
          if (status == 'successful') {
            developer.log('✅ [Payment] Payment verified successfully');
            return true;
          } else {
            developer.log('❌ [Payment] Payment not successful: $status');
            return false;
          }
        } else {
          developer.log('❌ [Payment] Verification API returned error: ${data['message']}');
          return false;
        }
      } else {
        developer.log('❌ [Payment] Verification failed with status ${response.statusCode}');
        developer.log('❌ [Payment] Response: ${response.body}');
        return false;
      }
    } catch (e) {
      developer.log('❌ [Payment] Verification error: $e');
      return false;
    }
  }

  /// Process Paystack card/bank payment
  ///
  /// Initialises a transaction via Paystack API, then opens the
  /// authorization_url in an external browser.  The caller should
  /// call [verifyPaystackPayment] after the user returns.
  Future<PaymentResult> processPaystackPayment({
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerName,
    String? description,
    String? transactionRef,
  }) async {
    try {
      developer.log('💳 [Payment] Processing Paystack payment: $currency $amount');

      // Ensure initialized
      if (!_isInitialized) {
        await initialize();
      }

      final secretKey = dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';
      if (secretKey.isEmpty) {
        return PaymentResult.failure(
          message: 'Paystack not configured. Please contact support.',
        );
      }

      final String txRef =
          transactionRef ?? 'PS-${DateTime.now().millisecondsSinceEpoch}';

      final int amountInPesewas = (amount * 100).round();

      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': customerEmail,
          'amount': amountInPesewas,
          'currency': currency,
          'reference': txRef,
          'callback_url': 'https://beaconnewbeginnings.org/payment/callback',
          'metadata': {
            'name': customerName,
            'description': description ?? 'Donation',
          },
        }),
      );

      developer.log('💳 [Payment] Paystack init response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final authUrl = data['data']['authorization_url'] as String;
          final reference = data['data']['reference'] as String;

          final uri = Uri.parse(authUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          developer.log('✅ [Payment] Paystack browser launched for $reference');
          return PaymentResult(
            success: false,
            isPending: true,
            transactionId: reference,
            message:
                'Payment opened in browser. Tap Verify below when done.',
          );
        } else {
          return PaymentResult.failure(
            message: data['message'] ?? 'Paystack initialisation failed.',
          );
        }
      } else {
        return PaymentResult.failure(
          message: 'Paystack error (${response.statusCode}). Please try again.',
        );
      }
    } catch (e) {
      developer.log('❌ [Payment] Paystack payment error: $e');
      return PaymentResult.failure(
        message: 'Paystack payment failed: ${e.toString()}',
      );
    }
  }

  /// Verify a Paystack transaction by reference
  Future<PaymentResult> verifyPaystackPayment(String reference) async {
    try {
      developer.log('🔍 [Payment] Verifying Paystack transaction: $reference');

      final secretKey = dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';
      if (secretKey.isEmpty) {
        return PaymentResult.failure(
          message: 'Paystack not configured. Please contact support.',
        );
      }

      final response = await http.get(
        Uri.parse(
            'https://api.paystack.co/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/json',
        },
      );

      developer.log(
          '🔍 [Payment] Paystack verify response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true &&
            data['data']['status'] == 'success') {
          developer.log('✅ [Payment] Paystack payment verified: $reference');
          return PaymentResult.success(
            transactionId: reference,
            message: 'Payment verified successfully',
            rawResponse: Map<String, dynamic>.from(data['data']),
          );
        } else {
          final status = data['data']?['status'] ?? data['message'] ?? 'failed';
          developer.log('❌ [Payment] Paystack payment not successful: $status');
          return PaymentResult.failure(
            message: 'Payment not successful (status: $status). Please try again.',
            rawResponse: data['data'] != null
                ? Map<String, dynamic>.from(data['data'])
                : null,
          );
        }
      } else {
        return PaymentResult.failure(
          message:
              'Verification error (${response.statusCode}). Please try again.',
        );
      }
    } catch (e) {
      developer.log('❌ [Payment] Paystack verification error: $e');
      return PaymentResult.failure(
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Validate Ghana phone number format
  bool _isValidGhanaPhone(String phone) {
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Ghana format: 10 digits starting with 0, or 12 digits starting with 233
    final regex1 = RegExp(r'^0[2-5][0-9]{8}$'); // 0241234567
    final regex2 = RegExp(r'^233[2-5][0-9]{8}$'); // 233241234567

    return regex1.hasMatch(cleaned) || regex2.hasMatch(cleaned);
  }

  /// Get supported Mobile Money networks in Ghana
  List<String> getSupportedMoMoNetworks() {
    return ['MTN', 'VODAFONE', 'AIRTELTIGO'];
  }

  /// Check if payment service is ready
  bool get isInitialized => _isInitialized;

  /// Check if Flutterwave is configured
  bool get isFlutterwaveConfigured =>
      _flutterwavePublicKey != null && _flutterwavePublicKey!.isNotEmpty;

  /// Check if PayPal is configured
  bool get isPayPalConfigured =>
      _paypalClientId != null && _paypalClientId!.isNotEmpty;

  /// Check if in test mode
  bool get isTestMode =>
      _flutterwavePublicKey?.contains('TEST') == true ||
      _paypalClientId?.contains('sandbox') == true;
}
