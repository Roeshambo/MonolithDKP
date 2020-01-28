local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local moveTimerToggle = 0;
local validating = false

local function DrawPercFrame(box)
  --Draw % signs if set to percent
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box], "RIGHT", -15, 0);
  MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetText("%")
  
  MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetFontObject("MonDKPNormalLeft");
  MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[box], "RIGHT", -15, 0);
  MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetText("%")
end

local function SaveSettings()
  if MonDKP.ConfigTab4.default[1] then
    MonDKP_DB.DKPBonus.OnTimeBonus = MonDKP.ConfigTab4.default[1]:GetNumber();
    MonDKP_DB.DKPBonus.BossKillBonus = MonDKP.ConfigTab4.default[2]:GetNumber();
    MonDKP_DB.DKPBonus.CompletionBonus = MonDKP.ConfigTab4.default[3]:GetNumber();
    MonDKP_DB.DKPBonus.NewBossKillBonus = MonDKP.ConfigTab4.default[4]:GetNumber();
    MonDKP_DB.DKPBonus.UnexcusedAbsence = MonDKP.ConfigTab4.default[5]:GetNumber();
    if MonDKP.ConfigTab4.default[6]:GetNumber() < 0 then
      MonDKP_DB.DKPBonus.DecayPercentage = 0 - MonDKP.ConfigTab4.default[6]:GetNumber();
    else
      MonDKP_DB.DKPBonus.DecayPercentage = MonDKP.ConfigTab4.default[6]:GetNumber();
    end
    MonDKP.ConfigTab2.decayDKP:SetNumber(MonDKP_DB.DKPBonus.DecayPercentage);
    MonDKP.ConfigTab4.default[6]:SetNumber(MonDKP_DB.DKPBonus.DecayPercentage)
    MonDKP_DB.DKPBonus.BidTimer = MonDKP.ConfigTab4.bidTimer:GetNumber();

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
    
    MonDKP_DB.MaxBidBySlot.Head = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[1]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Neck = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[2]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Shoulders = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[3]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Cloak = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[4]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Chest = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[5]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Bracers = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[6]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Hands = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[7]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Belt = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[8]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Legs = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Boots = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[10]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Ring = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[11]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Trinket = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[12]:GetNumber()
    MonDKP_DB.MaxBidBySlot.OneHanded = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[13]:GetNumber()
    MonDKP_DB.MaxBidBySlot.TwoHanded = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:GetNumber()
    MonDKP_DB.MaxBidBySlot.OffHand = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[15]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Range = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[16]:GetNumber()
    MonDKP_DB.MaxBidBySlot.Other = MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:GetNumber()
  end

  core.MonDKPUI:SetScale(MonDKP_DB.defaults.MonDKPScaleSize);
  MonDKP_DB.defaults.HistoryLimit = MonDKP.ConfigTab4.history:GetNumber();
  MonDKP_DB.defaults.DKPHistoryLimit = MonDKP.ConfigTab4.DKPHistory:GetNumber();
  MonDKP_DB.defaults.TooltipHistoryCount = MonDKP.ConfigTab4.TooltipHistory:GetNumber();
  DKPTable_Update()
end

function MonDKP:Options()
  local default = {}
  MonDKP.ConfigTab4.default = default;

  MonDKP.ConfigTab4.header = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.header:SetFontObject("MonDKPLargeCenter");
  MonDKP.ConfigTab4.header:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab4.header:SetText(L["DEFAULTSETTINGS"]);
  MonDKP.ConfigTab4.header:SetScale(1.2)

  if core.IsOfficer == true then
    MonDKP.ConfigTab4.description = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.description:SetFontObject("MonDKPNormalLeft");
    MonDKP.ConfigTab4.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.header, "BOTTOMLEFT", 7, -15);
    MonDKP.ConfigTab4.description:SetText("|CFFcca600"..L["DEFAULTDKPAWARDVALUES"].."|r");
  
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
    MonDKP.ConfigTab4.ModesButton = self:CreateButton("TOPRIGHT", MonDKP.ConfigTab4, "TOPRIGHT", -40, -20, L["DKPMODES"]);
    MonDKP.ConfigTab4.ModesButton:SetSize(110,25)
    MonDKP.ConfigTab4.ModesButton:SetScript("OnClick", function()
      MonDKP:ToggleDKPModesWindow()
    end);
    MonDKP.ConfigTab4.ModesButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["DKPMODESTTDESC2"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["DKPMODESTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    MonDKP.ConfigTab4.ModesButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    end)
    if not core.IsOfficer then
      MonDKP.ConfigTab4.ModesButton:Hide()
    end

    MonDKP.ConfigTab4.default[1]:SetText(MonDKP_DB.DKPBonus.OnTimeBonus)
    MonDKP.ConfigTab4.default[1].tooltipText = L["ONTIMEBONUS"]
    MonDKP.ConfigTab4.default[1].tooltipDescription = L["ONTIMEBONUSTTDESC"]
      
    MonDKP.ConfigTab4.default[2]:SetText(MonDKP_DB.DKPBonus.BossKillBonus)
    MonDKP.ConfigTab4.default[2].tooltipText = L["BOSSKILLBONUS"]
    MonDKP.ConfigTab4.default[2].tooltipDescription = L["BOSSKILLBONUSTTDESC"]
       
    MonDKP.ConfigTab4.default[3]:SetText(MonDKP_DB.DKPBonus.CompletionBonus)
    MonDKP.ConfigTab4.default[3].tooltipText = L["RAIDCOMPLETIONBONUS"]
    MonDKP.ConfigTab4.default[3].tooltipDescription = L["RAIDCOMPLETEBONUSTT"]
      
    MonDKP.ConfigTab4.default[4]:SetText(MonDKP_DB.DKPBonus.NewBossKillBonus)
    MonDKP.ConfigTab4.default[4].tooltipText = L["NEWBOSSKILLBONUS"]
    MonDKP.ConfigTab4.default[4].tooltipDescription = L["NEWBOSSKILLTTDESC"]

    MonDKP.ConfigTab4.default[5]:SetText(MonDKP_DB.DKPBonus.UnexcusedAbsence)
    MonDKP.ConfigTab4.default[5]:SetNumeric(false)
    MonDKP.ConfigTab4.default[5].tooltipText = L["UNEXCUSEDABSENCE"]
    MonDKP.ConfigTab4.default[5].tooltipDescription = L["UNEXCUSEDTTDESC"]
    MonDKP.ConfigTab4.default[5].tooltipWarning = L["UNEXCUSEDTTWARN"]

    MonDKP.ConfigTab4.default[6]:SetText(MonDKP_DB.DKPBonus.DecayPercentage)
    MonDKP.ConfigTab4.default[6]:SetTextInsets(0, 15, 0, 0)
    MonDKP.ConfigTab4.default[6].tooltipText = L["DECAYPERCENTAGE"]
    MonDKP.ConfigTab4.default[6].tooltipDescription = L["DECAYPERCENTAGETTDESC"]
    MonDKP.ConfigTab4.default[6].tooltipWarning = L["DECAYPERCENTAGETTWARN"]

    --OnTimeBonus Header
    MonDKP.ConfigTab4.OnTimeHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.OnTimeHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.OnTimeHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[1], "LEFT", 0, 0);
    MonDKP.ConfigTab4.OnTimeHeader:SetText(L["ONTIMEBONUS"]..": ")

    --BossKillBonus Header
    MonDKP.ConfigTab4.BossKillHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.BossKillHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.BossKillHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[2], "LEFT", 0, 0);
    MonDKP.ConfigTab4.BossKillHeader:SetText(L["BOSSKILLBONUS"]..": ")

    --CompletionBonus Header
    MonDKP.ConfigTab4.CompleteHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.CompleteHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.CompleteHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[3], "LEFT", 0, 0);
    MonDKP.ConfigTab4.CompleteHeader:SetText(L["RAIDCOMPLETIONBONUS"]..": ")

    --NewBossKillBonus Header
    MonDKP.ConfigTab4.NewBossHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.NewBossHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.NewBossHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[4], "LEFT", 0, 0);
    MonDKP.ConfigTab4.NewBossHeader:SetText(L["NEWBOSSKILLBONUS"]..": ")

    --UnexcusedAbsence Header
    MonDKP.ConfigTab4.UnexcusedHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.UnexcusedHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.UnexcusedHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[5], "LEFT", 0, 0);
    MonDKP.ConfigTab4.UnexcusedHeader:SetText(L["UNEXCUSEDABSENCE"]..": ")

    --DKP Decay Header
    MonDKP.ConfigTab4.DecayHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.DecayHeader:SetFontObject("MonDKPSmallRight");
    MonDKP.ConfigTab4.DecayHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[6], "LEFT", 0, 0);
    MonDKP.ConfigTab4.DecayHeader:SetText(L["DECAYAMOUNT"]..": ")

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
        prefix = L["MINIMUMBID"];
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTMINBIDVALUES"].."|r");
      elseif MonDKP_DB.modes.mode == "Static Item Values" then
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if MonDKP_DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif MonDKP_DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      elseif MonDKP_DB.modes.mode == "Roll Based Bidding" then
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if MonDKP_DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif MonDKP_DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      elseif MonDKP_DB.modes.mode == "Zero Sum" then
        MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if MonDKP_DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif MonDKP_DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      end

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].Header:SetText(L["HEAD"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetText(MonDKP_DB.MinBidBySlot.Head)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipText = L["HEAD"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipDescription = prefix.." "..L["FORHEADSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].Header:SetText(L["NECK"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:SetText(MonDKP_DB.MinBidBySlot.Neck)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipText = L["NECK"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipDescription = prefix.." "..L["FORNECKSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3].Header:SetText(L["SHOULDERS"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3]:SetText(MonDKP_DB.MinBidBySlot.Shoulders)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipText = L["SHOULDERS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipDescription = prefix.." "..L["FORSHOULDERSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4].Header:SetText(L["CLOAK"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4]:SetText(MonDKP_DB.MinBidBySlot.Cloak)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipText = L["CLOAK"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipDescription = prefix.." "..L["FORBACKSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5].Header:SetText(L["CHEST"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5]:SetText(MonDKP_DB.MinBidBySlot.Chest)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipText = L["CHEST"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipDescription = prefix.." "..L["FORCHESTSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6].Header:SetText(L["BRACERS"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6]:SetText(MonDKP_DB.MinBidBySlot.Bracers)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipText = L["BRACERS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipDescription = prefix.." "..L["FORWRISTSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7].Header:SetText(L["HANDS"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7]:SetText(MonDKP_DB.MinBidBySlot.Hands)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipText = L["HANDS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipDescription = prefix.." "..L["FORHANDSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8].Header:SetText(L["BELT"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8]:SetText(MonDKP_DB.MinBidBySlot.Belt)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipText = L["BELT"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipDescription = prefix.." "..L["FORWAISTSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9].Header:SetText(L["LEGS"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetText(MonDKP_DB.MinBidBySlot.Legs)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipText = L["LEGS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipDescription = prefix.." "..L["FORLEGSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10].Header:SetText(L["BOOTS"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10]:SetText(MonDKP_DB.MinBidBySlot.Boots)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipText = L["BOOTS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipDescription = prefix.." "..L["FORFEETSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11].Header:SetText(L["RINGS"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11]:SetText(MonDKP_DB.MinBidBySlot.Ring)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipText = L["RINGS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipDescription = prefix.." "..L["FORFINGERSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12].Header:SetText(L["TRINKET"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12]:SetText(MonDKP_DB.MinBidBySlot.Trinket)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipText = L["TRINKET"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipDescription = prefix.." "..L["FORTRINKETSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13].Header:SetText(L["ONEHANDED"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13]:SetText(MonDKP_DB.MinBidBySlot.OneHanded)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipText = L["ONEHANDEDWEAPONS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipDescription = prefix.." "..L["FORONEHANDSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14].Header:SetText(L["TWOHANDED"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetText(MonDKP_DB.MinBidBySlot.TwoHanded)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipText = L["TWOHANDEDWEAPONS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipDescription = prefix.." "..L["FORTWOHANDSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15].Header:SetText(L["OFFHAND"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15]:SetText(MonDKP_DB.MinBidBySlot.OffHand)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipText = L["OFFHANDITEMS"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipDescription = prefix.." "..L["FOROFFHANDSLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16].Header:SetText(L["RANGE"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16]:SetText(MonDKP_DB.MinBidBySlot.Range)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipText = L["RANGE"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipDescription = prefix.." "..L["FORRANGESLOT"]

      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17].Header:SetText(L["OTHER"]..": ")
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetText(MonDKP_DB.MinBidBySlot.Other)
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipText = L["OTHER"]
      MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipDescription = prefix.." "..L["FOROTHERSLOT"]

      if MonDKP_DB.modes.costvalue == "Percent" then
        for i=1, #MonDKP.ConfigTab4.DefaultMinBids.SlotBox do
          DrawPercFrame(i)
          MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
        end
      end

      -- Broadcast Minimum Bids Button
      MonDKP.ConfigTab4.BroadcastMinBids = self:CreateButton("TOP", MonDKP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"]);
      MonDKP.ConfigTab4.BroadcastMinBids:ClearAllPoints();
      MonDKP.ConfigTab4.BroadcastMinBids:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[17], "RIGHT", 41, 0)
      MonDKP.ConfigTab4.BroadcastMinBids:SetSize(110,25)
      MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnClick", function()
        StaticPopupDialogs["SEND_MINBIDS"] = {
          text = L["BCASTMINBIDCONFIRM"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            local temptable = {}
            table.insert(temptable, MonDKP_DB.MinBidBySlot)
            table.insert(temptable, MonDKP_MinBids)
            MonDKP.Sync:SendData("MonDKPMinBid", temptable)
            MonDKP:Print(L["MINBIDVALUESSENT"])
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
        GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
        GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true);
        GameTooltip:Show()
      end)
      MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    
    -- Default Maximum Bids Container Frame
    if MonDKP_DB.modes.mode == "Minimum Bid Values" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
      MonDKP.ConfigTab4.DefaultMaxBids = CreateFrame("Frame", nil, MonDKP.ConfigTab4);
      MonDKP.ConfigTab4.DefaultMaxBids:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 0, -52)
      MonDKP.ConfigTab4.DefaultMaxBids:SetSize(420, 410);

      MonDKP.ConfigTab4.DefaultMaxBids.description = MonDKP.ConfigTab4.DefaultMaxBids:CreateFontString(nil, "OVERLAY")
      MonDKP.ConfigTab4.DefaultMaxBids.description:SetFontObject("MonDKPSmallRight");
      MonDKP.ConfigTab4.DefaultMaxBids.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMaxBids, "TOPLEFT", 15, 15);

      -- DEFAULT Max bids Create EditBoxes
      local SlotBox = {}
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox = SlotBox;

      for i=1, 17 do
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i] = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetAutoFocus(false)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetMultiLine(false)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetSize(60, 24)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdrop({
          bgFile   = "Textures\\white.blp", tile = true,
          edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
        });
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetMaxLetters(6)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetFontObject("MonDKPSmallRight")
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
          if i == 8 then
            self:HighlightText(0,0)
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:SetFocus()
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:HighlightText()
            SaveSettings()
          elseif i == 5 then
            self:HighlightText(0,0)
            MonDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:SetFocus()
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          elseif i == 13 then
            self:HighlightText(0,0)
            MonDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:SetFocus()
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:HighlightText()
            SaveSettings()
          elseif i == 17 then
            self:HighlightText(0,0)
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:SetFocus()
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:HighlightText()
            SaveSettings()
          elseif i == 16 then
            self:HighlightText(0,0)
            MonDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(1)
            MonDKP.ConfigTab4.default[1]:SetFocus()
            MonDKP.ConfigTab4.default[1]:HighlightText()
            SaveSettings()
          else
            self:HighlightText(0,0)
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:SetFocus()
            MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          end
        end)
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEnter", function(self)
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
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)

        -- Slot Headers
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header = MonDKP.ConfigTab4.DefaultMaxBids:CreateFontString(nil, "OVERLAY")
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header:SetFontObject("MonDKPNormalLeft");
        MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header:SetPoint("RIGHT", MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i], "LEFT", 0, 0);

        if i==1 then
          MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMaxBids, "TOPLEFT", 100, -10)
        elseif i==9 then
          MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[1], "TOPLEFT", 150, 0)
        elseif i==17 then
          MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOP", MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[8], "BOTTOM", 0, -22)
        else
          MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOP", MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i-1], "BOTTOM", 0, -22)
        end
      end

      local prefix;

      prefix = L["MAXIMUMBID"];
      MonDKP.ConfigTab4.DefaultMaxBids.description:SetText("|CFFcca600"..L["DEFAULTMAXBIDVALUES"].."|r");

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].Header:SetText(L["HEAD"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[1]:SetText(MonDKP_DB.MaxBidBySlot.Head)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].tooltipText = L["HEAD"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].tooltipDescription = prefix.." "..L["FORHEADSLOT"].." "..L["MAXIMUMBIDTTDESC"]
       
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].Header:SetText(L["NECK"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[2]:SetText(MonDKP_DB.MaxBidBySlot.Neck)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].tooltipText = L["NECK"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].tooltipDescription = prefix.." "..L["FORNECKSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].Header:SetText(L["SHOULDERS"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[3]:SetText(MonDKP_DB.MaxBidBySlot.Shoulders)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].tooltipText = L["SHOULDERS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].tooltipDescription = prefix.." "..L["FORSHOULDERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].Header:SetText(L["CLOAK"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[4]:SetText(MonDKP_DB.MaxBidBySlot.Cloak)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].tooltipText = L["CLOAK"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].tooltipDescription = prefix.." "..L["FORBACKSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].Header:SetText(L["CHEST"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[5]:SetText(MonDKP_DB.MaxBidBySlot.Chest)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].tooltipText = L["CHEST"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].tooltipDescription = prefix.." "..L["FORCHESTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].Header:SetText(L["BRACERS"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[6]:SetText(MonDKP_DB.MaxBidBySlot.Bracers)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].tooltipText = L["BRACERS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].tooltipDescription = prefix.." "..L["FORWRISTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].Header:SetText(L["HANDS"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[7]:SetText(MonDKP_DB.MaxBidBySlot.Hands)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].tooltipText = L["HANDS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].tooltipDescription = prefix.." "..L["FORHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].Header:SetText(L["BELT"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[8]:SetText(MonDKP_DB.MaxBidBySlot.Belt)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].tooltipText = L["BELT"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].tooltipDescription = prefix.." "..L["FORWAISTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].Header:SetText(L["LEGS"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:SetText(MonDKP_DB.MaxBidBySlot.Legs)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].tooltipText = L["LEGS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].tooltipDescription = prefix.." "..L["FORLEGSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].Header:SetText(L["BOOTS"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[10]:SetText(MonDKP_DB.MaxBidBySlot.Boots)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].tooltipText = L["BOOTS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].tooltipDescription = prefix.." "..L["FORFEETSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].Header:SetText(L["RINGS"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[11]:SetText(MonDKP_DB.MaxBidBySlot.Ring)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].tooltipText = L["RINGS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].tooltipDescription = prefix.." "..L["FORFINGERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].Header:SetText(L["TRINKET"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[12]:SetText(MonDKP_DB.MaxBidBySlot.Trinket)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].tooltipText = L["TRINKET"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].tooltipDescription = prefix.." "..L["FORTRINKETSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].Header:SetText(L["ONEHANDED"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[13]:SetText(MonDKP_DB.MaxBidBySlot.OneHanded)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].tooltipText = L["ONEHANDEDWEAPONS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].tooltipDescription = prefix.." "..L["FORONEHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].Header:SetText(L["TWOHANDED"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:SetText(MonDKP_DB.MaxBidBySlot.TwoHanded)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].tooltipText = L["TWOHANDEDWEAPONS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].tooltipDescription = prefix.." "..L["FORTWOHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].Header:SetText(L["OFFHAND"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[15]:SetText(MonDKP_DB.MaxBidBySlot.OffHand)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].tooltipText = L["OFFHANDITEMS"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].tooltipDescription = prefix.." "..L["FOROFFHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].Header:SetText(L["RANGE"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[16]:SetText(MonDKP_DB.MaxBidBySlot.Range)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].tooltipText = L["RANGE"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].tooltipDescription = prefix.." "..L["FORRANGESLOT"].." "..L["MAXIMUMBIDTTDESC"]

      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].Header:SetText(L["OTHER"]..": ")
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:SetText(MonDKP_DB.MaxBidBySlot.Other)
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].tooltipText = L["OTHER"]
      MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].tooltipDescription = prefix.." "..L["FOROTHERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      if MonDKP_DB.modes.costvalue == "Percent" then
        for i=1, #MonDKP.ConfigTab4.DefaultMaxBids.SlotBox do
          DrawPercFrame(i)
          MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
        end
      end

      -- Broadcast Maximum Bids Button
      MonDKP.ConfigTab4.BroadcastMaxBids = self:CreateButton("TOP", MonDKP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"]);
      MonDKP.ConfigTab4.BroadcastMaxBids:ClearAllPoints();
      MonDKP.ConfigTab4.BroadcastMaxBids:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMaxBids.SlotBox[17], "RIGHT", 41, 0)
      MonDKP.ConfigTab4.BroadcastMaxBids:SetSize(110,25)
      MonDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnClick", function()
        StaticPopupDialogs["SEND_MAXBIDS"] = {
          text = L["BCASTMAXBIDCONFIRM"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            local temptable = {}
            table.insert(temptable, MonDKP_DB.MaxBidBySlot)
            table.insert(temptable, MonDKP_MaxBids)
            MonDKP.Sync:SendData("MonDKPMaxBid", temptable)
            MonDKP:Print(L["MAXBIDVALUESSENT"])
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("SEND_MAXBIDS")
      end);
      MonDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
        GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true);
        GameTooltip:Show()
      end)
      MonDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
  end
    -- Bid Timer Slider
    MonDKP.ConfigTab4.bidTimerSlider = CreateFrame("SLIDER", "$parentBidTimerSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate");
    if MonDKP_DB.modes.mode == "Minimum Bid Values" or (MonDKP_DB.modes.mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
      MonDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMaxBids, "BOTTOMLEFT", 54, -40);
    else
      MonDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 54, -40);
    end
    MonDKP.ConfigTab4.bidTimerSlider:SetMinMaxValues(10, 90);
    MonDKP.ConfigTab4.bidTimerSlider:SetValue(MonDKP_DB.DKPBonus.BidTimer);
    MonDKP.ConfigTab4.bidTimerSlider:SetValueStep(1);
    MonDKP.ConfigTab4.bidTimerSlider.tooltipText = L["BIDTIMER"]
    MonDKP.ConfigTab4.bidTimerSlider.tooltipRequirement = L["BIDTIMERDEFAULTTTDESC"]
    MonDKP.ConfigTab4.bidTimerSlider:SetObeyStepOnDrag(true);
    getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."Low"):SetText("10")
    getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."High"):SetText("90")
    MonDKP.ConfigTab4.bidTimerSlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
      MonDKP.ConfigTab4.bidTimer:SetText(MonDKP.ConfigTab4.bidTimerSlider:GetValue())
    end)

    MonDKP.ConfigTab4.bidTimerHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    MonDKP.ConfigTab4.bidTimerHeader:SetFontObject("MonDKPTinyCenter");
    MonDKP.ConfigTab4.bidTimerHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.bidTimerSlider, "TOP", 0, 3);
    MonDKP.ConfigTab4.bidTimerHeader:SetText(L["BIDTIMER"])

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
  MonDKP.ConfigTab4.TooltipHistorySlider.tooltipText = L["TTHISTORYCOUNT"]
  MonDKP.ConfigTab4.TooltipHistorySlider.tooltipRequirement = L["TTHISTORYCOUNTTTDESC"]
  MonDKP.ConfigTab4.TooltipHistorySlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.TooltipHistorySlider:GetName().."Low"):SetText("5")
  getglobal(MonDKP.ConfigTab4.TooltipHistorySlider:GetName().."High"):SetText("35")
  MonDKP.ConfigTab4.TooltipHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.TooltipHistory:SetText(MonDKP.ConfigTab4.TooltipHistorySlider:GetValue())
  end)

  MonDKP.ConfigTab4.TooltipHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.TooltipHistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.TooltipHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.TooltipHistorySlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.TooltipHistoryHeader:SetText(L["TTHISTORYCOUNT"])

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
  MonDKP.ConfigTab4.historySlider.tooltipText = L["LOOTHISTORYLIMIT"]
  MonDKP.ConfigTab4.historySlider.tooltipRequirement = L["LOOTHISTLIMITTTDESC"]
  MonDKP.ConfigTab4.historySlider.tooltipWarning = L["LOOTHISTLIMITTTWARN"]
  MonDKP.ConfigTab4.historySlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.historySlider:GetName().."Low"):SetText("500")
  getglobal(MonDKP.ConfigTab4.historySlider:GetName().."High"):SetText("2500")
  MonDKP.ConfigTab4.historySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.history:SetText(MonDKP.ConfigTab4.historySlider:GetValue())
  end)

  MonDKP.ConfigTab4.HistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.HistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.HistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.historySlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.HistoryHeader:SetText(L["LOOTHISTORYLIMIT"])

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
  MonDKP.ConfigTab4.DKPHistorySlider.tooltipText = L["DKPHISTORYLIMIT"]
  MonDKP.ConfigTab4.DKPHistorySlider.tooltipRequirement = L["DKPHISTLIMITTTDESC"]
  MonDKP.ConfigTab4.DKPHistorySlider.tooltipWarning = L["DKPHISTLIMITTTWARN"]
  MonDKP.ConfigTab4.DKPHistorySlider:SetObeyStepOnDrag(true);
  getglobal(MonDKP.ConfigTab4.DKPHistorySlider:GetName().."Low"):SetText("500")
  getglobal(MonDKP.ConfigTab4.DKPHistorySlider:GetName().."High"):SetText("2500")
  MonDKP.ConfigTab4.DKPHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    MonDKP.ConfigTab4.DKPHistory:SetText(MonDKP.ConfigTab4.DKPHistorySlider:GetValue())
  end)

  MonDKP.ConfigTab4.DKPHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("MonDKPTinyCenter");
  MonDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.DKPHistorySlider, "TOP", 0, 3);
  MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["DKPHISTORYLIMIT"])

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
  MonDKP.ConfigTab4.TimerSizeSlider.tooltipText = L["TIMERSIZE"]
  MonDKP.ConfigTab4.TimerSizeSlider.tooltipRequirement = L["TIMERSIZETTDESC"]
  MonDKP.ConfigTab4.TimerSizeSlider.tooltipWarning = L["TIMERSIZETTWARN"]
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
  MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["TIMERSIZE"])

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
  MonDKP.ConfigTab4.MonDKPScaleSize.tooltipText = L["MONDKPSCALESIZE"]
  MonDKP.ConfigTab4.MonDKPScaleSize.tooltipRequirement = L["MONDKPSCALESIZETTDESC"]
  MonDKP.ConfigTab4.MonDKPScaleSize.tooltipWarning = L["MONDKPSCALESIZETTWARN"]
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
  MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["MAINGUISIZE"])

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
  MonDKP.ConfigTab4.supressNotifications.text:SetText("|cff5151de"..L["SUPPRESSNOTIFICATIONS"].."|r");
  MonDKP.ConfigTab4.supressNotifications.text:SetFontObject("MonDKPSmall")
  MonDKP.ConfigTab4.supressNotifications:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["SUPPRESSNOTIFICATIONS"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["SUPPRESSNOTIFYTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["SUPPRESSNOTIFYTTWARN"], 1.0, 0, 0, true);
    GameTooltip:Show()
  end)
  MonDKP.ConfigTab4.supressNotifications:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  MonDKP.ConfigTab4.supressNotifications:SetScript("OnClick", function()
    if MonDKP.ConfigTab4.supressNotifications:GetChecked() then
      MonDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cffff0000"..L["HIDDEN"].."|r.")
      MonDKP_DB["defaults"]["supressNotifications"] = true;
    else
      MonDKP_DB["defaults"]["supressNotifications"] = false;
      MonDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cff00ff00"..L["VISIBLE"].."|r.")
    end
    PlaySound(808)
  end)

  -- Combat Logging checkbox
  MonDKP.ConfigTab4.CombatLogging = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate");
  MonDKP.ConfigTab4.CombatLogging:SetPoint("TOP", MonDKP.ConfigTab4.supressNotifications, "BOTTOM", 0, 0)
  MonDKP.ConfigTab4.CombatLogging:SetChecked(MonDKP_DB.defaults.AutoLog)
  MonDKP.ConfigTab4.CombatLogging:SetScale(0.8)
  MonDKP.ConfigTab4.CombatLogging.text:SetText("|cff5151de"..L["AUTOCOMBATLOG"].."|r");
  MonDKP.ConfigTab4.CombatLogging.text:SetFontObject("MonDKPSmall")
  MonDKP.ConfigTab4.CombatLogging:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["AUTOCOMBATLOG"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["AUTOCOMBATLOGTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["AUTOCOMBATLOGTTWARN"], 1.0, 0, 0, true);
    GameTooltip:Show()
  end)
  MonDKP.ConfigTab4.CombatLogging:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  MonDKP.ConfigTab4.CombatLogging:SetScript("OnClick", function(self)
    MonDKP_DB.defaults.AutoLog = self:GetChecked()
    PlaySound(808)
  end)

  if MonDKP_DB.defaults.AutoOpenBid == nil then
    MonDKP_DB.defaults.AutoOpenBid = true
  end

  MonDKP.ConfigTab4.AutoOpenCheckbox = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate");
  MonDKP.ConfigTab4.AutoOpenCheckbox:SetChecked(MonDKP_DB.defaults.AutoOpenBid)
  MonDKP.ConfigTab4.AutoOpenCheckbox:SetScale(0.8);
  MonDKP.ConfigTab4.AutoOpenCheckbox.text:SetText("|cff5151de"..L["AUTOOPEN"].."|r");
  MonDKP.ConfigTab4.AutoOpenCheckbox.text:SetScale(1);
  MonDKP.ConfigTab4.AutoOpenCheckbox.text:SetFontObject("MonDKPSmallLeft")
  MonDKP.ConfigTab4.AutoOpenCheckbox:SetPoint("TOP", MonDKP.ConfigTab4.CombatLogging, "BOTTOM", 0, 0);
  MonDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnClick", function(self)
    MonDKP_DB.defaults.AutoOpenBid = self:GetChecked()
  end)
  MonDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    GameTooltip:SetText(L["AUTOOPEN"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["AUTOOPENTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  MonDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  if core.IsOfficer == true then
    -- Supress Broadcast Notifications checkbox
    MonDKP.ConfigTab4.supressTells = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate");
    MonDKP.ConfigTab4.supressTells:SetPoint("LEFT", MonDKP.ConfigTab4.supressNotifications, "RIGHT", 200, 0)
    MonDKP.ConfigTab4.supressTells:SetChecked(MonDKP_DB.defaults.SupressTells)
    MonDKP.ConfigTab4.supressTells:SetScale(0.8)
    MonDKP.ConfigTab4.supressTells.text:SetText("|cff5151de"..L["SUPPRESSBIDWHISP"].."|r");
    MonDKP.ConfigTab4.supressTells.text:SetFontObject("MonDKPSmall")
    MonDKP.ConfigTab4.supressTells:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["SUPPRESSBIDWHISP"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["SUPRESSBIDWHISPTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["SUPRESSBIDWHISPTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    MonDKP.ConfigTab4.supressTells:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    MonDKP.ConfigTab4.supressTells:SetScript("OnClick", function()
      if MonDKP.ConfigTab4.supressTells:GetChecked() then
        MonDKP:Print(L["BIDWHISPARENOW"].." |cffff0000"..L["HIDDEN"].."|r.")
        MonDKP_DB["defaults"]["SupressTells"] = true;
      else
        MonDKP_DB["defaults"]["SupressTells"] = false;
        MonDKP:Print(L["BIDWHISPARENOW"].." |cff00ff00"..L["VISIBLE"].."|r.")
      end
      PlaySound(808)
    end)
  end

  -- Save Settings Button
  MonDKP.ConfigTab4.submitSettings = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab4, "BOTTOMLEFT", 30, 30, L["SAVESETTINGS"]);
  MonDKP.ConfigTab4.submitSettings:ClearAllPoints();
  MonDKP.ConfigTab4.submitSettings:SetPoint("TOP", MonDKP.ConfigTab4.AutoOpenCheckbox, "BOTTOMLEFT", 20, -40)
  MonDKP.ConfigTab4.submitSettings:SetSize(90,25)
  MonDKP.ConfigTab4.submitSettings:SetScript("OnClick", function()
    if core.IsOfficer == true then
      for i=1, 6 do
        if not tonumber(MonDKP.ConfigTab4.default[i]:GetText()) then
          StaticPopupDialogs["OPTIONS_VALIDATION"] = {
            text = L["INVALIDOPTIONENTRY"].." "..MonDKP.ConfigTab4.default[i].tooltipText..". "..L["PLEASEUSENUMS"],
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
            text = L["INVALIDMINBIDENTRY"].." "..MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].tooltipText..". "..L["PLEASEUSENUMS"],
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
    MonDKP:Print(L["DEFAULTSETSAVED"])
  end)

  -- Chatframe Selection 
  MonDKP.ConfigTab4.ChatFrame = CreateFrame("FRAME", "MonDKPChatFrameSelectDropDown", MonDKP.ConfigTab4, "MonolithDKPUIDropDownMenuTemplate")
  if not MonDKP_DB.defaults.ChatFrames then MonDKP_DB.defaults.ChatFrames = {} end

  UIDropDownMenu_Initialize(MonDKP.ConfigTab4.ChatFrame, function(self, level, menuList)
  local SelectedFrame = UIDropDownMenu_CreateInfo()
    SelectedFrame.func = self.SetValue
    SelectedFrame.fontObject = "MonDKPSmallCenter"
    SelectedFrame.keepShownOnClick = true;
    SelectedFrame.isNotRadio = true;

    for i = 1, NUM_CHAT_WINDOWS do
      local name = GetChatWindowInfo(i)
      if name ~= "" then
        SelectedFrame.text, SelectedFrame.arg1, SelectedFrame.checked = name, name, MonDKP_DB.defaults.ChatFrames[name]
        UIDropDownMenu_AddButton(SelectedFrame)
      end
    end
  end)

  MonDKP.ConfigTab4.ChatFrame:SetPoint("LEFT", MonDKP.ConfigTab4.CombatLogging, "RIGHT", 130, 0)
  UIDropDownMenu_SetWidth(MonDKP.ConfigTab4.ChatFrame, 150)
  UIDropDownMenu_SetText(MonDKP.ConfigTab4.ChatFrame, "Addon Notifications")

  function MonDKP.ConfigTab4.ChatFrame:SetValue(arg1)
    MonDKP_DB.defaults.ChatFrames[arg1] = not MonDKP_DB.defaults.ChatFrames[arg1]
    CloseDropDownMenus()
  end



  -- Position Bid Timer Button
  MonDKP.ConfigTab4.moveTimer = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["MOVEBIDTIMER"]);
  MonDKP.ConfigTab4.moveTimer:ClearAllPoints();
  MonDKP.ConfigTab4.moveTimer:SetPoint("LEFT", MonDKP.ConfigTab4.submitSettings, "RIGHT", 200, 0)
  MonDKP.ConfigTab4.moveTimer:SetSize(110,25)
  MonDKP.ConfigTab4.moveTimer:SetScript("OnClick", function()
    if moveTimerToggle == 0 then
      MonDKP:StartTimer(120, L["MOVEME"])
      MonDKP.ConfigTab4.moveTimer:SetText(L["HIDEBIDTIMER"])
      moveTimerToggle = 1;
    else
      MonDKP.BidTimer:SetScript("OnUpdate", nil)
      MonDKP.BidTimer:Hide()
      MonDKP.ConfigTab4.moveTimer:SetText(L["MOVEBIDTIMER"])
      moveTimerToggle = 0;
    end
  end)

  -- wipe tables button
  MonDKP.ConfigTab4.WipeTables = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["WIPETABLES"]);
  MonDKP.ConfigTab4.WipeTables:ClearAllPoints();
  MonDKP.ConfigTab4.WipeTables:SetPoint("RIGHT", MonDKP.ConfigTab4.moveTimer, "LEFT", -40, 0)
  MonDKP.ConfigTab4.WipeTables:SetSize(110,25)
  MonDKP.ConfigTab4.WipeTables:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["WIPETABLES"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["WIPETABLESTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  MonDKP.ConfigTab4.WipeTables:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  MonDKP.ConfigTab4.WipeTables:SetScript("OnClick", function()

    StaticPopupDialogs["WIPE_TABLES"] = {
      text = L["WIPETABLESCONF"],
      button1 = L["YES"],
      button2 = L["NO"],
      OnAccept = function()
        MonDKP_Whitelist = nil
        MonDKP_DKPTable = nil
        MonDKP_Loot = nil
        MonDKP_DKPHistory = nil
        MonDKP_Archive = nil
        MonDKP_Standby = nil
        MonDKP_MinBids = nil
        MonDKP_MaxBids = nil

        MonDKP_DKPTable = {}
        MonDKP_Loot = {}
        MonDKP_DKPHistory = {}
        MonDKP_Archive = {}
        MonDKP_Whitelist = {}
        MonDKP_Standby = {}
        MonDKP_MinBids = {}
        MonDKP_MaxBids = {}
        MonDKP:LootHistory_Reset()
        MonDKP:FilterDKPTable(core.currentSort, "reset")
        MonDKP:StatusVerify_Update()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("WIPE_TABLES")
  end)

  -- Options Footer (empty frame to push bottom of scrollframe down)
  MonDKP.ConfigTab4.OptionsFooterFrame = CreateFrame("Frame", nil, MonDKP.ConfigTab4);
  MonDKP.ConfigTab4.OptionsFooterFrame:SetPoint("TOPLEFT", MonDKP.ConfigTab4.moveTimer, "BOTTOMLEFT")
  MonDKP.ConfigTab4.OptionsFooterFrame:SetSize(420, 50);
end