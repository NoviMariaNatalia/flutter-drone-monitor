import 'package:dart_pusher_channels/dart_pusher_channels.dart';

class WebSocketService {
  static PusherChannelsClient? _client;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;

    const options = PusherChannelsOptions.fromHost(
      scheme: 'wss',
      host: 'api-drone.heivet.com',
      port: 443,
      key: 'drone_key_2026',
      shouldSupplyMetadataQueries: true,
    );

    _client = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) {
        print('[WS] Koneksi error: $exception');
        Future.delayed(const Duration(seconds: 3), refresh);
      },
    );

    _client!.onConnectionEstablished.listen((_) {
      print('[WS] Connected ke Reverb!');
    });

    _client!.connect();
    _initialized = true;
    print('[WS] Connecting...');
  }

  static void subscribeToDrone(
      String droneId, {
        required Function(dynamic) onDroneMovement,
        required Function(dynamic) onFloodImageCaptured,
      }) {
    if (_client == null) return;

    final channelName = 'drone.$droneId';
    final channel = _client!.publicChannel(channelName);
    channel.subscribe();

    channel.bind('App\\Events\\DroneMovement').listen((event) {
      print('[WS] DroneMovement: $droneId → ${event.data}');
      onDroneMovement(event.data);
    });

    channel.bind('App\\Events\\FloodImageCaptured').listen((event) {
      print('[WS] FloodImageCaptured: $droneId → ${event.data}');
      onFloodImageCaptured(event.data);
    });

    print('[WS] Subscribed to $channelName');
  }

  static void unsubscribeFromDrone(String droneId) {
    print('[WS] Unsubscribed from drone.$droneId');
  }

  static void disconnect() {
    _client?.dispose();
    _initialized = false;
    _client = null;
    print('[WS] Disconnected');
  }
}