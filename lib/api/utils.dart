/// Decode common HTML entities in API responses.
String decodeHtml(String text) {
  if (text.isEmpty) return text;
  return text
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&mdash;', '\u2014')
      .replaceAll('&ndash;', '\u2013')
      .replaceAll('&hellip;', '\u2026');
}

/// Build a proxy URL for cover images through the backend.
/// Direct URLs are often blocked by CORS.
String proxyImageUrl(String url, String baseUrl) {
  if (url.isEmpty) return '';
  final apiBase = baseUrl.replaceAll('/api', '');
  return '$apiBase/api/image-proxy?url=${Uri.encodeComponent(url)}';
}
