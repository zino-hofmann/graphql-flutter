import 'dart:convert';

/// The episodes in the Star Wars trilogy
enum Episode {
  NEWHOPE,
  EMPIRE,
  JEDI,
}

String episodeToJson(Episode e) {
  switch (e) {
    case Episode.NEWHOPE:
      return 'NEWHOPE';
    case Episode.EMPIRE:
      return 'EMPIRE';
    case Episode.JEDI:
      return 'JEDI';
    default:
      return null;
  }
}

Episode episodeFromJson(String e) {
  switch (e) {
    case 'NEWHOPE':
      return Episode.NEWHOPE;
    case 'EMPIRE':
      return Episode.EMPIRE;
    case 'JEDI':
      return Episode.JEDI;
    default:
      return null;
  }
}

String getPrettyJSONString(Object jsonObject) {
  return const JsonEncoder.withIndent('  ').convert(jsonObject);
}
