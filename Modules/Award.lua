local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local function AwardItem(player, cost, boss, zone, loot)
  local cost = cost;
  local winner = player;
  local curTime = time();
  local curZone = zone;
  local curBoss = boss;
  local loot = loot;
  local mode = MonDKP_DB.modes.mode;

  MonDKP:SeedVerify_Update()

  if core.IsOfficer then            
    if MonDKP_DB.modes.costvalue == "Percent" then
      local search = MonDKP:Table_Search(MonDKP_DKPTable, winner);

      if MonDKP_DB.modes.mode == "Roll Based Bidding" then
        if search then
          cost = MonDKP_round(MonDKP_DKPTable[search[1][1]].dkp * (cost / 100), MonDKP_DB.modes.rounding);
        else
          print(L["ERROR"])
        end
      else
        cost = MonDKP_round(MonDKP_DKPTable[search[1][1]].dkp * (cost / 100), MonDKP_DB.modes.rounding);
      end
    else
      cost = MonDKP_round(cost, MonDKP_DB.modes.rounding)
    end
    
    MonDKP:DKPTable_Set(winner, "dkp", MonDKP_round(-cost, MonDKP_DB.modes.rounding), true)
    tinsert(MonDKP_Loot, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost})
    
    if core.UpToDate and core.IsOfficer then -- updates seeds only if table is currently up to date.
      MonDKP:UpdateSeeds()
    end
    
    local temp_table = {}
    tinsert(temp_table, {seed = MonDKP_Loot.seed, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost}})
    MonDKP:LootHistory_Reset();
    MonDKP:LootHistory_Update("No Filter")
    MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
    MonDKP.Sync:SendData("MonDKPLootAward", temp_table[1])

    if core.BiddingWindow and core.BiddingWindow:IsShown() then  -- runs below if award is through bidding window (update minbids and zerosum bank)
      if _G["MonDKPBiddingStartBiddingButton"] then
        _G["MonDKPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
        _G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
          ToggleTimerBtn(self)
        end)
        timerToggle = 0;
      end

      core.BidInProgress = false;
      MonDKP:BroadcastStopBidTimer()
      SendChatMessage(L["CONGRATS"].." "..winner.." "..L["ON"].." "..loot.." @ "..cost.." "..L["DKP"], "RAID_WARNING")

      if MonDKP_DB.modes.AnnounceAward then
        SendChatMessage(L["CONGRATS"].." "..winner.." "..L["ON"].." "..loot.." @ "..cost.." "..L["DKP"], "GUILD")
      end
        
      if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
        local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
        local val = MonDKP:GetMinBid(loot);

        if not search and core.BiddingWindow.cost:GetNumber() ~= tonumber(val) then
          tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.cost:GetNumber()})
          core.BiddingWindow.CustomMinBid:SetShown(true);
          core.BiddingWindow.CustomMinBid:SetChecked(true);
        elseif search and core.BiddingWindow.cost:GetNumber() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
          if MonDKP_MinBids[search[1][1]].minbid ~= core.BiddingWindow.cost:GetText() then
          MonDKP_MinBids[search[1][1]].minbid = MonDKP_round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding);
          core.BiddingWindow.CustomMinBid:SetShown(true);
          core.BiddingWindow.CustomMinBid:SetChecked(true);
        end
      end

      if search and core.BiddingWindow.CustomMinBid:GetChecked() == false then
        table.remove(MonDKP_MinBids, search[1][1])
        core.BiddingWindow.CustomMinBid:SetShown(false);
      end
        end
        
      if mode == "Zero Sum" then
        MonDKP_DB.modes.ZeroSumBank.balance = MonDKP_DB.modes.ZeroSumBank.balance + tonumber(cost)
        table.insert(MonDKP_DB.modes.ZeroSumBank, { loot = loot, cost = tonumber(cost) })
        MonDKP:ZeroSumBank_Update()
        MonDKP.Sync:SendData("MonDKPZeroSum", MonDKP_DB.modes.ZeroSumBank)
      end
      core.BiddingWindow:Hide()
      table.wipe(temp_table)
      ClearBidWindow()
    end
  end
end

local function AwardConfirm_Create()
  local f = CreateFrame("Frame", "MonDKP_AwardWindowConfirm", UIParent, "ShadowOverlaySmallTemplate");

  f:SetPoint("TOP", UIParent, "TOP", 0, -200);
  f:SetSize(400, 230);
  f:SetClampedToScreen(true)
  f:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  f:SetBackdropColor(0,0,0,0.9);
  f:SetBackdropBorderColor(1,1,1,1)
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(15)
  f:Hide()

  f.confirmHeader = f:CreateFontString(nil, "OVERLAY")
  f.confirmHeader:SetFontObject("MonDKPLargeRight");
  f.confirmHeader:SetScale(0.9)
  f.confirmHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -15);
  f.confirmHeader:SetText(L["CONFAWARD"])

  f.playerHeader = f:CreateFontString(nil, "OVERLAY")
  f.playerHeader:SetFontObject("MonDKPLargeRight");
  f.playerHeader:SetScale(0.7)
  f.playerHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 120, -60);
  f.playerHeader:SetText(L["PLAYER"]..":")

  f.player = f:CreateFontString(nil, "OVERLAY")
  f.player:SetFontObject("MonDKPNormalLeft");
  f.player:SetPoint("LEFT", f.playerHeader, "RIGHT", 5, 1);
  f.player:SetSize(200, 28);

  f.lootHeader = f:CreateFontString(nil, "OVERLAY")
  f.lootHeader:SetFontObject("MonDKPLargeRight");
  f.lootHeader:SetScale(0.7)
  f.lootHeader:SetPoint("TOPRIGHT", f.playerHeader, "BOTTOMRIGHT", 0, -10);
  f.lootHeader:SetText(L["ITEM"]..":")

  f.lootIcon = f:CreateTexture(nil, "OVERLAY", nil);
  f.lootIcon:SetPoint("LEFT", f.lootHeader, "RIGHT", 5, 0);
  f.lootIcon:SetColorTexture(0, 0, 0, 1)
  f.lootIcon:SetSize(28, 28);

  f.loot = f:CreateFontString(nil, "OVERLAY")
  f.loot:SetFontObject("MonDKPNormalLeft");
  f.loot:SetPoint("LEFT", f.lootIcon, "RIGHT", 5, 1);
  f.loot:SetSize(200, 28);

  f.costHeader = f:CreateFontString(nil, "OVERLAY")
  f.costHeader:SetFontObject("MonDKPLargeRight");
  f.costHeader:SetScale(0.7)
  f.costHeader:SetPoint("TOPRIGHT", f.lootHeader, "BOTTOMRIGHT", 0, -10);
  f.costHeader:SetText(L["ITEMCOST"]..":")

  f.cost = f:CreateFontString(nil, "OVERLAY")
  f.cost:SetFontObject("MonDKPNormalLeft");
  f.cost:SetPoint("LEFT", f.costHeader, "RIGHT", 5, 0);
  f.cost:SetSize(200, 28);

  f.bossHeader = f:CreateFontString(nil, "OVERLAY")
  f.bossHeader:SetFontObject("MonDKPLargeRight");
  f.bossHeader:SetScale(0.7)
  f.bossHeader:SetPoint("TOPRIGHT", f.costHeader, "BOTTOMRIGHT", 0, -10);
  f.bossHeader:SetText(L["BOSS"]..":")

  f.bossDropDown = CreateFrame("FRAME", "MonDKPAwardConfirmBossDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
  f.bossDropDown:SetPoint("LEFT", f.bossHeader, "RIGHT", -15, 0)
  UIDropDownMenu_SetWidth(f.bossDropDown, 150)
  UIDropDownMenu_JustifyText(f.bossDropDown, "LEFT")

  f.zoneHeader = f:CreateFontString(nil, "OVERLAY")
  f.zoneHeader:SetFontObject("MonDKPLargeRight");
  f.zoneHeader:SetScale(0.7)
  f.zoneHeader:SetPoint("TOPRIGHT", f.bossHeader, "BOTTOMRIGHT", 0, -10);
  f.zoneHeader:SetText(L["ZONE"]..":")

  f.zoneDropDown = CreateFrame("FRAME", "MonDKPAwardConfirmBossDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
  f.zoneDropDown:SetPoint("LEFT", f.zoneHeader, "RIGHT", -15, 0)
  UIDropDownMenu_SetWidth(f.zoneDropDown, 150)
  UIDropDownMenu_JustifyText(f.zoneDropDown, "LEFT")

  f.yesButton = MonDKP:CreateButton("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 15, L["CONFIRM"]);
  f.noButton = MonDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 15, L["CANCEL"]);

  return f;
end

function MonDKP:AwardConfirm(player, cost, boss, zone, loot)
  if core.CurrentlySyncing then
    StaticPopupDialogs["CURRENTLY_SYNC"] = {
      text = "|CFFFF0000"..L["WARNING"].."|r: "..L["CURRENTLYSYNCING"],
      button1 = L["OK"],
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("CURRENTLY_SYNC")
    return;
  end
  local _,_,_,_,_,_,_,_,_,itemIcon = GetItemInfo(loot)
  local curBoss, curZone = boss, zone
  local class;
  local search = MonDKP:Table_Search(MonDKP_DKPTable, player)

  class = MonDKP:GetCColors(MonDKP_DKPTable[search[1][1]].class)

  PlaySound(850)
  core.AwardConfirm = core.AwardConfirm or AwardConfirm_Create()
  core.AwardConfirm:SetShown(not core.AwardConfirm:IsShown())

  core.AwardConfirm.player:SetText("|cff"..class.hex..player.."|r")
  core.AwardConfirm.lootIcon:SetTexture(itemIcon)
  core.AwardConfirm.loot:SetText(loot)
  core.AwardConfirm.cost:SetText("|cffff0000"..cost.." "..L["DKP"].."|r")
  --core.AwardConfirm.boss:SetText(boss.." in "..zone)

  UIDropDownMenu_SetText(core.AwardConfirm.bossDropDown, curBoss)
  UIDropDownMenu_Initialize(core.AwardConfirm.bossDropDown, function(self, level, menuList)                                   -- BOSS dropdown
    UIDropDownMenu_SetAnchor(core.AwardConfirm.bossDropDown, 0, 0, "TOPLEFT", core.AwardConfirm.bossDropDown, "BOTTOMLEFT")
    --UIDropDownMenu_JustifyText(core.AwardConfirm.bossDropDown, "LEFT") 
    local reason = UIDropDownMenu_CreateInfo()
    local tempNPCs = {};

    table.insert(tempNPCs, core.LastKilledBoss)

    for k,v in pairs(core.LastKilledNPC) do             -- eliminates duplicate zones
      if not MonDKP:Table_Search(tempNPCs, v) then
        table.insert(tempNPCs, v)
      end
    end

    reason.func = self.SetValue

    if not MonDKP:Table_Search(tempNPCs, curBoss) then
      reason.text, reason.arg1, reason.checked, reason.isNotRadio = curBoss, curBoss, curBoss == curBoss, true
      UIDropDownMenu_AddButton(reason)
    end

    for i=1, #tempNPCs do
      reason.text, reason.arg1, reason.checked, reason.isNotRadio = tempNPCs[i], tempNPCs[i], tempNPCs[i] == curBoss, true
      UIDropDownMenu_AddButton(reason)
    end
  end)

  UIDropDownMenu_SetText(core.AwardConfirm.zoneDropDown, core.CurrentRaidZone)
  UIDropDownMenu_Initialize(core.AwardConfirm.zoneDropDown, function(self, level, menuList)                                   -- ZONE dropdown
    UIDropDownMenu_SetAnchor(core.AwardConfirm.zoneDropDown, 0, 0, "TOPLEFT", core.AwardConfirm.zoneDropDown, "BOTTOMLEFT")
    --UIDropDownMenu_JustifyText(core.AwardConfirm.bossDropDown, "LEFT") 
    local reason = UIDropDownMenu_CreateInfo()
    local tempZones = {};

    table.insert(tempZones, core.CurrentRaidZone)

    for k,v in pairs(core.RecentZones) do             -- eliminates duplicate zones
      if not MonDKP:Table_Search(tempZones, v) then
        table.insert(tempZones, v)
      end
    end

    reason.func = self.SetValue

    for i=1, #tempZones do
      reason.text, reason.arg1, reason.checked, reason.isNotRadio = tempZones[i], tempZones[i], tempZones[i] == curZone, true
      UIDropDownMenu_AddButton(reason)
    end
  end)

  function core.AwardConfirm.bossDropDown:SetValue(newValue)          ---- BOSS dropdown function
    UIDropDownMenu_SetText(core.AwardConfirm.bossDropDown, newValue)
    curBoss = newValue;
    CloseDropDownMenus()
  end

  function core.AwardConfirm.zoneDropDown:SetValue(newValue)          ---- ZONE dropdown function
    UIDropDownMenu_SetText(core.AwardConfirm.zoneDropDown, newValue)
    curZone = newValue;
    CloseDropDownMenus()
  end

  core.AwardConfirm.yesButton:SetScript("OnClick", function()         -- Run when "Yes" is clicked
    AwardItem(player, cost, curBoss, curZone, loot)


    PlaySound(851)
    core.AwardConfirm:SetShown(false)
  end)
  core.AwardConfirm.noButton:SetScript("OnClick", function()          -- Run when "No" is clicked
    PlaySound(851)
    core.AwardConfirm:SetShown(false)
  end)
end