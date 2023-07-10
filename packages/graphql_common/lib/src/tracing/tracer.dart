/// Tracer is an abstract class that provide the basic blocs to
/// build an application tracer (aka Logger).
///
/// author: Vincenzo Palazzo <vincenzopalazzodev@gmail.com>
abstract class Tracer {
  /// Async function to start to tracing the library at runtime
  /// useful when the user want log the information in an external
  /// source, and it is required an async trace!
  Future<void> asyncTrace(String msg, {Map<String, dynamic>? opts});
}
