local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;


local function Remove_Entries()
	CommDKP:StatusVerify_Update()
	local numPlayers = 0;
	local removedUsers, c;
	local deleted = {};

	for i=1, #core.SelectedData do
		local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), core.SelectedData[i]["player"]);
		local flag = false -- flag = only create archive entry if they appear anywhere in the history. If there's no history, there's no reason anyone would have it.
		local curTime = time()

		if search then
			local path = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]]

			for i=1, #CommDKP:GetTable(CommDKP_DKPHistory, true) do
				if strfind(CommDKP:GetTable(CommDKP_DKPHistory, true)[i].players, ","..path.player..",") or strfind(CommDKP:GetTable(CommDKP_DKPHistory, true)[i].players, path.player..",") == 1 then
					flag = true
				end
			end

			for i=1, #CommDKP:GetTable(CommDKP_Loot, true) do
				if CommDKP:GetTable(CommDKP_Loot, true)[i].player == path.player then
					flag = true
				end
			end
			
			if flag then 		-- above 2 loops flags character if they have any loot/dkp history. Only inserts to archive and broadcasts if found. Other players will not have the entry if no history exists
				if not CommDKP:GetTable(CommDKP_Archive, true)[core.SelectedData[i].player] then
					CommDKP:GetTable(CommDKP_Archive, true)[core.SelectedData[i].player] = { deleted=true, edited=curTime }
				end
				CommDKP:GetTable(CommDKP_Archive, true)[core.SelectedData[i].player].dkp = path.dkp
				CommDKP:GetTable(CommDKP_Archive, true)[core.SelectedData[i].player].lifetime_spent = path.lifetime_spent
				CommDKP:GetTable(CommDKP_Archive, true)[core.SelectedData[i].player].lifetime_gained = path.lifetime_gained
				CommDKP:GetTable(CommDKP_Archive, true)[core.SelectedData[i].player].deleted = true
				CommDKP:GetTable(CommDKP_Archive, true)[core.SelectedData[i].player].edited = curTime
			end

			c = CommDKP:GetCColors(core.SelectedData[i]["class"])
			if i==1 then
				removedUsers = "|c"..c.hex..core.SelectedData[i]["player"].."|r"
			else
				removedUsers = removedUsers..", |c"..c.hex..core.SelectedData[i]["player"].."|r"
			end
			numPlayers = numPlayers + 1

			tremove(CommDKP:GetTable(CommDKP_DKPTable, true), search[1][1])
			tinsert(deleted, { player=path.player, deleted=true })
			CommDKP:GetTable(CommDKP_Profiles, true)[path.player] = nil;

			local search2 = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Standby, true), core.SelectedData[i].player, "player");

			if search2 then
				table.remove(CommDKP:GetTable(CommDKP_Standby, true), search2[1][1])
			end
		end
	end
	table.wipe(core.SelectedData)
	CommDKPSelectionCount_Update()
	CommDKP:FilterDKPTable(core.currentSort, "reset")
	CommDKP:Print("["..CommDKP:GetTeamName(CommDKP:GetCurrentTeamIndex()).."] ".."Removed "..numPlayers.." player(s): "..removedUsers)
	CommDKP:ClassGraph_Update()

	if #deleted >0 then
		CommDKP.Sync:SendData("CommDKPDelUsers", deleted)
	end
end

local function AddRaidToDKPTable()
	local GroupType = "none";

	if IsInRaid() then
		GroupType = "raid"
	elseif IsInGroup() then
		GroupType = "party"
	end

	if GroupType ~= "none" then
		local tempName,tempClass;
		local addedUsers, c
		local numPlayers = 0;
		local guildSize = GetNumGuildMembers();
		local name, rank, rankIndex;
		local InGuild = false; -- Only adds player to list if the player is found in the guild roster.
		local GroupSize;
		local FlagRecovery = false
		local curTime = time()
		local entities = {}

		if GroupType == "raid" then
			GroupSize = 40
		elseif GroupType == "party" then
			GroupSize = 5
		end

		for i=1, GroupSize do
			tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
			for j=1, guildSize do
				name, rank, rankIndex = GetGuildRosterInfo(j)
				name = strsub(name, 1, string.find(name, "-")-1)						-- required to remove server name from player (can remove in classic if this is not an issue)
				if name == tempName then
					InGuild = true;
				end
			end
			if tempName then
				local profile = CommDKP:GetDefaultEntity();
				if not CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), tempName) then
					if InGuild then
						profile.player=tempName;
						profile.class=tempClass;
						profile.rank = rankIndex;
						profile.rankName = rank;
					else
						profile.player=tempName;
						profile.class=tempClass;
					end
					tinsert(CommDKP:GetTable(CommDKP_DKPTable, true), profile);
					tinsert(entities, profile);
					CommDKP:GetTable(CommDKP_Profiles, true)[name] = profile;
					numPlayers = numPlayers + 1;
					c = CommDKP:GetCColors(tempClass)
					if addedUsers == nil then
						addedUsers = "|c"..c.hex..tempName.."|r"; 
					else
						addedUsers = addedUsers..", |c"..c.hex..tempName.."|r"
					end
					if CommDKP:GetTable(CommDKP_Archive, true)[tempName] and CommDKP:GetTable(CommDKP_Archive, true)[tempName].deleted then
						profile.dkp = CommDKP:GetTable(CommDKP_Archive, true)[tempName].dkp
						profile.lifetime_gained = CommDKP:GetTable(CommDKP_Archive, true)[tempName].lifetime_gained
						profile.lifetime_spent = CommDKP:GetTable(CommDKP_Archive, true)[tempName].lifetime_spent
						CommDKP:GetTable(CommDKP_Archive, true)[tempName].deleted = "Recovered"
						CommDKP:GetTable(CommDKP_Archive, true)[tempName].edited = curTime
						FlagRecovery = true
					end
				end
			end
		end
		if addedUsers then
			CommDKP:Print("["..CommDKP:GetTeamName(CommDKP:GetCurrentTeamIndex()).."] "..L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
		end
		if core.ClassGraph then
			CommDKP:ClassGraph_Update()
		else
			CommDKP:ClassGraph()
		end
		if FlagRecovery then 
			CommDKP:Print(L["YOUHAVERECOVERED"])
		end
		CommDKP:FilterDKPTable(core.currentSort, "reset")
		if numPlayers > 0 then
			CommDKP.Sync:SendData("CommDKPAddUsers", CopyTable(entities))
		end
	else
		CommDKP:Print(L["NOPARTYORRAID"])
	end
end

local function AddGuildToDKPTable(rank, level)
	local guildSize = GetNumGuildMembers();
	local class, addedUsers, c, name, rankName, rankIndex, charLevel;
	local numPlayers = 0;
	local FlagRecovery = false
	local curTime = time()
	local entities = {}

	for i=1, guildSize do
		name,rankName,rankIndex,charLevel,_,_,_,_,_,_,class = GetGuildRosterInfo(i)
		name = strsub(name, 1, string.find(name, "-")-1)			-- required to remove server name from player (can remove in classic if this is not an issue)
		local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), name)

		if not search and (level == nil or charLevel >= level) and (rank == nil or rankIndex == rank) then
			local profile = CommDKP:GetDefaultEntity();

			profile.player=name;
			profile.class=class;
			profile.rank = rankIndex;
			profile.rankName = rank;

			tinsert(CommDKP:GetTable(CommDKP_DKPTable, true), profile);
			tinsert(entities, profile);
			CommDKP:GetTable(CommDKP_Profiles, true)[name] = profile;

			numPlayers = numPlayers + 1;
			c = CommDKP:GetCColors(class)
			if addedUsers == nil then
				addedUsers = "|c"..c.hex..name.."|r"; 
			else
				addedUsers = addedUsers..", |c"..c.hex..name.."|r"
			end
			if CommDKP:GetTable(CommDKP_Archive, true)[name] and CommDKP:GetTable(CommDKP_Archive, true)[name].deleted then
				profile.dkp = CommDKP:GetTable(CommDKP_Archive, true)[name].dkp
				profile.lifetime_gained = CommDKP:GetTable(CommDKP_Archive, true)[name].lifetime_gained
				profile.lifetime_spent = CommDKP:GetTable(CommDKP_Archive, true)[name].lifetime_spent
				CommDKP:GetTable(CommDKP_Archive, true)[name].deleted = "Recovered"
				CommDKP:GetTable(CommDKP_Archive, true)[name].edited = curTime
				FlagRecovery = true
			end
		end
	end
	CommDKP:FilterDKPTable(core.currentSort, "reset")
	if addedUsers then
		CommDKP:Print("["..CommDKP:GetTeamName(CommDKP:GetCurrentTeamIndex()).."] "..L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
	end
	if FlagRecovery then 
		CommDKP:Print(L["YOUHAVERECOVERED"])
	end
	if core.ClassGraph then
		CommDKP:ClassGraph_Update()
	else
		CommDKP:ClassGraph()
	end
	if numPlayers > 0 then
		CommDKP.Sync:SendData("CommDKPAddUsers", CopyTable(entities))
	end
end

local function AddTargetToDKPTable()
	local name = UnitName("target");
	local _,class = UnitClass("target");
	local c;
	local curTime = time()
	local entities = {}

	local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), name)
	local profile = CommDKP:GetDefaultEntity();
	
	profile.player=name;
	profile.class=class;

	if not search then
		tinsert(CommDKP:GetTable(CommDKP_DKPTable, true), profile);
		tinsert(entities, profile);
		CommDKP:GetTable(CommDKP_Profiles, true)[name] = profile;

		CommDKP:FilterDKPTable(core.currentSort, "reset")
		c = CommDKP:GetCColors(class)
		CommDKP:Print("["..CommDKP:GetTeamName(CommDKP:GetCurrentTeamIndex()).."] "..L["ADDED"].." |c"..c.hex..name.."|r")

		if addedUsers == nil then
			addedUsers = "|c"..c.hex..name.."|r"; 
		else
			addedUsers = addedUsers..", |c"..c.hex..name.."|r"
		end


		if core.ClassGraph then
			CommDKP:ClassGraph_Update()
		else
			CommDKP:ClassGraph()
		end
		if CommDKP:GetTable(CommDKP_Archive, true)[name] and CommDKP:GetTable(CommDKP_Archive, true)[name].deleted then
			profile.dkp = CommDKP:GetTable(CommDKP_Archive, true)[name].dkp
			profile.lifetime_gained = CommDKP:GetTable(CommDKP_Archive, true)[name].lifetime_gained
			profile.lifetime_spent = CommDKP:GetTable(CommDKP_Archive, true)[name].lifetime_spent
			CommDKP:GetTable(CommDKP_Archive, true)[name].deleted = "Recovered"
			CommDKP:GetTable(CommDKP_Archive, true)[name].edited = curTime
			CommDKP:Print(L["YOUHAVERECOVERED"])
		end
		CommDKP.Sync:SendData("CommDKPAddUsers", CopyTable(entities))
	end
end

function CommDKP:CopyProfileToTeam(row, team)
	local entities = {};
	local copy = {};
	if #core.SelectedData > 1 then
		--Multiple Selections
		copy = CopyTable(core.SelectedData)
	else
		--Only Profile Selected
		tinsert(copy,core.WorkingTable[row])
	end

	for i=1, #copy do
		local profile = copy[i];
		local name = profile.player;

		local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, team), name);

		if not search then
			profile.norecover = true;
			tinsert(entities, profile);
		end
	end

	if #entities > 0 then
		CommDKP:AddEntitiesToDKPTable(CopyTable(entities), team);
		CommDKP.Sync:SendData("CommDKPAddUsers", CopyTable(entities), nil, team);
	end
end

function CommDKP:AddEntitiesToDKPTable(entities, team)
	team = team or CommDKP:GetCurrentTeamIndex();
	local addedUsers;
	local numPlayers = 0;
	local curTime = time()

	for i=1, #entities do
		local name = entities[i].player;
		local class = entities[i].class;
		local profile = entities[i];
		local c;
	
		local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, team), name)
	
		CommDKP:GetTable(CommDKP_Profiles, true, team)[name] = profile;

		if not search then
	
			numPlayers = numPlayers + 1;
			c = CommDKP:GetCColors(class)
			if addedUsers == nil then
				addedUsers = "|c"..c.hex..name.."|r"; 
			else
				addedUsers = addedUsers..", |c"..c.hex..name.."|r"
			end
			if profile.norecover then
				profile.norecover = nil;
			else
				if CommDKP:GetTable(CommDKP_Archive, true, team)[name] and CommDKP:GetTable(CommDKP_Archive, true, team)[name].deleted then
					profile.dkp = CommDKP:GetTable(CommDKP_Archive, true, team)[name].dkp
					profile.lifetime_gained = CommDKP:GetTable(CommDKP_Archive, true, team)[name].lifetime_gained
					profile.lifetime_spent = CommDKP:GetTable(CommDKP_Archive, true, team)[name].lifetime_spent
					CommDKP:GetTable(CommDKP_Archive, true, team)[name].deleted = "Recovered"
					CommDKP:GetTable(CommDKP_Archive, true, team)[name].edited = curTime
					FlagRecovery = true
				end
			end
			tinsert(CommDKP:GetTable(CommDKP_DKPTable, true, team), CopyTable(profile));
		end
	end

	if numPlayers > 0  then
		CommDKP:FilterDKPTable(core.currentSort, "reset")
		if addedUsers then
			CommDKP:Print("["..CommDKP:GetTeamName(team).."] "..L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
		end
		if FlagRecovery then 
			CommDKP:Print(L["YOUHAVERECOVERED"])
		end
		if core.ClassGraph then
			CommDKP:ClassGraph_Update()
		else
			CommDKP:ClassGraph()
		end
	end
end


function CommDKP:GetGuildRankList()
	local numRanks = GuildControlGetNumRanks()
	local tempTable = {}
	for i=1, numRanks do
		table.insert(tempTable, {index = i-1, name = GuildControlGetRankName(i)})
		tempTable[GuildControlGetRankName(i)] = i-1
	end
	
	return tempTable;
end

-------
-- TEAM FUNCTIONS
-------

function CommDKP:ChangeTeamName(index, _name) 
	CommDKP:GetTable(CommDKP_DB, false)["teams"][tostring(index)].name = _name;
	CommDKP.Sync:SendData("CommDKPTeams", {Teams =  CommDKP:GetTable(CommDKP_DB, false)["teams"]} , nil)
end

function CommDKP:AddNewTeamToGuild() 
	local _index = 0
	local _tmp = CommDKP:GetTable(CommDKP_DB, false)["teams"]
	local realmName = CommDKP:GetRealmName();
	local guildName = CommDKP:GetGuildName();

	-- get the index of last team from CommDKP_DB
	for k,v in pairs(_tmp) do
		if(type(v) == "table") then
			_index = _index + 1
		end
	end

	-- add new team definition to CommDKP_DB with generic GuildName-index
	CommDKP:GetTable(CommDKP_DB, false)["teams"][tostring(_index)] = { ["name"] = guildName.."-"..tostring(_index)}

	------
	-- add new team with new "index" to all "team" tables in saved variables
	-- CommDKP_Loot, CommDKP_DKPTable, CommDKP_DKPHistory, CommDKP_MinBids, CommDKP_MaxBids, CommDKP_Standby, CommDKP_Archive
	------
		CommDKP:GetTable(CommDKP_Loot, false)[tostring(_index)] = {}
		CommDKP:GetTable(CommDKP_DKPTable, false)[tostring(_index)] = {}
		CommDKP:GetTable(CommDKP_DKPHistory, false)[tostring(_index)] = {}
		CommDKP:GetTable(CommDKP_MinBids, false)[tostring(_index)] = {}
		CommDKP:GetTable(CommDKP_MaxBids, false)[tostring(_index)] = {}
		CommDKP:GetTable(CommDKP_Standby, false)[tostring(_index)] = {}
		CommDKP:GetTable(CommDKP_Archive, false)[tostring(_index)] = {}

		CommDKP.Sync:SendData("CommDKPTeams", {Teams =  CommDKP:GetTable(CommDKP_DB, false)["teams"]} , nil)

	return tostring(_index)
end

-------
-- TEAM FUNCTIONS END
-------

function CommDKP:reset_prev_dkp(player)
	if player then
		local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), player, "player")

		if search then
			CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].previous_dkp = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp
		end
	else
		for i=1, #CommDKP:GetTable(CommDKP_DKPTable, true) do
			CommDKP:GetTable(CommDKP_DKPTable, true)[i].previous_dkp = CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp
		end
	end
end

local function UpdateWhitelist()
	if #core.SelectedData > 0 then
		table.wipe(CommDKP:GetTable(CommDKP_Whitelist))
		for i=1, #core.SelectedData do
			local validate = CommDKP:ValidateSender(core.SelectedData[i].player)

			if not validate then
				StaticPopupDialogs["VALIDATE_OFFICER"] = {
					text = core.SelectedData[i].player.." "..L["NOTANOFFICER"],
					button1 = "Ok",
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("VALIDATE_OFFICER")
				return;
			end
		end
		for i=1, #core.SelectedData do
			table.insert(CommDKP:GetTable(CommDKP_Whitelist), core.SelectedData[i].player)
		end

		local verifyLeadAdded = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Whitelist), UnitName("player"))

		if not verifyLeadAdded then
			local pname = UnitName("player");
			table.insert(CommDKP:GetTable(CommDKP_Whitelist), pname)		-- verifies leader is included in white list. Adds if they aren't
		end
	else
		table.wipe(CommDKP:GetTable(CommDKP_Whitelist))
	end
	CommDKP.Sync:SendData("CDKPWhitelist", CommDKP:GetTable(CommDKP_Whitelist))
	CommDKP:Print(L["WHITELISTBROADCASTED"])
end

local function ViewWhitelist()
	if #CommDKP:GetTable(CommDKP_Whitelist) > 0 then
		core.SelectedData = {}
		for i=1, #CommDKP:GetTable(CommDKP_Whitelist) do
			local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), CommDKP:GetTable(CommDKP_Whitelist)[i])

			if search then
				table.insert(core.SelectedData, CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]])
			end
		end
		CommDKP:FilterDKPTable(core.currentSort, "reset")
	end
end


---------------------------------------
-- Manage DKP TAB.Create()
---------------------------------------
function CommDKP:ManageEntries()

	local CheckLeader = CommDKP:GetGuildRankIndex(UnitName("player"))
	-- add raid to dkp table if they don't exist

	----------------------------------
	-- Header text above the buttons
	----------------------------------
		CommDKP.ConfigTab3.AddEntriesHeader = CommDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
		CommDKP.ConfigTab3.AddEntriesHeader:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab3.add_raid_to_table, "TOPLEFT", -10, 10);
		CommDKP.ConfigTab3.AddEntriesHeader:SetWidth(400)
		CommDKP.ConfigTab3.AddEntriesHeader:SetFontObject("CommDKPNormalLeft")
		CommDKP.ConfigTab3.AddEntriesHeader:SetText(L["ADDREMDKPTABLEENTRIES"]); 

	----------------------------------
	-- add raid members button
	----------------------------------
		CommDKP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 30, -90, L["ADDRAIDMEMBERS"]);
		CommDKP.ConfigTab3.add_raid_to_table:SetSize(120,25);

		-- tooltip for add raid members button
		CommDKP.ConfigTab3.add_raid_to_table:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDRAIDMEMBERS"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDRAIDMEMBERSTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.add_raid_to_table:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)

		-- confirmation dialog to remove user(s)
		CommDKP.ConfigTab3.add_raid_to_table:SetScript("OnClick", 
			function ()
				local selected = L["ADDRAIDMEMBERSCONFIRM"];

				StaticPopupDialogs["ADD_RAID_ENTRIES"] = {
				text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					AddRaidToDKPTable()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
				}
				StaticPopup_Show ("ADD_RAID_ENTRIES")
			end
		);


	
	----------------------------------
	-- remove selected entries button
	----------------------------------
		CommDKP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 170, -60, L["REMOVEENTRIES"]);
		CommDKP.ConfigTab3.remove_entries:SetSize(120,25);
		CommDKP.ConfigTab3.remove_entries:ClearAllPoints()
		CommDKP.ConfigTab3.remove_entries:SetPoint("LEFT", CommDKP.ConfigTab3.add_raid_to_table, "RIGHT", 20, 0)
		CommDKP.ConfigTab3.remove_entries:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["REMOVESELECTEDENTRIES"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["REMSELENTRIESTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["REMSELENTRIESTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.remove_entries:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to remove user(s)
		CommDKP.ConfigTab3.remove_entries:SetScript("OnClick", 
			function ()	
				if #core.SelectedData > 0 then
					local selected = L["CONFIRMREMOVESELECT"]..": \n\n";

					for i=1, #core.SelectedData do
						local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), core.SelectedData[i].player)

						if classSearch then
							c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[classSearch[1][1]].class)
						else
							c = { hex="ffffffff" }
						end
						if i == 1 then
							selected = selected.."|c"..c.hex..core.SelectedData[i].player.."|r"
						else
							selected = selected..", |c"..c.hex..core.SelectedData[i].player.."|r"
						end
					end
					selected = selected.."?"

					StaticPopupDialogs["REMOVE_ENTRIES"] = {
					text = selected,
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						Remove_Entries()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
					}
					StaticPopup_Show ("REMOVE_ENTRIES")
				else
					CommDKP:Print(L["NOENTRIESSELECTED"])
				end
			end
		);
	----------------------------------
	-- Reset previous DKP button -- number showing how much a player has gained or lost since last clear
	----------------------------------
		CommDKP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 310, -60, L["RESETPREVIOUS"]);
		CommDKP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
		CommDKP.ConfigTab3.reset_previous_dkp:ClearAllPoints()
		CommDKP.ConfigTab3.reset_previous_dkp:SetPoint("LEFT", CommDKP.ConfigTab3.remove_entries, "RIGHT", 20, 0)
		CommDKP.ConfigTab3.reset_previous_dkp:SetScript("OnEnter",
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["RESETPREVDKP"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["RESETPREVDKPTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["RESETPREVDKPTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.reset_previous_dkp:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to remove user(s)
		CommDKP.ConfigTab3.reset_previous_dkp:SetScript("OnClick",
			function ()	
				StaticPopupDialogs["RESET_PREVIOUS_DKP"] = {
					text = L["RESETPREVCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						CommDKP:reset_prev_dkp()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("RESET_PREVIOUS_DKP")
			end
		);

	local curIndex;
	local curRank;

	----------------------------------
	-- rank select dropDownMenu
	----------------------------------
		CommDKP.ConfigTab3.GuildRankDropDown = CreateFrame("FRAME", "CommDKPConfigReasonDropDown", CommDKP.ConfigTab3, "CommunityDKPUIDropDownMenuTemplate")
		CommDKP.ConfigTab3.GuildRankDropDown:SetPoint("TOPLEFT", CommDKP.ConfigTab3.add_raid_to_table, "BOTTOMLEFT", -17, -15)
		CommDKP.ConfigTab3.GuildRankDropDown:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["RANKLIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["RANKLISTTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.GuildRankDropDown:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		UIDropDownMenu_SetWidth(CommDKP.ConfigTab3.GuildRankDropDown, 105)
		UIDropDownMenu_SetText(CommDKP.ConfigTab3.GuildRankDropDown, "Select Rank")

		-- Create and bind the initialization function to the dropdown menu
		UIDropDownMenu_Initialize(CommDKP.ConfigTab3.GuildRankDropDown, 
			function(self, level, menuList)
				local rank = UIDropDownMenu_CreateInfo()
					rank.func = self.SetValue
					rank.fontObject = "CommDKPSmallCenter"

					local rankList = CommDKP:GetGuildRankList()

					for i=1, #rankList do
						rank.text, rank.arg1, rank.arg2, rank.checked, rank.isNotRadio = rankList[i].name, rankList[i].name, rankList[i].index, rankList[i].name == curRank, true
						UIDropDownMenu_AddButton(rank)
					end
			end
		)

		-- Dropdown Menu Function
		function CommDKP.ConfigTab3.GuildRankDropDown:SetValue(arg1, arg2)
			if curRank ~= arg1 then
				curRank = arg1
				curIndex = arg2
				UIDropDownMenu_SetText(CommDKP.ConfigTab3.GuildRankDropDown, arg1)
			else
				curRank = nil
				curIndex = nil
				UIDropDownMenu_SetText(CommDKP.ConfigTab3.GuildRankDropDown, L["SELECTRANK"])
			end

			CloseDropDownMenus()
		end

	----------------------------------
	-- Add Guild to DKP Table Button
	----------------------------------
		CommDKP.ConfigTab3.AddGuildToDKP = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDGUILDMEMBERS"]);
		CommDKP.ConfigTab3.AddGuildToDKP:SetSize(120,25);
		CommDKP.ConfigTab3.AddGuildToDKP:ClearAllPoints()
		CommDKP.ConfigTab3.AddGuildToDKP:SetPoint("LEFT", CommDKP.ConfigTab3.GuildRankDropDown, "RIGHT", 2, 2)
		CommDKP.ConfigTab3.AddGuildToDKP:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDGUILDDKPTABLE"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDGUILDDKPTABLETT"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.AddGuildToDKP:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to add user(s)
		CommDKP.ConfigTab3.AddGuildToDKP:SetScript("OnClick",
			function ()	
				if curIndex ~= nil then
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
						text = L["ADDGUILDCONFIRM"].." \""..curRank.."\"?",
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							AddGuildToDKPTable(curIndex)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				else
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
						text = L["NORANKSELECTED"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				end
			end
		);

	----------------------------------
	-- Add target to DKP list button
	----------------------------------	
		CommDKP.ConfigTab3.AddTargetToDKP = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDTARGET"]);
		CommDKP.ConfigTab3.AddTargetToDKP:SetSize(120,25);
		CommDKP.ConfigTab3.AddTargetToDKP:ClearAllPoints()
		CommDKP.ConfigTab3.AddTargetToDKP:SetPoint("LEFT", CommDKP.ConfigTab3.AddGuildToDKP, "RIGHT", 20, 0)
		CommDKP.ConfigTab3.AddTargetToDKP:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDTARGETTODKPTABLE"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDTARGETTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.AddTargetToDKP:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		CommDKP.ConfigTab3.AddTargetToDKP:SetScript("OnClick", 
			function ()	-- confirmation dialog to add user(s)
				if UnitIsPlayer("target") == true then
					StaticPopupDialogs["ADD_TARGET_DKP"] = {
						text = L["CONFIRMADDTARGET"].." "..UnitName("target").." "..L["TODKPLIST"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							AddTargetToDKPTable()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_TARGET_DKP")
				else
					StaticPopupDialogs["ADD_TARGET_DKP"] = {
						text = L["NOPLAYERTARGETED"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_TARGET_DKP")
				end
			end
		);

	----------------------------------
	-- Purge DKP list button
	----------------------------------
		CommDKP.ConfigTab3.CleanList = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 0, 0, L["PURGELIST"]);
		CommDKP.ConfigTab3.CleanList:SetSize(120,25);
		CommDKP.ConfigTab3.CleanList:ClearAllPoints()
		CommDKP.ConfigTab3.CleanList:SetPoint("TOP", CommDKP.ConfigTab3.AddTargetToDKP, "BOTTOM", 0, -16)
		CommDKP.ConfigTab3.CleanList:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["PURGELIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["PURGELISTTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.CleanList:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		CommDKP.ConfigTab3.CleanList:SetScript("OnClick", 
			function()
				StaticPopupDialogs["PURGE_CONFIRM"] = {
					text = L["PURGECONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						local purgeString, c, name;
						local count = 0;
						local i = 1;

						while i <= #CommDKP:GetTable(CommDKP_DKPTable, true) do
							local search = CommDKP:TableStrFind(CommDKP:GetTable(CommDKP_DKPHistory, true), CommDKP:GetTable(CommDKP_DKPTable, true)[i].player, "players")

							if CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp == 0 and not search then
								c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[i].class)
								name = CommDKP:GetTable(CommDKP_DKPTable, true)[i].player;

								if purgeString == nil then
									purgeString = "|c"..c.hex..name.."|r"; 
								else
									purgeString = purgeString..", |c"..c.hex..name.."|r"
								end

								count = count + 1;
								table.remove(CommDKP:GetTable(CommDKP_DKPTable, true), i)
							else
								i=i+1;
							end
						end
						if count > 0 then
							CommDKP:Print(L["PURGELIST"].." ("..count.."):")
							CommDKP:Print(purgeString)
							CommDKP:FilterDKPTable(core.currentSort, "reset")
						end
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("PURGE_CONFIRM")
			end
		)

	----------------------------------
	-- White list container
	----------------------------------

		CommDKP.ConfigTab3.WhitelistContainer = CreateFrame("Frame", nil, CommDKP.ConfigTab3);
		CommDKP.ConfigTab3.WhitelistContainer:SetSize(475, 200);
		CommDKP.ConfigTab3.WhitelistContainer:SetPoint("TOPLEFT", CommDKP.ConfigTab3.GuildRankDropDown, "BOTTOMLEFT", 20, -30)

		-- Whitelist Header
		CommDKP.ConfigTab3.WhitelistContainer.WhitelistHeader = CommDKP.ConfigTab3.WhitelistContainer:CreateFontString(nil, "OVERLAY")
		CommDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetPoint("TOPLEFT", CommDKP.ConfigTab3.WhitelistContainer, "TOPLEFT", -10, 0);
		CommDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetWidth(400)
		CommDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetFontObject("CommDKPNormalLeft")
		CommDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetText(L["WHITELISTHEADER"]); 

		-- Whitelist button
		CommDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton = self:CreateButton("BOTTOMLEFT", CommDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SETWHITELIST"]);
		CommDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:ClearAllPoints()
		CommDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetPoint("TOPLEFT", CommDKP.ConfigTab3.WhitelistContainer.WhitelistHeader, "BOTTOMLEFT", 10, -10)
		CommDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["SETWHITELIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["SETWHITELISTTTDESC1"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["SETWHITELISTTTDESC2"], 0.2, 1.0, 0.2, true);
				GameTooltip:AddLine(L["SETWHITELISTTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to add user(s)
		CommDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnClick", 
			function ()	
				if #core.SelectedData > 0 then
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
						text = L["CONFIRMWHITELIST"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							UpdateWhitelist()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				else
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
						text = L["CONFIRMWHITELISTCLEAR"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							UpdateWhitelist()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				end
			end
		);

			----------------------------------
			-- View Whitelist Button
			----------------------------------
		
				CommDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton = self:CreateButton("BOTTOMLEFT", CommDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["VIEWWHITELISTBTN"]);
				CommDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:ClearAllPoints()
				CommDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetPoint("LEFT", CommDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton, "RIGHT", 10, 0)
				CommDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnEnter",
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(L["VIEWWHITELISTBTN"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddLine(L["VIEWWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
						GameTooltip:Show();
					end
				)
				CommDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnLeave", 
					function(self)
						GameTooltip:Hide()
					end
				)
				CommDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnClick", 
					function ()	-- confirmation dialog to add user(s)
						if #CommDKP:GetTable(CommDKP_Whitelist) > 0 then
							ViewWhitelist()
						else
							StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
								text = L["WHITELISTEMPTY"],
								button1 = L["OK"],
								timeout = 0,
								whileDead = true,
								hideOnEscape = true,
								preferredIndex = 3
							}
							StaticPopup_Show ("ADD_GUILD_MEMBERS")
						end
					end
				);

			----------------------------------
			-- Broadcast Whitelist Button
			----------------------------------
		
				CommDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton = self:CreateButton("BOTTOMLEFT", CommDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SENDWHITELIST"]);
				CommDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:ClearAllPoints()
				CommDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetPoint("LEFT", CommDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton, "RIGHT", 30, 0)
				CommDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnEnter", 
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(L["SENDWHITELIST"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddLine(L["SENDWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
						GameTooltip:AddLine(L["SENDWHITELISTTTWARN"], 1.0, 0, 0, true);
						GameTooltip:Show();
					end
				)
				CommDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnLeave",
					function(self)
						GameTooltip:Hide()
					end
				)
				-- confirmation dialog to add user(s)
				CommDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnClick",
					function ()	
						CommDKP.Sync:SendData("CDKPWhitelist", CommDKP:GetTable(CommDKP_Whitelist))
						CommDKP:Print(L["WHITELISTBROADCASTED"])
					end
				);

		

	----------------------------------
	-- Guild team management section
	----------------------------------

	local selectedTeam;
	local selectedTeamIndex;

		----------------------------------
		-- Teams Header
		----------------------------------
		CommDKP.ConfigTab3.TeamHeader = CommDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
		CommDKP.ConfigTab3.TeamHeader:SetPoint("TOPLEFT", CommDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", -10, -5);
		CommDKP.ConfigTab3.TeamHeader:SetWidth(400)
		CommDKP.ConfigTab3.TeamHeader:SetFontObject("CommDKPNormalLeft")
		CommDKP.ConfigTab3.TeamHeader:SetText(L["TEAMMANAGEMENTHEADER"].." of "..CommDKP:GetGuildName()..""); 

		----------------------------------
		-- Drop down with lists of teams 
		----------------------------------
			CommDKP.ConfigTab3.TeamListDropDown = CreateFrame("FRAME", "CommDKPConfigReasonDropDown", CommDKP.ConfigTab3, "CommunityDKPUIDropDownMenuTemplate")
			--CommDKP.ConfigTab3.TeamManagementContainer.TeamListDropDown:ClearAllPoints()
			CommDKP.ConfigTab3.TeamListDropDown:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab3.TeamHeader, "BOTTOMLEFT", 0, -50)
			-- tooltip on mouseOver
			CommDKP.ConfigTab3.TeamListDropDown:SetScript("OnEnter", 
				function(self) 
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(L["TEAMLIST"], 0.25, 0.75, 0.90, 1, true);
					GameTooltip:AddLine(L["TEAMLISTDESC"], 1.0, 1.0, 1.0, true);
					GameTooltip:Show();
				end
			)
			CommDKP.ConfigTab3.TeamListDropDown:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)
			UIDropDownMenu_SetWidth(CommDKP.ConfigTab3.TeamListDropDown, 105)
			UIDropDownMenu_SetText(CommDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])

			-- Create and bind the initialization function to the dropdown menu
			UIDropDownMenu_Initialize(CommDKP.ConfigTab3.TeamListDropDown, 
				function(self, level, menuList)
					local dropDownMenuItem = UIDropDownMenu_CreateInfo()
					dropDownMenuItem.func = self.SetValue
					dropDownMenuItem.fontObject = "CommDKPSmallCenter"
				
					teamList = CommDKP:GetGuildTeamList()

					for i=1, #teamList do
						dropDownMenuItem.text = teamList[i][2]
						dropDownMenuItem.arg1 = teamList[i][2]
						dropDownMenuItem.arg2 = teamList[i][1]
						dropDownMenuItem.checked = teamList[i][1] == selectedTeamIndex
						dropDownMenuItem.isNotRadio = true
						UIDropDownMenu_AddButton(dropDownMenuItem)
					end
				end
			)

			-- Dropdown Menu on SetValue()
			function CommDKP.ConfigTab3.TeamListDropDown:SetValue(arg1, arg2)
				if selectedTeamIndex ~= arg2 then
					selectedTeam = arg1
					selectedTeamIndex = arg2
					UIDropDownMenu_SetText(CommDKP.ConfigTab3.TeamListDropDown, arg1)
					CommDKP.ConfigTab3.TeamNameInput:SetText(arg1)
				else
					selectedTeam = nil
					selectedTeamIndex = nil
					CommDKP.ConfigTab3.TeamNameInput:SetText("")
					UIDropDownMenu_SetText(CommDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
				end

				CloseDropDownMenus()
			end

		----------------------------------
		-- Team name input box
		----------------------------------
			CommDKP.ConfigTab3.TeamNameInput = CreateFrame("EditBox", nil, CommDKP.ConfigTab3)
			CommDKP.ConfigTab3.TeamNameInput:SetAutoFocus(false)
			CommDKP.ConfigTab3.TeamNameInput:SetMultiLine(false)
			CommDKP.ConfigTab3.TeamNameInput:SetSize(160, 24)
			CommDKP.ConfigTab3.TeamNameInput:SetPoint("TOPRIGHT", CommDKP.ConfigTab3.TeamListDropDown, "TOPRIGHT", 160, 0)
			CommDKP.ConfigTab3.TeamNameInput:SetBackdrop({
				bgFile   = "Textures\\white.blp", tile = true,
				edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile",
				tile = true, 
				tileSize = 32, 
				edgeSize = 2
			});
			CommDKP.ConfigTab3.TeamNameInput:SetBackdropColor(0,0,0,0.9)
			CommDKP.ConfigTab3.TeamNameInput:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
			--CommDKP.ConfigTab3.TeamNameInput:SetMaxLetters(6)
			CommDKP.ConfigTab3.TeamNameInput:SetTextColor(1, 1, 1, 1)
			CommDKP.ConfigTab3.TeamNameInput:SetFontObject("CommDKPSmallRight")
			CommDKP.ConfigTab3.TeamNameInput:SetTextInsets(10, 10, 5, 5)
			CommDKP.ConfigTab3.TeamNameInput.tooltipText = L["TEAMNAMEINPUTTOOLTIP"]
			CommDKP.ConfigTab3.TeamNameInput.tooltipDescription = L["TEAMNAMEINPUTTOOLTIPDESC"]
			CommDKP.ConfigTab3.TeamNameInput:SetScript("OnEscapePressed", 
				function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					self:ClearFocus()
				end
			)
			CommDKP.ConfigTab3.TeamNameInput:SetScript("OnEnterPressed", 
				function(self)
					self:HighlightText(0,0)
					if (selectedTeamIndex == nil ) then
						StaticPopupDialogs["RENAME_TEAM"] = {
							text = L["NOTEAMCHOSEN"],
							button1 = L["OK"],
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3
						}
						StaticPopup_Show ("RENAME_TEAM")
					else
						CommDKP:ChangeTeamName(selectedTeamIndex, self:GetText())
						-- if we are performing name change on currently selected team, change main team view dropdown Text
						if tonumber(CommDKP:GetCurrentTeamIndex()) == selectedTeamIndex then
							UIDropDownMenu_SetText(CommDKP.UIConfig.TeamViewChangerDropDown, self:SetText(""))
						end
						UIDropDownMenu_SetText(CommDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
						selectedTeam = nil
						selectedTeamIndex = nil
						CloseDropDownMenus()
						self:ClearFocus()
						self:SetText("")
					end
				end
			)
			CommDKP.ConfigTab3.TeamNameInput:SetScript("OnEnter", 
				function(self)
					if (self.tooltipText) then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
					end
					if (self.tooltipDescription) then
						GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
						GameTooltip:Show();
					end
					if (self.tooltipWarning) then
						GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
						GameTooltip:Show();
					end
				end
			)
			CommDKP.ConfigTab3.TeamNameInput:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)

			

		----------------------------------
		-- Rename selected team button
		----------------------------------	
			CommDKP.ConfigTab3.TeamRename = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 0, 0, L["TEAMRENAME"]);
			CommDKP.ConfigTab3.TeamRename:SetSize(120,25);
			CommDKP.ConfigTab3.TeamRename:ClearAllPoints()
			CommDKP.ConfigTab3.TeamRename:SetPoint("TOPRIGHT", CommDKP.ConfigTab3.TeamNameInput, "TOPRIGHT", 125, 0)
			CommDKP.ConfigTab3.TeamRename:SetScript("OnEnter", 
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(L["TEAMRENAMESELECTED"], 0.25, 0.75, 0.90, 1, true);
					GameTooltip:AddLine(L["TEAMRENAMESELECTEDESC"], 1.0, 1.0, 1.0, true);
					GameTooltip:Show();
				end
			)
			CommDKP.ConfigTab3.TeamRename:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)
			-- rename team function
			CommDKP.ConfigTab3.TeamRename:SetScript("OnClick", 
				function ()	
					if selectedTeamIndex == nil then
						StaticPopupDialogs["RENAME_TEAM"] = {
							text = L["NOTEAMCHOSEN"],
							button1 = L["OK"],
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3
						}
						StaticPopup_Show ("RENAME_TEAM")
					else
						if CheckLeader == 1 then
							CommDKP:ChangeTeamName(selectedTeamIndex, CommDKP.ConfigTab3.TeamNameInput:GetText())
							-- if we are performing name change on currently selected team, change main team view dropdown Text
							if tonumber(CommDKP:GetCurrentTeamIndex()) == selectedTeamIndex then
								UIDropDownMenu_SetText(CommDKP.UIConfig.TeamViewChangerDropDown, CommDKP.ConfigTab3.TeamNameInput:GetText())
							end
							CommDKP.ConfigTab3.TeamNameInput:SetText("")
							UIDropDownMenu_SetText(CommDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
							selectedTeam = nil
							selectedTeamIndex = nil
							CloseDropDownMenus()
						else
							StaticPopupDialogs["NOT_GUILD_MASTER"] = {
								text = L["NOTGUILDMASTER"],
								button1 = L["OK"],
								timeout = 0,
								whileDead = true,
								hideOnEscape = true,
								preferredIndex = 3
							}
							StaticPopup_Show ("NOT_GUILD_MASTER")	
						end
					end
				end
			);

		----------------------------------
		-- Add new team button
		----------------------------------	
		CommDKP.ConfigTab3.TeamAdd = self:CreateButton("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 0, 0, L["TEAMADD"]);
		CommDKP.ConfigTab3.TeamAdd:SetSize(120,25);
		CommDKP.ConfigTab3.TeamAdd:ClearAllPoints()
		CommDKP.ConfigTab3.TeamAdd:SetPoint("BOTTOM", CommDKP.ConfigTab3.TeamRename, "BOTTOM", 0, -40)
		CommDKP.ConfigTab3.TeamAdd:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["TEAMADD"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["TEAMADDDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.ConfigTab3.TeamAdd:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		-- rename team function
		CommDKP.ConfigTab3.TeamAdd:SetScript("OnClick", 
			function ()	
				if CheckLeader == 1 then
					StaticPopupDialogs["ADD_TEAM"] = {
						text = L["TEAMADDDIALOG"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							CommDKP:AddNewTeamToGuild()
							CommDKP.ConfigTab3.TeamNameInput:SetText("")
							UIDropDownMenu_SetText(CommDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
							CloseDropDownMenus()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3
					}
					StaticPopup_Show ("ADD_TEAM")	
				else
					StaticPopupDialogs["NOT_GUILD_MASTER"] = {
						text = L["NOTGUILDMASTER"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3
					}
					StaticPopup_Show ("NOT_GUILD_MASTER")	
				end			
			end
		);

	-- only show whitelist and/or team management if player is a guild master
	if CheckLeader == 1 then
		CommDKP.ConfigTab3.WhitelistContainer:Show()
		CommDKP.ConfigTab3.TeamHeader:Show()
		CommDKP.ConfigTab3.TeamListDropDown:Show()
		CommDKP.ConfigTab3.TeamNameInput:Show()
		CommDKP.ConfigTab3.TeamRename:Show()
		CommDKP.ConfigTab3.TeamAdd:Show()
	else
		CommDKP.ConfigTab3.WhitelistContainer:Hide()
		CommDKP.ConfigTab3.TeamHeader:Hide()
		CommDKP.ConfigTab3.TeamListDropDown:Hide()
		CommDKP.ConfigTab3.TeamNameInput:Hide()
		CommDKP.ConfigTab3.TeamRename:Hide()
		CommDKP.ConfigTab3.TeamAdd:Hide()
	end
end
