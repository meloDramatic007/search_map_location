import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/google_search/geo_coding.dart';
import '../utils/google_search/latlng.dart';
import 'dart:convert';

import '../utils/google_search/place.dart';
import '../utils/google_search/place_type.dart';
class SearchLocation extends StatefulWidget {
  final String apiKey;
  final String placeholder;
  final bool hasClearButton;
  final Color iconColor;
  final Function(Place)? onSelected;
  final Function(String)? onSearch;
  final Function(String)? onChangeText;
  final Function()? onClearIconPress;
  final String language;
  final String? country;
  final LatLng? location;
  final double? radius;
  final bool strictBounds;
  final PlaceType? placeType;
  final bool darkMode;
  final InputDecoration? inputDecoration;
  final TextStyle? textStyle;

  SearchLocation({
    required this.apiKey,
    this.placeholder = 'Search',
    this.hasClearButton = true,
    this.iconColor = Colors.blue,
    this.onSelected,
    this.onSearch,
    this.onChangeText,
    this.onClearIconPress,
    this.language = 'en',
    this.country,
    this.location,
    this.radius,
    this.strictBounds = false,
    this.placeType,
    this.darkMode = false,
    this.inputDecoration,
    this.textStyle,
    Key? key,
  }) : super(key: key);

  @override
  _SearchLocationState createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation> with TickerProviderStateMixin {
   TextEditingController _textEditingController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _containerHeight;
  late Animation<double> _listOpacity;
  late CrossFadeState crossFadeState;
  List<dynamic> _placePredictions = [];
  bool _isEditing = false;
  Geocoding? geocode;
  String _currentInput = "";
  final FocusNode _fn = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    geocode ??= Geocoding(apiKey: widget.apiKey, language: widget.language);

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _containerHeight = Tween<double>(begin: 55, end: 364).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _listOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _textEditingController.addListener(_autocompletePlace);
    
    // if(_textEditingController.text.isNotEmpty){
    //   log("message");
    //   setState(() {
    //     _isEditing = true;
    //   });
      
    // }
    if (widget.hasClearButton) {
      _fn.addListener(() {
        setState(() {
          if (_fn.hasFocus) {
            crossFadeState = CrossFadeState.showSecond;
          } else {
            crossFadeState = CrossFadeState.showFirst;
          }
        });
      });
    }
  }

  // Debounced autocomplete function
  void _autocompletePlace() {
    final input = _textEditingController.text;

    // If input is empty, clear predictions
    if (input.isEmpty) {
      // if (!_containerHeight.isDismissed) _closeSearch();
      _fn.unfocus();
      setState(() {
        _placePredictions.clear();
        _isEditing = false;
      });
      return;
    }

    // Only proceed if input has changed
    // if (input != _currentInput) {
      setState(() {
        _currentInput = input;
        _isEditing = true;
      });

      // Delay the API call to prevent excessive requests
      Future.delayed(Duration(milliseconds: 500), () async {
        final predictions = await _makeRequest(input);
        setState(() {
          _placePredictions = predictions;
          _animationController.forward();
        });
      });
    // }
  }

  Future<List<dynamic>> _makeRequest(String input) async {
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${widget.apiKey}&language=${widget.language}";
    if (widget.location != null && widget.radius != null) {
      url += "&location=${widget.location!.latitude},${widget.location!.longitude}&radius=${widget.radius}";
      if (widget.strictBounds) url += "&strictbounds";
    }
    if (widget.placeType != null) url += "&types=${widget.placeType!.apiString}";
    if (widget.country != null) url += "&components=country:${widget.country}";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data["error_message"] != null) throw Exception(data["error_message"]);
    return data["predictions"];
  }

  void _selectPlace({Place? prediction}) {
    if (prediction != null) {
      _textEditingController.value = TextEditingValue(
        text: prediction.description,
        selection: TextSelection.collapsed(offset: prediction.description.length),
      );
      widget.onSelected?.call(prediction);
    }
    _closeSearch();
  }

  void _closeSearch() async {
   
    _fn.unfocus();
    setState(() {
      _placePredictions.clear();
      _isEditing = false;
    });
    await _animationController.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textEditingController.dispose();
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      child: _searchContainer(child: _searchInput(context)),
    );
  }

  Widget _searchContainer({required Widget child}) {
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return Container(
          decoration: _containerDecoration(),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 4),
                child: child,
              ),
              if (MediaQuery.of(context).viewInsets.bottom != 0 && _isEditing == true && _placePredictions.isNotEmpty)
                Opacity(
                  opacity: _listOpacity.value,
                  child: Column(
                    children: _placePredictions.map((prediction) => _placeOption(Place.fromJSON(prediction, geocode!))).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeOption(Place prediction) {
    return MaterialButton(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      onPressed: () => _selectPlace(prediction: prediction),
      child: ListTile(
        title: Text(
          prediction.description.length < 45
              ? prediction.description
              : prediction.description.substring(0, 45) + " ...",
          style: widget.textStyle ??
              TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: widget.darkMode ? Colors.grey[100] : Colors.grey[850]),
          maxLines: 1,
        ),
      ),
    );
  }

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      color: widget.darkMode ? Colors.grey[800] : Colors.white,
      borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 10)
      ],
    );
  }

  Widget _searchInput(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _textEditingController,
            decoration: widget.inputDecoration ?? _inputStyle(),
            onChanged: widget.onChangeText,
            onSubmitted: (_) => _selectPlace(),
            onEditingComplete: _selectPlace,
            autofocus: false,
            focusNode: _fn,
            style: widget.textStyle ??
                TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: widget.darkMode ? Colors.grey[100] : Colors.grey[850]),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputStyle() {
    return InputDecoration(
      hintText: widget.placeholder,
      border: InputBorder.none,
      prefixIcon: Icon(Icons.search, color: widget.iconColor),
      suffixIcon: widget.hasClearButton
          ? Icon(Icons.clear, color: widget.iconColor)
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      hintStyle: TextStyle(
          color: widget.darkMode ? Colors.grey[100] : Colors.grey[850]),
    );
  }
}
