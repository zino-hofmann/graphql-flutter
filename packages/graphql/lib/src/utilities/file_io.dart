import 'dart:async';
import 'dart:io' as io;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

MediaType contentType(f) {
  final a = lookupMimeType(f.path);
  if (a == null) {
    return null;
  }
  final b = MediaType.parse(a);
  return b;
}

Future<MultipartFile> multipartFileFrom(io.File f) async => MultipartFile(
      '',
      f.openRead(),
      await f.length(),
      contentType: contentType(f),
      filename: basename(f.path),
    );
