local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local lockouts = CreateFrame("Frame", "LockoutsFrame");

--------------------------------------
-- Slash Command
--------------------------------------
MonDKP.Commands = {
	["config"] = MonDKP.Toggle,
	["reset"] = MonDKP.ResetPosition,
	["bid"] = function(...)
		local item = strjoin(" ", ...)
		MonDKP:CheckOfficer()
		MonDKP:SeedVerify_Update()

		if core.IsOfficer then	
			if ... == nil then
				MonDKP.ToggleBidWindow()
			else
				local itemName,_,_,_,_,_,_,_,_,itemIcon = GetItemInfo(item)
				MonDKP:Print("Opening Bid Window for: ".. item)
				MonDKP:ToggleBidWindow(item, itemIcon, itemName)
			end
		else
			MonDKP:Print("You do not have permission to access that feature.")
		end
	end,
	["award"] = function (name, cost, ...)
		if core.IsOfficer then
			MonDKP:SeedVerify_Update()
			local item = strjoin(" ", ...)
			local validation = MonDKP:Table_Search(MonDKP_DKPTable, name)

			if not validation then 			-- validate command name, cost and itemlink
				MonDKP:Print(L["InvalidTargetPlayer"])
				return;
			elseif not tonumber(cost) then
				MonDKP:Print(L["InvalidItemCost"])
				return;
			elseif not strfind(item, "|Hitem:") then
				MonDKP:Print(L["InvalidItemLink"])
				return;
			end

			if core.UpToDate == false and core.IsOfficer == true then
			    StaticPopupDialogs["CONFIRM_PUSH"] = {
					text = "|CFFFF0000"..L["WARNING"].."|r: "..L["OutdateModifyWarn"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						MonDKP:AwardConfirm(MonDKP_DKPTable[validation[1][1]].player, cost, MonDKP_DB.bossargs.LastKilledBoss, MonDKP_DB.bossargs.CurrentRaidZone, item)
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("CONFIRM_PUSH")
			else
				MonDKP:AwardConfirm(MonDKP_DKPTable[validation[1][1]].player, cost, MonDKP_DB.bossargs.LastKilledBoss, MonDKP_DB.bossargs.CurrentRaidZone, item)
			end
		else
			MonDKP:Print(L["NoPermission"])
		end
	end,
	["lockouts"] = function()
		lockouts:RegisterEvent("UPDATE_INSTANCE_INFO");
		lockouts:SetScript("OnEvent", MonDKP_OnEvent);
		RequestRaidInfo()
	end,
	["timer"] = function(time, ...)
		if time == nil then
			MonDKP:BroadcastTimer(1, "...")
		else
			local title = strjoin(" ", ...)
			MonDKP:BroadcastTimer(tonumber(time), title)
		end
	end,
	["export"] = function(time, ...)
		MonDKP:ToggleExportWindow()
	end,
	["modes"] = function()
		MonDKP:CheckOfficer()
		if core.IsOfficer then
			MonDKP:ToggleDKPModesWindow()
		else
			MonDKP:Print(L["NoPermission"])
		end
	end,
	["help"] = function()
		print(" ");
		MonDKP:Print(L["SlashCommandList"]..":")
		MonDKP:Print("|cff00cc66/dkp|r - "..L["DKPLaunch"]);
		MonDKP:Print("|cff00cc66/dkp ?|r - "..L["HelpInfo"]);
		MonDKP:Print("|cff00cc66/dkp reset|r - "..L["DKPResetPos"]);
		MonDKP:Print("|cff00cc66/dkp lockouts|r - "..L["DKPLockout"]);
		MonDKP:Print("|cff00cc66/dkp timer|r - "..L["CreateRaidTimer"]);
		MonDKP:Print("|cff00cc66/dkp bid|r - "..L["OpenBidWindowHelp"]);
		MonDKP:Print("|cff00cc66/dkp award "..L["PlayerCost"].."|r - "..L["DKPAwardHelp"]);
		MonDKP:Print("|cff00cc66/dkp modes|r - "..L["DKPModesHelp"]);
		MonDKP:Print("|cff00cc66/dkp export|r - "..L["DKPExportHelp"]);
		print(" ");
		MonDKP:Print(L["WhisperCmdsHelp"]);
		MonDKP:Print("|cff00cc66!bid (or !bid <"..L["Value"]..">)|r - "..L["BidHelp"]);
		MonDKP:Print("|cff00cc66!dkp (or !dkp <"..L["PlayerName"]..">)|r - "..L["DKPCmdHelp"]);
	end,
};

local function HandleSlashCommands(str)
	if (#str == 0) then
		MonDKP.Commands.config();
		return;		
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = MonDKP.Commands;
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg];
				end
			else
				MonDKP.Commands.help();
				return;
			end
		end
	end
end

function MonDKP_OnEvent(self, event, arg1, ...)

	-- unregister unneccessary events
	if event == "CHAT_MSG_WHISPER" and not MonDKP_DB.modes.channels.whisper then
		self:UnregisterEvent("CHAT_MSG_WHISPER")
		return
	end
	if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") and not MonDKP_DB.modes.channels.raid then
		self:UnregisterEvent("CHAT_MSG_RAID")
		self:UnregisterEvent("CHAT_MSG_RAID_LEADER")
		return
	end
	if event == "CHAT_MSG_GUILD" and not MonDKP_DB.modes.channels.guild then
		self:UnregisterEvent("CHAT_MSG_GUILD")
		return
	end

	if event == "ADDON_LOADED" then
		MonDKP:OnInitialize(event, arg1)
		self:UnregisterEvent("ADDON_LOADED")
	--[[elseif event == "ENCOUNTER_START" then  				-- tentatively used for whisper standby. Announce to guild when a boss dies etc.
		--local otherStuff = ...;
	elseif event == "ENCOUNTER_END" then
		--local otherStuff = ...;--]]
	elseif event == "BOSS_KILL" then
		MonDKP:CheckOfficer()
		if core.IsOfficer and IsInRaid() then
			local boss_name = ...;

			if MonDKP:Table_Search(core.EncounterList, arg1) then
				MonDKP.ConfigTab2.BossKilledDropdown:SetValue(arg1)
			end

			if boss_name == core.BossList["WORLD"][1] or boss_name == core.BossList["WORLD"][2] or boss_name == core.BossList["WORLD"][3] or boss_name == core.BossList["WORLD"][4] or boss_name == core.BossList["WORLD"][5] or boss_name == core.BossList["WORLD"][6] then 		-- requests IDs to be reported when discovered
				MonDKP:Print("Event ID: "..arg1.." - > "..boss_name.." Killed. Please report this Event ID at https://www.curseforge.com/wow/addons/monolith-dkp to update raid event handlers.")
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then   		-- logs 15 recent zones entered while in a raid party
		if IsInRaid() then 					-- only processes combat log events if in raid
			MonDKP:CheckOfficer()
			if core.IsOfficer then
				if not MonDKP:Table_Search(MonDKP_DB.bossargs.RecentZones, GetRealZoneText()) then 	-- only adds it if it doesn't already exist in the table
					table.insert(MonDKP_DB.bossargs.RecentZones, 1, GetRealZoneText())
					if #MonDKP_DB.bossargs.RecentZones > 15 then
						for i=16, #MonDKP_DB.bossargs.RecentZones do  		-- trims the tail end of the stack
							table.remove(MonDKP_DB.bossargs.RecentZones, i)
						end
					end
				end
			end
		end
	elseif event == "CHAT_MSG_WHISPER" then
		MonDKP:CheckOfficer()
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1) and core.IsOfficer == true then
			MonDKP_CHAT_MSG_WHISPER(arg1, ...)
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		GuildRoster()
		if IsInGuild() then
			self:UnregisterEvent("GUILD_ROSTER_UPDATE")

			-- Prints info after all addons have loaded. Circumvents addons that load saved chat messages pushing info out of view.
			C_Timer.After(3, function ()
				MonDKP:CheckOfficer()
				MonDKP:Print(L["Version"].." "..core.MonVersion..", "..L["CreatedMaintain"].." Roeshambo@Stalagg-PvP");
				MonDKP:Print(L["Loaded"].." "..#MonDKP_DKPTable.." "..L["PlayerRecords"]..", "..#MonDKP_Loot.." "..L["LootHistRecords"].." "..#MonDKP_DKPHistory.." "..L["DKPHistRecords"]..".");
				MonDKP:Print(L["Use"].." /dkp ? "..L["SubmitBugs"].." @ https://github.com/Roeshambo/MonolithDKP/issues");
				MonDKP.Sync:SendData("MonDKPBuildCheck", tostring(core.BuildNumber)) -- broadcasts build number to guild to check if a newer version is available
			end)
		end
	elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
		MonDKP:CheckOfficer()
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1) and core.IsOfficer == true then
			MonDKP_CHAT_MSG_WHISPER(arg1, ...)
		end
	elseif event == "UPDATE_INSTANCE_INFO" then
		local num = GetNumSavedInstances()
		local raidString, reset, newreset, days, hours, mins, maxPlayers, numEncounter, curLength;

		if not MonDKP_DB.Lockouts then MonDKP_DB.Lockouts = {Three = 0, Five = 1570032000, Seven = 1569945600} end

		for i=1, num do 		-- corrects reset timestamp for any raids where an active lockout exists
			_,_,reset,_,_,_,_,_,maxPlayers,_,numEncounter = GetSavedInstanceInfo(i)
			newreset = time() + reset + 2 	-- returned time is 2 seconds off

			if maxPlayers == 40 and numEncounter > 1 then
				curLength = "Seven"
			elseif maxPlayers == 40 and numEncounter == 1 then
				curLength = "Five"
			elseif maxPlayers == 20 then
				curLength = "Three"
			end

			if MonDKP_DB.Lockouts[curLength] < newreset then
				MonDKP_DB.Lockouts[curLength] = newreset
			end
		end

		-- Updates lockout timer if no lockouts were found to do so.
		while MonDKP_DB.Lockouts.Three < time() do MonDKP_DB.Lockouts.Three = MonDKP_DB.Lockouts.Three + 259200 end
		while MonDKP_DB.Lockouts.Five < time() do MonDKP_DB.Lockouts.Five = MonDKP_DB.Lockouts.Five + 432000 end
		while MonDKP_DB.Lockouts.Seven < time() do MonDKP_DB.Lockouts.Seven = MonDKP_DB.Lockouts.Seven + 604800 end

		for k,v in pairs(MonDKP_DB.Lockouts) do
			reset = v - time();
			days = math.floor(reset / 86400)
			hours = math.floor(math.floor(reset % 86400) / 3600)
			mins = math.ceil((reset % 3600) / 60)
			
			if days > 1 then days = " "..days.." "..L["Days"] elseif days == 0 then days = "" else days = " "..days.." "..L["Day"] end
			if hours > 1 then hours = " "..hours.." "..L["Hours"] elseif hours == 0 then hours = "" else hours = " "..hours.." "..L["Hour"].."." end
			if mins > 1 then mins = " "..mins.." "..L["Minutes"].."." elseif mins == 0 then mins = "" else mins = " "..mins.." "..L["Minute"].."." end

			if k == "Three" then raidString = "ZG, AQ20"
			elseif k == "Five" then raidString = "Onyxia"
			elseif k == "Seven" then raidString = "MC, BWL, AQ40"
			end

			if k ~= "Three" then 	-- remove when three day raid lockouts are added
				MonDKP:Print(raidString.." "..L["ResetsIn"]..days..hours..mins.." ("..date("%A @ %H:%M:%S%p", v)..")")
			end
		end

		self:UnregisterEvent("UPDATE_INSTANCE_INFO");
	elseif event == "CHAT_MSG_GUILD" then
		MonDKP:CheckOfficer()
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1) and core.IsOfficer == true then
			MonDKP_CHAT_MSG_WHISPER(arg1, ...)
		end
	--elseif event == "CHAT_MSG_SYSTEM" then
		--MonoDKP_CHAT_MSG_SYSTEM(arg1)
	elseif event == "GROUP_ROSTER_UPDATE" then 			--updates raid listing if window is open
		if core.MonDKPUI:IsShown() then
			if core.CurSubView == "raid" then
				MonDKP:ViewLimited(true)
			elseif core.CurSubView == "raid and standby" then
				MonDKP:ViewLimited(true, true)
			end
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 		-- logs last 15 NPCs killed while in raid
		if IsInRaid() then 					-- only processes combat log events if in raid
			local _,arg1,_,_,_,_,_,arg2,arg3 = CombatLogGetCurrentEventInfo();
			if arg1 == "UNIT_DIED" and (not strfind(arg2, "Player") or not strfind(arg2, "Pet-")) then
				MonDKP:CheckOfficer()
				if core.IsOfficer then
					if not MonDKP:Table_Search(MonDKP_DB.bossargs.LastKilledNPC, arg3) then 	-- only adds it if it doesn't already exist in the table
						table.insert(MonDKP_DB.bossargs.LastKilledNPC, 1, arg3)
						if #MonDKP_DB.bossargs.LastKilledNPC > 15 then
							for i=16, #MonDKP_DB.bossargs.LastKilledNPC do  		-- trims the tail end of the stack
								table.remove(MonDKP_DB.bossargs.LastKilledNPC, i)
							end
						end
					end
				end
			end
		end
	--[[elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 					-- replaced with above BOSS_KILL event handler
		if IsInRaid() then 					-- only processes combat log events if in raid
			local _,arg1,_,_,_,_,_,_,arg2 = CombatLogGetCurrentEventInfo();			-- run operation when boss is killed
			if arg1 == "UNIT_DIED" then
				MonDKP:CheckOfficer()
				if core.IsOfficer == true then
					if MonDKP:TableStrFind(core.BossList, arg2) then
						MonDKP.ConfigTab2.BossKilledDropdown:SetValue(arg2)
					elseif arg2 == "Flamewalker Elite" or arg2 == "Flamewalker Healer" then
						MonDKP.ConfigTab2.BossKilledDropdown:SetValue("Majordomo Executus")
					elseif arg2 == "Emperor Vek'lor" or arg2 == "Emperor Vek'nilash" then
						MonDKP.ConfigTab2.BossKilledDropdown:SetValue("Twin Emperors")
					elseif arg2 == "Princess Yauj" or arg2 == "Vem" or arg2 == "Lord Kri" then
						MonDKP.ConfigTab2.BossKilledDropdown:SetValue("Bug Family")
					elseif arg2 == "Highlord Mograine" or arg2 == "Thane Korth'azz" or arg2 == "Sir Zeliek" or arg2 == "Lady Blaumeux" then
						MonDKP.ConfigTab2.BossKilledDropdown:SetValue("The Four Horsemen")
					elseif arg2 == "Gri'lek" or arg2 == "Hazza'rah" or arg2 == "Renataki" or arg2 == "Wushoolay" then
						MonDKP.ConfigTab2.BossKilledDropdown:SetValue("Edge of Madness")
					end
				end
			end
		end--]]
	elseif event == "LOOT_OPENED" then
		if IsInRaid() then
			MonDKP_Register_ShiftClickLootWindowHook()
		end
	end
end

function MonDKP:OnInitialize(event, name)		-- This is the FIRST function to run on load triggered registered events at bottom of file
	if (name ~= "MonolithDKP") then return end 

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end
	
	----------------------------------
	-- Register Slash Commands
	----------------------------------
	SLASH_MonolithDKP1 = "/dkp";
	SlashCmdList.MonolithDKP = HandleSlashCommands;

	--[[SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI 				-- for debugging
	SlashCmdList.RELOADUI = ReloadUI;

	SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
	SlashCmdList.FRAMESTK = function()
		LoadAddOn("Blizzard_DebugTools");
		FrameStackTooltip_Toggle();
	end--]]

    if(event == "ADDON_LOADED") then
		if not MonDKP_DKPTable then MonDKP_DKPTable = {} end;
		if not MonDKP_Loot then MonDKP_Loot = {} end;
		if not MonDKP_DKPHistory then MonDKP_DKPHistory = {} end;
		if not MonDKP_MinBids then MonDKP_MinBids = {} end;
		if not MonDKP_Whitelist then MonDKP_Whitelist = {} end;
		if not MonDKP_Standby then MonDKP_Standby = {} end;
		if not MonDKP_DB then MonDKP_DB = {} end
		if not MonDKP_DB.DKPBonus or not MonDKP_DB.DKPBonus.OnTimeBonus then
			MonDKP_DB.DKPBonus = { 
    			OnTimeBonus = 15, BossKillBonus = 5, CompletionBonus = 10, NewBossKillBonus = 10, UnexcusedAbsence = -25, BidTimer = 30, DecayPercentage = 20, GiveRaidStart = false, IncStandby = false,
    		}
		end
		if not MonDKP_DB.defaults or not MonDKP_DB.defaults.HistoryLimit then
			MonDKP_DB.defaults = {
    			HistoryLimit = 2500, DKPHistoryLimit = 2500, BidTimerSize = 1.0, MonDKPScaleSize = 1.0, supressNotifications = false, TooltipHistoryCount = 15,
    		}
    	end
		if not MonDKP_DKPTable.seed then MonDKP_DKPTable.seed = 0 end
		if not MonDKP_DKPHistory.seed then MonDKP_DKPHistory.seed = 0 end
		if not MonDKP_Loot.seed then MonDKP_Loot.seed = 0 end
		if not MonDKP_DB.raiders then MonDKP_DB.raiders = {} end
		if not MonDKP_DB.MinBidBySlot or not MonDKP_DB.MinBidBySlot.Head then
			MonDKP_DB.MinBidBySlot = {
    			Head = 70, Neck = 70, Shoulders = 70, Cloak = 70, Chest = 70, Bracers = 70, Hands = 70, Belt = 70, Legs = 70, Boots = 70, Ring = 70, Trinket = 70, OneHanded = 70, TwoHanded = 70, OffHand = 70, Range = 70, Other = 70,
    		}
    	end
		if not MonDKP_DB.bossargs then MonDKP_DB.bossargs = { CurrentRaidZone = "Molten Core", LastKilledBoss = "Lucifron" } end
		if not MonDKP_DB.modes or not MonDKP_DB.modes.mode then MonDKP_DB.modes = { mode = "Minimum Bid Values", SubZeroBidding = false, rounding = 0, AddToNegative = false, increment = 60, ZeroSumBidType = "Static", AllowNegativeBidders = false } end;
		if not MonDKP_DB.modes.ZeroSumBank then MonDKP_DB.modes.ZeroSumBank = { balance = 0 } end
		if not MonDKP_DB.modes.channels then MonDKP_DB.modes.channels = { raid = true, whisper = true, guild = true } end
		if not MonDKP_DB.modes.costvalue then MonDKP_DB.modes.costvalue = "Integer" end
		if not MonDKP_DB.modes.rolls or not MonDKP_DB.modes.rolls.min then MonDKP_DB.modes.rolls = { min = 1, max = 100, UsePerc = false, AddToMax = 0 } end
		if not MonDKP_DB.bossargs.LastKilledNPC then MonDKP_DB.bossargs.LastKilledNPC = {} end
		if not MonDKP_DB.bossargs.RecentZones then MonDKP_DB.bossargs.RecentZones = {} end

	    ------------------------------------
	    --	Import SavedVariables
	    ------------------------------------
	    core.settings.DKPBonus = MonDKP_DB.DKPBonus 				--imports default settings (Options Tab)
	    core.settings.MinBidBySlot = MonDKP_DB.MinBidBySlot			--imports default minimum bids (Options Tab)
	    core.settings.defaults = MonDKP_DB.defaults					--imports default UI settings
	    core.WorkingTable = MonDKP_DKPTable;						--imports full DKP table to WorkingTable for list manipulation without altering the SavedVariable
	    core.CurrentRaidZone = MonDKP_DB.bossargs.CurrentRaidZone;	-- stores raid zone as a redundency
		core.LastKilledBoss = MonDKP_DB.bossargs.LastKilledBoss;	-- stores last boss killed as a redundency
		core.LastKilledNPC	= MonDKP_DB.bossargs.LastKilledNPC 		-- Stores last 30 mobs killed in raid.
		core.RecentZones	= MonDKP_DB.bossargs.RecentZones 		-- Stores last 30 zones entered within a raid party.

		table.sort(MonDKP_DKPTable, function(a, b)
			return a["player"] < b["player"]
		end)

		for i=1, #MonDKP_DKPTable do
			MonDKP_DKPTable[i].class = string.upper(MonDKP_DKPTable[i].class)		-- hotfix for migrating previous class listings to localization neutral classes
		end
		
		core.MonDKPUI = MonDKP.UIConfig or MonDKP:CreateMenu();		-- creates main menu
		MonDKP:StartBidTimer(seconds, nil)							-- initiates timer frame for use
		MonDKP:PurgeLootHistory()									-- purges Loot History entries that exceed the "HistoryLimit" option variable (oldest entries)
		MonDKP:PurgeDKPHistory()									-- purges DKP History entries that exceed the "DKPHistoryLimit" option variable (oldest entries)
	end
end

----------------------------------
-- Register Events and Initiallize AddOn
----------------------------------

local events = CreateFrame("Frame", "EventsFrame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("GROUP_ROSTER_UPDATE");
events:RegisterEvent("ENCOUNTER_START");  		-- FOR TESTING PURPOSES.
events:RegisterEvent("ENCOUNTER_END");  		-- FOR TESTING PURPOSES.
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- NPC kill event
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("CHAT_MSG_RAID")
events:RegisterEvent("CHAT_MSG_RAID_LEADER")
events:RegisterEvent("CHAT_MSG_WHISPER");
events:RegisterEvent("CHAT_MSG_GUILD")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("BOSS_KILL")
events:SetScript("OnEvent", MonDKP_OnEvent); -- calls the above MonDKP_OnEvent function to determine what to do with the event