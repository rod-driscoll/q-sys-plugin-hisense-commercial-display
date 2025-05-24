-- Configuration Controls --
table.insert(ctrls, {
  Name         = "IPAddress",
  ControlType  = "Text",
  Count        = 1,
  DefaultValue = "Enter an IP Address",
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "Port",
  ControlType  = "Text",
  ControlUnit  = "Integer",
  DefaultValue = "8000",
  Min          = 0,
  Max          = 65535,
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "DisplayID",
  ControlType  = "Knob",
  ControlUnit  = "Integer",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both",
  DefaultValue = 1,
  Min          = 0,
  Max          = 253
})
table.insert(ctrls, {
  Name         = "Broadcast",
  ControlType  = "Button",
  ButtonType   = "Toggle",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "Reset",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})

-- Status Controls --
table.insert(ctrls, {
  Name          = "Status",
  ControlType   = "Indicator",
  IndicatorType = Reflect and "StatusGP" or "Status",
  PinStyle      = "Output",
  UserPin       = true,
  Count         = 1
})
table.insert(ctrls, {
  Name         = "ModelNumber",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "PanelType",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "ModelName",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "DeviceName",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "SerialNumber",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "DeviceFirmware",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "MACAddress",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1,
  DefaultValue = ""
})

-- Power Controls --
table.insert(ctrls, {
  Name          = "PowerStatus",
  ControlType   = "Indicator",
  IndicatorType = "Led",
  Count         = 1,
  UserPin       = true,
  PinStyle      = "Output"
})
table.insert(ctrls, {
  Name          = "StandbyStatus",
  ControlType   = "Indicator",
  IndicatorType = "Led",
  Count         = 1,
  UserPin       = true,
  PinStyle      = "Output"
})
table.insert(ctrls, {
  Name         = "Power",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input",
  Icon         = "Power"
})
table.insert(ctrls, {
  Name         = "PowerOn",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})
table.insert(ctrls, {
  Name         = "PowerOff",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})
table.insert(ctrls, {
  Name         = "Reboot",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})

-- Panel Controls --
table.insert(ctrls, {
  Name          = "PanelStatus",
  ControlType   = "Indicator",
  IndicatorType = "Led",
  Count         = 1,
  UserPin       = true,
  PinStyle      = "Output"
})
table.insert(ctrls, {
  Name         = "Panel",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input",
  Icon         = "Power"
})
table.insert(ctrls, {
  Name         = "PanelOn",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})
table.insert(ctrls, {
  Name         = "PanelOff",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})

-- Input Controls --
table.insert(ctrls, {
  Name         = "Input",
  ControlType  = "Text",
  Style        = "ComboBox",
  PinStyle     = "Both",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "InputButtons",
  ControlType  = "Button",
  ButtonType   = "Momentary",
  Count        = InputCount,
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name          = "InputStatus",
  ControlType   = "Indicator",
  IndicatorType = "Led",
  Count         = InputCount
})
table.insert(ctrls, {
  Name         = "InputNext",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})

-- Sound Controls --
table.insert(ctrls, {
  Name         = "Volume",
  ControlType  = "Knob",
  ControlUnit  = "Integer",
  DefaultValue = 0,
  Min          = 0,
  Max          = 100,
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "VolumeUp",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input",
  Icon         = "Plus"
})
table.insert(ctrls, {
  Name         = "VolumeDown",
  ControlType  = "Button",
  ButtonType   = "Trigger",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input",
  Icon         = "Minus"
})
table.insert(ctrls, {
  Name         = "Mute",
  ControlType  = "Button",
  ButtonType   = "Toggle",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})