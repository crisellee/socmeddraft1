import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AiService {
  static const String _apiKey = "AIzaSyC3XxD8fHly8TFvLiQgfA4LpmQRgYVra8A";

  final GenerativeModel _model;
  ChatSession? _chatSession;

  AiService() : _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
    systemInstruction: Content.system(
        "You are AI TALK BUDDY. "
        "STRICT RULE: Always respond in the SAME language the user uses. If they speak Tagalog, you MUST reply in Tagalog. If they speak English, you MUST reply in English. "
        "Be helpful, engaging, and friendly. "
        "You can analyze images and listen to audio. If a user sends a picture or voice message, describe it or answer questions about it naturally."
    ),
  ) {
    _chatSession = _model.startChat();
  }

  /// 1. Text-only conversation
  Future<String> getAiResponse(String prompt) async {
    try {
      _chatSession ??= _model.startChat();
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      return response.text ?? "Paumanhin buddy, hindi ko naintindihan iyon.";
    } catch (e) {
      return _handleError(e);
    }
  }

  /// 2. Vision response (Image + Text)
  Future<String> getAiResponseWithImage(String prompt, Uint8List imageBytes) async {
    try {
      final content = [
        Content.multi([
          TextPart(prompt.isEmpty ? "Ano ang nasa picture na ito?" : prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];
      final response = await _model.generateContent(content);
      return response.text ?? "Hindi ko mabasa ang picture na ito buddy.";
    } catch (e) {
      return "Medyo nahihirapan akong tingnan ang picture ngayon buddy. 🧐";
    }
  }

  /// 3. Audio response (Voice Record understanding)
  Future<String> getAiResponseWithAudio(String prompt, Uint8List audioBytes) async {
    try {
      final content = [
        Content.multi([
          TextPart(prompt.isEmpty ? "Paki-explain ang sinabi sa audio na ito." : prompt),
          // Gemini supports various audio formats like wav, mp3, m4a
          DataPart('audio/mp3', audioBytes), 
        ])
      ];
      final response = await _model.generateContent(content);
      return response.text ?? "Hindi ko naintindihan ang audio na ito buddy.";
    } catch (e) {
      debugPrint("AI Audio Error: $e");
      return "Pasensya na buddy, hindi ko ma-process ang voice message mo ngayon. 🎙️";
    }
  }

  String _handleError(Object e) {
    final errorStr = e.toString();
    if (errorStr.contains("403") || errorStr.contains("401")) {
      return "Error: Invalid API Key. Pakicheck ang key mo. 🔑";
    }
    return "Error: Hindi ako makakonekta buddy. Balik tayo mamaya! 🌐";
  }
}
