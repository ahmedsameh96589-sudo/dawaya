import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../../core/services/api_services.dart';
import '../../../core/theme/app_colors.dart';
import '../models/news_item.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<NewsItem> _items = [];
  bool _loading = true;
  String? _error;
  String? _lastLoadedLanguage;
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) return;
    _didInitialLoad = true;
    _loadNews(AppLocalizer.of(context).languageCode);
  }

  Future<void> _loadNews(String language) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.fetchNews(language: language);
      setState(() {
        _items = items;
        _loading = false;
        _lastLoadedLanguage = language;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizer.of(context);
    if (_lastLoadedLanguage != l10n.languageCode && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadNews(l10n.languageCode);
      });
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.t('news')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(l10n.t('serverError')),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _loadNews(l10n.languageCode),
                        child: Text(l10n.t('retry')),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final date = item.publishedAt.toLocal();
                    final dateText =
                        "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}";
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            child: item.imageUrl.isEmpty
                                ? Container(
                                    height: 160,
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: Icon(
                                        Icons.campaign_outlined,
                                        size: 48,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    item.imageUrl,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              item.summary,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.source.isEmpty
                                        ? dateText
                                        : "${item.source} • $dateText",
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.open_in_new,
                                  size: 14,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
