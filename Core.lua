--[[
  Core.lua is intended to store all core functions and variables to be used throughout the addon. 
  Don't put anything in here that you don't want to be loaded FIRST.
--]]

local _, core = ...;
local _G = _G;

core.MonDKP = {};       -- UI Frames global
local MonDKP = core.MonDKP;

core.CColors = {   -- class colors in RGB
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

--------------------------------------
-- Addon Defaults
--------------------------------------
local defaults = {
  theme = {
    r = 0.6823, 
    g = 0.6823,
    b = 0.8666,
    hex = "aeaedd"
  }
}

core.MonDKPUI = {}
core.TableWidth, core.TableRowHeight, core.TableNumRows = 500, 18, 27; -- width, row height, number of rows
core.SelectedData = { player="none"};         -- stores data of clicked row for manipulation.
core.classFiltered = {};   -- tracks classes filtered out with checkboxes
core.classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
core.MonVersion = "v0.1 (alpha)";
core.WorkingTable = {};

function GetCColors(class)
  if core.CColors then 
    local c = core.CColors[class];
    return c;
  else
    return false;
  end
end

function MonDKP:GetVer()
  return core.MonVersion;
end

function MonDKP:ResetPosition()
  MonDKP.UIConfig:ClearAllPoints();
  MonDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
  MonDKP.UIConfig:SetSize(1000, 590);
  MonDKP:Print("Window Position Reset")
end

function MonDKP:GetThemeColor()
  local c = defaults.theme;
  return c;
end

function MonDKP:Print(...)        --print function to add "MonolithDKP:" to the beginning of print() outputs.
    local hex = MonDKP:GetThemeColor().hex;
    local prefix = string.format("|cff%s%s|r", hex:upper(), "MonolithDKP:");
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep
-- returns an indexed array of the keys to get to it.
-- IE: If the returned array is {1,3,2,player} it means it is located at tar[1][3][2][player]
-- use to search for players in SavedVariables. If not found, returns false
-------------------------------------
function MonDKP:Table_Search(tar, val)
  local value = string.upper(tostring(val));
  local location = {}
  for k,v in pairs(tar) do
    if(type(v) == "table") then
      local temp1 = k
      for k,v in pairs(v) do
        if(type(v) == "table") then
          local temp2 = k;
          for k,v in pairs(v) do
            if(type(v) == "table") then
              local temp3 = k
              for k,v in pairs(v) do
                if string.upper(tostring(v)) == value then
                  location = {temp1, temp2, temp3, k}
                  return location;
                end;
              end
            end
            if string.upper(tostring(v)) == value then
              location = {temp1, temp2, k}
              return location
            end;
          end
        end
        if string.upper(tostring(v)) == value then
          location = {temp1, k}
          return location
        end;
      end
    end
    if string.upper(tostring(v)) == value then  -- only returns in indexed arrays
      return v
    end;
  end
  return false;
end

function MonDKP:PrintTable(tar)             --prints table structure for testing purposes
  for k,v in pairs(tar) do
    if (type(v) == "table") then
      for k,v in pairs(v) do
        if (type(v) == "table") then
          for k,v in pairs(v) do
            if (type(v) == "table") then
              for k,v in pairs(v) do
                if (type(v) ~= "table") then
                  print("            ", k, " -> ", v)
                end
              end
              print(" ")
            else
              print("        ", k, " -> ", v)
            end
          end
          print(" ")
        else
          print("    ", k, " -> ", v)
        end
      end
      print(" ")
    else
      print(k, " -> ", v)
    end
  end
  print(" ")
end