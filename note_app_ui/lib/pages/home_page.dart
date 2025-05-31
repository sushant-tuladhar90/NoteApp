import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:note_app_ui/models/note.dart";
import "package:note_app_ui/pages/add_new_note.dart";
import "package:note_app_ui/providers/notes_provider.dart";
import "package:note_app_ui/services/auth_service.dart";
import "package:provider/provider.dart";
import "package:flutter_slidable/flutter_slidable.dart";
import "package:note_app_ui/pages/login_page.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Notes initialization will be triggered by AuthService changes via Consumer
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Use Provider to access AuthService
      await Provider.of<AuthService>(context, listen: false).logout();
      // Navigate to login page and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "My Notes",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context), // Pass context to handler
            icon: Icon(Icons.logout, size: 20, color: Colors.black,)
          )
        ],
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[700]!, Colors.blue[400]!],
            ),
          ),
        ),
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.isAuthenticated && authService.userId != null) {
            // User is authenticated, now consume NotesProvider
            return Consumer<NotesProvider>(
              builder: (context, notesProvider, child) {
                // Trigger notes initialization if not already loading and notes are empty
                // or if userId changes (though userId changes should ideally be handled by authService listener)
                if (!notesProvider.isLoading && notesProvider.notes.isEmpty && authService.userId != null) {
                   Future.microtask(() => notesProvider.initializeNotes());
                }

                if (notesProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  );
                }

                if (notesProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        SizedBox(height: 16),
                        Text(
                          'Error: ${notesProvider.error}',
                          style: TextStyle(color: Colors.red[300]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (notesProvider.notes.isNotEmpty) {
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemCount: notesProvider.notes.length,
                    itemBuilder: (context, index) {
                      Note currentNote = notesProvider.notes[index];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Note'),
                                    content: Text('Are you sure you want to delete this note?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          notesProvider.deleteNote(currentNote);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              borderRadius: BorderRadius.circular(8),
                              padding: EdgeInsets.only(right: 16.0, top: 0.0, bottom: 0.0),
                              autoClose: true,
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => AddNewNote(
                                  isUpdate: true,
                                  note: currentNote,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        currentNote.title!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.blue[900],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(currentNote.dateAdded!),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  currentNote.content!,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                   return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No Notes Yet",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap the + button to create your first note",
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                }
              },
            );
          } else {
            // User is not authenticated, maybe show a loading indicator or redirect
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              fullscreenDialog: true,
              builder: (context) => AddNewNote(isUpdate: false),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
