import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Every host the app contacts on its own. Online tiles come from
/// OpenFreeMap, map packs from this repository's GitHub Releases (GitHub
/// redirects downloads to its asset hosts). Hosts of tile sources the user
/// adds are allowed on top of these, see [Net.userHosts].
/// tools/ci/check_domains.sh keeps code URLs within this list.
const allowedHosts = {
  'tiles.openfreemap.org',
  'github.com',
  'objects.githubusercontent.com',
  'release-assets.githubusercontent.com',
};

/// Map packs: release `maps` of github.com/hexlogic/horyzontal. A debug build
/// may point at a local server with `--dart-define=PACKS_BASE_URL=...`.
const packsBaseUrl = String.fromEnvironment(
  'PACKS_BASE_URL',
  defaultValue: 'https://github.com/hexlogic/horyzontal/releases/download/maps/',
);

const onlineStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

class NetworkBlocked implements Exception {
  const NetworkBlocked(this.reason);
  final String reason;
  @override
  String toString() => 'NetworkBlocked($reason)';
}

/// HTTP client that refuses hosts outside [allowedHosts] and [userHosts]
/// (also after redirects) and anything at all in offline-only mode.
class Net {
  Net({required this.offlineOnly, Set<String> Function()? userHosts}) : userHosts = userHosts ?? (() => const {});

  final bool Function() offlineOnly;

  /// Hosts of the tile sources the user added.
  final Set<String> Function() userHosts;

  static bool _debugOverride(Uri u) =>
      packsBaseUrl.startsWith('http://') && u.toString().startsWith(packsBaseUrl);

  void check(Uri u) {
    if (offlineOnly()) throw const NetworkBlocked('offline-only');
    if (u.scheme != 'https' && !_debugOverride(u)) throw NetworkBlocked('scheme ${u.scheme}');
    if (!allowedHosts.contains(u.host) && !userHosts().contains(u.host) && !_debugOverride(u)) {
      throw NetworkBlocked('host ${u.host}');
    }
  }

  /// GET with manual redirects so every hop is checked. [headers] e.g. Range.
  Future<HttpClientResponse> get(Uri url, {Map<String, String> headers = const {}, HttpClient? client}) async {
    client ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..userAgent = 'Horyzontal';
    var u = url;
    for (var hop = 0; hop < 6; hop++) {
      check(u);
      final req = await client.getUrl(u);
      req.followRedirects = false;
      headers.forEach(req.headers.set);
      final res = await req.close();
      if (res.isRedirect) {
        await res.drain<void>();
        u = u.resolve(res.headers.value(HttpHeaders.locationHeader)!);
        continue;
      }
      return res;
    }
    throw const HttpException('Too many redirects');
  }

  Future<String> getString(Uri url) async {
    final res = await get(url);
    if (res.statusCode != 200) {
      await res.drain<void>();
      throw HttpException('HTTP ${res.statusCode}', uri: url);
    }
    return res.transform(utf8.decoder).join();
  }
}
