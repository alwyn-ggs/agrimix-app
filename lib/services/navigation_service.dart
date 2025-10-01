import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) async {
    final state = navigatorKey.currentState;
    if (state == null) return null;
    return state.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) async {
    final state = navigatorKey.currentState;
    if (state == null) return null;
    return state.pushReplacementNamed<T, TO>(routeName, arguments: arguments, result: result);
  }
}


