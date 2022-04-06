## [1.1.0]
### Fixed
- Fix gem dependency incompatibility between Fastlane and Highline. Require
  Fastlane less than 2.182 until Highline dependency is removed. [Andrew Havens]

### Changed
- Temporarily disable build_export_private_key when releasing gem. [Andrew Havens]
- Remove explicit dependency on highline gem. Fastlane >= 2.182 depends on a
  newer version of highline (one that supports Ruby 3.0). It was only ever used
  to fix a bug in Spaceship, but that bug has been fixed since Fastlane v2.75.0.
  [Andrew Havens]
- Add important note about how to install the distribution certificate. [Andrew
  Havens]
- Improve grammar in some log messages. [Andrew Havens]
- Fix typo in specifying developer_id_application. [Andrew Havens]
- Fix broken specs caused by hardcoded certificate fingerprint. [Andrew Havens]

## [1.0.4]
### Fixed
- Fix bug in forcing recreate certificate when valid certificates are already
  installed. [Andrew Havens]

### Changed
- Return SHA-1 fingerprint instead of common name to avoid problems with
  duplicate installed certificates with the same name. [Andrew Havens]

## [1.0.3]
### Changed
- Ensure export_private_key executable is compiled prior to gem release so that
  it can be included in the gem package. [Andrew Havens]
- Fix invalid gem specification due to incorrect file paths. [Andrew Havens]

## [1.0.2]
### Added
- Added bundler gem tasks for easier release workflow. [Andrew Havens]
- Added instructions for updating distribution certificates. [Petrik Heus]

### Changed
- Loosen fastlane version range to lock to major version 2 instead of minor
  version 113. [Andrew Havens]
- Don't enforce Bundler version as development dependency. [Andrew Havens]

## [1.0.1]
### Changed
- Fixed a case issue to account for new iPhone ID type. [Ben Govero]
- Updated fastlane and fixed related specs. [Ben Govero]
- Update free team requests to work with Fastlane 2. [Andrew Havens]
- Don't auto-select first team since it might not be the "free" team. [Andrew Havens]

## [1.0.0]
### Added
- Add a message to explain why sudo privileges are needed.
- Added more info on `recreate_certificate`.

### Changed
- Migrate to using latest version of Fastlane (which includes the latest
  version of Spaceship).
- require ‘highline’ gem for user inputs. [Watson]

## [0.0.7]
### Changed
- Update Spaceship version, now using '~> 0.38.0'.

## [0.0.6]
### Added
- The output directory can be configured via `MotionProvisioning.output_path`.

### Changed
- Update Spaceship version, now using '~> 0.37.0'.

## [0.0.3] - 2016-08-12
### Fixed
- Private keys are properly exported from the Keychain when downloading a
  certificate that's already installed int he local machine.
- Fixed compatibility with Ruby 2.0

[0.0.6]: https://github.com/HipByte/motion-provisioning/compare/0.0.5...0.0.6
[0.0.5]: https://github.com/HipByte/motion-provisioning/compare/0.0.4...0.0.5
[0.0.4]: https://github.com/HipByte/motion-provisioning/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/HipByte/motion-provisioning/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/HipByte/motion-provisioning/compare/0.0.1...0.0.2
