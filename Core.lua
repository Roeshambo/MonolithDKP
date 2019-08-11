--[[
  Core.lua is intended to store all core functions and variables to be used throughout the addon. 
  Don't put anything in here that you don't want to be loaded immediately after the Libs but before initialization.
--]]

local _, core = ...;
local _G = _G;

core.MonDKP = {};       -- UI Frames global
local MonDKP = core.MonDKP;

local race,_,_ = UnitRace("player");
if race == "Undead" or race == "Tauren" or race == "Orc" or race == "Troll" then
  core.faction = "Horde";
elseif race == "Gnome" or race == "Human" or race == "Night Elf" or race == "Dwarf" then
  core.faction = "Alliance";
else
  core.faction = "Horde";  -- account for live races (delete before release)
end


if core.faction == "Horde" then
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
  core.classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
elseif core.faction == "Alliance" then
  core.CColors = {   -- class colors
    ["Druid"] = { r = 1, g = 0.49, b = 0.04, hex = "FF7D0A" },
    ["Hunter"] = {  r = 0.67, g = 0.83, b = 0.45, hex = "ABD473" },
    ["Mage"] = { r = 0.25, g = 0.78, b = 0.92, hex = "40C7EB" },
    ["Paladin"] = { r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
    ["Priest"] = { r = 1, g = 1, b = 1, hex = "FFFFFF" },
    ["Rogue"] = { r = 1, g = 0.96, b = 0.41, hex = "FFF569" },
    ["Warlock"] = { r = 0.53, g = 0.53, b = 0.93, hex = "8787ED" },
    ["Warrior"] = { r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E" }
  }
  core.classes = { "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Warlock", "Warrior" }
end

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
    UnexcusedAbsence = -25,
    BidTimer = 30,
    HistoryLimit = 2500,
    DKPHistoryLimit = 2500,
    DecayPercentage = 20,
    BidTimerSize = 1.0,
    MonDKPScaleSize = 1.0,
    supressNotifications = false,
    TooltipHistoryCount = 15,
  }
}

----------------------------------------------------
-- Boss List
-- search = MonDKP:Table_Search(core.BossList, "Lucifron") returns search[1] { 1 = MC, 2 = 1} (lucifron is at 1st spot in MC table)
-- [1][1] will return "MC" and [1][2] will return "1" indicating the position of "Lucifron" in the MC table.
-- core.BossList[search[1][1]][search[1][2]] would be core.BossList["MC"][1] = Lucifron
--
-- Can alternatively use tContains(core.BossList.MC, "Lucifron") for a true/false return if path isn't required
----------------------------------------------------
core.BossList = {
  MC = {"Lucifron", "Magmadar", "Gehennas",
          "Garr", "Baron Geddon", "Shazzrah", "Sulfuron Harbinger", 
          "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros"},

  BWL = {"Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer",
          "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", 
          "Nefarian"},

  AQ = {"The Prophet Skeram", "Battleguard Sartura", "Fankriss the Unyielding",
          "Princess Huhuran", "Twin Emperors", "C'Thun", 
          "Bug Family", "Viscidus", "Ouro"},

  NAXX = {"Anub'Rekhan", "Grand Widow Faerlina", "Maexxna",
          "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", 
          "Instructor Razuvious", "Gothik the Harvester", "The Four Horsemen",
          "Patchwerk", "Grobbulus", "Gluth", "Thaddius",
        "Sapphiron", "Kel'Thuzad"}
}

core.MonDKPUI = {}        -- global storing entire Configuration UI to hide/show UI
core.TableWidth, core.TableRowHeight, core.TableNumRows = 500, 18, 27; -- width, row height, number of rows
core.SelectedData = { player="none"};         -- stores data of clicked row for manipulation.
core.classFiltered = {};   -- tracks classes filtered out with checkboxes
core.IsOfficer = "";
core.MonVersion = "v1.0.3 (Release)";
core.SelectedRows = {};       -- tracks rows in DKPTable that are currently selected for SetHighlightTexture
core.ShowState = false;
core.currentSort = "class"		-- stores current sort selection
core.BidInProgress = false;   -- flagged true if bidding in progress. else; false.
core.NumLootItems = 0;        -- updates on LOOT_OPENED event
core.CurrentRaidZone = ""
core.LastKilledBoss = ""

function MonDKP:GetCColors(class)
  if core.CColors then 
    local c = core.CColors[class] or core.CColors;
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

function MonDKP:GetGuildRank(player)
  local name, rank;
  local guildSize;

  if IsInGuild() then
    guildSize = GetNumGuildMembers();
    for i=1, guildSize do
      name, rank = GetGuildRosterInfo(i)
      name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
      if name == player then
        return rank;
      end
    end
    return "Not in Guild";
  end
  return "No Guild"
end

function MonDKP:CheckOfficer()      -- checks if user is an officer IF core.IsOfficer is empty. Use before checks against core.IsOfficer
  if core.IsOfficer == "" then
    if IsInGuild() then
      local curPlayerRank = MonDKP:GetGuildRankIndex(UnitName("player"))
      core.IsOfficer = C_GuildInfo.GuildControlGetRankFlags(curPlayerRank)[12]
    else
      core.IsOfficer = false;
    end
    core.MonDKPOptions = core.MonDKPOptions or MonDKP:Options()
  end
end

function MonDKP:GetGuildRankIndex(player)
  local name, rank;
  local guildSize,_,_ = GetNumGuildMembers();

  if IsInGuild() then
    for i=1, tonumber(guildSize) do
      name,_,rank = GetGuildRosterInfo(i)
      name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
      if name == player then
        return rank+1;
      end
    end
    return false;
  end
end

function MonDKP:GetGuildRankGroup(index)                -- returns all members within a specific rank index as well as their index in the guild list (for use with GuildRosterSetPublicNote(index, "msg") and GuildRosterSetOfficerNote)
  local name, rank, note;                               -- local temp = MonDKP:GetGuildRankGroup(1)
  local group = {}                                      -- print(temp[1]["name"])
  local guildSize,_,_ = GetNumGuildMembers();

  if IsInGuild() then
    for i=1, tonumber(guildSize) do
      name,_,rank,_,_,_,note = GetGuildRosterInfo(i)
      rank = rank+1;
      name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
      if rank == index then
        tinsert(group, { name = name, index = i, note = note })
      end
    end
    return group;
  end
end

function MonDKP:GetThemeColor()
  local c = {defaults.theme, defaults.theme2};
  return c;
end

function MonDKP:GetPlayerDKP(player)
  local search = MonDKP:Table_Search(MonDKP_DKPTable, player)
  local dkp;

  if search then
    return MonDKP_DKPTable[search[1][1]].dkp
  else
    return false;
  end
end

function MonDKP:GetDKPSettings()
  return core.settings["DKPBonus"];
end

function MonDKP:PurgeLootHistory()     -- cleans old loot history beyond history limit to reduce native system load
  local limit = core.settings["DKPBonus"]["HistoryLimit"]
  MonDKP:SortLootTable()

  if #MonDKP_Loot > limit then
    for i=limit+1, #MonDKP_Loot do
      tremove(MonDKP_Loot, i)
    end
  end
end

function MonDKP:PurgeDKPHistory()     -- cleans old DKP history beyond history limit to reduce native system load
  local limit = core.settings["DKPBonus"]["DKPHistoryLimit"]
  MonDKP:SortDKPHistoryTable()

  if #MonDKP_DKPHistory > limit then
    for i=limit+1, #MonDKP_DKPHistory do
      tremove(MonDKP_DKPHistory, i)
    end
  end
end

function MonDKP:FormatTime(time)
  local TZ = date("%Z") -- Time Zone
  local str;

  --[[if strfind(TZ, "Eastern") then
    TZ = "Eastern"
  elseif strfind(TZ, "Central") then
    TZ = "Central"
  elseif strfind(TZ, "Mountain") then
    TZ = "Mountain"
  elseif strfind(TZ, "Pacific") then
    TZ = "Pacific"
  end--]]

  str = date("%y/%m/%d %H:%M:%S", time)

  return str;
end

function MonDKP:Print(...)        --print function to add "MonolithDKP:" to the beginning of print() outputs.
    if not MonDKP_DB["DKPBonus"]["supressNotifications"] then
      local defaults = MonDKP:GetThemeColor();
      local prefix = string.format("|cff%s%s|r|cff%s", defaults[1].hex:upper(), "MonolithDKP:", defaults[2].hex:upper());
      local suffix = "|r";
      if postColor then
        DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ..., suffix, postColor));
      else
        DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ..., suffix));
      end
    end
end

function MonDKP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)  -- temp function for testing purpose only
  local btn = CreateFrame("Button", nil, relativeFrame, "MonolithDKPButtonTemplate")
  btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
  btn:SetSize(100, 30);
  btn:SetText(text);
  btn:GetFontString():SetTextColor(1, 1, 1, 1)
  btn:SetNormalFontObject("MonDKPSmallCenter");
  btn:SetHighlightFontObject("MonDKPSmallCenter");
  return btn; 
end

function MonDKP:BroadcastTimer(seconds, ...)       -- broadcasts timer and starts it natively
  if IsInRaid() and core.IsOfficer == true then
    local title = ...;
    if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
      MonDKP:Print("Invalid Timer");
      return;
    end
    MonDKP:StartTimer(seconds, ...)
    MonDKP.Sync:SendData("MonDKPNotify", "StartTimer,"..seconds..","..title)
  end
end

function MonDKP:StartTimer(seconds, ...)
  local duration = tonumber(seconds)
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
      end
      if tonumber(timerText) < 10 then
        audioPlayed = true
        StopSound(23639)
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
      MonDKP.BidTimer:SetScript("OnUpdate", nil)
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

function MonDKP:TableStrFind(tar, val)              -- same function as above, but searches values that contain the searched string rather than exact string matches
  local value = string.upper(tostring(val));        -- ex. MonDKP:TableStrFind(MonDKP_DKPHistory, "Roeshambo") will return the path to any table element that contains "Roeshambo"
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
                if strfind(string.upper(tostring(v)), value) then
                  tinsert(location, {temp1, temp2, temp3, k} )
                end;
              end
            end
            if strfind(string.upper(tostring(v)), value) then
              tinsert(location, {temp1, temp2, k} )
            end;
          end
        end
        if strfind(string.upper(tostring(v)), value) then
          tinsert(location, {temp1, k} )
        end;
      end
    end
    if strfind(string.upper(tostring(v)), value) then  -- only returns in indexed arrays
      tinsert(location, k)
    end;
  end
  if (#location > 0) then
    return location;
  else
    return false;
  end
end

function MonDKP:DKPTable_Set(tar, field, value, loot)                -- updates field with value where tar is found (IE: MonDKP:DKPTable_Set("Roeshambo", "dkp", 10) adds 10 dkp to user Roeshambo). loot = true/false if it's to alter lifetime_spent
  local result = MonDKP:Table_Search(MonDKP_DKPTable, tar);
  for i=1, #result do
    local current = MonDKP_DKPTable[result[i][1]][field];
    if(field == "dkp") then
      MonDKP_DKPTable[result[i][1]][field] = current + value
      if value > 0 and loot == false then
        MonDKP_DKPTable[result[i][1]]["lifetime_gained"] = MonDKP_DKPTable[result[i][1]]["lifetime_gained"] + value
      elseif value < 0 and loot == true then
        MonDKP_DKPTable[result[i][1]]["lifetime_spent"] = MonDKP_DKPTable[result[i][1]]["lifetime_spent"] + value
      end
    else
      MonDKP_DKPTable[result[i][1]][field] = value
    end
  end
  MonDKP:FilterDKPTable(core.currentSort, "reset")
end