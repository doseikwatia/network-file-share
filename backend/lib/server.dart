import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_flutter_asset/shelf_flutter_asset.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as path;
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:uuid/uuid.dart';

class Server {
  String address;
  String staticDir;
  String indexFile;
  String uploadDir;
  SecurityContext securityContext;
  int port;
  HttpServer? server;
  Uuid uuid = const Uuid();

  Server(this.address, this.port, this.securityContext,
      {this.staticDir = 'web',
      this.indexFile = 'index.html',
      this.uploadDir = 'uploads'}) {}
  void start() {
    var router = Router();
    var assetHandler =
        createStaticHandler(staticDir,defaultDocument: indexFile);
    router.get('/<ignored|.*>', assetHandler);
    router.post('/uploads', this.upload);
    shelf_io
        .serve(router, address, port, securityContext: securityContext)
        .then((server) {
      this.server = server;
      this.server!.autoCompress = true;
      print('server is running');
    });
  }

  void stop() {
    server!.close();
  }

  Future upload(Request request) async {
    MultipartRequest? multipartRequest = request.multipart();
    if (multipartRequest != null) {
      var dirID = uuid.v6();
      var dirname = path.join(uploadDir, dirID);
      Directory(dirname).createSync();
      await for (final part in multipartRequest.parts) {
        var contentDisposition = part.headers['content-disposition']!;
        final filename = RegExp(r'filename="([^"]*)"')
            .firstMatch(contentDisposition)
            ?.group(1);
        var file = File(path.join(dirname, filename));
        await part.pipe(file.openWrite());
      }
      return Response.ok(dirID);
    } else {
      return Response.badRequest(body: 'No multipart request found');
    }
  }
}
