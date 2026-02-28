import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Real image comparison service for dispute resolution.
/// Compares complaint photo vs delivery photo using actual pixel analysis
/// instead of random similarity scores.
class ImageComparisonService {
  static final ImageComparisonService instance = ImageComparisonService._();
  ImageComparisonService._();

  /// Compare two images by sending them to the Python ML Backend
  Future<Map<String, dynamic>> compareImages(
      File image1, File image2) async {
    try {
      // Connect to the Flask Python API running locally
      // For physical device testing, you may need to replace localhost with your computer's local IP (e.g., 192.168.1.x)
      final uri = Uri.parse('http://10.0.2.2:5000/compare'); 

      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(await http.MultipartFile.fromPath(
        'image1',
         image1.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'image2',
         image2.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return {
          'similarity': data['similarity'],
          'cosine_similarity': data['cosine_similarity'],
          'structural_similarity': data['structural_similarity'],
          'verdict': data['verdict'],
          'description': data['description'],
          'method': 'resnet18_ml',
          // Assuming max refund is 500, we use the modifier returned by Python
          'refundAmount': 500.0 * (data['refund_modifier'] as num).toDouble(),
        };
      } else {
        print('Python ML Backend Error: ${response.statusCode}');
        return {'similarity': 50.0, 'method': 'error', 'verdict': 'manual_review', 'refundAmount': 0.0};
      }
    } catch (e) {
      print('Exception calling python ML API: $e');
      return {'similarity': 50.0, 'method': 'error', 'verdict': 'manual_review', 'refundAmount': 0.0};
    }
  }
}
