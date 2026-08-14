import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final urlString = 'https://fal.run/fal-ai/nano-banana-pro/edit';
  
  final falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  final referenceUrl = 'https://upload.wikimedia.org/wikipedia/commons/4/48/Outdoors-man-portrait_%28cropped%29.jpg';
  
  try {
    final response = await http.post(
      Uri.parse(urlString),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Key $falKey',
      },
      body: jsonEncode({
        'prompt': 'Change the background to a professional corporate office. INSTRUCTION: PIXEL PRIORITY MODE. Maintain the exact same facial features as the reference images — same eyes, nose shape, jawline contour, and skin texture. IDENTITY LOCK: ABSOLUTE.',
        'image_url': referenceUrl,
      }),
    );

    print('----------');
    print('Endpoint: $urlString');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error on $urlString: $e');
  }
}
