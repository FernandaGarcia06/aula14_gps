
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Obtém a localização atual do dispositivo
  Future<Position> obterPosicaoAtual() async {
    bool servicoHabilitado =
        await Geolocator.isLocationServiceEnabled();

    if (!servicoHabilitado) {
      throw Exception(
        'O serviço de GPS está desativado no dispositivo.',
      );
    }

    LocationPermission permissao =
        await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();

      if (permissao == LocationPermission.denied) {
        throw Exception(
          'Permissão de localização negada.',
        );
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão negada permanentemente. Altere nas configurações.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Monitora a localização em tempo real
  Stream<Position> monitorarPosicao() {
    const LocationSettings configuracoes =
        LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(
      locationSettings: configuracoes,
    );
  }
}
