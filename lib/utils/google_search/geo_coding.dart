import 'dart:convert';
import 'geo_location.dart';
import 'package:http/http.dart' as http;

class Geocoding {
  Geocoding({required this.apiKey,required this.language});
  String apiKey;
  String language;

  Future<dynamic> getGeolocation(String adress) async {
    String trimmedAdress = adress.replaceAllMapped(' ', (m) => '+');
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=$trimmedAdress&key=$apiKey&language=$language";
    final response = await http.get(Uri.parse(url));
    final extractedData = json.decode(response.body);
    if (extractedData["error_message"] == null) {
      return Geolocation.fromJSON(extractedData);
    } else {
      var error = extractedData["error_message"];
      if (error == "This API project is not authorized to use this API.")
        error +=
        " Make sure both the Geolocation and Geocoding APIs are activated on your Google Cloud Platform";
      throw Exception(error);
    }
  }
}