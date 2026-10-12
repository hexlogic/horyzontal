import 'package:flutter/material.dart';

import 'autotest.dart';
import 'map/map_page.dart';
import 'transfer/transfer_page.dart';

// cryptography_flutter registers itself: AES-GCM runs in CryptoKit /
// javax.crypto instead of pure Dart.
void main() {
  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Горизонталь: спайк',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3A5A40), useMaterial3: true),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _tab = 0;
  final _map = GlobalKey<MapPageState>();
  final _transfer = GlobalKey<TransferPageState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(seconds: 1)); // let the map view settle
      await Autotest.runIfRequested(
        map: _map.currentState!,
        transfer: _transfer.currentState!,
        selectTab: (i) => setState(() => _tab = i),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [MapPage(key: _map), TransferPage(key: _transfer)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Мапа'),
          NavigationDestination(icon: Icon(Icons.wifi_tethering), label: 'Передача'),
        ],
      ),
    );
  }
}
