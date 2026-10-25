import 'audio_chime_stub.dart'
    if (dart.library.js_interop) 'audio_chime_web.dart';

class AudioChime {
  /// Plays a crisp kitchen bell sound ("Ding!")
  static void play() {
    playBellChime();
  }
}
