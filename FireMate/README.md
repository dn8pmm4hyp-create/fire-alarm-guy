# 🧯 FireMate

A SwiftUI iOS companion app for fire alarm engineers — the serious sibling of the
[Fire Alarm Guy](../README.md) game that lives in this repo.

## Structure

```
FireMate/
├── App/            FireMateApp.swift, RootView.swift (tab navigation)
├── Theme/          Theme.swift (colours, spacing, card styles, shared inputs)
├── Assistant/      VoiceEngine (speech in/out), ButlerBrain (offline answers),
│                   CloudAssistant (Claude Messages API), AssistantView (chat UI)
├── Tools/          8 calculators + ToolsView hub:
│                   Standby Battery · Voltage Drop · Ohm's Law · Cable Resistance ·
│                   PSU Loading · Loop Loading · Sound Level · Detector Spacing
├── Forms/          FormModels (ServiceForm + JSON store), FormsView (list),
│                   ServiceFormEditor, FormPDFExporter (A4 PDF via ShareLink)
├── Reference/      ReferenceView (searchable BS 5839-1 quick-reference library)
└── Settings/       SettingsView (engineer profile, voice, API key in Keychain)
```

## Building

There is no `.xcodeproj` checked in — create one and drop the sources in:

1. Xcode → **File → New → Project → iOS App**, name it `FireMate`,
   interface **SwiftUI**, language **Swift** (iOS 17+ deployment target).
2. Delete the template `ContentView.swift` and `FireMateApp.swift`, then drag the
   `FireMate/` folders from this repo into the project navigator
   (check *Copy items if needed* off if you keep the repo checkout as the source).
3. Add these keys to the target's **Info** tab (for the voice assistant):
   - `NSMicrophoneUsageDescription` — "FireMate uses the microphone for voice questions."
   - `NSSpeechRecognitionUsageDescription` — "FireMate transcribes your voice questions."
4. Build & run.

## Cloud assistant

The Assistant tab answers common questions offline via `ButlerBrain`. Anything it
can't handle is sent to the Anthropic Messages API (`claude-opus-4-8`) by
`CloudAssistant` — paste an API key in **Settings** to enable it. The key is stored
in the device Keychain and never leaves the device except in requests to
`api.anthropic.com`.

## Disclaimer

Calculators and reference notes encode BS 5839-1 rules of thumb as engineering
aids. They are not a substitute for the published standard, manufacturer data or
professional judgement.
