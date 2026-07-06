import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate100 = Color(0xFFF1F5F9);

  static const lightBg = Color(0xFFF8FAFC);
  static const lightText = Color(0xFF0F172A);

  static const indigo400 = Color(0xFF818CF8);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);

  static const gradientTextColors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];

  static const studentAccent = Color(0xFF10B981);
  static const studentAccentLight = Color(0xFF34D399);
  static const teacherAccent = Color(0xFF0EA5E9);
  static const teacherAccentLight = Color(0xFF38BDF8);
  static const ownerAccent = Color(0xFF8B5CF6);
  static const ownerAccentLight = Color(0xFFA78BFA);
  static const parentAccent = Color(0xFFF59E0B);
  static const parentAccentLight = Color(0xFFFBBF24);

  static const rose400 = Color(0xFFFB7185);
  static const rose500 = Color(0xFFF43F5E);
  static const emerald500 = Color(0xFF10B981);
  static const amber500 = Color(0xFFF59E0B);

  static const white10 = Color(0x1AFFFFFF);
  static const white05 = Color(0x0DFFFFFF);

  static Color forRole(String role) {
    switch (role) {
      case 'teacher':
        return teacherAccent;
      case 'owner':
        return ownerAccent;
      case 'parent':
        return parentAccent;
      case 'student':
      default:
        return studentAccent;
    }
  }
}
