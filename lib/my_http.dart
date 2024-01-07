import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:developer' as developer;

class MyHttp {
  Future<Map<String, dynamic>> get(String uri) async {
    final response = await http.get(Uri.parse(uri));
    developer.log(uri);
    developer.log(response.body);
    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body);
    } else {
      throw Exception(response.toString());
    }
  }

  Future<String> getAsString(String uri) async {
    final response = await http.get(Uri.parse(uri));
    developer.log(uri);
    developer.log(response.body);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(response.toString());
    }
  }
}
