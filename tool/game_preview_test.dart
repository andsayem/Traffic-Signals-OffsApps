// Renders game preview PNGs: flutter test tool/game_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:traffic_signal_symbols/game/data/part.dart';
import 'package:traffic_signal_symbols/game/data/vehicles.dart';
import 'package:traffic_signal_symbols/game/engine/renderer.dart';
import 'package:traffic_signal_symbols/game/logic/assembly.dart';
import 'package:traffic_signal_symbols/game/widgets/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(
  String name,
  AssemblyController car,
  OrbitCamera cam, {
  bool labels = false,
}) async {
  const size = Size(800, 600);
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF141922));
  drawScene(canvas, size, cam, car.renderItems(), car.style);
  if (labels) {
    paintLabels(canvas, cam, [
      for (final p in car.parts)
        Label3D(car.anchorOf(p), p.name, p.group.color),
    ]);
  }
  final img = await rec.endRecording().toImage(800, 600);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render previews', (tester) async {
    await tester.runAsync(() async {
      const only = String.fromEnvironment('only');
      for (final v in vehicles) {
        if (only.isNotEmpty && v.id != only) continue;
        OrbitCamera cam({
          double yaw = OrbitCamera.homeYaw,
          double pitch = OrbitCamera.homePitch,
        }) => OrbitCamera(
          yaw: yaw,
          pitch: pitch,
          target: v.cameraTarget,
          distance: v.cameraDistance,
        );
        final full = AssemblyController(vehicle: v)..showHint = false;
        full.installAll();
        await _render('${v.id}_front', full, cam());
        await _render('${v.id}_side', full, cam(yaw: 0, pitch: 0.12));
        await _render('${v.id}_back', full, cam(yaw: 3.8, pitch: 0.3));
        if (const bool.fromEnvironment('quick')) continue;
        final half = AssemblyController(vehicle: v);
        for (var i = 0; i < half.parts.length ~/ 2; i++) {
          half.install(half.nextHint!);
          half.tick(2);
        }
        await _render('${v.id}_half', half, cam(pitch: 0.6));
        final learn = AssemblyController(vehicle: v)
          ..showHint = false
          ..installAll()
          ..setExplode(0.7);
        await _render('${v.id}_learn', learn, cam(), labels: true);
        final drive = AssemblyController(vehicle: v)
          ..showHint = false
          ..installAll()
          ..toggleDrive();
        drive.tick(0.05);
        drive.tick(1);
        await _render('${v.id}_drive', drive, cam());
        await _render('${v.id}_drive_side', drive, cam(yaw: 0, pitch: 0.12));
      }
    });
  });
}
