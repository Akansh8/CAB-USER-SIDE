import 'package:cabrider/datamodels/datamodels.dart';
import 'package:flutter/cupertino.dart';

class AppData extends ChangeNotifier {
  String id;
  Address pickUpAddress;
  Address destinationAddress;
  void updatePickupAddress(Address pickup) {
    pickUpAddress = pickup;
    notifyListeners();
  }

  void updateDestinationAddress(Address destination) {
    destinationAddress = destination;
    notifyListeners();
  }
}
