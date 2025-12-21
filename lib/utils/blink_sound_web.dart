// Web implementation using package:web (JS interop) for a soft "bling".
import 'package:web/web.dart' as web;

web.AudioContext? _ctx;

Future<void> ensureBlinkAudioUnlocked() async {
  if (_ctx != null && _ctx!.state == 'suspended') {
    await Future.microtask(() => _ctx!.resume());
  }
}

void playBlink() {
  _ctx ??= web.AudioContext();
  final ctx = _ctx!;

  final osc = ctx.createOscillator();
  final gain = ctx.createGain();

  // Soft triangle wave for a gentler bling
  osc.type = 'triangle';
  // Slightly randomize pitch to feel more lively
  final baseFreq = 880; // A5
  final jitter = (web.window.performance.now() % 30).toDouble(); // 0..30 Hz jitter
  osc.frequency.value = baseFreq + jitter;

  osc.connect(gain);
  gain.connect(ctx.destination);

  final t = ctx.currentTime;
  // Quick attack and short decay for a tiny ping
  gain.gain.setValueAtTime(0.0001, t);
  gain.gain.exponentialRampToValueAtTime(0.08, t + 0.01);
  gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.12);

  osc.start(0);
  osc.stop(t + 0.14);
}