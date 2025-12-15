import 'package:flutter/material.dart';

class PollCard extends StatefulWidget {
  final String pollId;
  final String columnTag;
  final String title;
  final String description;
  final int yesPercentage;
  final int noPercentage;
  final int totalVotes;
  final String category;
  final VoidCallback? onVoteYes;
  final VoidCallback? onVoteNo;
  final bool hasVoted;
  final bool isVoting;

  const PollCard({
    super.key,
    required this.pollId,
    required this.columnTag,
    required this.title,
    required this.description,
    required this.yesPercentage,
    required this.noPercentage,
    required this.totalVotes,
    required this.category,
    this.onVoteYes,
    this.onVoteNo,
    required this.hasVoted,
    required this.isVoting,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'poll_card:${widget.columnTag}:${widget.pollId}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E1E1E),
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00A859),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                widget.description,
                style: const TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // Percentage Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPercentage('Yes', widget.yesPercentage, const Color(0xFF00A859)),
                  _buildPercentage('No', widget.noPercentage, const Color(0xFFDC143C)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Vote Buttons
              Row(
                children: [
                  Expanded(
                    child: _build3DButton(
                      semanticsLabel: 'poll_vote_yes_button:${widget.pollId}',
                      label: widget.isVoting ? 'Voting...' : 'Yes',
                      color: const Color(0xFF00A859),
                      onPressed: widget.onVoteYes,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _build3DButton(
                      semanticsLabel: 'poll_vote_no_button:${widget.pollId}',
                      label: widget.isVoting ? 'Voting...' : 'No',
                      color: const Color(0xFFDC143C),
                      onPressed: widget.onVoteNo,
                    ),
                  ),
                ],
              ),
              Semantics(
                label: 'poll_vote_disabled:${widget.pollId}:${widget.hasVoted}',
                child: const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              
              // Total Votes
              Semantics(
                label: 'poll_total_votes:${widget.pollId}:${widget.totalVotes}',
                child: const SizedBox.shrink(),
              ),
              Text(
                '${widget.totalVotes.toString()} votes',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildPercentage(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$percentage%',
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA0A0A0),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _build3DButton({
    required String semanticsLabel,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final bool enabled = onPressed != null;
    final Color backgroundColor = enabled ? color : const Color(0xFF1E1E1E);
    final Color foregroundColor = enabled ? Colors.white : const Color(0xFF64748B);

    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: enabled,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
          shadowColor: backgroundColor,
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (!enabled) {
                return 0;
              }
              if (states.contains(MaterialState.hovered)) {
                return 8;
              }
              if (states.contains(MaterialState.pressed)) {
                return 2;
              }
              return 4;
            },
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}
