import 'package:flutter/material.dart';
// Updated imports for newton_particles 0.2.2
import 'package:newton_particles/newton_particles.dart';

/// Full screen widget that renders [ParticleField].
///
/// The [controller] can be used to trigger bursts from
/// anywhere in the widget tree.
// class ParticleOverlay extends StatelessWidget {
//   final ParticleController controller;
//   const ParticleOverlay({super.key, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: IgnorePointer(
//         child: ParticleField(controller: controller),
//       ),
//     );
//   }
// }






import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatelessWidget {
  final ConfettiController controller;
  const ConfettiOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ConfettiWidget(
          confettiController: controller,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          maxBlastForce: 20,
          minBlastForce: 5,
          gravity: 0.1,
          colors: const [
            Colors.red,
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.purple,
          ],
        ),
      ),
    );
  }
}