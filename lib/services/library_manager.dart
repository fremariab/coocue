import 'package:coocue/models/lullaby.dart';

// made this a singleton so the LIBRARYMANAGER can be accessed from anywhere
class LibraryManager {
  LibraryManager._();
  static final LibraryManager I = LibraryManager._();

  // list to store the user's saved lullabies
  final List<Lullaby> personalLibrary = [];

  // adds tracks only if they’re not already in the list by checking asset
  void addAll(Iterable<Lullaby> tracks) {
    for (final t in tracks) {
      if (!personalLibrary.any((e) => e.asset == t.asset)) {
        personalLibrary.add(t);
      }
    }
  }

  // removes a track from the list based on its asset
  void remove(Lullaby t) => personalLibrary.removeWhere((e) => e.asset == t.asset);
}
