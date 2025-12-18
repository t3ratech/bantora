import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/idea.dart';
import '../models/poll.dart';
import '../services/api_service.dart';
import 'poll_detail_screen.dart';

class IdeaDetailScreen extends StatefulWidget {
  final String ideaId;
  final ApiService apiService;
  final List<Map<String, dynamic>> categories;

  const IdeaDetailScreen({
    super.key,
    required this.ideaId,
    required this.apiService,
    required this.categories,
  });

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  bool _loading = true;
  Idea? _idea;
  List<Poll> _generatedPolls = [];

  String _ideaShareUrl(String ideaId) {
    final origin = Uri.parse(widget.apiService.baseUrl).origin;
    return '$origin/api/ideas/$ideaId';
  }

  String _ideaShareText(Idea idea, String categoryLabel) {
    final buffer = StringBuffer();
    buffer.writeln('Idea:');
    buffer.writeln(idea.content);
    buffer.writeln();
    buffer.writeln('Category: $categoryLabel');
    if (idea.hashtags.isNotEmpty) {
      buffer.writeln("Hashtags: #${idea.hashtags.join(' #')}");
    }
    buffer.writeln('Link: ${_ideaShareUrl(idea.id)}');
    return buffer.toString().trim();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final idea = await widget.apiService.getIdea(widget.ideaId);
    final polls = await widget.apiService.getIdeaGeneratedPolls(widget.ideaId);

    if (!mounted) return;
    setState(() {
      _idea = idea;
      _generatedPolls = polls;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final idea = _idea;
    if (idea == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Idea Details'),
        ),
        body: const Center(
          child: Text('Idea not found.'),
        ),
      );
    }

    final category = widget.categories.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['id'] == idea.categoryId,
          orElse: () => throw StateError('Unknown idea categoryId: ${idea.categoryId}'),
        );
    final categoryLabelRaw = category['name'];
    if (categoryLabelRaw is! String || categoryLabelRaw.isEmpty) {
      throw StateError('Invalid category name for categoryId: ${idea.categoryId}');
    }
    final categoryLabel = categoryLabelRaw;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.share(_ideaShareText(idea, categoryLabel));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(Icons.category, categoryLabel),
                      _chip(Icons.info_outline, idea.status.toUpperCase()),
                      _chip(Icons.thumb_up, '${idea.upvotes} upvotes'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    idea.content,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (idea.aiSummary != null && idea.aiSummary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'AI Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(idea.aiSummary!),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Hashtags',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: idea.hashtags
                        .map((tag) => Chip(
                              label: Text('#$tag'),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Generated Polls',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_generatedPolls.isEmpty)
            const Text('No polls generated from this idea yet.')
          else
            ..._generatedPolls.map((poll) {
              final category = widget.categories.cast<Map<String, dynamic>>().firstWhere(
                    (c) => c['id'] == poll.categoryId,
                    orElse: () => throw StateError('Unknown poll categoryId: ${poll.categoryId}'),
                  );
              final categoryLabelRaw = category['name'];
              if (categoryLabelRaw is! String || categoryLabelRaw.isEmpty) {
                throw StateError('Invalid category name for categoryId: ${poll.categoryId}');
              }
              final categoryLabel = categoryLabelRaw;

              return Card(
                child: ListTile(
                  title: Text(poll.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(categoryLabel),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PollDetailScreen(
                          poll: poll,
                          apiService: widget.apiService,
                          categories: widget.categories,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
