local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

--
--  When clicking a box off, unchecks "All" as well and flags checkAll to false
--
local checkAll = true;                    -- changes to false when less than all of the boxes are checked

local function FilterChecks(self)         -- sets/unsets check boxes in conjunction with "All" button, then runs MonDKP:FilterDKPTable() above
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
  MonDKP:FilterDKPTable("class", "reset");
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
-- Populate Tabs 
---------------------------------------
function MonDKP:ConfigMenuTabs()

  MonDKP.ConfigTab1, MonDKP.ConfigTab2, MonDKP.ConfigTab3, MonDKP.ConfigTab4, MonDKP.ConfigTab5 = SetTabs(MonDKP.UIConfig.TabMenu, 5, "Filters", "Award DKP", "Edit Entries", "Options", "History");

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
  MonDKP.ConfigTab2.trackBtn:SetSize(90,20)

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
  -- MENU TAB 5 (Currently ONLY Filler elements)
  ---------------------------------------

  MonDKP.ConfigTab5.text = MonDKP.ConfigTab5:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
  MonDKP.ConfigTab5.text:ClearAllPoints();
  MonDKP.ConfigTab5.text:SetFontObject("GameFontHighlight");
  MonDKP.ConfigTab5.text:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab5.text:SetText("Content Five!");
end
  