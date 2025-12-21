// Conditional blink sound utility.
// On web, uses the Web Audio API for a soft ping.
// On other platforms, falls back to a system click.

import 'blink_sound_stub.dart' if (dart.library.html) 'blink_sound_web.dart' as impl;

void playBlink() => impl.playBlink();
Future<void> ensureBlinkAudioUnlocked() => impl.ensureBlinkAudioUnlocked();