import 'package:cabrider/datamodels/datamodels.dart';
import 'package:cabrider/dataprovider/appdata.dart';
import 'package:cabrider/helpers/helpers.dart';
import 'package:cabrider/keys/keys.dart';
import 'package:cabrider/widgets/Progress%20Dialogue.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../brand_colors.dart';

class PredictionTile extends StatelessWidget {
  final Prediction prediction;

  const PredictionTile({Key key, this.prediction}) : super(key: key);
  void getPlaceDetails(String placeId, context) async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return ProgressDialog(
            status: 'Please Wait...',
          );
        });
    String url =
        "https://lookup.search.hereapi.com/v1/lookup?id=$placeId&apikey=$hereApiKey";
    var response = await RequestHelper().getRequest(url);
    Navigator.of(context).pop();
    if (response == 'failed') return;
    if (response.containsKey("id") &&
        response.containsKey("title") &&
        response.containsKey("address") &&
        response["address"].containsKey("label") &&
        response.containsKey("position") &&
        response["position"].containsKey("lat") &&
        response["position"].containsKey("lng")) {
      Address thisPlace = Address();
      thisPlace.placeName = response["title"].toString();
      thisPlace.placeId = response["id"].toString();
      thisPlace.placeFormattedAddress = response["address"]["label"].toString();
      thisPlace.latitude = response["position"]["lat"];
      thisPlace.longitude = response["position"]["lng"];
      Provider.of<AppData>(context, listen: false)
          .updateDestinationAddress(thisPlace);
      // print("Detination Address Selected = " + thisPlace.latitude.toString() + "," + thisPlace.longitude.toString());
      Navigator.pop(context, 'getdirection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        getPlaceDetails(prediction.placeId, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Icon(
                  CupertinoIcons.location,
                  color: BrandColors.colorDimText,
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.mainText,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          prediction.secondaryText,
                          style: TextStyle(
                              fontSize: 16, color: BrandColors.colorDimText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}
