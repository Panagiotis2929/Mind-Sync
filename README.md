# Mind-Sync: Neural Audio Architect

<img width="1912" height="700" alt="image" src="https://github.com/user-attachments/assets/c8fb1eb6-fd1d-47b0-abd5-5108685ed18d" />

<img width="1912" height="700" alt="image" src="https://github.com/user-attachments/assets/f4e44905-66c3-427a-ba49-f65196dc7e9f" />

<img width="1912" height="700" alt="image" src="https://github.com/user-attachments/assets/4c78876e-e5df-4029-99c8-9bdfb508a8ea" />

Mind-Sync is an application that uses mathematics to generate sounds that assist in concentration, relaxation, or sleep, leveraging Binaural Beat Entrainment technology.
Instead of playing pre-recorded files, the application "synthesizes" the sound the moment you listen to it, calculating frequencies and waveforms in real-time.

---

# Local Execution Instructions

For the application to function and for the DSP ONLINE indicator to appear, the simultaneous execution of both the backend and frontend is required.

## 1. Backend
Open a terminal, navigate to the backend folder, and start the server:

```bash
cd backend
go run cmd/server/main.go
```
## 2. frontend 
Open a second terminal, navigate to the frontend folder, and run the application in the browser:

```bash
cd frontend
flutter run -d chrome
```
The application will automatically connect to the local server once the frontend startup is complete.

---

### What makes the application stand out?
* **Zero File I/O:** No audio files are used. Everything is generated from mathematical formulas.
* **DSP Engine:** Sound is created in the browser via the Web Audio API.
* **Responsive UI:** Built with Flutter Web, featuring a cyberpunk aesthetic.
* **Offline-First:** Works autonomously, without cloud dependencies.

### Technologies Used
* **Frontend:** Flutter Web (Dart)

* **Backend:** Go (Golang)

* **Database:** SQLite (for storing user preferences)

* **Audio:** Web Audio API (PCM synthesis)
---

### Debugging
During the execution of the application in the browser, the following error will appear in the console, which is due to the way Dart communicates with JavaScript:
```text
Failed to start audio: TypeError: Instance of 'NativeFloat32List': 
type 'NativeFloat32List' is not a subtype of type 'JsObject'
```
<img width="1912" height="600" alt="image" src="https://github.com/user-attachments/assets/420cdc26-f83c-4b47-a9bf-2fff13954ffc" />

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
│   │   └── engine_test.go           
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
