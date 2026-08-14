import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/hugging_face_service.dart';
import '../widgets/under_development_overlay.dart';

class DetectorScreen extends StatefulWidget {
  const DetectorScreen({super.key});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  final TextEditingController _textController = TextEditingController();
  final HuggingFaceService _hfService = HuggingFaceService();
  
  double? _aiProbability;
  bool _isLoading = false;
  bool _hasResult = false;

  Future<void> _detectAi() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasResult = false;
      _aiProbability = null;
    });

    final result = await _hfService.detectAiContent(text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasResult = true;
        _aiProbability = result['aiProbability'] as double?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'AI Detector',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: UnderDevelopmentOverlay(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Result Area
            if (_hasResult && _aiProbability != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutralBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      'Probability Score',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.neutralTextMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: _aiProbability,
                            strokeWidth: 12,
                            color: _aiProbability! > 0.5 ? Colors.redAccent : Colors.greenAccent,
                            backgroundColor: AppColors.neutralBorder,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${(_aiProbability! * 100).toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _aiProbability! > 0.5 ? 'AI Generated' : 'Human Written',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _aiProbability! > 0.5 ? Colors.redAccent : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyze Text',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Paste text here to check for AI generation...',
                      hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.neutralBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.neutralBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _detectAi,
                      child: Text(
                        _isLoading ? 'Analyzing...' : 'Analyze Trace',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
       ),
      ),
    );
  }
}
