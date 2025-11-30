import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../models/idea.dart';
import '../services/api_service.dart';
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
      appBar: AppBar(
        title: const Text('Bantora'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return const Center(child: Text("Please use a larger screen for the 3-column view."));
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Popular
                    Expanded(
                      child: _buildColumn(
                        title: 'Popular Concepts',
                        color: Colors.amber.shade100,
                        children: _popularPolls.map((p) => _buildPollCard(p)).toList(),
                      ),
                    ),
                    // Middle Column: New/AI
                    Expanded(
                      child: _buildColumn(
                        title: 'New AI Polls',
                        color: Colors.blue.shade50,
                        children: _newPolls.map((p) => _buildPollCard(p)).toList(),
                      ),
                    ),
                    // Right Column: Raw Ideas
                    Expanded(
                      child: _buildColumn(
                        title: 'Raw Ideas Feed',
                        color: Colors.grey.shade100,
                        children: [
                          _buildIdeaInput(),
                          ..._rawIdeas.map((i) => _buildIdeaCard(i)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildColumn({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ideaController,
              decoration: const InputDecoration(
                hintText: 'Propose an idea...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitIdea,
              child: const Text('Submit Idea'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollCard(Poll poll) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PollDetailScreen(
                poll: poll,
                apiService: widget.apiService,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poll.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(poll.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text('${poll.totalVotes} votes', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdeaCard(Idea idea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.content),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User: ${idea.userPhone}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${idea.upvotes} upvotes',
                  style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
