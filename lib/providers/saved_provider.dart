import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../api/saved_api.dart';

class SavedItem {
  final String id;
  final String bvid;
  final String title;
  final String coverUrl;
  final String upName;
  final String reason;

  SavedItem({required this.id, required this.bvid, this.title = '', this.coverUrl = '', this.upName = '', this.reason = ''});

  factory SavedItem.fromJson(Map<String, dynamic> json) => SavedItem(
    id: json['id']?.toString() ?? '',
    bvid: json['bvid'] ?? '',
    title: json['title'] ?? '',
    coverUrl: json['cover_url'] ?? '',
    upName: json['up_name'] ?? '',
    reason: json['reason'] ?? '',
  );
}

class SavedProvider extends ChangeNotifier {
  final SavedApi _api;

  List<SavedItem> _watchLater = [];
  List<SavedItem> _favorites = [];

  SavedProvider(ApiClient client) : _api = SavedApi(client);

  List<SavedItem> get watchLater => _watchLater;
  List<SavedItem> get favorites => _favorites;

  Future<void> loadWatchLater() async {
    try {
      final items = await _api.fetchWatchLater();
      _watchLater = items.map((e) => SavedItem.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadFavorites() async {
    try {
      final items = await _api.fetchFavorites();
      _favorites = items.map((e) => SavedItem.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleWatchLater(String bvid, bool add) async {
    try {
      if (add) { await _api.addToWatchLater(bvid); } else { await _api.removeFromWatchLater(bvid); }
      await loadWatchLater();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String bvid, bool add) async {
    try {
      if (add) { await _api.addToFavorite(bvid); } else { await _api.removeFromFavorite(bvid); }
      await loadFavorites();
    } catch (_) {}
  }
}
