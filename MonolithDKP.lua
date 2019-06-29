local _, core = ...;
local _G = _G;

core.MonDKP = {};

local MonDKP = core.MonDKP;
local UIConfig;
local MonVersion = "v0.1";

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
  UIConfig.TitleBar:SetPoint("BOTTOM", UIConfig, "TOP", 0, -18)
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
  tinsert(UISpecialFrames, UIConfig:GetName());

  ---------------------------------------
  -- TabMenu
  ---------------------------------------

  UIConfig.TabMenu = CreateFrame("Frame", "MonDKPConfigTabMenu", UIConfig);
  UIConfig.TabMenu:SetPoint("TOPRIGHT", UIConfig, "TOPRIGHT", -22, -20);
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
  UIConfig.TabMenu.ScrollFrame:SetPoint("TOPLEFT",  MonDKPConfigTabMenu, "TOPLEFT", 4, -8);
  UIConfig.TabMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", MonDKPConfigTabMenu, "BOTTOMRIGHT", -3, 4);
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

  local ConfigTab1, ConfigTab2, ConfigTab3, ConfigTab4 = SetTabs(UIConfig.TabMenu, 4, "Filters", "Award DKP", "Award Items", "Options");
  
  ---------------------------------------
  -- MENU TAB 1
  ---------------------------------------

  ConfigTab1.text = ConfigTab1:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  ConfigTab1.text:ClearAllPoints();
  ConfigTab1.text:SetFontObject("GameFontHighlight");
  ConfigTab1.text:SetPoint("TOPLEFT", ConfigTab1, "TOPLEFT", 15, -10);
  ConfigTab1.text:SetText("Filters"); 

  local checkBtn = {}
    ConfigTab1.checkBtn = checkBtn;

  --
  --  When clicking a box off, unchecks "All" as well and flags checkAll to false
  --
  local checkAll = true;
  local function FilterChecks(self)
    if (self:GetChecked() == false) then
      ConfigTab1.checkBtn[9]:SetChecked(false);
      checkAll = false;
    end
    local verifyCheck = true; -- switches to false if the below loop finds anything unchecked
    for i=1, 8 do             -- checks all boxes to see if all are checked, if so, checks "All" as well
      if ConfigTab1.checkBtn[i]:GetChecked() == false then
        verifyCheck = false;
      end
    end
    if (verifyCheck == true) then
      ConfigTab1.checkBtn[9]:SetChecked(true);
    else
      ConfigTab1.checkBtn[9]:SetChecked(false);
    end
  end

  -- Class Check Button 1:
  ConfigTab1.checkBtn[1] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", ConfigTab1, "TOPLEFT", 15, -60);
  ConfigTab1.checkBtn[1].text:SetText("Druid");
  ConfigTab1.checkBtn[1]:SetID(1)
  ConfigTab1.checkBtn[1]:SetChecked(true);
  ConfigTab1.checkBtn[1]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 2:
  ConfigTab1.checkBtn[2] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
  ConfigTab1.checkBtn[2].text:SetText("Hunter");
  ConfigTab1.checkBtn[2]:SetID(2)
  ConfigTab1.checkBtn[2]:SetChecked(true);
  ConfigTab1.checkBtn[2]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 3:
  ConfigTab1.checkBtn[3] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
  ConfigTab1.checkBtn[3].text:SetText("Mage");
  ConfigTab1.checkBtn[3]:SetID(3)
  ConfigTab1.checkBtn[3]:SetChecked(true);
  ConfigTab1.checkBtn[3]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 4:
  ConfigTab1.checkBtn[4] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
  ConfigTab1.checkBtn[4].text:SetText("Priest");
  ConfigTab1.checkBtn[4]:SetID(4)
  ConfigTab1.checkBtn[4]:SetChecked(true);
  ConfigTab1.checkBtn[4]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 5:
  ConfigTab1.checkBtn[5] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
  ConfigTab1.checkBtn[5].text:SetText("Rogue");
  ConfigTab1.checkBtn[5]:SetID(5)
  ConfigTab1.checkBtn[5]:SetChecked(true);
  ConfigTab1.checkBtn[5]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 6:
  ConfigTab1.checkBtn[6] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
  ConfigTab1.checkBtn[6].text:SetText("Shaman");
  ConfigTab1.checkBtn[6]:SetID(6)
  ConfigTab1.checkBtn[6]:SetChecked(true);
  ConfigTab1.checkBtn[6]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 7:
  ConfigTab1.checkBtn[7] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
  ConfigTab1.checkBtn[7].text:SetText("Warlock");
  ConfigTab1.checkBtn[7]:SetID(7)
  ConfigTab1.checkBtn[7]:SetChecked(true);
  ConfigTab1.checkBtn[7]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 8:
  ConfigTab1.checkBtn[8] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);
  ConfigTab1.checkBtn[8].text:SetText("Warrior");
  ConfigTab1.checkBtn[8]:SetID(8)
  ConfigTab1.checkBtn[8]:SetChecked(true);
  ConfigTab1.checkBtn[8]:SetScript("OnClick", FilterChecks)

  -- Class Check Button 9:
  ConfigTab1.checkBtn[9] = CreateFrame("CheckButton", nil, ConfigTab1, "UICheckButtonTemplate");
  ConfigTab1.checkBtn[9]:SetPoint("BOTTOMRIGHT", ConfigTab1.checkBtn[3], "TOPLEFT", 10, 0);
  ConfigTab1.checkBtn[9].text:SetText("All");
  ConfigTab1.checkBtn[9]:SetID(9)
  ConfigTab1.checkBtn[9]:SetChecked(true);
  ConfigTab1.checkBtn[9]:SetScript("OnClick",
    function()
      for i=1, 9 do
        if (checkAll) then
          ConfigTab1.checkBtn[i]:SetChecked(false)
        else
          ConfigTab1.checkBtn[i]:SetChecked(true)
        end
      end
      checkAll = not checkAll;
    end)

  ---------------------------------------
  -- MENU TAB 2 (Currently ONLY Filler elements)
  ---------------------------------------

  ConfigTab2.text = ConfigTab2:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  ConfigTab2.text:ClearAllPoints();
  ConfigTab2.text:SetFontObject("GameFontHighlight");
  ConfigTab2.text:SetPoint("TOPLEFT", ConfigTab2, "TOPLEFT", 15, -10);
  ConfigTab2.text:SetText("Content TWO!"); 

  -- Button:
  ConfigTab2.trackBtn = self:CreateButton("CENTER", ConfigTab2, "TOP", 0, -70, "Award DKP");

  -- Button:  
  ConfigTab2.stopTrackBtn = self:CreateButton("TOP", ConfigTab2.trackBtn, "BOTTOM", 0, -10, "Remove DKP");

  -- Button: 
  ConfigTab2.engageBtn = self:CreateButton("TOP", ConfigTab2.stopTrackBtn, "BOTTOM", 0, -10, "Update DKP");

  -- Slider 1:
  ConfigTab2.slider1 = CreateFrame("SLIDER", nil, ConfigTab2, "OptionsSliderTemplate");
  ConfigTab2.slider1:SetPoint("TOP", ConfigTab2.engageBtn, "BOTTOM", 0, -20);
  ConfigTab2.slider1:SetMinMaxValues(1, 100);
  ConfigTab2.slider1:SetValue(50);
  ConfigTab2.slider1:SetValueStep(2);
  ConfigTab2.slider1:SetObeyStepOnDrag(true);

  -- Slider 2:
  ConfigTab2.slider2 = CreateFrame("SLIDER", nil, ConfigTab2, "OptionsSliderTemplate");
  ConfigTab2.slider2:SetPoint("TOP", ConfigTab2.slider1, "BOTTOM", 0, -20);
  ConfigTab2.slider2:SetMinMaxValues(1, 100);
  ConfigTab2.slider2:SetValue(40);
  ConfigTab2.slider2:SetValueStep(2);
  ConfigTab2.slider2:SetObeyStepOnDrag(true);

  -- Check Button 1:
  ConfigTab2.checkBtn1 = CreateFrame("CheckButton", nil, ConfigTab2, "UICheckButtonTemplate");
  ConfigTab2.checkBtn1:SetPoint("TOPLEFT", ConfigTab2.slider1, "BOTTOMLEFT", -10, -60);
  ConfigTab2.checkBtn1.text:SetText("My Check Button!");

  -- Check Button 2:
  ConfigTab2.checkBtn2 = CreateFrame("CheckButton", nil, ConfigTab2, "UICheckButtonTemplate");
  ConfigTab2.checkBtn2:SetPoint("TOPLEFT", ConfigTab2.checkBtn1, "BOTTOMLEFT", 0, -10);
  ConfigTab2.checkBtn2.text:SetText("Another Check Button!");
  ConfigTab2.checkBtn2:SetChecked(true);

  ---------------------------------------
  -- MENU TAB 3 (Currently ONLY Filler elements)
  ---------------------------------------

  ConfigTab3.text = ConfigTab3:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  ConfigTab3.text:ClearAllPoints();
  ConfigTab3.text:SetFontObject("GameFontHighlight");
  ConfigTab3.text:SetPoint("TOPLEFT", ConfigTab3, "TOPLEFT", 15, -10);
  ConfigTab3.text:SetText("Content THREE!"); 

  ---------------------------------------
  -- MENU TAB 4 (Currently ONLY Filler elements)
  ---------------------------------------

  ConfigTab4.text = ConfigTab4:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  ConfigTab4.text:ClearAllPoints();
  ConfigTab4.text:SetFontObject("GameFontHighlight");
  ConfigTab4.text:SetPoint("TOPLEFT", ConfigTab4, "TOPLEFT", 15, -10);
  ConfigTab4.text:SetText("Content FOUR!"); 

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
  UIConfig.Version:SetTextColor(c.r, c.g, c.b, 1);
  UIConfig.Version:SetPoint("BOTTOMRIGHT", UIConfig.TitleBar, "BOTTOMRIGHT", -8, 5);
  UIConfig.Version:SetText(MonDKP:GetVer()); 

  UIConfig:Hide(); -- hide menu after creation until called.

  return UIConfig;
end
