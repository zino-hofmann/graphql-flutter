import 'package:http/http.dart';

// @deprecated, backward compatible only
// in case the body is io.File
// in future release, io.File will no longer be supported
// but this stub is noop
Future<Map<String, MultipartFile>> deprecatedHelper(
        body, currentMap, currentPath) async =>
    null;

// @deprecated, backward compatible only
// in case the body is io.File
// in future release, io.File will no longer be supported
// but this stub always returns false
bool isIoFile(object) => false;
