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
		MonDKP:FilterDKPTable(core.currentSort, "reset")
		MonDKP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
		table.wipe(core.SelectedData)
		MonDKP:ClassGraph_Update()
		MonDKP:UpdateSeeds()
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
	end
end

function AddRaidToDKPTable()
	local NumGroup = 0;
	local GroupType = "none";

	if IsInGroup() then
		NumGroup = GetNumGroupMembers()
		GroupType = "party"
	elseif IsInRaid() then
		NumGroup = GetNumRaidMembers()
		GroupType = "raid"
	end

	if GroupType ~= "none" then
		local tempName,tempClass;
		local addedUsers, c
		local numPlayers = 0;
		local guildSize = GetNumGuildMembers();
		local name;
		local InGuild = false; -- Only adds player to list if the player is found in the guild roster.

		for i=1, 40 do
			tempName,_,_,_,tempClass = GetRaidRosterInfo(i)
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

local function reset_prev_dkp()
	for i=1, #MonDKP_DKPTable do
		MonDKP_DKPTable[i].previous_dkp = MonDKP_DKPTable[i].dkp
	end
	MonDKP:FilterDKPTable(core.currentSort, "reset")
	MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
end

function MonDKP:ManageEntries()

	-- add raid to dkp table if they don't exist
	MonDKP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 30, -60, "Add Raid Members");
	MonDKP.ConfigTab3.add_raid_to_table:SetSize(120,25);
	MonDKP.ConfigTab3.add_raid_to_table:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Add Raid Members", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Add all raid/party members that are in guild to DKP table. This button is a redundency as the function is fired any time a new member joins the raid for Officers or higher.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("This is a redundency. This function is auto run for officers and above any time someone joins the raid.", 1.0, 0, 0, true);
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

	--[[MonDKP.ConfigTab3.add_raid_header = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab3.add_raid_header:ClearAllPoints();
	MonDKP.ConfigTab3.add_raid_header:SetWidth(400)
	MonDKP.ConfigTab3.add_raid_header:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab3.add_raid_header:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.add_raid_to_table, "TOPLEFT", -20, 5);
	MonDKP.ConfigTab3.add_raid_header:SetText("Add Entries");--]]

	-- remove selected entries button
	MonDKP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 170, -60, "Remove Entries");
	MonDKP.ConfigTab3.remove_entries:SetSize(120,25);
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

	--[[MonDKP.ConfigTab3.remove_entries_header = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab3.remove_entries_header:ClearAllPoints();
	MonDKP.ConfigTab3.remove_entries_header:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab3.remove_entries_header:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.remove_entries, "TOPLEFT", -20, 5);
	MonDKP.ConfigTab3.remove_entries_header:SetText("Remove Entries");--]]


	-- Reset previous DKP -- number showing how much a player has gained or lost since last clear
	MonDKP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 310, -60, "Reset Previous");
	MonDKP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
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

	--[[MonDKP.ConfigTab3.reset_previous_header = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab3.reset_previous_header:ClearAllPoints();
	MonDKP.ConfigTab3.reset_previous_header:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab3.reset_previous_header:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.reset_previous_dkp, "TOPLEFT", -20, 5);
	MonDKP.ConfigTab3.reset_previous_header:SetText("Reset previous DKP");--]]

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