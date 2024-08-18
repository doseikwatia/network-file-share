import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:user_interface/constants.dart';
import 'package:user_interface/screen/server_page.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> hostIPs = [];
  String hostIP = "";
  int port = portNumber;
  String uploadDir = path.join(Directory.current.path,'upload');
  @override
  initState() {
    super.initState();
    //creating upload directory
    var uploadDirectory = Directory.fromRawPath(Uint8List.fromList(uploadDir.codeUnits));
    if (!uploadDirectory.existsSync()){
      uploadDirectory.createSync();
    }
    //get network interfaces
    NetworkInterface.list().then((interfaceList) {
      var addresses = interfaceList.fold(
        <String>[],
        (previousValue, element) {
          previousValue.addAll(element.addresses
              .where((a) => !a.isLinkLocal && !a.isMulticast)
              .map((a) => a.address));
          return previousValue;
        },
      );
      setState(() {
        hostIPs = addresses;
        hostIP = addresses.first;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(appTitle),
      ),
      body: Center(
        child: SizedBox(
          width: max(
              MediaQuery.of(context).size.width * 0.45,
              10 *
                  hostIPs.fold(
                      0,
                      (previousValue, element) =>
                          max(previousValue, element.length.toDouble()))),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                      label: Text('Upload Directory'),
                      icon: Icon(Icons.folder),
                          ),
                        readOnly: true,
                        // initialValue: uploadDir,
                        controller: TextEditingController(text: uploadDir),
                        onTap: () {
                          FilePicker.platform.getDirectoryPath(
                            initialDirectory: uploadDir,
                            dialogTitle: 'Pick upload directory')
                          .then((dirname){
                            if (dirname != null){
                              setState(() {
                                uploadDir = dirname;
                              });
                            }
                          });
                        },
                ),
                DropdownButtonFormField(
                    decoration: InputDecoration(
                        icon: Icon(Icons.house_outlined),
                        label: Text('Address')),
                    value: hostIP,
                    items: hostIPs
                        .toSet()
                        .toList()
                        .map<DropdownMenuItem<String>>((h) => DropdownMenuItem(
                              child: Text(h),
                              value: h,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        hostIP = value!;
                      });
                    }),
                SizedBox(
                  height: 10,
                ),
                TextFormField(
                    onChanged: (value) {
                      setState(() {
                        port = int.tryParse(value) ?? 0;
                      });
                    },
                    initialValue: port.toString(),
                    decoration: InputDecoration(
                        icon: Icon(Icons.propane_outlined),
                        label: Text('Port')),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) {
                          if (newValue.text.isEmpty) {
                            return newValue;
                          }
                          var newPort = int.parse(newValue.text);
                          return (newPort >= minPortNumber &&
                                  newPort <= maxPortNumber)
                              ? newValue
                              : oldValue;
                        },
                      )
                    ]),
                SizedBox(
                  height: 10,
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ServerPage(hostIP, port, uploadDir)));
                  },
                  child: Text(startServer),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
