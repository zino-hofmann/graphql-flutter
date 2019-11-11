import 'dart:io' as io;

import 'package:http/http.dart';
import 'package:graphql/src/utilities/file_io.dart' show multipartFileFrom;

// @deprecated, backward compatible only
// in case the body is io.File
// in future release, io.File will no longer be supported
Future<Map<String, MultipartFile>> deprecatedHelper(
    body, currentMap, currentPath) async {
  if (body is io.File) {
    return currentMap
      ..addAll(<String, MultipartFile>{
        currentPath.join('.'): await multipartFileFrom(body)
      });
  }
  return null;
}

bool isIoFile(object) {
  final r = object is io.File;
  if (r) {
    print(r'''
⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️ DEPRECATION WARNING ⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️

Please do not use `File` direcly anymore. Instead, use
`MultipartFile`. There's also a utitlity method to help you
`import 'package:graphql/utilities.dart' show multipartFileFrom;`

⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️ DEPRECATION WARNING ⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️
    ''');
  }
  return r;
}
