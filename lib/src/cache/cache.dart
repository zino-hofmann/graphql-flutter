abstract class Cache {
  dynamic read(String key) {}

  Future<bool> remove(String key, bool cascade) async {}
  
  void write(
    String key,
    dynamic value,
  ) {}

  void save() {}
  void restore() {}
  void reset() {}
}
