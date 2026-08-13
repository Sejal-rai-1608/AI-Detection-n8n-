import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Configurable Webhook Constant (Replace with your actual n8n webhook URL)
  static const String WEBHOOK_URL =
      "https://n8n-latest-d7l3.onrender.com/webhook-test/truthlens";
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Helper to send POST requests

  /// Verify text news content via n8n webhook
  Future<Map<String, dynamic>> verifyNews(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse(WEBHOOK_URL),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"type": "news", "text": text}),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bodyText = response.body;
        if (bodyText.isEmpty) {
          throw Exception("Empty response from server.");
        }

        // Attempt to decode as JSON
        try {
          final decoded = jsonDecode(bodyText);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else if (decoded is List && decoded.isNotEmpty) {
            final first = decoded.first;
            if (first is Map<String, dynamic>) {
              return first;
            }
          }
        } catch (_) {
          // If JSON decoding fails, treat it as plain text
        }

        // Return plain text wrapped in a map
        return {"textResponse": bodyText};
      } else {
        throw Exception(
          "Server responded with status code: ${response.statusCode}",
        );
      }
    } on TimeoutException {
      throw Exception(
        "Connection timed out. Please check your n8n workflow server.",
      );
    } on http.ClientException catch (e) {
      throw Exception("Network connection error: ${e.message}");
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw Exception(
          "Cannot reach n8n server. Verify internet connection and webhook URL.",
        );
      }
      throw Exception(
        "Verification failed: ${e.toString().replaceAll("Exception: ", "")}",
      );
    }
  }

  /// Verify image forensics via n8n webhook using Multipart request
  Future<Map<String, dynamic>> verifyImage(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(WEBHOOK_URL));

      // Detect media type
      final lowerName = filename.toLowerCase();
      MediaType mediaType;
      if (lowerName.endsWith('.png')) {
        mediaType = MediaType('image', 'png');
      } else if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
        mediaType = MediaType('image', 'jpeg');
      } else if (lowerName.endsWith('.gif')) {
        mediaType = MediaType('image', 'gif');
      } else if (lowerName.endsWith('.webp')) {
        mediaType = MediaType('image', 'webp');
      } else {
        mediaType = MediaType('image', 'jpeg'); // default fallback
      }

      // Add the file from bytes (works on all platforms including web)
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: mediaType,
        ),
      );

      // Add other fields if needed
      request.fields['type'] = 'image';

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';

        // Scenario 1: Binary Image File is returned directly
        if (contentType.contains('image/') ||
            contentType.contains('application/octet-stream')) {
          return {
            "processed_image_bytes": response.bodyBytes,
            "status": "Suspicious",
            "confidence": 85.0,
            "reason": "Processed image returned from n8n",
          };
        }

        // Scenario 2: JSON Response is returned
        Map<String, dynamic> resultData;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            resultData = decoded;
          } else if (decoded is List && decoded.isNotEmpty) {
            resultData = decoded.first as Map<String, dynamic>;
          } else {
            throw Exception("Invalid response format.");
          }
        } catch (e) {
          // Fallback check: if JSON decoding fails but response body is raw image bytes
          if (response.bodyBytes.isNotEmpty &&
              ((response.bodyBytes.length > 2 &&
                      response.bodyBytes[0] == 0xFF &&
                      response.bodyBytes[1] == 0xD8) ||
                  (response.bodyBytes.length > 4 &&
                      response.bodyBytes[0] == 0x89 &&
                      response.bodyBytes[1] == 0x50))) {
            return {
              "processed_image_bytes": response.bodyBytes,
              "status": "Suspicious",
              "confidence": 85.0,
              "reason": "Processed image returned from n8n",
            };
          }
          rethrow;
        }

        // Check if there is an image field in the JSON (base64 string)
        if (resultData.containsKey("image") && resultData["image"] is String) {
          final String imgStr = resultData["image"];
          if (imgStr.isNotEmpty) {
            try {
              String base64Data = imgStr;
              if (imgStr.contains("base64,")) {
                base64Data = imgStr.split("base64,")[1];
              }
              final decodedBytes = base64Decode(base64Data.trim());
              resultData["processed_image_bytes"] = decodedBytes;
            } catch (_) {
              // Ignore if not valid base64
            }
          }
        }

        return resultData;
      } else {
        throw Exception(
          "Server responded with status code: ${response.statusCode}",
        );
      }
    } on TimeoutException {
      throw Exception(
        "Connection timed out. Please check your n8n workflow server.",
      );
    } on http.ClientException catch (e) {
      throw Exception("Network connection error: ${e.message}");
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw Exception(
          "Cannot reach n8n server. Verify internet connection and webhook URL.",
        );
      }
      throw Exception(
        "Verification failed: ${e.toString().replaceAll("Exception: ", "")}",
      );
    }
  }

  /// Verify URL domain credibility via n8n webhook
  Future<Map<String, dynamic>> verifyUrl(String url) async {
    try {
      final response = await http
          .post(
            Uri.parse(WEBHOOK_URL),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"type": "url", "url": url}),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bodyText = response.body;
        if (bodyText.isEmpty) {
          throw Exception("Empty response from server.");
        }

        // Attempt to decode as JSON
        try {
          final decoded = jsonDecode(bodyText);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else if (decoded is List && decoded.isNotEmpty) {
            final first = decoded.first;
            if (first is Map<String, dynamic>) {
              return first;
            }
          }
        } catch (_) {
          // If JSON decoding fails, treat it as plain text
        }

        // Return plain text wrapped in a map
        return {"textResponse": bodyText};
      } else {
        throw Exception(
          "Server responded with status code: ${response.statusCode}",
        );
      }
    } on TimeoutException {
      throw Exception(
        "Connection timed out. Please check your n8n workflow server.",
      );
    } on http.ClientException catch (e) {
      throw Exception("Network connection error: ${e.message}");
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw Exception(
          "Cannot reach n8n server. Verify internet connection and webhook URL.",
        );
      }
      throw Exception(
        "Verification failed: ${e.toString().replaceAll("Exception: ", "")}",
      );
    }
  }

  /// Verify video content/forensics via n8n webhook using Multipart request
  Future<Map<String, dynamic>> verifyVideo(
    Uint8List bytes,
    String filename,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = http.MultipartRequest('POST', Uri.parse(WEBHOOK_URL));

      // Detect media type
      final lowerName = filename.toLowerCase();
      MediaType mediaType;
      if (lowerName.endsWith('.mp4')) {
        mediaType = MediaType('video', 'mp4');
      } else if (lowerName.endsWith('.mov')) {
        mediaType = MediaType('video', 'quicktime');
      } else if (lowerName.endsWith('.avi')) {
        mediaType = MediaType('video', 'x-msvideo');
      } else if (lowerName.endsWith('.mkv')) {
        mediaType = MediaType('video', 'x-matroska');
      } else {
        mediaType = MediaType('video', 'mp4'); // default fallback
      }

      // Sanitize filename to replace spaces and special characters with underscores
      final sanitizedFilename = filename.replaceAll(
        RegExp(r'[^a-zA-Z0-9\.]'),
        '_',
      );

      // Add the file from bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: sanitizedFilename,
          contentType: mediaType,
        ),
      );

      request.fields['type'] = 'video';

      print("=== API REQUEST ===");
      print("Request URL: $WEBHOOK_URL");
      print("Request Method: POST (Multipart)");
      print("Fields: ${request.fields}");
      print("File Name: $filename");
      print("File Size: ${bytes.length} bytes");

      // Increase timeout to 5 minutes to wait for full n8n execution (TwelveLabs upload & analysis)
      final Duration videoTimeout = const Duration(minutes: 5);
      final streamedResponse = await request.send().timeout(videoTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      print("=== API RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response Body Length: ${response.body.length}");
      print("Response Body: ${response.body}");

      if (response.statusCode >= 500) {
        throw Exception(
          "Server Error (500): The server encountered an error while processing the video.",
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          "Server responded with status code: ${response.statusCode}",
        );
      }

      final bodyText = response.body;
      if (bodyText.isEmpty) {
        throw Exception("Empty response from server.");
      }

      Map<String, dynamic> result;
      try {
        final decoded = jsonDecode(bodyText);
        if (decoded is Map<String, dynamic>) {
          result = decoded;
        } else if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map<String, dynamic>) {
            result = first;
          } else {
            throw const FormatException(
              "Decoded list does not contain a JSON object.",
            );
          }
        } else {
          throw const FormatException(
            "Response is not a valid JSON object or list.",
          );
        }
      } on FormatException catch (e) {
        print("=== PARSING ERROR ===");
        print("Invalid JSON: ${e.message}");
        throw Exception(
          "Invalid JSON: The server response could not be parsed as JSON. Details: ${e.message}",
        );
      }

      print("=== PARSED JSON ===");
      print(const JsonEncoder.withIndent('  ').convert(result));
      return result;
    } on TimeoutException {
      print("=== TIMEOUT ERROR ===");
      print("Request timed out after ${stopwatch.elapsed.inSeconds} seconds.");
      throw Exception(
        "Request timed out. The video processing workflow took longer than expected. Please try again or use a smaller video.",
      );
    } on http.ClientException catch (e) {
      print("=== NETWORK ERROR ===");
      print("Network connection error: ${e.message}");
      throw Exception("Network connection error: ${e.message}");
    } catch (e) {
      print("=== UNEXPECTED ERROR ===");
      print("Error details: $e");
      if (e.toString().contains("SocketException")) {
        throw Exception(
          "Cannot reach n8n server. Verify internet connection and webhook URL.",
        );
      }
      throw Exception(
        "Verification failed: ${e.toString().replaceAll("Exception: ", "")}",
      );
    } finally {
      stopwatch.stop();
    }
  }
}
