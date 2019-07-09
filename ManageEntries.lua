local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

local function Remove_Entries()
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
	MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
end

local function AddRaidToDKPTable()
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
		for i=1, 40 do
			tempName,_,_,_,tempClass = GetRaidRosterInfo(i)
			if tempName then
				if not MonDKP:Table_Search(MonDKP_DKPTable, tempName) then
					tinsert(MonDKP_DKPTable, {
						player=tempName,
						class=tempClass,
						dkp=0,
						previous_dkp=0
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
		end
		if addedUsers then
			MonDKP:Print("Added "..numPlayers.." player(s): "..addedUsers)
		else
			MonDKP:Print("No new players added")
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset")
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
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
	MonDKP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 40, -100, "Add Raid Members");
	MonDKP.ConfigTab3.add_raid_to_table:SetSize(120,25);
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

	MonDKP.ConfigTab3.add_raid_header = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab3.add_raid_header:ClearAllPoints();
	MonDKP.ConfigTab3.add_raid_header:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab3.add_raid_header:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.add_raid_to_table, "TOPLEFT", -20, 10);
	MonDKP.ConfigTab3.add_raid_header:SetText("Add any raid members that don't belong to the DKP table. Any\nmembers that belong to it will remain unchanged. This also adds\noffline raid/party members.");

	-- remove selected entries button
	MonDKP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 40, -200, "Remove Entries");
	MonDKP.ConfigTab3.remove_entries:SetSize(120,25);
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

	MonDKP.ConfigTab3.remove_entries_header = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab3.remove_entries_header:ClearAllPoints();
	MonDKP.ConfigTab3.remove_entries_header:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab3.remove_entries_header:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.remove_entries, "TOPLEFT", -20, 10);
	MonDKP.ConfigTab3.remove_entries_header:SetText("Remove selected entries from DKP table.\n|cffff0000(WARNING: This action is permanent.)|r");


	-- Reset previous DKP -- number showing how much a player has gained or lost since last clear
	MonDKP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOP", MonDKP.ConfigTab3.remove_entries, "BOTTOM", 0, -75, "Reset");
	MonDKP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
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

	MonDKP.ConfigTab3.reset_previous_header = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab3.reset_previous_header:ClearAllPoints();
	MonDKP.ConfigTab3.reset_previous_header:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab3.reset_previous_header:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab3.reset_previous_dkp, "TOPLEFT", -20, 10);
	MonDKP.ConfigTab3.reset_previous_header:SetText("Reset previous DKP. This should be reset in regular intervals\n(weekly, monthly etc)");

end