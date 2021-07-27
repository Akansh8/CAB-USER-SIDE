import 'package:cabrider/datamodels/datamodels.dart';

class FireHelper {
  static List<NearbyDriver> nearbydriverList = [];
  static void removeFromList(String key) {
    int index = nearbydriverList.indexWhere((element) => element.key == key);
    nearbydriverList.removeAt(index);
  }

  static void updateNearbyLocation(NearbyDriver driver) {
    int index =
        nearbydriverList.indexWhere((element) => element.key == driver.key);
    nearbydriverList[index] = driver;
  }
}
