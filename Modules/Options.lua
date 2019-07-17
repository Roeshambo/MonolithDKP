local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;


function MonDKP:Options()
  local default = {}
  MonDKP.ConfigTab4.default = default;

  for i=1, 6 do
    MonDKP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
    MonDKP.ConfigTab4.default[i]:SetAutoFocus(false)
    MonDKP.ConfigTab4.default[i]:SetMultiLine(false)
    MonDKP.ConfigTab4.default[i]:SetSize(60, 24)
    MonDKP.ConfigTab4.default[i]:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 1, 
    });
    MonDKP.ConfigTab4.default[i]:SetBackdropColor(0,0,0,0.9)
    MonDKP.ConfigTab4.default[i]:SetBackdropBorderColor(1,1,1,0.6)
    MonDKP.ConfigTab4.default[i]:SetMaxLetters(4)
    MonDKP.ConfigTab4.default[i]:SetTextColor(1, 1, 1, 1)
    MonDKP.ConfigTab4.default[i]:SetFontObject("GameFontNormalRight")
    MonDKP.ConfigTab4.default[i]:SetTextInsets(10, 10, 5, 5)
    MonDKP.ConfigTab4.default[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    MonDKP.ConfigTab4.default[i]:SetScript("OnEnter", function(self)
      if (self.tooltipText) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
      end
      if (self.tooltipDescription) then
        GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
        GameTooltip:Show();
      end
      if (self.tooltipWarning) then
        GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
        GameTooltip:Show();
      end
    end)
    MonDKP.ConfigTab4.default[i]:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    if i==1 then
      MonDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 155, -95)
    elseif i==4 then
      MonDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.default[1], "TOPLEFT", 200, 0)
    else
      MonDKP.ConfigTab4.default[i]:SetPoint("TOP", MonDKP.ConfigTab4.default[i-1], "BOTTOM", 0, -15)
    end
  end

  local DKPSettings = MonDKP:GetDKPSettings()
     
  MonDKP.ConfigTab4.default[1]:SetText(tonumber(DKPSettings["OnTimeBonus"]))
  MonDKP.ConfigTab4.default[1].tooltipText = "On Time Bonus"
  MonDKP.ConfigTab4.default[1].tooltipDescription = "Bonus given as for being present for a raid on time."
    
  MonDKP.ConfigTab4.default[2]:SetText(tonumber(DKPSettings["BossKillBonus"]))
  MonDKP.ConfigTab4.default[2].tooltipText = "Boss Kill Bonus"
  MonDKP.ConfigTab4.default[2].tooltipDescription = "Bonus given for killing a boss."
     
  MonDKP.ConfigTab4.default[3]:SetText(tonumber(DKPSettings["CompletionBonus"]))
  MonDKP.ConfigTab4.default[3].tooltipText = "Raid Completion Bonus"
  MonDKP.ConfigTab4.default[3].tooltipDescription = "Bonus given to everyone that attends a raid through completion."
    
  MonDKP.ConfigTab4.default[4]:SetText(tonumber(DKPSettings["NewBossKillBonus"]))
  MonDKP.ConfigTab4.default[4].tooltipText = "New Boss Kill Bonus"
  MonDKP.ConfigTab4.default[4].tooltipDescription = "Bonus given for first time boss kills during progression raids."

  MonDKP.ConfigTab4.default[5]:SetText(tonumber(DKPSettings["UnexcusedAbsence"]))
  MonDKP.ConfigTab4.default[5].tooltipText = "Unexcused Absence"
  MonDKP.ConfigTab4.default[5].tooltipDescription = "Penalty for unexcused absence from raid."
  MonDKP.ConfigTab4.default[5].tooltipWarning = "Should be a negative number."

  MonDKP.ConfigTab4.default[6]:SetText(tonumber(DKPSettings["DecayPercentage"]))
  MonDKP.ConfigTab4.default[6]:SetTextInsets(0, 15, 0, 0)
  MonDKP.ConfigTab4.default[6].tooltipText = "Decay Percentage"
  MonDKP.ConfigTab4.default[6].tooltipDescription = "Percentage to reduce all DKP values by for routine decay."
  MonDKP.ConfigTab4.default[6].tooltipWarning = "NOT a negative number."

  MonDKP.ConfigTab4.header = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.header:SetFontObject("MonDKPLargeCenter");
  MonDKP.ConfigTab4.header:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab4.header:SetText("Default Settings");

  MonDKP.ConfigTab4.description = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.description:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.header, "BOTTOMLEFT", 7, -15);
  MonDKP.ConfigTab4.description:SetText("Default DKP settings for raid bonus'.");

  --OnTimeBonus Header
  MonDKP.ConfigTab4.OnTimeHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.OnTimeHeader:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.OnTimeHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[1], "LEFT", -5, 0);
  MonDKP.ConfigTab4.OnTimeHeader:SetText("On Time Bonus: ")

  --BossKillBonus Header
  MonDKP.ConfigTab4.BossKillHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.BossKillHeader:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.BossKillHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[2], "LEFT", -5, 0);
  MonDKP.ConfigTab4.BossKillHeader:SetText("Boss Kill Bonus: ")

  --CompletionBonus Header
  MonDKP.ConfigTab4.CompleteHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.CompleteHeader:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.CompleteHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[3], "LEFT", -5, 0);
  MonDKP.ConfigTab4.CompleteHeader:SetText("Raid Completion Bonus: ")

  --NewBossKillBonus Header
  MonDKP.ConfigTab4.NewBossHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.NewBossHeader:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.NewBossHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[4], "LEFT", -5, 0);
  MonDKP.ConfigTab4.NewBossHeader:SetText("New Boss Kill Bonus: ")

  --UnexcusedAbsence Header
  MonDKP.ConfigTab4.UnexcusedHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.UnexcusedHeader:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.UnexcusedHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[5], "LEFT", -5, 0);
  MonDKP.ConfigTab4.UnexcusedHeader:SetText("Unexcused Absence: ")

  --DKP Decay Header
  MonDKP.ConfigTab4.DecayHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DecayHeader:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.DecayHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[6], "LEFT", -5, 0);
  MonDKP.ConfigTab4.DecayHeader:SetText("Decay Amount: ")

  MonDKP.ConfigTab4.DecayFooter = MonDKP.ConfigTab4.default[6]:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DecayFooter:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.DecayFooter:SetPoint("LEFT", MonDKP.ConfigTab4.default[6], "RIGHT", -15, 1);
  MonDKP.ConfigTab4.DecayFooter:SetText("%")

  -- Bid Timer Slider
  MonDKP.ConfigTab4.bidTimerSlider = CreateFrame("SLIDER", "$parentBidTimerSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
  MonDKP.ConfigTab4.bidTimerSlider:SetPoint("TOP", MonDKP.ConfigTab4.CompleteHeader, "BOTTOM", 50, -40);
  MonDKP.ConfigTab4.bidTimerSlider:SetMinMaxValues(10, 45);
  MonDKP.ConfigTab4.bidTimerSlider:SetValue(DKPSettings["BidTimer"]);
  MonDKP.ConfigTab4.bidTimerSlider:SetValueStep(1);
  MonDKP.ConfigTab4.bidTimerSlider.tooltipText = 'Bid Timer'
  MonDKP.ConfigTab4.bidTimerSlider.tooltipRequirement = "Default time used for bid timer in seconds."
  MonDKP.ConfigTab4.bidTimerSlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."Low"):SetText("10")
  getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."High"):SetText("45")
  MonDKP.ConfigTab4.bidTimerSlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.bidTimer:SetText(MonDKP.ConfigTab4.bidTimerSlider:GetValue())
  end)

  MonDKP.ConfigTab4.bidTimerHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.bidTimerHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.bidTimerHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.bidTimerSlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.bidTimerHeader:SetText("Bid Timer")

  MonDKP.ConfigTab4.bidTimer = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
  MonDKP.ConfigTab4.bidTimer:SetAutoFocus(false)
  MonDKP.ConfigTab4.bidTimer:SetMultiLine(false)
  MonDKP.ConfigTab4.bidTimer:SetSize(50, 18)
  MonDKP.ConfigTab4.bidTimer:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 1, 
  });
  MonDKP.ConfigTab4.bidTimer:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab4.bidTimer:SetBackdropBorderColor(1,1,1,0.6)
  MonDKP.ConfigTab4.bidTimer:SetMaxLetters(4)
  MonDKP.ConfigTab4.bidTimer:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab4.bidTimer:SetFontObject("MonDKPTinyCenter")
  MonDKP.ConfigTab4.bidTimer:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab4.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.bidTimer:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.bidTimerSlider:SetValue(MonDKP.ConfigTab4.bidTimer:GetNumber());
  end)
  MonDKP.ConfigTab4.bidTimer:SetPoint("TOP", MonDKP.ConfigTab4.bidTimerSlider, "BOTTOM", 0, -3)     
  MonDKP.ConfigTab4.bidTimer:SetText(MonDKP.ConfigTab4.bidTimerSlider:GetValue())

  -- History Limit Slider
  MonDKP.ConfigTab4.historySlider = CreateFrame("SLIDER", "$parentHistorySlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
  MonDKP.ConfigTab4.historySlider:SetPoint("LEFT", MonDKP.ConfigTab4.bidTimerSlider, "RIGHT", 50, 0);
  MonDKP.ConfigTab4.historySlider:SetMinMaxValues(500, 2500);
  MonDKP.ConfigTab4.historySlider:SetValue(DKPSettings["HistoryLimit"]);
  MonDKP.ConfigTab4.historySlider:SetValueStep(25);
  MonDKP.ConfigTab4.historySlider.tooltipText = 'Loot History Limit'
  MonDKP.ConfigTab4.historySlider.tooltipRequirement = "Maximum loot history entries stored."
  MonDKP.ConfigTab4.historySlider.tooltipWarning = "Warning: If you reduce this below the number of currently stored entries, the oldest will be deleted to meet the limit."
  MonDKP.ConfigTab4.historySlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.historySlider:GetName().."Low"):SetText("500")
  getglobal(MonDKP.ConfigTab4.historySlider:GetName().."High"):SetText("2500")
  MonDKP.ConfigTab4.historySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.history:SetText(MonDKP.ConfigTab4.historySlider:GetValue())
  end)

  MonDKP.ConfigTab4.HistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.HistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.HistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.historySlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.HistoryHeader:SetText("Loot History Limit")

  MonDKP.ConfigTab4.history = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
  MonDKP.ConfigTab4.history:SetAutoFocus(false)
  MonDKP.ConfigTab4.history:SetMultiLine(false)
  MonDKP.ConfigTab4.history:SetSize(50, 18)
  MonDKP.ConfigTab4.history:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 1, 
  });
  MonDKP.ConfigTab4.history:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab4.history:SetBackdropBorderColor(1,1,1,0.6)
  MonDKP.ConfigTab4.history:SetMaxLetters(4)
  MonDKP.ConfigTab4.history:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab4.history:SetFontObject("MonDKPTinyCenter")
  MonDKP.ConfigTab4.history:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab4.history:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.history:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.historySlider:SetValue(MonDKP.ConfigTab4.history:GetNumber());
  end)
  MonDKP.ConfigTab4.history:SetPoint("TOP", MonDKP.ConfigTab4.historySlider, "BOTTOM", 0, -3)     
  MonDKP.ConfigTab4.history:SetText(MonDKP.ConfigTab4.historySlider:GetValue())

-- Save Settings Button
MonDKP.ConfigTab4.submitSettings = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab4, "BOTTOMLEFT", 30, 80, "Save Settings");
MonDKP.ConfigTab4.submitSettings:SetSize(90,25)
MonDKP.ConfigTab4.submitSettings:SetScript("OnClick", function()
  for i=1, 5 do
    if not tonumber(MonDKP.ConfigTab4.default[i]:GetText()) then
      StaticPopupDialogs["OPTIONS_VALIDATION"] = {
        text = "Invalid Options Entry. Please use numbers.",
        button1 = "Ok",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show ("OPTIONS_VALIDATION")

    return;
    end
  end
  MonDKP_DB["DKPBonus"]["OnTimeBonus"] = MonDKP.ConfigTab4.default[1]:GetNumber();
  MonDKP_DB["DKPBonus"]["BossKillBonus"] = MonDKP.ConfigTab4.default[2]:GetNumber();
  MonDKP_DB["DKPBonus"]["CompletionBonus"] = MonDKP.ConfigTab4.default[3]:GetNumber();
  MonDKP_DB["DKPBonus"]["NewBossKillBonus"] = MonDKP.ConfigTab4.default[4]:GetNumber();
  MonDKP_DB["DKPBonus"]["UnexcusedAbsence"] = MonDKP.ConfigTab4.default[5]:GetNumber();
  MonDKP_DB["DKPBonus"]["BidTimer"] = MonDKP.ConfigTab4.bidTimer:GetNumber();
  MonDKP_DB["DKPBonus"]["HistoryLimit"] = MonDKP.ConfigTab4.history:GetNumber();
  MonDKP:Print("Default settings saved.")
end)



  -- Position Bid Timer Button

  MonDKP.ConfigTab4.moveTimer = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab4, "BOTTOMRIGHT", -30, 80, "Move Bid Timer");
  MonDKP.ConfigTab4.moveTimer:SetSize(110,25)
  MonDKP.ConfigTab4.moveTimer:SetScript("OnClick", function()
    MonDKP:StartTimer(120, "Move Me!")
  end)
end