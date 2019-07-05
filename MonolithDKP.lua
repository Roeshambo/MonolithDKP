local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

-- DBs required: MonDKP_DB (log app settings), MonDKP_Log(log kills/dkp distributed), MonDKP_DKPTable(Member/class/dkp list), MonDKP_Tables, MonDKP_Loot(loot and who got it)
-- DBs are initiallized at the bottom of init.lua

function MonDKP:Toggle()        -- toggles IsShown() state of MonDKP.UIConfig, the entire addon window
  core.MonDKPUI = MonDKP.UIConfig or MonDKP:CreateMenu();
  core.MonDKPUI:SetShown(not core.MonDKPUI:IsShown())
end

---------------------------------------
-- Sort Function
---------------------------------------
local SortButtons = {}

function MonDKP:FilterDKPTable(sort, reset)          -- filters core.WorkingTable based on classes in classFiltered table.
  core.WorkingTable = {}
  for k,v in pairs(MonDKP_DKPTable) do        -- sort and reset are used to pass along to MonDKP:SortDKPTable()
    if(core.classFiltered[MonDKP_DKPTable[k]["class"]] == true) then
      tinsert(core.WorkingTable, v)
    end
  end
  MonDKP:SortDKPTable(sort, reset);
end

function MonDKP:SortDKPTable(id, reset)        -- reorganizes core.WorkingTable based on id passed. Avail IDs are "class", "player" and "dkp"
  local button = SortButtons[id]        -- passing "reset" forces it to do initial sort (A to Z repeatedly instead of A to Z then Z to A toggled)
  if reset then                         -- reset is useful for check boxes when you don't want it repeatedly reversing the sort
    button.Ascend = true
  else
    button.Ascend = not button.Ascend
  end
  for k, v in pairs(SortButtons) do
    if v ~= button then
      v.Ascend = nil
    end
  end
  table.sort(core.WorkingTable, function(a, b)
    if button.Ascend then
      if(id == "dkp") then return a[button.Id] > b[button.Id] else return a[button.Id] < b[button.Id] end
    else
      if(id == "dkp") then return a[button.Id] < b[button.Id] else return a[button.Id] > b[button.Id] end
    end
  end)
  DKPTable_Update()
end

function MonDKP:CreateMenu()
  MonDKP.UIConfig = CreateFrame("Frame", "MonDKPConfig", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
  MonDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
  MonDKP.UIConfig:SetSize(1000, 590);
  MonDKP.UIConfig:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
  });
  MonDKP.UIConfig:SetBackdropColor(0,0,0,0.8);
  MonDKP.UIConfig:SetMovable(true);
  MonDKP.UIConfig:EnableMouse(true);
  MonDKP.UIConfig:SetResizable(true);
  MonDKP.UIConfig:SetMaxResize(1400, 875)
  MonDKP.UIConfig:SetMinResize(1000, 590)
  MonDKP.UIConfig:RegisterForDrag("LeftButton");
  MonDKP.UIConfig:SetScript("OnDragStart", MonDKP.UIConfig.StartMoving);
  MonDKP.UIConfig:SetScript("OnDragStop", MonDKP.UIConfig.StopMovingOrSizing);

  -- Title Frame (top/center)
  MonDKP.UIConfig.TitleBar = CreateFrame("Frame", "MonDKPTitle", MonDKP.UIConfig, "ShadowOverlaySmallTemplate")
  MonDKP.UIConfig.TitleBar:SetPoint("BOTTOM", MonDKP.UIConfig, "TOP", -225, -18)
  MonDKP.UIConfig.TitleBar:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
  });
  MonDKP.UIConfig.TitleBar:SetBackdropColor(0,0,0,0.9)
  MonDKP.UIConfig.TitleBar:SetSize(166, 54)

  -- Addon Title
  MonDKP.UIConfig.Title = MonDKP.UIConfig.TitleBar:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
  MonDKP.UIConfig.Title:SetColorTexture(0, 0, 0, 1)
  MonDKP.UIConfig.Title:SetPoint("CENTER", MonDKP.UIConfig.TitleBar, "CENTER");
  MonDKP.UIConfig.Title:SetSize(160, 48);
  MonDKP.UIConfig.Title:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\mondkp-title-t.tga");

  -- Close Button
  MonDKP.UIConfig.closeContainer = CreateFrame("Frame", "MonDKPTitle", MonDKP.UIConfig)
  MonDKP.UIConfig.closeContainer:SetPoint("CENTER", MonDKP.UIConfig, "TOPRIGHT", -4, 0)
  MonDKP.UIConfig.closeContainer:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
  });
  MonDKP.UIConfig.closeContainer:SetBackdropColor(0,0,0,0.9)
  MonDKP.UIConfig.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
  MonDKP.UIConfig.closeContainer:SetSize(28, 28)

  MonDKP.UIConfig.closeBtn = CreateFrame("Button", nil, MonDKP.UIConfig, "UIPanelCloseButton")
  MonDKP.UIConfig.closeBtn:SetPoint("CENTER", MonDKP.UIConfig.closeContainer, "TOPRIGHT", -14, -14)
  tinsert(UISpecialFrames, MonDKP.UIConfig:GetName()); -- Sets frame to close on "Escape"

  MonDKP:ConfigMenuTabs();        -- Create and populate Config Menu Tabs
  MonDKP:DKPTable_Create();       -- Create DKPTable and populate rows
  
  ---------------------------------------
  -- DKP Table Header and Sort Buttons
  ---------------------------------------

  MonDKP.DKPTable_Headers = CreateFrame("Frame", "MonDKPDKPTableHeaders", MonDKP.UIConfig)
  MonDKP.DKPTable_Headers:SetSize(500, 22)
  MonDKP.DKPTable_Headers:SetPoint("BOTTOMLEFT", MonDKP.DKPTable, "TOPLEFT", 0, 1)
  MonDKP.DKPTable_Headers:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
  });
  MonDKP.DKPTable_Headers:SetBackdropColor(0,0,0,0.8);
  MonDKP.DKPTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
  MonDKP.DKPTable_Headers:Show()

  ---------------------------------------
  -- Sort Buttons
  --------------------------------------- 

  SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", MonDKP.DKPTable_Headers)
  SortButtons.class = CreateFrame("Button", "$ParentSortButtonClass", MonDKP.DKPTable_Headers)
  SortButtons.dkp = CreateFrame("Button", "$ParentSortButtonDkp", MonDKP.DKPTable_Headers)
   
  SortButtons.class:SetPoint("BOTTOM", MonDKP.DKPTable_Headers, "BOTTOM", 0, 2)
  SortButtons.player:SetPoint("RIGHT", SortButtons.class, "LEFT")
  SortButtons.dkp:SetPoint("LEFT", SortButtons.class, "RIGHT")
   
  for k, v in pairs(SortButtons) do
    v.Id = k
    v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
    v:SetSize((core.TableWidth/3)-1, core.TableRowHeight)
    v:SetScript("OnClick", function(self) MonDKP:SortDKPTable(self.Id) end)
  end

  SortButtons.player.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
  SortButtons.player.t:SetFont("Interface\\AddOns\\MonolithDKP\\Media\\Fonts\\homizio_bold.ttf", 14)
  SortButtons.player.t:SetTextColor(1, 1, 1, 1);
  SortButtons.player.t:SetPoint("CENTER", SortButtons.player, "CENTER", 0, -1);
  SortButtons.player.t:SetText("Player"); 

  SortButtons.class.t = SortButtons.class:CreateFontString(nil, "OVERLAY")
  SortButtons.class.t:SetFont("Interface\\AddOns\\MonolithDKP\\Media\\Fonts\\homizio_bold.ttf", 14)
  SortButtons.class.t:SetFontObject("GameFontNormalSmall");
  SortButtons.class.t:SetTextColor(1, 1, 1, 1);
  SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 0, -1);
  SortButtons.class.t:SetText("Class"); 

  SortButtons.dkp.t = SortButtons.dkp:CreateFontString(nil, "OVERLAY")
  SortButtons.dkp.t:SetFont("Interface\\AddOns\\MonolithDKP\\Media\\Fonts\\homizio_bold.ttf", 14)
  SortButtons.dkp.t:SetFontObject("GameFontNormalSmall");
  SortButtons.dkp.t:SetTextColor(1, 1, 1, 1);
  SortButtons.dkp.t:SetPoint("CENTER", SortButtons.dkp, "CENTER", 0, -1);
  SortButtons.dkp.t:SetText("Total DKP");

  ----- Counter below DKP Table
  MonDKP.DKPTable.counter = CreateFrame("Frame", "MonDKPDisplayFrameCounter", MonDKP.UIConfig);
  MonDKP.DKPTable.counter:SetPoint("TOP", MonDKP.DKPTable, "BOTTOM", 0, 0)
  MonDKP.DKPTable.counter:SetSize(400, 30)

  MonDKP.DKPTable.counter.t = MonDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
  MonDKP.DKPTable.counter.t:SetFontObject("GameFontHighlight");
  MonDKP.DKPTable.counter.t:SetTextColor(1, 1, 1, 0.7);
  MonDKP.DKPTable.counter.t:SetPoint("CENTER", MonDKP.DKPTable.counter, "CENTER");

  ---------------------------------------
  -- RESIZE BUTTON
  ---------------------------------------

  local resizeButton = CreateFrame("Button", nil, MonDKP.UIConfig);
  resizeButton:SetSize(16, 16);
  resizeButton:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig, "BOTTOMRIGHT", -5, 4);
  resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
  resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
  resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
   
  resizeButton:SetScript("OnMouseDown", function(self, button)
    MonDKP.UIConfig:StartSizing("BOTTOMRIGHT");
    MonDKP.UIConfig:SetUserPlaced(true);
  end);
   
  resizeButton:SetScript("OnMouseUp", function(self, button)
    MonDKP.UIConfig.TabMenu:SetHeight(self:GetParent():GetHeight() - 145);    -- keeps TabMenu height 185 pixels smaller than MonDKP.UIConfig
    if (self:GetParent():GetWidth() * 0.4 <= 500) then                -- scales TabMenu width at 0.4 parent width, with max of 500px
      MonDKP.UIConfig.TabMenu:SetWidth(self:GetParent():GetWidth() * 0.4);
    else
      MonDKP.UIConfig.TabMenu:SetWidth(500);
    end
    MonDKP.UIConfig:StopMovingOrSizing();
  end);
  ---------------------------------------
  -- VERSION IDENTIFIER
  ---------------------------------------
  local c = MonDKP:GetThemeColor();
  MonDKP.UIConfig.Version = MonDKP.UIConfig.TitleBar:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  MonDKP.UIConfig.Version:ClearAllPoints();
  MonDKP.UIConfig.Version:SetFontObject("GameFontWhiteSmall");
  MonDKP.UIConfig.Version:SetTextColor(c[1].r, c[1].g, c[1].b, 0.5);
  MonDKP.UIConfig.Version:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig.TitleBar, "BOTTOMRIGHT", -8, 4);
  MonDKP.UIConfig.Version:SetText(core.MonVersion); 

  MonDKP.UIConfig:Hide(); -- hide menu after creation until called.
  MonDKP:FilterDKPTable("class", "reset")   -- initial sort and populates data values in DKPTable.Rows{} MonDKP:FilterDKPTable() -> MonDKP:SortDKPTable() -> DKPTable_Update()

  return MonDKP.UIConfig;
end
