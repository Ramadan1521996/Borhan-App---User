import 'dart:convert';
import 'package:Borhan_User/models/user_chat.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  

  var _userData = UserChat(email: '', id: '');
  UserChat get userData {
    return _userData;
  }
  final String myKey = 'AIzaSyCLYK4YRGvB9ouLYqxGNnRetvZuG2mhA0c';

  Future<String> _authenticate(
      String email, String password, String urlSegment) async {

    String localId;
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$myKey';
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final responseData = json.decode(response.body);
      _userData = UserChat(
        email: responseData['email'],
        id: responseData['localId'],
      );
      localId= responseData['localId'];
      
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
    } catch (error) {
      throw error;
    }
      return localId ;
  }

  Future<void> _sendResetPasswordEmail(String email) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$myKey';
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {"requestType": "PASSWORD_RESET", "email": email},
        ),
      );
      final responseData = json.decode(response.body);
      
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
    } catch (error) {
      throw error;
    }
  }

  Future<String> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<String> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<void> resetPassword(String email) async {
    return _sendResetPasswordEmail(email);
  }
}
