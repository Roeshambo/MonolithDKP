--[[
	Usage so far:  MonDKP.Sync:SendData(prefix, core.WorkingTable)  --sends table through comm channel for updates
--]]	

local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

MonDKP.Sync = LibStub("AceAddon-3.0"):NewAddon("MonDKP", "AceComm-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibCompress = LibStub:GetLibrary("LibCompress")
local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()
local Meta_Remote_Temp = { DKP={}, Loot={} }
local timer = 0
local MetasReceived = 0
local SyncInProgress = false
local SyncMessage = false
local InitiatingOfficer = false
local FlagValidation = false
local ProfileRequest = {}

function MonDKP:ValidateSender(sender)								-- returns true if "sender" has permission to write officer notes. false if not or not found.
	if MonDKP:GetGuildRankIndex(sender) == 1 then       			-- automatically gives permissions above all settings if player is guild leader
		return true;
	end
	if #MonDKP_Whitelist > 0 then									-- if a whitelist exists, checks that rather than officer note permissions
		for i=1, #MonDKP_Whitelist do
			if MonDKP_Whitelist[i] == sender then
				return true;
			end
		end
		return false;
	else
		local rankIndex = MonDKP:GetGuildRankIndex(sender);				-- validates user has permission to push table update broadcasts.

		if rankIndex then
			return C_GuildInfo.GuildControlGetRankFlags(rankIndex)[12]		-- returns true/false if player can write to officer notes
		else
			return false;
		end
	end
end

local function TempProfile_Create(player, dkp, gained, spent)
	local tempName, tempClass
	local guildSize = GetNumGuildMembers();
	local class = "NONE"
	local dkp = dkp or 0
	local gained = gained or 0
	local spent = spent or 0
	
	for i=1, guildSize do
		tempName,_,_,_,_,_,_,_,_,_,tempClass = GetGuildRosterInfo(i)
		tempName = strsub(tempName, 1, string.find(tempName, "-")-1)			-- required to remove server name from player (can remove in classic if this is not an issue)
		if tempName == player then
			class = tempClass
			break
		end
	end

	local search = MonDKP:Table_Search(MonDKP_DKPTable, player, "player")

	if not search then
		table.insert(MonDKP_DKPTable, {player=player, lifetime_spent=spent, lifetime_gained=gained, class=class, dkp=dkp, rank=10, spec=L["NOSPECREPORTED"], role=L["NOROLEDETECTED"], rankName="None", previous_dkp=0 })
	else
		local entry = MonDKP_DKPTable[search[1][1]]

		entry.lifetime_spent = entry.lifetime_spent + spent
		entry.lifetime_gained = entry.lifetime_gained + gained
		entry.dkp = entry.dkp + dkp
	end

	if class == "NONE" then
		if not MonDKP_Archive[player] or (MonDKP_Archive[player] and MonDKP_Archive[player].deleted ~= true) then
			table.insert(ProfileRequest, player)
		end
	else
		MonDKP:FilterDKPTable(core.currentSort, "reset")
		MonDKP:ClassGraph_Update()
	end
end

local function PlayerProfile_Send(player)
	local search = MonDKP:Table_Search(MonDKP_DKPTable, player, "player")

	if search then
		local info = MonDKP_DKPTable[search[1][1]]
		MonDKP.Sync:SendData("MDKPProfile", {player=info.player, class=info.class})
	end
end

local function SyncFinalize()
	MonDKP.Sync:SendData("MDKPSyncInit", "end")
	MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
	MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 5 then
			local deleted = {}

			MonDKP.SyncTimer:SetScript("OnUpdate", nil)
			timer = 0

			for k,v in pairs(MonDKP_Archive) do
				if MonDKP_Archive[k].deleted then
					table.insert(deleted, { player=k, deleted=v.deleted, edited=v.edited })
				end
			end

			if #deleted > 0 then
				MonDKP.Sync:SendData("MDKPDelUsers", deleted)
			end
			
			if SyncMessage then
				MonDKP:Print(L["SYNCCOMPLETE"])
			end
			SyncMessage = false
			SyncInProgress = false
			InitiatingOfficer = false
			MetasReceived = 0
			-- end sync for sending officer
		end
	end)
end

local function SyncInit()
	MonDKP.Sync:SendData("MDKPSyncInit", MonDKP_Meta)			-- request tables from players to determine what to send

	MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
	MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 3 then
			MonDKP.SyncTimer:SetScript("OnUpdate", nil)
			timer = 0

			for k1,v1 in pairs(MonDKP_Meta) do
			    for k2,v2 in pairs(v1) do
			    	local lowest = 0

			        if Meta_Remote_Temp[k1][k2] then lowest = Meta_Remote_Temp[k1][k2] end
			        
			        if lowest < MonDKP_Meta[k1][k2].current and MetasReceived > 0 then
				        local i=lowest+1
						local timer = 0
						local processing = false
						
						local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
						ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
							timer = timer + elapsed
							if timer > 0.1 and i <= MonDKP_Meta[k1][k2].current and not processing then
								processing = true
								if k1 == "DKP" then
						        	local search = MonDKP:Table_Search(MonDKP_DKPHistory, tostring(k2.."-"..i), "index")
								
									if search then
										MonDKP.Sync:SendData("MDKPSyncDKP", MonDKP_DKPHistory[search[1][1]])
										SyncMessage = true
										SyncInProgress = true
									end
								else
									local search = MonDKP:Table_Search(MonDKP_Loot, tostring(k2.."-"..i), "index")

									if search then
										MonDKP.Sync:SendData("MDKPSyncLoot", MonDKP_Loot[search[1][1]])
										SyncMessage = true
										SyncInProgress = true
									end
								end
								processing = false
								i=i+1
								timer = 0
							elseif i > MonDKP_Meta[k1][k2].current then
								ValidateTimer:SetScript("OnUpdate", nil)
								timer = 0
							end
				        end)
				    end
			    end
			end
			SyncFinalize()
		end
	end)
end

function MonDKP:SyncOfficers()
	if not core.Migrated or SyncInProgress then return end

	Meta_Remote_Temp = { DKP={}, Loot={} }
	SyncInProgress = true
	InitiatingOfficer = true
	
	if #core.Errant > 0 then
		MonDKP.Sync:SendData("MDKPErrantOff", core.Errant)
	end

	MonDKP.Sync:SendData("MDKPSyncOff", MonDKP_Meta)

	MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent) 		-- 3 second timer, pushed back 1 second if timer is above 1 and a broadcast is received
	MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)						-- every time the timer reaches 3 seconds it resets to 0 and kicks off the next Sync phase
		timer = timer + elapsed
		if timer > 3 then
			MonDKP.SyncTimer:SetScript("OnUpdate", nil)
			timer = 0
			SyncInit()
			MonDKP:StatusVerify_Update()
		end
	end)
end

function MonDKP:RequestSync()
	if SyncInProgress then
		MonDKP:Print(L["SYNCALREADY"])
		return
	end

	local officers = {}

	MonDKP:CheckOfficer()
	if core.IsOfficer and (#MonDKP_Loot > 0 or #MonDKP_DKPHistory > 0) then
		MonDKP:SyncOfficers()
	else
		if #MonDKP_Whitelist == 0 then
			if IsInGuild() then
				guildSize = GetNumGuildMembers();
				for i=1, guildSize do
					local name, rankIndex, online

					name, _, rankIndex, _,_,_,_,_,online = GetGuildRosterInfo(i)
					name = strsub(name, 1, string.find(name, "-")-1)
					rankIndex = rankIndex+1

					if C_GuildInfo.GuildControlGetRankFlags(rankIndex)[12] and online and name ~= UnitName("player") then
						table.insert(officers, name)
					end
				end
				if #officers > 0 then
					MonDKP.Sync:SendData("MDKPReqSync", "Sync Request", officers[math.random(1,#officers)]) -- requests sync from random online officer
				else
					MonDKP:Print(L["NOOFFICERSONLINE"])
					MonDKP.Sync:SendData("MDKPTableComp", "Start") -- requests meta tables for comparison if no officers are online
				end
			end
		else
			if IsInGuild() then
				guildSize = GetNumGuildMembers();
				for i=1, guildSize do
					local name, rankIndex, online

					name, _, rankIndex, _,_,_,_,_,online = GetGuildRosterInfo(i)
					name = strsub(name, 1, string.find(name, "-")-1)
					rankIndex = rankIndex+1

					if MonDKP:Table_Search(MonDKP_Whitelist, name) and online and name ~= UnitName("player") then
						table.insert(officers, name)
					end
				end
				if #officers > 0 then
					MonDKP.Sync:SendData("MDKPReqSync", "Sync Request", officers[math.random(1,#officers)]) -- requests sync from random online whitelisted officer
				else
					MonDKP:Print(L["NOOFFICERSONLINE"])
					MonDKP.Sync:SendData("MDKPTableComp", "Start") -- requests meta tables for comparison if no officers are online
				end
			end
		end
	end
end

function MonDKP:UpdateQuery() 	-- DKP Status Button click function
	MonDKP:ErrantCheck()
	SyncMessage = true	
	
	if SyncInProgress then
		MonDKP:Print(L["SYNCALREADY"])
		return
	end

	MonDKP.Sync:SendData("MDKPQuery", "start") 	-- requests role and spec data
	MonDKP:RequestSync()	-- begins sync (if officer) or requests sync from random online officer if non officer
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)			-- hides "No player named X online" spam if officer logs off mid sync
	if SyncInProgress then
		if strfind(msg, "No player named") == 1 then
			return true
		end
	end
end)

-------------------------------------------------
-- Register Broadcast Prefixs
-------------------------------------------------

function MonDKP.Sync:OnEnable()
	-- Sync Prefixs
	MonDKP.Sync:RegisterComm("MDKPSyncOff", MonDKP.Sync:OnCommReceived())			-- Requests missing entries from officers
	MonDKP.Sync:RegisterComm("MDKPOffDKP", MonDKP.Sync:OnCommReceived())			-- Receive DKP Entries between officers before full guild sync request
	MonDKP.Sync:RegisterComm("MDKPOffLoot", MonDKP.Sync:OnCommReceived())			-- Receive Loot Entries between officers before full guild sync request
	MonDKP.Sync:RegisterComm("MDKPSyncInit", MonDKP.Sync:OnCommReceived())		-- Initiates Guild Sync (sent meta table requests all tables, "end" initiates errant entry check)
	MonDKP.Sync:RegisterComm("MDKPSyncReq", MonDKP.Sync:OnCommReceived())			-- Returns player meta table for comparison by officer (all can see and process this to determine if they have missing entries)
	MonDKP.Sync:RegisterComm("MDKPSyncDKP", MonDKP.Sync:OnCommReceived())			-- Process and apply DKP entries received from officer
	MonDKP.Sync:RegisterComm("MDKPSyncLoot", MonDKP.Sync:OnCommReceived())		-- Process and apply Loot entries received from officer
	MonDKP.Sync:RegisterComm("MDKPErrantReq", MonDKP.Sync:OnCommReceived())		-- Scans all entries for all officers "lowest" to "current" finding any entries missing in between (IE: They have Roeshambo-10 and 12 but not 11)
	MonDKP.Sync:RegisterComm("MDKPErrantOff", MonDKP.Sync:OnCommReceived())		-- Same as above, officers only
	MonDKP.Sync:RegisterComm("MDKPProfileReq", MonDKP.Sync:OnCommReceived())		-- Requests missing player profile info
	MonDKP.Sync:RegisterComm("MDKPProfile", MonDKP.Sync:OnCommReceived())			-- Sends player profile info (name/class)
	MonDKP.Sync:RegisterComm("MDKPReqSync", MonDKP.Sync:OnCommReceived())			-- Non officer, submits a sync request to a random online officer
	MonDKP.Sync:RegisterComm("MDKPDelUsers", MonDKP.Sync:OnCommReceived())		-- Broadcasts deleted users (archived users not on the DKP table)
	MonDKP.Sync:RegisterComm("MDKPArchive", MonDKP.Sync:OnCommReceived())			-- Broadcasts archive for full sync
	MonDKP.Sync:RegisterComm("MDKPMetaFull", MonDKP.Sync:OnCommReceived())		-- Broadcasts meta table for full sync
	MonDKP.Sync:RegisterComm("MDKPTableComp", MonDKP.Sync:OnCommReceived())		-- Broadcasts requests all meta tables if no officers are online, for comparison purpose only
	MonDKP.Sync:RegisterComm("MDKPMigrated", MonDKP.Sync:OnCommReceived())		-- Broadcasts to other officers letting them know migration occurred. Swapping their window
	-- Normal broadcast Prefixs
	MonDKP.Sync:RegisterComm("MDKPDecay", MonDKP.Sync:OnCommReceived())			-- Broadcasts a weekly decay adjustment
	MonDKP.Sync:RegisterComm("MDKPBCastMsg", MonDKP.Sync:OnCommReceived())		-- broadcasts a message that is printed as is
	MonDKP.Sync:RegisterComm("MDKPCommand", MonDKP.Sync:OnCommReceived())			-- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
	MonDKP.Sync:RegisterComm("MDKPLootDist", MonDKP.Sync:OnCommReceived())		-- broadcasts individual loot award to loot table
	MonDKP.Sync:RegisterComm("MDKPDelLoot", MonDKP.Sync:OnCommReceived())			-- broadcasts deleted loot award entries
	MonDKP.Sync:RegisterComm("MDKPDelSync", MonDKP.Sync:OnCommReceived())			-- broadcasts deleated DKP history entries
	MonDKP.Sync:RegisterComm("MDKPDKPDist", MonDKP.Sync:OnCommReceived())			-- broadcasts individual DKP award to DKP history table
	MonDKP.Sync:RegisterComm("MDKPMinBid", MonDKP.Sync:OnCommReceived())			-- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
	MonDKP.Sync:RegisterComm("MDKPWhitelist", MonDKP.Sync:OnCommReceived())		-- broadcasts whitelist
	MonDKP.Sync:RegisterComm("MDKPDKPModes", MonDKP.Sync:OnCommReceived())		-- broadcasts DKP Mode settings
	MonDKP.Sync:RegisterComm("MDKPStand", MonDKP.Sync:OnCommReceived())			-- broadcasts standby list
	MonDKP.Sync:RegisterComm("MDKPRaidTime", MonDKP.Sync:OnCommReceived())		-- broadcasts Raid Timer Commands
	MonDKP.Sync:RegisterComm("MDKPZeroSumBank", MonDKP.Sync:OnCommReceived())		-- broadcasts ZeroSum Bank
	MonDKP.Sync:RegisterComm("MDKPQuery", MonDKP.Sync:OnCommReceived())			-- Querys guild for spec/role data
	MonDKP.Sync:RegisterComm("MDKPBuild", MonDKP.Sync:OnCommReceived())			-- broadcasts Addon build number to inform others an update is available.
	MonDKP.Sync:RegisterComm("MDKPTalents", MonDKP.Sync:OnCommReceived())			-- broadcasts current spec
	MonDKP.Sync:RegisterComm("MDKPRoles", MonDKP.Sync:OnCommReceived())			-- broadcasts current role info
	MonDKP.Sync:RegisterComm("MDKPBossLoot", MonDKP.Sync:OnCommReceived())		-- broadcast current loot table
	MonDKP.Sync:RegisterComm("MDKPBidShare", MonDKP.Sync:OnCommReceived())		-- broadcast accepted bids
	MonDKP.Sync:RegisterComm("MDKPBidder", MonDKP.Sync:OnCommReceived())			-- Submit bids
	--MonDKP.Sync:RegisterComm("MonDKPEditLoot", MonDKP.Sync:OnCommReceived())		-- not in use
	--MonDKP.Sync:RegisterComm("MonDKPDataSync", MonDKP.Sync:OnCommReceived())		-- not in use
	--MonDKP.Sync:RegisterComm("MonDKPDKPLogSync", MonDKP.Sync:OnCommReceived())	-- not in use
	--MonDKP.Sync:RegisterComm("MonDKPLogSync", MonDKP.Sync:OnCommReceived())		-- not in use
end

function MonDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
	if not core.Initialized then return end
	if prefix == "MDKPMigrated" and not core.Migrated and core.IsOfficer then
		C_Timer.After(2, function()
			MonDKP:MigrationFrame()
		end)
	end
	if prefix and core.Migrated then
		print("|cffff0000Received: "..prefix.." from "..sender.."|r")
		if timer > 1 then timer = timer - 1 end 	-- Pushes back phase timer if a broadcast is received and timer is above 1. This is to determine when each phase of the sync is completed. (timer hits 3, nothing is being received)
		--------------- Start Sync Section
		if prefix == "MDKPSyncOff" then				-- syncs up all officers
			if MonDKP:ValidateSender(sender) and core.IsOfficer and sender ~= UnitName("player") then
				if SyncInProgress then return end
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					MonDKP.Sync:SendData("MDKPSyncReq", MonDKP_Meta)
					SyncInProgress = true
					for k1,v1 in pairs(deserialized) do
						for k2,v2 in pairs(v1) do 	-- creates meta fields for officer if they don't exist
							if not MonDKP_Meta_Remote[k1][k2] or deserialized[k1][k2].current > MonDKP_Meta_Remote[k1][k2] then
								MonDKP_Meta_Remote[k1][k2] = deserialized[k1][k2].current
							end
						end
					end
					for k,v in pairs(deserialized.DKP) do
						if MonDKP_Meta.DKP[k] and MonDKP_Meta.DKP[k].current then
							if MonDKP_Meta.DKP[k].current > deserialized.DKP[k].current then
								for i=deserialized.DKP[k].current+1, MonDKP_Meta.DKP[k].current do
									local search = MonDKP:Table_Search(MonDKP_DKPHistory, k.."-"..i, "index")
									
									if search then
										MonDKP.Sync:SendData("MDKPOffDKP", MonDKP_DKPHistory[search[1][1]], sender)  -- whisper to sending officer
										SyncMessage = true
									end
								end
							end
						else
							MonDKP_Meta.DKP[k] = { current=0, lowest=0 }
						end
					end
					for k,v in pairs(deserialized.Loot) do
						if MonDKP_Meta.Loot[k] and MonDKP_Meta.Loot[k].current then
							if MonDKP_Meta.Loot[k].current > deserialized.Loot[k].current then
								for i=deserialized.Loot[k].current+1, MonDKP_Meta.Loot[k].current do
									local search = MonDKP:Table_Search(MonDKP_Loot, k.."-"..i, "index")
									
									if search then
										MonDKP.Sync:SendData("MDKPOffLoot", MonDKP_Loot[search[1][1]], sender)       	-- whisper to sending officer
										SyncMessage = true
									end
								end
							end
						else
							MonDKP_Meta.Loot[k] = { current=0, lowest=0 }
						end
					end
					for k,v in pairs(MonDKP_Meta.Loot) do 				-- send MonDKP_Loot entries that don't exist in initiating officers tables
						if not deserialized.Loot[k] then
							for i=1, MonDKP_Meta.Loot[k].current do
								local search = MonDKP:Table_Search(MonDKP_Loot, k.."-"..i, "index")

								if search then
									MonDKP.Sync:SendData("MDKPOffLoot", MonDKP_Loot[search[1][1]], sender)       	-- whisper to sending officer
									SyncMessage = true
								end
							end
						end
					end
					for k,v in pairs(MonDKP_Meta.DKP) do 				-- send MonDKP_DKPHistory entries that don't exist in initiating officers tables
						if not deserialized.DKP[k] then
							for i=1, MonDKP_Meta.DKP[k].current do
								local search = MonDKP:Table_Search(MonDKP_DKPHistory, k.."-"..i, "index")

								if search then
									MonDKP.Sync:SendData("MDKPOffDKP", MonDKP_DKPHistory[search[1][1]], sender)       	-- whisper to sending officer
									SyncMessage = true
								end
							end
						end
					end
				end
				return
			end
		elseif prefix == "MDKPSyncInit" then  -- send to all to initiate/finialize sync requests
			if MonDKP:ValidateSender(sender) then
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					SyncInProgress = true
					if type(deserialized) == "table" and sender ~= UnitName("player") then
						for k1,v1 in pairs(deserialized) do
							for k2,v2 in pairs(v1) do 	-- creates meta fields for officer if they don't exist
								if not MonDKP_Meta[k1][k2] then
									MonDKP_Meta[k1][k2] = {lowest=0, current=0}
								end
								if not MonDKP_Meta_Remote[k1][k2] or deserialized[k1][k2].current > MonDKP_Meta_Remote[k1][k2] then
									MonDKP_Meta_Remote[k1][k2] = deserialized[k1][k2].current
								end
							end
						end
						MonDKP:StatusVerify_Update()
						MonDKP.Sync:SendData("MDKPSyncReq", MonDKP_Meta) -- sends meta table to determine what must be broadcasted
						if timer == 0 then
							MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
							MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
								timer = timer + elapsed
								if timer > 5 then
									MonDKP.SyncTimer:SetScript("OnUpdate", nil)
									timer = 0

									if FlagValidation then
										FlagValidation = false
										MonDKP:ValidateLootTable()
									end

									if core.IsOfficer and not InitiatingOfficer then
										local deleted = {}
										for k,v in pairs(MonDKP_Archive) do
											if MonDKP_Archive[k].deleted then
												table.insert(deleted, { player=k, deleted=v.deleted, edited=v.edited })
											end
										end

										if #deleted > 0 then
											MonDKP.Sync:SendData("MDKPDelUsers", deleted)
										end
									end

									if SyncMessage then
										MonDKP:Print(L["SYNCCOMPLETE"])
									end
									if #ProfileRequest > 0 then
										MonDKP.Sync:SendData("MDKPProfileReq", ProfileRequest)
										ProfileRequest = {}
									end
									SyncMessage = false
									SyncInProgress = false

									MonDKP:FilterDKPTable(core.currentSort, "reset")
									MonDKP.Sync:SendData("MDKPSyncReq", MonDKP_Meta) -- sends final meta for table verification
									-- end sync for all receiving players
								end
							end)
						end
					elseif deserialized == "end" then			-- requests errant entries (IE: have Roeshambo-10 and Roeshambo-12, missing Roeshambo-11)
						if #core.Errant > 0 and sender ~= UnitName("player") then
							MonDKP.Sync:SendData("MDKPErrantReq", core.Errant)
						else
							MonDKP:SortLootTable()
							MonDKP:LootHistory_Reset()
							MonDKP:LootHistory_Update(L["NOFILTER"]);
							MonDKP:FilterDKPTable(core.currentSort, "reset")
							if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
								MonDKP:DKPHistory_Update(true)
							end
						end
						MonDKP:StatusVerify_Update()
						SyncInProgress = false
					end
				end
			end
			return
		elseif prefix == "MDKPSyncReq" then  -- processes all meta tables broadcasted to determine who has what, what to send, and what is missing overall (displayed on sync button as missing entries)
			decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message)) 	-- no officer actions taken here. Only processing
			local success, deserialized = LibAceSerializer:Deserialize(decoded);
			if success then
				if timer > 1 then timer = timer - 2 end
				MetasReceived = MetasReceived + 1

				for k1,v1 in pairs(deserialized) do
				    for k2,v2 in pairs(v1) do
				    	if not MonDKP_Meta[k1][k2] then
				    		MonDKP_Meta[k1][k2] = { current=0, lowest=0 }
				    	end
				    	if not MonDKP_Meta_Remote[k1][k2] or deserialized[k1][k2].current > MonDKP_Meta_Remote[k1][k2] then -- updates highest known entry for each off. in Meta
				            MonDKP_Meta_Remote[k1][k2] = deserialized[k1][k2].current
				        end
				        if not Meta_Remote_Temp[k1][k2] or Meta_Remote_Temp[k1][k2] > deserialized[k1][k2].current then	-- updates temp meta with lowest known value
				        	Meta_Remote_Temp[k1][k2] = deserialized[k1][k2].current
				        end

				        if deserialized[k1][k2].current < MonDKP_Meta[k1][k2].lowest-1 and MonDKP_Meta[k1][k2].current > 1 and core.IsOfficer and InitiatingOfficer then  -- handles players that require full broadcast (with archive and meta)
				        	local archive = {}
				        	local flag = false
				        	print("FULL FLAG")
				            if timer > 1 then timer = timer - 10 end  -- adds 10sec to timer to accomodate a *possibly* long archive table
				            
				            for k1,v1 in pairs(MonDKP_Archive) do 		-- adds relevant archive values to table to send for full sync
								if v1.lifetime_gained > 0 or v1.lifetime_spent > 0 or v1.dkp > 0 then
									archive[k1] = v1;
									flag = true;
								end
							end

							if flag then
								MonDKP.Sync:SendData("MDKPArchive", archive, sender)
							end
							MonDKP.Sync:SendData("MDKPMetaFull", MonDKP_Archive_Meta, sender)

							for k1,v1 in pairs(Meta_Remote_Temp) do
								for k2,v2 in pairs(v1) do
									if MonDKP_Meta[k1][k2] then
										Meta_Remote_Temp[k1][k2] = MonDKP_Meta[k1][k2].lowest-1
									else
										Meta_Remote_Temp[k1][k2] = 0
									end
								end
							end
							return
							-- (done) send archive to sender (only let initiating officer do this! Everyone sees this method)
				            -- (done) flag for full update
				            -- (done) set all meta_remote_temp values to 0 and prompt to wipe tables
				            -- (done) if Archive has any entries with values above 0, send them 1by1 in whisper
				            -- (done) send meta table but only apply "lowest" for each officer. current will update on it's own when data is received.
							-- (done) push back timer by 5 seconds to compensate for the additional processing/sending
							-- (done) initiate full table validation after all is received
				        end
				    end
				end
				MonDKP:StatusVerify_Update()
			end
			return
		elseif prefix == "MDKPSyncDKP" or prefix == "MDKPSyncLoot" then 				-- insert entries received if they don't exist in local tables
			if sender ~= UnitName("player") and MonDKP:ValidateSender(sender) then
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					SyncInProgress = true
					if not MonDKP.SyncTimer and timer == 0 then
						MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
						MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
							timer = timer + elapsed
							if timer > 5 then
								MonDKP.SyncTimer:SetScript("OnUpdate", nil)
								timer = 0
								if SyncMessage then
									MonDKP:Print(L["SYNCCOMPLETE"])
								end
								SyncInProgress = false
								SyncMessage = false
							end
						end)
					end
					if prefix == "MDKPSyncDKP" then
						local search = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.index, "index")
						local officer, index = strsplit("-", deserialized.index)
						index = tonumber(index);

						if core.ArchiveActive and MonDKP_Archive_Meta.DKP[officer] and MonDKP_Archive_Meta.DKP[officer] >= index then return end -- ignores if this entry is already archived

						if not MonDKP_Meta.DKP[officer] then
							MonDKP_Meta.DKP[officer] = {current=0, lowest=0}
						end

						local rem_errant = MonDKP:Table_Search(core.Errant, "DKP,"..deserialized.index)

						if rem_errant then
							print(#core.Errant)
							table.remove(core.Errant, rem_errant[1])
						end

						if not search then
							local dkp
							local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
							SyncMessage = true

							if strfind(deserialized.dkp, "%-%d+%%") then
								dkp = {strsplit(",", deserialized.dkp)}
							end

							if deserialized.deletes then
								local search_del = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.deletes, "index")

								if search_del and not MonDKP_DKPHistory[search_del[1][1]].deletedby then
									MonDKP_DKPHistory[search_del[1][1]].deletedby = deserialized.index
								end
							end

							if not deserialized.deletedby then
								local search_del = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.index, "deletes")

								if search_del then
									deserialized.deletedby = MonDKP_DKPHistory[search_del[1][1]].index
								end
							end

							table.insert(MonDKP_DKPHistory, deserialized)

							for i=1, #players do
								if players[i] then
									local findEntry = MonDKP:Table_Search(MonDKP_DKPTable, players[i], "player")

									if strfind(deserialized.dkp, "%-%d+%%") then 		-- handles decay entries
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + tonumber(dkp[i])
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												TempProfile_Create(players[i], tonumber(dkp[i]))
											end
										end
									else
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + deserialized.dkp
											if (deserialized.dkp > 0 and not deserialized.deletes) or (deserialized.dkp < 0 and deserialized.deletes) then		-- adjust lifetime if it's a DKP gain or deleting a DKP gain 
												MonDKP_DKPTable[findEntry[1][1]].lifetime_gained = MonDKP_DKPTable[findEntry[1][1]].lifetime_gained + deserialized.dkp	-- NOT if it's a DKP penalty or deleteing a DKP penalty
											end
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												local class

												if (deserialized.dkp > 0 and not deserialized.deletes) or (deserialized.dkp < 0 and deserialized.deletes) then
													TempProfile_Create(players[i], deserialized.dkp, deserialized.dkp)
												else
													TempProfile_Create(players[i])
												end
											end
										end
									end
								end
							end

							if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
								MonDKP:DKPHistory_Update(true)
							end

							if not MonDKP_Meta.DKP[officer] then
								MonDKP_Meta.DKP[officer] = {current=0, lowest=0}
							end

							if MonDKP_Meta.DKP[officer].current < index then
								MonDKP_Meta.DKP[officer].current = index
							end

							if MonDKP_Meta.DKP[officer].lowest > index or MonDKP_Meta.DKP[officer].lowest == 0 then
								MonDKP_Meta.DKP[officer].lowest = index
							end
							MonDKP:StatusVerify_Update()
						end
					else
						local search = MonDKP:Table_Search(MonDKP_Loot, deserialized.index, "index")
						local officer, index = strsplit("-", deserialized.index)
						index = tonumber(index);

						if core.ArchiveActive and MonDKP_Archive_Meta.Loot[officer] and MonDKP_Archive_Meta.Loot[officer] >= index then return end -- ignores if this entry is already archived

						if not MonDKP_Meta.Loot[officer] then
							MonDKP_Meta.Loot[officer] = {current=0, lowest=0}
						end

						local rem_errant = MonDKP:Table_Search(core.Errant, "Loot,"..deserialized.index)

						if rem_errant then
							table.remove(core.Errant, rem_errant[1])
							print(#core.Errant)
						end

						if not search and index >= MonDKP_Meta.Loot[officer].lowest then
							local findEntry = MonDKP:Table_Search(MonDKP_DKPTable, deserialized.player, "player")

							SyncMessage = true

							if deserialized.deletes then
								local search_del = MonDKP:Table_Search(MonDKP_Loot, deserialized.deletes, "index")

								if search_del and not MonDKP_Loot[search_del[1][1]].deletedby then
									MonDKP_Loot[search_del[1][1]].deletedby = deserialized.index
								end
							end

							if not deserialized.deletedby then
								local search_del = MonDKP:Table_Search(MonDKP_Loot, deserialized.index, "deletes")

								if search_del then
									deserialized.deletedby = MonDKP_Loot[search_del[1][1]].index
								end
							end
							
							table.insert(MonDKP_Loot, deserialized)

							if findEntry then
								MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + deserialized.cost
								MonDKP_DKPTable[findEntry[1][1]].lifetime_spent = MonDKP_DKPTable[findEntry[1][1]].lifetime_spent + deserialized.cost
							else
								if not MonDKP_Archive[deserialized.player] or (MonDKP_Archive[deserialized.player] and MonDKP_Archive[deserialized.player].deleted ~= true) then
									TempProfile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost)
								end
							end

							if MonDKP.ConfigTab5 then
								MonDKP:SortLootTable()
								MonDKP:LootHistory_Reset()
								MonDKP:LootHistory_Update(L["NOFILTER"]);
							end

							if not MonDKP_Meta.Loot[officer] then
								MonDKP_Meta.Loot[officer] = {current=0, lowest=0}
							end

							if MonDKP_Meta.Loot[officer].current < index then
								MonDKP_Meta.Loot[officer].current = index
							end

							if MonDKP_Meta.Loot[officer].lowest > index or MonDKP_Meta.Loot[officer].lowest == 0 then
								MonDKP_Meta.Loot[officer].lowest = index
							end
							MonDKP:StatusVerify_Update()
						end
					end
				end
			end
			return
		elseif prefix == "MDKPOffDKP" or prefix == "MDKPOffLoot" then  		-- same as above, handling entries. But for officers only (pre sync officer request)
			if sender ~= UnitName("player") and core.IsOfficer and MonDKP:ValidateSender(sender) then
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					if not MonDKP.SyncTimer and timer == 0 then
						MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
						MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
							timer = timer + elapsed
							if timer > 5 then
								MonDKP.SyncTimer:SetScript("OnUpdate", nil)
								timer = 0
								if SyncMessage then
									MonDKP:Print(L["SYNCCOMPLETE"])
								end
								SyncInProgress = false
								SyncMessage = false
							end
						end)
					end
					if prefix == "MDKPOffDKP" then
						local search = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.index, "index")
						local officer, index = strsplit("-", deserialized.index)
						index = tonumber(index);

						if core.ArchiveActive and MonDKP_Archive_Meta.DKP[officer] and MonDKP_Archive_Meta.DKP[officer] >= index then return end -- ignores if this entry is already archived
 
						if not MonDKP_Meta.DKP[officer] then
							MonDKP_Meta.DKP[officer] = {current=0, lowest=0}
						end

						local rem_errant = MonDKP:Table_Search(core.Errant, "DKP,"..deserialized.index)

						if rem_errant then
							print(#core.Errant)
							table.remove(core.Errant, rem_errant[1])
						end

						if not search and index >= MonDKP_Meta.DKP[officer].lowest then
							local players = {strsplit(",", strsub(deserialized.players, 1, -2))}

							SyncMessage = true

							if strfind(deserialized.dkp, "%-%d+%%") then
								dkp = {strsplit(",", deserialized.dkp)}
							end

							if deserialized.deletes then  		-- adds deletedby field to entry if the received table is a delete entry
								local search_del = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.deletes, "index")

								if search_del then
									MonDKP_DKPHistory[search_del[1][1]].deletedby = deserialized.index
								end
							end
							
							if not deserialized.deletedby then
								local search_del = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.index, "deletes")

								if search_del then
									deserialized.deletedby = MonDKP_DKPHistory[search_del[1][1]].index
								end
							end

							table.insert(MonDKP_DKPHistory, deserialized)

							for i=1, #players do
								if players[i] then
									local findEntry = MonDKP:Table_Search(MonDKP_DKPTable, players[i], "player")

									if strfind(deserialized.dkp, "%-%d+%%") then 		-- handles decay entries
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + tonumber(dkp[i])
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												TempProfile_Create(players[i], tonumber(dkp[i]))
											end
										end
									else
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + deserialized.dkp
											if (deserialized.dkp > 0 and not deserialized.deletes) or (deserialized.dkp < 0 and deserialized.deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain 
												MonDKP_DKPTable[findEntry[1][1]].lifetime_gained = MonDKP_DKPTable[findEntry[1][1]].lifetime_gained + deserialized.dkp 	-- NOT if it's a DKP penalty or deleteing a DKP penalty
											end
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												local class

												if (deserialized.dkp > 0 and not deserialized.deletes) or (deserialized.dkp < 0 and deserialized.deletes) then
													TempProfile_Create(players[i], deserialized.dkp, deserialized.dkp)
												else
													TempProfile_Create(players[i])
												end
											end
										end
									end
								end
							end

							if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
								MonDKP:DKPHistory_Update(true)
							end

							if MonDKP_Meta.DKP[officer].current < index then
								MonDKP_Meta.DKP[officer].current = index
							end
							MonDKP:StatusVerify_Update()
						end
					else
						local search = MonDKP:Table_Search(MonDKP_Loot, deserialized.index, "index")
						local officer, index = strsplit("-", deserialized.index)
						index = tonumber(index);

						if core.ArchiveActive and MonDKP_Archive_Meta.Loot[officer] and MonDKP_Archive_Meta.Loot[officer] >= index then return end -- ignores if this entry is already archived

						if not MonDKP_Meta.Loot[officer] then
							MonDKP_Meta.Loot[officer] = {current=0, lowest=0}
						end

						local rem_errant = MonDKP:Table_Search(core.Errant, "Loot,"..deserialized.index)

						if rem_errant then
							print(#core.Errant)
							table.remove(core.Errant, rem_errant[1])
						end

						if not search and index >= MonDKP_Meta.Loot[officer].lowest then
							local findEntry = MonDKP:Table_Search(MonDKP_DKPTable, deserialized.player, "player")

							SyncMessage = true

							if deserialized.deletes then
								local search_del = MonDKP:Table_Search(MonDKP_Loot, deserialized.deletes, "index")

								if search_del and not MonDKP_Loot[search_del[1][1]].deletedby then
									MonDKP_Loot[search_del[1][1]].deletedby = deserialized.index
								end
							end

							if not deserialized.deletedby then
								local search_del = MonDKP:Table_Search(MonDKP_Loot, deserialized.index, "deletes")

								if search_del then
									deserialized.deletedby = MonDKP_Loot[search_del[1][1]].index
								end
							end

							table.insert(MonDKP_Loot, deserialized)

							if findEntry then
								MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + deserialized.cost
								MonDKP_DKPTable[findEntry[1][1]].lifetime_spent = MonDKP_DKPTable[findEntry[1][1]].lifetime_spent + deserialized.cost
							else
								if not MonDKP_Archive[deserialized.player] or (MonDKP_Archive[deserialized.player] and MonDKP_Archive[deserialized.player].deleted ~= true) then
									TempProfile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost)
								end
							end

							if MonDKP.ConfigTab5 then
								MonDKP:SortLootTable()
								MonDKP:LootHistory_Reset()
								MonDKP:LootHistory_Update(L["NOFILTER"]);
							end

							if MonDKP_Meta.Loot[officer].current < index then
								MonDKP_Meta.Loot[officer].current = index
							end

							if MonDKP_Meta.Loot[officer].lowest > index or MonDKP_Meta.Loot[officer].lowest == 0 then
								MonDKP_Meta.Loot[officer].lowest = index
							end
							MonDKP:StatusVerify_Update()
						end
					end
				end
			end
			return
		elseif prefix == "MDKPErrantReq" or prefix == "MDKPErrantOff" then  -- handles errant request between officers for pre sync (ensure all entries possible are received before broadcasting to guild)
			if core.IsOfficer and sender ~= UnitName("player") then
				if SyncInProgress and prefix == "MDKPErrantOff" then return end
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					SyncInProgress = true
					local i=1
					local timer = 0
					local processing = false
					
					local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
					ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
						timer = timer + elapsed
						if timer > 0.1 and i <= #deserialized and not processing then
							processing = true
							local loc, errant = strsplit(",", deserialized[i])

							if loc == "DKP" then
								local search = MonDKP:Table_Search(MonDKP_DKPHistory, errant, "index")

								if search then
									if prefix == "MDKPErrantReq" then
										MonDKP.Sync:SendData("MDKPSyncDKP", MonDKP_DKPHistory[search[1][1]])
									else
										MonDKP.Sync:SendData("MDKPSyncDKP", MonDKP_DKPHistory[search[1][1]], sender)  -- sends errant entries to officer requesting
									end
								end
							else
								local search = MonDKP:Table_Search(MonDKP_Loot, errant, "index")

								if search then
									if prefix == "MDKPErrantReq" then
										MonDKP.Sync:SendData("MDKPSyncLoot", MonDKP_Loot[search[1][1]])
									else
										MonDKP.Sync:SendData("MDKPSyncLoot", MonDKP_Loot[search[1][1]], sender)  -- sends errant entries to officer requesting
									end
								end
							end
							processing = false
							i=i+1
							timer = 0
						elseif i > #deserialized then
							ValidateTimer:SetScript("OnUpdate", nil)
							timer = 0
						end
					end)
				end
			end
			return;
		elseif (prefix == "MDKPArchive" or prefix == "MDKPMetaFull") and sender ~= UnitName("player") then
			if MonDKP:ValidateSender(sender) then
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					if timer > 1 then timer = timer - 5 end

					if prefix == "MDKPArchive" then
						MonDKP_Archive = nil
						MonDKP_Loot = nil
						MonDKP_DKPHistory = nil
						MonDKP_DKPTable = nil
						MonDKP_Standby = nil

						MonDKP_Archive = {}
						MonDKP_Loot = {}
						MonDKP_DKPHistory = {}
						MonDKP_DKPTable = {}
						MonDKP_Standby = {}

						MonDKP_Archive = deserialized
						FlagValidation = true
					else
						MonDKP_Archive_Meta = deserialized;
						core.ArchiveActive = true
					end
				end
			end
			return
		elseif prefix == "MDKPProfileReq" and sender ~= UnitName("player") then  -- sends player profile
			if core.IsOfficer then
				decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					local i=1
					local timer = 0
					
					local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
					ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
						timer = timer + elapsed
						if timer > 0.3 and i <= #deserialized then
							PlayerProfile_Send(deserialized[i])
							i=i+1
							timer = 0
						elseif i > #deserialized then
							ValidateTimer:SetScript("OnUpdate", nil)
							timer = 0
						end
					end)
				end
			end
			return
		elseif prefix == "MDKPReqSync" then
			MonDKP:SyncOfficers()
			return
		elseif prefix == "MDKPTableComp" then
			MonDKP.Sync:SendData("MDKPSyncReq", MonDKP_Meta) -- officers offline, share meta tables to determine if anyone is out of date. No actions taken
			return
		--------------- end sync section
		elseif prefix == "MDKPQuery" then
			-- talents check
			local TalTrees={}; table.insert(TalTrees, {GetTalentTabInfo(1)}); table.insert(TalTrees, {GetTalentTabInfo(2)}); table.insert(TalTrees, {GetTalentTabInfo(3)}); 
			local talBuild = "("..TalTrees[1][3].."/"..TalTrees[2][3].."/"..TalTrees[3][3]..")"
			local talRole;

			table.sort(TalTrees, function(a, b)
				return a[3] > b[3]
			end)
			
			talBuild = TalTrees[1][1].." "..talBuild;
			talRole = TalTrees[1][4];
			
			MonDKP.Sync:SendData("MDKPTalents", talBuild)
			MonDKP.Sync:SendData("MDKPRoles", talRole)

			table.wipe(TalTrees);
			return;
		elseif prefix == "MDKPBidder" then
			if core.BidInProgress and core.IsOfficer then
				MonDKP_CHAT_MSG_WHISPER(message, sender)
				return
			else
				return
			end
		elseif prefix == "MDKPTalents" then
			local search = MonDKP:Table_Search(MonDKP_DKPTable, sender, "player")

			if search then
				local curSelection = MonDKP_DKPTable[search[1][1]]
				curSelection.spec = message;
			end
			return
		elseif prefix == "MDKPRoles" then
			local search = MonDKP:Table_Search(MonDKP_DKPTable, sender, "player")
			local curClass = "None";

			if search then
				local curSelection = MonDKP_DKPTable[search[1][1]]
				curClass = MonDKP_DKPTable[search[1][1]].class
			
				if curClass == "WARRIOR" then
					if strfind(message, "Protection") then
						curSelection.role = L["TANK"]
					else
						curSelection.role = L["MELEEDPS"]
					end
				elseif curClass == "PALADIN" then
					if strfind(message, "Protection") then
						curSelection.role = L["TANK"]
					elseif strfind(message, "Holy") then
						curSelection.role = L["HEALER"]
					else
						curSelection.role = L["MELEEDPS"]
					end
				elseif curClass == "HUNTER" then
					curSelection.role = L["RANGEDPS"]
				elseif curClass == "ROGUE" then
					curSelection.role = L["MELEEDPS"]
				elseif curClass == "PRIEST" then
					if strfind(message, "Shadow") then
						curSelection.role = L["CASTERDPS"]
					else
						curSelection.role = L["HEALER"]
					end
				elseif curClass == "SHAMAN" then
					if strfind(message, "Restoration") then
						curSelection.role = L["HEALER"]
					elseif strfind(message, "Elemental") then
						curSelection.role = L["CASTERDPS"]
					else
						curSelection.role = L["MELEEDPS"]
					end
				elseif curClass == "MAGE" then
					curSelection.role = L["CASTERDPS"]
				elseif curClass == "WARLOCK" then
					curSelection.role = L["CASTERDPS"]
				elseif curClass == "DRUID" then
					if strfind(message, "Feral") then
						curSelection.role = L["TANK"]
					elseif strfind(message, "Balance") then
						curSelection.role = L["CASTERDPS"]
					else
						curSelection.role = L["HEALER"]
					end
				else
					curSelection.role = L["NOROLEDETECTED"]
				end
			end
			return;
		elseif prefix == "MDKPBuild" and sender ~= UnitName("player") then
			local LastVerCheck = time() - core.LastVerCheck;

			if LastVerCheck > 900 then   					-- limits the Out of Date message from firing more than every 15 minutes 
				if tonumber(message) > core.BuildNumber then
					core.LastVerCheck = time();
					MonDKP:Print(L["OUTOFDATEANNOUNCE"])
				end
			end

			if tonumber(message) < core.BuildNumber then 	-- returns build number if receiving party has a newer version
				MonDKP.Sync:SendData("MDKPBuild", tostring(core.BuildNumber))
			end
			return;
		end
		if MonDKP:ValidateSender(sender) then		-- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
			if (prefix == "MDKPBCastMsg") and sender ~= UnitName("player") then
				MonDKP:Print(message)
			elseif (prefix == "MDKPCommand") then
				local command, arg1, arg2, arg3 = strsplit(",", message);
				if sender ~= UnitName("player") then
					if command == "StartTimer" then
						MonDKP:StartTimer(arg1, arg2)
					elseif command == "StartBidTimer" then
						MonDKP:StartBidTimer(arg1, arg2, arg3)
						core.BiddingInProgress = true;
						if strfind(arg1, "{") then
							MonDKP:Print("Bid timer extended by "..tonumber(strsub(arg1, strfind(arg1, "{")+1)).." seconds.")
						end
					elseif command == "StopBidTimer" then
						if MonDKP.BidTimer then
							MonDKP.BidTimer:SetScript("OnUpdate", nil)
							MonDKP.BidTimer:Hide()
							core.BiddingInProgress = false;
						end
					elseif command == "BidInfo" then
						if not core.BidInterface then
							core.BidInterface = core.BidInterface or MonDKP:BidInterface_Create()	-- initiates bid window if it hasn't been created
						end
						if MonDKP_DB.defaults.AutoOpenBid then	-- toggles bid window if option is set to
							MonDKP:BidInterface_Toggle()
						end
						MonDKP:CurrItem_Set(arg1, arg2, arg3, sender)	-- populates bid window
					end
				end
			elseif prefix == "MDKPBidShare" then
				if core.BidInterface then
					MonDKP:Bids_Set(deserialized)
					return
				end
			elseif prefix == "MDKPRaidTime" and sender ~= UnitName("player") and core.IsOfficer and MonDKP.ConfigTab2 then
				local command, args = strsplit(",", message);
				if command == "start" then
					local arg1, arg2, arg3, arg4, arg5, arg6 = strsplit(" ", args, 6)

					if arg1 == "true" then arg1 = true else arg1 = false end
					if arg4 == "true" then arg4 = true else arg4 = false end
					if arg5 == "true" then arg5 = true else arg5 = false end
					if arg6 == "true" then arg6 = true else arg6 = false end

					if arg2 ~= nil then
						MonDKP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(arg2));
						MonDKP_DB.modes.increment = tonumber(arg2);
					end
					if arg3 ~= nil then
						MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(arg3));
						MonDKP_DB.DKPBonus.IntervalBonus = tonumber(arg3);
					end
					if arg4 ~= nil then
						MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(arg4);
						MonDKP_DB.DKPBonus.GiveRaidStart = arg4;
					end
					if arg5 ~= nil then
						MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(arg5);
						MonDKP_DB.DKPBonus.GiveRaidEnd = arg5;
					end
					if arg6 ~= nil then
						MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(arg6);
						MonDKP_DB.DKPBonus.IncStandby = arg6;
					end

					MonDKP:StartRaidTimer(arg1)
				elseif command == "stop" then
					MonDKP:StopRaidTimer()
				elseif strfind(command, "sync", 1) then
					local _, syncTimer, syncSecondCount, syncMinuteCount, syncAward = strsplit(" ", command, 5)
					MonDKP:StartRaidTimer(nil, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
					core.RaidInProgress = true
				end
			end
			if (sender ~= UnitName("player")) then
				if prefix == "MDKPLootDist" or prefix == "MDKPDKPDist" or prefix == "MDKPDelLoot" or prefix == "MDKPDelSync" or prefix == "MDKPMinBid" or prefix == "MDKPWhitelist"
				or prefix == "MDKPDKPModes" or prefix == "MDKPStand" or prefix == "MDKPZeroSumBank" or prefix == "MDKPBossLoot" or prefix == "MDKPProfile"
				or prefix == "MDKPDecay" or prefix == "MDKPDelUsers" then
					decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
					local success, deserialized = LibAceSerializer:Deserialize(decoded);
					if success then
						if prefix == "MDKPLootDist" then
							local search = MonDKP:Table_Search(MonDKP_DKPTable, deserialized.player, "player")
							if search then
								local DKPTable = MonDKP_DKPTable[search[1][1]]
								DKPTable.dkp = DKPTable.dkp + deserialized.cost
								DKPTable.lifetime_spent = DKPTable.lifetime_spent + deserialized.cost
							else
								if not MonDKP_Archive[deserialized.player] or (MonDKP_Archive[deserialized.player] and MonDKP_Archive[deserialized.player].deleted ~= true) then
									TempProfile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);
								end
							end
							tinsert(MonDKP_Loot, 1, deserialized)

							MonDKP:CurrentIndex_Set("Loot", deserialized.index)
							MonDKP:LootHistory_Reset()
							MonDKP:LootHistory_Update(L["NOFILTER"])
							MonDKP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "MDKPProfile" then  		-- receives profile data sent from officers
							local search;

							while not search do 	-- loops until the temporary profile is completed to apply data
								search = MonDKP:Table_Search(MonDKP_DKPTable, deserialized.player, "player")
								MonDKP:ClassGraph_Update()
							end

							if search then
								MonDKP_DKPTable[search[1][1]].class = deserialized.class
							end
							MonDKP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "MDKPDKPDist" then
							local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
							local dkp = deserialized.dkp

							tinsert(MonDKP_DKPHistory, 1, deserialized)

							for i=1, #players do
								local search = MonDKP:Table_Search(MonDKP_DKPTable, players[i], "player")

								if search then
									MonDKP_DKPTable[search[1][1]].dkp = MonDKP_DKPTable[search[1][1]].dkp + tonumber(dkp)
									if tonumber(dkp) > 0 then
										MonDKP_DKPTable[search[1][1]].lifetime_gained = MonDKP_DKPTable[search[1][1]].lifetime_gained + tonumber(dkp)
									end
								else
									if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
										TempProfile_Create(players[i], tonumber(dkp));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
									end
								end
							end

							MonDKP:CurrentIndex_Set("DKP", deserialized.index)

							if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
								MonDKP:DKPHistory_Update(true)
							end
							MonDKP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "MDKPDecay" then
							local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
							local dkp = {strsplit(",", deserialized.dkp)}

							tinsert(MonDKP_DKPHistory, 1, deserialized)
							
							for i=1, #players do
								local search = MonDKP:Table_Search(MonDKP_DKPTable, players[i], "player")

								if search then
									MonDKP_DKPTable[search[1][1]].dkp = MonDKP_DKPTable[search[1][1]].dkp + tonumber(dkp[i])
								else
									if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
										TempProfile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
									end
								end
							end

							MonDKP:CurrentIndex_Set("DKP", deserialized.index)

							if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
								MonDKP:DKPHistory_Update(true)
							end
							MonDKP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "MDKPDelUsers" then
							local numPlayers = 0
							local removedUsers = ""

							for i=1, #deserialized do
								local search = MonDKP:Table_Search(MonDKP_DKPTable, deserialized[i].player, "player")

								if search and deserialized[i].deleted and deserialized[i].deleted ~= "Recovered" then
									if (MonDKP_Archive[deserialized[i].player] and MonDKP_Archive[deserialized[i].player].edited < deserialized[i].edited) or not MonDKP_Archive[deserialized[i].player] then
										--delete user, archive data
										if not MonDKP_Archive[deserialized[i].player] then		-- creates/adds to archive entry for user
											MonDKP_Archive[deserialized[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=deserialized[i].deleted, edited=deserialized[i].edited }
										else
											MonDKP_Archive[deserialized[i].player].deleted = deserialized[i].deleted
											MonDKP_Archive[deserialized[i].player].edited = deserialized[i].edited
										end
										
										c = MonDKP:GetCColors(MonDKP_DKPTable[search[1][1]].class)
										if i==1 then
											removedUsers = "|cff"..c.hex..MonDKP_DKPTable[search[1][1]].player.."|r"
										else
											removedUsers = removedUsers..", |cff"..c.hex..MonDKP_DKPTable[search[1][1]].player.."|r"
										end
										numPlayers = numPlayers + 1

										tremove(MonDKP_DKPTable, search[1][1])

										local search2 = MonDKP:Table_Search(MonDKP_Standby, deserialized[i].player, "player");

										if search2 then
											table.remove(MonDKP_Standby, search2[1][1])
										end
									end
								elseif not search and deserialized[i].deleted == "Recovered" then
									if MonDKP_Archive[deserialized[i].player] and MonDKP_Archive[deserialized[i].player].edited < deserialized[i].edited then
										TempProfile_Create(deserialized[i].player);	-- User was recovered, create/request profile as needed
										MonDKP_Archive[deserialized[i].player].deleted = "Recovered"
										MonDKP_Archive[deserialized[i].player].edited = deserialized[i].edited
									end
								end
							end
							if numPlayers > 0 then
								MonDKP:FilterDKPTable(core.currentSort, "reset")
								MonDKP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
								MonDKP:ClassGraph_Update()
							end
							return
						elseif prefix == "MDKPDelLoot" then
							local search = MonDKP:Table_Search(MonDKP_Loot, deserialized.deletes, "index")

							if search then
								MonDKP_Loot[search[1][1]].deletedby = deserialized.index
							end

							local search_player = MonDKP:Table_Search(MonDKP_DKPTable, deserialized.player, "player")

							if search_player then
								MonDKP_DKPTable[search_player[1][1]].dkp = MonDKP_DKPTable[search_player[1][1]].dkp + deserialized.cost 			 					-- refund previous looter
								MonDKP_DKPTable[search_player[1][1]].lifetime_spent = MonDKP_DKPTable[search_player[1][1]].lifetime_spent + deserialized.cost 			-- remove from lifetime_spent
							else
								if not MonDKP_Archive[deserialized.player] or (MonDKP_Archive[deserialized.player] and MonDKP_Archive[deserialized.player].deleted ~= true) then
									TempProfile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
								end
							end

							table.insert(MonDKP_Loot, 1, deserialized)							
							MonDKP:CurrentIndex_Set("Loot", deserialized.index)
							MonDKP:SortLootTable()
							MonDKP:LootHistory_Reset()
							MonDKP:LootHistory_Update(L["NOFILTER"]);
							MonDKP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "MDKPDelSync" then
							local search = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.deletes, "index")
							local players = {strsplit(",", strsub(deserialized.players, 1, -2))} 	-- cuts off last "," from string to avoid creating an empty value
							local dkp, mod;

							if strfind(deserialized.dkp, "%-%d+%%") then 		-- determines if it's a mass decay
								dkp = {strsplit(",", deserialized.dkp)}
								mod = "perc";
							else
								dkp = deserialized.dkp
								mod = "whole"
							end

							for i=1, #players do
								if mod == "perc" then
									local search2 = MonDKP:Table_Search(MonDKP_DKPTable, players[i], "player")

									if search2 then
										MonDKP_DKPTable[search2[1][1]].dkp = MonDKP_DKPTable[search2[1][1]].dkp + tonumber(dkp[i])
									else
										if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
											TempProfile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
										end
									end
								else
									local search2 = MonDKP:Table_Search(MonDKP_DKPTable, players[i], "player")

									if search2 then
										MonDKP_DKPTable[search2[1][1]].dkp = MonDKP_DKPTable[search2[1][1]].dkp + tonumber(dkp)

										if tonumber(dkp) < 0 then
											MonDKP_DKPTable[search2[1][1]].lifetime_gained = MonDKP_DKPTable[search2[1][1]].lifetime_gained + tonumber(dkp)
										end
									else
										if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
											local gained;
											if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end

											TempProfile_Create(players[i], tonumber(dkp), gained);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
										end
									end
								end
							end

							if search then
								MonDKP_DKPHistory[search[1][1]].deletedby = deserialized.index;  	-- adds deletedby field if the entry exists
							end

							table.insert(MonDKP_DKPHistory, 1, deserialized)

							MonDKP:CurrentIndex_Set("DKP", deserialized.index)

							if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history then
								MonDKP:DKPHistory_Update(true)
							end
							DKPTable_Update()
						elseif prefix == "MDKPMinBid" then
							if core.IsOfficer then
								MonDKP_DB.MinBidBySlot = deserialized[1]

								for i=1, #deserialized[2] do
									local search = MonDKP:Table_Search(MonDKP_MinBids, deserialized[2][i].item)
									if search then
										MonDKP_MinBids[search[1][1]].minbid = deserialized[2][i].minbid
									else
										table.insert(MonDKP_MinBids, deserialized[2][i])
									end
								end
							end
						elseif prefix == "MDKPWhitelist" then
							MonDKP_Whitelist = deserialized;
						elseif prefix == "MDKPStand" then
							MonDKP_Standby = deserialized;
						elseif prefix == "MDKPZeroSumBank" then
							if core.IsOfficer then
								MonDKP_DB.modes.ZeroSumBank = deserialized;
								if core.ZeroSumBank then
									MonDKP:ZeroSumBank_Update()
								end
							end
						elseif prefix == "MDKPDKPModes" then
							MonDKP_DB.modes = deserialized[1]
							MonDKP_DB.DKPBonus = deserialized[2]
							MonDKP_DB.raiders = deserialized[3]
						elseif prefix == "MDKPBossLoot" then
							local lootList = {};
							MonDKP_DB.bossargs.LastKilledBoss = deserialized.boss;
						
							for i=1, #deserialized do
								local item = Item:CreateFromItemLink(deserialized[i]);
								item:ContinueOnItemLoad(function()
									local icon = item:GetItemIcon()
									table.insert(lootList, {icon=icon, link=item:GetItemLink()})
								end);
							end

							MonDKP:LootTable_Set(lootList)
						end
					else
						MonDKP:Print("Report the following error on Curse or Github: "..deserialized)  -- error reporting if string doesn't get deserialized correctly
					end
				end
			end
		else
			MonDKP:CheckOfficer()
			if core.IsOfficer == true and UnitName("player") ~= sender then
				local msg;

				if #MonDKP_Whitelist > 0 then
					msg = sender..", "..L["UNAUTHUPDATE1"];
				else
					msg = sender..", "..L["UNAUTHUPDATE2"];
				end
				MonDKP:Print(msg..": "..prefix)
				StaticPopupDialogs["MODIFY_WARNING"] = {
					text = msg,
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("MODIFY_WARNING")
			end
		end
	end
end

function MonDKP.Sync:SendData(prefix, data, target)
	print("|cff00ff00Sent: "..prefix.."|r")
	if IsInGuild() then
		if prefix == "MDKPQuery" or prefix == "MDKPBuild" or prefix == "MDKPTableComp" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		elseif prefix == "MDKPTalents" or prefix == "MDKPRoles" or prefix == "MDKPMigrated" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		elseif prefix == "MDKPBidder" then		-- bid submissions. Keep to raid.
			MonDKP.Sync:SendCommMessage(prefix, data, "RAID")
			return;
		elseif prefix == "MDKPReqSync" then
			MonDKP.Sync:SendCommMessage(prefix, data, "WHISPER", target)
			return
		end
	end
	if IsInGuild() and (core.IsOfficer or prefix == "MDKPSyncReq" or prefix == "MDKPErrantReq" or prefix == "MDKPProfileReq") then
		local serialized = nil;
		local packet = nil;

		if prefix == "MDKPCommand" or prefix == "MDKPRaidTime" then
			MonDKP.Sync:SendCommMessage(prefix, data, "RAID")
			return;
		end

		if prefix == "MDKPBCastMsg" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		end	

		if data then
			serialized = LibAceSerializer:Serialize(data);	-- serializes tables to a string
		end

		local huffmanCompressed = LibCompress:CompressHuffman(serialized);
		if huffmanCompressed then
			packet = LibCompressAddonEncodeTable:Encode(huffmanCompressed);
		end

		-- send packet
		if (prefix == "MDKPZeroSumBank" or prefix == "MDKPBossLoot" or prefix == "MDKPBidShare") then		-- Zero Sum bank/loot table/bid table data and bid submissions. Keep to raid.
			MonDKP.Sync:SendCommMessage(prefix, packet, "RAID")
			return;
		end
		
		if prefix == "MonDKPAOffDKP" or prefix == "MDKPOffLoot" or ((prefix == "MDKPSyncDKP" or prefix == "MDKPSyncLoot" or prefix == "MDKPMetaFull" or prefix == "MDKPArchive") and target) then
			MonDKP.Sync:SendCommMessage(prefix, packet, "WHISPER", target)
			return
		end

		MonDKP.Sync:SendCommMessage(prefix, packet, "GUILD")
	end
end