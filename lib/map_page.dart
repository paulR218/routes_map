import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'common_methods.dart';
import 'direction_details.dart';
import 'global_var.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> googleMapCompleterController =  Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  static var pickupGeoGraphicCoordinates =  LatLng(14.7397,121.01917);
  static var dropOffDestinationGeoGraphicCoordinates = const LatLng(14.47912970, 120.89696340);
  var pickupHumanReadableAddress = "";
  //static var waypointCoordinates = const LatLng(14.5342, 121.00365);
  static var waypointCoordinates = ["Quiapo Manila, Metro Manila", "P.Ocampo St., San Andres, Manila, Metro Manila"];
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polyLineCoordinates = [];
  Set<Polyline> polyLineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  double bottomMapPadding = 0;
  Position? currentPositionOfUser;



  retrieveDirectionDetails() async {
    pickupHumanReadableAddress = await CommonMethods.convertGeographicCoordinatesIntoHumanReadableAddress(pickupGeoGraphicCoordinates, context);
    var detailsFromDirectionAPI = await CommonMethods.getDirectionDetailsFromAPI(pickupHumanReadableAddress, dropOffDestinationGeoGraphicCoordinates,waypointCoordinates);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination = pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polyLineCoordinates.clear();
    if(latLngPointsFromPickUpToDestination.isNotEmpty) {
      for (var latLngPoint in latLngPointsFromPickUpToDestination) {
        polyLineCoordinates.add(
            LatLng(latLngPoint.latitude, latLngPoint.longitude));
      }
    }
    polyLineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId("polylineID"),
        color: Colors.pink,
        points: polyLineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

    //fit polyline into the map
    LatLngBounds boundsLatlng;
    if(pickupGeoGraphicCoordinates.latitude > dropOffDestinationGeoGraphicCoordinates.latitude &&
        pickupGeoGraphicCoordinates.longitude > dropOffDestinationGeoGraphicCoordinates.longitude){
      boundsLatlng = LatLngBounds(southwest: dropOffDestinationGeoGraphicCoordinates, northeast: pickupGeoGraphicCoordinates);
    }
    else if(pickupGeoGraphicCoordinates.longitude > dropOffDestinationGeoGraphicCoordinates.longitude){
      boundsLatlng = LatLngBounds(
        southwest: LatLng(pickupGeoGraphicCoordinates.latitude, dropOffDestinationGeoGraphicCoordinates.longitude),
        northeast: LatLng(dropOffDestinationGeoGraphicCoordinates.latitude, pickupGeoGraphicCoordinates.longitude),
      );
    }
    else if(pickupGeoGraphicCoordinates.latitude > dropOffDestinationGeoGraphicCoordinates.latitude){
      boundsLatlng = LatLngBounds(
        southwest: LatLng(dropOffDestinationGeoGraphicCoordinates.latitude, pickupGeoGraphicCoordinates.longitude),
        northeast: LatLng(pickupGeoGraphicCoordinates.latitude,dropOffDestinationGeoGraphicCoordinates.longitude),
      );
    }
    else{
      boundsLatlng = LatLngBounds(southwest: pickupGeoGraphicCoordinates, northeast: dropOffDestinationGeoGraphicCoordinates);
    }

    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatlng, 72));

    //add the markers from pickup and destination
    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: pickupGeoGraphicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: "pickUp Location", snippet: "Pickup Location"),
    );

    Marker dropOffPointMarker = Marker(
      markerId: const MarkerId("dropOffPointMarkerID"),
      position: dropOffDestinationGeoGraphicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: const InfoWindow(title: "dropOffDestinationLocation", snippet: "Destination Location"),
    );

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffPointMarker);
    });

    //add the circles from pickup and destination
    Circle pickUpPointCircle = Circle(
        circleId: const CircleId("pickupCircleID"),
        strokeColor: Colors.blue,
        strokeWidth: 4,
        radius: 14,
        center: pickupGeoGraphicCoordinates,
        fillColor: Colors.pink
    );

    Circle dropOffDestinationPointCircle = Circle(
        circleId: const CircleId("dropOffDestinationCircleID"),
        strokeColor: Colors.blue,
        strokeWidth: 4,
        radius: 14,
        center: dropOffDestinationGeoGraphicCoordinates,
        fillColor: Colors.green
    );

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });
  }

  /*getCurrentLiveLocationOfUser() async {
    Position  positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng latLngUserPosition = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: latLngUserPosition, zoom: 15);

    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    await CommonMethods.convertGeographicCoordinatesIntoHumanReadableAddress(currentPositionOfUser!, context);
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  GoogleMap(
        padding:  EdgeInsets.only(top: 25, bottom: bottomMapPadding),
          mapType: MapType.normal,
          myLocationEnabled: true,
          polylines: polyLineSet,
          markers: markerSet,
          circles: circleSet,
          initialCameraPosition: googlePlexInitialPosition,
          onMapCreated: (GoogleMapController mapController){
          controllerGoogleMap = mapController;

          googleMapCompleterController.complete(controllerGoogleMap);

          setState(() {
          bottomMapPadding = 140;
          });
          //getCurrentLiveLocationOfUser();
          retrieveDirectionDetails();
          },
      )
      );
  }
}
