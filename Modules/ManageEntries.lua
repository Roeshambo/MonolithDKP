local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

local function Remove_Entries()
	MonDKP:SeedVerify_Update()
	if core.UpToDate == false and core.IsOfficer == true then
		StaticPopupDialogs["CONFIRM_REMOVE"] = {
			text = "|CFFFF0000WARNING|r: You are attempting to modify an outdated DKP table. This may inadvertently corrupt data for the officers that have the most recent tables.\n\n Are you sure you would like to do this?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				local numPlayers = 0;
				local removedUsers, c;
				for i=1, #core.SelectedData do
					local search = MonDKP:Table_Search(MonDKP_DKPTable, core.SelectedData[i]["player"]);
					if search then
						tremove(MonDKP_DKPTable, search[1][1])
						c = MonDKP:GetCColors(core.SelectedData[i]["class"])
						if i==1 then
							removedUsers = "|cff"..c.hex..core.SelectedData[i]["player"].."|r"
						else
							removedUsers = removedUsers..", |cff"..c.hex..core.SelectedData[i]["player"].."|r"
						end
						numPlayers = numPlayers + 1
					end
				end
				MonDKP:FilterDKPTable(core.currentSort, "reset")
				MonDKP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
				table.wipe(core.SelectedData)
				MonDKP:ClassGraph_Update()
				MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CONFIRM_REMOVE")
	else
		local numPlayers = 0;
		local removedUsers, c;
		for i=1, #core.SelectedData do
			local search = MonDKP:Table_Search(MonDKP_DKPTable, core.SelectedData[i]["player"]);
			if search then
				tremove(MonDKP_DKPTable, search[1][1])
				c = MonDKP:GetCColors(core.SelectedData[i]["class"])
				if i==1 then
					removedUsers = "|cff"..c.hex..core.SelectedData[i]["player"].."|r"
				else
					removedUsers = removedUsers..", |cff"..c.hex..core.SelectedData[i]["player"].."|r"
				end
				numPlayers = numPlayers + 1
			end
		end
		MonDKP:UpdateSeeds()
		MonDKP:FilterDKPTable(core.currentSort, "reset")
		MonDKP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
		table.wipe(core.SelectedData)
		MonDKP:ClassGraph_Update()
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
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
		local name;
		local InGuild = false; -- Only adds player to list if the player is found in the guild roster.
		local GroupSize;

		if GroupType == "raid" then
			GroupSize = 40
		elseif GroupType == "party" then
			GroupSize = 5
		end

		for i=1, GroupSize do
			tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
			for j=1, guildSize do
				name = GetGuildRosterInfo(j)
				name = strsub(name, 1, string.find(name, "-")-1)						-- required to remove server name from player (can remove in classic if this is not an issue)
				if name == tempName then
					InGuild = true;
				end
			end
			if tempName and InGuild then
				if not MonDKP:Table_Search(MonDKP_DKPTable, tempName) then
					tinsert(MonDKP_DKPTable, {
						player=tempName,
						class=tempClass,
						dkp=0,
						previous_dkp=0,
						lifetime_gained = 0,
						lifetime_spent = 0,
					});
					numPlayers = numPlayers + 1;
					c = MonDKP:GetCColors(tempClass)
					if addedUsers == nil then
						addedUsers = "|cff"..c.hex..tempName.."|r"; 
					else
						addedUsers = addedUsers..", |cff"..c.hex..tempName.."|r"
					end
				end
			end
			InGuild = false;
		end
		if addedUsers then
			MonDKP:Print("Added "..numPlayers.." player(s): "..addedUsers)
		end
		if core.ClassGraph then
			MonDKP:ClassGraph_Update()
		else
			MonDKP:ClassGraph()
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset")
		--MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)   removed broadcast on add to prevent crossfire from other officers. Move it to init in the event and guild leader ONLY
	else
		MonDKP:Print("You are not in a party or raid.")
	end
end

local function AddGuildToDKPTable(rank)
	local guildSize = GetNumGuildMembers();
	local class, addedUsers, c, name, rankIndex;
	local numPlayers = 0;

	for i=1, guildSize do
		name,_,rankIndex,_,_,_,_,_,_,_,class = GetGuildRosterInfo(i)
		name = strsub(name, 1, string.find(name, "-")-1)			-- required to remove server name from player (can remove in classic if this is not an issue)
		local search = MonDKP:Table_Search(MonDKP_DKPTable, name)

		if not search and rankIndex <= rank then
			tinsert(MonDKP_DKPTable, {
				player=name,
				class=class,
				dkp=0,
				previous_dkp=0,
				lifetime_gained = 0,
				lifetime_spent = 0,
			});
			numPlayers = numPlayers + 1;
			c = MonDKP:GetCColors(class)
			if addedUsers == nil then
				addedUsers = "|cff"..c.hex..name.."|r"; 
			else
				addedUsers = addedUsers..", |cff"..c.hex..name.."|r"
			end
		end
	end
	MonDKP:FilterDKPTable(core.currentSort, "reset")
	if addedUsers then
		MonDKP:Print("Added "..numPlayers.." player(s): "..addedUsers)
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

	local search = MonDKP:Table_Search(MonDKP_DKPTable, name)

	if not search then
		tinsert(MonDKP_DKPTable, {
			player=name,
			class=class,
			dkp=0,
			previous_dkp=0,
			lifetime_gained = 0,
			lifetime_spent = 0,
		});

		MonDKP:FilterDKPTable(core.currentSort, "reset")
		c = MonDKP:GetCColors(class)
		MonDKP:Print("Added |cff"..c.hex..name.."|r")

		if core.ClassGraph then
			MonDKP:ClassGraph_Update()
		else
			MonDKP:ClassGraph()
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

local function reset_prev_dkp()
	for i=1, #MonDKP_DKPTable do
		MonDKP_DKPTable[i].previous_dkp = MonDKP_DKPTable[i].dkp
	end
	MonDKP:FilterDKPTable(core.currentSort, "reset")
	MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
end

local function UpdateWhitelist()
	if #core.SelectedData > 0 then
		table.wipe(MonDKP_Whitelist)
		for i=1, #core.SelectedData do
			local validate = MonDKP:ValidateSender(core.SelectedData[i].player)

			if not validate then
				StaticPopupDialogs["VALIDATE_OFFICER"] = {
					text = core.SelectedData[i].player.." is not an officer. You may only add ranks that have \"Edit Officer Note\" permissions in guild settings.",
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
			table.insert(MonDKP_Whitelist, core.SelectedData[i].player)
		end
	else
		table.wipe(MonDKP_Whitelist)
	end
	MonDKP.Sync:SendData("MonDKPWhitelist", MonDKP_Whitelist)
	MonDKP:Print("Whitelist Broadcasted")
end

local function ViewWhitelist()
	if #MonDKP_Whitelist > 0 then
		core.SelectedData = {}
		for i=1, #MonDKP_Whitelist do
			local search = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Whitelist[i])

			if search then
				table.insert(core.SelectedData, MonDKP_DKPTable[search[1][1]])
			end
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset")
	end
end

function MonDKP:ManageEntries()

	-- add raid to dkp table if they don't exist
	MonDKP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 30, -90, "Add Raid Members");
	MonDKP.ConfigTab3.add_raid_to_table:SetSize(120,25);
	MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Add Raid Members", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Add all raid/party members that are in guild to DKP table.", 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		local selected = "Are you sure you'd like to add missing raid members to DKP table?";

		StaticPopupDialogs["ADD_RAID_ENTRIES"] = {
		  text = selected,
		  button1 = "Yes",
		  button2 = "No",
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
	MonDKP.ConfigTab3.AddEntriesHeader:SetText("Add/Remove DKP Table Entries"); 

	-- remove selected entries button
	MonDKP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 170, -60, "Remove Entries");
	MonDKP.ConfigTab3.remove_entries:SetSize(120,25);
	MonDKP.ConfigTab3.remove_entries:ClearAllPoints()
	MonDKP.ConfigTab3.remove_entries:SetPoint("LEFT", MonDKP.ConfigTab3.add_raid_to_table, "RIGHT", 20, 0)
	MonDKP.ConfigTab3.remove_entries:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Remove Selected Entries", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Removes selected players from the DKP table. All reference of that player will remain (DKP History and Loot History) but their name will appear gray.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Warning: This action is permanent.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.remove_entries:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.remove_entries:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		if #core.SelectedData > 0 then
			local selected = "Are you sure you'd like to remove: \n\n";

			for i=1, #core.SelectedData do
				local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, core.SelectedData[i].player)

			    if classSearch then
			     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
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
			  button1 = "Yes",
			  button2 = "No",
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
			MonDKP:Print("No entries selected.")
		end
	end);

	-- Reset previous DKP -- number showing how much a player has gained or lost since last clear
	MonDKP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 310, -60, "Reset Previous");
	MonDKP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
	MonDKP.ConfigTab3.reset_previous_dkp:ClearAllPoints()
	MonDKP.ConfigTab3.reset_previous_dkp:SetPoint("LEFT", MonDKP.ConfigTab3.remove_entries, "RIGHT", 20, 0)
	MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Reset Previous DKP", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Resets the previous DKP counter to their current DKP (small gray +/- numbers next to each players current DKP). This does not effect functionality in any way. Just a reference of how much each player has earned/spent since you last reset it.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Recommended to reset in regular intervals (weekly, monthly etc). This is a QOL feature and does not impact functionality.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.reset_previous_dkp:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		StaticPopupDialogs["RESET_PREVIOUS_DKP"] = {
			text = "Are you sure you'd like to reset previous DKP?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
			    reset_prev_dkp()
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
		GameTooltip:SetText("Rank List", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Select a rank and click \"Add Guild Members\" to add all guild members of the selected rank or above to the DKP table.", 1.0, 1.0, 1.0, true);
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
			UIDropDownMenu_SetText(MonDKP.ConfigTab3.GuildRankDropDown, "Select Rank")
		end

		CloseDropDownMenus()
	end

	-- Add Guild to DKP Table Button
	MonDKP.ConfigTab3.AddGuildToDKP = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, "Add Guild Members");
	MonDKP.ConfigTab3.AddGuildToDKP:SetSize(120,25);
	MonDKP.ConfigTab3.AddGuildToDKP:ClearAllPoints()
	MonDKP.ConfigTab3.AddGuildToDKP:SetPoint("LEFT", MonDKP.ConfigTab3.GuildRankDropDown, "RIGHT", 2, 2)
	MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Add Guild to DKP Table", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Adds all guild members that are at or above the selected rank and are not already part of the DKP table.", 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.AddGuildToDKP:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
		if curIndex ~= nil then
			StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
				text = "Are you sure you'd like to add all guild members that are rank \""..curRank.."\" or above?",
				button1 = "Yes",
				button2 = "No",
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
				text = "No rank is selected.",
				button1 = "Ok",
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADD_GUILD_MEMBERS")
		end
	end);

	MonDKP.ConfigTab3.AddTargetToDKP = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 0, 0, "Add Target");
	MonDKP.ConfigTab3.AddTargetToDKP:SetSize(120,25);
	MonDKP.ConfigTab3.AddTargetToDKP:ClearAllPoints()
	MonDKP.ConfigTab3.AddTargetToDKP:SetPoint("LEFT", MonDKP.ConfigTab3.AddGuildToDKP, "RIGHT", 20, 0)
	MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Add Target to DKP Table", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Adds your current target, if a player, to the DKP table. This, unlike all other options, does not require the target to be in your guild.", 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab3.AddTargetToDKP:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
		if UnitIsPlayer("target") == true then
			StaticPopupDialogs["ADD_TARGET_DKP"] = {
				text = "Are you sure you'd like to add "..UnitName("target").." to the DKP list?",
				button1 = "Yes",
				button2 = "No",
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
				text = "No player targeted.",
				button1 = "Ok",
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADD_TARGET_DKP")
		end
	end);

	MonDKP.ConfigTab3.WhitelistContainer = CreateFrame("Frame", nil, MonDKP.ConfigTab3);
	MonDKP.ConfigTab3.WhitelistContainer:SetSize(475, 200);
	MonDKP.ConfigTab3.WhitelistContainer:SetPoint("TOPLEFT", MonDKP.ConfigTab3.GuildRankDropDown, "BOTTOMLEFT", 20, -30)

		-- Whitelist Header
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader = MonDKP.ConfigTab3.WhitelistContainer:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab3.WhitelistContainer, "TOPLEFT", -10, 0);
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetWidth(400)
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetFontObject("MonDKPNormalLeft")
		MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetText("Whitelist Settings |CFF444444(Leader Only)|r\n\nIt is strongly advised you only use this whitelist setting if you wish to restrict what officers require permissions. If you want all officers to have permissions, ignore this settings feature entirely."); 

		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, "Set Whitelist");
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:ClearAllPoints()
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetPoint("TOPLEFT", MonDKP.ConfigTab3.WhitelistContainer.WhitelistHeader, "BOTTOMLEFT", 10, -10)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("Set Whitelist", 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine("Adds selected officers from the DKP table to the whitelist. Whitelist is used to |cffff0000limit|r the officers that have permissions to modify DKP values.", 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine("Using this option with no players selected will clear your whitelist.", 0.2, 1.0, 0.2, true);
			GameTooltip:AddLine("Only officers can be whitelisted. This option is used exclusively to restrict which officers have officer rights within this addon. If you wish for all officers to have permission, leave the whitelist empty.", 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			if #core.SelectedData > 0 then
				StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					text = "Are you sure you'd like to add the selected players to the whitelist?",
					button1 = "Yes",
					button2 = "No",
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
					text = "Are you sure you'd like to clear the whitelist?",
					button1 = "Yes",
					button2 = "No",
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
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, "View Whitelist");
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:ClearAllPoints()
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetPoint("LEFT", MonDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton, "RIGHT", 10, 0)
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("View Whitelist", 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine("Selects all officers on your DKP list that are whitelisted.", 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			if #MonDKP_Whitelist > 0 then
				ViewWhitelist()
			else
				StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					text = "Your whitelist is empty.",
					button1 = "Ok",
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ADD_GUILD_MEMBERS")
			end
		end);

		-- Broadcast Whitelist Button
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, "Send Whitelist");
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:ClearAllPoints()
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetPoint("LEFT", MonDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton, "RIGHT", 30, 0)
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("Send Whitelist", 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine("Broadcasts your whitelist to all officers.", 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine("Recommended you do this when all officers are online. If an officer does not receive this whitelist, they will have full officer permissions. They will not, however, be able to broadcast their information to other officers. You will be notified if they attempt to. If you receive that notification, Send the whitelist and their permissions will be removed.", 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		MonDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			MonDKP.Sync:SendData("MonDKPWhitelist", MonDKP_Whitelist)
			MonDKP:Print("Whitelist Broadcasted")
		end);

	local CheckLeader = MonDKP:GetGuildRankIndex(UnitName("player"))
	if CheckLeader == 1 then
		MonDKP.ConfigTab3.WhitelistContainer:Show()
	else
		MonDKP.ConfigTab3.WhitelistContainer:Hide()
	end



	-- Broadcast DKP Button
	MonDKP.ConfigTab3.broadcastButton = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab3, "BOTTOMLEFT", 15, 15, "Broadcast DKP Table");
	MonDKP.ConfigTab3.broadcastButton:SetSize(140,25)
	MonDKP.ConfigTab3.broadcastButton:SetScript("OnClick", function()
		StaticPopupDialogs["BROADCAST_DKP"] = {
			text = "Are you sure you'd like to broadcast your DKP table?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
			    MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("BROADCAST_DKP")
	end)

	-- Broadcast Loot History Button
	MonDKP.ConfigTab3.broadcastLootButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3.broadcastButton, "TOPRIGHT", 10, 0, "Broadcast Loot History");
	MonDKP.ConfigTab3.broadcastLootButton:SetSize(140,25)
	MonDKP.ConfigTab3.broadcastLootButton:SetScript("OnClick", function()
		StaticPopupDialogs["BROADCAST_LOOT"] = {
			text = "Are you sure you'd like to broadcast your Loot History table?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
			    MonDKP.Sync:SendData("MonDKPBroadcast", "Loot history update in progress...")
				MonDKP.Sync:SendData("MonDKPLogSync", MonDKP_Loot)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("BROADCAST_LOOT")
	end)

	-- Broadcast DKP History Button
	MonDKP.ConfigTab3.broadcastDKPButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3.broadcastLootButton, "TOPRIGHT", 10, 0, "Broadcast DKP History");
	MonDKP.ConfigTab3.broadcastDKPButton:SetSize(140,25)
	MonDKP.ConfigTab3.broadcastDKPButton:SetScript("OnClick", function()
		StaticPopupDialogs["BROADCAST_DKPHIST"] = {
			text = "Are you sure you'd like to broadcast your DKP History table?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
			    MonDKP.Sync:SendData("MonDKPBroadcast", "DKP history update in progress...")
				MonDKP.Sync:SendData("MonDKPDKPLogSync", MonDKP_DKPHistory)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("BROADCAST_DKPHIST")
	end)

	MonDKP.ConfigTab3.BroadcastHeader = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab3.BroadcastHeader:ClearAllPoints();
	MonDKP.ConfigTab3.BroadcastHeader:SetWidth(450)
	MonDKP.ConfigTab3.BroadcastHeader:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab3.BroadcastHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.broadcastButton, "TOPLEFT", 0, 10);
	MonDKP.ConfigTab3.BroadcastHeader:SetText("|cffff0000Warning: If DKP History or Loot history tables are larger than 100 entries it will take time to broadcast them due to Blizzard implemented anti-flood measures. 2500 entries could take up to 3-5 minutes. Please allow 1-2 seconds between broadcasts to allow simultaneous updates. \"Broadcast DKP Table\" should be relatively instant. All broadcasts are GUILD wide (with an exception to bid/raid timers which are restricted to RAID).");
end