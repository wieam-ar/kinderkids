class NumberItem {
  final String symbol; // "1" or "١"
  final String word;   // "One" or "واحد"
  final int value;      // 1

  NumberItem({
    required this.symbol,
    required this.word,
    required this.value,
  });

  factory NumberItem.fromJson(Map<String, dynamic> json) => NumberItem(
    symbol: json['symbol'] as String,
    word: json['word'] as String,
    value: json['value'] as int,
  );

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'word': word,
    'value': value,
  };
}

class NumberData {
  final List<NumberItem> arabic;
  final List<NumberItem> english;

  NumberData({required this.arabic, required this.english});

  factory NumberData.fromJson(Map<String, dynamic> json) => NumberData(
    arabic: (json['arabic'] as List)
        .map((e) => NumberItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    english: (json['english'] as List)
        .map((e) => NumberItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}