import 'package:dawayaa/features/news/models/news_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a NewsAPI article', () {
    final item = NewsItem.fromJson({
      'source': {'name': 'BBC'},
      'title': 'New flu vaccine',
      'description': 'Summary',
      'url': 'https://bbc.com/a',
      'urlToImage': 'https://bbc.com/a.jpg',
      'publishedAt': '2026-09-01T10:00:00Z',
    });

    expect(item.id, 'https://bbc.com/a');
    expect(item.source, 'BBC');
    expect(item.summary, 'Summary');
    expect(item.imageUrl, 'https://bbc.com/a.jpg');
    expect(item.publishedAt, DateTime.utc(2026, 9, 1, 10));
  });

  test('falls back sensibly when fields are missing', () {
    final item = NewsItem.fromJson({'content': 'Body text'});

    expect(item.title, 'Health update');
    expect(item.summary, 'Body text');
    expect(item.source, '');
    expect(item.url, '');
  });
}
