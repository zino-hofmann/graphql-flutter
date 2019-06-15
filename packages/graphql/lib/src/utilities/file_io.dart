import 'dart:async';
import 'dart:io' as io;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

Future<MultipartFile> multipartFileFrom(io.File f) async => MultipartFile(
      '',
      f.openRead(),
      await f.length(),
      contentType: MediaType.parse(lookupMimeType(f.path)),
      filename: basename(f.path),
    );
