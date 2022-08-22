class Blog {
  String name;
  String createAt;
  // TODO parse list of posts

  Blog({required this.name, required this.createAt});

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(name: json["name"]!, createAt: json["createdAt"]);
  }
}
