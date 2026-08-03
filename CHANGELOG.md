# Changelog

All notable changes to HEOS Menu Bar will be documented in this file.

## [Unreleased]

### Fixed

- Open Settings with `SettingsLink` on modern macOS versions.
- Allow entering a HEOS IP address directly from the disconnected menu.
- Stop stalled TCP connection attempts after eight seconds with an actionable error.
- Resolve the Bonjour host but connect to the HEOS CLI on port 1255 instead of the advertised communications port.

## [0.1.0] - 2026-08-03

### Added

- Native macOS menu bar interface and settings window.
- HEOS TCP client with streaming JSON response parsing.
- Automatic Bonjour discovery and manual host configuration.
- Player discovery, volume control, and mute control.
- Live HEOS change events and automatic reconnect.
- Swift Package structure, protocol tests, and project documentation.
