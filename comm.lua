--[[
	Usage so far:  MonDKP.Sync:SendData(core.WorkingTable)  --sends table through comm channel for updates

	TODO:
	functions will be separated into more specific uses such as full DB upload (it's current state) as well as
	individual entries (sending updates for one or more users. IE: if dkp is deducted from a single person)
	Will also incorporate events to trigger the update for users that have an outdated DB as well as a cooldown mechanism to prevent flooding

	Prefix's used: 	MonDKPDataSync - Mass Update. Update all SavedVariables
					MonDKPBroadcast - Message on broadcast
					MonDKPDataSmall - Supress full update message
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
	MonDKP.Sync:RegisterComm("MonDKPDataSmall", MonDKP.Sync:OnCommReceived())
	MonDKP.Sync:RegisterComm("MonDKPLogSync", MonDKP.Sync:OnCommReceived())
end

function MonDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
	if (prefix) then
		if (prefix == "MonDKPBroadcast") then
			MonDKP:Print(message)
		end
		if (sender ~= UnitName("player")) then
			if (prefix == "MonDKPDataSync" or prefix == "MonDKPDataSmall" or prefix == "MonDKPLogSync") then
				if (prefix == "MonDKPDataSync") then
					MonDKP:Print("DKP Database update initiated by "..sender.."...")
				end
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					if (prefix == "MonDKPLogSync") then
						MonDKP_Log = deserialized;
						MonDKP:LootHistory_Update()
						MonDKP:Print("Loot history update complete.")
					else
						MonDKP_DKPTable = deserialized;			-- commits to SavedVariables
						MonDKP:FilterDKPTable("class", "reset")
						DKPTable_Update()
						if (prefix == "MonDKPDataSync") then
							MonDKP:Print("DKP Database update complete!")
						end
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

	if (type(data) == "string") then
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