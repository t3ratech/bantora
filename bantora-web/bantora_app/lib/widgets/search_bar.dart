import 'package:flutter/material.dart';

class BantoraSearchBar extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final String hintText;

  const BantoraSearchBar({
    super.key,
    this.onSearch,
    this.hintText = 'Search polls, ideas...',
  });

  @override
  State<BantoraSearchBar> createState() => _BantoraSearchBarState();
}

class _BantoraSearchBarState extends State<BantoraSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused ? const Color(0xFF00A859) : const Color(0xFF1E1E1E),
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF00A859).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: _isFocused ? const Color(0xFF00A859) : const Color(0xFFA0A0A0),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                label: 'search_input',
                textField: true,
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFA0A0A0),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: widget.onSearch,
                  onChanged: widget.onSearch,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              Semantics(
                label: 'search_clear_button',
                button: true,
                child: IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFFA0A0A0),
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch?.call('');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
