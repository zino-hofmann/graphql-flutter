abstract class Cache {
  dynamic read(String key) {}
  void write(
    String key,
    dynamic value,
  ) {}

  void save() {}
  void restore() {}
  void reset() {}
}
