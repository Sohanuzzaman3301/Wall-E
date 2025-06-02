import 'package:flutter/material.dart';
import 'package:ms_undraw/ms_undraw.dart';

/// A utility class that provides easy access to undraw illustrations used in the app
class UndrawIllustrations {
  // Private constructor to prevent instantiation
  UndrawIllustrations._();

  // Onboarding illustrations
  static Widget get welcome => UnDraw(
        illustration: UnDrawIllustration.welcome,
        color: Colors.blue,
        height: 250,
      );

  static Widget get environmentalCare => UnDraw(
        illustration: UnDrawIllustration.eco_conscious,
        color: Colors.green,
        height: 250,
      );

  // Empty states
  static Widget get emptyBox => UnDraw(
        illustration: UnDrawIllustration.empty,
        color: Colors.grey,
        height: 200,
      );

  static Widget get noData => UnDraw(
        illustration: UnDrawIllustration.no_data,
        color: Colors.grey,
        height: 200,
      );

  // Success/Error states
  static Widget get success => UnDraw(
        illustration: UnDrawIllustration.completed,
        color: Colors.green,
        height: 200,
      );

  static Widget get error => UnDraw(
        illustration: UnDrawIllustration.warning,
        color: Colors.red,
        height: 200,
      );

  // Feature illustrations
  static Widget get recycling => UnDraw(
        illustration: UnDrawIllustration.eco_conscious,
        color: Colors.green,
        height: 250,
      );

  static Widget get wasteSorting => UnDraw(
        illustration: UnDrawIllustration.tasks,
        color: Colors.blue,
        height: 250,
      );

  static Widget get environmentalProtection => UnDraw(
        illustration: UnDrawIllustration.eco_conscious,
        color: Colors.green,
        height: 250,
      );

  // Loading states
  static Widget get loading => UnDraw(
        illustration: UnDrawIllustration.loading,
        color: Colors.blue,
        height: 200,
      );

  // Custom illustration with parameters
  static Widget custom({
    required UnDrawIllustration illustration,
    required Color color,
    double height = 200,
    double? width,
  }) {
    return UnDraw(
      illustration: illustration,
      color: color,
      height: height,
      width: width,
    );
  }
} 