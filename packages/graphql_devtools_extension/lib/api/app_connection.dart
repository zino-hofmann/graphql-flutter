import 'package:devtools_extensions/devtools_extensions.dart';

class AppConnection {
  static const _cacheApiKey = 'ext.graphql.getCache';
  static const _cacheApiValueKey = 'value';

  static Future<Map<String, dynamic>?> fetchCache() async {
    final result =
        await serviceManager.callServiceExtensionOnMainIsolate(_cacheApiKey);
    return result.json?[_cacheApiValueKey] as Map<String, dynamic>?;
  }
}
