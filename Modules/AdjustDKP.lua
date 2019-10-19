local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local curReason;

local function AdjustDKP()
	if core.CurrentlySyncing then
		StaticPopupDialogs["CURRENTLY_SYNC"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["CurrentlySyncing"],
			button1 = L["OK"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CURRENTLY_SYNC")
		return;
	end
	local adjustReason = curReason;
	local c = MonDKP:GetCColors();
	local curTime = time()

	if (curReason == L["Other"]) then adjustReason = L["Other"].." - "..MonDKP.ConfigTab2.otherReason:GetText(); end
	if curReason == L["BossKillBonus"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss; end
	if curReason == L["NewBossKillBonus"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss.." ("..L["FirstKill"]..")" end
	if (#core.SelectedData > 0 and adjustReason and adjustReason ~= L["Other"].." - "..L["EnterOtherReasonHere"]) then
		MonDKP:SeedVerify_Update()
		if core.UpToDate == false and core.IsOfficer == true then
			StaticPopupDialogs["CONFIRM_ADJUST1"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["OutdateModifyWarn"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
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
					tinsert(MonDKP_DKPHistory, {players=dkpHistoryString, dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=curTime})
					MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)         -- broadcast updated DKP table
					if MonDKP.ConfigTab6.history then
						MonDKP:DKPHistory_Reset()
					end
					MonDKP:DKPHistory_Update()
					local temp_table = {}
					tinsert(temp_table, {seed = MonDKP_DKPHistory.seed, {players=dkpHistoryString, dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=curTime}})
					MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
					table.wipe(temp_table)
					if (MonDKP.ConfigTab1.checkBtn[10]:GetChecked() and MonDKP.ConfigTab2.selectAll:GetChecked()) then
						MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidDKPAdjustBy"].." "..MonDKP.ConfigTab2.addDKP:GetNumber().." "..L["ForReason"]..": "..adjustReason)
					else
						MonDKP.Sync:SendData("MonDKPBroadcast", L["DKPAdjustBy"].." "..MonDKP.ConfigTab2.addDKP:GetNumber().." "..L["ForPlayers"]..": ")
						MonDKP.Sync:SendData("MonDKPBroadcast", tempString)
						MonDKP.Sync:SendData("MonDKPBroadcast", L["Reason"]..": "..adjustReason)
					end
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_ADJUST1")
		else
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
			tinsert(MonDKP_DKPHistory, {players=dkpHistoryString, dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=curTime})
			MonDKP:UpdateSeeds()
			MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)         -- broadcast updated DKP table
			if MonDKP.ConfigTab6.history then
				MonDKP:DKPHistory_Reset()
			end
			MonDKP:DKPHistory_Update()
			local temp_table = {}
			tinsert(temp_table, {seed = MonDKP_DKPHistory.seed, {players=dkpHistoryString, dkp=MonDKP.ConfigTab2.addDKP:GetNumber(), reason=adjustReason, date=curTime}})
			MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
			table.wipe(temp_table)
			if (MonDKP.ConfigTab1.checkBtn[10]:GetChecked() and MonDKP.ConfigTab2.selectAll:GetChecked()) then
				MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidDKPAdjustBy"].." "..MonDKP.ConfigTab2.addDKP:GetNumber().." "..L["ForReason"]..": "..adjustReason)
			else
				MonDKP.Sync:SendData("MonDKPBroadcast", L["DKPAdjustBy"].." "..MonDKP.ConfigTab2.addDKP:GetNumber().." "..L["ForPlayers"]..": ")
				MonDKP.Sync:SendData("MonDKPBroadcast", tempString)
				MonDKP.Sync:SendData("MonDKPBroadcast", L["Reason"]..": "..adjustReason)
			end
		end
		if core.CurView == "limited" then
			local tempTable = {}

			for i=1, #core.WorkingTable do
				local search = MonDKP:Table_Search(MonDKP_DKPTable, core.WorkingTable[i].player)

				if search then
					table.insert(tempTable, MonDKP_DKPTable[search[1][1]])
				end
			end
			core.WorkingTable = CopyTable(tempTable)
			table.wipe(tempTable)
			DKPTable_Update()
		end
		--[[MonDKP.ConfigTab2.RaidOnlyCheck:SetChecked(false)
		MonDKP.ConfigTab2.selectAll:SetChecked(false)
		core.CurView = "all"--]]
	else
		local validation;
		if (#core.SelectedData == 0 and not adjustReason) then
			validation = L["PlayerReasonValidate"]
		elseif #core.SelectedData == 0 then
			validation = L["PlayerValidate"]
		elseif not adjustReason or MonDKP.ConfigTab2.otherReason:GetText() == "" or MonDKP.ConfigTab2.otherReason:GetText() == L["EnterOtherReasonHere"] then
			validation = L["OtherReasonValidate"]
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
	local curTime = time()

	MonDKP:SeedVerify_Update()
	if core.UpToDate == false and core.IsOfficer == true then
		StaticPopupDialogs["CONFIRM_DECAY"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["OutdateModifyWarn"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				for key, value in ipairs(MonDKP_DKPTable) do
					local dkp = value["dkp"]
					local player = value["player"]
					local amount = amount;
					amount = tonumber(amount) / 100		-- converts percentage to a decimal
					if amount < 0 then
						amount = amount * -1			-- flips value to positive if officer accidently used negative number in editbox
					end
					local deducted;		-- stores dkp * amount percentage as a decimal (20% = 0.2)

					if (GetSelections and MonDKP:Table_Search(core.SelectedData, player)) or GetSelections == false then
						if dkp > 0 then
							if deductionType == "percent" then
								deducted = dkp * amount
								dkp = MonDKP_round(dkp - deducted, MonDKP_DB.modes.rounding);
								value["dkp"] = MonDKP_round(tonumber(dkp), MonDKP_DB.modes.rounding);
							elseif deductionType == "points" then
								-- do stuff for flat point deductions
							end
						elseif dkp < 0 and MonDKP.ConfigTab2.AddNegative:GetChecked() then
							if deductionType == "percent" then
								deducted = dkp * amount
								dkp = MonDKP_round(deducted - dkp, MonDKP_DB.modes.rounding) * -1
								value["dkp"] = MonDKP_round(tonumber(dkp), MonDKP_DB.modes.rounding)
							elseif deductionType == "points" then
								-- do stuff for flat point deductions
							end	
						end
						playerString = playerString..player..",";
					end
				end

				if tonumber(amount) < 0 then amount = amount * -1 end		-- flips value to positive if officer accidently used a negative number

				tinsert(MonDKP_DKPHistory, {players=playerString, dkp="-"..amount.."%", reason=L["WeeklyDecay"], date=curTime})
				MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)         -- broadcast updated DKP table
				if MonDKP.ConfigTab6.history then
					MonDKP:DKPHistory_Reset()
				end
				MonDKP:DKPHistory_Update()
				local temp_table = {}
				tinsert(temp_table, {seed = MonDKP_DKPHistory.seed, {players=playerString, dkp="-"..amount.."%", reason=L["WeeklyDecay"], date=curTime}})
				MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
				table.wipe(temp_table)
				DKPTable_Update()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CONFIRM_DECAY")
	else
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
						dkp = MonDKP_round(dkp - deducted, MonDKP_DB.modes.rounding);
						value["dkp"] = MonDKP_round(tonumber(dkp), MonDKP_DB.modes.rounding);
					elseif deductionType == "points" then
						-- do stuff for flat point deductions
					end
				elseif dkp < 0 and MonDKP.ConfigTab2.AddNegative:GetChecked() then
					if deductionType == "percent" then
						deducted = dkp * amount
						dkp = MonDKP_round(deducted - dkp, MonDKP_DB.modes.rounding) * -1
						value["dkp"] = MonDKP_round(tonumber(dkp), MonDKP_DB.modes.rounding)
					elseif deductionType == "points" then
						-- do stuff for flat point deductions
					end	
				end
				playerString = playerString..player..",";
			end
		end

		if tonumber(amount) < 0 then amount = amount * -1 end		-- flips value to positive if officer accidently used a negative number

		tinsert(MonDKP_DKPHistory, {players=playerString, dkp="-"..amount.."%", reason=L["WeeklyDecay"], date=curTime})
		MonDKP:UpdateSeeds()
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)         -- broadcast updated DKP table
		if MonDKP.ConfigTab6.history then
			MonDKP:DKPHistory_Reset()
		end
		MonDKP:DKPHistory_Update()
		local temp_table = {}
		tinsert(temp_table, {seed = MonDKP_DKPHistory.seed, {players=playerString, dkp="-"..amount.."%", reason=L["WeeklyDecay"], date=curTime}})
		MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
		table.wipe(temp_table)
		DKPTable_Update()
	end
end

function MonDKP:AdjustDKPTab_Create()
	MonDKP.ConfigTab2.header = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.header:SetPoint("TOPLEFT", MonDKP.ConfigTab2, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab2.header:SetFontObject("MonDKPLargeCenter")
	MonDKP.ConfigTab2.header:SetText(L["AdjustDKP"]);
	MonDKP.ConfigTab2.header:SetScale(1.2)

	MonDKP.ConfigTab2.description = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.description:SetPoint("TOPLEFT", MonDKP.ConfigTab2.header, "BOTTOMLEFT", 7, -10);
	MonDKP.ConfigTab2.description:SetWidth(400)
	MonDKP.ConfigTab2.description:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab2.description:SetText(L["AdjustDesc"]); 

	-- Reason DROPDOWN box 
	-- Create the dropdown, and configure its appearance
	MonDKP.ConfigTab2.reasonDropDown = CreateFrame("FRAME", "MonDKPConfigReasonDropDown", MonDKP.ConfigTab2, "MonolithDKPUIDropDownMenuTemplate")
	MonDKP.ConfigTab2.reasonDropDown:SetPoint("TOPLEFT", MonDKP.ConfigTab2.description, "BOTTOMLEFT", -23, -60)
	UIDropDownMenu_SetWidth(MonDKP.ConfigTab2.reasonDropDown, 150)
	UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown, L["SelectReason"])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(MonDKP.ConfigTab2.reasonDropDown, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "MonDKPSmallCenter"
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["OnTimeBonus"], L["OnTimeBonus"], L["OnTimeBonus"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["BossKillBonus"], L["BossKillBonus"], L["BossKillBonus"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["RaidCompletionBonus"], L["RaidCompletionBonus"], L["RaidCompletionBonus"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["NewBossKillBonus"], L["NewBossKillBonus"], L["NewBossKillBonus"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["CorrectingError"], L["CorrectingError"], L["CorrectingError"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["DKPAdjust"], L["DKPAdjust"], L["DKPAdjust"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["UnexcusedAbsence"], L["UnexcusedAbsence"], L["UnexcusedAbsence"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["Other"], L["Other"], L["Other"] == curReason, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function MonDKP.ConfigTab2.reasonDropDown:SetValue(newValue)
		if curReason ~= newValue then curReason = newValue else curReason = nil end

		local DKPSettings = MonDKP:GetDKPSettings()
		UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown, curReason)

		if (curReason == L["OnTimeBonus"]) then MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["OnTimeBonus"])); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["BossKillBonus"]) then
			MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["BossKillBonus"]));
			MonDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["RaidCompletionBonus"]) then MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["CompletionBonus"])); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["NewBossKillBonus"]) then
			MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["NewBossKillBonus"]));
			MonDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["UnexcusedAbsence"]) then MonDKP.ConfigTab2.addDKP:SetNumber(tonumber(DKPSettings["UnexcusedAbsence"])); MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		else MonDKP.ConfigTab2.addDKP:SetText(""); MonDKP.ConfigTab2.BossKilledDropdown:Hide() end

		if (curReason == L["Other"]) then
			MonDKP.ConfigTab2.otherReason:Show();
			MonDKP.ConfigTab2.BossKilledDropdown:Hide()
		else
			MonDKP.ConfigTab2.otherReason:Hide();
		end

		CloseDropDownMenus()
	end

	MonDKP.ConfigTab2.reasonDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["Reason"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ReasonTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ReasonTTWarn"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.reasonDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.reasonHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.reasonHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.reasonDropDown, "TOPLEFT", 25, 0);
	MonDKP.ConfigTab2.reasonHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.reasonHeader:SetText(L["ReasonForAdjustment"]..":")

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
	MonDKP.ConfigTab2.otherReason:SetText(L["EnterOtherReasonHere"])
	MonDKP.ConfigTab2.otherReason:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab2.otherReason:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() == L["EnterOtherReasonHere"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	MonDKP.ConfigTab2.otherReason:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["EnterOtherReasonHere"])
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
	UIDropDownMenu_SetText(MonDKP.ConfigTab2.BossKilledDropdown, L["SelectBoss"])

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

		if curReason ~= L["BossKillBonus"] and curReason ~= L["NewBossKillBonus"] then
			MonDKP.ConfigTab2.reasonDropDown:SetValue(L["BossKillBonus"])
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
		GameTooltip:SetText(L["Points"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["PointsTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["PointsTTWarn"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.addDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.pointsHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.pointsHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.addDKP, "TOPLEFT", 3, 3);
	MonDKP.ConfigTab2.pointsHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.pointsHeader:SetText(L["Points"]..":")

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
	MonDKP.ConfigTab2.selectAll.text:SetText("  |cff5151de"..L["SelectAllVisible"].."|r");
	MonDKP.ConfigTab2.selectAll.text:SetScale(1.5);
	MonDKP.ConfigTab2.selectAll.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.selectAll:SetPoint("LEFT", MonDKP.ConfigTab2.addDKP, "RIGHT", 15, -13);
	MonDKP.ConfigTab2.selectAll:Hide();
	

		-- Adjust DKP Button
	MonDKP.ConfigTab2.adjustButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab2.addDKP, "BOTTOMLEFT", -1, -15, L["AdjustDKP"]);
	MonDKP.ConfigTab2.adjustButton:SetSize(90,25)
	MonDKP.ConfigTab2.adjustButton:SetScript("OnClick", function()
		if #core.SelectedData > 0 and curReason and MonDKP.ConfigTab2.otherReason:GetText() then
			local selected = L["AreYouSure"].." "..MonDKP_round(MonDKP.ConfigTab2.addDKP:GetNumber(), MonDKP_DB.modes.rounding).." "..L["DKPToFollowing"]..": \n\n";

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
		GameTooltip:SetText(L["AdjustDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["AdjustDKPTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["AdjustDKPTTWarn"], 1.0, 0, 0, true);
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
		GameTooltip:SetText(L["WeeklyDKPDecay"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["WeeklyDecayTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["WeeklyDecayTTWarn"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.decayDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.decayDKPHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.decayDKPHeader:SetFontObject("GameFontHighlightLeft");
	MonDKP.ConfigTab2.decayDKPHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.decayDKP, "TOPLEFT", 3, 3);
	MonDKP.ConfigTab2.decayDKPHeader:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.decayDKPHeader:SetText(L["WeeklyDKPDecay"]..":")

	MonDKP.ConfigTab2.decayDKPFooter = MonDKP.ConfigTab2.decayDKP:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab2.decayDKPFooter:SetFontObject("MonDKPNormalLeft");
	MonDKP.ConfigTab2.decayDKPFooter:SetPoint("LEFT", MonDKP.ConfigTab2.decayDKP, "RIGHT", -15, 0);
	MonDKP.ConfigTab2.decayDKPFooter:SetText("%")

	-- selected players only checkbox
	MonDKP.ConfigTab2.SelectedOnlyCheck = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetChecked(false)
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScale(0.6);
	MonDKP.ConfigTab2.SelectedOnlyCheck.text:SetText("  |cff5151de"..L["SelPlayersOnly"].."|r");
	MonDKP.ConfigTab2.SelectedOnlyCheck.text:SetScale(1.5);
	MonDKP.ConfigTab2.SelectedOnlyCheck.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetPoint("TOP", MonDKP.ConfigTab2.decayDKP, "BOTTOMLEFT", 15, -13);
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnClick", function(self)
		PlaySound(808)
	end)
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SelPlayersOnly"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SelPlayersTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["SelPlayersTTWarn"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- add to negative dkp checkbox
	MonDKP.ConfigTab2.AddNegative = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
	MonDKP.ConfigTab2.AddNegative:SetChecked(MonDKP_DB.modes.AddToNegative)
	MonDKP.ConfigTab2.AddNegative:SetScale(0.6);
	MonDKP.ConfigTab2.AddNegative.text:SetText("  |cff5151de"..L["AddNegValues"].."|r");
	MonDKP.ConfigTab2.AddNegative.text:SetScale(1.5);
	MonDKP.ConfigTab2.AddNegative.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab2.AddNegative:SetPoint("TOP", MonDKP.ConfigTab2.SelectedOnlyCheck, "BOTTOM", 0, 0);
	MonDKP.ConfigTab2.AddNegative:SetScript("OnClick", function(self)
		MonDKP_DB.modes.AddToNegative = self:GetChecked();
		PlaySound(808)
	end)
	MonDKP.ConfigTab2.AddNegative:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["AddNegValues"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["AddNegTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["AddNegTTWarn"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	MonDKP.ConfigTab2.AddNegative:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	MonDKP.ConfigTab2.decayButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab2.decayDKP, "TOPRIGHT", 20, 0, L["ApplyDecay"]);
	MonDKP.ConfigTab2.decayButton:SetSize(90,25)
	MonDKP.ConfigTab2.decayButton:SetScript("OnClick", function()
		local SelectedToggle;
		local selected;

		if MonDKP.ConfigTab2.SelectedOnlyCheck:GetChecked() then SelectedToggle = "|cffff0000"..L["Selected"].."|r" else SelectedToggle = "|cffff0000"..L["All"].."|r" end
		selected = L["ConfirmDecay"].." "..SelectedToggle.." "..L["DKPEntriesBy"].." "..MonDKP.ConfigTab2.decayDKP:GetNumber().."%%";

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
		GameTooltip:SetText(L["WeeklyDKPDecay"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["AppDecayTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["AppDecayTTWarn"], 1.0, 0, 0, true);
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

		-- Raid Timer Header
	    MonDKP.ConfigTab2.RaidTimerContainer.Header = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetFontObject("MonDKPLargeLeft");
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetScale(0.6)
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetPoint("TOPLEFT", MonDKP.ConfigTab2.RaidTimerContainer, "TOPLEFT", 15, -15);
	    MonDKP.ConfigTab2.RaidTimerContainer.Header:SetText(L["RaidTimer"])

	    -- Raid Timer Output Header
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetFontObject("MonDKPNormalRight");
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetPoint("TOP", MonDKP.ConfigTab2.RaidTimerContainer, "TOP", -20, -40);
	    MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TimeElapsed"]..":")
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
	    MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BonusAwarded"]..":")
	    MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Hide();

	    -- Bonus Awarded Output
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetFontObject("MonDKPLargeLeft");
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetScale(0.8)
	    MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetPoint("LEFT", MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader, "RIGHT", 5, 0);

	    -- Start Raid Timer Button
	    MonDKP.ConfigTab2.RaidTimerContainer.StartTimer = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 135, L["InitRaid"]);
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetSize(90,25)
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnClick", function(self)
			if not IsInRaid() then
				StaticPopupDialogs["NO_RAID_TIMER"] = {
					text = L["NotInRaid"],
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
				if MonDKP_DB.DKPBonus.GiveRaidStart and self:GetText() ~= L["ContinueRaid"] then
					StaticPopupDialogs["START_RAID_BONUS"] = {
						text = L["RaidTimerBonusConfirm"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							MonDKP.Sync:SendData("MonDKPRaidTimer", "start,false")
							if MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["ContinueRaid"] then
								MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidResume"])
							else
								MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidStart"])
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
					MonDKP.Sync:SendData("MonDKPRaidTimer", "start,false")
					if MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["ContinueRaid"] then
						MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidResume"])
					else
						MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidStart"])
						MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
					end
					MonDKP:StartRaidTimer(false)
				end
			else
				StaticPopupDialogs["END_RAID"] = {
					text = L["EndCurRaidConfirm"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidTimerConclude"].." "..MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
						MonDKP.Sync:SendData("MonDKPRaidTimer", "stop")
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
			GameTooltip:SetText(L["InitRaid"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["InitRaidTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["InitRaidTTWarn"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Pause Raid Timer Button
	    MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab2.RaidTimerContainer, "BOTTOMRIGHT", -10, 135, L["PauseRaid"]);
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetSize(90,25)
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnClick", function(self)
			if core.RaidInProgress then
				MonDKP.Sync:SendData("MonDKPRaidTimer", "start,true")
				MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidPause"].." "..MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
				MonDKP:StartRaidTimer(true)
			end
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["PauseRaid"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["PauseRaidTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["PauseRaidTTWarn"], 1.0, 0, 0, true);
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
					text = L["IncrementInvalidWarn"],
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
			GameTooltip:SetText(L["AwardInterval"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AwardIntervalTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["AwardIntervalTTWarn"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetFontObject("MonDKPTinyRight");
	    MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer.interval, "TOPLEFT", 0, 2);
	    MonDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetText(L["Interval"]..":")

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
					text = L["IncrementInvalidWarn"],
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
			GameTooltip:SetText(L["AwardBonus"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AwardBonusTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetFontObject("MonDKPTinyRight");
	    MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue, "TOPLEFT", 0, 2);
	    MonDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetText(L["Bonus"]..":")
    	
    	-- Give On Time Bonus Checkbox
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(MonDKP_DB.DKPBonus.GiveRaidStart)
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScale(0.6);
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetText("  |cff5151de"..L["GiveOnTimeBonus"].."|r");
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
			GameTooltip:SetText(L["GiveOnTimeBonus"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GiveOnTimeTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Give Raid End Bonus Checkbox
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(MonDKP_DB.DKPBonus.GiveRaidEnd)
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScale(0.6);
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetText("  |cff5151de"..L["GiveEndBonus"].."|r");
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
			GameTooltip:SetText(L["GiveEndBonus"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GiveEndBonusTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Include Standby Checkbox
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(MonDKP_DB.DKPBonus.IncStandby)
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScale(0.6);
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetText("  |cff5151de"..L["IncludeStandby"].."|r");
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
			GameTooltip:SetText(L["IncludeStandby"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["IncludeStandbyTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["IncludeStandbyTTWarn"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning = MonDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetFontObject("MonDKPTinyLeft");
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetWidth(180)
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 10);
	    MonDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetText("|CFFFF0000"..L["TimerWarning"].."|r")
end