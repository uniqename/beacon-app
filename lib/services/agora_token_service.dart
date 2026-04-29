import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// Service for generating and fetching Agora RTC tokens
///
/// In production, tokens should be generated server-side for security.
/// This service communicates with a token server (e.g., Cloudflare Worker)
/// to fetch tokens for joining Agora channels.
///
/// ## Security Note
/// Never include your Agora App Certificate in the mobile app.
/// Always generate tokens server-side.
///
/// ## Token Server Setup
/// Deploy the included Cloudflare Worker (see /docs/agora-token-worker.js)
/// or implement your own token server following Agora's token generation guide.
class AgoraTokenService {
  final String tokenServerUrl;
  final Duration tokenCacheDuration;

  // Cache tokens to avoid unnecessary network calls
  final Map<String, _CachedToken> _tokenCache = {};

  AgoraTokenService({
    required this.tokenServerUrl,
    this.tokenCacheDuration = const Duration(minutes: 30),
  });

  /// Fetch an Agora token for joining a channel
  ///
  /// [channelName] - The channel to join
  /// [userId] - User ID (will be hashed to int for Agora UID)
  /// [role] - 'speaker' (publisher) or 'listener' (subscriber)
  /// [expirationSeconds] - How long the token should be valid (default: 3600s = 1 hour)
  ///
  /// Returns the token string, or null if fetching fails
  Future<String?> fetchToken({
    required String channelName,
    required String userId,
    required String role, // 'speaker' or 'listener'
    int expirationSeconds = 3600,
  }) async {
    try {
      // Check cache first
      final cacheKey = '$channelName:$userId:$role';
      final cached = _tokenCache[cacheKey];

      if (cached != null && !cached.isExpired) {
        developer.log('AgoraTokenService: Using cached token for $cacheKey');
        return cached.token;
      }

      // Convert userId to UID (Agora uses int UIDs)
      final uid = userId.hashCode.abs();

      // Prepare request
      final uri = Uri.parse(tokenServerUrl);
      final body = jsonEncode({
        'channelName': channelName,
        'uid': uid,
        'role': role,
        'expirationSeconds': expirationSeconds,
      });

      developer.log('AgoraTokenService: Fetching token for channel: $channelName, uid: $uid, role: $role');

      // Make request to token server
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final expiry = data['expiry'] as int?;

        if (token != null) {
          // Cache the token
          _tokenCache[cacheKey] = _CachedToken(
            token: token,
            expiry: expiry != null
                ? DateTime.fromMillisecondsSinceEpoch(expiry * 1000)
                : DateTime.now().add(Duration(seconds: expirationSeconds)),
          );

          developer.log('AgoraTokenService: Token fetched successfully');
          return token;
        } else {
          developer.log('AgoraTokenService: Token not found in response');
          return null;
        }
      } else {
        developer.log('AgoraTokenService: Server returned error: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('AgoraTokenService: Error fetching token: $e');
      return null;
    }
  }

  /// Clear the token cache
  void clearCache() {
    _tokenCache.clear();
    developer.log('AgoraTokenService: Cache cleared');
  }

  /// Clear expired tokens from cache
  void clearExpiredTokens() {
    _tokenCache.removeWhere((key, value) => value.isExpired);
    developer.log('AgoraTokenService: Expired tokens cleared');
  }

  /// Get a token for a speaker (broadcaster) role
  Future<String?> fetchSpeakerToken({
    required String channelName,
    required String userId,
    int expirationSeconds = 3600,
  }) {
    return fetchToken(
      channelName: channelName,
      userId: userId,
      role: 'speaker',
      expirationSeconds: expirationSeconds,
    );
  }

  /// Get a token for a listener (subscriber) role
  Future<String?> fetchListenerToken({
    required String channelName,
    required String userId,
    int expirationSeconds = 3600,
  }) {
    return fetchToken(
      channelName: channelName,
      userId: userId,
      role: 'listener',
      expirationSeconds: expirationSeconds,
    );
  }
}

/// Cached token with expiration tracking
class _CachedToken {
  final String token;
  final DateTime expiry;

  _CachedToken({
    required this.token,
    required this.expiry,
  });

  /// Check if token is expired (with 5-minute buffer)
  bool get isExpired {
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }
}

/// For development/testing: Generate tokens without a server
///
/// ⚠️ WARNING: DO NOT USE IN PRODUCTION
/// This is a simplified token generation for testing only.
/// In production, always generate tokens server-side to protect your App Certificate.
class AgoraTokenDevelopmentHelper {
  /// Generate a simple test token (development only)
  ///
  /// This is NOT secure and should only be used for local testing.
  /// For production, deploy a proper token server.
  static String generateTestToken(String channelName, int uid) {
    // This is a placeholder. In development, you can:
    // 1. Leave token as empty string (works if App Certificate is disabled in Agora console)
    // 2. Use a test token generated from Agora console
    // 3. Deploy a local token server
    return ''; // Empty token works when App Certificate is disabled
  }

  /// Check if token generation is available
  static bool isAvailable = false;
}

/*
===============================================================================
CLOUDFLARE WORKER DEPLOYMENT GUIDE
===============================================================================

Follow these steps to deploy the Agora token server to Cloudflare Workers (FREE):

## Prerequisites
1. Cloudflare account (free tier is sufficient)
2. Node.js installed
3. Agora App ID and App Certificate from Agora console

## Step 1: Install Wrangler CLI
```bash
npm install -g wrangler
wrangler login
```

## Step 2: Create Worker Project
```bash
mkdir agora-token-worker
cd agora-token-worker
npm init -y
npm install agora-access-token
```

## Step 3: Create Worker Script (index.js)
```javascript
import { RtcTokenBuilder, RtcRole } from 'agora-access-token';

export default {
  async fetch(request, env) {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only allow POST
    if (request.method !== 'POST') {
      return new Response('Method not allowed', {
        status: 405,
        headers: corsHeaders,
      });
    }

    try {
      // Parse request
      const { channelName, uid, role, expirationSeconds } = await request.json();

      // Validate inputs
      if (!channelName || uid === undefined || !role) {
        return new Response(JSON.stringify({ error: 'Missing required fields' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Get credentials from environment variables
      const appId = env.AGORA_APP_ID;
      const appCertificate = env.AGORA_APP_CERTIFICATE;

      if (!appId || !appCertificate) {
        return new Response(JSON.stringify({ error: 'Server configuration error' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Calculate expiration
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const expirationTime = expirationSeconds || 3600;
      const privilegeExpiredTs = currentTimestamp + expirationTime;

      // Determine role
      const userRole = role === 'speaker'
        ? RtcRole.PUBLISHER
        : RtcRole.SUBSCRIBER;

      // Generate token
      const token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid,
        userRole,
        privilegeExpiredTs
      );

      // Return token
      return new Response(JSON.stringify({
        token,
        expiry: privilegeExpiredTs,
        channelName,
        uid,
        role,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (error) {
      console.error('Token generation error:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  }
};
```

## Step 4: Create wrangler.toml
```toml
name = "agora-token-worker"
main = "index.js"
compatibility_date = "2024-01-01"

[vars]
# Add non-sensitive vars here

# Don't put secrets in this file! Use 'wrangler secret put' instead
```

## Step 5: Add Secrets (DO NOT commit these!)
```bash
# Set Agora App ID
wrangler secret put AGORA_APP_ID
# Enter your App ID when prompted

# Set Agora App Certificate
wrangler secret put AGORA_APP_CERTIFICATE
# Enter your App Certificate when prompted
```

## Step 6: Deploy
```bash
wrangler deploy
```

You'll get a URL like: https://agora-token-worker.<your-subdomain>.workers.dev

## Step 7: Update .env in Flutter App
```env
AGORA_TOKEN_SERVER_URL=https://agora-token-worker.<your-subdomain>.workers.dev
```

## Testing the Worker
```bash
curl -X POST https://agora-token-worker.<your-subdomain>.workers.dev \
  -H "Content-Type: application/json" \
  -d '{
    "channelName": "test-channel",
    "uid": 12345,
    "role": "speaker",
    "expirationSeconds": 3600
  }'
```

Expected response:
```json
{
  "token": "006...<long token string>",
  "expiry": 1234567890,
  "channelName": "test-channel",
  "uid": 12345,
  "role": "speaker"
}
```

## Cost
- Cloudflare Workers FREE tier: 100,000 requests/day
- More than enough for a support group app
- No credit card required for free tier

===============================================================================
*/
