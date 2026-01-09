fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run all tests

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app for release

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Submit a new build to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Prepare release (bump version)

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Sync code signing certificates and profiles

### ios add_device

```sh
[bundle exec] fastlane ios add_device
```

Add a new test device

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
