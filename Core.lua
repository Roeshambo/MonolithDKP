--[[
	Core.lua is intended to store all core functions and variables to be used throughout the addon. 
	Don't put anything in here that you don't want to be loaded immediately after the Libs but before initialization.
--]]

local _, core = ...;
local _G = _G;
local L = core.L;

core.CommDKP = {};       -- UI Frames global
core.CommDKPApi = { __version = 1, pricelist = nil }
local CommDKP = core.CommDKP;
local CommDKPApi = core.CommDKPApi;

_G.CommDKPApi = CommDKPApi;

core.faction = UnitFactionGroup("player")


API_CLASSES = LOCALIZED_CLASS_NAMES_MALE;

core.CColors = {
	["UNKNOWN"] = { r = 0.627, g = 0.627, b = 0.627, hex = "A0A0A0" }
}
core.classes = {}

for class,friendlyClass in pairs(API_CLASSES) do
	local colorTable = {};
	local addColor = false;

	-- There appears to be no WoW API that lists out specific classes to a single faction
	-- Nor is there an API that identifies a specific class to a specific faction.
	-- I'd love to not hard code this though, but I seem to be out of luck.

	if core.faction == "Horde" then
		if class ~= "PALADIN" then
			addColor = true;
		end
	end

	if core.faction == "Alliance" then
		if class ~= "SHAMAN" then
			addColor = true;
		end
	end

	if addColor then
		colorTable.class = friendlyClass;
		colorTable.r, colorTable.g, colorTable.b, colorTable.hex = GetClassColor(class);

		core.CColors[class] = colorTable;
		table.insert(core.classes, class)
	end
end

--------------------------------------
-- Addon Defaults
--------------------------------------
local defaults = {
	theme = { r = 0.6823, g = 0.6823, b = 0.8666, hex = "aeaedd" },
	theme2 = { r = 1, g = 0.37, b = 0.37, hex = "ff6060" }
}

core.PriceSortButtons = {}
core.WorkingTable = {};       -- table of all entries from CommDKP:GetTable(CommDKP_DKPTable, true) that are currently visible in the window. From CommDKP:GetTable(CommDKP_DKPTable, true)
core.EncounterList = {      -- Event IDs must be in the exact same order as core.BossList declared in localization files
	MC = {
		663, 664, 665,
		666, 668, 667, 669, 
		670, 671, 672
	},
	BWL = {
		610, 611, 612,
		613, 614, 615, 616, 
		617
	},
	AQ = {
		709, 711, 712,
		714, 715, 717, 
		710, 713, 716
	},
	NAXX = {
		1107, 1110, 1116,
		1117, 1112, 1115, 
		1113, 1109, 1121,
		1118, 1111, 1108, 1120,
		1119, 1114
	},
	ZG = {
		787, 790, 793, 789, 784, 791,
		785, 792, 786, 788
	},
	AQ20 = {
		722, 721, 719, 718, 720, 723
	},
	ONYXIA = {1084},
	WORLD = {     -- No encounter IDs have been identified for these world bosses yet
		"Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Ysondre", "Taerar"
	}
}

core.CommDKPUI = {}        -- global storing entire Configuration UI to hide/show UI
core.MonVersion = "v3.2.3";
core.BuildNumber = 30203;
core.ReleaseNumber = 60
core.defaultTable = "__default";
core.SemVer = core.MonVersion.."-r"..tostring(core.ReleaseNumber);
core.UpgradeSchema = false;
core.TableWidth, core.TableRowHeight, core.TableNumRows, core.PriceNumRows = 500, 18, 27, 22; -- width, row height, number of rows
core.SelectedData = { player="none"};         -- stores data of clicked row for manipulation.
core.classFiltered = {};   -- tracks classes filtered out with checkboxes
core.IsOfficer = nil;
core.ShowState = false;
core.StandbyActive = false;
core.currentSort = "dkp"		-- stores current sort selection
core.BidInProgress = false;   -- flagged true if bidding in progress. else; false.
core.BidAuctioneer = false;
core.RaidInProgress = false;
core.RaidInPause = false;
core.NumLootItems = 0;        -- updates on LOOT_OPENED event
core.Initialized = false
core.InitStart = false
core.CurrentRaidZone = ""
core.LastKilledBoss = ""
core.ArchiveActive = false
core.CurView = "all"
core.CurSubView = "all"
core.LastVerCheck = 0
core.CenterSort = "class";
core.OOD = false
core.RealmName = nil;
core.FactionName = nil;
core.RepairWorking = false;

function CommDKP:GetCColors(class)
	if core.CColors then 
	local c
		if class then
		c = core.CColors[class] or core.CColors["UNKNOWN"];
	else
		c = core.CColors
	end
		return c;
	else
		return false;
	end
end

function CommDKP_round(number, decimals)
		number = number or 0;
		decimals = decimals or 0;
		return tonumber((("%%.%df"):format(decimals)):format(number))
end

function CommDKP:ResetPosition()
	core.DB.bidpos = nil;
	core.DB.timerpos = nil;
	CommDKP.UIConfig:ClearAllPoints();
	CommDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
	CommDKP.UIConfig:SetSize(550, 590);
	CommDKP.UIConfig.TabMenu:Hide()
	CommDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\expand-arrow");
	core.ShowState = false;
	CommDKP.BidTimer:ClearAllPoints()
	CommDKP.BidTimer:SetPoint("CENTER", UIParent)
	CommDKP:Print(L["POSITIONRESET"])
end

function CommDKP:GetGuildRank(player)
	local name, rank, rankIndex;
	local guildSize;

	if IsInGuild() then
		guildSize = GetNumGuildMembers();
		for i=1, guildSize do
			name, rank, rankIndex = GetGuildRosterInfo(i)
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if name == player then
				return rank, rankIndex;
			end
		end
		return L["NOTINGUILD"];
	end
	return L["NOGUILD"]
end

function CommDKP:GetDefaultEntity()
	local entityProfile = {}
	entityProfile = {
		player = "",
		class = "None",
		dkp = 0,
		previous_dkp = 0,
		lifetime_gained = 0,
		lifetime_spent = 0,
		rank = 20,
		rankName = "None",
		spec = "No Spec Reported",
		role = "No Role Reported",
		version = "Unknown"
  };
  return entityProfile;
end

function CommDKP:GetRealmName()

	if core.FactionName == nil or core.RealmName == nil then
		core.RealmName = GetRealmName();
		core.FactionName = UnitFactionGroup(UnitName("player"));
	end

	return core.RealmName.."-"..core.FactionName
end

function CommDKP:GetGuildName()
	local name;

	if IsInGuild() then
		name,_,_ = GetGuildInfo(UnitName("player"))
		if name then
			return name;
		else
			return L["NOGUILD"]
		end
	end
	return L["NOTINGUILD"];	
end

function CommDKP:GetGuildRankIndex(player)
	local name, rank;
	local guildSize,_,_ = GetNumGuildMembers();

	if IsInGuild() then
		for i=1, tonumber(guildSize) do
			name,_,rank = GetGuildRosterInfo(i)
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if name == player then
				return rank+1;
			end
		end
		return false;
	end
end

function CommDKP:CheckOfficer()      -- checks if user is an officer IF core.IsOfficer is empty. Use before checks against core.IsOfficer
	if not core.InitStart then 
		return
	end
	if core.IsOfficer == nil then      -- used as a redundency as it should be set on load in init.lua GUILD_ROSTER_UPDATE event
		if CommDKP:GetGuildRankIndex(UnitName("player")) == 1 then       -- automatically gives permissions above all settings if player is guild leader
			core.IsOfficer = true
			return;
		end
		if IsInGuild() then
			if #CommDKP:GetTable(CommDKP_Whitelist) > 0 then
				core.IsOfficer = false;
				for i=1, #CommDKP:GetTable(CommDKP_Whitelist) do
					if CommDKP:GetTable(CommDKP_Whitelist)[i] == UnitName("player") then
						core.IsOfficer = true;
					end
				end
			else
				local curPlayerRank = CommDKP:GetGuildRankIndex(UnitName("player"))
				if curPlayerRank then
					core.IsOfficer = C_GuildInfo.GuildControlGetRankFlags(curPlayerRank)[12]
				end
			end
		else
			core.IsOfficer = false;
		end
	end
end

function CommDKP:GetGuildRankGroup(index)                -- returns all members within a specific rank index as well as their index in the guild list (for use with GuildRosterSetPublicNote(index, "msg") and GuildRosterSetOfficerNote)
	local name, rank --, seed;                               -- local temp = CommDKP:GetGuildRankGroup(1)
	local group = {}                                      -- print(temp[1]["name"])
	local guildSize,_,_ = GetNumGuildMembers();

	if IsInGuild() then
		for i=1, tonumber(guildSize) do
			name,_,rank = GetGuildRosterInfo(i)
			--seed = CommDKP:RosterSeedExtract(i)
			rank = rank+1;
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if rank == index then
				--tinsert(group, { name = name, index = i, seed = seed })
				tinsert(group, { name = name, index = i })
			end
		end
		return group;
	end
end

function CommDKP:CheckRaidLeader()
	local tempName,tempRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole;

	for i=1, 40 do
		 
		 tempName, tempRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i);

		if tempName == UnitName("player") and tempRank == 2 then
			return true
		elseif tempName == UnitName("player") and tempRank < 2 then
			return false
		end
	end
	return false;
end

function CommDKP:GetThemeColor()
	local c = {defaults.theme, defaults.theme2};
	return c;
end

function CommDKP:GetPlayerDKP(player)
	local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), player)

	if search then
		return CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp
	else
		return false;
	end
end

function CommDKP:PurgeLootHistory()     -- cleans old loot history beyond history limit to reduce native system load
	local limit = core.DB.defaults.HistoryLimit

	if #CommDKP:GetTable(CommDKP_Loot, true) > limit then
		while #CommDKP:GetTable(CommDKP_Loot, true) > limit do
			CommDKP:SortLootTable()
			local path = CommDKP:GetTable(CommDKP_Loot, true)[#CommDKP:GetTable(CommDKP_Loot, true)]

			if not CommDKP:GetTable(CommDKP_Archive, true)[path.player] then
				CommDKP:GetTable(CommDKP_Archive, true)[path.player] = { dkp=path.cost, lifetime_spent=path.cost, lifetime_gained=0 }
			else
				CommDKP:GetTable(CommDKP_Archive, true)[path.player].dkp = CommDKP:GetTable(CommDKP_Archive, true)[path.player].dkp + path.cost
				CommDKP:GetTable(CommDKP_Archive, true)[path.player].lifetime_spent = CommDKP:GetTable(CommDKP_Archive, true)[path.player].lifetime_spent + path.cost
			end
			if not CommDKP:GetTable(CommDKP_Archive, true).LootMeta or CommDKP:GetTable(CommDKP_Archive, true).LootMeta < path.date then
				CommDKP:GetTable(CommDKP_Archive, true).LootMeta = path.date
			end

			tremove(CommDKP:GetTable(CommDKP_Loot, true), #CommDKP:GetTable(CommDKP_Loot, true))
		end
	end
end

function CommDKP:PurgeDKPHistory()     -- purges old entries and stores relevant data in each users CommDKP:GetTable(CommDKP_Archive, true) entry (dkp, lifetime spent, and lifetime gained) 
	local limit = core.DB.defaults.DKPHistoryLimit

	if #CommDKP:GetTable(CommDKP_DKPHistory, true) > limit then
		while #CommDKP:GetTable(CommDKP_DKPHistory, true) > limit do
			CommDKP:SortDKPHistoryTable()
			local path = CommDKP:GetTable(CommDKP_DKPHistory, true)[#CommDKP:GetTable(CommDKP_DKPHistory, true)]

			local players = {strsplit(",", strsub(path.players, 1, -2))}
			local dkp = {strsplit(",", path.dkp)}

			if #dkp == 1 then
				for i=1, #players do
					dkp[i] = tonumber(dkp[1])
				end
			else
				for i=1, #dkp do
					dkp[i] = tonumber(dkp[i])
				end
			end

			for i=1, #players do
				if not CommDKP:GetTable(CommDKP_Archive, true)[players[i]] then
					if ((dkp[i] > 0 and not path.deletes) or (dkp[i] < 0 and path.deletes)) and not strfind(path.dkp, "%-%d*%.?%d+%%") then
						CommDKP:GetTable(CommDKP_Archive, true)[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=dkp[i] }
					else
						CommDKP:GetTable(CommDKP_Archive, true)[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=0 }
					end
				else
					local dkpAmount = dkp[i] or 0
					CommDKP:GetTable(CommDKP_Archive, true)[players[i]].dkp = CommDKP:GetTable(CommDKP_Archive, true)[players[i]].dkp + dkpAmount
					if ((dkpAmount > 0 and not path.deletes) or (dkpAmount < 0 and path.deletes)) and not strfind(path.dkp, "%-%d*%.?%d+%%") then 	--lifetime gained if dkp addition and not a delete entry, dkp decrease and IS a delete entry
						CommDKP:GetTable(CommDKP_Archive, true)[players[i]].lifetime_gained = CommDKP:GetTable(CommDKP_Archive, true)[players[i]].lifetime_gained + path.dkp 				--or is NOT a decay
					end
				end
			end
			if not CommDKP:GetTable(CommDKP_Archive, true).DKPMeta or CommDKP:GetTable(CommDKP_Archive, true).DKPMeta < path.date then
				CommDKP:GetTable(CommDKP_Archive, true).DKPMeta = path.date
			end

			tremove(CommDKP:GetTable(CommDKP_DKPHistory, true), #CommDKP:GetTable(CommDKP_DKPHistory, true))
		end
	end
end

function CommDKP:FormatTime(time)
	local str = date("%y/%m/%d %H:%M:%S", time)

	return str;
end

function CommDKP:Print(...)        --print function to add "CommunityDKP:" to the beginning of print() outputs.
	if core.DB == nil or not core.DB.defaults.SuppressNotifications then
		local defaults = CommDKP:GetThemeColor();
		local prefix = string.format("|cff%s%s|r|cff%s", defaults[1].hex:upper(), "CommunityDKP:", defaults[2].hex:upper());
		local suffix = "|r";

		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i)

			if core.DB == nil or core.DB.defaults.ChatFrames[name] then
				_G["ChatFrame"..i]:AddMessage(string.join(" ", prefix, ..., suffix));
			end
		end
	end
end

function CommDKP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
	local btn = CreateFrame("Button", nil, relativeFrame, "CommunityDKPButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
	btn:SetSize(100, 30);
	btn:SetText(text);
	btn:GetFontString():SetTextColor(1, 1, 1, 1)
	btn:SetNormalFontObject("CommDKPSmallCenter");
	btn:SetHighlightFontObject("CommDKPSmallCenter");
	return btn; 
end

function CommDKP:BroadcastTimer(seconds, ...)       -- broadcasts timer and starts it natively
	if IsInRaid() and core.IsOfficer == true then
		local title = ...;
		if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
			CommDKP:Print(L["INVALIDTIMER"]);
			return;
		end
		CommDKP:StartTimer(seconds, ...)
		CommDKP.Sync:SendData("CommDKPCommand", "StartTimer#"..seconds.."#"..title)
	end
end

function CommDKP:CreateContainer(parent, name, header)
	local f = CreateFrame("Frame", "CommDKP"..name, parent);
	f:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,0.5)

	f.header = CreateFrame("Frame", "CommDKP"..name.."Header", f)
	f.header:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f.header:SetBackdropColor(0,0,0,1)
	f.header:SetBackdropBorderColor(0,0,0,1)
	f.header:SetPoint("LEFT", f, "TOPLEFT", 20, 0)
	f.header.text = f.header:CreateFontString(nil, "OVERLAY")
	f.header.text:SetFontObject("CommDKPSmallCenter");
	f.header.text:SetPoint("CENTER", f.header, "CENTER", 0, 0);
	f.header.text:SetText(header);
	f.header:SetWidth(f.header.text:GetWidth() + 30)
	f.header:SetHeight(f.header.text:GetHeight() + 4)

	return f;
end

function CommDKP:StartTimer(seconds, ...)
	local duration = tonumber(seconds)
	local alpha = 1;

	if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
		CommDKP:Print(L["INVALIDTIMER"]);
		return;
	end

	CommDKP.BidTimer = CommDKP.BidTimer or CommDKP:CreateTimer();    -- recycles timer frame so multiple instances aren't created
	CommDKP.BidTimer:SetShown(not CommDKP.BidTimer:IsShown())         -- shows if not shown
	if CommDKP.BidTimer:IsShown() == false then                    -- terminates function if hiding timer
		return;
	end

	CommDKP.BidTimer:SetMinMaxValues(0, duration)
	CommDKP.BidTimer.timerTitle:SetText(...)
	PlaySound(8959)

	if core.DB.timerpos then
		local a = core.DB.timerpos                   -- retrieves timer's saved position from SavedVariables
		CommDKP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
	else
		CommDKP.BidTimer:SetPoint("CENTER")                      -- sets to center if no position has been saved
	end

	local timer = 0             -- timer starts at 0
	local timerText;            -- count down when below 1 minute
	local modulo                -- remainder after divided by 60
	local timerMinute           -- timerText / 60 to get minutes.
	local audioPlayed = false;  -- so audio only plays once
	local expiring;             -- determines when red blinking bar starts. @ 30 sec if timer > 120 seconds, @ 10 sec if below 120 seconds

	CommDKP.BidTimer:SetScript("OnUpdate", function(self, elapsed)   -- timer loop
		timer = timer + elapsed
		timerText = CommDKP_round(duration - timer, 1)
		if tonumber(timerText) > 60 then
			timerMinute = math.floor(tonumber(timerText) / 60, 0);
			modulo = bit.mod(tonumber(timerText), 60);
			if tonumber(modulo) < 10 then modulo = "0"..modulo end
			CommDKP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
		else
			CommDKP.BidTimer.timertext:SetText(timerText)
		end
		if duration >= 120 then
			expiring = 30;
		else
			expiring = 10;
		end
		if tonumber(timerText) < expiring then
			if audioPlayed == false then
				PlaySound(23639);
			end
			if tonumber(timerText) < 10 then
				audioPlayed = true
				StopSound(23639)
			end
			CommDKP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
			if alpha > 0 then
				alpha = alpha - 0.005
			elseif alpha <= 0 then
				alpha = 1
			end
		else
			CommDKP.BidTimer:SetStatusBarColor(0, 0.8, 0)
		end
		self:SetValue(timer)
		if timer >= duration then
			CommDKP.BidTimer:SetScript("OnUpdate", nil)
			CommDKP.BidTimer:Hide();
		end
	end)
end

function CommDKP:StatusVerify_Update()
	if (CommDKP.UIConfig and not CommDKP.UIConfig:IsShown()) or 
	   (#CommDKP:GetTable(CommDKP_DKPHistory, true, CommDKP:GetCurrentTeamIndex()) == 0 and #CommDKP:GetTable(CommDKP_Loot, true, CommDKP:GetCurrentTeamIndex()) == 0) then
		-- blocks update if dkp window is closed. Updated when window is opened anyway
		return;
	end

	if IsInGuild() and core.Initialized then
		core.OOD = false

		local missing = {}

		if (CommDKP:GetTable(CommDKP_Loot, true, CommDKP:GetCurrentTeamIndex()).seed and strfind(CommDKP:GetTable(CommDKP_Loot, true, CommDKP:GetCurrentTeamIndex()).seed, "-")) or
		   (CommDKP:GetTable(CommDKP_DKPHistory, true, CommDKP:GetCurrentTeamIndex()).seed and strfind(CommDKP:GetTable(CommDKP_DKPHistory, true, CommDKP:GetCurrentTeamIndex()).seed, "-"))
		then

			local search_dkp = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true, CommDKP:GetCurrentTeamIndex()), CommDKP:GetTable(CommDKP_DKPHistory, true, CommDKP:GetCurrentTeamIndex()).seed, "index")
			local search_loot = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true, CommDKP:GetCurrentTeamIndex()), CommDKP:GetTable(CommDKP_Loot, true, CommDKP:GetCurrentTeamIndex()).seed, "index")
	
			if not search_dkp then
				core.OOD = true
				local officer1, date1 = strsplit("-", CommDKP:GetTable(CommDKP_DKPHistory, true, CommDKP:GetCurrentTeamIndex()).seed)
				if (date1 and tonumber(date1) < (time() - 1209600)) or not CommDKP:ValidateSender(officer1) then   -- does not consider if claimed entry was made more than two weeks ago or name is not an officer
					core.OOD = false
				else
					date1 = date("%m/%d/%y %H:%M:%S", tonumber(date1))
					missing[officer1] = date1 			-- if both missing seeds identify the same officer, it'll only list once
				end
			end
			
			if not search_loot and not core.OOD then
				core.OOD = true
				local officer2, date2 = strsplit("-", CommDKP:GetTable(CommDKP_Loot, true, CommDKP:GetCurrentTeamIndex()).seed)
				if (date2 and tonumber(date2) < (time() - 1209600)) or not CommDKP:ValidateSender(officer2) then   -- does not consider if claimed entry was made more than two weeks ago or name is not an officer
					core.OOD = false
				else
					date2 = date("%m/%d/%y %H:%M:%S", tonumber(date2))
					missing[officer2] = date2
				end
			end
		end

		if not core.OOD then
			CommDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\up-to-date")
			CommDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ALLTABLES"].." |cff00ff00"..L["UPTODATE"].."|r.", 1.0, 1.0, 1.0, false);
				if core.IsOfficer then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			CommDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			return true;
		else
			CommDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\out-of-date")
			CommDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				if #CommDKP:GetTable(CommDKP_Loot, true, CommDKP:GetCurrentTeamIndex()) == 0 and #CommDKP:GetTable(CommDKP_DKPHistory, true, CommDKP:GetCurrentTeamIndex()) == 0 then
					GameTooltip:AddLine(L["TABLESAREEMPTY"], 1.0, 1.0, 1.0, false);
				else
					GameTooltip:AddLine(L["ONETABLEOOD"].." |cffff0000"..L["OUTOFDATE"].."|r.", 1.0, 1.0, 1.0, false);
				end
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(L["MISSINGENT"]..":", 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine(L["PLAYER"], L["CREATED"],1,1,1,1,1,1)
				for k,v in pairs(missing) do
					local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, CommDKP:GetCurrentTeamIndex()), k)

					if classSearch then
						c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true, CommDKP:GetCurrentTeamIndex())[classSearch[1][1]].class)
					else
						c = { hex="ffffffff" }
					end
					GameTooltip:AddDoubleLine("|c"..c.hex..k.."|r",v,1,1,1,1,1,1);
				end
				if core.IsOfficer then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			CommDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			return false;
		end
	elseif core.Initialized then
		CommDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["CURRNOTINGUILD"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show()
		end)
		CommDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		return false;
	end
end

-------
-- TEAM FUNCTIONS
-------
function CommDKP:tablelength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1 
	end
	return count
end

function CommDKP:GetCurrentTeamIndex() 
	local _tmpString = CommDKP:GetTable(CommDKP_DB, false)["defaults"]["CurrentTeam"] or "0"
	return _tmpString
end

function CommDKP:GetCurrentTeamName()
	local _string = "Unguilded";
	local teams = CommDKP:GetTable(CommDKP_DB, false)["teams"];

	if CommDKP:tablelength(teams) > 0 then
		_string = CommDKP:GetTable(CommDKP_DB, false)["teams"][CommDKP:GetCurrentTeamIndex()].name
	end

	return _string
end

function CommDKP:GetTeamName(index)
	local _string = "Unguilded";
	if index == nil then return _string end
	local teamName = CommDKP:GetTable(CommDKP_DB, false)["teams"][index]["name"];

	if teamName == nil then return "no team" end;

	return teamName;
end

function CommDKP:GetGuildTeamList(asObject) 
	local asObject = asObject or false
	local _list = {};
	local _tmp = CommDKP:GetTable(CommDKP_DB, false)["teams"]

	for k,v in pairs(_tmp) do
		if(type(v) == "table") then
			if asObject then
				local team = v;
				team["index"] = tonumber(k);
				table.insert(_list, team);
			else
				table.insert(_list, {tonumber(k), v.name})
			end
		end
	end
	-- so, because team "index" is a string Lua doesn't give a flying fuck
	-- about order of adding elements to "string" indexed table so we have to unfuck it
	table.sort(_list,  
		function(a, b)
			if asObject then
				return a.index < b.index
			else
				return a[1] < b[1]
			end
		end
	)

	return _list
end

function CommDKP:FormatPriceTable(minBids, convertToTable)
	minBids = minBids or CommDKP:GetTable(CommDKP_MinBids, true);
	convertToTable = convertToTable or false; --false means it will convert to an array
	local priceTable = {}

	if withIds then
		for i=1, #minBids do
			priceTable[minBids[i].itemID] = minBids[i];
		end
	else
		for key, value in pairs(minBids) do
			tinsert(priceTable, value);
		end
	end
	return priceTable;
end

-- moved to core from ManageEntries as this is called from comm.lua aswell
function CommDKP:SetCurrentTeam(index)
	CommDKP:GetTable(CommDKP_DB, false)["defaults"]["CurrentTeam"] = tostring(index);
	CommDKP:StatusVerify_Update();
	UIDropDownMenu_SetText(CommDKP.UIConfig.TeamViewChangerDropDown, CommDKP:GetCurrentTeamName());

	-- reset dkp table and update it
	core.WorkingTable = CommDKP:GetTable(CommDKP_DKPTable, true);
	core.PriceTable	= CommDKP:FormatPriceTable();

	CommDKP:DKPTable_Update();

	-- reset dkp history table and update it
	CommDKP:DKPHistory_Update(true);
	-- reset loot history
	CommDKP:LootHistory_Update(L["NOFILTER"]);
	-- update class graph
	CommDKP:ClassGraph_Update();
	-- update price table
	CommDKP:PriceTable_Update(0);
	-- broadcast Talents and Roles
	CommDKP:SendTalentsAndRole();
end

function CommDKP:SendTalentsAndRole()

	--Does a Profile Exist? If no, exit, nothing to do here.
	local oldProfile = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), UnitName("player"), "player")
	local newProfile = CommDKP:GetTable(CommDKP_Profiles, true)[UnitName("player")]
	if newProfile == nil and not oldProfile then
		return;
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

	local profile = newProfile or CommDKP:GetDefaultEntity();
	profile.player=UnitName("player");
	profile.version=core.SemVer;

	CommDKP:GetTable(CommDKP_Profiles, true)[UnitName("player")] = profile;

	if oldProfile then
		CommDKP:GetTable(CommDKP_DKPTable, true)[oldProfile[1][1]].version = core.SemVer;
	end

	CommDKP.Sync:SendData("CDKProfileSend", profile)
	CommDKP.Sync:SendData("CommDKPTalents", talBuild)
	CommDKP.Sync:SendData("CommDKPRoles", talRole)

	table.wipe(TalTrees);
end

-------
-- TEAM FUNCTIONS END
-------

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep (use field only if you wish to search a specific key IE: CommDKP:GetTable(CommDKP_DKPTable, true), "Vapok", "player" would only search for Vapok in the player key)
-- returns an indexed array of the keys to get to searched value
-- First key is the result (ie if it's found 8 times, it will return 8 tables containing results).
-- Second key holds the path to the value searched. So to get to a player searched on DKPTable that returned 1 result, CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]][search[1][2]] would point at the "player" field
-- if the result is 1 level deeper, it would be CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]][search[1][2]][search[1][3]].  CommDKP:GetTable(CommDKP_DKPTable, true)[search[2][1]][search[2][2]][search[2][3]] would locate the second return, if there is one.
-- use to search for players in SavedVariables. Only two possible returns is the table or false.
-------------------------------------
function CommDKP:Table_Search(tar, val, field)
	local value = string.upper(tostring(val));
	local location = {}
	for k,v in pairs(tar) do
		if(type(v) == "table") then
			local temp1 = k
			for k,v in pairs(v) do
				if(type(v) == "table") then
					local temp2 = k;
					for k,v in pairs(v) do
						if(type(v) == "table") then
							local temp3 = k
							for k,v in pairs(v) do
								if string.upper(tostring(v)) == value then
									if field then
										if k == field then
											tinsert(location, {temp1, temp2, temp3, k} )
										end
									else
										tinsert(location, {temp1, temp2, temp3, k} )
									end
								end;
							end
						end
						if string.upper(tostring(v)) == value then
							if field then
								if k == field then
									tinsert(location, {temp1, temp2, k} )
								end
							else
								tinsert(location, {temp1, temp2, k} )
							end
						end;
					end
				end
				if string.upper(tostring(v)) == value then
					if field then
						if k == field then
							tinsert(location, {temp1, k} )
						end
					else
						tinsert(location, {temp1, k} )
					end
				end;
			end
		end
		if string.upper(tostring(v)) == value then
			if field then
				if k == field then
					tinsert(location, k)
				end
			else
				tinsert(location, k)
			end
		end;
	end
	if (#location > 0) then
		return location;
	else
		return false;
	end
end

function CommDKP:TableStrFind(tar, val, field)              -- same function as above, but searches values that contain the searched string rather than exact string matches
	local value = string.upper(tostring(val));        -- ex. CommDKP:TableStrFind(CommDKP:GetTable(CommDKP_DKPHistory, true), "Vapok") will return the path to any table element that contains "Vapok"
	local location = {}
	for k,v in pairs(tar) do
		if(type(v) == "table") then
			local temp1 = k
			for k,v in pairs(v) do
				if(type(v) == "table") then
					local temp2 = k;
					for k,v in pairs(v) do
						if(type(v) == "table") then
							local temp3 = k
							for k,v in pairs(v) do
								if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
									if field then
										if k == field then
											tinsert(location, {temp1, temp2, temp3, k} )
										end
									else
										tinsert(location, {temp1, temp2, temp3, k} )
									end
								end;
							end
						end
						if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
							if field then
								if k == field then
									tinsert(location, {temp1, temp2, k} )
								end
							else
								tinsert(location, {temp1, temp2, k} )
							end
						end;
					end
				end
				if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
					if field then
						if k == field then
							tinsert(location, {temp1, k} )
						end
					else
						tinsert(location, {temp1, k} )
					end
				end;
			end
		end
		if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
			if field then
				if k == field then
					tinsert(location, k)
				end
			else
				tinsert(location, k)
			end
		end;
	end
	if (#location > 0) then
		return location;
	else
		return false;
	end
end

function CommDKP:DKPTable_Set(tar, field, value, loot)                -- updates field with value where tar is found (IE: CommDKP:DKPTable_Set("Vapok", "dkp", 10) adds 10 dkp to user Vapok). loot = true/false if it's to alter lifetime_spent
	local result = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), tar);
	for i=1, #result do
		local current = CommDKP:GetTable(CommDKP_DKPTable, true)[result[i][1]][field];
		if(field == "dkp") then
			CommDKP:GetTable(CommDKP_DKPTable, true)[result[i][1]][field] = CommDKP_round(tonumber(current + value), core.DB.modes.rounding)
			if value > 0 and loot == false then
				CommDKP:GetTable(CommDKP_DKPTable, true)[result[i][1]]["lifetime_gained"] = CommDKP_round(tonumber(CommDKP:GetTable(CommDKP_DKPTable, true)[result[i][1]]["lifetime_gained"] + value), core.DB.modes.rounding)
			elseif value < 0 and loot == true then
				CommDKP:GetTable(CommDKP_DKPTable, true)[result[i][1]]["lifetime_spent"] = CommDKP_round(tonumber(CommDKP:GetTable(CommDKP_DKPTable, true)[result[i][1]]["lifetime_spent"] + value), core.DB.modes.rounding)
			end
		else
			CommDKP:GetTable(CommDKP_DKPTable, true)[result[i][1]][field] = value
		end
	end
	CommDKP:DKPTable_Update()
end
