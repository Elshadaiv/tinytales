import 'package:flutter/foundation.dart';

class SelectedBabyService
{
  static final ValueNotifier<String?> selectedBabyId = ValueNotifier<String?>(null);
  static final ValueNotifier<String> selectedBabyName = ValueNotifier<String>("");
}