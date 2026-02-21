import 'package:just_audio/just_audio.dart';

class AdhanAudioService {
  AdhanAudioService._();
  static final instance = AdhanAudioService._();

  final _player = AudioPlayer();

  Future<void> playAdhan() async {
    await _player.setAsset('assets/audio/adhan.mp3');
    await _player.play();
  }
}