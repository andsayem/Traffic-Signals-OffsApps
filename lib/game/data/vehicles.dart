import 'package:flutter/material.dart';

import '../engine/vec3.dart';
import 'bicycle.dart';
import 'motorbike.dart';
import 'part.dart';
import 'rider.dart';
import 'sportbike.dart';
import 'car_body.dart';

/// A buildable vehicle and how to present it.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.icon,
    required this.build,
    required this.cameraTarget,
    required this.cameraDistance,
    required this.groundScale,
    required this.shadowSize,
    required this.wheelRadius,
    required this.defaultPaint,
    this.rider,
  });

  final String id, name;
  final IconData icon;
  final List<VehiclePart> Function() build;
  final V3 cameraTarget;
  final double cameraDistance;

  /// Turntable size relative to the car's.
  final double groundScale;

  /// Shadow ellipse radii along X and Z.
  final (double, double) shadowSize;
  final double wheelRadius;
  final Color defaultPaint;

  /// Who sits on or in the vehicle while driving.
  final RiderPose? rider;
}

const car = Vehicle(
  id: 'car',
  name: 'Car',
  icon: Icons.directions_car_rounded,
  build: buildModernSedan,
  cameraTarget: V3(0, 0.75, 0),
  cameraDistance: 9,
  groundScale: 1,
  shadowSize: (2.35, 1.1),
  wheelRadius: 0.36,
  defaultPaint: Color(0xFFD32F2F),
  rider: RiderPose(
    look: RiderLook(
      top: Color(0xFF1565C0),
      pants: Color(0xFF2B3A55),
      shoes: Color(0xFF222222),
    ),
    hip: V3(0.12, 0.7, -0.38),
    shoulders: V3(0.0, 1.13, -0.38),
    head: V3(0.03, 1.29, -0.38),
    elbow: V3(0.27, 0.92, 0.2),
    hand: V3(0.47, 1.03, 0.13),
    knee: V3(0.5, 0.77, 0.12),
    foot: V3(0.66, 0.47, 0.13),
    thigh: 0.4,
    shin: 0.36,
  ),
);

const suv = Vehicle(
  id: 'suv',
  name: 'SUV',
  icon: Icons.airport_shuttle_rounded,
  build: buildSuv,
  cameraTarget: V3(0, 0.95, 0),
  cameraDistance: 9.6,
  groundScale: 1.02,
  shadowSize: (2.35, 1.15),
  wheelRadius: 0.42,
  defaultPaint: Color(0xFF37474F),
  rider: RiderPose(
    look: RiderLook(
      top: Color(0xFFEF6C00),
      pants: Color(0xFF263238),
      shoes: Color(0xFF3E2723),
    ),
    hip: V3(0.12, 0.88, -0.38),
    shoulders: V3(0.0, 1.31, -0.38),
    head: V3(0.03, 1.47, -0.38),
    elbow: V3(0.34, 1.12, 0.2),
    hand: V3(0.56, 1.2, 0.13),
    knee: V3(0.5, 0.95, 0.12),
    foot: V3(0.68, 0.65, 0.13),
    thigh: 0.4,
    shin: 0.36,
  ),
);

const motorbike = Vehicle(
  id: 'motorbike',
  name: 'Motorbike',
  icon: Icons.two_wheeler_rounded,
  build: buildMotorbike,
  cameraTarget: V3(0, 0.62, 0),
  cameraDistance: 4.6,
  groundScale: 0.55,
  shadowSize: (1.15, 0.32),
  wheelRadius: 0.32,
  defaultPaint: Color(0xFF1E6FD9),
  rider: RiderPose(
    look: RiderLook(
      top: Color(0xFF263238),
      pants: Color(0xFF2B3A55),
      shoes: Color(0xFF3E2723),
      helmet: true,
      gloves: true,
    ),
    hip: V3(-0.22, 1.0, 0),
    shoulders: V3(0.04, 1.4, 0),
    head: V3(0.11, 1.56, 0),
    elbow: V3(0.22, 1.2, 0.25),
    hand: V3(0.415, 1.07, 0.31),
    knee: V3(0.14, 0.73, 0.21),
    foot: V3(-0.02, 0.31, 0.19),
  ),
);

const sportBike = Vehicle(
  id: 'sportbike',
  name: 'Sports Bike',
  icon: Icons.sports_motorsports_rounded,
  build: buildSportBike,
  cameraTarget: V3(0, 0.66, 0),
  cameraDistance: 4.6,
  groundScale: 0.55,
  shadowSize: (1.15, 0.32),
  wheelRadius: 0.32,
  defaultPaint: Color(0xFFD50000),
  rider: RiderPose(
    look: RiderLook(
      top: Color(0xFF212121),
      pants: Color(0xFF212121),
      shoes: Color(0xFF212121),
      helmet: true,
      helmetColor: Color(0xFFD50000),
      gloves: true,
    ),
    hip: V3(-0.22, 1.0, 0),
    shoulders: V3(0.12, 1.33, 0),
    head: V3(0.22, 1.45, 0),
    elbow: V3(0.28, 1.14, 0.24),
    hand: V3(0.415, 1.07, 0.31),
    knee: V3(0.16, 0.76, 0.21),
    foot: V3(-0.02, 0.36, 0.19),
  ),
);

const bicycle = Vehicle(
  id: 'bicycle',
  name: 'Bicycle',
  icon: Icons.pedal_bike_rounded,
  build: buildBicycle,
  cameraTarget: V3(0, 0.55, 0),
  cameraDistance: 4,
  groundScale: 0.48,
  shadowSize: (0.95, 0.2),
  wheelRadius: 0.34,
  defaultPaint: Color(0xFF2E7D32),
  rider: RiderPose(
    look: RiderLook(
      top: Color(0xFFFFC107),
      pants: Color(0xFF212121),
      shoes: Color(0xFFF5F5F5),
      helmet: true,
      helmetColor: Color(0xFFF5F5F5),
      shorts: true,
    ),
    hip: V3(-0.17, 1.07, 0),
    shoulders: V3(0.1, 1.42, 0),
    head: V3(0.17, 1.57, 0),
    elbow: V3(0.24, 1.2, 0.22),
    hand: V3(0.37, 0.99, 0.23),
    hipWidth: 0.09,
    shoulderWidth: 0.18,
    pedals: Pedals(
      center: V3(0, 0.28, 0),
      crank: 0.16,
      footZ: 0.14,
      spinRatio: 0.45,
    ),
  ),
);

// Easiest first: pedal bike up to the full-size cars.
const vehicles = [bicycle, sportBike, motorbike, suv, car];
