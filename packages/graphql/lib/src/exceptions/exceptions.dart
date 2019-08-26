import './_base_exceptions.dart' as _b;
import 'package:graphql/src/exceptions/io_network_exception.dart' as _n;

export './_base_exceptions.dart' hide translateFailure;
export './graphql_error.dart';
export './operation_exception.dart';
export './network_exception_stub.dart'
    if (dart.library.io) './io_network_exception.dart'
    hide translateNetworkFailure;

_b.ClientException translateFailure(dynamic failure) {
  return _n.translateNetworkFailure(failure) ?? _b.translateFailure(failure);
}
