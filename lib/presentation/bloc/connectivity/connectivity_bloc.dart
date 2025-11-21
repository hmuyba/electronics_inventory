import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/connectivity_helper.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  StreamSubscription? _connectivitySubscription;

  ConnectivityBloc() : super(ConnectivityInitial()) {
    on<ConnectivityCheckRequested>(_onCheckRequested);
    on<ConnectivityChanged>(_onConnectivityChanged);

    // Escuchar cambios de conectividad
    _connectivitySubscription = ConnectivityHelper.onConnectivityChanged.listen(
      (isConnected) {
        add(ConnectivityChanged(isConnected));
      },
    );
  }

  Future<void> _onCheckRequested(
    ConnectivityCheckRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    final hasConnection = await ConnectivityHelper.hasConnection();
    emit(hasConnection ? ConnectivityOnline() : ConnectivityOffline());
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(event.isConnected ? ConnectivityOnline() : ConnectivityOffline());
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
