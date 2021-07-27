import 'package:firebase_database/firebase_database.dart';

class MyUser {
  String fullname, email, phone, id;
  MyUser({
    this.id,
    this.email,
    this.fullname,
    this.phone,
  });
  MyUser.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.key;
    email = snapshot.value["email"];
    phone = snapshot.value["phone"];
    fullname = snapshot.value["fullname"];
  }
}
