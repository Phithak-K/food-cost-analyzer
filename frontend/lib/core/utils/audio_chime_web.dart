import 'dart:js_interop';

@JS('playKitchenBellChime')
external void _playKitchenBellChime();

void playBellChime() {
  try {
    _playKitchenBellChime();
  } catch (_) {
    // Graceful fallback if user hasn't interacted with browser page yet
  }
}
