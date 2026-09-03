import 'package:flutter/material.dart';

class FloatingParticle {
  final String id;
  final String text;
  final Offset position;
  final DateTime createdAt;
  final Color color;
  final double fontSize;
  final bool showFireIcon;

  FloatingParticle({
    required this.id,
    required this.text,
    required this.position,
    required this.createdAt,
    this.color = Colors.white,
    this.fontSize = 24.0,
    this.showFireIcon = false,
  });
}
