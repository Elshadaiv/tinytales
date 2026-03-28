class CommunityEvent
{
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String venueName;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String eventUrl;

  CommunityEvent(
      {
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.venueName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.startDateTime,
    this.endDateTime,
    required this.eventUrl,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json)
  {
    return CommunityEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      venueName: json['venueName'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      startDateTime: DateTime.tryParse(json['startDateTime'] ?? '') ?? DateTime.now(),
      endDateTime: json['endDateTime'] != null
          ? DateTime.tryParse(json['endDateTime'])
          : null,
      eventUrl: json['eventUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson()
  {
    return
      {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'venueName': venueName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'eventUrl': eventUrl,
    };
  }
}