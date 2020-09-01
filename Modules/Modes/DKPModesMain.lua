local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

function CommDKP:DKPModes_Main()
  local f = core.ModesWindow;

  f.DKPModesMain.ModeDescriptionHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.ModeDescriptionHeader:SetFontObject("CommDKPLargeLeft");
  f.DKPModesMain.ModeDescriptionHeader:SetWidth(400);
  f.DKPModesMain.ModeDescriptionHeader:SetPoint("TOPLEFT", f.DKPModesMain, "TOPLEFT", 30, -20);

  f.DKPModesMain.ModeDescription = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.ModeDescription:SetPoint("TOPLEFT", f.DKPModesMain, "TOPLEFT", 20, -45);
  f.DKPModesMain.ModeDescription:SetWidth(400);
  f.DKPModesMain.ModeDescription:SetFontObject("CommDKPSmallLeft")
  
  local MinBidDescription = L["MINBIDDESCRIPTION"]
  local StaticDescription = L["STATICDESCRIPTION"]
  local RollDescription = L["ROLLDESCRIPTION"]
  local ZeroSumDescription = L["ZEROSUMDESCRIPTION"];

  if core.DB.modes.mode == "Minimum Bid Values" then
    f.DKPModesMain.ModeDescriptionHeader:SetText(L["MINBIDVALUESHEAD"])
    f.DKPModesMain.ModeDescription:SetText(MinBidDescription)
  elseif core.DB.modes.mode == "Static Item Values" then
    f.DKPModesMain.ModeDescriptionHeader:SetText(L["STATICITEMVALUESHEAD"])
    f.DKPModesMain.ModeDescription:SetText(StaticDescription)
  elseif core.DB.modes.mode == "Roll Based Bidding" then
    f.DKPModesMain.ModeDescriptionHeader:SetText(L["ROLLBIDDINGHEAD"])
    f.DKPModesMain.ModeDescription:SetText(RollDescription)
  elseif core.DB.modes.mode == "Zero Sum" then
    f.DKPModesMain.ModeDescriptionHeader:SetText(L["ZEROSUMHEAD"])
    f.DKPModesMain.ModeDescription:SetText(ZeroSumDescription)
  end

  -- Mode DROPDOWN box 
  local CurMode = core.DB.modes.mode;
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


  f.DKPModesMain.ModesDropDown = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f.DKPModesMain, "CommunityDKPUIDropDownMenuTemplate")

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(f.DKPModesMain.ModesDropDown, function(self, level, menuList)
  local DKPMode = UIDropDownMenu_CreateInfo()
    DKPMode.func = self.SetValue
    DKPMode.fontObject = "CommDKPSmallCenter"
    DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["MINBIDVALUESHEAD"], "Minimum Bid Values", "Minimum Bid Values" == CurMode, false
    UIDropDownMenu_AddButton(DKPMode)
    DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["STATICITEMVALUESHEAD"], "Static Item Values", "Static Item Values" == CurMode, false
    UIDropDownMenu_AddButton(DKPMode)
    DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["ROLLBIDDINGHEAD"], "Roll Based Bidding", "Roll Based Bidding" == CurMode, false
    UIDropDownMenu_AddButton(DKPMode)
    DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["ZEROSUMHEAD"], "Zero Sum", "Zero Sum" == CurMode, false
    UIDropDownMenu_AddButton(DKPMode)
  end)

  f.DKPModesMain.ModesDropDown:SetPoint("TOPLEFT", f.DKPModesMain, "TOPLEFT", 10, -200)
  UIDropDownMenu_SetWidth(f.DKPModesMain.ModesDropDown, 150)
  UIDropDownMenu_SetText(f.DKPModesMain.ModesDropDown, LocalMode)

  -- Dropdown Menu Function
  function f.DKPModesMain.ModesDropDown:SetValue(newValue)
    if curMode ~= newValue then CurMode = newValue end

    f.DKPModesMain.ModeDescriptionHeader:SetText(newValue)
    
    if newValue == "Minimum Bid Values" then
      core.DB.modes.mode = "Minimum Bid Values";
      f.DKPModesMain.ModeDescription:SetText(MinBidDescription)
      f.DKPModesMain.ItemCostDropDown:Hide();
      f.DKPModesMain.ItemCostHeader:Hide();
      f.DKPModesMain.MaxBidBehaviorDropDown:Show();
      f.DKPModesMain.MaxBidBehaviorHeader:Show();
      core.DB.modes.costvalue = "Integer";
      UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, "Integer")
      f.DKPModesMain.SubZeroBidding:Show();
      f.DKPModesMain.SubZeroBidding:SetChecked(core.DB.modes.SubZeroBidding)
      if core.DB.modes.SubZeroBidding == true then
        f.DKPModesMain.AllowNegativeBidders:Show()
        f.DKPModesMain.AllowNegativeBidders:SetChecked(core.DB.modes.AllowNegativeBidders)
      end
      f.DKPModesMain.RollContainer:Hide();
      f.DKPModesMain.ZeroSumType:Hide();
      f.DKPModesMain.ZeroSumTypeHeader:Hide();
      f.DKPModesMain.CostSelection:Show();
      f.DKPModesMain.CostSelectionHeader:Show();
      f.DKPModesMain.Inflation:Hide()
        f.DKPModesMain.Inflation.Header:Hide()
    elseif newValue == "Static Item Values" then
      core.DB.modes.mode = "Static Item Values"
      f.DKPModesMain.ModeDescription:SetText(StaticDescription)
      f.DKPModesMain.ItemCostHeader:Show();
      f.DKPModesMain.ItemCostDropDown:Show();
      f.DKPModesMain.MaxBidBehaviorDropDown:Hide();
      f.DKPModesMain.MaxBidBehaviorHeader:Hide();
      core.DB.modes.MaxBehavior = "Max DKP";
      UIDropDownMenu_SetText(f.DKPModesMain.MaxBidBehaviorDropDown, "Max DKP")
      f.DKPModesMain.RollContainer:Hide()
      f.DKPModesMain.ZeroSumType:Hide()
      f.DKPModesMain.ZeroSumTypeHeader:Hide();
      f.DKPModesMain.CostSelection:Hide();
      f.DKPModesMain.CostSelectionHeader:Hide();
      f.DKPModesMain.Inflation:Hide()
      f.DKPModesMain.Inflation.Header:Hide()

      if core.DB.modes.costvalue == "Integer" then
        f.DKPModesMain.SubZeroBidding:Show()
        f.DKPModesMain.SubZeroBidding:SetChecked(core.DB.modes.SubZeroBidding)
        if core.DB.modes.SubZeroBidding == true then
          f.DKPModesMain.AllowNegativeBidders:Show()
          f.DKPModesMain.AllowNegativeBidders:SetChecked(core.DB.modes.AllowNegativeBidders)
        end
        UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, L["INTEGER"])
      else
        f.DKPModesMain.SubZeroBidding:Hide()
        f.DKPModesMain.AllowNegativeBidders:Hide()
        UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, L["PERCENT"])
      end
    elseif newValue == "Roll Based Bidding" then
      core.DB.modes.mode = "Roll Based Bidding"
      f.DKPModesMain.ItemCostHeader:Show();
      f.DKPModesMain.ItemCostDropDown:Show();
      f.DKPModesMain.MaxBidBehaviorDropDown:Hide();
      f.DKPModesMain.MaxBidBehaviorHeader:Hide();
      core.DB.modes.MaxBehavior = "Max DKP";
      UIDropDownMenu_SetText(f.DKPModesMain.MaxBidBehaviorDropDown, "Max DKP")
      f.DKPModesMain.ModeDescription:SetText(RollDescription)
      f.DKPModesMain.RollContainer:Show()
      f.DKPModesMain.ZeroSumType:Hide()
      f.DKPModesMain.ZeroSumTypeHeader:Hide();
      f.DKPModesMain.CostSelection:Hide()
      f.DKPModesMain.CostSelectionHeader:Hide()
      f.DKPModesMain.Inflation:Hide()
        f.DKPModesMain.Inflation.Header:Hide()

      if core.DB.modes.costvalue == "Integer" then
        f.DKPModesMain.SubZeroBidding:Show()
        f.DKPModesMain.SubZeroBidding:SetChecked(core.DB.modes.SubZeroBidding)
        if core.DB.modes.SubZeroBidding == true then
          f.DKPModesMain.AllowNegativeBidders:Show()
          f.DKPModesMain.AllowNegativeBidders:SetChecked(core.DB.modes.AllowNegativeBidders)
        end
        UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, "Integer")
      end
    elseif newValue == "Zero Sum" then
      core.DB.modes.mode = "Zero Sum"
      core.DB.modes.costvalue = "Integer"
      f.DKPModesMain.ModeDescription:SetText(ZeroSumDescription)
      f.DKPModesMain.SubZeroBidding:Hide()
      f.DKPModesMain.AllowNegativeBidders:Hide()
      f.DKPModesMain.RollContainer:Hide()
      f.DKPModesMain.ItemCostHeader:Hide();
      UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, "Integer")
      f.DKPModesMain.ItemCostDropDown:Hide();
      f.DKPModesMain.ZeroSumType:Show()
      f.DKPModesMain.ZeroSumTypeHeader:Show();
      core.DB.modes.SubZeroBidding = true
      f.DKPModesMain.Inflation:Show()
        f.DKPModesMain.Inflation.Header:Show()

      if core.DB.modes.ZeroSumBidType == "Static" then
        f.DKPModesMain.MaxBidBehaviorDropDown:Hide();
        f.DKPModesMain.MaxBidBehaviorHeader:Hide();
        core.DB.modes.MaxBehavior = "Max DKP";
        UIDropDownMenu_SetText(f.DKPModesMain.MaxBidBehaviorDropDown, "Max DKP")
        f.DKPModesMain.CostSelection:Hide()
        f.DKPModesMain.CostSelectionHeader:Hide()
      else
        f.DKPModesMain.MaxBidBehaviorDropDown:Show();
        f.DKPModesMain.MaxBidBehaviorHeader:Show();
        f.DKPModesMain.CostSelection:Show()
        f.DKPModesMain.CostSelectionHeader:Show()
        f.DKPModesMain.SubZeroBidding:Show()
        f.DKPModesMain.AllowNegativeBidders:Show()
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

    UIDropDownMenu_SetText(f.DKPModesMain.ModesDropDown, LocalMode)
    CloseDropDownMenus()
  end

  f.DKPModesMain.ModesDropDown:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["DKPMODESTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.DKPModesMain.ModesDropDown:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  f.DKPModesMain.ModeHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.ModeHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ModesDropDown, "TOPLEFT", 25, 0);
  f.DKPModesMain.ModeHeader:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.ModeHeader:SetText(L["DKPMODES"])

  -- Rounding DROPDOWN box 
  f.DKPModesMain.RoundDropDown = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f.DKPModesMain, "CommunityDKPUIDropDownMenuTemplate")

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(f.DKPModesMain.RoundDropDown, function(self, level, menuList)
  local places = UIDropDownMenu_CreateInfo()
    places.func = self.SetValue
    places.fontObject = "CommDKPSmallCenter"
    places.text, places.arg1, places.checked, places.isNotRadio = 0, 0, 0 == core.DB.modes.rounding, false
    UIDropDownMenu_AddButton(places)
    places.text, places.arg1, places.checked, places.isNotRadio = 1, 1, 1 == core.DB.modes.rounding, false
    UIDropDownMenu_AddButton(places)
    places.text, places.arg1, places.checked, places.isNotRadio = 2, 2, 2 == core.DB.modes.rounding, false
    UIDropDownMenu_AddButton(places)
    places.text, places.arg1, places.checked, places.isNotRadio = 3, 3, 3 == core.DB.modes.rounding, false
    UIDropDownMenu_AddButton(places)
    places.text, places.arg1, places.checked, places.isNotRadio = 4, 4, 4 == core.DB.modes.rounding, false
    UIDropDownMenu_AddButton(places)
  end)

  f.DKPModesMain.RoundDropDown:SetPoint("TOPLEFT", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 0, -95)
  UIDropDownMenu_SetWidth(f.DKPModesMain.RoundDropDown, 80)
  UIDropDownMenu_SetText(f.DKPModesMain.RoundDropDown, core.DB.modes.rounding)

  -- Dropdown Menu Function
  function f.DKPModesMain.RoundDropDown:SetValue(newValue)
    core.DB.modes.rounding = newValue;
    UIDropDownMenu_SetText(f.DKPModesMain.RoundDropDown, newValue)
    CloseDropDownMenus()
  end

  f.DKPModesMain.RoundDropDown:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  f.DKPModesMain.RoundDropDown:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["DKPROUNDING"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["DKPROUNDINGTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
    f.DKPModesMain.RoundDropDown:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

  f.DKPModesMain.RoundHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.RoundHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.RoundDropDown, "TOPLEFT", 25, 0);
  f.DKPModesMain.RoundHeader:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.RoundHeader:SetText(L["DKPROUNDING"])

  -- MAX Bid button behavior
  f.DKPModesMain.MaxBidBehaviorDropDown = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f.DKPModesMain, "CommunityDKPUIDropDownMenuTemplate")

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(f.DKPModesMain.MaxBidBehaviorDropDown, function(self, level, menuList)
  local MaxBehavior = UIDropDownMenu_CreateInfo()
    MaxBehavior.func = self.SetValue
    MaxBehavior.fontObject = "CommDKPSmallCenter"
    MaxBehavior.text, MaxBehavior.arg1, MaxBehavior.checked, MaxBehavior.isNotRadio = L["MAXBIDBEHAVIORMAXDKP"], "Max DKP", "Max DKP" == core.DB.modes.MaxBehavior, false
    UIDropDownMenu_AddButton(MaxBehavior)
    MaxBehavior.text, MaxBehavior.arg1, MaxBehavior.checked, MaxBehavior.isNotRadio = L["MAXBIDBEHAVIORMAXITEMVALUE"], "Max Item Value", "Max Item Value" == core.DB.modes.MaxBehavior, false
    UIDropDownMenu_AddButton(MaxBehavior)
    MaxBehavior.text, MaxBehavior.arg1, MaxBehavior.checked, MaxBehavior.isNotRadio = L["MAXBIDBEHAVIORMIN"], "Min(Max DKP, Max Item Value)", "Min(Max DKP, Max Item Value)" == core.DB.modes.MaxBehavior, false
    UIDropDownMenu_AddButton(MaxBehavior)
  end)

  f.DKPModesMain.MaxBidBehaviorDropDown:SetPoint("TOPLEFT", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 0, -50)
  UIDropDownMenu_SetWidth(f.DKPModesMain.MaxBidBehaviorDropDown, 200)
  UIDropDownMenu_SetText(f.DKPModesMain.MaxBidBehaviorDropDown, core.DB.modes.MaxBehavior)

  -- Dropdown Menu Function
  function f.DKPModesMain.MaxBidBehaviorDropDown:SetValue(newValue)
    core.DB.modes.MaxBehavior = newValue;
    if newValue == "Max DKP" then
      UIDropDownMenu_SetText(f.DKPModesMain.MaxBidBehaviorDropDown, L["MAXBIDBEHAVIORMAXDKP"])
    elseif newValue == "Max Item Value" then
      UIDropDownMenu_SetText(f.DKPModesMain.MaxBidBehaviorDropDown, L["MAXBIDBEHAVIORMAXITEMVALUE"])
    else
      UIDropDownMenu_SetText(f.DKPModesMain.MaxBidBehaviorDropDown, L["MAXBIDBEHAVIORMIN"])
    end
    CloseDropDownMenus()
  end

  f.DKPModesMain.MaxBidBehaviorDropDown:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  f.DKPModesMain.MaxBidBehaviorDropDown:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["MAXBIDBEHAVIOR"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["MAXBIDBEHAVIORTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
    f.DKPModesMain.MaxBidBehaviorDropDown:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  
  f.DKPModesMain.MaxBidBehaviorHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.MaxBidBehaviorHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.MaxBidBehaviorDropDown, "TOPLEFT", 25, 0);
  f.DKPModesMain.MaxBidBehaviorHeader:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.MaxBidBehaviorHeader:SetText(L["MAXBIDBEHAVIOR"])

  -- AntiSnipe Option
  f.DKPModesMain.AntiSnipe = CreateFrame("EditBox", nil, f.DKPModesMain)
    f.DKPModesMain.AntiSnipe:SetAutoFocus(false)
    f.DKPModesMain.AntiSnipe:SetMultiLine(false)
    f.DKPModesMain.AntiSnipe:SetPoint("TOPLEFT", f.DKPModesMain.RoundDropDown, "BOTTOMLEFT", 18, -15)
    f.DKPModesMain.AntiSnipe:SetSize(100, 24)
    f.DKPModesMain.AntiSnipe:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPModesMain.AntiSnipe:SetBackdropColor(0,0,0,0.9)
    f.DKPModesMain.AntiSnipe:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPModesMain.AntiSnipe:SetMaxLetters(8)
    f.DKPModesMain.AntiSnipe:SetTextColor(1, 1, 1, 1)
    f.DKPModesMain.AntiSnipe:SetFontObject("CommDKPSmallRight")
    f.DKPModesMain.AntiSnipe:SetTextInsets(10, 15, 5, 5)
    f.DKPModesMain.AntiSnipe:SetText(core.DB.modes.AntiSnipe)
    f.DKPModesMain.AntiSnipe:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      core.DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
      self:ClearFocus()
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnTabPressed", function(self)    -- clears focus on esc
      core.DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
      self:ClearFocus()
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
      core.DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
      self:ClearFocus()
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnKeyUp", function(self)    -- clears focus on esc
      if f.DKPModesMain.AntiSnipe:GetText():match("%a+") then
        f.DKPModesMain.AntiSnipe:SetNumber(f.DKPModesMain.AntiSnipe:GetNumber() or 0)
        if f.DKPModesMain.AntiSnipe:GetText() == "0" then
          f.DKPModesMain.AntiSnipe:HighlightText()
        end
      else
        core.DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
      end
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["ANTISNIPE"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["ANTISNIPETTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["ANTISNIPETTWARN"], 1.0, 0, 0, true);
    GameTooltip:Show();
  end)
    f.DKPModesMain.AntiSnipe:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    f.DKPModesMain.AntiSnipe.Header = f.DKPModesMain.AntiSnipe:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.AntiSnipe.Header:SetFontObject("CommDKPNormalLeft");
    f.DKPModesMain.AntiSnipe.Header:SetPoint("BOTTOMLEFT", f.DKPModesMain.AntiSnipe, "TOPLEFT", 0, 2);
    f.DKPModesMain.AntiSnipe.Header:SetText(L["ANTISNIPE"])

  -- Channels DROPDOWN box 
  f.DKPModesMain.ChannelsDropDown = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f.DKPModesMain, "CommunityDKPUIDropDownMenuTemplate")

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(f.DKPModesMain.ChannelsDropDown, function(self, level, menuList)
  local OpenChannel = UIDropDownMenu_CreateInfo()
    OpenChannel.func = self.SetValue
    OpenChannel.fontObject = "CommDKPSmallCenter"
    OpenChannel.keepShownOnClick = true;
    OpenChannel.isNotRadio = true;
    OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["WHISPER"], "Whisper", true == core.DB.modes.channels.whisper
    UIDropDownMenu_AddButton(OpenChannel)
    OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["RAID"], "Raid", true == core.DB.modes.channels.raid
    UIDropDownMenu_AddButton(OpenChannel)
    OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["GUILD"], "Guild", true == core.DB.modes.channels.guild
    UIDropDownMenu_AddButton(OpenChannel)
  end)

  f.DKPModesMain.ChannelsDropDown:SetPoint("LEFT", f.DKPModesMain.ModesDropDown, "RIGHT", 30, 0)
  UIDropDownMenu_SetWidth(f.DKPModesMain.ChannelsDropDown, 150)
  UIDropDownMenu_SetText(f.DKPModesMain.ChannelsDropDown, L["OPENCHANNELS"])

  -- Dropdown Menu Function
  function f.DKPModesMain.ChannelsDropDown:SetValue(arg1)
    if arg1 == "Whisper" then
      core.DB.modes.channels.whisper = not core.DB.modes.channels.whisper
    elseif arg1 == "Raid" then
      core.DB.modes.channels.raid = not core.DB.modes.channels.raid
    elseif arg1 == "Guild" then
      core.DB.modes.channels.guild = not core.DB.modes.channels.guild
    end

    UIDropDownMenu_SetText(f.DKPModesMain.ChannelsDropDown, "Open Channels")
    CloseDropDownMenus()
  end

  f.DKPModesMain.ChannelsDropDown:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["COMMANDCHANNELS"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["COMMANDCHANNELSTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.DKPModesMain.ChannelsDropDown:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  f.DKPModesMain.ChannelsHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.ChannelsHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ChannelsDropDown, "TOPLEFT", 25, 0);
  f.DKPModesMain.ChannelsHeader:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.ChannelsHeader:SetText(L["COMMANDCHANNELS"])

  -- Cost Auto Update Value DROPDOWN box 
  if not core.DB.modes.CostSelection then core.DB.modes.CostSelection = "Second Bidder" end
  f.DKPModesMain.CostSelection = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f.DKPModesMain, "CommunityDKPUIDropDownMenuTemplate")
  f.DKPModesMain.CostSelection:SetPoint("TOPLEFT", f.DKPModesMain.ChannelsDropDown, "BOTTOMLEFT", 0, -10)

  local LocalCostSel;

  if core.DB.modes.CostSelection == "First Bidder" then
    LocalCostSel = L["FIRSTBIDDER"]
  elseif core.DB.modes.CostSelection == "Second Bidder" then
    LocalCostSel = L["SECONDBIDDER"]
  elseif core.DB.modes.CostSelection == "Second Bidder or Min" then
    LocalCostSel = L["SECONDBIDDERORMIN"]
  end

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(f.DKPModesMain.CostSelection, function(self, level, menuList)
  local CostSelect = UIDropDownMenu_CreateInfo()
    CostSelect.func = self.SetValue
    CostSelect.fontObject = "CommDKPSmallCenter"
    CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["FIRSTBIDDER"], "First Bidder", "First Bidder" == core.DB.modes.CostSelection, false
    UIDropDownMenu_AddButton(CostSelect)
    CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["SECONDBIDDER"], "Second Bidder", "Second Bidder" == core.DB.modes.CostSelection, false
    UIDropDownMenu_AddButton(CostSelect)
    CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["SECONDBIDDERORMIN"], "Second Bidder or Min", "Second Bidder or Min" == core.DB.modes.CostSelection, false
    UIDropDownMenu_AddButton(CostSelect)
  end)
  
  

  UIDropDownMenu_SetWidth(f.DKPModesMain.CostSelection, 150)
  UIDropDownMenu_SetText(f.DKPModesMain.CostSelection, LocalCostSel)

  -- Dropdown Menu Function
  function f.DKPModesMain.CostSelection:SetValue(arg1)
    core.DB.modes.CostSelection = arg1

    if arg1 == "First Bidder" then
      LocalCostSel = L["FIRSTBIDDER"]
    elseif arg1 == "Second Bidder" then
      LocalCostSel = L["SECONDBIDDER"]
    else
      LocalCostSel = L["SECONDBIDDERORMIN"]
    end

    UIDropDownMenu_SetText(f.DKPModesMain.CostSelection, LocalCostSel)
    CloseDropDownMenus()
  end

  f.DKPModesMain.CostSelection:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["COSTAUTOUPDATE"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["COSTAUTOUPDATETTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.DKPModesMain.CostSelection:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  f.DKPModesMain.CostSelectionHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.CostSelectionHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.CostSelection, "TOPLEFT", 25, 0);
  f.DKPModesMain.CostSelectionHeader:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.CostSelectionHeader:SetText(L["COSTAUTOUPDATEVALUE"])

  if not (core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid")) then
    f.DKPModesMain.CostSelection:Hide()
    f.DKPModesMain.CostSelectionHeader:Hide();
  end

  -- Artificial Inflation Editbox
  if not core.DB.modes.Inflation then core.DB.modes.Inflation = 0 end
  f.DKPModesMain.Inflation = CreateFrame("EditBox", nil, f.DKPModesMain)
    f.DKPModesMain.Inflation:SetAutoFocus(false)
    f.DKPModesMain.Inflation:SetMultiLine(false)
    f.DKPModesMain.Inflation:SetPoint("TOPLEFT", f.DKPModesMain.CostSelection, "BOTTOMLEFT", 20, -15)
    f.DKPModesMain.Inflation:SetSize(100, 24)
    f.DKPModesMain.Inflation:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPModesMain.Inflation:SetBackdropColor(0,0,0,0.9)
    f.DKPModesMain.Inflation:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPModesMain.Inflation:SetMaxLetters(8)
    f.DKPModesMain.Inflation:SetTextColor(1, 1, 1, 1)
    f.DKPModesMain.Inflation:SetFontObject("CommDKPSmallRight")
    f.DKPModesMain.Inflation:SetTextInsets(10, 15, 5, 5)
    f.DKPModesMain.Inflation:SetText(core.DB.modes.Inflation)
    f.DKPModesMain.Inflation:Hide();
    f.DKPModesMain.Inflation:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      core.DB.modes.Inflation = f.DKPModesMain.Inflation:GetNumber()
      self:ClearFocus()
    end)
    f.DKPModesMain.Inflation:SetScript("OnTabPressed", function(self)    -- clears focus on esc
      core.DB.modes.Inflation = f.DKPModesMain.Inflation:GetNumber()
      self:ClearFocus()
    end)
    f.DKPModesMain.Inflation:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
      core.DB.modes.Inflation = f.DKPModesMain.Inflation:GetNumber()
      self:ClearFocus()
    end)
    f.DKPModesMain.Inflation:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["ARTIFICIALINFLATION"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["ARTINFLATTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
    f.DKPModesMain.Inflation:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    -- Min Roll Header
    f.DKPModesMain.Inflation.Header = f.DKPModesMain.Inflation:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.Inflation.Header:SetFontObject("CommDKPNormalLeft");
    f.DKPModesMain.Inflation.Header:SetPoint("BOTTOM", f.DKPModesMain.Inflation, "TOP", -20, 2);
    f.DKPModesMain.Inflation.Header:SetText(L["INFLATION"])

    if core.DB.modes.mode == "Zero Sum" then
      f.DKPModesMain.Inflation:Show()
      f.DKPModesMain.Inflation.Header:Show()
    end

    -- ZeroSum Type DROPDOWN box 
  f.DKPModesMain.ZeroSumType = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f.DKPModesMain, "CommunityDKPUIDropDownMenuTemplate")

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(f.DKPModesMain.ZeroSumType, function(self, level, menuList)
  local BidType = UIDropDownMenu_CreateInfo()
    BidType.func = self.SetValue
    BidType.fontObject = "CommDKPSmallCenter"
    BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["STATIC"], "Static", "Static" == core.DB.modes.ZeroSumBidType, false
    UIDropDownMenu_AddButton(BidType)
    BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["MINIMUMBID"], "Minimum Bid", "Minimum Bid" == core.DB.modes.ZeroSumBidType, false
    UIDropDownMenu_AddButton(BidType)
  end)

  f.DKPModesMain.ZeroSumType:SetPoint("TOPLEFT", f.DKPModesMain.Inflation, "BOTTOMLEFT", -20, -20)
  UIDropDownMenu_SetWidth(f.DKPModesMain.ZeroSumType, 150)
  UIDropDownMenu_SetText(f.DKPModesMain.ZeroSumType, core.DB.modes.ZeroSumBidType)

  -- Dropdown Menu Function
  function f.DKPModesMain.ZeroSumType:SetValue(newValue)
    core.DB.modes.ZeroSumBidType = newValue;
    if newValue == "Static" then
      f.DKPModesMain.CostSelection:Hide();
      f.DKPModesMain.CostSelectionHeader:Hide();
      newValue = L["STATIC"]
      f.DKPModesMain.SubZeroBidding:Hide()
      f.DKPModesMain.AllowNegativeBidders:Hide()
      f.DKPModesMain.MaxBidBehaviorDropDown:Hide();
      f.DKPModesMain.MaxBidBehaviorHeader:Hide();
      core.DB.modes.MaxBehavior = "Max DKP";
    else
      f.DKPModesMain.CostSelection:Show();
      f.DKPModesMain.CostSelectionHeader:Show();
      newValue = L["MINIMUMBID"]
      f.DKPModesMain.SubZeroBidding:Show()
      f.DKPModesMain.AllowNegativeBidders:Show()
      f.DKPModesMain.MaxBidBehaviorDropDown:Show();
      f.DKPModesMain.MaxBidBehaviorHeader:Show();
    end

    UIDropDownMenu_SetText(f.DKPModesMain.ZeroSumType, newValue)
    CloseDropDownMenus()
  end

  f.DKPModesMain.ZeroSumType:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["ZEROSUMITEMCOST"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["ZEROSUMITEMCOSTTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.DKPModesMain.ZeroSumType:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  f.DKPModesMain.ZeroSumTypeHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.ZeroSumTypeHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ZeroSumType, "TOPLEFT", 25, 0);
  f.DKPModesMain.ZeroSumTypeHeader:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.ZeroSumTypeHeader:SetText(L["BIDMETHOD"])

  if core.DB.modes.mode ~= "Zero Sum" then
    f.DKPModesMain.ZeroSumType:Hide()
    f.DKPModesMain.ZeroSumTypeHeader:Hide();
  end

  -- Item Cost Value DROPDOWN box 
  f.DKPModesMain.ItemCostDropDown = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f.DKPModesMain, "CommunityDKPUIDropDownMenuTemplate")

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(f.DKPModesMain.ItemCostDropDown, function(self, level, menuList)
  local CostValue = UIDropDownMenu_CreateInfo()
    CostValue.func = self.SetValue
    CostValue.fontObject = "CommDKPSmallCenter"
    CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["INTEGER"], "Integer", "Integer" == core.DB.modes.costvalue, false
    UIDropDownMenu_AddButton(CostValue)
    CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["PERCENT"], "Percent", "Percent" == core.DB.modes.costvalue, false
    UIDropDownMenu_AddButton(CostValue)
  end)
  
  f.DKPModesMain.ItemCostDropDown:SetPoint("TOPLEFT", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 0, -50)
  UIDropDownMenu_SetWidth(f.DKPModesMain.ItemCostDropDown, 150)
  UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, L[string.upper(core.DB.modes.costvalue)])

  -- Dropdown Menu Function
  function f.DKPModesMain.ItemCostDropDown:SetValue(arg1)
    if arg1 == "Integer" then
      core.DB.modes.costvalue = "Integer"
      f.DKPModesMain.SubZeroBidding:Show()
      f.DKPModesMain.SubZeroBidding:SetChecked(core.DB.modes.SubZeroBidding)
      if core.DB.modes.SubZeroBidding == true then
        f.DKPModesMain.AllowNegativeBidders:Show()
        f.DKPModesMain.AllowNegativeBidders:SetChecked(core.DB.modes.AllowNegativeBidders)
      end
      UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, L["INTEGER"])
    elseif arg1 == "Percent" then
      core.DB.modes.costvalue = "Percent"
      f.DKPModesMain.SubZeroBidding:Hide()
      f.DKPModesMain.AllowNegativeBidders:Hide()
      core.DB.modes.SubZeroBidding = false;
      f.DKPModesMain.SubZeroBidding:SetChecked(false)
      UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, L["PERCENT"])
    end

    
    CloseDropDownMenus()
  end

  f.DKPModesMain.ItemCostDropDown:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["ITEMCOSTTYPES"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["ITEMCOSTTYPESTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.DKPModesMain.ItemCostDropDown:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  f.DKPModesMain.ItemCostHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
  f.DKPModesMain.ItemCostHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ItemCostDropDown, "TOPLEFT", 25, 0);
  f.DKPModesMain.ItemCostHeader:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.ItemCostHeader:SetText(L["ITEMCOSTTYPES"])

  if core.DB.modes.mode == "Minimum Bid Values" then
    f.DKPModesMain.ItemCostDropDown:Hide();
    f.DKPModesMain.ItemCostHeader:Hide();
    core.DB.modes.costvalue = "Integer";
    f.DKPModesMain.MaxBidBehaviorDropDown:Show();
    f.DKPModesMain.MaxBidBehaviorHeader:Show();
  elseif core.DB.modes.mode == "Roll Based Bidding" then
    f.DKPModesMain.MaxBidBehaviorDropDown:Hide();
    f.DKPModesMain.MaxBidBehaviorHeader:Hide();
    core.DB.modes.MaxBehavior = "Max DKP";
elseif core.DB.modes.mode == "Static Item Values" then
    f.DKPModesMain.MaxBidBehaviorDropDown:Hide();
    f.DKPModesMain.MaxBidBehaviorHeader:Hide();
    core.DB.modes.MaxBehavior = "Max DKP";
  elseif core.DB.modes.mode == "Zero Sum" then
    f.DKPModesMain.ItemCostDropDown:Hide();
    f.DKPModesMain.ItemCostHeader:Hide();
    core.DB.modes.costvalue = "Integer";
    if core.DB.modes.ZeroSumBidType == "Static" then
      f.DKPModesMain.MaxBidBehaviorDropDown:Hide();
      f.DKPModesMain.MaxBidBehaviorHeader:Hide();
      core.DB.modes.MaxBehavior = "Max DKP";      
    else
      f.DKPModesMain.MaxBidBehaviorDropDown:Show();
      f.DKPModesMain.MaxBidBehaviorHeader:Show();    
    end
  end

  -- Sub Zero Bidding Checkbox
  f.DKPModesMain.SubZeroBidding = CreateFrame("CheckButton", nil, f.DKPModesMain, "UICheckButtonTemplate");
  f.DKPModesMain.SubZeroBidding:SetChecked(core.DB.modes.SubZeroBidding)
  f.DKPModesMain.SubZeroBidding:SetScale(0.6);
  f.DKPModesMain.SubZeroBidding.text:SetText("  |cff5151de"..L["SUBZEROBIDDING"].."|r");
  f.DKPModesMain.SubZeroBidding.text:SetScale(1.5);
  f.DKPModesMain.SubZeroBidding.text:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.SubZeroBidding:SetPoint("TOP", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 60, 0);
  f.DKPModesMain.SubZeroBidding:SetScript("OnClick", function(self)
    if self:GetChecked() == true then
      core.DB.modes.SubZeroBidding = true;
      CommDKP:Print("Sub Zero Bidding |cff00ff00"..L["ENABLED"].."|r")
      f.DKPModesMain.AllowNegativeBidders:Show()
      f.DKPModesMain.AllowNegativeBidders:SetChecked(core.DB.modes.AllowNegativeBidders)
    else
      core.DB.modes.SubZeroBidding = false;
      CommDKP:Print("Sub Zero Bidding |cffff0000"..L["DISABLED"].."|r")
      core.DB.modes.AllowNegativeBidders = false
      f.DKPModesMain.AllowNegativeBidders:Hide()
    end
    PlaySound(808);
  end)
  f.DKPModesMain.SubZeroBidding:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["SUBZEROBIDDING"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["SUBZEROBIDDINGTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.DKPModesMain.SubZeroBidding:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  if core.DB.modes.costvalue == "Percent" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
    f.DKPModesMain.SubZeroBidding:Hide()
  end
  
  -- Allow Bids below zero Checkbox
  f.DKPModesMain.AllowNegativeBidders = CreateFrame("CheckButton", nil, f.DKPModesMain, "UICheckButtonTemplate");
  f.DKPModesMain.AllowNegativeBidders:SetChecked(core.DB.modes.AllowNegativeBidders)
  f.DKPModesMain.AllowNegativeBidders:SetScale(0.6);
  f.DKPModesMain.AllowNegativeBidders.text:SetText("  |cff5151de"..L["ALLOWNEGATIVEBIDDERS"].."|r");
  f.DKPModesMain.AllowNegativeBidders.text:SetScale(1.5);
  f.DKPModesMain.AllowNegativeBidders.text:SetFontObject("CommDKPSmallLeft")
  f.DKPModesMain.AllowNegativeBidders:SetPoint("TOPLEFT", f.DKPModesMain.SubZeroBidding, "BOTTOMLEFT", 0, 0);
  f.DKPModesMain.AllowNegativeBidders:SetScript("OnClick", function(self)
    if self:GetChecked() == true then
      core.DB.modes.AllowNegativeBidders = true;
      CommDKP:Print("Allow Negative Bidders |cff00ff00"..L["ENABLED"].."|r")
    else
      core.DB.modes.AllowNegativeBidders = false;
      CommDKP:Print("Allow Negative Bidders |cffff0000"..L["DISABLED"].."|r")
    end
    PlaySound(808);
  end)
  f.DKPModesMain.AllowNegativeBidders:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["ALLOWNEGATIVEBIDDERS"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["ALLOWNEGATIVEBIDTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.DKPModesMain.AllowNegativeBidders:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  if (core.DB.modes.costvalue == "Percent" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static")) or core.DB.modes.SubZeroBidding == false then
    f.DKPModesMain.AllowNegativeBidders:Hide()
  end


  -- Roll Container
  f.DKPModesMain.RollContainer = CreateFrame("Frame", nil, f.DKPModesMain);
  f.DKPModesMain.RollContainer:SetSize(210, 150);
  f.DKPModesMain.RollContainer:SetPoint("TOPLEFT", f.DKPModesMain.ChannelsDropDown, "BOTTOMLEFT", -10, -20)
  f.DKPModesMain.RollContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
  f.DKPModesMain.RollContainer:SetBackdropColor(0,0,0,0.9)
  f.DKPModesMain.RollContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  f.DKPModesMain.RollContainer:Hide();
    if core.DB.modes.mode == "Roll Based Bidding" then
      f.DKPModesMain.RollContainer:Show()
    end

  -- Roll Container Header
    f.DKPModesMain.RollContainer.Header = f.DKPModesMain.RollContainer:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.RollContainer.Header:SetFontObject("CommDKPLargeLeft");
    f.DKPModesMain.RollContainer.Header:SetScale(0.6)
    f.DKPModesMain.RollContainer.Header:SetPoint("TOPLEFT", f.DKPModesMain.RollContainer, "TOPLEFT", 15, -15);
    f.DKPModesMain.RollContainer.Header:SetText(L["ROLLSETTINGS"])


    -- Min Roll Editbox
    f.DKPModesMain.RollContainer.rollMin = CreateFrame("EditBox", nil, f.DKPModesMain.RollContainer)
      f.DKPModesMain.RollContainer.rollMin:SetAutoFocus(false)
      f.DKPModesMain.RollContainer.rollMin:SetMultiLine(false)
      f.DKPModesMain.RollContainer.rollMin:SetPoint("TOPLEFT", f.DKPModesMain.RollContainer, "TOPLEFT", 20, -50)
      f.DKPModesMain.RollContainer.rollMin:SetSize(70, 24)
      f.DKPModesMain.RollContainer.rollMin:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
      });
      f.DKPModesMain.RollContainer.rollMin:SetBackdropColor(0,0,0,0.9)
      f.DKPModesMain.RollContainer.rollMin:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
      f.DKPModesMain.RollContainer.rollMin:SetMaxLetters(6)
      f.DKPModesMain.RollContainer.rollMin:SetTextColor(1, 1, 1, 1)
      f.DKPModesMain.RollContainer.rollMin:SetFontObject("CommDKPSmallRight")
      f.DKPModesMain.RollContainer.rollMin:SetTextInsets(10, 15, 5, 5)
      f.DKPModesMain.RollContainer.rollMin:SetText(core.DB.modes.rolls.min)
      f.DKPModesMain.RollContainer.rollMin:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
        self:ClearFocus()
      end)
      f.DKPModesMain.RollContainer.rollMin:SetScript("OnTabPressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
          f.DKPModesMain.RollContainer.rollMax:SetFocus()
      end)
      f.DKPModesMain.RollContainer.rollMin:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()  
        self:ClearFocus()
      end)
      f.DKPModesMain.RollContainer.rollMin:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["MINIMUMROLL"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["MINIMUMROLLTTDESC"], 1.0, 1.0, 1.0, true);
      --GameTooltip:AddLine("The state of this option will persist indefinitely until manually disabled/enabled.", 1.0, 0, 0, true);
      GameTooltip:Show();
    end)
      f.DKPModesMain.RollContainer.rollMin:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)

      -- Min Roll Header
      f.DKPModesMain.RollContainer.rollMin.Header = f.DKPModesMain.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
      f.DKPModesMain.RollContainer.rollMin.Header:SetFontObject("CommDKPNormalLeft");
      f.DKPModesMain.RollContainer.rollMin.Header:SetPoint("BOTTOM", f.DKPModesMain.RollContainer.rollMin, "TOP", -20, 2);
      f.DKPModesMain.RollContainer.rollMin.Header:SetText(L["MIN"])

      -- Dash Between Rolls
      f.DKPModesMain.RollContainer.dash = f.DKPModesMain.RollContainer:CreateFontString(nil, "OVERLAY")
      f.DKPModesMain.RollContainer.dash:SetFontObject("CommDKPLargeLeft");
      f.DKPModesMain.RollContainer.dash:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMin, "RIGHT", 9, 0);
      f.DKPModesMain.RollContainer.dash:SetText("-")

      -- Max Roll Editbox
    f.DKPModesMain.RollContainer.rollMax = CreateFrame("EditBox", nil, f.DKPModesMain.RollContainer)
      f.DKPModesMain.RollContainer.rollMax:SetAutoFocus(false)
      f.DKPModesMain.RollContainer.rollMax:SetMultiLine(false)
      f.DKPModesMain.RollContainer.rollMax:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMin, "RIGHT", 24, 0)
      f.DKPModesMain.RollContainer.rollMax:SetSize(70, 24)
      f.DKPModesMain.RollContainer.rollMax:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
      });
      f.DKPModesMain.RollContainer.rollMax:SetBackdropColor(0,0,0,0.9)
      f.DKPModesMain.RollContainer.rollMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
      f.DKPModesMain.RollContainer.rollMax:SetMaxLetters(6)
      f.DKPModesMain.RollContainer.rollMax:SetTextColor(1, 1, 1, 1)
      f.DKPModesMain.RollContainer.rollMax:SetFontObject("CommDKPSmallRight")
      f.DKPModesMain.RollContainer.rollMax:SetTextInsets(10, 15, 5, 5)
      f.DKPModesMain.RollContainer.rollMax:SetText(core.DB.modes.rolls.max)
      f.DKPModesMain.RollContainer.rollMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()  
        self:ClearFocus()
      end)
      f.DKPModesMain.RollContainer.rollMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
          core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()  
        f.DKPModesMain.RollContainer.AddMax:SetFocus()
      end)
      f.DKPModesMain.RollContainer.rollMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()  
        self:ClearFocus()
      end)
      f.DKPModesMain.RollContainer.rollMax:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["MAXIMUMROLL"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["MAXIMUMROLLTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["MAXIMUMROLLTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show();
    end)
      f.DKPModesMain.RollContainer.rollMax:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)

      -- Max Roll Header
      f.DKPModesMain.RollContainer.rollMax.Header = f.DKPModesMain.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
      f.DKPModesMain.RollContainer.rollMax.Header:SetFontObject("CommDKPNormalLeft");
      f.DKPModesMain.RollContainer.rollMax.Header:SetPoint("BOTTOM", f.DKPModesMain.RollContainer.rollMax, "TOP", -20, 2);
      f.DKPModesMain.RollContainer.rollMax.Header:SetText(L["MAX"])

    f.DKPModesMain.RollContainer.rollMin.perc = f.DKPModesMain.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.RollContainer.rollMin.perc:SetFontObject("CommDKPSmallLeft");
    f.DKPModesMain.RollContainer.rollMin.perc:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMin, "RIGHT", -15, 0);
    f.DKPModesMain.RollContainer.rollMin.perc:SetText("%")
    f.DKPModesMain.RollContainer.rollMin.perc:SetShown(core.DB.modes.rolls.UsePerc);

    f.DKPModesMain.RollContainer.rollMax.perc = f.DKPModesMain.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.RollContainer.rollMax.perc:SetFontObject("CommDKPSmallLeft");
    f.DKPModesMain.RollContainer.rollMax.perc:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMax, "RIGHT", -15, 0);
    f.DKPModesMain.RollContainer.rollMax.perc:SetText("%")
    f.DKPModesMain.RollContainer.rollMax.perc:SetShown(core.DB.modes.rolls.UsePerc);

      -- Percent Rolls Checkbox
    f.DKPModesMain.RollContainer.UsePerc = CreateFrame("CheckButton", nil, f.DKPModesMain.RollContainer, "UICheckButtonTemplate");
    f.DKPModesMain.RollContainer.UsePerc:SetChecked(core.DB.modes.rolls.UsePerc)
    f.DKPModesMain.RollContainer.UsePerc:SetScale(0.6);
    f.DKPModesMain.RollContainer.UsePerc.text:SetText("  |cff5151de"..L["USEPERCENTAGE"].."|r");
    f.DKPModesMain.RollContainer.UsePerc.text:SetScale(1.5);
    f.DKPModesMain.RollContainer.UsePerc.text:SetFontObject("CommDKPSmallLeft")
    f.DKPModesMain.RollContainer.UsePerc:SetPoint("TOP", f.DKPModesMain.RollContainer.rollMin, "BOTTOMLEFT", 0, -10);
    f.DKPModesMain.RollContainer.UsePerc:SetScript("OnClick", function(self)
      core.DB.modes.rolls.UsePerc = self:GetChecked();
      f.DKPModesMain.RollContainer.rollMin.perc:SetShown(self:GetChecked())
      f.DKPModesMain.RollContainer.rollMax.perc:SetShown(self:GetChecked())
      if f.DKPModesMain.RollContainer.rollMax:GetNumber() == 0 then
        f.DKPModesMain.RollContainer.rollMax:SetNumber(100)
      end
      PlaySound(808);
    end)
    f.DKPModesMain.RollContainer.UsePerc:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT");
      GameTooltip:SetText(L["USEPERCFORROLLS"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["USEPERCROLLSTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["USEPERCROLLSTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show();
    end)
    f.DKPModesMain.RollContainer.UsePerc:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

      -- Add to Max Editbox
    f.DKPModesMain.RollContainer.AddMax = CreateFrame("EditBox", nil, f.DKPModesMain.RollContainer)
      f.DKPModesMain.RollContainer.AddMax:SetAutoFocus(false)
      f.DKPModesMain.RollContainer.AddMax:SetMultiLine(false)
      f.DKPModesMain.RollContainer.AddMax:SetPoint("TOP", f.DKPModesMain.RollContainer.rollMax, "BOTTOM", 0, -30)
      f.DKPModesMain.RollContainer.AddMax:SetSize(70, 24)
      f.DKPModesMain.RollContainer.AddMax:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
      });
      f.DKPModesMain.RollContainer.AddMax:SetBackdropColor(0,0,0,0.9)
      f.DKPModesMain.RollContainer.AddMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
      f.DKPModesMain.RollContainer.AddMax:SetMaxLetters(6)
      f.DKPModesMain.RollContainer.AddMax:SetTextColor(1, 1, 1, 1)
      f.DKPModesMain.RollContainer.AddMax:SetFontObject("CommDKPSmallRight")
      f.DKPModesMain.RollContainer.AddMax:SetTextInsets(10, 15, 5, 5)
      f.DKPModesMain.RollContainer.AddMax:SetText(core.DB.modes.rolls.AddToMax)
      f.DKPModesMain.RollContainer.AddMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
          self:ClearFocus()
      end)
      f.DKPModesMain.RollContainer.AddMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
          f.DKPModesMain.RollContainer.rollMin:SetFocus()
      end)
      f.DKPModesMain.RollContainer.AddMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
        core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
      core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
      core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
          self:ClearFocus()
      end)
      f.DKPModesMain.RollContainer.AddMax:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["ADDTOMAXROLL"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["ADDTOMAXROLLTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["ADDTOMAXROLLTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show();
    end)
      f.DKPModesMain.RollContainer.AddMax:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)

      -- Add to Max Header
      f.DKPModesMain.RollContainer.AddMax.Header = f.DKPModesMain.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
      f.DKPModesMain.RollContainer.AddMax.Header:SetFontObject("CommDKPSmallRight");
      f.DKPModesMain.RollContainer.AddMax.Header:SetPoint("RIGHT", f.DKPModesMain.RollContainer.AddMax, "LEFT", -5, 0);
      f.DKPModesMain.RollContainer.AddMax.Header:SetText(L["ADDTOMAXROLL"]..": ")

  -- Broadcast DKP Modes Button
  f.DKPModesMain.BroadcastSettings = self:CreateButton("BOTTOMRIGHT", f.DKPModesMain, "BOTTOMRIGHT", -30, 30, L["BROADCASTSETTINGS"]);
  f.DKPModesMain.BroadcastSettings:SetSize(110,25)
  f.DKPModesMain.BroadcastSettings:SetScript("OnClick", function()
    core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
    core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()  
    core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()  

    if (core.DB.modes.rolls.min > core.DB.modes.rolls.max and core.DB.modes.rolls.max ~= 0 and core.DB.modes.rolls.UserPerc == false) or (core.DB.modes.rolls.UsePerc and (core.DB.modes.rolls.min < 0 or core.DB.modes.rolls.max > 100 or core.DB.modes.rolls.min > core.DB.modes.rolls.max)) then
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
        table.insert(temptable1, core.DB.modes)
        table.insert(temptable1, core.DB.DKPBonus)
        table.insert(temptable1, core.DB.raiders)
        CommDKP.Sync:SendData("CommDKPDKPModes", temptable1)
        CommDKP:Print(L["DKPMODESENTCONF"])
        local temptable2 = {}
              table.insert(temptable2, core.DB.MinBidBySlot)
              table.insert(temptable2, CommDKP:FormatPriceTable())
              CommDKP.Sync:SendData("CommDKPMinBid", temptable2)
        local temptable3 = {}
              table.insert(temptable3, core.DB.MaxBidBySlot)
              table.insert(temptable3, CommDKP:GetTable(CommDKP_MaxBids, true))
              CommDKP.Sync:SendData("CommDKPMaxBid", temptable3)
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("SEND_MODES")
  end);
  f.DKPModesMain.BroadcastSettings:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["BROADCASTSETTINGS"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["BROADCASTSETTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show()
  end)
  f.DKPModesMain.BroadcastSettings:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
end
