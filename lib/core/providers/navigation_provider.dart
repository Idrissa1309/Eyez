import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationIndexProvider = StateProvider<int>((ref) {
  return 0; // Default to Home (Accueil)
});
