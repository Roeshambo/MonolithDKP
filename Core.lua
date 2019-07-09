--[[
  Core.lua is intended to store all core functions and variables to be used throughout the addon. 
  Don't put anything in here that you don't want to be loaded immediately after the Libs but before initialization.
--]]

local _, core = ...;
local _G = _G;

core.MonDKP = {};       -- UI Frames global
local MonDKP = core.MonDKP;

core.CColors = {   -- class colors
  ["Druid"] = { r = 1, g = 0.49, b = 0.04, hex = "FF7D0A" },
  ["Hunter"] = {  r = 0.67, g = 0.83, b = 0.45, hex = "ABD473" },
  ["Mage"] = { r = 0.25, g = 0.78, b = 0.92, hex = "40C7EB" },
  ["Priest"] = { r = 1, g = 1, b = 1, hex = "FFFFFF" },
  ["Rogue"] = { r = 1, g = 0.96, b = 0.41, hex = "FFF569" },
  ["Shaman"] = { r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
  ["Warlock"] = { r = 0.53, g = 0.53, b = 0.93, hex = "8787ED" },
  ["Warrior"] = { r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E" }
}

--------------------------------------
-- Addon Defaults
--------------------------------------
local defaults = {
  theme = { r = 0.6823, g = 0.6823, b = 0.8666, hex = "aeaedd" },
  theme2 = { r = 1, g = 0.37, b = 0.37, hex = "ff6060" }
}

core.WorkingTable = {};       -- table of all entries from MonDKP_DKPTable that are currently visible in the window. From MonDKP_DKPTable
core.settings = {             -- From MonDKP_DB
  DKPBonus = { 
    OnTimeBonus = 15,
    BossKillBonus = 5,
    CompletionBonus = 10,
    NewBossKillBonus = 10,
    UnexcusedAbsence = -25
  }
}

core.MonDKPUI = {}        -- global storing entire Configuration UI to hide/show UI
core.TableWidth, core.TableRowHeight, core.TableNumRows = 500, 18, 27; -- width, row height, number of rows
core.SelectedData = { player="none"};         -- stores data of clicked row for manipulation.
core.classFiltered = {};   -- tracks classes filtered out with checkboxes
core.classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
core.MonVersion = "v0.1 (alpha)";
core.SelectedRows = {};       -- tracks rows in DKPTable that are currently selected for SetHighlightTexture
core.ShowState = false;
core.currentSort = "class"		-- stores current sort selection

function MonDKP:GetCColors(class)
  if core.CColors then 
    local c = core.CColors[class];
    return c;
  else
    return false;
  end
end

function round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end

function MonDKP:ResetPosition()
  MonDKP.UIConfig:ClearAllPoints();
  MonDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
  MonDKP.UIConfig:SetSize(550, 590);
  MonDKP.UIConfig.TabMenu:Hide()
  MonDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\expand-arrow");
  core.ShowState = false;
  MonDKP.BidTimer:ClearAllPoints()
  MonDKP.BidTimer:SetPoint("CENTER", UIParent)
  MonDKP:Print("Window Position Reset")
end

function MonDKP:GetThemeColor()
  local c = {defaults.theme, defaults.theme2};
  return c;
end

function MonDKP:GetDKPSettings()
  return core.settings["DKPBonus"];
end

function MonDKP:Print(...)        --print function to add "MonolithDKP:" to the beginning of print() outputs.
    local defaults = MonDKP:GetThemeColor();
    local prefix = string.format("|cff%s%s|r|cff%s", defaults[1].hex:upper(), "MonolithDKP:", defaults[2].hex:upper());
    local suffix = "|r";
    if postColor then
      DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ..., suffix, postColor));
    else
      DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ..., suffix));
    end
end

function MonDKP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)  -- temp function for testing purpose only
  local btn = CreateFrame("Button", nil, relativeFrame, "MonolithDKPButtonTemplate")
  btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
  btn:SetSize(100, 30);
  btn:SetText(text);
  btn:GetFontString():SetTextColor(1, 1, 1, 1)
  btn:SetNormalFontObject("MonDKPTinyCenter");
  btn:SetHighlightFontObject("MonDKPTinyCenter");
  return btn; 
end

function MonDKP:StartTimer(seconds, ...)
  local duration = seconds
  local title = ...;
  local alpha = 1;

  if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
    MonDKP:Print("Invalid Timer");
    return;
  end

  MonDKP.BidTimer = MonDKP.BidTimer or MonDKP:CreateTimer();    -- recycles timer frame so multiple instances aren't created
  MonDKP.BidTimer:SetShown(not MonDKP.BidTimer:IsShown())         -- shows if not shown
  if MonDKP.BidTimer:IsShown() == false then                    -- terminates function if hiding timer
    return;
  end

  MonDKP.BidTimer:SetMinMaxValues(0, duration)
  MonDKP.BidTimer.timerTitle:SetText(...)
  PlaySound(8959)

  if MonDKP_DB.timerpos then
    local a = MonDKP_DB["timerpos"]                   -- retrieves timer's saved position from SavedVariables
    MonDKP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
  else
    MonDKP.BidTimer:SetPoint("CENTER")                      -- sets to center if no position has been saved
  end

  local timer = 0             -- timer starts at 0
  local timerText;            -- count down when below 1 minute
  local modulo                -- remainder after divided by 60
  local timerMinute           -- timerText / 60 to get minutes.
  local audioPlayed = false;  -- so audio only plays once
  local expiring;             -- determines when red blinking bar starts. @ 30 sec if timer > 120 seconds, @ 10 sec if below 120 seconds

  MonDKP.BidTimer:SetScript("OnUpdate", function(self, elapsed)   -- timer loop
    timer = timer + elapsed
    timerText = round(duration - timer, 1)
    if tonumber(timerText) > 60 then
      timerMinute = math.floor(tonumber(timerText) / 60, 0);
      modulo = bit.mod(tonumber(timerText), 60);
      if tonumber(modulo) < 10 then modulo = "0"..modulo end
      MonDKP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
    else
      MonDKP.BidTimer.timertext:SetText(timerText)
    end
    if duration >= 120 then
      expiring = 30;
    else
      expiring = 10;
    end
    if tonumber(timerText) < expiring then
      if audioPlayed == false then
        PlaySound(23639);
        audioPlayed = true;
      end
      MonDKP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
      if alpha > 0 then
        alpha = alpha - 0.005
      elseif alpha <= 0 then
        alpha = 1
      end
    else
      MonDKP.BidTimer:SetStatusBarColor(0, 0.8, 0)
    end
    self:SetValue(timer)
    if timer >= duration then
      MonDKP.BidTimer:Hide();
    end
  end)
end

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep
-- returns an indexed array of the keys to get to it.
-- IE: If the returned array is {1,3,2,player} it means it is located at tar[1][3][2][player]
-- use to search for players in SavedVariables. Only two possible returns is the table or false.
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
                  tinsert(location, {temp1, temp2, temp3, k} )
                end;
              end
            end
            if string.upper(tostring(v)) == value then
              tinsert(location, {temp1, temp2, k} )
            end;
          end
        end
        if string.upper(tostring(v)) == value then
          tinsert(location, {temp1, k} )
        end;
      end
    end
    if string.upper(tostring(v)) == value then  -- only returns in indexed arrays
      tinsert(location, k)
    end;
  end
  if (#location > 0) then
    return location;
  else
    return false;
  end
end

function MonDKP:DKPTable_Set(tar, field, value)                -- updates field with value where tar is found (IE: MonDKP:DKPTable_Set("Roeshambo", "dkp", 10) adds 10 dkp to user Roeshambo)
  local result = MonDKP:Table_Search(MonDKP_DKPTable, tar);
  for i=1, #result do
    local current = MonDKP_DKPTable[result[i][1]][field];
    if(field == "dkp") then
      MonDKP_DKPTable[result[i][1]][field] = current + value
    else
      MonDKP_DKPTable[result[i][1]][field] = value
    end
  end
  MonDKP:FilterDKPTable(core.currentSort, "reset")
end
  

function MonDKP:PrintTable(tar)             --prints table structure for testing purposes
  ChatFrame1:Clear()
  for k,v in pairs(tar) do                  -- remove prior to RC
    if (type(v) == "table") then
      print(k)
      for k,v in pairs(v) do
        if (type(v) == "table") then
          print("    ", k)
          for k,v in pairs(v) do
            if (type(v) == "table") then
              print("        ", k)
              for k,v in pairs(v) do
                if (type(v) ~= "table") then
                  print("            ", v)
                end
              end
              print(" ")
            else
              print("        ", v)
            end
          end
          print(" ")
        else
          print("    ", v)
        end
      end
      print(" ")
    else
      print(v)
    end
  end
  print(" ")
end