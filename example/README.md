# sunmi_cloud_printer_example

Demonstrates scanning, connecting, plain-text printing, and Arabic-safe image
printing with the `sunmi_external_cloud_printer` plugin.

## Included flows

- `Print Test` sends a normal text receipt through `appendText()`.
- `Print Arabic` renders an Arabic receipt to a PNG in Flutter and prints it
	through `appendImage()`. Use this path when the printer firmware does not
	shape Arabic text correctly.

## Getting started

1. Connect a supported Sunmi printer.
2. Tap `Scan`.
3. Tap a discovered printer to connect.
4. Use `Print Test` or `Print Arabic`.
