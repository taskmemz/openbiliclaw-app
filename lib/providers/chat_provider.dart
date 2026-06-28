import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../api/chat_api.dart';
import '../models/chat.dart';

class ChatProvider extends ChangeNotifier {
  final ChatApi _api;

  List<ChatTurn> _turns = [];
  bool _loading = false;
  bool _responding = false;

  ChatProvider(ApiClient client) : _api = ChatApi(client);

  List<ChatTurn> get turns => _turns;
  bool get loading => _loading;
  bool get responding => _responding;

  Future<void> loadTurns() async {
    _loading = true;
    notifyListeners();
    try {
      _turns = await _api.fetchTurns(session: 'mobile', limit: 50);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || _responding) return;
    _responding = true;
    final userTurn = ChatTurn(turnId: DateTime.now().millisecondsSinceEpoch.toString(), role: 'user', message: message);
    _turns.add(userTurn);
    notifyListeners();

    try {
      final result = await _api.startTurn(message: message, session: 'mobile');
      await _pollForResponse(result.turnId);
    } catch (e) {
      _turns.add(ChatTurn(turnId: 'err-${DateTime.now().millisecondsSinceEpoch}', role: 'assistant', message: '抱歉，我暂时没接上。', error: e.toString()));
    }
    _responding = false;
    notifyListeners();
  }

  Future<void> _pollForResponse(String turnId) async {
    for (var i = 0; i < 180; i++) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        final turn = await _api.fetchTurn(turnId);
        if (turn.isAssistant) {
          _turns.add(turn);
          notifyListeners();
          return;
        }
      } catch (_) {}
    }
    _turns.add(ChatTurn(turnId: 'timeout-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant', message: '响应超时，可能是 LLM 比较慢，可以等一下再试一次。'));
    notifyListeners();
  }
}
