local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

local curReason;

local function AdjustDKP()
	local adjustReason = curReason;
	local c = MonDKP:GetCColors();
	local date = time()

	if (curReason == "Other") then adjustReason = "Other - "..MonDKP.ConfigTab2.otherReason:GetText(); end
	if curReason == "Boss Kill Bonus" then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss; end
	if curReason == "New Boss Kill Bonus" then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss.." (First Kill)" end
	if (#core.SelectedData > 1 and adjustReason and adjustReason ~= "Other - Enter Other Reason Here") then
		local tempString = "";       -- stores list of changes
		local dkpHistoryString = ""   -- stores list for MonDKP_DKPHistory
		for i=1, #core.SelectedData do
			if MonDKP:Table_Search(core.WorkingTable, core.SelectedData[i]["player"]) then
					if i < #core.SelectedData then
						tempString = tempString.."|cff"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r, ";
					else
						tempString = tempString.."|cff"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r";
					end
					dkpHistoryString = dkpHistoryString..core.SelectedData[i]["player"]..","
					MonDKP:DKPTable_Set(core.SelectedData[i]["player"], "dkp", MonDKP.ConfigTab2.addDKP:GetNumber(), false)
			end
		end
		tinsert(MonDKP_DKPHistory, {players=dkpHistoryString, dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=date})
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)         -- broadcast updated DKP table
		MonDKP:DKPHistory_Reset()
		MonDKP:DKPHistory_Update()
		local temp_table = {}
		tinsert(temp_table, {players=dkpHistoryString, dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=date})
		MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
		table.wipe(temp_table)
		if (MonDKP.ConfigTab1.checkBtn[10]:GetChecked() and MonDKP.ConfigTab2.selectAll:GetChecked()) then
			MonDKP.Sync:SendData("MonDKPBroadcast", "Raid DKP Adjusted by "..MonDKP.ConfigTab2.addDKP:GetNumber().." for reason: "..adjustReason)
		else
			MonDKP.Sync:SendData("MonDKPBroadcast", "DKP Adjusted by "..MonDKP.ConfigTab2.addDKP:GetNumber().." for the following players: ")
			MonDKP.Sync:SendData("MonDKPBroadcast", tempString)
			MonDKP.Sync:SendData("MonDKPBroadcast", "Reason: "..adjustReason)
		end
	elseif (#core.SelectedData == 1 and adjustReason and adjustReason ~= "Other - Enter Other Reason Here") then
		if core.SelectedData[1]["player"] and MonDKP:Table_Search(core.WorkingTable, core.SelectedData[1]["player"]) then
			MonDKP:DKPTable_Set(core.SelectedData[1]["player"], "dkp", MonDKP.ConfigTab2.addDKP:GetNumber(), false)
			MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable) -- broadcast updated DKP table
			MonDKP.Sync:SendData("MonDKPBroadcast", "|cff"..c[core.SelectedData[1]["class"]].hex..core.SelectedData[1]["player"].."s|r|cffff6060 DKP adjusted by "..MonDKP.ConfigTab2.addDKP:GetNumber().." for reason: "..adjustReason.."|r")
			tinsert(MonDKP_DKPHistory, {players=core.SelectedData[1]["player"], dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=date})
			MonDKP:DKPHistory_Reset()
			MonDKP:DKPHistory_Update()
			local temp_table = {}
			tinsert(temp_table, {players=core.SelectedData[1]["player"], dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=date})
			MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
			table.wipe(temp_table)
		end
	else
		local validation;
		if (#core.SelectedData == 0 and not adjustReason) then
			validation = "Player or Reason"
		elseif #core.SelectedData == 0 then
			validation = "Player"
		elseif not adjustReason or MonDKP.ConfigTab2.otherReason:GetText() == "" or MonDKP.ConfigTab2.otherReason:GetText() == "Enter Other Reason Here" then
			validation = "Other - Reason"
		end

		StaticPopupDialogs["VALIDATION_PROMPT"] = {
			text = "No "..validation.." Selected",
			button1 = "OK",
			timeout = 5,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("VALIDATION_PROMPT")
	end
end

local function DecayDKP(amount, deductionType)
	local playerString = "";

	for key, value in pairs(MonDKP_DKPTable) do
		local dkp = value["dkp"]
		local player = value["player"]
		local amount = amount;
		amount = tonumber(amount) / 100		-- converts percentage to a decimal
		if amount < 0 then
			amount = amount * -1			-- flips value to positive if officer accidently used negative number in editbox
		end
		local deducted;

		if dkp > 0 then
			if deductionType == "percent" then
				deducted = dkp * amount
				dkp = round(dkp - deducted, 0);
				value["dkp"] = tonumber(round(dkp, 0));
			elseif deductionType == "points" then
				-- do stuff for flat point deductions
			end
		end
		playerString = playerString..player..",";
	end

	if tonumber(amount) < 0 then amount = amount * -1 end		-- flips value to positive if officer accidently used a negative number

	tinsert(MonDKP_DKPHistory, {players=playerString, dkp="-"..amount.."%", reason="Weekly Decay", date=time()})
	MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)         -- broadcast updated DKP table
	MonDKP:DKPHistory_Reset()
	MonDKP:DKPHistory_Update()
	local temp_table = {}
	tinsert(temp_table, {players=playerString, dkp="-"..amount.."%", reason="Weekly Decay", date=time()})
	MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
	table.wipe(temp_table)
	DKPTable_Update()
end

function MonDKP:AdjustDKPTab_Create()
	MonDKP.ConfigTab2.header = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.header:SetPoint("TOPLEFT", MonDKP.ConfigTab2, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab2.header:SetFontObject("MonDKPLargeCenter")
	MonDKP.ConfigTab2.header:SetText("Adjust DKP");
	MonDKP.ConfigTab2.header:SetScale(1.2)

	MonDKP.ConfigTab2.description = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.description:SetPoint("TOPLEFT", MonDKP.ConfigTab2.header, "BOTTOMLEFT", 7, -10);
	MonDKP.ConfigTab2.description:SetWidth(400)
	MonDKP.ConfigTab2.description:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab2.description:SetText("Select individual players from the left (Shift+Click for multiple players) or click \"Select All Visible\" below and enter amount to adjust.\n\nScope can be adjusted with \"Show Raid Only\" below or on the \"Filters\" tab."); 

	-- Reason DROPDOWN box 
	-- Create the dropdown, and configure its appearance
	MonDKP.ConfigTab2.reasonDropDown = CreateFrame("FRAME", "MonDKPConfigReasonDropDown", MonDKP.ConfigTab2, "MonolithDKPUIDropDownMenuTemplate")
	MonDKP.ConfigTab2.reasonDropDown:SetPoint("TOPLEFT", MonDKP.ConfigTab2.description, "BOTTOMLEFT", -23, -60)
	UIDropDownMenu_SetWidth(MonDKP.ConfigTab2.reasonDropDown, 150)
	UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown, "Select Reason")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(MonDKP.ConfigTab2.reasonDropDown, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "MonDKPSmallCenter"
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "On Time Bonus", "On Time Bonus", "On Time Bonus" == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "Boss Kill Bonus", "Boss Kill Bonus", "Boss Kill Bonus" == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "Raid Completion Bonus", "Raid Completion Bonus", "Raid Completion Bonus" == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "New Boss Kill Bonus", "New Boss Kill Bonus", "New Boss Kill Bonus" == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "Correcting Error", "Correcting Error", "Correcting Error" == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "DKP Adjust", "DKP Adjust", "DKP Adjust" == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "Unexcused Absence", "Unexcused Absence", "Unexcused Absence" == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = "Other", "Other", "Other" == curReason, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function MonDKP.ConfigTab2.reasonDropDown:SetValue(newValue)
		if curReason ~= newValue then curReason = newValue else curReason = nil end

		local DKPSettings = MonDKP:GetDKPSettings()
		UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown, curReason)

		if (curReason == "On Time Bonus") then MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["OnTimeBonus"])); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == "Boss Kill Bonus") then
			MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["BossKillBonus"]));
			MonDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == "Raid Completion Bonus") then MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["CompletionBonus"])); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == "New Boss Kill Bonus") then
			MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["NewBossKillBonus"]));
			MonDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == "Unexcused Absence") then MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["UnexcusedAbsence"])); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		else MonDKP.ConfigTab2.addDKP:SetText(""); MonDKP.ConfigTab2.BossKilledDropdown:Hide() end

		if (curReason == "Other") then
			MonDKP.ConfigTab2.otherReason:Show();
			MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		else
			MonDKP.ConfigTab2.otherReason:Hide();
		end

		CloseDropDownMenus()
	end

	MonDKP.ConfigTab2.reasonDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Reason", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Select reason for DKP adjustment. If \"Boss Kill Bonus\" or \"New Boss Kill Bonus\" is selected, an additional dropdown will be created to select the zone and boss. \"Other\" will create a textbox for you to enter a custom reason.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("When a boss is killed, the appropriate zone and boss will be auto-selected for you.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.reasonDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.reasonHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.reasonHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.reasonHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.reasonDropDown, "TOPLEFT", 25, 0);
	MonDKP.ConfigTab2.reasonHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.reasonHeader:SetText("Reason for Adjustment:")

	-- Other Reason Editbox. Hidden unless "Other" is selected in dropdown
	MonDKP.ConfigTab2.otherReason = CreateFrame("EditBox", nil, MonDKP.ConfigTab2)
	MonDKP.ConfigTab2.otherReason:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 19, 2)     
	MonDKP.ConfigTab2.otherReason:SetAutoFocus(false)
	MonDKP.ConfigTab2.otherReason:SetMultiLine(false)
	MonDKP.ConfigTab2.otherReason:SetSize(300, 24)
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
	MonDKP.ConfigTab2.otherReason:SetText("Enter Other Reason Here")
	MonDKP.ConfigTab2.otherReason:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab2.otherReason:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() == "Enter Other Reason Here") then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	MonDKP.ConfigTab2.otherReason:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText("Enter Other Reason Here")
			self:SetTextColor(0.4, 0.4, 0.4, 1)
		end
	end)
	MonDKP.ConfigTab2.otherReason:Hide();

	-- Boss Killed Dropdown - Hidden unless "Boss Kill Bonus" or "New Boss Kill Bonus" is selected
	-- Killing a boss on the list will auto select that boss
	MonDKP.ConfigTab2.BossKilledDropdown = CreateFrame("FRAME", "MonDKPBossKilledDropdown", MonDKP.ConfigTab2, "MonolithDKPUIDropDownMenuTemplate")
	MonDKP.ConfigTab2.BossKilledDropdown:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 0, 2)
	MonDKP.ConfigTab2.BossKilledDropdown:Hide()
	UIDropDownMenu_SetWidth(MonDKP.ConfigTab2.BossKilledDropdown, 250)
	UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, "Select Boss")

	UIDropDownMenu_Initialize(MonDKP.ConfigTab2.BossKilledDropdown, function(self, level, menuList)
		local boss = UIDropDownMenu_CreateInfo()
		boss.fontObject = "MonDKPSmallCenter"
		if (level or 1) == 1 then	  
			boss.text, boss.checked, boss.menuList, boss.hasArrow = "Molten Core", core.CurrentRaidZone == "Molten Core", "MC", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = "Blackwing Lair", core.CurrentRaidZone == "Blackwing Lair", "BWL", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = "Temple of Ahn'Qiraj", core.CurrentRaidZone == "Temple of Ahn'Qiraj", "AQ", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = "Naxxramas", core.CurrentRaidZone == "Naxxramas", "NAXX", true
			UIDropDownMenu_AddButton(boss)
		else
			boss.func = self.SetValue
			for i=1, #core.BossList[menuList] do
				boss.text, boss.arg1, boss.checked = core.BossList[menuList][i], core.BossList[menuList][i], core.BossList[menuList][i] == core.LastKilledBoss
				UIDropDownMenu_AddButton(boss, level)
			end
		end
	end)

	function MonDKP.ConfigTab2.BossKilledDropdown:SetValue(newValue)
		local search = MonDKP:TableStrFind(core.BossList, newValue);
		
		if MonDKP:TableStrFind(core.BossList.MC, newValue) then
			core.CurrentRaidZone = "Molten Core"
		elseif MonDKP:TableStrFind(core.BossList.BWL, newValue) then
			core.CurrentRaidZone = "Blackwing Lair"
		elseif MonDKP:TableStrFind(core.BossList.AQ, newValue) then
			core.CurrentRaidZone = "Temple of Ahn'Qiraj"
		elseif MonDKP:TableStrFind(core.BossList.NAXX, newValue) then
			core.CurrentRaidZone = "Naxxramas"
		end

		if search then
			core.LastKilledBoss = core.BossList[search[1][1]][search[1][2]]
		else
			return;
		end

		MonDKP_DB.bossargs["LastKilledBoss"] = core.LastKilledBoss;
		MonDKP_DB.bossargs["CurrentRaidZone"] = core.CurrentRaidZone;

		if curReason ~= "Boss Kill Bonus" and curReason ~= "New Boss Kill Bonus" then
			MonDKP.ConfigTab2.reasonDropDown:SetValue("Boss Kill Bonus")
		end
		UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		CloseDropDownMenus()
	end

	-- Add DKP Edit Box
	MonDKP.ConfigTab2.addDKP = CreateFrame("EditBox", nil, MonDKP.ConfigTab2)
	MonDKP.ConfigTab2.addDKP:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 20, -45)     
	MonDKP.ConfigTab2.addDKP:SetAutoFocus(false)
	MonDKP.ConfigTab2.addDKP:SetMultiLine(false)
	MonDKP.ConfigTab2.addDKP:SetSize(100, 24)
	MonDKP.ConfigTab2.addDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 1, 
	});
	MonDKP.ConfigTab2.addDKP:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab2.addDKP:SetBackdropBorderColor(1,1,1,0.6)
	MonDKP.ConfigTab2.addDKP:SetMaxLetters(4)
	MonDKP.ConfigTab2.addDKP:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab2.addDKP:SetFontObject("MonDKPNormalRight")
	MonDKP.ConfigTab2.addDKP:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab2.addDKP:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText("")
		self:ClearFocus()
	end)
	MonDKP.ConfigTab2.addDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Points", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Enter amount of DKP to be distributed to selected players on the DKP table. Default values can be changed in the \"Options\" tab below.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Use a negative number to remove DKP from selected players.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.addDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.pointsHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.pointsHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.addDKP, "TOPLEFT", 3, 3);
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.pointsHeader:SetText("Points:")

	-- Raid Only Checkbox
	MonDKP.ConfigTab2.RaidOnlyCheck = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.RaidOnlyCheck:SetChecked(false)
	MonDKP.ConfigTab2.RaidOnlyCheck:SetScale(0.6);
	MonDKP.ConfigTab2.RaidOnlyCheck.text:SetText("  |cff5151deShow Raid Only|r");
	MonDKP.ConfigTab2.RaidOnlyCheck.text:SetScale(1.5);
	MonDKP.ConfigTab2.RaidOnlyCheck.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.RaidOnlyCheck:SetPoint("LEFT", MonDKP.ConfigTab2.addDKP, "RIGHT", 15, 13);
	MonDKP.ConfigTab2.RaidOnlyCheck:SetScript("OnClick", function()
		MonDKP.ConfigTab1.checkBtn[10]:SetChecked(not MonDKP.ConfigTab1.checkBtn[10]:GetChecked());		-- utilizes Filters tab Raid Only filter without rewriting functions or events
		MonDKPSetFilterChecks(MonDKP.ConfigTab1.checkBtn[10]);

	end)
	MonDKP.ConfigTab2.RaidOnlyCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Show Raid Only", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Filters DKP table to only show players in your raid party. Use with \"Select All Visible\" below to apply DKP bonuses to only those currently present.", 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.RaidOnlyCheck:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Select All Checkbox
	MonDKP.ConfigTab2.selectAll = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.selectAll:SetChecked(false)
	MonDKP.ConfigTab2.selectAll:SetScale(0.6);
	MonDKP.ConfigTab2.selectAll.text:SetText("  |cff5151deSelect All Visible|r");
	MonDKP.ConfigTab2.selectAll.text:SetScale(1.5);
	MonDKP.ConfigTab2.selectAll.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.selectAll:SetPoint("LEFT", MonDKP.ConfigTab2.addDKP, "RIGHT", 15, -13);
	MonDKP.ConfigTab2.selectAll:SetScript("OnClick", function(self)
		if (MonDKP.ConfigTab2.selectAll:GetChecked() == true) then
			core.SelectedRows = core.WorkingTable;
			core.SelectedData = core.WorkingTable;
			PlaySound(808)
			MonDKPSelectionCount_Update()
		else
			core.SelectedRows = {}
			core.SelectedData = {}
			PlaySound(868)
			MonDKPSelectionCount_Update()
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset");
	end)
	MonDKP.ConfigTab2.selectAll:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Select All Visible", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Selects all players visible in the current scope of the DKP table. This scope can be limited on the \"Filters\" tab.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Filters are automatically applied to selection. Selecting all and then applying filters to the list will limit the scope recursively.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.selectAll:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

		-- Adjust DKP Button
	MonDKP.ConfigTab2.adjustButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab2.addDKP, "BOTTOMLEFT", -1, -15, "Adjust DKP");
	MonDKP.ConfigTab2.adjustButton:SetSize(90,25)
	MonDKP.ConfigTab2.adjustButton:SetScript("OnClick", function()
		if #core.SelectedData > 0 and curReason and MonDKP.ConfigTab2.otherReason:GetText() then
			local selected = "Are you sure you'd like to give "..round(MonDKP.ConfigTab2.addDKP:GetNumber(), 0).." DKP to the following players: \n\n";

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
				button1 = "Yes",
				button2 = "No",
				OnAccept = function()
					AdjustDKP()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
		else
			AdjustDKP();
		end
	end)
	MonDKP.ConfigTab2.adjustButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Adjust DKP", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Apply above entry to all selected players in the DKP table.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("This entry will be broadcasted to all online players in your guild.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.adjustButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- weekly decay
	MonDKP.ConfigTab2.decayDKP = CreateFrame("EditBox", nil, MonDKP.ConfigTab2)
	MonDKP.ConfigTab2.decayDKP:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2, "BOTTOMLEFT", 20, 35)     
	MonDKP.ConfigTab2.decayDKP:SetAutoFocus(false)
	MonDKP.ConfigTab2.decayDKP:SetMultiLine(false)
	MonDKP.ConfigTab2.decayDKP:SetSize(100, 24)
	MonDKP.ConfigTab2.decayDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 1, 
	});
	MonDKP.ConfigTab2.decayDKP:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab2.decayDKP:SetBackdropBorderColor(1,1,1,0.6)
	MonDKP.ConfigTab2.decayDKP:SetMaxLetters(4)
	MonDKP.ConfigTab2.decayDKP:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab2.decayDKP:SetFontObject("MonDKPNormalRight")
	MonDKP.ConfigTab2.decayDKP:SetTextInsets(10, 15, 5, 5)
	MonDKP.ConfigTab2.decayDKP:SetNumber(tonumber(core.settings.DKPBonus.DecayPercentage))
	MonDKP.ConfigTab2.decayDKP:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)

	MonDKP.ConfigTab2.decayDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Weekly DKP Decay", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Amount of DKP you wish to reduce all DKP entries by as a weekly decay. This should be a positive number and no selections on the DKP table must be made.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Warning: Can not be undone.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.decayDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.decayDKPHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.decayDKPHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.decayDKPHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.decayDKP, "TOPLEFT", 3, 3);
	MonDKP.ConfigTab2.decayDKPHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.decayDKPHeader:SetText("Weekly DKP Decay:")

	MonDKP.ConfigTab2.decayDKPFooter = MonDKP.ConfigTab2.decayDKP:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.decayDKPFooter:SetFontObject("MonDKPNormalLeft");
	MonDKP.ConfigTab2.decayDKPFooter:SetPoint("LEFT", MonDKP.ConfigTab2.decayDKP, "RIGHT", -15, 0);
	MonDKP.ConfigTab2.decayDKPFooter:SetText("%")

	MonDKP.ConfigTab2.decayButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab2.decayDKP, "TOPRIGHT", 20, 0, "Apply Decay");
	MonDKP.ConfigTab2.decayButton:SetSize(90,25)
	MonDKP.ConfigTab2.decayButton:SetScript("OnClick", function()
		local selected = "Are you sure you'd like to decay all DKP entries by "..MonDKP.ConfigTab2.decayDKP:GetNumber().."%%";

			StaticPopupDialogs["ADJUST_DKP"] = {
				text = selected,
				button1 = "Yes",
				button2 = "No",
				OnAccept = function()
					DecayDKP(MonDKP.ConfigTab2.decayDKP:GetNumber(), "percent")
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
		GameTooltip:SetText("Weekly DKP Decay", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Amount of DKP you wish to reduce all DKP entries by as a weekly decay. This should be a positive number and no selections on the DKP table must be made.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Warning: Can not be undone.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.decayButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end