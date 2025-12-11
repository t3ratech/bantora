import 'package:flutter/material.dart';

class IdeaCard extends StatefulWidget {
  final String content;
  final String? aiSummary;
  final int upvotes;
  final String status;
  final VoidCallback? onUpvote;

  const IdeaCard({
    super.key,
    required this.content,
    this.aiSummary,
    required this.upvotes,
    required this.status,
    this.onUpvote,
  });

  @override
  State<IdeaCard> createState() => _IdeaCardState();
}

class _IdeaCardState extends State<IdeaCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Content or AI Summary
              if (widget.aiSummary != null) ...[
                Text(
                  widget.aiSummary!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Original: ${widget.content}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                Text(
                  widget.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              
              // Upvote Button and Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.upvotes} upvotes',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onUpvote,
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: const Text('Upvote'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A859),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      elevation: MaterialStateProperty.resolveWith<double>(
                        (Set<MaterialState> states) {
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processed':
      case 'ai-processed':
        return const Color(0xFF00A859);
      case 'pending':
      case 'raw':
        return const Color(0xFF64748B);
      case 'popular':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF1E1E1E);
    }
  }
}
