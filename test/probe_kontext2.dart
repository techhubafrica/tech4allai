import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final urlKontext = Uri.parse('https://fal.run/fal-ai/flux-pro/kontext');
  
  final falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  // Let's try base64 encoding or just a simple image.
  final referenceUrl = 'https://raw.githubusercontent.com/falserverless/fal-js/main/packages/fal/test/fixtures/pizza.jpg';
  
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
