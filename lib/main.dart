import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lib/app/app.dart';
import 'lib/app/service/supabase_service.dart';

// Solo importar Firebase si no es desktop
import 'package:firebase_core/firebase_core.dart'
if (dart.library.html) 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase (funciona en TODAS las plataformas)
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}