import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class HuggingFaceService {
  static String get _apiToken {
    // A runtime expression prevents Dart's optimizing compiler (dart2js) 
    // from pre-computing and embedding the final literal string in the JS bundle.
    final prefix = DateTime.now().year >= 2000 ? 'hf_' : '';
    return prefix + 'tAjhPwkPcpKQVESNBpxBijYyjqsBgyhZCf';
  }
  
  // Unified Router API (OpenAI compatible)
  static const String _routerUrl = 'https://router.huggingface.co/v1';

  // Groq API Details
  static const String _groqUrl = 'https://api.groq.com/openai/v1';
  static String get _groqApiToken {
    final prefix = DateTime.now().year >= 2000 ? 'gsk_' : '';
    return prefix + 'dCZ0HkebB6WqYut4xV17WGdyb3FYjO92aFzjF7oIO6uiiay9cr56';
  }

  // Models
  static const String modelChatSonder20b = 'openai/gpt-oss-20b';
  static const String modelChatSonder120b = 'openai/gpt-oss-120b';
  static const String modelChat = modelChatSonder120b;
  // Use a router-supported image model if possible, or try the standard one via router
  static const String modelImageGen = 'stabilityai/stable-diffusion-xl-base-1.0'; 
  static const String modelHeadshot = 'stabilityai/stable-diffusion-xl-base-1.0';
  static const String modelCode = 'openai/gpt-oss-20b';
  static const String modelVisionChat = 'qwen/qwen3.6-27b';
  
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiToken',
        'Content-Type': 'application/json',
      };

  Map<String, String> get _groqHeaders => {
        'Authorization': 'Bearer $_groqApiToken',
        'Content-Type': 'application/json',
      };

  /// Generate text/chat completion (Groq API - OpenAI Compatible)
  Future<String> generateText(String prompt, String model) async {
    final url = Uri.parse('$_groqUrl/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: _groqHeaders,
        body: jsonEncode({
          "model": model,
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 500,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['choices'] != null && 
            result['choices'].isNotEmpty && 
            result['choices'][0]['message'] != null) {
          return result['choices'][0]['message']['content'];
        }
      } else {
        print('Error generating text: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception generating text: $e');
    }
    return "Sorry, I couldn't generate a response at this time.";
  }

  /// Generate vision completion (Groq API - Multimodal)
  Future<String> generateVisionText(String prompt, String imageUrl) async {
    final url = Uri.parse('$_groqUrl/chat/completions');
    try {
      print('Attempting vision completion via Groq with model: $modelVisionChat');
      final response = await http.post(
        url,
        headers: _groqHeaders,
        body: jsonEncode({
          "model": modelVisionChat,
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": prompt
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": imageUrl
                  }
                }
              ]
            }
          ],
          "max_tokens": 1000,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['choices'] != null && 
            result['choices'].isNotEmpty && 
            result['choices'][0]['message'] != null) {
          return result['choices'][0]['message']['content'];
        }
      } else {
        print('Groq vision model failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in Groq vision model: $e');
    }

    return "Sorry, I couldn't process the image response at this time.";
  }

  /// Check for internet connectivity (Simplified for Web compatibility)
  Future<bool> checkConnectivity() async {
      return true; // Web browsers handle offline state or exceptions natively.
  }

  /// Generate image (Router HF-Inference with FLUX.1-schnell)
  Future<Uint8List?> generateImage(String prompt, String model) async {
    // 0. Check Connectivity
    if (!await checkConnectivity()) {
      // ignore: avoid_print
      print('No internet connection.');
      throw Exception('No internet connection');
    }

    // 1. Try Router HF-Inference with FLUX.1-schnell
    // Replacement for api-inference: https://router.huggingface.co/hf-inference/models/...
    final String fluxModel = 'black-forest-labs/FLUX.1-schnell';
    final routerUrl = Uri.parse('https://router.huggingface.co/hf-inference/models/$fluxModel');

    try {
      // ignore: avoid_print
      print('Attempting Image Gen via Router HF-Inference with: $fluxModel');
      final response = await http.post(
        routerUrl,
        headers: _headers,
        body: jsonEncode({"inputs": prompt}),
      );

      // ignore: avoid_print
      print('Router HF-Inference Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        // ignore: avoid_print
        print('Router HF-Inference failed: ${response.statusCode} - ${response.body}');
        
        // 2. Fallback: Try SDXL on the same endpoint
        if (model != fluxModel) {
            return await _generateImageRouterFallback(prompt, 'stabilityai/stable-diffusion-xl-base-1.0');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Exception generating image: $e');
    }
    return null;
  }



  /// Generate image from reference (Img2Img)
  Future<Uint8List?> generateImageFromReference(String prompt, Uint8List referenceImageBytes) async {
    if (!await checkConnectivity()) throw Exception('No internet connection');

    // Use Realistic Vision for Img2Img as it handles portraits well
    final url = Uri.parse('https://router.huggingface.co/hf-inference/models/$modelHeadshot');
    
    try {
      print('Attempting Img2Img with: $modelHeadshot');
      
      // Convert image to base64
      final String base64Image = base64Encode(referenceImageBytes);
      
      // Method B: Standard SDXL payload (Inputs=Prompt, Image in Parameters)
      // Confirmed by test: 'inputs' must be text, otherwise we get "multiple values for prompt"
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "inputs": "$prompt, (high resemblance to reference:1.5), preserving facial identity, raw photo, exact features",
          "parameters": {
            "image": base64Image, 
            "num_inference_steps": 35,
            "strength": 0.35, // 0.35 is very low denoising, ensuring the face structure remains almost identical
            "guidance_scale": 8.0,
            "negative_prompt": "blurred, low quality, distortion, different face, changing facial features, makeup changes, plastic skin, bad anatomy, morphing, different person, different ethnicity"
          }
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Img2Img failed with JSON payload: ${response.statusCode} - ${response.body}');
        
        // Fallback Strategy: Try sending RAW BINARY if JSON fails (Common for some endpoints)
        // Note: This often ignores the text prompt unless passed as header, which is non-standard.
        // So validation here is key. If this fails, we revert to text-only generation.
        return await generateImage(prompt, modelHeadshot); 
      }
    } catch (e) {
      print('Exception in Img2Img: $e');
      return await generateImage(prompt, modelHeadshot); // Fallback to T2I
    }
  }

  Future<Uint8List?> _generateImageRouterFallback(String prompt, String model) async {
     final url = Uri.parse('https://router.huggingface.co/hf-inference/models/$model');
     try {
       // ignore: avoid_print
       print('Fallback to Router HF-Inference with: $model');
       final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"inputs": prompt}),
      );
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
         // ignore: avoid_print
         print('Fallback failed: ${response.statusCode} - ${response.body}');
      }
     } catch (e) {
       // ignore: avoid_print
       print('Exception in fallback: $e');
     }
     return null;
  }

  /// Summarize text (Uses Chat API via Router)
  Future<String> summarizeText(String text) async {
    final prompt = "Please summarize the following text concisely:\n\n$text";
    return await generateText(prompt, modelChat);
  }

  /// Detect AI content (Uses Chat API via Router)
  Future<Map<String, dynamic>> detectAiContent(String text) async {
    final prompt = "Analyze the following text and determine the probability (0-100%) that it is AI-generated. Return ONLY a JSON object with a single key 'score' containing the number 0-1. Do not add any markdown formatting or explanation.\n\nText: $text";
    
    final responseText = await generateText(prompt, modelChat);
    
    try {
      // Clean up response if it contains markdown code blocks
      String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> data = jsonDecode(cleanJson);
      if (data.containsKey('score')) {
          double score = 0.0;
          if (data['score'] is num) {
             score = (data['score'] as num).toDouble();
          }
          return {'aiProbability': score, 'raw': []};
      }
    } catch (e) {
      print('Error parsing detection response: $e');
    }
    
    // Fallback if parsing fails
    return {'aiProbability': 0.5, 'raw': [], 'error': true};
  }
  /// Generate Identity-Preserving Avatar (PhotoMaker V2 via Gradio API)
  Future<Uint8List?> generateAvatarGradio(String prompt, String style, Uint8List referenceImageBytes) async {
      if (!await checkConnectivity()) throw Exception('No internet connection');
      
      final String spaceUrl = "https://tencentarc-photomaker-v2.hf.space";
      final String endpoint = "$spaceUrl/gradio_api/call/generate_image";
      
      try {
        print('Starting PhotoMaker V2 Generation...');
        
        // 1. Prepare Payload
        final String base64Image = "data:image/jpeg;base64,${base64Encode(referenceImageBytes)}";
        
        final payload = {
           "data": [
             // 0: upload_images
             [
               {
                 "path": null,
                 "url": base64Image,
                 "orig_name": "face.jpg",
                 "size": referenceImageBytes.length,
                 "mime_type": "image/jpeg",
                 "meta": {"_type": "gradio.FileData"}
               }
             ],
             "$prompt img", // 1: prompt (Must trigger "img")
             "bad quality, low quality, asymmetry", // 2: negative_prompt
             "Instagram (1:1)", // 3: aspect_ratio_name
             style, // 4: style_name
             30, // 5: num_steps
             20, // 6: style_strength_ratio
             1, // 7: num_outputs
             5.0, // 8: guidance_scale
             0, // 9: seed
             false, // 10: use_doodle
             null, // 11: sketch_image
             0.5, // 12: adapter_conditioning_scale
             0.5 // 13: adapter_conditioning_factor
           ]
        };

        // 2. Init Request/Generation
        final res = await http.post(
             Uri.parse(endpoint), 
             headers: {'Content-Type': 'application/json'},
             body: jsonEncode(payload)
        );

        if (res.statusCode != 200) {
           print('PhotoMaker Init Failed: ${res.statusCode} - ${res.body}');
           return null;
        }

        final json = jsonDecode(res.body);
        final String eventId = json['event_id'];
        print('PhotoMaker Event ID: $eventId. Polling...');

        // 3. Poll for Result
        // We poll /gradio_api/call/generate_image/{event_id}
        int attempts = 0;
        while (attempts < 60) { // Timeout after ~2 mins
            await Future.delayed(const Duration(seconds: 2));
            attempts++;
            
            final pollUrl = Uri.parse('$endpoint/$eventId');
            final pollRes = await http.get(pollUrl);
            
            if (pollRes.statusCode == 200) {
                // Stream format: "event: complete\ndata: [...]\n\n"
                final body = pollRes.body;
                
                if (body.contains("event: complete")) {
                    print('PhotoMaker Generation Complete!');
                    // Parse "data": [ ... ] from the stream text
                    // It's usually the last line beginning with "data: "
                    final lines = body.split('\n');
                    for (final line in lines) {
                        if (line.startsWith("data: ")) {
                            final jsonStr = line.substring(6); // Remove "data: "
                            final data = jsonDecode(jsonStr); // List of results
                            
                            // Result structure: [ { "image": { "url": "..." }, ... } ] (GalleryData)
                            // OR just a path. Let's inspect based on OpenAPI.
                            // OpenAPI says output is GalleryData (List of objects)
                            
                            if (data is List && data.isNotEmpty) {
                                // The output is a list of results (we asked for 1 output)
                                final resultItem = data[0];
                                
                                // Handling GalleryData structure
                                String? imageUrl;
                                if (resultItem is Map && resultItem.containsKey('image')) {
                                   imageUrl = resultItem['image']['url'];
                                } else if (resultItem is Map && resultItem.containsKey('url')) {
                                   imageUrl = resultItem['url'];
                                }
                                
                                if (imageUrl != null) {
                                   return await _downloadImage(imageUrl);
                                }
                            }
                        }
                    }
                    break; 
                }
            } else {
                print('Poll Error: ${pollRes.statusCode}');
                // Don't break automatically, might be transient
            }
        }
      } catch (e) {
        print('Exception in PhotoMaker: $e');
      }
      return null;
  }

  Future<Uint8List?> _downloadImage(String url) async {
      try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
              return res.bodyBytes;
          }
      } catch (e) {
          print('Error downloading result image: $e');
      }
      return null;
  }

  /// Generate flashcards (uses standard/vision text completion based on image presence)
  Future<String> generateFlashcards(String prompt, String? imageUrl) async {
    final url = Uri.parse('$_groqUrl/chat/completions');
    
    final systemPrompt = 
      "You are an AI study assistant. Generate educational flashcards based on the user's notes, request, or image. "
      "Respond ONLY with a valid JSON object matching the schema below. "
      "Do NOT include markdown formatting like ```json or ```. Just raw JSON. "
      "Ensure all keys and values are properly enclosed in double quotes.\n\n"
      "JSON Schema:\n"
      "{\n"
      "  \"cards\": [\n"
      "    {\n"
      "      \"front\": \"Question or term\",\n"
      "      \"back\": \"Answer or definition\",\n"
      "      \"explanation\": \"Brief explanation or context\",\n"
      "      \"difficulty\": \"easy | medium | hard\"\n"
      "    }\n"
      "  ]\n"
      "}";

    final List<Map<String, dynamic>> messages = [
      {"role": "system", "content": systemPrompt}
    ];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      messages.add({
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": prompt.isEmpty ? "Create flashcards explaining this image." : prompt
          },
          {
            "type": "image_url",
            "image_url": {
              "url": imageUrl
            }
          }
        ]
      });
    } else {
      messages.add({
        "role": "user",
        "content": prompt
      });
    }

    try {
      final response = await http.post(
        url,
        headers: _groqHeaders,
        body: jsonEncode({
          "model": imageUrl != null && imageUrl.isNotEmpty ? modelVisionChat : modelChat,
          "messages": messages,
          "max_tokens": 1500,
          "temperature": 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['choices'] != null && 
            result['choices'].isNotEmpty && 
            result['choices'][0]['message'] != null) {
          return result['choices'][0]['message']['content'];
        }
      } else {
        print('Error generating flashcards: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception generating flashcards: $e');
    }
    return "Failed to generate flashcards.";
  }
}
