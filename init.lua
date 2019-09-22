local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

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
		if core.IsOfficer then
			MonDKP:ToggleDKPModesWindow()
		else
			MonDKP:Print("You do not have permission tok access that feature.")
		end
	end,
	["help"] = function()
		print(" ");
		MonDKP:Print("List of slash commands:")
		MonDKP:Print("|cff00cc66/dkp|r - Launches DKP Window");
		MonDKP:Print("|cff00cc66/dkp ?|r - Shows Help Info");
		MonDKP:Print("|cff00cc66/dkp reset|r - Resets DKP Window Position/Size");
		MonDKP:Print("|cff00cc66/dkp timer|r - Creates Raid Timer (Officers Only) (eg. /dkp timer 120 Pizza Break!)");
		MonDKP:Print("|cff00cc66/dkp bid|r - Opens Bid Window (Officers Only) (eg. /dkp bid [item link])");
		MonDKP:Print("|cff00cc66/dkp modes|r - Opens DKP Modes Window (Officers Only)");
		MonDKP:Print("|cff00cc66/dkp export|r - Opens window to export all DKP information to HTML, CSV or XML. (More export implementations to come)");
		print(" ");
		MonDKP:Print("Whisper Commands (To Designated Officers)");
		MonDKP:Print("|cff00cc66!bid (or !bid <value>)|r - Bid on current item when bidding is opened.");
		MonDKP:Print("|cff00cc66!dkp (or !dkp <player_name>)|r - Returns your current DKP (Or DKP of <player_name>)");
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
	elseif event == "CHAT_MSG_WHISPER" then
		MonDKP:CheckOfficer()
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1) and core.IsOfficer == true then
			MonDKP_CHAT_MSG_WHISPER(arg1, ...)
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		GuildInfo()
		if IsInGuild() then
			MonDKP:CheckOfficer()
			self:UnregisterEvent("GUILD_ROSTER_UPDATE")
		end
	elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
		MonDKP:CheckOfficer()
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1) and core.IsOfficer == true then
			MonDKP_CHAT_MSG_WHISPER(arg1, ...)
		end
	elseif event == "CHAT_MSG_GUILD" then
		MonDKP:CheckOfficer()
		if (core.BidInProgress or string.find(arg1, "!dkp") == 1) and core.IsOfficer == true then
			MonDKP_CHAT_MSG_WHISPER(arg1, ...)
		end
	--elseif event == "CHAT_MSG_SYSTEM" then
		--MonoDKP_CHAT_MSG_SYSTEM(arg1)
	--[[elseif event == "GROUP_ROSTER_UPDATE" then 			-- functionality unneccessary
		if not C_GuildInfo.GuildRoster() then
			MonDKP:CheckOfficer()
			if core.IsOfficer == true then
				AddRaidToDKPTable()
			end
		end--]]
	elseif event == "GUILD_ROSTER_UPDATE" then 		-- checks if player is an officer on load
		if IsInGuild() then
			MonDKP:CheckOfficer()
			if core.IsOfficer ~= "" then
				self:UnregisterEvent("GUILD_ROSTER_UPDATE")
			end
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if IsInRaid() then 					-- only processes combat log events if in raid
			local _,arg1,_,_,_,_,_,_,arg2 = CombatLogGetCurrentEventInfo();			-- run operation when boss is killed
			if arg1 == "UNIT_DIED" then
				MonDKP:CheckOfficer()
				if core.IsOfficer == true then
					if MonDKP:TableStrFind(core.BossList, arg2) then
						MonDKP.ConfigTab2.BossKilledDropdown:SetValue(arg2)
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
		end
	elseif event == "LOOT_OPENED" then
		MonDKP_Register_ShiftClickLootWindowHook()
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
		if not MonDKP_DB.modes or not MonDKP_DB.modes.mode then MonDKP_DB.modes = { mode = "Minimum Bid Values", SubZeroBidding = false, rounding = 0, AddToNegative = false, increment = 60, ZeroSumBidType = "Static" } end;
		if not MonDKP_DB.modes.ZeroSumBank then MonDKP_DB.modes.ZeroSumBank = { balance = 0 } end
		if not MonDKP_DB.modes.channels then MonDKP_DB.modes.channels = { raid = true, whisper = true, guild = true } end
		if not MonDKP_DB.modes.costvalue then MonDKP_DB.modes.costvalue = "Integer" end
		if not MonDKP_DB.modes.rolls or not MonDKP_DB.modes.rolls.min then MonDKP_DB.modes.rolls = { min = 1, max = 100, UsePerc = false, AddToMax = 0 } end

	    ------------------------------------
	    --	Import SavedVariables
	    ------------------------------------
	    core.settings.DKPBonus = MonDKP_DB.DKPBonus 				--imports default settings (Options Tab)
	    core.settings.MinBidBySlot = MonDKP_DB.MinBidBySlot			--imports default minimum bids (Options Tab)
	    core.settings.defaults = MonDKP_DB.defaults					--imports default UI settings
	    core.WorkingTable = MonDKP_DKPTable;						--imports full DKP table to WorkingTable for list manipulation without altering the SavedVariable
	    core.CurrentRaidZone = MonDKP_DB.bossargs.CurrentRaidZone;	-- stores raid zone as a redundency
		core.LastKilledBoss = MonDKP_DB.bossargs.LastKilledBoss;	-- stores last boss killed as a redundency

		table.sort(MonDKP_DKPTable, function(a, b)
			return a["player"] < b["player"]
		end)

		MonDKP:Print("Version "..core.MonVersion..", created and maintained by Roeshambo@Stalagg-PvP");
		MonDKP:Print("Loaded "..#MonDKP_DKPTable.." player records, "..#MonDKP_Loot.." loot history records and "..#MonDKP_DKPHistory.." dkp history records.");
		MonDKP:Print("Use /dkp ? for help and submit any bugs @ https://github.com/Roeshambo/MonolithDKP/issues");

		for i=1, #MonDKP_DKPTable do
			MonDKP_DKPTable[i].class = string.upper(MonDKP_DKPTable[i].class)
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
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:RegisterEvent("CHAT_MSG_RAID")
events:RegisterEvent("CHAT_MSG_RAID_LEADER")
events:RegisterEvent("CHAT_MSG_WHISPER");
events:RegisterEvent("CHAT_MSG_GUILD")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:SetScript("OnEvent", MonDKP_OnEvent); -- calls the above MonDKP_OnEvent function to determine what to do with the event