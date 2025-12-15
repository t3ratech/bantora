import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/poll.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/poll_card.dart';
import '../widgets/idea_card.dart';
import '../widgets/search_bar.dart';
import 'poll_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Poll> _popularPolls = [];
  List<Poll> _newPolls = [];
  List<Idea> _rawIdeas = [];
  bool _loading = true;
  bool _submittingIdea = false;
  String _searchQuery = '';
  String _statusMessage = '';
  final Set<String> _votingPollIds = <String>{};
  final Set<String> _votedPollIds = <String>{};
  final Set<String> _upvotingIdeaIds = <String>{};
  final TextEditingController _ideaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _loading = true);
    }
    // In a real app, these would be separate API calls with filters
    final polls = await widget.apiService.getPolls();
    final ideas = await widget.apiService.getIdeas();

    setState(() {
      final sortedPolls = polls.toList()
        ..sort((a, b) => b.totalVotes.compareTo(a.totalVotes));

      _popularPolls = sortedPolls.take(3).toList();
      _newPolls = sortedPolls.skip(3).toList();
      _rawIdeas = ideas;
      if (showLoading) {
        _loading = false;
      }
    });
  }

  bool _pollMatchesQuery(Poll poll, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return poll.title.toLowerCase().contains(q) || poll.description.toLowerCase().contains(q);
  }

  bool _ideaMatchesQuery(Idea idea, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return idea.content.toLowerCase().contains(q) ||
        (idea.aiSummary != null && idea.aiSummary!.toLowerCase().contains(q));
  }

  Future<void> _voteOnPoll({required Poll poll, required String optionId}) async {
    if (_votingPollIds.contains(poll.id) || _votedPollIds.contains(poll.id)) return;

    setState(() {
      _votingPollIds.add(poll.id);
    });

    final success = await widget.apiService.vote(
      pollId: poll.id,
      optionId: optionId,
    );

    if (!mounted) return;

    setState(() {
      _votingPollIds.remove(poll.id);
      if (success) {
        _votedPollIds.add(poll.id);
      }
    });

    if (success) {
      setState(() {
        _statusMessage = 'Vote submitted successfully!';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote submitted successfully!')),
      );
      await _loadData(showLoading: false);
    } else {
      setState(() {
        _statusMessage = 'Failed to submit vote. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit vote. Please try again.')),
      );
    }
  }

  Future<void> _upvoteIdea(Idea idea) async {
    if (_upvotingIdeaIds.contains(idea.id)) return;

    setState(() {
      _upvotingIdeaIds.add(idea.id);
    });

    final success = await widget.apiService.upvoteIdea(idea.id);

    if (!mounted) return;

    setState(() {
      _upvotingIdeaIds.remove(idea.id);
      if (success) {
        _rawIdeas = _rawIdeas
            .map((i) => i.id == idea.id
                ? Idea(
                    id: i.id,
                    userPhone: i.userPhone,
                    content: i.content,
                    status: i.status,
                    aiSummary: i.aiSummary,
                    createdAt: i.createdAt,
                    upvotes: i.upvotes + 1,
                  )
                : i)
            .toList();
      }
    });

    if (success) {
      setState(() {
        _statusMessage = 'Upvote received!';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upvote received!')),
      );
      await _loadData(showLoading: false);
    } else {
      setState(() {
        _statusMessage = 'Failed to upvote. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upvote. Please try again.')),
      );
    }
  }

  Future<void> _submitIdea() async {
    if (_ideaController.text.isEmpty || _submittingIdea) return;

    setState(() => _submittingIdea = true);
    final success = await widget.apiService.createIdea(content: _ideaController.text);
    if (!mounted) return;
    setState(() => _submittingIdea = false);

    if (success) {
      _ideaController.clear();
      _loadData(showLoading: false);
      setState(() {
        _statusMessage = 'Idea submitted successfully!';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idea submitted successfully!')),
      );
    } else {
      setState(() {
        _statusMessage = 'Failed to submit idea';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit idea')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;

    final visiblePopularPolls = _popularPolls.where((p) => _pollMatchesQuery(p, _searchQuery)).toList();
    final visibleNewPolls = _newPolls.where((p) => _pollMatchesQuery(p, _searchQuery)).toList();
    final visibleIdeas = _rawIdeas.where((i) => _ideaMatchesQuery(i, _searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.how_to_vote, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('BANTORA'),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
            },
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BantoraSearchBar(
                    onSearch: (query) {
                      setState(() => _searchQuery = query);
                    },
                  ),
                ),
               // Status message area
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Semantics(
                    label: 'status_message:${_statusMessage}',
                    container: true,
                    explicitChildNodes: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border.all(color: colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                ),
                
                // 3-Column Layout
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Center(
                          child: Text(
                            "Please use a larger screen for the 3-column view.",
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Popular
                          Expanded(
                            child: Semantics(
                              label: 'popular_column',
                              container: true,
                              explicitChildNodes: true,
                              child: _buildColumn(
                                title: 'Popular (${visiblePopularPolls.length})',
                                subtitle: 'Polls with high engagement',
                                countSemanticsLabel: 'popular_polls_count:${visiblePopularPolls.length}',
                                children: visiblePopularPolls
                                  .map((p) => _buildPollCardWidget(p, columnTag: 'popular'))
                                  .toList(),
                              ),
                            ),
                          ),
                          
                          // Middle Column: New/AI
                          Expanded(
                            child: Semantics(
                              label: 'new_column',
                              container: true,
                              explicitChildNodes: true,
                              child: _buildColumn(
                                title: 'New / AI (${visibleNewPolls.length})',
                                subtitle: 'Recent AI-processed polls',
                                countSemanticsLabel: 'new_polls_count:${visibleNewPolls.length}',
                                children: visibleNewPolls
                                  .map((p) => _buildPollCardWidget(p, columnTag: 'new'))
                                  .toList(),
                              ),
                            ),
                          ),
                          
                          // Right Column: Raw Ideas
                          Expanded(
                            child: Semantics(
                              label: 'ideas_column',
                              container: true,
                              explicitChildNodes: true,
                              child: _buildColumn(
                                title: 'Raw Ideas (${visibleIdeas.length})',
                                subtitle: 'User submissions',
                                countSemanticsLabel: 'raw_ideas_count:${visibleIdeas.length}',
                                children: [
                                  _buildIdeaInput(),
                                  ...visibleIdeas.map(_buildIdeaCardWidget),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildColumn({
    required String title,
    required String subtitle,
    required List<Widget> children,
    String? countSemanticsLabel,
  }) {
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.transparent, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (countSemanticsLabel != null)
            Opacity(
              opacity: 0.0,
              alwaysIncludeSemantics: true,
              child: Text(
                countSemanticsLabel,
                style: const TextStyle(fontSize: 0),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Divider(color: dividerColor, height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaInput() {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit Your Idea',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'idea_input',
            textField: true,
            child: TextField(
              controller: _ideaController,
              style: TextStyle(color: colorScheme.onSurface),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Propose an idea for African development...',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                filled: true,
                fillColor: colorScheme.surface,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: 'submit_idea_button',
              button: true,
              enabled: !(_ideaController.text.isEmpty || _submittingIdea),
              child: ElevatedButton(
                onPressed: (_ideaController.text.isEmpty || _submittingIdea) ? null : _submitIdea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_submittingIdea ? 'Submitting...' : 'Submit Idea'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCardWidget(Poll poll, {required String columnTag}) {
    // Calculate Yes/No percentages from options
    int yesPercentage = 50; // Default
    int noPercentage = 50;
    
    if (poll.options.length >= 2) {
      final totalVotes = poll.options.fold<int>(0, (sum, opt) => sum + opt.votesCount);
      if (totalVotes > 0) {
        yesPercentage = ((poll.options[0].votesCount / totalVotes) * 100).round();
        noPercentage = 100 - yesPercentage;
      }
    }
    
    final bool isVoting = _votingPollIds.contains(poll.id);
    final bool hasVoted = _votedPollIds.contains(poll.id);
    final String? yesOptionId = poll.options.isNotEmpty ? poll.options[0].id : null;
    final String? noOptionId = poll.options.length > 1 ? poll.options[1].id : null;

    return PollCard(
      pollId: poll.id,
      columnTag: columnTag,
      title: poll.title,
      description: poll.description,
      yesPercentage: yesPercentage,
      noPercentage: noPercentage,
      totalVotes: poll.totalVotes,
      category: poll.category ?? 'General',
      hasVoted: hasVoted,
      isVoting: isVoting,
      onVoteYes: (yesOptionId == null || hasVoted || isVoting)
          ? null
          : () => _voteOnPoll(poll: poll, optionId: yesOptionId),
      onVoteNo: (noOptionId == null || hasVoted || isVoting)
          ? null
          : () => _voteOnPoll(poll: poll, optionId: noOptionId),
    );
  }

  Widget _buildIdeaCardWidget(Idea idea) {
    final bool isUpvoting = _upvotingIdeaIds.contains(idea.id);
    return IdeaCard(
      ideaId: idea.id,
      content: idea.content,
      aiSummary: idea.aiSummary,
      upvotes: idea.upvotes,
      status: idea.status,
      isUpvoting: isUpvoting,
      onUpvote: isUpvoting ? null : () => _upvoteIdea(idea),
    );
  }

  // Old builders kept for backward compatibility during transition
  Widget _buildPollCard(Poll poll) {
    return _buildPollCardWidget(poll, columnTag: 'unknown');
  }

  Widget _buildIdeaCard(Idea idea) {
    return _buildIdeaCardWidget(idea);
  }
}
