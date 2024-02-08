import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'address_model.dart';
import 'app_info.dart';
import 'direction_details.dart';
import 'global_var.dart';
import 'package:intl/intl.dart';



class CommonMethods{

  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try{
      if(responseFromAPI.statusCode == 200){
        String dataFromAPI = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromAPI);
        return dataDecoded;
      }
      else{
        return "error";
      }
    }
    catch(errorMsg){
      return "error";
    }
  }

  static Future<String> convertGeographicCoordinatesIntoHumanReadableAddress(LatLng position, BuildContext context) async {
    String apiGeoCodingUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey";
    String humanReadableAddress = "";
    var responseFromApi = await sendRequestToAPI(apiGeoCodingUrl);

    if(responseFromApi != "error"){
      humanReadableAddress = responseFromApi["results"][0]["formatted_address"];

      AddressModel model = AddressModel();
      model.humanReadableAddress = humanReadableAddress;
      model.placeName = humanReadableAddress;
      model.longitudePosition = position.longitude;
      model.latitudePosition = position.latitude;

      //Provider.of<AppInfo>(context, listen: false).updatePickUpLocation(model);
    }

    return humanReadableAddress;
  }

  static Future<DirectionDetails?> getDirectionDetailsFromAPI(var source, LatLng destination, var waypoints) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    String urlDirectionAPI = "https://maps.googleapis.com/maps/api/directions/json?&departure_time=now&destination=${destination.latitude},${destination.longitude}&origin=$source&mode=driving&waypoints=optimize:true|via:$waypoints&avoid=tolls&key=$googleMapKey";
    //&waypoints=${waypoints.latitude},${waypoints.longitude}
    var responseFromDirectionAPI = await sendRequestToAPI(urlDirectionAPI);

    if(responseFromDirectionAPI == "error"){
      return null ;
    }

    print(responseFromDirectionAPI);

    DirectionDetails detailsModel = DirectionDetails();
    detailsModel.distanceTextString = responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits = responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString = responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits = responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints = responseFromDirectionAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }

}