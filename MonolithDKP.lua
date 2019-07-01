local _, core = ...;
local _G = _G;

core.MonDKP = {};
core.classFiltered = {};
core.classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }

local MonDKP = core.MonDKP;
local UIConfig;
local MonVersion = "v0.1 (alpha)";

--DBs required: MonDKP_DB (log app settings), MonDKP_Log(log kills/dkp distributed), MonDKP_DKPTable(Member/class/dkp list), MonDKP_Tables, MonDKP_Loot(loot and who got it)
--------------------------------------
-- Defaults
--------------------------------------
local defaults = {
  theme = {
    r = 0.6823, 
    g = 0.6823,
    b = 0.8666,
    hex = "aeaedd"
  }
}

function MonDKP:Toggle() 
  local menu = UIConfig or MonDKP:CreateMenu();
  menu:SetShown(not menu:IsShown())
end

function MonDKP:GetVer()
  return MonVersion;
end

function MonDKP:ResetPosition()
  UIConfig:ClearAllPoints();
  UIConfig:SetPoint("CENTER", UIParent, "CENTER", -350, 150);
  UIConfig:SetSize(1000, 590);
end

function MonDKP:GetThemeColor()
  local c = defaults.theme;
  return c;
end

local function ScrollFrame_OnMouseWheel(self, delta)
  local newValue = self:GetVerticalScroll() - (delta * 20);
  
  if (newValue < 0) then
    newValue = 0;
  elseif (newValue > self:GetVerticalScrollRange()) then
    newValue = self:GetVerticalScrollRange();
  end
  
  self:SetVerticalScroll(newValue);
end

local function Tab_OnClick(self)
  PanelTemplates_SetTab(self:GetParent(), self:GetID());
  
  local scrollChild = UIConfig.TabMenu.ScrollFrame:GetScrollChild();
  if (scrollChild) then
    scrollChild:Hide();
  end
  
  UIConfig.TabMenu.ScrollFrame:SetScrollChild(self.content);
  self.content:Show();
  UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(0)
end

function MonDKP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
  local btn = CreateFrame("Button", nil, relativeFrame, "GameMenuButtonTemplate")
  btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
  btn:SetSize(140, 40);
  btn:SetText(text);
  btn:SetNormalFontObject("GameFontNormalLarge");
  btn:SetHighlightFontObject("GameFontHighlightLarge");
  return btn; 
end

local function SetTabs(frame, numTabs, ...)
  frame.numTabs = numTabs;
  
  local contents = {};
  local frameName = frame:GetName();
  
  for i = 1, numTabs do 
    local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CharacterFrameTabButtonTemplate");
    tab:SetID(i);
    tab:SetText(select(i, ...));
    tab:SetScript("OnClick", Tab_OnClick);
    
    tab.content = CreateFrame("Frame", nil, UIConfig.TabMenu.ScrollFrame);
    tab.content:SetSize(375, 800);
    tab.content:Hide();
        
    table.insert(contents, tab.content);
    
    if (i == 1) then
      tab:SetPoint("TOPLEFT", UIConfig.TabMenu, "BOTTOMLEFT", 5, 0);
    else
      tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -14, 0);
    end 
  end
  
  Tab_OnClick(_G[frameName.."Tab1"]);
  
  return unpack(contents);
end

function MonDKP:CreateMenu()
  UIConfig = CreateFrame("Frame", "MonDKPConfig", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
  UIConfig:SetPoint("CENTER", UIParent, "CENTER", -350, 150);
  UIConfig:SetSize(1000, 590);
  UIConfig:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
  });
  UIConfig:SetBackdropColor(0,0,0,0.8);
  UIConfig:SetMovable(true);
  UIConfig:EnableMouse(true);
  UIConfig:SetResizable(true);
  UIConfig:SetMaxResize(1400, 875)
  UIConfig:SetMinResize(1000, 590)
  UIConfig:RegisterForDrag("LeftButton");
  UIConfig:SetScript("OnDragStart", UIConfig.StartMoving);
  UIConfig:SetScript("OnDragStop", UIConfig.StopMovingOrSizing);

  -- Title Frame (top/center)
  UIConfig.TitleBar = CreateFrame("Frame", "MonDKPTitle", UIConfig, "ShadowOverlaySmallTemplate")
  UIConfig.TitleBar:SetPoint("BOTTOM", UIConfig, "TOP", -225, -18)
  UIConfig.TitleBar:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
  });
  UIConfig.TitleBar:SetBackdropColor(0,0,0,0.9)
  UIConfig.TitleBar:SetSize(160, 48)

  -- Addon Title
  local c = MonDKP:GetThemeColor();
  UIConfig.Title = UIConfig.TitleBar:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  UIConfig.Title:ClearAllPoints();
  UIConfig.Title:SetFontObject("QuestTitleFont");
  UIConfig.Title:SetTextColor(c.r, c.g, c.b, 1);
  UIConfig.Title:SetPoint("CENTER", UIConfig.TitleBar, "CENTER");
  UIConfig.Title:SetText("Monolith DKP"); 

  -- Close Button
  UIConfig.closeBtn = CreateFrame("Button", nil, UIConfig, "UIPanelCloseButton")
  UIConfig.closeBtn:SetPoint("CENTER", UIConfig, "TOPRIGHT", -13, -13)
  UIConfig.closeBtn:SetNormalFontObject("GameFontNormalLarge");
  UIConfig.closeBtn:SetHighlightFontObject("GameFontHighlightLarge");
  tinsert(UISpecialFrames, UIConfig:GetName()); -- Sets frame to close on "Escape"

  ---------------------------------------
  -- TabMenu
  ---------------------------------------

  UIConfig.TabMenu = CreateFrame("Frame", "MonDKPcore.ConfigTabMenu", UIConfig);
  UIConfig.TabMenu:SetPoint("TOPRIGHT", UIConfig, "TOPRIGHT", -22, -25);
  UIConfig.TabMenu:SetSize(400, 500);
  UIConfig.TabMenu:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  UIConfig.TabMenu:SetBackdropColor(0,0,0,0.9);
  UIConfig.TabMenu:SetBackdropBorderColor(1,1,1,0.5)

  -- TabMenu ScrollFrame and ScrollBar
  UIConfig.TabMenu.ScrollFrame = CreateFrame("ScrollFrame", nil, UIConfig.TabMenu, "UIPanelScrollFrameTemplate");
  UIConfig.TabMenu.ScrollFrame:ClearAllPoints();
  UIConfig.TabMenu.ScrollFrame:SetPoint("TOPLEFT",  UIConfig.TabMenu, "TOPLEFT", 4, -8);
  UIConfig.TabMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", UIConfig.TabMenu, "BOTTOMRIGHT", -3, 4);
  UIConfig.TabMenu.ScrollFrame:SetClipsChildren(false);
  UIConfig.TabMenu.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
  
  UIConfig.TabMenu.ScrollFrame.ScrollBar:Hide();
  UIConfig.TabMenu.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, UIConfig.TabMenu.ScrollFrame, "UIPanelScrollBarTrimTemplate")
  UIConfig.TabMenu.ScrollFrame.ScrollBar:ClearAllPoints();
  UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", UIConfig.TabMenu.ScrollFrame, "TOPRIGHT", -20, -12);
  UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", UIConfig.TabMenu.ScrollFrame, "BOTTOMRIGHT", -2, 15);

  ---------------------------------------
  -- Populate Tabs 
  ---------------------------------------

  core.ConfigTab1, core.ConfigTab2, core.ConfigTab3, core.ConfigTab4 = SetTabs(UIConfig.TabMenu, 4, "Filters", "Award DKP", "Award Items", "Options");
  
  ---------------------------------------
  -- MENU TAB 1
  ---------------------------------------

  core.ConfigTab1.text = core.ConfigTab1:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  core.ConfigTab1.text:ClearAllPoints();
  core.ConfigTab1.text:SetFontObject("GameFontHighlight");
  core.ConfigTab1.text:SetPoint("TOPLEFT", core.ConfigTab1, "TOPLEFT", 15, -10);
  core.ConfigTab1.text:SetText("Filters"); 

  local checkBtn = {}
    core.ConfigTab1.checkBtn = checkBtn;

  --
  --  When clicking a box off, unchecks "All" as well and flags checkAll to false
  --
  local checkAll = true;
  local function FilterChecks(self)
    if (self:GetChecked() == false) then
      core.ConfigTab1.checkBtn[9]:SetChecked(false);
      checkAll = false;
    end
    local verifyCheck = true; -- switches to false if the below loop finds anything unchecked
    for i=1, 8 do             -- checks all boxes to see if all are checked, if so, checks "All" as well
      if core.ConfigTab1.checkBtn[i]:GetChecked() == false then
        verifyCheck = false;
      end
    end
    if (verifyCheck == true) then
      core.ConfigTab1.checkBtn[9]:SetChecked(true);
    else
      core.ConfigTab1.checkBtn[9]:SetChecked(false);
    end
    for k,v in pairs(core.classes) do
      if (core.ConfigTab1.checkBtn[k]:GetChecked() == true) then
        core.classFiltered[v] = true;
      else
        core.classFiltered[v] = false;
      end
    end
    DKPTable_Update();
    core.DKPTable.counter.t:SetText(#core.WorkingTable.." Entries Listed"); 
  end

  -- Class Check Button 1:
  core.ConfigTab1.checkBtn[1] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", core.ConfigTab1, "TOPLEFT", 15, -60);
  core.ConfigTab1.checkBtn[1].text:SetText("Druid");
  core.ConfigTab1.checkBtn[1]:SetID(1)
  core.ConfigTab1.checkBtn[1]:SetChecked(true);
  core.ConfigTab1.checkBtn[1]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 2:
  core.ConfigTab1.checkBtn[2] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", core.ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
  core.ConfigTab1.checkBtn[2].text:SetText("Hunter");
  core.ConfigTab1.checkBtn[2]:SetID(2)
  core.ConfigTab1.checkBtn[2]:SetChecked(true);
  core.ConfigTab1.checkBtn[2]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 3:
  core.ConfigTab1.checkBtn[3] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", core.ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
  core.ConfigTab1.checkBtn[3].text:SetText("Mage");
  core.ConfigTab1.checkBtn[3]:SetID(3)
  core.ConfigTab1.checkBtn[3]:SetChecked(true);
  core.ConfigTab1.checkBtn[3]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 4:
  core.ConfigTab1.checkBtn[4] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", core.ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
  core.ConfigTab1.checkBtn[4].text:SetText("Priest");
  core.ConfigTab1.checkBtn[4]:SetID(4)
  core.ConfigTab1.checkBtn[4]:SetChecked(true);
  core.ConfigTab1.checkBtn[4]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 5:
  core.ConfigTab1.checkBtn[5] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", core.ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
  core.ConfigTab1.checkBtn[5].text:SetText("Rogue");
  core.ConfigTab1.checkBtn[5]:SetID(5)
  core.ConfigTab1.checkBtn[5]:SetChecked(true);
  core.ConfigTab1.checkBtn[5]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 6:
  core.ConfigTab1.checkBtn[6] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", core.ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
  core.ConfigTab1.checkBtn[6].text:SetText("Shaman");
  core.ConfigTab1.checkBtn[6]:SetID(6)
  core.ConfigTab1.checkBtn[6]:SetChecked(true);
  core.ConfigTab1.checkBtn[6]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 7:
  core.ConfigTab1.checkBtn[7] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", core.ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
  core.ConfigTab1.checkBtn[7].text:SetText("Warlock");
  core.ConfigTab1.checkBtn[7]:SetID(7)
  core.ConfigTab1.checkBtn[7]:SetChecked(true);
  core.ConfigTab1.checkBtn[7]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 8:
  core.ConfigTab1.checkBtn[8] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", core.ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);
  core.ConfigTab1.checkBtn[8].text:SetText("Warrior");
  core.ConfigTab1.checkBtn[8]:SetID(8)
  core.ConfigTab1.checkBtn[8]:SetChecked(true);
  core.ConfigTab1.checkBtn[8]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 9:
  core.ConfigTab1.checkBtn[9] = CreateFrame("CheckButton", nil, core.ConfigTab1, "UICheckButtonTemplate");
  core.ConfigTab1.checkBtn[9]:SetPoint("BOTTOMRIGHT", core.ConfigTab1.checkBtn[3], "TOPLEFT", 10, 0);
  core.ConfigTab1.checkBtn[9].text:SetText("All");
  core.ConfigTab1.checkBtn[9]:SetID(9)
  core.ConfigTab1.checkBtn[9]:SetChecked(true);
  core.ConfigTab1.checkBtn[9]:SetScript("OnClick",
    function()
      for i=1, 9 do
        if (checkAll) then
          core.ConfigTab1.checkBtn[i]:SetChecked(false)
        else
          core.ConfigTab1.checkBtn[i]:SetChecked(true)
        end
      end
      checkAll = not checkAll;
      FilterChecks(core.ConfigTab1.checkBtn[9]);
    end)

  for k,v in pairs(core.classes) do               -- sets core.classFiltered table with all values
    if (core.ConfigTab1.checkBtn[k]:GetChecked() == true) then
      core.classFiltered[v] = true;
    else
      core.classFiltered[v] = false;
    end
  end

  ---------------------------------------
  -- MENU TAB 2 (Currently ONLY Filler elements)
  ---------------------------------------

  core.ConfigTab2.text = core.ConfigTab2:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  core.ConfigTab2.text:ClearAllPoints();
  core.ConfigTab2.text:SetFontObject("GameFontHighlight");
  core.ConfigTab2.text:SetPoint("TOPLEFT", core.ConfigTab2, "TOPLEFT", 15, -10);
  core.ConfigTab2.text:SetText("Content TWO!"); 

  -- Button:
  core.ConfigTab2.trackBtn = self:CreateButton("CENTER", core.ConfigTab2, "TOP", 0, -70, "Award DKP");

  -- Button:  
  core.ConfigTab2.stopTrackBtn = self:CreateButton("TOP", core.ConfigTab2.trackBtn, "BOTTOM", 0, -10, "Remove DKP");

  -- Button: 
  core.ConfigTab2.engageBtn = self:CreateButton("TOP", core.ConfigTab2.stopTrackBtn, "BOTTOM", 0, -10, "Update DKP");

  -- Slider 1:
  core.ConfigTab2.slider1 = CreateFrame("SLIDER", nil, core.ConfigTab2, "OptionsSliderTemplate");
  core.ConfigTab2.slider1:SetPoint("TOP", core.ConfigTab2.engageBtn, "BOTTOM", 0, -20);
  core.ConfigTab2.slider1:SetMinMaxValues(1, 100);
  core.ConfigTab2.slider1:SetValue(50);
  core.ConfigTab2.slider1:SetValueStep(2);
  core.ConfigTab2.slider1:SetObeyStepOnDrag(true);

  -- Slider 2:
  core.ConfigTab2.slider2 = CreateFrame("SLIDER", nil, core.ConfigTab2, "OptionsSliderTemplate");
  core.ConfigTab2.slider2:SetPoint("TOP", core.ConfigTab2.slider1, "BOTTOM", 0, -20);
  core.ConfigTab2.slider2:SetMinMaxValues(1, 100);
  core.ConfigTab2.slider2:SetValue(40);
  core.ConfigTab2.slider2:SetValueStep(2);
  core.ConfigTab2.slider2:SetObeyStepOnDrag(true);

  -- Check Button 1:
  core.ConfigTab2.checkBtn1 = CreateFrame("CheckButton", nil, core.ConfigTab2, "UICheckButtonTemplate");
  core.ConfigTab2.checkBtn1:SetPoint("TOPLEFT", core.ConfigTab2.slider1, "BOTTOMLEFT", -10, -60);
  core.ConfigTab2.checkBtn1.text:SetText("My Check Button!");

  -- Check Button 2:
  core.ConfigTab2.checkBtn2 = CreateFrame("CheckButton", nil, core.ConfigTab2, "UICheckButtonTemplate");
  core.ConfigTab2.checkBtn2:SetPoint("TOPLEFT", core.ConfigTab2.checkBtn1, "BOTTOMLEFT", 0, -10);
  core.ConfigTab2.checkBtn2.text:SetText("Another Check Button!");
  core.ConfigTab2.checkBtn2:SetChecked(true);

  ---------------------------------------
  -- MENU TAB 3 (Currently ONLY Filler elements)
  ---------------------------------------

  core.ConfigTab3.text = core.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  core.ConfigTab3.text:ClearAllPoints();
  core.ConfigTab3.text:SetFontObject("GameFontHighlight");
  core.ConfigTab3.text:SetPoint("TOPLEFT", core.ConfigTab3, "TOPLEFT", 15, -10);
  core.ConfigTab3.text:SetText("Content THREE!"); 

  ---------------------------------------
  -- MENU TAB 4 (Currently ONLY Filler elements)
  ---------------------------------------

  core.ConfigTab4.text = core.ConfigTab4:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  core.ConfigTab4.text:ClearAllPoints();
  core.ConfigTab4.text:SetFontObject("GameFontHighlight");
  core.ConfigTab4.text:SetPoint("TOPLEFT", core.ConfigTab4, "TOPLEFT", 15, -10);
  core.ConfigTab4.text:SetText("Content FOUR!"); 

  ---------------------------------------
  -- DKP Table (TableFunctions.lua)
  ---------------------------------------
  -- Header
  ---------------------------------------
  core.DKPTable_Headers = CreateFrame("Frame", "MonDKPDKPTableHeaders", UIConfig)
  core.DKPTable_Headers:SetSize(500, 25)
  core.DKPTable_Headers:SetPoint("TOPLEFT", UIConfig, "TOPLEFT", 20, -25)
  core.DKPTable_Headers:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
  });
  core.DKPTable_Headers:SetBackdropColor(0,0,0,0.8);
  core.DKPTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
  core.DKPTable_Headers:Show()

  --[[local Header1 = CreateFrame("Button", "$parentHeader1", core.DKPTable_Headers)
  local Header2 = CreateFrame("Button", "$parentHeader2", core.DKPTable_Headers)
  local Header3 = CreateFrame("Button", "$parentHeader3", core.DKPTable_Headers)

  Header1:SetSize(core.TableWidth/3, core.TableHeight);
  Header2:SetSize(core.TableWidth/3, core.TableHeight);
  Header3:SetSize(core.TableWidth/3, core.TableHeight);

  Header1:SetHighlightTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
  Header2:SetHighlightTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
  Header3:SetHighlightTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");

  Header1:SetPoint("LEFT", core.DKPTable_Headers, "Left", 15)
  Header2:SetPoint("CENTER", core.DKPTable_Headers, "CENTER")
  Header3:SetPoint("RIGHT", core.DKPTable_Headers, "RIGHT", -15) --]]


  local SortButtons = {}
 
  local function SortTable(id, reset)
    local button = SortButtons[id]
    if reset then
      button.Ascend = true
    else
      button.Ascend = not button.Ascend
    end
    local Suffix = button.Ascend and " ^" or " v"
    button:SetText(button.Id .. Suffix)
    for k, v in pairs(SortButtons) do
      if v ~= button then
        v.Ascend = nil
        v:SetText(v.Id)
      end
    end
    table.sort(core.WorkingTable, function(a, b)
      if button.Ascend then
        return a[button.Id] < b[button.Id]
      else
        return a[button.Id] > b[button.Id]
      end
    end)
    DKPTable_Update(core.DKPTable)
  end

  SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", core.DKPTable_Headers)
  SortButtons.class = CreateFrame("Button", "$ParentSortButtonClass", core.DKPTable_Headers)
  SortButtons.dkp = CreateFrame("Button", "$ParentSortButtonDkp", core.DKPTable_Headers)
   
  SortButtons.class:SetPoint("BOTTOM", core.DKPTable_Headers, "BOTTOM", 0, 4)
  SortButtons.player:SetPoint("RIGHT", SortButtons.class, "LEFT")
  SortButtons.dkp:SetPoint("LEFT", SortButtons.class, "RIGHT")
   
  for k, v in pairs(SortButtons) do
    v.Id = k
    v:SetHighlightTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
    v:SetSize(core.TableWidth/3, core.TableHeight)
    v:SetScript("OnClick", function(self) SortTable(self.Id) end)
  end

  SortButtons.player.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
  SortButtons.player.t:SetFontObject("GameFontNormalSmall");
  SortButtons.player.t:SetTextColor(1, 1, 1, 1);
  SortButtons.player.t:SetPoint("CENTER", SortButtons.player, "CENTER");
  SortButtons.player.t:SetText("Player"); 

  SortButtons.class.t = SortButtons.class:CreateFontString(nil, "OVERLAY")
  SortButtons.class.t:SetFontObject("GameFontNormalSmall");
  SortButtons.class.t:SetTextColor(1, 1, 1, 1);
  SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER");
  SortButtons.class.t:SetText("Class"); 

  SortButtons.dkp.t = SortButtons.dkp:CreateFontString(nil, "OVERLAY")
  SortButtons.dkp.t:SetFontObject("GameFontNormalSmall");
  SortButtons.dkp.t:SetTextColor(1, 1, 1, 1);
  SortButtons.dkp.t:SetPoint("CENTER", SortButtons.dkp, "CENTER");
  SortButtons.dkp.t:SetText("Total DKP");
  ---------------------------------------
  -- Creating the DKP Table
  ---------------------------------------
  core.DKPTable = CreateFrame("ScrollFrame", "MonDKPDisplayScrollFrame", UIConfig, "FauxScrollFrameTemplate")
  core.DKPTable:SetSize(core.TableWidth, core.TableHeight*core.TableNumrows)
  core.DKPTable:SetPoint("LEFT", 20, 0)
  core.DKPTable:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  core.DKPTable:SetBackdropColor(0,0,0,0.4);
  core.DKPTable:SetBackdropBorderColor(1,1,1,0.5)
  core.DKPTable:SetClipsChildren(false);

  core.DKPTable.ScrollBar = FauxScrollFrame_GetChildFrames(core.DKPTable)
  core.DKPTable.Rows = {}
  for i=1, core.TableNumrows do
    core.DKPTable.Rows[i] = CreateRow(core.DKPTable, i)
    core.DKPTable.Rows[i]:SetPoint("TOPLEFT", core.DKPTable.Rows[i-1] or core.DKPTable, core.DKPTable.Rows[i-1] and "BOTTOMLEFT" or "TOPLEFT")
  end
  core.DKPTable:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, core.TableHeight, DKPTable_Update)
  end)
  DKPTable_Update(core.DKPTable)  -- remove when completed

  -------------------------------------

  --[[core.DKPTable = CreateFrame("ScrollFrame", "MonDKPDiplayFrame", UIConfig, "FauxScrollFrameTemplate")
  core.DKPTable:SetSize(core.TableWidth, core.TableHeight*core.TableNumrows)
  core.DKPTable:SetPoint("TOPLEFT", core.DKPTable_Headers, "BOTTOMLEFT", 0, 1)
  core.DKPTable:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  core.DKPTable:SetBackdropColor(0,0,0,0.4);
  core.DKPTable:SetBackdropBorderColor(1,1,1,0.5)
  core.DKPTable:SetClipsChildren(false);
  core.DKPTable:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);

  core.DKPTable.ScrollBar:ClearAllPoints();
  core.DKPTable.ScrollBar:SetPoint("TOPLEFT", core.DKPTable, "TOPRIGHT", 20, -17);
  core.DKPTable.ScrollBar:SetPoint("BOTTOMRIGHT", core.DKPTable, "BOTTOMRIGHT", 0, 16);

  core.DKPTable.Rows = {}
  for i=1, core.TableNumrows do
      core.DKPTable.Rows[i] = CreateRow(core.DKPTable, i)
      core.DKPTable.Rows[i]:SetPoint("TOPLEFT", core.DKPTable.Rows[i-1] or core.DKPTable, core.DKPTable.Rows[i-1] and "BOTTOMLEFT" or "TOPLEFT")
  end
  core.DKPTable:SetScript("OnVerticalScroll", function(self, offset)
      FauxScrollFrame_OnVerticalScroll(self, offset, core.TableHeight, DKPTable_Update)
  end)
  DKPTable_Update(core.DKPTable);--]]

  ----- Counter below DKP Table
  core.DKPTable.counter = CreateFrame("Frame", "MonDKPDisplayFrameCounter", UIConfig);
  core.DKPTable.counter:SetPoint("TOP", core.DKPTable, "BOTTOM", 0, 0)
  core.DKPTable.counter:SetSize(400, 30)

  core.DKPTable.counter.t = core.DKPTable.counter:CreateFontString(nil, "OVERLAY")
  core.DKPTable.counter.t:SetFontObject("GameFontHighlight");
  core.DKPTable.counter.t:SetTextColor(1, 1, 1, 0.7);
  core.DKPTable.counter.t:SetPoint("CENTER", core.DKPTable.counter, "CENTER");
  core.DKPTable.counter.t:SetText(#core.WorkingTable.." Entries Listed"); 

  ---------------------------------------
  -- RESIZE BUTTON
  ---------------------------------------

  local resizeButton = CreateFrame("Button", nil, UIConfig);
  resizeButton:SetSize(16, 16);
  resizeButton:SetPoint("BOTTOMRIGHT", UIConfig, "BOTTOMRIGHT", -5, 4);
  resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
  resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
  resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
   
  resizeButton:SetScript("OnMouseDown", function(self, button)
    UIConfig:StartSizing("BOTTOMRIGHT");
    UIConfig:SetUserPlaced(true);
  end);

  resizeButton:SetScript("OnUpdate", function(self, button)           -- TabMenu scaling OnUpdate
    UIConfig.TabMenu:SetHeight(self:GetParent():GetHeight() - 145);    -- keeps TabMenu height 185 pixels smaller than UIConfig
    if (self:GetParent():GetWidth() * 0.4 <= 500) then                -- scales TabMenu width at 0.4 parent width, with max of 500px
      UIConfig.TabMenu:SetWidth(self:GetParent():GetWidth() * 0.4);
    else
      UIConfig.TabMenu:SetWidth(500);
    end
  end);
   
  resizeButton:SetScript("OnMouseUp", function(self, button)
    UIConfig:StopMovingOrSizing();
  end);
  ---------------------------------------
  -- VERSION IDENTIFIER
  ---------------------------------------
  UIConfig.Version = UIConfig.TitleBar:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  UIConfig.Version:ClearAllPoints();
  UIConfig.Version:SetFontObject("GameFontWhiteSmall");
  UIConfig.Version:SetTextColor(c.r, c.g, c.b, 0.5);
  UIConfig.Version:SetPoint("BOTTOMRIGHT", UIConfig.TitleBar, "BOTTOMRIGHT", -8, 5);
  UIConfig.Version:SetText(MonDKP:GetVer()); 

  UIConfig:Hide(); -- hide menu after creation until called.

  return UIConfig;
end
