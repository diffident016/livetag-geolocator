import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class Services {
  static Future updateDb(String tagId, String tagName,
      {required double lat, required double long}) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("tags/$tagId");

    try {
      await ref.set({
        "data": {
          "location": {"lat": lat, "long": long},
          "tag_name": tagName,
          "timestamp": DateTime.now().toString()
        }
      });

      return true;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
}
