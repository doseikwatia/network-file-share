import 'dart:async';

import 'package:http/http.dart';

class ProgressMultipartRequest extends MultipartRequest {
  final void Function(int bytes, int totalBytes) progress;
  ProgressMultipartRequest(super.method, super.uri, this.progress);

  Future<StreamedResponse> send() async {
    final totalBytes = contentLength;
    var client =  Client();
    int bytes = 0;

    var transformer = StreamTransformer.fromHandlers(handleDone: (EventSink<List<int>>sink) {
      sink.close();
      client.close();
    },handleData: (List<int> data,EventSink<List<int>> sink){
      bytes += data.length;
      sink.add(data);
      progress(bytes,totalBytes);
    },);
    try {
      var response = await client.send(this);
      var stream = response.stream.transform(transformer);
      return  StreamedResponse( ByteStream(stream), response.statusCode,
          contentLength: response.contentLength,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase);
    } catch (_) {
      client.close();
      rethrow;
    }
  }
}
