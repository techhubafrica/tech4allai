import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  final referenceUrl = 'https://upload.wikimedia.org/wikipedia/commons/4/48/Outdoors-man-portrait_%28cropped%29.jpg';
  
  try {
    final payloadResponse = await http.post(
      Uri.parse('https://fal.run/fal-ai/nano-banana-pro/edit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Key $falKey',
      },
      body: jsonEncode({
        'prompt': 'Change the background to a professional corporate office.',
        'image_url': referenceUrl,
      }),
    );
    
    print('Payload Test 1: ${payloadResponse.statusCode} - ${payloadResponse.body}');
  } catch (e) {
    print('Error: $e');
  }
}
