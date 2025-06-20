class LogEntry {
  final int? id;
  final String date;
  final String time;
  final double latitude;
  final double longitude;

  LogEntry({
    this.id,
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'],
      date: map['date'],
      time: map['time'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
