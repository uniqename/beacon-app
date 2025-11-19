import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentCountry;
  String? _currentState;
  String? _currentCity;

  Position? get currentPosition => _currentPosition;
  String? get currentCountry => _currentCountry;
  String? get currentState => _currentState;
  String? get currentCity => _currentCity;

  bool get isInGhana => _currentCountry?.toLowerCase() == 'ghana';
  bool get isInUSA => _currentCountry?.toLowerCase() == 'united states' || 
                     _currentCountry?.toLowerCase() == 'usa';

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      await _updateLocationInfo(position);
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<void> _updateLocationInfo(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _currentCountry = place.country;
        _currentState = place.administrativeArea;
        _currentCity = place.locality;
      }
    } catch (e) {
      print('Error getting place info: $e');
    }
  }

  String getLocationBasedEmergencyNumber() {
    if (isInGhana) {
      return '191'; // Ghana Police
    } else if (isInUSA) {
      return '911'; // USA Emergency
    } else {
      return '911'; // Default to international standard
    }
  }

  String getLocationBasedFireNumber() {
    if (isInGhana) {
      return '192'; // Ghana Fire Service
    } else if (isInUSA) {
      return '911'; // USA Emergency
    } else {
      return '911';
    }
  }

  String getLocationBasedAmbulanceNumber() {
    if (isInGhana) {
      return '193'; // Ghana Ambulance
    } else if (isInUSA) {
      return '911'; // USA Emergency
    } else {
      return '911';
    }
  }

  String getLocationDisplayText() {
    if (_currentCity != null && _currentState != null) {
      return '$_currentCity, $_currentState';
    } else if (_currentState != null) {
      return _currentState!;
    } else if (_currentCountry != null) {
      return _currentCountry!;
    } else {
      return 'Location not available';
    }
  }
}