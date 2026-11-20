import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

enum LocationFailureType { serviceDisabled, denied, deniedForever }

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);
  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

class DeviceLocationService {
  Future<Position> getPosition() async {
    // Di platform Web, pengecekan isLocationServiceEnabled tidak didukung (akan throw MissingPluginException).
    // Hanya periksa serviceEnabled di Android/iOS/Desktop.
    if (!kIsWeb) {
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (_) {
        serviceEnabled = true;
      }
      if (!serviceEnabled) {
        throw const LocationFailure(
          LocationFailureType.serviceDisabled,
          'GPS/lokasi perangkat tidak aktif. Nyalakan melalui Settings perangkat.',
        );
      }
    }

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {
      permission = LocationPermission.always;
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureType.denied,
        'Izin lokasi ditolak. Foto dan draft tetap dapat digunakan.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.deniedForever,
        'Izin lokasi ditolak permanen. Ubah di Pengaturan izin browser/aplikasi.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      // Fallback jika GPS satelit lambat di emulator atau web
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
      } catch (_) {}

      throw LocationFailure(
        LocationFailureType.serviceDisabled,
        'Gagal memperoleh sinyal GPS: $e',
      );
    }
  }
}
