
import 'package:cloud_firestore/cloud_firestore.dart';

class Station {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerHr;
  final bool isAvailable;
  final double rating;
  final String chargerType;
  final int totalPorts;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHr,
    required this.isAvailable,
    required this.rating,
    this.chargerType = 'Type2',
    this.totalPorts = 1,
  });

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerHr': pricePerHr,
      'isAvailable': isAvailable,
      'rating': rating,
      'chargerType': chargerType,
      'totalPorts': totalPorts,
    };
  }

  // Create from JSON
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      pricePerHr: (json['pricePerUnit'] ?? json['pricePerHr'] ?? 0.0).toDouble(),
      isAvailable: json['isAvailable'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      chargerType: json['chargerType']?.toString() ?? 'Type2',
      totalPorts: json['totalPorts'] ?? json['availablePorts'] ?? 1,
    );
  }

  // Create from Firestore Document
  factory Station.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
      
      double parseDouble(dynamic value, double defaultValue) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      bool parseBool(dynamic value, bool defaultValue) {
        if (value == null) return defaultValue;
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        return defaultValue;
      }

      return Station(
        id: doc.id,
        name: data['name']?.toString() ?? '',
        address: data['address']?.toString() ?? '',
        latitude: parseDouble(data['latitude'], 0.0),
        longitude: parseDouble(data['longitude'], 0.0),
        pricePerHr: parseDouble(data['pricePerUnit'] ?? data['pricePerHr'] ?? data['price'], 0.0),
        isAvailable: parseBool(data['isAvailable'], true),
        rating: parseDouble(data['rating'], 0.0),
        chargerType: data['chargerType']?.toString() ?? 'Type2',
        totalPorts: data['totalPorts'] ?? data['availablePorts'] ?? 1,
      );
    } catch (e) {
      print("Error parsing Station ${doc.id}: $e");
      rethrow;
    }
  }
}

// Mock Data for Testing - Aditya will replace with real backend data
List<Station> dummyStations = [
  Station(
    id: '1',
    name: 'VoltPark Central',
    address: '12 Main St, MG Road, Bengaluru',
    latitude: 12.9716,
    longitude: 77.5946,
    pricePerHr: 50.0,
    isAvailable: true,
    rating: 4.5,
  ),
  Station(
    id: '2',
    name: 'EcoCharge Hub',
    address: '45 Green Ave, Indiranagar, Bengaluru',
    latitude: 12.9784,
    longitude: 77.6408,
    pricePerHr: 45.0,
    isAvailable: false,
    rating: 4.2,
  ),
  Station(
    id: '3',
    name: 'AmpZone Fast Charging',
    address: '88 Tech Park, Whitefield, Bengaluru',
    latitude: 12.9698,
    longitude: 77.7500,
    pricePerHr: 60.0,
    isAvailable: true,
    rating: 4.8,
  ),
  Station(
    id: '4',
    name: 'PowerHub Station',
    address: 'Koramangala 4th Block, Bengaluru',
    latitude: 12.9339,
    longitude: 77.6232,
    pricePerHr: 55.0,
    isAvailable: true,
    rating: 4.6,
  ),
];
