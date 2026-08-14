import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://fal.run/fal-ai/instantid/standard');
  final falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  
  final referenceUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg';
  
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Key $falKey',
      },
      body: jsonEncode({
        'prompt': 'A professional corporate headshot',
        'face_image_url': referenceUrl,
        'image_size': 'portrait_4_3',
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
