
local _, core = ...;
local _G = _G;
local classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
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
local SelectedData = 0;

--[[
  Table above will be structured as:

WorkingTable = {
  ["player"] = "Roeshambo",
  ["class"] = "Warrior",
  ["dkp"] = 1000,
  ["previous_dkp"] = 800, --not implemented yet. set previous_dkp = dkp at beginning of raid to see how much was gained/lost during a raid.

}
--]]

function GetCColors(class)
  local c = CColors[class];
  return c;
end

function DKPTable_Rebuild()         --rebuild WorkingTable with applied filters
  
end

function DKPTable_OnClick(self)   -- self = Rows[]
    SelectedData = self.index;
    for i=1, core.TableNumrows do
      self:GetParent().Rows[i]:SetNormalTexture(nil)
    end
    self:SetNormalTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
    --[[  
    for k,v in pairs(WorkingTable[SelectedData]) do
      if(tostring(k) == "class") then
        print(k, " -> ", classes[v])
      else
        print(k, " -> ", v)
      end
    end
    --retrieves string text
    print(self.DKPInfo[1].data:GetText())
    print(self.DKPInfo[2].data:GetText())
    print(self.DKPInfo[3].data:GetText())
    self.index selects the number of the row
    --]]
end
 
function CreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.DKPInfo = {}
    f:SetSize(core.TableWidth, core.TableHeight)
    f:SetHighlightTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
    f:SetScript("OnClick", DKPTable_OnClick)
    for i=1, 3 do
      tinsert(f.DKPInfo, CreateFrame("Frame", "$parentButton"..i, f))
      f.DKPInfo[i]:SetSize(core.TableWidth/3, core.TableHeight)
      f.DKPInfo[i]:SetPoint("LEFT", f.DKPInfo[i-1] or f, f.DKPInfo[i-1] and "RIGHT" or "LEFT")
      f.DKPInfo[i].data = f.DKPInfo[i]:CreateFontString(nil, "OVERLAY");
      f.DKPInfo[i].data:SetFontObject("GameFontHighlight");
      f.DKPInfo[i].data:SetTextColor(1, 1, 1, 1);
      f.DKPInfo[i].data:SetPoint("CENTER", f.DKPInfo[i], "CENTER");
      if (i==3) then
        f.DKPInfo[i].adjusted = f.DKPInfo[i]:CreateFontString(nil, "OVERLAY");
        f.DKPInfo[i].adjusted:SetFontObject("GameFontWhiteTiny");
        f.DKPInfo[i].adjusted:SetTextColor(1, 1, 1, 0.6);
        f.DKPInfo[i].adjusted:SetPoint("LEFT", f.DKPInfo[i].data, "RIGHT", 3, -1);
      end
    end
    return f
end
 
function DKPTable_Update(self)
    local numOptions = #core.WorkingTable
    local index, row
    local offset = FauxScrollFrame_GetOffset(core.DKPTable)
    for i=1, core.TableNumrows do
        index = offset + i
        row = core.DKPTable.Rows[i]
        local c = GetCColors(core.WorkingTable[index].class);
        row.DKPInfo[1].data:SetText(core.WorkingTable[index].player)
        row.DKPInfo[1].data:SetTextColor(c.r, c.g, c.b, 1)
        row.DKPInfo[2].data:SetText("N/A")
        row.DKPInfo[3].data:SetText(core.WorkingTable[index].dkp)
        row.DKPInfo[3].adjusted:SetText("("..core.WorkingTable[index].dkp - core.WorkingTable[index].previous_dkp..")");
        if (index == SelectedData) then
          row:SetNormalTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
        else
          row:SetNormalTexture(nil)
        end
        if core.WorkingTable[index] then
            row:Show()
            row.index = index
        else
            row:Hide()
        end
    end
    FauxScrollFrame_Update(core.DKPTable, numOptions, core.TableNumrows, core.TableHeight)
end


--self.text

--self.text:GetText() ~= classes[WorkingTable[index].class]

--creat table for all dkp holders
--shift to working table and clear as needed.
--IE: Empty table, push full list to table one by one omiting any class not on the filter
--Sorting columns need to be made as well.