
local _, core = ...;
local _G = _G;
local CColors = {
  ["Druid"] = {
    r = 1,
    g = 0.49,
    b = 0.04
  },
  ["Hunter"] = {
    r = 0.67,
    g = 0.83,
    b = 0.45
  },
  ["Mage"] = {
    r = 0.25,
    g = 0.78,
    b = 0.92
  },
  ["Priest"] = {
    r = 1,
    g = 1,
    b = 1
  },
  ["Rogue"] = {
    r = 1,
    g = 0.96,
    b = 0.41
  },
  ["Shaman"] = {
    r = 0.96,
    g = 0.55,
    b = 0.73
  },
  ["Warlock"] = {
    r = 0.53,
    g = 0.53,
    b = 0.93
  },
  ["Warrior"] = {
    r = 0.78,
    g = 0.61,
    b = 0.43
  }
}
core.TableWidth, core.TableHeight, core.TableNumrows = 500, 18, 27;
local SelectedRow = 0;      -- tracks row in DKPTable that is currently selected for SetHighlightTexture
local SelectedData = { player="none"};         -- stores data of clicked row for manipulation.

function GetCColors(class)
  if CColors then 
    local c = CColors[class];
    return c;
  else
    return false;
  end
end

function DKPTable_OnClick(self)   -- self = Rows[]
    SelectedRow = self.index;
    SelectedData = {        --storing the data of the selected row for comparison and manipulation
      player=core.WorkingTable[SelectedRow].player,
      class=core.WorkingTable[SelectedRow].class,
      dkp=core.WorkingTable[SelectedRow].dkp,
      previous_dkp=core.WorkingTable[SelectedRow].previous_dkp
    }
    for i=1, core.TableNumrows do
      self:GetParent().Rows[i]:SetNormalTexture(nil)
    end
    self:SetNormalTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
end

function CreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.DKPInfo = {}
    f:SetSize(core.TableWidth, core.TableHeight)
    f:SetHighlightTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
    f:SetScript("OnClick", DKPTable_OnClick)
    for i=1, 3 do
      f.DKPInfo[i] = f:CreateFontString(nil, "OVERLAY");
      f.DKPInfo[i]:SetFontObject("GameFontHighlight");
      f.DKPInfo[i]:SetTextColor(1, 1, 1, 1);
      if (i==1) then
        f.DKPInfo[i].rowCounter = f:CreateFontString(nil, "OVERLAY");
        f.DKPInfo[i].rowCounter:SetFontObject("GameFontWhiteTiny");
        f.DKPInfo[i].rowCounter:SetTextColor(1, 1, 1, 0.3);
        f.DKPInfo[i].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);
      end
      if (i==3) then
        f.DKPInfo[i].adjusted = f:CreateFontString(nil, "OVERLAY");
        f.DKPInfo[i].adjusted:SetFontObject("GameFontWhiteTiny");
        f.DKPInfo[i].adjusted:SetTextColor(1, 1, 1, 0.6);
        f.DKPInfo[i].adjusted:SetPoint("LEFT", f.DKPInfo[3], "RIGHT", 3, -1);
      end
    end
    f.DKPInfo[1]:SetPoint("LEFT", 50, 0)
    f.DKPInfo[2]:SetPoint("CENTER")
    f.DKPInfo[3]:SetPoint("RIGHT", -80, 0)
    return f
end

function DKPTable_Update(self)
  local numOptions = #core.WorkingTable
  local index, row, c
  local offset = FauxScrollFrame_GetOffset(core.DKPTable) or 0
  for i=1, core.TableNumrows do
    row = core.DKPTable.Rows[i];
    row:Hide();
  end
  for i=1, core.TableNumrows do
    row = core.DKPTable.Rows[i]
    index = offset + i
    if core.WorkingTable[index] then
      c = GetCColors(core.WorkingTable[index].class);
      row:Show()
      row.index = index
      row.DKPInfo[1]:SetText(core.WorkingTable[index].player)
      row.DKPInfo[1].rowCounter:SetText(index)
      row.DKPInfo[1]:SetTextColor(c.r, c.g, c.b, 1)
      row.DKPInfo[2]:SetText(core.WorkingTable[index].class)
      row.DKPInfo[3]:SetText(core.WorkingTable[index].dkp)
      row.DKPInfo[3].adjusted:SetText("("..core.WorkingTable[index].dkp - core.WorkingTable[index].previous_dkp..")");
      
      if (core.WorkingTable[index].player == SelectedData.player) then
        row:SetNormalTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
      else
        row:SetNormalTexture(nil)
      end
    else
      row:Hide()
    end
  end
  FauxScrollFrame_Update(core.DKPTable, numOptions, core.TableNumrows, core.TableHeight, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

--creat table for all dkp holders
--shift to working table and clear as needed.
--IE: Empty table, push full list to table one by one omiting any class not on the filter
--Sorting columns need to be made as well.