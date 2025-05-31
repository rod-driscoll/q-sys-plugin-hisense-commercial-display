local InputCount = 7
local InputTypes = {
  --[[ Attempted to create a default selection.
    At run time replace entries with different values if they conflict
    Due to a complete in-consistency in the protocols there is no guarantee
      the inputs will be correct on a device prior to physical testing]]
  {Name="Menu"        , Tx='\x00', Rx={ '\x05\x03\x00' } },
  {Name="PC"          , Tx='\x0C', Rx={ '\x05\x03\x01', '\x05\x00' } },
  {Name="DVI"         , Tx='\x09', Rx={  } },
  {Name="Display Port", Tx='\x16', Rx={ '\x05\x03\x02', '\x05\x03' } },
  {Name="HDMI 1"      , Tx='\x0E', Rx={ '\x05\x03\x04', '\x05\x07', '\x0E' } },
  {Name="HDMI 2"      , Tx='\x0F', Rx={ '\x05\x03\x03', '\x05\x06', '\x0F' } },
  {Name="VGA"         , Tx='\x17', Rx={ '\x06\x04\x00', '\x08\x01' } },
  {Name="HDMI Front"  , Tx='\x05', Rx={                 '\x05\x05', '\x17' } }, -- 2 word Rx is repeat of DVI
  {Name="HDMI Side"   , Tx='\x06', Rx={                 '\x05\x04' } },
  {Name="Type-C"      , Tx='\x0B', Rx={                 '\x05\x09', '\x0C' } },
  {Name="HDMI"        , Tx='\x08', Rx={  } },
  {Name="OPS"         , Tx='\x04', Rx={  } },
  {Name="USB"         , Tx='\x0C', Rx={  } },
  {Name="Home"        , Tx='\x14', Rx={  } },
  {Name="CMS"         , Tx='\x15', Rx={  } },
  {Name="PDF"         , Tx='\x17', Rx={  } }, -- Tx is repeat of VGA
  {Name="Custom"      , Tx='\x18', Rx={  } },
}