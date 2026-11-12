import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app/app.dart';

void main() {
  runApp(RyanGunshopApp(useLocalStorage: !kIsWeb));
}
