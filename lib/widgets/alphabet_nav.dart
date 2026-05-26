import 'package:flutter/material.dart';
import '../config/theme.dart';

class AlphabetNav extends StatefulWidget {
  final List<String> letters;
  final String? selectedLetter;
  final ValueChanged<String> onLetterTap;

  const AlphabetNav({
    super.key,
    required this.letters,
    this.selectedLetter,
    required this.onLetterTap,
  });

  @override
  State<AlphabetNav> createState() => _AlphabetNavState();
}

class _AlphabetNavState extends State<AlphabetNav> {
  int _getLetterIndex(double localY, double height) {
    if (widget.letters.isEmpty) return -1;
    final letterHeight = height / widget.letters.length;
    final index = (localY / letterHeight).floor();
    return index.clamp(0, widget.letters.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final localY = box.globalToLocal(details.globalPosition).dy;
          final idx = _getLetterIndex(localY, box.size.height);
          if (idx >= 0 && idx < widget.letters.length) {
            widget.onLetterTap(widget.letters[idx]);
          }
        },
        onVerticalDragUpdate: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final localY = box.globalToLocal(details.globalPosition).dy;
          final idx = _getLetterIndex(localY, box.size.height);
          if (idx >= 0 && idx < widget.letters.length) {
            widget.onLetterTap(widget.letters[idx]);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.letters.map((letter) {
                final isSelected = letter == widget.selectedLetter;
                return GestureDetector(
                  onTap: () => widget.onLetterTap(letter),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 24,
                    height: 18,
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: AppTheme.textStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
