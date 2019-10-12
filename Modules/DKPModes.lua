local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

function MonDKP:ToggleDKPModesWindow()
	if core.IsOfficer == true then
		core.ModesWindow = core.ModesWindow or MonDKP:DKPModesFrame_Create();
	 	core.ModesWindow:SetShown(not core.ModesWindow:IsShown())
	 	core.ModesWindow:SetFrameLevel(10)
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
		if MonDKP.UIConfig then MonDKP.UIConfig:SetFrameLevel(2) end
	else
		MonDKP:Print(L["NoPermission"])
	end
end

function MonDKP:DKPModesFrame_Create()
	local f = CreateFrame("Frame", "MonDKP_DKPModesFrame", UIParent, "ShadowOverlaySmallTemplate");
	local ActiveMode = MonDKP_DB.modes.mode;
	local ActiveCostType = MonDKP_DB.modes.costvalue;

	if not core.IsOfficer then
		MonDKP:Print(L["NoPermission"])
		return
	end

	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetClampedToScreen(true)
	f:SetSize(475, 600);
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(5)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", f.StopMovingOrSizing);
	f:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
		if MonDKP.UIConfig then MonDKP.UIConfig:SetFrameLevel(2) end
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	-- Close Button
	f.closeContainer = CreateFrame("Frame", "MonDKModesWindowCloseButtonContainer", f)
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)
	f:Hide()

	f.ModeDescriptionHeader = f:CreateFontString(nil, "OVERLAY")
	f.ModeDescriptionHeader:SetFontObject("MonDKPLargeLeft");
	f.ModeDescriptionHeader:SetWidth(400);
	f.ModeDescriptionHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -20);

	f.ModeDescription = f:CreateFontString(nil, "OVERLAY")
	f.ModeDescription:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -45);
	f.ModeDescription:SetWidth(400);
	f.ModeDescription:SetFontObject("MonDKPSmallLeft")
	
	local MinBidDescription = L["MinBidDescription"]
	local StaticDescription = L["StaticDescription"]
	local RollDescription = L["RollDescription"]
	local ZeroSumDescription = L["ZeroSumDescription"];

	if MonDKP_DB.modes.mode == "Minimum Bid Values" then
		f.ModeDescriptionHeader:SetText(L["MinBidValuesHead"])
		f.ModeDescription:SetText(MinBidDescription)
	elseif MonDKP_DB.modes.mode == "Static Item Values" then
		f.ModeDescriptionHeader:SetText(L["StaticItemValuesHead"])
		f.ModeDescription:SetText(StaticDescription)
	elseif MonDKP_DB.modes.mode == "Roll Based Bidding" then
		f.ModeDescriptionHeader:SetText(L["RollBiddingHead"])
		f.ModeDescription:SetText(RollDescription)
	elseif MonDKP_DB.modes.mode == "Zero Sum" then
		f.ModeDescriptionHeader:SetText(L["ZeroSumHead"])
		f.ModeDescription:SetText(ZeroSumDescription)
	end

	-- Mode DROPDOWN box 
	local CurMode = MonDKP_DB.modes.mode;
	local LocalMode;

	if CurMode == "Minimum Bid Values" then
		LocalMode = L["MinBidValuesHead"];
	elseif CurMode == "Static Item Values" then
		LocalMode = L["StaticItemValuesHead"]
	elseif CurMode == "Roll Based Bidding" then
		LocalMode = L["RollBiddingHead"]
	elseif CurMode == "Zero Sum" then
		LocalMode = L["ZeroSumHead"]
	end


	f.ModesDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.ModesDropDown:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -200)
	UIDropDownMenu_SetWidth(f.ModesDropDown, 150)
	UIDropDownMenu_SetText(f.ModesDropDown, LocalMode)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.ModesDropDown, function(self, level, menuList)
	local DKPMode = UIDropDownMenu_CreateInfo()
		DKPMode.func = self.SetValue
		DKPMode.fontObject = "MonDKPSmallCenter"
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["MinBidValuesHead"], "Minimum Bid Values", "Minimum Bid Values" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["StaticItemValuesHead"], "Static Item Values", "Static Item Values" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["RollBiddingHead"], "Roll Based Bidding", "Roll Based Bidding" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["ZeroSumHead"], "Zero Sum", "Zero Sum" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
	end)

	-- Dropdown Menu Function
	function f.ModesDropDown:SetValue(newValue)
		if curMode ~= newValue then CurMode = newValue end

		f.ModeDescriptionHeader:SetText(newValue)
		
		if newValue == "Minimum Bid Values" then
			MonDKP_DB.modes.mode = "Minimum Bid Values";
			f.ModeDescription:SetText(MinBidDescription)
			f.ItemCostDropDown:Hide();
			f.ItemCostHeader:Hide();
			f.MaxBid:Show();
			f.MaxBid.Header:Show();
			MonDKP_DB.modes.costvalue = "Integer";
			UIDropDownMenu_SetText(f.ItemCostDropDown, "Integer")
			f.SubZeroBidding:Show();
			f.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
			if MonDKP_DB.modes.SubZeroBidding == true then
				f.AllowNegativeBidders:Show()
				f.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
			end
			f.RollContainer:Hide();
			f.ZeroSumType:Hide();
			f.ZeroSumTypeHeader:Hide();
			f.CostSelection:Show();
			f.CostSelectionHeader:Show();
			f.Inflation:Hide()
    		f.Inflation.Header:Hide()
		elseif newValue == "Static Item Values" then
			MonDKP_DB.modes.mode = "Static Item Values"
			f.ModeDescription:SetText(StaticDescription)
			f.ItemCostHeader:Show();
			f.ItemCostDropDown:Show();
			f.RollContainer:Hide()
			f.MaxBid:Hide();
			f.MaxBid.Header:Hide();
			f.ZeroSumType:Hide()
			f.ZeroSumTypeHeader:Hide();
			f.CostSelection:Hide();
			f.CostSelectionHeader:Hide();
			f.Inflation:Hide()
    		f.Inflation.Header:Hide()

			if MonDKP_DB.modes.costvalue == "Integer" then
				f.SubZeroBidding:Show()
				f.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
				if MonDKP_DB.modes.SubZeroBidding == true then
					f.AllowNegativeBidders:Show()
					f.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
				end
				UIDropDownMenu_SetText(f.ItemCostDropDown, "Integer")
			end
		elseif newValue == "Roll Based Bidding" then
			MonDKP_DB.modes.mode = "Roll Based Bidding"
			f.ItemCostHeader:Show();
			f.ItemCostDropDown:Show();
			f.ModeDescription:SetText(RollDescription)
			f.RollContainer:Show()
			f.MaxBid:Hide();
			f.MaxBid.Header:Hide();
			f.ZeroSumType:Hide()
			f.ZeroSumTypeHeader:Hide();
			f.CostSelection:Hide()
			f.CostSelectionHeader:Hide()
			f.Inflation:Hide()
    		f.Inflation.Header:Hide()

			if MonDKP_DB.modes.costvalue == "Integer" then
				f.SubZeroBidding:Show()
				f.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
				if MonDKP_DB.modes.SubZeroBidding == true then
					f.AllowNegativeBidders:Show()
					f.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
				end
				UIDropDownMenu_SetText(f.ItemCostDropDown, "Integer")
			end
		elseif newValue == "Zero Sum" then
			MonDKP_DB.modes.mode = "Zero Sum"
			MonDKP_DB.modes.costvalue = "Integer"
			f.ModeDescription:SetText(ZeroSumDescription)
			f.SubZeroBidding:Hide()
			f.AllowNegativeBidders:Hide()
			f.RollContainer:Hide()
			f.ItemCostHeader:Hide();
			UIDropDownMenu_SetText(f.ItemCostDropDown, "Integer")
			f.ItemCostDropDown:Hide();
			f.ZeroSumType:Show()
			f.ZeroSumTypeHeader:Show();
			MonDKP_DB.modes.SubZeroBidding = true
			f.Inflation:Show()
    		f.Inflation.Header:Show()

			if MonDKP_DB.modes.ZeroSumBidType == "Static" then
				f.MaxBid:Hide();
				f.MaxBid.Header:Hide();
				f.CostSelection:Hide()
				f.CostSelectionHeader:Hide()
			else
				f.MaxBid:Show()
				f.MaxBid.Header:Show();
				f.CostSelection:Show()
				f.CostSelectionHeader:Show()
				f.SubZeroBidding:Show()
				f.AllowNegativeBidders:Show()
			end
		end

		if CurMode == "Minimum Bid Values" then
			LocalMode = L["MinBidValuesHead"];
		elseif CurMode == "Static Item Values" then
			LocalMode = L["StaticItemValuesHead"]
		elseif CurMode == "Roll Based Bidding" then
			LocalMode = L["RollBiddingHead"]
		elseif CurMode == "Zero Sum" then
			LocalMode = L["ZeroSumHead"]
		end

		UIDropDownMenu_SetText(f.ModesDropDown, LocalMode)
		CloseDropDownMenus()
	end

	f.ModesDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DKPModes"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DKPModesTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.ModesDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.ModeHeader = f:CreateFontString(nil, "OVERLAY")
	f.ModeHeader:SetPoint("BOTTOMLEFT", f.ModesDropDown, "TOPLEFT", 25, 0);
	f.ModeHeader:SetFontObject("MonDKPSmallLeft")
	f.ModeHeader:SetText(L["DKPModes"])

	-- Rounding DROPDOWN box 
	f.RoundDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.RoundDropDown:SetPoint("TOPLEFT", f.ModesDropDown, "BOTTOMLEFT", 0, -95)
	UIDropDownMenu_SetWidth(f.RoundDropDown, 80)
	UIDropDownMenu_SetText(f.RoundDropDown, MonDKP_DB.modes.rounding)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.RoundDropDown, function(self, level, menuList)
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
	function f.RoundDropDown:SetValue(newValue)
		MonDKP_DB.modes.rounding = newValue;
		UIDropDownMenu_SetText(f.RoundDropDown, newValue)
		CloseDropDownMenus()
	end

	f.RoundDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	f.RoundDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DKPRounding"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DKPRoundingTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.RoundDropDown:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

	f.RoundHeader = f:CreateFontString(nil, "OVERLAY")
	f.RoundHeader:SetPoint("BOTTOMLEFT", f.RoundDropDown, "TOPLEFT", 25, 0);
	f.RoundHeader:SetFontObject("MonDKPSmallLeft")
	f.RoundHeader:SetText(L["DKPRounding"])

	-- Channels DROPDOWN box 
	f.ChannelsDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.ChannelsDropDown:SetPoint("LEFT", f.ModesDropDown, "RIGHT", 30, 0)
	UIDropDownMenu_SetWidth(f.ChannelsDropDown, 150)
	UIDropDownMenu_SetText(f.ChannelsDropDown, L["OpenChannels"])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.ChannelsDropDown, function(self, level, menuList)
	local OpenChannel = UIDropDownMenu_CreateInfo()
		OpenChannel.func = self.SetValue
		OpenChannel.fontObject = "MonDKPSmallCenter"
		OpenChannel.keepShownOnClick = true;
		OpenChannel.isNotRadio = true;
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["Whisper"], "Whisper", true == MonDKP_DB.modes.channels.whisper
		UIDropDownMenu_AddButton(OpenChannel)
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["Raid"], "Raid", true == MonDKP_DB.modes.channels.raid
		UIDropDownMenu_AddButton(OpenChannel)
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["Guild"], "Guild", true == MonDKP_DB.modes.channels.guild
		UIDropDownMenu_AddButton(OpenChannel)
	end)

	-- Dropdown Menu Function
	function f.ChannelsDropDown:SetValue(arg1)
		if arg1 == "Whisper" then
			MonDKP_DB.modes.channels.whisper = not MonDKP_DB.modes.channels.whisper
		elseif arg1 == "Raid" then
			MonDKP_DB.modes.channels.raid = not MonDKP_DB.modes.channels.raid
		elseif arg1 == "Guild" then
			MonDKP_DB.modes.channels.guild = not MonDKP_DB.modes.channels.guild
		end

		UIDropDownMenu_SetText(f.ChannelsDropDown, "Open Channels")
		CloseDropDownMenus()
	end

	f.ChannelsDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CommandChannels"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["CommandChannelsTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.ChannelsDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.ChannelsHeader = f:CreateFontString(nil, "OVERLAY")
	f.ChannelsHeader:SetPoint("BOTTOMLEFT", f.ChannelsDropDown, "TOPLEFT", 25, 0);
	f.ChannelsHeader:SetFontObject("MonDKPSmallLeft")
	f.ChannelsHeader:SetText(L["CommandChannels"])

	-- Cost Auto Update Value DROPDOWN box 
	if not MonDKP_DB.modes.CostSelection then MonDKP_DB.modes.CostSelection = "Second Bidder" end
	f.CostSelection = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.CostSelection:SetPoint("TOPLEFT", f.ChannelsDropDown, "BOTTOMLEFT", 0, -10)

	local LocalCostSel;

	if MonDKP_DB.modes.CostSelection == "First Bidder" then
		LocalCostSel = L["FirstBidder"]
	elseif MonDKP_DB.modes.CostSelection == "Second Bidder" then
		LocalCostSel = L["SecondBidder"]
	end

	UIDropDownMenu_SetWidth(f.CostSelection, 150)
	UIDropDownMenu_SetText(f.CostSelection, LocalCostSel)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.CostSelection, function(self, level, menuList)
	local CostSelect = UIDropDownMenu_CreateInfo()
		CostSelect.func = self.SetValue
		CostSelect.fontObject = "MonDKPSmallCenter"
		CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["FirstBidder"], "First Bidder", "First Bidder" == MonDKP_DB.modes.CostSelection, false
		UIDropDownMenu_AddButton(CostSelect)
		CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["SecondBidder"], "Second Bidder", "Second Bidder" == MonDKP_DB.modes.CostSelection, false
		UIDropDownMenu_AddButton(CostSelect)
	end)

	-- Dropdown Menu Function
	function f.CostSelection:SetValue(arg1)
		MonDKP_DB.modes.CostSelection = arg1

		if arg1 == "First Bidder" then
			LocalCostSel = L["FirstBidder"]
		else
			LocalCostSel = L["SecondBidder"]
		end

		UIDropDownMenu_SetText(f.CostSelection, LocalCostSel)
		CloseDropDownMenus()
	end

	f.CostSelection:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CostAutoUpdate"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["CostAutoUpdateTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.CostSelection:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.CostSelectionHeader = f:CreateFontString(nil, "OVERLAY")
	f.CostSelectionHeader:SetPoint("BOTTOMLEFT", f.CostSelection, "TOPLEFT", 25, 0);
	f.CostSelectionHeader:SetFontObject("MonDKPSmallLeft")
	f.CostSelectionHeader:SetText(L["CostAutoUpdateValue"])

	if not (MonDKP_DB.modes.mode == "Minimum Bid Values" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid")) then
		f.CostSelection:Hide()
		f.CostSelectionHeader:Hide();
	end

	-- Artificial Inflation Editbox
	if not MonDKP_DB.modes.Inflation then MonDKP_DB.modes.Inflation = 0 end
	f.Inflation = CreateFrame("EditBox", nil, f)
    f.Inflation:SetAutoFocus(false)
    f.Inflation:SetMultiLine(false)
    f.Inflation:SetPoint("TOPLEFT", f.CostSelection, "BOTTOMLEFT", 20, -15)
    f.Inflation:SetSize(100, 24)
    f.Inflation:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.Inflation:SetBackdropColor(0,0,0,0.9)
    f.Inflation:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.Inflation:SetMaxLetters(8)
    f.Inflation:SetTextColor(1, 1, 1, 1)
    f.Inflation:SetFontObject("MonDKPSmallRight")
    f.Inflation:SetTextInsets(10, 15, 5, 5)
    f.Inflation:SetText(MonDKP_DB.modes.Inflation)
    f.Inflation:Hide();
    f.Inflation:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.Inflation = f.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.Inflation:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.Inflation = f.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.Inflation:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.Inflation = f.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.Inflation:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ArtificialInflation"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ArtInflatTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.Inflation:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    -- Min Roll Header
    f.Inflation.Header = f.Inflation:CreateFontString(nil, "OVERLAY")
    f.Inflation.Header:SetFontObject("MonDKPNormalLeft");
    f.Inflation.Header:SetPoint("BOTTOM", f.Inflation, "TOP", -20, 2);
    f.Inflation.Header:SetText(L["Inflation"])

    if MonDKP_DB.modes.mode == "Zero Sum" then
    	f.Inflation:Show()
    	f.Inflation.Header:Show()
    end

    -- ZeroSum Type DROPDOWN box 
	f.ZeroSumType = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.ZeroSumType:SetPoint("TOPLEFT", f.Inflation, "BOTTOMLEFT", -20, -20)
	UIDropDownMenu_SetWidth(f.ZeroSumType, 150)
	UIDropDownMenu_SetText(f.ZeroSumType, MonDKP_DB.modes.ZeroSumBidType)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.ZeroSumType, function(self, level, menuList)
	local BidType = UIDropDownMenu_CreateInfo()
		BidType.func = self.SetValue
		BidType.fontObject = "MonDKPSmallCenter"
		BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["Static"], "Static", "Static" == MonDKP_DB.modes.ZeroSumBidType, false
		UIDropDownMenu_AddButton(BidType)
		BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["MinimumBid"], "Minimum Bid", "Minimum Bid" == MonDKP_DB.modes.ZeroSumBidType, false
		UIDropDownMenu_AddButton(BidType)
	end)

	-- Dropdown Menu Function
	function f.ZeroSumType:SetValue(newValue)
		MonDKP_DB.modes.ZeroSumBidType = newValue;
		if newValue == "Static" then
			f.MaxBid:Hide();
			f.MaxBid.Header:Hide();
			f.CostSelection:Hide();
			f.CostSelectionHeader:Hide();
			newValue = L["Static"]
			f.SubZeroBidding:Hide()
			f.AllowNegativeBidders:Hide()
		else
			f.MaxBid:Show();
			f.MaxBid.Header:Show();
			f.CostSelection:Show();
			f.CostSelectionHeader:Show();
			newValue = L["MinimumBid"]
			f.SubZeroBidding:Show()
			f.AllowNegativeBidders:Show()
		end

		UIDropDownMenu_SetText(f.ZeroSumType, newValue)
		CloseDropDownMenus()
	end

	f.ZeroSumType:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ZeroSumItemCost"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ZeroSumItemCostTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.ZeroSumType:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.ZeroSumTypeHeader = f:CreateFontString(nil, "OVERLAY")
	f.ZeroSumTypeHeader:SetPoint("BOTTOMLEFT", f.ZeroSumType, "TOPLEFT", 25, 0);
	f.ZeroSumTypeHeader:SetFontObject("MonDKPSmallLeft")
	f.ZeroSumTypeHeader:SetText(L["BidMethod"])

	if MonDKP_DB.modes.mode ~= "Zero Sum" then
		f.ZeroSumType:Hide()
		f.ZeroSumTypeHeader:Hide();
	end

	-- Item Cost Value DROPDOWN box 
	f.ItemCostDropDown = CreateFrame("FRAME", "MonDKPModeSelectDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.ItemCostDropDown:SetPoint("TOPLEFT", f.ModesDropDown, "BOTTOMLEFT", 0, -50)
	UIDropDownMenu_SetWidth(f.ItemCostDropDown, 150)
	UIDropDownMenu_SetText(f.ItemCostDropDown, L[MonDKP_DB.modes.costvalue])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.ItemCostDropDown, function(self, level, menuList)
	local CostValue = UIDropDownMenu_CreateInfo()
		CostValue.func = self.SetValue
		CostValue.fontObject = "MonDKPSmallCenter"
		CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["Integer"], "Integer", "Integer" == MonDKP_DB.modes.costvalue, false
		UIDropDownMenu_AddButton(CostValue)
		CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["Percent"], "Percent", "Percent" == MonDKP_DB.modes.costvalue, false
		UIDropDownMenu_AddButton(CostValue)
	end)

	-- Dropdown Menu Function
	function f.ItemCostDropDown:SetValue(arg1)
		if arg1 == "Integer" then
			MonDKP_DB.modes.costvalue = "Integer"
			f.SubZeroBidding:Show()
			f.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
			if MonDKP_DB.modes.SubZeroBidding == true then
				f.AllowNegativeBidders:Show()
				f.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
			end
		elseif arg1 == "Percent" then
			MonDKP_DB.modes.costvalue = "Percent"
			f.SubZeroBidding:Hide()
			f.AllowNegativeBidders:Hide()
			MonDKP_DB.modes.SubZeroBidding = false;
			f.SubZeroBidding:SetChecked(false)
		end

		UIDropDownMenu_SetText(f.ItemCostDropDown, L[arg1])
		CloseDropDownMenus()
	end

	f.ItemCostDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ItemCostTypes"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ItemCostTypesTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.ItemCostDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.ItemCostHeader = f:CreateFontString(nil, "OVERLAY")
	f.ItemCostHeader:SetPoint("BOTTOMLEFT", f.ItemCostDropDown, "TOPLEFT", 25, 0);
	f.ItemCostHeader:SetFontObject("MonDKPSmallLeft")
	f.ItemCostHeader:SetText(L["ItemCostTypes"])

	if MonDKP_DB.modes.mode == "Minimum Bid Values" then
		f.ItemCostDropDown:Hide();
		f.ItemCostHeader:Hide();
		MonDKP_DB.modes.costvalue = "Integer";
	elseif MonDKP_DB.modes.mode == "Zero Sum" then
		f.ItemCostDropDown:Hide();
		f.ItemCostHeader:Hide();
		MonDKP_DB.modes.costvalue = "Integer";
	end


	-- Min Roll Editbox
	if not MonDKP_DB.modes.MaximumBid then MonDKP_DB.modes.MaximumBid = 0 end
	f.MaxBid = CreateFrame("EditBox", nil, f)
    f.MaxBid:SetAutoFocus(false)
    f.MaxBid:SetMultiLine(false)
    f.MaxBid:SetPoint("TOPLEFT", f.ModesDropDown, "BOTTOMLEFT", 18, -55)
    f.MaxBid:SetSize(100, 24)
    f.MaxBid:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.MaxBid:SetBackdropColor(0,0,0,0.9)
    f.MaxBid:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.MaxBid:SetMaxLetters(8)
    f.MaxBid:SetTextColor(1, 1, 1, 1)
    f.MaxBid:SetFontObject("MonDKPSmallRight")
    f.MaxBid:SetTextInsets(10, 15, 5, 5)
    f.MaxBid:SetText(MonDKP_DB.modes.MaximumBid)
    f.MaxBid:Hide();
    f.MaxBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.MaximumBid = f.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.MaxBid:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.MaximumBid = f.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.MaxBid:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	MonDKP_DB.modes.MaximumBid = f.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.MaxBid:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["MaximumBid"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["MaximumBidTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.MaxBid:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    -- Min Roll Header
    f.MaxBid.Header = f.MaxBid:CreateFontString(nil, "OVERLAY")
    f.MaxBid.Header:SetFontObject("MonDKPNormalLeft");
    f.MaxBid.Header:SetPoint("BOTTOM", f.MaxBid, "TOP", -8, 2);
    f.MaxBid.Header:SetText(L["MaximumBid"])


    if MonDKP_DB.modes.mode == "Minimum Bid Values" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		f.MaxBid:Show();
		f.MaxBid.Header:Show();
	end

	-- Sub Zero Bidding Checkbox
	f.SubZeroBidding = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.SubZeroBidding:SetChecked(MonDKP_DB.modes.SubZeroBidding)
	f.SubZeroBidding:SetScale(0.6);
	f.SubZeroBidding.text:SetText("  |cff5151de"..L["SubZeroBidding"].."|r");
	f.SubZeroBidding.text:SetScale(1.5);
	f.SubZeroBidding.text:SetFontObject("MonDKPSmallLeft")
	f.SubZeroBidding:SetPoint("TOP", f.ModesDropDown, "BOTTOMLEFT", 60, 0);
	f.SubZeroBidding:SetScript("OnClick", function(self)
		if not MonDKP_DB.modes.SubZeroBidding then MonDKP_DB.modes.SubZeroBidding = false end
		if self:GetChecked() == true then
			MonDKP_DB.modes.SubZeroBidding = true;
			MonDKP:Print("Sub Zero Bidding |cff00ff00"..L["Enabled"].."|r")
			f.AllowNegativeBidders:Show()
			f.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
		else
			MonDKP_DB.modes.SubZeroBidding = false;
			MonDKP:Print("Sub Zero Bidding |cffff0000"..L["Disabled"].."|r")
			MonDKP_DB.modes.AllowNegativeBidders = false
			f.AllowNegativeBidders:Hide()
		end
		PlaySound(808);
	end)
	f.SubZeroBidding:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SubZeroBidding"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SubZeroBiddingTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.SubZeroBidding:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	if MonDKP_DB.modes.costvalue == "Percent" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		f.SubZeroBidding:Hide()
	end
	
	-- Allow Bids below zero Checkbox
	f.AllowNegativeBidders = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.AllowNegativeBidders:SetChecked(MonDKP_DB.modes.AllowNegativeBidders)
	f.AllowNegativeBidders:SetScale(0.6);
	f.AllowNegativeBidders.text:SetText("  |cff5151de"..L["AllowNegativeBidders"].."|r");
	f.AllowNegativeBidders.text:SetScale(1.5);
	f.AllowNegativeBidders.text:SetFontObject("MonDKPSmallLeft")
	f.AllowNegativeBidders:SetPoint("TOPLEFT", f.SubZeroBidding, "BOTTOMLEFT", 0, 0);
	f.AllowNegativeBidders:SetScript("OnClick", function(self)
		if not MonDKP_DB.modes.AllowNegativeBidders then MonDKP_DB.modes.AllowNegativeBidders = false end
		if self:GetChecked() == true then
			MonDKP_DB.modes.AllowNegativeBidders = true;
			MonDKP:Print("Allow Negative Bidders |cff00ff00"..L["Enabled"].."|r")
		else
			MonDKP_DB.modes.AllowNegativeBidders = false;
			MonDKP:Print("Allow Negative Bidders |cffff0000"..L["Disabled"].."|r")
		end
		PlaySound(808);
	end)
	f.AllowNegativeBidders:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["AllowNegativeBidders"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["AllowNegativeBidTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.AllowNegativeBidders:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	if (MonDKP_DB.modes.costvalue == "Percent" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static")) or MonDKP_DB.modes.SubZeroBidding == false then
		f.AllowNegativeBidders:Hide()
	end


	-- Roll Container
	f.RollContainer = CreateFrame("Frame", nil, f);
	f.RollContainer:SetSize(210, 150);
	f.RollContainer:SetPoint("TOPLEFT", f.ChannelsDropDown, "BOTTOMLEFT", -10, -20)
	f.RollContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
	f.RollContainer:SetBackdropColor(0,0,0,0.9)
	f.RollContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	f.RollContainer:Hide();
    if MonDKP_DB.modes.mode == "Roll Based Bidding" then
    	f.RollContainer:Show()
    end

	-- Roll Container Header
    f.RollContainer.Header = f.RollContainer:CreateFontString(nil, "OVERLAY")
    f.RollContainer.Header:SetFontObject("MonDKPLargeLeft");
    f.RollContainer.Header:SetScale(0.6)
    f.RollContainer.Header:SetPoint("TOPLEFT", f.RollContainer, "TOPLEFT", 15, -15);
    f.RollContainer.Header:SetText(L["RollSettings"])


		-- Min Roll Editbox
		f.RollContainer.rollMin = CreateFrame("EditBox", nil, f.RollContainer)
	    f.RollContainer.rollMin:SetAutoFocus(false)
	    f.RollContainer.rollMin:SetMultiLine(false)
	    f.RollContainer.rollMin:SetPoint("TOPLEFT", f.RollContainer, "TOPLEFT", 20, -50)
	    f.RollContainer.rollMin:SetSize(70, 24)
	    f.RollContainer.rollMin:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.RollContainer.rollMin:SetBackdropColor(0,0,0,0.9)
	    f.RollContainer.rollMin:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.RollContainer.rollMin:SetMaxLetters(6)
	    f.RollContainer.rollMin:SetTextColor(1, 1, 1, 1)
	    f.RollContainer.rollMin:SetFontObject("MonDKPSmallRight")
	    f.RollContainer.rollMin:SetTextInsets(10, 15, 5, 5)
	    f.RollContainer.rollMin:SetText(MonDKP_DB.modes.rolls.min)
	    f.RollContainer.rollMin:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()
	    	self:ClearFocus()
	    end)
	    f.RollContainer.rollMin:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()
	      	f.RollContainer.rollMax:SetFocus()
	    end)
	    f.RollContainer.rollMin:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()	
	    	self:ClearFocus()
	    end)
	    f.RollContainer.rollMin:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MinimumRoll"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["MinimumRollTTDesc"], 1.0, 1.0, 1.0, true);
			--GameTooltip:AddLine("The state of this option will persist indefinitely until manually disabled/enabled.", 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.RollContainer.rollMin:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Min Roll Header
	    f.RollContainer.rollMin.Header = f.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
	    f.RollContainer.rollMin.Header:SetFontObject("MonDKPNormalLeft");
	    f.RollContainer.rollMin.Header:SetPoint("BOTTOM", f.RollContainer.rollMin, "TOP", -20, 2);
	    f.RollContainer.rollMin.Header:SetText(L["Min"])

	    -- Dash Between Rolls
	    f.RollContainer.dash = f.RollContainer:CreateFontString(nil, "OVERLAY")
	    f.RollContainer.dash:SetFontObject("MonDKPLargeLeft");
	    f.RollContainer.dash:SetPoint("LEFT", f.RollContainer.rollMin, "RIGHT", 9, 0);
	    f.RollContainer.dash:SetText("-")

	    -- Max Roll Editbox
		f.RollContainer.rollMax = CreateFrame("EditBox", nil, f.RollContainer)
	    f.RollContainer.rollMax:SetAutoFocus(false)
	    f.RollContainer.rollMax:SetMultiLine(false)
	    f.RollContainer.rollMax:SetPoint("LEFT", f.RollContainer.rollMin, "RIGHT", 24, 0)
	    f.RollContainer.rollMax:SetSize(70, 24)
	    f.RollContainer.rollMax:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.RollContainer.rollMax:SetBackdropColor(0,0,0,0.9)
	    f.RollContainer.rollMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.RollContainer.rollMax:SetMaxLetters(6)
	    f.RollContainer.rollMax:SetTextColor(1, 1, 1, 1)
	    f.RollContainer.rollMax:SetFontObject("MonDKPSmallRight")
	    f.RollContainer.rollMax:SetTextInsets(10, 15, 5, 5)
	    f.RollContainer.rollMax:SetText(MonDKP_DB.modes.rolls.max)
	    f.RollContainer.rollMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()	
	    	self:ClearFocus()
	    end)
	    f.RollContainer.rollMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	      	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()	
	    	f.RollContainer.AddMax:SetFocus()
	    end)
	    f.RollContainer.rollMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()	
	    	self:ClearFocus()
	    end)
	    f.RollContainer.rollMax:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MaximumRoll"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["MaximumRollTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["MaximumRollTTWarn"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.RollContainer.rollMax:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Max Roll Header
	    f.RollContainer.rollMax.Header = f.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
	    f.RollContainer.rollMax.Header:SetFontObject("MonDKPNormalLeft");
	    f.RollContainer.rollMax.Header:SetPoint("BOTTOM", f.RollContainer.rollMax, "TOP", -20, 2);
	    f.RollContainer.rollMax.Header:SetText(L["Max"])

		f.RollContainer.rollMin.perc = f.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
		f.RollContainer.rollMin.perc:SetFontObject("MonDKPSmallLeft");
		f.RollContainer.rollMin.perc:SetPoint("LEFT", f.RollContainer.rollMin, "RIGHT", -15, 0);
		f.RollContainer.rollMin.perc:SetText("%")
		f.RollContainer.rollMin.perc:SetShown(MonDKP_DB.modes.rolls.UsePerc);

		f.RollContainer.rollMax.perc = f.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
		f.RollContainer.rollMax.perc:SetFontObject("MonDKPSmallLeft");
		f.RollContainer.rollMax.perc:SetPoint("LEFT", f.RollContainer.rollMax, "RIGHT", -15, 0);
		f.RollContainer.rollMax.perc:SetText("%")
		f.RollContainer.rollMax.perc:SetShown(MonDKP_DB.modes.rolls.UsePerc);

	    -- Percent Rolls Checkbox
		f.RollContainer.UsePerc = CreateFrame("CheckButton", nil, f.RollContainer, "UICheckButtonTemplate");
		f.RollContainer.UsePerc:SetChecked(MonDKP_DB.modes.rolls.UsePerc)
		f.RollContainer.UsePerc:SetScale(0.6);
		f.RollContainer.UsePerc.text:SetText("  |cff5151deUse Percentage|r");
		f.RollContainer.UsePerc.text:SetScale(1.5);
		f.RollContainer.UsePerc.text:SetFontObject("MonDKPSmallLeft")
		f.RollContainer.UsePerc:SetPoint("TOP", f.RollContainer.rollMin, "BOTTOMLEFT", 0, -10);
		f.RollContainer.UsePerc:SetScript("OnClick", function(self)
			MonDKP_DB.modes.rolls.UsePerc = self:GetChecked();
			f.RollContainer.rollMin.perc:SetShown(self:GetChecked())
			f.RollContainer.rollMax.perc:SetShown(self:GetChecked())
			if f.RollContainer.rollMax:GetNumber() == 0 then
				f.RollContainer.rollMax:SetNumber(100)
			end
			PlaySound(808);
		end)
		f.RollContainer.UsePerc:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			GameTooltip:SetText(L["UsePercForRolls"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["UsePercRollsTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["UsePercRollsTTWarn"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		f.RollContainer.UsePerc:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

    	-- Add to Max Editbox
		f.RollContainer.AddMax = CreateFrame("EditBox", nil, f.RollContainer)
	    f.RollContainer.AddMax:SetAutoFocus(false)
	    f.RollContainer.AddMax:SetMultiLine(false)
	    f.RollContainer.AddMax:SetPoint("TOP", f.RollContainer.rollMax, "BOTTOM", 0, -30)
	    f.RollContainer.AddMax:SetSize(70, 24)
	    f.RollContainer.AddMax:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.RollContainer.AddMax:SetBackdropColor(0,0,0,0.9)
	    f.RollContainer.AddMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.RollContainer.AddMax:SetMaxLetters(6)
	    f.RollContainer.AddMax:SetTextColor(1, 1, 1, 1)
	    f.RollContainer.AddMax:SetFontObject("MonDKPSmallRight")
	    f.RollContainer.AddMax:SetTextInsets(10, 15, 5, 5)
	    f.RollContainer.AddMax:SetText(MonDKP_DB.modes.rolls.AddToMax)
	    f.RollContainer.AddMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()
	      	self:ClearFocus()
	    end)
	    f.RollContainer.AddMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()
	      	f.RollContainer.rollMin:SetFocus()
	    end)
	    f.RollContainer.AddMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
			MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
			MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()
	      	self:ClearFocus()
	    end)
	    f.RollContainer.AddMax:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AddToMaxRoll"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AddToMaxRollTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["AddToMaxRollTTWarn"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.RollContainer.AddMax:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Add to Max Header
	    f.RollContainer.AddMax.Header = f.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
	    f.RollContainer.AddMax.Header:SetFontObject("MonDKPSmallRight");
	    f.RollContainer.AddMax.Header:SetPoint("RIGHT", f.RollContainer.AddMax, "LEFT", -5, 0);
	    f.RollContainer.AddMax.Header:SetText(L["AddToMaxRoll"]..": ")

	-- Broadcast DKP Modes Button
	f.BroadcastSettings = self:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 30, "Broadcast Settings");
	f.BroadcastSettings:SetSize(110,25)
	f.BroadcastSettings:SetScript("OnClick", function()
		MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
		MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()	
		MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()	

		if (MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max and MonDKP_DB.modes.rolls.max ~= 0 and MonDKP_DB.modes.rolls.UserPerc == false) or (MonDKP_DB.modes.rolls.UsePerc and (MonDKP_DB.modes.rolls.min < 0 or MonDKP_DB.modes.rolls.max > 100 or MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max)) then
			StaticPopupDialogs["NOTIFY_ROLLS"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["InvalidRollRange"],
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
			text = L["AreYouSureBroadcast"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				local temptable1 = {}
				table.insert(temptable1, MonDKP_DB.modes)
				table.insert(temptable1, MonDKP_DB.DKPBonus)
				table.insert(temptable1, MonDKP_DB.raiders)
				MonDKP.Sync:SendData("MonDKPModes", temptable1)
				MonDKP:Print(L["DKPModeSentConf"])
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
	f.BroadcastSettings:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["BroadcastSettings"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["BroadcastSetTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show()
	end)
	f.BroadcastSettings:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Window Footer
    f.Footer = f:CreateFontString(nil, "OVERLAY")
    f.Footer:SetFontObject("MonDKPNormalLeft");
    f.Footer:SetWidth(375)
    f.Footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 150);
    f.Footer:SetText(L["DKPModesFooter"])

	f:SetScript("OnHide", function()
		MonDKP_DB.modes.rolls.min = f.RollContainer.rollMin:GetNumber()
		MonDKP_DB.modes.rolls.max = f.RollContainer.rollMax:GetNumber()
		MonDKP_DB.modes.rolls.AddToMax = f.RollContainer.AddMax:GetNumber()

		if (MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max and MonDKP_DB.modes.rolls.max ~= 0 and MonDKP_DB.modes.rolls.UserPerc == false) or (MonDKP_DB.modes.rolls.UsePerc and (MonDKP_DB.modes.rolls.min < 0 or MonDKP_DB.modes.rolls.max > 100 or MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max)) then
			StaticPopupDialogs["NOTIFY_ROLLS"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["InvalidRollParam"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("NOTIFY_ROLLS")
			f:Show()
			return;
		end
		StaticPopupDialogs["CONFIRM_SAVE"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["ReloadUIConfirm"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				ReloadUI();
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CONFIRM_SAVE")
	end)
	return f;
end