# Contributing

Run `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test`,
`dart doc --dry-run .`, and `dart pub publish --dry-run` before submitting a
release change. Inspect the publish file list and resolve every warning except
the expected dirty-tree warning while preparing an uncommitted release. Do not
add private Apple APIs, copied shaders, or experimental glass package
dependencies.

For a publication, follow the complete
[release checklist](doc/release_checklist.md).

Native-backend changes must include the tested iOS/Xcode versions and update the
composition checklist. Performance claims must include device, OS, Flutter
version, renderer, surface count/sizes, and average/worst build and raster time.
