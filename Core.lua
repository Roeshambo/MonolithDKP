--[[
	Core.lua is intended to store all core functions and variables to be used throughout the addon. 
	Don't put anything in here that you don't want to be loaded immediately after the Libs but before initialization.
--]]

local _, core = ...;
local _G = _G;
local L = core.L;

core.MonDKP = {};       -- UI Frames global
local MonDKP = core.MonDKP;

local tc_colors = {
	["Druid"] = { r = 1, g = 0.49, b = 0.04, hex = "FF7D0A" },
	["Hunter"] = {  r = 0.67, g = 0.83, b = 0.45, hex = "ABD473" },
	["Mage"] = { r = 0.25, g = 0.78, b = 0.92, hex = "40C7EB" },
	["Priest"] = { r = 1, g = 1, b = 1, hex = "FFFFFF" },
	["Rogue"] = { r = 1, g = 0.96, b = 0.41, hex = "FFF569" },
	["Shaman"] = { r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
	["Paladin"] = { r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
	["Warlock"] = { r = 0.53, g = 0.53, b = 0.93, hex = "8787ED" },
	["Warrior"] = { r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E" }
}

local tc_classes = {}

core.faction = UnitFactionGroup("player")
if core.faction == "Horde" then
	tc_classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
elseif core.faction == "Alliance" then
	tc_classes = { "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Warlock", "Warrior" }
end

core.CColors = {
	["UNKNOWN"] = { r = 0.627, g = 0.627, b = 0.627, hex = "A0A0A0" }
}
core.classes = {}
for i = 1, #tc_classes do
	local cname = tc_classes[i]
	local lname = string.upper(cname)
	core.CColors[lname] = tc_colors[cname]
	table.insert(core.classes, lname)
end

--------------------------------------
-- Addon Defaults
--------------------------------------
local defaults = {
	theme = { r = 0.6823, g = 0.6823, b = 0.8666, hex = "aeaedd" },
	theme2 = { r = 1, g = 0.37, b = 0.37, hex = "ff6060" }
}

core.WorkingTable = {};       -- table of all entries from MonDKP_DKPTable that are currently visible in the window. From MonDKP_DKPTable
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

core.MonDKPUI = {}        -- global storing entire Configuration UI to hide/show UI
core.MonVersion = "v2.0.2 beta 2";
core.BuildNumber = 20002.02;
core.TableWidth, core.TableRowHeight, core.TableNumRows = 500, 18, 27; -- width, row height, number of rows
core.SelectedData = { player="none"};         -- stores data of clicked row for manipulation.
core.classFiltered = {};   -- tracks classes filtered out with checkboxes
core.IsOfficer = nil;
core.ShowState = false;
core.StandbyActive = false;
core.currentSort = "class"		-- stores current sort selection
core.BidInProgress = false;   -- flagged true if bidding in progress. else; false.
core.RaidInProgress = false;
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
core.Migrated = false
core.ErrantInProgress = false

function MonDKP:GetCColors(class)
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

function MonDKP_round(number, decimals)
		return tonumber((("%%.%df"):format(decimals)):format(number))
end

function MonDKP:ResetPosition()
	MonDKP.UIConfig:ClearAllPoints();
	MonDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
	MonDKP.UIConfig:SetSize(550, 590);
	MonDKP.UIConfig.TabMenu:Hide()
	MonDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\expand-arrow");
	core.ShowState = false;
	MonDKP.BidTimer:ClearAllPoints()
	MonDKP.BidTimer:SetPoint("CENTER", UIParent)
	MonDKP:Print(L["POSITIONRESET"])
end

function MonDKP:GetGuildRank(player)
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

function MonDKP:GetGuildRankIndex(player)
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

function MonDKP:CheckOfficer()      -- checks if user is an officer IF core.IsOfficer is empty. Use before checks against core.IsOfficer
	if not core.Initialized then return end
	if core.IsOfficer == nil then      -- used as a redundency as it should be set on load in init.lua GUILD_ROSTER_UPDATE event
		if MonDKP:GetGuildRankIndex(UnitName("player")) == 1 then       -- automatically gives permissions above all settings if player is guild leader
			core.IsOfficer = true
			MonDKP.ConfigTab3.WhitelistContainer:Show()
			return;
		end
		if IsInGuild() then
			if #MonDKP_Whitelist > 0 then
				core.IsOfficer = false;
				for i=1, #MonDKP_Whitelist do
					if MonDKP_Whitelist[i] == UnitName("player") then
						core.IsOfficer = true;
					end
				end
			else
				local curPlayerRank = MonDKP:GetGuildRankIndex(UnitName("player"))
				if curPlayerRank then
					core.IsOfficer = C_GuildInfo.GuildControlGetRankFlags(curPlayerRank)[12]
				end
			end
		else
			core.IsOfficer = false;
		end
	end
end

function MonDKP:GetGuildRankGroup(index)                -- returns all members within a specific rank index as well as their index in the guild list (for use with GuildRosterSetPublicNote(index, "msg") and GuildRosterSetOfficerNote)
	local name, rank --, seed;                               -- local temp = MonDKP:GetGuildRankGroup(1)
	local group = {}                                      -- print(temp[1]["name"])
	local guildSize,_,_ = GetNumGuildMembers();

	if IsInGuild() then
		for i=1, tonumber(guildSize) do
			name,_,rank = GetGuildRosterInfo(i)
			--seed = MonDKP:RosterSeedExtract(i)
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

function MonDKP:CheckRaidLeader()
	local tempName,tempRank;

	for i=1, 40 do
		tempName, tempRank = GetRaidRosterInfo(i)

		if tempName == UnitName("player") and tempRank == 2 then
			return true
		end
	end
	return false;
end

function MonDKP:GetThemeColor()
	local c = {defaults.theme, defaults.theme2};
	return c;
end

--[[
NO LONGER IN USE

function MonDKP:GenerateSeed()
	local seed = tonumber(date("!%y%m%d%H%M%S")) -- using utc times instead of time()
	return seed
end

function MonDKP:RosterSeedUpdate(index)
	local oldseed, note = MonDKP:RosterSeedExtract(index)
	local newseed = MonDKP:GenerateSeed()
	local textseed = "{MonDKP=" .. tostring(newseed) .. "}"
	if oldseed > 0 then
			note = string.gsub(note, "{MonDKP=(%d+)}", textseed)
	else
			note = note .. " " .. textseed
	end

	if strlen(note) > 31 then   -- validates note length. If it's too long for the public note, truncates it to fit the seed.
		note = strsub(note, 1, 9)
		note = note .. " " .. textseed

		StaticPopupDialogs["SEED_VALIDATE"] = {
			text = L["NOTETOOLONG"],
			button1 = "Ok",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("SEED_VALIDATE")
	end

	GuildRosterSetPublicNote(index, note)
	return newseed
end

function MonDKP:RosterSeedExtract(index)
	local seed, note
	_,_,_,_,_,_,note = GetGuildRosterInfo(index)
	seed = string.match(note, "{MonDKP=(%d+)}")
	if not seed then
			seed = 0
		end
	return tonumber(seed), note
end

function MonDKP:UpdateSeeds()		-- updates seeds on leaders note as well as all 3 tables
	local leader = MonDKP:GetGuildRankGroup(1)
	local seed = MonDKP:RosterSeedUpdate(leader[1].index)
	
	MonDKP_DKPTable.seed = seed
	MonDKP_DKPHistory.seed = seed
	MonDKP_Loot.seed = seed
end
--]]

function MonDKP:GetPlayerDKP(player)
	local search = MonDKP:Table_Search(MonDKP_DKPTable, player)

	if search then
		return MonDKP_DKPTable[search[1][1]].dkp
	else
		return false;
	end
end

function MonDKP:PurgeLootHistory()     -- cleans old loot history beyond history limit to reduce native system load
	local limit = MonDKP_DB.defaults.HistoryLimit

	if #MonDKP_Loot > limit then
		while #MonDKP_Loot > limit do
			MonDKP:SortLootTable()
			local curOfficer, curIndex = strsplit("-", MonDKP_Loot[#MonDKP_Loot].index)
			curIndex = tonumber(curIndex)
			local newLowest = curIndex + 1
			local path = MonDKP_Loot[#MonDKP_Loot]

			if not MonDKP_Archive[path.player] then
				MonDKP_Archive[path.player] = { dkp=path.cost, lifetime_spent=path.cost, lifetime_gained=0 }
			else
				MonDKP_Archive[path.player].dkp = MonDKP_Archive[path.player].dkp + path.cost
				MonDKP_Archive[path.player].lifetime_spent = MonDKP_Archive[path.player].lifetime_spent + path.cost
			end

			if not MonDKP_Archive_Meta.Loot[curOfficer] or MonDKP_Archive_Meta.Loot[curOfficer] < curIndex then
				MonDKP_Archive_Meta.Loot[curOfficer] = curIndex
			end

			if newLowest > MonDKP_Meta.Loot[curOfficer].lowest then
				MonDKP_Meta.Loot[curOfficer].lowest = newLowest
			end

			tremove(MonDKP_Loot, #MonDKP_Loot)
		end
	end
end

function MonDKP:PurgeDKPHistory()     -- purges old entries and stores relevant data in each users MonDKP_Archive entry (dkp, lifetime spent, and lifetime gained) 
	local limit = MonDKP_DB.defaults.DKPHistoryLimit

	if #MonDKP_DKPHistory > limit then
		while #MonDKP_DKPHistory > limit do
			MonDKP:SortDKPHistoryTable()
			local path = MonDKP_DKPHistory[#MonDKP_DKPHistory]
			local players = {strsplit(",", strsub(path.players, 1, -2))}
			local dkp = {strsplit(",", path.dkp)}
			local curOfficer, curIndex = strsplit("-", path.index)
			curIndex = tonumber(curIndex)
			local newLowest = curIndex + 1

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
				if not MonDKP_Archive[players[i]] then
					if ((dkp[i] > 0 and not path.deletes) or (dkp[i] < 0 and path.deletes)) and not strfind(path.dkp, "%-%d+%%") then
						MonDKP_Archive[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=dkp[i] }
					else
						MonDKP_Archive[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=0 }
					end
				else
					MonDKP_Archive[players[i]].dkp = MonDKP_Archive[players[i]].dkp + dkp[i]
					if ((dkp[i] > 0 and not path.deletes) or (dkp[i] < 0 and path.deletes)) and not strfind(path.dkp, "%-%d+%%") then 	--lifetime gained if dkp addition and not a delete entry, dkp decrease and IS a delete entry
						MonDKP_Archive[players[i]].lifetime_gained = MonDKP_Archive[players[i]].lifetime_gained + path.dkp 				--or is NOT a decay
					end
				end
			end

			if not MonDKP_Archive_Meta.DKP[curOfficer] or MonDKP_Archive_Meta.DKP[curOfficer] < curIndex then
				MonDKP_Archive_Meta.DKP[curOfficer] = curIndex
			end

			if newLowest > MonDKP_Meta.DKP[curOfficer].lowest then
				MonDKP_Meta.DKP[curOfficer].lowest = newLowest
			end

			tremove(MonDKP_DKPHistory, #MonDKP_DKPHistory)
		end
	end
end

function MonDKP:FormatTime(time)
	local str = date("%y/%m/%d %H:%M:%S", time)

	return str;
end

function MonDKP:Print(...)        --print function to add "MonolithDKP:" to the beginning of print() outputs.
	if not MonDKP_DB.defaults.supressNotifications then
		local defaults = MonDKP:GetThemeColor();
		local prefix = string.format("|cff%s%s|r|cff%s", defaults[1].hex:upper(), "MonolithDKP:", defaults[2].hex:upper());
		local suffix = "|r";

		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i)

			if MonDKP_DB.defaults.ChatFrames[name] then
				_G["ChatFrame"..i]:AddMessage(string.join(" ", prefix, ..., suffix));
			end
		end
	end
end

function MonDKP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
	local btn = CreateFrame("Button", nil, relativeFrame, "MonolithDKPButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
	btn:SetSize(100, 30);
	btn:SetText(text);
	btn:GetFontString():SetTextColor(1, 1, 1, 1)
	btn:SetNormalFontObject("MonDKPSmallCenter");
	btn:SetHighlightFontObject("MonDKPSmallCenter");
	return btn; 
end

function MonDKP:BroadcastTimer(seconds, ...)       -- broadcasts timer and starts it natively
	if IsInRaid() and core.IsOfficer == true then
		local title = ...;
		if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
			MonDKP:Print(L["INVALIDTIMER"]);
			return;
		end
		MonDKP:StartTimer(seconds, ...)
		MonDKP.Sync:SendData("MDKPCommand", "StartTimer,"..seconds..","..title)
	end
end

function MonDKP:CreateContainer(parent, name, header)
	local f = CreateFrame("Frame", "MonDKP"..name, parent);
	f:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,0.5)

	f.header = CreateFrame("Frame", "MonDKP"..name.."Header", f)
	f.header:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f.header:SetBackdropColor(0,0,0,1)
	f.header:SetBackdropBorderColor(0,0,0,1)
	f.header:SetPoint("LEFT", f, "TOPLEFT", 20, 0)
	f.header.text = f.header:CreateFontString(nil, "OVERLAY")
	f.header.text:SetFontObject("MonDKPSmallCenter");
	f.header.text:SetPoint("CENTER", f.header, "CENTER", 0, 0);
	f.header.text:SetText(header);
	f.header:SetWidth(f.header.text:GetWidth() + 10)
	f.header:SetHeight(f.header.text:GetHeight() + 4)

	return f;
end

function MonDKP:StartTimer(seconds, ...)
	local duration = tonumber(seconds)
	local alpha = 1;

	if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
		MonDKP:Print(L["INVALIDTIMER"]);
		return;
	end

	MonDKP.BidTimer = MonDKP.BidTimer or MonDKP:CreateTimer();    -- recycles timer frame so multiple instances aren't created
	MonDKP.BidTimer:SetShown(not MonDKP.BidTimer:IsShown())         -- shows if not shown
	if MonDKP.BidTimer:IsShown() == false then                    -- terminates function if hiding timer
		return;
	end

	MonDKP.BidTimer:SetMinMaxValues(0, duration)
	MonDKP.BidTimer.timerTitle:SetText(...)
	PlaySound(8959)

	if MonDKP_DB.timerpos then
		local a = MonDKP_DB["timerpos"]                   -- retrieves timer's saved position from SavedVariables
		MonDKP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
	else
		MonDKP.BidTimer:SetPoint("CENTER")                      -- sets to center if no position has been saved
	end

	local timer = 0             -- timer starts at 0
	local timerText;            -- count down when below 1 minute
	local modulo                -- remainder after divided by 60
	local timerMinute           -- timerText / 60 to get minutes.
	local audioPlayed = false;  -- so audio only plays once
	local expiring;             -- determines when red blinking bar starts. @ 30 sec if timer > 120 seconds, @ 10 sec if below 120 seconds

	MonDKP.BidTimer:SetScript("OnUpdate", function(self, elapsed)   -- timer loop
		timer = timer + elapsed
		timerText = MonDKP_round(duration - timer, 1)
		if tonumber(timerText) > 60 then
			timerMinute = math.floor(tonumber(timerText) / 60, 0);
			modulo = bit.mod(tonumber(timerText), 60);
			if tonumber(modulo) < 10 then modulo = "0"..modulo end
			MonDKP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
		else
			MonDKP.BidTimer.timertext:SetText(timerText)
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
			MonDKP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
			if alpha > 0 then
				alpha = alpha - 0.005
			elseif alpha <= 0 then
				alpha = 1
			end
		else
			MonDKP.BidTimer:SetStatusBarColor(0, 0.8, 0)
		end
		self:SetValue(timer)
		if timer >= duration then
			MonDKP.BidTimer:SetScript("OnUpdate", nil)
			MonDKP.BidTimer:Hide();
		end
	end)
end

local tooltipShown = false  -- only updates tooltip if moused over status icon

function MonDKP:StatusVerify_Update(sync)
	if not MonDKP.UIConfig:IsShown() and not sync then     -- blocks update if dkp window is closed. Updated when window is opened anyway
		return;
	end
	if IsInGuild() and core.Initialized then
		local records = {};
		core.OOD = false

		if #MonDKP_Errant > 0 then
			for i=1, #MonDKP_Errant do
				local curOfficer, curIndex = strsplit("-", MonDKP_Errant[i])
				local tab, curOfficer = strsplit(",", curOfficer)

				if not records[curOfficer] then
					records[curOfficer] = 1
				else
					records[curOfficer] = records[curOfficer] + 1
				end
			end
			core.OOD = true;
		end

		for k,v in pairs(MonDKP_Meta_Remote) do
		    local tempTable = k
			for k,v in pairs(v) do
				if MonDKP_Meta[tempTable][k] and v > MonDKP_Meta[tempTable][k].current then
					core.OOD = true;
					if not records[k] then
						records[k] = v - MonDKP_Meta[tempTable][k].current
					else
						records[k] = records[k] + (v - MonDKP_Meta[tempTable][k].current)
					end
				elseif not MonDKP_Meta[tempTable][k] and v > 0 then
					core.OOD = true
					MonDKP_Meta[tempTable][k] = { current=0, lowest=0 }
					if not records[k] then
						records[k] = v
					else
						records[k] = records[k] + v
					end
				end
			end
		end

		if #MonDKP_Loot == 0 and #MonDKP_DKPHistory == 0 then
			core.OOD = true
		end

		if sync then
			MonDKP:RequestSync("init")
		end

		if GameTooltip:IsShown() and core.OOD and tooltipShown then
			GameTooltip:ClearLines()
			GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
			if #MonDKP_Loot == 0 and #MonDKP_DKPHistory == 0 then
				GameTooltip:AddLine(L["TABLESAREEMPTY"], 1.0, 1.0, 1.0, false);
			else
				GameTooltip:AddLine(L["ONETABLEOOD"].." |cffff0000"..L["OUTOFDATE"].."|r.", 1.0, 1.0, 1.0, false);
			end
			GameTooltip:AddLine(" ")
			if core.ErrantInProgress then
				GameTooltip:AddLine("Errant entry check in progress. Please Wait...", 1.0, 1.0, 1.0, false);
				GameTooltip:AddLine(" ")
			end
			
			if next(records) ~= nil then
				GameTooltip:AddLine("Missing Entries:", 0.25, 0.75, 0.90, 1, true);
				for k,v in pairs(records) do
					local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, k)

					if classSearch then
						c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
					else
						c = { hex="ffffff" }
					end
					GameTooltip:AddLine("|cff"..c.hex..k.."|r: "..v, 1.0, 1.0, 1.0, false);
				end
				GameTooltip:AddLine(" ")
			end
			if MonDKP_SyncInProgress_Get() then
				GameTooltip:AddLine("|cffff0000"..L["BEGINSYNC"].."|r", 1.0, 1.0, 1.0, true);
				local players = MonDKP_SyncingPlayers_Get()
				
				if #players > 0 and core.IsOfficer then
					local playerString = L["UPDATING"]
					for i=1, #players do
						local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, k)

						if classSearch then
							c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
						else
							c = { hex="cccccc" }
						end
						playerString = playerString.."|cff"..c.hex..players[i].."|r,"
					end
					GameTooltip:AddLine(strsub(playerString, 1, -2), 1.0, 1.0, 1.0, true);
				end
			else
				GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
			end
			GameTooltip:Show()
		elseif GameTooltip:IsShown() and not core.OOD and tooltipShown then
			GameTooltip:ClearLines()
			GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ALLTABLES"].." |cff00ff00"..L["UPTODATE"].."|r.", 1.0, 1.0, 1.0, false);
			GameTooltip:AddLine(" ")
			if core.ErrantInProgress then
				GameTooltip:AddLine("Errant entry check in progress. Please Wait...", 1.0, 1.0, 1.0, false);
				GameTooltip:AddLine(" ")
			end
			if MonDKP_SyncInProgress_Get() then
				GameTooltip:AddLine("|cffff0000"..L["BEGINSYNC"].."|r", 1.0, 1.0, 1.0, true);
				local players = MonDKP_SyncingPlayers_Get()
				
				if #players > 0 and core.IsOfficer then
					local playerString = L["UPDATING"]
					for i=1, #players do
						local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, k)

						if classSearch then
							c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
						else
							c = { hex="cccccc" }
						end
						playerString = playerString.."|cff"..c.hex..players[i].."|r,"
					end
					GameTooltip:AddLine(strsub(playerString, 1, -2), 1.0, 1.0, 1.0, true);
				end
			else
				GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
			end
			GameTooltip:Show()
		end

		if not core.OOD then
			if core.ErrantInProgress or MonDKP_SyncInProgress_Get() then
				MonDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonDKP-review-tables")
			else
				MonDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\up-to-date")
			end
			MonDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				tooltipShown = true
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ALLTABLES"].." |cff00ff00"..L["UPTODATE"].."|r.", 1.0, 1.0, 1.0, false);
				GameTooltip:AddLine(" ")
				if core.ErrantInProgress then
					GameTooltip:AddLine("Errant entry check in progress. Please Wait...", 1.0, 1.0, 1.0, false);
					GameTooltip:AddLine(" ")
				end
				if MonDKP_SyncInProgress_Get() then
					GameTooltip:AddLine("|cffff0000"..L["BEGINSYNC"].."|r", 1.0, 1.0, 1.0, true);
					local players = MonDKP_SyncingPlayers_Get()
					
					if #players > 0 and core.IsOfficer then
						local playerString = L["UPDATING"]
						for i=1, #players do
							local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, k)

							if classSearch then
								c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
							else
								c = { hex="cccccc" }
							end
							playerString = playerString.."|cff"..c.hex..players[i].."|r,"
						end
						GameTooltip:AddLine(strsub(playerString, 1, -2), 1.0, 1.0, 1.0, true);
					end
				else
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			MonDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				tooltipShown = false
				GameTooltip:Hide()
			end)

			return true;
		else
			if core.ErrantInProgress or MonDKP_SyncInProgress_Get() then
				MonDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonDKP-review-tables")
			else
				MonDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\out-of-date")
			end
			MonDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				tooltipShown = true
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				if #MonDKP_Loot == 0 and #MonDKP_DKPHistory == 0 then
					GameTooltip:AddLine(L["TABLESAREEMPTY"], 1.0, 1.0, 1.0, false);
				else
					GameTooltip:AddLine(L["ONETABLEOOD"].." |cffff0000"..L["OUTOFDATE"].."|r.", 1.0, 1.0, 1.0, false);
				end
				GameTooltip:AddLine(" ")
				if core.ErrantInProgress then
					GameTooltip:AddLine("Errant entry check in progress. Please Wait...", 1.0, 1.0, 1.0, false);
					GameTooltip:AddLine(" ")
				end
				if next(records) ~= nil then
					GameTooltip:AddLine("Missing Entries:", 0.25, 0.75, 0.90, 1, true);
					for k,v in pairs(records) do
						local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, k)

						if classSearch then
							c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
						else
							c = { hex="ffffff" }
						end
						GameTooltip:AddLine("|cff"..c.hex..k.."|r: "..v, 1.0, 1.0, 1.0, false);
					end
					GameTooltip:AddLine(" ")
				end
				if MonDKP_SyncInProgress_Get() then
					GameTooltip:AddLine("|cffff0000"..L["BEGINSYNC"].."|r", 1.0, 1.0, 1.0, true);
					local players = MonDKP_SyncingPlayers_Get()
					
					if #players > 0 and core.IsOfficer then
						local playerString = L["UPDATING"]
						for i=1, #players do
							local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, k)

							if classSearch then
								c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
							else
								c = { hex="cccccc" }
							end
							playerString = playerString.."|cff"..c.hex..players[i].."|r,"
						end
						GameTooltip:AddLine(strsub(playerString, 1, -2), 1.0, 1.0, 1.0, true);
					end
				else
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			MonDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				tooltipShown = false
				GameTooltip:Hide()
			end)

			return false;
		end
	elseif core.Initialized then
		MonDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
			tooltipShown = true
			DKPStatusTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			DKPStatusTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
			DKPStatusTooltip:AddLine(L["CURRNOTINGUILD"], 1.0, 1.0, 1.0, true);
			DKPStatusTooltip:Show()
		end)
		MonDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
			tooltipShown = false
			DKPStatusTooltip:Hide()
		end)

		return false;
	end
end

function MonDKP:CurrentIndex_Set(t, index)
	local curOfficer, curIndex = strsplit("-", index)
	curIndex = tonumber(curIndex);

	if t == "DKP" then
		if not MonDKP_Meta.DKP[curOfficer] then
			MonDKP_Meta.DKP[curOfficer] = { current=0, lowest=0 }
		end

		if curIndex > MonDKP_Meta.DKP[curOfficer].current then
			MonDKP_Meta.DKP[curOfficer].current = curIndex
		end

		if curIndex < MonDKP_Meta.DKP[curOfficer].lowest or MonDKP_Meta.DKP[curOfficer].lowest == 0 then
			MonDKP_Meta.DKP[curOfficer].lowest = curIndex
		end
	elseif t == "Loot" then
		if not MonDKP_Meta.Loot[curOfficer] then
			MonDKP_Meta.Loot[curOfficer] = { current=0, lowest=0 }
		end

		if curIndex > MonDKP_Meta.Loot[curOfficer].current then
			MonDKP_Meta.Loot[curOfficer].current = curIndex
		end

		if curIndex < MonDKP_Meta.Loot[curOfficer].lowest or MonDKP_Meta.Loot[curOfficer].lowest == 0 then
			MonDKP_Meta.Loot[curOfficer].lowest = curIndex
		end
	end
end

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep (use field only if you wish to search a specific key IE: MonDKP_DKPTable, "Roeshambo", "player" would only search for Roeshambo in the player key)
-- returns an indexed array of the keys to get to searched value
-- First key is the result (ie if it's found 8 times, it will return 8 tables containing results).
-- Second key holds the path to the value searched. So to get to a player searched on DKPTable that returned 1 result, MonDKP_DKPTable[search[1][1]][search[1][2]] would point at the "player" field
-- if the result is 1 level deeper, it would be MonDKP_DKPTable[search[1][1]][search[1][2]][search[1][3]].  MonDKP_DKPTable[search[2][1]][search[2][2]][search[2][3]] would locate the second return, if there is one.
-- use to search for players in SavedVariables. Only two possible returns is the table or false.
-------------------------------------
function MonDKP:Table_Search(tar, val, field)
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

function MonDKP:TableStrFind(tar, val, field)              -- same function as above, but searches values that contain the searched string rather than exact string matches
	local value = string.upper(tostring(val));        -- ex. MonDKP:TableStrFind(MonDKP_DKPHistory, "Roeshambo") will return the path to any table element that contains "Roeshambo"
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
								if strfind(string.upper(tostring(v)), value) then
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
						if strfind(string.upper(tostring(v)), value) then
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
				if strfind(string.upper(tostring(v)), value) then
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
		if strfind(string.upper(tostring(v)), value) then
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

function MonDKP:DKPTable_Set(tar, field, value, loot)                -- updates field with value where tar is found (IE: MonDKP:DKPTable_Set("Roeshambo", "dkp", 10) adds 10 dkp to user Roeshambo). loot = true/false if it's to alter lifetime_spent
	local result = MonDKP:Table_Search(MonDKP_DKPTable, tar);
	for i=1, #result do
		local current = MonDKP_DKPTable[result[i][1]][field];
		if(field == "dkp") then
			MonDKP_DKPTable[result[i][1]][field] = MonDKP_round(tonumber(current + value), MonDKP_DB.modes.rounding)
			if value > 0 and loot == false then
				MonDKP_DKPTable[result[i][1]]["lifetime_gained"] = MonDKP_round(tonumber(MonDKP_DKPTable[result[i][1]]["lifetime_gained"] + value), MonDKP_DB.modes.rounding)
			elseif value < 0 and loot == true then
				MonDKP_DKPTable[result[i][1]]["lifetime_spent"] = MonDKP_round(tonumber(MonDKP_DKPTable[result[i][1]]["lifetime_spent"] + value), MonDKP_DB.modes.rounding)
			end
		else
			MonDKP_DKPTable[result[i][1]][field] = value
		end
	end
	DKPTable_Update()
end