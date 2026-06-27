import '../api/utils.dart';

class ChatTurn {
  final String turnId;
  final String session;
  final String scope;
  final String role;
  final String message;
  final String error;
  final String createdAt;

  ChatTurn({
    required this.turnId,
    this.session = '',
    this.scope = 'chat',
    this.role = '',
    this.message = '',
    this.error = '',
    this.createdAt = '',
  });

  factory ChatTurn.fromJson(Map<String, dynamic> json) => ChatTurn(
    turnId: json['turn_id'] ?? '',
    session: json['session'] ?? '',
    scope: json['scope'] ?? 'chat',
    role: json['role'] ?? '',
    message: decodeHtml(json['message'] ?? ''),
    error: decodeHtml(json['error'] ?? ''),
    createdAt: json['created_at'] ?? '',
  );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasError => error.isNotEmpty;
}
