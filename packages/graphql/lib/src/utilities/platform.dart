export './platform_stub.dart'
    if (dart.library.html) './platform_html.dart'
    if (dart.library.io) './platform_io.dart';
