import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

//Screens
// import 'package:colortest/color_picker_screen.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Led App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BluetoothScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  List<BluetoothService> bluetoothServices = [];
  BluetoothCharacteristic? characteristic;
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  void checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isGranted == true &&
        statuses[Permission.bluetoothConnect]?.isGranted == true &&
        statuses[Permission.location]?.isGranted == true) {
      startScan();
    } else {
      print("Permissions not granted");
    }
  }

  void startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    flutterBlue.stopScan();
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      connectedDevice = device;
    });

    bluetoothServices = await device.discoverServices();
    for (var service in bluetoothServices) {
      for (var char in service.characteristics) {
        if (char.properties.write) {
          setState(() {
            characteristic = char;
          });
        }
      }
    }
  }

  void sendData(String data) async {
    if (characteristic != null) {
      await characteristic!.write(data.codeUnits);
      print("Data sent: $data");
    } else {
      print("No writable characteristic found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth App'),
      ),
      body: connectedDevice == null
          ? ListView(
              padding: const EdgeInsets.only(top: 20),
              children: [
                ListTile(
                  onTap: startScan, 
                  title: const Text('Escanear dispositivos'),
                  tileColor: Colors.black,
                  textColor: Colors.white,
                ),

                SizedBox(height: 20), // ignore: prefer_const_constructors

                ...scanResults.map((result) => ListTile(
                      title: Text(result.device.name.isEmpty
                          ? result.device.id.toString()
                          : result.device.name),
                      subtitle: Text(result.device.id.toString()),
                      onTap: () {
                        connectToDevice(result.device);
                      },
                    )),
              ],
            )
          : Column(
              children: [
                Text('Connected to ${connectedDevice!.name}'),
                ElevatedButton(
                  onPressed: () {
                    sendData('Hello Arduino');
                  },
                  child: Text('Send Data'),
                ),
              ],
            ),
    );
  }
}
