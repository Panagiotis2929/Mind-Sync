import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/home_screen.dart';
import 'features/audio_engine/bloc/audio_engine_bloc.dart';
import 'features/audio_engine/services/api_client.dart';
import 'features/audio_engine/services/web_audio_synthesizer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on mobile; allow free resize on desktop/web
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Force dark system UI overlay to match cyberpunk theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.light,
    systemNavigationBarColor:  Color(0xFF050810),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MindSyncApp());
}

/// MindSyncApp is the root widget. It wires the dependency graph at the top
/// of the widget tree so all descendants can access shared services via
/// BlocProvider and RepositoryProvider without drilling.
class MindSyncApp extends StatelessWidget {
  const MindSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Construct shared singletons ──────────────────────────────────────
    final apiClient  = MindSyncApiClient();
    final synthesizer = WebAudioSynthesizer();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioEngineBloc>(
          create: (_) => AudioEngineBloc(
            api:   apiClient,
            synth: synthesizer,
          ),
          // Bloc is lazily created; audio starts only when user presses Play
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title:        'Mind-Sync · Neural Audio Architect',
        debugShowCheckedModeBanner: false,
        theme:        MindSyncTheme.dark,
        darkTheme:    MindSyncTheme.dark,
        themeMode:    ThemeMode.dark,
        home:         const HomeScreen(),
        builder: (context, child) {
          // Apply global text scale clamping to prevent system font size
          // from breaking the precision-designed cyberpunk layout
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.15),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
