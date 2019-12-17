local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local curReason;

function MonDKP:AdjustDKP(value)
	local adjustReason = curReason;
	local curTime = time()
	local c;
	local curOfficer = UnitName("player")

	if not IsInRaid() then
		c = MonDKP:GetCColors();
	end

	if (curReason == L["OTHER"]) then adjustReason = L["OTHER"].." - "..MonDKP.ConfigTab2.otherReason:GetText(); end
	if curReason == L["BOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss; end
	if curReason == L["NEWBOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss.." ("..L["FIRSTKILL"]..")" end
	if (#core.SelectedData > 0 and adjustReason and adjustReason ~= L["OTHER"].." - "..L["ENTEROTHERREASONHERE"]) then
		if core.IsOfficer then
			local tempString = "";       -- stores list of changes
			local dkpHistoryString = ""   -- stores list for MonDKP_DKPHistory
			for i=1, #core.SelectedData do
				local current;
				local search = MonDKP:Table_Search(MonDKP_DKPTable, core.SelectedData[i]["player"])
				if search then
					if not IsInRaid() then
						if i < #core.SelectedData then
							tempString = tempString.."|cff"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r, ";
						else
							tempString = tempString.."|cff"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r";
						end
					end
					dkpHistoryString = dkpHistoryString..core.SelectedData[i]["player"]..","
					current = MonDKP_DKPTable[search[1][1]].dkp
					MonDKP_DKPTable[search[1][1]].dkp = MonDKP_round(tonumber(current + value), MonDKP_DB.modes.rounding)
					if value > 0 then
						MonDKP_DKPTable[search[1][1]]["lifetime_gained"] = MonDKP_round(tonumber(MonDKP_DKPTable[search[1][1]]["lifetime_gained"] + value), MonDKP_DB.modes.rounding)
					end
				end
			end
			local newIndex = curOfficer.."-"..curTime
			tinsert(MonDKP_DKPHistory, 1, {players=dkpHistoryString, dkp=value, reason=adjustReason, date=curTime, index=newIndex})
			MonDKP.Sync:SendData("MonDKPDKPDist", MonDKP_DKPHistory[1])

			if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
				MonDKP:DKPHistory_Update(true)
			end
			DKPTable_Update()
			if IsInRaid() then
				MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..value.." "..L["FORREASON"]..": "..adjustReason)
			else
				MonDKP.Sync:SendData("MonDKPBCastMsg", L["DKPADJUSTBY"].." "..value.." "..L["FORPLAYERS"]..": ")
				MonDKP.Sync:SendData("MonDKPBCastMsg", tempString)
				MonDKP.Sync:SendData("MonDKPBCastMsg", L["REASON"]..": "..adjustReason)
			end
		end
	else
		local validation;
		if (#core.SelectedData == 0 and not adjustReason) then
			validation = L["PLAYERREASONVALIDATE"]
		elseif #core.SelectedData == 0 then
			validation = L["PLAYERVALIDATE"]
		elseif not adjustReason or MonDKP.ConfigTab2.otherReason:GetText() == "" or MonDKP.ConfigTab2.otherReason:GetText() == L["ENTEROTHERREASONHERE"] then
			validation = L["OTHERREASONVALIDATE"]
		end

		StaticPopupDialogs["VALIDATION_PROMPT"] = {
			text = validation,
			button1 = L["OK"],
			timeout = 5,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("VALIDATION_PROMPT")
	end
end

local function DecayDKP(amount, deductionType, GetSelections)
	local playerString = "";
	local dkpString = "";
	local curTime = time()
	local curOfficer = UnitName("player")

	for key, value in ipairs(MonDKP_DKPTable) do
		local dkp = tonumber(value["dkp"])
		local player = value["player"]
		local amount = amount;
		amount = tonumber(amount) / 100		-- converts percentage to a decimal
		if amount < 0 then
			amount = amount * -1			-- flips value to positive if officer accidently used negative number in editbox
		end
		local deducted;

		if (GetSelections and MonDKP:Table_Search(core.SelectedData, player)) or GetSelections == false then
			if dkp > 0 then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = dkp - deducted
					value["dkp"] = MonDKP_round(tonumber(dkp), MonDKP_DB.modes.rounding);
					dkpString = dkpString.."-"..MonDKP_round(deducted, MonDKP_DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end
			elseif dkp < 0 and MonDKP.ConfigTab2.AddNegative:GetChecked() then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = (deducted - dkp) * -1
					value["dkp"] = MonDKP_round(tonumber(dkp), MonDKP_DB.modes.rounding)
					dkpString = dkpString..MonDKP_round(-deducted, MonDKP_DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end	
			end
		end
	end
	dkpString = dkpString.."-"..amount.."%";

	if tonumber(amount) < 0 then amount = amount * -1 end		-- flips value to positive if officer accidently used a negative number

	local newIndex = curOfficer.."-"..curTime
	tinsert(MonDKP_DKPHistory, 1, {players=playerString, dkp=dkpString, reason=L["WEEKLYDECAY"], date=curTime, index=newIndex})
	MonDKP.Sync:SendData("MonDKPDecay", MonDKP_DKPHistory[1])
	if MonDKP.ConfigTab6.history then
		MonDKP:DKPHistory_Update(true)
	end
	DKPTable_Update()
end

local function RaidTimerPopout_Create()
	if not MonDKP.RaidTimerPopout then
		MonDKP.RaidTimerPopout = CreateFrame("Frame", "MonDKP_RaidTimerPopout", UIParent, "ShadowOverlaySmallTemplate");

	    MonDKP.RaidTimerPopout:SetPoint("RIGHT", UIParent, "RIGHT", -300, 100);
	    MonDKP.RaidTimerPopout:SetSize(100, 50);
	    MonDKP.RaidTimerPopout:SetBackdrop( {
	      bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
	      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
	      insets = { left = 0, right = 0, top = 0, bottom = 0 }
	    });
	    MonDKP.RaidTimerPopout:SetBackdropColor(0,0,0,0.9);
	    MonDKP.RaidTimerPopout:SetBackdropBorderColor(1,1,1,1)
	    MonDKP.RaidTimerPopout:SetFrameStrata("DIALOG")
	    MonDKP.RaidTimerPopout:SetFrameLevel(15)
	    MonDKP.RaidTimerPopout:SetMovable(true);
	    MonDKP.RaidTimerPopout:EnableMouse(true);
	    MonDKP.RaidTimerPopout:RegisterForDrag("LeftButton");
	    MonDKP.RaidTimerPopout:SetScript("OnDragStart", MonDKP.RaidTimerPopout.StartMoving);
	    MonDKP.RaidTimerPopout:SetScript("OnDragStop", MonDKP.RaidTimerPopout.StopMovingOrSizing);

	    -- Popout Close Button
	    MonDKP.RaidTimerPopout.closeContainer = CreateFrame("Frame", "MonDKPChangeLogClose", MonDKP.RaidTimerPopout)
	    MonDKP.RaidTimerPopout.closeContainer:SetPoint("CENTER", MonDKP.RaidTimerPopout, "TOPRIGHT", -8, -4)
	    MonDKP.RaidTimerPopout.closeContainer:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	    });
	    MonDKP.RaidTimerPopout.closeContainer:SetBackdropColor(0,0,0,0.9)
	    MonDKP.RaidTimerPopout.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	    MonDKP.RaidTimerPopout.closeContainer:SetScale(0.7)
	    MonDKP.RaidTimerPopout.closeContainer:SetSize(28, 28)

	    MonDKP.RaidTimerPopout.closeBtn = CreateFrame("Button", nil, MonDKP.RaidTimerPopout, "UIPanelCloseButton")
	    MonDKP.RaidTimerPopout.closeBtn:SetPoint("CENTER", MonDKP.RaidTimerPopout.closeContainer, "TOPRIGHT", -14, -14)
	    MonDKP.RaidTimerPopout.closeBtn:SetScale(0.7)
	    MonDKP.RaidTimerPopout.closeBtn:HookScript("OnClick", function()
	    	MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">");
	    end)

	    -- Raid Timer Output
	    MonDKP.RaidTimerPopout.Output = MonDKP.RaidTimerPopout:CreateFontString(nil, "OVERLAY")
	    MonDKP.RaidTimerPopout.Output:SetFontObject("MonDKPLargeLeft");
	    MonDKP.RaidTimerPopout.Output:SetScale(0.8)
	    MonDKP.RaidTimerPopout.Output:SetPoint("CENTER", MonDKP.RaidTimerPopout, "CENTER", 0, 0);
	    MonDKP.RaidTimerPopout.Output:SetText("|cff00ff0000:00:00|r")
	    MonDKP.RaidTimerPopout:Hide();
	else
		MonDKP.RaidTimerPopout:Show()
	end
end

function MonDKP:AdjustDKPTab_Create()
	MonDKP.ConfigTab2.header = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.header:SetPoint("TOPLEFT", MonDKP.ConfigTab2, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab2.header:SetFontObject("MonDKPLargeCenter")
	MonDKP.ConfigTab2.header:SetText(L["ADJUSTDKP"]);
	MonDKP.ConfigTab2.header:SetScale(1.2)

	MonDKP.ConfigTab2.description = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.description:SetPoint("TOPLEFT", MonDKP.ConfigTab2.header, "BOTTOMLEFT", 7, -10);
	MonDKP.ConfigTab2.description:SetWidth(400)
	MonDKP.ConfigTab2.description:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab2.description:SetText(L["ADJUSTDESC"]); 

	-- Reason DROPDOWN box 
	-- Create the dropdown, and configure its appearance
	MonDKP.ConfigTab2.reasonDropDown = CreateFrame("FRAME", "MonDKPConfigReasonDropDown", MonDKP.ConfigTab2, "MonolithDKPUIDropDownMenuTemplate")
	MonDKP.ConfigTab2.reasonDropDown:SetPoint("TOPLEFT", MonDKP.ConfigTab2.description, "BOTTOMLEFT", -23, -60)
	UIDropDownMenu_SetWidth(MonDKP.ConfigTab2.reasonDropDown, 150)
	UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown, L["SELECTREASON"])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(MonDKP.ConfigTab2.reasonDropDown, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "MonDKPSmallCenter"
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["ONTIMEBONUS"], L["ONTIMEBONUS"], L["ONTIMEBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["BOSSKILLBONUS"], L["BOSSKILLBONUS"], L["BOSSKILLBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["CORRECTINGERROR"], L["CORRECTINGERROR"], L["CORRECTINGERROR"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["DKPADJUST"], L["DKPADJUST"], L["DKPADJUST"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["OTHER"], L["OTHER"], L["OTHER"] == curReason, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function MonDKP.ConfigTab2.reasonDropDown:SetValue(newValue)
		if curReason ~= newValue then curReason = newValue else curReason = nil end

		UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown, curReason)

		if (curReason == L["ONTIMEBONUS"]) then MonDKP.ConfigTab2.addDKP:SetNumber(MonDKP_DB.DKPBonus.OnTimeBonus); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["BOSSKILLBONUS"]) then
			MonDKP.ConfigTab2.addDKP:SetNumber(MonDKP_DB.DKPBonus.BossKillBonus);
			MonDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["RAIDCOMPLETIONBONUS"]) then MonDKP.ConfigTab2.addDKP:SetNumber(MonDKP_DB.DKPBonus.CompletionBonus); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["NEWBOSSKILLBONUS"]) then
			MonDKP.ConfigTab2.addDKP:SetNumber(MonDKP_DB.DKPBonus.NewBossKillBonus);
			MonDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["UNEXCUSEDABSENCE"]) then MonDKP.ConfigTab2.addDKP:SetNumber(MonDKP_DB.DKPBonus.UnexcusedAbsence); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		else MonDKP.ConfigTab2.addDKP:SetText(""); MonDKP.ConfigTab2.BossKilledDropdown:Hide() end

		if (curReason == L["OTHER"]) then
			MonDKP.ConfigTab2.otherReason:Show();
			MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		else
			MonDKP.ConfigTab2.otherReason:Hide();
		end

		CloseDropDownMenus()
	end

	MonDKP.ConfigTab2.reasonDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["REASON"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["REASONTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["REASONTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.reasonDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.reasonHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.reasonHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.reasonDropDown, "TOPLEFT", 25, 0);
	MonDKP.ConfigTab2.reasonHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.reasonHeader:SetText(L["REASONFORADJUSTMENT"]..":")

	-- Other Reason Editbox. Hidden unless "Other" is selected in dropdown
	MonDKP.ConfigTab2.otherReason = CreateFrame("EditBox", nil, MonDKP.ConfigTab2)
	MonDKP.ConfigTab2.otherReason:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 19, 2)     
	MonDKP.ConfigTab2.otherReason:SetAutoFocus(false)
	MonDKP.ConfigTab2.otherReason:SetMultiLine(false)
	MonDKP.ConfigTab2.otherReason:SetSize(225, 24)
	MonDKP.ConfigTab2.otherReason:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	MonDKP.ConfigTab2.otherReason:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab2.otherReason:SetBackdropBorderColor(1,1,1,0.6)
	MonDKP.ConfigTab2.otherReason:SetMaxLetters(50)
	MonDKP.ConfigTab2.otherReason:SetTextColor(0.4, 0.4, 0.4, 1)
	MonDKP.ConfigTab2.otherReason:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab2.otherReason:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab2.otherReason:SetText(L["ENTEROTHERREASONHERE"])
	MonDKP.ConfigTab2.otherReason:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab2.otherReason:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() == L["ENTEROTHERREASONHERE"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	MonDKP.ConfigTab2.otherReason:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["ENTEROTHERREASONHERE"])
			self:SetTextColor(0.4, 0.4, 0.4, 1)
		end
	end)
	MonDKP.ConfigTab2.otherReason:Hide();

	-- Boss Killed Dropdown - Hidden unless "Boss Kill Bonus" or "New Boss Kill Bonus" is selected
	-- Killing a boss on the list will auto select that boss
	MonDKP.ConfigTab2.BossKilledDropdown = CreateFrame("FRAME", "MonDKPBossKilledDropdown", MonDKP.ConfigTab2, "MonolithDKPUIDropDownMenuTemplate")
	MonDKP.ConfigTab2.BossKilledDropdown:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 0, 2)
	MonDKP.ConfigTab2.BossKilledDropdown:Hide()
	UIDropDownMenu_SetWidth(MonDKP.ConfigTab2.BossKilledDropdown, 210)
	UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, L["SELECTBOSS"])

	UIDropDownMenu_Initialize(MonDKP.ConfigTab2.BossKilledDropdown, function(self, level, menuList)
		local boss = UIDropDownMenu_CreateInfo()
		boss.fontObject = "MonDKPSmallCenter"
		if (level or 1) == 1 then
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[1], core.CurrentRaidZone == core.ZoneList[1], "MC", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[2], core.CurrentRaidZone == core.ZoneList[2], "BWL", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[3], core.CurrentRaidZone == core.ZoneList[3], "AQ", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[4], core.CurrentRaidZone == core.ZoneList[4], "NAXX", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[7], core.CurrentRaidZone == core.ZoneList[7], "ONYXIA", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[5], core.CurrentRaidZone == core.ZoneList[5], "ZG", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[6], core.CurrentRaidZone == core.ZoneList[6], "AQ20", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[8], core.CurrentRaidZone == core.ZoneList[8], "WORLD", true
			UIDropDownMenu_AddButton(boss)
		else
			boss.func = self.SetValue
			for i=1, #core.BossList[menuList] do
				boss.text, boss.arg1, boss.checked = core.BossList[menuList][i], core.EncounterList[menuList][i], core.BossList[menuList][i] == core.LastKilledBoss
				UIDropDownMenu_AddButton(boss, level)
			end
		end
	end)

	function MonDKP.ConfigTab2.BossKilledDropdown:SetValue(newValue)
		local search = MonDKP:Table_Search(core.EncounterList, newValue);
		
		if MonDKP:Table_Search(core.EncounterList.MC, newValue) then
			core.CurrentRaidZone = core.ZoneList[1]
		elseif MonDKP:Table_Search(core.EncounterList.BWL, newValue) then
			core.CurrentRaidZone = core.ZoneList[2]
		elseif MonDKP:Table_Search(core.EncounterList.AQ, newValue) then
			core.CurrentRaidZone = core.ZoneList[3]
		elseif MonDKP:Table_Search(core.EncounterList.NAXX, newValue) then
			core.CurrentRaidZone = core.ZoneList[4]
		elseif MonDKP:Table_Search(core.EncounterList.ZG, newValue) then
			core.CurrentRaidZone = core.ZoneList[5]
		elseif MonDKP:Table_Search(core.EncounterList.AQ20, newValue) then
			core.CurrentRaidZone = core.ZoneList[6]
		elseif MonDKP:Table_Search(core.EncounterList.ONYXIA, newValue) then
			core.CurrentRaidZone = core.ZoneList[7]
		--elseif MonDKP:Table_Search(core.EncounterList.WORLD, newValue) then 		-- encounter IDs not known yet
			--core.CurrentRaidZone = core.ZoneList[8]
		end

		if search then
			core.LastKilledBoss = core.BossList[search[1][1]][search[1][2]]
		else
			return;
		end

		MonDKP_DB.bossargs["LastKilledBoss"] = core.LastKilledBoss;
		MonDKP_DB.bossargs["CurrentRaidZone"] = core.CurrentRaidZone;

		if curReason ~= L["BOSSKILLBONUS"] and curReason ~= L["NEWBOSSKILLBONUS"] then
			MonDKP.ConfigTab2.reasonDropDown:SetValue(L["BOSSKILLBONUS"])
		end
		UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		CloseDropDownMenus()
	end

	-- Add DKP Edit Box
	MonDKP.ConfigTab2.addDKP = CreateFrame("EditBox", nil, MonDKP.ConfigTab2)
	MonDKP.ConfigTab2.addDKP:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 20, -44)     
	MonDKP.ConfigTab2.addDKP:SetAutoFocus(false)
	MonDKP.ConfigTab2.addDKP:SetMultiLine(false)
	MonDKP.ConfigTab2.addDKP:SetSize(100, 24)
	MonDKP.ConfigTab2.addDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	MonDKP.ConfigTab2.addDKP:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab2.addDKP:SetBackdropBorderColor(1,1,1,0.6)
	MonDKP.ConfigTab2.addDKP:SetMaxLetters(10)
	MonDKP.ConfigTab2.addDKP:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab2.addDKP:SetFontObject("MonDKPNormalRight")
	MonDKP.ConfigTab2.addDKP:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab2.addDKP:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText("")
		self:ClearFocus()
	end)
	MonDKP.ConfigTab2.addDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["POINTS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["POINTSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["POINTSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.addDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.pointsHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.pointsHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.addDKP, "TOPLEFT", 3, 3);
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.pointsHeader:SetText(L["POINTS"]..":")

	-- Raid Only Checkbox
	MonDKP.ConfigTab2.RaidOnlyCheck = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.RaidOnlyCheck:SetChecked(false)
	MonDKP.ConfigTab2.RaidOnlyCheck:SetScale(0.6);
	MonDKP.ConfigTab2.RaidOnlyCheck.text:SetText("  |cff5151deShow Raid Only|r");
	MonDKP.ConfigTab2.RaidOnlyCheck.text:SetScale(1.5);
	MonDKP.ConfigTab2.RaidOnlyCheck.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.RaidOnlyCheck:SetPoint("LEFT", MonDKP.ConfigTab2.addDKP, "RIGHT", 15, 13);
	MonDKP.ConfigTab2.RaidOnlyCheck:Hide()
	

	-- Select All Checkbox
	MonDKP.ConfigTab2.selectAll = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.selectAll:SetChecked(false)
	MonDKP.ConfigTab2.selectAll:SetScale(0.6);
	MonDKP.ConfigTab2.selectAll.text:SetText("  |cff5151de"..L["SELECTALLVISIBLE"].."|r");
	MonDKP.ConfigTab2.selectAll.text:SetScale(1.5);
	MonDKP.ConfigTab2.selectAll.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.selectAll:SetPoint("LEFT", MonDKP.ConfigTab2.addDKP, "RIGHT", 15, -13);
	MonDKP.ConfigTab2.selectAll:Hide();
	

		-- Adjust DKP Button
	MonDKP.ConfigTab2.adjustButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab2.addDKP, "BOTTOMLEFT", -1, -15, L["ADJUSTDKP"]);
	MonDKP.ConfigTab2.adjustButton:SetSize(90,25)
	MonDKP.ConfigTab2.adjustButton:SetScript("OnClick", function()
		if #core.SelectedData > 0 and curReason and MonDKP.ConfigTab2.otherReason:GetText() then
			local selected = L["AREYOUSURE"].." "..MonDKP_round(MonDKP.ConfigTab2.addDKP:GetNumber(), MonDKP_DB.modes.rounding).." "..L["DKPTOFOLLOWING"]..": \n\n";

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
			StaticPopupDialogs["ADJUST_DKP"] = {
				text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					MonDKP:AdjustDKP(MonDKP.ConfigTab2.addDKP:GetNumber())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
		else
			MonDKP:AdjustDKP(MonDKP.ConfigTab2.addDKP:GetNumber());
		end
	end)
	MonDKP.ConfigTab2.adjustButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADJUSTDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.adjustButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- weekly decay Editbox
	MonDKP.ConfigTab2.decayDKP = CreateFrame("EditBox", nil, MonDKP.ConfigTab2)
	MonDKP.ConfigTab2.decayDKP:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2, "BOTTOMLEFT", 21, 70)     
	MonDKP.ConfigTab2.decayDKP:SetAutoFocus(false)
	MonDKP.ConfigTab2.decayDKP:SetMultiLine(false)
	MonDKP.ConfigTab2.decayDKP:SetSize(100, 24)
	MonDKP.ConfigTab2.decayDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	MonDKP.ConfigTab2.decayDKP:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab2.decayDKP:SetBackdropBorderColor(1,1,1,0.6)
	MonDKP.ConfigTab2.decayDKP:SetMaxLetters(4)
	MonDKP.ConfigTab2.decayDKP:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab2.decayDKP:SetFontObject("MonDKPNormalRight")
	MonDKP.ConfigTab2.decayDKP:SetTextInsets(10, 15, 5, 5)
	MonDKP.ConfigTab2.decayDKP:SetNumber(tonumber(MonDKP_DB.DKPBonus.DecayPercentage))
	MonDKP.ConfigTab2.decayDKP:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)

	MonDKP.ConfigTab2.decayDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.decayDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.decayDKPHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.decayDKPHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.decayDKPHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.decayDKP, "TOPLEFT", 3, 3);
	MonDKP.ConfigTab2.decayDKPHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.decayDKPHeader:SetText(L["WEEKLYDKPDECAY"]..":")

	MonDKP.ConfigTab2.decayDKPFooter = MonDKP.ConfigTab2.decayDKP:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.decayDKPFooter:SetFontObject("MonDKPNormalLeft");
	MonDKP.ConfigTab2.decayDKPFooter:SetPoint("LEFT", MonDKP.ConfigTab2.decayDKP, "RIGHT", -15, 0);
	MonDKP.ConfigTab2.decayDKPFooter:SetText("%")

	-- selected players only checkbox
	MonDKP.ConfigTab2.SelectedOnlyCheck = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetChecked(false)
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScale(0.6);
	MonDKP.ConfigTab2.SelectedOnlyCheck.text:SetText("  |cff5151de"..L["SELPLAYERSONLY"].."|r");
	MonDKP.ConfigTab2.SelectedOnlyCheck.text:SetScale(1.5);
	MonDKP.ConfigTab2.SelectedOnlyCheck.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetPoint("TOP", MonDKP.ConfigTab2.decayDKP, "BOTTOMLEFT", 15, -13);
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnClick", function(self)
		PlaySound(808)
	end)
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SELPLAYERSONLY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SELPLAYERSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["SELPLAYERSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- add to negative dkp checkbox
	MonDKP.ConfigTab2.AddNegative = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.AddNegative:SetChecked(MonDKP_DB.modes.AddToNegative)
	MonDKP.ConfigTab2.AddNegative:SetScale(0.6);
	MonDKP.ConfigTab2.AddNegative.text:SetText("  |cff5151de"..L["ADDNEGVALUES"].."|r");
	MonDKP.ConfigTab2.AddNegative.text:SetScale(1.5);
	MonDKP.ConfigTab2.AddNegative.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.AddNegative:SetPoint("TOP", MonDKP.ConfigTab2.SelectedOnlyCheck, "BOTTOM", 0, 0);
	MonDKP.ConfigTab2.AddNegative:SetScript("OnClick", function(self)
		MonDKP_DB.modes.AddToNegative = self:GetChecked();
		PlaySound(808)
	end)
	MonDKP.ConfigTab2.AddNegative:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDNEGVALUES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDNEGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADDNEGTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.AddNegative:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.decayButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab2.decayDKP, "TOPRIGHT", 20, 0, L["APPLYDECAY"]);
	MonDKP.ConfigTab2.decayButton:SetSize(90,25)
	MonDKP.ConfigTab2.decayButton:SetScript("OnClick", function()
		local SelectedToggle;
		local selected;

		if MonDKP.ConfigTab2.SelectedOnlyCheck:GetChecked() then SelectedToggle = "|cffff0000"..L["SELECTED"].."|r" else SelectedToggle = "|cffff0000"..L["ALL"].."|r" end
		selected = L["CONFIRMDECAY"].." "..SelectedToggle.." "..L["DKPENTRIESBY"].." "..MonDKP.ConfigTab2.decayDKP:GetNumber().."%%";

			StaticPopupDialogs["ADJUST_DKP"] = {
				text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					DecayDKP(MonDKP.ConfigTab2.decayDKP:GetNumber(), "percent", MonDKP.ConfigTab2.SelectedOnlyCheck:GetChecked())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
	end)
	MonDKP.ConfigTab2.decayButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["APPDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["APPDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.decayButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Raid Timer Container
	MonDKP.ConfigTab2.RaidTimerContainer = CreateFrame("Frame", nil, MonDKP.ConfigTab2);
	MonDKP.ConfigTab2.RaidTimerContainer:SetSize(200, 360);
	MonDKP.ConfigTab2.RaidTimerContainer:SetPoint("RIGHT", MonDKP.ConfigTab2, "RIGHT", -25, -60)
	MonDKP.ConfigTab2.RaidTimerContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2, 
    });
	MonDKP.ConfigTab2.RaidTimerContainer:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab2.RaidTimerContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)

		-- Pop out button
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut = CreateFrame("Button", nil, MonDKP.ConfigTab2, "UIMenuButtonStretchTemplate")
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetPoint("TOPRIGHT", MonDKP.ConfigTab2.RaidTimerContainer, "TOPRIGHT", -5, -5)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetHeight(22)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetWidth(18)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetNormalFontObject("MonDKPLargeCenter")
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetHighlightFontObject("MonDKPLargeCenter")
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:GetFontString():SetTextColor(0, 0.3, 0.7, 1)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScale(1.2)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameStrata("DIALOG")
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameLevel(15)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">")
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["POPOUTTIMER"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["POPOUTTIMERDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnClick", function(self)
			if self:GetText() == ">" then
				self:SetText("<");
				RaidTimerPopout_Create()
			else
				self:SetText(">");
				MonDKP.RaidTimerPopout:Hide();
			end
		end)

		-- Raid Timer Header
	    MonDKP.ConfigTab2.RaidTimerContainer.Header = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetFontObject("MonDKPLargeLeft");
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetScale(0.6)
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetPoint("TOPLEFT", MonDKP.ConfigTab2.RaidTimerContainer, "TOPLEFT", 15, -15);
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetText(L["RAIDTIMER"])

	    -- Raid Timer Output Header
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetFontObject("MonDKPNormalRight");
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetPoint("TOP", MonDKP.ConfigTab2.RaidTimerContainer, "TOP", -20, -40);
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Hide();

	    -- Raid Timer Output
	    MonDKP.ConfigTab2.RaidTimerContainer.Output = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.Output:SetFontObject("MonDKPLargeLeft");
	    MonDKP.ConfigTab2.RaidTimerContainer.Output:SetScale(0.8)
	    MonDKP.ConfigTab2.RaidTimerContainer.Output:SetPoint("LEFT", MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader, "RIGHT", 5, 0);

	    -- Bonus Awarded Header
	    MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetFontObject("MonDKPNormalRight");
	    MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetPoint("TOP", MonDKP.ConfigTab2.RaidTimerContainer, "TOP", -15, -60);
	    MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
	    MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Hide();

	    -- Bonus Awarded Output
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetFontObject("MonDKPLargeLeft");
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetScale(0.8)
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetPoint("LEFT", MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader, "RIGHT", 5, 0);

	    -- Start Raid Timer Button
	    MonDKP.ConfigTab2.RaidTimerContainer.StartTimer = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 135, L["INITRAID"]);
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetSize(90,25)
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnClick", function(self)
			if not IsInRaid() then
				StaticPopupDialogs["NO_RAID_TIMER"] = {
					text = L["NOTINRAID"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("NO_RAID_TIMER")
				return;
			end
			if not core.RaidInProgress then				
				if MonDKP_DB.DKPBonus.GiveRaidStart and self:GetText() ~= L["CONTINUERAID"] then
					StaticPopupDialogs["START_RAID_BONUS"] = {
						text = L["RAIDTIMERBONUSCONFIRM"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()						
							local setInterval = MonDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
							local setBonus = MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
							local setOnTime = tostring(MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
							local setGiveEnd = tostring(MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
							local setStandby = tostring(MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
							MonDKP.Sync:SendData("MonDKPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
							if MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
								MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDRESUME"])
							else
								MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDSTART"])
								MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
							end
							MonDKP:StartRaidTimer(false)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("START_RAID_BONUS")
				else
					local setInterval = MonDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
					local setBonus = MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
					local setOnTime = tostring(MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
					local setGiveEnd = tostring(MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
					local setStandby = tostring(MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
					MonDKP.Sync:SendData("MonDKPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
					if MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
						MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDRESUME"])
					else
						MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDSTART"])
						MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
					end
					MonDKP:StartRaidTimer(false)
				end
			else
				StaticPopupDialogs["END_RAID"] = {
					text = L["ENDCURRAIDCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDTIMERCONCLUDE"].." "..MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
						MonDKP.Sync:SendData("MonDKPRaidTime", "stop")
						MonDKP:StopRaidTimer()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("END_RAID")
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INITRAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INITRAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INITRAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Pause Raid Timer Button
	    MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab2.RaidTimerContainer, "BOTTOMRIGHT", -10, 135, L["PAUSERAID"]);
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetSize(90,25)
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnClick", function(self)
			if core.RaidInProgress then
				local setInterval = MonDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
				local setBonus = MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
				local setOnTime = tostring(MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
				local setGiveEnd = tostring(MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
				local setStandby = tostring(MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());

				MonDKP.Sync:SendData("MonDKPRaidTime", "start,true "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
				MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDPAUSE"].." "..MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
				MonDKP:StartRaidTimer(true)
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["PAUSERAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["PAUSERAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["PAUSERAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Award Interval Editbox
		if not MonDKP_DB.modes.increment then MonDKP_DB.modes.increment = 60 end
		MonDKP.ConfigTab2.RaidTimerContainer.interval = CreateFrame("EditBox", nil, MonDKP.ConfigTab2.RaidTimerContainer)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 35, 225)     
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetAutoFocus(false)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetMultiLine(false)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetSize(60, 24)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdropColor(0,0,0,0.9)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdropBorderColor(1,1,1,0.6)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetMaxLetters(5)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetTextColor(1, 1, 1, 1)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetTextInsets(10, 15, 5, 5)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(MonDKP_DB.modes.increment))
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				MonDKP_DB.modes.increment = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
					text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFocus()
			MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:HighlightText()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDINTERVAL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetFontObject("MonDKPTinyRight");
	    MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer.interval, "TOPLEFT", 0, 2);
	    MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetText(L["INTERVAL"]..":")

	    -- Award Value Editbox
	    if not MonDKP_DB.DKPBonus.IntervalBonus then MonDKP_DB.DKPBonus.IntervalBonus = 15 end
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue = CreateFrame("EditBox", nil, MonDKP.ConfigTab2.RaidTimerContainer)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetPoint("LEFT", MonDKP.ConfigTab2.RaidTimerContainer.interval, "RIGHT", 10, 0)     
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetAutoFocus(false)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMultiLine(false)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetSize(60, 24)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropColor(0,0,0,0.9)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropBorderColor(1,1,1,0.6)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMaxLetters(5)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextColor(1, 1, 1, 1)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextInsets(10, 15, 5, 5)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(MonDKP_DB.DKPBonus.IntervalBonus))
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				MonDKP_DB.DKPBonus.IntervalBonus = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
					text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			MonDKP.ConfigTab2.RaidTimerContainer.interval:SetFocus()
			MonDKP.ConfigTab2.RaidTimerContainer.interval:HighlightText()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetFontObject("MonDKPTinyRight");
	    MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue, "TOPLEFT", 0, 2);
	    MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetText(L["BONUS"]..":")
    	
    	-- Give On Time Bonus Checkbox
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(MonDKP_DB.DKPBonus.GiveRaidStart)
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScale(0.6);
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetText("  |cff5151de"..L["GIVEONTIMEBONUS"].."|r");
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetScale(1.5);
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetFontObject("MonDKPSmallLeft")
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetPoint("TOPLEFT", MonDKP.ConfigTab2.RaidTimerContainer.interval, "BOTTOMLEFT", 0, -10);
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				MonDKP_DB.DKPBonus.GiveRaidStart = true;
				PlaySound(808)
			else
				MonDKP_DB.DKPBonus.GiveRaidStart = false;
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEONTIMEBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEONTIMETTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Give Raid End Bonus Checkbox
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(MonDKP_DB.DKPBonus.GiveRaidEnd)
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScale(0.6);
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetText("  |cff5151de"..L["GIVEENDBONUS"].."|r");
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetScale(1.5);
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetFontObject("MonDKPSmallLeft")
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetPoint("TOP", MonDKP.ConfigTab2.RaidTimerContainer.StartBonus, "BOTTOM", 0, 2);
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				MonDKP_DB.DKPBonus.GiveRaidEnd = true;
				PlaySound(808)
			else
				MonDKP_DB.DKPBonus.GiveRaidEnd = false;
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEENDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEENDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Include Standby Checkbox
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(MonDKP_DB.DKPBonus.IncStandby)
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScale(0.6);
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetScale(1.5);
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetFontObject("MonDKPSmallLeft")
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetPoint("TOP", MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus, "BOTTOM", 0, 2);
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnClick", function(self)
			if self:GetChecked() then
				MonDKP_DB.DKPBonus.IncStandby = true;
				PlaySound(808)
			else
				MonDKP_DB.DKPBonus.IncStandby = false;
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INCLUDESTANDBY"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetFontObject("MonDKPTinyLeft");
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetWidth(180)
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 10);
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetText("|CFFFF0000"..L["TIMERWARNING"].."|r")
	    RaidTimerPopout_Create()
end