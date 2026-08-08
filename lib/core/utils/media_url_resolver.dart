import '../constants/api_constants.dart';

String resolveMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) return trimmed;

  final rawBaseUrl = ApiConstants.baseUrl.trim();
  final normalizedBaseUrl =
      rawBaseUrl.startsWith('http://') || rawBaseUrl.startsWith('https://')
      ? rawBaseUrl
      : 'http://$rawBaseUrl';
  final baseUri = Uri.parse(normalizedBaseUrl);
  final originUri = baseUri.replace(path: '', query: '', fragment: '');
  final relativePath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return originUri.resolve(relativePath).toString();
}
