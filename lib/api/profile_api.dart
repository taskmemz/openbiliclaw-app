import '../models/profile.dart';
import 'client.dart';

class ProfileApi {
  final ApiClient _client;
  ProfileApi(this._client);

  Future<ProfileSummary> fetchSummary({int? limit, String? cursor}) async {
    final qs = _buildQuery({'limit': limit?.toString(), 'cursor': cursor});
    final data = await _client.get('/profile-summary$qs');
    return ProfileSummary.fromJson(data);
  }

  Future<Map<String, dynamic>> fetchEditState() => _client.get('/profile/edit-state');

  Future<Map<String, dynamic>> submitEdit({required String target, required String op, String? value, String parent = '', double? weight}) =>
      _client.post('/profile/edit', body: {'target': target, 'op': op, 'value': value, 'parent': parent, 'weight': weight});

  Future<List<Map<String, dynamic>>> fetchPendingNotifications() async {
    final data = await _client.get('/notifications/pending');
    return (data['notifications'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<List<Map<String, dynamic>>> fetchPendingProbes() async {
    final data = await _client.get('/interest-probes/pending');
    return (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<List<Map<String, dynamic>>> fetchPendingAvoidanceProbes() async {
    final data = await _client.get('/avoidance-probes/pending');
    return (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<void> respondToProbe(String domain, String response, {String message = ''}) =>
      _client.post('/interest-probes/respond', body: {'domain': domain, 'response': response, 'message': message});

  Future<void> respondToAvoidanceProbe(String domain, String response, {String message = ''}) =>
      _client.post('/avoidance-probes/respond', body: {'domain': domain, 'response': response, 'message': message});

  Future<Map<String, dynamic>> fetchRuntimeStatus() => _client.get('/runtime-status');

  String _buildQuery(Map<String, String?> params) {
    final pairs = params.entries.where((e) => e.value != null && e.value!.isNotEmpty).map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value!)}').join('&');
    return pairs.isNotEmpty ? '?$pairs' : '';
  }
}
