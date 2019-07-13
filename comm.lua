--[[
	Usage so far:  MonDKP.Sync:SendData(prefix, core.WorkingTable)  --sends table through comm channel for updates

	TODO:
	functions will be separated into more specific uses such as full DB upload (it's current state) as well as
	individual entries (sending updates for one or more users. IE: if dkp is deducted from a single person)
	Will also incorporate events to trigger the update for users that have an outdated DB as well as a cooldown mechanism to prevent flooding

	Prefix's used: 	MonDKPDataSync - Mass Update. Update all SavedVariables
					MonDKPBroadcast - Message on broadcast
					MonDKPLogSync - Syncs Loot Log
					MonDKPNotify - string of variables to be broken down to launch modules (eg. timer 20 timer_title_string)


--]]	

local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

MonDKP.Sync = LibStub("AceAddon-3.0"):NewAddon("MonDKP", "AceComm-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibCompress = LibStub:GetLibrary("LibCompress")
local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()

function MonDKP.Sync:OnEnable()
	MonDKP.Sync:RegisterComm("MonDKPDataSync", MonDKP.Sync:OnCommReceived())
	MonDKP.Sync:RegisterComm("MonDKPBroadcast", MonDKP.Sync:OnCommReceived())
	MonDKP.Sync:RegisterComm("MonDKPLogSync", MonDKP.Sync:OnCommReceived())
	MonDKP.Sync:RegisterComm("MonDKPNotify", MonDKP.Sync:OnCommReceived())
	MonDKP.Sync:RegisterComm("MonDKPLootAward", MonDKP.Sync:OnCommReceived())
end

function MonDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
	if (prefix) then
		if (prefix == "MonDKPBroadcast") and sender ~= UnitName("player") then
			MonDKP:Print(message)
		elseif (prefix == "MonDKPNotify") then
			local command, arg1, arg2 = strsplit(",", message);
			if sender ~= UnitName("player") then
				if command == "StartTimer" then
					MonDKP:StartTimer(arg1, arg2)
				elseif command == "StartBidTimer" then
					MonDKP:StartBidTimer(arg1, arg2)
				end
			end
		end
		if (sender ~= UnitName("player")) then
			if (prefix == "MonDKPDataSync" or prefix == "MonDKPLogSync" or prefix == "MonDKPLootAward") then
				if (prefix == "MonDKPDataSync") then
					MonDKP:Print("DKP database updated by "..sender.."...")
				end
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					if (prefix == "MonDKPLogSync") then
						MonDKP_Loot = deserialized;
						MonDKP:LootHistory_Reset()
						MonDKP:LootHistory_Update("No Filter")
						MonDKP:Print("Loot history update complete.")
					elseif prefix == "MonDKPLootAward" then
						tinsert(MonDKP_Loot, deserialized)
						MonDKP:LootHistory_Reset()
						MonDKP:LootHistory_Update("No Filter")
					else
						MonDKP_DKPTable = deserialized;			-- commits to SavedVariables
						MonDKP:FilterDKPTable(core.currentSort, "reset")
						DKPTable_Update()
					end
				else
					print(deserialized)  -- error reporting if string doesn't get deserialized correctly
				end
			end
		end
		if (sender == UnitName("player") and prefix == "MonDKPLogSync") then
			MonDKP:Print("Loot History Broadcast Complete")
		end
	end
end

function MonDKP.Sync:SendData(prefix, data)
	local serialized = nil;
	local packet = nil;
	local verInteg1 = false;
	local verInteg2 = false;

	if (prefix == "MonDKPBroadcast" or prefix == "MonDKPNotify") then
		MonDKP.Sync:SendCommMessage(prefix, data, "PARTY")
		return;
	end

	if data then
		serialized = LibAceSerializer:Serialize(data);
	end

	-- compress serialized string with both possible compressions for comparison
	-- I do both in case one of them doesn't retain integrity after decompression and decoding, the other is sent
	local huffmanCompressed = LibCompress:CompressHuffman(serialized);
	if huffmanCompressed then
		huffmanCompressed = LibCompressAddonEncodeTable:Encode(huffmanCompressed);
	end
	local lzwCompressed = LibCompress:CompressLZW(serialized);
	if lzwCompressed then
		lzwCompressed = LibCompressAddonEncodeTable:Encode(lzwCompressed);
	end

	-- Decode to test integrity
	local test1 = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(huffmanCompressed))
	if test1 == serialized then
		verInteg1 = true
	end
	local test2 = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(lzwCompressed))
	if test2 == serialized then
		verInteg2 = true
	end
	-- check which string with verified integrity is shortest. Huffman usually is
	if (strlen(huffmanCompressed) < strlen(lzwCompressed) and verInteg1 == true) then
		packet = huffmanCompressed;
	elseif (strlen(huffmanCompressed) > strlen(lzwCompressed) and verInteg2 == true) then
		packet = lzwCompressed
	elseif (strlen(huffmanCompressed) == strlen(lzwCompressed)) then
		if verInteg1 == true then packet = huffmanCompressed
		elseif verInteg2 == true then packet = lzwCompressed end
	end

	--debug lengths, uncomment to see string lengths of each uncompressed, Huffman and LZQ compressions
	--[[print("Uncompressed: ", strlen(serialized))
	print("Huffman: ", strlen(huffmanCompressed))
	print("LZQ: ", strlen(lzwCompressed)) --]]

	-- send packet
	MonDKP.Sync:SendCommMessage(prefix, packet, "PARTY")

	-- Verify Send
	if (prefix == "MonDKPDataSync") then
		MonDKP:Print("DKP Database Broadcasted")
	elseif (prefix == "MonDKPLogSync") then
		MonDKP:Print("Loot History Broadcasted")
	end
end