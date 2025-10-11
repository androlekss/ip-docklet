# ip-docklet

An IP docklet for [Plank Reloaded](https://github.com/zquestz/plank-reloaded).
# Features
Lightweight Plank docklet for Linux desktop environments that displays your current public IP address directly on the dock.
Clicking the docklet copies the IP to clipboard.  
Includes optional WireGuard integration for quick VPN control.

# Dependencies

- vala  
- gtk+-3.0  
- plank-reloaded  
- glib-2.0  

#Installation

## Method 1: Build from source

Clone the repository
git clone https://github.com/androlekss/ip-docklet.git
cd ip-docklet

Build and install
meson setup --prefix=/usr build
meson compile -C build
sudo meson install -C build

# Setup
After installation, open the Plank Reloaded settings, navigate to "Docklets", and drag and drop IP Docklet onto your dock.

# Usage

- Displays your current public IP address on the dock  
- Click to copy IP to clipboard  
- Automatically refreshes when IP changes  
- If WireGuard is installed, click toggles VPN connection (wg-quick up/down)  
- Interface name defaults to wg0 (can be customized in source)

# What’s new in 0.1.0

- Initial release with IP display and clipboard support

# What’s new in 0.1.1

- Added WireGuard VPN control via docklet click

# License
This project is licensed under the GNU General Public License v3.0 (GPL-3.0). See the LICENSE file for details.

# Contributing
Contributions are welcome! Please feel free to submit a Pull Request.
