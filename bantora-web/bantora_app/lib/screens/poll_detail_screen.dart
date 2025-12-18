import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/poll.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
import 'idea_detail_screen.dart';

class PollDetailScreen extends StatefulWidget {
  final Poll poll;
  final ApiService apiService;
  final List<Map<String, dynamic>> categories;

  const PollDetailScreen({
    super.key,
    required this.poll,
    required this.apiService,
    required this.categories,
  });

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  String? _selectedOptionId;
  bool _voting = false;
  bool _hasVoted = false;
  bool _loadingSourceIdeas = true;
  List<Idea> _sourceIdeas = [];

  String _pollShareUrl() {
    final origin = Uri.parse(widget.apiService.baseUrl).origin;
    return '$origin/api/polls/${widget.poll.id}';
  }

  String _pollShareText(String categoryLabel) {
    final buffer = StringBuffer();
    buffer.writeln(widget.poll.title);
    if (widget.poll.description.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(widget.poll.description);
    }
    buffer.writeln();
    buffer.writeln('Category: $categoryLabel');
    buffer.writeln('Link: ${_pollShareUrl()}');
    return buffer.toString().trim();
  }

  @override
  void initState() {
    super.initState();
    _loadSourceIdeas();
  }

  Future<void> _loadSourceIdeas() async {
    final ideas = await widget.apiService.getPollSourceIdeas(widget.poll.id);
    if (!mounted) return;
    setState(() {
      _sourceIdeas = ideas;
      _loadingSourceIdeas = false;
    });
  }

  int get _totalVotes {
    return widget.poll.options.fold<int>(
      0,
      (sum, option) => sum + option.votesCount,
    );
  }

  Future<void> _vote() async {
    if (_selectedOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _voting = true);

    final success = await widget.apiService.vote(
      pollId: widget.poll.id,
      optionId: _selectedOptionId!,
    );

    setState(() {
      _voting = false;
      if (success) _hasVoted = true;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh poll data
      final updatedPoll = await widget.apiService.getPoll(widget.poll.id);
      if (updatedPoll != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PollDetailScreen(
              poll: updatedPoll,
              apiService: widget.apiService,
              categories: widget.categories,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit vote. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.categories.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['id'] == widget.poll.categoryId,
          orElse: () => throw StateError('Unknown poll categoryId: ${widget.poll.categoryId}'),
        );
    final categoryLabelRaw = category['name'];
    if (categoryLabelRaw is! String || categoryLabelRaw.isEmpty) {
      throw StateError('Invalid category name for categoryId: ${widget.poll.categoryId}');
    }
    final categoryLabel = categoryLabelRaw;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poll Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.share(_pollShareText(categoryLabel));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Poll Header
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.poll.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.poll.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.category,
                        categoryLabel,
                        Colors.purple,
                      ),
                      _buildInfoChip(
                        Icons.how_to_vote,
                        '$_totalVotes votes',
                        Colors.blue,
                      ),
                      _buildInfoChip(
                        Icons.public,
                        widget.poll.scope,
                        Colors.green,
                      ),
                      _buildInfoChip(
                        Icons.access_time,
                        _formatDate(widget.poll.createdAt),
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Source Ideas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_loadingSourceIdeas)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_sourceIdeas.isEmpty)
            const Text('No source ideas linked to this poll.')
          else
            ..._sourceIdeas.map((idea) {
              return Card(
                child: ListTile(
                  title: Text(idea.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text("#${idea.hashtags.join(' #')}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IdeaDetailScreen(
                          ideaId: idea.id,
                          apiService: widget.apiService,
                          categories: widget.categories,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

          const SizedBox(height: 24),

          // Voting Section
          if (!_hasVoted && widget.poll.status == 'ACTIVE') ...[
            const Text(
              'Cast Your Vote',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.poll.options.map((option) => _buildVoteOption(option)),
            const SizedBox(height: 16),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _voting ? null : _vote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _voting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'SUBMIT VOTE',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],

          // Results Section
          if (_hasVoted || widget.poll.status != 'ACTIVE') ...[
            const Text(
              'Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.poll.options.map((option) => _buildResultBar(option)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildVoteOption(PollOption option) {
    final isSelected = _selectedOptionId == option.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.deepPurple.withOpacity(0.1) : null,
      child: RadioListTile<String>(
        title: Text(
          option.optionText,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        value: option.id,
        groupValue: _selectedOptionId,
        onChanged: (value) {
          setState(() => _selectedOptionId = value);
        },
        activeColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildResultBar(PollOption option) {
    final percentage = _totalVotes > 0 
        ? (option.votesCount / _totalVotes * 100) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    option.optionText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${option.votesCount} votes',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
