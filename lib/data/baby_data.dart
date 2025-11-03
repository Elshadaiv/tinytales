
class babyData
{
  final String babyId;
  final String name;
  final String gender;
  final String dob;
  final String weight;
  final String height;
  final String hospital;
  final String userId;

  babyData(
  {
    required this.babyId,
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
      'babyId': babyId,
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


class Immunisation
{
final String name;
List<String> dates;
bool isGiven;
String dateGiven;

Immunisation(
{
  required this.name,
  this.dates = const [],
  this.isGiven = false,
  this.dateGiven = '',

});

Map<String, dynamic> toMap()
{
  return {
    'name': name,
    'dates': dates,
    'isGiven': isGiven,
  };
}

factory Immunisation.fromMap(Map<String, dynamic> map)
{
  return Immunisation(

        name: map['name'],
dates: List<String>.from(map['dates'] ?? []),
      isGiven: map ['isGivem'] ?? false,
  );

}
}

