local InputCount = 7
local InputTypes = { -- Response from poll
  {Name="Menu"        , Value='\x05\x00'}, -- TODO: confirm on TV
  {Name="PC"          , Value='\x05\x01'},
  {Name="DVI"         , Value='\x05\x02'},
  {Name="Display Port", Value='\x05\x03'},
  {Name="HDMI 1"      , Value='\x05\x04'},
  {Name="HDMI 2"      , Value='\x05\x05'},
  {Name="VGA"         , Value='\x08\x01'},
}

local AlternativeInputNames = { -- documented (badly)
  {Name="DVI"         , Value='\x09', ButtonIndex=3},
  {Name="PC"          , Value='\x0c', ButtonIndex=2},
  {Name="HDMI 1"      , Value='\x0e', ButtonIndex=5},
  {Name="HDMI 2"      , Value='\x0f', ButtonIndex=6},
  {Name="Display Port", Value='\x16', ButtonIndex=4},
  {Name="VGA"         , Value='\x17', ButtonIndex=7},
}

function GetInputIndex(val)
  if DebugFunction then PrintByteString(val, 'GetInputIndex(): ') end
  for i,input in ipairs(InputTypes) do
    if(input.Value == val)then
      if DebugFunction then print('GetInputIndex('..i..') InputTypes: '..input.Name) end
      for j,k in ipairs(AlternativeInputNames) do
        if(k.Name == input.Name)then
          if DebugFunction then print('GetInputIndex('..j..') AlternativeInputNames: '..input.Name) end
          return j, input.Name
        end
      end
      return i, input.Name
    end
  end
end

