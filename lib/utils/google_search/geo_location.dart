

import 'latlng.dart';

class Geolocation {
  Geolocation(this._coordinates);

  Geolocation.fromJSON(geolocationJSON) {
    this._coordinates = geolocationJSON["results"][0]["geometry"]["location"];
    this.fullJSON = geolocationJSON["results"][0];
  }

  /// Property that holds the JSON response that contains the location of the place.
  var _coordinates;

  /// Property that holds the JSON response that contains the viewport of the place.


  /// Has the full JSON response received from the Geolocation API. Can be used to extract extra information of the location. More info on the [Geolocation API documentation](https://developers.google.com/maps/documentation/geolocation/intro)
  ///
  /// All of its information can be accessed like a regular [Map]. For example:
  /// ```
  /// fullJSON["adress_components"][2]["short_name"]
  /// ```
  var fullJSON;

  /// If you have the `google_maps_flutter` package, this method will return the coordinates of the place as
  /// a `LatLng` object. Otherwise, it'll be returned as Map.
  get coordinates {
    try {
      return LatLng(latitude:_coordinates["lat"],longitude: _coordinates["lng"] );
    } catch (e) {
      print(
          "You appear to not have the `google_maps_flutter` package installed. In this case, this method will return an object with the latitude and longitude");
      return _coordinates;
    }
  }

  /// If you have the `google_maps_flutter` package, this method will return the coordinates of the place as
  /// a `LatLngBounds` object. Otherwise, it'll be returned as Map.

}
