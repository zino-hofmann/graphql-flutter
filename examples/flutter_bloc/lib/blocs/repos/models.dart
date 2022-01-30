class Repo {
  const Repo({
    required this.id,
    required this.name,
    required this.viewerHasStarred,
    this.isLoading = false,
  });

  final String? id;
  final String? name;
  final bool? viewerHasStarred;
  final bool isLoading;
}
