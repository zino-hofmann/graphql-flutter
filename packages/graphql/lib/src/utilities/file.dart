import 'dart:async';
import 'package:http/http.dart';

import './file_stub.dart' as impl
    if (dart.library.html) './file_html.dart'
    if (dart.library.io) './file_io.dart';

/// Input's type must be either `io.File` or `html.File`
FutureOr<MultipartFile> multipartFileFrom(/*io.File or html.File*/ f) => impl.multipartFileFrom(f);
