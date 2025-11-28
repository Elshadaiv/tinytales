import 'package:audioplayers/audioplayers.dart';

class BackgroundMusicService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> start() async
  {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource("audio/TinyTalesLobbyMusic.mp3"), volume: 0.12);
  }

  static Future<void> stop() async
  {
    await _player.stop();
  }
}