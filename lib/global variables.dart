import 'package:cabrider/datamodels/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String mapkey = "AIzaSyCDc5tU69-wN5dKcqGl805arpBiOU5XASI";
final CameraPosition googlePlex = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
User currentFirebaseUser;
MyUser currentUserInfo;
