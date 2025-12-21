import 'package:flutter/services.dart';

// Non-web fallback: use a subtle system click.
void playBlink() {
  SystemSound.play(SystemSoundType.click);
}

Future<void> ensureBlinkAudioUnlocked() async {}