import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../api/recommend_api.dart';
import '../models/recommendation.dart';
import '../models/delight.dart';

class RecommendProvider extends ChangeNotifier {
  final RecommendApi _api;

  List<Recommendation> _recommendations = [];
  List<Delight> _delights = [];
  bool _loading = false;
  bool _online = false;
  String _runtimeSummary = '';
  Timer? _pollTimer;

  RecommendProvider(ApiClient client) : _api = RecommendApi(client);

  List<Recommendation> get recommendations => _recommendations;
  List<Delight> get delights => _delights;
  bool get loading => _loading;
  bool get online => _online;
  String get runtimeSummary => _runtimeSummary;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _recommendations = await _api.fetch();
      _delights = await _api.fetchDelights(limit: 10);
      _online = true;
    } catch (_) {
      _online = false;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> reshuffle() async {
    try {
      final data = await _api.reshuffle();
      _recommendations = (data['items'] as List?)?.map((e) => Recommendation.fromJson(e)).toList() ?? [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> append() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final excluded = _recommendations.map((r) => r.bvid).toList();
      final data = await _api.append(excluded);
      final newItems = (data['items'] as List?)?.map((e) => Recommendation.fromJson(e)).toList() ?? [];
      _recommendations.addAll(newItems);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> submitFeedback(String bvid, String type, {String? note}) async {
    await _api.submitFeedback({'bvid': bvid, 'type': type, 'note': ?note});
    for (var r in _recommendations) {
      if (r.bvid == bvid) r.feedbackType = type;
    }
    notifyListeners();
  }

  Future<void> respondToDelight(String bvid, String response, {String message = ''}) async {
    await _api.respondToDelight(bvid, response, message: message);
    _delights.removeWhere((d) => d.bvid == bvid);
    notifyListeners();
  }

  Future<void> reportClick(Recommendation rec) async {
    await _api.reportClick({'bvid': rec.bvid, 'title': rec.title, 'up_name': rec.upName, 'source_platform': rec.sourcePlatform, 'content_url': rec.contentUrl});
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    try {
      final status = await _api.fetch(timeout: 5);
      _online = true;
      if (status.isNotEmpty) {
        _runtimeSummary = '${status.length} 条推荐待看';
        notifyListeners();
      }
    } catch (_) {
      _online = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
