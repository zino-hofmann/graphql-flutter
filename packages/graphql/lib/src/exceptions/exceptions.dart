import 'package:graphql/src/exceptions/_base_exceptions.dart' as _b;
import 'package:graphql/src/exceptions/io_network_exception.dart' as _n;

export 'package:graphql/src/exceptions/_base_exceptions.dart'
    hide translateFailure;
export 'package:graphql/src/exceptions/graphql_error.dart';
export 'package:graphql/src/exceptions/operation_exception.dart';
export 'package:graphql/src/exceptions/network_exception_stub.dart'
    if (dart.library.io) 'package:graphql/src/exceptions/io_network_exception.dart'
    hide translateNetworkFailure;

_b.ClientException translateFailure(dynamic failure) {
  return _n.translateNetworkFailure(failure) ?? _b.translateFailure(failure);
}
