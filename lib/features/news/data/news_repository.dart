import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/news_item.dart';

class NewsRepository {
  NewsRepository(this._api);

  final ApiClient _api;

  Future<List<NewsItem>> fetchNews({String language = 'en'}) async {
    final body = await _api.get(
      '/news',
      query: {'language': language.toLowerCase() == 'ar' ? 'ar' : 'en'},
    );
    return dataList(body, 'articles').map(NewsItem.fromJson).toList();
  }
}

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(ref.watch(apiClientProvider)),
);

/// Health news in the given language (`en` or `ar`).
final newsProvider = FutureProvider.autoDispose.family<List<NewsItem>, String>(
  (ref, language) =>
      ref.watch(newsRepositoryProvider).fetchNews(language: language),
);
