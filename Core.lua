local _, core = ...;
local _G = _G;

core.MonDKP = {};       -- UI Frames
local MonDKP = core.MonDKP;

core.CColors = {
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

core.TableWidth, core.TableHeight, core.TableNumrows = 500, 18, 27;
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
  UIConfig:ClearAllPoints();
  UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
  UIConfig:SetSize(1000, 590);
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

function MonDKP:MonDKP_Search(tar, val)  --recursively searches tar (table) for val (string) as far as three nests deep
  local value = tostring(val);
  for k,v in pairs(tar) do
    if(type(v) == "table") then
      for k,v in pairs(v) do
        if(type(v) == "table") then
          for k,v in pairs(v) do
            if v == value then return true end;
          end
        end
        if v == value then return true end;
      end
    end
    if v == value then return true end;
  end

  return false;
end