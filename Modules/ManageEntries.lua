local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;


local function Remove_Entries()
	MonDKP:StatusVerify_Update()
	local numPlayers = 0;
	local removedUsers, c;
	local deleted = {}

	for i=1, #core.SelectedData do
		local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), core.SelectedData[i]["player"]);
		local flag = false -- flag = only create archive entry if they appear anywhere in the history. If there's no history, there's no reason anyone would have it.
		local curTime = time()

		if search then
			local path = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]]

			for i=1, #MonDKP:GetTable(MonDKP_DKPHistory, true) do
				if strfind(MonDKP:GetTable(MonDKP_DKPHistory, true)[i].players, ","..path.player..",") or strfind(MonDKP:GetTable(MonDKP_DKPHistory, true)[i].players, path.player..",") == 1 then
					flag = true
				end
			end

			for i=1, #MonDKP:GetTable(MonDKP_Loot, true) do
				if MonDKP:GetTable(MonDKP_Loot, true)[i].player == path.player then
					flag = true
				end
			end
			
			if flag then 		-- above 2 loops flags character if they have any loot/dkp history. Only inserts to archive and broadcasts if found. Other players will not have the entry if no history exists
				if not MonDKP:GetTable(MonDKP_Archive, true)[core.SelectedData[i].player] then
					MonDKP:GetTable(MonDKP_Archive, true)[core.SelectedData[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime }
				else
					MonDKP:GetTable(MonDKP_Archive, true)[core.SelectedData[i].player].deleted = true
					MonDKP:GetTable(MonDKP_Archive, true)[core.SelectedData[i].player].edited = curTime
				end
				table.insert(deleted, { player=path.player, deleted=true })
			end

			c = MonDKP:GetCColors(core.SelectedData[i]["class"])
			if i==1 then
				removedUsers = "|cff"..c.hex..core.SelectedData[i]["player"].."|r"
			else
				removedUsers = removedUsers..", |cff"..c.hex..core.SelectedData[i]["player"].."|r"
			end
			numPlayers = numPlayers + 1

			tremove(MonDKP:GetTable(MonDKP_DKPTable, true), search[1][1])

			local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Standby, true), core.SelectedData[i].player, "player");

			if search2 then
				table.remove(MonDKP:GetTable(MonDKP_Standby, true), search2[1][1])
			end
		end
	end
	table.wipe(core.SelectedData)
	MonDKPSelectionCount_Update()
	MonDKP:FilterDKPTable(core.currentSort, "reset")
	MonDKP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
	MonDKP:ClassGraph_Update()
	if #deleted >0 then
		MonDKP.Sync:SendData("MonDKPDelUsers", deleted)
	end
end

function AddRaidToDKPTable()
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
			if tempName and InGuild then
				if not MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), tempName) then
					tinsert(MonDKP:GetTable(MonDKP_DKPTable, true), {
						player=tempName,
						class=tempClass,
						dkp=0,
						previous_dkp=0,
						lifetime_gained = 0,
						lifetime_spent = 0,
						rank = rankIndex,
						rankName = rank,
						spec = "No Spec Reported",
						role = "No Role Reported",
					});
					numPlayers = numPlayers + 1;
					c = MonDKP:GetCColors(tempClass)
					if addedUsers == nil then
						addedUsers = "|cff"..c.hex..tempName.."|r"; 
					else
						addedUsers = addedUsers..", |cff"..c.hex..tempName.."|r"
					end
					if MonDKP:GetTable(MonDKP_Archive, true)[tempName] and MonDKP:GetTable(MonDKP_Archive, true)[tempName].deleted then
						MonDKP:GetTable(MonDKP_Archive, true)[tempName].deleted = "Recovered"
						MonDKP:GetTable(MonDKP_Archive, true)[tempName].edited = curTime
						FlagRecovery = true
					end
				end
			end
			InGuild = false;
		end
		if addedUsers then
			MonDKP:Print(L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
		end
		if core.ClassGraph then
			MonDKP:ClassGraph_Update()
		else
			MonDKP:ClassGraph()
		end
		if FlagRecovery then 
			MonDKP:Print(L["YOUHAVERECOVERED"])
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset")
	else
		MonDKP:Print(L["NOPARTYORRAID"])
	end
end

local function AddGuildToDKPTable(rank, level)
	local guildSize = GetNumGuildMembers();
	local class, addedUsers, c, name, rankName, rankIndex, charLevel;
	local numPlayers = 0;
	local FlagRecovery = false
	local curTime = time()

	for i=1, guildSize do
		name,rankName,rankIndex,charLevel,_,_,_,_,_,_,class = GetGuildRosterInfo(i)
		name = strsub(name, 1, string.find(name, "-")-1)			-- required to remove server name from player (can remove in classic if this is not an issue)
		local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), name)

		if not search and (level == nil or charLevel >= level) and (rank == nil or rankIndex == rank) then
			tinsert(MonDKP:GetTable(MonDKP_DKPTable, true), {
				player=name,
				class=class,
				dkp=0,
				previous_dkp=0,
				lifetime_gained = 0,
				lifetime_spent = 0,
				rank=rankIndex,
				rankName=rankName,
				spec = "No Spec Reported",
				role = "No Role Reported",
			});
			numPlayers = numPlayers + 1;
			c = MonDKP:GetCColors(class)
			if addedUsers == nil then
				addedUsers = "|cff"..c.hex..name.."|r"; 
			else
				addedUsers = addedUsers..", |cff"..c.hex..name.."|r"
			end
			if MonDKP:GetTable(MonDKP_Archive, true)[name] and MonDKP:GetTable(MonDKP_Archive, true)[name].deleted then
				MonDKP:GetTable(MonDKP_Archive, true)[name].deleted = "Recovered"
				MonDKP:GetTable(MonDKP_Archive, true)[name].edited = curTime
				FlagRecovery = true
			end
		end
	end
	MonDKP:FilterDKPTable(core.currentSort, "reset")
	if addedUsers then
		MonDKP:Print(L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
	end
	if FlagRecovery then 
		MonDKP:Print(L["YOUHAVERECOVERED"])
	end
	if core.ClassGraph then
		MonDKP:ClassGraph_Update()
	else
		MonDKP:ClassGraph()
	end
end

local function AddTargetToDKPTable()
	local name = UnitName("target");
	local _,class = UnitClass("target");
	local c;
	local curTime = time()

	local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), name)

	if not search then
		tinsert(MonDKP:GetTable(MonDKP_DKPTable, true), {
			player=name,
			class=class,
			dkp=0,
			previous_dkp=0,
			lifetime_gained = 0,
			lifetime_spent = 0,
			rank=20,
			rankName="None",
			spec = "No Spec Reported",
			role = "No Role Reported",
		});

		MonDKP:FilterDKPTable(core.currentSort, "reset")
		c = MonDKP:GetCColors(class)
		MonDKP:Print(L["ADDED"].." |cff"..c.hex..name.."|r")

		if core.ClassGraph then
			MonDKP:ClassGraph_Update()
		else
			MonDKP:ClassGraph()
		end
		if MonDKP:GetTable(MonDKP_Archive, true)[name] and MonDKP:GetTable(MonDKP_Archive, true)[name].deleted then
			MonDKP:GetTable(MonDKP_Archive, true)[name].deleted = "Recovered"
			MonDKP:GetTable(MonDKP_Archive, true)[name].edited = curTime
			MonDKP:Print(L["YOUHAVERECOVERED"])
		end
	end
end

function GetGuildRankList()
	local numRanks = GuildControlGetNumRanks()
	local tempTable = {}
	for i=1, numRanks do
		table.insert(tempTable, {index = i-1, name = GuildControlGetRankName(i)})
	end
	
	return tempTable;
end

-------
-- TEAM FUNCTIONS
-------

function MonDKP:GetCurrentTeamIndex() 
	local _tmpString = MonDKP:GetTable(MonDKP_DB, false)["defaults"]["CurrentTeam"] or "0"
	return _tmpString
end

function MonDKP:GetCurrentTeamName()
	local _string = "Unguilded";
	local teams = MonDKP:GetTable(MonDKP_DB, false)["teams"];

	if tablelength(teams) > 0 then
		_string = MonDKP:GetTable(MonDKP_DB, false)["teams"][MonDKP:GetCurrentTeamIndex()].name
	end

	return _string
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1 
	end
	return count
end

function MonDKP:GetGuildTeamList() 
	local _list = {};
	local _tmp = MonDKP:GetTable(MonDKP_DB, false)["teams"]
	local index = 1

	for k,v in pairs(_tmp) do
		if(type(v) == "table") then
			for z,x in pairs(v) do
				table.insert(_list, {tonumber(k), v.name})
				index = index + 1
			end
		end
	end
	-- so, because team "index" is a string Lua doesn't give a flying fuck
	-- about order of adding elements to "string" indexed table so we have to unfuck it
	table.sort(_list,  
		function(a, b)
			return a[1] < b[1]
		end
	)

	return _list
end

function ChangeTeamName(index, _name) 
	MonDKP:GetTable(MonDKP_DB, false)["teams"][tostring(index)].name = _name;
	MonDKP.Sync:SendData("MonDKPTeams", {Teams =  MonDKP:GetTable(MonDKP_DB, false)["teams"]} , nil)
end

local function AddNewTeamToGuild() 
	local _index = 0
	local _tmp = MonDKP:GetTable(MonDKP_DB, false)["teams"]
	local realmName = MonDKP:GetRealmName();
	local guildName = MonDKP:GetGuildName();

	-- get the index of last team from MonDKP_DB
	for k,v in pairs(_tmp) do
		if(type(v) == "table") then
			_index = _index + 1
		end
	end

	-- add new team definition to MonDKP_DB with generic GuildName-index
	MonDKP:GetTable(MonDKP_DB, false)["teams"][tostring(_index)] = { ["name"] = guildName.."-"..tostring(_index)}

	------
	-- add new team with new "index" to all "team" tables in saved variables
	-- MonDKP_Loot, MonDKP_DKPTable, MonDKP_DKPHistory, MonDKP_MinBids, MonDKP_MaxBids, MonDKP_Standby, MonDKP_Archive
	------
		MonDKP:GetTable(MonDKP_Loot, false)[tostring(_index)] = {}
		MonDKP:GetTable(MonDKP_DKPTable, false)[tostring(_index)] = {}
		MonDKP:GetTable(MonDKP_DKPHistory, false)[tostring(_index)] = {}
		MonDKP:GetTable(MonDKP_MinBids, false)[tostring(_index)] = {}
		MonDKP:GetTable(MonDKP_MaxBids, false)[tostring(_index)] = {}
		MonDKP:GetTable(MonDKP_Standby, false)[tostring(_index)] = {}
		MonDKP:GetTable(MonDKP_Archive, false)[tostring(_index)] = {}

		MonDKP.Sync:SendData("MonDKPTeams", {Teams =  MonDKP:GetTable(MonDKP_DB, false)["teams"]} , nil)
end

-------
-- TEAM FUNCTIONS END
-------

function MonDKP:reset_prev_dkp(player)
	if player then
		local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), player, "player")

		if search then
			MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].previous_dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].dkp
		end
	else
		for i=1, #MonDKP:GetTable(MonDKP_DKPTable, true) do
			MonDKP:GetTable(MonDKP_DKPTable, true)[i].previous_dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[i].dkp
		end
	end
end

local function UpdateWhitelist()
	if #core.SelectedData > 0 then
		table.wipe(MonDKP:GetTable(MonDKP_Whitelist))
		for i=1, #core.SelectedData do
			local validate = MonDKP:ValidateSender(core.SelectedData[i].player)

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
			table.insert(MonDKP:GetTable(MonDKP_Whitelist), core.SelectedData[i].player)
		end

		local verifyLeadAdded = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Whitelist), UnitName("player"))

		if not verifyLeadAdded then
			local pname = UnitName("player");
			table.insert(MonDKP:GetTable(MonDKP_Whitelist), pname)		-- verifies leader is included in white list. Adds if they aren't
		end
	else
		table.wipe(MonDKP:GetTable(MonDKP_Whitelist))
	end
	MonDKP.Sync:SendData("MonDKPWhitelist", MonDKP:GetTable(MonDKP_Whitelist))
	MonDKP:Print(L["WHITELISTBROADCASTED"])
end

local function ViewWhitelist()
	if #MonDKP:GetTable(MonDKP_Whitelist) > 0 then
		core.SelectedData = {}
		for i=1, #MonDKP:GetTable(MonDKP_Whitelist) do
			local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), MonDKP:GetTable(MonDKP_Whitelist)[i])

			if search then
				table.insert(core.SelectedData, MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]])
			end
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset")
	end
end


---------------------------------------
-- Manage DKP TAB.Create()
---------------------------------------
function MonDKP:ManageEntries()

	local CheckLeader = MonDKP:GetGuildRankIndex(UnitName("player"))
	-- add raid to dkp table if they don't exist

	----------------------------------
	-- Header text above the buttons
	----------------------------------
		MonDKP.ConfigTab3.AddEntriesHeader = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab3.AddEntriesHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.add_raid_to_table, "TOPLEFT", -10, 10);
		MonDKP.ConfigTab3.AddEntriesHeader:SetWidth(400)
		MonDKP.ConfigTab3.AddEntriesHeader:SetFontObject("MonDKPNormalLeft")
		MonDKP.ConfigTab3.AddEntriesHeader:SetText(L["ADDREMDKPTABLEENTRIES"]); 

	----------------------------------
	-- add raid members button
	----------------------------------
		MonDKP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 30, -90, L["ADDRAIDMEMBERS"]);
		MonDKP.ConfigTab3.add_raid_to_table:SetSize(120,25);

		-- tooltip for add raid members button
		MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDRAIDMEMBERS"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDRAIDMEMBERSTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)

		-- confirmation dialog to remove user(s)
		MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnClick", 
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
		MonDKP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 170, -60, L["REMOVEENTRIES"]);
		MonDKP.ConfigTab3.remove_entries:SetSize(120,25);
		MonDKP.ConfigTab3.remove_entries:ClearAllPoints()
		MonDKP.ConfigTab3.remove_entries:SetPoint("LEFT", MonDKP.ConfigTab3.add_raid_to_table, "RIGHT", 20, 0)
		MonDKP.ConfigTab3.remove_entries:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["REMOVESELECTEDENTRIES"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["REMSELENTRIESTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["REMSELENTRIESTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.remove_entries:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to remove user(s)
		MonDKP.ConfigTab3.remove_entries:SetScript("OnClick", 
			function ()	
				if #core.SelectedData > 0 then
					local selected = L["CONFIRMREMOVESELECT"]..": \n\n";

					for i=1, #core.SelectedData do
						local classSearch = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), core.SelectedData[i].player)

						if classSearch then
							c = MonDKP:GetCColors(MonDKP:GetTable(MonDKP_DKPTable, true)[classSearch[1][1]].class)
						else
							c = { hex="ffffff" }
						end
						if i == 1 then
							selected = selected.."|cff"..c.hex..core.SelectedData[i].player.."|r"
						else
							selected = selected..", |cff"..c.hex..core.SelectedData[i].player.."|r"
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
					MonDKP:Print(L["NOENTRIESSELECTED"])
				end
			end
		);
	----------------------------------
	-- Reset previous DKP button -- number showing how much a player has gained or lost since last clear
	----------------------------------
		MonDKP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 310, -60, L["RESETPREVIOUS"]);
		MonDKP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
		MonDKP.ConfigTab3.reset_previous_dkp:ClearAllPoints()
		MonDKP.ConfigTab3.reset_previous_dkp:SetPoint("LEFT", MonDKP.ConfigTab3.remove_entries, "RIGHT", 20, 0)
		MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnEnter",
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["RESETPREVDKP"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["RESETPREVDKPTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["RESETPREVDKPTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to remove user(s)
		MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnClick",
			function ()	
				StaticPopupDialogs["RESET_PREVIOUS_DKP"] = {
					text = L["RESETPREVCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						MonDKP:reset_prev_dkp()
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
		MonDKP.ConfigTab3.GuildRankDropDown = CreateFrame("FRAME", "MonDKPConfigReasonDropDown", MonDKP.ConfigTab3, "MonolithDKPUIDropDownMenuTemplate")
		MonDKP.ConfigTab3.GuildRankDropDown:SetPoint("TOPLEFT", MonDKP.ConfigTab3.add_raid_to_table, "BOTTOMLEFT", -17, -15)
		MonDKP.ConfigTab3.GuildRankDropDown:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["RANKLIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["RANKLISTTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.GuildRankDropDown:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		UIDropDownMenu_SetWidth(MonDKP.ConfigTab3.GuildRankDropDown, 105)
		UIDropDownMenu_SetText(MonDKP.ConfigTab3.GuildRankDropDown, "Select Rank")

		-- Create and bind the initialization function to the dropdown menu
		UIDropDownMenu_Initialize(MonDKP.ConfigTab3.GuildRankDropDown, 
			function(self, level, menuList)
				local rank = UIDropDownMenu_CreateInfo()
					rank.func = self.SetValue
					rank.fontObject = "MonDKPSmallCenter"

					local rankList = GetGuildRankList()

					for i=1, #rankList do
						rank.text, rank.arg1, rank.arg2, rank.checked, rank.isNotRadio = rankList[i].name, rankList[i].name, rankList[i].index, rankList[i].name == curRank, true
						UIDropDownMenu_AddButton(rank)
					end
			end
		)

		-- Dropdown Menu Function
		function MonDKP.ConfigTab3.GuildRankDropDown:SetValue(arg1, arg2)
			if curRank ~= arg1 then
				curRank = arg1
				curIndex = arg2
				UIDropDownMenu_SetText(MonDKP.ConfigTab3.GuildRankDropDown, arg1)
			else
				curRank = nil
				curIndex = nil
				UIDropDownMenu_SetText(MonDKP.ConfigTab3.GuildRankDropDown, L["SELECTRANK"])
			end

			CloseDropDownMenus()
		end

	----------------------------------
	-- Add Guild to DKP Table Button
	----------------------------------
		MonDKP.ConfigTab3.AddGuildToDKP = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDGUILDMEMBERS"]);
		MonDKP.ConfigTab3.AddGuildToDKP:SetSize(120,25);
		MonDKP.ConfigTab3.AddGuildToDKP:ClearAllPoints()
		MonDKP.ConfigTab3.AddGuildToDKP:SetPoint("LEFT", MonDKP.ConfigTab3.GuildRankDropDown, "RIGHT", 2, 2)
		MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDGUILDDKPTABLE"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDGUILDDKPTABLETT"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to add user(s)
		MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnClick",
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
		MonDKP.ConfigTab3.AddTargetToDKP = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDTARGET"]);
		MonDKP.ConfigTab3.AddTargetToDKP:SetSize(120,25);
		MonDKP.ConfigTab3.AddTargetToDKP:ClearAllPoints()
		MonDKP.ConfigTab3.AddTargetToDKP:SetPoint("LEFT", MonDKP.ConfigTab3.AddGuildToDKP, "RIGHT", 20, 0)
		MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDTARGETTODKPTABLE"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDTARGETTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnClick", 
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
		MonDKP.ConfigTab3.CleanList = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["PURGELIST"]);
		MonDKP.ConfigTab3.CleanList:SetSize(120,25);
		MonDKP.ConfigTab3.CleanList:ClearAllPoints()
		MonDKP.ConfigTab3.CleanList:SetPoint("TOP", MonDKP.ConfigTab3.AddTargetToDKP, "BOTTOM", 0, -16)
		MonDKP.ConfigTab3.CleanList:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["PURGELIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["PURGELISTTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.CleanList:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		MonDKP.ConfigTab3.CleanList:SetScript("OnClick", 
			function()
				StaticPopupDialogs["PURGE_CONFIRM"] = {
					text = L["PURGECONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						local purgeString, c, name;
						local count = 0;
						local i = 1;

						while i <= #MonDKP:GetTable(MonDKP_DKPTable, true) do
							local search = MonDKP:TableStrFind(MonDKP:GetTable(MonDKP_DKPHistory, true), MonDKP:GetTable(MonDKP_DKPTable, true)[i].player, "players")

							if MonDKP:GetTable(MonDKP_DKPTable, true)[i].dkp == 0 and not search then
								c = MonDKP:GetCColors(MonDKP:GetTable(MonDKP_DKPTable, true)[i].class)
								name = MonDKP:GetTable(MonDKP_DKPTable, true)[i].player;

								if purgeString == nil then
									purgeString = "|cff"..c.hex..name.."|r"; 
								else
									purgeString = purgeString..", |cff"..c.hex..name.."|r"
								end

								count = count + 1;
								table.remove(MonDKP:GetTable(MonDKP_DKPTable, true), i)
							else
								i=i+1;
							end
						end
						if count > 0 then
							MonDKP:Print(L["PURGELIST"].." ("..count.."):")
							MonDKP:Print(purgeString)
							MonDKP:FilterDKPTable(core.currentSort, "reset")
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

		MonDKP.ConfigTab3.WhitelistContainer = CreateFrame("Frame", nil, MonDKP.ConfigTab3);
		MonDKP.ConfigTab3.WhitelistContainer:SetSize(475, 200);
		MonDKP.ConfigTab3.WhitelistContainer:SetPoint("TOPLEFT", MonDKP.ConfigTab3.GuildRankDropDown, "BOTTOMLEFT", 20, -30)

		-- Whitelist Header
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader = MonDKP.ConfigTab3.WhitelistContainer:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab3.WhitelistContainer, "TOPLEFT", -10, 0);
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetWidth(400)
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetFontObject("MonDKPNormalLeft")
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetText(L["WHITELISTHEADER"]); 

		-- Whitelist button
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SETWHITELIST"]);
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:ClearAllPoints()
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetPoint("TOPLEFT", MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader, "BOTTOMLEFT", 10, -10)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["SETWHITELIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["SETWHITELISTTTDESC1"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["SETWHITELISTTTDESC2"], 0.2, 1.0, 0.2, true);
				GameTooltip:AddLine(L["SETWHITELISTTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to add user(s)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnClick", 
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
		
				MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["VIEWWHITELISTBTN"]);
				MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:ClearAllPoints()
				MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetPoint("LEFT", MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton, "RIGHT", 10, 0)
				MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnEnter",
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(L["VIEWWHITELISTBTN"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddLine(L["VIEWWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
						GameTooltip:Show();
					end
				)
				MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnLeave", 
					function(self)
						GameTooltip:Hide()
					end
				)
				MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnClick", 
					function ()	-- confirmation dialog to add user(s)
						if #MonDKP:GetTable(MonDKP_Whitelist) > 0 then
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
		
				MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SENDWHITELIST"]);
				MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:ClearAllPoints()
				MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetPoint("LEFT", MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton, "RIGHT", 30, 0)
				MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnEnter", 
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(L["SENDWHITELIST"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddLine(L["SENDWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
						GameTooltip:AddLine(L["SENDWHITELISTTTWARN"], 1.0, 0, 0, true);
						GameTooltip:Show();
					end
				)
				MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnLeave",
					function(self)
						GameTooltip:Hide()
					end
				)
				-- confirmation dialog to add user(s)
				MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnClick",
					function ()	
						MonDKP.Sync:SendData("MonDKPWhitelist", MonDKP:GetTable(MonDKP_Whitelist))
						MonDKP:Print(L["WHITELISTBROADCASTED"])
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
		MonDKP.ConfigTab3.TeamHeader = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab3.TeamHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", -10, -5);
		MonDKP.ConfigTab3.TeamHeader:SetWidth(400)
		MonDKP.ConfigTab3.TeamHeader:SetFontObject("MonDKPNormalLeft")
		MonDKP.ConfigTab3.TeamHeader:SetText(L["TEAMMANAGEMENTHEADER"].." of "..MonDKP:GetGuildName()..""); 

		----------------------------------
		-- Drop down with lists of teams 
		----------------------------------
			MonDKP.ConfigTab3.TeamListDropDown = CreateFrame("FRAME", "MonDKPConfigReasonDropDown", MonDKP.ConfigTab3, "MonolithDKPUIDropDownMenuTemplate")
			--MonDKP.ConfigTab3.TeamManagementContainer.TeamListDropDown:ClearAllPoints()
			MonDKP.ConfigTab3.TeamListDropDown:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.TeamHeader, "BOTTOMLEFT", 0, -50)
			-- tooltip on mouseOver
			MonDKP.ConfigTab3.TeamListDropDown:SetScript("OnEnter", 
				function(self) 
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(L["TEAMLIST"], 0.25, 0.75, 0.90, 1, true);
					GameTooltip:AddLine(L["TEAMLISTDESC"], 1.0, 1.0, 1.0, true);
					GameTooltip:Show();
				end
			)
			MonDKP.ConfigTab3.TeamListDropDown:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)
			UIDropDownMenu_SetWidth(MonDKP.ConfigTab3.TeamListDropDown, 105)
			UIDropDownMenu_SetText(MonDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])

			-- Create and bind the initialization function to the dropdown menu
			UIDropDownMenu_Initialize(MonDKP.ConfigTab3.TeamListDropDown, 
				function(self, level, menuList)
					local dropDownMenuItem = UIDropDownMenu_CreateInfo()
					dropDownMenuItem.func = self.SetValue
					dropDownMenuItem.fontObject = "MonDKPSmallCenter"
				
					teamList = MonDKP:GetGuildTeamList()

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
			function MonDKP.ConfigTab3.TeamListDropDown:SetValue(arg1, arg2)
				if selectedTeamIndex ~= arg2 then
					selectedTeam = arg1
					selectedTeamIndex = arg2
					UIDropDownMenu_SetText(MonDKP.ConfigTab3.TeamListDropDown, arg1)
					MonDKP.ConfigTab3.TeamNameInput:SetText(arg1)
				else
					selectedTeam = nil
					selectedTeamIndex = nil
					MonDKP.ConfigTab3.TeamNameInput:SetText("")
					UIDropDownMenu_SetText(MonDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
				end

				CloseDropDownMenus()
			end

		----------------------------------
		-- Team name input box
		----------------------------------
			MonDKP.ConfigTab3.TeamNameInput = CreateFrame("EditBox", nil, MonDKP.ConfigTab3)
			MonDKP.ConfigTab3.TeamNameInput:SetAutoFocus(false)
			MonDKP.ConfigTab3.TeamNameInput:SetMultiLine(false)
			MonDKP.ConfigTab3.TeamNameInput:SetSize(160, 24)
			MonDKP.ConfigTab3.TeamNameInput:SetPoint("TOPRIGHT", MonDKP.ConfigTab3.TeamListDropDown, "TOPRIGHT", 160, 0)
			MonDKP.ConfigTab3.TeamNameInput:SetBackdrop({
				bgFile   = "Textures\\white.blp", tile = true,
				edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile",
				tile = true, 
				tileSize = 32, 
				edgeSize = 2
			});
			MonDKP.ConfigTab3.TeamNameInput:SetBackdropColor(0,0,0,0.9)
			MonDKP.ConfigTab3.TeamNameInput:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
			--MonDKP.ConfigTab3.TeamNameInput:SetMaxLetters(6)
			MonDKP.ConfigTab3.TeamNameInput:SetTextColor(1, 1, 1, 1)
			MonDKP.ConfigTab3.TeamNameInput:SetFontObject("MonDKPSmallRight")
			MonDKP.ConfigTab3.TeamNameInput:SetTextInsets(10, 10, 5, 5)
			MonDKP.ConfigTab3.TeamNameInput.tooltipText = L["TEAMNAMEINPUTTOOLTIP"]
			MonDKP.ConfigTab3.TeamNameInput.tooltipDescription = L["TEAMNAMEINPUTTOOLTIPDESC"]
			MonDKP.ConfigTab3.TeamNameInput:SetScript("OnEscapePressed", 
				function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					self:ClearFocus()
				end
			)
			MonDKP.ConfigTab3.TeamNameInput:SetScript("OnEnterPressed", 
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
						ChangeTeamName(selectedTeamIndex, self:GetText())
						-- if we are performing name change on currently selected team, change main team view dropdown Text
						if tonumber(MonDKP:GetCurrentTeamIndex()) == selectedTeamIndex then
							UIDropDownMenu_SetText(MonDKP.UIConfig.TeamViewChangerDropDown, self:SetText(""))
						end
						UIDropDownMenu_SetText(MonDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
						selectedTeam = nil
						selectedTeamIndex = nil
						CloseDropDownMenus()
						self:ClearFocus()
						self:SetText("")
					end
				end
			)
			MonDKP.ConfigTab3.TeamNameInput:SetScript("OnEnter", 
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
			MonDKP.ConfigTab3.TeamNameInput:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)

			

		----------------------------------
		-- Rename selected team button
		----------------------------------	
			MonDKP.ConfigTab3.TeamRename = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["TEAMRENAME"]);
			MonDKP.ConfigTab3.TeamRename:SetSize(120,25);
			MonDKP.ConfigTab3.TeamRename:ClearAllPoints()
			MonDKP.ConfigTab3.TeamRename:SetPoint("TOPRIGHT", MonDKP.ConfigTab3.TeamNameInput, "TOPRIGHT", 125, 0)
			MonDKP.ConfigTab3.TeamRename:SetScript("OnEnter", 
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(L["TEAMRENAMESELECTED"], 0.25, 0.75, 0.90, 1, true);
					GameTooltip:AddLine(L["TEAMRENAMESELECTEDESC"], 1.0, 1.0, 1.0, true);
					GameTooltip:Show();
				end
			)
			MonDKP.ConfigTab3.TeamRename:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)
			-- rename team function
			MonDKP.ConfigTab3.TeamRename:SetScript("OnClick", 
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
							ChangeTeamName(selectedTeamIndex, MonDKP.ConfigTab3.TeamNameInput:GetText())
							-- if we are performing name change on currently selected team, change main team view dropdown Text
							if tonumber(MonDKP:GetCurrentTeamIndex()) == selectedTeamIndex then
								UIDropDownMenu_SetText(MonDKP.UIConfig.TeamViewChangerDropDown, MonDKP.ConfigTab3.TeamNameInput:GetText())
							end
							MonDKP.ConfigTab3.TeamNameInput:SetText("")
							UIDropDownMenu_SetText(MonDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
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
		MonDKP.ConfigTab3.TeamAdd = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["TEAMADD"]);
		MonDKP.ConfigTab3.TeamAdd:SetSize(120,25);
		MonDKP.ConfigTab3.TeamAdd:ClearAllPoints()
		MonDKP.ConfigTab3.TeamAdd:SetPoint("BOTTOM", MonDKP.ConfigTab3.TeamRename, "BOTTOM", 0, -40)
		MonDKP.ConfigTab3.TeamAdd:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["TEAMADD"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["TEAMADDDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		MonDKP.ConfigTab3.TeamAdd:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		-- rename team function
		MonDKP.ConfigTab3.TeamAdd:SetScript("OnClick", 
			function ()	
				if CheckLeader == 1 then
					StaticPopupDialogs["ADD_TEAM"] = {
						text = L["TEAMADDDIALOG"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							AddNewTeamToGuild()
							MonDKP.ConfigTab3.TeamNameInput:SetText("")
							UIDropDownMenu_SetText(MonDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
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
		MonDKP.ConfigTab3.WhitelistContainer:Show()
		MonDKP.ConfigTab3.TeamHeader:Show()
		MonDKP.ConfigTab3.TeamListDropDown:Show()
		MonDKP.ConfigTab3.TeamNameInput:Show()
		MonDKP.ConfigTab3.TeamRename:Show()
		MonDKP.ConfigTab3.TeamAdd:Show()
	else
		MonDKP.ConfigTab3.WhitelistContainer:Hide()
		MonDKP.ConfigTab3.TeamHeader:Hide()
		MonDKP.ConfigTab3.TeamListDropDown:Hide()
		MonDKP.ConfigTab3.TeamNameInput:Hide()
		MonDKP.ConfigTab3.TeamRename:Hide()
		MonDKP.ConfigTab3.TeamAdd:Hide()
	end
end