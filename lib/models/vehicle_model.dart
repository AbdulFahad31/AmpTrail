

enum ConnectorType {
  type2,
  ccs2,
  chademo,
  gb_t,
}

class Vehicle {
  final String id;
  final String brand;
  final String model;
  final String licensePlate;
  final ConnectorType connectorType;
  final int batteryCapacity; // in kWh

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.connectorType,
    required this.batteryCapacity,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'model': model,
    'licensePlate': licensePlate,
    'connectorType': connectorType.index,
    'batteryCapacity': batteryCapacity,
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'],
    brand: json['brand'],
    model: json['model'],
    licensePlate: json['licensePlate'],
    connectorType: ConnectorType.values[json['connectorType']],
    batteryCapacity: json['batteryCapacity'],
  );
}

// Mock initial vehicle
List<Vehicle> myVehicles = [
  Vehicle(
    id: 'v1',
    brand: 'Tesla',
    model: 'Model 3',
    licensePlate: 'KA 01 EV 1234',
    connectorType: ConnectorType.ccs2,
    batteryCapacity: 75,
  ),
];
