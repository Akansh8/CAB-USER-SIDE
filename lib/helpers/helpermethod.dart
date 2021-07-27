import 'dart:math';

import 'package:cabrider/datamodels/datamodels.dart';
import 'package:cabrider/datamodels/user.dart';
import 'package:cabrider/global%20variables.dart';
import 'package:cabrider/helpers/requesthelper.dart';
import 'package:cabrider/keys/keys.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cabrider/dataprovider/dataprovider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HelperMethods {
  static void getCurrentUserInfo() async {
    currentFirebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = currentFirebaseUser.uid;
    DatabaseReference userref =
        FirebaseDatabase.instance.reference().child("users/$userId");
    userref.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        currentUserInfo = MyUser.fromSnapshot(snapshot);
        print("****************************${currentUserInfo.fullname}");
      }
    });
  }

  static Future<String> findCoordinateAddress(
      Position position, BuildContext context) async {
    String placeAddress = '';
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      return placeAddress;
    }

    String url =
        'https://revgeocode.search.hereapi.com/v1/revgeocode?at=${position.latitude}%2C${position.longitude}&lang=en-US&apikey=$hereApiKey';

    var response = await RequestHelper().getRequest(url);

    if (response != 'failed') {
      placeAddress = response["items"][0]["address"]["label"];
      Address pickupAddress = Address(
          latitude: position.latitude,
          longitude: position.longitude,
          placeName: placeAddress);
      Provider.of<AppData>(context, listen: false)
          .updatePickupAddress(pickupAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails> getDirectionDetails(
      LatLng start, LatLng end) async {
    String url =
        "https://router.hereapi.com/v8/routes?transportMode=car&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&return=polyline&spans=length,duration&apikey=$hereApiKey";
    var response = await RequestHelper().getRequest(url);
    // print(response);
    if (response == 'failed') return null;
    if (response.containsKey("routes")) {
      print(
          "******************************************Inside Routes***************************************************************");
      var json = response["routes"][0]["sections"][0];
      DirectionDetails directionDetails = DirectionDetails();
      if (json.containsKey("spans") && (json["spans"] as List).length > 0) {
        double duration = double.parse(json["spans"][0]["duration"].toString());
        double distance = double.parse(json["spans"][0]["length"].toString());
        directionDetails.duarationText = (duration / 60).toStringAsFixed(2);
        directionDetails.durationValue = duration.truncate();
        directionDetails.distanceText = (distance / 1000).toStringAsFixed(2);
        directionDetails.distanceValue = (distance).truncate();
      }
      directionDetails.encodedPoints = json["polyline"].toString();
      return directionDetails;
    }
  }

  static double generateRandomNumber(int max) {
    return (Random().nextInt(max)).toDouble();
  }

  static int estimateFares(DirectionDetails details) {
    //per km = 10 rs
    //per minute = 3 rs
    //base fare = 30 rs
    double baseFare = 30;
    double distanceFare = (details.distanceValue / 1000) * 10;
    double timeFare = (details.durationValue / 60.0) * 3;
    double totalFare = baseFare + distanceFare + timeFare;
    return totalFare.truncate();
  }
}
