import 'package:flutter/material.dart';
import '../theme.dart';

/// Type of tutorial to display.
enum TutorialType { basic, wallet, tournaments, friends }

/// Simple guide shown on first launch explaining basic gameplay.
class TutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final TutorialType type;
  const TutorialOverlay({Key? key, required this.onDismiss, this.type = TutorialType.basic}) : super(key: key);

  String get _title {
    switch (type) {
      case TutorialType.wallet:
        return 'Wallet';
      case TutorialType.tournaments:
        return 'Tournaments';
      case TutorialType.friends:
        return 'Friends';
      case TutorialType.basic:
      default:
        return 'How to Play';
    }
  }

  List<Widget> _content() {
    switch (type) {
      case TutorialType.wallet:
        return [
          _instruction(Icons.account_balance_wallet,
              'Manage your game coins. Deposit or withdraw anytime.'),
          _instruction(Icons.history, 'View your transaction history below.'),
        ];
      case TutorialType.tournaments:
        return [
          _instruction(Icons.emoji_events,
              'Join tournaments to compete for bigger rewards.'),
          _instruction(Icons.add_circle_outline,
              'Use the add button to create your own.'),
        ];
      case TutorialType.friends:
        return [
          _instruction(Icons.person_add,
              'Add friends by ID and invite them to play.'),
          _instruction(Icons.people, 'Track friend activity in your list.'),
        ];
      case TutorialType.basic:
      default:
        return [
          _instruction(Icons.casino,
              'Roll the dice to determine how many steps a token can move.'),
          _instruction(Icons.touch_app,
              'Tap on a highlighted token to move it forward.'),
          _instruction(Icons.flag, 'Move all tokens home to win the game.'),
        ];
    }
  }

  Widget _instruction(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _content();
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _title,
                style: AppTextStyles.poppinsBold.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              ...content,
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onDismiss,
                child: const Text('Got it!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
