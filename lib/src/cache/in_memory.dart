class InMemoryCache {
  Map<String, dynamic> _inMemoryCache = new Map<String, dynamic>();

  bool hasEntity(String key) => _inMemoryCache.containsKey(key);

  dynamic read(String key) {
    print("CACHE: READ");

    if (hasEntity(key)) {
      return _inMemoryCache[key];
    }

    return null;
  }

  void write(String key, dynamic value) {
    print("CACHE: WRITE");

    _inMemoryCache[key] = value;
  }

  void reset() {
    print("CACHE: RESET");

    _inMemoryCache.clear();
  }
}
