import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../services/api_service.dart';

class PollDetailScreen extends StatefulWidget {
  final Poll poll;
  final ApiService apiService;

  const PollDetailScreen({
    super.key,
    required this.poll,
    required this.apiService,
  });

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  String? _selectedOptionId;
  bool _voting = false;
  bool _anonymous = false;
  bool _hasVoted = false;

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
      anonymous: _anonymous,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poll Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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

          // Voting Section
          if (!_hasVoted && widget.poll.status == 'ACTIVE') ...[
            const Text(
              'Cast Your Vote',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.poll.options.map((option) => _buildVoteOption(option)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Vote anonymously'),
              subtitle: const Text('Your identity will not be recorded'),
              value: _anonymous,
              onChanged: (value) {
                setState(() => _anonymous = value ?? false);
              },
              activeColor: Colors.deepPurple,
            ),
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
