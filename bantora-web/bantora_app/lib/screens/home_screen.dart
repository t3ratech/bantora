import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
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
  final TextEditingController _ideaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    // In a real app, these would be separate API calls with filters
    final polls = await widget.apiService.getPolls();
    final ideas = await widget.apiService.getIdeas();

    setState(() {
      // Mocking logic for columns
      _popularPolls = polls.where((p) => p.totalVotes > 10).toList();
      _newPolls = polls.where((p) => p.totalVotes <= 10).toList();
      _rawIdeas = ideas;
      _loading = false;
    });
  }

  Future<void> _submitIdea() async {
    if (_ideaController.text.isEmpty) return;
    
    final success = await widget.apiService.createIdea(_ideaController.text);
    if (success) {
      _ideaController.clear();
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idea submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit idea')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.how_to_vote, color: const Color(0xFF00A859)),
            const SizedBox(width: 8),
            const Text('BANTORA'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A859)))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BantoraSearchBar(
                    onSearch: (query) {
                      // TODO: Implement search filtering
                      print('Search query: $query');
                    },
                  ),
                ),
                
                // 3-Column Layout
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return const Center(
                          child: Text(
                            "Please use a larger screen for the 3-column view.",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Popular
                          Expanded(
                            child: _buildColumn(
                              title: 'Popular',
                              subtitle: 'Polls with high engagement',
                              children: _popularPolls.map(_buildPollCardWidget).toList(),
                            ),
                          ),
                          
                          // Middle Column: New/AI
                          Expanded(
                            child: _buildColumn(
                              title: 'New / AI',
                              subtitle: 'Recent AI-processed polls',
                              children: _newPolls.map(_buildPollCardWidget).toList(),
                            ),
                          ),
                          
                          // Right Column: Raw Ideas
                          Expanded(
                            child: _buildColumn(
                              title: 'Raw Ideas',
                              subtitle: 'User submissions',
                              children: [
                                _buildIdeaInput(),
                                ..._rawIdeas.map(_buildIdeaCardWidget),
                              ],
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
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFA0A0A0),
            ),
          ),
          const Divider(color: Color(0xFF1E1E1E), height: 24),
          Expanded(
            child: ListView(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit Your Idea',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ideaController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Propose an idea for African development...',
              hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
              filled: true,
              fillColor: Color(0xFF000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF1E1E1E)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitIdea,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A859),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Submit Idea'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCardWidget(Poll poll) {
    // Calculate Yes/No percentages from options
    int yesPercentage = 50; // Default
    int noPercentage = 50;
    
    if (poll.options != null && poll.options!.length >= 2) {
      final totalVotes = poll.options!.fold<int>(0, (sum, opt) => sum + opt.votesCount);
      if (totalVotes > 0) {
        yesPercentage = ((poll.options![0].votesCount / totalVotes) * 100).round();
        noPercentage = 100 - yesPercentage;
      }
    }
    
    return PollCard(
      title: poll.title,
      description: poll.description,
      yesPercentage: yesPercentage,
      noPercentage: noPercentage,
      totalVotes: poll.totalVotes,
      category: poll.category ?? 'General',
      onVoteYes: () {
        // TODO: Implement vote handler
        print('Voted Yes on: ${poll.title}');
      },
      onVoteNo: () {
        // TODO: Implement vote handler
        print('Voted No on: ${poll.title}');
      },
    );
  }

  Widget _buildIdeaCardWidget(Idea idea) {
    return IdeaCard(
      content: idea.content,
      aiSummary: idea.aiSummary,
      upvotes: idea.upvotes,
      status: idea.status ?? 'PENDING',
      onUpvote: () {
        // TODO: Implement upvote handler  
        print('Upvoted: ${idea.content}');
      },
    );
  }

  // Old builders kept for backward compatibility during transition
  Widget _buildPollCard(Poll poll) {
    return _buildPollCardWidget(poll);
  }

  Widget _buildIdeaCard(Idea idea) {
    return _buildIdeaCardWidget(idea);
  }
}
