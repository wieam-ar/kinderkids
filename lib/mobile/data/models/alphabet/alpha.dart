class AlphabetLetter {
  final String character;
  final String soundFile;
  final String soundUrl;
  final String pronunciation;

  const AlphabetLetter({
    required this.character,
    required this.soundFile,
    required this.soundUrl,
    required this.pronunciation,
  });

  factory AlphabetLetter.fromJson(Map<String, dynamic> json) {
    return AlphabetLetter(
      character: json['character'] as String,
      soundFile: json['soundFile'] as String,
      soundUrl: json['soundUrl'] as String,
      pronunciation: json['pronunciation'] as String,
    );
  }
}

/// The two independent parts of the alphabet activity: Arabic and English.
/// Each is practiced as its own separate sequence.
class AlphabetData {
  final List<AlphabetLetter> arabic;
  final List<AlphabetLetter> english;

  const AlphabetData({required this.arabic, required this.english});

  factory AlphabetData.fromJson(Map<String, dynamic> json) {
    return AlphabetData(
      arabic: (json['arabic'] as List)
          .map((e) => AlphabetLetter.fromJson(e as Map<String, dynamic>))
          .toList(),
      english: (json['english'] as List)
          .map((e) => AlphabetLetter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}