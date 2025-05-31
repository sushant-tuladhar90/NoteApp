import 'package:flutter/foundation.dart';
import 'package:note_app_ui/models/note.dart';
import 'package:note_app_ui/services/api_services.dart';
import 'package:note_app_ui/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool isLoading = false;
  String? error;
  String? _userId;
  bool _initialLoadAttempted = false;

  List<Note> get notes => _notes;
  bool get initialLoadAttempted => _initialLoadAttempted;

  NotesProvider() {
    initializeNotes();
  }

  Future<String?> _getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final decodedToken = JwtDecoder.decode(token);
        return decodedToken['_id'] as String?;
      } catch (e) {
        print('Error decoding token: $e');
        return null;
      }
    }
    return null;
  }

  void setNotes(List<Note> newNotes) {
    _notes = newNotes;
    notifyListeners();
  }

  void addNoteToState(Note note) {
    _notes.add(note);
    notifyListeners();
  }

  void removeNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  void clearNotes() {
    _notes = [];
    notifyListeners();
  }

  void sortNotes() {
    _notes.sort((a, b) {
      final dateA = a.dateAdded ?? DateTime(1970);
      final dateB = b.dateAdded ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
  }

  Future<void> initializeNotes() async {
    if (_initialLoadAttempted) {
      return;
    }

    try {
      _initialLoadAttempted = true;
      isLoading = true;
      notifyListeners();

      _userId = await _getUserIdFromToken();
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final notes = await ApiServices.fetchNote(_userId!);
      _notes = notes;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addNote(Note note) async {
    try {
      isLoading = true;
      notifyListeners();

      if (_userId == null) {
        _userId = await _getUserIdFromToken();
        if (_userId == null) {
          throw Exception('User not authenticated');
        }
      }

      // Set the user ID for the new note
      note = note.copyWith(userId: _userId);
      
      await ApiServices.addNote(note);
      _notes.add(note);
      sortNotes();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      isLoading = true;
      notifyListeners();

      if (_userId == null) {
        _userId = await _getUserIdFromToken();
        if (_userId == null) {
          throw Exception('User not authenticated');
        }
      }

      // Ensure the note belongs to the current user
      if (note.userId != _userId) {
        throw Exception('Unauthorized to update this note');
      }

      await ApiServices.addNote(note);
      int indexOfNote = _notes.indexWhere((element) => element.id == note.id);
      if (indexOfNote != -1) {
        _notes[indexOfNote] = note;
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      isLoading = true;
      notifyListeners();

      if (_userId == null) {
        _userId = await _getUserIdFromToken();
        if (_userId == null) {
          throw Exception('User not authenticated');
        }
      }

      // Ensure the note belongs to the current user
      if (note.userId != _userId) {
        throw Exception('Unauthorized to delete this note');
      }

      await ApiServices.deleteNote(note);
      int indexOfNote = _notes.indexWhere((element) => element.id == note.id);
      if (indexOfNote != -1) {
        _notes.removeAt(indexOfNote);
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }
}