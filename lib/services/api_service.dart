import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Phase 3 API connector — v3.8 TEST BUILD ONLY.
///
/// This is NOT the Phase 2 demo build (v3.7). v3.7 stays safe
/// on the user's phone. This build talks to the friend's
/// Django backend (delivered 2026-10-27) instead of mock data.
///
/// BEFORE RUNNING ON A REAL PHONE, CHANGE THIS ONE LINE:
///   1. On the PC running Django, run `ipconfig` and find
///      the IPv4 Address, e.g. 192.168.0.105
///   2. Put that address here, e.g.
///      'http://192.168.0.105:8000'
///   3. On the PC, run Django with
///      `python manage.py runserver 0.0.0.0:8000`
///      (plain `runserver` only listens on 127.0.0.1, which
///      a phone cannot reach)
///   4. In the backend's settings.py, add that same IP to
///      ALLOWED_HOSTS, e.g.
///      ALLOWED_HOSTS = ['127.0.0.1', 'localhost', '192.168.0.105']
///      then restart Django.
///   5. Connect the phone directly to home Wi-Fi for this
///      test (the Meizu is normally on the Flip hotspot
///      subnet, which may not reach the PC's LAN IP).
///
/// Emulator instead of a real phone? Use
/// 'http://10.0.2.2:8000' — on an emulator, 127.0.0.1
/// means the emulator itself, not the PC.
///
/// Backend contract (friend's Django, verified 2026-10-27):
///   POST /register/  {name, email, password} -> {access, refresh, user}
///   POST /login/     {email, password}       -> {access, refresh, user}
///   POST /refresh/   {refresh}               -> {access}
///   GET    /api/transactions/          -> list, newest first
///   POST   /api/transactions/          -> create
///   PUT    /api/transactions/<id>/     -> full update
///   DELETE /api/transactions/<id>/     -> delete
/// Every transaction call needs
/// `Authorization: Bearer <access token>`.
/// Access tokens last 30 minutes; on a 401 this code tries
/// one refresh (7-day refresh token) and retries once.
///
/// Payment methods — the one mapping the app must do:
///   App display string        Backend code
///   'Cash'                     'cash'
///   'bKash'                    'bkash'
///   'Debit card •• 1842'      'debit_card'
///   'Bank transfer'            'bank_transfer'
/// Sending the display strings as-is gets a 400 from DRF
/// (payment_method has choices). So toJson for the API is
/// built here by hand, and fromJson results are mapped
/// back to display strings for the UI.
const String apiBaseUrl = 'http://192.168.0.103:8000';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

String _paymentToBackend(String? display) {
  switch (display) {
    case 'Cash':
      return 'cash';
    case 'bKash':
      return 'bkash';
    case 'Debit card •• 1842':
      return 'debit_card';
    case 'Bank transfer':
      return 'bank_transfer';
    default:
      // Unknown / null: send null (backend allows blank)
      // rather than a string DRF would reject with 400.
      return '';
  }
}

String? _paymentFromBackend(String? code) {
  switch (code) {
    case 'cash':
      return 'Cash';
    case 'bkash':
      return 'bKash';
    case 'debit_card':
      return 'Debit card •• 1842';
    case 'bank_transfer':
      return 'Bank transfer';
    case null:
      return null;
    default:
      return code;
  }
}

class ApiService {
  static String? accessToken;
  static String? refreshToken;

  static void clearTokens() {
    accessToken = null;
    refreshToken = null;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  static String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        if (body['detail'] is String) return body['detail'] as String;
        if (body['detail'] is List && (body['detail'] as List).isNotEmpty) {
          return (body['detail'] as List).first.toString();
        }
        // DRF field errors, e.g. {"email": ["..."]}
        final first = body.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
    } catch (_) {}
    return 'Server error (${response.statusCode}). '
        'Is Django running, and is the LAN IP in api_service.dart correct?';
  }

  /// Login. Returns the display name for the Home greeting.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    accessToken = body['access'] as String?;
    refreshToken = body['refresh'] as String?;
    final user = body['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Student';
    return local[0].toUpperCase() + local.substring(1);
  }

  /// Sign up. Returns the display name for the Home greeting.
  static Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );
    if (response.statusCode != 201) {
      throw ApiException(_errorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    accessToken = body['access'] as String?;
    refreshToken = body['refresh'] as String?;
    return name.trim();
  }

  static Future<bool> _tryRefresh() async {
    final refresh = refreshToken;
    if (refresh == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      accessToken = body['access'] as String?;
      return accessToken != null;
    } catch (_) {
      return false;
    }
  }

  /// Run a request, retrying once after a token refresh on 401.
  static Future<http.Response> _withRefresh(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await request();
    }
    return response;
  }
}

/// The Phase 3 repository: same interface as
/// MockTransactionRepository, so no screen changes.
/// Screens still compute every total from the list this
/// returns — the backend is never asked for totals.
class ApiTransactionRepository implements TransactionRepository {
  Map<String, dynamic> _toApiBody(Transaction t) {
    final payment = _paymentToBackend(t.paymentMethod);
    return {
      'title': t.title,
      'amount': t.amount.toStringAsFixed(2),
      'transaction_type': t.type.name,
      'category': t.category.name,
      'date': t.date.toIso8601String().split('T').first,
      // Omit the key entirely when there is no payment
      // method, instead of sending an empty string.
      if (payment.isNotEmpty) 'payment_method': payment,
    };
  }

  Transaction _fromApi(Map<String, dynamic> json) {
    final parsed = Transaction.fromJson(json);
    return parsed.copyWith(
      paymentMethod: _paymentFromBackend(json['payment_method'] as String?),
    );
  }

  List<Transaction> _parseList(String body) {
    final decoded = jsonDecode(body);
    final List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && decoded['results'] is List) {
      items = decoded['results'] as List;
    } else {
      items = [];
    }
    return items
        .map((e) => _fromApi(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Transaction>> fetchAll() async {
    // No token yet (app just opened, user not logged in):
    // return empty, do not throw — the Login screen is
    // showing anyway, and login will load for real.
    if (ApiService.accessToken == null) return [];
    try {
      final response = await ApiService._withRefresh(
        () => http.get(
          Uri.parse('$apiBaseUrl/api/transactions/'),
          headers: ApiService._headers,
        ),
      );
      if (response.statusCode != 200) {
        throw ApiException(ApiService._errorMessage(response));
      }
      return _parseList(response.body);
    } catch (e) {
      if (e is ApiException) rethrow;
      // Network down / wrong LAN IP / Django not running:
      // surface it as a readable error, not a crash.
      throw ApiException(
        'Could not reach the backend at $apiBaseUrl. '
        'Is Django running with runserver 0.0.0.0:8000, '
        'and is the LAN IP correct?',
      );
    }
  }

  @override
  Future<Transaction> add(Transaction transaction) async {
    final response = await ApiService._withRefresh(
      () => http.post(
        Uri.parse('$apiBaseUrl/api/transactions/'),
        headers: ApiService._headers,
        body: jsonEncode(_toApiBody(transaction)),
      ),
    );
    if (response.statusCode != 201) {
      throw ApiException(ApiService._errorMessage(response));
    }
    return _fromApi(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final response = await ApiService._withRefresh(
      () => http.put(
        Uri.parse('$apiBaseUrl/api/transactions/${transaction.id}/'),
        headers: ApiService._headers,
        body: jsonEncode(_toApiBody(transaction)),
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(ApiService._errorMessage(response));
    }
    return _fromApi(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    final response = await ApiService._withRefresh(
      () => http.delete(
        Uri.parse('$apiBaseUrl/api/transactions/$id/'),
        headers: ApiService._headers,
      ),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(ApiService._errorMessage(response));
    }
  }
}
