
class Chat {
  final int id;
  final String name;
  final String message;

  const Chat({required this.id, required this.name, required this.message});

  factory Chat.fromJSON(Map<String, dynamic> json) {
    return Chat(id: json["id"], name: json["name"], message: json["message"]);
  }
}