import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final endpoints = [
    'https://fal.run/fal-ai/flux/dev/image-to-image',
    'https://fal.run/fal-ai/flux-pro/v1.1-ultra/image-to-image',
    'https://fal.run/fal-ai/flux-pro/image-to-image',
  ];
  
  final falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  final referenceUrl = 'https://upload.wikimedia.org/wikipedia/commons/4/48/Outdoors-man-portrait_%28cropped%29.jpg';
  
  for (final urlString in endpoints) {
    try {
      final response = await http.post(
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $falKey',
        },
        body: jsonEncode({
          'prompt': 'Transform into professional studio headshot',
          'image_url': referenceUrl,
        }),
      );

      print('----------');
      print('Endpoint: $urlString');
      print('Status: ${response.statusCode}');
    } catch (e) {
      print('Error on $urlString: $e');
    }
  }
}
