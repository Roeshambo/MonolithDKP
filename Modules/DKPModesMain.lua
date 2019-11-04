local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

function MonDKP:ToggleDKPModesWindow()
	local f = core.ModesWindow;

	f.DKPTab1.ModeDescriptionHeader = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.ModeDescriptionHeader:SetFontObject("MonDKPLargeLeft");
	f.DKPTab1.ModeDescriptionHeader:SetWidth(400);
	f.DKPTab1.ModeDescriptionHeader:SetPoint("TOPLEFT", f.DKPTab1, "TOPLEFT", 30, -20);

	f.DKPTab1.ModeDescription = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.ModeDescription:SetPoint("TOPLEFT", f.DKPTab1, "TOPLEFT", 20, -45);
	f.DKPTab1.ModeDescription:SetWidth(400);
	f.DKPTab1.ModeDescription:SetFontObject("MonDKPSmallLeft")
	
	local MinBidDescription = L["MINBIDDESCRIPTION"]
	local StaticDescription = L["STATICDESCRIPTION"]
	local RollDescription = L["ROLLDESCRIPTION"]
	local ZeroSumDescription = L["ZEROSUMDESCRIPTION"];

	if MonDKP_DB.modes.mode == "Minimum Bid Values" then
		f.DKPTab1.ModeDescriptionHeader:SetText(L["MINBIDVALUESHEAD"])
		f.DKPTab1.ModeDescription:SetText(MinBidDescription)
	elseif MonDKP_DB.modes.mode == "Static Item Values" then
		f.DKPTab1.ModeDescriptionHeader:SetText(L["STATICITEMVALUESHEAD"])
		f.DKPTab1.ModeDescription:SetText(StaticDescription)
	elseif MonDKP_DB.modes.mode == "Roll Based Bidding" then
		f.DKPTab1.ModeDescriptionHeader:SetText(L["ROLLBIDDINGHEAD"])
		f.DKPTab1.ModeDescription:SetText(RollDescription)
	elseif MonDKP_DB.modes.mode == "Zero Sum" then
		f.DKPTab1.ModeDescriptionHeader:SetText(L["ZEROSUMHEAD"])
		f.DKPTab1.ModeDescription:SetText(ZeroSumDescription)
	end

	-- Mode DROPDOWN box 
	local CurMode = MonDKP_DB.modes.mode;
	local LocalMode;

	if CurMode == "Minimum Bid Values" then
		LocalMode = L["MINBIDVALUESHEAD"];
	elseif CurMode == "Static Item Values" then
		LocalMode = L["STATICITEMVALUESHEAD"]
	elseif CurMode == "Roll Based Bidding" then
		LocalMode = L["ROLLBIDDINGHEAD"]
	elseif CurMode == "Zero Sum" then
		LocalMode = L["ZEROSUMHEAD"]
	end


	f.DKPTab1.ModesDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f.DKPTab1, "MonolithDKPUIDropDownMenuTemplate")
	f.DKPTab1.ModesDropDown:SetPoint("TOPLEFT", f.DKPTab1, "TOPLEFT", 10, -200)
	UIDropDownMenu_SetWidth(f.DKPTab1.ModesDropDown, 150)
	UIDropDownMenu_SetText(f.DKPTab1.ModesDropDown, LocalMode)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPTab1.ModesDropDown, function(self, level, menuList)
	local DKPMode = UIDropDownMenu_CreateInfo()
		DKPMode.func = self.SetValue
		DKPMode.fontObject = "MonDKPSmallCenter"
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["MINBIDVALUESHEAD"], "Minimum Bid Values", "Minimum Bid Values" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["STATICITEMVALUESHEAD"], "Static Item Values", "Static Item Values" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["ROLLBIDDINGHEAD"], "Roll Based Bidding", "Roll Based Bidding" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["ZEROSUMHEAD"], "Zero Sum", "Zero Sum" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
	end)

	-- Dropdown Menu Function
	function f.DKPTab1.ModesDropDown:SetValue(newValue)
		if curMode ~= newValue then CurMode = newValue end

		f.DKPTab1.ModeDescriptionHeader:SetText(newValue)
		
		if newValue == "Minimum Bid Values" then
			MonDKP_DB.modes.mode = "Minimum Bid Values";
			f.DKPTab1.ModeDescription:SetText(MinBidDescription)
			f.DKPTab1.ItemCostDropDown:Hide();
			f.DKPTab1.ItemCostHeader:Hide();
			f.DKPTab1.MaxBid:Show();
			f.DKPTab1.MaxBid.Header:Show();
			MonDKP_DB.modes.costvalue = "Integer";
			UIDropDownMenu_SetText(f.DKPTab1.ItemCostDropDown, "Integer")
			f.DKPTab1.SubZeroBidding:Show();
			f.DKPTab1.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
			if MonDKP_DB.modes.SubZeroBidding == true then
				f.DKPTab1.AllowNegativeBidders:Show()
				f.DKPTab1.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
			end
			f.DKPTab1.RollContainer:Hide();
			f.DKPTab1.ZeroSumType:Hide();
			f.DKPTab1.ZeroSumTypeHeader:Hide();
			f.DKPTab1.CostSelection:Show();
			f.DKPTab1.CostSelectionHeader:Show();
			f.DKPTab1.Inflation:Hide()
    		f.DKPTab1.Inflation.Header:Hide()
		elseif newValue == "Static Item Values" then
			MonDKP_DB.modes.mode = "Static Item Values"
			f.DKPTab1.ModeDescription:SetText(StaticDescription)
			f.DKPTab1.ItemCostHeader:Show();
			f.DKPTab1.ItemCostDropDown:Show();
			f.DKPTab1.RollContainer:Hide()
			f.DKPTab1.MaxBid:Hide();
			f.DKPTab1.MaxBid.Header:Hide();
			f.DKPTab1.ZeroSumType:Hide()
			f.DKPTab1.ZeroSumTypeHeader:Hide();
			f.DKPTab1.CostSelection:Hide();
			f.DKPTab1.CostSelectionHeader:Hide();
			f.DKPTab1.Inflation:Hide()
    		f.DKPTab1.Inflation.Header:Hide()

			if MonDKP_DB.modes.costvalue == "Integer" then
				f.DKPTab1.SubZeroBidding:Show()
				f.DKPTab1.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
				if MonDKP_DB.modes.SubZeroBidding == true then
					f.DKPTab1.AllowNegativeBidders:Show()
					f.DKPTab1.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
				end
				UIDropDownMenu_SetText(f.DKPTab1.ItemCostDropDown, "Integer")
			end
		elseif newValue == "Roll Based Bidding" then
			MonDKP_DB.modes.mode = "Roll Based Bidding"
			f.DKPTab1.ItemCostHeader:Show();
			f.DKPTab1.ItemCostDropDown:Show();
			f.DKPTab1.ModeDescription:SetText(RollDescription)
			f.DKPTab1.RollContainer:Show()
			f.DKPTab1.MaxBid:Hide();
			f.DKPTab1.MaxBid.Header:Hide();
			f.DKPTab1.ZeroSumType:Hide()
			f.DKPTab1.ZeroSumTypeHeader:Hide();
			f.DKPTab1.CostSelection:Hide()
			f.DKPTab1.CostSelectionHeader:Hide()
			f.DKPTab1.Inflation:Hide()
    		f.DKPTab1.Inflation.Header:Hide()

			if MonDKP_DB.modes.costvalue == "Integer" then
				f.DKPTab1.SubZeroBidding:Show()
				f.DKPTab1.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
				if MonDKP_DB.modes.SubZeroBidding == true then
					f.DKPTab1.AllowNegativeBidders:Show()
					f.DKPTab1.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
				end
				UIDropDownMenu_SetText(f.DKPTab1.ItemCostDropDown, "Integer")
			end
		elseif newValue == "Zero Sum" then
			MonDKP_DB.modes.mode = "Zero Sum"
			MonDKP_DB.modes.costvalue = "Integer"
			f.DKPTab1.ModeDescription:SetText(ZeroSumDescription)
			f.DKPTab1.SubZeroBidding:Hide()
			f.DKPTab1.AllowNegativeBidders:Hide()
			f.DKPTab1.RollContainer:Hide()
			f.DKPTab1.ItemCostHeader:Hide();
			UIDropDownMenu_SetText(f.DKPTab1.ItemCostDropDown, "Integer")
			f.DKPTab1.ItemCostDropDown:Hide();
			f.DKPTab1.ZeroSumType:Show()
			f.DKPTab1.ZeroSumTypeHeader:Show();
			MonDKP_DB.modes.SubZeroBidding = true
			f.DKPTab1.Inflation:Show()
    		f.DKPTab1.Inflation.Header:Show()

			if MonDKP_DB.modes.ZeroSumBidType == "Static" then
				f.DKPTab1.MaxBid:Hide();
				f.DKPTab1.MaxBid.Header:Hide();
				f.DKPTab1.CostSelection:Hide()
				f.DKPTab1.CostSelectionHeader:Hide()
			else
				f.DKPTab1.MaxBid:Show()
				f.DKPTab1.MaxBid.Header:Show();
				f.DKPTab1.CostSelection:Show()
				f.DKPTab1.CostSelectionHeader:Show()
				f.DKPTab1.SubZeroBidding:Show()
				f.DKPTab1.AllowNegativeBidders:Show()
			end
		end

		if CurMode == "Minimum Bid Values" then
			LocalMode = L["MINBIDVALUESHEAD"];
		elseif CurMode == "Static Item Values" then
			LocalMode = L["STATICITEMVALUESHEAD"]
		elseif CurMode == "Roll Based Bidding" then
			LocalMode = L["ROLLBIDDINGHEAD"]
		elseif CurMode == "Zero Sum" then
			LocalMode = L["ZEROSUMHEAD"]
		end

		UIDropDownMenu_SetText(f.DKPTab1.ModesDropDown, LocalMode)
		CloseDropDownMenus()
	end

	f.DKPTab1.ModesDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DKPMODESTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.ModesDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPTab1.ModeHeader = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.ModeHeader:SetPoint("BOTTOMLEFT", f.DKPTab1.ModesDropDown, "TOPLEFT", 25, 0);
	f.DKPTab1.ModeHeader:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.ModeHeader:SetText(L["DKPMODES"])

	-- Rounding DROPDOWN box 
	f.DKPTab1.RoundDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f.DKPTab1, "MonolithDKPUIDropDownMenuTemplate")
	f.DKPTab1.RoundDropDown:SetPoint("TOPLEFT", f.DKPTab1.ModesDropDown, "BOTTOMLEFT", 0, -95)
	UIDropDownMenu_SetWidth(f.DKPTab1.RoundDropDown, 80)
	UIDropDownMenu_SetText(f.DKPTab1.RoundDropDown, MonDKP_DB.modes.rounding)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPTab1.RoundDropDown, function(self, level, menuList)
	local places = UIDropDownMenu_CreateInfo()
		places.func = self.SetValue
		places.fontObject = "MonDKPSmallCenter"
		places.text, places.arg1, places.checked, places.isNotRadio = 0, 0, 0 == MonDKP_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 1, 1, 1 == MonDKP_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 2, 2, 2 == MonDKP_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 3, 3, 3 == MonDKP_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 4, 4, 4 == MonDKP_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
	end)

	-- Dropdown Menu Function
	function f.DKPTab1.RoundDropDown:SetValue(newValue)
		MonDKP_DB.modes.rounding = newValue;
		UIDropDownMenu_SetText(f.DKPTab1.RoundDropDown, newValue)
		CloseDropDownMenus()
	end

	f.DKPTab1.RoundDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	f.DKPTab1.RoundDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DKPROUNDING"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DKPROUNDINGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.DKPTab1.RoundDropDown:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

	f.DKPTab1.RoundHeader = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.RoundHeader:SetPoint("BOTTOMLEFT", f.DKPTab1.RoundDropDown, "TOPLEFT", 25, 0);
	f.DKPTab1.RoundHeader:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.RoundHeader:SetText(L["DKPROUNDING"])

	-- AntiSnipe Option
	if not MonDKP_DB.modes.AntiSnipe then MonDKP_DB.modes.AntiSnipe = 0 end
	f.DKPTab1.AntiSnipe = CreateFrame("EditBox", nil, f.DKPTab1)
    f.DKPTab1.AntiSnipe:SetAutoFocus(false)
    f.DKPTab1.AntiSnipe:SetMultiLine(false)
    f.DKPTab1.AntiSnipe:SetPoint("TOPLEFT", f.DKPTab1.RoundDropDown, "BOTTOMLEFT", 18, -15)
    f.DKPTab1.AntiSnipe:SetSize(100, 24)
    f.DKPTab1.AntiSnipe:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPTab1.AntiSnipe:SetBackdropColor(0,0,0,0.9)
    f.DKPTab1.AntiSnipe:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPTab1.AntiSnipe:SetMaxLetters(8)
    f.DKPTab1.AntiSnipe:SetTextColor(1, 1, 1, 1)
    f.DKPTab1.AntiSnipe:SetFontObject("MonDKPSmallRight")
    f.DKPTab1.AntiSnipe:SetTextInsets(10, 15, 5, 5)
    f.DKPTab1.AntiSnipe:SetText(MonDKP_DB.modes.AntiSnipe)
    f.DKPTab1.AntiSnipe:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.AntiSnipe = f.DKPTab1.AntiSnipe:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.AntiSnipe:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.AntiSnipe = f.DKPTab1.AntiSnipe:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.AntiSnipe:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.AntiSnipe = f.DKPTab1.AntiSnipe:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.AntiSnipe:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ANTISNIPE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ANTISNIPETTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ANTISNIPETTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
    f.DKPTab1.AntiSnipe:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    f.DKPTab1.AntiSnipe.Header = f.DKPTab1.AntiSnipe:CreateFontString(nil, "OVERLAY")
    f.DKPTab1.AntiSnipe.Header:SetFontObject("MonDKPNormalLeft");
    f.DKPTab1.AntiSnipe.Header:SetPoint("BOTTOMLEFT", f.DKPTab1.AntiSnipe, "TOPLEFT", 0, 2);
    f.DKPTab1.AntiSnipe.Header:SetText(L["ANTISNIPE"])

	-- AutoAward DKP Checkbox
	f.DKPTab1.AutoAward = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.AutoAward:SetChecked(MonDKP_DB.modes.AutoAward)
	f.DKPTab1.AutoAward:SetScale(0.6);
	f.DKPTab1.AutoAward.text:SetText("  |cff5151de"..L["AUTOAWARD"].."|r");
	f.DKPTab1.AutoAward.text:SetScale(1.5);
	f.DKPTab1.AutoAward.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.AutoAward:SetPoint("TOPLEFT", f.DKPTab1.AntiSnipe, "BOTTOMLEFT", 10, -10);
	f.DKPTab1.AutoAward:SetScript("OnClick", function(self)
		MonDKP_DB.modes.AutoAward = self:GetChecked();
		if self:GetChecked() == false then
			f.DKPTab1.IncStandby:SetChecked(false)
			MonDKP_DB.DKPBonus.AutoIncStandby = false;
		end
		PlaySound(808);
	end)
	f.DKPTab1.AutoAward:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["AUTOAWARD"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["AUTOAWARDTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["INCLUDESBYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.AutoAward:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Include Standby Checkbox
	f.DKPTab1.IncStandby = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.IncStandby:SetChecked(MonDKP_DB.DKPBonus.AutoIncStandby)
	f.DKPTab1.IncStandby:SetScale(0.6);
	f.DKPTab1.IncStandby.text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
	f.DKPTab1.IncStandby.text:SetScale(1.5);
	f.DKPTab1.IncStandby.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.IncStandby:SetPoint("TOP", f.DKPTab1.AutoAward, "BOTTOM", 0, 0);
	f.DKPTab1.IncStandby:SetScript("OnClick", function(self)
		MonDKP_DB.DKPBonus.AutoIncStandby = self:GetChecked();
		if self:GetChecked() == true then
			f.DKPTab1.AutoAward:SetChecked(true)
			MonDKP_DB.modes.AutoAward = true;
		end
		PlaySound(808);
	end)
	f.DKPTab1.IncStandby:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["INCLUDESTANDBY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["INCLUDESBYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["INCLUDESBYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.IncStandby:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Standby On Boss Kill Checkbox
	f.DKPTab1.Standby = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.Standby:SetChecked(MonDKP_DB.modes.StandbyOptIn)
	f.DKPTab1.Standby:SetScale(0.6);
	f.DKPTab1.Standby.text:SetText("  |cff5151de"..L["STANDBYOPTIN"].."|r");
	f.DKPTab1.Standby.text:SetScale(1.5);
	f.DKPTab1.Standby.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.Standby:SetPoint("TOP", f.DKPTab1.IncStandby, "BOTTOM", 0, 0);
	f.DKPTab1.Standby:SetScript("OnClick", function(self)
		MonDKP_DB.modes.StandbyOptIn = self:GetChecked();
		PlaySound(808);
	end)
	f.DKPTab1.Standby:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["STANDBYOPTIN"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["STANDBYOPTINTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["STANDBYOPTINTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.Standby:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Channels DROPDOWN box 
	f.DKPTab1.ChannelsDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f.DKPTab1, "MonolithDKPUIDropDownMenuTemplate")
	f.DKPTab1.ChannelsDropDown:SetPoint("LEFT", f.DKPTab1.ModesDropDown, "RIGHT", 30, 0)
	UIDropDownMenu_SetWidth(f.DKPTab1.ChannelsDropDown, 150)
	UIDropDownMenu_SetText(f.DKPTab1.ChannelsDropDown, L["OPENCHANNELS"])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPTab1.ChannelsDropDown, function(self, level, menuList)
	local OpenChannel = UIDropDownMenu_CreateInfo()
		OpenChannel.func = self.SetValue
		OpenChannel.fontObject = "MonDKPSmallCenter"
		OpenChannel.keepShownOnClick = true;
		OpenChannel.isNotRadio = true;
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["WHISPER"], "Whisper", true == MonDKP_DB.modes.channels.whisper
		UIDropDownMenu_AddButton(OpenChannel)
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["RAID"], "Raid", true == MonDKP_DB.modes.channels.raid
		UIDropDownMenu_AddButton(OpenChannel)
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["GUILD"], "Guild", true == MonDKP_DB.modes.channels.guild
		UIDropDownMenu_AddButton(OpenChannel)
	end)

	-- Announce Highest Bid
	f.DKPTab1.AnnounceBid = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.AnnounceBid:SetChecked(MonDKP_DB.modes.AnnounceBid)
	f.DKPTab1.AnnounceBid:SetScale(0.6);
	f.DKPTab1.AnnounceBid.text:SetText("  |cff5151de"..L["ANNOUNCEBID"].."|r");
	f.DKPTab1.AnnounceBid.text:SetScale(1.5);
	f.DKPTab1.AnnounceBid.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.AnnounceBid:SetPoint("LEFT", f.DKPTab1.AutoAward.text, "RIGHT", 20, 0);
	f.DKPTab1.AnnounceBid:SetScript("OnClick", function(self)
		MonDKP_DB.modes.AnnounceBid = self:GetChecked();
		if self:GetChecked() == false then
			f.DKPTab1.AnnounceBidName:SetChecked(false)
			MonDKP_DB.modes.AnnounceBidName = false;
		end
		PlaySound(808);
	end)
	f.DKPTab1.AnnounceBid:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ANNOUNCEBID"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ANNOUNCEBIDTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.AnnounceBid:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Include Name Announce Highest Bid
	f.DKPTab1.AnnounceBidName = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.AnnounceBidName:SetChecked(MonDKP_DB.modes.AnnounceBidName)
	f.DKPTab1.AnnounceBidName:SetScale(0.6);
	f.DKPTab1.AnnounceBidName.text:SetText("  |cff5151de"..L["INCLUDENAME"].."|r");
	f.DKPTab1.AnnounceBidName.text:SetScale(1.5);
	f.DKPTab1.AnnounceBidName.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.AnnounceBidName:SetPoint("TOP", f.DKPTab1.AnnounceBid, "BOTTOM", 0, 0);
	f.DKPTab1.AnnounceBidName:SetScript("OnClick", function(self)
		MonDKP_DB.modes.AnnounceBidName = self:GetChecked();
		if self:GetChecked() == true then
			f.DKPTab1.AnnounceBid:SetChecked(true)
			MonDKP_DB.modes.AnnounceBid = true;
		end
		PlaySound(808);
	end)
	f.DKPTab1.AnnounceBidName:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["INCLUDENAME"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["INCLUDENAMETTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.AnnounceBidName:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Announce Award to Guild
	f.DKPTab1.AnnounceAward = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.AnnounceAward:SetChecked(MonDKP_DB.modes.AnnounceAward)
	f.DKPTab1.AnnounceAward:SetScale(0.6);
	f.DKPTab1.AnnounceAward.text:SetText("  |cff5151de"..L["ANNOUNCEAWARD"].."|r");
	f.DKPTab1.AnnounceAward.text:SetScale(1.5);
	f.DKPTab1.AnnounceAward.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.AnnounceAward:SetPoint("TOP", f.DKPTab1.AnnounceBidName, "BOTTOM", 0, 0);
	f.DKPTab1.AnnounceAward:SetScript("OnClick", function(self)
		MonDKP_DB.modes.AnnounceAward = self:GetChecked();
		PlaySound(808);
	end)
	f.DKPTab1.AnnounceAward:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ANNOUNCEAWARD"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ANNOUNCEAWARDTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.AnnounceAward:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Dropdown Menu Function
	function f.DKPTab1.ChannelsDropDown:SetValue(arg1)
		if arg1 == "Whisper" then
			MonDKP_DB.modes.channels.whisper = not MonDKP_DB.modes.channels.whisper
		elseif arg1 == "Raid" then
			MonDKP_DB.modes.channels.raid = not MonDKP_DB.modes.channels.raid
		elseif arg1 == "Guild" then
			MonDKP_DB.modes.channels.guild = not MonDKP_DB.modes.channels.guild
		end

		UIDropDownMenu_SetText(f.DKPTab1.ChannelsDropDown, "Open Channels")
		CloseDropDownMenus()
	end

	f.DKPTab1.ChannelsDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["COMMANDCHANNELS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["COMMANDCHANNELSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.ChannelsDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPTab1.ChannelsHeader = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.ChannelsHeader:SetPoint("BOTTOMLEFT", f.DKPTab1.ChannelsDropDown, "TOPLEFT", 25, 0);
	f.DKPTab1.ChannelsHeader:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.ChannelsHeader:SetText(L["COMMANDCHANNELS"])

	-- Cost Auto Update Value DROPDOWN box 
	if not MonDKP_DB.modes.CostSelection then MonDKP_DB.modes.CostSelection = "Second Bidder" end
	f.DKPTab1.CostSelection = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f.DKPTab1, "MonolithDKPUIDropDownMenuTemplate")
	f.DKPTab1.CostSelection:SetPoint("TOPLEFT", f.DKPTab1.ChannelsDropDown, "BOTTOMLEFT", 0, -10)

	local LocalCostSel;

	if MonDKP_DB.modes.CostSelection == "First Bidder" then
		LocalCostSel = L["FIRSTBIDDER"]
	elseif MonDKP_DB.modes.CostSelection == "Second Bidder" then
		LocalCostSel = L["SECONDBIDDER"]
	end

	UIDropDownMenu_SetWidth(f.DKPTab1.CostSelection, 150)
	UIDropDownMenu_SetText(f.DKPTab1.CostSelection, LocalCostSel)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPTab1.CostSelection, function(self, level, menuList)
	local CostSelect = UIDropDownMenu_CreateInfo()
		CostSelect.func = self.SetValue
		CostSelect.fontObject = "MonDKPSmallCenter"
		CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["FIRSTBIDDER"], "First Bidder", "First Bidder" == MonDKP_DB.modes.CostSelection, false
		UIDropDownMenu_AddButton(CostSelect)
		CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["SECONDBIDDER"], "Second Bidder", "Second Bidder" == MonDKP_DB.modes.CostSelection, false
		UIDropDownMenu_AddButton(CostSelect)
	end)

	-- Dropdown Menu Function
	function f.DKPTab1.CostSelection:SetValue(arg1)
		MonDKP_DB.modes.CostSelection = arg1

		if arg1 == "First Bidder" then
			LocalCostSel = L["FIRSTBIDDER"]
		else
			LocalCostSel = L["SECONDBIDDER"]
		end

		UIDropDownMenu_SetText(f.DKPTab1.CostSelection, LocalCostSel)
		CloseDropDownMenus()
	end

	f.DKPTab1.CostSelection:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["COSTAUTOUPDATE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["COSTAUTOUPDATETTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.CostSelection:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPTab1.CostSelectionHeader = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.CostSelectionHeader:SetPoint("BOTTOMLEFT", f.DKPTab1.CostSelection, "TOPLEFT", 25, 0);
	f.DKPTab1.CostSelectionHeader:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.CostSelectionHeader:SetText(L["COSTAUTOUPDATEVALUE"])

	if not (MonDKP_DB.modes.mode == "Minimum Bid Values" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid")) then
		f.DKPTab1.CostSelection:Hide()
		f.DKPTab1.CostSelectionHeader:Hide();
	end

	-- Artificial Inflation Editbox
	if not MonDKP_DB.modes.Inflation then MonDKP_DB.modes.Inflation = 0 end
	f.DKPTab1.Inflation = CreateFrame("EditBox", nil, f.DKPTab1)
    f.DKPTab1.Inflation:SetAutoFocus(false)
    f.DKPTab1.Inflation:SetMultiLine(false)
    f.DKPTab1.Inflation:SetPoint("TOPLEFT", f.DKPTab1.CostSelection, "BOTTOMLEFT", 20, -15)
    f.DKPTab1.Inflation:SetSize(100, 24)
    f.DKPTab1.Inflation:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPTab1.Inflation:SetBackdropColor(0,0,0,0.9)
    f.DKPTab1.Inflation:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPTab1.Inflation:SetMaxLetters(8)
    f.DKPTab1.Inflation:SetTextColor(1, 1, 1, 1)
    f.DKPTab1.Inflation:SetFontObject("MonDKPSmallRight")
    f.DKPTab1.Inflation:SetTextInsets(10, 15, 5, 5)
    f.DKPTab1.Inflation:SetText(MonDKP_DB.modes.Inflation)
    f.DKPTab1.Inflation:Hide();
    f.DKPTab1.Inflation:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.Inflation = f.DKPTab1.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.Inflation:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.Inflation = f.DKPTab1.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.Inflation:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.Inflation = f.DKPTab1.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.Inflation:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ARTIFICIALINFLATION"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ARTINFLATTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.DKPTab1.Inflation:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    -- Min Roll Header
    f.DKPTab1.Inflation.Header = f.DKPTab1.Inflation:CreateFontString(nil, "OVERLAY")
    f.DKPTab1.Inflation.Header:SetFontObject("MonDKPNormalLeft");
    f.DKPTab1.Inflation.Header:SetPoint("BOTTOM", f.DKPTab1.Inflation, "TOP", -20, 2);
    f.DKPTab1.Inflation.Header:SetText(L["INFLATION"])

    if MonDKP_DB.modes.mode == "Zero Sum" then
    	f.DKPTab1.Inflation:Show()
    	f.DKPTab1.Inflation.Header:Show()
    end

    -- ZeroSum Type DROPDOWN box 
	f.DKPTab1.ZeroSumType = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f.DKPTab1, "MonolithDKPUIDropDownMenuTemplate")
	f.DKPTab1.ZeroSumType:SetPoint("TOPLEFT", f.DKPTab1.Inflation, "BOTTOMLEFT", -20, -20)
	UIDropDownMenu_SetWidth(f.DKPTab1.ZeroSumType, 150)
	UIDropDownMenu_SetText(f.DKPTab1.ZeroSumType, MonDKP_DB.modes.ZeroSumBidType)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPTab1.ZeroSumType, function(self, level, menuList)
	local BidType = UIDropDownMenu_CreateInfo()
		BidType.func = self.SetValue
		BidType.fontObject = "MonDKPSmallCenter"
		BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["STATIC"], "Static", "Static" == MonDKP_DB.modes.ZeroSumBidType, false
		UIDropDownMenu_AddButton(BidType)
		BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["MINIMUMBID"], "Minimum Bid", "Minimum Bid" == MonDKP_DB.modes.ZeroSumBidType, false
		UIDropDownMenu_AddButton(BidType)
	end)

	-- Dropdown Menu Function
	function f.DKPTab1.ZeroSumType:SetValue(newValue)
		MonDKP_DB.modes.ZeroSumBidType = newValue;
		if newValue == "Static" then
			f.DKPTab1.MaxBid:Hide();
			f.DKPTab1.MaxBid.Header:Hide();
			f.DKPTab1.CostSelection:Hide();
			f.DKPTab1.CostSelectionHeader:Hide();
			newValue = L["STATIC"]
			f.DKPTab1.SubZeroBidding:Hide()
			f.DKPTab1.AllowNegativeBidders:Hide()
		else
			f.DKPTab1.MaxBid:Show();
			f.DKPTab1.MaxBid.Header:Show();
			f.DKPTab1.CostSelection:Show();
			f.DKPTab1.CostSelectionHeader:Show();
			newValue = L["MINIMUMBID"]
			f.DKPTab1.SubZeroBidding:Show()
			f.DKPTab1.AllowNegativeBidders:Show()
		end

		UIDropDownMenu_SetText(f.DKPTab1.ZeroSumType, newValue)
		CloseDropDownMenus()
	end

	f.DKPTab1.ZeroSumType:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ZEROSUMITEMCOST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ZEROSUMITEMCOSTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.ZeroSumType:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPTab1.ZeroSumTypeHeader = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.ZeroSumTypeHeader:SetPoint("BOTTOMLEFT", f.DKPTab1.ZeroSumType, "TOPLEFT", 25, 0);
	f.DKPTab1.ZeroSumTypeHeader:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.ZeroSumTypeHeader:SetText(L["BIDMETHOD"])

	if MonDKP_DB.modes.mode ~= "Zero Sum" then
		f.DKPTab1.ZeroSumType:Hide()
		f.DKPTab1.ZeroSumTypeHeader:Hide();
	end

	-- Item Cost Value DROPDOWN box 
	f.DKPTab1.ItemCostDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f.DKPTab1, "MonolithDKPUIDropDownMenuTemplate")
	f.DKPTab1.ItemCostDropDown:SetPoint("TOPLEFT", f.DKPTab1.ModesDropDown, "BOTTOMLEFT", 0, -50)
	UIDropDownMenu_SetWidth(f.DKPTab1.ItemCostDropDown, 150)
	UIDropDownMenu_SetText(f.DKPTab1.ItemCostDropDown, L[MonDKP_DB.modes.costvalue])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPTab1.ItemCostDropDown, function(self, level, menuList)
	local CostValue = UIDropDownMenu_CreateInfo()
		CostValue.func = self.SetValue
		CostValue.fontObject = "MonDKPSmallCenter"
		CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["INTEGER"], "Integer", "Integer" == MonDKP_DB.modes.costvalue, false
		UIDropDownMenu_AddButton(CostValue)
		CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["PERCENT"], "Percent", "Percent" == MonDKP_DB.modes.costvalue, false
		UIDropDownMenu_AddButton(CostValue)
	end)

	-- Dropdown Menu Function
	function f.DKPTab1.ItemCostDropDown:SetValue(arg1)
		if arg1 == "Integer" then
			MonDKP_DB.modes.costvalue = "Integer"
			f.DKPTab1.SubZeroBidding:Show()
			f.DKPTab1.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
			if MonDKP_DB.modes.SubZeroBidding == true then
				f.DKPTab1.AllowNegativeBidders:Show()
				f.DKPTab1.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
			end
		elseif arg1 == "Percent" then
			MonDKP_DB.modes.costvalue = "Percent"
			f.DKPTab1.SubZeroBidding:Hide()
			f.DKPTab1.AllowNegativeBidders:Hide()
			MonDKP_DB.modes.SubZeroBidding = false;
			f.DKPTab1.SubZeroBidding:SetChecked(false)
		end

		UIDropDownMenu_SetText(f.DKPTab1.ItemCostDropDown, L[arg1])
		CloseDropDownMenus()
	end

	f.DKPTab1.ItemCostDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ITEMCOSTTYPES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ITEMCOSTTYPESTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.ItemCostDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPTab1.ItemCostHeader = f.DKPTab1:CreateFontString(nil, "OVERLAY")
	f.DKPTab1.ItemCostHeader:SetPoint("BOTTOMLEFT", f.DKPTab1.ItemCostDropDown, "TOPLEFT", 25, 0);
	f.DKPTab1.ItemCostHeader:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.ItemCostHeader:SetText(L["ITEMCOSTTYPES"])

	if MonDKP_DB.modes.mode == "Minimum Bid Values" then
		f.DKPTab1.ItemCostDropDown:Hide();
		f.DKPTab1.ItemCostHeader:Hide();
		MonDKP_DB.modes.costvalue = "Integer";
	elseif MonDKP_DB.modes.mode == "Zero Sum" then
		f.DKPTab1.ItemCostDropDown:Hide();
		f.DKPTab1.ItemCostHeader:Hide();
		MonDKP_DB.modes.costvalue = "Integer";
	end


	-- Min Roll Editbox
	if not MonDKP_DB.modes.MaximumBid then MonDKP_DB.modes.MaximumBid = 0 end
	f.DKPTab1.MaxBid = CreateFrame("EditBox", nil, f.DKPTab1)
    f.DKPTab1.MaxBid:SetAutoFocus(false)
    f.DKPTab1.MaxBid:SetMultiLine(false)
    f.DKPTab1.MaxBid:SetPoint("TOPLEFT", f.DKPTab1.ModesDropDown, "BOTTOMLEFT", 18, -55)
    f.DKPTab1.MaxBid:SetSize(100, 24)
    f.DKPTab1.MaxBid:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPTab1.MaxBid:SetBackdropColor(0,0,0,0.9)
    f.DKPTab1.MaxBid:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPTab1.MaxBid:SetMaxLetters(8)
    f.DKPTab1.MaxBid:SetTextColor(1, 1, 1, 1)
    f.DKPTab1.MaxBid:SetFontObject("MonDKPSmallRight")
    f.DKPTab1.MaxBid:SetTextInsets(10, 15, 5, 5)
    f.DKPTab1.MaxBid:SetText(MonDKP_DB.modes.MaximumBid)
    f.DKPTab1.MaxBid:Hide();
    f.DKPTab1.MaxBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.MaximumBid = f.DKPTab1.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.MaxBid:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.MaximumBid = f.DKPTab1.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.MaxBid:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.MaximumBid = f.DKPTab1.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPTab1.MaxBid:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["MAXIMUMBID"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["MAXIMUMBIDTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.DKPTab1.MaxBid:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    -- Min Roll Header
    f.DKPTab1.MaxBid.Header = f.DKPTab1.MaxBid:CreateFontString(nil, "OVERLAY")
    f.DKPTab1.MaxBid.Header:SetFontObject("MonDKPNormalLeft");
    f.DKPTab1.MaxBid.Header:SetPoint("BOTTOM", f.DKPTab1.MaxBid, "TOP", -8, 2);
    f.DKPTab1.MaxBid.Header:SetText(L["MAXIMUMBID"])


    if MonDKP_DB.modes.mode == "Minimum Bid Values" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		f.DKPTab1.MaxBid:Show();
		f.DKPTab1.MaxBid.Header:Show();
	end

	-- Sub Zero Bidding Checkbox
	f.DKPTab1.SubZeroBidding = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
	f.DKPTab1.SubZeroBidding:SetScale(0.6);
	f.DKPTab1.SubZeroBidding.text:SetText("  |cff5151de"..L["SUBZEROBIDDING"].."|r");
	f.DKPTab1.SubZeroBidding.text:SetScale(1.5);
	f.DKPTab1.SubZeroBidding.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.SubZeroBidding:SetPoint("TOP", f.DKPTab1.ModesDropDown, "BOTTOMLEFT", 60, 0);
	f.DKPTab1.SubZeroBidding:SetScript("OnClick", function(self)
		if not MonDKP_DB.modes.SubZeroBidding then MonDKP_DB.modes.SubZeroBidding = false end
		if self:GetChecked() == true then
			MonDKP_DB.modes.SubZeroBidding = true;
			MonDKP:Print("Sub Zero Bidding |cff00ff00"..L["ENABLED"].."|r")
			f.DKPTab1.AllowNegativeBidders:Show()
			f.DKPTab1.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
		else
			MonDKP_DB.modes.SubZeroBidding = false;
			MonDKP:Print("Sub Zero Bidding |cffff0000"..L["DISABLED"].."|r")
			MonDKP_DB.modes.AllowNegativeBidders = false
			f.DKPTab1.AllowNegativeBidders:Hide()
		end
		PlaySound(808);
	end)
	f.DKPTab1.SubZeroBidding:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SUBZEROBIDDING"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SUBZEROBIDDINGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.SubZeroBidding:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	if MonDKP_DB.modes.costvalue == "Percent" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		f.DKPTab1.SubZeroBidding:Hide()
	end
	
	-- Allow Bids below zero Checkbox
	f.DKPTab1.AllowNegativeBidders = CreateFrame("CheckButton", nil, f.DKPTab1, "UICheckButtonTemplate");
	f.DKPTab1.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
	f.DKPTab1.AllowNegativeBidders:SetScale(0.6);
	f.DKPTab1.AllowNegativeBidders.text:SetText("  |cff5151de"..L["ALLOWNEGATIVEBIDDERS"].."|r");
	f.DKPTab1.AllowNegativeBidders.text:SetScale(1.5);
	f.DKPTab1.AllowNegativeBidders.text:SetFontObject("MonDKPSmallLeft")
	f.DKPTab1.AllowNegativeBidders:SetPoint("TOPLEFT", f.DKPTab1.SubZeroBidding, "BOTTOMLEFT", 0, 0);
	f.DKPTab1.AllowNegativeBidders:SetScript("OnClick", function(self)
		if not MonDKP_DB.modes.AllowNegativeBidders then MonDKP_DB.modes.AllowNegativeBidders = false end
		if self:GetChecked() == true then
			MonDKP_DB.modes.AllowNegativeBidders = true;
			MonDKP:Print("Allow Negative Bidders |cff00ff00"..L["ENABLED"].."|r")
		else
			MonDKP_DB.modes.AllowNegativeBidders = false;
			MonDKP:Print("Allow Negative Bidders |cffff0000"..L["DISABLED"].."|r")
		end
		PlaySound(808);
	end)
	f.DKPTab1.AllowNegativeBidders:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ALLOWNEGATIVEBIDDERS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ALLOWNEGATIVEBIDTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPTab1.AllowNegativeBidders:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	if (MonDKP_DB.modes.costvalue == "Percent" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static")) or MonDKP_DB.modes.SubZeroBidding == false then
		f.DKPTab1.AllowNegativeBidders:Hide()
	end


	-- Roll Container
	f.DKPTab1.RollContainer = CreateFrame("Frame", nil, f.DKPTab1);
	f.DKPTab1.RollContainer:SetSize(210, 150);
	f.DKPTab1.RollContainer:SetPoint("TOPLEFT", f.DKPTab1.ChannelsDropDown, "BOTTOMLEFT", -10, -20)
	f.DKPTab1.RollContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
	f.DKPTab1.RollContainer:SetBackdropColor(0,0,0,0.9)
	f.DKPTab1.RollContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	f.DKPTab1.RollContainer:Hide();
    if MonDKP_DB.modes.mode == "Roll Based Bidding" then
    	f.DKPTab1.RollContainer:Show()
    end

	-- Roll Container Header
    f.DKPTab1.RollContainer.Header = f.DKPTab1.RollContainer:CreateFontString(nil, "OVERLAY")
    f.DKPTab1.RollContainer.Header:SetFontObject("MonDKPLargeLeft");
    f.DKPTab1.RollContainer.Header:SetScale(0.6)
    f.DKPTab1.RollContainer.Header:SetPoint("TOPLEFT", f.DKPTab1.RollContainer, "TOPLEFT", 15, -15);
    f.DKPTab1.RollContainer.Header:SetText(L["ROLLSETTINGS"])


		-- Min Roll Editbox
		f.DKPTab1.RollContainer.rollMin = CreateFrame("EditBox", nil, f.DKPTab1.RollContainer)
	    f.DKPTab1.RollContainer.rollMin:SetAutoFocus(false)
	    f.DKPTab1.RollContainer.rollMin:SetMultiLine(false)
	    f.DKPTab1.RollContainer.rollMin:SetPoint("TOPLEFT", f.DKPTab1.RollContainer, "TOPLEFT", 20, -50)
	    f.DKPTab1.RollContainer.rollMin:SetSize(70, 24)
	    f.DKPTab1.RollContainer.rollMin:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.DKPTab1.RollContainer.rollMin:SetBackdropColor(0,0,0,0.9)
	    f.DKPTab1.RollContainer.rollMin:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.DKPTab1.RollContainer.rollMin:SetMaxLetters(6)
	    f.DKPTab1.RollContainer.rollMin:SetTextColor(1, 1, 1, 1)
	    f.DKPTab1.RollContainer.rollMin:SetFontObject("MonDKPSmallRight")
	    f.DKPTab1.RollContainer.rollMin:SetTextInsets(10, 15, 5, 5)
	    f.DKPTab1.RollContainer.rollMin:SetText(MonDKP_DB.modes.rolls.min)
	    f.DKPTab1.RollContainer.rollMin:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()
	    	self:ClearFocus()
	    end)
	    f.DKPTab1.RollContainer.rollMin:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()
	      	f.DKPTab1.RollContainer.rollMax:SetFocus()
	    end)
	    f.DKPTab1.RollContainer.rollMin:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()	
	    	self:ClearFocus()
	    end)
	    f.DKPTab1.RollContainer.rollMin:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MINIMUMROLL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["MINIMUMROLLTTDESC"], 1.0, 1.0, 1.0, true);
			--GameTooltip:AddLine("The state of this option will persist indefinitely until manually disabled/enabled.", 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.DKPTab1.RollContainer.rollMin:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Min Roll Header
	    f.DKPTab1.RollContainer.rollMin.Header = f.DKPTab1.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
	    f.DKPTab1.RollContainer.rollMin.Header:SetFontObject("MonDKPNormalLeft");
	    f.DKPTab1.RollContainer.rollMin.Header:SetPoint("BOTTOM", f.DKPTab1.RollContainer.rollMin, "TOP", -20, 2);
	    f.DKPTab1.RollContainer.rollMin.Header:SetText(L["MIN"])

	    -- Dash Between Rolls
	    f.DKPTab1.RollContainer.dash = f.DKPTab1.RollContainer:CreateFontString(nil, "OVERLAY")
	    f.DKPTab1.RollContainer.dash:SetFontObject("MonDKPLargeLeft");
	    f.DKPTab1.RollContainer.dash:SetPoint("LEFT", f.DKPTab1.RollContainer.rollMin, "RIGHT", 9, 0);
	    f.DKPTab1.RollContainer.dash:SetText("-")

	    -- Max Roll Editbox
		f.DKPTab1.RollContainer.rollMax = CreateFrame("EditBox", nil, f.DKPTab1.RollContainer)
	    f.DKPTab1.RollContainer.rollMax:SetAutoFocus(false)
	    f.DKPTab1.RollContainer.rollMax:SetMultiLine(false)
	    f.DKPTab1.RollContainer.rollMax:SetPoint("LEFT", f.DKPTab1.RollContainer.rollMin, "RIGHT", 24, 0)
	    f.DKPTab1.RollContainer.rollMax:SetSize(70, 24)
	    f.DKPTab1.RollContainer.rollMax:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.DKPTab1.RollContainer.rollMax:SetBackdropColor(0,0,0,0.9)
	    f.DKPTab1.RollContainer.rollMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.DKPTab1.RollContainer.rollMax:SetMaxLetters(6)
	    f.DKPTab1.RollContainer.rollMax:SetTextColor(1, 1, 1, 1)
	    f.DKPTab1.RollContainer.rollMax:SetFontObject("MonDKPSmallRight")
	    f.DKPTab1.RollContainer.rollMax:SetTextInsets(10, 15, 5, 5)
	    f.DKPTab1.RollContainer.rollMax:SetText(MonDKP_DB.modes.rolls.max)
	    f.DKPTab1.RollContainer.rollMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()	
	    	self:ClearFocus()
	    end)
	    f.DKPTab1.RollContainer.rollMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	      	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()	
	    	f.DKPTab1.RollContainer.AddMax:SetFocus()
	    end)
	    f.DKPTab1.RollContainer.rollMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()	
	    	self:ClearFocus()
	    end)
	    f.DKPTab1.RollContainer.rollMax:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MAXIMUMROLL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["MAXIMUMROLLTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["MAXIMUMROLLTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.DKPTab1.RollContainer.rollMax:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Max Roll Header
	    f.DKPTab1.RollContainer.rollMax.Header = f.DKPTab1.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
	    f.DKPTab1.RollContainer.rollMax.Header:SetFontObject("MonDKPNormalLeft");
	    f.DKPTab1.RollContainer.rollMax.Header:SetPoint("BOTTOM", f.DKPTab1.RollContainer.rollMax, "TOP", -20, 2);
	    f.DKPTab1.RollContainer.rollMax.Header:SetText(L["MAX"])

		f.DKPTab1.RollContainer.rollMin.perc = f.DKPTab1.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
		f.DKPTab1.RollContainer.rollMin.perc:SetFontObject("MonDKPSmallLeft");
		f.DKPTab1.RollContainer.rollMin.perc:SetPoint("LEFT", f.DKPTab1.RollContainer.rollMin, "RIGHT", -15, 0);
		f.DKPTab1.RollContainer.rollMin.perc:SetText("%")
		f.DKPTab1.RollContainer.rollMin.perc:SetShown(MonDKP_DB.modes.rolls.UsePerc);

		f.DKPTab1.RollContainer.rollMax.perc = f.DKPTab1.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
		f.DKPTab1.RollContainer.rollMax.perc:SetFontObject("MonDKPSmallLeft");
		f.DKPTab1.RollContainer.rollMax.perc:SetPoint("LEFT", f.DKPTab1.RollContainer.rollMax, "RIGHT", -15, 0);
		f.DKPTab1.RollContainer.rollMax.perc:SetText("%")
		f.DKPTab1.RollContainer.rollMax.perc:SetShown(MonDKP_DB.modes.rolls.UsePerc);

	    -- Percent Rolls Checkbox
		f.DKPTab1.RollContainer.UsePerc = CreateFrame("CheckButton", nil, f.DKPTab1.RollContainer, "UICheckButtonTemplate");
		f.DKPTab1.RollContainer.UsePerc:SetChecked(MonDKP_DB.modes.rolls.UsePerc)
		f.DKPTab1.RollContainer.UsePerc:SetScale(0.6);
		f.DKPTab1.RollContainer.UsePerc.text:SetText("  |cff5151de"..L["USEPERCENTAGE"].."|r");
		f.DKPTab1.RollContainer.UsePerc.text:SetScale(1.5);
		f.DKPTab1.RollContainer.UsePerc.text:SetFontObject("MonDKPSmallLeft")
		f.DKPTab1.RollContainer.UsePerc:SetPoint("TOP", f.DKPTab1.RollContainer.rollMin, "BOTTOMLEFT", 0, -10);
		f.DKPTab1.RollContainer.UsePerc:SetScript("OnClick", function(self)
			MonDKP_DB.modes.rolls.UsePerc = self:GetChecked();
			f.DKPTab1.RollContainer.rollMin.perc:SetShown(self:GetChecked())
			f.DKPTab1.RollContainer.rollMax.perc:SetShown(self:GetChecked())
			if f.DKPTab1.RollContainer.rollMax:GetNumber() == 0 then
				f.DKPTab1.RollContainer.rollMax:SetNumber(100)
			end
			PlaySound(808);
		end)
		f.DKPTab1.RollContainer.UsePerc:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			GameTooltip:SetText(L["USEPERCFORROLLS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["USEPERCROLLSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["USEPERCROLLSTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		f.DKPTab1.RollContainer.UsePerc:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

    	-- Add to Max Editbox
		f.DKPTab1.RollContainer.AddMax = CreateFrame("EditBox", nil, f.DKPTab1.RollContainer)
	    f.DKPTab1.RollContainer.AddMax:SetAutoFocus(false)
	    f.DKPTab1.RollContainer.AddMax:SetMultiLine(false)
	    f.DKPTab1.RollContainer.AddMax:SetPoint("TOP", f.DKPTab1.RollContainer.rollMax, "BOTTOM", 0, -30)
	    f.DKPTab1.RollContainer.AddMax:SetSize(70, 24)
	    f.DKPTab1.RollContainer.AddMax:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.DKPTab1.RollContainer.AddMax:SetBackdropColor(0,0,0,0.9)
	    f.DKPTab1.RollContainer.AddMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.DKPTab1.RollContainer.AddMax:SetMaxLetters(6)
	    f.DKPTab1.RollContainer.AddMax:SetTextColor(1, 1, 1, 1)
	    f.DKPTab1.RollContainer.AddMax:SetFontObject("MonDKPSmallRight")
	    f.DKPTab1.RollContainer.AddMax:SetTextInsets(10, 15, 5, 5)
	    f.DKPTab1.RollContainer.AddMax:SetText(MonDKP_DB.modes.rolls.AddToMax)
	    f.DKPTab1.RollContainer.AddMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()
	      	self:ClearFocus()
	    end)
	    f.DKPTab1.RollContainer.AddMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()
	      	f.DKPTab1.RollContainer.rollMin:SetFocus()
	    end)
	    f.DKPTab1.RollContainer.AddMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()
	      	self:ClearFocus()
	    end)
	    f.DKPTab1.RollContainer.AddMax:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["ADDTOMAXROLL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ADDTOMAXROLLTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["ADDTOMAXROLLTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.DKPTab1.RollContainer.AddMax:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Add to Max Header
	    f.DKPTab1.RollContainer.AddMax.Header = f.DKPTab1.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
	    f.DKPTab1.RollContainer.AddMax.Header:SetFontObject("MonDKPSmallRight");
	    f.DKPTab1.RollContainer.AddMax.Header:SetPoint("RIGHT", f.DKPTab1.RollContainer.AddMax, "LEFT", -5, 0);
	    f.DKPTab1.RollContainer.AddMax.Header:SetText(L["ADDTOMAXROLL"]..": ")

	-- Broadcast DKP Modes Button
	f.DKPTab1.BroadcastSettings = self:CreateButton("BOTTOMRIGHT", f.DKPTab1, "BOTTOMRIGHT", -30, 30, L["BROADCASTSETTINGS"]);
	f.DKPTab1.BroadcastSettings:SetSize(110,25)
	f.DKPTab1.BroadcastSettings:SetScript("OnClick", function()
		MonDKP_DB.modes.rolls.min = f.DKPTab1.RollContainer.rollMin:GetNumber()
		MonDKP_DB.modes.rolls.max = f.DKPTab1.RollContainer.rollMax:GetNumber()	
		MonDKP_DB.modes.rolls.AddToMax = f.DKPTab1.RollContainer.AddMax:GetNumber()	

		if (MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max and MonDKP_DB.modes.rolls.max ~= 0 and MonDKP_DB.modes.rolls.UserPerc == false) or (MonDKP_DB.modes.rolls.UsePerc and (MonDKP_DB.modes.rolls.min < 0 or MonDKP_DB.modes.rolls.max > 100 or MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max)) then
			StaticPopupDialogs["NOTIFY_ROLLS"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["INVALIDROLLRANGE"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("NOTIFY_ROLLS")
			return;
		end

		StaticPopupDialogs["SEND_MODES"] = {
			text = L["AREYOUSUREBROADCAST"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				local temptable1 = {}
				table.insert(temptable1, MonDKP_DB.modes)
				table.insert(temptable1, MonDKP_DB.DKPBonus)
				table.insert(temptable1, MonDKP_DB.raiders)
				MonDKP.Sync:SendData("MonDKPModes", temptable1)
				MonDKP:Print(L["DKPMODESENTCONF"])
				local temptable2 = {}
	            table.insert(temptable2, MonDKP_DB.MinBidBySlot)
	            table.insert(temptable2, MonDKP_MinBids)
	            MonDKP.Sync:SendData("MonDKPMinBids", temptable2)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("SEND_MODES")
	end);
	f.DKPTab1.BroadcastSettings:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["BROADCASTSETTINGS"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["BROADCASTSETTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show()
	end)
	f.DKPTab1.BroadcastSettings:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)