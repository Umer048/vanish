import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStore {
  late File _file;
  Future<void> _chain = Future.value();

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/vanish_state.json');
  }

  Future<Map<String, dynamic>> load() async {
    try {
      if (!await _file.exists()) return {};
      final j = jsonDecode(await _file.readAsString());
      return j is Map<String, dynamic> ? j : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, dynamic> state) {
    final data = jsonEncode(state);
    _chain = _chain.then((_) async {
      try {
        final tmp = File('${_file.path}.tmp');
        await tmp.writeAsString(data, flush: true);
        await tmp.rename(_file.path);
      } catch (_) {}
    });
    return _chain;
  }

  String get path => _file.path;
}