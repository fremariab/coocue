class Lullaby {
  final String title;
  // added this to hold the lullaby’s title

  final String asset;
  // added this to keep the built-in asset path (empty if not used)

  final String? url;
  // added this to store a firebase link for custom uploads

  final String duration;
  // added this to record the track length, e.g. “1:27”

  Lullaby({
    required this.title,
    this.asset = '',
    this.url,
    this.duration = '',
  });
}
