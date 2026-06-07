# Mind-Sync: Neural Audio Architect
```
███╗   ███╗██╗███╗   ██╗██████╗       ███████╗██╗   ██╗███╗   ██╗ ██████╗
████╗ ████║██║████╗  ██║██╔══██╗      ██╔════╝╚██╗ ██╔╝████╗  ██║██╔════╝
██╔████╔██║██║██╔██╗ ██║██║  ██║█████╗███████╗ ╚████╔╝ ██╔██╗ ██║██║     
██║╚██╔╝██║██║██║╚██╗██║██║  ██║╚════╝╚════██║  ╚██╔╝  ██║╚██╗██║██║     
██║ ╚═╝ ██║██║██║ ╚████║██████╔╝      ███████║   ██║   ██║ ╚████║╚██████╗
╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝       ╚══════╝   ╚═╝   ╚═╝  ╚═══╝ ╚═════╝
                  N E U R A L   A U D I O   A R C H I T E C T
```

Το Mind-Sync είναι μια εφαρμογή που χρησιμοποιεί καθαρά μαθηματικά για να παράγει ήχους που βοηθούν στη συγκέντρωση, τη χαλάρωση ή τον ύπνο, αξιοποιώντας την τεχνολογία του **Binaural Beat Entrainment**. 
Αντί να παίζει προηχογραφημένα αρχεία (MP3), η εφαρμογή "συνθέτει" τον ήχο τη στιγμή που τον ακούς, υπολογίζοντας συχνότητες και κυματομορφές σε πραγματικό χρόνο.

---

# Οδηγίες Τοπικής Εκτέλεσης

Για να λειτουργήσει η εφαρμογή και να εμφανιστεί η ένδειξη **DSP ONLINE**, απαιτείται η ταυτόχρονη εκτέλεση του backend και του frontend.

## 1. Backend
Ανοίξτε ένα τερματικό, μεταβείτε στον φάκελο `backend` και εκκινήστε τον server:

```bash
cd backend
go run cmd/server/main.go
```
## 2. frontend 
Ανοίξτε ένα δεύτερο τερματικό, μεταβείτε στον φάκελο frontend και εκτελέστε την εφαρμογή στον browser:

```bash
cd frontend
flutter run -d chrome
```
Η εφαρμογή θα συνδεθεί αυτόματα με τον τοπικό server μόλις ολοκληρωθεί η εκκίνηση του frontend.

---

### Τι κάνει την εφαρμογή να ξεχωρίζει;
* **Zero File I/O:** Δεν χρησιμοποιούνται αρχεία ήχου. Όλα παράγονται από μαθηματικούς τύπους.
* **DSP Engine:** Ο ήχος δημιουργείται στο πρόγραμμα περιήγησης (browser) μέσω του **Web Audio API**.
* **Responsive UI:** Φτιαγμένο με **Flutter Web**, με cyberpunk αισθητική.
* **Offline-First:** Λειτουργεί αυτόνομα, χωρίς cloud εξαρτήσεις.

### Τεχνολογίες που χρησιμοποιήθηκαν
* **Frontend:** Flutter Web (Dart)
* **Backend:** Go (Golang)
* **Βάση Δεδομένων:** SQLite (για την αποθήκευση των προτιμήσεων του χρήστη)
* **Ήχος:** Web Audio API (PCM synthesis)

---

### Debugging
Κατά την εκτέλεση της εφαρμογής στον browser, θα εμφανιστεί το παρακάτω σφάλμα στην κονσόλα, το οποίο οφείλεται στον τρόπο επικοινωνίας του Dart με τη JavaScript:
```text
Failed to start audio: TypeError: Instance of 'NativeFloat32List': 
type 'NativeFloat32List' is not a subtype of type 'JsObject'
```

---

## Directory Structure
 
```
mind-sync/
├── backend/                          # Go 1.22 HTTP API
│   ├── cmd/
│   │   └── server/
│   │       └── main.go               # Entry point, DI wiring, graceful shutdown
│   ├── internal/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── neural_blueprint.go   # Core DSP output entity
│   │   │   │   ├── neural_signature.go   # Saved preset + session entities
│   │   │   │   └── errors.go             # Typed domain error hierarchy
│   │   │   └── repositories/
│   │   │       └── interfaces.go         # Pure Go repository contracts
│   │   ├── application/
│   │   │   ├── dtos/
│   │   │   │   ├── blueprint_dto.go      # Request/response DTOs
│   │   │   │   └── signature_dto.go
│   │   │   └── usecases/
│   │   │       ├── compute_blueprint.go  # DSP orchestration use case
│   │   │       ├── manage_signatures.go  # Preset CRUD use case
│   │   │       └── track_sessions.go     # Session lifecycle use case
│   │   ├── infrastructure/
│   │   │   ├── persistence/
│   │   │   │   ├── sqlite_db.go          # Schema, WAL, connection pool
│   │   │   │   ├── signature_repo.go     # SQLite NeuralSignature impl
│   │   │   │   └── session_repo.go       # SQLite SessionRecord impl
│   │   │   └── logger/
│   │   │       └── logger.go             # Structured zap logger
│   │   └── interfaces/http/
│   │       ├── handlers/
│   │       │   ├── blueprint_handler.go  # POST /blueprint/compute
│   │       │   ├── signature_handler.go  # CRUD /signatures
│   │       │   ├── session_handler.go    # Session lifecycle endpoints
│   │       │   └── response.go           # Standardized JSON envelope
│   │       ├── middleware/
│   │       │   └── middleware.go         # RequestID, Logger, Recoverer
│   │       └── router/
│   │           └── router.go             # chi v5 route registration
│   ├── pkg/dsp/
│   │   ├── engine.go                 # DSP computation engine (pure math)
│   │   └── engine_test.go            # Psychoacoustic correctness tests
│   ├── Makefile
│   └── go.mod
│
└── frontend/                         # Flutter 3.22 (Web target)
    ├── lib/
    │   ├── main.dart                 # App entry, MultiBlocProvider wiring
    │   ├── core/
    │   │   ├── constants/
    │   │   │   ├── colors.dart       # Full cyberpunk color system
    │   │   │   └── dimensions.dart   # Spacing, radius, typography scale
    │   │   ├── theme/
    │   │   │   └── app_theme.dart    # MaterialApp ThemeData configuration
    │   │   └── router/
    │   │       └── home_screen.dart  # Root screen composition
    │   ├── features/
    │   │   ├── audio_engine/
    │   │   │   ├── bloc/
    │   │   │   │   ├── audio_engine_bloc.dart    # State machine
    │   │   │   │   ├── audio_engine_event.dart   # Sealed event hierarchy
    │   │   │   │   └── audio_engine_state.dart   # Immutable state
    │   │   │   ├── models/
    │   │   │   │   ├── neural_blueprint.dart     # DSP output model
    │   │   │   │   └── synthesis_parameters.dart # User slider state
    │   │   │   ├── services/
    │   │   │   │   ├── api_client.dart           # HTTP client
    │   │   │   │   └── web_audio_synthesizer.dart# Web Audio API bridge
    │   │   │   └── widgets/
    │   │   │       └── control_panel.dart        # All sliders + transport
    │   │   ├── visualizer/
    │   │   │   ├── painters/
    │   │   │   │   └── waveform_painter.dart     # CustomPainter
    │   │   │   └── widgets/
    │   │   │       └── waveform_visualizer.dart  # Animated container
    │   │   ├── presets/
    │   │   │   └── widgets/
    │   │   │       └── presets_panel.dart        # Factory + saved presets
    │   │   └── session_history/
    │   │       └── widgets/
    │   │           └── session_history_panel.dart
    │   └── shared/
    │       └── widgets/
    │           ├── neon_card.dart       # Base card, GlowingText, StatusBadge
    │           ├── neural_slider.dart   # Branded parameter slider
    │           └── brainwave_indicator.dart
    └── pubspec.yaml
```
 
---

## Brainwave Frequency Reference
 
| State   | Range     | Target Use Case                        | Entrainment Color |
|---------|-----------|----------------------------------------|-------------------|
| GAMMA   | 30–100 Hz | Peak cognitive performance, flow state | 🔴 Red            |
| BETA    | 13–30 Hz  | Active thinking, problem solving       | 🟠 Amber          |
| ALPHA   | 8–13 Hz   | Relaxed focus, creative inspiration    | 🔵 Cyan           |
| THETA   | 4–8 Hz    | Deep meditation, hypnagogic state      | 🟣 Violet         |
| DELTA   | 0.5–4 Hz  | Deep dreamless sleep, recovery         | 💙 Blue           |
 
---
 
## License
 
MIT © 2024 Mind-Sync Contributors

---

## Author

### KYRANAS RALLIS-PANAGIOTIS

- GitHub: [@Panagiotis2929](https://github.com/Panagiotis2929)

---
