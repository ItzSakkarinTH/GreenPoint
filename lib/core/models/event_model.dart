class EventModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? startDate;
  final String? endDate;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.startDate,
    this.endDate,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['photoUrl'],
      startDate: json['startDate'] ?? json['start_date'],
      endDate: json['endDate'] ?? json['end_date'],
    );
  }
}
