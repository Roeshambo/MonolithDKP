local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local EntryTableTemp = {}  	-- all DKP and Loot entries 
local DKPTableTemp = {}		-- temp DKP table
local DKPStringTemp = ""	-- stores DKP comparisons to create a new entry if they are different
local PlayerStringTemp = "" -- stores player list to create new DKPHistory entry if any values differ from the DKPTable

-- ONE ENTRY for all adjustments
-- Add up all players into a temporary table. Compare differences in DKP from the MonDKP_DKPTable and create one entry to account for all differences
-- IE: Domali has 36 dkp, Roeshambo has 50 dkp.. Adding up all history and removing loot awards shows Domali at 30 dkp and Roeshambo at 100 dkp.
-- Create a new entry in DKP history (hidden) that says players = "Domali,Roeshambo," and dkp = "-6,-50" and label as "Migration Adjustment" (translation not necessary)
-- Give entry ["hidden"] = true value.

function MonDKP:MigrateTables()
	for i=1, #MonDKP_Loot do
		if MonDKP_Loot[i].bids then
			for k1,v1 in pairs(MonDKP_Loot[i].bids) do
				for k2,v2 in pairs(v1) do
					if k2 == "player" then
						MonDKP_Loot[i].bids[k1].bidder = v2				-- fixes "player" in "bids" tables (screws the search up)
						MonDKP_Loot[i].bids[k1].player = nil
					end
				end
			end
		end
	end

	for i=1, #MonDKP_Loot do
		table.sort(MonDKP_Loot, function(a,b)   	-- inverts tables; oldest to newest
			return a["date"] < b["date"]
		end)
		
		if not MonDKP_Meta.Loot[UnitName("player")] then
			MonDKP_Meta.Loot[UnitName("player")] = {current=1, lowest=1}
		else
			MonDKP_Meta.Loot[UnitName("player")].current = MonDKP_Meta.Loot[UnitName("player")].current + 1
		end

		MonDKP_Loot[i].index = UnitName("player").."-"..MonDKP_Meta.Loot[UnitName("player")].current

		if tonumber(MonDKP_Loot[i].cost) > 0 then
			MonDKP_Loot[i].cost = tonumber(MonDKP_Loot[i].cost) * -1
		end
		table.insert(EntryTableTemp, MonDKP_Loot[i])
	end

	for i=1, #MonDKP_DKPHistory do
		table.sort(MonDKP_DKPHistory, function(a,b)  -- inverts tables; oldest to newest
			return a["date"] < b["date"]
		end)

		if not MonDKP_Meta.DKP[UnitName("player")] then
			MonDKP_Meta.DKP[UnitName("player")] = {current=1, lowest=1}
		else
			MonDKP_Meta.DKP[UnitName("player")].current = MonDKP_Meta.DKP[UnitName("player")].current + 1
		end

		MonDKP_DKPHistory[i].index = UnitName("player").."-"..MonDKP_Meta.DKP[UnitName("player")].current

		table.insert(EntryTableTemp, MonDKP_DKPHistory[i])
	end

	for i=1, #EntryTableTemp do   -- attempt to recreate a timeline to apply decays, if they exist
		table.sort(EntryTableTemp, function(a,b)   	-- inverts tables; oldest to newest
			return a["date"] < b["date"]
		end)

		if EntryTableTemp[i].loot then
			local search = MonDKP:Table_Search(DKPTableTemp, EntryTableTemp[i].player, "player")

			if search then
				DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(EntryTableTemp[i].cost)
			else
				table.insert(DKPTableTemp, { player=EntryTableTemp[i].player, dkp=tonumber(EntryTableTemp[i].cost) })
			end
		elseif EntryTableTemp[i].reason then
			local players = {strsplit(",", strsub(EntryTableTemp[i].players, 1, -2))}

			if strfind(EntryTableTemp[i].dkp, "%-%d*%.?%d+%%") then -- is a decay, calculate new values
				local f = {strfind(EntryTableTemp[i].dkp, "%-%d*%.?%d+%%")}
				local playerString = ""
				local DKPString = ""
				local value = tonumber(strsub(EntryTableTemp[i].dkp, f[1]+1, f[2]-1)) / 100

				for j=1, #players do
					local search2 = MonDKP:Table_Search(DKPTableTemp, players[j], "player")

					if search2 and DKPTableTemp[search2[1][1]].dkp > 0 then
						local deduction = DKPTableTemp[search2[1][1]].dkp * -value;
						deduction = MonDKP_round(deduction, MonDKP_DB.modes.rounding)

						DKPTableTemp[search2[1][1]].dkp = DKPTableTemp[search2[1][1]].dkp + deduction
						playerString = playerString..players[j]..","
						DKPString = DKPString..deduction..","
					else
						playerString = playerString..players[j]..","
						DKPString = DKPString.."0,"

						if not search2 then
							table.insert(DKPTableTemp, { player=players[j], dkp=0 })
						end
					end

				end
				DKPString = DKPString..EntryTableTemp[i].dkp

				local EntrySearch = MonDKP:Table_Search(MonDKP_DKPHistory, EntryTableTemp[i].date, "date")

				if EntrySearch then
					MonDKP_DKPHistory[EntrySearch[1][1]].players = playerString
					MonDKP_DKPHistory[EntrySearch[1][1]].dkp = DKPString
				end
			else
				local dkp = tonumber(EntryTableTemp[i].dkp)

				for j=1, #players do
					local search = MonDKP:Table_Search(DKPTableTemp, players[j], "player")

					if search then
						DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + dkp
					else
						table.insert(DKPTableTemp, { player=players[j], dkp=dkp })
					end
				end
			end
		end
	end

	-- Create new DKPHistory entry compensating for difference between history and DKPTable (if some history was lost due to overwriting)
	for i=1, #MonDKP_DKPTable do 
		local search = MonDKP:Table_Search(DKPTableTemp, MonDKP_DKPTable[i].player, "player")

		if search then
			if MonDKP_DKPTable[i].dkp ~= DKPTableTemp[search[1][1]].dkp then
				local val = MonDKP_DKPTable[i].dkp - DKPTableTemp[search[1][1]].dkp

				PlayerStringTemp = PlayerStringTemp..MonDKP_DKPTable[i].player..","
				DKPStringTemp = DKPStringTemp..val..","
			end
		end
	end

	if DKPStringTemp ~= "" and PlayerStringTemp ~= "" then
		MonDKP_Meta.DKP[UnitName("player")].current = MonDKP_Meta.DKP[UnitName("player")].current + 1

		local insert = {
			players = PlayerStringTemp,
			index 	= UnitName("player").."-"..MonDKP_Meta.DKP[UnitName("player")].current,
			dkp 	= DKPStringTemp.."-1%",
			date 	= time(),
			reason	= "Migration Correction",
			hidden	= true,
		}
		table.insert(MonDKP_DKPHistory, insert)
	end

	local curTime = time();
	for i=1, #DKPTableTemp do 	-- finds who had history but was deleted; adds them to archive if so
		local search = MonDKP:Table_Search(MonDKP_DKPTable, DKPTableTemp[i].player)

		if not search then
			MonDKP_Archive[DKPTableTemp[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime } 
		end
	end

	table.sort(MonDKP_Loot, function(a,b)
		return a["date"] > b["date"]
	end)
	table.sort(MonDKP_DKPHistory, function(a,b)
		return a["date"] > b["date"]
	end)

	local leader = MonDKP:GetGuildRankGroup(1) 	-- get leader index
	GuildRosterSetPublicNote(leader[1].index, "{MonDKP="..UnitName("player").."}")
end

function MonDKP:MigrationFrame()
	if not MigrationFrame then
		MigrationFrame = CreateFrame("Frame", "MonDKP_MigrationDisplayFrame", UIParent, "ShadowOverlaySmallTemplate");

		MigrationFrame:SetPoint("TOP", UIParent, "TOP", 0, -200);
		MigrationFrame:SetSize(600, 500);
		MigrationFrame:SetBackdrop( {
			bgFile = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
		});
		MigrationFrame:SetBackdropColor(0,0,0,0.9);
		MigrationFrame:SetBackdropBorderColor(1,1,1,1)
		MigrationFrame:SetFrameStrata("DIALOG")
		MigrationFrame:SetFrameLevel(5)
		MigrationFrame:SetMovable(true);
		MigrationFrame:EnableMouse(true);
		MigrationFrame:RegisterForDrag("LeftButton");
		MigrationFrame:SetScript("OnDragStart", MigrationFrame.StartMoving);
		MigrationFrame:SetScript("OnDragStop", MigrationFrame.StopMovingOrSizing);

		-- Close Button
		MigrationFrame.closeContainer = CreateFrame("Frame", "MonDKPMigrationClose", MigrationFrame)
		MigrationFrame.closeContainer:SetPoint("CENTER", MigrationFrame, "TOPRIGHT", -4, 0)
		MigrationFrame.closeContainer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
		});
		MigrationFrame.closeContainer:SetBackdropColor(0,0,0,0.9)
		MigrationFrame.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
		MigrationFrame.closeContainer:SetSize(28, 28)

		MigrationFrame.closeBtn = CreateFrame("Button", nil, MigrationFrame, "UIPanelCloseButton")
		MigrationFrame.closeBtn:SetPoint("CENTER", MigrationFrame.closeContainer, "TOPRIGHT", -14, -14)

		MigrationFrame.description = MigrationFrame:CreateFontString(nil, "OVERLAY")
		MigrationFrame.description:SetFontObject("MonDKPNormalLeft");
		MigrationFrame.description:SetWidth(500);
		MigrationFrame.description:SetPoint("TOPLEFT", MigrationFrame, "TOPLEFT", 24, -20);

		MigrationFrame.MigrateButton = self:CreateButton("BOTTOMLEFT", MigrationFrame, "BOTTOMLEFT", 15, 15, L["MIGRATE"]);
		MigrationFrame.MigrateButton:SetSize(140,25)
		MigrationFrame.MigrateButton:SetScript("OnClick", function()

			StaticPopupDialogs["MIGRATECONFIRM"] = {
				text = L["CONFIRMMIGRATE"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					MonDKP:MigrateTables()
					MonDKP.Sync:SendData("MDKPMigrated", "Swap")
					ReloadUI()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("MIGRATECONFIRM")
		end)
	end

	local leader = MonDKP:GetGuildRankGroup(1) 	-- get leader index
	local _,_,_,_,_,_,note = GetGuildRosterInfo(leader[1].index) -- extract leader public note
	local offCheck = string.match(note, "{MonDKP=(%a+)}")	-- extract officer name (if any)

	if not offCheck then
		MigrationFrame.description:SetText("")
		MigrationFrame.description:SetText(L["MIGRATEINST1"])
		if MigrationFrame.DeleteTables and MigrationFrame.DeleteTables:IsShown() then
			MigrationFrame.DeleteTables:Hide()
		end
	else
		MigrationFrame.description:SetText("")
		MigrationFrame.description:SetText(string.format(L["MIGRATEINST2"], offCheck, offCheck))
		MigrationFrame.DeleteTables = self:CreateButton("BOTTOMLEFT", MigrationFrame, "BOTTOMLEFT", 15, 15, L["DELETETABLES"]);
		MigrationFrame.DeleteTables:SetSize(140,25)
		MigrationFrame.DeleteTables:SetScript("OnClick", function()

			StaticPopupDialogs["DELETEDENTRYCONFIRM"] = {
				text = L["DELETETABLES"].."?",
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					MonDKP_DKPTable = nil
					MonDKP_Loot = nil
					MonDKP_DKPHistory = nil
					MonDKP_DKPTable = {}
					MonDKP_Loot = {}
					MonDKP_DKPHistory = {}
					ReloadUI()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("DELETEDENTRYCONFIRM")
		end)

		if MigrationFrame.MigrateButton and MigrationFrame.MigrateButton:IsShown() then
			MigrationFrame.MigrateButton:Hide()
		end
	end

	MigrationFrame.MigrateButton:Hide()
	MigrationFrame:Show()
	if MonDKP.ChangeLogDisplay and MonDKP.ChangeLogDisplay:IsShown() then
		MonDKP.ChangeLogDisplay:Hide()
	end

	if not offCheck then
		C_Timer.After(5, function()
			MigrationFrame.MigrateButton:Show()
		end)
	end

	MigrationFrame:SetScript("OnHide", function()
		if MonDKP_DB.defaults.HideChangeLogs < core.BuildNumber then
			MonDKP.ChangeLogDisplay:Show()
		end
	end)
end