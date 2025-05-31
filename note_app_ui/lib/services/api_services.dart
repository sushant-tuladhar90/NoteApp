import 'dart:convert';
import 'dart:developer';
import 'package:note_app_ui/models/note.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiServices {
  // For physical device testing
  static final String _baseUrl = "http://192.168.1.69:5000";
  // static final String _baseUrl = "http://10.0.2.2:5000";  // For Android Emulator
  // static final String _baseUrl = "http://127.0.0.1:5000";  // For iOS Simulator
  // static final String _baseUrl = "http://localhost:5000";  // For Web

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<Note>> fetchNote(String userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      Uri requestUri = Uri.parse("$_baseUrl/notes/list");
      var response = await http.post(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({"userId": userId})
      );
      
      if (response.statusCode == 200) {
        List<dynamic> notesJson = jsonDecode(response.body);
        return notesJson.map((json) => Note.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching notes: $e');
      rethrow;
    }
  }

  static Future<void> addNote(Note note) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      log('Attempting to add note to: $_baseUrl/notes/add');
      log('Note data: ${note.toMap()}');
      
      Uri requestUri = Uri.parse("$_baseUrl/notes/add");
      var response = await http.post(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(note.toMap())
      );
      
      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        log('Note added successfully: $decoded');
      } else {
        log('Server responded with status: ${response.statusCode}');
        log('Response body: ${response.body}');
        throw Exception('Failed to add note: ${response.statusCode}');
      }
    } catch (e) {
      log('Error adding note: $e');
      rethrow;
    }
  }

  static Future<void> deleteNote(Note note) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      Uri requestUri = Uri.parse("$_baseUrl/notes/delete");
      var response = await http.post(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({"id": note.id})
      );
      
      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        log('Note deleted successfully: $decoded');
      } else {
        log('Server responded with status: ${response.statusCode}');
        log('Response body: ${response.body}');
        throw Exception('Failed to delete note: ${response.statusCode}');
      }
    } catch (e) {
      log('Error deleting note: $e');
      rethrow;
    }
  }
}
