import 'package:cabrider/brand_colors.dart';
import 'package:cabrider/datamodels/datamodels.dart';
import 'package:cabrider/dataprovider/dataprovider.dart';
import 'package:cabrider/helpers/helpers.dart';
import 'package:cabrider/keys/keys.dart';
import 'package:cabrider/widgets/BrandDivider.dart';
import 'package:cabrider/widgets/prediction%20widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var pickupController = TextEditingController();
  var destinationController = TextEditingController();
  List<Prediction> destinationPredictionList = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void searchPlace(String placeName) async {
    destinationPredictionList.clear();
    if (placeName.trim().length <= 1) return;
    Address here = Provider.of<AppData>(context, listen: false).pickUpAddress;
    if (here == null) return;
    String uri =
        "https://autosuggest.search.hereapi.com/v1/discover?at=${here.latitude},${here.longitude}&q=$placeName&lang=en&limit=5&termsLimit=3&apikey=$hereApiKey";
    print("url = " + uri);
    var response = await RequestHelper().getRequest(uri);
    if (response == 'failed') {
      return;
    }
    // print(response);
    if (response.containsKey("items")) {
      print("Items was found in JSON");

      var predictionJson = response["items"];
      if (predictionJson == null) return;

      List<Prediction> thisList = [];
      for (var json in (predictionJson as List)) {
        if (json.containsKey("id") &&
            json.containsKey("title") &&
            json.containsKey("address") &&
            json["address"].containsKey("label")) {
          thisList.add(Prediction(
              placeId: json["id"],
              mainText: json["title"],
              secondaryText: json["address"]["label"]));
        }
      }
      setState(() {
        destinationPredictionList = thisList;
      });
      // print("My List:-\n");
      // for (int i = 0; i < destinationPredictionList.length; i++) {
      //   print(destinationPredictionList[i].mainText + "\n");
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    String address =
        Provider.of<AppData>(context, listen: false).pickUpAddress.placeName ??
            "";
    pickupController.text = address;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 5.0,
                spreadRadius: 0.5,
                offset: Offset(0.7, 0.7),
              )
            ]),
            child: Padding(
              padding:
                  EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Stack(
                    children: [
                      GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.arrow_back)),
                      Center(
                        child: Text(
                          "Set Destination",
                          style:
                              TextStyle(fontSize: 20, fontFamily: 'Brand-Bold'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 18,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'images/pickicon.png',
                        height: 16,
                        width: 16,
                      ),
                      SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: BrandColors.colorLightGrayFair,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: TextField(
                              controller: pickupController,
                              decoration: InputDecoration(
                                hintText: 'Pickup Location',
                                fillColor: BrandColors.colorLightGrayFair,
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 10, top: 8, bottom: 8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'images/desticon1.png',
                        height: 16,
                        width: 16,
                      ),
                      SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: BrandColors.colorLightGrayFair,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: TextField(
                              onChanged: (value) {
                                searchPlace(value);
                              },
                              autofocus: true,
                              controller: destinationController,
                              decoration: InputDecoration(
                                hintText: 'Where to?',
                                fillColor: BrandColors.colorLightGrayFair,
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 10, top: 8, bottom: 8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          (destinationPredictionList.length > 0)
              ? Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListView.separated(
                      padding: EdgeInsets.all(0),
                      itemBuilder: (context, index) {
                        return PredictionTile(
                          prediction: destinationPredictionList[index],
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          BrandDivider(),
                      itemCount: destinationPredictionList.length,
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
      // floatingActionButton: IconButton(
      //   icon: Icon(
      //     CupertinoIcons.search,
      //     color: Colors.blue,
      //   ),
      //   onPressed: () => searchPlace(destinationController.text.toString()),
      // ),
    );
  }
}
