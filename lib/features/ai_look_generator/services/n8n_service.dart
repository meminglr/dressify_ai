import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/generation_request.dart';
import 'n8n_exception.dart';

/// Service responsible for communicating with the n8n virtual try-on webhooks.
///
/// Supports two endpoints:
/// - **Single garment** (`/webhook/tryon-test`): flat payload with one garment
/// - **Multi garment** (`/webhook/tryon-multi`): array payload with 1–5 garments
///
/// The correct endpoint is selected automatically based on the number of garments
/// in the [GenerationRequest]. Uses [Dio] for HTTP communication and implements
/// a singleton pattern so the same client instance is reused across the app.
///
/// Usage:
/// ```dart
/// final result = await N8nService.instance.generateLook(request: request);
/// final imageUrl = result['image_url'] as String;
/// ```
class N8nService {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const String _baseUrl = 'https://n8n.emniva.com';

  /// Endpoint for single-garment try-on.
  static const String _singleEndpoint = '/webhook/tryon-test';

  /// Endpoint for multi-garment try-on (1–5 garments).
  static const String _multiEndpoint = '/webhook/tryon-multi';

  static const Duration _timeout = Duration(seconds: 180);

  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static N8nService? _instance;

  /// Returns the shared [N8nService] instance, creating it on first access.
  static N8nService get instance => _instance ??= N8nService._();

  /// Private constructor — use [N8nService.instance] instead.
  N8nService._() : _dio = _buildDio();

  // ---------------------------------------------------------------------------
  // HTTP client
  // ---------------------------------------------------------------------------

  final Dio _dio;

  /// Builds a [Dio] instance pre-configured with base URL and timeouts.
  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sends a virtual try-on generation request to the appropriate n8n webhook.
  ///
  /// Automatically selects the endpoint based on garment count:
  /// - 1 garment → `/webhook/tryon-test` (single-garment endpoint)
  /// - 2–5 garments → `/webhook/tryon-multi` (multi-garment endpoint)
  ///
  /// Returns a map with:
  /// - `success` (bool) — whether the generation succeeded
  /// - `image_url` (String) — public URL of the generated look image
  /// - `media_id` (String) — storage media ID for the generated image
  ///
  /// Throws [N8nException] on any error (network, timeout, API, or unexpected).
  Future<Map<String, dynamic>> generateLook({
    required GenerationRequest request,
  }) async {
    final isSingle = request.garments.length == 1;
    final endpoint = isSingle ? _singleEndpoint : _multiEndpoint;
    final payload = isSingle ? _buildSinglePayload(request) : request.toJson();

    debugPrint(
      'N8nService: sending ${isSingle ? "single" : "multi"} request '
      'for user ${request.userId} (${request.garments.length} garment(s))',
    );

    try {
      final response = await _dio.post<String>(
        endpoint,
        data: jsonEncode(payload),
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Expect HTTP 200 for success
      if (response.statusCode != 200) {
        debugPrint('N8nService: unexpected status ${response.statusCode}');
        throw N8nException('Sunucu hatası. Lütfen tekrar deneyin');
      }

      // Parse JSON body
      final Map<String, dynamic> data =
          jsonDecode(response.data ?? '{}') as Map<String, dynamic>;

      // Validate API-level success flag
      if (data['success'] != true) {
        debugPrint('N8nService: API returned success=false — $data');
        throw N8nException('Look oluşturulamadı. Lütfen tekrar deneyin');
      }

      // Validate required fields
      final imageUrl = data['image_url'] as String?;
      final mediaId = data['media_id'];
      
      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint('N8nService: missing or empty image_url in response — $data');
        throw N8nException('Görüntü URL\'si alınamadı. Lütfen tekrar deneyin');
      }
      
      if (mediaId == null) {
        debugPrint('N8nService: missing media_id in response — $data');
        throw N8nException('Medya ID\'si alınamadı. Lütfen tekrar deneyin');
      }

      debugPrint(
        'N8nService: generation succeeded, media_id=$mediaId, image_url=$imageUrl',
      );
      return data;
    } on N8nException {
      rethrow;
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      debugPrint('N8nService: unexpected error — $e');
      throw N8nException('Bir hata oluştu: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Payload builders
  // ---------------------------------------------------------------------------

  /// Builds the flat payload for the single-garment endpoint.
  ///
  /// Single endpoint format:
  /// ```json
  /// {
  ///   "user_id": "...",
  ///   "person_image_url": "...",
  ///   "garment_image_url": "...",
  ///   "product_category": "Tişört",
  ///   "product_name": "..."   // optional
  /// }
  /// ```
  Map<String, dynamic> _buildSinglePayload(GenerationRequest request) {
    final garment = request.garments.first;
    return {
      'user_id': request.userId,
      'person_image_url': request.personImageUrl,
      'garment_image_url': garment.imageUrl,
      'product_category': garment.category,
      if (garment.productName != null) 'product_name': garment.productName,
    };
  }

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  /// Maps [DioException] types to user-friendly [N8nException] messages.
  ///
  /// Always throws — never returns normally.
  Never _handleDioException(DioException e) {
    debugPrint('N8nService: DioException type=${e.type} — ${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        throw N8nException('İstek zaman aşımına uğradı');

      case DioExceptionType.connectionError:
        throw N8nException('İnternet bağlantınızı kontrol edin');

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        debugPrint('N8nService: bad response status=$status');
        throw N8nException('Sunucu hatası. Lütfen tekrar deneyin');

      default:
        throw N8nException('Bir hata oluştu: ${e.message ?? e.toString()}');
    }
  }
}
