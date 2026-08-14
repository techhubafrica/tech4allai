import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FalApiService {
  // Use the full FAL_KEY securely provided by the user
  static const String _falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';
  
  // The specific fal.ai API endpoints for image generation
  static const String _instantIdUrl = 'https://fal.run/fal-ai/nano-banana-pro/edit';
  static const String _fluxSchnellUrl = 'https://fal.run/fal-ai/nano-banana-2';

  /// Generate a bespoke AI headshot instantaneously using a single reference photo
  Future<String?> generateFromReferenceImage({
    required String referenceUrl,
    required String prompt,
    bool isFree = false,
  }) async {
    final modelPath = isFree ? 'fal-ai/flux-2/klein/4b/edit/lora' : 'fal-ai/nano-banana-pro/edit';
    final url = Uri.parse('https://fal.run/$modelPath');
    
    try {
      print('Sending reference image request to: $url');
      print('Using Reference Image URL: $referenceUrl');
      print('Prompt: $prompt');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_falKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'image_urls': [referenceUrl],
        }),
      );

      print('Fal.ai Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        String? generatedImageUrl;
        if (result['images'] != null && result['images'].isNotEmpty) {
           generatedImageUrl = result['images'][0]['url'];
        } else if (result['image'] != null && result['image']['url'] != null) {
           generatedImageUrl = result['image']['url'];
        } else if (result['url'] != null) {
           generatedImageUrl = result['url'];
        }

        if (generatedImageUrl != null) {
           print('Success! Generated image URL: $generatedImageUrl');
           return generatedImageUrl;
        } else {
           print('Error: API returned 200 but could not parse the URL. Raw: $result');
           return null;
        }
      } else {
        print('Error from Fal.ai: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception calling Fal.ai: $e');
      return null;
    }
  }

  /// Generate AI Image from multiple reference photos using Nano Banana Pro
  Future<String?> generateFromMultipleReferenceImages({
    required List<String> referenceUrls,
    required String prompt,
    bool isFree = false,
  }) async {
    final modelPath = isFree ? 'fal-ai/flux-2/klein/4b/edit/lora' : 'fal-ai/nano-banana-pro/edit';
    final url = Uri.parse('https://fal.run/$modelPath');
    
    try {
      print('Sending reference image request to: $url');
      print('Using Reference Image URLs: $referenceUrls');
      print('Prompt: $prompt');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_falKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'image_urls': referenceUrls,
        }),
      );

      print('Fal.ai Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        String? generatedImageUrl;
        if (result['images'] != null && result['images'].isNotEmpty) {
           generatedImageUrl = result['images'][0]['url'];
        } else if (result['image'] != null && result['image']['url'] != null) {
           generatedImageUrl = result['image']['url'];
        } else if (result['url'] != null) {
           generatedImageUrl = result['url'];
        }

        if (generatedImageUrl != null) {
           print('Success! Generated image URL: $generatedImageUrl');
           return generatedImageUrl;
        } else {
           print('Error: API returned 200 but could not parse the URL. Raw: $result');
           return null;
        }
      } else {
        print('Error from Fal.ai: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception calling Fal.ai: $e');
      return null;
    }
  }

  /// General Image Generation using Fal.ai Nano Banana 2 (Gemini Architecture)
  Future<String?> generateImageFromPrompt({
    required String prompt,
    required String aspectRatio,
    bool isFree = false,
  }) async {
    final modelPath = isFree ? 'fal-ai/flux/schnell' : 'fal-ai/nano-banana-2';
    final url = Uri.parse('https://fal.run/$modelPath');
    
    try {
      print('Sending Text-to-Image Request to: $url');
      print('Prompt: $prompt');
      print('Aspect Ratio: $aspectRatio');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_falKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'aspect_ratio': aspectRatio,
        }),
      );

      print('Fal.run Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        String? generatedImageUrl;
        if (result['images'] != null && result['images'].isNotEmpty) {
           generatedImageUrl = result['images'][0]['url'];
        } else if (result['url'] != null) {
           generatedImageUrl = result['url'];
        }

        if (generatedImageUrl != null) {
           print('Success! Generated image URL: $generatedImageUrl');
           return generatedImageUrl;
        } else {
           print('Error: API returned 200 but could not parse the URL. Raw: $result');
           return null;
        }
      } else {
        print('Error from Fal.run: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception calling Fal.run: $e');
      return null;
    }
  }

  /// Helper to download the image bytes from the generated URL
  Future<Uint8List?> downloadImageBytes(String url) async {
      try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
              return res.bodyBytes;
          } else {
              print('Failed to download image bytes: ${res.statusCode}');
          }
      } catch (e) {
          print('Exception downloading result image: $e');
      }
      return null;
  }
}
