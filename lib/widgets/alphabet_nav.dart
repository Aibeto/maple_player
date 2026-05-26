import 'package:flutter/material.dart';
import '../config/theme.dart';

class AlphabetNav extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: letters.map((letter) {
              final isSelected = letter == selectedLetter;
              return GestureDetector(
                onTap: () => onLetterTap(letter),
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
    );
  }
}
