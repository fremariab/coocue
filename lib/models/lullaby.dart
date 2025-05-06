// class Lullaby {
//   final String title;
//   final String asset;     // path in assets/ or a download URL
//   final String duration;  // simple “1:32”, leave '' if unknown

//   Lullaby({
//     required this.title,
//     required this.asset,
//     this.duration = '',
//   });
// }
class Lullaby {
  final String title;

  /// For built‑in tracks bundled in assets
  final String asset;        // ''  for uploaded files

  /// For custom uploads stored in Firebase Storage
  final String? url;         // null for built‑ins

  final String duration;     // optional “1:27”

  Lullaby({
    required this.title,
    this.asset = '',
    this.url,
    this.duration = '',
  });
}
