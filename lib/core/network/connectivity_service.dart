import 'dart:async';
import 'dart:io';

/// Lightweight connectivity checker (no extra dependency).
/// Attempts a DNS lookup to check if the device has internet access.
class ConnectivityService {
  bool _isOnline = true;
  final _controller = StreamController<bool>.broadcast();

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isOnline = false;
    } on TimeoutException catch (_) {
      _isOnline = false;
    }
    _controller.add(_isOnline);
    return _isOnline;
  }

  void dispose() {
    _controller.close();
  }
}
