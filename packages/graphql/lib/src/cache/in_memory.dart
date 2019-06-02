// @todo refactor this with other in_memory_* files
export './in_memory_stub.dart'
    if (dart.library.html) './in_memory_html.dart'
    if (dart.library.io) './in_memory_io.dart';
