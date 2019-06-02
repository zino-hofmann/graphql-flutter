abstract class Cache {
  dynamic read(String key) {}

  void write(
    String key,
    dynamic value,
  ) {}

  Future<void> save() async {}

  void restore() {}

  void reset() {}
}
