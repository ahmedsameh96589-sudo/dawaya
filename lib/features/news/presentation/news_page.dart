import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_states.dart';
import '../data/news_repository.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizer.of(context);
    // Keyed by language, so switching language loads (and caches) that feed.
    final provider = newsProvider(l10n.languageCode);
    final news = ref.watch(provider);
    Future<void> refresh() => ref.refresh(provider.future);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.t('news')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: news.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ErrorRetryView(error: l10n.t('serverError'), onRetry: refresh),
          data: (items) => items.isEmpty
              ? const EmptyStateView(icon: Icons.article_outlined, title: 'No news right now')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
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
        ),
      ),
    );
  }
}
