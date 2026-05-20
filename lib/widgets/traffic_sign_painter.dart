import 'dart:math';
import 'package:flutter/material.dart';

class TrafficSignWidget extends StatelessWidget {
  final String signId;
  final double size;
  final bool isGlowing;

  const TrafficSignWidget({
    super.key,
    required this.signId,
    this.size = 150.0,
    this.isGlowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: isGlowing
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getGlowColor(signId).withOpacity(0.3),
                  blurRadius: size * 0.2,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: TrafficSignPainter(signId: signId),
      ),
    );
  }

  Color _getGlowColor(String id) {
    if (id == 'stop' || id == 'no_entry' || id == 'red_signal') {
      return Colors.red;
    } else if (id == 'yellow_signal') {
      return Colors.amber;
    } else if (id == 'green_signal') {
      return Colors.green;
    } else if (id.startsWith('turn_') || id == 'keep_left' || id == 'parking' || id == 'hospital') {
      return Colors.blue;
    }
    return Colors.orange;
  }
}

class TrafficSignPainter extends CustomPainter {
  final String signId;

  TrafficSignPainter({required this.signId});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double center = w / 2;

    final Paint fillPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    switch (signId) {
      // ==========================================
      // WARNING SIGNS (Red Equilateral Triangle)
      // ==========================================
      case 'sharp_turn':
      case 'school_zone':
      case 'slippery_road':
      case 'animal_crossing':
      case 'crossroad':
      case 'traffic_light_ahead':
      case 'pedestrian_crossing':
      case 'narrow_road':
      case 'two_way_traffic':
        _drawWarningTriangle(canvas, size, fillPaint, strokePaint);
        _drawWarningSymbol(canvas, size, fillPaint, strokePaint);
        break;

      // ==========================================
      // REGULATORY SIGNS
      // ==========================================
      case 'stop':
        _drawStopOctagon(canvas, size, fillPaint, strokePaint);
        break;
      case 'no_entry':
        _drawNoEntry(canvas, size, fillPaint, strokePaint);
        break;
      case 'speed_limit':
        _drawSpeedLimit(canvas, size, fillPaint, strokePaint);
        break;
      case 'no_parking':
        _drawNoParking(canvas, size, fillPaint, strokePaint);
        break;
      case 'give_way':
        _drawGiveWay(canvas, size, fillPaint, strokePaint);
        break;
      case 'no_left_turn':
      case 'no_right_turn':
      case 'no_u_turn':
      case 'no_overtaking':
        _drawProhibitedCircle(canvas, size, fillPaint, strokePaint);
        _drawProhibitedSymbol(canvas, size, fillPaint, strokePaint);
        break;

      // ==========================================
      // MANDATORY SIGNS (Blue Circle)
      // ==========================================
      case 'turn_left':
      case 'turn_right':
      case 'keep_left':
      case 'keep_right':
      case 'go_straight':
      case 'roundabout':
      case 'mandatory_u_turn':
        _drawMandatoryCircle(canvas, size, fillPaint, strokePaint);
        _drawMandatorySymbol(canvas, size, fillPaint, strokePaint);
        break;

      // ==========================================
      // INFORMATION SIGNS (Blue Square)
      // ==========================================
      case 'hospital':
      case 'parking':
      case 'bus_stop':
      case 'petrol_pump':
      case 'telephone':
      case 'restaurant':
      case 'first_aid':
      case 'taxi_stand':
        _drawInfoSquare(canvas, size, fillPaint, strokePaint);
        _drawInfoSymbol(canvas, size, fillPaint, strokePaint);
        break;

      // ==========================================
      // TRAFFIC LIGHTS
      // ==========================================
      case 'red_signal':
        _drawTrafficLight(canvas, size, fillPaint, strokePaint, activeLight: 0);
        break;
      case 'yellow_signal':
        _drawTrafficLight(canvas, size, fillPaint, strokePaint, activeLight: 1);
        break;
      case 'green_signal':
        _drawTrafficLight(canvas, size, fillPaint, strokePaint, activeLight: 2);
        break;
      case 'pedestrian_signal':
        _drawPedestrianSignal(canvas, size, fillPaint, strokePaint);
        break;

      default:
        // Fallback placeholder sign (question mark)
        fillPaint.color = Colors.grey;
        canvas.drawCircle(Offset(center, center), center - 5, fillPaint);
        _drawText(canvas, size, '?', Colors.white, size.height * 0.6);
    }
  }

  // Draw generic warning triangle (apex pointing up)
  void _drawWarningTriangle(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;

    final path = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.95, h * 0.88)
      ..lineTo(w * 0.05, h * 0.88)
      ..close();

    // Fill white
    fill.color = Colors.white;
    canvas.drawPath(path, fill);

    // Red border
    stroke.color = const Color(0xFFFF3B30);
    stroke.strokeWidth = w * 0.08;
    canvas.drawPath(path, stroke);
  }

  // Draw Warning inner symbols
  void _drawWarningSymbol(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    final double center = w / 2;

    fill.color = Colors.black;
    stroke.color = Colors.black;
    stroke.style = PaintingStyle.stroke;

    if (signId == 'sharp_turn') {
      // Draw curved arrow
      stroke.strokeWidth = w * 0.07;
      stroke.strokeCap = StrokeCap.round;

      final arrowPath = Path()
        ..moveTo(w * 0.35, h * 0.7)
        ..quadraticBezierTo(w * 0.35, h * 0.45, w * 0.6, h * 0.45);
      canvas.drawPath(arrowPath, stroke);

      // Arrow head
      final headPath = Path()
        ..moveTo(w * 0.55, h * 0.38)
        ..lineTo(w * 0.7, h * 0.45)
        ..lineTo(w * 0.55, h * 0.52)
        ..close();
      fill.color = Colors.black;
      canvas.drawPath(headPath, fill);
    } 
    else if (signId == 'school_zone') {
      // Draw two walking silhouettes (parent and child)
      fill.color = Colors.black;
      // Adult head
      canvas.drawCircle(Offset(w * 0.43, h * 0.43), w * 0.05, fill);
      // Adult body
      final bodyPath = Path()
        ..moveTo(w * 0.36, h * 0.72)
        ..lineTo(w * 0.4, h * 0.5)
        ..lineTo(w * 0.46, h * 0.5)
        ..lineTo(w * 0.5, h * 0.72)
        ..lineTo(w * 0.45, h * 0.72)
        ..lineTo(w * 0.43, h * 0.6)
        ..lineTo(w * 0.41, h * 0.72)
        ..close();
      canvas.drawPath(bodyPath, fill);

      // Child head
      canvas.drawCircle(Offset(w * 0.6, h * 0.54), w * 0.04, fill);
      // Child body
      final childBodyPath = Path()
        ..moveTo(w * 0.54, h * 0.75)
        ..lineTo(w * 0.57, h * 0.6)
        ..lineTo(w * 0.63, h * 0.6)
        ..lineTo(w * 0.66, h * 0.75)
        ..lineTo(w * 0.62, h * 0.75)
        ..lineTo(w * 0.6, h * 0.67)
        ..lineTo(w * 0.58, h * 0.75)
        ..close();
      canvas.drawPath(childBodyPath, fill);
    } 
    else if (signId == 'slippery_road') {
      // Draw skidding car tracks
      stroke.strokeWidth = w * 0.03;
      stroke.strokeCap = StrokeCap.round;
      
      final leftTrack = Path()
        ..moveTo(w * 0.4, h * 0.72)
        ..cubicTo(w * 0.42, h * 0.67, w * 0.36, h * 0.62, w * 0.45, h * 0.55);
      canvas.drawPath(leftTrack, stroke);

      final rightTrack = Path()
        ..moveTo(w * 0.6, h * 0.72)
        ..cubicTo(w * 0.58, h * 0.67, w * 0.64, h * 0.62, w * 0.55, h * 0.55);
      canvas.drawPath(rightTrack, stroke);

      // Car silhouette tilted
      fill.color = Colors.black;
      final carPath = Path()
        ..moveTo(w * 0.38, h * 0.5)
        ..lineTo(w * 0.62, h * 0.46)
        ..lineTo(w * 0.58, h * 0.38)
        ..lineTo(w * 0.42, h * 0.4)
        ..close();
      canvas.drawPath(carPath, fill);
      // wheels
      canvas.drawCircle(Offset(w * 0.44, h * 0.51), w * 0.035, fill);
      canvas.drawCircle(Offset(w * 0.56, h * 0.49), w * 0.035, fill);
    } 
    else if (signId == 'animal_crossing') {
      // Draw animal silhouette (deer)
      fill.color = Colors.black;
      final deerPath = Path()
        ..moveTo(w * 0.38, h * 0.65) // back leg
        ..lineTo(w * 0.4, h * 0.55)
        ..lineTo(w * 0.48, h * 0.53) // body
        ..lineTo(w * 0.55, h * 0.42) // neck
        ..lineTo(w * 0.58, h * 0.44) // head
        ..lineTo(w * 0.57, h * 0.46)
        ..lineTo(w * 0.52, h * 0.5) // neck down
        ..lineTo(w * 0.54, h * 0.65) // front leg
        ..lineTo(w * 0.51, h * 0.65)
        ..lineTo(w * 0.49, h * 0.56)
        ..lineTo(w * 0.43, h * 0.57)
        ..lineTo(w * 0.41, h * 0.65)
        ..close();
      canvas.drawPath(deerPath, fill);

      // Antlers
      stroke.strokeWidth = w * 0.015;
      final antlers = Path()
        ..moveTo(w * 0.56, h * 0.42)
        ..lineTo(w * 0.58, h * 0.36)
        ..moveTo(w * 0.57, h * 0.39)
        ..lineTo(w * 0.61, h * 0.38);
      canvas.drawPath(antlers, stroke);
    } else if (signId == 'crossroad') {
      stroke.strokeWidth = w * 0.08;
      // Vertical bar
      canvas.drawLine(Offset(center, h * 0.38), Offset(center, h * 0.72), stroke);
      // Horizontal bar
      canvas.drawLine(Offset(w * 0.33, h * 0.55), Offset(w * 0.67, h * 0.55), stroke);
    } else if (signId == 'traffic_light_ahead') {
      // Small vertical black rectangle housing
      fill.color = const Color(0xFF1E293B);
      final housing = Rect.fromCenter(
        center: Offset(center, h * 0.55),
        width: w * 0.12,
        height: h * 0.30,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(housing, const Radius.circular(4)), fill);
      
      // Three dots: Red, Amber, Green
      fill.color = const Color(0xFFFF3B30);
      canvas.drawCircle(Offset(center, h * 0.45), w * 0.035, fill);
      fill.color = const Color(0xFFFFCC00);
      canvas.drawCircle(Offset(center, h * 0.55), w * 0.035, fill);
      fill.color = const Color(0xFF34C759);
      canvas.drawCircle(Offset(center, h * 0.65), w * 0.035, fill);
    } else if (signId == 'pedestrian_crossing') {
      // Zebra stripes at bottom
      stroke.strokeWidth = w * 0.02;
      for (double i = 0.3; i <= 0.7; i += 0.09) {
        canvas.drawLine(Offset(w * i, h * 0.72), Offset(w * (i + 0.04), h * 0.72), stroke);
      }
      // Walking silhouette
      fill.color = Colors.black;
      final double figureCenterY = h * 0.48;
      canvas.drawCircle(Offset(w * 0.5, figureCenterY - h * 0.08), w * 0.04, fill); // head
      
      // torso and legs
      final bodyPath = Path()
        ..moveTo(w * 0.48, figureCenterY - h * 0.03)
        ..lineTo(w * 0.53, figureCenterY + h * 0.03) // body
        ..lineTo(w * 0.46, figureCenterY + h * 0.15) // front leg
        ..lineTo(w * 0.5, figureCenterY + h * 0.15)
        ..lineTo(w * 0.55, figureCenterY + h * 0.05)
        ..lineTo(w * 0.6, figureCenterY + h * 0.15) // back leg
        ..lineTo(w * 0.64, figureCenterY + h * 0.13)
        ..close();
      canvas.drawPath(bodyPath, fill);
    } else if (signId == 'narrow_road') {
      stroke.strokeWidth = w * 0.05;
      stroke.strokeCap = StrokeCap.round;
      
      // Draw left boundary
      final leftPath = Path()
        ..moveTo(w * 0.35, h * 0.72)
        ..lineTo(w * 0.35, h * 0.6)
        ..lineTo(w * 0.45, h * 0.5)
        ..lineTo(w * 0.45, h * 0.38);
      canvas.drawPath(leftPath, stroke);
      
      // Draw right boundary
      final rightPath = Path()
        ..moveTo(w * 0.65, h * 0.72)
        ..lineTo(w * 0.65, h * 0.6)
        ..lineTo(w * 0.55, h * 0.5)
        ..lineTo(w * 0.55, h * 0.38);
      canvas.drawPath(rightPath, stroke);
    } else if (signId == 'two_way_traffic') {
      stroke.strokeWidth = w * 0.05;
      stroke.strokeCap = StrokeCap.round;
      
      // Up arrow (right side)
      canvas.drawLine(Offset(w * 0.58, h * 0.72), Offset(w * 0.58, h * 0.4), stroke);
      final upHead = Path()
        ..moveTo(w * 0.52, h * 0.46)
        ..lineTo(w * 0.58, h * 0.38)
        ..lineTo(w * 0.64, h * 0.46)
        ..close();
      fill.color = Colors.black;
      canvas.drawPath(upHead, fill);
      
      // Down arrow (left side)
      canvas.drawLine(Offset(w * 0.42, h * 0.38), Offset(w * 0.42, h * 0.7), stroke);
      final downHead = Path()
        ..moveTo(w * 0.36, h * 0.62)
        ..lineTo(w * 0.42, h * 0.7)
        ..lineTo(w * 0.48, h * 0.62)
        ..close();
      canvas.drawPath(downHead, fill);
    }
  }

  // Draw stop octagon
  void _drawStopOctagon(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double r = w * 0.5;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      double angle = i * pi / 4 + pi / 8;
      double x = r + (r - 4) * cos(angle);
      double y = r + (r - 4) * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Octagon fill
    fill.color = const Color(0xFFFF3B30);
    canvas.drawPath(path, fill);

    // Inner white border
    stroke.color = Colors.white;
    stroke.strokeWidth = w * 0.04;
    final borderPath = Path();
    for (int i = 0; i < 8; i++) {
      double angle = i * pi / 4 + pi / 8;
      double x = r + (r - w * 0.08) * cos(angle);
      double y = r + (r - w * 0.08) * sin(angle);
      if (i == 0) {
        borderPath.moveTo(x, y);
      } else {
        borderPath.lineTo(x, y);
      }
    }
    borderPath.close();
    canvas.drawPath(borderPath, stroke);

    // Draw Text STOP
    _drawText(canvas, size, 'STOP', Colors.white, w * 0.22);
  }

  // Draw No Entry
  void _drawNoEntry(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double center = w / 2;

    // Red circle
    fill.color = const Color(0xFFFF3B30);
    canvas.drawCircle(Offset(center, center), center - 5, fill);

    // White bar
    fill.color = Colors.white;
    final Rect bar = Rect.fromCenter(
      center: Offset(center, center),
      width: w * 0.7,
      height: w * 0.16,
    );
    canvas.drawRect(bar, fill);
  }

  // Draw Speed Limit
  void _drawSpeedLimit(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double center = w / 2;

    // White circle fill
    fill.color = Colors.white;
    canvas.drawCircle(Offset(center, center), center - 5, fill);

    // Red border
    stroke.color = const Color(0xFFFF3B30);
    stroke.strokeWidth = w * 0.09;
    canvas.drawCircle(Offset(center, center), center - stroke.strokeWidth / 2 - 2, stroke);

    // Speed limit text e.g. "80"
    _drawText(canvas, size, '80', Colors.black, w * 0.35);
  }

  // Draw No Parking
  void _drawNoParking(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double center = w / 2;

    // Blue circle fill
    fill.color = const Color(0xFF007AFF);
    canvas.drawCircle(Offset(center, center), center - 5, fill);

    // Red border
    stroke.color = const Color(0xFFFF3B30);
    stroke.strokeWidth = w * 0.09;
    canvas.drawCircle(Offset(center, center), center - stroke.strokeWidth / 2 - 2, stroke);

    // Diagonal slash
    stroke.color = const Color(0xFFFF3B30);
    stroke.strokeWidth = w * 0.08;
    canvas.drawLine(
      Offset(center - (center * 0.65), center - (center * 0.65)),
      Offset(center + (center * 0.65), center + (center * 0.65)),
      stroke,
    );
  }

  // Draw Give Way
  void _drawGiveWay(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    
    // Inverted equilateral triangle pointing down
    final path = Path()
      ..moveTo(w * 0.05, h * 0.15)
      ..lineTo(w * 0.95, h * 0.15)
      ..lineTo(w * 0.5, h * 0.9)
      ..close();
      
    fill.color = Colors.white;
    canvas.drawPath(path, fill);
    
    stroke.color = const Color(0xFFFF3B30);
    stroke.strokeWidth = w * 0.08;
    canvas.drawPath(path, stroke);
  }

  // Draw Prohibited Circle (White fill, Red thick border)
  void _drawProhibitedCircle(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double center = w / 2;
    
    // White background circle
    fill.color = Colors.white;
    canvas.drawCircle(Offset(center, center), center - 5, fill);
    
    // Red circular border
    stroke.color = const Color(0xFFFF3B30);
    stroke.strokeWidth = w * 0.09;
    canvas.drawCircle(Offset(center, center), center - stroke.strokeWidth / 2 - 2, stroke);
  }

  // Draw Prohibited symbols (No turns, No overtaking)
  void _drawProhibitedSymbol(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    final double center = w / 2;
    
    stroke.color = const Color(0xFFFF3B30);
    stroke.strokeWidth = w * 0.08;
    stroke.style = PaintingStyle.stroke;
    stroke.strokeCap = StrokeCap.round;
    
    if (signId == 'no_left_turn') {
      // Draw left arrow in black
      final arrowStroke = Paint()
        ..color = Colors.black
        ..strokeWidth = w * 0.07
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final arrowPath = Path()
        ..moveTo(w * 0.6, h * 0.65)
        ..lineTo(w * 0.6, h * 0.5)
        ..lineTo(w * 0.35, h * 0.5);
      canvas.drawPath(arrowPath, arrowStroke);
      
      final arrowHead = Path()
        ..moveTo(w * 0.42, h * 0.42)
        ..lineTo(w * 0.28, h * 0.5)
        ..lineTo(w * 0.42, h * 0.58)
        ..close();
      fill.color = Colors.black;
      canvas.drawPath(arrowHead, fill);
      
      // Draw diagonal slash
      canvas.drawLine(
        Offset(center - (center * 0.6), center - (center * 0.6)),
        Offset(center + (center * 0.6), center + (center * 0.6)),
        stroke,
      );
    }
    else if (signId == 'no_right_turn') {
      // Draw right arrow in black
      final arrowStroke = Paint()
        ..color = Colors.black
        ..strokeWidth = w * 0.07
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final arrowPath = Path()
        ..moveTo(w * 0.4, h * 0.65)
        ..lineTo(w * 0.4, h * 0.5)
        ..lineTo(w * 0.65, h * 0.5);
      canvas.drawPath(arrowPath, arrowStroke);
      
      final arrowHead = Path()
        ..moveTo(w * 0.58, h * 0.42)
        ..lineTo(w * 0.72, h * 0.5)
        ..lineTo(w * 0.58, h * 0.58)
        ..close();
      fill.color = Colors.black;
      canvas.drawPath(arrowHead, fill);
      
      // Draw diagonal slash
      canvas.drawLine(
        Offset(center - (center * 0.6), center - (center * 0.6)),
        Offset(center + (center * 0.6), center + (center * 0.6)),
        stroke,
      );
    }
    else if (signId == 'no_u_turn') {
      // Draw U-turn arrow in black
      final arrowStroke = Paint()
        ..color = Colors.black
        ..strokeWidth = w * 0.07
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final arrowPath = Path()
        ..moveTo(w * 0.38, h * 0.65)
        ..quadraticBezierTo(w * 0.38, h * 0.35, w * 0.62, h * 0.38)
        ..lineTo(w * 0.62, h * 0.65);
      canvas.drawPath(arrowPath, arrowStroke);
      
      final arrowHead = Path()
        ..moveTo(w * 0.31, h * 0.55)
        ..lineTo(w * 0.38, h * 0.67)
        ..lineTo(w * 0.45, h * 0.55)
        ..close();
      fill.color = Colors.black;
      canvas.drawPath(arrowHead, fill);
      
      // Draw diagonal slash
      canvas.drawLine(
        Offset(center - (center * 0.6), center - (center * 0.6)),
        Offset(center + (center * 0.6), center + (center * 0.6)),
        stroke,
      );
    }
    else if (signId == 'no_overtaking') {
      // Draw two cars side-by-side: left red, right black
      // Left car (red)
      final leftCar = Path()
        ..moveTo(w * 0.3, h * 0.58)
        ..lineTo(w * 0.46, h * 0.58)
        ..lineTo(w * 0.42, h * 0.48)
        ..lineTo(w * 0.34, h * 0.48)
        ..close();
      fill.color = const Color(0xFFFF3B30);
      canvas.drawPath(leftCar, fill);
      canvas.drawCircle(Offset(w * 0.34, h * 0.59), w * 0.035, fill);
      canvas.drawCircle(Offset(w * 0.42, h * 0.59), w * 0.035, fill);
      
      // Right car (black)
      final rightCar = Path()
        ..moveTo(w * 0.54, h * 0.58)
        ..lineTo(w * 0.7, h * 0.58)
        ..lineTo(w * 0.66, h * 0.48)
        ..lineTo(w * 0.58, h * 0.48)
        ..close();
      fill.color = Colors.black;
      canvas.drawPath(rightCar, fill);
      canvas.drawCircle(Offset(w * 0.58, h * 0.59), w * 0.035, fill);
      canvas.drawCircle(Offset(w * 0.66, h * 0.59), w * 0.035, fill);
    }
  }

  // Draw Mandatory blue circle
  void _drawMandatoryCircle(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double center = w / 2;

    // Blue background
    fill.color = const Color(0xFF007AFF);
    canvas.drawCircle(Offset(center, center), center - 5, fill);

    // White border
    stroke.color = Colors.white;
    stroke.strokeWidth = w * 0.03;
    canvas.drawCircle(Offset(center, center), center - stroke.strokeWidth / 2 - 4, stroke);
  }

  // Draw Mandatory Symbols
  void _drawMandatorySymbol(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    final double center = w / 2;

    fill.color = Colors.white;
    stroke.color = Colors.white;
    stroke.style = PaintingStyle.stroke;
    stroke.strokeCap = StrokeCap.round;

    if (signId == 'turn_left') {
      stroke.strokeWidth = w * 0.08;
      // Arrow shaft
      canvas.drawLine(Offset(w * 0.7, center), Offset(w * 0.35, center), stroke);
      // Arrow head
      final path = Path()
        ..moveTo(w * 0.42, h * 0.38)
        ..lineTo(w * 0.28, center)
        ..lineTo(w * 0.42, h * 0.62)
        ..close();
      fill.color = Colors.white;
      canvas.drawPath(path, fill);
    } 
    else if (signId == 'turn_right') {
      stroke.strokeWidth = w * 0.08;
      // Arrow shaft
      canvas.drawLine(Offset(w * 0.3, center), Offset(w * 0.65, center), stroke);
      // Arrow head
      final path = Path()
        ..moveTo(w * 0.58, h * 0.38)
        ..lineTo(w * 0.72, center)
        ..lineTo(w * 0.58, h * 0.62)
        ..close();
      fill.color = Colors.white;
      canvas.drawPath(path, fill);
    } 
    else if (signId == 'keep_left') {
      stroke.strokeWidth = w * 0.08;
      // Diagonal arrow shaft
      canvas.drawLine(
        Offset(center + w * 0.15, center - h * 0.15),
        Offset(center - w * 0.1, center + h * 0.1),
        stroke,
      );
      // Arrow head pointing down-left
      final path = Path()
        ..moveTo(center - w * 0.15, center)
        ..lineTo(center - w * 0.22, center + h * 0.22)
        ..lineTo(center, center + h * 0.15)
        ..close();
      fill.color = Colors.white;
      canvas.drawPath(path, fill);
    } else if (signId == 'keep_right') {
      stroke.strokeWidth = w * 0.08;
      // Diagonal arrow shaft
      canvas.drawLine(
        Offset(center - w * 0.15, center - h * 0.15),
        Offset(center + w * 0.1, center + h * 0.1),
        stroke,
      );
      // Arrow head pointing down-right
      final path = Path()
        ..moveTo(center, center + h * 0.15)
        ..lineTo(center + w * 0.22, center + h * 0.22)
        ..lineTo(center + w * 0.15, center)
        ..close();
      fill.color = Colors.white;
      canvas.drawPath(path, fill);
    } else if (signId == 'go_straight') {
      stroke.strokeWidth = w * 0.08;
      // Vertical shaft
      canvas.drawLine(Offset(center, h * 0.68), Offset(center, h * 0.35), stroke);
      // Arrow head pointing up
      final path = Path()
        ..moveTo(w * 0.38, h * 0.42)
        ..lineTo(center, h * 0.28)
        ..lineTo(w * 0.62, h * 0.42)
        ..close();
      fill.color = Colors.white;
      canvas.drawPath(path, fill);
    } else if (signId == 'roundabout') {
      stroke.strokeWidth = w * 0.05;
      final double radius = w * 0.2;
      canvas.drawCircle(Offset(center, center), radius, stroke);
      
      // Arrow heads along the circle (represented as white dots/wedges)
      fill.color = Colors.white;
      canvas.drawCircle(Offset(center + radius, center), w * 0.045, fill);
      canvas.drawCircle(Offset(center - radius * 0.5, center + radius * 0.86), w * 0.045, fill);
      canvas.drawCircle(Offset(center - radius * 0.5, center - radius * 0.86), w * 0.045, fill);
    } else if (signId == 'mandatory_u_turn') {
      stroke.strokeWidth = w * 0.08;
      // Draw U-turn arrow in white
      final arrowPath = Path()
        ..moveTo(w * 0.38, h * 0.65)
        ..quadraticBezierTo(w * 0.38, h * 0.35, w * 0.62, h * 0.38)
        ..lineTo(w * 0.62, h * 0.65);
      canvas.drawPath(arrowPath, stroke);
      
      final arrowHead = Path()
        ..moveTo(w * 0.31, h * 0.55)
        ..lineTo(w * 0.38, h * 0.67)
        ..lineTo(w * 0.45, h * 0.55)
        ..close();
      fill.color = Colors.white;
      canvas.drawPath(arrowHead, fill);
    }
  }

  // Draw Info Square
  void _drawInfoSquare(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;

    // Outer blue rounded rect
    fill.color = const Color(0xFF007AFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, w - 8, h - 8), const Radius.circular(16)),
      fill,
    );
  }

  // Draw Info Symbols
  void _drawInfoSymbol(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    final double center = w / 2;

    if (signId == 'parking') {
      _drawText(canvas, size, 'P', Colors.white, w * 0.45);
    } 
    else if (signId == 'hospital') {
      // Draw white center square
      fill.color = Colors.white;
      final whiteRect = Rect.fromCenter(
        center: Offset(center, center),
        width: w * 0.6,
        height: h * 0.6,
      );
      canvas.drawRect(whiteRect, fill);

      // Draw red cross
      fill.color = const Color(0xFFFF3B30);
      final verticalCross = Rect.fromCenter(
        center: Offset(center, center),
        width: w * 0.14,
        height: h * 0.4,
      );
      final horizontalCross = Rect.fromCenter(
        center: Offset(center, center),
        width: w * 0.4,
        height: h * 0.14,
      );
      canvas.drawRect(verticalCross, fill);
      canvas.drawRect(horizontalCross, fill);
    } 
    else if (signId == 'bus_stop') {
      // Draw white bus silhouette
      fill.color = Colors.white;
      // Bus body
      final busBody = Rect.fromCenter(
        center: Offset(center, center - h * 0.05),
        width: w * 0.5,
        height: h * 0.35,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(busBody, const Radius.circular(8)), fill);

      // Bus top cap
      final busCap = Rect.fromCenter(
        center: Offset(center, center - h * 0.2),
        width: w * 0.3,
        height: h * 0.08,
      );
      canvas.drawRect(busCap, fill);

      // Bus windows
      fill.color = const Color(0xFF007AFF);
      canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.22, w * 0.11, h * 0.09), fill);
      canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.22, w * 0.11, h * 0.09), fill);
      canvas.drawRect(Rect.fromLTWH(w * 0.58, h * 0.22, w * 0.11, h * 0.09), fill);

      // Bus wheels
      fill.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.35, center + h * 0.12), w * 0.07, fill);
      canvas.drawCircle(Offset(w * 0.65, center + h * 0.12), w * 0.07, fill);

      // Inner tyre holes
      fill.color = Colors.black;
      canvas.drawCircle(Offset(w * 0.35, center + h * 0.12), w * 0.03, fill);
      canvas.drawCircle(Offset(w * 0.65, center + h * 0.12), w * 0.03, fill);
    } 
    else if (signId == 'petrol_pump') {
      // Draw fuel dispenser
      fill.color = Colors.white;
      // Main pump body
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.33, h * 0.22, w * 0.34, h * 0.5), const Radius.circular(6)),
        fill,
      );
      // Dispenser screen
      fill.color = const Color(0xFF007AFF);
      canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.28, w * 0.24, h * 0.12), fill);

      // Hose and nozzle
      stroke.color = Colors.white;
      stroke.strokeWidth = w * 0.04;
      stroke.style = PaintingStyle.stroke;
      stroke.strokeCap = StrokeCap.round;

      final hosePath = Path()
        ..moveTo(w * 0.67, h * 0.35)
        ..quadraticBezierTo(w * 0.76, h * 0.42, w * 0.74, h * 0.62)
        ..lineTo(w * 0.71, h * 0.58);
      canvas.drawPath(hosePath, stroke);
    } else if (signId == 'telephone') {
      // Draw handset silhouette
      fill.color = Colors.white;
      final handset = Path()
        ..moveTo(w * 0.35, h * 0.35)
        ..quadraticBezierTo(w * 0.5, h * 0.3, w * 0.65, h * 0.35)
        ..lineTo(w * 0.6, h * 0.48)
        ..quadraticBezierTo(w * 0.5, h * 0.43, w * 0.4, h * 0.48)
        ..close();
      canvas.drawPath(handset, fill);
      // Telephone ear/mouth pieces
      canvas.drawCircle(Offset(w * 0.35, h * 0.4), w * 0.06, fill);
      canvas.drawCircle(Offset(w * 0.65, h * 0.4), w * 0.06, fill);
    } else if (signId == 'restaurant') {
      // Draw white fork and knife side by side
      fill.color = Colors.white;
      // Fork tines
      canvas.drawRect(Rect.fromLTWH(w * 0.36, h * 0.32, w * 0.02, h * 0.12), fill);
      canvas.drawRect(Rect.fromLTWH(w * 0.40, h * 0.32, w * 0.02, h * 0.12), fill);
      canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.32, w * 0.02, h * 0.12), fill);
      // Fork base & handle
      canvas.drawRect(Rect.fromLTWH(w * 0.36, h * 0.44, w * 0.10, h * 0.04), fill);
      canvas.drawRect(Rect.fromLTWH(w * 0.40, h * 0.48, w * 0.02, h * 0.20), fill);
      
      // Knife blade
      final knifeBlade = Path()
        ..moveTo(w * 0.58, h * 0.32)
        ..lineTo(w * 0.64, h * 0.34)
        ..lineTo(w * 0.64, h * 0.48)
        ..lineTo(w * 0.58, h * 0.48)
        ..close();
      canvas.drawPath(knifeBlade, fill);
      // Knife handle
      canvas.drawRect(Rect.fromLTWH(w * 0.60, h * 0.48, w * 0.02, h * 0.20), fill);
    } else if (signId == 'first_aid') {
      // White square
      fill.color = Colors.white;
      final whiteSquare = Rect.fromCenter(
        center: Offset(center, center),
        width: w * 0.55,
        height: h * 0.55,
      );
      canvas.drawRect(whiteSquare, fill);
      
      // Green cross
      fill.color = const Color(0xFF34C759); // Green Cross
      final vCross = Rect.fromCenter(center: Offset(center, center), width: w * 0.12, height: h * 0.36);
      final hCross = Rect.fromCenter(center: Offset(center, center), width: w * 0.36, height: h * 0.12);
      canvas.drawRect(vCross, fill);
      canvas.drawRect(hCross, fill);
    } else if (signId == 'taxi_stand') {
      // Draw text "TAXI" inside
      _drawText(canvas, size, 'TAXI', Colors.white, w * 0.18);
    }
  }

  // Draw 3-lamp Traffic Light
  void _drawTrafficLight(Canvas canvas, Size size, Paint fill, Paint stroke, {required int activeLight}) {
    final double w = size.width;
    final double h = size.height;
    final double center = w / 2;

    // Housing black rounded rect
    fill.color = const Color(0xFF1E293B);
    final housing = Rect.fromCenter(
      center: Offset(center, center),
      width: w * 0.45,
      height: h * 0.9,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(housing, const Radius.circular(24)), fill);

    // Draw three lamp holes / light circles
    final double spacing = h * 0.25;
    final double startY = h * 0.25;

    for (int i = 0; i < 3; i++) {
      double y = startY + (i * spacing);
      Color lampColor = Colors.grey.shade800;

      if (i == activeLight) {
        if (i == 0) lampColor = const Color(0xFFFF3B30); // Glowing Red
        if (i == 1) lampColor = const Color(0xFFFFCC00); // Glowing Yellow
        if (i == 2) lampColor = const Color(0xFF34C759); // Glowing Green
      }

      fill.color = lampColor;
      canvas.drawCircle(Offset(center, y), w * 0.13, fill);

      // Light shield visors
      stroke.color = Colors.black;
      stroke.strokeWidth = w * 0.02;
      stroke.style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center, y), radius: w * 0.14),
        pi,
        pi,
        false,
        stroke,
      );
    }
  }

  // Draw Pedestrian Signal
  void _drawPedestrianSignal(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final double w = size.width;
    final double h = size.height;
    final double center = w / 2;

    // Black signal housing
    fill.color = const Color(0xFF1E293B);
    final housing = Rect.fromCenter(
      center: Offset(center, center),
      width: w * 0.45,
      height: h * 0.85,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(housing, const Radius.circular(16)), fill);

    // Dividing bar
    fill.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(w * 0.27, h * 0.48, w * 0.46, h * 0.04), fill);

    // Top Compartment - Glowing red hand or standing man
    // Let's paint a standing figure (red)
    fill.color = const Color(0xFFFF3B30);
    final double topCenterY = h * 0.28;
    canvas.drawCircle(Offset(center, topCenterY - h * 0.08), w * 0.035, fill); // head
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center, topCenterY), width: w * 0.05, height: h * 0.1),
      fill,
    ); // body
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center - w * 0.04, topCenterY), width: w * 0.02, height: h * 0.08),
      fill,
    ); // left arm
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center + w * 0.04, topCenterY), width: w * 0.02, height: h * 0.08),
      fill,
    ); // right arm
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center - w * 0.015, topCenterY + h * 0.08), width: w * 0.02, height: h * 0.06),
      fill,
    ); // left leg
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center + w * 0.015, topCenterY + h * 0.08), width: w * 0.02, height: h * 0.06),
      fill,
    ); // right leg

    // Bottom Compartment - Glowing green walking man
    fill.color = const Color(0xFF34C759);
    final double bottomCenterY = h * 0.72;
    canvas.drawCircle(Offset(center + w * 0.03, bottomCenterY - h * 0.08), w * 0.035, fill); // head

    // Walk path body
    final walkingBody = Path()
      ..moveTo(center + w * 0.02, bottomCenterY - h * 0.04)
      ..lineTo(center - w * 0.04, bottomCenterY + h * 0.01) // torso
      ..lineTo(center - w * 0.08, bottomCenterY + h * 0.09) // front leg
      ..lineTo(center - w * 0.05, bottomCenterY + h * 0.09)
      ..lineTo(center - w * 0.01, bottomCenterY + h * 0.02)
      ..lineTo(center + w * 0.05, bottomCenterY + h * 0.08) // back leg
      ..lineTo(center + w * 0.08, bottomCenterY + h * 0.08)
      ..lineTo(center + w * 0.03, bottomCenterY - h * 0.01)
      ..close();
    canvas.drawPath(walkingBody, fill);

    // Walking arms
    stroke.color = const Color(0xFF34C759);
    stroke.strokeWidth = w * 0.02;
    stroke.strokeCap = StrokeCap.round;
    // Front arm swinging forward
    canvas.drawLine(
      Offset(center - w * 0.01, bottomCenterY - h * 0.03),
      Offset(center - w * 0.07, bottomCenterY - h * 0.01),
      stroke,
    );
    // Back arm swinging back
    canvas.drawLine(
      Offset(center + w * 0.03, bottomCenterY - h * 0.03),
      Offset(center + w * 0.08, bottomCenterY - h * 0.05),
      stroke,
    );
  }

  // Text drawing helper
  void _drawText(Canvas canvas, Size size, String text, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
