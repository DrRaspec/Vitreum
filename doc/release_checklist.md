# Release checklist

Use this checklist for every pub.dev release.

## Metadata

- Select the version according to Dart's semantic-versioning convention.
- Keep `pubspec.yaml`, `ios/vitreum.podspec`, Android build metadata, the README
  badge, installation snippet, and changelog release heading consistent.
- Confirm repository, homepage, issue tracker, documentation, license, topics,
  screenshot paths, supported SDKs, deployment targets, and plugin class names.
- Remove placeholders, private URLs, credentials, generated files, and local
  dependency overrides.

## Documentation and compatibility

- Document every new public type and configuration field.
- Record defaults, validation ranges, backend limitations, accessibility
  consequences, and migration behavior.
- Keep native iOS claims within the validated one-overlay topology.
- Check every README and guide link, image, command, and version reference.
- Review source compatibility for public field types and constructor defaults.

## Validation

Run from the package root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart doc --dry-run .
dart pub publish --dry-run
```

Also run the example tests and native builds on supported toolchains when the
release changes platform code. Native glass changes require physical-device or
simulator validation using the matrix in `native_composition_spike.md`.

Inspect the complete publish file list and archive size. The dry run should
have no warnings after the release changes are committed; a dirty-tree warning
is expected only while preparing an uncommitted release.

## Publish

- Commit the final release diff and confirm `git status` is clean.
- Run `dart pub publish --dry-run` once more from the clean commit.
- Publish with `dart pub publish`; do not use `--force` or
  `--skip-validation` to bypass unresolved findings.
- Verify the package page, README, screenshots, generated API documentation,
  example tab, platform tags, and install command on pub.dev.
- Create and push a matching Git tag and release notes after publication.
