# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a mobile-first Bluetooth device management app for solar tracker systems (TCU - Tracker Control Unit). The app connects to Bluetooth-enabled solar tracking devices and allows configuration of astronomical parameters, component settings, protection settings, and group control operations.

## Tech Stack

- Single HTML file (`index.html`) — no build system required
- Tailwind CSS via CDN (`https://cdn.tailwindcss.com`)
- Lucide icons via CDN (`https://unpkg.com/lucide@latest`)
- Vanilla JavaScript (no framework)

## Development

No build or test commands needed. Open `index.html` directly in a browser.

To simulate mobile view: Open browser DevTools → Toggle device toolbar → Select iPhone or similar mobile device.

## Architecture

The app uses a single-page view-based architecture with two main views:
1. **DeviceList** (`#view-list`) — Bluetooth device discovery and list
2. **DeviceLayout** (`#view-device`) — Individual device configuration

Navigation between views is handled by `goToList()` and `goToDevice(deviceName)`.

The DeviceLayout view contains four tabbed sections accessible via bottom navigation:
- **Info** (`#tab-info`) — Placeholder for device information
- **Settings** (`#tab-settings`) — Astronomical parameters, component parameters, protection parameters, east/west limit angles
- **Broadcast** (`#tab-broadcast`) — Placeholder for broadcast functionality
- **Group** (`#tab-group`) — 12-button control panel for collective operations (auto, flat, stop, west, east, clean, weather modes, low power)

Tab switching is handled by `switchTab(tabId)`.

## Key Data Flow

Device settings are organized into four parameter groups:
1. **Astronomical** — longitude, latitude, timezone
2. **Component** — width (m), spacing (m)
3. **Protection** — overcurrent (mA), night return angle, cleaning angle, wind angle, TCU version
4. **East/West Limits** — east limit angle, west limit angle

All settings have "Write and Broadcast" buttons that would send configuration to the device over Bluetooth.
