import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';

class ColorPickerScreen extends StatefulWidget {
  final BluetoothDevice? selectedDevice;
  final BluetoothConnection? connection;
  const ColorPickerScreen({super.key, required this.selectedDevice, required this.connection});

  @override
  // ignore: library_private_types_in_public_api
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {

  final _controller = CircleColorPickerController(
    initialColor: Colors.blue,
  );

  Color selectedColor = Colors.blue; // Color inicial
  double redValue = 0.0;
  double greenValue = 0.0;
  double blueValue = 255.0;
  bool _isSwitched = false;

  void disconnectDevice() {
    widget.connection?.finish();
    Navigator.pop(context);
  }

  void sendColorToArduino(Color color) async {
    int red = color.red;
    int green = color.green;
    int blue = color.blue;

    String data = '$red,$green,$blue';
    widget.connection?.output.add(Uint8List.fromList(utf8.encode(data)));
  }

  void sendOffOn(String data) async {
    widget.connection?.output.add(Uint8List.fromList(utf8.encode(data)));
  }

  void updateSelectedColor() {
    // Calcula el color combinado usando los valores de los sliders
    _controller.color = Color.fromARGB(255, redValue.toInt(), greenValue.toInt(), blueValue.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isSwitched ? Colors.white : Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text('Conectado a dispositivo: ${widget.selectedDevice?.name ?? 'Ninguno'}', style: TextStyle(fontSize: 15, color: _isSwitched ? Colors.black : Colors.white)),
            SizedBox(height: 20),
            _isSwitched  ? const Text('ENCENDIDO',style: TextStyle(fontSize: 24,))
            : const Text('APAGADO',style: TextStyle(fontSize: 24, color: Colors.white)),
            Switch(
              value: _isSwitched,
              onChanged: (value) {
                sendOffOn(value ? '1' : '0');
                setState(() {
                  _isSwitched = value;
                });
              },
            ),
            _isSwitched ? CircleColorPicker(
              controller: _controller,
              onChanged: (color) {
                setState(() {
                  selectedColor = color;
                  redValue = color.red.toDouble();
                  greenValue = color.green.toDouble();
                  blueValue = color.blue.toDouble();
                });
              },
            ): Container(),
            const SizedBox(height: 20),
            _isSwitched ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ColorSlider(
                  label: 'Red',
                  value: redValue,
                  onChanged: (value) {
                    setState(() {
                      redValue = value;
                      updateSelectedColor();
                    });
                  },
                ),
                ColorSlider(
                  label: 'Green',
                  value: greenValue,
                  onChanged: (value) {
                    setState(() {
                      greenValue = value;
                      updateSelectedColor();
                    });
                  },
                ),
                ColorSlider(
                  label: 'Blue',
                  value: blueValue,
                  onChanged: (value) {
                    setState(() {
                      blueValue = value;
                      updateSelectedColor();
                    });
                  },
                ),
              ],
            ) : Container(),
            const SizedBox(height: 20),
            _isSwitched ? ElevatedButton(
              onPressed: () {
                // connectToDevice(); // Conecta al Arduino
                sendColorToArduino(selectedColor); // Envía el color seleccionado
              },
              child: const Text('Enviar color al Arduino'),
            ): Container(),

            ElevatedButton(
              onPressed: () {
                sendOffOn("0");
                disconnectDevice();
              },
              child: const Text('Desconectar dispositivo')),
          ],
        ),
      ),
    );
  }
}

class ColorSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const ColorSlider({super.key, 
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0,
          max: 255,
          divisions: 255,
        ),
      ],
    );
  }
}