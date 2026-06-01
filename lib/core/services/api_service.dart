import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://api.example.com'; // Placeholder base URL

  Future<Map<String, dynamic>> generateAIPlan(Map<String, String> setupData) async {
    // Simulated API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, you would do:
    // final response = await http.post(
    //   Uri.parse('$baseUrl/ai-plan'),
    //   body: jsonEncode(setupData),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // return jsonDecode(response.body);

    return {
      'status': 'success',
      'poses': [
        {
          'id': 1,
          'instruction': 'Stand 8 ft from camera · Turn body 30° left · Keep chin slightly up · Best with side light',
          'type': 'Full body',
        },
        {
          'id': 2,
          'instruction': 'Walk slowly toward camera · Relax one arm · Great for candid travel feel',
          'type': 'Natural',
        }
      ]
    };
  }

  Future<Map<String, dynamic>> checkCompliance(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'status': 'success',
      'face_centered': true,
      'background_acceptable': true,
      'head_size_in_range': false,
    };
  }
}
