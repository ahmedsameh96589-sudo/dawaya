class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.publishedAt,
    required this.source,
    required this.url,
  });

  final String id;
  final String title;
  final String summary;
  final String imageUrl;
  final DateTime publishedAt;
  final String source;
  final String url;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? source =
        json["source"] as Map<String, dynamic>?;
    final String sourceName = source?["name"] as String? ?? "";
    final String publishedAtRaw =
        json["publishedAt"] as String? ?? DateTime.now().toIso8601String();
    final String title = json["title"] as String? ?? "Health update";
    final String url = json["url"] as String? ?? "";
    final String id = url.isNotEmpty ? url : "$title-$publishedAtRaw";
    return NewsItem(
      id: id,
      title: title,
      summary:
          json["description"] as String? ?? json["content"] as String? ?? "",
      imageUrl: json["urlToImage"] as String? ?? "",
      publishedAt: DateTime.tryParse(publishedAtRaw) ?? DateTime.now(),
      source: sourceName,
      url: url,
    );
  }
}
