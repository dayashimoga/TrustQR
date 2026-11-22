import 'dart:io';
import '../config/rbac_config.dart';
import '../store/rbac_store.dart';
import 'rbac_router.dart';

/// Lightweight, high-performance RBAC and Entitlement HTTP server.
class RbacServer {
  final HttpServer _server;
  final RbacConfig config;
  final RbacStore store;
  final RbacRouter router;

  RbacServer._(this._server, this.config, this.store, this.router);

  /// Binds and starts the HTTP server.
  static Future<RbacServer> bind({
    InternetAddress? address,
    int port = 8089,
    RbacConfig? config,
    RbacStore? store,
  }) async {
    final effectiveConfig = config ?? RbacConfig.defaultConfig(address: address, port: port);
    final effectiveStore = store ?? RbacStore();
    final router = RbacRouter(config: effectiveConfig, store: effectiveStore);

    final server = await HttpServer.bind(
      address ?? effectiveConfig.address,
      port,
    );

    final instance = RbacServer._(server, effectiveConfig, effectiveStore, router);
    server.listen(instance.router.handleRequest);
    return instance;
  }

  /// Port on which the HTTP server is listening.
  int get port => _server.port;

  /// Address on which the HTTP server is listening.
  InternetAddress get address => _server.address;

  /// Closes the server.
  Future<void> close({bool force = false}) => _server.close(force: force);
}
