import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://fal.run/fal-ai/flux-pro/v1.1-ultra/image-to-image');
  // Wait, let me try https://fal.run/fal-ai/flux-pro/kontext first.
  final urlKontext = Uri.parse('https://fal.run/fal-ai/flux-pro/kontext');
  
  final falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  final referenceUrl = 'https://upload.wikimedia.org/wikipedia/commons/4/48/Outdoors-man-portrait_%28cropped%29.jpg';
  
  try {
    final response = await http.post(
      urlKontext,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Key $falKey',
      },
      body: jsonEncode({
        'prompt': 'Transform into professional studio headshot, soft lighting, neutral background, 85mm portrait',
        'image_url': referenceUrl,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
