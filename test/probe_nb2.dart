import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final urlString = 'https://fal.run/fal-ai/nano-banana-2';
  final falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  
  try {
    final response = await http.post(
      Uri.parse(urlString),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Key $falKey',
      },
      body: jsonEncode({
        'prompt': 'A futuristic cyberpunk city with flying cars.',
        'aspect_ratio': '16:9'
      }),
    );
    
    print('Status Code: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('Body: ${response.body}');
    } else {
      print('Success!');
      print('Body: ${response.body.substring(0, 100)}...'); // Print start
    }
  } catch (e) {
    print('Error: $e');
  }
}
