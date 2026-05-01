// lib/core/services/chatbot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChatbotService {
  // Option 1: Google Gemini API (Recommended - Free tier available)
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  // Option 2: OpenAI API (Paid)
  static const String _openAiApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // You can get a free API key from: https://aistudio.google.com/app/apikey
  // For production, use flutter_dotenv to hide your API key
  static String _apiKey = 'AIzaSyDp4iS7eXpudx49RbNd_YUTrGMWBBLgtjI';
  static String _apiProvider = 'gemini'; // 'gemini' or 'openai'
  
  // Set the API key (call this during app initialization)
  static void initialize({required String apiKey, String provider = 'gemini'}) {
    _apiKey = apiKey;
    _apiProvider = provider;
    debugPrint('✅ ChatbotService initialized with $provider API');
  }
  
  // Update API key (for testing)
  static void updateApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  // Send message to AI and get response
  static Future<String> sendMessage(String userMessage, {List<Map<String, String>>? chatHistory}) async {
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ API key not set. Please initialize ChatbotService with your API key.');
      return _getFallbackResponse(userMessage);
    }
    
    try {
      if (_apiProvider == 'gemini') {
        return await _sendToGemini(userMessage, chatHistory);
      } else if (_apiProvider == 'openai') {
        return await _sendToOpenAI(userMessage, chatHistory);
      } else {
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      debugPrint('❌ Chatbot API error: $e');
      return _getFallbackResponse(userMessage);
    }
  }
  
  // Google Gemini API implementation
  static Future<String> _sendToGemini(String userMessage, List<Map<String, String>>? chatHistory) async {
    final url = Uri.parse('$_geminiApiUrl?key=$_apiKey');
    
    // Build conversation context
    List<Map<String, dynamic>> contents = [];
    
    // Add system instruction for medical context
    const systemInstruction = '''
You are "Seva Pulse Health Assistant", a friendly and professional medical chatbot for a hospital management app called "Seva Pulse". 
Your role is to help patients with:
- Booking and managing appointments
- Medicine reminders and prescription information
- Health tips and general wellness advice
- Explaining hospital services and facilities
- Answering questions about health camps and events

Important guidelines:
- Always advise consulting a real doctor for serious medical concerns
- Never diagnose or prescribe medication
- Be empathetic and helpful
- Keep responses concise (2-3 sentences when possible)
- If unsure, suggest contacting the hospital directly

The app features: appointment booking, medicine tracking, prescription management, health camps, canteen menu, and doctor consultations.
''';
    
    // Add system instruction as first message
    contents.add({
      'role': 'user',
      'parts': [{'text': systemInstruction}]
    });
    contents.add({
      'role': 'model',
      'parts': [{'text': 'I understand. I will act as the Seva Pulse Health Assistant and follow all guidelines.'}]
    });
    
    // Add chat history (last 5 messages for context)
    if (chatHistory != null && chatHistory.isNotEmpty) {
      for (var msg in chatHistory.take(10)) { // Limit history to 10 messages
        contents.add({
          'role': msg['isUser'] == 'true' ? 'user' : 'model',
          'parts': [{'text': msg['text']}]
        });
      }
    }
    
    // Add current user message
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}]
    });
    
    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 500,
        'topP': 0.95,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ]
    };
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      try {
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        return aiResponse.toString().trim();
      } catch (e) {
        debugPrint('Error parsing Gemini response: $e');
        return _getFallbackResponse(userMessage);
      }
    } else {
      debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
      return _getFallbackResponse(userMessage);
    }
  }
  
  // OpenAI API implementation (alternative)
  static Future<String> _sendToOpenAI(String userMessage, List<Map<String, String>>? chatHistory) async {
    final url = Uri.parse(_openAiApiUrl);
    
    // Build messages array with context
    List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content': 'You are Seva Pulse Health Assistant, a helpful medical chatbot for a hospital app. Assist with appointments, medicines, health tips, and hospital services. Always advise consulting a doctor for serious issues. Keep responses concise and friendly.'
      }
    ];
    
    // Add chat history
    if (chatHistory != null && chatHistory.isNotEmpty) {
      for (var msg in chatHistory.take(10)) {
        messages.add({
          'role': msg['isUser'] == 'true' ? 'user' : 'assistant',
          'content': msg['text'] ?? '',
        });
      }
    }
    
    // Add current message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });
    
    final requestBody = {
      'model': 'gpt-3.5-turbo',
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 500,
    };
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: json.encode(requestBody),
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
      return _getFallbackResponse(userMessage);
    }
  }
  
  // Fallback responses when API fails
  static String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('appointment') || message.contains('book')) {
      return "📅 You can book an appointment by tapping the 'Book an Appointment' card on the home screen or going to Medical Specialties. Would you like me to help you find a specialist?";
    } else if (message.contains('medicine') || message.contains('prescription')) {
      return "💊 You can manage your medicines and prescriptions in the 'My Medicine' and 'Prescriptions' sections. Set reminders so you never miss a dose!";
    } else if (message.contains('symptom') || message.contains('pain') || message.contains('fever')) {
      return "🏥 I understand you're not feeling well. For proper medical advice, please consult with one of our doctors. You can book an appointment right away in the app. Is this an emergency? Please call emergency services immediately if needed.";
    } else if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return "👋 Hello! I'm your Seva Pulse Health Assistant. How can I help you today? You can ask me about appointments, medicines, health camps, or anything about our hospital services.";
    } else if (message.contains('thank')) {
      return "❤️ You're welcome! I'm glad I could help. Is there anything else you need assistance with?";
    } else if (message.contains('doctor') || message.contains('specialist')) {
      return "👨‍⚕️ We have many specialists including Cardiologists, Neurologists, Orthopedics, Pediatricians, and more. You can browse all specialties in the Medical Specialties section.";
    } else if (message.contains('canteen') || message.contains('food')) {
      return "🍽️ Our hospital canteen serves fresh and healthy meals from 7:00 AM to 9:00 PM. You can view the full menu in the Canteen section. Would you like to contact the canteen directly?";
    } else if (message.contains('health camp') || message.contains('camp')) {
      return "🏕️ We regularly organize free health camps and awareness programs. Check the Health Feed section for upcoming camps near you!";
    } else {
      return "💙 Thank you for your message. I'm here to help with appointments, medicines, health information, or any questions about Seva Pulse Hospital. Could you please provide more details about what you need?";
    }
  }
}