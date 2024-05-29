import 'package:colortest/color_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const FlutterBluetoothApp());
}

class FlutterBluetoothApp extends StatelessWidget {
  const FlutterBluetoothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conexión bluetooth con Arduino',
      theme: ThemeData(
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
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  BluetoothDevice? connectedDevice;
  List<BluetoothDevice> bondedDevices = [];

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  void checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (  
        statuses[Permission.bluetoothScan]?.isGranted == true &&
        statuses[Permission.bluetooth]?.isGranted == true &&
        statuses[Permission.bluetoothConnect]?.isGranted == true &&
        statuses[Permission.location]?.isGranted == true) {
      getBondedDevices();
    } else {
      print("Permissions not granted");
    }
  }

  void getBondedDevices() async {
    bondedDevices = await bluetooth.getBondedDevices();
    setState(() {});
  }

  void connectToDevice(BluetoothDevice device) async {

    try {
      connection = await BluetoothConnection.toAddress(device.address);
    setState(() {
      connectedDevice = device;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ColorPickerScreen(selectedDevice: connectedDevice, connection: connection,)),
      );
    });
    } catch(e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: 
          ListView(
              padding: const EdgeInsets.only(top: 70),
              children: [
                Center(
                  child: Text("Dispositivos bluetooth conectados", style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 20,),
                ...bondedDevices.map((device) => ListTile(
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.address.toString()),
                      onTap: () {
                        connectToDevice(device);
                      },
                      trailing: Text('Conectar'),
                    )),
              ],
            )
    );
  }
}
