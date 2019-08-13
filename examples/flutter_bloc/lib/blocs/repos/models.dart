class Repo {
  const Repo({
    this.id,
    this.name,
    this.viewerHasStarred,
    this.isLoading: false,
  });

  final String id;
  final String name;
  final bool viewerHasStarred;
  final bool isLoading;
}
