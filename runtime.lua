--[[
	Hisensese Commercial Display Runtime

	2 Connectivity types;  Direct Serial Connection and Ethernet
	Both use the same commands
	Based on user set Property "Connection Type"  the communication engine and send and receive functions will be defined to use one or the other.

	The command parsing, processsing, and input handlers will call the same functions so Send needs to have the same inputs in both builds.
]]

-- Control aliases
  Status = Controls.Status
  
  local DebugTx = true
  local DebugRx = false
  local DebugFunction = true
  DebugPrint = Properties["Debug Print"].Value
  DisplaySeries = Properties["Display Series"].Value
   
  -- Timers, tables, and constants
  StatusState = { OK = 0, COMPROMISED = 1, FAULT = 2, NOTPRESENT = 3, MISSING = 4, INITIALIZING = 5 }
  Heartbeat = Timer.New()
  PowerupTimer = Timer.New()
  VolumeDebounce = Timer.New()
  VolumRampTimer = Timer.New()
  StartupTimer = Timer.New()

  PowerupCount = 0
  PollRate = Properties["Poll Interval"].Value
  Timeout = PollRate + 10
  BufferLength = 1024
  ConnectionType = Properties["Connection Type"].Value
  DataBuffer = ""
  CommandQueue = {}
  CommandProcessing = false
  --Internal command timeout
  CommandTimeout = 5
  CommunicationTimer = Timer.New()
  PowerOnDebounceTime = 20
  PowerOnDebounce = false
  TimeoutCount = 0
  ActiveInput = 1
  for i=1,#Controls['InputButtons'] do
  	if Controls['InputButtons'][i].Boolean then
  		ActiveInput = i
  	end
  end
  
  InputCount = 0
  for i,_ in ipairs(InputTypes) do InputCount = i end 
  local choices = {}
  for _,v in ipairs(AlternativeInputNames) do table.insert(choices, v.Name) end 
	Controls["Input"].Choices = choices

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
  
  --[[
  	Request Command Set
  	Named reference to each of the command objects used here in
  	Note commands are in decimal here, translation to hex is done in Send()
  ]]
  local Request = {
  	Status      ={Command=0x28,Data=''},           -- DD FF 00 06 C1 28 00 00 01 EE BB CC
  	MACAddress  ={Command=0x6C,Data=''},           -- DD FF 00 06 C1 6C 00 00 01 AA BB CC
  	SWVersion   ={Command=0x1B,Data=''},           -- DD FF 00 06 C1 1B 00 00 01 DD BB CC 
  	SerialNumber={Command=0xFF,Data='',Data2=0x0B},-- DD FF 00 06 C1 FF 00 0B 01 32 BB CC 
  	DeviceName  ={Command=0xFF,Data='',Data2=0x0D},-- DD FF 00 06 C1 FF 00 0D 01 34 BB CC -- 32 bytes device ID
  	ModelName   ={Command=0xFE,Data='',Data2=0x02},-- DD FF 00 06 C1 FE 00 02 64 5F BB CC
  	ModelNumber ={Command=0xFE,Data='',Data2=0x01},-- DD FF 00 06 C1 FE 00 01 64 5C BB CC -- brand. ex: Hisensese (ASCII)
  
  	PowerOn     ={Command=0x15,Data='\xBB\xBB'},   -- DD FF 00 08 C1 15 00 00 01 BB BB DD BB CC
  	PowerOff    ={Command=0x15,Data='\xAA\xAA'},   -- DD FF 00 08 C1 15 00 00 01 AA AA DD BB CC
  
  	PanelStatus ={Command=0x10,Data=''},           -- DD FF 00 06 C1 10 00 00 01 D6 BB CC
  	PanelOn     ={Command=0x31,Data='\x01'},       -- DD FF 00 07 C1 31 00 00 01 01 F7 BB CC
  	PanelOff    ={Command=0x31,Data='\x00'},       -- DD FF 00 07 C1 31 00 00 01 00 F6 BB CC
  
  	InputStatus ={Command=0x1A,Data=''},           -- DD FF 00 06 C1 1A 00 00 01 DC BB CC
  	InputSet    ={Command=0x08,Data='\x0E'},       -- DD FF 00 07 C1 08 00 00 01 08 C7 BB CC  (08 HDMI, 09 DVI, 0C PC, 0E HDMI1, 0F HDMI2, 16 DP, 17 VGA)
  
  	VolumeStatus={Command=0x7D,Data=''},           -- DD FF 00 06 C1 7D 00 00 64 DE BB CC
  	VolumeSet   ={Command=0x27,Data='\x01'},       -- DD FF 00 07 C1 27 00 00 01 01 E1 BB CC (volume 0-100 is 10th byte)
  	MuteOn      ={Command=0x26,Data='\x01'},       -- DD FF 00 07 C1 26 00 00 01 01 E0 BB CC 
  	MuteOff     ={Command=0x26,Data='\x00'},       -- DD FF 00 07 C1 26 00 00 01 00 E1 BB CC
  }
    
  -- create a table of items that require querying on connect
  local PropertiesToGet = { "Status", "InputStatus", "PanelStatus", "MACAddress", "SWVersion", "SerialNumber", "DeviceName", "ModelName", "ModelNumber" }
  local StatusToGet = { "Status", "InputStatus", "PanelStatus" } -- , "VolumeStatus" } -- no VolumeStatus

  -- create a queue of commands, these commands will be iteratively called after connection when the regular command queue is empty
  local PollQueueCurrent = {}
  local function LoadPollQueue(items) -- need to copy items by value instead of reference
  	if DebugFunction then print("LoadPollQueue(#"..(items and #items or 'nil')..")") end
    local queue = {}
    for k,v in pairs(items) do table.insert(queue, v) end
    return queue
  end 

  -- Helper functions
  -- A function to determine common print statement scenarios for troubleshooting
  function SetupDebugPrint()
  	if DebugPrint=="Tx/Rx" then
  		DebugTx,DebugRx=true,true
  	elseif DebugPrint=="Tx" then
  		DebugTx=true
  	elseif DebugPrint=="Rx" then
  		DebugRx=true
  	elseif DebugPrint=="Function Calls" then
  		DebugFunction=true
  	elseif DebugPrint=="All" then
  		DebugTx,DebugRx,DebugFunction=true,true,true
  	end
  end
  
  -- A function to clear controls/flags/variables and clears tables
  function ClearVariables()
  	if DebugFunction then print("ClearVariables() Called") end
  	DataBuffer = ""
  	CommandQueue = {}
  end
  
  --Reset any of the "Unavailable" data;  Will cause a momentary colision that will resolve itself the customer names the device "Unavailable"
  function ClearUnavailableData()
  	if DebugFunction then print("ClearUnavailableData() Called") end
  end
  
  -- Update the Status control
  function ReportStatus(state,msg)
  	if DebugFunction then print("ReportStatus() Called: "..state.." - "..msg) end
  	--Dont report status changes immediately after power on
  	if PowerOnDebounce == false then
  		local msg=msg or ""
  		Status.Value=StatusState[state]
  		Status.String=msg
  		--Show the power off state if we can't communicate
  		if(state ~= "OK")then
  			Controls["PowerStatus"].Value = 0
  			Controls["PanelStatus"].Boolean = false
  		end
  	end
  end
  
  -- Interface will receive a lot of strings of hex bytes; Printing decimal values for easier debug
  function PrintByteString(ByteString, header, allHex)
  	--if DebugFunction then print("PrintByteString() Called") end
  	local result=header or ""
  	if(ByteString:len()>0)then
  		for i=1,ByteString:len() do
      --[[
        result = result..string.format("\\x%02X",ByteString:byte(i))
        ]]
        if allHex or not (ByteString:byte(i) >= 32 and ByteString:byte(i) <= 126) then
          result = result..string.format("\\x%02X",ByteString:byte(i))
        else
          result = result .. string.char(ByteString:byte(i))
  		  end
  	  end
    end
  	print( result )
  end
  
  -- Arrays of bytes may get used often; Printing decimal values for easier debug
  function PrintByteArray(ByteArray, header)
  	if DebugFunction then print("PrintByteArray() Called") end
  	local result=header or ""
  	if(#ByteArray>0)then
  		for i=1,#ByteArray do
  			result = result .. ByteArray[i] .. " "
  		end
  	end
  	print( result )
  end
  
  -- Set the current input indicators
  function SetActiveInput(index)
  	if DebugFunction then print("SetActiveInputIndicator() Called") end
  	if(index)then
  		Controls["Input"].String = AlternativeInputNames[index].Name
  		Controls["InputButtons"][ActiveInput].Value = false
  		Controls["InputStatus"][ActiveInput].Value = false
  		Controls["InputButtons"][index].Value = true
  		Controls["InputStatus"][index].Value = true
  		ActiveInput = index
  	else
  		Controls["Input"].String = "Unknown"
  		Controls["InputButtons"][ActiveInput].Value = false
  		Controls["InputStatus"][ActiveInput].Value = false
  	end
  end
  
  --Parse a string from byte array
  function ParseString(data)
  	if DebugFunction then print("ParseString() Called") end
  	local name = ""
  	for i,byte in ipairs(data) do
  		name = name .. string.char(byte)
  	end
  	return name
  end
  
  --A debounce timer on power up avoids reporting the TCP reset that occurs as ane error
  function ClearDebounce()
  	PowerOnDebounce = false
  end
  
  
  ------ Communication Interfaces --------
  -- Shared interface functions
  function Init()
  	if DebugFunction then print("Init() Called") end
    PollQueueCurrent = LoadPollQueue(PropertiesToGet)
  	Disconnected()
   	Connect()
  end
  
  function Connected()
  	if DebugFunction then print("Connected() Called") end
  	CommunicationTimer:Stop()
  	Heartbeat:Start(PollRate)
  	CommandProcessing = false
    PollQueueCurrent = LoadPollQueue(PropertiesToGet)
    if #CommandQueue<1 then 
      --Send( Request["Status"] )
      if #PollQueueCurrent>0 then 
        --if DebugFunction then print("#PollQueueCurrent: "..#PollQueueCurrent) end
        local item = table.remove(PollQueueCurrent)
        --if DebugFunction then print("item "..(item and 'exists' or 'is nil')) end  
        Send( Request[item] )
      end
  	else
      SendNextCommand()
    end
  end
  
  --Wrapper for setting the pwer level
  function SetPowerLevel(val)
  	--
  	if val==1 and Controls["PowerStatus"].Value~=val then
  		ClearUnavailableData()
  		PowerupTimer:Stop()
  
  	--If the display is being shut off, clear the buffer of commands
  	--This prevents a hanging off command from immediately turn the display off on next power-on command
  	elseif(val == 0)then
  		CommandQueue = {}
  	end
  	Controls["PowerStatus"].Value = val
  end
  
  --[[  Communication format
  	All commands are hex bytes of the format:
  			Header        Data-Length  Command          DeviceID  Data      Checksum ETX
        \xDD\xFF\x00  \x08         \xC1\x15\x00\x00 \x??      \xAA\xAA  \x??     \xBB\xCC
  	Extended commands will have Val 1 be a SubCommand when sending
    Data-Length is the number of bytes after the Data-Length byte up to and including the Checksum byte 
  	Checksum is an XOR data bytes including DataLength byte
    DeviceID is the 9th byte, and is part of the data
  
  	Both Serial and TCP mode must contain functions:
  		Connect()
  		Controls["PowerOn"].EventHandler() 
  		And a receive handler that passes data to ParseData()
  ]]
  
  -- Take a request object and queue it for sending.  Object format is of:
  --  { Command=int, Data={int} }
  --  ints must be between 0 and 255 for hex translation
  --  Broadcast is a Boolean to determine if using Broadcast ID for this send
  function Send(cmd, sendImmediately)
    if DebugFunction then 
      for k,v in pairs(Request) do
        if v.Command == cmd.Command then
          print(string.format("Send[\\x%02X](%s, %s) Called", cmd.Command, k, sendImmediately))
        break end
      end
    end
  	local ID = Controls["DisplayID"].Value
  	local value = string.char(#cmd.Data+6).."\xC1"..string.char(cmd.Command).."\x00"..string.char(cmd.Data2 or 0x00)..string.char(ID)..cmd.Data
  	--if DebugTx then PrintByteString(value, "String requiring checksum: ") end
    local checksum = 0
    for i=1, #value do checksum = checksum ~ value:byte(i) end
  	--if DebugTx then print("checksum: "..checksum) end
  	value = "\xDD\xFF\x00"..value..string.char(checksum).."\xBB\xCC"
  
  	--Check for if a command is already queued
  	for i, val in ipairs(CommandQueue) do
  		if(val == value)then
  			--Some Commands should be sent immediately
  			if sendImmediately then
  				--remove other copies of a command and move to head of the queue
  				table.remove(CommandQueue,i)
  				if DebugTx then PrintByteString(value, "Queueing: ") end
  				table.insert(CommandQueue,1,value)
  			end
  			return
  		end
  	end
  	--Queue the command if it wasn't found
  	--if DebugTx then PrintByteString(value, "Queueing: ") end
  	table.insert(CommandQueue,value)
  	SendNextCommand()
  end
  
  local function GetBMSeriesString(ByteString)
    local result = ""
    for i=1,ByteString:len() do
      result = result..string.format("%02X ",ByteString:byte(i))
    end
    result = result:gsub("%s+$", "")
    result = result.."\x0d\x0a\x0a"
    return result -- trim trailing whitespace
  end
  
  --Timeout functionality
  -- Close the current and start a new connection with the next command
  -- This was included due to behaviour within the Device Serial; may be redundant check on TCP mode
  CommunicationTimer.EventHandler = function()
  	if DebugFunction then print("CommunicationTimer Event (timeout) Called") end
  	ReportStatus("MISSING","Communication Timeout")
  	CommunicationTimer:Stop()
  	CommandProcessing = false
  	SendNextCommand()
  end 
  
  --  Serial mode Command function  --
  if ConnectionType == "Serial" then
  	print("Serial Mode Initializing...")
  	-- Create Serial Connection
  	Device = SerialPorts[1]
  	Baudrate, DataBits, Parity = 9600, 8, "N"
  
  	--Send the display the next command off the top of the queue
  	function SendNextCommand()
  		if DebugFunction and not DebugTx then print("SendNextCommand() Called") end
  		if CommandProcessing then
  			-- Do Nothing
  		elseif #CommandQueue > 0 then
  			CommandProcessing = true
        local command = table.remove(CommandQueue,1)
        if DisplaySeries == "BM" then command = GetBMSeriesString(command) end
  			if DebugTx then PrintByteString(command, "Sending["..DisplaySeries.."]: ") end
  			Device:Write( command )
  			CommunicationTimer:Start(CommandTimeout)
  		else
  			CommunicationTimer:Stop()
  		end
  	end
  
  	function Disconnected()
  		if DebugFunction then print("Disconnected() Called") end
  		CommunicationTimer:Stop() 
  		CommandQueue = {}
  		Heartbeat:Stop()
  	end
  
  	-- Clear old and open the socket, sending the next queued command
  	function Connect()
  		if DebugFunction then print("Connect() Called") end
  		Device:Close()
  		Device:Open(Baudrate, DataBits, Parity)
  	end
  
  	-- Handle events from the serial port
  	Device.Connected = function(serialTable)
  		if DebugFunction then print("Connected handler called Called") end
  		ReportStatus("OK","")
  		Connected()
  	end
  
  	Device.Reconnect = function(serialTable)
  		if DebugFunction then print("Reconnect handler called Called") end
  		Connected()
  	end
  
  	Device.Data = function(serialTable, data)
  		ReportStatus("OK","")
  		CommunicationTimer:Stop() 
  		CommandProcessing = false
  		local msg = DataBuffer .. Device:Read(1024)
  		DataBuffer = "" 
  		if DebugRx then PrintByteString(msg, "Received: ") end
  		ParseResponse(msg)
  		SendNextCommand()
  	end
  
  	Device.Closed = function(serialTable)
  		if DebugFunction then print("Closed handler called Called") end
  		Disconnected()
  		ReportStatus("MISSING","Connection closed")
  	end
  
  	Device.Error = function(serialTable, error)
  		if DebugFunction then print("Socket Error handler called Called") end
  		Disconnected()
  		ReportStatus("MISSING",error)
  	end
  
  	Device.Timeout = function(serialTable, error)
  		if DebugFunction then print("Socket Timeout handler called Called") end
  		Disconnected()
  		ReportStatus("MISSING","Serial Timeout")
  	end
  
    function SetPowerOn()
  		if DebugFunction then print("PowerOn Serial Handler Called") end
  		PowerupTimer:Stop()
  		--Documentation calls for 3 commands to be sent, every 2 seconds, for 3 repetitions
  		Send( Request["PowerOn"], true )
  		PowerupCount=0
  		PowerupTimer:Start(2)
  		PowerOnDebounce = true
  		Timer.CallAfter( ClearDebounce, PowerOnDebounceTime)
  	end
  	--Serial mode PowerOn handler uses the main api (see network power on below for more fun)
  	Controls["PowerOn"].EventHandler = SetPowerOn	
  
  	Controls["PanelOn"].EventHandler = function()
  		if DebugFunction then print("PanelOn Serial Handler Called") end
  		Send( Request["PanelOn"] )
      SetPowerOn()
  	end
  
  --  Ethernet Command Function  --DisplaySeries == "BM"
  else
  	print("TCP Mode Initializing...")
  	IPAddress = Controls.IPAddress
  	if Controls.Port.String == '' then Controls.Port.String = 'BM' and '8000' or '8088' end
  	Port = Controls.Port
  	-- Create Sockets
  	Device = TcpSocket.New()
  	Device.ReconnectTimeout = 5
  	Device.ReadTimeout = 10  --Tested to verify 6 seconds necessary for input switches;  Appears some TV behave more slowly
  	Device.WriteTimeout = 10
  	udp = UdpSocket.New()
  	
  	--Send the display the next command off the top of the queue
  	function SendNextCommand()
  		if DebugFunction and not DebugTx then print("SendNextCommand() Called") end
  		if CommandProcessing then
  			-- Do Nothing
  		elseif #CommandQueue > 0 then
  			if not Device.IsConnected then
  				Connect()
  			else
  				CommandProcessing = true
          local command = table.remove(CommandQueue,1)
          if DisplaySeries == "BM" then command = GetBMSeriesString(command) end
          if DebugTx then PrintByteString(command, "Sending["..DisplaySeries.."]: ") end
  				Device:Write( command )
  			end
  		end
  	end
  
  	function Disconnected()
  		if DebugFunction then print("Disconnected() Called") end
  		if Device.IsConnected then
  			Device:Disconnect()
  		end
  		CommandQueue = {}
  		Heartbeat:Stop()
  	end
  
  	-- Clear old and open the socket
  	function Connect()
  		if DebugFunction then print("Connect() Called") end
  		if IPAddress.String ~= "Enter an IP Address" and IPAddress.String ~= "" and Port.String ~= "" then
  			if Device.IsConnected then
  				Device:Disconnect()
  			end
        if DebugFunction then print("Connect("..IPAddress.String..":"..Port.String..")") end
  			Device:Connect(IPAddress.String, tonumber(Port.String))
  		else
  			ReportStatus("MISSING","No IP Address or Port")
  		end
  	end
  
  	-- Handle events from the socket;  Nearly identical to Serial
  	Device.EventHandler = function(sock, evt, err)
  		if DebugFunction then print("Ethernet Socket Handler Called "..evt) end
  		if evt == TcpSocket.Events.Connected then
  			ReportStatus("OK","")
  			Connected()
  		elseif evt == TcpSocket.Events.Reconnect then
        --if DebugFunction then print('Reconnect event - IsConnected: '..tostring(Device.IsConnected)) end
  			--Disconnected()
  
  		elseif evt == TcpSocket.Events.Data then
  			ReportStatus("OK","")
  			CommandProcessing = false
  			TimeoutCount = 0
  			local data = sock:Read(BufferLength)
  			local line = data
  			local msg = DataBuffer
  			DataBuffer = "" 
  			while (line ~= nil) do
  				msg = msg..line
  				line = sock:Read(BufferLength)
  			end
  			if DebugRx then 
          PrintByteString(data, "Received: ")
          if #data ~= #msg then
            PrintByteString(msg, "Buffer: ")
         end
        end
  			ParseResponse(msg)  
  			SendNextCommand()
  			
  		elseif evt == TcpSocket.Events.Closed then
  			Disconnected()
  			ReportStatus("MISSING","Socket closed")
  
  		elseif evt == TcpSocket.Events.Error then
  			Disconnected()
  			ReportStatus("MISSING","Socket error")
  
  		elseif evt == TcpSocket.Events.Timeout then
  			TimeoutCount = TimeoutCount + 1
        --print('TimeoutCount: '..TimeoutCount)
  			if TimeoutCount > 3 then
  				Disconnected()
  				ReportStatus("MISSING","Socket Timeout")
  			end
  
  		else
  			Disconnected()
  			ReportStatus("MISSING",err)
  
  		end
  	end
  
  	--Ethernet specific event handlers
  	Controls["IPAddress"].EventHandler = function()
  		if DebugFunction then print("IP Address Event Handler Called") end
  		if Controls["IPAddress"].String == "" then
  			Controls["IPAddress"].String = "Enter an IP Address"
  		end
  		ClearVariables()
  		Init()
  	end
  	Controls["Port"].EventHandler = function()
  		if DebugFunction then print("Port Event Handler Called") end
  		ClearVariables()
  		Init()
  	end
  
  	-- Get the binary numerical value from a string IP address of the format "%d.%d.%d.%d"
  	-- Consider hardening inputs for this function
  	function IPV4ToValue(ipString)
  		local bitShift = 24
  		local ipValue = 0
  		for octet in ipString:gmatch("%d+") do
  			ipValue = ipValue + (tonumber(octet) << bitShift)
  			bitShift = bitShift - 8
  		end
  		return ipValue or nil
  	end
  
  	-- Convert a 32bit number into an IPV4 string format
  	function ValueToIPV4(value)
  		return string.format("%d.%d.%d.%d", value >> 24, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
  	end
  
  	-- Compare IPAddresses as values (32bit integers)
  	function IPMaskCheck(ip1, ip2, mask)
  		return ip1 & mask == ip2 & mask
  	end
  
  	-- Accept IPAddresses as strings
  	function IsIPInSubnet(ip1, ip2, mask)
  		return IPMaskCheck(IPV4ToValue(ip1), IPV4ToValue(ip2), IPV4ToValue(mask))
  	end
  
    function SetPowerOn(ctl)
  		if DebugFunction then print("PowerOn Ethernet Handler Called") end
  		--MAC from device is sent as string text, needs translation
			local macstr = Controls["MACAddress"].String
			if macstr:len()>12 then macstr = macstr:gsub(":",""):gsub("-","") end
  		if macstr:len()==12 then
  			local mac = ""
  			local localIPAddress = nil
  			local broadcastRange = "255.255.255.255"
  			local deviceIpValue = IPV4ToValue(IPAddress.String)
  			local nics = Network.Interfaces()
  
  			--WOL Packet is 6 full scale bytes then 16 repetitions of Device MAC
  			for i=1,6 do
  				mac = mac..string.char( tonumber( "0x"..macstr:sub((i*2)-1, i*2) ) );  
  			end
  			local WOLPacket = "\xff\xff\xff\xff\xff\xff"
  			for i=1,16 do
  				WOLPacket = WOLPacket..mac
  			end
  
  			-- Check Gateways and generate a broadcast range if it is found to be 0.0.0.0.  This might be better as a property (if user wanted local range for some reason)
  			for name,interface in pairs(nics) do
  				if interface.Gateway == "0.0.0.0" then
  					for _,nic in pairs(nics) do
  						local ipValue = IPV4ToValue(nic.Address)
  						local maskValue = IPV4ToValue(nic.Netmask or "255.255.255.0")  -- Mask may not be available in emulation mode
  						if ipValue & maskValue == deviceIpValue & maskValue then
  							localIPAddress = nic.Address
  							if nic.BroadcastAddress then
  								broadcastRange = nic.BroadcastAddress
  							else
  								broadcastRange = ValueToIPV4((deviceIpValue & maskValue) | (0xFFFFFFFF - maskValue))
  							end
  							break
  						end
  					end
  					break
  				end
  			end
        --hack
        --broadcastRange = '192.168.104.255'
  			--UDP broadcast of the wake on lan packet
  			if DebugTx then print("Sending WoL packet UDP: 9 "..broadcastRange) end
  			udp:Open( localIPAddress )
  			udp:Send( broadcastRange, 9, WOLPacket )
  			udp:Close()
  		end
  
  		PowerupTimer:Stop()
  		Send( Request["PowerOn"], true )
  		--Also send the MDC command in case of broadcast awake signal
  		PowerupCount = 0
  		PowerupTimer:Start(2)
  		PowerOnDebounce = true
  		Timer.CallAfter( ClearDebounce, PowerOnDebounceTime)
  	end
  
  	-- PowerOn command on Ethernet requires a UDP broadcast wake-on-lan packet
  	-- The packet needs the MAC of the display to be formed - GetDisplayInfo must be run once to get the MAC first.
  	-- If Display is connected WiFi the poweron will not work
  	Controls.PowerOn.EventHandler = SetPowerOn
  
  	Controls["PanelOn"].EventHandler = function()
  		if DebugFunction then print("PanelOn Ethernet Handler Called") end
  		Send( Request["PanelOn"])
      SetPowerOn()
  	end
  
  end
  
  
  --  Device Request and Data handlers
  
  --[[ Test the device once for
  	Model Number
  	Device Name
  	Model Name
  	Serial Number
  	SW Revision
  ]]
  -- Initial data grab from device
  function GetDeviceInfo()
  	if DebugFunction then print("GetDeviceInfo() Called") end
  	if Properties["Get Device Info"].Value then
  		if(Controls["DeviceName"].String == "") then Send( Request["DeviceName"] )  end
  		if(Controls["MACAddress"].String == "") then Send( Request["MACAddress"] )  end
    	if(Controls["SerialNumber"].String == "") then Send( Request["SerialNumber"] )  end
  		if(Controls["DeviceFirmware"].String == "") then Send( Request["SWVersion"] ) end
  		if(Controls["ModelNumber"].String == "") then Send( Request["ModelNumber"] ) end -- actually brand
  		if(Controls["ModelName"].String == "") then Send( Request["ModelName"] )  end
  	end
  end
  
  --[[  Response Data parser
  	
  	All response commands are hex bytes of the format
  
    Header        Data-Length  Command          DeviceID  Data      Checksum ETX
    \xAB\xAB\x00  \x08         \xC1\x15\x00\x00 \x??      \xAA\xAA  \x??     \xCD\xCD
  
    Data-Length is the number of bytes after the Data-Length byte up to and including the Checksum byte 
  	Checksum is an XOR data bytes including DataLength byte
    DeviceID is the 9th byte, and is part of the data
  
  	Read until a header is found, then:
  		1. Define a data object
  		2. Parse the command, deviceID, length, and ack into the structure
  		3. Parse the data bytes into an array
  		4. Calculate the checksum
  
  	Then check for:
  		1. correct length
  		2. Ack or Nack
  		3. Checksum is valid
  		4. Push the data object into a handler based on the command
  
  	Recursively call if there is more data after the checksum. Stuff incomplete messages in the buffer
  ]]
  
  
  function ParseResponse(str)
    if DebugFunction and not DebugRx then PrintByteString(str, "ParseResponse() Called: ", true) end
    local _,msg = str:match("^%[(.-)%]:(.+)\x0d") -- BM series sending ASCII response
    if msg then
      if DebugFunction then print("ASCII RX ["..#msg.."]: "..msg) end
  		if DisplaySeries == "Auto" then DisplaySeries = "BM" end
 		  if msg:match('232 time out') then
        print('ERROR received.')
       	DataBuffer = ""
      return end
      msg = msg:gsub(" ","") -- remove spaces because "%S+" isn't working to ignore spaces
      msg = msg:gsub("%S%S", function(hex) return string.char(tonumber(hex, 16)) end)
    else
      if DebugFunction then print("String RX ["..#str.."]: "..str) end
      if str:match('No Client Input,Please input command\x0a') then
        print('ASCII message received')
        if DisplaySeries == "Auto" then DisplaySeries = "BM" end
        DataBuffer = ""
      return end
      msg = str
    end
  	--Message is too short, buffer the chunk and wait for more
  	if msg:len()==0 then 
  		--do nothing
  	elseif string.match(msg, 'error') then -- can't use trailing $ in regex because it gets parsed badly by the compiler
      print('ERROR response received')
  	elseif msg:len() < 12 then
      PrintByteString(msg, 'WARNING short response received: ')
  		DataBuffer = DataBuffer .. msg
  
  	--Message doesn't start at begining.  Find the correct start then parse from there
  	--elseif msg:byte(1) ~= 0xAB or msg:byte(2) ~= 0xAB or msg:byte(3) ~= 0x00 then
  	elseif not msg:match('^\xAB\xAB\x00') then
  		local i=msg:find("\xAB\xAB\x00") 
  		if i == nil then
        PrintByteString(msg, "WARNING Message doesn't start with STX '\xAB\xAB\x00'")
        --DataBuffer = DataBuffer .. msg
  			DataBuffer = ""
  		else
        PrintByteString(msg, "ParseResponse["..i.."]: ")
  			ParseResponse( msg:sub(i,-1) )
  		end
  	
  	--If the message length field is longer than the buffer, stuff back into the buffer and wait for a complete message
  	elseif msg:len() < msg:byte(3)+5 then
      PrintByteString(msg, "WARNING message length field is longer than the buffer: ")
  		DataBuffer = DataBuffer .. msg
  
  	--Handle a good message
  	else
      DataBuffer = ''
  		local ResponseObj = {}
  		--Pack the data for the handler 
      local DataStartBytePos = 5
  		ResponseObj['DataLength']=msg:byte(4) -- this is not accurate for the ModelName response
      local i=msg:find("\xCD\xCD") 
      if ResponseObj['DataLength'] ~= i-5 then
        print('Data lenght byte: '..ResponseObj['DataLength']..', actual length: '..i-5)
  		  ResponseObj['DataLength']=i-5
  		end
      ResponseObj['Command'   ]=msg:byte(6)	
      ResponseObj['Data2'     ]=msg:byte(8) -- \x00
  		ResponseObj['DeviceId'  ]=msg:byte(9)
  		ResponseObj['Data'      ]=msg:sub(10,ResponseObj['DataLength']+3) -- \xAA\xAA
  		ResponseObj['CheckSum'  ]=msg:byte(ResponseObj['DataLength']+4)
      ResponseObj['CheckSumTotal']=0
    
      --if DebugFunction and DebugRx then PrintByteString(ResponseObj['Data'], "Data: ") end
  		--Read the data bytes into the data array
  		if ResponseObj['DataLength']>5 then
  			for i=1, (ResponseObj['DataLength']) do
  				--table.insert( ResponseObj['Data'], msg:byte(i+DataStartBytePos) )
  				ResponseObj['CheckSumTotal']=ResponseObj['CheckSumTotal']~msg:byte(i+3)
          --print(string.format("CHK[%d] b: \\x%02X, val: \\x%02X", i, msg:byte(i+3), ResponseObj['CheckSumTotal']))
        end
  		end
      ResponseObj['Ack']=true
  
  		--Checksum failures;  Don't handle
  		if ResponseObj['CheckSum'] ~= ResponseObj['CheckSumTotal'] then
  			if DebugRx then
          print(string.format("Checksum failure: \\x%02X does not match \\x%02X", ResponseObj['CheckSum'], ResponseObj['CheckSumTotal'])) 
          PrintByteString(msg:sub(4,ResponseObj['DataLength']+3), "Data: ", true)
        end
  		--else HandleResponse(ResponseObj)
  		end
  		HandleResponse(ResponseObj)
  
  		--Re-process any remaining data
      local remaining = msg:sub(7+ResponseObj['DataLength'],-1)
      --PrintByteString(remaining, "Re-process any remaining data: ")
  		ParseResponse( remaining )
  	end 
    if #CommandQueue<1 then
      if #PollQueueCurrent==0 then PollQueueCurrent = LoadPollQueue(StatusToGet) end
      local item = table.remove(PollQueueCurrent)
      Send( Request[item] )
    end 
  end
  
  -- Handler for good data from interface
  function HandleResponse(msg)
  	if DebugFunction then 
      for k,v in pairs(Request) do
        if v.Command == msg.Command then
          print(string.format("HandleResponse[\\x%02X](%s) Called", msg.Command, k))
        break end
      end
    --if DebugRx then PrintByteString(msg.Data, "Data: ") end
    end
  
  	--Serial Number / DeviceName (both use the same .Command)
  	if msg["Command"]==Request.SerialNumber.Command then
      if Request.SerialNumber.Data2 == msg.Data2 then
        if DebugFunction then PrintByteString(msg['Data'], "SerialNumber response received: ") end
        if msg['Ack'] then Controls["SerialNumber"].String = msg["Data"]
        else               Controls["SerialNumber"].String = "Unavailable" end
      elseif Request.DeviceName.Data2 == msg.Data2 then
        if DebugFunction then PrintByteString(msg['Data'], "DeviceName response received: ") end
        if msg['Ack'] then Controls["DeviceName"].String = msg["Data"]
        else               Controls["DeviceName"].String = "Unavailable" end
      else
        if DebugFunction then PrintByteString(msg['Data'], "Unhandled Device info response received: ") end
      end
  
  	--Model Number / ModelName (both use the same .Command)
  	elseif msg["Command"]==Request.ModelName.Command then
      if Request.ModelName.Data2 == msg.Data2 then
        if DebugFunction then PrintByteString(msg['Data'], "ModelName response received: ") end
        if msg['Ack'] then Controls["ModelName"].String = msg["Data"]
          PluginInfo.Model = Controls["ModelName"].String
        else               Controls["ModelName"].String = "Unavailable" end
      elseif Request.ModelNumber.Data2 == msg.Data2 then
        if DebugFunction then PrintByteString(msg['Data'], "ModelNumber response received: ") end
        if msg['Ack'] then Controls["ModelNumber"].String = msg["Data"]
        else               Controls["ModelNumber"].String = "Unavailable" end
      end
  
  	--SW Version
  	elseif msg["Command"]==Request.SWVersion.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Software version response received: ") end
  		if msg['Ack'] then Controls["DeviceFirmware"].String = string.format("%02d/%02d/%02d",msg["Data"]:byte(3),msg["Data"]:byte(2),msg["Data"]:byte(1))
  		else               Controls["DeviceFirmware"].String = "Unavailable" end
  
  	--Input source Control response
  	elseif msg["Command"]==Request.InputStatus.Command then --or msg["Command"]==Request.InputSet.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Input status response received: ") end
      local input = GetInputIndex(msg["Data"])
  
  	elseif msg["Command"]==Request.InputSet.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Input response received: ") end
      local input = GetInputIndex(msg["Data"])
  
  	--MAC Address
  	elseif msg["Command"]==Request.MACAddress.Command then
  		if msg['Ack'] then
        if DebugFunction then PrintByteString(msg['Data'], "MACAddress response received: ") end
        local mac = ""
        for i=1, #msg['Data'] do mac = mac..string.format("%02X",msg['Data']:byte(i)) end
        Controls["MACAddress"].String = mac
  		else
  			Controls["MACAddress"].String = "Unavailable"
  		end
  	
  	-- Catch NACK responses that aren't handled
  	elseif not msg["Ack"] then
  		print("Nack response received for command "..msg["Command"])
  
  	--Handle Status command
  	elseif msg["Command"]==Request.Status.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Status response received: ") end
      --print("data:byte(1): "..msg["Data"]:byte(1))
  		Controls["Volume"].Value = msg["Data"]:byte(1)
  		SetActiveInput( GetInputIndex(msg["Data"]:sub(2,3)) )
      if msg["Data"]:byte(4)==0x00 then -- or Device.IsConnected then
        SetPowerLevel(1) print('PowerOn Rx')
      elseif msg["Data"]:byte(4)==0xFF then 
        SetPowerLevel(0) print('PowerOff Rx')
      end
  		Controls["Mute"].Value = msg["Data"]:byte(5)
  
  	--Power Status
  	elseif msg["Command"]==Request.PowerOff.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Power response received: ") end
  		SetPowerLevel( msg["Data"]:byte(1) )
  
  	--Panel Status
  	elseif msg["Command"]==Request.PanelOn.Command or msg["Command"]==Request.PanelStatus.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Panel response received: ") end
  		Controls["PanelStatus"].Boolean = (msg["Data"] == Request["PanelOn"].Data)
  		Controls["PanelOn"].Boolean  = (msg["Data"] == Request["PanelOn" ].Data)
  		Controls["PanelOff"].Boolean = (msg["Data"] == Request["PanelOff"].Data)
  
  	--Mute Status
  	elseif msg["Command"]==Request.MuteOn.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Mute response received: ") end
  		Controls["Mute"].Value = msg["Data"]:byte(1)
  
  	--Volume Status
  	elseif msg["Command"]==Request.VolumeStatus.Command or msg["Command"]==Request.VolumeSet.Command then
      if DebugFunction then PrintByteString(msg['Data'], "Volume response received: ", true) end
  		Controls["Volume"].Value = msg["Data"]:byte(1)
  
  	--Handle Anything else by printing the unexpected command (debug?)
  	else
  		if DebugRx then 
  			if DebugFunction then 
          print("Unexpected Data received.  Command: "..msg["Command"])
  			  PrintByteArray( msg["Data"] )
        end
  		end
  	end
  end
  
  --[[    Input Handler functions      ]]
  
  -- Re-Initiate communication when the user changes the IP address or Port or ID being queried
  Controls["DisplayID"].EventHandler = function()
  	if DebugFunction then print("Port Event Handler Called") end
  	ClearVariables()
  	Init()
  end
  
  function SetPowerOff()
  	if DebugFunction then print("PowerOff Handler Called") end
  	-- Stop the power on sequence if the user presses power off
  	PowerupTimer:Stop()
  	CommandQueue = {}
  	Controls["PowerStatus"].Value = 0
  	Send( Request["PowerOff"], true )
  end
  
  --Controls Handlers
  -- Power controls
  Controls["PowerOff"].EventHandler = SetPowerOff
  
  -- Panel controls
  Controls["PanelOff"].EventHandler = function()
  	if DebugFunction then print("PanelOff Handler Called") end
  	Controls["PanelStatus"].Boolean = false
  	Send( Request["PanelOff"])
    if DisplaySeries == "BM" then
      SetPowerOff()
    end
  end
  
  -- Input controls
  for i=1,#Controls['InputButtons'] do
    --if AlternativeInputNames[i] and AlternativeInputNames[i].Name then 
    --  Controls['InputButtons'][i].Legend = AlternativeInputNames[i].Name
    --end
  	Controls['InputButtons'][i].EventHandler = function(ctl)
  		if DebugFunction then print("Input["..(AlternativeInputNames[i].Name or i).."] button "..tostring(ctl.Boolean)) end
  		if ctl.Boolean then
  			Request["InputSet"]["Data"] = AlternativeInputNames[i].Value
  			Send( Request["InputSet"] )
  		end
  	end
  end 

	Controls["Input"].EventHandler = function(ctl)
		if DebugFunction then print("Input["..ctl.String.."] Choice") end
    for i,v in ipairs(AlternativeInputNames) do
      if v.Name == ctl.String then
        Request["InputSet"]["Data"] = v.Value
        Send( Request["InputSet"] )
        return
      end
    end
    ctl.String = "" -- invalid choice, default to unknown and let the next poll update the value correctly
	end
  
  -- Sound Controls
  Controls["Mute"].EventHandler = function(ctrl)
  	if DebugFunction then print("Mute Handler Called") end
  	if ctrl.Value == 1 then
  		Send( Request["MuteOn"] )
  	else
  		Send( Request["MuteOff"] )
  	end
  end
  
  function VolumRampTimerExpired()
  	if DebugFunction then print("VolumRampTimerExpired Handler Called "..string.format('\\x%02X', math.floor(Controls["Volume"].Value))) end
  	if Controls["VolumeUp"].Boolean then 
      Controls["Volume"].Value = Controls["Volume"].Value > 98 and 100 or Controls["Volume"].Value + 1
    elseif Controls["VolumeDown"].Boolean then 
      Controls["Volume"].Value = Controls["Volume"].Value < 2 and 0 or Controls["Volume"].Value - 1
    elseif VolumRampTimer:IsRunning() then 
      VolumRampTimer:Stop()
    end
    Request["VolumeSet"]["Data"] = string.char(math.floor(Controls["Volume"].Value)) -- convert 100 to '\x64' 
  	Send( Request["VolumeSet"] )
  end
  VolumRampTimer.EventHandler = VolumRampTimerExpired
  
  Controls["VolumeUp"].EventHandler = function(ctl)
  	if DebugFunction then print("VolumeUp Handler Called "..tostring(ctl.Boolean)) end
    if ctl.Boolean then	
      if Request["VolumeUp"] then 
        Send( Request["VolumeUp"] ) 
      else
        if not VolumRampTimer:IsRunning() then VolumRampTimer:Start(0.3) end
        VolumRampTimerExpired()
      end
    else
      if VolumRampTimer:IsRunning() then VolumRampTimer:Stop() end
    end
  end
  Controls["VolumeDown"].EventHandler = function(ctl)
  	if DebugFunction then print("VolumeDown Handler Called "..tostring(ctl.Boolean)) end
    if ctl.Boolean then	
      if Request["VolumeDown"] then 
        Send( Request["VolumeDown"] ) 
      else
        if not VolumRampTimer:IsRunning() then VolumRampTimer:Start(0.3) end
        VolumRampTimerExpired()
      end
    else
      if VolumRampTimer:IsRunning() then VolumRampTimer:Stop() end
    end
  end
  
  VolumeDebounce.EventHandler = function()
  	if DebugFunction then print("VolumeDebounce Handler Called "..string.format('\\x%02X', math.floor(Controls["Volume"].Value))) end
  	Request["VolumeSet"]["Data"] = string.char(math.floor(Controls["Volume"].Value)) -- convert 100 to '\x64' 
  	Send( Request["VolumeSet"] )
  	VolumeDebounce:Stop()
  end
  
  Controls["Volume"].EventHandler = function(ctrl)
  	if DebugFunction then print("Volume Handler Called") end
  	VolumeDebounce:Start(.500)
  end
  
  -- Timer EventHandlers  --
  Heartbeat.EventHandler = function()
  	if DebugFunction and not DebugTx then print("Heartbeat Event Handler Called") end
  	Send( Request["Status"] )
  	if Controls["PowerStatus"].Value==1 then
  		--Send( Request["PanelStatus"] ) -- this causes the device to reboot and erase
  		Send( Request["InputStatus"] )
  	  --Send( Request["VolumeStatus"] )
  		--GetDeviceInfo()
  	end
  end 
  
  
  -- PowerOn command requires spamming the interface 3 times at 2 second intervals
  PowerupTimer.EventHandler = function()
  	if Controls["PowerStatus"].Value == 1 then
  		PowerupTimer:Stop()
  	else
  		Send( Request["PowerOn"], true )
  		PowerupCount= PowerupCount + 1
  		if PowerupCount>2 then
  			PowerupTimer:Stop()
  		end
  	end
  end
  
  -- Kick it off
  SetupDebugPrint()
  if not StartupTimer:IsRunning() then
      StartupTimer.EventHandler = function()
        print("StartupTimer expired")
        Init()
        StartupTimer:Stop()
      end
      StartupTimer:Start(2)
  end
