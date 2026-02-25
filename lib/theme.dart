import 'package:flutter/material.dart';

class AppColors {
  //static const primaryBlue = Color(0xFF00A4BD);
  static const primaryBlue = Color(0xFF007ACC);
  static const secondaryBlue = Color(0xFFE5F6FA);
  static const accentBlue = Color(0xFF007A91);
  static const textPrimary = Colors.black87;
  static const textSecondary = Colors.black45;
}

class AppTextStyles {
  static const titleBoldWhite = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const headingBoldPrimary = TextStyle(
    color: AppColors.primaryBlue,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const normalPrimary = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
  );

  static const normalSecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );
}
