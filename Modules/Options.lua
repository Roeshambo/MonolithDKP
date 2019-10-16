local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local moveTimerToggle = 0;

local function DrawPercFrame(box)
  --Draw % signs if set to percent
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box], "RIGHT", -15, 0);
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetText("%")
end

local function SaveSettings()
  if MonDKP.ConfigTab4.default[1] then
    core.MonDKPUI:SetScale(MonDKP_DB["defaults"]["MonDKPScaleSize"]);
    MonDKP_DB["DKPBonus"]["OnTimeBonus"] = MonDKP.ConfigTab4.default[1]:GetNumber();
    MonDKP_DB["DKPBonus"]["BossKillBonus"] = MonDKP.ConfigTab4.default[2]:GetNumber();
    MonDKP_DB["DKPBonus"]["CompletionBonus"] = MonDKP.ConfigTab4.default[3]:GetNumber();
    MonDKP_DB["DKPBonus"]["NewBossKillBonus"] = MonDKP.ConfigTab4.default[4]:GetNumber();
    MonDKP_DB["DKPBonus"]["UnexcusedAbsence"] = MonDKP.ConfigTab4.default[5]:GetNumber();
    if MonDKP.ConfigTab4.default[6]:GetNumber() < 0 then
      MonDKP_DB["DKPBonus"]["DecayPercentage"] = 0 - MonDKP.ConfigTab4.default[6]:GetNumber();
    else
      MonDKP_DB["DKPBonus"]["DecayPercentage"] = MonDKP.ConfigTab4.default[6]:GetNumber();
    end
    MonDKP.ConfigTab2.decayDKP:SetNumber(MonDKP_DB["DKPBonus"]["DecayPercentage"]);
    MonDKP.ConfigTab4.default[6]:SetNumber(MonDKP_DB["DKPBonus"]["DecayPercentage"])
    MonDKP_DB["DKPBonus"]["BidTimer"] = MonDKP.ConfigTab4.bidTimer:GetNumber();

    MonDKP_DB.MinBidBySlot.Head = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:GetNumber()
    MonDKP_DB.MinBidBySlot.Neck = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:GetNumber()
    MonDKP_DB.MinBidBySlot.Shoulders = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3]:GetNumber()
    MonDKP_DB.MinBidBySlot.Cloak = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4]:GetNumber()
    MonDKP_DB.MinBidBySlot.Chest = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5]:GetNumber()
    MonDKP_DB.MinBidBySlot.Bracers = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6]:GetNumber()
    MonDKP_DB.MinBidBySlot.Hands = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7]:GetNumber()
    MonDKP_DB.MinBidBySlot.Belt = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8]:GetNumber()
    MonDKP_DB.MinBidBySlot.Legs = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:GetNumber()
    MonDKP_DB.MinBidBySlot.Boots = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10]:GetNumber()
    MonDKP_DB.MinBidBySlot.Ring = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11]:GetNumber()
    MonDKP_DB.MinBidBySlot.Trinket = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12]:GetNumber()
    MonDKP_DB.MinBidBySlot.OneHanded = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13]:GetNumber()
    MonDKP_DB.MinBidBySlot.TwoHanded = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:GetNumber()
    MonDKP_DB.MinBidBySlot.OffHand = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15]:GetNumber()
    MonDKP_DB.MinBidBySlot.Range = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16]:GetNumber()
    MonDKP_DB.MinBidBySlot.Other = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:GetNumber()
  end

  MonDKP_DB["defaults"]["HistoryLimit"] = MonDKP.ConfigTab4.history:GetNumber();
  MonDKP_DB["defaults"]["DKPHistoryLimit"] = MonDKP.ConfigTab4.DKPHistory:GetNumber();
  MonDKP_DB["defaults"]["TooltipHistoryCount"] = MonDKP.ConfigTab4.TooltipHistory:GetNumber();
  DKPTable_Update()
end

function MonDKP:Options()
  local default = {}
  MonDKP.ConfigTab4.default = default;
  local DKPSettings = MonDKP:GetDKPSettings();
  local MinBidSettings = MonDKP:GetMinBidSettings();


  MonDKP.ConfigTab4.header = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.header:SetFontObject("MonDKPLargeCenter");
  MonDKP.ConfigTab4.header:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab4.header:SetText(L["DefaultSettings"]);
  MonDKP.ConfigTab4.header:SetScale(1.2)

  if core.IsOfficer == true then
    MonDKP.ConfigTab4.description = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.description:SetFontObject("MonDKPNormalLeft");
    MonDKP.ConfigTab4.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.header, "BOTTOMLEFT", 7, -15);
    MonDKP.ConfigTab4.description:SetText("|CFFcca600"..L["DefaultDKPAwardValues"].."|r");
  
    for i=1, 6 do
      MonDKP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
      MonDKP.ConfigTab4.default[i]:SetAutoFocus(false)
      MonDKP.ConfigTab4.default[i]:SetMultiLine(false)
      MonDKP.ConfigTab4.default[i]:SetSize(80, 24)
      MonDKP.ConfigTab4.default[i]:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
      });
      MonDKP.ConfigTab4.default[i]:SetBackdropColor(0,0,0,0.9)
      MonDKP.ConfigTab4.default[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
      MonDKP.ConfigTab4.default[i]:SetMaxLetters(6)
      MonDKP.ConfigTab4.default[i]:SetTextColor(1, 1, 1, 1)
      MonDKP.ConfigTab4.default[i]:SetFontObject("MonDKPSmallRight")
      MonDKP.ConfigTab4.default[i]:SetTextInsets(10, 10, 5, 5)
      MonDKP.ConfigTab4.default[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:HighlightText(0,0)
        SaveSettings()
        self:ClearFocus()
      end)
      MonDKP.ConfigTab4.default[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
        self:HighlightText(0,0)
        SaveSettings()
        self:ClearFocus()
      end)
      MonDKP.ConfigTab4.default[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
        SaveSettings()
        if i == 6 then
          self:HighlightText(0,0)
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetFocus()
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:HighlightText()
        else
          self:HighlightText(0,0)
          MonDKP.ConfigTab4.default[i+1]:SetFocus()
          MonDKP.ConfigTab4.default[i+1]:HighlightText()
        end
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
        MonDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 144, -84)
      elseif i==4 then
        MonDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.default[1], "TOPLEFT", 212, 0)
      else
        MonDKP.ConfigTab4.default[i]:SetPoint("TOP", MonDKP.ConfigTab4.default[i-1], "BOTTOM", 0, -22)
      end
    end

    -- Modes Button
    MonDKP.ConfigTab4.ModesButton = self:CreateButton("TOPRIGHT", MonDKP.ConfigTab4, "TOPRIGHT", -40, -20, L["DKPModes"]);
    MonDKP.ConfigTab4.ModesButton:SetSize(110,25)
    MonDKP.ConfigTab4.ModesButton:SetScript("OnClick", function()
      MonDKP:ToggleDKPModesWindow()
    end);
    MonDKP.ConfigTab4.ModesButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["DKPModes"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["DKPModesTTDesc2"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["DKPModesTTWarn"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    MonDKP.ConfigTab4.ModesButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    end)
    if not core.IsOfficer then
      MonDKP.ConfigTab4.ModesButton:Hide()
    end

    MonDKP.ConfigTab4.default[1]:SetText(tonumber(DKPSettings["OnTimeBonus"]))
    MonDKP.ConfigTab4.default[1].tooltipText = L["OnTimeBonus"]
    MonDKP.ConfigTab4.default[1].tooltipDescription = L["OnTimeBonusTTDesc"]
      
    MonDKP.ConfigTab4.default[2]:SetText(tonumber(DKPSettings["BossKillBonus"]))
    MonDKP.ConfigTab4.default[2].tooltipText = L["BossKillBonus"]
    MonDKP.ConfigTab4.default[2].tooltipDescription = L["BossKillBonusTTDesc"]
       
    MonDKP.ConfigTab4.default[3]:SetText(tonumber(DKPSettings["CompletionBonus"]))
    MonDKP.ConfigTab4.default[3].tooltipText = L["RaidCompletionBonus"]
    MonDKP.ConfigTab4.default[3].tooltipDescription = L["RaidCompleteBonusTT"]
      
    MonDKP.ConfigTab4.default[4]:SetText(tonumber(DKPSettings["NewBossKillBonus"]))
    MonDKP.ConfigTab4.default[4].tooltipText = L["NewBossKillBonus"]
    MonDKP.ConfigTab4.default[4].tooltipDescription = L["NewBossKillTTDesc"]

    MonDKP.ConfigTab4.default[5]:SetText(tonumber(DKPSettings["UnexcusedAbsence"]))
    MonDKP.ConfigTab4.default[5].tooltipText = L["UnexcusedAbsence"]
    MonDKP.ConfigTab4.default[5].tooltipDescription = L["UnexcusedTTDesc"]
    MonDKP.ConfigTab4.default[5].tooltipWarning = L["UnexcusedTTWarn"]

    MonDKP.ConfigTab4.default[6]:SetText(tonumber(DKPSettings["DecayPercentage"]))
    MonDKP.ConfigTab4.default[6]:SetTextInsets(0, 15, 0, 0)
    MonDKP.ConfigTab4.default[6].tooltipText = L["DecayPercentage"]
    MonDKP.ConfigTab4.default[6].tooltipDescription = L["DecayPercentageTTDesc"]
    MonDKP.ConfigTab4.default[6].tooltipWarning = L["DecayPercentageTTWarn"]

    --OnTimeBonus Header
    MonDKP.ConfigTab4.OnTimeHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.OnTimeHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.OnTimeHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[1], "LEFT", 0, 0);
    MonDKP.ConfigTab4.OnTimeHeader:SetText(L["OnTimeBonus"]..": ")

    --BossKillBonus Header
    MonDKP.ConfigTab4.BossKillHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.BossKillHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.BossKillHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[2], "LEFT", 0, 0);
    MonDKP.ConfigTab4.BossKillHeader:SetText(L["BossKillBonus"]..": ")

    --CompletionBonus Header
    MonDKP.ConfigTab4.CompleteHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.CompleteHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.CompleteHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[3], "LEFT", 0, 0);
    MonDKP.ConfigTab4.CompleteHeader:SetText(L["RaidCompletionBonus"]..": ")

    --NewBossKillBonus Header
    MonDKP.ConfigTab4.NewBossHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.NewBossHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.NewBossHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[4], "LEFT", 0, 0);
    MonDKP.ConfigTab4.NewBossHeader:SetText(L["NewBossKillBonus"]..": ")

    --UnexcusedAbsence Header
    MonDKP.ConfigTab4.UnexcusedHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.UnexcusedHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.UnexcusedHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[5], "LEFT", 0, 0);
    MonDKP.ConfigTab4.UnexcusedHeader:SetText(L["UnexcusedAbsence"]..": ")

    --DKP Decay Header
    MonDKP.ConfigTab4.DecayHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.DecayHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.DecayHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[6], "LEFT", 0, 0);
    MonDKP.ConfigTab4.DecayHeader:SetText(L["DecayAmount"]..": ")

    MonDKP.ConfigTab4.DecayFooter = MonDKP.ConfigTab4.default[6]:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.DecayFooter:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.DecayFooter:SetPoint("LEFT", MonDKP.ConfigTab4.default[6], "RIGHT", -15, -1);
    MonDKP.ConfigTab4.DecayFooter:SetText("%")

    -- Default Minimum Bids Container Frame
    MonDKP.ConfigTab4.DefaultMinBids = CreateFrame("Frame", nil, MonDKP.ConfigTab4);
    MonDKP.ConfigTab4.DefaultMinBids:SetPoint("TOPLEFT", MonDKP.ConfigTab4.default[3], "BOTTOMLEFT", -130, -52)
    MonDKP.ConfigTab4.DefaultMinBids:SetSize(420, 410);

    MonDKP.ConfigTab4.DefaultMinBids.description = MonDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.DefaultMinBids.description:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.DefaultMinBids.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 15, 15);

      -- DEFAULT min bids Create EditBoxes
      local SlotBox = {}
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox = SlotBox;

      for i=1, 17 do
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i] = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetAutoFocus(false)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMultiLine(false)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetSize(60, 24)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdrop({
          bgFile   = "Textures\\white.blp", tile = true,
          edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
        });
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMaxLetters(6)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetFontObject("MonDKPSmallRight")
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
          if i == 8 then
            self:HighlightText(0,0)
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetFocus()
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:HighlightText()
            SaveSettings()
          elseif i == 5 then
            self:HighlightText(0,0)
            MonDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          elseif i == 13 then
            self:HighlightText(0,0)
            MonDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetFocus()
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:HighlightText()
            SaveSettings()
          elseif i == 17 then
            self:HighlightText(0,0)
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetFocus()
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:HighlightText()
            SaveSettings()
          elseif i == 16 then
            self:HighlightText(0,0)
            MonDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(1)
            MonDKP.ConfigTab4.default[1]:SetFocus()
            MonDKP.ConfigTab4.default[1]:HighlightText()
            SaveSettings()
          else
            self:HighlightText(0,0)
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
            MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          end
        end)
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnter", function(self)
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
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)

        -- Slot Headers
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header = MonDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetFontObject("MonDKPNormalLeft");
        MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetPoint("RIGHT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i], "LEFT", 0, 0);

        if i==1 then
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 100, -10)
        elseif i==9 then
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1], "TOPLEFT", 150, 0)
        elseif i==17 then
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8], "BOTTOM", 0, -22)
        else
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i-1], "BOTTOM", 0, -22)
        end
      end

      local prefix;

      if MonDKP_DB.modes.mode == "Minimum Bid Values" then
        prefix = L["MinimumBid"];
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DefaultMinBidValues"].."|r");
      elseif MonDKP_DB.modes.mode == "Static Item Values" then
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DefaultItemCosts"].."|r");
        if MonDKP_DB.modes.costvalue == "Integer" then
          prefix = L["DKPPrice"]
        elseif MonDKP_DB.modes.costvalue == "Percent" then
          prefix = L["PercentCost"]
        end
      elseif MonDKP_DB.modes.mode == "Roll Based Bidding" then
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DefaultItemCosts"].."|r");
        if MonDKP_DB.modes.costvalue == "Integer" then
          prefix = L["DKPPrice"]
        elseif MonDKP_DB.modes.costvalue == "Percent" then
          prefix = L["PercentCost"]
        end
      elseif MonDKP_DB.modes.mode == "Zero Sum" then
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DefaultItemCosts"].."|r");
        if MonDKP_DB.modes.costvalue == "Integer" then
          prefix = L["DKPPrice"]
        elseif MonDKP_DB.modes.costvalue == "Percent" then
          prefix = L["PercentCost"]
        end
      end

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].Header:SetText(L["Head"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetText(tonumber(MinBidSettings["Head"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipText = L["Head"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipDescription = prefix.." "..L["ForHeadSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].Header:SetText(L["Neck"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:SetText(tonumber(MinBidSettings["Neck"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipText = L["Neck"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipDescription = prefix.." "..L["ForNeckSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3].Header:SetText(L["Shoulders"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3]:SetText(tonumber(MinBidSettings["Shoulders"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipText = L["Shoulders"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipDescription = prefix.." "..L["ForShoulderSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4].Header:SetText(L["Cloak"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4]:SetText(tonumber(MinBidSettings["Cloak"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipText = L["Cloak"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipDescription = prefix.." "..L["ForBackSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5].Header:SetText(L["Chest"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5]:SetText(tonumber(MinBidSettings["Chest"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipText = L["Chest"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipDescription = prefix.." "..L["ForChestSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6].Header:SetText(L["Bracers"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6]:SetText(tonumber(MinBidSettings["Bracers"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipText = L["Bracers"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipDescription = prefix.." "..L["ForWristSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7].Header:SetText(L["Hands"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7]:SetText(tonumber(MinBidSettings["Hands"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipText = L["Hands"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipDescription = prefix.." "..L["ForHandSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8].Header:SetText(L["Belt"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8]:SetText(tonumber(MinBidSettings["Belt"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipText = L["Belt"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipDescription = prefix.." "..L["ForWaistSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9].Header:SetText(L["Legs"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetText(tonumber(MinBidSettings["Legs"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipText = L["Legs"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipDescription = prefix.." "..L["ForLegSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10].Header:SetText(L["Boots"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10]:SetText(tonumber(MinBidSettings["Boots"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipText = L["Boots"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipDescription = prefix.." "..L["ForFeetSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11].Header:SetText(L["Rings"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11]:SetText(tonumber(MinBidSettings["Ring"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipText = L["Rings"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipDescription = prefix.." "..L["ForFingerSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12].Header:SetText(L["Trinket"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12]:SetText(tonumber(MinBidSettings["Trinket"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipText = L["Trinket"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipDescription = prefix.." "..L["ForTrinketSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13].Header:SetText(L["OneHanded"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13]:SetText(tonumber(MinBidSettings["OneHanded"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipText = L["OneHandedWeapons"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipDescription = prefix.." "..L["ForOneHandSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14].Header:SetText(L["TwoHanded"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetText(tonumber(MinBidSettings["TwoHanded"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipText = L["TwoHandedWeapons"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipDescription = prefix.." "..L["ForTwoHandSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15].Header:SetText(L["OffHand"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15]:SetText(tonumber(MinBidSettings["OffHand"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipText = L["OffHandItems"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipDescription = prefix.." "..L["ForOffHandSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16].Header:SetText(L["Range"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16]:SetText(tonumber(MinBidSettings["Range"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipText = L["Range"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipDescription = prefix.." "..L["ForRangeSlot"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17].Header:SetText(L["Other"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetText(tonumber(MinBidSettings["Other"]))
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipText = L["Other"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipDescription = prefix.." "..L["ForOtherSlot"]

      if MonDKP_DB.modes.costvalue == "Percent" then
        for i=1, #MonDKP.ConfigTab4.DefaultMinBids.SlotBox do
          DrawPercFrame(i)
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
        end
      end

      -- Broadcast Minimum Bids Button
      MonDKP.ConfigTab4.BroadcastMinBids = self:CreateButton("TOP", MonDKP.ConfigTab4, "BOTTOM", 30, 30, L["BcastValues"]);
      MonDKP.ConfigTab4.BroadcastMinBids:ClearAllPoints();
      MonDKP.ConfigTab4.BroadcastMinBids:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17], "RIGHT", 41, 0)
      MonDKP.ConfigTab4.BroadcastMinBids:SetSize(110,25)
      MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnClick", function()
        StaticPopupDialogs["SEND_MINBIDS"] = {
          text = L["BcastMinBidConfirm"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            local temptable = {}
            table.insert(temptable, MonDKP_DB.MinBidBySlot)
            table.insert(temptable, MonDKP_MinBids)
            MonDKP.Sync:SendData("MonDKPMinBids", temptable)
            MonDKP:Print(L["MinBidValuesSent"])
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("SEND_MINBIDS")
      end);
      MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BcastValues"], 0.25, 0.75, 0.90, 1, true)
        GameTooltip:AddLine(L["BcastValuesTTDesc"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["BcastValuesTTWarn"], 1.0, 0, 0, true);
        GameTooltip:Show()
      end)
      MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)

    -- Bid Timer Slider
    MonDKP.ConfigTab4.bidTimerSlider = CreateFrame("SLIDER", "$parentBidTimerSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
    MonDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 54, -40);
    MonDKP.ConfigTab4.bidTimerSlider:SetMinMaxValues(10, 90);
    MonDKP.ConfigTab4.bidTimerSlider:SetValue(DKPSettings["BidTimer"]);
    MonDKP.ConfigTab4.bidTimerSlider:SetValueStep(1);
    MonDKP.ConfigTab4.bidTimerSlider.tooltipText = L["BidTimer"]
    MonDKP.ConfigTab4.bidTimerSlider.tooltipRequirement = L["BidTimerDefaultTTDesc"]
    MonDKP.ConfigTab4.bidTimerSlider:SetObeyStepOnDrag(true);
    getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."Low"):SetText("10")
    getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."High"):SetText("90")
    MonDKP.ConfigTab4.bidTimerSlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
      MonDKP.ConfigTab4.bidTimer:SetText(MonDKP.ConfigTab4.bidTimerSlider:GetValue())
    end)

    MonDKP.ConfigTab4.bidTimerHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.bidTimerHeader:SetFontObject("MonDKPTinyCenter");
    MonDKP.ConfigTab4.bidTimerHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.bidTimerSlider, "TOP", 0, 3);
    MonDKP.ConfigTab4.bidTimerHeader:SetText(L["BidTimer"])

    MonDKP.ConfigTab4.bidTimer = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
    MonDKP.ConfigTab4.bidTimer:SetAutoFocus(false)
    MonDKP.ConfigTab4.bidTimer:SetMultiLine(false)
    MonDKP.ConfigTab4.bidTimer:SetSize(50, 18)
    MonDKP.ConfigTab4.bidTimer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
    MonDKP.ConfigTab4.bidTimer:SetBackdropColor(0,0,0,0.9)
    MonDKP.ConfigTab4.bidTimer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    MonDKP.ConfigTab4.bidTimer:SetMaxLetters(4)
    MonDKP.ConfigTab4.bidTimer:SetTextColor(1, 1, 1, 1)
    MonDKP.ConfigTab4.bidTimer:SetFontObject("MonDKPTinyCenter")
    MonDKP.ConfigTab4.bidTimer:SetTextInsets(10, 10, 5, 5)
    MonDKP.ConfigTab4.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    MonDKP.ConfigTab4.bidTimer:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    MonDKP.ConfigTab4.bidTimer:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
      MonDKP.ConfigTab4.bidTimerSlider:SetValue(MonDKP.ConfigTab4.bidTimer:GetNumber());
    end)
    MonDKP.ConfigTab4.bidTimer:SetPoint("TOP", MonDKP.ConfigTab4.bidTimerSlider, "BOTTOM", 0, -3)     
    MonDKP.ConfigTab4.bidTimer:SetText(MonDKP.ConfigTab4.bidTimerSlider:GetValue())
  end

  -- Tooltip History Slider
  MonDKP.ConfigTab4.TooltipHistorySlider = CreateFrame("SLIDER", "$parentTooltipHistorySlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
  if MonDKP.ConfigTab4.bidTimer then
    MonDKP.ConfigTab4.TooltipHistorySlider:SetPoint("LEFT", MonDKP.ConfigTab4.bidTimerSlider, "RIGHT", 30, 0);
  else
    MonDKP.ConfigTab4.TooltipHistorySlider:SetPoint("TOP", MonDKP.ConfigTab4, "TOP", 1, -107);
  end
  MonDKP.ConfigTab4.TooltipHistorySlider:SetMinMaxValues(5, 35);
  MonDKP.ConfigTab4.TooltipHistorySlider:SetValue(MonDKP_DB.defaults.TooltipHistoryCount);
  MonDKP.ConfigTab4.TooltipHistorySlider:SetValueStep(1);
  MonDKP.ConfigTab4.TooltipHistorySlider.tooltipText = L["TTHistoryCount"]
  MonDKP.ConfigTab4.TooltipHistorySlider.tooltipRequirement = L["TTHistoryCountTTDesc"]
  MonDKP.ConfigTab4.TooltipHistorySlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.TooltipHistorySlider:GetName().."Low"):SetText("5")
  getglobal(MonDKP.ConfigTab4.TooltipHistorySlider:GetName().."High"):SetText("35")
  MonDKP.ConfigTab4.TooltipHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.TooltipHistory:SetText(MonDKP.ConfigTab4.TooltipHistorySlider:GetValue())
  end)

  MonDKP.ConfigTab4.TooltipHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.TooltipHistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.TooltipHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.TooltipHistorySlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.TooltipHistoryHeader:SetText(L["TTHistoryCount"])

  MonDKP.ConfigTab4.TooltipHistory = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
  MonDKP.ConfigTab4.TooltipHistory:SetAutoFocus(false)
  MonDKP.ConfigTab4.TooltipHistory:SetMultiLine(false)
  MonDKP.ConfigTab4.TooltipHistory:SetSize(50, 18)
  MonDKP.ConfigTab4.TooltipHistory:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  MonDKP.ConfigTab4.TooltipHistory:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab4.TooltipHistory:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
  MonDKP.ConfigTab4.TooltipHistory:SetMaxLetters(4)
  MonDKP.ConfigTab4.TooltipHistory:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab4.TooltipHistory:SetFontObject("MonDKPTinyCenter")
  MonDKP.ConfigTab4.TooltipHistory:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab4.TooltipHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.TooltipHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.TooltipHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.TooltipHistorySlider:SetValue(MonDKP.ConfigTab4.TooltipHistory:GetNumber());
  end)
  MonDKP.ConfigTab4.TooltipHistory:SetPoint("TOP", MonDKP.ConfigTab4.TooltipHistorySlider, "BOTTOM", 0, -3)     
  MonDKP.ConfigTab4.TooltipHistory:SetText(MonDKP.ConfigTab4.TooltipHistorySlider:GetValue())


  -- Loot History Limit Slider
  MonDKP.ConfigTab4.historySlider = CreateFrame("SLIDER", "$parentHistorySlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
  if MonDKP.ConfigTab4.bidTimer then
    MonDKP.ConfigTab4.historySlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.bidTimerSlider, "BOTTOMLEFT", 0, -50);
  else
    MonDKP.ConfigTab4.historySlider:SetPoint("TOPRIGHT", MonDKP.ConfigTab4.TooltipHistorySlider, "BOTTOMLEFT", 56, -49);
  end
  MonDKP.ConfigTab4.historySlider:SetMinMaxValues(500, 2500);
  MonDKP.ConfigTab4.historySlider:SetValue(MonDKP_DB.defaults.HistoryLimit);
  MonDKP.ConfigTab4.historySlider:SetValueStep(25);
  MonDKP.ConfigTab4.historySlider.tooltipText = L["LootHistoryLimit"]
  MonDKP.ConfigTab4.historySlider.tooltipRequirement = L["LootHistLimitTTDesc"]
  MonDKP.ConfigTab4.historySlider.tooltipWarning = L["LootHistLimitTTWarn"]
  MonDKP.ConfigTab4.historySlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.historySlider:GetName().."Low"):SetText("500")
  getglobal(MonDKP.ConfigTab4.historySlider:GetName().."High"):SetText("2500")
  MonDKP.ConfigTab4.historySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.history:SetText(MonDKP.ConfigTab4.historySlider:GetValue())
  end)

  MonDKP.ConfigTab4.HistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.HistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.HistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.historySlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.HistoryHeader:SetText(L["LootHistoryLimit"])

  MonDKP.ConfigTab4.history = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
  MonDKP.ConfigTab4.history:SetAutoFocus(false)
  MonDKP.ConfigTab4.history:SetMultiLine(false)
  MonDKP.ConfigTab4.history:SetSize(50, 18)
  MonDKP.ConfigTab4.history:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  MonDKP.ConfigTab4.history:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab4.history:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
  MonDKP.ConfigTab4.history:SetMaxLetters(4)
  MonDKP.ConfigTab4.history:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab4.history:SetFontObject("MonDKPTinyCenter")
  MonDKP.ConfigTab4.history:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab4.history:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.history:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.history:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.historySlider:SetValue(MonDKP.ConfigTab4.history:GetNumber());
  end)
  MonDKP.ConfigTab4.history:SetPoint("TOP", MonDKP.ConfigTab4.historySlider, "BOTTOM", 0, -3)     
  MonDKP.ConfigTab4.history:SetText(MonDKP.ConfigTab4.historySlider:GetValue())

  -- DKP History Limit Slider
  MonDKP.ConfigTab4.DKPHistorySlider = CreateFrame("SLIDER", "$parentDKPHistorySlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
  MonDKP.ConfigTab4.DKPHistorySlider:SetPoint("LEFT", MonDKP.ConfigTab4.historySlider, "RIGHT", 30, 0);
  MonDKP.ConfigTab4.DKPHistorySlider:SetMinMaxValues(500, 2500);
  MonDKP.ConfigTab4.DKPHistorySlider:SetValue(MonDKP_DB.defaults.DKPHistoryLimit);
  MonDKP.ConfigTab4.DKPHistorySlider:SetValueStep(25);
  MonDKP.ConfigTab4.DKPHistorySlider.tooltipText = L["DKPHistoryLimit"]
  MonDKP.ConfigTab4.DKPHistorySlider.tooltipRequirement = L["DKPHistLimitTTDesc"]
  MonDKP.ConfigTab4.DKPHistorySlider.tooltipWarning = L["DKPHistLimitTTWarn"]
  MonDKP.ConfigTab4.DKPHistorySlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.DKPHistorySlider:GetName().."Low"):SetText("500")
  getglobal(MonDKP.ConfigTab4.DKPHistorySlider:GetName().."High"):SetText("2500")
  MonDKP.ConfigTab4.DKPHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.DKPHistory:SetText(MonDKP.ConfigTab4.DKPHistorySlider:GetValue())
  end)

  MonDKP.ConfigTab4.DKPHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.DKPHistorySlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["DKPHistoryLimit"])

  MonDKP.ConfigTab4.DKPHistory = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
  MonDKP.ConfigTab4.DKPHistory:SetAutoFocus(false)
  MonDKP.ConfigTab4.DKPHistory:SetMultiLine(false)
  MonDKP.ConfigTab4.DKPHistory:SetSize(50, 18)
  MonDKP.ConfigTab4.DKPHistory:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  MonDKP.ConfigTab4.DKPHistory:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab4.DKPHistory:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  MonDKP.ConfigTab4.DKPHistory:SetMaxLetters(4)
  MonDKP.ConfigTab4.DKPHistory:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab4.DKPHistory:SetFontObject("MonDKPTinyCenter")
  MonDKP.ConfigTab4.DKPHistory:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab4.DKPHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.DKPHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.DKPHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.DKPHistorySlider:SetValue(MonDKP.ConfigTab4.history:GetNumber());
  end)
  MonDKP.ConfigTab4.DKPHistory:SetPoint("TOP", MonDKP.ConfigTab4.DKPHistorySlider, "BOTTOM", 0, -3)     
  MonDKP.ConfigTab4.DKPHistory:SetText(MonDKP.ConfigTab4.DKPHistorySlider:GetValue())

  -- Bid Timer Size Slider
  MonDKP.ConfigTab4.TimerSizeSlider = CreateFrame("SLIDER", "$parentBidTimerSizeSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
  MonDKP.ConfigTab4.TimerSizeSlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.historySlider, "BOTTOMLEFT", 0, -50);
  MonDKP.ConfigTab4.TimerSizeSlider:SetMinMaxValues(0.5, 2.0);
  MonDKP.ConfigTab4.TimerSizeSlider:SetValue(MonDKP_DB.defaults.BidTimerSize);
  MonDKP.ConfigTab4.TimerSizeSlider:SetValueStep(0.05);
  MonDKP.ConfigTab4.TimerSizeSlider.tooltipText = L["TimerSize"]
  MonDKP.ConfigTab4.TimerSizeSlider.tooltipRequirement = L["TimerSizeTTDesc"]
  MonDKP.ConfigTab4.TimerSizeSlider.tooltipWarning = L["TimerSizeTTWarn"]
  MonDKP.ConfigTab4.TimerSizeSlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.TimerSizeSlider:GetName().."Low"):SetText("50%")
  getglobal(MonDKP.ConfigTab4.TimerSizeSlider:GetName().."High"):SetText("200%")
  MonDKP.ConfigTab4.TimerSizeSlider:SetScript("OnValueChanged", function(self)   
    MonDKP.ConfigTab4.TimerSize:SetText(MonDKP.ConfigTab4.TimerSizeSlider:GetValue())
    MonDKP_DB.defaults.BidTimerSize = MonDKP.ConfigTab4.TimerSizeSlider:GetValue();
    MonDKP.BidTimer:SetScale(MonDKP_DB.defaults.BidTimerSize);
  end)

  MonDKP.ConfigTab4.DKPHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.TimerSizeSlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["TimerSize"])

  MonDKP.ConfigTab4.TimerSize = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
  MonDKP.ConfigTab4.TimerSize:SetAutoFocus(false)
  MonDKP.ConfigTab4.TimerSize:SetMultiLine(false)
  MonDKP.ConfigTab4.TimerSize:SetSize(50, 18)
  MonDKP.ConfigTab4.TimerSize:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  MonDKP.ConfigTab4.TimerSize:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab4.TimerSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  MonDKP.ConfigTab4.TimerSize:SetMaxLetters(4)
  MonDKP.ConfigTab4.TimerSize:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab4.TimerSize:SetFontObject("MonDKPTinyCenter")
  MonDKP.ConfigTab4.TimerSize:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab4.TimerSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.TimerSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.TimerSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.TimerSizeSlider:SetValue(MonDKP.ConfigTab4.TimerSize:GetNumber());
  end)
  MonDKP.ConfigTab4.TimerSize:SetPoint("TOP", MonDKP.ConfigTab4.TimerSizeSlider, "BOTTOM", 0, -3)     
  MonDKP.ConfigTab4.TimerSize:SetText(MonDKP.ConfigTab4.TimerSizeSlider:GetValue())

  -- UI Scale Size Slider
  MonDKP.ConfigTab4.MonDKPScaleSize = CreateFrame("SLIDER", "$parentMonDKPScaleSizeSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
  MonDKP.ConfigTab4.MonDKPScaleSize:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DKPHistorySlider, "BOTTOMLEFT", 0, -50);
  MonDKP.ConfigTab4.MonDKPScaleSize:SetMinMaxValues(0.5, 2.0);
  MonDKP.ConfigTab4.MonDKPScaleSize:SetValue(MonDKP_DB.defaults.MonDKPScaleSize);
  MonDKP.ConfigTab4.MonDKPScaleSize:SetValueStep(0.05);
  MonDKP.ConfigTab4.MonDKPScaleSize.tooltipText = L["MonDKPScaleSize"]
  MonDKP.ConfigTab4.MonDKPScaleSize.tooltipRequirement = L["MonDKPScaleSizeTTDesc"]
  MonDKP.ConfigTab4.MonDKPScaleSize.tooltipWarning = L["MonDKPScaleSizeTTWarn"]
  MonDKP.ConfigTab4.MonDKPScaleSize:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.MonDKPScaleSize:GetName().."Low"):SetText("50%")
  getglobal(MonDKP.ConfigTab4.MonDKPScaleSize:GetName().."High"):SetText("200%")
  MonDKP.ConfigTab4.MonDKPScaleSize:SetScript("OnValueChanged", function(self)   
    MonDKP.ConfigTab4.UIScaleSize:SetText(MonDKP.ConfigTab4.MonDKPScaleSize:GetValue())
    MonDKP_DB.defaults.MonDKPScaleSize = MonDKP.ConfigTab4.MonDKPScaleSize:GetValue();
  end)

  MonDKP.ConfigTab4.DKPHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.MonDKPScaleSize, "TOP", 0, 3);
  MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["MainGUISize"])

  MonDKP.ConfigTab4.UIScaleSize = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
  MonDKP.ConfigTab4.UIScaleSize:SetAutoFocus(false)
  MonDKP.ConfigTab4.UIScaleSize:SetMultiLine(false)
  MonDKP.ConfigTab4.UIScaleSize:SetSize(50, 18)
  MonDKP.ConfigTab4.UIScaleSize:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  MonDKP.ConfigTab4.UIScaleSize:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab4.UIScaleSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  MonDKP.ConfigTab4.UIScaleSize:SetMaxLetters(4)
  MonDKP.ConfigTab4.UIScaleSize:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab4.UIScaleSize:SetFontObject("MonDKPTinyCenter")
  MonDKP.ConfigTab4.UIScaleSize:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab4.UIScaleSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.UIScaleSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  MonDKP.ConfigTab4.UIScaleSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.MonDKPScaleSize:SetValue(MonDKP.ConfigTab4.UIScaleSize:GetNumber());
  end)
  MonDKP.ConfigTab4.UIScaleSize:SetPoint("TOP", MonDKP.ConfigTab4.MonDKPScaleSize, "BOTTOM", 0, -3)     
  MonDKP.ConfigTab4.UIScaleSize:SetText(MonDKP.ConfigTab4.MonDKPScaleSize:GetValue())

  -- Supress Broadcast Notifications checkbox
  MonDKP.ConfigTab4.supressNotifications = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate");
  MonDKP.ConfigTab4.supressNotifications:SetPoint("TOP", MonDKP.ConfigTab4.TimerSizeSlider, "BOTTOMLEFT", 0, -35)
  MonDKP.ConfigTab4.supressNotifications:SetChecked(MonDKP_DB.defaults.supressNotifications)
  MonDKP.ConfigTab4.supressNotifications:SetScale(0.8)
  MonDKP.ConfigTab4.supressNotifications.text:SetText("|cff5151de"..L["SuppressNotifications"].."|r");
  MonDKP.ConfigTab4.supressNotifications.text:SetFontObject("MonDKPSmall")
  MonDKP.ConfigTab4.supressNotifications:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["SuppressNotifications"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["SuppressNotifyTTDesc"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["SuppressNotifyTTWarn"], 1.0, 0, 0, true);
    GameTooltip:Show()
  end)
  MonDKP.ConfigTab4.supressNotifications:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  MonDKP.ConfigTab4.supressNotifications:SetScript("OnClick", function()
    if MonDKP.ConfigTab4.supressNotifications:GetChecked() then
      MonDKP:Print(L["NotificationsLikeThis"].." |cffff0000"..L["Hidden"].."|r.")
      MonDKP_DB["defaults"]["supressNotifications"] = true;
    else
      MonDKP_DB["defaults"]["supressNotifications"] = false;
      MonDKP:Print(L["NotificationsLikeThis"].." |cff00ff00"..L["Visible"].."|r.")
    end
    PlaySound(808)
  end)

  if core.IsOfficer == true then
    -- Supress Broadcast Notifications checkbox
    if not MonDKP_DB.defaults.SupressTells then MonDKP_DB.defaults.SupressTells = true end
    MonDKP.ConfigTab4.supressTells = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate");
    MonDKP.ConfigTab4.supressTells:SetPoint("LEFT", MonDKP.ConfigTab4.supressNotifications, "RIGHT", 200, 0)
    MonDKP.ConfigTab4.supressTells:SetChecked(MonDKP_DB.defaults.SupressTells)
    MonDKP.ConfigTab4.supressTells:SetScale(0.8)
    MonDKP.ConfigTab4.supressTells.text:SetText("|cff5151de"..L["SuppressBidWhisp"].."|r");
    MonDKP.ConfigTab4.supressTells.text:SetFontObject("MonDKPSmall")
    MonDKP.ConfigTab4.supressTells:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["SuppressBidWhisp"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["SupressBidWhispTTDesc"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["SupressBidWhispTTWarn"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    MonDKP.ConfigTab4.supressTells:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    MonDKP.ConfigTab4.supressTells:SetScript("OnClick", function()
      if MonDKP.ConfigTab4.supressTells:GetChecked() then
        MonDKP:Print(L["BidWhispAreNow"].." |cffff0000"..L["Hidden"].."|r.")
        MonDKP_DB["defaults"]["SupressTells"] = true;
      else
        MonDKP_DB["defaults"]["SupressTells"] = false;
        MonDKP:Print(L["BidWhispAreNow"].." |cff00ff00"..L["Visible"].."|r.")
      end
      PlaySound(808)
    end)
  end

  -- Save Settings Button
  MonDKP.ConfigTab4.submitSettings = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab4, "BOTTOMLEFT", 30, 30, L["SaveSettings"]);
  MonDKP.ConfigTab4.submitSettings:ClearAllPoints();
  MonDKP.ConfigTab4.submitSettings:SetPoint("TOP", MonDKP.ConfigTab4.supressNotifications, "BOTTOMLEFT", 20, -20)
  MonDKP.ConfigTab4.submitSettings:SetSize(90,25)
  MonDKP.ConfigTab4.submitSettings:SetScript("OnClick", function()
    if core.IsOfficer == true then
      for i=1, 6 do
        if not tonumber(MonDKP.ConfigTab4.default[i]:GetText()) then
          StaticPopupDialogs["OPTIONS_VALIDATION"] = {
            text = L["InvalidOptionEntry"].." "..MonDKP.ConfigTab4.default[i].tooltipText..". "..L["PleaseUseNums"],
            button1 = L["OK"],
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          StaticPopup_Show ("OPTIONS_VALIDATION")

        return;
        end
      end
      for i=1, 17 do
        if not tonumber(MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:GetText()) then
          StaticPopupDialogs["OPTIONS_VALIDATION"] = {
            text = L["InvalidMinBidEntry"].." "..MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].tooltipText..". "..L["PleaseUseNums"],
            button1 = L["OK"],
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          StaticPopup_Show ("OPTIONS_VALIDATION")

        return;
        end
      end
    end
    
    SaveSettings()
    MonDKP:Print(L["DefaultSetSaved"])
  end)

  -- Position Bid Timer Button

  MonDKP.ConfigTab4.moveTimer = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["MoveBidTimer"]);
  MonDKP.ConfigTab4.moveTimer:ClearAllPoints();
  MonDKP.ConfigTab4.moveTimer:SetPoint("LEFT", MonDKP.ConfigTab4.submitSettings, "RIGHT", 200, 0)
  MonDKP.ConfigTab4.moveTimer:SetSize(110,25)
  MonDKP.ConfigTab4.moveTimer:SetScript("OnClick", function()
    if moveTimerToggle == 0 then
      MonDKP:StartTimer(120, L["MoveMe"])
      MonDKP.ConfigTab4.moveTimer:SetText(L["HideBidTimer"])
      moveTimerToggle = 1;
    else
      MonDKP.BidTimer:SetScript("OnUpdate", nil)
      MonDKP.BidTimer:Hide()
      MonDKP.ConfigTab4.moveTimer:SetText(L["MoveBidTimer"])
      moveTimerToggle = 0;
    end
  end)

  -- Options Footer (empty frame to push bottom of scrollframe down)
  MonDKP.ConfigTab4.OptionsFooterFrame = CreateFrame("Frame", nil, MonDKP.ConfigTab4);
  MonDKP.ConfigTab4.OptionsFooterFrame:SetPoint("TOPLEFT", MonDKP.ConfigTab4.moveTimer, "BOTTOMLEFT")
  MonDKP.ConfigTab4.OptionsFooterFrame:SetSize(420, 50);
end