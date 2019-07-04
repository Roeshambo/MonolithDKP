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

  MonDKP.ConfigTab1, MonDKP.ConfigTab2, MonDKP.ConfigTab3, MonDKP.ConfigTab4, MonDKP.ConfigTab5 = SetTabs(MonDKP.UIConfig.TabMenu, 5, "Filters", "Adjust DKP", "Edit Entries", "Options", "History");

  ---------------------------------------
  -- MENU TAB 1
  ---------------------------------------

  MonDKP.ConfigTab1.text = MonDKP.ConfigTab1:CreateFontString(nil, "OVERLAY")   -- Filters header
  MonDKP.ConfigTab1.text:ClearAllPoints();
  MonDKP.ConfigTab1.text:SetFontObject("GameFontHighlight");
  MonDKP.ConfigTab1.text:SetPoint("TOPLEFT", MonDKP.ConfigTab1, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab1.text:SetText("Filters");

  local checkBtn = {}
  MonDKP.ConfigTab1.checkBtn = checkBtn;

  -- Create CheckBoxes
  for i=1, 10 do
    MonDKP.ConfigTab1.checkBtn[i] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
    if i <= 9 then MonDKP.ConfigTab1.checkBtn[i]:SetChecked(true) else MonDKP.ConfigTab1.checkBtn[i]:SetChecked(false) end;
    MonDKP.ConfigTab1.checkBtn[i]:SetID(i)
    if i <= 8 then
      MonDKP.ConfigTab1.checkBtn[i].text:SetText(core.classes[i]);
    end
    if i==9 then
      MonDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick",
        function()
          for j=1, 9 do
            if (checkAll) then
              MonDKP.ConfigTab1.checkBtn[j]:SetChecked(false)
            else
              MonDKP.ConfigTab1.checkBtn[j]:SetChecked(true)
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
    else
      MonDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick", FilterChecks)
    end
  end

  -- Class Check Buttons:
  MonDKP.ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", MonDKP.ConfigTab1, "TOPLEFT", 15, -60);
  MonDKP.ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
  MonDKP.ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
  MonDKP.ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
  MonDKP.ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
  MonDKP.ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);

  -- Other filter buttons
  MonDKP.ConfigTab1.checkBtn[9]:SetPoint("BOTTOMRIGHT", MonDKP.ConfigTab1.checkBtn[3], "TOPLEFT", 10, 0);
  MonDKP.ConfigTab1.checkBtn[9].text:SetText("All");
  MonDKP.ConfigTab1.checkBtn[10]:SetPoint("BOTTOMRIGHT", MonDKP.ConfigTab1.checkBtn[2], "TOPLEFT", -15, 0);
  MonDKP.ConfigTab1.checkBtn[10].text:SetText("In Party/Raid");

  ---------------------------------------
  -- MENU TAB 2 (Currently ONLY Filler elements)
  ---------------------------------------

  MonDKP.ConfigTab2.header = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab2.header:SetFontObject("GameFontNormalLarge");
  MonDKP.ConfigTab2.header:SetPoint("TOPLEFT", MonDKP.ConfigTab2, "TOPLEFT", 15, -10);
  MonDKP.ConfigTab2.header:SetText("Adjust DKP");
  MonDKP.ConfigTab2.header:SetScale(1.2)

  MonDKP.ConfigTab2.description = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab2.description:SetFontObject("GameFontHighlightLeft");
  MonDKP.ConfigTab2.description:SetPoint("TOPLEFT", MonDKP.ConfigTab2.header, "BOTTOMLEFT", 7, -10);
  MonDKP.ConfigTab2.description:SetText("Select individual users from the left (Shift+Click\nfor multiple users) or click \"Select All Visible\"\nbelow and enter amount to adjust.\n\n\"Select All Visible\" will only select entries visible.\nCan be narrowed down via the Filters Tab\n\n\nPoints: (Use a negative number to deduct DKP)"); 

  -- Add DKP Edit Box
  MonDKP.ConfigTab2.addDKP = CreateFrame("EditBox", nil, MonDKP.ConfigTab2)
  MonDKP.ConfigTab2.addDKP:SetPoint("TOPLEFT", MonDKP.ConfigTab2.description, "BOTTOMLEFT", -5, -8)     
  MonDKP.ConfigTab2.addDKP:SetAutoFocus(false)
  MonDKP.ConfigTab2.addDKP:SetMultiLine(false)
  MonDKP.ConfigTab2.addDKP:SetSize(100, 24)
  MonDKP.ConfigTab2.addDKP:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\MonolithDKP\\textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
  });
  MonDKP.ConfigTab2.addDKP:SetBackdropColor(0,0,0,0.9)
  MonDKP.ConfigTab2.addDKP:SetBackdropBorderColor(1,1,1,0.6)
  MonDKP.ConfigTab2.addDKP:SetMaxLetters(4)
  MonDKP.ConfigTab2.addDKP:SetTextColor(1, 1, 1, 1)
  MonDKP.ConfigTab2.addDKP:SetFontObject("GameFontNormalRight")
  MonDKP.ConfigTab2.addDKP:SetTextInsets(10, 10, 5, 5)
  MonDKP.ConfigTab2.addDKP:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
    self:SetText("")
    self:ClearFocus()
  end)

  -- Select All Checkbox
  MonDKP.ConfigTab2.selectAll = CreateFrame("CheckButton", nil, MonDKP.ConfigTab2, "UICheckButtonTemplate");
  MonDKP.ConfigTab2.selectAll:SetChecked(false)
  MonDKP.ConfigTab2.selectAll:SetScale(0.6);
  MonDKP.ConfigTab2.selectAll.text:SetText("  Select All Visible");
  MonDKP.ConfigTab2.selectAll.text:SetScale(1.5);
  MonDKP.ConfigTab2.selectAll:SetPoint("LEFT", MonDKP.ConfigTab2.addDKP, "RIGHT", 15, 0);
  MonDKP.ConfigTab2.selectAll:SetScript("OnClick", function(self)
    if (self:GetChecked() == true) then
      core.SelectedRows = core.WorkingTable;
      core.SelectedData = core.WorkingTable;
    else
      core.SelectedRows = {}
      core.SelectedData = {}
    end
    MonDKP:FilterDKPTable("class", "reset");
  end)

  MonDKP.ConfigTab2.reasonHeader = MonDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
  MonDKP.ConfigTab2.reasonHeader:SetFontObject("GameFontHighlightLeft");
  MonDKP.ConfigTab2.reasonHeader:SetPoint("TOPLEFT", MonDKP.ConfigTab2.addDKP, "BOTTOMLEFT", 5, -18);
  MonDKP.ConfigTab2.reasonHeader:SetText("Reason for adjustment:")
  
  -- Reason DROPDOWN box 
  local curReason; -- stores user input in dropdown 
  
  -- Create the dropdown, and configure its appearance
  MonDKP.ConfigTab2.reasonDropDown = CreateFrame("FRAME", "MonDKPConfigReasonDropDown", MonDKP.ConfigTab2, "MonolithDKPUIDropDownMenuTemplate")
  MonDKP.ConfigTab2.reasonDropDown:SetPoint("TOPLEFT", MonDKP.ConfigTab2.reasonHeader, "BOTTOMLEFT", -23, -10)
  UIDropDownMenu_SetWidth(MonDKP.ConfigTab2.reasonDropDown, 100)
  UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown)

  -- Create and bind the initialization function to the dropdown menu
  UIDropDownMenu_Initialize(MonDKP.ConfigTab2.reasonDropDown, function(self, level, menuList)
  local reason = UIDropDownMenu_CreateInfo()
    -- Display the 0-9, 10-19, ... groups
    reason.func = self.SetValue
    reason.text, reason.arg1, reason.checked, reason.isNotRadio = "DKP Adjust", "DKP Adjust", "DKP Adjust" == curReason, true
    UIDropDownMenu_AddButton(reason)
    reason.text, reason.arg1, reason.checked, reason.isNotRadio = "Failed", "Failed", "Failed" == curReason, true
    UIDropDownMenu_AddButton(reason)
    reason.text, reason.arg1, reason.checked, reason.isNotRadio = "Just Cuz", "Just Cuz", "Just Cuz" == curReason, true
    UIDropDownMenu_AddButton(reason)
  end)

  -- Dropdown Menu Function
  function MonDKP.ConfigTab2.reasonDropDown:SetValue(newValue)
    curReason = newValue
    UIDropDownMenu_SetText(MonDKP.ConfigTab2.reasonDropDown, newValue)
    CloseDropDownMenus()
  end

  -- Adjust DKP Button
  MonDKP.ConfigTab2.adjustButton = self:CreateButton("TOPLEFT", MonDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 20, -5, "Adjust DKP");
  MonDKP.ConfigTab2.adjustButton:SetSize(90,25)
  MonDKP.ConfigTab2.adjustButton:SetScript("OnClick", function()
    if (#core.SelectedData > 1 and curReason) then
      local tempString = "";       -- stores list of changes
      for i=1, #core.SelectedData do
        if MonDKP:Table_Search(core.WorkingTable, core.SelectedData[i]["player"]) then
            if i < #core.SelectedData then
              tempString = tempString..core.SelectedData[i]["player"]..", ";
            else
              tempString = tempString..core.SelectedData[i]["player"];
            end
            MonDKP:DKPTable_Set(core.SelectedData[i]["player"], "dkp", MonDKP.ConfigTab2.addDKP:GetNumber())
        end
      end
      if (MonDKP.ConfigTab1.checkBtn[10]:GetChecked() and MonDKP.ConfigTab2.selectAll:GetChecked()) then
        MonDKP:Print("Raid DKP Adjusted by "..MonDKP.ConfigTab2.addDKP:GetNumber().." for reason: "..curReason)
      else
        MonDKP:Print("DKP Adjusted by "..MonDKP.ConfigTab2.addDKP:GetNumber().." for the following users: ")
        MonDKP:Print(tempString)
        MonDKP:Print("Reason: "..curReason)
      end
    elseif (#core.SelectedData == 1 and curReason) then
      if core.SelectedData[1]["player"] and MonDKP:Table_Search(core.WorkingTable, core.SelectedData[1]["player"]) then
        MonDKP:DKPTable_Set(core.SelectedData[1]["player"], "dkp", MonDKP.ConfigTab2.addDKP:GetNumber())
        MonDKP:Print(core.SelectedData[1]["player"].."s DKP adjusted by "..MonDKP.ConfigTab2.addDKP:GetNumber().." for reason: "..curReason)
      end
    else
      local validation;
      if (#core.SelectedData == 0 and not curReason) then
        validation = "Entry or Reason"
      elseif #core.SelectedData == 0 then
        validation = "Entry"
      elseif not curReason then
        validation = "Reason"
      end
      StaticPopupDialogs["VALIDATION_PROMPT"] = {
        text = "No "..validation.." Selected",
        button1 = "OK",
        timeout = 5,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show ("VALIDATION_PROMPT")
    end
  end)

  

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
  