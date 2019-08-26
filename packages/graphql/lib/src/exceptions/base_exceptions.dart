abstract class ClientException implements Exception {}

abstract class ClientCacheException implements ClientException {}

/// A failure during the cache's entity normalization processes
class NormalizationException implements ClientCacheException {
  NormalizationException(this.cause, this.overflowError, this.value);

  StackOverflowError overflowError;
  String cause;
  Object value;

  String get message => cause;
}

/// A failure to find a key in the cache when cacheOnly=true
class CacheMissException implements ClientCacheException {
  CacheMissException(this.cause, this.missingKey);

  String cause;
  String missingKey;

  String get message => cause;
}
