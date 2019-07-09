local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;


function MonDKP:Options()
  MonDKP.ConfigTab4.header = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.header:SetFontObject("MonDKPLargeCenter");
  MonDKP.ConfigTab4.header:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab4.header:SetText("Default Settings");

  MonDKP.ConfigTab4.description = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.description:SetFontObject("MonDKPSmallLeft");
  MonDKP.ConfigTab4.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.header, "BOTTOMLEFT", 7, -30);
  MonDKP.ConfigTab4.description:SetText("Default DKP settings for raid bonus'.");

  --OnTimeBonus Header
  MonDKP.ConfigTab4.OnTimeHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.OnTimeHeader:SetFontObject("MonDKPSmallLeft");
  MonDKP.ConfigTab4.OnTimeHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab4.description, "BOTTOMLEFT", 0, -20);
  MonDKP.ConfigTab4.OnTimeHeader:SetText("On Time Bonus: ")

  --BossKillBonus Header
  MonDKP.ConfigTab4.BossKillHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.BossKillHeader:SetFontObject("MonDKPSmallLeft");
  MonDKP.ConfigTab4.BossKillHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab4.OnTimeHeader, "BOTTOMLEFT", 0, -20);
  MonDKP.ConfigTab4.BossKillHeader:SetText("Boss Kill Bonus: ")

  --CompletionBonus Header
  MonDKP.ConfigTab4.CompleteHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.CompleteHeader:SetFontObject("MonDKPSmallLeft");
  MonDKP.ConfigTab4.CompleteHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab4.BossKillHeader, "BOTTOMLEFT", 0, -20);
  MonDKP.ConfigTab4.CompleteHeader:SetText("Raid Completion Bonus: ")

  --NewBossKillBonus Header
  MonDKP.ConfigTab4.NewBossHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.NewBossHeader:SetFontObject("MonDKPSmallLeft");
  MonDKP.ConfigTab4.NewBossHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab4.CompleteHeader, "BOTTOMLEFT", 0, -20);
  MonDKP.ConfigTab4.NewBossHeader:SetText("New Boss Kill Bonus: ")

  --UnexcusedAbsence Header
  MonDKP.ConfigTab4.UnexcusedHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab4.UnexcusedHeader:SetFontObject("MonDKPSmallLeft");
  MonDKP.ConfigTab4.UnexcusedHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab4.NewBossHeader, "BOTTOMLEFT", 0, -20);
  MonDKP.ConfigTab4.UnexcusedHeader:SetText("Unexcused Absence: ")

  -- Default OnTimeBonus Edit Box
  local default = {}
  MonDKP.ConfigTab4.default = default;

  for i=1, 5 do
    MonDKP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, MonDKP.ConfigTab4)
    MonDKP.ConfigTab4.default[i]:SetAutoFocus(false)
    MonDKP.ConfigTab4.default[i]:SetMultiLine(false)
    MonDKP.ConfigTab4.default[i]:SetSize(50, 24)
    MonDKP.ConfigTab4.default[i]:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
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
  end

  local DKPSettings = MonDKP:GetDKPSettings()

  MonDKP.ConfigTab4.default[1]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.OnTimeHeader, "TOPRIGHT", 5, 5)     
  MonDKP.ConfigTab4.default[1]:SetText(tonumber(DKPSettings["OnTimeBonus"]))

  MonDKP.ConfigTab4.default[2]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.BossKillHeader, "TOPRIGHT", 5, 5)     
  MonDKP.ConfigTab4.default[2]:SetText(tonumber(DKPSettings["BossKillBonus"]))

  MonDKP.ConfigTab4.default[3]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.CompleteHeader, "TOPRIGHT", 5, 5)     
  MonDKP.ConfigTab4.default[3]:SetText(tonumber(DKPSettings["CompletionBonus"]))

  MonDKP.ConfigTab4.default[4]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.NewBossHeader, "TOPRIGHT", 5, 5)     
  MonDKP.ConfigTab4.default[4]:SetText(tonumber(DKPSettings["NewBossKillBonus"]))

  MonDKP.ConfigTab4.default[5]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.UnexcusedHeader, "TOPRIGHT", 5, 5)
  MonDKP.ConfigTab4.default[5]:SetText(tonumber(DKPSettings["UnexcusedAbsence"]))

  -- Save Settings Button
  MonDKP.ConfigTab4.submitSettings = self:CreateButton("TOPLEFT", MonDKP.ConfigTab4.default[5], "BOTTOMLEFT", -100, -20, "Save Settings");
  MonDKP.ConfigTab4.submitSettings:SetSize(90,25)
  MonDKP.ConfigTab4.submitSettings:SetScript("OnClick", function()
    MonDKP_DB["DKPBonus"]["OnTimeBonus"] = MonDKP.ConfigTab4.default[1]:GetNumber();
    MonDKP_DB["DKPBonus"]["BossKillBonus"] = MonDKP.ConfigTab4.default[2]:GetNumber();
    MonDKP_DB["DKPBonus"]["CompletionBonus"] = MonDKP.ConfigTab4.default[3]:GetNumber();
    MonDKP_DB["DKPBonus"]["NewBossKillBonus"] = MonDKP.ConfigTab4.default[4]:GetNumber();
    MonDKP_DB["DKPBonus"]["UnexcusedAbsence"] = MonDKP.ConfigTab4.default[5]:GetNumber();
    MonDKP:Print("Default settings saved.")
  end)



  -- Position Bid Timer Button

  MonDKP.ConfigTab4.moveTimer = self:CreateButton("TOP", MonDKP.ConfigTab4.submitSettings, "BOTTOM", 0, -30, "Move Bid Timer");
  MonDKP.ConfigTab4.moveTimer:SetSize(110,25)
  MonDKP.ConfigTab4.moveTimer:SetScript("OnClick", function()
    MonDKP:StartTimer(120, "Move Me!")
  end)
end