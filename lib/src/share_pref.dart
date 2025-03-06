import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  // ignore: constant_identifier_names
  static const String _url_key = '_url_key_65435643';

  static Future<String> get getUrl async {
    final _pref = await SharedPreferences.getInstance();
    return _pref.getString(_url_key) ?? "";
  }

  static set setUrl(String _value) {
    SharedPreferences.getInstance()
        .then((_pref) => _pref.setString(_url_key, _value));
  }
}
