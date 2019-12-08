--[[
	Usage so far:  MonDKP.Sync:SendData(prefix, core.WorkingTable)  --sends table through comm channel for updates
--]]	

local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

MonDKP.Sync = LibStub("AceAddon-3.0"):NewAddon("MonDKP", "AceComm-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
--local LibCompress = LibStub:GetLibrary("LibCompress")
--local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local Meta_Remote_Temp = { DKP={}, Loot={} } 		-- temp table storing what entries are required to be sent for sync (lowest received "current" value of every player)
local SyncTimer = 0 								-- counter to move phases of sync
local MetasReceived = 0 							-- count of metas received for sync
local SyncInProgress = false 						-- blocks additional sync requests when one is underway
local SyncMessage = false 							-- flags sync message if additional entries are required
local InitiatingOfficer = false 					-- flags officer if they are initiating a sync
local FlagValidation = false 						-- flags player if receiving a full sync. Will require validation run
local Errant = {}									-- list of errant entries required by players. Stored by initiating officer
local OfficerErrant = {}							-- stores errant request between officers for processing (clears if they are not selected to send)
local OfficerErrantCount = {}						-- stores officer with highest errant count (to select for request)
local OfficerSync = {}								-- stores officer with highets number of entries available beyond local officer. Submit request to them.
local OfficerTempMeta = {}							-- temporarily stores syncing officers meta until they decide which officer should update them
local RecentlySynced = false 						-- flags player as recently synced. blocks meta requests until 60 second timer expires to prevent flooding
local OnlineOfficers = {} 							-- stores list of Online officers
local FirstSyncReady = false 						-- Flags a player ready to receive first time sync. Prevents player from receiving if logging in mid sync. Allows "Full Sync" flag in case archive is needed
local SyncingPlayers = {}							-- Stores names for display of who is receiving a sync

function MonDKP_SyncInProgress_Get()
	return SyncInProgress
end

function MonDKP_SyncingPlayers_Get()
	return SyncingPlayers
end

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

	table.insert(MonDKP_DKPTable, {player=player, lifetime_spent=spent, lifetime_gained=gained, class=class, dkp=dkp, rank=10, spec=L["NOSPECREPORTED"], role=L["NOROLEDETECTED"], rankName="None", previous_dkp=0 })

	MonDKP:FilterDKPTable(core.currentSort, "reset")
	MonDKP:ClassGraph_Update()
end

local function RequestErrant()
	local i=1
	local timer = 0

	local ErrantTimer = ErrantTimer or CreateFrame("StatusBar", nil, UIParent)
	ErrantTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.3 and i <= #MonDKP_Errant then
			MonDKP.Sync:SendData("MDKPErrantReq", MonDKP_Errant[i]) 
			i=i+1
			timer = 0
		elseif i > #MonDKP_Errant then
			ErrantTimer:SetScript("OnUpdate", nil)
		end
	end)
end

local function PlayerProfiles_Send()
	local i=1
	local timer = 0
	local ProfTimer = ProfTimer or CreateFrame("StatusBar", nil, UIParent)
	ProfTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.2 and i <= #MonDKP_DKPTable then
			local info = { player=MonDKP_DKPTable[i].player, class=MonDKP_DKPTable[i].class }
			MonDKP.Sync:SendData("MDKPProfile", info)
			i=i+1
			timer = 0
		elseif i > #MonDKP_DKPTable then
			ProfTimer:SetScript("OnUpdate", nil)
		end
	end)
end

local function SyncDeleted()
	local deleted = {}

	for k,v in pairs(MonDKP_Archive) do
		if MonDKP_Archive[k].deleted then
			table.insert(deleted, { player=k, deleted=v.deleted, edited=v.edited })
		end
	end

	PlayerProfiles_Send()

	if #deleted > 0 then
		MonDKP.Sync:SendData("MDKPDelUsers", deleted)
	end

	MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
	MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
		SyncTimer = SyncTimer + elapsed
		if SyncTimer > 3 then
			MonDKP.SyncTimer:SetScript("OnUpdate", nil)
			SyncTimer = 0
			
			if SyncMessage then
				if MetasReceived == 0 then
					MonDKP:Print(L["SYNCCOMPLETE2"])
				else
					MonDKP:Print(L["SYNCCOMPLETE"])
					MonDKP:ErrantCheck()
				end
			end

			SyncMessage = false
			SyncInProgress = false
			InitiatingOfficer = false
			MetasReceived = 0

			Meta_Remote_Temp = { DKP={}, Loot={} }
			FlagValidation = false
			Errant = {}
			OfficerErrant = {}
			OfficerErrantCount = {}
			OfficerSync = {}
			OfficerTempMeta = {}
			RecentlySynced = false
			OnlineOfficers = {}
			SyncingPlayers = {}
			collectgarbage("collect")

			MonDKP.Sync:SendData("MDKPSyncFlag", "End") 			-- flags all receiving players as "In Progress" to prevent additional sync attempts
			-- end sync for sending officer
		end
	end)
end

local function SyncFinalize()
	MonDKP.Sync:SendData("MDKPSyncInit", "end")
	MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
	MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
		SyncTimer = SyncTimer + elapsed
		if SyncTimer > 5 then
			MonDKP.SyncTimer:SetScript("OnUpdate", nil)
			SyncTimer = 0
			
			if #Errant > 0 then
				local i=1
				local timer = 0
				local processing = false
				
				local ErrantTimer = ErrantTimer or CreateFrame("StatusBar", nil, UIParent)
				ErrantTimer:SetScript("OnUpdate", function(self, elapsed)
					timer = timer + elapsed
					if timer > 0.3 and i <= #Errant and not processing then
						processing = true
						local loc, index = strsplit(",", Errant[i])

						if loc == "DKP" then
							local search = MonDKP:Table_Search(MonDKP_DKPHistory, index, "index")

							if search then
								MonDKP.Sync:SendData("MDKPSyncDKP", MonDKP_DKPHistory[search[1][1]])
							end
						else
							local search = MonDKP:Table_Search(MonDKP_Loot, index, "index")

							if search then
								MonDKP.Sync:SendData("MDKPSyncLoot", MonDKP_Loot[search[1][1]])
							end
						end
						processing = false
						i=i+1
						timer = 0
					elseif i > #Errant and timer > 3 then
						ErrantTimer:SetScript("OnUpdate", nil)
						Errant = {}
						SyncDeleted()
					end
				end)
			else
				SyncDeleted()
			end
		end
	end)
end

local InitTimer = InitTimer or CreateFrame("StatusBar", nil, UIParent)

local function SyncInit()
	local InitTimerElapsed = 0
	local InitCount = 1
	--local _,_,NumOnline = GetNumGuildMembers()
	local OnlinePlayers = {}

	Meta_Remote_Temp = { DKP={}, Loot={} }

	for k1,v1 in pairs(MonDKP_Meta) do 	-- starts all values in temp table @ local "current". this value is lowered in "MDKPSyncReq" prefix handler if someone's "current" is lower than local "current"
		for k2,v2 in pairs(v1) do
			Meta_Remote_Temp[k1][k2] = MonDKP_Meta[k1][k2].current
		end	
	end

	for i=1, GetNumGuildMembers() do
		local name,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
		if online then
			name = strsub(name, 1, string.find(name, "-")-1)
			table.insert(OnlinePlayers, name)
		end
	end

	InitTimer = InitTimer or CreateFrame("StatusBar", nil, UIParent)
	InitTimer:SetScript("OnUpdate", function(self, elapsed) 				-- sending one at a time to throttle chat traffic and the possibility of having to process dozens of Metas simultaneously
		InitTimerElapsed = InitTimerElapsed + elapsed
		if InitTimerElapsed > 0.3 and InitCount <= #OnlinePlayers then
			if OnlinePlayers[InitCount] ~= UnitName("player") then
				MonDKP.Sync:SendData("MDKPSyncInit", MonDKP_Meta, OnlinePlayers[InitCount])			-- request tables from players to determine what to send
			end
			SyncTimer = 0
			InitCount = InitCount + 1
			InitTimerElapsed = 0
		elseif InitCount > #OnlinePlayers then
			InitTimer:SetScript("OnUpdate", nil)
			InitTimerElapsed = 0
			InitCount = 1
			OnlinePlayers = nil
		end
	end)

	MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
	MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
		SyncTimer = SyncTimer + elapsed
		if SyncTimer > 7 then
			MonDKP.SyncTimer:SetScript("OnUpdate", nil)
			SyncTimer = 0
			MonDKP:StatusVerify_Update()

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
							if timer > 0.3 and i <= MonDKP_Meta[k1][k2].current and not processing then
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
			MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
			MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
				SyncTimer = SyncTimer + elapsed
				if SyncTimer > 3 then
					MonDKP.SyncTimer:SetScript("OnUpdate", nil)
					SyncTimer = 0
				    SyncFinalize()
				end
			end)
		end
	end)
end

local function SyncOffMeta()
	MonDKP.Sync:SendData("MDKPSyncOff", MonDKP_Meta)
	MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent) 		-- 3 second timer, pushed back 1 second if timer is above 1 and a broadcast is received
	MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)						-- every time the timer reaches 3 seconds it resets to 0 and kicks off the next Sync phase
		SyncTimer = SyncTimer + elapsed
		if SyncTimer > 3 then
			MonDKP.SyncTimer:SetScript("OnUpdate", nil)
			SyncTimer = 0

			if OfficerSync.count then
				MonDKP.Sync:SendData("MDKPSyncOff", OfficerSync.officer)
			end
			MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
			MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)				
				SyncTimer = SyncTimer + elapsed
				if SyncTimer > 5 then
					MonDKP.SyncTimer:SetScript("OnUpdate", nil)
					SyncTimer = 0
					SyncInit()
					MonDKP:StatusVerify_Update()
				end
			end)
		end
	end)
end

local function SyncOffErrant()
	if #MonDKP_Errant > 0 then
		local MaxTime = 5
		if #MonDKP_Errant > 200 then MaxTime = MaxTime + ((#MonDKP_Errant/100) * 2) end
		MonDKP.Sync:SendData("MDKPErrantOff", MonDKP_Errant)
		MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent) 		-- 5 second timer, pushed back 1 second if timer is above 1 and a broadcast is received
		MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)						-- every time the timer reaches 3 seconds it resets to 0 and kicks off the next Sync phase
			SyncTimer = SyncTimer + elapsed
			if SyncTimer > MaxTime  then
				MonDKP.SyncTimer:SetScript("OnUpdate", nil)
				SyncTimer = 0

				if OfficerErrantCount.officer then
					MonDKP.Sync:SendData("MDKPErrantOff", OfficerErrantCount.officer)
				end
				MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
				MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
					SyncTimer = SyncTimer + elapsed
					if SyncTimer > 5 then
						MonDKP.SyncTimer:SetScript("OnUpdate", nil)
						SyncTimer = 0
						SyncOffMeta()
					end
				end)
			end
		end)
	else
		SyncOffMeta()
	end
end

function MonDKP:SyncOfficers()
	if not core.Migrated or SyncInProgress then return end
	MonDKP.Sync:SendData("MDKPSyncFlag", "Start") 			-- flags all receiving players as "In Progress" to prevent additional sync attempts

	SyncInProgress = true
	InitiatingOfficer = true
	MetasReceived = 0
	
	SyncOffErrant()
end

function MonDKP:RequestSync(init)
	if SyncInProgress then
		if not init then MonDKP:Print(L["SYNCALREADY"]) end
		return
	elseif not init then
		MonDKP:Print(L["BEGINSYNC"])
	end

	OnlineOfficers = {}

	MonDKP:CheckOfficer()
	if core.IsOfficer and (#MonDKP_Loot > 0 or #MonDKP_DKPHistory > 0) then
		MonDKP:SyncOfficers()
	else
		MonDKP.Sync:SendData("MDKPOfficerReq", "check") 	-- receives response from all online officers, stores name in OnlineOfficers{}
		MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
		MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
			SyncTimer = SyncTimer + elapsed
			if SyncTimer > 3 then
				MonDKP.SyncTimer:SetScript("OnUpdate", nil)
				SyncTimer = 0
				if #OnlineOfficers > 0 then
					SyncInProgress = true
					MonDKP.Sync:SendData("MDKPOfficerReq", "Sync Request", OnlineOfficers[math.random(1,#OnlineOfficers)]) -- requests sync from random officer from responses received
				else
					local InitTimerElapsed = 0
					local InitCount = 1
					local _,_,NumOnline = GetNumGuildMembers()
					SyncInProgress = true

					InitTimer = InitTimer or CreateFrame("StatusBar", nil, UIParent)
					InitTimer:SetScript("OnUpdate", function(self, elapsed) 				-- sending one at a time to throttle chat traffic and the possibility of having to process dozens of Metas simultaneously
						InitTimerElapsed = InitTimerElapsed + elapsed
						if InitTimerElapsed > 0.3 and InitCount <= NumOnline then
							local name,_,_,_,_,_,_,_,online = GetGuildRosterInfo(InitCount)
							name = strsub(name, 1, string.find(name, "-")-1)

							if name and name ~= UnitName("player") and online then
								MonDKP.Sync:SendData("MDKPTableComp", MonDKP_Meta, name)	-- broadcasts meta to guild to get everyone's "current" values
							end
							InitCount = InitCount + 1
							InitTimerElapsed = 0
							MonDKP:StatusVerify_Update()
						elseif InitCount > NumOnline then
							InitTimer:SetScript("OnUpdate", nil)
							InitTimerElapsed = 0
							InitCount = 1
							SyncInProgress = false
							MonDKP:StatusVerify_Update()
						end
					end)
					if not init then
						MonDKP:Print(L["NOOFFICERSONLINE"])
					end
				end
			end
		end)
	end
end

function MonDKP:UpdateQuery() 	-- DKP Status Button click function
	if SyncInProgress then
		MonDKP:Print(L["SYNCALREADY"])
		return
	end

	SyncMessage = true
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
	MonDKP.Sync:RegisterComm("MDKPSyncFlag", MonDKP.Sync:OnCommReceived())			-- Flags players at the beginning and end of a sync to prevent overlapping sync attempts
	MonDKP.Sync:RegisterComm("MDKPSyncOff", MonDKP.Sync:OnCommReceived())			-- Requests missing entries from officers
	MonDKP.Sync:RegisterComm("MDKPOffDKP", MonDKP.Sync:OnCommReceived())			-- Receive DKP Entries between officers before full guild sync request
	MonDKP.Sync:RegisterComm("MDKPOffLoot", MonDKP.Sync:OnCommReceived())			-- Receive Loot Entries between officers before full guild sync request
	MonDKP.Sync:RegisterComm("MDKPSyncInit", MonDKP.Sync:OnCommReceived())			-- Initiates Guild Sync (sent meta table requests all tables, "end" initiates errant entry check)
	MonDKP.Sync:RegisterComm("MDKPSyncReq", MonDKP.Sync:OnCommReceived())			-- Returns player meta table for comparison by officer (all can see and process this to determine if they have missing entries)
	MonDKP.Sync:RegisterComm("MDKPSyncDKP", MonDKP.Sync:OnCommReceived())			-- Process and apply DKP entries received from officer
	MonDKP.Sync:RegisterComm("MDKPSyncLoot", MonDKP.Sync:OnCommReceived())			-- Process and apply Loot entries received from officer
	MonDKP.Sync:RegisterComm("MDKPErrantReq", MonDKP.Sync:OnCommReceived())			-- Scans all entries for all officers "lowest" to "current" finding any entries missing in between (IE: They have Roeshambo-10 and 12 but not 11)
	MonDKP.Sync:RegisterComm("MDKPErrantOff", MonDKP.Sync:OnCommReceived())			-- Same as above, officers only
	MonDKP.Sync:RegisterComm("MDKPProfile", MonDKP.Sync:OnCommReceived())			-- Sends player profile info (name/class)
	MonDKP.Sync:RegisterComm("MDKPDelUsers", MonDKP.Sync:OnCommReceived())			-- Broadcasts deleted users (archived users not on the DKP table)
	MonDKP.Sync:RegisterComm("MDKPOfficerReq", MonDKP.Sync:OnCommReceived())		-- Checks officers that are online and then requests sync from a random one
	MonDKP.Sync:RegisterComm("MDKPArchive", MonDKP.Sync:OnCommReceived())			-- Broadcasts archive for full sync
	MonDKP.Sync:RegisterComm("MDKPMetaFull", MonDKP.Sync:OnCommReceived())			-- Broadcasts meta table for full sync
	MonDKP.Sync:RegisterComm("MDKPMigrated", MonDKP.Sync:OnCommReceived())			-- Broadcasts to other officers letting them know migration occurred. Swapping their window
	MonDKP.Sync:RegisterComm("MDKPTableComp", MonDKP.Sync:OnCommReceived())			-- Broadcasts meta values of whole guild if no officers are online. To determine if anyone is out of date.
	-- Normal broadcast Prefixs
	MonDKP.Sync:RegisterComm("MDKPDecay", MonDKP.Sync:OnCommReceived())				-- Broadcasts a weekly decay adjustment
	MonDKP.Sync:RegisterComm("MDKPBCastMsg", MonDKP.Sync:OnCommReceived())			-- broadcasts a message that is printed as is
	MonDKP.Sync:RegisterComm("MDKPCommand", MonDKP.Sync:OnCommReceived())			-- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
	MonDKP.Sync:RegisterComm("MDKPLootDist", MonDKP.Sync:OnCommReceived())			-- broadcasts individual loot award to loot table
	MonDKP.Sync:RegisterComm("MDKPDelLoot", MonDKP.Sync:OnCommReceived())			-- broadcasts deleted loot award entries
	MonDKP.Sync:RegisterComm("MDKPDelSync", MonDKP.Sync:OnCommReceived())			-- broadcasts deleated DKP history entries
	MonDKP.Sync:RegisterComm("MDKPDKPDist", MonDKP.Sync:OnCommReceived())			-- broadcasts individual DKP award to DKP history table
	MonDKP.Sync:RegisterComm("MDKPMinBid", MonDKP.Sync:OnCommReceived())			-- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
	MonDKP.Sync:RegisterComm("MDKPWhitelist", MonDKP.Sync:OnCommReceived())			-- broadcasts whitelist
	MonDKP.Sync:RegisterComm("MDKPDKPModes", MonDKP.Sync:OnCommReceived())			-- broadcasts DKP Mode settings
	MonDKP.Sync:RegisterComm("MDKPStand", MonDKP.Sync:OnCommReceived())				-- broadcasts standby list
	MonDKP.Sync:RegisterComm("MDKPRaidTime", MonDKP.Sync:OnCommReceived())			-- broadcasts Raid Timer Commands
	MonDKP.Sync:RegisterComm("MDKPZeroSumBank", MonDKP.Sync:OnCommReceived())		-- broadcasts ZeroSum Bank
	MonDKP.Sync:RegisterComm("MDKPQuery", MonDKP.Sync:OnCommReceived())				-- Querys guild for spec/role data
	MonDKP.Sync:RegisterComm("MDKPBuild", MonDKP.Sync:OnCommReceived())				-- broadcasts Addon build number to inform others an update is available.
	MonDKP.Sync:RegisterComm("MDKPTalents", MonDKP.Sync:OnCommReceived())			-- broadcasts current spec
	MonDKP.Sync:RegisterComm("MDKPRoles", MonDKP.Sync:OnCommReceived())				-- broadcasts current role info
	MonDKP.Sync:RegisterComm("MDKPBossLoot", MonDKP.Sync:OnCommReceived())			-- broadcast current loot table
	MonDKP.Sync:RegisterComm("MDKPBidShare", MonDKP.Sync:OnCommReceived())			-- broadcast accepted bids
	MonDKP.Sync:RegisterComm("MDKPBidder", MonDKP.Sync:OnCommReceived())			-- Submit bids
	--MonDKP.Sync:RegisterComm("MonDKPEditLoot", MonDKP.Sync:OnCommReceived())		-- not in use
	--MonDKP.Sync:RegisterComm("MonDKPDataSync", MonDKP.Sync:OnCommReceived())		-- not in use
	--MonDKP.Sync:RegisterComm("MonDKPDKPLogSync", MonDKP.Sync:OnCommReceived())	-- not in use
	--MonDKP.Sync:RegisterComm("MonDKPLogSync", MonDKP.Sync:OnCommReceived())		-- not in use
end

function MonDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
	if not core.Initialized or core.IsOfficer == nil then return end
	if prefix == "MDKPMigrated" and not core.Migrated and core.IsOfficer then
		C_Timer.After(2, function()
			MonDKP:MigrationFrame()
		end)
	end
	if prefix and core.Migrated then
		--if prefix ~= "MDKPProfile" then print("|cffff0000Received: "..prefix.." from "..sender.."|r") end
		if SyncTimer > 1 then SyncTimer = 1 end 	-- Pushes back phase timer if a broadcast is received and timer is above 1. This is to determine when each phase of the sync is completed. (timer hits 3, nothing is being received)
		--------------- Start Sync Section
		if prefix == "MDKPSyncFlag" then
			if message == "Start" then
				SyncInProgress = true
				if #MonDKP_DKPHistory == 0 and #MonDKP_Loot == 0 then FirstSyncReady = true end  -- allows players to receive entries if first sync (prevents receiving entries if logged in mid sync)
				MonDKP:StatusVerify_Update()
			elseif message == "End" then
				if MonDKP.SyncTimer then MonDKP.SyncTimer:SetScript("OnUpdate", nil) end
				SyncTimer = 0

				if SyncMessage then
					MonDKP:Print(L["SYNCCOMPLETE"])
					MonDKP:ErrantCheck()
				end

				if FlagValidation then
					FlagValidation = false
					MonDKP:ValidateLootTable()
				end

				SyncMessage = false
				SyncingPlayers = {}
				SyncInProgress = false
				collectgarbage("collect")
				MonDKP:StatusVerify_Update()
				MonDKP:ClassGraph_Update()
				MonDKP:FilterDKPTable(core.currentSort, "reset")
				-- end sync for all receiving players
			end
			return
		elseif prefix == "MDKPSyncOff" then				-- syncs up all officers
			SyncInProgress = true
			if MonDKP:ValidateSender(sender) and core.IsOfficer and sender ~= UnitName("player") then
				decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					SyncInProgress = true
					if type(deserialized) == "table" then
						OfficerTempMeta = deserialized 		-- temporarily stores meta
						local count = MonDKP_OffMetaCount_Handler(deserialized)
						if count > 0 then
							MonDKP.Sync:SendData("MDKPSyncOff", count, sender)
						end
						local response = MonDKP_InitMeta_Handler(deserialized)
						if response then
							MonDKP.Sync:SendData("MDKPSyncReq", response)
						end

						for k1,v1 in pairs(deserialized) do
							for k2,v2 in pairs(v1) do
								if not MonDKP_Meta[k1][k2] then
									MonDKP_Meta[k1][k2] = { current=0, lowest=0 }
								end
							end
						end
					elseif tonumber(deserialized) then
						local count = tonumber(deserialized)

						if not OfficerSync.count or count > OfficerSync.count then
							OfficerSync = { officer=sender, count=count }
						end
					elseif deserialized == UnitName("player") then
						for k1,v1 in pairs(MonDKP_Meta) do
							for k2,v2 in pairs(v1) do
								local i

								if OfficerTempMeta[k1][k2] and (not MonDKP_Meta_Remote[k1][k2] or OfficerTempMeta[k1][k2].current > MonDKP_Meta_Remote[k1][k2]) then
									MonDKP_Meta_Remote[k1][k2] = OfficerTempMeta[k1][k2].current
								end

								if not OfficerTempMeta[k1][k2] then
									i = 1
								elseif MonDKP_Meta[k1][k2].current > OfficerTempMeta[k1][k2].current then
									i = OfficerTempMeta[k1][k2].current + 1
								end

								local OffSyncCounter = 0
								
								if i then
									local OffSyncTimer = OffSyncTimer or CreateFrame("StatusBar", nil, UIParent)
									OffSyncTimer:SetScript("OnUpdate", function(self, elapsed)
										OffSyncCounter = OffSyncCounter + elapsed
										if OffSyncCounter > 0.5 and i <= MonDKP_Meta[k1][k2].current then
											if k1 == "DKP" then
												local search = MonDKP:Table_Search(MonDKP_DKPHistory, k2.."-"..i, "index")
												
												if search then
													MonDKP.Sync:SendData("MDKPOffDKP", MonDKP_DKPHistory[search[1][1]], sender)  -- whisper to sending officer
													SyncMessage = true
												end
											else
												local search = MonDKP:Table_Search(MonDKP_Loot, k2.."-"..i, "index")
												
												if search then
													MonDKP.Sync:SendData("MDKPOffLoot", MonDKP_Loot[search[1][1]], sender)       	-- whisper to sending officer
													SyncMessage = true
												end
											end

											OffSyncCounter = 0
											i = i + 1
										elseif i > MonDKP_Meta[k1][k2].current then
											OffSyncTimer:SetScript("OnUpdate", nil)
											OffSyncCounter = 0
											i = 1
										end
									end)
								end
							end
						end
					end
				end
				return
			end
		elseif prefix == "MDKPSyncInit" then  -- sent to all to initiate/finialize sync requests, for initiate, returns missing entries for request
			if MonDKP:ValidateSender(sender) and sender ~= UnitName("player") then
				decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					SyncInProgress = true
					if type(deserialized) == "table" and sender ~= UnitName("player") and not RecentlySynced then
						local response = MonDKP_InitMeta_Handler(deserialized) -- processes meta received and creates a table with relevant information (Only meta values lower than received meta) or false if no update is needed

						MonDKP:StatusVerify_Update()
						if response then
							MonDKP.Sync:SendData("MDKPSyncReq", response) -- sends table with local "current" values, if they differ from the initiating officers table.
						end
						RecentlySynced = true
						C_Timer.After(60, function() RecentlySynced = false end) -- blocks additional meta requests for 60 seconds, just in case

						if MonDKP.SyncTimer then MonDKP.SyncTimer:SetScript("OnUpdate", nil) end
						timer = 0
						MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
						MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
							SyncTimer = SyncTimer + elapsed
							if SyncTimer > 30 then
								MonDKP.SyncTimer:SetScript("OnUpdate", nil)
								SyncTimer = 0
								SyncInProgress = false
								SyncMessage = false
								MonDKP:StatusVerify_Update()
								MonDKP:ClassGraph_Update()
								MonDKP:FilterDKPTable(core.currentSort, "reset")
								collectgarbage("collect")
							end
						end)
					elseif deserialized == "end" then			-- requests errant entries (IE: have Roeshambo-10 and Roeshambo-12, missing Roeshambo-11)
						if #MonDKP_Errant > 0 and UnitName("player") ~= sender then
							RequestErrant()
						else
							MonDKP:FilterDKPTable(core.currentSort, "reset")
							if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
								MonDKP:DKPHistory_Update(true)
							elseif MonDKP.ConfigTab5 and MonDKP.ConfigTab5:IsShown() then
								MonDKP:SortLootTable()
								MonDKP:LootHistory_Reset()
								MonDKP:LootHistory_Update(L["NOFILTER"]);
							end
						end
						MonDKP:StatusVerify_Update()
					end
				end
			end
			return
		elseif prefix == "MDKPSyncReq" then  -- processes all meta tables broadcasted to determine who has what, what to send, and what is missing overall (displayed on sync button as missing entries)
			decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message)) 	-- no officer actions taken here. Only processing
			local success, deserialized = LibAceSerializer:Deserialize(decoded);
			if success then
				if SyncTimer > 1 then SyncTimer = SyncTimer - 2 end
				if InitiatingOfficer and core.IsOfficer then MetasReceived = MetasReceived + 1 end

				if type(deserialized) == "table" then
					if SyncInProgress and core.IsOfficer then
						local find = MonDKP:Table_Search(SyncingPlayers, sender)
						if not find then
							table.insert(SyncingPlayers, sender)
						end
					end
					for k1,v1 in pairs(deserialized) do
						if type(v1) == "table" then
						    for k2,v2 in pairs(v1) do
						    	if not MonDKP_Meta[k1][k2] then
						    		MonDKP_Meta[k1][k2] = { current=0, lowest=0 }
						    	end
						    	if not MonDKP_Meta_Remote[k1][k2] or deserialized[k1][k2] > MonDKP_Meta_Remote[k1][k2] then -- updates highest known entry for each off. in Meta_Remote
						            MonDKP_Meta_Remote[k1][k2] = deserialized[k1][k2]
						        end
						        if (not Meta_Remote_Temp[k1][k2] or Meta_Remote_Temp[k1][k2] == 0 or Meta_Remote_Temp[k1][k2] > deserialized[k1][k2]) and core.IsOfficer and InitiatingOfficer then	-- updates temp meta with lowest known value for broadcasting
						        	Meta_Remote_Temp[k1][k2] = deserialized[k1][k2]
						        end
						    end
						end
					end

					if (tonumber(deserialized.OffDKP) and tonumber(deserialized.OffLoot)) and MonDKP:ValidateSender(sender) then
						local oldDKP, oldLoot
						local flag = false
						local newLoot = tonumber(deserialized.OffLoot)
						local newDKP = tonumber(deserialized.OffDKP)

						if MonDKP_Meta_Remote.DKP[sender] and newDKP < MonDKP_Meta_Remote.DKP[sender] then
							oldDKP = MonDKP_Meta_Remote.DKP[sender] or 0
							MonDKP_Meta_Remote.DKP[sender] = newDKP

							if newDKP < oldDKP then
								for i=newDKP+1, oldDKP do
									local search = MonDKP:Table_Search(MonDKP_DKPHistory, sender.."-"..i, "index")

									if search then
										table.remove(MonDKP_DKPHistory, search[1][1])
										flag = true
									end
								end
							end
						elseif not MonDKP_Meta_Remote.DKP[sender] then
							MonDKP_Meta_Remote.DKP[sender] = newDKP
						end

						if MonDKP_Meta_Remote.Loot[sender] and newLoot <  MonDKP_Meta_Remote.Loot[sender] then
							oldLoot = MonDKP_Meta_Remote.Loot[sender] or 0
							MonDKP_Meta_Remote.Loot[sender] = newLoot

							if newLoot < oldLoot then
								for i=newLoot+1, oldLoot do
									local search = MonDKP:Table_Search(MonDKP_Loot, sender.."-"..i, "index")

									if search then
										table.remove(MonDKP_Loot, search[1][1])
										flag = true
									end
								end
							end
						elseif not MonDKP_Meta_Remote.Loot[sender] then
							MonDKP_Meta_Remote.Loot[sender] = newDKP
						end
						if flag then
							MonDKP:Print(L["PLEASEVALIDATE"])
						end
					end
				elseif deserialized == "Full Sync" and core.IsOfficer and InitiatingOfficer then  -- message sent by player if they have no entries rather than sending full meta (reduces traffic)
					local archive = {}
		        	local flag = false

		        	if SyncInProgress then
						local find = MonDKP:Table_Search(SyncingPlayers, sender)
						if not find then
							table.insert(SyncingPlayers, sender)
						end
					end

					for k1,v1 in pairs(MonDKP_Archive) do 		-- adds relevant archive values to table to send for full sync
						if v1.lifetime_gained > 0 or v1.lifetime_spent > 0 or v1.dkp > 0 then
							archive[k1] = v1;
							flag = true; 	-- flags for archive to be sent, entries were found
						end
					end

					if flag then
						if SyncTimer > 1 then SyncTimer = SyncTimer - 10 end  -- adds 10sec to timer to accomodate a *possibly* long archive table
						MonDKP.Sync:SendData("MDKPMetaFull", MonDKP_Archive_Meta, sender)  -- prepares user for full sync. Empties all relavent tables and sets Archive_Meta
		            	C_Timer.After(1, function()
		            		MonDKP.Sync:SendData("MDKPArchive", archive, sender)
		            	end)
					end

					for k1,v1 in pairs(MonDKP_Meta) do
						for k2,v2 in pairs(v1) do
							Meta_Remote_Temp[k1][k2] = MonDKP_Meta[k1][k2].lowest-1 	-- sets all remote_temp entries to 1 below local 'lowest' so all entries are sent
						end
					end
					return
				end
				MonDKP:StatusVerify_Update()
			end
			return
		elseif prefix == "MDKPTableComp" and UnitName("player") ~= sender then
			if not RecentlySynced then
				decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					local response = MonDKP_TableComp_Handler(deserialized)
					MonDKP:StatusVerify_Update()
					if response then
						MonDKP.Sync:SendData("MDKPSyncReq", response) -- sends table with local "current" values, if they differ from the initiating officers table.
					end
					RecentlySynced = true
					C_Timer.After(60, function() RecentlySynced = false end) -- blocks additional meta requests for 60 seconds, just in case
				end
			end
		elseif prefix == "MDKPSyncDKP" or prefix == "MDKPSyncLoot" then 				-- insert entries received if they don't exist in local tables
			if name ~= UnitName("player") and MonDKP:ValidateSender(sender) then
				decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					SyncInProgress = true
					if not MonDKP.SyncTimer and SyncTimer == 0 then  		-- intiates sync timer if player logged in mid sync
						MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
						MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
							SyncTimer = SyncTimer + elapsed
							if SyncTimer > 10 then
								MonDKP.SyncTimer:SetScript("OnUpdate", nil)
								SyncTimer = 0
								if SyncMessage then
									MonDKP:Print(L["SYNCCOMPLETE"])
									MonDKP:ErrantCheck()
								end
								SyncInProgress = false
								SyncMessage = false
								collectgarbage("collect")
							end
						end)
					end

					if #MonDKP_DKPHistory == 0 and #MonDKP_Loot == 0 and not FirstSyncReady then return end

					if prefix == "MDKPSyncDKP" then
						local search = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.index, "index")
						local officer, index = strsplit("-", deserialized.index)
						index = tonumber(index);

						if core.ArchiveActive and MonDKP_Archive_Meta.DKP[officer] and MonDKP_Archive_Meta.DKP[officer] >= index then return end -- ignores if this entry is already archived

						if #MonDKP_Errant > 0 then
							local rem_errant = MonDKP:Table_Search(MonDKP_Errant, "DKP,"..deserialized.index)

							if rem_errant then
								table.remove(MonDKP_Errant, rem_errant[1])
							end
						end

						if not search then
							local dkp
							local players = {strsplit(",", strsub(deserialized.players, 1, -2))}

							SyncMessage = true

							if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then
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

									if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then 		-- handles decay entries
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + tonumber(dkp[i])
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												TempProfile_Create(players[i], tonumber(dkp[i]))
											end
										end
									else
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + tonumber(deserialized.dkp)
											if (tonumber(deserialized.dkp) > 0 and not deserialized.deletes) or (tonumber(deserialized.dkp) < 0 and deserialized.deletes) then		-- adjust lifetime if it's a DKP gain or deleting a DKP gain 
												MonDKP_DKPTable[findEntry[1][1]].lifetime_gained = MonDKP_DKPTable[findEntry[1][1]].lifetime_gained + tonumber(deserialized.dkp)	-- NOT if it's a DKP penalty or deleteing a DKP penalty
											end
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												local class

												if (tonumber(deserialized.dkp) > 0 and not deserialized.deletes) or (tonumber(deserialized.dkp) < 0 and deserialized.deletes) then
													TempProfile_Create(players[i], tonumber(deserialized.dkp), tonumber(deserialized.dkp))
												else
													TempProfile_Create(players[i])
												end
											end
										end
									end
								end
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

						if #MonDKP_Errant > 0 then
							local rem_errant = MonDKP:Table_Search(MonDKP_Errant, "Loot,"..deserialized.index)

							if rem_errant then
								table.remove(MonDKP_Errant, rem_errant[1])
							end
						end

						if not search then
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
				decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					SyncInProgress = true
					if not MonDKP.SyncTimer and SyncTimer == 0 then  		-- initiates sync timer if player logs in mid sync
						MonDKP.SyncTimer = MonDKP.SyncTimer or CreateFrame("StatusBar", nil, UIParent)
						MonDKP.SyncTimer:SetScript("OnUpdate", function(self, elapsed)
							SyncTimer = SyncTimer + elapsed
							if SyncTimer > 10 then
								MonDKP.SyncTimer:SetScript("OnUpdate", nil)
								SyncTimer = 0
								if SyncMessage then
									MonDKP:Print(L["SYNCCOMPLETE"])
									MonDKP:ErrantCheck()
								end
								SyncInProgress = false
								SyncMessage = false
								collectgarbage("collect")
							end
						end)
					end

					if #MonDKP_DKPHistory == 0 and #MonDKP_Loot == 0 and not FirstSyncReady then return end

					if prefix == "MDKPOffDKP" then
						local search = MonDKP:Table_Search(MonDKP_DKPHistory, deserialized.index, "index")
						local officer, index = strsplit("-", deserialized.index)
						index = tonumber(index);

						if core.ArchiveActive and MonDKP_Archive_Meta.DKP[officer] and MonDKP_Archive_Meta.DKP[officer] >= index then return end -- ignores if this entry is already archived
 
						if not MonDKP_Meta.DKP[officer] then
							MonDKP_Meta.DKP[officer] = {current=0, lowest=0}
						end

						if #MonDKP_Errant > 0 then
							local rem_errant = MonDKP:Table_Search(MonDKP_Errant, "DKP,"..deserialized.index)

							if rem_errant then
								table.remove(MonDKP_Errant, rem_errant[1])
							end
						end
						
						if not search then
							local players = {strsplit(",", strsub(deserialized.players, 1, -2))}

							SyncMessage = true

							if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then
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

									if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then 		-- handles decay entries
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + tonumber(dkp[i])
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												TempProfile_Create(players[i], tonumber(dkp[i]))
											end
										end
									else
										if findEntry then
											MonDKP_DKPTable[findEntry[1][1]].dkp = MonDKP_DKPTable[findEntry[1][1]].dkp + tonumber(deserialized.dkp)
											if (tonumber(deserialized.dkp) > 0 and not deserialized.deletes) or (tonumber(deserialized.dkp) < 0 and deserialized.deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain 
												MonDKP_DKPTable[findEntry[1][1]].lifetime_gained = MonDKP_DKPTable[findEntry[1][1]].lifetime_gained + deserialized.dkp 	-- NOT if it's a DKP penalty or deleteing a DKP penalty
											end
										else
											if not MonDKP_Archive[players[i]] or (MonDKP_Archive[players[i]] and MonDKP_Archive[players[i]].deleted ~= true) then
												local class

												if (tonumber(deserialized.dkp) > 0 and not deserialized.deletes) or (tonumber(deserialized.dkp) < 0 and deserialized.deletes) then
													TempProfile_Create(players[i], tonumber(deserialized.dkp), tonumber(deserialized.dkp))
												else
													TempProfile_Create(players[i])
												end
											end
										end
									end
								end
							end

							if MonDKP_Meta.DKP[officer].current < index then
								MonDKP_Meta.DKP[officer].current = index
							end
							if index < MonDKP_Meta.DKP[officer].lowest or MonDKP_Meta.DKP[officer].lowest == 0 then
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

						if #MonDKP_Errant > 0 then
							local rem_errant = MonDKP:Table_Search(MonDKP_Errant, "Loot,"..deserialized.index)

							if rem_errant then
								table.remove(MonDKP_Errant, rem_errant[1])
							end
						end
						
						if not search then
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
				SyncInProgress = true
				
				if prefix == "MDKPErrantReq" and InitiatingOfficer then
					local search = MonDKP:Table_Search(Errant, message)

					if not search then
						table.insert(Errant, message)
					end
				elseif prefix == "MDKPErrantOff" then
					decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
					local success, deserialized = LibAceSerializer:Deserialize(decoded);
					if success then
						if type(deserialized) == "table" then
							local count = 0
							local timer = 0
							local i = 1
							local sender = sender

							OfficerErrant = deserialized

							local ErrantTimer = ErrantTimer or CreateFrame("StatusBar", nil, UIParent)
							ErrantTimer:SetScript("OnUpdate", function(self, elapsed)
								timer = timer + elapsed
								if timer > 0.01 and i <= #deserialized then
									local loc, index = strsplit(",", deserialized[i])
									local search

									if loc == "DKP" then
										search = MonDKP:Table_Search(MonDKP_DKPHistory, index, "index")
									else
										search = MonDKP:Table_Search(MonDKP_Loot, index, "index")
									end

									if search then
										count = count + 1
									end

									i=i+1
									timer = 0
								elseif i > #deserialized then
									ErrantTimer:SetScript("OnUpdate", nil)
									timer = 0
									i=1

									MonDKP.Sync:SendData("MDKPErrantOff", count, sender)
								end
							end)
						elseif tonumber(deserialized) then
							local count = tonumber(deserialized)
							if not OfficerErrantCount.count or count > OfficerErrantCount.count then
								OfficerErrantCount = { officer=sender, count=count }
							end
						elseif deserialized == UnitName("player") then
							local i=1
							local timer = 0
							local processing = false
							
							local ErrantTimer = ErrantTimer or CreateFrame("StatusBar", nil, UIParent)
							ErrantTimer:SetScript("OnUpdate", function(self, elapsed)
								timer = timer + elapsed
								if timer > 0.3 and i <= #OfficerErrant and not processing then
									processing = true
									local loc, index = strsplit(",", OfficerErrant[i])

									if loc == "DKP" then
										local search = MonDKP:Table_Search(MonDKP_DKPHistory, index, "index")

										if search then
											MonDKP.Sync:SendData("MDKPOffDKP", MonDKP_DKPHistory[search[1][1]], sender)
										end
									else
										local search = MonDKP:Table_Search(MonDKP_Loot, index, "index")

										if search then
											MonDKP.Sync:SendData("MDKPOffLoot", MonDKP_Loot[search[1][1]], sender)

										end
									end
									processing = false
									i=i+1
									timer = 0
								elseif i > #OfficerErrant and timer > 3 then
									ErrantTimer:SetScript("OnUpdate", nil)
									OfficerErrantCount = {}
									OfficerErrant = {}
								end
							end)
						else
							OfficerErrantCount = {}
							OfficerErrant = {}
						end
					end
				end
			end
			return;
		elseif (prefix == "MDKPArchive" or prefix == "MDKPMetaFull") and sender ~= UnitName("player") then
			if MonDKP:ValidateSender(sender) then
				decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
				local success, deserialized = LibAceSerializer:Deserialize(decoded);
				if success then
					if SyncTimer > 1 then SyncTimer = SyncTimer - 5 end

					if prefix == "MDKPArchive" then
						MonDKP_Archive = deserialized
						FlagValidation = true
					else
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

						MonDKP_Archive_Meta = deserialized;
						core.ArchiveActive = true
					end
				end
			end
			return			
		elseif prefix == "MDKPOfficerReq" then
			if message == "check" and core.IsOfficer and UnitName("player") ~= sender and not SyncInProgress then
				MonDKP.Sync:SendData("MDKPOfficerReq", "confirm", sender)
			elseif message == "confirm" then
				if MonDKP:ValidateSender(sender) then
					table.insert(OnlineOfficers, sender)
				end
			elseif message == "Sync Request" and core.IsOfficer then
				MonDKP:SyncOfficers()
				--MonDKP:Print(sender.." requested a sync.")
			end
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
					local a,b,c = strsplit("/", message)
					if strfind(message, "Protection") or (tonumber(c) and tonumber(strsub(c, 1, -2)) > 15) then
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
						if core.BidInterface and #core.BidInterface.LootTableButtons > 0 then
							for i=1, #core.BidInterface.LootTableButtons do
								ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
							end
						end
						C_Timer.After(2, function()
							if core.BidInterface and core.BidInterface:IsShown() and not core.BiddingInProgress then
								core.BidInterface:Hide()
							end
						end)
					elseif command == "BidInfo" then
						if not core.BidInterface then
							core.BidInterface = core.BidInterface or MonDKP:BidInterface_Create()	-- initiates bid window if it hasn't been created
						end
						if MonDKP_DB.defaults.AutoOpenBid and not core.BidInterface:IsShown() then	-- toggles bid window if option is set to
							MonDKP:BidInterface_Toggle()
						end
						MonDKP:CurrItem_Set(arg1, arg2, arg3, sender)	-- populates bid window
					end
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
				or prefix == "MDKPDecay" or prefix == "MDKPDelUsers" or prefix == "MDKPBidShare" then
					decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
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
							local search = MonDKP:Table_Search(MonDKP_DKPTable, deserialized.player, "player")
							
							if search and strupper(MonDKP_DKPTable[search[1][1]].class) == "NONE" then
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
						elseif prefix == "MDKPDelUsers" and UnitName("player") ~= sender then
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

							if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then 		-- determines if it's a mass decay
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
									if deserialized.balance == 0 then
										core.ZeroSumBank.LootFrame.LootList:SetText("")
									end
									MonDKP:ZeroSumBank_Update()
								end
							end
						elseif prefix == "MDKPDKPModes" then
							if MonDKP_DB.modes.mode ~= deserialized[1].mode then
								MonDKP:Print(L["RECOMMENDRELOAD"])
							end
							MonDKP_DB.modes = deserialized[1]
							MonDKP_DB.DKPBonus = deserialized[2]
							MonDKP_DB.raiders = deserialized[3]
						elseif prefix == "MDKPBidShare" then
							if core.BidInterface then
								MonDKP:Bids_Set(deserialized)
							end
							return
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
		end
	end
end

function MonDKP.Sync:SendData(prefix, data, target)
	--if prefix ~= "MDKPProfile" then print("|cff00ff00Sent: "..prefix.."|r") end
	if data == nil or data == "" then data = " " end -- just in case, to prevent disconnects due to empty/nil string AddonMessages
	if IsInGuild() then
		if prefix == "MDKPQuery" or prefix == "MDKPBuild" or prefix == "MDKPErrantReq" or prefix == "MDKPSyncFlag" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		elseif prefix == "MDKPTalents" or prefix == "MDKPRoles" or prefix == "MDKPMigrated" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		elseif prefix == "MDKPBidder" then		-- bid submissions. Keep to raid.
			MonDKP.Sync:SendCommMessage(prefix, data, "RAID")
			return;
		elseif prefix == "MDKPOfficerReq" then 		-- request online officers to begin sync request
			if target then
				MonDKP.Sync:SendCommMessage(prefix, data, "WHISPER", target)
			else
				MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			end
		end
	end
	if IsInGuild() and (core.IsOfficer or prefix == "MDKPSyncReq" or prefix == "MDKPTableComp") then
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

		--[[local huffmanCompressed = LibCompress:CompressHuffman(serialized);
		if huffmanCompressed then
			packet = LibCompressAddonEncodeTable:Encode(huffmanCompressed);
		end--]]
		local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
		if compressed then
			packet = LibDeflate:EncodeForWoWAddonChannel(compressed)
		end
		-- send packet
		if (prefix == "MDKPZeroSumBank" or prefix == "MDKPBossLoot" or prefix == "MDKPBidShare") then		-- Zero Sum bank/loot table/bid table data and bid submissions. Keep to raid.
			MonDKP.Sync:SendCommMessage(prefix, packet, "RAID")
			return;
		end
		
		if prefix == "MDKPOffDKP" or prefix == "MDKPOffLoot" or ((prefix == "MDKPSyncDKP" or prefix == "MDKPSyncLoot" or prefix == "MDKPMetaFull" or prefix == "MDKPArchive") and target) then
			MonDKP.Sync:SendCommMessage(prefix, packet, "WHISPER", target)
			--print("|cff00ff00Sent: "..data.index.." ("..prefix..") sent to "..target.."|r")
			return
		end

		if target then
			MonDKP.Sync:SendCommMessage(prefix, packet, "WHISPER", target)
		else
			MonDKP.Sync:SendCommMessage(prefix, packet, "GUILD")
			if data.index then
				--print("|cff00ff00Sent: "..data.index.." ("..prefix..")|r")
			end
		end
	end
end