// lib/features/user/screens/chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/chatbot_service.dart';
import '../../../core/theme/theme_extensions.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _isTyping = false;
  
  // Store chat history for context
  List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }
  
  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Hello! I'm your Seva Pulse Health Assistant. 🌟\n\nI can help you with:\n• 📅 Book Appointment\n• 💊 Medicine Reminders\n• 📋 View Prescriptions\n• 🍽️ Diet Plans\n• 🏥 Hospital Services\n• 📍 Contact Information\n\nJust type what you need or tap on the suggestions below!",
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: false,
        actionButtons: [
          ChatAction(label: "📅 Book Appointment", actionType: "appointment"),
          ChatAction(label: "💊 My Medicines", actionType: "medicines"),
          ChatAction(label: "📋 My Prescriptions", actionType: "prescriptions"),
          ChatAction(label: "🍽️ Canteen Menu", actionType: "canteen"),
        ],
      ),
    );
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? predefinedMessage}) async {
    final userMessage = predefinedMessage ?? _messageController.text.trim();
    if (userMessage.isEmpty || _isLoading) return;

    // Add user message
    final userChatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      isLoading: false,
    );
    
    setState(() {
      _messages.add(userChatMessage);
      _chatHistory.add({'text': userMessage, 'isUser': 'true'});
      _isLoading = true;
      _isTyping = true;
    });
    
    if (predefinedMessage == null) {
      _messageController.clear();
    }
    _scrollToBottom();
    
    // Add typing indicator
    final typingIndicatorId = 'typing_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(ChatMessage(
        id: typingIndicatorId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });
    _scrollToBottom();
    
    try {
      // Process the message and get response with actions
      final response = await _processUserIntent(userMessage);
      
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg.id == typingIndicatorId);
      });
      
      // Add AI response with action buttons
      final aiResponse = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response['message'],
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: false,
        actionButtons: response['actions'],
      );
      
      setState(() {
        _messages.add(aiResponse);
        _chatHistory.add({'text': response['message'], 'isUser': 'false'});
        _isLoading = false;
        _isTyping = false;
      });
      
      _scrollToBottom();
      
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg.id == typingIndicatorId);
      });
      
      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "I'm having trouble connecting right now. Please check your internet connection and try again. 🙏",
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: false,
        isError: true,
      );
      
      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
        _isTyping = false;
      });
      
      _scrollToBottom();
    }
  }

  Future<Map<String, dynamic>> _processUserIntent(String message) async {
    final lowerMessage = message.toLowerCase();
    
    // Check for appointment booking intent
    if (lowerMessage.contains('book appointment') || 
        lowerMessage.contains('appointment') && (lowerMessage.contains('book') || lowerMessage.contains('schedule'))) {
      return {
        'message': 'I can help you book an appointment! 📅\n\nWhat type of appointment would you like?\n\n• General Consultation\n• Specialist Visit\n• Follow-up Checkup\n\nClick the button below to proceed.',
        'actions': [
          ChatAction(label: "📅 Book New Appointment", actionType: "book_appointment"),
          ChatAction(label: "👨‍⚕️ View My Appointments", actionType: "my_appointments"),
        ],
      };
    }
    
    // Check for medicines intent
    if (lowerMessage.contains('medicine') || 
        lowerMessage.contains('medication') || 
        lowerMessage.contains('my medicines')) {
      return {
        'message': '💊 Here are your medicine options:\n\n• View all your current medicines\n• Add new medicine reminders\n• Track your daily doses\n\nSelect an option below:',
        'actions': [
          ChatAction(label: "💊 View My Medicines", actionType: "view_medicines"),
          ChatAction(label: "➕ Add New Medicine", actionType: "add_medicine"),
        ],
      };
    }
    
    // Check for prescriptions intent
    if (lowerMessage.contains('prescription') || 
        lowerMessage.contains('my prescriptions')) {
      return {
        'message': '📋 Your prescriptions are ready!\n\nYou can:\n• View all your prescriptions\n• Download past prescriptions\n• Share with doctors\n\nClick below to view:',
        'actions': [
          ChatAction(label: "📋 View Prescriptions", actionType: "view_prescriptions"),
        ],
      };
    }
    
    // Check for diet plans
    if (lowerMessage.contains('diet') || 
        lowerMessage.contains('nutrition') || 
        lowerMessage.contains('food plan')) {
      return {
        'message': '🥗 I can help you with diet plans!\n\n• Balanced Diet Chart\n• Specific Health Condition Diets\n• Weight Management Plans\n• View Hospital Canteen Menu\n\nWhat would you like?',
        'actions': [
          ChatAction(label: "🍽️ View Canteen Menu", actionType: "canteen"),
          ChatAction(label: "📋 Diet Plan", actionType: "diet_plan"),
        ],
      };
    }
    
    // Check for canteen menu
    if (lowerMessage.contains('canteen') || 
        lowerMessage.contains('food') || 
        lowerMessage.contains('menu')) {
      return {
        'message': '🍽️ Visit our hospital canteen!\n\nWe offer:\n• Healthy meals\n• Fresh juices\n• Snacks & beverages\n\nClick below to see the full menu:',
        'actions': [
          ChatAction(label: "🍽️ View Canteen Menu", actionType: "canteen"),
        ],
      };
    }
    
    // Check for health tips
    if (lowerMessage.contains('health tip') || 
        lowerMessage.contains('wellness') || 
        lowerMessage.contains('healthy')) {
      // Get a health tip from the service
      final healthTip = await ChatbotService.sendMessage(
        "Give me a short health tip",
        chatHistory: _chatHistory,
      );
      return {
        'message': healthTip,
        'actions': [
          ChatAction(label: "💪 More Health Tips", actionType: "health_tips"),
        ],
      };
    }
    
    // Check for contact info
    if (lowerMessage.contains('contact') || 
        lowerMessage.contains('hospital address') || 
        lowerMessage.contains('phone')) {
      return {
        'message': '📍 Hospital Information:\n\nK-Star Multispeciality Hospital\nSambhaji Nagar Rd, Tapowan,\nKolhapur, Maharashtra 416007\n\n📞 Phone: +91 9090575353\n📧 Email: kstarhospital@gmail.com\n\n🕒 Open 24/7\n\nNeed directions? Click below!',
        'actions': [
          ChatAction(label: "🗺️ Get Directions", actionType: "directions"),
          ChatAction(label: "📞 Call Hospital", actionType: "call_hospital"),
        ],
      };
    }
    
    // Default - send to AI for general response
    final aiResponse = await ChatbotService.sendMessage(
      message,
      chatHistory: _chatHistory,
    );
    
    return {
      'message': aiResponse,
      'actions': [
        ChatAction(label: "📅 Book Appointment", actionType: "appointment"),
        ChatAction(label: "💊 My Medicines", actionType: "medicines"),
        ChatAction(label: "📋 My Prescriptions", actionType: "prescriptions"),
      ],
    };
  }

  void _handleAction(ChatAction action) {
    switch (action.actionType) {
      case "appointment":
      case "book_appointment":
        Navigator.pushNamed(context, '/specialties');
        break;
        
      case "my_appointments":
        Navigator.pushNamed(context, '/user-home');
        break;
        
      case "view_medicines":
      case "medicines":
        Navigator.pushNamed(context, '/user-home');
        _showNavigationMessage("Medicine screen opened. Go to 'My Medicine' tab.");
        break;
        
      case "add_medicine":
        _showNavigationMessage("Add medicine feature coming soon! You can add medicines from the My Medicine screen.");
        break;
        
      case "view_prescriptions":
      case "prescriptions":
        Navigator.pushNamed(context, '/user-home');
        _showNavigationMessage("Prescriptions screen opened. Go to 'Prescriptions' tab.");
        break;
        
      case "canteen":
        Navigator.pushNamed(context, '/canteen-menu');
        break;
        
      case "diet_plan":
        _showNavigationMessage("Diet plan feature coming soon! Meanwhile, check our canteen menu for healthy options.");
        break;
        
      case "health_tips":
        Navigator.pushNamed(context, '/health-tips');
        break;
        
      case "directions":
        Navigator.pushNamed(context, '/contact-us');
        break;
        
      case "call_hospital":
        final url = Uri.parse('tel:9090575353');
        _launchUrl(url);
        break;
        
      default:
        _showNavigationMessage("Feature coming soon! 🚀");
    }
  }
  
  void _showNavigationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
  
  void _clearChat() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Clear Chat', style: TextStyle(color: context.primaryText)),
        content: Text('Are you sure you want to clear all messages?', style: TextStyle(color: context.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _chatHistory.clear();
                _addWelcomeMessage();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Health Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: context.backgroundColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip('📅 Book Appointment', () => _sendMessage(predefinedMessage: 'I want to book an appointment')),
                  const SizedBox(width: 8),
                  _buildQuickChip('💊 My Medicines', () => _sendMessage(predefinedMessage: 'Show my medicines')),
                  const SizedBox(width: 8),
                  _buildQuickChip('📋 Prescriptions', () => _sendMessage(predefinedMessage: 'Show my prescriptions')),
                  const SizedBox(width: 8),
                  _buildQuickChip('🍽️ Canteen Menu', () => _sendMessage(predefinedMessage: 'Show canteen menu')),
                  const SizedBox(width: 8),
                  _buildQuickChip('🥗 Diet Plan', () => _sendMessage(predefinedMessage: 'I need a diet plan')),
                  const SizedBox(width: 8),
                  _buildQuickChip('📍 Hospital Info', () => _sendMessage(predefinedMessage: 'Hospital contact information')),
                ],
              ),
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  message: message,
                  onActionTap: _handleAction,
                );
              },
            ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: context.backgroundColor,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.primaryColor,
                    radius: 12,
                    child: Icon(Icons.medical_services, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('AI is typing...', style: TextStyle(fontSize: 12, color: context.secondaryText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: context.secondaryText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: context.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    style: TextStyle(color: context.primaryText),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isLoading ? Colors.grey : context.primaryColor,
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: context.primaryColor, fontSize: 12)),
      onPressed: onTap,
      backgroundColor: context.cardColor,
      side: BorderSide(color: context.primaryColor),
    );
  }
}

// ChatAction class
class ChatAction {
  final String label;
  final String actionType;

  ChatAction({
    required this.label,
    required this.actionType,
  });
}

// ChatMessage class
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final bool isError;
  final List<ChatAction>? actionButtons;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
    this.actionButtons,
  });
}

// ChatBubble widget with action buttons - FIXED to use context extension
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(ChatAction) onActionTap;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.primaryColor,
              child: const Icon(Icons.medical_services, color: Colors.white, size: 18),
              radius: 16,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: context.primaryColor,
              child: const Icon(
                Icons.medical_services,
                color: Colors.white,
                size: 18,
              ),
              radius: 16,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? (message.isError ? Colors.red.shade100 : context.primaryColor)
                    : context.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser 
                          ? (message.isError ? Colors.red.shade900 : Colors.white)
                          : context.primaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Action Buttons
                  if (message.actionButtons != null && message.actionButtons!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.actionButtons!.map((action) {
                        return ElevatedButton(
                          onPressed: () => onActionTap(action),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            action.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: message.isUser 
                          ? (message.isError ? Colors.red.shade300 : Colors.white70)
                          : context.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF2ecc71),
              radius: 16,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}