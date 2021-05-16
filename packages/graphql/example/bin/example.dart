import 'package:args/args.dart';
import 'package:example/main.dart';

late ArgResults argResults;

/// CLI fro executing github actions
///
/// Usage:
/// ```sh
/// # List repositories
/// pub run example
///
/// # Star Repository
/// pub run example -a star --id $REPOSITORY_ID_HERE
///
/// # Unstar Repository
/// pub run example -a unstar --id $REPOSITORY_ID_HERE
/// ```
void main(List<String> arguments) {
  final ArgParser parser = ArgParser()
    ..addOption('action', abbr: 'a', defaultsTo: 'fetch')
    ..addOption('id', defaultsTo: '');

  argResults = parser.parse(arguments);

  final String? action = argResults['action'] as String?;
  final String? id = argResults['id'] as String?;

  switch (action) {
    case 'star':
      starRepository(id);
      break;
    case 'unstar':
      removeStarFromRepository(id);
      break;
    default:
      readRepositories();
      break;
  }
}
