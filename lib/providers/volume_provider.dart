import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class VolumeProvider extends ChangeNotifier {
  double _volume = 0.0;
  bool _isMuted = true;
  StreamSubscription? _volumeListener;

  double get volume => _volume;
  bool get isMuted => _isMuted;

  Future<void> init() async {
    try {
      _volume = await FlutterVolumeController.getVolume() ?? 0.0;
      _volumeListener = FlutterVolumeController.addListener((volume) {
        _volume = volume;
        _isMuted = volume <= 0.01;
        notifyListeners();
      });
    } catch (e) {
      print('Volume controller init error: $e');
    }
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    _isMuted = value <= 0.01;
    await FlutterVolumeController.setVolume(value);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      await setVolume(0.5);
    } else {
      await setVolume(0.0);
    }
  }

  @override
  void dispose() {
    _volumeListener?.cancel();
    super.dispose();
  }
}
