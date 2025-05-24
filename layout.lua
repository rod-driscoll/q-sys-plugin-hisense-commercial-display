local CurrentPage = pagenames[props["page_index"].Value]
local colors = {  
  Background  = {232,232,232},
  Transparent = {255,255,255,0},
  Text        = {24,24,24},
  Header      = {0,0,0},
  Button      = {48,32,40},
  Red         = {217,32,32},
  DarkRed     = {80,16,16},
  Green       = {32,217,32},
  OKGreen     = {48,144,48},
  Blue        = {32,32,233},
  Black       = {0,0,0},
  White       = {255,255,255},
  Gray        = {96,96,96}
}
if CurrentPage == "Setup" then
  -- User defines connection properties
  table.insert(graphics,{Type="GroupBox",Text="Connect",Fill=colors.Background,StrokeWidth=1,CornerRadius=4,HTextAlign="Left",Position={5,5},Size={400,135}})
  if props["Connection Type"].Value=="Ethernet" then 
    table.insert(graphics,{Type="Text",Text="IP Address",Position={15,35},Size={100,16},FontSize=14,HTextAlign="Right"})
    layout["IPAddress"] = {PrettyName="Settings~IP Address",Style="Text",Color=colors.White,Position={120,35},Size={99,16},FontSize=12}
    table.insert(graphics,{Type="Text",Text="Port",Position={15,60},Size={100,16},FontSize=14,HTextAlign="Right"})
    layout["Port"] = {PrettyName="Settings~Port",Style="Text",Color=colors.White,Position={120,60},Size={99,16},FontSize=12}
    table.insert(graphics,{Type="Text",Text="(BM series: 8088, DM series: 8000)",Position={221,60},Size={160,18},FontSize=10,HTextAlign="Left"})
    table.insert(graphics,{Type="Text",Text="MAC Address",Position={15,110},Size={100,16},FontSize=14,HTextAlign="Right"})
    layout["MACAddress"] = {PrettyName="Settings~MAC Address",Style="Text",Color=colors.White,Position={120,110},Size={99,16},FontSize=12}
  else
    table.insert(graphics,{Type="Text",Text="Reset Serial",Position={5,32},Size={110,16},FontSize=14,HTextAlign="Right"})
    layout["Reset"] = {PrettyName="Settings~Reset Serial", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={120,30}, Size={50,20} }
  end
  table.insert(graphics,{Type="Text",Text="Display ID",Position={15,85},Size={100,16},FontSize=14,HTextAlign="Right"})
  layout["DisplayID"] = {Type="Text",PrettyName="Settings~Display ID Number", Style="Text", FontColor=colors.Text, Position={120,85}, Size={99,16}, FontSize=12}

  -- Status fields updated upon connect show model/name/serial/sw rev
  table.insert(graphics,{Type="GroupBox",Text="Status",Fill=colors.Background,StrokeWidth=1,CornerRadius=4,HTextAlign="Left",Position={5,150},Size={400,205}})
  layout["Status"] = {PrettyName="Status~Connection Status", Position={40,180}, Size={330,32}, Padding=4 }
  table.insert(graphics,{Type="Text",Text="Device Name",Position={15,227},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["DeviceName"] = {PrettyName="Status~Device Name", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,226}, Size={255,16} }
  table.insert(graphics,{Type="Text",Text="Model Name",Position={15,250},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["ModelName"] = {PrettyName="Status~Model Name", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,249}, Size={255,16} }
  table.insert(graphics,{Type="Text",Text="Serial Number",Position={15,273},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["SerialNumber"] = {PrettyName="Status~Serial Number", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,272}, Size={255,16} }
  table.insert(graphics,{Type="Text",Text="Software Version",Position={15,296},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["DeviceFirmware"] = {PrettyName="Status~SW Version", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,295}, Size={255,16} }

  table.insert(graphics,{Type="Text",Text=PluginInfo.Manufacturer.." Commercial Display Plugin version "..PluginInfo.Version,Position={15,340},Size={380,14},FontSize=10,HTextAlign="Right", Color=colors.Gray})

  --Invisible Controls for pin access to data
  layout["ModelNumber"] = {PrettyName="Status~Model Family", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={1,1}, Size={1,1}, IsInvisible=true }
  layout["PanelType"] = {PrettyName="Status~Panel Type", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={1,1}, Size={1,1}, IsInvisible=true }

elseif CurrentPage == "Control" then
  -- Control interface for the monitor
  table.insert(graphics,{Type="GroupBox",Text="Control",Fill=colors.Background,StrokeWidth=1,CornerRadius=4,HTextAlign="Left",Position={5,5},Size={305,405}})
  -- Power
  table.insert(graphics,{Type="Header",Text="Power",Position={15,25},Size={285,14},FontSize=12,HTextAlign="Center",Color=colors.Header})
  table.insert(graphics,{Type="Text",Text="On",Position={12,40},Size={71,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  layout["PowerOn"] = {PrettyName="Power~On", Style="Button", Color=colors.Button, FontColor=colors.Hreen, FontSize=14, CornerRadius=2, Position={15,53}, Size={65,25} }
  table.insert(graphics,{Type="Text",Text="Off",Position={231,40},Size={71,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  layout["PowerOff"] = {PrettyName="Power~Off", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={234,53}, Size={65,25} }
  --table.insert(graphics,{Type="Text",Text="Status",Position={12,40},Size={71,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  layout["PowerStatus"] = {PrettyName="Power~Status", Style="LED", Color=colors.Blue, OffColor=colors.DarkRed, UnlinkOffColor=true, CornerRadius=6, Position={147,55}, Size={20,20} }
  --Panel
  table.insert(graphics,{Type="Header",Text="Panel",Position={15,90},Size={285,14},FontSize=12,HTextAlign="Center",Color=colors.Header})
  table.insert(graphics,{Type="Text",Text="On",Position={12,105},Size={71,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  layout["PanelOn"] = {PrettyName="Panel~On", Style="Button", Color=colors.Button, FontColor=colors.Hreen, FontSize=14, CornerRadius=2, Position={15,118}, Size={65,25} }
  table.insert(graphics,{Type="Text",Text="Off",Position={231,105},Size={71,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  layout["PanelOff"] = {PrettyName="Panel~Off", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={234,118}, Size={65,25} }
  --table.insert(graphics,{Type="Text",Text="Status",Position={12,105},Size={71,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  layout["PanelStatus"] = {PrettyName="Panel~Status", Style="LED", Color=colors.Blue, OffColor=colors.DarkRed, UnlinkOffColor=true, CornerRadius=6, Position={147,120}, Size={20,20} }
  -- Inputs
  table.insert(graphics,{Type="Header",Text="Input",Position={15,155},Size={285,14},FontSize=12,HTextAlign="Center",Color=colors.Header})
  table.insert(graphics,{Type="Text",Text="Current Input",Position={12,174},Size={75,20},FontSize=12,HTextAlign="Right", VTextAlign="Middle", Color=colors.Text})
  layout["Input"] = {PrettyName="Input~Current Input", Style="ComboBox", FontColor=colors.Black, FontSize=14, Position={88,174} , Size={211,20} }
  local i,j=0,0
  for val,input in pairs(AlternativeInputNames) do
    if (i+(j*4)) < InputCount then
      table.insert(graphics,{Type="Text",Text=input.Name,Position={12+(73*i),195+j*45},Size={71,22},FontSize=10,Color=colors.Text,HTextAlign="Center", VTextAlign="Bottom"})
      layout["InputButtons "..(j*4+1+i)] = {PrettyName="Input~"..input.Name, Style="Button", UnlinkOffColor=true, Color=colors.Blue, OffColor=colors.Button, FontColor=colors.White, FontSize=14, Position={15+(73*i), 215+j*45}, Size={65,25} }
      layout["InputStatus "..(j*4+1+i)] = {PrettyName="Input~Status "..input.Name, Style="LED", Color=colors.White, OffColor=colors.Transparent, UnlinkOffColor=true, StrokeWidth=0, Position={68+(73*i), 217+j*45}, Size={10,10}, ZOrder=-1000}
      i=i+1
      if(i>3)then 
        j=j+1
        i=0
      end
    end
  end

  table.insert(graphics,{Type="Header",Text="Volume",Position={15,297},Size={285,14},FontSize=12,HTextAlign="Center",Color=colors.Header})
  layout["VolumeDown"] = { PrettyName="Volume~Down", Style="Button", Color=colors.Button, IconColor=colors.White, Position={15,319}, Size={30,30} }
  layout["Volume"] = { PrettyName="Volume~Level", Style="Fader", Color=colors.Button, Position={50,317}, Size={140,35} }
  layout["VolumeUp"] = { PrettyName="Volume~Up", Style="Button", Color=colors.Button, IconColor=colors.White, Position={195,319}, Size={30,30} }
  table.insert(graphics,{Type="Text",Text="Mute",Position={224,308},Size={85,15},FontSize=10,Color=colors.Text,HTextAlign="Center", VTextAlign="Bottom"})
  layout["Mute"] = { PrettyName="Volume~Mute", Style="Button", Color=colors.Red, Position={234,322}, Size={65,25} }

  table.insert(graphics,{Type="Text",Text=PluginInfo.Manufacturer.." Commercial Display Plugin version "..PluginInfo.Version,Position={15,397},Size={285,14},FontSize=10,HTextAlign="Right", Color=colors.Gray})
end