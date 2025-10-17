
class babyData
{
  final String name;
  final String gender;
  final String dob;
  final String weight;
  final String height;
  final String hospital;
  final String userId;

  babyData(
  {
    required this.name,
    required this.gender,
    required this.dob,
    required this.weight,
    required this.height,
    required this.hospital,
    required this.userId

  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'dob': dob,
      'weight': weight,
      'height': height,
      'hospital': hospital,
      'userId': userId,
    };
  }
}

