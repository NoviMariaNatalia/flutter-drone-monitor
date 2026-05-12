import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';

class WebSocketService {
  static PusherChannelsClient? _client;
  static bool _initialized = false;
  static VoidCallback? _onConnected;

  static void init({VoidCallback? onConnected}) {
    if (_initialized) return;

    _onConnected = onConnected;

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
      _onConnected?.call(); // panggil callback setelah connected
    });

    _client!.connect();
    _initialized = true;
    print('[WS] Connecting...');
  }

  static void subscribeToMonitor({
    required Function(dynamic) onStatusChanged,
  }) {
    if (_client == null) return;

    final channel = _client!.publicChannel('drones-monitor');
    channel.subscribe();

    // Gunakan global eventStream dan filter manual
    _client!.eventStream.listen((event) {
      // print('[WS] RAW EVENT: ${event.name} | channel: ${event.channelName} | data: ${event.data}');

      if (event.channelName == 'drones-monitor' && event.name == 'status.changed') {
        print('[WS] StatusChanged → ${event.data}');
        onStatusChanged(event.data);
      }
    });

    print('[WS] Subscribed to drones-monitor');
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