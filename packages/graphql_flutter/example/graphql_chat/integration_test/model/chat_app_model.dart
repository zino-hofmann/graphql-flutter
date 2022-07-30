class Chat {
  final int id;
  final String name;
  final String description;

  const Chat({required this.id, required this.name, required this.description});

  factory Chat.fromJSON(Map<String, dynamic> json) {
    return Chat(
        id: json["id"] as int,
        name: json["name"].toString(),
        description: json["description"].toString());
  }
}
