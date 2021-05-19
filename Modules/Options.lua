local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local moveTimerToggle = 0;
local validating = false

local function DrawPercFrame(box)
  --Draw % signs if set to percent
  CommDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
  CommDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetFontObject("CommDKPNormalLeft");
  CommDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetPoint("LEFT", CommDKP.ConfigTab4.DefaultMinBids.SlotBox[box], "RIGHT", -15, 0);
  CommDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetText("%")
  
  if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetFontObject("CommDKPNormalLeft");
    CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetPoint("LEFT", CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[box], "RIGHT", -15, 0);
    CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetText("%")
  end
end

local function SaveSettings()
  if CommDKP.ConfigTab4.default[1] then
    core.DB.DKPBonus.OnTimeBonus = CommDKP.ConfigTab4.default[1]:GetNumber();
    core.DB.DKPBonus.BossKillBonus = CommDKP.ConfigTab4.default[2]:GetNumber();
    core.DB.DKPBonus.CompletionBonus = CommDKP.ConfigTab4.default[3]:GetNumber();
    core.DB.DKPBonus.NewBossKillBonus = CommDKP.ConfigTab4.default[4]:GetNumber();
    core.DB.DKPBonus.UnexcusedAbsence = CommDKP.ConfigTab4.default[5]:GetNumber();
    if CommDKP.ConfigTab4.default[6]:GetNumber() < 0 then
      core.DB.DKPBonus.DecayPercentage = 0 - CommDKP.ConfigTab4.default[6]:GetNumber();
    else
      core.DB.DKPBonus.DecayPercentage = CommDKP.ConfigTab4.default[6]:GetNumber();
    end
    CommDKP.ConfigTab2.decayDKP:SetNumber(core.DB.DKPBonus.DecayPercentage);
    CommDKP.ConfigTab4.default[6]:SetNumber(core.DB.DKPBonus.DecayPercentage)
    core.DB.DKPBonus.BidTimer = CommDKP.ConfigTab4.bidTimer:GetNumber();

    core.DB.MinBidBySlot.Head = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:GetNumber()
    core.DB.MinBidBySlot.Neck = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:GetNumber()
    core.DB.MinBidBySlot.Shoulders = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[3]:GetNumber()
    core.DB.MinBidBySlot.Cloak = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[4]:GetNumber()
    core.DB.MinBidBySlot.Chest = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[5]:GetNumber()
    core.DB.MinBidBySlot.Bracers = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[6]:GetNumber()
    core.DB.MinBidBySlot.Hands = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[7]:GetNumber()
    core.DB.MinBidBySlot.Belt = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[8]:GetNumber()
    core.DB.MinBidBySlot.Legs = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:GetNumber()
    core.DB.MinBidBySlot.Boots = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[10]:GetNumber()
    core.DB.MinBidBySlot.Ring = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[11]:GetNumber()
    core.DB.MinBidBySlot.Trinket = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[12]:GetNumber()
    core.DB.MinBidBySlot.OneHanded = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[13]:GetNumber()
    core.DB.MinBidBySlot.TwoHanded = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:GetNumber()
    core.DB.MinBidBySlot.OffHand = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[15]:GetNumber()
    core.DB.MinBidBySlot.Range = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[16]:GetNumber()
    core.DB.MinBidBySlot.Other = CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:GetNumber()

    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      core.DB.MaxBidBySlot.Head = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[1]:GetNumber()
      core.DB.MaxBidBySlot.Neck = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[2]:GetNumber()
      core.DB.MaxBidBySlot.Shoulders = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[3]:GetNumber()
      core.DB.MaxBidBySlot.Cloak = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[4]:GetNumber()
      core.DB.MaxBidBySlot.Chest = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[5]:GetNumber()
      core.DB.MaxBidBySlot.Bracers = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[6]:GetNumber()
      core.DB.MaxBidBySlot.Hands = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[7]:GetNumber()
      core.DB.MaxBidBySlot.Belt = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[8]:GetNumber()
      core.DB.MaxBidBySlot.Legs = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:GetNumber()
      core.DB.MaxBidBySlot.Boots = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[10]:GetNumber()
      core.DB.MaxBidBySlot.Ring = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[11]:GetNumber()
      core.DB.MaxBidBySlot.Trinket = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[12]:GetNumber()
      core.DB.MaxBidBySlot.OneHanded = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[13]:GetNumber()
      core.DB.MaxBidBySlot.TwoHanded = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:GetNumber()
      core.DB.MaxBidBySlot.OffHand = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[15]:GetNumber()
      core.DB.MaxBidBySlot.Range = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[16]:GetNumber()
      core.DB.MaxBidBySlot.Other = CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:GetNumber()
      end
  end

  core.CommDKPUI:SetScale(core.DB.defaults.CommDKPScaleSize);
  core.DB.defaults.HistoryLimit = CommDKP.ConfigTab4.history:GetNumber();
  core.DB.defaults.DKPHistoryLimit = CommDKP.ConfigTab4.DKPHistory:GetNumber();
  core.DB.defaults.TooltipHistoryCount = CommDKP.ConfigTab4.TooltipHistory:GetNumber();
  CommDKP:DKPTable_Update()
end

function CommDKP:Options()
  local default = {}
  CommDKP.ConfigTab4.default = default;
  CommDKP:CheckOfficer()
  CommDKP.ConfigTab4.header = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CommDKP.ConfigTab4.header:SetFontObject("CommDKPLargeCenter");
  CommDKP.ConfigTab4.header:SetPoint("TOPLEFT", CommDKP.ConfigTab4, "TOPLEFT", 15, -10);
  CommDKP.ConfigTab4.header:SetText(L["DEFAULTSETTINGS"]);
  CommDKP.ConfigTab4.header:SetScale(1.2)

  if core.IsOfficer == true then
    CommDKP.ConfigTab4.description = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.description:SetFontObject("CommDKPNormalLeft");
    CommDKP.ConfigTab4.description:SetPoint("TOPLEFT", CommDKP.ConfigTab4.header, "BOTTOMLEFT", 7, -15);
    CommDKP.ConfigTab4.description:SetText("|CFFcca600"..L["DEFAULTDKPAWARDVALUES"].."|r");
  
    for i=1, 6 do
      CommDKP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
      CommDKP.ConfigTab4.default[i]:SetAutoFocus(false)
      CommDKP.ConfigTab4.default[i]:SetMultiLine(false)
      CommDKP.ConfigTab4.default[i]:SetSize(80, 24)
      CommDKP.ConfigTab4.default[i]:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
      });
      CommDKP.ConfigTab4.default[i]:SetBackdropColor(0,0,0,0.9)
      CommDKP.ConfigTab4.default[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
      CommDKP.ConfigTab4.default[i]:SetMaxLetters(6)
      CommDKP.ConfigTab4.default[i]:SetTextColor(1, 1, 1, 1)
      CommDKP.ConfigTab4.default[i]:SetFontObject("CommDKPSmallRight")
      CommDKP.ConfigTab4.default[i]:SetTextInsets(10, 10, 5, 5)
      CommDKP.ConfigTab4.default[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:HighlightText(0,0)
        SaveSettings()
        self:ClearFocus()
      end)
      CommDKP.ConfigTab4.default[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
        self:HighlightText(0,0)
        SaveSettings()
        self:ClearFocus()
      end)
      CommDKP.ConfigTab4.default[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
        SaveSettings()
        if i == 6 then
          self:HighlightText(0,0)
          CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetFocus()
          CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:HighlightText()
        else
          self:HighlightText(0,0)
          CommDKP.ConfigTab4.default[i+1]:SetFocus()
          CommDKP.ConfigTab4.default[i+1]:HighlightText()
        end
      end)
      CommDKP.ConfigTab4.default[i]:SetScript("OnEnter", function(self)
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
      CommDKP.ConfigTab4.default[i]:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)

      if i==1 then
        CommDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab4, "TOPLEFT", 144, -84)
      elseif i==4 then
        CommDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab4.default[1], "TOPLEFT", 212, 0)
      else
        CommDKP.ConfigTab4.default[i]:SetPoint("TOP", CommDKP.ConfigTab4.default[i-1], "BOTTOM", 0, -22)
      end
    end

    -- Modes Button
    CommDKP.ConfigTab4.ModesButton = self:CreateButton("TOPRIGHT", CommDKP.ConfigTab4, "TOPRIGHT", -40, -20, L["DKPMODES"]);
    CommDKP.ConfigTab4.ModesButton:SetSize(110,25)
    CommDKP.ConfigTab4.ModesButton:SetScript("OnClick", function()
      CommDKP:ToggleDKPModesWindow()
    end);
    CommDKP.ConfigTab4.ModesButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["DKPMODESTTDESC2"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["DKPMODESTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    CommDKP.ConfigTab4.ModesButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    end)
    if not core.IsOfficer then
      CommDKP.ConfigTab4.ModesButton:Hide()
    end
    CommDKP.ConfigTab4.default[1]:SetText(core.DB.DKPBonus.OnTimeBonus)
    CommDKP.ConfigTab4.default[1].tooltipText = L["ONTIMEBONUS"]
    CommDKP.ConfigTab4.default[1].tooltipDescription = L["ONTIMEBONUSTTDESC"]
      
    CommDKP.ConfigTab4.default[2]:SetText(core.DB.DKPBonus.BossKillBonus)
    CommDKP.ConfigTab4.default[2].tooltipText = L["BOSSKILLBONUS"]
    CommDKP.ConfigTab4.default[2].tooltipDescription = L["BOSSKILLBONUSTTDESC"]
       
    CommDKP.ConfigTab4.default[3]:SetText(core.DB.DKPBonus.CompletionBonus)
    CommDKP.ConfigTab4.default[3].tooltipText = L["RAIDCOMPLETIONBONUS"]
    CommDKP.ConfigTab4.default[3].tooltipDescription = L["RAIDCOMPLETEBONUSTT"]
      
    CommDKP.ConfigTab4.default[4]:SetText(core.DB.DKPBonus.NewBossKillBonus)
    CommDKP.ConfigTab4.default[4].tooltipText = L["NEWBOSSKILLBONUS"]
    CommDKP.ConfigTab4.default[4].tooltipDescription = L["NEWBOSSKILLTTDESC"]

    CommDKP.ConfigTab4.default[5]:SetText(core.DB.DKPBonus.UnexcusedAbsence)
    CommDKP.ConfigTab4.default[5]:SetNumeric(false)
    CommDKP.ConfigTab4.default[5].tooltipText = L["UNEXCUSEDABSENCE"]
    CommDKP.ConfigTab4.default[5].tooltipDescription = L["UNEXCUSEDTTDESC"]
    CommDKP.ConfigTab4.default[5].tooltipWarning = L["UNEXCUSEDTTWARN"]

    CommDKP.ConfigTab4.default[6]:SetText(core.DB.DKPBonus.DecayPercentage)
    CommDKP.ConfigTab4.default[6]:SetTextInsets(0, 15, 0, 0)
    CommDKP.ConfigTab4.default[6].tooltipText = L["DECAYPERCENTAGE"]
    CommDKP.ConfigTab4.default[6].tooltipDescription = L["DECAYPERCENTAGETTDESC"]
    CommDKP.ConfigTab4.default[6].tooltipWarning = L["DECAYPERCENTAGETTWARN"]

    --OnTimeBonus Header
    CommDKP.ConfigTab4.OnTimeHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.OnTimeHeader:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.OnTimeHeader:SetPoint("RIGHT", CommDKP.ConfigTab4.default[1], "LEFT", 0, 0);
    CommDKP.ConfigTab4.OnTimeHeader:SetText(L["ONTIMEBONUS"]..": ")

    --BossKillBonus Header
    CommDKP.ConfigTab4.BossKillHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.BossKillHeader:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.BossKillHeader:SetPoint("RIGHT", CommDKP.ConfigTab4.default[2], "LEFT", 0, 0);
    CommDKP.ConfigTab4.BossKillHeader:SetText(L["BOSSKILLBONUS"]..": ")

    --CompletionBonus Header
    CommDKP.ConfigTab4.CompleteHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.CompleteHeader:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.CompleteHeader:SetPoint("RIGHT", CommDKP.ConfigTab4.default[3], "LEFT", 0, 0);
    CommDKP.ConfigTab4.CompleteHeader:SetText(L["RAIDCOMPLETIONBONUS"]..": ")

    --NewBossKillBonus Header
    CommDKP.ConfigTab4.NewBossHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.NewBossHeader:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.NewBossHeader:SetPoint("RIGHT", CommDKP.ConfigTab4.default[4], "LEFT", 0, 0);
    CommDKP.ConfigTab4.NewBossHeader:SetText(L["NEWBOSSKILLBONUS"]..": ")

    --UnexcusedAbsence Header
    CommDKP.ConfigTab4.UnexcusedHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.UnexcusedHeader:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.UnexcusedHeader:SetPoint("RIGHT", CommDKP.ConfigTab4.default[5], "LEFT", 0, 0);
    CommDKP.ConfigTab4.UnexcusedHeader:SetText(L["UNEXCUSEDABSENCE"]..": ")

    --DKP Decay Header
    CommDKP.ConfigTab4.DecayHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.DecayHeader:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.DecayHeader:SetPoint("RIGHT", CommDKP.ConfigTab4.default[6], "LEFT", 0, 0);
    CommDKP.ConfigTab4.DecayHeader:SetText(L["DECAYAMOUNT"]..": ")

    CommDKP.ConfigTab4.DecayFooter = CommDKP.ConfigTab4.default[6]:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.DecayFooter:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.DecayFooter:SetPoint("LEFT", CommDKP.ConfigTab4.default[6], "RIGHT", -15, -1);
    CommDKP.ConfigTab4.DecayFooter:SetText("%")

    -- Default Minimum Bids Container Frame
    CommDKP.ConfigTab4.DefaultMinBids = CreateFrame("Frame", nil, CommDKP.ConfigTab4);
    CommDKP.ConfigTab4.DefaultMinBids:SetPoint("TOPLEFT", CommDKP.ConfigTab4.default[3], "BOTTOMLEFT", -130, -52)
    CommDKP.ConfigTab4.DefaultMinBids:SetSize(420, 410);

    CommDKP.ConfigTab4.DefaultMinBids.description = CommDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.DefaultMinBids.description:SetFontObject("CommDKPSmallRight");
    CommDKP.ConfigTab4.DefaultMinBids.description:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 15, 15);
      -- DEFAULT min bids Create EditBoxes
      local SlotBox = {}
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox = SlotBox;

      for i=1, 17 do
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i] = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetAutoFocus(false)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMultiLine(false)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetSize(60, 24)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdrop({
          bgFile   = "Textures\\white.blp", tile = true,
          edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
        });
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMaxLetters(6)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetFontObject("CommDKPSmallRight")
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
          if i == 8 then
            self:HighlightText(0,0)
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetFocus()
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:HighlightText()
            SaveSettings()
          elseif i == 5 then
            self:HighlightText(0,0)
            CommDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          elseif i == 13 then
            self:HighlightText(0,0)
            CommDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetFocus()
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:HighlightText()
            SaveSettings()
          elseif i == 17 then
            self:HighlightText(0,0)
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetFocus()
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:HighlightText()
            SaveSettings()
          elseif i == 16 then
            self:HighlightText(0,0)
            CommDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(1)
            CommDKP.ConfigTab4.default[1]:SetFocus()
            CommDKP.ConfigTab4.default[1]:HighlightText()
            SaveSettings()
          else
            self:HighlightText(0,0)
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
            CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          end
        end)
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnter", function(self)
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
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)

        -- Slot Headers
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header = CommDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetFontObject("CommDKPNormalLeft");
        CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetPoint("RIGHT", CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i], "LEFT", 0, 0);

        if i==1 then
          CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 100, -10)
        elseif i==9 then
          CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1], "TOPLEFT", 150, 0)
        elseif i==17 then
          CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", CommDKP.ConfigTab4.DefaultMinBids.SlotBox[8], "BOTTOM", 0, -22)
        else
          CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i-1], "BOTTOM", 0, -22)
        end
      end

      local prefix;
      if core.DB.modes.mode == "Minimum Bid Values" then
        prefix = L["MINIMUMBID"];
        CommDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTMINBIDVALUES"].."|r");
      elseif core.DB.modes.mode == "Static Item Values" then
        CommDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if core.DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif core.DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      elseif core.DB.modes.mode == "Roll Based Bidding" then
        CommDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if core.DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif core.DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      elseif core.DB.modes.mode == "Zero Sum" then
        CommDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if core.DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif core.DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      end
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1].Header:SetText(L["HEAD"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetText(core.DB.MinBidBySlot.Head)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipText = L["HEAD"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipDescription = prefix.." "..L["FORHEADSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[2].Header:SetText(L["NECK"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:SetText(core.DB.MinBidBySlot.Neck)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipText = L["NECK"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipDescription = prefix.." "..L["FORNECKSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[3].Header:SetText(L["SHOULDERS"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[3]:SetText(core.DB.MinBidBySlot.Shoulders)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipText = L["SHOULDERS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipDescription = prefix.." "..L["FORSHOULDERSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[4].Header:SetText(L["CLOAK"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[4]:SetText(core.DB.MinBidBySlot.Cloak)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipText = L["CLOAK"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipDescription = prefix.." "..L["FORBACKSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[5].Header:SetText(L["CHEST"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[5]:SetText(core.DB.MinBidBySlot.Chest)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipText = L["CHEST"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipDescription = prefix.." "..L["FORCHESTSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[6].Header:SetText(L["BRACERS"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[6]:SetText(core.DB.MinBidBySlot.Bracers)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipText = L["BRACERS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipDescription = prefix.." "..L["FORWRISTSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[7].Header:SetText(L["HANDS"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[7]:SetText(core.DB.MinBidBySlot.Hands)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipText = L["HANDS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipDescription = prefix.." "..L["FORHANDSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[8].Header:SetText(L["BELT"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[8]:SetText(core.DB.MinBidBySlot.Belt)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipText = L["BELT"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipDescription = prefix.." "..L["FORWAISTSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[9].Header:SetText(L["LEGS"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetText(core.DB.MinBidBySlot.Legs)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipText = L["LEGS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipDescription = prefix.." "..L["FORLEGSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[10].Header:SetText(L["BOOTS"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[10]:SetText(core.DB.MinBidBySlot.Boots)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipText = L["BOOTS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipDescription = prefix.." "..L["FORFEETSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[11].Header:SetText(L["RINGS"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[11]:SetText(core.DB.MinBidBySlot.Ring)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipText = L["RINGS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipDescription = prefix.." "..L["FORFINGERSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[12].Header:SetText(L["TRINKET"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[12]:SetText(core.DB.MinBidBySlot.Trinket)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipText = L["TRINKET"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipDescription = prefix.." "..L["FORTRINKETSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[13].Header:SetText(L["ONEHANDED"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[13]:SetText(core.DB.MinBidBySlot.OneHanded)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipText = L["ONEHANDEDWEAPONS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipDescription = prefix.." "..L["FORONEHANDSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[14].Header:SetText(L["TWOHANDED"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetText(core.DB.MinBidBySlot.TwoHanded)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipText = L["TWOHANDEDWEAPONS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipDescription = prefix.." "..L["FORTWOHANDSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[15].Header:SetText(L["OFFHAND"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[15]:SetText(core.DB.MinBidBySlot.OffHand)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipText = L["OFFHANDITEMS"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipDescription = prefix.." "..L["FOROFFHANDSLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[16].Header:SetText(L["RANGE"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[16]:SetText(core.DB.MinBidBySlot.Range)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipText = L["RANGE"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipDescription = prefix.." "..L["FORRANGESLOT"]

      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17].Header:SetText(L["OTHER"]..": ")
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetText(core.DB.MinBidBySlot.Other)
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipText = L["OTHER"]
      CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipDescription = prefix.." "..L["FOROTHERSLOT"]

      if core.DB.modes.costvalue == "Percent" then
        for i=1, #CommDKP.ConfigTab4.DefaultMinBids.SlotBox do
          DrawPercFrame(i)
          CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
        end
      end
      -- Broadcast Minimum Bids Button
      CommDKP.ConfigTab4.BroadcastMinBids = self:CreateButton("TOP", CommDKP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"]);
      CommDKP.ConfigTab4.BroadcastMinBids:ClearAllPoints();
      CommDKP.ConfigTab4.BroadcastMinBids:SetPoint("LEFT", CommDKP.ConfigTab4.DefaultMinBids.SlotBox[17], "RIGHT", 41, 0)
      CommDKP.ConfigTab4.BroadcastMinBids:SetSize(110,25)
      CommDKP.ConfigTab4.BroadcastMinBids:SetScript("OnClick", function()
        StaticPopupDialogs["SEND_MINBIDS"] = {
          text = L["BCASTMINBIDCONFIRM"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            local temptable = {}
            table.insert(temptable, core.DB.MinBidBySlot)
            local teams = CommDKP:GetGuildTeamList(true);
            local teamTable = {}
          
            for k, v in pairs(teams) do
              local teamIndex = tostring(v.index);
              table.insert(teamTable, {teamIndex, CommDKP:GetTable(CommDKP_MinBids, true, teamIndex)});
            end
            table.insert(temptable, teamTable);
            CommDKP.Sync:SendData("CommDKPMinBid", temptable)
            CommDKP:Print(L["MINBIDVALUESSENT"])
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("SEND_MINBIDS")
      end);
      CommDKP.ConfigTab4.BroadcastMinBids:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
        GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true);
        GameTooltip:Show()
      end)
      CommDKP.ConfigTab4.BroadcastMinBids:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    -- Default Maximum Bids Container Frame
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      CommDKP.ConfigTab4.DefaultMaxBids = CreateFrame("Frame", nil, CommDKP.ConfigTab4);
      CommDKP.ConfigTab4.DefaultMaxBids:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 0, -52)
      CommDKP.ConfigTab4.DefaultMaxBids:SetSize(420, 410);

      CommDKP.ConfigTab4.DefaultMaxBids.description = CommDKP.ConfigTab4.DefaultMaxBids:CreateFontString(nil, "OVERLAY")
      CommDKP.ConfigTab4.DefaultMaxBids.description:SetFontObject("CommDKPSmallRight");
      CommDKP.ConfigTab4.DefaultMaxBids.description:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMaxBids, "TOPLEFT", 15, 15);

      -- DEFAULT Max bids Create EditBoxes
      local SlotBox = {}
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox = SlotBox;

      for i=1, 17 do
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i] = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetAutoFocus(false)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetMultiLine(false)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetSize(60, 24)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdrop({
          bgFile   = "Textures\\white.blp", tile = true,
          edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
        });
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetMaxLetters(6)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetFontObject("CommDKPSmallRight")
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
          if i == 8 then
            self:HighlightText(0,0)
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:SetFocus()
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:HighlightText()
            SaveSettings()
          elseif i == 5 then
            self:HighlightText(0,0)
            CommDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:SetFocus()
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          elseif i == 13 then
            self:HighlightText(0,0)
            CommDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:SetFocus()
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:HighlightText()
            SaveSettings()
          elseif i == 17 then
            self:HighlightText(0,0)
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:SetFocus()
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:HighlightText()
            SaveSettings()
          elseif i == 16 then
            self:HighlightText(0,0)
            CommDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(1)
            CommDKP.ConfigTab4.default[1]:SetFocus()
            CommDKP.ConfigTab4.default[1]:HighlightText()
            SaveSettings()
          else
            self:HighlightText(0,0)
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:SetFocus()
            CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          end
        end)
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEnter", function(self)
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
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)

        -- Slot Headers
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header = CommDKP.ConfigTab4.DefaultMaxBids:CreateFontString(nil, "OVERLAY")
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header:SetFontObject("CommDKPNormalLeft");
        CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header:SetPoint("RIGHT", CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i], "LEFT", 0, 0);

        if i==1 then
          CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMaxBids, "TOPLEFT", 100, -10)
        elseif i==9 then
          CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[1], "TOPLEFT", 150, 0)
        elseif i==17 then
          CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOP", CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[8], "BOTTOM", 0, -22)
        else
          CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOP", CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i-1], "BOTTOM", 0, -22)
        end
      end

      local prefix;

      prefix = L["MAXIMUMBID"];
      CommDKP.ConfigTab4.DefaultMaxBids.description:SetText("|CFFcca600"..L["DEFAULTMAXBIDVALUES"].."|r");

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].Header:SetText(L["HEAD"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[1]:SetText(core.DB.MaxBidBySlot.Head)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].tooltipText = L["HEAD"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].tooltipDescription = prefix.." "..L["FORHEADSLOT"].." "..L["MAXIMUMBIDTTDESC"]
       
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].Header:SetText(L["NECK"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[2]:SetText(core.DB.MaxBidBySlot.Neck)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].tooltipText = L["NECK"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].tooltipDescription = prefix.." "..L["FORNECKSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].Header:SetText(L["SHOULDERS"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[3]:SetText(core.DB.MaxBidBySlot.Shoulders)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].tooltipText = L["SHOULDERS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].tooltipDescription = prefix.." "..L["FORSHOULDERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].Header:SetText(L["CLOAK"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[4]:SetText(core.DB.MaxBidBySlot.Cloak)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].tooltipText = L["CLOAK"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].tooltipDescription = prefix.." "..L["FORBACKSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].Header:SetText(L["CHEST"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[5]:SetText(core.DB.MaxBidBySlot.Chest)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].tooltipText = L["CHEST"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].tooltipDescription = prefix.." "..L["FORCHESTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].Header:SetText(L["BRACERS"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[6]:SetText(core.DB.MaxBidBySlot.Bracers)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].tooltipText = L["BRACERS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].tooltipDescription = prefix.." "..L["FORWRISTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].Header:SetText(L["HANDS"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[7]:SetText(core.DB.MaxBidBySlot.Hands)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].tooltipText = L["HANDS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].tooltipDescription = prefix.." "..L["FORHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].Header:SetText(L["BELT"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[8]:SetText(core.DB.MaxBidBySlot.Belt)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].tooltipText = L["BELT"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].tooltipDescription = prefix.." "..L["FORWAISTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].Header:SetText(L["LEGS"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:SetText(core.DB.MaxBidBySlot.Legs)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].tooltipText = L["LEGS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].tooltipDescription = prefix.." "..L["FORLEGSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].Header:SetText(L["BOOTS"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[10]:SetText(core.DB.MaxBidBySlot.Boots)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].tooltipText = L["BOOTS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].tooltipDescription = prefix.." "..L["FORFEETSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].Header:SetText(L["RINGS"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[11]:SetText(core.DB.MaxBidBySlot.Ring)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].tooltipText = L["RINGS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].tooltipDescription = prefix.." "..L["FORFINGERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].Header:SetText(L["TRINKET"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[12]:SetText(core.DB.MaxBidBySlot.Trinket)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].tooltipText = L["TRINKET"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].tooltipDescription = prefix.." "..L["FORTRINKETSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].Header:SetText(L["ONEHANDED"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[13]:SetText(core.DB.MaxBidBySlot.OneHanded)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].tooltipText = L["ONEHANDEDWEAPONS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].tooltipDescription = prefix.." "..L["FORONEHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].Header:SetText(L["TWOHANDED"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:SetText(core.DB.MaxBidBySlot.TwoHanded)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].tooltipText = L["TWOHANDEDWEAPONS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].tooltipDescription = prefix.." "..L["FORTWOHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].Header:SetText(L["OFFHAND"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[15]:SetText(core.DB.MaxBidBySlot.OffHand)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].tooltipText = L["OFFHANDITEMS"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].tooltipDescription = prefix.." "..L["FOROFFHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].Header:SetText(L["RANGE"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[16]:SetText(core.DB.MaxBidBySlot.Range)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].tooltipText = L["RANGE"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].tooltipDescription = prefix.." "..L["FORRANGESLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].Header:SetText(L["OTHER"]..": ")
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:SetText(core.DB.MaxBidBySlot.Other)
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].tooltipText = L["OTHER"]
      CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].tooltipDescription = prefix.." "..L["FOROTHERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      if core.DB.modes.costvalue == "Percent" then
        for i=1, #CommDKP.ConfigTab4.DefaultMaxBids.SlotBox do
          DrawPercFrame(i)
          CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
        end
      end
      -- Broadcast Maximum Bids Button
      CommDKP.ConfigTab4.BroadcastMaxBids = self:CreateButton("TOP", CommDKP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"]);
      CommDKP.ConfigTab4.BroadcastMaxBids:ClearAllPoints();
      CommDKP.ConfigTab4.BroadcastMaxBids:SetPoint("LEFT", CommDKP.ConfigTab4.DefaultMaxBids.SlotBox[17], "RIGHT", 41, 0)
      CommDKP.ConfigTab4.BroadcastMaxBids:SetSize(110,25)
      CommDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnClick", function()
        StaticPopupDialogs["SEND_MAXBIDS"] = {
          text = L["BCASTMAXBIDCONFIRM"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            local temptable = {}
            table.insert(temptable, core.DB.MaxBidBySlot)
            local teams = CommDKP:GetGuildTeamList(true);
            local teamTable = {}
          
            for k, v in pairs(teams) do
              local teamIndex = tostring(v.index);
              table.insert(teamTable, {teamIndex, CommDKP:GetTable(CommDKP_MaxBids, true, teamIndex)});
            end
            table.insert(temptable, teamTable);
            CommDKP.Sync:SendData("CommDKPMaxBid", temptable)
            CommDKP:Print(L["MAXBIDVALUESSENT"])
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("SEND_MAXBIDS")
      end);
      CommDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
        GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true);
        GameTooltip:Show()
      end)
      CommDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    end
    -- Bid Timer Slider
    CommDKP.ConfigTab4.bidTimerSlider = CreateFrame("SLIDER", "$parentBidTimerSlider", CommDKP.ConfigTab4, "CommDKPOptionsSliderTemplate");
    Mixin(CommDKP.ConfigTab4.bidTimerSlider, BackdropTemplateMixin)
  CommDKP.ConfigTab4.bidTimerSlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      CommDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMaxBids, "BOTTOMLEFT", 54, -40);
    else
      CommDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 54, -40);
    end
    CommDKP.ConfigTab4.bidTimerSlider:SetMinMaxValues(10, 90);
    CommDKP.ConfigTab4.bidTimerSlider:SetValue(core.DB.DKPBonus.BidTimer);
    CommDKP.ConfigTab4.bidTimerSlider:SetValueStep(1);
    CommDKP.ConfigTab4.bidTimerSlider.tooltipText = L["BIDTIMER"]
    CommDKP.ConfigTab4.bidTimerSlider.tooltipRequirement = L["BIDTIMERDEFAULTTTDESC"]
    CommDKP.ConfigTab4.bidTimerSlider:SetObeyStepOnDrag(true);
    getglobal(CommDKP.ConfigTab4.bidTimerSlider:GetName().."Low"):SetText("10")
    getglobal(CommDKP.ConfigTab4.bidTimerSlider:GetName().."High"):SetText("90")
    CommDKP.ConfigTab4.bidTimerSlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
      CommDKP.ConfigTab4.bidTimer:SetText(CommDKP.ConfigTab4.bidTimerSlider:GetValue())
    end)

    CommDKP.ConfigTab4.bidTimerHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CommDKP.ConfigTab4.bidTimerHeader:SetFontObject("CommDKPTinyCenter");
    CommDKP.ConfigTab4.bidTimerHeader:SetPoint("BOTTOM", CommDKP.ConfigTab4.bidTimerSlider, "TOP", 0, 3);
    CommDKP.ConfigTab4.bidTimerHeader:SetText(L["BIDTIMER"])

    CommDKP.ConfigTab4.bidTimer = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
    CommDKP.ConfigTab4.bidTimer:SetAutoFocus(false)
    CommDKP.ConfigTab4.bidTimer:SetMultiLine(false)
    CommDKP.ConfigTab4.bidTimer:SetSize(50, 18)
    CommDKP.ConfigTab4.bidTimer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
    CommDKP.ConfigTab4.bidTimer:SetBackdropColor(0,0,0,0.9)
    CommDKP.ConfigTab4.bidTimer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    CommDKP.ConfigTab4.bidTimer:SetMaxLetters(4)
    CommDKP.ConfigTab4.bidTimer:SetTextColor(1, 1, 1, 1)
    CommDKP.ConfigTab4.bidTimer:SetFontObject("CommDKPTinyCenter")
    CommDKP.ConfigTab4.bidTimer:SetTextInsets(10, 10, 5, 5)
    CommDKP.ConfigTab4.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    CommDKP.ConfigTab4.bidTimer:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    CommDKP.ConfigTab4.bidTimer:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
      CommDKP.ConfigTab4.bidTimerSlider:SetValue(CommDKP.ConfigTab4.bidTimer:GetNumber());
    end)
    CommDKP.ConfigTab4.bidTimer:SetPoint("TOP", CommDKP.ConfigTab4.bidTimerSlider, "BOTTOM", 0, -3)     
    CommDKP.ConfigTab4.bidTimer:SetText(CommDKP.ConfigTab4.bidTimerSlider:GetValue())
  end -- the end

  -- Tooltip History Slider
  CommDKP.ConfigTab4.TooltipHistorySlider = CreateFrame("SLIDER", "$parentTooltipHistorySlider", CommDKP.ConfigTab4, "CommDKPOptionsSliderTemplate");
  if CommDKP.ConfigTab4.bidTimer then
    CommDKP.ConfigTab4.TooltipHistorySlider:SetPoint("LEFT", CommDKP.ConfigTab4.bidTimerSlider, "RIGHT", 30, 0);
  else
    CommDKP.ConfigTab4.TooltipHistorySlider:SetPoint("TOP", CommDKP.ConfigTab4, "TOP", 1, -107);
  end

  Mixin(CommDKP.ConfigTab4.TooltipHistorySlider, BackdropTemplateMixin)
  CommDKP.ConfigTab4.TooltipHistorySlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })

  CommDKP.ConfigTab4.TooltipHistorySlider:SetMinMaxValues(5, 35);
  CommDKP.ConfigTab4.TooltipHistorySlider:SetValue(core.DB.defaults.TooltipHistoryCount);
  CommDKP.ConfigTab4.TooltipHistorySlider:SetValueStep(1);
  CommDKP.ConfigTab4.TooltipHistorySlider.tooltipText = L["TTHISTORYCOUNT"]
  CommDKP.ConfigTab4.TooltipHistorySlider.tooltipRequirement = L["TTHISTORYCOUNTTTDESC"]
  CommDKP.ConfigTab4.TooltipHistorySlider:SetObeyStepOnDrag(true);
  getglobal(CommDKP.ConfigTab4.TooltipHistorySlider:GetName().."Low"):SetText("5")
  getglobal(CommDKP.ConfigTab4.TooltipHistorySlider:GetName().."High"):SetText("35")
  CommDKP.ConfigTab4.TooltipHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.TooltipHistory:SetText(CommDKP.ConfigTab4.TooltipHistorySlider:GetValue())
  end)

  CommDKP.ConfigTab4.TooltipHistoryHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CommDKP.ConfigTab4.TooltipHistoryHeader:SetFontObject("CommDKPTinyCenter");
  CommDKP.ConfigTab4.TooltipHistoryHeader:SetPoint("BOTTOM", CommDKP.ConfigTab4.TooltipHistorySlider, "TOP", 0, 3);
  CommDKP.ConfigTab4.TooltipHistoryHeader:SetText(L["TTHISTORYCOUNT"])

  CommDKP.ConfigTab4.TooltipHistory = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  CommDKP.ConfigTab4.TooltipHistory:SetAutoFocus(false)
  CommDKP.ConfigTab4.TooltipHistory:SetMultiLine(false)
  CommDKP.ConfigTab4.TooltipHistory:SetSize(50, 18)
  CommDKP.ConfigTab4.TooltipHistory:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CommDKP.ConfigTab4.TooltipHistory:SetBackdropColor(0,0,0,0.9)
  CommDKP.ConfigTab4.TooltipHistory:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
  CommDKP.ConfigTab4.TooltipHistory:SetMaxLetters(4)
  CommDKP.ConfigTab4.TooltipHistory:SetTextColor(1, 1, 1, 1)
  CommDKP.ConfigTab4.TooltipHistory:SetFontObject("CommDKPTinyCenter")
  CommDKP.ConfigTab4.TooltipHistory:SetTextInsets(10, 10, 5, 5)
  CommDKP.ConfigTab4.TooltipHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.TooltipHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.TooltipHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.TooltipHistorySlider:SetValue(CommDKP.ConfigTab4.TooltipHistory:GetNumber());
  end)
  CommDKP.ConfigTab4.TooltipHistory:SetPoint("TOP", CommDKP.ConfigTab4.TooltipHistorySlider, "BOTTOM", 0, -3)     
  CommDKP.ConfigTab4.TooltipHistory:SetText(CommDKP.ConfigTab4.TooltipHistorySlider:GetValue())


  -- Loot History Limit Slider
  CommDKP.ConfigTab4.historySlider = CreateFrame("SLIDER", "$parentHistorySlider", CommDKP.ConfigTab4, "CommDKPOptionsSliderTemplate");

  if CommDKP.ConfigTab4.bidTimer then
    CommDKP.ConfigTab4.historySlider:SetPoint("TOPLEFT", CommDKP.ConfigTab4.bidTimerSlider, "BOTTOMLEFT", 0, -50);
  else
    CommDKP.ConfigTab4.historySlider:SetPoint("TOPRIGHT", CommDKP.ConfigTab4.TooltipHistorySlider, "BOTTOMLEFT", 56, -49);
  end

  Mixin(CommDKP.ConfigTab4.historySlider, BackdropTemplateMixin)
  CommDKP.ConfigTab4.historySlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })

  CommDKP.ConfigTab4.historySlider:SetMinMaxValues(100, 2500);
  CommDKP.ConfigTab4.historySlider:SetValue(core.DB.defaults.HistoryLimit);
  CommDKP.ConfigTab4.historySlider:SetValueStep(25);
  CommDKP.ConfigTab4.historySlider.tooltipText = L["LOOTHISTORYLIMIT"]
  CommDKP.ConfigTab4.historySlider.tooltipRequirement = L["LOOTHISTLIMITTTDESC"]
  CommDKP.ConfigTab4.historySlider.tooltipWarning = L["LOOTHISTLIMITTTWARN"]
  CommDKP.ConfigTab4.historySlider:SetObeyStepOnDrag(true);
  getglobal(CommDKP.ConfigTab4.historySlider:GetName().."Low"):SetText("100")
  getglobal(CommDKP.ConfigTab4.historySlider:GetName().."High"):SetText("2500")
  CommDKP.ConfigTab4.historySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.history:SetText(CommDKP.ConfigTab4.historySlider:GetValue())
  end)

  CommDKP.ConfigTab4.HistoryHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CommDKP.ConfigTab4.HistoryHeader:SetFontObject("CommDKPTinyCenter");
  CommDKP.ConfigTab4.HistoryHeader:SetPoint("BOTTOM", CommDKP.ConfigTab4.historySlider, "TOP", 0, 3);
  CommDKP.ConfigTab4.HistoryHeader:SetText(L["LOOTHISTORYLIMIT"])

  CommDKP.ConfigTab4.history = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  CommDKP.ConfigTab4.history:SetAutoFocus(false)
  CommDKP.ConfigTab4.history:SetMultiLine(false)
  CommDKP.ConfigTab4.history:SetSize(50, 18)
  CommDKP.ConfigTab4.history:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CommDKP.ConfigTab4.history:SetBackdropColor(0,0,0,0.9)
  CommDKP.ConfigTab4.history:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
  CommDKP.ConfigTab4.history:SetMaxLetters(4)
  CommDKP.ConfigTab4.history:SetTextColor(1, 1, 1, 1)
  CommDKP.ConfigTab4.history:SetFontObject("CommDKPTinyCenter")
  CommDKP.ConfigTab4.history:SetTextInsets(10, 10, 5, 5)
  CommDKP.ConfigTab4.history:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.history:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.history:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.historySlider:SetValue(CommDKP.ConfigTab4.history:GetNumber());
  end)
  CommDKP.ConfigTab4.history:SetPoint("TOP", CommDKP.ConfigTab4.historySlider, "BOTTOM", 0, -3)     
  CommDKP.ConfigTab4.history:SetText(CommDKP.ConfigTab4.historySlider:GetValue())

  -- DKP History Limit Slider
  CommDKP.ConfigTab4.DKPHistorySlider = CreateFrame("SLIDER", "$parentDKPHistorySlider", CommDKP.ConfigTab4, "CommDKPOptionsSliderTemplate");
  Mixin(CommDKP.ConfigTab4.DKPHistorySlider, BackdropTemplateMixin)
  CommDKP.ConfigTab4.DKPHistorySlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  CommDKP.ConfigTab4.DKPHistorySlider:SetPoint("LEFT", CommDKP.ConfigTab4.historySlider, "RIGHT", 30, 0);
  CommDKP.ConfigTab4.DKPHistorySlider:SetMinMaxValues(100, 2500);
  CommDKP.ConfigTab4.DKPHistorySlider:SetValue(core.DB.defaults.DKPHistoryLimit);
  CommDKP.ConfigTab4.DKPHistorySlider:SetValueStep(25);
  CommDKP.ConfigTab4.DKPHistorySlider.tooltipText = L["DKPHISTORYLIMIT"]
  CommDKP.ConfigTab4.DKPHistorySlider.tooltipRequirement = L["DKPHISTLIMITTTDESC"]
  CommDKP.ConfigTab4.DKPHistorySlider.tooltipWarning = L["DKPHISTLIMITTTWARN"]
  CommDKP.ConfigTab4.DKPHistorySlider:SetObeyStepOnDrag(true);
  getglobal(CommDKP.ConfigTab4.DKPHistorySlider:GetName().."Low"):SetText("100")
  getglobal(CommDKP.ConfigTab4.DKPHistorySlider:GetName().."High"):SetText("2500")
  CommDKP.ConfigTab4.DKPHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.DKPHistory:SetText(CommDKP.ConfigTab4.DKPHistorySlider:GetValue())
  end)

  CommDKP.ConfigTab4.DKPHistoryHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CommDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("CommDKPTinyCenter");
  CommDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", CommDKP.ConfigTab4.DKPHistorySlider, "TOP", 0, 3);
  CommDKP.ConfigTab4.DKPHistoryHeader:SetText(L["DKPHISTORYLIMIT"])

  CommDKP.ConfigTab4.DKPHistory = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  CommDKP.ConfigTab4.DKPHistory:SetAutoFocus(false)
  CommDKP.ConfigTab4.DKPHistory:SetMultiLine(false)
  CommDKP.ConfigTab4.DKPHistory:SetSize(50, 18)
  CommDKP.ConfigTab4.DKPHistory:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CommDKP.ConfigTab4.DKPHistory:SetBackdropColor(0,0,0,0.9)
  CommDKP.ConfigTab4.DKPHistory:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  CommDKP.ConfigTab4.DKPHistory:SetMaxLetters(4)
  CommDKP.ConfigTab4.DKPHistory:SetTextColor(1, 1, 1, 1)
  CommDKP.ConfigTab4.DKPHistory:SetFontObject("CommDKPTinyCenter")
  CommDKP.ConfigTab4.DKPHistory:SetTextInsets(10, 10, 5, 5)
  CommDKP.ConfigTab4.DKPHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.DKPHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.DKPHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.DKPHistorySlider:SetValue(CommDKP.ConfigTab4.history:GetNumber());
  end)
  CommDKP.ConfigTab4.DKPHistory:SetPoint("TOP", CommDKP.ConfigTab4.DKPHistorySlider, "BOTTOM", 0, -3)     
  CommDKP.ConfigTab4.DKPHistory:SetText(CommDKP.ConfigTab4.DKPHistorySlider:GetValue())

  -- Bid Timer Size Slider
  CommDKP.ConfigTab4.TimerSizeSlider = CreateFrame("SLIDER", "$parentBidTimerSizeSlider", CommDKP.ConfigTab4, "CommDKPOptionsSliderTemplate");
  Mixin(CommDKP.ConfigTab4.TimerSizeSlider, BackdropTemplateMixin)
  CommDKP.ConfigTab4.TimerSizeSlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  CommDKP.ConfigTab4.TimerSizeSlider:SetPoint("TOPLEFT", CommDKP.ConfigTab4.historySlider, "BOTTOMLEFT", 0, -50);
  CommDKP.ConfigTab4.TimerSizeSlider:SetMinMaxValues(0.5, 2.0);
  CommDKP.ConfigTab4.TimerSizeSlider:SetValue(core.DB.defaults.BidTimerSize);
  CommDKP.ConfigTab4.TimerSizeSlider:SetValueStep(0.05);
  CommDKP.ConfigTab4.TimerSizeSlider.tooltipText = L["TIMERSIZE"]
  CommDKP.ConfigTab4.TimerSizeSlider.tooltipRequirement = L["TIMERSIZETTDESC"]
  CommDKP.ConfigTab4.TimerSizeSlider.tooltipWarning = L["TIMERSIZETTWARN"]
  CommDKP.ConfigTab4.TimerSizeSlider:SetObeyStepOnDrag(true);
  getglobal(CommDKP.ConfigTab4.TimerSizeSlider:GetName().."Low"):SetText("50%")
  getglobal(CommDKP.ConfigTab4.TimerSizeSlider:GetName().."High"):SetText("200%")
  CommDKP.ConfigTab4.TimerSizeSlider:SetScript("OnValueChanged", function(self)   
    CommDKP.ConfigTab4.TimerSize:SetText(CommDKP.ConfigTab4.TimerSizeSlider:GetValue())
    core.DB.defaults.BidTimerSize = CommDKP.ConfigTab4.TimerSizeSlider:GetValue();
    CommDKP.BidTimer:SetScale(core.DB.defaults.BidTimerSize);
  end)

  CommDKP.ConfigTab4.DKPHistoryHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CommDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("CommDKPTinyCenter");
  CommDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", CommDKP.ConfigTab4.TimerSizeSlider, "TOP", 0, 3);
  CommDKP.ConfigTab4.DKPHistoryHeader:SetText(L["TIMERSIZE"])

  CommDKP.ConfigTab4.TimerSize = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  CommDKP.ConfigTab4.TimerSize:SetAutoFocus(false)
  CommDKP.ConfigTab4.TimerSize:SetMultiLine(false)
  CommDKP.ConfigTab4.TimerSize:SetSize(50, 18)
  CommDKP.ConfigTab4.TimerSize:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CommDKP.ConfigTab4.TimerSize:SetBackdropColor(0,0,0,0.9)
  CommDKP.ConfigTab4.TimerSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  CommDKP.ConfigTab4.TimerSize:SetMaxLetters(4)
  CommDKP.ConfigTab4.TimerSize:SetTextColor(1, 1, 1, 1)
  CommDKP.ConfigTab4.TimerSize:SetFontObject("CommDKPTinyCenter")
  CommDKP.ConfigTab4.TimerSize:SetTextInsets(10, 10, 5, 5)
  CommDKP.ConfigTab4.TimerSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.TimerSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.TimerSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.TimerSizeSlider:SetValue(CommDKP.ConfigTab4.TimerSize:GetNumber());
  end)
  CommDKP.ConfigTab4.TimerSize:SetPoint("TOP", CommDKP.ConfigTab4.TimerSizeSlider, "BOTTOM", 0, -3)     
  CommDKP.ConfigTab4.TimerSize:SetText(CommDKP.ConfigTab4.TimerSizeSlider:GetValue())

  -- UI Scale Size Slider
  CommDKP.ConfigTab4.CommDKPScaleSize = CreateFrame("SLIDER", "$parentCommDKPScaleSizeSlider", CommDKP.ConfigTab4, "CommDKPOptionsSliderTemplate");
  Mixin(CommDKP.ConfigTab4.CommDKPScaleSize, BackdropTemplateMixin)
  CommDKP.ConfigTab4.CommDKPScaleSize:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  CommDKP.ConfigTab4.CommDKPScaleSize:SetPoint("TOPLEFT", CommDKP.ConfigTab4.DKPHistorySlider, "BOTTOMLEFT", 0, -50);
  CommDKP.ConfigTab4.CommDKPScaleSize:SetMinMaxValues(0.5, 2.0);
  CommDKP.ConfigTab4.CommDKPScaleSize:SetValue(core.DB.defaults.CommDKPScaleSize);
  CommDKP.ConfigTab4.CommDKPScaleSize:SetValueStep(0.05);
  CommDKP.ConfigTab4.CommDKPScaleSize.tooltipText = L["CommDKPSCALESIZE"]
  CommDKP.ConfigTab4.CommDKPScaleSize.tooltipRequirement = L["CommDKPSCALESIZETTDESC"]
  CommDKP.ConfigTab4.CommDKPScaleSize.tooltipWarning = L["CommDKPSCALESIZETTWARN"]
  CommDKP.ConfigTab4.CommDKPScaleSize:SetObeyStepOnDrag(true);
  getglobal(CommDKP.ConfigTab4.CommDKPScaleSize:GetName().."Low"):SetText("50%")
  getglobal(CommDKP.ConfigTab4.CommDKPScaleSize:GetName().."High"):SetText("200%")
  CommDKP.ConfigTab4.CommDKPScaleSize:SetScript("OnValueChanged", function(self)   
    CommDKP.ConfigTab4.UIScaleSize:SetText(CommDKP.ConfigTab4.CommDKPScaleSize:GetValue())
    core.DB.defaults.CommDKPScaleSize = CommDKP.ConfigTab4.CommDKPScaleSize:GetValue();
  end)

  CommDKP.ConfigTab4.DKPHistoryHeader = CommDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CommDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("CommDKPTinyCenter");
  CommDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", CommDKP.ConfigTab4.CommDKPScaleSize, "TOP", 0, 3);
  CommDKP.ConfigTab4.DKPHistoryHeader:SetText(L["MAINGUISIZE"])

  CommDKP.ConfigTab4.UIScaleSize = CreateFrame("EditBox", nil, CommDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  CommDKP.ConfigTab4.UIScaleSize:SetAutoFocus(false)
  CommDKP.ConfigTab4.UIScaleSize:SetMultiLine(false)
  CommDKP.ConfigTab4.UIScaleSize:SetSize(50, 18)
  CommDKP.ConfigTab4.UIScaleSize:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CommDKP.ConfigTab4.UIScaleSize:SetBackdropColor(0,0,0,0.9)
  CommDKP.ConfigTab4.UIScaleSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  CommDKP.ConfigTab4.UIScaleSize:SetMaxLetters(4)
  CommDKP.ConfigTab4.UIScaleSize:SetTextColor(1, 1, 1, 1)
  CommDKP.ConfigTab4.UIScaleSize:SetFontObject("CommDKPTinyCenter")
  CommDKP.ConfigTab4.UIScaleSize:SetTextInsets(10, 10, 5, 5)
  CommDKP.ConfigTab4.UIScaleSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.UIScaleSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CommDKP.ConfigTab4.UIScaleSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CommDKP.ConfigTab4.CommDKPScaleSize:SetValue(CommDKP.ConfigTab4.UIScaleSize:GetNumber());
  end)
  CommDKP.ConfigTab4.UIScaleSize:SetPoint("TOP", CommDKP.ConfigTab4.CommDKPScaleSize, "BOTTOM", 0, -3)     
  CommDKP.ConfigTab4.UIScaleSize:SetText(CommDKP.ConfigTab4.CommDKPScaleSize:GetValue())

  -- Suppress Broadcast Notifications checkbox
  CommDKP.ConfigTab4.SuppressNotifications = CreateFrame("CheckButton", nil, CommDKP.ConfigTab4, "UICheckButtonTemplate");
  CommDKP.ConfigTab4.SuppressNotifications:SetPoint("TOP", CommDKP.ConfigTab4.TimerSizeSlider, "BOTTOMLEFT", 0, -35)
  CommDKP.ConfigTab4.SuppressNotifications:SetChecked(core.DB.defaults.SuppressNotifications)
  CommDKP.ConfigTab4.SuppressNotifications:SetScale(0.8)
  CommDKP.ConfigTab4.SuppressNotifications.text:SetText("|cff5151de"..L["SUPPRESSNOTIFICATIONS"].."|r");
  CommDKP.ConfigTab4.SuppressNotifications.text:SetFontObject("CommDKPSmall")
  CommDKP.ConfigTab4.SuppressNotifications:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["SUPPRESSNOTIFICATIONS"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["SUPPRESSNOTIFYTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["SUPPRESSNOTIFYTTWARN"], 1.0, 0, 0, true);
    GameTooltip:Show()
  end)
  CommDKP.ConfigTab4.SuppressNotifications:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  CommDKP.ConfigTab4.SuppressNotifications:SetScript("OnClick", function()
    if CommDKP.ConfigTab4.SuppressNotifications:GetChecked() then
      CommDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cffff0000"..L["HIDDEN"].."|r.")
      core.DB["defaults"]["SuppressNotifications"] = true;
    else
      core.DB["defaults"]["SuppressNotifications"] = false;
      CommDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cff00ff00"..L["VISIBLE"].."|r.")
    end
    PlaySound(808)
  end)

  -- Combat Logging checkbox
  CommDKP.ConfigTab4.CombatLogging = CreateFrame("CheckButton", nil, CommDKP.ConfigTab4, "UICheckButtonTemplate");
  CommDKP.ConfigTab4.CombatLogging:SetPoint("TOP", CommDKP.ConfigTab4.SuppressNotifications, "BOTTOM", 0, 0)
  CommDKP.ConfigTab4.CombatLogging:SetChecked(core.DB.defaults.AutoLog)
  CommDKP.ConfigTab4.CombatLogging:SetScale(0.8)
  CommDKP.ConfigTab4.CombatLogging.text:SetText("|cff5151de"..L["AUTOCOMBATLOG"].."|r");
  CommDKP.ConfigTab4.CombatLogging.text:SetFontObject("CommDKPSmall")
  CommDKP.ConfigTab4.CombatLogging:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["AUTOCOMBATLOG"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["AUTOCOMBATLOGTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["AUTOCOMBATLOGTTWARN"], 1.0, 0, 0, true);
    GameTooltip:Show()
  end)
  CommDKP.ConfigTab4.CombatLogging:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  CommDKP.ConfigTab4.CombatLogging:SetScript("OnClick", function(self)
    core.DB.defaults.AutoLog = self:GetChecked()
    PlaySound(808)
  end)

  if core.DB.defaults.AutoOpenBid == nil then
    core.DB.defaults.AutoOpenBid = true
  end

  CommDKP.ConfigTab4.AutoOpenCheckbox = CreateFrame("CheckButton", nil, CommDKP.ConfigTab4, "UICheckButtonTemplate");
  CommDKP.ConfigTab4.AutoOpenCheckbox:SetChecked(core.DB.defaults.AutoOpenBid)
  CommDKP.ConfigTab4.AutoOpenCheckbox:SetScale(0.8);
  CommDKP.ConfigTab4.AutoOpenCheckbox.text:SetText("|cff5151de"..L["AUTOOPEN"].."|r");
  CommDKP.ConfigTab4.AutoOpenCheckbox.text:SetScale(1);
  CommDKP.ConfigTab4.AutoOpenCheckbox.text:SetFontObject("CommDKPSmallLeft")
  CommDKP.ConfigTab4.AutoOpenCheckbox:SetPoint("TOP", CommDKP.ConfigTab4.CombatLogging, "BOTTOM", 0, 0);
  CommDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnClick", function(self)
    core.DB.defaults.AutoOpenBid = self:GetChecked()
  end)
  CommDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    GameTooltip:SetText(L["AUTOOPEN"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["AUTOOPENTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  CommDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  if core.IsOfficer == true then
    -- Suppress Broadcast Notifications checkbox
    CommDKP.ConfigTab4.SuppressTells = CreateFrame("CheckButton", nil, CommDKP.ConfigTab4, "UICheckButtonTemplate");
    CommDKP.ConfigTab4.SuppressTells:SetPoint("LEFT", CommDKP.ConfigTab4.SuppressNotifications, "RIGHT", 200, 0)
    CommDKP.ConfigTab4.SuppressTells:SetChecked(core.DB.defaults.SuppressTells)
    CommDKP.ConfigTab4.SuppressTells:SetScale(0.8)
    CommDKP.ConfigTab4.SuppressTells.text:SetText("|cff5151de"..L["SUPPRESSBIDWHISP"].."|r");
    CommDKP.ConfigTab4.SuppressTells.text:SetFontObject("CommDKPSmall")
    CommDKP.ConfigTab4.SuppressTells:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["SUPPRESSBIDWHISP"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["SuppressBIDWHISPTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["SuppressBIDWHISPTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    CommDKP.ConfigTab4.SuppressTells:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    CommDKP.ConfigTab4.SuppressTells:SetScript("OnClick", function()
      if CommDKP.ConfigTab4.SuppressTells:GetChecked() then
        CommDKP:Print(L["BIDWHISPARENOW"].." |cffff0000"..L["HIDDEN"].."|r.")
        core.DB["defaults"]["SuppressTells"] = true;
      else
        core.DB["defaults"]["SuppressTells"] = false;
        CommDKP:Print(L["BIDWHISPARENOW"].." |cff00ff00"..L["VISIBLE"].."|r.")
      end
      PlaySound(808)
    end)

    if core.DB.defaults.DecreaseDisenchantValue == nil then
      core.DB.defaults.DecreaseDisenchantValue = false
    end
  
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox = CreateFrame("CheckButton", nil, CommDKP.ConfigTab4, "UICheckButtonTemplate");
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetPoint("LEFT", CommDKP.ConfigTab4.CombatLogging, "RIGHT", 200, 0)
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetChecked(core.DB.defaults.DecreaseDisenchantValue)
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScale(0.8);
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox.text:SetText("|cff5151de"..L["DECREASEDISENCHANT"].."|r");
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox.text:SetFontObject("CommDKPSmall")
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScript("OnClick", function(self)
      core.DB.defaults.DecreaseDisenchantValue = self:GetChecked()
    end)
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT");
      GameTooltip:SetText(L["DECREASEDISENCHANT"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["DECREASEDISENCHANTTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:Show();
    end)
    CommDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  
  end

  -- Save Settings Button
  CommDKP.ConfigTab4.submitSettings = self:CreateButton("BOTTOMLEFT", CommDKP.ConfigTab4, "BOTTOMLEFT", 30, 30, L["SAVESETTINGS"]);
  CommDKP.ConfigTab4.submitSettings:ClearAllPoints();
  CommDKP.ConfigTab4.submitSettings:SetPoint("TOP", CommDKP.ConfigTab4.AutoOpenCheckbox, "BOTTOMLEFT", 20, -40)
  CommDKP.ConfigTab4.submitSettings:SetSize(90,25)
  CommDKP.ConfigTab4.submitSettings:SetScript("OnClick", function()
    if core.IsOfficer == true then
      for i=1, 6 do
        if not tonumber(CommDKP.ConfigTab4.default[i]:GetText()) then
          StaticPopupDialogs["OPTIONS_VALIDATION"] = {
            text = L["INVALIDOPTIONENTRY"].." "..CommDKP.ConfigTab4.default[i].tooltipText..". "..L["PLEASEUSENUMS"],
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
        if not tonumber(CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:GetText()) then
          StaticPopupDialogs["OPTIONS_VALIDATION"] = {
            text = L["INVALIDMINBIDENTRY"].." "..CommDKP.ConfigTab4.DefaultMinBids.SlotBox[i].tooltipText..". "..L["PLEASEUSENUMS"],
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
    CommDKP:Print(L["DEFAULTSETSAVED"])
  end)

  -- Chatframe Selection 
  CommDKP.ConfigTab4.ChatFrame = CreateFrame("FRAME", "CommDKPChatFrameSelectDropDown", CommDKP.ConfigTab4, "CommunityDKPUIDropDownMenuTemplate")
  if not core.DB.defaults.ChatFrames then core.DB.defaults.ChatFrames = {} end

  UIDropDownMenu_Initialize(CommDKP.ConfigTab4.ChatFrame, function(self, level, menuList)
  local SelectedFrame = UIDropDownMenu_CreateInfo()
    SelectedFrame.func = self.SetValue
    SelectedFrame.fontObject = "CommDKPSmallCenter"
    SelectedFrame.keepShownOnClick = true;
    SelectedFrame.isNotRadio = true;

    for i = 1, NUM_CHAT_WINDOWS do
      local name = GetChatWindowInfo(i)
      if name ~= "" then
        SelectedFrame.text, SelectedFrame.arg1, SelectedFrame.checked = name, name, core.DB.defaults.ChatFrames[name]
        UIDropDownMenu_AddButton(SelectedFrame)
      end
    end
  end)

  CommDKP.ConfigTab4.ChatFrame:SetPoint("LEFT", CommDKP.ConfigTab4.AutoOpenCheckbox, "RIGHT", 130, 0)
  UIDropDownMenu_SetWidth(CommDKP.ConfigTab4.ChatFrame, 150)
  UIDropDownMenu_SetText(CommDKP.ConfigTab4.ChatFrame, "Addon Notifications")

  function CommDKP.ConfigTab4.ChatFrame:SetValue(arg1)
    core.DB.defaults.ChatFrames[arg1] = not core.DB.defaults.ChatFrames[arg1]
    CloseDropDownMenus()
  end



  -- Position Bid Timer Button
  CommDKP.ConfigTab4.moveTimer = self:CreateButton("BOTTOMRIGHT", CommDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["MOVEBIDTIMER"]);
  CommDKP.ConfigTab4.moveTimer:ClearAllPoints();
  CommDKP.ConfigTab4.moveTimer:SetPoint("LEFT", CommDKP.ConfigTab4.submitSettings, "RIGHT", 200, 0)
  CommDKP.ConfigTab4.moveTimer:SetSize(110,25)
  CommDKP.ConfigTab4.moveTimer:SetScript("OnClick", function()
    if moveTimerToggle == 0 then
      CommDKP:StartTimer(120, L["MOVEME"])
      CommDKP.ConfigTab4.moveTimer:SetText(L["HIDEBIDTIMER"])
      moveTimerToggle = 1;
    else
      CommDKP.BidTimer:SetScript("OnUpdate", nil)
      CommDKP.BidTimer:Hide()
      CommDKP.ConfigTab4.moveTimer:SetText(L["MOVEBIDTIMER"])
      moveTimerToggle = 0;
    end
  end)

  -- wipe tables button
  CommDKP.ConfigTab4.WipeTables = self:CreateButton("BOTTOMRIGHT", CommDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["WIPETABLES"]);
  CommDKP.ConfigTab4.WipeTables:ClearAllPoints();
  CommDKP.ConfigTab4.WipeTables:SetPoint("RIGHT", CommDKP.ConfigTab4.moveTimer, "LEFT", -40, 0)
  CommDKP.ConfigTab4.WipeTables:SetSize(110,25)
  CommDKP.ConfigTab4.WipeTables:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["WIPETABLES"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["WIPETABLESTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  CommDKP.ConfigTab4.WipeTables:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  CommDKP.ConfigTab4.WipeTables:SetScript("OnClick", function()

    StaticPopupDialogs["WIPE_TABLES"] = {
      text = L["WIPETABLESCONF"],
      button1 = L["YES"],
      button2 = L["NO"],
      OnAccept = function()
        CommDKP:SetTable(CommDKP_Whitelist, false, nil);
        CommDKP:SetTable(CommDKP_DKPTable, true, nil);
        CommDKP:SetTable(CommDKP_Loot, true, nil);
        CommDKP:SetTable(CommDKP_DKPHistory, true, nil);
        CommDKP:SetTable(CommDKP_Archive, true, nil);
        CommDKP:SetTable(CommDKP_Standby, true, nil);
        CommDKP:SetTable(CommDKP_MinBids, true, nil);
        CommDKP:SetTable(CommDKP_MaxBids, true, nil);

        CommDKP:SetTable(CommDKP_DKPTable, true, {});
        CommDKP:SetTable(CommDKP_Loot, true, {});
        CommDKP:SetTable(CommDKP_DKPHistory, true, {});
        CommDKP:SetTable(CommDKP_Archive, true, {});
        CommDKP:SetTable(CommDKP_Whitelist, false, {});
        CommDKP:SetTable(CommDKP_Standby, true, {});
        CommDKP:SetTable(CommDKP_MinBids, true, {});
        CommDKP:SetTable(CommDKP_MaxBids, true, {});
        CommDKP:LootHistory_Reset()
        CommDKP:FilterDKPTable(core.currentSort, "reset")
        CommDKP:StatusVerify_Update()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("WIPE_TABLES")
  end)

  -- Options Footer (empty frame to push bottom of scrollframe down)
  CommDKP.ConfigTab4.OptionsFooterFrame = CreateFrame("Frame", nil, CommDKP.ConfigTab4);
  CommDKP.ConfigTab4.OptionsFooterFrame:SetPoint("TOPLEFT", CommDKP.ConfigTab4.moveTimer, "BOTTOMLEFT")
  CommDKP.ConfigTab4.OptionsFooterFrame:SetSize(420, 50);
  
end
