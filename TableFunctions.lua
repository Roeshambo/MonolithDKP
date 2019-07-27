local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

local SelectedRow = 0;        -- sets the row that is being clicked

function DKPTable_OnClick(self)   
  local offset = FauxScrollFrame_GetOffset(MonDKP.DKPTable) or 0
  local index, TempSearch;
  SelectedRow = self.index
  if(not IsShiftKeyDown()) then
    for i=1, core.TableNumRows do
      core.SelectedData = {}
      TempSearch = MonDKP:Table_Search(core.SelectedRows, SelectedRow);
      core.SelectedRows = {}
      if (TempSearch == false) then
        tinsert(core.SelectedRows, {SelectedRow});
      else
        core.SelectedData = {}
      end
      self:GetParent().Rows[i]:SetNormalTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight")
    end
  else
    TempSearch = MonDKP:Table_Search(core.SelectedRows, SelectedRow);
    if MonDKP.ConfigTab2.selectAll:GetChecked() then
      core.SelectedRows = {}
      core.SelectedData = {}
      tinsert(core.SelectedRows, {SelectedRow});
      MonDKP.ConfigTab2.selectAll:SetChecked(false)
    elseif TempSearch == false then
      tinsert(core.SelectedRows, {SelectedRow});
    else
      tremove(core.SelectedRows, TempSearch[1][1])
    end
  end
  if (TempSearch == false) then
    tinsert(core.SelectedData, {        --storing the data of the selected row for comparison and manipulation
      player=core.WorkingTable[SelectedRow].player,
      class=core.WorkingTable[SelectedRow].class,
      dkp=core.WorkingTable[SelectedRow].dkp,
      previous_dkp=core.WorkingTable[SelectedRow].previous_dkp
    });
  else
    tremove(core.SelectedData, TempSearch[1][1])
  end
  for i=1, core.TableNumRows do
    index = offset + i;
    local a = MonDKP:Table_Search(core.SelectedRows, index);
    if(a==false) then
      MonDKP.DKPTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
      MonDKP.DKPTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
    else
      MonDKP.DKPTable.Rows[i]:SetNormalTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight")
      MonDKP.DKPTable.Rows[i]:GetNormalTexture():SetAlpha(0.7)
    end
  end
end

local function DisplayUserHistory(self, player)
  local PlayerTable = {}
  local c, PlayerSearch, PlayerSearch2, LifetimeSearch, RowCount, curDate;

  PlayerSearch = MonDKP:TableStrFind(MonDKP_DKPHistory, player)
  PlayerSearch2 = MonDKP:TableStrFind(MonDKP_Loot, player)
  LifetimeSearch = MonDKP:Table_Search(MonDKP_DKPTable, player)

  c = MonDKP:GetCColors(MonDKP_DKPTable[LifetimeSearch[1][1]].class)

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
  GameTooltip:SetText("Recent History for |cff"..c.hex..player.."|r\n", 0.25, 0.75, 0.90, 1, true);

  if PlayerSearch then
    for i=1, #PlayerSearch do
      tinsert(PlayerTable, {reason = MonDKP_DKPHistory[PlayerSearch[i][1]].reason, date = MonDKP_DKPHistory[PlayerSearch[i][1]].date, dkp = MonDKP_DKPHistory[PlayerSearch[i][1]].dkp})
    end
  end

  if PlayerSearch2 then
    for i=1, #PlayerSearch2 do
      tinsert(PlayerTable, {loot = MonDKP_Loot[PlayerSearch2[i][1]].loot, date = MonDKP_Loot[PlayerSearch2[i][1]].date, zone = MonDKP_Loot[PlayerSearch2[i][1]].zone, boss = MonDKP_Loot[PlayerSearch2[i][1]].boss, cost = MonDKP_Loot[PlayerSearch2[i][1]].cost})
    end
  end

  table.sort(PlayerTable, function(a, b)
    return a["date"] > b["date"]
  end)

  if #PlayerTable > 0 then
    if #PlayerTable > core.settings.DKPBonus["TooltipHistoryCount"] then
      RowCount = core.settings.DKPBonus["TooltipHistoryCount"]
    else
      RowCount = #PlayerTable;
    end

    for i=1, RowCount do
      if date("%m/%d/%y", PlayerTable[i].date) ~= curDate then
        curDate = date("%m/%d/%y", PlayerTable[i].date)
        GameTooltip:AddLine(date("%m/%d/%y", PlayerTable[i].date), 1.0, 1.0, 1.0, true);
      end
      if PlayerTable[i].dkp then
        if strfind(PlayerTable[i].dkp, "%%") or tonumber(PlayerTable[i].dkp) < 0 then
          GameTooltip:AddDoubleLine("  "..PlayerTable[i].reason, "|cffff0000"..PlayerTable[i].dkp.." DKP|r", 1.0, 0, 0);
        else
          GameTooltip:AddDoubleLine("  "..PlayerTable[i].reason, "|cff00ff00"..PlayerTable[i].dkp.." DKP|r", 0, 1.0, 0);
        end
      elseif PlayerTable[i].cost then
        GameTooltip:AddDoubleLine("  "..PlayerTable[i].zone..": |cffff0000"..PlayerTable[i].boss.."|r", PlayerTable[i].loot.." |cffff0000(-"..PlayerTable[i].cost.." DKP)|r", 1.0, 1.0, 1.0);
      end
    end
    GameTooltip:AddDoubleLine(" ", " ", 1.0, 1.0, 1.0);
    GameTooltip:AddLine("  |cff00ff00Lifetime Earned: "..MonDKP_DKPTable[LifetimeSearch[1][1]].lifetime_gained.."|r", 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine("  |cffff0000Lifetime Spent: "..MonDKP_DKPTable[LifetimeSearch[1][1]].lifetime_spent.."|r", 1.0, 1.0, 1.0, true);
  else
    GameTooltip:AddLine("No DKP Entries", 1.0, 1.0, 1.0, true);
  end

  GameTooltip:Show();
end

local function CreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.DKPInfo = {}
    f:SetSize(core.TableWidth, core.TableRowHeight)
    f:SetHighlightTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight");
    f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
    f:GetNormalTexture():SetAlpha(0.2)
    f:SetScript("OnClick", DKPTable_OnClick)
    for i=1, 3 do
      f.DKPInfo[i] = f:CreateFontString(nil, "OVERLAY");
      f.DKPInfo[i]:SetFontObject("GameFontHighlight");
      f.DKPInfo[i]:SetFontObject("MonDKPSmallLeft")
      f.DKPInfo[i]:SetTextColor(1, 1, 1, 1);
      if (i==1) then
        f.DKPInfo[i].rowCounter = f:CreateFontString(nil, "OVERLAY");
        f.DKPInfo[i].rowCounter:SetFontObject("GameFontWhiteTiny");
        f.DKPInfo[i].rowCounter:SetFontObject("MonDKPSmallLeft")
        f.DKPInfo[i].rowCounter:SetTextColor(1, 1, 1, 0.3);
        f.DKPInfo[i].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);
      end
      if (i==3) then
        f.DKPInfo[i]:SetFontObject("MonDKPSmallLeft")
        f.DKPInfo[i].adjusted = f:CreateFontString(nil, "OVERLAY");
        f.DKPInfo[i].adjusted:SetFontObject("MonDKPSmallLeft")
        f.DKPInfo[i].adjusted:SetScale("0.8")
        f.DKPInfo[i].adjusted:SetTextColor(1, 1, 1, 0.6);
        f.DKPInfo[i].adjusted:SetPoint("LEFT", f.DKPInfo[3], "RIGHT", 3, -1);
        f.DKPInfo[i].adjustedArrow = f:CreateTexture(nil, "OVERLAY", nil, -8);
        f.DKPInfo[i].adjustedArrow:SetPoint("RIGHT", f, "RIGHT", -20, 0);
        f.DKPInfo[i].adjustedArrow:SetColorTexture(0, 0, 0, 0.5)
        f.DKPInfo[i].adjustedArrow:SetSize(8, 12);
      end
    end
    f.DKPInfo[1]:SetPoint("LEFT", 50, 0)
    f.DKPInfo[2]:SetPoint("CENTER")
    f.DKPInfo[3]:SetPoint("RIGHT", -80, 0)
    return f
end

function DKPTable_Update()
  local numOptions = #core.WorkingTable
  local index, row, c
  local offset = FauxScrollFrame_GetOffset(MonDKP.DKPTable) or 0
  local rank;
  for i=1, core.TableNumRows do     -- hide all rows before displaying them 1 by 1 as they show values
    row = MonDKP.DKPTable.Rows[i];
    row:Hide();
  end
  --[[for i=1, #MonDKP_DKPTable do
    if MonDKP_DKPTable[i].dkp < 0 then MonDKP_DKPTable[i].dkp = 0 end  -- cleans negative numbers from SavedVariables
  end--]]
  for i=1, core.TableNumRows do     -- show rows if they have values
    row = MonDKP.DKPTable.Rows[i]
    index = offset + i
    if core.WorkingTable[index] then
      --if (tonumber(core.WorkingTable[index].dkp) < 0) then core.WorkingTable[index].dkp = 0 end           -- shows 0 if negative DKP
      c = MonDKP:GetCColors(core.WorkingTable[index].class);
      row:Show()
      row.index = index
      local CurPlayer = core.WorkingTable[index].player;
      rank = MonDKP:GetGuildRank(core.WorkingTable[index].player) or "None"
      row.DKPInfo[1]:SetText(core.WorkingTable[index].player.." |cff444444("..rank..")|r")
      row.DKPInfo[1].rowCounter:SetText(index)
      row.DKPInfo[1]:SetTextColor(c.r, c.g, c.b, 1)
      row.DKPInfo[2]:SetText(core.WorkingTable[index].class)
      row.DKPInfo[3]:SetText(core.WorkingTable[index].dkp)
      local CheckAdjusted = core.WorkingTable[index].dkp - core.WorkingTable[index].previous_dkp;
      if(CheckAdjusted > 0) then 
        CheckAdjusted = strjoin("", "+", CheckAdjusted) 
        row.DKPInfo[3].adjustedArrow:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\green-up-arrow.png");
      elseif (CheckAdjusted < 0) then
        row.DKPInfo[3].adjustedArrow:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\red-down-arrow.png");
      else
        row.DKPInfo[3].adjustedArrow:SetTexture(nil);
      end        
      row.DKPInfo[3].adjusted:SetText("("..CheckAdjusted..")");

      local a = MonDKP:Table_Search(core.SelectedData, core.WorkingTable[index].player);  -- searches selectedData for the player name indexed.
      if(a==false) then
        MonDKP.DKPTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
        MonDKP.DKPTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
      else
        MonDKP.DKPTable.Rows[i]:SetNormalTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight")
        MonDKP.DKPTable.Rows[i]:GetNormalTexture():SetAlpha(0.7)
      end
      MonDKP.DKPTable.Rows[i]:SetScript("OnEnter", function(self)
        DisplayUserHistory(self, CurPlayer)
      end)
      MonDKP.DKPTable.Rows[i]:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    else
      row:Hide()
    end
  end
  MonDKP.DKPTable.counter.t:SetText(#core.WorkingTable.." Entries Shown");    -- updates "Entries Shown" at bottom of DKPTable
  MonDKP.DKPTable.counter.t:SetFontObject("MonDKPSmallLeft")

  FauxScrollFrame_Update(MonDKP.DKPTable, numOptions, core.TableNumRows, core.TableRowHeight, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function MonDKP:DKPTable_Create()
  MonDKP.DKPTable = CreateFrame("ScrollFrame", "MonDKPDisplayScrollFrame", MonDKP.UIConfig, "FauxScrollFrameTemplate")
  MonDKP.DKPTable:SetSize(core.TableWidth, core.TableRowHeight*core.TableNumRows+3)
  MonDKP.DKPTable:SetPoint("LEFT", 20, 3)
  MonDKP.DKPTable:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  MonDKP.DKPTable:SetBackdropColor(0,0,0,0.4);
  MonDKP.DKPTable:SetBackdropBorderColor(1,1,1,0.5)
  MonDKP.DKPTable:SetClipsChildren(false);

  MonDKP.DKPTable.ScrollBar = FauxScrollFrame_GetChildFrames(MonDKP.DKPTable)
  MonDKP.DKPTable.Rows = {}
  for i=1, core.TableNumRows do
    MonDKP.DKPTable.Rows[i] = CreateRow(MonDKP.DKPTable, i)
    if i==1 then
      MonDKP.DKPTable.Rows[i]:SetPoint("TOPLEFT", MonDKP.DKPTable, "TOPLEFT", 0, -2)
    else  
      MonDKP.DKPTable.Rows[i]:SetPoint("TOPLEFT", MonDKP.DKPTable.Rows[i-1], "BOTTOMLEFT")
    end
  end
  MonDKP.DKPTable:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, core.TableRowHeight, DKPTable_Update)
  end)
  
  MonDKP.DKPTable.SeedVerify = CreateFrame("Frame", nil, MonDKP.DKPTable);
  MonDKP.DKPTable.SeedVerify:SetPoint("TOPLEFT", MonDKP.DKPTable, "BOTTOMLEFT", 0, -15);
  MonDKP.DKPTable.SeedVerify:SetSize(18, 18);
  MonDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  MonDKP.DKPTable.SeedVerifyIcon = MonDKP.DKPTable:CreateTexture(nil, "OVERLAY", nil)             -- seed verify (bottom left) indicator
  MonDKP.DKPTable.SeedVerifyIcon:SetPoint("TOPLEFT", MonDKP.DKPTable.SeedVerify, "TOPLEFT", 0, 0);
  MonDKP.DKPTable.SeedVerifyIcon:SetColorTexture(0, 0, 0, 1)
  MonDKP.DKPTable.SeedVerifyIcon:SetSize(18, 18);
  MonDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\out-of-date")
end

function MonDKP:SeedVerify_Update()
  if IsInGuild() then
    local leader = MonDKP:GetGuildRankGroup(1)

    if MonDKP_DB.seed >= tonumber(leader[1].note) then
      MonDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\up-to-date")
      MonDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
        GameTooltip:SetText("DKP Status", 0.25, 0.75, 0.90, 1, true);
        GameTooltip:AddLine("Your DKP Table is currently |cff00ff00up-to-date|r.", 1.0, 1.0, 1.0, false);
        GameTooltip:Show()
      end)
    else
      MonDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\out-of-date")
      MonDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
        GameTooltip:SetText("DKP Status", 0.25, 0.75, 0.90, 1, true);
        GameTooltip:AddLine("Your DKP Table is currently |cffff0000out-of-date|r.", 1.0, 1.0, 1.0, false);
        GameTooltip:AddLine("Request updated tables from an officer.", 1.0, 1.0, 1.0, false);
        GameTooltip:Show()
      end)
    end
  else
    MonDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
        GameTooltip:SetText("DKP Status", 0.25, 0.75, 0.90, 1, true);
        GameTooltip:AddLine("You are not currently in a guild. DKP status can not be queried.", 1.0, 1.0, 1.0, true);
        GameTooltip:Show()
      end)
  end
end