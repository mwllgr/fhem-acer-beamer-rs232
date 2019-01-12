# FHEM module to control Acer beamers via RS232
This module can control some Acer beamers which have an RS232 port included.  
Just connect a USB-to-RS232 serial converter to your FHEM server. More information about the pinout below.

# Usage
Just copy the file `FHEM/70_AcerBeamer_RS232.pm` into the `FHEM/` folder of your FHEM installation.  
Example path: `/opt/fhem/FHEM/70_AcerBeamer_RS232.pm`

## Define
`define <Name> AcerBeamer_RS232 <Device>`  
ser2net is also supported.

Example:  
`define Beamer AcerBeamer_RS232 /dev/ttyUSB0`

# Available commands
* Power
  * On (does not work on all beamers)
  * Off
* Source
  * Auto
  * Resync
  * D-Sub
  * HDMI
  * Composite
  * S-Video
* Remote control
  * Menu
  * Volume +
  * Volume -
  * Mute
  * Freeze
  * Video mute/hide
  * Zoom
  * Up
  * Down
  * Left
  * Right
* Quick settings
  * 16:9 / 4:3
  * Brightness
  * Contrast
  * Color temperature
  * RGB colors
  * Keystone
  * eKey
  * Language

# Pinout
![Pinout](http://bilder.hifi-forum.de/medium/226620/pinbelegung_195544.jpg)  
Source: hifi-forum.de / Acer Support
 
# Information sources
Visit [http://www.hifi-forum.de/viewthread-94-10979.html](http://www.hifi-forum.de/viewthread-94-10979.html) if you need more information about the used protocol.  
Module based on [75_LGTV_RS232.pm by markusbloch](https://svn.fhem.de/trac/browser/trunk/fhem/contrib/75_LGTV_RS232.pm).
