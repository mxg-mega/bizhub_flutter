import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onScan;
  const BarcodeScannerWidget({super.key, required this.onScan});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: controller.torchEnabled
                ? const Icon(Icons.flash_off, color: Colors.grey)
                : const Icon(Icons.flash_on, color: Colors.yellow),
            // icon: ValueListenableBuilder(
            //   valueListenable: controller.,
            //   builder: (context, state, child) {
            //     switch (state) {
            //       case TorchState.off:
            //         return const Icon(Icons.flash_off, color: Colors.grey);
            //       case TorchState.on:
            //         return const Icon(Icons.flash_on, color: Colors.yellow);
            //     }
            //   },
            // ),'
            onPressed: () {setState(() {
              controller.toggleTorch();
            });},
          ),
          IconButton(
            icon: controller.facing == CameraFacing.front
                ? const Icon(Icons.camera_front)
                : const Icon(Icons.camera_rear),
            // icon: ValueListenableBuilder(
            //   valueListenable: controller.cameraFacingState,
            //   builder: (context, state, child) {
            //     switch (state) {
            //       case CameraFacing.front:
            //         return const Icon(Icons.camera_front);
            //       case CameraFacing.back:
            //         return const Icon(Icons.camera_rear);
            //     }
            //   },
            // ),
            onPressed: () => setState(() {
                controller.switchCamera();
            })  ,
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              widget.onScan(barcode.rawValue!);
              Navigator.pop(context);
              break;
            }
          }
        },
      ),
    );
}
