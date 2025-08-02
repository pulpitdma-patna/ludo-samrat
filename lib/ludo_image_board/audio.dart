
import 'package:audioplayers/audioplayers.dart';

class Audio {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playMove() async {
    Future.delayed(const Duration(seconds: 1),() async {
      // await _audioPlayer.play(AssetSource('sounds/move.wav'));
    },);
  }

  static Future<void> playKill() async {
    await _audioPlayer.play(AssetSource('sounds/laugh.mp3'));
  }

  static Future<void> rollDice() async {
    await _audioPlayer.play(AssetSource('sounds/roll_the_dice.mp3'));
  }
}

// import 'package:just_audio/just_audio.dart';
//
// class Audio {
//   static AudioPlayer audioPlayer = AudioPlayer();
//
//   static Future<void> playMove() async {
//     var duration = await audioPlayer.setAsset('assets/sounds/move.wav');
//     audioPlayer.play();
//     return Future.delayed(duration ?? Duration.zero);
//   }
//
//   static Future<void> playKill() async {
//     var duration = await audioPlayer.setAsset('assets/sounds/laugh.mp3');
//     audioPlayer.play();
//     return Future.delayed(duration ?? Duration.zero);
//   }
//
//   static Future<void> rollDice() async {
//     var duration = await audioPlayer.setAsset('assets/sounds/roll_the_dice.mp3');
//     audioPlayer.play();
//     return Future.delayed(duration ?? Duration.zero);
//   }
// }
