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
import 'idea_detail_screen.dart';

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
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _hashtags = [];
  String? _selectedCategoryId;
  String? _pollCategoryFilter;
  String? _pollHashtagFilter;
  String? _ideaCategoryFilter;
  String? _ideaHashtagFilter;
  bool _loading = true;
  bool _submittingIdea = false;
  String _searchQuery = '';
  String _statusMessage = '';
  final Set<String> _votingPollIds = <String>{};
  final Set<String> _votedPollIds = <String>{};
  final Set<String> _upvotingIdeaIds = <String>{};
  final TextEditingController _ideaController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _ideaMatchesCategoryFilter(Idea idea) {
    final filter = _ideaCategoryFilter;
    if (filter == null || filter.isEmpty) {
      return true;
    }
    return idea.categoryId == filter;
  }

  bool _ideaMatchesHashtagFilter(Idea idea) {
    final filter = _ideaHashtagFilter;
    if (filter == null || filter.isEmpty) {
      return true;
    }
    final needle = filter.toLowerCase().trim();
    return idea.hashtags.any((h) => h.toLowerCase().trim() == needle);
  }

  @override
  void dispose() {
    _ideaController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _loading = true);
    }
    try {
      final categories = await widget.apiService.getCategories();
      final hashtags = await widget.apiService.getHashtags();

      final categoryId = _pollCategoryFilter;
      final hashtag = _pollHashtagFilter;

      final popularPolls = await widget.apiService.getPolls(
        categoryId: categoryId,
        hashtag: hashtag,
        sort: 'votes',
        limit: 3,
      );
      final newPolls = await widget.apiService.getPolls(
        categoryId: categoryId,
        hashtag: hashtag,
        sort: 'created',
      );

      final ideas = await widget.apiService.getIdeas(
        status: 'PENDING',
        categoryId: _ideaCategoryFilter,
        hashtag: _ideaHashtagFilter,
      );

      setState(() {
        _popularPolls = popularPolls;
        _newPolls = newPolls;
        _rawIdeas = ideas;
        _categories = categories;
        _hashtags = hashtags;

        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          final firstId = _categories.first['id'];
          if (firstId is String && firstId.isNotEmpty) {
            _selectedCategoryId = firstId;
          }
        }

        if (showLoading) {
          _loading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to load data: $e';
        if (showLoading) {
          _loading = false;
        }
      });
    }
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
                    categoryId: i.categoryId,
                    hashtags: i.hashtags,
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
    if (_submittingIdea) return;

    final content = _ideaController.text.trim();
    final categoryId = _selectedCategoryId;
    final tags = _hashtagsController.text
        .split(RegExp(r'[\s,]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => t.startsWith('#') ? t.substring(1) : t)
        .toList();

    if (content.isEmpty) return;

    if (categoryId == null || categoryId.isEmpty) {
      setState(() {
        _statusMessage = 'Please select a category';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (tags.isEmpty) {
      setState(() {
        _statusMessage = 'Please add at least one hashtag';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one hashtag')),
      );
      return;
    }

    setState(() => _submittingIdea = true);
    final success = await widget.apiService.createIdea(
      content: content,
      categoryId: categoryId,
      hashtags: tags,
    );
    if (!mounted) return;
    setState(() => _submittingIdea = false);

    if (success) {
      _ideaController.clear();
      _hashtagsController.clear();
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

    final visiblePopularPolls = _popularPolls.where((p) => _pollMatchesQuery(p, _searchQuery)).toList();
    final visibleNewPolls = _newPolls.where((p) => _pollMatchesQuery(p, _searchQuery)).toList();
    final visibleIdeas = _rawIdeas
        .where((i) => _ideaMatchesQuery(i, _searchQuery))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.how_to_vote, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('BANTORA'),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('tab_polls'), text: 'Polls'),
              Tab(key: Key('tab_ideas'), text: 'Ideas'),
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
              key: const Key('logout_button'),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BantoraSearchBar(
                      onSearch: (query) {
                        setState(() => _searchQuery = query);
                      },
                    ),
                  ),
                  if (_statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Semantics(
                        label: 'status_message:${_statusMessage}',
                        container: true,
                        explicitChildNodes: true,
                        child: Container(
                          key: Key('status_message:${_statusMessage}'),
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPollsTab(
                          visiblePopularPolls: visiblePopularPolls,
                          visibleNewPolls: visibleNewPolls,
                        ),
                        _buildIdeasTab(visibleIdeas: visibleIdeas),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPollsTab({
    required List<Poll> visiblePopularPolls,
    required List<Poll> visibleNewPolls,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filters = Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildPollFilters(),
        );

        if (constraints.maxWidth < 900) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              filters,
              Text(
                'Popular (${visiblePopularPolls.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...visiblePopularPolls.map((p) => _buildPollCardWidget(p, columnTag: 'popular')),
              const SizedBox(height: 24),
              Text(
                'New / AI (${visibleNewPolls.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...visibleNewPolls.map((p) => _buildPollCardWidget(p, columnTag: 'new')),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                label: 'popular_column',
                container: true,
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
            Expanded(
              child: Semantics(
                label: 'new_column',
                container: true,
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
          ],
        );
      },
    );
  }

  Widget _buildIdeasTab({required List<Idea> visibleIdeas}) {
    return ListView(
      key: const Key('ideas_list'),
      padding: const EdgeInsets.all(16),
      children: [
        Opacity(
          opacity: 0.0,
          alwaysIncludeSemantics: true,
          child: Text(
            'ideas_count:${visibleIdeas.length}',
            key: const Key('ideas_count_text'),
            style: const TextStyle(fontSize: 0),
          ),
        ),
        _buildIdeaFilters(),
        _buildIdeaInput(),
        ...visibleIdeas.map(_buildIdeaCardWidget),
      ],
    );
  }

  Widget _buildPollFilters() {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('All categories'),
      ),
      ..._categories
          .map((c) {
            final id = c['id'];
            final name = c['name'];
            if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
              return null;
            }
            return DropdownMenuItem<String>(
              value: id,
              child: Text(name),
            );
          })
          .whereType<DropdownMenuItem<String>>()
    ];

    return Semantics(
      label: 'poll_filters',
      container: true,
      explicitChildNodes: true,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _pollCategoryFilter ?? '',
              items: items,
              onChanged: (value) {
                setState(() {
                  _pollCategoryFilter = (value == null || value.isEmpty) ? null : value;
                  _loadData(showLoading: false);
                });
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _pollHashtagFilter ?? '',
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All hashtags'),
                ),
                ..._hashtags
                    .map((h) {
                      final tag = h['tag'];
                      if (tag is! String || tag.isEmpty) {
                        return null;
                      }
                      return DropdownMenuItem<String>(
                        value: tag,
                        child: Text('#$tag'),
                      );
                    })
                    .whereType<DropdownMenuItem<String>>()
              ],
              onChanged: (value) {
                setState(() {
                  _pollHashtagFilter = (value == null || value.isEmpty) ? null : value;
                  _loadData(showLoading: false);
                });
              },
              decoration: const InputDecoration(
                labelText: 'Hashtag',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaFilters() {
    if (_categories.isEmpty && _hashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoryItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('All categories'),
      ),
      ..._categories
          .map((c) {
            final id = c['id'];
            final name = c['name'];
            if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
              return null;
            }
            return DropdownMenuItem<String>(
              value: id,
              child: Text(name),
            );
          })
          .whereType<DropdownMenuItem<String>>()
    ];

    final hashtagItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('All hashtags'),
      ),
      ..._hashtags
          .map((h) {
            final tag = h['tag'];
            if (tag is! String || tag.isEmpty) {
              return null;
            }
            return DropdownMenuItem<String>(
              value: tag,
              child: Text('#$tag'),
            );
          })
          .whereType<DropdownMenuItem<String>>()
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        label: 'idea_filters',
        container: true,
        explicitChildNodes: true,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 360,
              child: DropdownButtonFormField<String>(
                value: _ideaCategoryFilter ?? '',
                items: categoryItems,
                onChanged: (value) {
                  setState(() {
                    _ideaCategoryFilter = (value == null || value.isEmpty) ? null : value;
                    _loadData(showLoading: false);
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: DropdownButtonFormField<String>(
                value: _ideaHashtagFilter ?? '',
                items: hashtagItems,
                onChanged: (value) {
                  setState(() {
                    _ideaHashtagFilter = (value == null || value.isEmpty) ? null : value;
                    _loadData(showLoading: false);
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Hashtag',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
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
              key: const Key('idea_input'),
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
          if (_categories.isEmpty)
            Text(
              'Loading categories...',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            )
          else
            Semantics(
              label: 'idea_category_select',
              container: true,
              child: DropdownButtonFormField<String>(
                key: const Key('idea_category_select'),
                value: _selectedCategoryId,
                items: _categories
                    .map((c) {
                      final id = c['id'];
                      final name = c['name'];
                      if (id is! String || id.isEmpty || name is! String) {
                        return null;
                      }
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Semantics(
                          label: 'idea_category_option:$id',
                          button: true,
                          child: Text(name),
                        ),
                      );
                    })
                    .whereType<DropdownMenuItem<String>>()
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Semantics(
            label: 'idea_hashtags_input',
            textField: true,
            child: TextField(
              key: const Key('idea_hashtags_input'),
              controller: _hashtagsController,
              style: TextStyle(color: colorScheme.onSurface),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Hashtags (comma or space separated), e.g. #water #agriculture',
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
              enabled: !(_ideaController.text.isEmpty || _hashtagsController.text.isEmpty || _selectedCategoryId == null || _submittingIdea),
              child: ElevatedButton(
                key: const Key('submit_idea_button'),
                onPressed: (_ideaController.text.isEmpty || _hashtagsController.text.isEmpty || _selectedCategoryId == null || _submittingIdea)
                    ? null
                    : _submitIdea,
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

    final category = _categories.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['id'] == poll.categoryId,
          orElse: () => throw StateError('Unknown poll categoryId: ${poll.categoryId}'),
        );
    final categoryLabelRaw = category['name'];
    if (categoryLabelRaw is! String || categoryLabelRaw.isEmpty) {
      throw StateError('Invalid category name for categoryId: ${poll.categoryId}');
    }
    final categoryLabel = categoryLabelRaw;

    return PollCard(
      pollId: poll.id,
      columnTag: columnTag,
      title: poll.title,
      description: poll.description,
      yesPercentage: yesPercentage,
      noPercentage: noPercentage,
      totalVotes: poll.totalVotes,
      categoryLabel: categoryLabel,
      onOpen: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PollDetailScreen(
              poll: poll,
              apiService: widget.apiService,
              categories: _categories,
            ),
          ),
        );
      },
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
      onOpen: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IdeaDetailScreen(
              ideaId: idea.id,
              apiService: widget.apiService,
              categories: _categories,
            ),
          ),
        );
      },
      isUpvoting: isUpvoting,
      onUpvote: isUpvoting ? null : () => _upvoteIdea(idea),
    );
  }

}
