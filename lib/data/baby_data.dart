
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
 String dateGiven;
bool isGiven;

Immunisation(
{
  required this.name,
  this.dateGiven = '',
  this.isGiven = false

});

Map<String, dynamic> toMap()
{
  return {
    'name': name,
    'dateGiven': dateGiven,
    'isGiven': isGiven,
  };
}

factory Immunisation.fromMap(Map<String, dynamic> map)
{
  return Immunisation(

        name: map['name'],
        dateGiven: map ['dateGiven'] ?? '',
      isGiven: map ['isGivem'] ?? false,
  );

}
}

