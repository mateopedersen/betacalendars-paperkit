# Contributing

Please open an issue before a substantial API change. Keep calendar arithmetic in the deterministic core model, add or regenerate fixtures for behavior changes, and run `swift test` plus the reference/tracking audit before submitting a pull request.

The core package has no network behavior or runtime third-party dependencies. Do not add `prepare_command` to the podspec. Changes to public APIs should include DocC updates and a changelog entry.
