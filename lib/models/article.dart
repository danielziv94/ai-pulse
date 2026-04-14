import 'package:flutter/material.dart';

class Article {
  final String id;
  final String title;
  final String url;
  final String description;
  String? aiSummary;
  final DateTime pubDate;
  final String source;
  bool isSaved;

  Article({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
    this.aiSummary,
    required this.pubDate,
    required this.source,
    this.isSaved = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(pubDate);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  int get estimatedReadMinutes {
    final wordCount = (description + (aiSummary ?? '')).split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'description': description,
        'aiSummary': aiSummary,
        'pubDate': pubDate.toIso8601String(),
        'source': source,
        'isSaved': isSaved,
      };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        description: json['description'] as String,
        aiSummary: json['aiSummary'] as String?,
        pubDate: DateTime.parse(json['pubDate'] as String),
        source: json['source'] as String,
        isSaved: json['isSaved'] as bool? ?? false,
      );
}

const Map<String, Color> kSourceColors = {
  'OpenAI': Color(0xFF10a37f),
  'Google': Color(0xFF4285f4),
  'Anthropic': Color(0xFFcc785c),
  'Meta AI': Color(0xFF0082fb),
  'Mistral': Color(0xFFff7000),
  'xAI': Color(0xFFe0e0e0),
  'Hugging Face': Color(0xFFff9d00),
  'Cohere': Color(0xFF39594d),
};

const List<String> kSources = [
  'All',
  'Anthropic',
  'OpenAI',
  'Google',
  'Meta AI',
  'Mistral',
  'xAI',
  'Hugging Face',
  'Cohere',
];
