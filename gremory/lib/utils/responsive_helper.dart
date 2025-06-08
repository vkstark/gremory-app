import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static double getResponsiveWidth(BuildContext context, double mobileWidth, double tabletWidth, double desktopWidth) {
    if (isMobile(context)) return mobileWidth;
    if (isTablet(context)) return tabletWidth;
    return desktopWidth;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 16.0;
    return 24.0;
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return baseFontSize * 0.9;
    if (width < tabletBreakpoint) return baseFontSize;
    return baseFontSize * 1.1;
  }

  static double getMessageMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth * 0.85;
    if (isTablet(context)) return screenWidth * 0.75;
    return 800; // Fixed max width for desktop
  }

  static int getSuggestionColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 2;
  }

  static EdgeInsets getResponsivePaddingInsets(BuildContext context) {
    final padding = getResponsivePadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
  }

  static double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width * 0.8;
    if (isTablet(context)) return 320;
    return 380;
  }

  static bool shouldShowSidebarPersistent(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
}
