import 'package:graphql_common/src/tracing/tracer.dart';
import 'package:logger/logger.dart';

class LoggerTracer extends Tracer {
  late Logger _logger;

  LoggerTracer(
      {LogFilter? filter,
      LogPrinter? printer,
      LogOutput? output,
      Level? level}) {
    _logger =
        Logger(filter: filter, printer: printer, output: output, level: level);
  }

  @override
  Future<void> asyncTrace(String msg, {Map<String, dynamic>? opts}) {
    return Future(() => _logger.d(msg));
  }
}
