import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
  late String serverURL;
  late PrettyQrDecoration decoration;
  var linkrecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    linkrecognizer.onTap = () {
      launchUrlString(serverURL);
    };
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
    serverURL = 'https://${host}:${widget.port}';
    qrCode = QrCode.fromData(
      data: serverURL,
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
    var fontSize = 20.0;
    return Scaffold(
      // appBar: AppBar(),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                  text: TextSpan(children: [
                TextSpan(
                  text: 'Scan QR code or the link below.',
                  style: TextStyle(color: Colors.black, fontSize: fontSize),
                ),
                const TextSpan(
                  text: '\nYour browser may complain about certificates. It is safe to ignore this and proceed to the page\n',
                   style: TextStyle(color: Colors.black,),
                ),
                TextSpan(
                    text: serverURL,
                    style: TextStyle(color: Colors.blue, fontSize: fontSize),
                    recognizer: linkrecognizer),
                const TextSpan(text: '\n\n')
              ])),
              SizedBox(
                  width: screenSize.width * 0.2,
                  child: PrettyQrView(
                    qrImage: qrImage,
                    decoration: decoration,
                  )),
            ]),
      ),
    );
  }

  @override
  void dispose() {
    server.stop();
    super.dispose();
  }
}
