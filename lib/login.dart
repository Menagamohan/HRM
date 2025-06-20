import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'headers.dart';
import 'response.dart';

class UserService {
  Future<dynamic> createUser({
    required String username,
    required String password,
  }) async {
    print(username);
    print(password);

    const String apiUrl =
        'http://hrmwebapi.lemeniz.com/api/Auth/Login'; // Replace with actual user creation endpoint



    try {
      final response = await http.post(
        Uri.parse('http://hrmwebapi.lemeniz.com/api/Auth/Login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username':username,
          'password': password,
        }),
      );
      var resp = json.decode(response.body);
      print(resp);
      if (resp['success'] == true) {
        // Optionally parse and return the user data
        print("Status Code: ${response.statusCode}");
        print("Body: ${response.body}");
        // You can use `userResponse` if needed
        return true;
      } else {
        print('Failed to create user: ${resp['message']}');
        return false;
      }
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
}
