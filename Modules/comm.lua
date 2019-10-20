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

function MonDKP:ValidateSender(sender)								-- returns true if "sender" has permission to write officer notes. false if not or not found.
	if MonDKP:GetGuildRankIndex(UnitName("player")) == 1 then       -- automatically gives permissions above all settings if player is guild leader
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

-------------------------------------------------
-- Register Broadcast Prefixs
-------------------------------------------------

function MonDKP.Sync:OnEnable()
	MonDKP.Sync:RegisterComm("MonDKPDataSync", MonDKP.Sync:OnCommReceived())		-- broadcasts entire DKP table
	MonDKP.Sync:RegisterComm("MonDKPBroadcast", MonDKP.Sync:OnCommReceived())		-- broadcasts a message that is printed as is
	MonDKP.Sync:RegisterComm("MonDKPNotify", MonDKP.Sync:OnCommReceived())			-- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
	MonDKP.Sync:RegisterComm("MonDKPLogSync", MonDKP.Sync:OnCommReceived())			-- broadcasts entire loot table
	MonDKP.Sync:RegisterComm("MonDKPLootAward", MonDKP.Sync:OnCommReceived())		-- broadcasts individual loot award to loot table
	MonDKP.Sync:RegisterComm("MonDKPDeleteLoot", MonDKP.Sync:OnCommReceived())		-- broadcasts deleted loot award entries
	MonDKP.Sync:RegisterComm("MonDKPEditLoot", MonDKP.Sync:OnCommReceived())		-- broadcasts edited loot award entries
	MonDKP.Sync:RegisterComm("MonDKPDKPLogSync", MonDKP.Sync:OnCommReceived())		-- broadcasts entire DKP history table
	MonDKP.Sync:RegisterComm("MonDKPDKPDelSync", MonDKP.Sync:OnCommReceived())		-- broadcasts deleated DKP history entries
	MonDKP.Sync:RegisterComm("MonDKPDKPAward", MonDKP.Sync:OnCommReceived())		-- broadcasts individual DKP award to DKP history table
	MonDKP.Sync:RegisterComm("MonDKPMinBids", MonDKP.Sync:OnCommReceived())			-- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
	MonDKP.Sync:RegisterComm("MonDKPWhitelist", MonDKP.Sync:OnCommReceived())		-- broadcasts whitelist
	MonDKP.Sync:RegisterComm("MonDKPModes", MonDKP.Sync:OnCommReceived())			-- broadcasts DKP Mode settings
	MonDKP.Sync:RegisterComm("MonDKPStandby", MonDKP.Sync:OnCommReceived())			-- broadcasts standby list
	MonDKP.Sync:RegisterComm("MonDKPRaidTimer", MonDKP.Sync:OnCommReceived())		-- broadcasts Raid Timer Commands
	MonDKP.Sync:RegisterComm("MonDKPZeroSum", MonDKP.Sync:OnCommReceived())			-- broadcasts ZeroSum Bank
	MonDKP.Sync:RegisterComm("MonDKPTableCheck", MonDKP.Sync:OnCommReceived())		-- broadcasts Check for updated tables
	MonDKP.Sync:RegisterComm("MonDKPBuildCheck", MonDKP.Sync:OnCommReceived())		-- broadcasts Addon build number to inform others an update is available.
	MonDKP.Sync:RegisterComm("MonDKPTalCheck", MonDKP.Sync:OnCommReceived())		-- broadcasts current spec
	MonDKP.Sync:RegisterComm("MonDKPRoleCheck", MonDKP.Sync:OnCommReceived())		-- broadcasts current role info
end

function MonDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
	if (prefix) then
		if prefix == "MonDKPTableCheck" then
			if message == "DKPTableUpdateCheck" then
				MonDKP:CheckOfficer()
				if core.IsOfficer then
					local tableCheck = MonDKP:SeedVerify_Update()
					MonDKP.Sync:SendData("MonDKPTableCheck", sender..","..tostring(core.UpToDate))
				else
					local tableCheck = MonDKP:SeedVerify_Update()
					MonDKP.Sync:SendData("MonDKPTableCheck", sender..","..tostring(core.UpToDate).." nonofficer")
				end
				-- talents check
				local TalTrees={}; table.insert(TalTrees, {GetTalentTabInfo(1)}); table.insert(TalTrees, {GetTalentTabInfo(2)}); table.insert(TalTrees, {GetTalentTabInfo(3)}); 
				local talBuild = "("..TalTrees[1][3].."/"..TalTrees[2][3].."/"..TalTrees[3][3]..")"
				local talRole;

				table.sort(TalTrees, function(a, b)
					return a[3] > b[3]
				end)
				
				talBuild = TalTrees[1][1].." "..talBuild;
				talRole = TalTrees[1][4];
				
				MonDKP.Sync:SendData("MonDKPTalCheck", talBuild)
				MonDKP.Sync:SendData("MonDKPRoleCheck", talRole)

				table.wipe(TalTrees);
				return;
			else
				if message == "true" then
					table.insert(core.UpdateCheck.updated, sender)
				elseif message == "false" then
					table.insert(core.UpdateCheck.OOD, sender)
				elseif message == "false nonofficer" then
					table.insert(core.UpdateCheck.nonofficer, sender)
				elseif message == "true nonofficer" then
					table.insert(core.UpdateCheck.nonofficer_updated, sender)
				end
			end
			return
		elseif prefix == "MonDKPTalCheck" then
			local search = MonDKP:Table_Search(MonDKP_DKPTable, sender)

			if search then
				local curSelection = MonDKP_DKPTable[search[1][1]]
				curSelection.spec = message;
			end
			return
		elseif prefix == "MonDKPRoleCheck" then
			local search = MonDKP:Table_Search(MonDKP_DKPTable, sender)
			local curClass = "None";

			if search then
				local curSelection = MonDKP_DKPTable[search[1][1]]
				curClass = MonDKP_DKPTable[search[1][1]].class
			
				if curClass == "WARRIOR" then
					if strfind(message, "Protection") then
						curSelection.role = L["Tank"]
					else
						curSelection.role = L["MeleeDPS"]
					end
				elseif curClass == "PALADIN" then
					if strfind(message, "Protection") then
						curSelection.role = L["Tank"]
					elseif strfind(message, "Holy") then
						curSelection.role = L["Healer"]
					else
						curSelection.role = L["MeleeDPS"]
					end
				elseif curClass == "HUNTER" then
					curSelection.role = L["RangeDPS"]
				elseif curClass == "ROGUE" then
					curSelection.role = L["MeleeDPS"]
				elseif curClass == "PRIEST" then
					if strfind(message, "Shadow") then
						curSelection.role = L["CasterDPS"]
					else
						curSelection.role = L["Healer"]
					end
				elseif curClass == "SHAMAN" then
					if strfind(message, "Restoration") then
						curSelection.role = L["Healer"]
					elseif strfind(message, "Elemental") then
						curSelection.role = L["CasterDPS"]
					else
						curSelection.role = L["MeleeDPS"]
					end
				elseif curClass == "MAGE" then
					curSelection.role = L["CasterDPS"]
				elseif curClass == "WARLOCK" then
					curSelection.role = L["CasterDPS"]
				elseif curClass == "DRUID" then
					if strfind(message, "Feral") then
						curSelection.role = L["Tank"]
					elseif strfind(message, "Balance") then
						curSelection.role = L["CasterDPS"]
					else
						curSelection.role = L["Healer"]
					end
				else
					curSelection.role = L["NoRoleDetected"]
				end
			end
			return;
		elseif prefix == "MonDKPBuildCheck" and sender ~= UnitName("player") then
			local LastVerCheck = time() - core.LastVerCheck;

			if LastVerCheck > 1800 then   					-- limits the Out of Date message from firing more than every 30 minutes 
				core.LastVerCheck = time();
				if tonumber(message) > core.BuildNumber then
					MonDKP:Print(L["OutOfDateAnnounce"])
				end
			end

			if tonumber(message) < core.BuildNumber then
				MonDKP.Sync:SendData("MonDKPBuildCheck", tostring(core.BuildNumber))
			end
			return;
		end
		if MonDKP:ValidateSender(sender) then		-- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
			if (prefix == "MonDKPBroadcast") and sender ~= UnitName("player") then
				MonDKP:Print(message)
			elseif (prefix == "MonDKPNotify") then
				local command, arg1, arg2, arg3 = strsplit(",", message);
				if sender ~= UnitName("player") then
					if command == "StartTimer" then
						MonDKP:StartTimer(arg1, arg2)
					elseif command == "StartBidTimer" then
						MonDKP:StartBidTimer(arg1, arg2, arg3)
					elseif command == "StopBidTimer" then
						if MonDKP.BidTimer then
							MonDKP.BidTimer:SetScript("OnUpdate", nil)
							MonDKP.BidTimer:Hide()
						end
					end
				end
			elseif prefix == "MonDKPRaidTimer" and sender ~= UnitName("player") and core.IsOfficer then
				local command, arg1 = strsplit(",", message);
				if command == "start" then
					if arg1 == "true" then
						arg1 = true
					else
						arg1 = false
					end

					MonDKP:StartRaidTimer(arg1)
				elseif command == "stop" then
					MonDKP:StopRaidTimer()
				end
			end
			if (sender ~= UnitName("player")) then
				if (prefix == "MonDKPDataSync" or prefix == "MonDKPLogSync" or prefix == "MonDKPLootAward" or prefix == "MonDKPDKPLogSync" or prefix == "MonDKPDKPAward"
				or prefix == "MonDKPDeleteLoot" or prefix == "MonDKPEditLoot" or prefix == "MonDKPDKPDelSync" or prefix == "MonDKPMinBids" or prefix == "MonDKPWhitelist"
				or prefix == "MonDKPModes" or prefix == "MonDKPStandby" or prefix == "MonDKPZeroSum") then
					decoded = LibCompress:Decompress(LibCompressAddonEncodeTable:Decode(message))
					local success, deserialized = LibAceSerializer:Deserialize(decoded);
					if success then
						local leader = MonDKP:GetGuildRankGroup(1)

						if (prefix == "MonDKPLogSync") then
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_HIST_BCAST1"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODLogSync"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										MonDKP_Loot = deserialized;
										MonDKP:LootHistory_Reset()
										MonDKP:LootHistory_Update("No Filter")
										MonDKP:Print(L["LootHistoryUpdateComp"])
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_HIST_BCAST1")
							else
								MonDKP_Loot = deserialized;
								MonDKP_DKPHistory.seed = deserialized.seed
								MonDKP_DKPTable.seed = deserialized.seed
								MonDKP:LootHistory_Reset()
								MonDKP:LootHistory_Update("No Filter")
								MonDKP:Print(L["LootHistoryUpdateComp"])
							end
						elseif prefix == "MonDKPLootAward" then
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_LOOT_AWARD_BCAST"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODDKPHistoryEntry"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										tinsert(MonDKP_Loot, deserialized[1])
										MonDKP:LootHistory_Reset()
										MonDKP:LootHistory_Update("No Filter")
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_LOOT_AWARD_BCAST")
							else
								tinsert(MonDKP_Loot, deserialized[1])
								MonDKP_Loot.seed = deserialized.seed
								MonDKP_DKPHistory.seed = deserialized.seed
								MonDKP_DKPTable.seed = deserialized.seed
								MonDKP:LootHistory_Reset()
								MonDKP:LootHistory_Update("No Filter")
							end
						elseif prefix == "MonDKPDKPAward" then
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_DKP_AWARD_BCAST"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODDKPHistoryEntry"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										tinsert(MonDKP_DKPHistory, deserialized[1])
										if MonDKP.ConfigTab6.history then
											MonDKP:DKPHistory_Reset()
										end
				      					MonDKP:DKPHistory_Update()
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_DKP_AWARD_BCAST")
							else
								tinsert(MonDKP_DKPHistory, deserialized[1])
								MonDKP_Loot.seed = deserialized.seed
								MonDKP_DKPHistory.seed = deserialized.seed
								MonDKP_DKPTable.seed = deserialized.seed
								if MonDKP.ConfigTab6.history then
									MonDKP:DKPHistory_Reset()
								end
		      					MonDKP:DKPHistory_Update()
		      				end
						elseif prefix == "MonDKPDKPLogSync" then
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_HIST_BCAST2"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODDKPHistoryTable"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										MonDKP_DKPHistory = deserialized
										if MonDKP.ConfigTab6.history then
											MonDKP:DKPHistory_Reset()
										end
				      					MonDKP:DKPHistory_Update()
										MonDKP:Print(L["DKPHistoryUpdateComp"])
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_HIST_BCAST2")
							else
								MonDKP_DKPHistory = deserialized
								MonDKP_Loot.seed = deserialized.seed
								MonDKP_DKPTable.seed = deserialized.seed
								if MonDKP.ConfigTab6.history then
									MonDKP:DKPHistory_Reset()
								end
		      					MonDKP:DKPHistory_Update()
								MonDKP:Print(L["DKPHistoryUpdateComp"])
							end
						elseif prefix == "MonDKPDeleteLoot" then
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_LOOT_BCAST1"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODLootHistoryDelete"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										MonDKP:SortLootTable()
										table.remove(MonDKP_Loot, deserialized[1])
										MonDKP:LootHistory_Reset()
										MonDKP:SortLootTable()
										MonDKP:LootHistory_Update("No Filter");
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_LOOT_BCAST1")
							else
								MonDKP:SortLootTable()

								if MonDKP_Loot[deserialized[1]] and MonDKP_Loot[deserialized[1]].date == deserialized[2] then	
									table.remove(MonDKP_Loot, deserialized[1])
								else
									for i=1, #MonDKP_Loot do
										if MonDKP_Loot[i].date == deserialized[2] then
											table.remove(MonDKP_Loot, i)
											break;
										end
									end
								end
								MonDKP_Loot.seed = deserialized.seed
								MonDKP_DKPHistory.seed = deserialized.seed
								MonDKP_DKPTable.seed = deserialized.seed
								MonDKP:LootHistory_Reset()
								MonDKP:LootHistory_Update("No Filter");
							end
						elseif prefix == "MonDKPEditLoot" then
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_LOOT_ADJUST_BCAST"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODLootTableItem"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										local search = MonDKP:Table_Search(MonDKP_Loot, deserialized[1].entry)
										if search then
											MonDKP_Loot[search[1][1]].player = deserialized[1].newplayer
										end
										MonDKP:SortLootTable()
										MonDKP:LootHistory_Update("No Filter");
										DKPTable_Update()
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_LOOT_ADJUST_BCAST")
							else
								local search = MonDKP:Table_Search(MonDKP_Loot, tonumber(deserialized[1].entry))
				
								if search then
									MonDKP_Loot[search[1][1]].player = deserialized[1].newplayer
								end
								MonDKP_Loot.seed = deserialized.seed
								MonDKP_DKPHistory.seed = deserialized.seed
								MonDKP_DKPTable.seed = deserialized.seed
								MonDKP:SortLootTable()
								MonDKP:LootHistory_Update("No Filter");
								DKPTable_Update()
							end
						elseif prefix == "MonDKPDKPDelSync" then
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_DKP_DELETE_BCAST"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODDKPHistoryDelete"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										MonDKP:SortDKPHistoryTable()
										table.remove(MonDKP_DKPHistory, deserialized[1])
										if MonDKP.ConfigTab6.history then
											MonDKP:DKPHistory_Reset()
										end
										MonDKP:DKPHistory_Update()
										DKPTable_Update()
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_DKP_DELETE_BCAST")
							else
								MonDKP:SortDKPHistoryTable()
								if MonDKP_DKPHistory[deserialized[1]].date == deserialized[2] then	
									table.remove(MonDKP_DKPHistory, deserialized[1])
								else
									for i=1, #MonDKP_DKPHistory do
										if MonDKP_DKPHistory[i].date == deserialized[2] then
											table.remove(MonDKP_DKPHistory, i)
											break;
										end
									end
								end
								MonDKP_Loot.seed = deserialized.seed
								MonDKP_DKPHistory.seed = deserialized.seed
								MonDKP_DKPTable.seed = deserialized.seed
								if MonDKP.ConfigTab6.history then
									MonDKP:DKPHistory_Reset()
								end
								MonDKP:DKPHistory_Update()
								DKPTable_Update()
							end
						elseif prefix == "MonDKPMinBids" then
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
								MonDKP:Print(L["MinBidValuesReceived"].." "..sender)
							end
						elseif prefix == "MonDKPWhitelist" then
							MonDKP_Whitelist = deserialized;
						elseif prefix == "MonDKPStandby" then
							MonDKP_Standby = deserialized;
						elseif prefix == "MonDKPZeroSum" then
							if core.IsOfficer then
								MonDKP_DB.modes.ZeroSumBank = deserialized;
								if core.ZeroSumBank then
									MonDKP:ZeroSumBank_Update()
								end
							end
						elseif prefix == "MonDKPModes" then
							MonDKP_DB.modes = deserialized[1]
							MonDKP_DB.DKPBonus = deserialized[2]
							MonDKP_DB.raiders = deserialized[3]
							StaticPopupDialogs["SEND_MODES"] = {
								text = sender.." "..L["ReloadUIForSettings"],
								button1 = L["YES"],
								button2 = L["NO"],
								OnAccept = function()
									ReloadUI();
								end,
								timeout = 0,
								whileDead = true,
								hideOnEscape = true,
								preferredIndex = 3,
							}
							StaticPopup_Show ("SEND_MODES")
						else
							if leader[1].seed > deserialized.seed and core.IsOfficer == true then
								StaticPopupDialogs["CONFIRM_DKP_BROADCAST"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..sender.." "..L["OODDKPTableBroadcast"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										MonDKP_DKPTable = deserialized;			-- commits to SavedVariables
										MonDKP:FilterDKPTable(core.currentSort, "reset")
										MonDKP:SeedVerify_Update()
										MonDKP:Print(L["DKPDataUpdatedBy"].." "..sender.."...")
									end,
									timeout = 5,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("CONFIRM_DKP_BROADCAST")
							else
								MonDKP_DKPTable = deserialized;			-- commits to SavedVariables
								MonDKP_Loot.seed = deserialized.seed
								MonDKP_DKPHistory.seed = deserialized.seed
								MonDKP:FilterDKPTable(core.currentSort, "reset")
								MonDKP:SeedVerify_Update()
								MonDKP:Print(L["DKPDataUpdatedBy"].." "..sender.."...")
							end
						end
					else
						print(deserialized)  -- error reporting if string doesn't get deserialized correctly
					end
				end
			end
			if (sender == UnitName("player") and prefix == "MonDKPLogSync") then
				MonDKP:Print(L["LootHistCastComp"])
			end
			if (sender == UnitName("player") and prefix == "MonDKPDKPLogSync") then
				MonDKP:Print(L["DKPHistCastComp"])
				StaticPopupDialogs["BCAST_COMP"] = {
					text = L["BcastCompleted"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("BCAST_COMP")
				if core.CurrentlySyncing then
					core.CurrentlySyncing = false;
				end
			end
		else
			MonDKP:CheckOfficer()
			if core.IsOfficer == true and UnitName("player") ~= sender then
				local msg;

				if #MonDKP_Whitelist > 0 then
					msg = sender..", "..L["UnauthUpdate1"];
				else
					msg = sender..", "..L["UnauthUpdate2"];
				end
				MonDKP:Print(msg)
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

function MonDKP.Sync:SendData(prefix, data)
	if IsInGuild() then
		if (prefix == "MonDKPTableCheck" and data == "DKPTableUpdateCheck") or prefix == "MonDKPBuildCheck" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		elseif prefix == "MonDKPTableCheck" and data ~= "DKPTableUpdateCheck" then
			local sender, response = strsplit(",", data)
			MonDKP.Sync:SendCommMessage(prefix, response, "WHISPER", sender)
			return;
		elseif prefix == "MonDKPTalCheck" or prefix == "MonDKPRoleCheck" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		end
	end
	if IsInGuild() and core.IsOfficer then
		local serialized = nil;
		local packet = nil;
		local verInteg1 = false;
		local verInteg2 = false;

		if prefix == "MonDKPNotify" or prefix == "MonDKPRaidTimer" then
			MonDKP.Sync:SendCommMessage(prefix, data, "RAID")
			return;
		end

		if prefix == "MonDKPBroadcast" then
			MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		end	

		if data then
			serialized = LibAceSerializer:Serialize(data);	-- serializes tables to a string
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
		if (prefix == "MonDKPZeroSum") then							-- Zero Sum bank data. Keep to raid.
			MonDKP.Sync:SendCommMessage(prefix, packet, "RAID")
			return;
		end

		MonDKP.Sync:SendCommMessage(prefix, packet, "GUILD")

		--[[if prefix == "MonDKPDataSync" then
			if core.UpToDate == true then
				MonDKP:UpdateSeeds()
			end
		end--]]

		-- Verify Send
		if (prefix == "MonDKPDataSync") then
			MonDKP:Print(L["DKPBroadcasted"])
		elseif (prefix == "MonDKPLogSync") then
			MonDKP:Print(L["BCastLootHist"].."...")
		elseif (prefix == "MonDKPDKPLogSync") then
			MonDKP:Print(L["BCastDKPHist"].."...")
		end
	end
end