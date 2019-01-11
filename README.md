# FHEM module to control Acer beamers via RS232
This module can control some Acer beamers which have an RS232 port included.

# Define
`define <Name> ACER_BEAMER_RS232 <Device>`  
ser2net is also supported.

Example:  
`define Beamer ACER_BEAMER_RS232 /dev/ttyUSB0`

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
  * Brightness
  * Contrast
  * Color temperature
  * RGB colors
  * Keystone
  * eKey
  * Language
  
# Sources
Visit [http://www.hifi-forum.de/viewthread-94-10979.html](http://www.hifi-forum.de/viewthread-94-10979.html) if you need more information about the used protocol.  
Module based on [75_LGTV_RS232.pm by markusbloch](https://svn.fhem.de/trac/browser/trunk/fhem/contrib/75_LGTV_RS232.pm).
