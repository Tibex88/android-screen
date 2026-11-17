# Android Screen for Mac

A small macOS launcher for [scrcpy](https://github.com/Genymobile/scrcpy). Mirror and control an Android phone over USB, trusted local Wi-Fi, or Tailscale.

## Install

Install [Homebrew](https://brew.sh), then run:

```sh
brew install scrcpy
brew install --cask android-platform-tools
```

Download or clone this repository. Make the launcher executable if needed:

```sh
chmod +x "Android Screen.command"
```

Enable **Developer options → USB debugging** on Android. Connect by USB, unlock the phone, and approve the Mac. Double-click **Android Screen.command** in Finder. You may copy the launcher to your Desktop; settings remain on your Mac independently of the script location.

## Menu

| Option | Action |
| --- | --- |
| 1 | Mirror over USB |
| 2 | Enable wireless ADB on port 5555 through USB |
| 3 | Mirror over Tailscale or trusted local Wi-Fi |
| 4 | Disable wireless ADB and return to USB debugging |
| 5 | List connected phones |
| 6 | Set or change the saved phone address |

USB usually provides the most responsive experience. Video is limited to a 1280-pixel longest edge, 30 fps, and 3 Mbps. Mouse and keyboard use UHID physical input simulation. Click inside the window to control the phone; press **left Option (⌥)** to release the mouse back to the Mac.

## Tailscale setup

1. Install and connect Tailscale on both devices using the same tailnet.
2. Connect the phone by USB and choose **2**.
3. Choose **3** and enter the phone’s Tailscale IP or hostname. The default port is 5555.
4. Once connected, unplug USB.

After restarting the phone or disabling wireless ADB, reconnect USB and choose **2** again. A saved address does not keep wireless debugging enabled across restarts.

ADB on port 5555 may also be reachable on the phone’s local network. Use trusted networks, avoid exposing it to the internet, and choose **4** when finished. Tailscale access rules must allow the Mac to reach the phone.

## Local settings and privacy

The first wireless connection asks for the phone address and stores it only on the current Mac:

```text
~/Library/Application Support/Android Screen/phone-address
```

The file has owner-only read/write permissions. It is plain text, not a password vault. The launcher reads it as data and does not execute it. No personal phone address is included in this repository.

Use option **6** to change the saved address. Delete the file to reset setup. Moving or updating the launcher does not erase this setting.

## Terminal usage

```sh
./"Android Screen.command" --help
./"Android Screen.command" usb
./"Android Screen.command" prepare
./"Android Screen.command" remote
./"Android Screen.command" configure
./"Android Screen.command" remote phone.example:5555
```

An explicit connection address is a temporary override; `configure` saves a new default. IPv4 addresses and hostnames are supported; IPv6 literals are not.

## Troubleshooting

- **Connection refused:** connect USB, choose **2**, then **3**. Check Tailscale and the saved address using **6**.
- **Unauthorized:** unlock the phone and accept its USB debugging prompt.
- **Multiple USB phones:** leave only the intended phone connected.
- **Mouse captured:** press left Option (⌥).
- **Sluggish wireless screen:** try USB with option **1**.
- **UHID unavailable:** the device must support UHID. See the scrcpy [mouse](https://github.com/Genymobile/scrcpy/blob/master/doc/mouse.md) and [keyboard](https://github.com/Genymobile/scrcpy/blob/master/doc/keyboard.md) documentation for other input modes.

This launcher depends on scrcpy and Android platform tools; it does not bundle them. It is an independent convenience script.
