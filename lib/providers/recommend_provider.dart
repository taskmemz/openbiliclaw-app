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
  int _delightIndex = 0;
  bool _loading = false;
  bool _online = false;
  String _runtimeSummary = '';
  Timer? _pollTimer;

  RecommendProvider(ApiClient client) : _api = RecommendApi(client);

  List<Recommendation> get recommendations => _recommendations;
  List<Delight> get delights => _delights;
  int get delightIndex => _delightIndex;
  bool get loading => _loading;
  bool get online => _online;
  String get runtimeSummary => _runtimeSummary;

  void setDelightIndex(int i) {
    if (i >= 0 && i < _delights.length) _delightIndex = i;
  }

  void nextDelight() {
    if (_delights.isNotEmpty) _delightIndex = (_delightIndex + 1) % _delights.length;
    notifyListeners();
  }

  void prevDelight() {
    if (_delights.isNotEmpty) _delightIndex = (_delightIndex - 1 + _delights.length) % _delights.length;
    notifyListeners();
  }

  String? contentUrlFor(Recommendation rec) {
    if (rec.contentUrl.isNotEmpty) return rec.contentUrl;
    if (rec.bvid.isNotEmpty) return 'https://www.bilibili.com/video/${rec.bvid}';
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final recs = await _api.fetch();
      _recommendations = recs;
      _delights = await _api.fetchDelights(limit: 10);
      _delightIndex = 0;
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
      final existingBvids = _recommendations.map((r) => r.bvid).toSet();
      for (final item in newItems) {
        if (!existingBvids.contains(item.bvid)) {
          _recommendations.add(item);
          existingBvids.add(item.bvid);
        }
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> submitFeedback(String bvid, String type, {String? note}) async {
    await _api.submitFeedback({'bvid': bvid, 'type': type, if (note != null) 'note': note});
    for (var r in _recommendations) {
      if (r.bvid == bvid) r.feedbackType = type;
    }
    notifyListeners();
  }

  Future<void> respondToDelight(String bvid, String response, {String message = ''}) async {
    await _api.respondToDelight(bvid, response, message: message);
    _delights.removeWhere((d) => d.bvid == bvid);
    _delightIndex = _delightIndex.clamp(0, (_delights.length - 1).clamp(0, _delights.length));
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
