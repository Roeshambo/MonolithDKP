local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local lockouts = CreateFrame("Frame", "LockoutsFrame");
local AllowGuildCheck = false

--------------------------------------
-- Slash Command
--------------------------------------
MonDKP.Commands = {
	["config"] = function()
		if core.Initialized then
			local pass, err = pcall(MonDKP.Toggle)

			if not pass then
				MonDKP:Print(err)
				core.MonDKPUI:SetShown(false)
				StaticPopupDialogs["SUGGEST_RELOAD"] = {
					text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
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
				StaticPopup_Show ("SUGGEST_RELOAD")
			end
		else
			MonDKP:Print("Monolith DKP has not completed initialization.")
		end
	end,
	["reset"] = MonDKP.ResetPosition,
	["bid"] = function(...)
		if core.Initialized then
			local item = strjoin(" ", ...)
			MonDKP:CheckOfficer()
			MonDKP:StatusVerify_Update()

			if core.IsOfficer then	
				if ... == nil then
					MonDKP.ToggleBidWindow()
				else
					local itemName,_,_,_,_,_,_,_,_,itemIcon = GetItemInfo(item)
					MonDKP:Print("Opening Bid Window for: ".. item)
					MonDKP:ToggleBidWindow(item, itemIcon, itemName)
				end
			end
			MonDKP:BidInterface_Toggle()
		else
			MonDKP:Print("Monolith DKP has not completed initialization.")
		end 
	end,
	["migrate"] = function()
		if not core.Migrated then MonDKP:MigrationFrame() end
	end,
	["test"] = function() 			-- test new features
		print("Errant Count: "..#MonDKP_Errant)
		print("DKP Hist Count: "..#MonDKP_DKPHistory)
		print("Loot Hist Count: "..#MonDKP_Loot)
	end,
	["award"] = function (name, ...)
		if core.IsOfficer and core.Initialized then
			MonDKP:StatusVerify_Update()
			
			if not name or not strfind(name, ":::::") then
				MonDKP:Print(L["AWARDWARNING"])
				return
			end
			local item = strjoin(" ", ...)
			if not item then return end
			item = name.." "..item;
			
			MonDKP:AwardConfirm(nil, 0, MonDKP_DB.bossargs.LastKilledBoss, MonDKP_DB.bossargs.CurrentRaidZone, item)
		else
			MonDKP:Print(L["NOPERMISSION"])
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
		if core.Initialized then
			MonDKP:CheckOfficer()
			if core.IsOfficer then
				MonDKP:ToggleDKPModesWindow()
			else
				MonDKP:Print(L["NOPERMISSION"])
			end
		else
			MonDKP:Print("Monolith DKP has not completed initialization.")
		end
	end,
	["help"] = function()
		print(" ");
		MonDKP:Print(L["SLASHCOMMANDLIST"]..":")
		MonDKP:Print("|cff00cc66/dkp|r - "..L["DKPLAUNCH"]);
		MonDKP:Print("|cff00cc66/dkp ?|r - "..L["HELPINFO"]);
		MonDKP:Print("|cff00cc66/dkp reset|r - "..L["DKPRESETPOS"]);
		MonDKP:Print("|cff00cc66/dkp lockouts|r - "..L["DKPLOCKOUT"]);
		MonDKP:Print("|cff00cc66/dkp timer|r - "..L["CREATERAIDTIMER"]);
		MonDKP:Print("|cff00cc66/dkp bid|r - "..L["OPENBIDWINDOWHELP"]);
		MonDKP:Print("|cff00cc66/dkp bid [itemlink]|r - "..L["OPENAUCWINHELP"]);
		MonDKP:Print("|cff00cc66/dkp award [item link]|r - "..L["DKPAWARDHELP"]);
		MonDKP:Print("|cff00cc66/dkp modes|r - "..L["DKPMODESHELP"]);
		MonDKP:Print("|cff00cc66/dkp export|r - "..L["DKPEXPORTHELP"]);
		print(" ");
		MonDKP:Print(L["WHISPERCMDSHELP"]);
		MonDKP:Print("|cff00cc66!bid (or !bid <"..L["VALUE"]..">)|r - "..L["BIDHELP"]);
		MonDKP:Print("|cff00cc66!dkp (or !dkp <"..L["PLAYERNAME"]..">)|r - "..L["DKPCMDHELP"]);
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
	if event == "CHAT_MSG_GUILD" and not MonDKP_DB.modes.channels.guild and not MonDKP_DB.modes.StandbyOptIn then
		self:UnregisterEvent("CHAT_MSG_GUILD")
		return
	end

	if event == "ADDON_LOADED" then
		MonDKP:OnInitialize(event, arg1)
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "BOSS_KILL" then
		MonDKP:CheckOfficer()
		if core.IsOfficer and IsInRaid() then
			local boss_name = ...;

			if MonDKP:Table_Search(core.EncounterList, arg1) then
				MonDKP.ConfigTab2.BossKilledDropdown:SetValue(arg1)

				if MonDKP_DB.modes.StandbyOptIn then
					MonDKP_Standby_Announce(boss_name)
				end

				if MonDKP_DB.modes.AutoAward then
					if not MonDKP_DB.modes.StandbyOptIn and MonDKP_DB.DKPBonus.IncStandby then
						MonDKP:AutoAward(3, MonDKP_DB.DKPBonus.BossKillBonus, MonDKP_DB.bossargs.CurrentRaidZone..": "..MonDKP_DB.bossargs.LastKilledBoss)
					else
						MonDKP:AutoAward(1, MonDKP_DB.DKPBonus.BossKillBonus, MonDKP_DB.bossargs.CurrentRaidZone..": "..MonDKP_DB.bossargs.LastKilledBoss)
					end
				end
			else
				MonDKP:Print("Event ID: "..arg1.." - > "..boss_name.." Killed. Please report this Event ID at https://www.curseforge.com/wow/addons/monolith-dkp to update raid event handlers.")
			end
		elseif IsInRaid() then
			MonDKP_DB.bossargs.LastKilledBoss = ...;
		end
	elseif event == "ENCOUNTER_START" then
		if MonDKP_DB.defaults.AutoLog and IsInRaid() then
			if not LoggingCombat() then
				LoggingCombat(1)
				MonDKP:Print(L["NOWLOGGINGCOMBAT"])
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then   		-- logs 15 recent zones entered while in a raid party
		if IsInRaid() and core.Initialized then 					-- only processes combat log events if in raid
			MonDKP:CheckOfficer()
			if core.IsOfficer then
				if not MonDKP:Table_Search(MonDKP_DB.bossargs.RecentZones, GetRealZoneText()) then 	-- only adds it if it doesn't already exist in the table
					if #MonDKP_DB.bossargs.RecentZones > 14 then
						for i=15, #MonDKP_DB.bossargs.RecentZones do  		-- trims the tail end of the stack
							table.remove(MonDKP_DB.bossargs.RecentZones, i)
						end
					end
					table.insert(MonDKP_DB.bossargs.RecentZones, 1, GetRealZoneText())
				end
			end
			if MonDKP_DB.defaults.AutoLog and MonDKP:Table_Search(core.ZoneList, GetRealZoneText()) then
				if not LoggingCombat() then
					LoggingCombat(1)
					MonDKP:Print(L["NOWLOGGINGCOMBAT"])
				end
			end
		end
	elseif event == "CHAT_MSG_WHISPER" then
		MonDKP:CheckOfficer()
		arg1 = strlower(arg1)
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1 or string.find(arg1, "！dkp") == 1) and core.IsOfficer == true then
			MonDKP_CHAT_MSG_WHISPER(arg1, ...)
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		if IsInGuild() and not core.InitStart then
			GuildRoster()
			core.InitStart = true
			--self:UnregisterEvent("GUILD_ROSTER_UPDATE")

			-- Prints info after all addons have loaded. Circumvents addons that load saved chat messages pushing info out of view.
			C_Timer.After(3, function ()
				MonDKP:CheckOfficer()
				MonDKP:Print(L["VERSION"].." "..core.MonVersion..", "..L["CREATEDMAINTAIN"].." Roeshambo@Stalagg-PvP");
				MonDKP:Print(L["LOADED"].." "..#MonDKP_DKPTable.." "..L["PLAYERRECORDS"]..", "..#MonDKP_Loot.." "..L["LOOTHISTRECORDS"].." "..#MonDKP_DKPHistory.." "..L["DKPHISTRECORDS"]..".");
				MonDKP:Print(L["USE"].." /dkp ? "..L["SUBMITBUGS"].." @ https://github.com/Roeshambo/MonolithDKP/issues");
				MonDKP.Sync:SendData("MDKPBuild", tostring(core.BuildNumber)) -- broadcasts build number to guild to check if a newer version is available
				MonDKP.Sync:SendData("MDKPQuery", "start") -- requests role and spec data

				if not core.Migrated and core.IsOfficer then  	-- prompts for migration (if officer and not migrated)
					-- initiate migration setup
					MonDKP:MigrationFrame()
				elseif not core.Migrated and not core.IsOfficer then -- wipes tables if non officer
					MonDKP_DKPTable = nil
					MonDKP_Loot = nil
					MonDKP_DKPHistory = nil
					MonDKP_DKPTable = {}
					MonDKP_Loot = {}
					MonDKP_DKPHistory = {}
					core.Migrated = true
					MonDKP:FilterDKPTable(core.currentSort, "reset")
					MonDKP:RequestSync()
				else
					if core.IsOfficer and not MonDKP_Meta.DKP[UnitName("player")] then
						MonDKP_Meta.DKP[UnitName("player")] = { current=0, lowest=0 }
					end
					if core.IsOfficer and not MonDKP_Meta.Loot[UnitName("player")] then
						MonDKP_Meta.Loot[UnitName("player")] = { current=0, lowest=0 }
					end
					for k1,v1 in pairs(MonDKP_Meta) do
						for k2,v2 in pairs(v1) do
							if not MonDKP:ValidateSender(k2) and v2.current == 0 and v2.lowest == 0 then
								MonDKP_Meta[k1][k2] = nil
								if MonDKP_Meta_Remote[k1][k2] then
									MonDKP_Meta_Remote[k1][k2] = nil
								end
							end
						end
					end
				end
				if #MonDKP_Loot == 0 and #MonDKP_DKPHistory == 0 then
					C_Timer.After(4, function()
						MonDKP:StatusVerify_Update(true)
					end)
				end
				AllowGuildCheck = true
				MonDKP:ErrantCheck(true)  -- begins errant check (finds entries missing between lowest and current) and executes sync
			end)
		end

		if IsInGuild() and core.InitStart and core.IsOfficer ~= nil and AllowGuildCheck then
			local GuildName = GetGuildInfo("player")

			if not MonDKP_DB.defaults.CurrentGuild[UnitName("player")] and GuildName then
				MonDKP_DB.defaults.CurrentGuild = {}
				MonDKP_DB.defaults.CurrentGuild[UnitName("player")] = GuildName
			elseif MonDKP_DB.defaults.CurrentGuild[UnitName("player")] and GuildName and MonDKP_DB.defaults.CurrentGuild[UnitName("player")] ~= GuildName then -- wipes all data when player joins a new guild
				core.IsOfficer = false
				MonDKP_Whitelist = nil
				MonDKP_DKPTable = nil
				MonDKP_Loot = nil
				MonDKP_DKPHistory = nil
				MonDKP_Meta = nil
				MonDKP_Meta_Remote = nil
				MonDKP_Archive = nil
				MonDKP_Whitelist = nil

				MonDKP_DKPTable = {}
				MonDKP_Loot = {}
				MonDKP_DKPHistory = {}
				MonDKP_Meta = {}
				MonDKP_Meta_Remote = {}
				MonDKP_Archive = {}
				MonDKP_Whitelist = {}
				core.Migrated = true
				MonDKP:FilterDKPTable(core.currentSort, "reset")
				MonDKP_DB.defaults.CurrentGuild[UnitName("player")] = GuildName

				StaticPopupDialogs["GUILD_CHANGED"] = {
					text = L["CHANGEDGUILDS"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("GUILD_CHANGED")
			end
		end
	elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
		MonDKP:CheckOfficer()
		arg1 = strlower(arg1)
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1 or string.find(arg1, "!standby") == 1 or string.find(arg1, "！dkp") == 1) and core.IsOfficer == true then
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
			
			if days > 1 then days = " "..days.." "..L["DAYS"] elseif days == 0 then days = "" else days = " "..days.." "..L["DAY"] end
			if hours > 1 then hours = " "..hours.." "..L["HOURS"] elseif hours == 0 then hours = "" else hours = " "..hours.." "..L["HOUR"].."." end
			if mins > 1 then mins = " "..mins.." "..L["MINUTES"].."." elseif mins == 0 then mins = "" else mins = " "..mins.." "..L["MINUTE"].."." end

			if k == "Three" then raidString = "ZG, AQ20"
			elseif k == "Five" then raidString = "Onyxia"
			elseif k == "Seven" then raidString = "MC, BWL, AQ40"
			end

			if k ~= "Three" then 	-- remove when three day raid lockouts are added
				MonDKP:Print(raidString.." "..L["RESETSIN"]..days..hours..mins.." ("..date("%A @ %H:%M:%S%p", v)..")")
			end
		end

		self:UnregisterEvent("UPDATE_INSTANCE_INFO");
	elseif event == "CHAT_MSG_GUILD" then
		MonDKP:CheckOfficer()
		if core.IsOfficer then
			arg1 = strlower(arg1)
			if (core.BidInProgress or string.find(arg1, "!dkp") == 1 or string.find(arg1, "！dkp") == 1) and MonDKP_DB.modes.channels.guild then
				MonDKP_CHAT_MSG_WHISPER(arg1, ...)
			elseif string.find(arg1, "!standby") == 1 and core.StandbyActive then
				MonDKP_Standby_Handler(arg1, ...)
			end
		end
	--elseif event == "CHAT_MSG_SYSTEM" then
		--MonoDKP_CHAT_MSG_SYSTEM(arg1)
	elseif event == "GROUP_ROSTER_UPDATE" then 			--updates raid listing if window is open
		if MonDKP.UIConfig and core.MonDKPUI:IsShown() then
			if core.CurSubView == "raid" then
				MonDKP:ViewLimited(true)
			elseif core.CurSubView == "raid and standby" then
				MonDKP:ViewLimited(true, true)
			end
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 		-- logs last 15 NPCs killed while in raid
		if IsInRaid() then 					-- only processes combat log events if in raid
			local _,arg1,_,_,_,_,_,arg2,arg3 = CombatLogGetCurrentEventInfo();
			if arg1 == "UNIT_DIED" and not strfind(arg2, "Player") and not strfind(arg2, "Pet-") then
				MonDKP:CheckOfficer()
				if core.IsOfficer then
					if not MonDKP:Table_Search(MonDKP_DB.bossargs.LastKilledNPC, arg3) then 	-- only adds it if it doesn't already exist in the table
						if #MonDKP_DB.bossargs.LastKilledNPC > 14 then
							for i=15, #MonDKP_DB.bossargs.LastKilledNPC do  		-- trims the tail end of the stack
								table.remove(MonDKP_DB.bossargs.LastKilledNPC, i)
							end
						end
						table.insert(MonDKP_DB.bossargs.LastKilledNPC, 1, arg3)
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
		if core.IsOfficer and IsInRaid() then
			MonDKP_Register_ShiftClickLootWindowHook()
			local lootTable = {}
			local lootList = {};

			for i=1, GetNumLootItems() do
				if LootSlotHasItem(i) and GetLootSlotLink(i) then
					local _,link,quality = GetItemInfo(GetLootSlotLink(i))
					if quality >= 4 then
						table.insert(lootTable, link)
					end
				end
			end
			lootTable.boss=core.LastKilledBoss
			MonDKP.Sync:SendData("MDKPBossLoot", lootTable)

			for i=1, #lootTable do
				local item = Item:CreateFromItemLink(lootTable[i]);
				item:ContinueOnItemLoad(function()
					local icon = item:GetItemIcon()
					table.insert(lootList, {icon=icon, link=item:GetItemLink()})
				end);
			end

			MonDKP:LootTable_Set(lootList)
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
	SLASH_MonolithDKP2 = "/mondkp";
	SlashCmdList.MonolithDKP = HandleSlashCommands;

	--[[SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI 				-- for debugging
	SlashCmdList.RELOADUI = ReloadUI;

	SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
	SlashCmdList.FRAMESTK = function()
		LoadAddOn("Blizzard_DebugTools");
		FrameStackTooltip_Toggle();
	end--]]

    if(event == "ADDON_LOADED") then
    	core.Initialized = false
    	core.InitStart = false
    	core.IsOfficer = nil
		C_Timer.After(5, function ()
			core.MonDKPUI = MonDKP.UIConfig or MonDKP:CreateMenu();		-- creates main menu after 5 seconds (trying to initialize after raid frames are loaded)
		end)
    	if not MonDKP_DKPTable then MonDKP_DKPTable = {} end;
		if not MonDKP_Loot then MonDKP_Loot = {} end;
		if not MonDKP_DKPHistory then MonDKP_DKPHistory = {} end;
		if not MonDKP_MinBids then MonDKP_MinBids = {} end;
		if not MonDKP_Whitelist then MonDKP_Whitelist = {} end;
		if not MonDKP_Standby then MonDKP_Standby = {} end;
		if not MonDKP_Archive then MonDKP_Archive = {} end;
		if not MonDKP_DB then MonDKP_DB = {} end
		if ((#MonDKP_Loot == 0 or MonDKP_Loot[1].index) and (#MonDKP_DKPHistory == 0 or MonDKP_DKPHistory[1].index)) then core.Migrated = true end;  -- determines if migration is necessary
		if not MonDKP_DB.DKPBonus or not MonDKP_DB.DKPBonus.OnTimeBonus then
			MonDKP_DB.DKPBonus = {
    			OnTimeBonus = 15, BossKillBonus = 5, CompletionBonus = 10, NewBossKillBonus = 10, UnexcusedAbsence = -25, BidTimer = 30, DecayPercentage = 20, GiveRaidStart = false, IncStandby = false,
    		}
		end
		if not MonDKP_DB.defaults or not MonDKP_DB.defaults.HistoryLimit then
			MonDKP_DB.defaults = {
    			HistoryLimit = 2500, DKPHistoryLimit = 2500, BidTimerSize = 1.0, MonDKPScaleSize = 1.0, supressNotifications = false, TooltipHistoryCount = 15, SupressTells = true,
    		}
    	end
    	if not MonDKP_DB.defaults.ChatFrames then 
    		MonDKP_DB.defaults.ChatFrames = {}
    		for i = 1, NUM_CHAT_WINDOWS do
				local name = GetChatWindowInfo(i)

				if name ~= "" then
					MonDKP_DB.defaults.ChatFrames[name] = true
				end
			end
    	end
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
		if not MonDKP_DB.defaults.HideChangeLogs then MonDKP_DB.defaults.HideChangeLogs = 0 end
		if not MonDKP_DB.modes.AntiSnipe then MonDKP_DB.modes.AntiSnipe = 0 end
		if not MonDKP_Meta then MonDKP_Meta = { DKP={}, Loot={} } end
		if not MonDKP_Archive_Meta then MonDKP_Archive_Meta = { DKP={}, Loot={} } end;
		if not MonDKP_Meta_Remote or not MonDKP_Meta_Remote.DKP or not MonDKP_Meta_Remote.Loot then MonDKP_Meta_Remote = { DKP={}, Loot={} } end
		if not MonDKP_DB.defaults.CurrentGuild then MonDKP_DB.defaults.CurrentGuild = {} end
		if not MonDKP_Errant then MonDKP_Errant = {} end

		------------------------------------
	    --	Validate Tables - Rebuilds DKPTable based off of DKP History, Loot History, and archived data. (This is manually triggered now)
	    ------------------------------------
	    --[[if core.Migrated then 		-- only allow this to fire if the migration has already occurred.
			MonDKP:ValidateLootTable()  		-- clears duplicate entries in loot table
			MonDKP:ValidateDKPHistory()			-- clears duplicate entries in dkp history table
			MonDKP:ValidateDKPTable_Loot()		-- adds up all entries in the loot table
			MonDKP:ValidateDKPTable_DKP()		-- adds up all entries in DKP table
			MonDKP:ValidateDKPTable_Final()		-- rectifies incorrect DKPTable data based off of the above 2 functions
		end--]]
	    ------------------------------------
	    --	Import SavedVariables
	    ------------------------------------
	    core.WorkingTable 		= MonDKP_DKPTable;						-- imports full DKP table to WorkingTable for list manipulation
	    core.CurrentRaidZone	= MonDKP_DB.bossargs.CurrentRaidZone;	-- stores raid zone as a redundency
		core.LastKilledBoss 	= MonDKP_DB.bossargs.LastKilledBoss;	-- stores last boss killed as a redundency
		core.LastKilledNPC		= MonDKP_DB.bossargs.LastKilledNPC 		-- Stores last 30 mobs killed in raid.
		core.RecentZones		= MonDKP_DB.bossargs.RecentZones 		-- Stores last 30 zones entered within a raid party.

		table.sort(MonDKP_DKPTable, function(a, b)
			return a["player"] < b["player"]
		end)
		
		MonDKP:StartBidTimer("seconds", nil)						-- initiates timer frame for use

		if MonDKP.BidTimer then MonDKP.BidTimer:SetScript("OnUpdate", nil) end
		
		if #MonDKP_Loot > MonDKP_DB.defaults.HistoryLimit then
			MonDKP:PurgeLootHistory()									-- purges Loot History entries that exceed the "HistoryLimit" option variable (oldest entries) and populates MonDKP_Archive with deleted values
		end
		if #MonDKP_DKPHistory > MonDKP_DB.defaults.DKPHistoryLimit then
			MonDKP:PurgeDKPHistory()									-- purges DKP History entries that exceed the "DKPHistoryLimit" option variable (oldest entries) and populates MonDKP_Archive with deleted values
		end

		for k1,v1 in pairs(MonDKP_Archive_Meta) do 		-- flags the archive active if any entries contain a value above 0
			for k2,v2 in pairs(v1) do
				if v2 and v2 > 0 then
					core.ArchiveActive = true 			-- flag is used to identify if lowest entry should be 1. No archive means an index of 1 must exist
				end
			end
		end
	end
end

----------------------------------
-- Register Events and Initiallize AddOn
----------------------------------

local events = CreateFrame("Frame", "EventsFrame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("GROUP_ROSTER_UPDATE");
events:RegisterEvent("ENCOUNTER_START");  		-- FOR TESTING PURPOSES.
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