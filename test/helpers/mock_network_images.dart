// Pattern aligned with Flutter's image_provider_network_image_test.dart
// (BSD-style): Fake HttpClient returning a tiny valid PNG for NetworkImage /
// Image.network in widget tests.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1×1 transparent PNG (same bytes as Flutter's kTransparentImage test asset).
const List<int> kTransparentTestPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x06, 0x62, 0x4B,
  0x47, 0x44, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xA0, 0xBD, 0xA7, 0x93, 0x00,
  0x00, 0x00, 0x09, 0x70, 0x48, 0x59, 0x73, 0x00, 0x00, 0x0B, 0x13, 0x00, 0x00,
  0x0B, 0x13, 0x01, 0x00, 0x9A, 0x9C, 0x18, 0x00, 0x00, 0x00, 0x07, 0x74, 0x49,
  0x4D, 0x45, 0x07, 0xE6, 0x03, 0x10, 0x17, 0x07, 0x1D, 0x2E, 0x5E, 0x30, 0x9B,
  0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0x60, 0x00,
  0x02, 0x00, 0x00, 0x05, 0x00, 0x01, 0xE2, 0x26, 0x05, 0x9B, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// Binds [debugNetworkImageHttpClientProvider] to an [HttpClient] that serves
/// [kTransparentTestPng] for every GET. Each request gets a fresh response
/// stream so multiple [Image.network] widgets can load.
///
/// Call [unbindMockNetworkImages] in a `finally` block before the test ends:
/// widget tests verify painting debug flags before `addTearDown` runs.
void bindMockNetworkImages() {
  debugNetworkImageHttpClientProvider = () => _FakeImageHttpClient();
}

void unbindMockNetworkImages() {
  debugNetworkImageHttpClientProvider = null;
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
}

class _FakeImageHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final request = _FakeImageHttpClientRequest();
    final png = Uint8List.fromList(kTransparentTestPng);
    request.response
      ..statusCode = HttpStatus.ok
      ..contentLength = png.length
      ..content = <Uint8List>[png];
    return request;
  }
}

class _FakeImageHttpClientRequest extends Fake implements HttpClientRequest {
  _FakeImageHttpClientRequest() : response = _FakeImageHttpClientResponse();
  final _FakeImageHttpClientResponse response;

  @override
  final HttpHeaders headers = _FakeImageHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => response;
}

class _FakeImageHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int statusCode = HttpStatus.ok;

  @override
  int contentLength = 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  late List<List<int>> content;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(content).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<E> drain<E>([E? futureValue]) async =>
      futureValue ?? futureValue as E;
}

class _FakeImageHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}
