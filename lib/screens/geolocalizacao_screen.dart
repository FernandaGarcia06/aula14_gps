
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

class GeolocalizacaoScreen extends StatefulWidget {
  const GeolocalizacaoScreen({super.key});

  @override
  State<GeolocalizacaoScreen> createState() =>
      _GeolocalizacaoScreenState();
}

class _GeolocalizacaoScreenState
    extends State<GeolocalizacaoScreen> {

  final LocationService _locationService = LocationService();

  Position? _posicaoAtual;

  bool _carregando = false;
  bool _rastreando = false;

  String? _mensagemErro;

  StreamSubscription<Position>? _positionStreamSub;

  // Captura a localização atual
  Future<void> capturarLocalizacao() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      Position posicao =
          await _locationService.obterPosicaoAtual();

      if (!mounted) return;

      setState(() {
        _posicaoAtual = posicao;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _mensagemErro = erro.toString();
        _carregando = false;
      });
    }
  }

  // Inicia o rastreamento em tempo real
  Future<void> iniciarRastreamento() async {
    if (_rastreando) return;

    setState(() {
      _mensagemErro = null;
    });

    try {
      // Verifica se o GPS está habilitado
      bool gpsAtivo =
          await Geolocator.isLocationServiceEnabled();

      if (!gpsAtivo) {
        throw Exception('Ative o GPS do dispositivo.');
      }

      // Verifica a permissão
      LocationPermission permissao =
          await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        throw Exception(
          'Permissão de localização não concedida.',
        );
      }

      // Inicia o monitoramento
      _positionStreamSub =
          _locationService.monitorarPosicao().listen(
        (Position position) {
          if (!mounted) return;

          setState(() {
            _posicaoAtual = position;
          });
        },
        onError: (erro) {
          if (!mounted) return;

          setState(() {
            _mensagemErro = erro.toString();
          });

          pararRastreamento();
        },
      );

      if (!mounted) {
        await _positionStreamSub?.cancel();
        return;
      }

      setState(() {
        _rastreando = true;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _mensagemErro = erro.toString();
      });
    }
  }

  // Para o rastreamento
  Future<void> pararRastreamento() async {
    await _positionStreamSub?.cancel();
    _positionStreamSub = null;

    if (!mounted) return;

    setState(() {
      _rastreando = false;
    });
  }

  // Define a cor e o texto da precisão
  Color obterCorPrecisao(double precisao) {
    if (precisao < 15) {
      return Colors.green;
    } else if (precisao <= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String obterTextoPrecisao(double precisao) {
    if (precisao < 15) {
      return 'Alta precisão';
    } else if (precisao <= 50) {
      return 'Precisão moderada';
    } else {
      return 'Baixa precisão';
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final precisao = _posicaoAtual?.accuracy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocalização GPS'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Icon(
              Icons.location_on,
              size: 85,
              color: Colors.lightBlue,
            ),

            const SizedBox(height: 10),

            const Text(
              'Localização do dispositivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Capture sua localização atual ou acompanhe '
              'as mudanças em tempo real.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            // Botão de captura
            ElevatedButton.icon(
              onPressed: _carregando
                  ? null
                  : capturarLocalizacao,
              icon: const Icon(Icons.my_location),
              label: const Text(
                'Capturar localização atual',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 12),

            // Botão de iniciar e parar rastreamento
            ElevatedButton.icon(
              onPressed: _rastreando
                  ? pararRastreamento
                  : iniciarRastreamento,
              icon: Icon(
                _rastreando
                    ? Icons.stop
                    : Icons.play_arrow,
              ),
              label: Text(
                _rastreando
                    ? 'Parar rastreamento'
                    : 'Iniciar rastreamento',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rastreando
                    ? Colors.red
                    : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 20),

            // Indicador de carregamento
            if (_carregando)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Mensagem de erro
            if (_mensagemErro != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _mensagemErro!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),

            // Informações da localização
            if (_posicaoAtual != null) ...[
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Dados da localização',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Latitude: ${_posicaoAtual!.latitude}',
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Longitude: ${_posicaoAtual!.longitude}',
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Precisão: ${_posicaoAtual!.accuracy.toStringAsFixed(2)} metros',
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Altitude: ${_posicaoAtual!.altitude.toStringAsFixed(2)} metros',
                      ),

                      const SizedBox(height: 18),

                      // Indicador de precisão
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: obterCorPrecisao(
                            _posicaoAtual!.accuracy,
                          ).withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),

                        child: Row(
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              color: obterCorPrecisao(
                                _posicaoAtual!.accuracy,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Text(
                              obterTextoPrecisao(
                                _posicaoAtual!.accuracy,
                              ),
                              style: TextStyle(
                                color: obterCorPrecisao(
                                  _posicaoAtual!.accuracy,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 15),

            // Status do rastreamento
            Center(
              child: Text(
                _rastreando
                    ? 'Rastreamento em andamento'
                    : 'Rastreamento parado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _rastreando
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
