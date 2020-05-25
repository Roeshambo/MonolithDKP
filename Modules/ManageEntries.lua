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
		local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), core.SelectedData[i]["player"]);
		local flag = false -- flag = only create archive entry if they appear anywhere in the history. If there's no history, there's no reason anyone would have it.
		local curTime = time()

		if search then
			local path = MonDKP:GetTable(MonDKP_Player_DKPTable, true)[search[1][1]]

			for i=1, #MonDKP:GetTable(MonDKP_Player_DKPHistory, true) do
				if strfind(MonDKP:GetTable(MonDKP_Player_DKPHistory, true)[i].players, ","..path.player..",") or strfind(MonDKP:GetTable(MonDKP_Player_DKPHistory, true)[i].players, path.player..",") == 1 then
					flag = true
				end
			end

			for i=1, #MonDKP:GetTable(MonDKP_Player_Loot, true) do
				if MonDKP:GetTable(MonDKP_Player_Loot, true)[i].player == path.player then
					flag = true
				end
			end
			
			if flag then 		-- above 2 loops flags character if they have any loot/dkp history. Only inserts to archive and broadcasts if found. Other players will not have the entry if no history exists
				if not MonDKP:GetTable(MonDKP_Player_Archive, true)[core.SelectedData[i].player] then
					MonDKP:GetTable(MonDKP_Player_Archive, true)[core.SelectedData[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime }
				else
					MonDKP:GetTable(MonDKP_Player_Archive, true)[core.SelectedData[i].player].deleted = true
					MonDKP:GetTable(MonDKP_Player_Archive, true)[core.SelectedData[i].player].edited = curTime
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

			tremove(MonDKP:GetTable(MonDKP_Player_DKPTable, true), search[1][1])

			local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_Standby, true), core.SelectedData[i].player, "player");

			if search2 then
				table.remove(MonDKP:GetTable(MonDKP_Player_Standby, true), search2[1][1])
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
				if not MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), tempName) then
					tinsert(MonDKP:GetTable(MonDKP_Player_DKPTable, true), {
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
					if MonDKP:GetTable(MonDKP_Player_Archive, true)[tempName] and MonDKP:GetTable(MonDKP_Player_Archive, true)[tempName].deleted then
						MonDKP:GetTable(MonDKP_Player_Archive, true)[tempName].deleted = "Recovered"
						MonDKP:GetTable(MonDKP_Player_Archive, true)[tempName].edited = curTime
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
		local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), name)

		if not search and (level == nil or charLevel >= level) and (rank == nil or rankIndex == rank) then
			tinsert(MonDKP:GetTable(MonDKP_Player_DKPTable, true), {
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
			if MonDKP:GetTable(MonDKP_Player_Archive, true)[name] and MonDKP:GetTable(MonDKP_Player_Archive, true)[name].deleted then
				MonDKP:GetTable(MonDKP_Player_Archive, true)[name].deleted = "Recovered"
				MonDKP:GetTable(MonDKP_Player_Archive, true)[name].edited = curTime
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

	local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), name)

	if not search then
		tinsert(MonDKP:GetTable(MonDKP_Player_DKPTable, true), {
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
		if MonDKP:GetTable(MonDKP_Player_Archive, true)[name] and MonDKP:GetTable(MonDKP_Player_Archive, true)[name].deleted then
			MonDKP:GetTable(MonDKP_Player_Archive, true)[name].deleted = "Recovered"
			MonDKP:GetTable(MonDKP_Player_Archive, true)[name].edited = curTime
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

function MonDKP:reset_prev_dkp(player)
	if player then
		local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), player, "player")

		if search then
			MonDKP:GetTable(MonDKP_Player_DKPTable, true)[search[1][1]].previous_dkp = MonDKP:GetTable(MonDKP_Player_DKPTable, true)[search[1][1]].dkp
		end
	else
		for i=1, #MonDKP:GetTable(MonDKP_Player_DKPTable, true) do
			MonDKP:GetTable(MonDKP_Player_DKPTable, true)[i].previous_dkp = MonDKP:GetTable(MonDKP_Player_DKPTable, true)[i].dkp
		end
	end
end

local function UpdateWhitelist()
	if #core.SelectedData > 0 then
		table.wipe(MonDKP:GetTable(MonDKP_Player_Whitelist))
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
			table.insert(MonDKP:GetTable(MonDKP_Player_Whitelist), core.SelectedData[i].player)
		end

		local verifyLeadAdded = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_Whitelist), UnitName("player"))

		if not verifyLeadAdded then
			local pname = UnitName("player");
			table.insert(MonDKP:GetTable(MonDKP_Player_Whitelist), pname)		-- verifies leader is included in white list. Adds if they aren't
		end
	else
		table.wipe(MonDKP:GetTable(MonDKP_Player_Whitelist))
	end
	MonDKP.Sync:SendData("MonDKPWhitelist", MonDKP:GetTable(MonDKP_Player_Whitelist))
	MonDKP:Print(L["WHITELISTBROADCASTED"])
end

local function ViewWhitelist()
	if #MonDKP:GetTable(MonDKP_Player_Whitelist) > 0 then
		core.SelectedData = {}
		for i=1, #MonDKP:GetTable(MonDKP_Player_Whitelist) do
			local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), MonDKP:GetTable(MonDKP_Player_Whitelist)[i])

			if search then
				table.insert(core.SelectedData, MonDKP:GetTable(MonDKP_Player_DKPTable, true)[search[1][1]])
			end
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset")
	end
end

function MonDKP:ManageEntries()

	-- add raid to dkp table if they don't exist
	MonDKP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 30, -90, L["ADDRAIDMEMBERS"]);
	MonDKP.ConfigTab3.add_raid_to_table:SetSize(120,25);
	MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDRAIDMEMBERS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDRAIDMEMBERSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
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
	end);

	MonDKP.ConfigTab3.AddEntriesHeader = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab3.AddEntriesHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.add_raid_to_table, "TOPLEFT", -10, 10);
	MonDKP.ConfigTab3.AddEntriesHeader:SetWidth(400)
	MonDKP.ConfigTab3.AddEntriesHeader:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab3.AddEntriesHeader:SetText(L["ADDREMDKPTABLEENTRIES"]); 

	-- remove selected entries button
	MonDKP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 170, -60, L["REMOVEENTRIES"]);
	MonDKP.ConfigTab3.remove_entries:SetSize(120,25);
	MonDKP.ConfigTab3.remove_entries:ClearAllPoints()
	MonDKP.ConfigTab3.remove_entries:SetPoint("LEFT", MonDKP.ConfigTab3.add_raid_to_table, "RIGHT", 20, 0)
	MonDKP.ConfigTab3.remove_entries:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["REMOVESELECTEDENTRIES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["REMSELENTRIESTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["REMSELENTRIESTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.remove_entries:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.remove_entries:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		if #core.SelectedData > 0 then
			local selected = L["CONFIRMREMOVESELECT"]..": \n\n";

			for i=1, #core.SelectedData do
				local classSearch = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), core.SelectedData[i].player)

			    if classSearch then
			     	c = MonDKP:GetCColors(MonDKP:GetTable(MonDKP_Player_DKPTable, true)[classSearch[1][1]].class)
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
	end);

	-- Reset previous DKP -- number showing how much a player has gained or lost since last clear
	MonDKP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 310, -60, L["RESETPREVIOUS"]);
	MonDKP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
	MonDKP.ConfigTab3.reset_previous_dkp:ClearAllPoints()
	MonDKP.ConfigTab3.reset_previous_dkp:SetPoint("LEFT", MonDKP.ConfigTab3.remove_entries, "RIGHT", 20, 0)
	MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["RESETPREVDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["RESETPREVDKPTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["RESETPREVDKPTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
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
	end);

	local curIndex;
	local curRank;

	MonDKP.ConfigTab3.GuildRankDropDown = CreateFrame("FRAME", "MonDKPConfigReasonDropDown", MonDKP.ConfigTab3, "MonolithDKPUIDropDownMenuTemplate")
	MonDKP.ConfigTab3.GuildRankDropDown:SetPoint("TOPLEFT", MonDKP.ConfigTab3.add_raid_to_table, "BOTTOMLEFT", -17, -15)
	MonDKP.ConfigTab3.GuildRankDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["RANKLIST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["RANKLISTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.GuildRankDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	UIDropDownMenu_SetWidth(MonDKP.ConfigTab3.GuildRankDropDown, 105)
	UIDropDownMenu_SetText(MonDKP.ConfigTab3.GuildRankDropDown, "Select Rank")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(MonDKP.ConfigTab3.GuildRankDropDown, function(self, level, menuList)
	local rank = UIDropDownMenu_CreateInfo()
		rank.func = self.SetValue
		rank.fontObject = "MonDKPSmallCenter"

		local rankList = GetGuildRankList()

		for i=1, #rankList do
			rank.text, rank.arg1, rank.arg2, rank.checked, rank.isNotRadio = rankList[i].name, rankList[i].name, rankList[i].index, rankList[i].name == curRank, true
			UIDropDownMenu_AddButton(rank)
		end
	end)

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

	-- Add Guild to DKP Table Button
	MonDKP.ConfigTab3.AddGuildToDKP = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDGUILDMEMBERS"]);
	MonDKP.ConfigTab3.AddGuildToDKP:SetSize(120,25);
	MonDKP.ConfigTab3.AddGuildToDKP:ClearAllPoints()
	MonDKP.ConfigTab3.AddGuildToDKP:SetPoint("LEFT", MonDKP.ConfigTab3.GuildRankDropDown, "RIGHT", 2, 2)
	MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDGUILDDKPTABLE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDGUILDDKPTABLETT"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
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
	end);

	MonDKP.ConfigTab3.AddTargetToDKP = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDTARGET"]);
	MonDKP.ConfigTab3.AddTargetToDKP:SetSize(120,25);
	MonDKP.ConfigTab3.AddTargetToDKP:ClearAllPoints()
	MonDKP.ConfigTab3.AddTargetToDKP:SetPoint("LEFT", MonDKP.ConfigTab3.AddGuildToDKP, "RIGHT", 20, 0)
	MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDTARGETTODKPTABLE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDTARGETTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
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
	end);

	MonDKP.ConfigTab3.CleanList = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, L["PURGELIST"]);
	MonDKP.ConfigTab3.CleanList:SetSize(120,25);
	MonDKP.ConfigTab3.CleanList:ClearAllPoints()
	MonDKP.ConfigTab3.CleanList:SetPoint("TOP", MonDKP.ConfigTab3.AddTargetToDKP, "BOTTOM", 0, -16)
	MonDKP.ConfigTab3.CleanList:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["PURGELIST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["PURGELISTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.CleanList:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.CleanList:SetScript("OnClick", function()
		StaticPopupDialogs["PURGE_CONFIRM"] = {
			text = L["PURGECONFIRM"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				local purgeString, c, name;
				local count = 0;
				local i = 1;

				while i <= #MonDKP:GetTable(MonDKP_Player_DKPTable, true) do
					local search = MonDKP:TableStrFind(MonDKP:GetTable(MonDKP_Player_DKPHistory, true), MonDKP:GetTable(MonDKP_Player_DKPTable, true)[i].player, "players")

					if MonDKP:GetTable(MonDKP_Player_DKPTable, true)[i].dkp == 0 and not search then
						c = MonDKP:GetCColors(MonDKP:GetTable(MonDKP_Player_DKPTable, true)[i].class)
						name = MonDKP:GetTable(MonDKP_Player_DKPTable, true)[i].player;

						if purgeString == nil then
							purgeString = "|cff"..c.hex..name.."|r"; 
						else
							purgeString = purgeString..", |cff"..c.hex..name.."|r"
						end

						count = count + 1;
						table.remove(MonDKP:GetTable(MonDKP_Player_DKPTable, true), i)
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
	end)

	MonDKP.ConfigTab3.WhitelistContainer = CreateFrame("Frame", nil, MonDKP.ConfigTab3);
	MonDKP.ConfigTab3.WhitelistContainer:SetSize(475, 200);
	MonDKP.ConfigTab3.WhitelistContainer:SetPoint("TOPLEFT", MonDKP.ConfigTab3.GuildRankDropDown, "BOTTOMLEFT", 20, -30)

		-- Whitelist Header
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader = MonDKP.ConfigTab3.WhitelistContainer:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab3.WhitelistContainer, "TOPLEFT", -10, 0);
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetWidth(400)
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetFontObject("MonDKPNormalLeft")
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetText(L["WHITELISTHEADER"]); 

		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SETWHITELIST"]);
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:ClearAllPoints()
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetPoint("TOPLEFT", MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader, "BOTTOMLEFT", 10, -10)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["SETWHITELIST"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["SETWHITELISTTTDESC1"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["SETWHITELISTTTDESC2"], 0.2, 1.0, 0.2, true);
			GameTooltip:AddLine(L["SETWHITELISTTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
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
		end);

		-- View Whitelist Button
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["VIEWWHITELISTBTN"]);
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:ClearAllPoints()
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetPoint("LEFT", MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton, "RIGHT", 10, 0)
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["VIEWWHITELISTBTN"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["VIEWWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			if #MonDKP:GetTable(MonDKP_Player_Whitelist) > 0 then
				ViewWhitelist()
			else
				StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					text = L["WHITELISTEMPTY"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ADD_GUILD_MEMBERS")
			end
		end);

		-- Broadcast Whitelist Button
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SENDWHITELIST"]);
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:ClearAllPoints()
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetPoint("LEFT", MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton, "RIGHT", 30, 0)
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["SENDWHITELIST"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["SENDWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["SENDWHITELISTTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			MonDKP.Sync:SendData("MonDKPWhitelist", MonDKP:GetTable(MonDKP_Player_Whitelist))
			MonDKP:Print(L["WHITELISTBROADCASTED"])
		end);

	local CheckLeader = MonDKP:GetGuildRankIndex(UnitName("player"))
	if CheckLeader == 1 then
		MonDKP.ConfigTab3.WhitelistContainer:Show()
	else
		MonDKP.ConfigTab3.WhitelistContainer:Hide()
	end
end