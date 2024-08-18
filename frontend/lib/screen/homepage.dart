import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/constants.dart';
import 'package:humanize_big_int/humanize_big_int.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _FileItem {
  final String filename;
  final PlatformFile file;
  _FileItem(this.filename, this.file);
}

class _HomePageState extends State<HomePage> {
  List<_FileItem> files = [];
  Future<void> _add() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

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
  }

  void _removeFileItemAt(int index) {
    setState(() {
      files.removeAt(index);
    });
  }

  void _uploadFiles() {
    var request = http.MultipartRequest('POST', Uri.parse(uploadEndpoint));
    var multipartfiles = files.map((f) => http.MultipartFile.fromBytes(
        'file', f.file.bytes!,
        filename: f.filename));
    request.files.addAll(multipartfiles);
    request.send().then((resp) async {
      String alertMessage = '';
      String alertTitle = AppLocalizations.of(context)!.failure;
      IconData alertIcon = Icons.error;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        var directoryIdBytes = await resp.stream.toBytes();
        var directoryId =  String.fromCharCodes(directoryIdBytes);
        alertTitle = 'Success';
        alertMessage = directoryId;
        alertIcon = Icons.check_box;
        //successful upload
        setState(() {
          files = [];
        });
      } else {
        var errorMsg = '${resp.statusCode} ${resp.reasonPhrase}';
        debugPrint(errorMsg);
        alertMessage = errorMsg;
      }
      showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
                title: Row(children: [
                  Icon(alertIcon),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(alertTitle)
                ]),
                content: Text(alertMessage),
                actions: [
                  FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.ok))
                ],
              ));
    }).onError(
      (error, stackTrace) {
        debugPrint(error.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(appTitle),
      ),
      persistentFooterButtons: const [Text('2024 \u00a9 $authorName')],
      persistentFooterAlignment: AlignmentDirectional.center,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ...(files.isEmpty
                ? [
                    Text(
                      AppLocalizations.of(context)!.help,
                    )
                  ]
                : [
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
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _removeFileItemAt(i);
                                        },
                                      )),
                                    ]))
                                .toList()),
                      ),
                    )
                  ]),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                      onPressed: _add,
                      child: Text(AppLocalizations.of(context)!.add)),
                  ...(files.isNotEmpty
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
