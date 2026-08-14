import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/hugging_face_service.dart';
import '../widgets/under_development_overlay.dart';

class SummarizerScreen extends StatefulWidget {
  const SummarizerScreen({super.key});

  @override
  State<SummarizerScreen> createState() => _SummarizerScreenState();
}

class _SummarizerScreenState extends State<SummarizerScreen> {
  final TextEditingController _textController = TextEditingController();
  final HuggingFaceService _hfService = HuggingFaceService();
  
  String? _summary;
  bool _isLoading = false;

  Future<void> _summarizeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _summary = null;
    });

    final result = await _hfService.summarizeText(text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _summary = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'AI Summarizer',
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutralBorder),
                image: const DecorationImage(
                  image: NetworkImage('https://cdn-icons-png.flaticon.com/512/2921/2921222.png'),
                  opacity: 0.05,
                  fit: BoxFit.contain,
                )
              ),
              child: Column(
                children: [
                   const Icon(Icons.upload_file, size: 48, color: AppColors.primary),
                   const SizedBox(height: 16),
                   Text(
                    'Upload Document',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                    'PDF, DOCX, or TXT (Max 10MB)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.neutralTextMuted,
                    ),
                   ),
                   const SizedBox(height: 24),
                   SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: (){
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File upload not implemented yet. Paste text below.')));
                      },
                      child: Text('Browse Files', style: GoogleFonts.inter(color: Colors.white)),
                    ),
                   )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.neutralBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: GoogleFonts.inter(color: AppColors.neutralTextMuted, fontSize: 12)),
                ),
                Expanded(child: Divider(color: AppColors.neutralBorder)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.neutralSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutralBorder),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste text here to summarize...',
                  hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
             const SizedBox(height: 24),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _summarizeText,
                child: Text(
                  _isLoading ? 'Summarizing...' : 'Summarize Text',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
             ),
             
             if (_summary != null) ...[
               const SizedBox(height: 32),
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: AppColors.neutralSurface,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                         const SizedBox(width: 8),
                         Text(
                           'Summary',
                           style: GoogleFonts.inter(
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                             color: Colors.white,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                     Text(
                       _summary!,
                       style: GoogleFonts.inter(
                         color: Colors.white,
                         height: 1.6,
                         fontSize: 15,
                       ),
                     ),
                   ],
                 ),
               ),
             ]
          ],
        ),
       ),
      ),
    );
  }
}
