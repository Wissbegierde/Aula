import 'package:flutter/foundation.dart';

class DashboardProvider extends ChangeNotifier {
  bool _lightsOn = true;
  int _occupancy = 14;
  final String classroomName;

  DashboardProvider({this.classroomName = 'Aula 201 — Edificio B'});

  bool get lightsOn => _lightsOn;
  int get occupancy => _occupancy;

  void toggleLights() {
    _lightsOn = !_lightsOn;
    notifyListeners();
  }

  void setOccupancy(int value) {
    _occupancy = value;
    notifyListeners();
  }
}
