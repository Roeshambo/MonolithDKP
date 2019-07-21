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
					MonDKP:DKPTable_Set(core.SelectedData[i]["player"], "dkp", MonDKP.ConfigTab2.addDKP:GetNumber())
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
			MonDKP:DKPTable_Set(core.SelectedData[1]["player"], "dkp", MonDKP.ConfigTab2.addDKP:GetNumber())
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
		if tonumber(amount) < 100 then
			amount = tonumber("0."..amount);
		elseif amount == 100 then
			amount = 1
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
	MonDKP.ConfigTab2.description:SetText("Select individual players from the left (Shift+Click for multiple players) or click \"Select All Visible\" below and enter amount to adjust.\n\n\"Select All Visible\" will only select entries visible. Can be narrowed down via the Filters Tab.\n\n (ex. limiting scope to \"In Party/Raid\" and checking \"Select All Visible\" will only apply changes to all in party/raid)"); 

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

	MonDKP.ConfigTab2.reasonHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.reasonHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.reasonHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.reasonDropDown, "TOPLEFT", 25, 0);
	MonDKP.ConfigTab2.reasonHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.reasonHeader:SetText("Reason for Adjustment:")

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

	-- Boss Killed Dropdown
	MonDKP.ConfigTab2.BossKilledDropdown = CreateFrame("FRAME", "MonDKPBossKilledDropdown", MonDKP.ConfigTab2, "MonolithDKPUIDropDownMenuTemplate")
	MonDKP.ConfigTab2.BossKilledDropdown:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 0, 2)
	MonDKP.ConfigTab2.BossKilledDropdown:Hide()
	UIDropDownMenu_SetWidth(MonDKP.ConfigTab2.BossKilledDropdown, 250)
	UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, "Select Boss")

	UIDropDownMenu_Initialize(MonDKP.ConfigTab2.BossKilledDropdown, function(self, level, menuList)
		local boss = UIDropDownMenu_CreateInfo()
		boss.fontObject = "MonDKPSmallCenter"
		if (level or 1) == 1 then	  
			boss.text, boss.checked, boss.menuList, boss.hasArrow = "Molten Core", core.CurrentRaidZone == "The Molten Core", "MC", true
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
			core.CurrentRaidZone = "The Molten Core"
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

	MonDKP.ConfigTab2.pointsHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.pointsHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.addDKP, "TOPLEFT", 3, 3);
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.pointsHeader:SetText("Points: (Use a negative number to deduct DKP)")

	-- Select All Checkbox
	MonDKP.ConfigTab2.selectAll = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.selectAll:SetChecked(false)
	MonDKP.ConfigTab2.selectAll:SetScale(0.6);
	MonDKP.ConfigTab2.selectAll.text:SetText("  Select All Visible");
	MonDKP.ConfigTab2.selectAll.text:SetScale(1.5);
	MonDKP.ConfigTab2.selectAll.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.selectAll:SetPoint("LEFT", MonDKP.ConfigTab2.addDKP, "RIGHT", 15, 0);
	MonDKP.ConfigTab2.selectAll:SetScript("OnClick", function(self)
		if (MonDKP.ConfigTab2.selectAll:GetChecked() == true) then
			core.SelectedRows = core.WorkingTable;
			core.SelectedData = core.WorkingTable;
		else
			core.SelectedRows = {}
			core.SelectedData = {}
		end
		MonDKP:FilterDKPTable(core.currentSort, "reset");
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
    GameTooltip:AddLine("Amount of DKP you wish to reduce all DKP entries by as a weekly decay.", 1.0, 1.0, 1.0, true);
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
end