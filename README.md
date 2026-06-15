# Speeding Bullet

A minimal, fast internet speed monitor widget for KDE Plasma 6. It sits in your panel and displays real-time download and upload speeds using the clean, bundled Inter font.

## Screenshots

<img width="119" height="44" alt="kwinshot_20260613_122406" src="https://github.com/user-attachments/assets/4e061a21-7064-49e8-b2d5-c10488b68973" /> <img width="149" height="85" alt="image" src="https://github.com/user-attachments/assets/427198e8-d1e3-42c9-b5c4-1f980c28197d" />


## Features

- **Accurate Real-Time Speeds**: Reads directly from `/proc/net/dev` for zero-overhead, precise byte-matching calculations.
- **Auto Interface Detection**: Automatically ignores loopback (`lo`), docker networks (`docker0`), virtual bridges (`virbr`), and VPN tunnels, locking onto your actual active network interface seamlessly.
- **Theme Aware**: Perfectly matches your current Plasma text colors (with positive green arrows).
- **Customizable**: Easy-to-use settings page to scale the font size up or down to match your panel height perfectly.
- **Plasma 6 Native**: Built specifically for Plasma 6, KF6, and Qt6 environments (supports both Wayland and X11).

## Requirements

- **Operating System**: Linux
- **Desktop Environment**: KDE Plasma 6+
- **Frameworks**: KDE Frameworks 6+

## Installation

1. Open your terminal and navigate to this folder.
2. Run the included install script:
   ```bash
   bash install.sh install
   ```
3. Restart your Plasma shell to load the new widget cleanly:
   ```bash
   systemctl --user restart plasma-plasmashell.service
   ```
   *(Note: This is safe to run on Wayland and will not close your open apps).*
4. Right-click your Plasma panel, select **Add Widgets**, search for **Speeding Bullet**, and drag it to your panel.

## Configuration

You can customize the widget after adding it to your panel:
1. Right-click the Speeding Bullet widget on your panel.
2. Select **Configure Speeding Bullet...**
3. Use the **Text Size** slider to scale the widget perfectly for your specific panel thickness.

## Troubleshooting / Development

If you are modifying the QML code, you can test it safely in a window without touching your panel:
```bash
plasmawindowed com.github.dip.speedingbullet
```

To sync changes made to the source files directly into your system folder:
```bash
bash install.sh reload
```
