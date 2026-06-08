import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/clothing_api_item.dart';

/// AI 옷장 백엔드 API 클라이언트
///
/// iOS 시뮬레이터에서 localhost:8000 으로 바로 접근합니다.
/// 실기기 사용 시 baseUrl을 Mac 로컬 IP로 변경하세요.
class ClosetApiClient {
  static const String baseUrl = 'http://localhost:8000';

  /// [imageFile]을 백엔드에 업로드하고 task_id를 반환합니다.
  ///
  /// POST /clothing/upload
  static Future<String> uploadClothing({
    required File imageFile,
    int userId = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/clothing/upload');
    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId.toString();
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: _mediaTypeOf(imageFile.path), // MIME 타입 명시
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 202) {
      throw ApiException(
        '업로드 실패 (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['task_id'] as String;
  }

  /// 파이프라인 처리 상태를 조회합니다.
  ///
  /// GET /pipeline/status/{taskId}
  static Future<PipelineStatus> getPipelineStatus(String taskId) async {
    final uri = Uri.parse('$baseUrl/pipeline/status/$taskId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        '상태 조회 실패 (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PipelineStatus.fromJson(json);
  }

  /// 사용자의 의류 목록을 조회합니다.
  ///
  /// GET /clothing/?user_id={userId}
  static Future<List<ClothingApiItem>> getClothingList({int userId = 1}) async {
    final uri = Uri.parse('$baseUrl/clothing/').replace(
      queryParameters: {'user_id': userId.toString()},
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        '목록 조회 실패 (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ClothingListResponse.fromJson(json).items;
  }

  /// 백엔드에서 서빙하는 이미지의 전체 URL을 반환합니다.
  ///
  /// imageUrl 예: "storage/crops/xxx.jpg"
  /// → http://localhost:8000/storage/crops/xxx.jpg
  static String imageFullUrl(String imageUrl) => '$baseUrl/$imageUrl';
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// 파일 경로의 확장자를 기반으로 MIME MediaType을 반환합니다.
///
/// iOS image_picker는 .jpg / .png / .heic 등을 반환할 수 있습니다.
/// 백엔드 허용 타입: image/jpeg, image/png, image/webp
MediaType _mediaTypeOf(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return MediaType('image', 'png');
    case 'webp':
      return MediaType('image', 'webp');
    case 'jpg':
    case 'jpeg':
    case 'heic': // iOS HEIC → jpeg로 폴백 (imageQuality 지정 시 jpeg 변환됨)
    default:
      return MediaType('image', 'jpeg');
  }
}
