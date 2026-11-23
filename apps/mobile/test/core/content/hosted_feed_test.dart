import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:madar_al_huda/core/content/hosted_feed.dart';

void main() {
  test(
    'updates a validated catalog and retains it on 304 and failure',
    () async {
      final dir = await Directory.systemTemp.createTemp('madar-hosted-test');
      addTearDown(() => dir.delete(recursive: true));
      final url = Uri.https('media.example.test', '/catalog.php');
      var requests = 0;
      final client = MockClient((request) async {
        expect(request.url, url);
        requests++;
        return switch (requests) {
          1 => http.Response(
            '{"episodes":[1,2,3]}',
            200,
            headers: {'content-type': 'application/json', 'etag': '"a"'},
          ),
          2 => () {
            expect(request.headers['if-none-match'], '"a"');
            return http.Response(
              '{"episodes":[1,2,3,7]}',
              200,
              headers: {'content-type': 'application/json', 'etag': '"b"'},
            );
          }(),
          3 => () {
            expect(request.headers['if-none-match'], '"b"');
            return http.Response('', 304);
          }(),
          4 => http.Response(
            '{"episodes":false}',
            200,
            headers: {'content-type': 'application/json'},
          ),
          _ => throw http.ClientException('offline'),
        };
      });
      addTearDown(client.close);
      final feed = HostedFeed(client, () async => dir);

      Future<List<int>> load() => feed.load(
        url: url,
        cacheName: 'stories',
        decode: (data) => List<int>.from((data as Map)['episodes'] as List),
        fallback: () async => [1],
      );

      expect(await load(), [1, 2, 3]);
      expect(await load(), [1, 2, 3, 7]);
      expect(await load(), [1, 2, 3, 7]);
      expect(await load(), [1, 2, 3, 7]);
      expect(await load(), [1, 2, 3, 7]);
    },
  );
}
