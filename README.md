
# q-sys-plugin-hisense-commercial-display

Plugin for Q-Sys environment to control a BM and DM series Hisense commercial display.

Language: Lua\
Platform: Q-Sys

Source code location: <https://github.com/rod-driscoll/q-sys-plugin-hisense-commercial-display>

![Control tab](https://github.com/rod-driscoll/q-sys-plugin-hisense-commercial-display/blob/master/content/control.png)\
![Setup tab](https://github.com/rod-driscoll/q-sys-plugin-hisense-commercial-display/blob/master/content/setup.png)\

## Deploying code

Copy the *.qplug file into "%USERPROFILE%\Documents\QSC\Q-Sys Designer\Plugins" then drag the plugin into a design.

## Developing code

Instructions and resources for Q-Sys plugin development is available at:

* <https://q-syshelp.qsc.com/DeveloperHelp/>
* <https://github.com/q-sys-community/q-sys-plugin-guide/tree/master>

Do not edit the *.qplug file directly, this is created using the compiler.
"plugin.lua" contains the main code.

### Development and testing

The files in "./DEV/" are for dev only and may not be the most current code, they were created from the main *.qplug file following these instructions for run-time debugging:\
[Debugging Run-time Code](https://q-syshelp.qsc.com/DeveloperHelp/#Getting_Started/Building_a_Plugin.htm?TocPath=Getting%2520Started%257C_____3)

## Features

Supports BM and DM models. Protocols differ between models so you need to select the model.
This plugin does not support models that require MQTT protocols.

* Power control
* Wake On LAN
  * Hisense documents a screen blank command but that doesn't work so you need to use the power commands which then requires WoL to power back on.
  * You need to enter the MAC for WoL to work. Some models/firmware versions support querying for mac address, but most don't.
* Source select
* Volume control
  * Ramping volume is not smooth because the displays don't respond promptly
* BM series uses port 8088 and a full hex byte protocol
* DM series uses port 8000 and a full ascii byte protocol

## Changelog

20250523 v1.0.0 Rod Driscoll<rod@theavitgroup.com.au>\
Initial version

## Authors

Original author: [Rod Driscoll](rod@theavitgroup.com.au)
Revision author: [Rod Driscoll](rod@theavitgroup.com.au)
