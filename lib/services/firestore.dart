
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService
{
  // this will allow me to create new baby

  final CollectionReference babyId =
      FirebaseFirestore.instance.collection('Baby Info');
}