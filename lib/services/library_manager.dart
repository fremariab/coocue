import 'package:coocue/models/lullaby.dart';

/// A singleton that holds the parent’s personal lullaby list
class LibraryManager {
  LibraryManager._();
  static final LibraryManager I = LibraryManager._();

  /// The user’s saved tracks
  final List<Lullaby> personalLibrary = [];

  /// Adds every track that isn’t already present (matched by asset path)
  void addAll(Iterable<Lullaby> tracks) {
    for (final t in tracks) {
      if (!personalLibrary.any((e) => e.asset == t.asset)) {
        personalLibrary.add(t);
      }
    }
  }

  void remove(Lullaby t) => personalLibrary.removeWhere((e) => e.asset == t.asset);
}
