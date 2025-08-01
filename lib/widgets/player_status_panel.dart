import 'package:flutter/material.dart';

class PlayerStatusPanel extends StatelessWidget {
  final Map<int, List<int>> positions;
  final Map<int, Color> playerColors;
  final Map<int, int> captures;

  const PlayerStatusPanel({
    super.key,
    required this.positions,
    required this.playerColors,
    required this.captures,
  });

  @override
  Widget build(BuildContext context) {
    final entries = positions.keys.toList()..sort();
    return Card(
      color: Colors.white70,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final pid in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: playerColors[pid] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'P$pid: ${positions[pid]?.length ?? 0} left, ${captures[pid] ?? 0} captured',
                      style: const TextStyle(fontSize: 11), // smaller font
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

