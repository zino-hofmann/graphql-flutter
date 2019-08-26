abstract class ClientException implements Exception {
  String get message;
}

//
// Cache exceptions
//

abstract class ClientCacheException implements ClientException {}

/// A failure during the cache's entity normalization processes
class NormalizationException implements ClientCacheException {
  NormalizationException(this.message, this.overflowError, this.value);

  StackOverflowError overflowError;
  String message;
  Object value;
}

/// A failure to find a key in the cache when cacheOnly=true
class CacheMissException implements ClientCacheException {
  CacheMissException(this.message, this.missingKey);

  String message;
  String missingKey;
}

//
// end cache exceptions
//

class UnhandledFailureWrapper implements ClientException {
  String get message => 'Unhandled Failure $failure';

  covariant Object failure;

  UnhandledFailureWrapper(this.failure);
}

ClientException translateFailure(dynamic failure) {
  if (failure is ClientException) {
    return failure;
  }

  return UnhandledFailureWrapper(failure);
}
