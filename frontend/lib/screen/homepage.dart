import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/constants.dart';
import 'package:http/http.dart';
import 'package:humanize_big_int/humanize_big_int.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _FileItem {
  final String filename;
  final PlatformFile file;
  double uploadProgress = 0;

  _FileItem(this.filename, this.file);
}

class _HomePageState extends State<HomePage> {
  List<_FileItem> files = [];
  bool uploading = false;
  double uploadProgress = 0;
  int bytesSent = 0;
  int totalBytes = 0;

  void _add() {
    FilePicker.platform
        .pickFiles(allowMultiple: true, withReadStream: true)
        .then((result) {
      if (result != null) {
        var tmpFiles = List<_FileItem>.from(files);
        tmpFiles.addAll(result.files.map((file) => _FileItem(file.name, file)));

        var filenames = <dynamic>{};
        tmpFiles.retainWhere((f) => filenames.add(f.filename));

        setState(() {
          files = tmpFiles.toList();
        });
      } else {
        // User canceled the picker
      }
    });
  }

  void _removeFileItemAt(int index) {
    setState(() {
      files.removeAt(index);
    });
  }

  void _uploadFiles() {
    setState(() {
      uploading = true;
    });

    bytesSent = 0;
    totalBytes = files.fold(
      0,
      (preVal, f) => preVal + f.file.size,
    );
    var transformer = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytesSent += data.length;
        setState(() {
          uploadProgress = bytesSent.toDouble() / totalBytes.toDouble();
          print('Upload progress: $uploadProgress');
        });
        sink.add(data);
      },
    );

    var request = MultipartRequest('POST', Uri.parse(uploadEndpoint))
      ..files.addAll(files.map((f) => MultipartFile(
          'file', f.file.readStream!.transform(transformer), f.file.size,
          filename: f.filename)));

    request.send().whenComplete(() {
      setState(() {
        uploading = false;
      });
    }).then((resp) {
      if (!(resp.statusCode >= 200 && resp.statusCode < 300)) {
        debugPrint("Has failure !!!");
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: const Text(
                    'Something went wrong. Are you on the same network as the server?'),
                icon: const Icon(Icons.error),
                title: const Text('Error'),
                actions: [
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Ok'))
                ],
              );
            });
      } else {
        resp.stream.toBytes().then((dirIDBytes) {
          var dirIDStr = String.fromCharCodes(dirIDBytes);
          setState(() {
            files = [];
          });
          return dirIDStr;
        }).then((dirID) => showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text(
                      'Uploaded successfully. The upload directory is $dirID'),
                  icon: const Icon(Icons.done),
                  title: const Text('Completed'),
                  actions: [
                    FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Ok'))
                  ],
                );
              },
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var authorTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse(authorWebsite));
      };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(appTitle),
        centerTitle: true,
      ),
      persistentFooterButtons: [
        Text.rich(TextSpan(
            text: '2024 \u00a9 $authorName', recognizer: authorTapRecognizer))
      ],
      persistentFooterAlignment: AlignmentDirectional.center,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ...(files.isEmpty
                ? [Text(AppLocalizations.of(context)!.help)]
                : [
                    ...(uploading
                        ? [
                            LinearProgressIndicator(
                              value: uploadProgress,
                            )
                          ]
                        : []),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                            columns: [
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.filename)),
                              DataColumn(
                                  label:
                                      Text(AppLocalizations.of(context)!.size)),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.action)),
                            ],
                            rows: files
                                .mapIndexed<DataRow>((i, f) => DataRow(cells: [
                                      DataCell(Text(
                                        f.filename,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DataCell(
                                          Text('${humanizeInt(f.file.size)}B')),
                                      DataCell(uploading
                                          ? Container() //Empty widget
                                          : IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () {
                                                _removeFileItemAt(i);
                                              },
                                            )),
                                    ]))
                                .toList()),
                      ),
                    )

//
                  ]),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                      onPressed: _add,
                      child: Text(AppLocalizations.of(context)!.add)),
                  ...((files.isNotEmpty && !uploading)
                      ? [
                          const SizedBox(width: 5),
                          FilledButton(
                            onPressed: _uploadFiles,
                            child: Text(AppLocalizations.of(context)!.upload),
                          ),
                        ]
                      : [])
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
