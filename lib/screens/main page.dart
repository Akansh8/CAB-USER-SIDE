import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cabrider/datamodels/datamodels.dart';
import 'package:cabrider/datamodels/nearby_driver.dart';
import 'package:cabrider/dataprovider/appdata.dart';
import 'package:cabrider/helpers/helpermethod.dart';
import 'package:cabrider/helpers/helpers.dart';
import 'package:cabrider/keys/keys.dart';
import 'package:cabrider/screens/screens.dart';
import 'package:cabrider/styles/styles.dart';
import 'package:cabrider/widgets/BrandDivider.dart';
import 'package:cabrider/widgets/Progress%20Dialogue.dart';
import 'package:cabrider/widgets/TaxiButton.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flexible_polyline/flexible_polyline.dart';
import 'package:flexible_polyline/latlngz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import "package:http/http.dart" as http;
import "dart:convert" as convert;
import 'package:cabrider/global variables.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../brand_colors.dart';

class MainPage extends StatefulWidget {
  final FirebaseApp app;
  MainPage({this.app});
  static const String id = "mainpage";
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final referenceDatabase = FirebaseDatabase.instance;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  double rideDetailsSheetHeight = 0; //235
  double searchDetailsSheetHeight = 275;
  double requestingSheetHeight = 0;
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  var geolocator = Geolocator();
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  BitmapDescriptor nearbyIcon;
  Position currentPosition;

  DirectionDetails tripDirectionDetails;
  bool drawerCanOpen = true;

  double mapBottomPadding = 280;

  DatabaseReference rideRef;

  bool nearbyDriversKeyLoaded = false;

  Future<dynamic> setupPositionLocator() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPosition = position;
    LatLng pos = LatLng(position.latitude, position.longitude);
    // print(pos.latitude);
    // print(pos.longitude);
    CameraPosition cp = CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));
    String address =
        await HelperMethods.findCoordinateAddress(position, context);
    // print(address);
    startGeoFireListener();
    return pos;
  }

  void showDetailsSheet() async {
    await getDirection();
    setState(() {
      searchDetailsSheetHeight = 0;
      rideDetailsSheetHeight = 235;
      drawerCanOpen = false;
      mapBottomPadding = 240;
    });
  }

  void showRequestingSheet() {
    setState(() {
      rideDetailsSheetHeight = 0;
      requestingSheetHeight = 195;
      drawerCanOpen = true;
      mapBottomPadding = 200;
    });
    createRideRequest();
  }

  void createMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'images/car_android.png')
          .then((icon) {
        nearbyIcon = icon;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    HelperMethods.getCurrentUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    // final tomtomHQ = LatLng(52.376372, 4.908066);
    createMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        width: 250,
        color: Colors.white,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.all(0),
            children: [
              Container(
                  color: Colors.white,
                  height: 160,
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'images/user_icon.png',
                          height: 60,
                          width: 60,
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Name',
                              style: TextStyle(
                                  fontSize: 20, fontFamily: 'Brand-Bold'),
                            ),
                            SizedBox(height: 5),
                            Text('View Profile'),
                          ],
                        )
                      ],
                    ),
                  )),
              BrandDivider(),
              SizedBox(
                height: 10,
              ),
              ListTile(
                leading: Icon(Icons.card_giftcard),
                title: Text(
                  'Free Rides',
                  style: kDrawerItemsStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.credit_card),
                title: Text(
                  'Payments',
                  style: kDrawerItemsStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.history_rounded),
                title: Text(
                  'History',
                  style: kDrawerItemsStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.contact_support_outlined),
                title: Text(
                  'Support',
                  style: kDrawerItemsStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(
                  'About',
                  style: kDrawerItemsStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapBottomPadding),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: googlePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;
              setupPositionLocator();
            },
          ),

          /// menu button
          Positioned(
            top: 44,
            left: 18,
            child: GestureDetector(
              onTap: () {
                (drawerCanOpen)
                    ? scaffoldKey.currentState.openDrawer()
                    : resetApp();
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    (drawerCanOpen) ? Icons.menu : CupertinoIcons.back,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          /// search sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                height: searchDetailsSheetHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7)),
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Nice to see you",
                        style: TextStyle(
                            fontSize: 10, fontFamily: 'Brand-Regular'),
                      ),
                      Text(
                        "Where are you going?",
                        style:
                            TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () async {
                          var response = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchPage()));
                          if (response == 'getdirection') {
                            await getDirection();
                            showDetailsSheet();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                )
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text('Search Destination'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: BrandColors.colorDimText,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Home'),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                'your home address',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BrandColors.colorDimText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      BrandDivider(),
                      SizedBox(
                        height: 13,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            color: BrandColors.colorDimText,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Work'),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Your Office Address',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BrandColors.colorDimText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //Ride details sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: BrandColors.colorAccent1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Image.asset(
                                'images/taxi.png',
                                height: 70,
                                width: 70,
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Taxi',
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Brand-Bold'),
                                  ),
                                  Text(
                                      (tripDirectionDetails != null)
                                          ? "${tripDirectionDetails.distanceText} km"
                                          : "",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Brand-Bold',
                                          color: BrandColors.colorDimText)),
                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                (tripDirectionDetails != null)
                                    ? '₹ ${HelperMethods.estimateFares(tripDirectionDetails)}'
                                    : "",
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Brand-Bold'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.moneyBillAlt,
                              size: 18,
                              color: BrandColors.colorTextLight,
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Text('Cash'),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: BrandColors.colorTextLight,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TaxiButton(
                          title: 'REQUEST CAB',
                          color: BrandColors.colorGreen,
                          onPressed: () {
                            showRequestingSheet();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                height: rideDetailsSheetHeight,
              ),
            ),
          ),

          // Request Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: new Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0, // soften the shadow
                      spreadRadius: 0.5, //extend the shadow
                      offset: Offset(
                        0.7, // Move to right 10  horizontally
                        0.7, // Move to bottom 10 Vertically
                      ),
                    )
                  ],
                ),
                height: requestingSheetHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextLiquidFill(
                          text: 'Requesting a Ride...',
                          waveColor: BrandColors.colorTextSemiLight,
                          boxBackgroundColor: Colors.white,
                          textStyle: TextStyle(
                              color: BrandColors.colorText,
                              fontSize: 22.0,
                              fontFamily: 'Brand-Bold'),
                          boxHeight: 40.0,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () {
                          cancelRequest();
                          resetApp();
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                width: 1.0,
                                color: BrandColors.colorLightGrayFair),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 25,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          'Cancel ride',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getDirection() async {
    Address pickup = Provider.of<AppData>(context, listen: false).pickUpAddress;
    Address destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;
    print(
        "************************Pickup Lat Lng*******************\n${pickup.latitude} , ${pickup.longitude}");
    print(
        "************************Destination Lat Lng*******************\n${destination.latitude} , ${destination.longitude}");
    var pickupLatLng = LatLng(pickup.latitude, pickup.longitude);
    var destinationLatLng = LatLng(destination.latitude, destination.longitude);
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              status: 'Please Wait...',
            ));
    var thisDirection = await HelperMethods.getDirectionDetails(
        pickupLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetails = thisDirection;
    });
    Navigator.of(context).pop();
    List<LatLngZ> results =
        FlexiblePolyline.decode(thisDirection.encodedPoints);
    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      //loop through all latlangz points and convert them to a list of LatLng, as required by polyline
      results.forEach((element) {
        polylineCoordinates.add(LatLng(element.lat, element.lng));
      });
    }
    _polylines.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyid'),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      _polylines.add(polyline);
    });
    //make polylines fit into the map
    LatLngBounds bounds;
    if (pickupLatLng.latitude > destinationLatLng.latitude &&
        pickupLatLng.longitude > destinationLatLng.longitude)
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickupLatLng);
    else if (pickupLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickupLatLng.latitude, destinationLatLng.longitude),
          northeast:
              LatLng(destinationLatLng.latitude, pickupLatLng.longitude));
    } else if (pickupLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, pickupLatLng.longitude),
          northeast:
              LatLng(pickupLatLng.latitude, destinationLatLng.longitude));
    } else {
      LatLngBounds(southwest: pickupLatLng, northeast: destinationLatLng);
    }
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    Marker pickupMarker = Marker(
      markerId: MarkerId('pickup'),
      position: pickupLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickup.placeName, snippet: 'My Location'),
    );
    Marker destinationMarker = Marker(
      markerId: MarkerId('destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: destination.placeName, snippet: 'Destination'),
    );
    Circle pickupCircle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickupLatLng,
      fillColor: Colors.green,
    );
    Circle destinationCircle = Circle(
      circleId: CircleId('destination'),
      strokeColor: Colors.red,
      strokeWidth: 3,
      radius: 12,
      center: destinationLatLng,
      fillColor: Colors.red,
    );
    _markers.clear();
    _circles.clear();
    setState(() {
      _markers.add(pickupMarker);
      _markers.add(destinationMarker);
      _circles.add(pickupCircle);
      _circles.add(destinationCircle);
    });
  }

  void startGeoFireListener() {
    Geofire.initialize('driversAvailable');
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 20)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map["key"];
            nearbyDriver.latitude = map["latitude"];
            nearbyDriver.longitude = map["longitude"];
            FireHelper.nearbydriverList.add(nearbyDriver);
            if (nearbyDriversKeyLoaded) {
              updateDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            FireHelper.removeFromList(map['key']);
            updateDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            // Update your key's location
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map["key"];
            nearbyDriver.latitude = map["latitude"];
            nearbyDriver.longitude = map["longitude"];
            FireHelper.updateNearbyLocation(nearbyDriver);
            break;

          case Geofire.onGeoQueryReady:
            // All Intial Data is loaded
            nearbyDriversKeyLoaded = true;
            updateDriversOnMap();
            print(
                '************FireHelper Length: ${FireHelper.nearbydriverList.length}');
            break;
        }
      }
    });
  }

  void updateDriversOnMap() {
    setState(() {
      _markers.clear();
    });
    Set<Marker> tempMarkers = Set<Marker>();
    for (NearbyDriver driver in FireHelper.nearbydriverList) {
      LatLng driverPosition = LatLng(driver.latitude, driver.longitude);
      Marker thisMarker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverPosition,
        icon: nearbyIcon,
        rotation: HelperMethods.generateRandomNumber(360),
      );
      tempMarkers.add(thisMarker);
    }
    setState(() {
      _markers = tempMarkers;
    });
  }

  void createRideRequest() async {
    rideRef = referenceDatabase.reference().child('rideRequest').push();
    var pickup = Provider.of<AppData>(context, listen: false).pickUpAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;
    Map pickupMap = {
      'latitude': pickup.latitude.toString(),
      'longitude': pickup.longitude.toString(),
    };
    Map destinationMap = {
      'latitude': destination.latitude.toString(),
      'longitude': destination.longitude.toString(),
    };
    Map rideMap = {
      'created_at': DateTime.now().toLocal(),
      'rider_name': currentUserInfo.fullname,
      'rider_phone': currentUserInfo.phone,
      'pickup_address': pickup.placeName,
      'destination_address': destination.placeName,
      'location': pickupMap,
      'destination': destinationMap,
      'payment_method': 'cash',
      'driver_id': 'waiting',
    };
    rideMap.forEach((key, value) {
      rideRef.child(key).set(value).asStream();
    });
  }

  void cancelRequest() {
    rideRef.remove();
  }

  resetApp() {
    setState(() {
      polylineCoordinates.clear();
      _circles.clear();
      _polylines.clear();
      _markers.clear();
      rideDetailsSheetHeight = 0;
      searchDetailsSheetHeight = 275;
      requestingSheetHeight = 0;
      drawerCanOpen = true;
      setupPositionLocator();
      mapBottomPadding = 280;
    });
  }
}
