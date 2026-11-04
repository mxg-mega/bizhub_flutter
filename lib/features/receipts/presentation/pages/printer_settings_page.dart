import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    final isConnected = await bluetooth.isConnected;
    final devices = await bluetooth.getBondedDevices();
    
    setState(() {
      _devices = devices;
      _connected = isConnected ?? false;
    });
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: const CommonAppBar(actions: []),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thermal Printer Settings', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 24.h),
              _buildDeviceSelector(),
              SizedBox(height: 32.h),
              const Divider(),
              ListTile(
                leading: Icon(Icons.bluetooth, color: _connected ? Colors.green : Colors.grey),
                title: Text(_connected ? 'Status: Connected' : 'Status: Disconnected'),
                trailing: ElevatedButton(
                  onPressed: _connected ? _disconnect : _connect,
                  child: Text(_connected ? 'Disconnect' : 'Connect'),
                ),
              ),
              if (_connected) ...[
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Send Test Print'),
                    onPressed: _sendTestPrint,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildDeviceSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paired Devices'),
          SizedBox(height: 12.h),
          DropdownButtonFormField<BluetoothDevice>(
            initialValue: _selectedDevice,
            hint: const Text('Select a printer'),
            items: _devices
                .map((final device) => DropdownMenuItem(
                      value: device,
                      child: Text(device.name ?? 'Unknown Device'),
                    ))
                .toList(),
            onChanged: (final device) => setState(() => _selectedDevice = device),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      );

  void _connect() async {
    if (_selectedDevice != null) {
      await bluetooth.connect(_selectedDevice!);
      setState(() => _connected = true);
    }
  }

  void _disconnect() async {
    await bluetooth.disconnect();
    setState(() => _connected = false);
  }

  void _sendTestPrint() async {
    if (_connected) {
      bluetooth.printCustom('BizModule Test Print', 3, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('Connection Successful!', 1, 1);
      bluetooth.printNewLine();
      bluetooth.printQRcode('https://bizmodule.web.app', 200, 200, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
    }
  }
}
