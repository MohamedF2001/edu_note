# EduNote

EduNote is an offline-first Flutter app for teachers to organize schools, classes, students, assessments and results.

## Project status

The app now includes local teacher registration and login, a single teacher subject, a Drift v2 migration, school/class/student workflows, class-scoped evaluations and results, transactional grade entry, and school/class ownership checks. Existing 24+ unit and widget tests cover calculations, class isolation, subject selection/locking, and cross-school grade rejection.

The top-level Evaluations and Results navigation entries are still placeholders. The database retains `ClassSubjects` as a compatibility bridge for historical records; migration to a direct `Evaluation.classId` model, PDF/XLSX exports, encrypted backup/restore, and global data erasure remain unfinished.

See [docs/architecture.md](docs/architecture.md) for the data model, screen map, calculation rules, security approach and phased delivery plan.

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

The app targets a single local teacher profile and does not require a server. No sample school, student or grade records are seeded.
