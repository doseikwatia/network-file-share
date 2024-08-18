import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:user_interface/server.dart';

class ServerPage extends StatefulWidget {
  final String host;
  final int port;
  final String uploadDir;
  ServerPage(this.host, this.port, this.uploadDir);
  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  late Server server;
  late QrCode qrCode;
  late QrImage qrImage;
  late PrettyQrDecoration decoration;

  @override
  void initState() {
    super.initState();
    try {
      var currentDir = Directory.current.absolute.path;
      SecurityContext securityContext = SecurityContext();
      securityContext.usePrivateKey(path.join(currentDir, 'cert', 'key.pem'));
      securityContext
          .useCertificateChain(path.join(currentDir, 'cert', 'cert.pem'));
      server = Server(widget.host, widget.port, securityContext,
          uploadDir: widget.uploadDir);
      server.start();
    } on Exception catch (e) {
      var snackBar = SnackBar(content: Text('Failed to start the server'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      print(e);
    }

    var host = widget.host.contains(":") ? '[${widget.host}]' : widget.host;
    qrCode = QrCode.fromData(
      data: 'https://${host}:${widget.port}',
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );

    qrImage = QrImage(qrCode);

    decoration = const PrettyQrDecoration(
      shape: PrettyQrSmoothSymbol(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR code to upload files'),
      ),
      body: Center(
        child: SizedBox(
          width: screenSize.width * 0.2,
          child: PrettyQrView(
            qrImage: qrImage,
            decoration: decoration,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    server.stop();
    super.dispose();
  }
}
