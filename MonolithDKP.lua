local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

-- DBs required: MonDKP_DB (log app settings), MonDKP_Log(log kills/dkp distributed), MonDKP_DKPTable(Member/class/dkp list), MonDKP_Tables, MonDKP_Loot(loot and who got it)
-- DBs are initiallized at the bottom of init.lua

function MonDKP:Toggle()        -- toggles IsShown() state of MonDKP.UIConfig, the entire addon window
  core.MonDKPUI = MonDKP.UIConfig or MonDKP:CreateMenu();
  core.MonDKPUI:SetShown(not core.MonDKPUI:IsShown())
end

local function ScrollFrame_OnMouseWheel(self, delta)          -- scroll function for all but the DKPTable frame
  local newValue = self:GetVerticalScroll() - (delta * 20);   -- DKPTable frame uses FauxScrollFrame_OnVerticalScroll()
  
  if (newValue < 0) then
    newValue = 0;
  elseif (newValue > self:GetVerticalScrollRange()) then
    newValue = self:GetVerticalScrollRange();
  end
  
  self:SetVerticalScroll(newValue);
end

local function Tab_OnClick(self)
  PanelTemplates_SetTab(self:GetParent(), self:GetID());
  
  local scrollChild = MonDKP.UIConfig.TabMenu.ScrollFrame:GetScrollChild();
  if (scrollChild) then
    scrollChild:Hide();
  end
  
  MonDKP.UIConfig.TabMenu.ScrollFrame:SetScrollChild(self.content);
  self.content:Show();
  MonDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(0)
end

function MonDKP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)  -- temp function for testing purpose only
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
    
    tab.content = CreateFrame("Frame", nil, MonDKP.UIConfig.TabMenu.ScrollFrame);
    tab.content:SetSize(375, 800);
    tab.content:Hide();
        
    table.insert(contents, tab.content);
    
    if (i == 1) then
      tab:SetPoint("TOPLEFT", MonDKP.UIConfig.TabMenu, "BOTTOMLEFT", 5, 0);
    else
      tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -14, 0);
    end 
  end
  
  Tab_OnClick(_G[frameName.."Tab1"]);
  
  return unpack(contents);
end

---------------------------------------
-- Sort Function
---------------------------------------  
local SortButtons = {}

function FilterDKPTable(sort, reset)          -- filters core.WorkingTable based on classes in classFiltered table.
  core.WorkingTable = {}                      -- classFiltered stores true/false
  for k,v in pairs(MonDKP_DKPTable) do        -- sort and reset are used to pass along to SortDKPTable()
    if(core.classFiltered[MonDKP_DKPTable[k]["class"]] == true) then
      tinsert(core.WorkingTable, v)
    end
  end
  SortDKPTable(sort, reset);
end

function SortDKPTable(id, reset)        -- reorganizes core.WorkingTable based on id passed. Avail IDs are "class", "player" and "dkp"
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
  DKPTable_Update(MonDKP.DKPTable)
end

--
--  When clicking a box off, unchecks "All" as well and flags checkAll to false
--
local checkAll = true;                    -- changes to false when less than all of the boxes are checked
local function FilterChecks(self)         -- sets/unsets check boxes in conjunction with "All" button, then runs FilterDKPTable() above
  if (self:GetChecked() == false) then
    MonDKP.ConfigTab1.checkBtn[9]:SetChecked(false);
    checkAll = false;
  end
  local verifyCheck = true; -- switches to false if the below loop finds anything unchecked
  for i=1, 8 do             -- checks all boxes to see if all are checked, if so, checks "All" as well
    if MonDKP.ConfigTab1.checkBtn[i]:GetChecked() == false then
      verifyCheck = false;
    end
  end
  if (verifyCheck == true) then
    MonDKP.ConfigTab1.checkBtn[9]:SetChecked(true);
  else
    MonDKP.ConfigTab1.checkBtn[9]:SetChecked(false);
  end
  for k,v in pairs(core.classes) do
    if (MonDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
      core.classFiltered[v] = true;
    else
      core.classFiltered[v] = false;
    end
  end
  FilterDKPTable("class", "reset");
end

function MonDKP:CreateMenu()
  MonDKP.UIConfig = CreateFrame("Frame", "MonDKPConfig", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
  MonDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
  MonDKP.UIConfig:SetSize(1000, 590);
  MonDKP.UIConfig:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
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
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
  });
  MonDKP.UIConfig.TitleBar:SetBackdropColor(0,0,0,0.9)
  MonDKP.UIConfig.TitleBar:SetSize(166, 54)

  -- Addon Title
  MonDKP.UIConfig.Title = MonDKP.UIConfig.TitleBar:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
  MonDKP.UIConfig.Title:SetColorTexture(0, 0, 0, 1)
  MonDKP.UIConfig.Title:SetPoint("CENTER", MonDKP.UIConfig.TitleBar, "CENTER");
  MonDKP.UIConfig.Title:SetSize(160, 48);
  MonDKP.UIConfig.Title:SetTexture("Interface\\AddOns\\MonolithDKP\\textures\\mondkp-title-t.tga");

  -- Close Button
  MonDKP.UIConfig.closeBtn = CreateFrame("Button", nil, MonDKP.UIConfig, "UIPanelCloseButton")
  MonDKP.UIConfig.closeBtn:SetPoint("CENTER", MonDKP.UIConfig, "TOPRIGHT", -13, -13)
  MonDKP.UIConfig.closeBtn:SetNormalFontObject("GameFontNormalLarge");
  MonDKP.UIConfig.closeBtn:SetHighlightFontObject("GameFontHighlightLarge");
  tinsert(UISpecialFrames, MonDKP.UIConfig:GetName()); -- Sets frame to close on "Escape"

  ---------------------------------------
  -- TabMenu
  ---------------------------------------

  MonDKP.UIConfig.TabMenu = CreateFrame("Frame", "MonDKPMonDKP.ConfigTabMenu", MonDKP.UIConfig);
  MonDKP.UIConfig.TabMenu:SetPoint("TOPRIGHT", MonDKP.UIConfig, "TOPRIGHT", -22, -25);
  MonDKP.UIConfig.TabMenu:SetSize(400, 500);
  MonDKP.UIConfig.TabMenu:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  MonDKP.UIConfig.TabMenu:SetBackdropColor(0,0,0,0.9);
  MonDKP.UIConfig.TabMenu:SetBackdropBorderColor(1,1,1,0.5)

  -- TabMenu ScrollFrame and ScrollBar
  MonDKP.UIConfig.TabMenu.ScrollFrame = CreateFrame("ScrollFrame", nil, MonDKP.UIConfig.TabMenu, "UIPanelScrollFrameTemplate");
  MonDKP.UIConfig.TabMenu.ScrollFrame:ClearAllPoints();
  MonDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("TOPLEFT",  MonDKP.UIConfig.TabMenu, "TOPLEFT", 4, -8);
  MonDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig.TabMenu, "BOTTOMRIGHT", -3, 4);
  MonDKP.UIConfig.TabMenu.ScrollFrame:SetClipsChildren(false);
  MonDKP.UIConfig.TabMenu.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
  
  MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:Hide();
  MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, MonDKP.UIConfig.TabMenu.ScrollFrame, "UIPanelScrollBarTrimTemplate")
  MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:ClearAllPoints();
  MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", MonDKP.UIConfig.TabMenu.ScrollFrame, "TOPRIGHT", -20, -12);
  MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig.TabMenu.ScrollFrame, "BOTTOMRIGHT", -2, 15);

  ---------------------------------------
  -- Populate Tabs 
  ---------------------------------------

  MonDKP.ConfigTab1, MonDKP.ConfigTab2, MonDKP.ConfigTab3, MonDKP.ConfigTab4 = SetTabs(MonDKP.UIConfig.TabMenu, 5, "Filters", "Award DKP", "Edit Entries", "Options", "History");
  
  ---------------------------------------
  -- MENU TAB 1
  ---------------------------------------

  MonDKP.ConfigTab1.text = MonDKP.ConfigTab1:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  MonDKP.ConfigTab1.text:ClearAllPoints();
  MonDKP.ConfigTab1.text:SetFontObject("GameFontHighlight");
  MonDKP.ConfigTab1.text:SetPoint("TOPLEFT", MonDKP.ConfigTab1, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab1.text:SetText("Filters"); 

  local checkBtn = {}
    MonDKP.ConfigTab1.checkBtn = checkBtn;

  -- Class Check Button 1:
  MonDKP.ConfigTab1.checkBtn[1] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", MonDKP.ConfigTab1, "TOPLEFT", 15, -60);
  MonDKP.ConfigTab1.checkBtn[1].text:SetText("Druid");
  MonDKP.ConfigTab1.checkBtn[1]:SetID(1)
  MonDKP.ConfigTab1.checkBtn[1]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[1]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 2:
  MonDKP.ConfigTab1.checkBtn[2] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
  MonDKP.ConfigTab1.checkBtn[2].text:SetText("Hunter");
  MonDKP.ConfigTab1.checkBtn[2]:SetID(2)
  MonDKP.ConfigTab1.checkBtn[2]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[2]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 3:
  MonDKP.ConfigTab1.checkBtn[3] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
  MonDKP.ConfigTab1.checkBtn[3].text:SetText("Mage");
  MonDKP.ConfigTab1.checkBtn[3]:SetID(3)
  MonDKP.ConfigTab1.checkBtn[3]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[3]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 4:
  MonDKP.ConfigTab1.checkBtn[4] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
  MonDKP.ConfigTab1.checkBtn[4].text:SetText("Priest");
  MonDKP.ConfigTab1.checkBtn[4]:SetID(4)
  MonDKP.ConfigTab1.checkBtn[4]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[4]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 5:
  MonDKP.ConfigTab1.checkBtn[5] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab1.checkBtn[5].text:SetText("Rogue");
  MonDKP.ConfigTab1.checkBtn[5]:SetID(5)
  MonDKP.ConfigTab1.checkBtn[5]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[5]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 6:
  MonDKP.ConfigTab1.checkBtn[6] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab1.checkBtn[6].text:SetText("Shaman");
  MonDKP.ConfigTab1.checkBtn[6]:SetID(6)
  MonDKP.ConfigTab1.checkBtn[6]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[6]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 7:
  MonDKP.ConfigTab1.checkBtn[7] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab1.checkBtn[7].text:SetText("Warlock");
  MonDKP.ConfigTab1.checkBtn[7]:SetID(7)
  MonDKP.ConfigTab1.checkBtn[7]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[7]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 8:
  MonDKP.ConfigTab1.checkBtn[8] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab1.checkBtn[8].text:SetText("Warrior");
  MonDKP.ConfigTab1.checkBtn[8]:SetID(8)
  MonDKP.ConfigTab1.checkBtn[8]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[8]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 9:
  MonDKP.ConfigTab1.checkBtn[9] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[9]:SetPoint("BOTTOMRIGHT", MonDKP.ConfigTab1.checkBtn[3], "TOPLEFT", 10, 0);
  MonDKP.ConfigTab1.checkBtn[9].text:SetText("All");
  MonDKP.ConfigTab1.checkBtn[9]:SetID(9)
  MonDKP.ConfigTab1.checkBtn[9]:SetChecked(true);
  MonDKP.ConfigTab1.checkBtn[9]:SetScript("OnClick",
    function()
      for i=1, 9 do
        if (checkAll) then
          MonDKP.ConfigTab1.checkBtn[i]:SetChecked(false)
        else
          MonDKP.ConfigTab1.checkBtn[i]:SetChecked(true)
        end
      end
      checkAll = not checkAll;
      FilterChecks(MonDKP.ConfigTab1.checkBtn[9]);
    end)

  for k,v in pairs(core.classes) do               -- sets core.classFiltered table with all values
    if (MonDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
      core.classFiltered[v] = true;
    else
      core.classFiltered[v] = false;
    end
  end

  -- Check Button 10 (In Part):   No Functionality yet
  MonDKP.ConfigTab1.checkBtn[10] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
  MonDKP.ConfigTab1.checkBtn[10]:SetPoint("BOTTOMRIGHT", MonDKP.ConfigTab1.checkBtn[2], "TOPLEFT", -15, 0);
  MonDKP.ConfigTab1.checkBtn[10].text:SetText("In Party/Raid");
  MonDKP.ConfigTab1.checkBtn[10]:SetID(9)
  MonDKP.ConfigTab1.checkBtn[10]:SetChecked(false);
  MonDKP.ConfigTab1.checkBtn[10]:SetScript("OnClick", FilterChecks)

  ---------------------------------------
  -- MENU TAB 2 (Currently ONLY Filler elements)
  ---------------------------------------

  MonDKP.ConfigTab2.text = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  MonDKP.ConfigTab2.text:ClearAllPoints();
  MonDKP.ConfigTab2.text:SetFontObject("GameFontHighlight");
  MonDKP.ConfigTab2.text:SetPoint("TOPLEFT", MonDKP.ConfigTab2, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab2.text:SetText("Content TWO!"); 

  -- Button:
  MonDKP.ConfigTab2.trackBtn = self:CreateButton("CENTER", MonDKP.ConfigTab2, "TOP", 0, -70, "Award DKP");

  -- Button:  
  MonDKP.ConfigTab2.stopTrackBtn = self:CreateButton("TOP", MonDKP.ConfigTab2.trackBtn, "BOTTOM", 0, -10, "Remove DKP");

  -- Button: 
  MonDKP.ConfigTab2.engageBtn = self:CreateButton("TOP", MonDKP.ConfigTab2.stopTrackBtn, "BOTTOM", 0, -10, "Update DKP");

  -- Slider 1:
  MonDKP.ConfigTab2.slider1 = CreateFrame("SLIDER", nil, MonDKP.ConfigTab2, "OptionsSliderTemplate");
  MonDKP.ConfigTab2.slider1:SetPoint("TOP", MonDKP.ConfigTab2.engageBtn, "BOTTOM", 0, -20);
  MonDKP.ConfigTab2.slider1:SetMinMaxValues(1, 100);
  MonDKP.ConfigTab2.slider1:SetValue(50);
  MonDKP.ConfigTab2.slider1:SetValueStep(2);
  MonDKP.ConfigTab2.slider1:SetObeyStepOnDrag(true);

  -- Slider 2:
  MonDKP.ConfigTab2.slider2 = CreateFrame("SLIDER", nil, MonDKP.ConfigTab2, "OptionsSliderTemplate");
  MonDKP.ConfigTab2.slider2:SetPoint("TOP", MonDKP.ConfigTab2.slider1, "BOTTOM", 0, -20);
  MonDKP.ConfigTab2.slider2:SetMinMaxValues(1, 100);
  MonDKP.ConfigTab2.slider2:SetValue(40);
  MonDKP.ConfigTab2.slider2:SetValueStep(2);
  MonDKP.ConfigTab2.slider2:SetObeyStepOnDrag(true);

  -- Check Button 1:
  MonDKP.ConfigTab2.checkBtn1 = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
  MonDKP.ConfigTab2.checkBtn1:SetPoint("TOPLEFT", MonDKP.ConfigTab2.slider1, "BOTTOMLEFT", -10, -60);
  MonDKP.ConfigTab2.checkBtn1.text:SetText("My Check Button!");

  -- Check Button 2:
  MonDKP.ConfigTab2.checkBtn2 = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
  MonDKP.ConfigTab2.checkBtn2:SetPoint("TOPLEFT", MonDKP.ConfigTab2.checkBtn1, "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab2.checkBtn2.text:SetText("Another Check Button!");
  MonDKP.ConfigTab2.checkBtn2:SetChecked(true);

  ---------------------------------------
  -- MENU TAB 3 (Currently ONLY Filler elements)
  ---------------------------------------

  MonDKP.ConfigTab3.text = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  MonDKP.ConfigTab3.text:ClearAllPoints();
  MonDKP.ConfigTab3.text:SetFontObject("GameFontHighlight");
  MonDKP.ConfigTab3.text:SetPoint("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab3.text:SetText("Content THREE!"); 

  ---------------------------------------
  -- MENU TAB 4 (Currently ONLY Filler elements)
  ---------------------------------------

  MonDKP.ConfigTab4.text = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  MonDKP.ConfigTab4.text:ClearAllPoints();
  MonDKP.ConfigTab4.text:SetFontObject("GameFontHighlight");
  MonDKP.ConfigTab4.text:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab4.text:SetText("Content FOUR!"); 

  ---------------------------------------
  -- DKP Table (TableFunctions.lua)
  ---------------------------------------
  ---------------------------------------
  -- Creating the DKP Table
  ---------------------------------------
  MonDKP.DKPTable = CreateFrame("ScrollFrame", "MonDKPDisplayScrollFrame", MonDKP.UIConfig, "FauxScrollFrameTemplate")
  MonDKP.DKPTable:SetSize(core.TableWidth, core.TableRowHeight*core.TableNumRows)
  MonDKP.DKPTable:SetPoint("LEFT", 20, 3)
  MonDKP.DKPTable:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  MonDKP.DKPTable:SetBackdropColor(0,0,0,0.4);
  MonDKP.DKPTable:SetBackdropBorderColor(1,1,1,0.5)
  MonDKP.DKPTable:SetClipsChildren(false);

  MonDKP.DKPTable.ScrollBar = FauxScrollFrame_GetChildFrames(MonDKP.DKPTable)
  MonDKP.DKPTable.Rows = {}
  for i=1, core.TableNumRows do
    MonDKP.DKPTable.Rows[i] = CreateRow(MonDKP.DKPTable, i)
    MonDKP.DKPTable.Rows[i]:SetPoint("TOPLEFT", MonDKP.DKPTable.Rows[i-1] or MonDKP.DKPTable, MonDKP.DKPTable.Rows[i-1] and "BOTTOMLEFT" or "TOPLEFT")
  end
  MonDKP.DKPTable:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, core.TableRowHeight, DKPTable_Update)
  end)
  
  ---------------------------------------
  -- DKP Table Headesr and Sort Buttons
  ---------------------------------------

  MonDKP.DKPTable_Headers = CreateFrame("Frame", "MonDKPDKPTableHeaders", MonDKP.UIConfig)
  MonDKP.DKPTable_Headers:SetSize(500, 22)
  MonDKP.DKPTable_Headers:SetPoint("BOTTOMLEFT", MonDKP.DKPTable, "TOPLEFT", 0, 1)
  MonDKP.DKPTable_Headers:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
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
    v:SetScript("OnClick", function(self) SortDKPTable(self.Id) end)
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

  ----- Counter below DKP Table
  MonDKP.DKPTable.counter = CreateFrame("Frame", "MonDKPDisplayFrameCounter", MonDKP.UIConfig);
  MonDKP.DKPTable.counter:SetPoint("TOP", MonDKP.DKPTable, "BOTTOM", 0, 0)
  MonDKP.DKPTable.counter:SetSize(400, 30)

  MonDKP.DKPTable.counter.t = MonDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
  MonDKP.DKPTable.counter.t:SetFontObject("GameFontHighlight");
  MonDKP.DKPTable.counter.t:SetTextColor(1, 1, 1, 0.7);
  MonDKP.DKPTable.counter.t:SetPoint("CENTER", MonDKP.DKPTable.counter, "CENTER");
  MonDKP.DKPTable.counter.t:SetText(#core.WorkingTable.." Entries Shown"); 

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
  MonDKP.UIConfig.Version:SetTextColor(c.r, c.g, c.b, 0.5);
  MonDKP.UIConfig.Version:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig.TitleBar, "BOTTOMRIGHT", -8, 5);
  MonDKP.UIConfig.Version:SetText(MonDKP:GetVer()); 

  MonDKP.UIConfig:Hide(); -- hide menu after creation until called.
  FilterDKPTable("class", "reset")   -- initial sort and populates data values in DKPTable.Rows{} FilterDKPTable() -> SortDKPTable() -> DKPTable_Update()

  return MonDKP.UIConfig;
end
