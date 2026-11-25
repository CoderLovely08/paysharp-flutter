# Contributing

## Setup

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart pub publish --dry-run
```

## Commit format

Use focused commits in this format:

```text
[Type]: Concise imperative description
```

Common types include `Feature`, `Fix`, `Test`, `Docs`, `CI`, `Security`, `Refactor`, `Chore`, and `Release`.

Do not include merchant credentials, private base URLs, customer information, or production payment payloads. New PaySharp behavior must be based on current public documentation or sanitized sandbox evidence.
