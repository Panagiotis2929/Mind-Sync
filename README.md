# Mind-Sync: Neural Audio Architect

<img width="1912" height="907" alt="image" src="https://github.com/user-attachments/assets/c8fb1eb6-fd1d-47b0-abd5-5108685ed18d" />

<img width="1912" height="907" alt="image" src="https://github.com/user-attachments/assets/f4e44905-66c3-427a-ba49-f65196dc7e9f" />

<img width="1912" height="907" alt="image" src="https://github.com/user-attachments/assets/4c78876e-e5df-4029-99c8-9bdfb508a8ea" />

Το Mind-Sync είναι μια εφαρμογή που χρησιμοποιεί μαθηματικά για να παράγει ήχους που βοηθούν στη συγκέντρωση, τη χαλάρωση ή τον ύπνο, αξιοποιώντας την τεχνολογία του **Binaural Beat Entrainment**. 
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
├── backend/                         
│   ├── cmd/
│   │   └── server/
│   │       └── main.go               
│   ├── internal/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── neural_blueprint.go  
│   │   │   │   ├── neural_signature.go   
│   │   │   │   └── errors.go            
│   │   │   └── repositories/
│   │   │       └── interfaces.go        
│   │   ├── application/
│   │   │   ├── dtos/
│   │   │   │   ├── blueprint_dto.go     
│   │   │   │   └── signature_dto.go
│   │   │   └── usecases/
│   │   │       ├── compute_blueprint.go  
│   │   │       ├── manage_signatures.go  
│   │   │       └── track_sessions.go    
│   │   ├── infrastructure/
│   │   │   ├── persistence/
│   │   │   │   ├── sqlite_db.go          
│   │   │   │   ├── signature_repo.go     
│   │   │   │   └── session_repo.go      
│   │   │   └── logger/
│   │   │       └── logger.go            
│   │   └── interfaces/http/
│   │       ├── handlers/
│   │       │   ├── blueprint_handler.go  
│   │       │   ├── signature_handler.go  
│   │       │   ├── session_handler.go    
│   │       │   └── response.go           
│   │       ├── middleware/
│   │       │   └── middleware.go         
│   │       └── router/
│   │           └── router.go            
│   ├── pkg/dsp/
│   │   ├── engine.go                
│   │   └── engine_test.go           s
│   ├── Makefile
│   └── go.mod
│
└── frontend/                        
    ├── lib/
    │   ├── main.dart               
    │   ├── core/
    │   │   ├── constants/
    │   │   │   ├── colors.dart       
    │   │   │   └── dimensions.dart   
    │   │   ├── theme/
    │   │   │   └── app_theme.dart   
    │   │   └── router/
    │   │       └── home_screen.dart  
    │   ├── features/
    │   │   ├── audio_engine/
    │   │   │   ├── bloc/
    │   │   │   │   ├── audio_engine_bloc.dart   
    │   │   │   │   ├── audio_engine_event.dart  
    │   │   │   │   └── audio_engine_state.dart   
    │   │   │   ├── models/
    │   │   │   │   ├── neural_blueprint.dart     
    │   │   │   │   └── synthesis_parameters.dart 
    │   │   │   ├── services/
    │   │   │   │   ├── api_client.dart          
    │   │   │   │   └── web_audio_synthesizer.dart
    │   │   │   └── widgets/
    │   │   │       └── control_panel.dart       
    │   │   ├── visualizer/
    │   │   │   ├── painters/
    │   │   │   │   └── waveform_painter.dart     
    │   │   │   └── widgets/
    │   │   │       └── waveform_visualizer.dart 
    │   │   ├── presets/
    │   │   │   └── widgets/
    │   │   │       └── presets_panel.dart      
    │   │   └── session_history/
    │   │       └── widgets/
    │   │           └── session_history_panel.dart
    │   └── shared/
    │       └── widgets/
    │           ├── neon_card.dart      
    │           ├── neural_slider.dart  
    │           └── brainwave_indicator.dart
    └── pubspec.yaml
```
 
---

## Brainwave Frequency Reference
 
| State   | Range     | Target Use Case                        | Entrainment Color |
|---------|-----------|----------------------------------------|-------------------|
| GAMMA   | 30–100 Hz | Peak cognitive performance, flow state |    Red            |
| BETA    | 13–30 Hz  | Active thinking, problem solving       |    Amber          |
| ALPHA   | 8–13 Hz   | Relaxed focus, creative inspiration    |    Cyan           |
| THETA   | 4–8 Hz    | Deep meditation, hypnagogic state      |    Violet         |
| DELTA   | 0.5–4 Hz  | Deep dreamless sleep, recovery         |    Blue           |

---
 
## License
 
MIT © 2024 Mind-Sync Contributors

---

## Author

### KYRANAS RALLIS-PANAGIOTIS

- GitHub: [@Panagiotis2929](https://github.com/Panagiotis2929)

---
