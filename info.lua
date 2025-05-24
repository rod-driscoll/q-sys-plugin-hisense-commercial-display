--[[
  20250306 v1.0 Rod Driscoll<rod@theavitgroup.com.au>
  Hisense BM Series TV IP protocol.

  This script communicates with the IP Control App on the Hisense BM/DM series TV, so make sure the APP is enabled
  This should work on the WR Interactive and M series, however inputs may not line up on both series.
  This protocol most likely won't work on the E series or the GM series
  https://www.hisense-b2b.com/Attachment/DownloadFile?downloadId=519
  https://www.hisense-b2b.com/Attachment/DownloadFile?downloadId=5

  Developer notes:
  ~ tested on a 100BM66D (BM Series) with firmware dated 01/02/24 (dd/mm/yy):
    ~ tested with LAN control only, serial control not tested; the documentation suggests it uses the same protocol.
    ~ 33 seconds from WoL to TCP socket connected
    ~ 10 seconds from connected to remote disconnect, so if polling > 10 secs it never requests status
    ~ Power, panel, source and volume control tested
    ~ Source select commands and responses don't align with documentation so will probably differ for each model
  ~ Checksum and length bytes returned from the display are not always correct
  ~ BM and DM series use the same base protocol with the TCP port and the byte format differing as follows:
    ~ BM series uses port 8088 and a full hex byte protocol   (e.g. 'PowerOff' = '\xDD\xFF\x00\x08\xC1\x15\x00\x00\x01\xAA\xAA\xDD\xBB\xCC
    ~ DM series uses port 8000 and a full ascii byte protocol (e.g. 'PowerOff' = 'DD FF 00 08 C1 15 00 00 01 AA AA DD BB CC'
  ~ DM series successfully queried device info such as MacAddress and other details
  ~ BM series does not recognise device info queries.
  ~ Volume ramping is not smooth because the display doesn't respond promptly and the plugin waits for a response before sending the next command

  Used Hisense Commercial Display plugin as a template.
]]

PluginInfo = {
  Name = "Hisense~BM/DM Series Display v1.0",
  Version = "1.0",
  BuildVersion = "1.0.0.0",
  Id = "Hisense BM/DM Series Display v1.0",
  Author = "Rod Driscoll<rod@theavitgroup.com.au>",
  Description = "Control and Status for Hisense BM/DM Series Displays.",
  Manufacturer = "Hisense",
  Model = "BM/DM Series",
  IsManaged = true,
  Type = Reflect and Reflect.Types.Display or 0,
}