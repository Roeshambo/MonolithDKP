local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local CommDKPApi = core.CommDKPApi;
local L = core.L;

local Bids_Submitted = {};
local upper = string.upper
local width, height, numrows = 370, 18, 13
local CurrItemForBid;
local CurrItemIcon;
local SelectedBidder = {}
local CurZone;
local Timer = 0;
local timerToggle = 0;
local mode;
local events = CreateFrame("Frame", "BiddingEventsFrame");
local menuFrame = CreateFrame("Frame", "CommDKPBidWindowMenuFrame", UIParent, "UIDropDownMenuTemplate")
local hookedSlots = {}

function CommDKPApi:SetPriceListApi(api)
  if api.GetItemPrice ~= nil then
    CommDKPApi.pricelist = api
    return true
  end
  return false
end

local function UpdateBidWindow()
  core.BiddingWindow.item:SetText(CurrItemForBid)
  core.BiddingWindow.itemIcon:SetTexture(CurrItemIcon)
end

function CommDKP:BidsSubmitted_Get()
  return Bids_Submitted;
end

function CommDKP:BidsSubmitted_Clear()
  Bids_Submitted = {};
end

local function Roll_OnEvent(self, event, arg1, ...)
  if event == "CHAT_MSG_SYSTEM" and core.BidInProgress then

    if GetLocale() == 'deDE' then RANDOM_ROLL_RESULT = "%s w\195\188rfelt. Ergebnis: %d (%d-%d)" end  -- corrects roll pattern for german clients
    local pattern = string.gsub(RANDOM_ROLL_RESULT, "[%(%)-]", "%%%1")
    pattern = string.gsub(pattern, "%%s", "(.+)")
    pattern = string.gsub(pattern, "%%d", "%(%%d+%)")

    for name, roll, low, high in string.gmatch(arg1, pattern) do
      local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), name)
      local minRoll;
          local maxRoll;

          if core.DB.modes.rolls.UsePerc then
            if core.DB.modes.rolls.min == 0 or core.DB.modes.rolls.min == 1 then
              minRoll = 1;
            else
              minRoll = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp * (core.DB.modes.rolls.min / 100);
            end
            maxRoll = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp * (core.DB.modes.rolls.max / 100) + core.DB.modes.rolls.AddToMax;
          elseif not core.DB.modes.rolls.UsePerc then
            minRoll = core.DB.modes.rolls.min;

            if core.DB.modes.rolls.max == 0 then
              maxRoll = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp + core.DB.modes.rolls.AddToMax;
            else
              maxRoll = core.DB.modes.rolls.max + core.DB.modes.rolls.AddToMax;
            end
          end
          if tonumber(minRoll) < 1 then minRoll = 1 end
          if tonumber(maxRoll) < 1 then maxRoll = 1 end
          if tonumber(low) > tonumber(minRoll) or tonumber(high) > tonumber(maxRoll) then
            SendChatMessage(L["ROLLDECLINED"].." "..math.floor(minRoll).."-"..math.floor(maxRoll)..".", "WHISPER", nil, name)
            return;
          end

          --math.floor(minRoll).."-"..math.floor(maxRoll)

      if search and mode == "Roll Based Bidding" and core.BiddingWindow.cost:GetNumber() > CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp and not core.DB.modes.SubZeroBidding and core.DB.modes.costvalue ~= "Percent" then
            SendChatMessage(L["ROLLNOTACCEPTED"].." "..CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp.." "..L["DKP"]..".", "WHISPER", nil, name)

            return;
            end

      if not CommDKP:Table_Search(Bids_Submitted, name) and search then
        if core.DB.modes.AnnounceBid and ((Bids_Submitted[1] and Bids_Submitted[1].roll < roll) or not Bids_Submitted[1]) then
          local msgTarget = "RAID";
          if core.DB.modes.AnnounceRaidWarning then
            msgTarget = "RAID_WARNING";
          end

          if not core.DB.modes.AnnounceBidName then
            SendChatMessage(L["NEWHIGHROLL"].." "..roll.." ("..low.."-"..high..")", msgTarget)
          else
            SendChatMessage(L["NEWHIGHROLLER"].." "..name..": "..roll.." ("..low.."-"..high..")", msgTarget)
          end
        end
        table.insert(Bids_Submitted, {player=name, roll=roll, range=" ("..low.."-"..high..")"})
        if core.DB.modes.BroadcastBids then
          CommDKP.Sync:SendData("CommDKPBidShare", Bids_Submitted)
        end
      else
        if not search then
          SendChatMessage(L["NAMENOTFOUND"], "WHISPER", nil, name)
        else
          SendChatMessage(L["ONLYONEROLLWARN"], "WHISPER", nil, name)
        end
      end
      CommDKP:BidScrollFrame_Update()
    end
  end
end

local function BidCmd(...)
  local _, cmd = string.split(" ", ..., 2)

  if tonumber(cmd) then
    cmd = tonumber(cmd) -- converts it to a number if it's a valid numeric string
  elseif cmd then
    cmd = cmd:trim()
  end

  return cmd;
end

function CommDKP_CHAT_MSG_WHISPER(text, ...)
  local name = ...;
  local cmd;
  local dkp;
  local seconds;
  local response = L["ERRORPROCESSING"];
  
  mode = core.DB.modes.mode;

  if string.find(name, "-") then          -- finds and removes server name from name if exists
    local dashPos = string.find(name, "-")
    name = strsub(name, 1, dashPos-1)
  end

  if string.find(text, "!bid") == 1 and core.IsOfficer == true then
    if core.BidInProgress then
      cmd = BidCmd(text)
      if (mode == "Static Item Values" and cmd ~= "cancel") or (mode == "Zero Sum" and cmd ~= "cancel" and core.DB.modes.ZeroSumBidType == "Static") then
        cmd = nil;
      end
      if cmd == "cancel" and core.DB.modes.mode ~= "Roll Based Bidding" then
        local flagCanceled = false
        for i=1, #Bids_Submitted do           -- !bid cancel will cancel their bid
          if Bids_Submitted[i] and Bids_Submitted[i].player == name then
            table.remove(Bids_Submitted, i)
            if core.DB.modes.BroadcastBids then
              CommDKP.Sync:SendData("CommDKPBidShare", Bids_Submitted)
            end
            CommDKP:BidScrollFrame_Update()
            response = L["BIDCANCELLED"]
            flagCanceled = true
            --SendChatMessage(response, "WHISPER", nil, name)
            --return;
          end
        end
        if not flagCanceled then
          response = L["NOTSUBMITTEDBID"]
        end
      elseif cmd == "cancel" and core.DB.modes.mode == "Roll Based Bidding" then
        response = L["CANTCANCELROLL"]
      end
      dkp = tonumber(CommDKP:GetPlayerDKP(name))
      if not dkp then    -- exits function if player is not on the DKP list
        SendChatMessage(L["INVALIDPLAYER"], "WHISPER", nil, name)
        return
      end

      if (tonumber(cmd) and (core.BiddingWindow.maxBid == nil or tonumber(cmd) <= core.BiddingWindow.maxBid:GetNumber() or core.BiddingWindow.maxBid:GetNumber() == 0)) or ((mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static")) and not cmd) then
        if dkp then
          if (cmd and cmd <= dkp) or (core.DB.modes.SubZeroBidding == true and dkp >= 0) or (core.DB.modes.SubZeroBidding == true and core.DB.modes.AllowNegativeBidders == true) or (mode == "Static Item Values" and dkp > 0 and (dkp > core.BiddingWindow.cost:GetNumber() or core.DB.modes.SubZeroBidding == true or core.DB.modes.costvalue == "Percent")) or ((mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") and not cmd) then
            if (cmd and core.BiddingWindow.minBid and tonumber(core.BiddingWindow.minBid:GetNumber()) <= cmd) or mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid" and cmd >= core.BiddingWindow.minBid:GetNumber()) then
              for i=1, #Bids_Submitted do           -- checks if a bid was submitted, removes last bid if it was
                if (not (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static")) and Bids_Submitted[i] and Bids_Submitted[i].player == name and Bids_Submitted[i].bid < cmd then
                  table.remove(Bids_Submitted, i)
                elseif (not (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static")) and Bids_Submitted[i] and Bids_Submitted[i].player == name and Bids_Submitted[i].bid >= cmd then
                  SendChatMessage(L["BIDEQUALORLESS"], "WHISPER", nil, name)
                  return
                end
              end
              if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
                if core.DB.modes.AnnounceBid and ((Bids_Submitted[1] and Bids_Submitted[1].bid < cmd) or not Bids_Submitted[1]) then
                  local msgTarget = "RAID";
                  if core.DB.modes.AnnounceRaidWarning then
                    msgTarget = "RAID_WARNING";
                  end

                  if not core.DB.modes.AnnounceBidName then
                    SendChatMessage(L["NEWHIGHBID"].." "..cmd.." DKP", msgTarget)
                  else
                    SendChatMessage(L["NEWHIGHBIDDER"].." "..name.." ("..cmd.." DKP)", msgTarget)
                  end
                end
                if core.DB.modes.DeclineLowerBids and Bids_Submitted[1] and cmd <= Bids_Submitted[1].bid then   -- declines bids lower than highest bid
                  response = "Bid Declined! Current highest bid is "..Bids_Submitted[1].bid;
                else
                  table.insert(Bids_Submitted, {player=name, bid=cmd})
                  response = L["YOURBIDOF"].." "..cmd.." "..L["DKPWASACCEPTED"].."."
                end
                if core.DB.modes.BroadcastBids then
                  CommDKP.Sync:SendData("CommDKPBidShare", Bids_Submitted)
                end
                if Timer ~= 0 and Timer > (core.BiddingWindow.bidTimer:GetText() - 10) and core.DB.modes.AntiSnipe > 0 then
                  seconds = core.BiddingWindow.bidTimer:GetText().."{"..core.DB.modes.AntiSnipe
                  if core.BiddingWindow.maxBid:GetNumber() ~= 0 then
                    CommDKP:BroadcastBidTimer(seconds, core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText().." Max Bid: "..core.BiddingWindow.maxBid:GetText(), core.BiddingWindow.itemIcon:GetTexture());
                  else
                    CommDKP:BroadcastBidTimer(seconds, core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText(), core.BiddingWindow.itemIcon:GetTexture());
                  end
                end
              elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
                if core.DB.modes.AnnounceBid and ((Bids_Submitted[1] and Bids_Submitted[1].dkp < dkp) or not Bids_Submitted[1]) then
                  local msgTarget = "RAID";
                  if core.DB.modes.AnnounceRaidWarning then
                    msgTarget = "RAID_WARNING";
                  end

                  if not core.DB.modes.AnnounceBidName then
                    SendChatMessage(L["NEWHIGHBID"].." "..dkp.." DKP", msgTarget)
                  else
                    SendChatMessage(L["NEWHIGHBIDDER"].." "..name.." ("..dkp.." DKP)", msgTarget)
                  end
                end
                table.insert(Bids_Submitted, {player=name, dkp=dkp})
                if core.DB.modes.BroadcastBids then
                  CommDKP.Sync:SendData("CommDKPBidShare", Bids_Submitted)
                end
                response = L["BIDWASACCEPTED"]

                if Timer ~= 0 and Timer > (core.BiddingWindow.bidTimer:GetText() - 10) and core.DB.modes.AntiSnipe > 0 then
                  seconds = core.BiddingWindow.bidTimer:GetText().."{"..core.DB.modes.AntiSnipe
                  CommDKP:BroadcastBidTimer(seconds, core.BiddingWindow.item:GetText().." Extended", core.BiddingWindow.itemIcon:GetTexture());
                end
              end
              CommDKP:BidScrollFrame_Update()
            else
              response = L["BIDDENIEDMINBID"].." "..core.BiddingWindow.minBid:GetNumber().."!"
            end
          elseif core.DB.modes.SubZeroBidding == true and dkp < 0 then
            response = L["BIDDENIEDNEGATIVE"].." ("..dkp.." "..L["DKP"]..")."
          else
            response = L["BIDDENIEDONLYHAVE"].." "..dkp.." "..L["DKP"]
          end
        end
      elseif not cmd and (mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid")) then
        response = L["BIDDENIEDNOVALUE"]
      elseif cmd ~= "cancel" and (tonumber(cmd) and tonumber(cmd) > core.BiddingWindow.maxBid:GetNumber()) then
        response = L["BIDDENIEDEXCEEDMAX"].." "..core.BiddingWindow.maxBid:GetNumber().." "..L["DKP"].."."
      else
        if cmd ~= "cancel" then
          response = L["BIDDENIEDINVALID"]
        end
      end
      SendChatMessage(response, "WHISPER", nil, name)
    else
      SendChatMessage(L["NOBIDINPROGRESS"], "WHISPER", nil, name)
    end
  elseif string.find(text, "!dkp") == 1 and core.IsOfficer == true then
    cmd = tostring(BidCmd(text))

    if cmd and cmd:gsub("%d+", "") == "" then
      return CommDKP_CHAT_MSG_WHISPER("!bid "..cmd, name)
    elseif cmd and cmd:gsub("%s+", "") ~= "nil" and cmd:gsub("%s+", "") ~= "" then    -- allows command if it has content (removes empty spaces)
      cmd = cmd:gsub("%s+", "") -- removes unintended spaces from string
      CommDKP:WhisperAvailableDKP(name, cmd);
      return;
    else
      CommDKP:WhisperAvailableDKP(name);
      return;
    end

    SendChatMessage(response, "WHISPER", nil, name)
  end


end

function CommDKP:WhisperAvailableDKP(name, cmd)
  local cmd = cmd or name;
  
  local teams = CommDKP:GetGuildTeamList(true);
  local response = "";
  local playerFound = false;
  local currentTeam = CommDKP:GetCurrentTeamIndex();

  for k, v in pairs(teams) do
    local teamIndex = tostring(v.index);
    local team = v
    local minimum;
    local maximum;
    local range = "";
    local perc = "";

    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex), cmd, "player")

    if search and not playerFound then
      -- CommunityDKP: Kyliee
      local playerResponse = "CommunityDKP: "..CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]].player;
      SendChatMessage(playerResponse, "WHISPER", nil, name)
      playerFound = true;
    end

    if core.DB.modes.mode == "Roll Based Bidding" and search then
      if core.DB.modes.rolls.UsePerc then
        if core.DB.modes.rolls.min == 0 then
          minimum = 1;
        else
          minimum = CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]].dkp * (core.DB.modes.rolls.min / 100);
        end
        perc = " ("..core.DB.modes.rolls.min.."% - "..core.DB.modes.rolls.max.."%)";
        maximum = CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]].dkp * (core.DB.modes.rolls.max / 100) + core.DB.modes.rolls.AddToMax;
      elseif not core.DB.modes.rolls.UsePerc then
        minimum = core.DB.modes.rolls.min;

        if core.DB.modes.rolls.max == 0 then
          maximum = CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]].dkp + core.DB.modes.rolls.AddToMax;
        else
          maximum = core.DB.modes.rolls.max + core.DB.modes.rolls.AddToMax;
        end
        if maximum < 0 then maximum = 0 end
        if minimum < 0 then minimum = 0 end
      end

      range = range.." "..L["USE"].." /random "..CommDKP_round(minimum, 0).."-"..CommDKP_round(maximum, 0).." "..L["TOBID"].." "..perc..".";
    end

    if search and playerFound then
      -- [Laughing Jester Tavern] 213 DKP Available
      -- [The Red Hand] 123 DKP Available
      response = "["..team.name.."] "..CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]].dkp.." "..L["DKPAVAILABLE"];
      SendChatMessage(response, "WHISPER", nil, name)
      if teamIndex == currentTeam then
        if name == cmd then
          SendChatMessage(range, "WHISPER", nil, name)
        end
      end
    end
  end
  if not playerFound then
    response = "CommunityDKP: "..L["PLAYERNOTFOUND"]
    SendChatMessage(response, "WHISPER", nil, name)
  end
  return;
end

function CommDKP:GetItemPrice(itemLink)
  if CommDKPApi.pricelist == nil then
    return nil
  end

  return CommDKPApi.pricelist:GetItemPrice(itemLink)
end

function CommDKP:GetItemLocBid(from, itemLink)
  local _,_,_,_,_,_,_,_,loc = GetItemInfo(itemLink);

  if loc == "INVTYPE_HEAD" then
    return from.Head
  elseif loc == "INVTYPE_NECK" then
    return from.Neck
  elseif loc == "INVTYPE_SHOULDER" then
    return from.Shoulders
  elseif loc == "INVTYPE_CLOAK" then
    return from.Cloak
  elseif loc == "INVTYPE_CHEST" or loc == "INVTYPE_ROBE" then
    return from.Chest
  elseif loc == "INVTYPE_WRIST" then
    return from.Bracers
  elseif loc == "INVTYPE_HAND" then
    return from.Hands
  elseif loc == "INVTYPE_WAIST" then
    return from.Belt
  elseif loc == "INVTYPE_LEGS" then
    return from.Legs
  elseif loc == "INVTYPE_FEET" then
    return from.Boots
  elseif loc == "INVTYPE_FINGER" then
    return from.Ring
  elseif loc == "INVTYPE_TRINKET" then
    return from.Trinket
  elseif loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONMAINHAND" or loc == "INVTYPE_WEAPONOFFHAND" then
    return from.OneHanded
  elseif loc == "INVTYPE_2HWEAPON" then
    return from.TwoHanded
  elseif loc == "INVTYPE_HOLDABLE" or loc == "INVTYPE_SHIELD" then
    return from.OffHand
  elseif loc == "INVTYPE_RANGED" or loc == "INVTYPE_THROWN" or loc == "INVTYPE_RANGEDRIGHT" or loc == "INVTYPE_RELIC" then
    return from.Range
  else
    return from.Other
  end
end

function CommDKP:GetMinBid(itemLink)
  local itemPrice = CommDKP:GetItemPrice(itemLink);
  if itemPrice then
    return itemPrice.minBid
  end

  return CommDKP:GetItemLocBid(core.DB.MinBidBySlot, itemLink)
end

function CommDKP:GetMaxBid(itemLink)
  local itemPrice = CommDKP:GetItemPrice(itemLink);
  if itemPrice then
    return itemPrice.maxBid
  end

  return CommDKP:GetItemLocBid(core.DB.MaxBidBySlot, itemLink)
end

function CommDKP:ToggleBidWindow(loot, lootIcon, itemName)
  local minBid, maxBid, itemID;

  mode = core.DB.modes.mode;

  if core.IsOfficer then
    if core.BiddingWindow == nil then
      print("Bidding Window is Nil")
    end

    core.BiddingWindow = core.BiddingWindow or CommDKP:CreateBidWindow();

    if core.DB.bidpos then
       core.BiddingWindow:ClearAllPoints()
      local a = core.DB.bidpos
      core.BiddingWindow:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
    end

    core.BiddingWindow:SetShown(true)
    core.BiddingWindow:SetFrameLevel(10)

    if core.DB.modes.mode == "Zero Sum" then
      core.ZeroSumBank = core.ZeroSumBank or CommDKP:ZeroSumBank_Create()
      core.ZeroSumBank:SetShown(true)
      core.ZeroSumBank:SetFrameLevel(10)

      CommDKP:ZeroSumBank_Update();
    end

    if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
    if CommDKP.UIConfig then CommDKP.UIConfig:SetFrameLevel(2) end

    if loot then
      _, _, _, _, itemID, _, _, _, _, _, _, _, _, _ = string.find(loot,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
       Bids_Submitted = {}
      if core.DB.modes.BroadcastBids then
        CommDKP.Sync:SendData("CommDKPBidShare", Bids_Submitted)
      end

      CurrItemForBid = loot;
      CurrItemIcon = lootIcon
      CurZone = GetRealZoneText()

      
      if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
        
        -- Max bid values
        local search_max = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_MaxBids, true), itemName)
        if search_max then
          maxBid = CommDKP:GetTable(CommDKP_MaxBids, true)[search_max[1][1]].maxbid
        else
          maxBid = CommDKP:GetMaxBid(CurrItemForBid)
        end
        
        -- search min bid value(item cost)
        local search_min = CommDKP:GetTable(CommDKP_MinBids, true)[itemID];
        if search_min then
          minBid = CommDKP:GetTable(CommDKP_MinBids, true)[itemID].minbid
        else
          minBid = CommDKP:GetMinBid(CurrItemForBid);
        end
      elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
        
        -- search min bid value(item cost)
        local search_min = CommDKP:GetTable(CommDKP_MinBids, true)[itemID];
        if search_min then
          minBid = CommDKP:GetTable(CommDKP_MinBids, true)[itemID].minbid
        else
          minBid = CommDKP:GetMinBid(CurrItemForBid);
        end
      else
        minBid = CommDKP:GetMinBid(CurrItemForBid);
        maxBid = CommDKP:GetMaxBid(CurrItemForBid);
      end
      
      if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
        core.BiddingWindow.CustomMinBid:Show();
        core.BiddingWindow.CustomMinBid:SetChecked(core.DB.defaults.CustomMinBid)
        core.BiddingWindow.CustomMinBid:SetScript("OnClick", function(self)
          if self:GetChecked() == true then
            core.BiddingWindow.minBid:SetText(CommDKP_round(minBid, core.DB.modes.rounding))
          else
            core.BiddingWindow.minBid:SetText(CommDKP:GetMinBid(CurrItemForBid))
          end
          core.DB.defaults.CustomMinBid = self:GetChecked();
        end)

        core.BiddingWindow.CustomMaxBid:Show();
        core.BiddingWindow.CustomMaxBid:SetChecked(core.DB.defaults.CustomMaxBid)
        core.BiddingWindow.CustomMaxBid:SetScript("OnClick", function(self)
          if self:GetChecked() == true then
            core.BiddingWindow.maxBid:SetText(CommDKP_round(maxBid, core.DB.modes.rounding))
          else
            local behavior = core.DB.modes.MaxBehavior
            local dkpValue = 0;

            if behavior == "Max DKP" then
                dkpValue = "MAX";
            else
              dkpValue = CommDKP_round(CommDKP:GetMaxBid(CurrItemForBid), core.DB.modes.rounding);
            end
            core.BiddingWindow.maxBid:SetText(dkpValue);
          end
          core.DB.defaults.CustomMaxBid = self:GetChecked();
        end)
      elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
        core.BiddingWindow.CustomMinBid:Show();
        core.BiddingWindow.CustomMinBid:SetChecked(core.DB.defaults.CustomMinBid)
        core.BiddingWindow.CustomMinBid:SetScript("OnClick", function(self)
          if self:GetChecked() == true then
            core.BiddingWindow.cost:SetText(CommDKP_round(minBid, core.DB.modes.rounding))
          else
            core.BiddingWindow.cost:SetText(CommDKP:GetMinBid(CurrItemForBid))
          end
          core.DB.defaults.CustomMinBid = not core.DB.defaults.CustomMinBid;
        end)
      end

      if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
        core.BiddingWindow.minBid:SetText(CommDKP_round(minBid, core.DB.modes.rounding))

        local behavior = core.DB.modes.MaxBehavior
        local dkpValue = 0;

        if not core.DB.defaults.CustomMaxBid then
          if behavior == "Max DKP" then
              dkpValue = "MAX";
          else
            dkpValue = CommDKP_round(maxBid, core.DB.modes.rounding);
          end
          core.BiddingWindow.maxBid:SetText(dkpValue);
        else
          core.BiddingWindow.maxBid:SetText(CommDKP_round(maxBid, core.DB.modes.rounding))
        end
      end

      core.BiddingWindow.cost:SetText(CommDKP_round(minBid, core.DB.modes.rounding))
      core.BiddingWindow.itemName:SetText(itemName)
      core.BiddingWindow.bidTimer:SetText(core.DB.DKPBonus.BidTimer)
      core.BiddingWindow.boss:SetText(core.LastKilledBoss)
      UpdateBidWindow()
      core.BiddingWindow.ItemTooltipButton:SetSize(core.BiddingWindow.itemIcon:GetWidth() + core.BiddingWindow.item:GetStringWidth() + 10, core.BiddingWindow.item:GetHeight());
      core.BiddingWindow.ItemTooltipButton:SetScript("OnEnter", function(self)
        ActionButton_ShowOverlayGlow(core.BiddingWindow.ItemIconButton)
        GameTooltip:SetOwner(self:GetParent(), "ANCHOR_BOTTOMRIGHT", 0, 500);
        GameTooltip:SetHyperlink(CurrItemForBid)
      end)
      core.BiddingWindow.ItemTooltipButton:SetScript("OnLeave", function(self)
        ActionButton_HideOverlayGlow(core.BiddingWindow.ItemIconButton)
        GameTooltip:Hide()
      end)
    else
      UpdateBidWindow()
    end

    CommDKP:BidScrollFrame_Update()
  else
    CommDKP:Print(L["NOPERMISSION"])
  end
end

local function StartBidding()
  local perc;
  mode = core.DB.modes.mode;
  core.BidInProgress = true;

  if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    core.BiddingWindow.cost:SetNumber(CommDKP_round(core.BiddingWindow.minBid:GetNumber(), core.DB.modes.rounding))
    if core.BiddingWindow.maxBid:GetNumber() ~= 0 then
      CommDKP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText().." Max Bid: "..core.BiddingWindow.maxBid:GetText(), CurrItemIcon)
    else
      CommDKP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText(), CurrItemIcon)
    end
    CommDKP.Sync:SendData("CommDKPCommand", "BidInfo#"..core.BiddingWindow.item:GetText().."#"..core.BiddingWindow.minBid:GetText().."#"..CurrItemIcon.."#"..core.BiddingWindow.maxBid:GetText())
    
    CommDKP:CurrItem_Set(core.BiddingWindow.item:GetText(), core.BiddingWindow.minBid:GetText(), CurrItemIcon, core.BiddingWindow.maxBid:GetText())

    if core.DB.defaults.AutoOpenBid then  -- toggles bid window if option is set to
      CommDKP:BidInterface_Toggle()
    end
    local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(CurrItemForBid,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

    local search_min = CommDKP:GetTable(CommDKP_MinBids, true)[itemID];
    local val_min = CommDKP:GetMinBid(CurrItemForBid);
    local search_max = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_MaxBids, true), core.BiddingWindow.itemName:GetText(), "item")
    local val_max = CommDKP:GetMaxBid(CurrItemForBid);

    -- Min
    if not search_min and core.BiddingWindow.minBid:GetNumber() ~= tonumber(val_min) then
      CommDKP:GetTable(CommDKP_MinBids, true)[itemID] = {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.minBid:GetNumber(), link=CurrItemForBid};
      core.BiddingWindow.CustomMinBid:SetShown(true);
      core.BiddingWindow.CustomMinBid:SetChecked(core.DB.defaults.CustomMinBid);
    elseif search_min and core.BiddingWindow.minBid:GetNumber() ~= tonumber(val_min) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
      if CommDKP:GetTable(CommDKP_MinBids, true)[itemID].minbid ~= core.BiddingWindow.minBid:GetNumber() then
        CommDKP:GetTable(CommDKP_MinBids, true)[itemID].minbid = core.BiddingWindow.minBid:GetNumber();
        core.BiddingWindow.CustomMinBid:SetShown(true);
        core.BiddingWindow.CustomMinBid:SetChecked(core.DB.defaults.CustomMinBid);
      end
    end

    if search_min and core.BiddingWindow.CustomMinBid:GetChecked() == false then
      CommDKP:GetTable(CommDKP_MinBids, true)[itemID] = {}
      core.BiddingWindow.CustomMinBid:SetShown(false);
    end

    -- Max
    if not search_max and core.BiddingWindow.maxBid:GetNumber() ~= tonumber(val_max) then
      tinsert(CommDKP:GetTable(CommDKP_MaxBids, true), {item=core.BiddingWindow.itemName:GetText(), maxbid=core.BiddingWindow.maxBid:GetNumber()})
      core.BiddingWindow.CustomMaxBid:SetShown(true);
      core.BiddingWindow.CustomMaxBid:SetChecked(core.DB.defaults.CustomMaxBid);
    elseif search_max and core.BiddingWindow.maxBid:GetNumber() ~= tonumber(val_max) and core.BiddingWindow.CustomMaxBid:GetChecked() == true then
      if CommDKP:GetTable(CommDKP_MaxBids, true)[search_max[1][1]].maxbid ~= core.BiddingWindow.maxBid:GetNumber() then
        CommDKP:GetTable(CommDKP_MaxBids, true)[search_max[1][1]].maxbid = core.BiddingWindow.maxBid:GetNumber();
        core.BiddingWindow.CustomMaxBid:SetShown(true);
        core.BiddingWindow.CustomMaxBid:SetChecked(core.DB.defaults.CustomMaxBid);
      end
    end

    if search_max and core.BiddingWindow.CustomMaxBid:GetChecked() == false then
      table.remove(CommDKP:GetTable(CommDKP_MaxBids, true), search_max[1][1])
      core.BiddingWindow.CustomMaxBid:SetShown(false);
    end
  else
    if core.DB.modes.costvalue == "Percent" then perc = "%" else perc = " DKP" end;
    CommDKP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Cost: "..core.BiddingWindow.cost:GetNumber()..perc, CurrItemIcon)
    CommDKP.Sync:SendData("CommDKPCommand", "BidInfo#"..core.BiddingWindow.item:GetText().."#"..core.BiddingWindow.cost:GetText()..perc.."#"..CurrItemIcon.."#0")
    CommDKP:BidInterface_Toggle()
    
    CommDKP:CurrItem_Set(core.BiddingWindow.item:GetText(), core.BiddingWindow.cost:GetText()..perc, CurrItemIcon, 0)
  end

  if mode == "Roll Based Bidding" then
    events:RegisterEvent("CHAT_MSG_SYSTEM")
    events:SetScript("OnEvent", Roll_OnEvent);
  end

  if CurrItemForBid then
    local channels = {};
    local channelText = "";

    if core.DB.modes.channels.raid then table.insert(channels, "/raid") end
    if core.DB.modes.channels.guild then table.insert(channels, "/guild") end
    if core.DB.modes.channels.whisper then table.insert(channels, "/whisper") end

    for i=1, #channels do
      if #channels == 1 then
        channelText = channels[i]
      else
        if i == 1 then
          channelText = channels[i];
        elseif i == #channels then
          channelText = channelText.." "..L["OR"].." "..channels[i]
        else
          channelText = channelText..", "..channels[i]
        end
      end
    end

    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      if core.BiddingWindow.maxBid:GetNumber() ~= 0 then
        SendChatMessage(L["TAKINGBIDSON"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.minBid:GetText().." "..L["DKPMINBID"].." "..core.BiddingWindow.maxBid:GetText().." "..L["DKPMAXBID"]..")", "RAID_WARNING")
      else
        SendChatMessage(L["TAKINGBIDSON"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.minBid:GetText().." "..L["DKPMINBID"]..")", "RAID_WARNING")
      end
      SendChatMessage(L["TOBIDUSE"].." "..channelText.." "..L["TOSEND"].." !bid <"..L["VALUE"].."> (ex: !bid "..core.BiddingWindow.minBid:GetText().."). "..L["OR"].." !bid cancel "..L["TOWITHDRAWBID"], "RAID_WARNING")
    elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
      SendChatMessage(L["TAKINGBIDSON"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")", "RAID_WARNING")
      SendChatMessage(L["TOBIDUSE"].." "..channelText.." "..L["TOSEND"].." !bid. "..L["OR"].." !bid cancel "..L["TOWITHDRAWBID"], "RAID_WARNING")
    elseif mode == "Roll Based Bidding" then
      SendChatMessage(L["ROLLFOR"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")", "RAID_WARNING")
      SendChatMessage(L["TOBIDROLLRANGE"].." "..channelText.." "..L["WITH"].." !dkp", "RAID_WARNING")
    end
  end
end

local function ToggleTimerBtn(self)
  mode = core.DB.modes.mode;

  if timerToggle == 0 then
    --if not IsInRaid() then CommDKP:Print("You are not in a raid.") return false end
    if (mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.minBid:GetText() == "" or core.BiddingWindow.maxBid:GetText() == "") then CommDKP:Print(L["NOMINBIDORITEM"]) return false end
    if (mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid")) and ((core.BiddingWindow.maxBid:GetNumber() ~= 0) and (core.BiddingWindow.minBid:GetNumber() > core.BiddingWindow.maxBid:GetNumber())) then CommDKP:Print(L["MAXGTMIN"]) return false end
    if (mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then CommDKP:Print(L["NOITEMORITEMCOST"]) return false end
    if mode == "Roll Based Bidding" and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then CommDKP:Print(L["NOITEMORITEMCOST"]) return false end

    timerToggle = 1;
    self:SetText(L["ENDBIDDING"])
    StartBidding()
    core.BidAuctioneer = true;
  else
    timerToggle = 0;
    core.BidInProgress = false;
    core.BidAuctioneer = false;
    self:SetText(L["STARTBIDDING"])
    SendChatMessage(L["BIDDINGCLOSED"], "RAID_WARNING")
    events:UnregisterEvent("CHAT_MSG_SYSTEM")
    CommDKP:BroadcastStopBidTimer()
  end
end

function CommDKP:ClearBidWindow()
  CurrItemForBid = "";
  CurrItemIcon = "";
  Bids_Submitted = {}
  SelectedBidder = {}
  if core.DB.modes.BroadcastBids then
    CommDKP.Sync:SendData("CommDKPBidShare", Bids_Submitted)
  end
  core.BiddingWindow.cost:SetText("")
  core.BiddingWindow.CustomMinBid:Hide();

  core.BiddingWindow.ItemTooltipButton:SetSize(0,0)
  CommDKP:BidScrollFrame_Update()
  UpdateBidWindow()
  core.BidInProgress = false;
  core.BiddingWindow.boss:SetText("")
  _G["CommDKPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
  _G["CommDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
    local pass, err = pcall(ToggleTimerBtn, self)

    if core.BiddingWindow.bidTimer then core.BiddingWindow.bidTimer:ClearFocus(); end
    if core.BiddingWindow.minBid then core.BiddingWindow.minBid:ClearFocus(); end

    if core.BiddingWindow.minBid then core.BiddingWindow.minBid:ClearFocus(); end
    core.BiddingWindow.bidTimer:ClearFocus()
    core.BiddingWindow.boss:ClearFocus()
    core.BiddingWindow.cost:ClearFocus()
    if not pass then
      core.BiddingWindow:SetShown(false)
      StaticPopupDialogs["SUGGEST_RELOAD"] = {
        text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
        button1 = L["YES"],
        button2 = L["NO"],
        OnAccept = function()
          ReloadUI();
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show ("SUGGEST_RELOAD")
    end
  end)
  timerToggle = 0;
  if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    core.BiddingWindow.minBid:SetText("")
    core.BiddingWindow.CustomMaxBid:Hide();
    core.BiddingWindow.maxBid:ClearFocus();
    core.BiddingWindow.maxBid:SetText("")
  end
  for i=1, numrows do
    core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
  end
end

function CommDKP:BroadcastBidTimer(seconds, title, itemIcon)       -- broadcasts timer and starts it natively
  local title = title;
  CommDKP.Sync:SendData("CommDKPCommand", "StartBidTimer#"..seconds.."#"..title.."#"..itemIcon)
  CommDKP:StartBidTimer(seconds, title, itemIcon)

  if strfind(seconds, "{") then
    CommDKP:Print("Bid timer extended by "..tonumber(strsub(seconds, strfind(seconds, "{")+1)).." seconds.")
  end
end

function CommDKP:BroadcastStopBidTimer()
  CommDKP.BidTimer:SetScript("OnUpdate", nil)
  CommDKP.BidTimer:Hide()
  CommDKP.Sync:SendData("CommDKPCommand", "StopBidTimer")
end

function CommDKP:StartBidTimer(seconds, title, itemIcon)
  local duration, timer, timerText, modulo, timerMinute, expiring;
  local title = title;
  local alpha = 1;
  local messageSent = { false, false, false, false, false, false }
  local audioPlayed = false;
  local extend = false;

  if tonumber(seconds) then
    timer = 0
    duration = tonumber(seconds);
  else
    if seconds ~= "seconds" then
      timer = Timer - tonumber(strsub(seconds, strfind(seconds, "{")+1))
      duration = tonumber(strsub(seconds, 1, strfind(seconds, "{")-1))          --strsub("30{10", strfind("30{10", "{")+1)
      extend = true;
    end
  end
  
  CommDKP.BidTimer = CommDKP.BidTimer or CommDKP:CreateTimer();    -- recycles bid timer frame so multiple instances aren't created
  if not extend then CommDKP.BidTimer:SetShown(not CommDKP.BidTimer:IsShown()); end          -- shows if not shown
  if core.BidInterface and core.BidInterface:IsShown() == false then CommDKP.BidTimer.OpenBid:Show() end
  CommDKP.BidTimer:SetMinMaxValues(0, duration or 20)
  CommDKP.BidTimer.timerTitle:SetText(title)
  CommDKP.BidTimer.itemIcon:SetTexture(itemIcon)
    CommDKP.BidTimer:SetAlpha(1);
    CommDKP.BidTimer:SetScale(core.DB.defaults.BidTimerSize);
  CommDKP.BidTimer:SetScript("OnMouseDown", function(self, button)
      if button == "RightButton" then
        CommDKP.BidTimer:SetAlpha(0);
        CommDKP.BidTimer:SetScale(0.1);
      end
    end)
  if title ~= nil then
    PlaySound(8959);
  end

  if core.DB.timerpos then
    local a = core.DB["timerpos"]                    -- retrieves timer's saved position from SavedVariables
    CommDKP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
  else
    CommDKP.BidTimer:SetPoint("CENTER")                      -- sets to center if no position has been saved
  end

  CommDKP.BidTimer:SetScript("OnUpdate", function(self, elapsed)
    timer = timer + elapsed
    Timer = timer;       -- stores external copy of timer for extending
    timerText = CommDKP_round(duration - timer, 1)
    if tonumber(timerText) > 60 then
      timerMinute = math.floor(tonumber(timerText) / 60, 0);
      modulo = bit.mod(tonumber(timerText), 60);
      if tonumber(modulo) < 10 then modulo = "0"..modulo end
      CommDKP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
    else
      CommDKP.BidTimer.timertext:SetText(timerText)
    end
    if duration >= 120 then
      expiring = 30;
    else
      expiring = 10;
    end
    if tonumber(timerText) < expiring then
      CommDKP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
      if alpha > 0 then
        alpha = alpha - 0.005
      elseif alpha <= 0 then
        alpha = 1
      end
    else
      CommDKP.BidTimer:SetStatusBarColor(0, 0.8, 0)
    end

    if tonumber(timerText) == 10 and messageSent[1] == false then
      if audioPlayed == false then
            PlaySound(23639);
          end
      CommDKP:Print(L["TENSECONDSTOBID"])
      messageSent[1] = true;
    end
    if tonumber(timerText) == 5 and messageSent[2] == false then
      CommDKP:Print("5")
      messageSent[2] = true;
    end
    if tonumber(timerText) == 4 and messageSent[3] == false then
      CommDKP:Print("4")
      messageSent[3] = true;
    end
    if tonumber(timerText) == 3 and messageSent[4] == false then
      CommDKP:Print("3")
      messageSent[4] = true;
    end
    if tonumber(timerText) == 2 and messageSent[5] == false then
      CommDKP:Print("2")
      messageSent[5] = true;
    end
    if tonumber(timerText) == 1 and messageSent[6] == false then
      CommDKP:Print("1")
      messageSent[6] = true;
    end
    self:SetValue(timer)
    if timer >= duration then
      if CurrItemForBid and core.BidInProgress then
        SendChatMessage(L["BIDDINGCLOSED"], "RAID_WARNING")
        events:UnregisterEvent("CHAT_MSG_SYSTEM")
      end
      core.BidInProgress = false;
      if _G["CommDKPBiddingStartBiddingButton"] then
        _G["CommDKPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
        _G["CommDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
          local pass, err = pcall(ToggleTimerBtn, self)

          if core.BiddingWindow.minBid then core.BiddingWindow.minBid:ClearFocus(); end
          core.BiddingWindow.bidTimer:ClearFocus()
          core.BiddingWindow.boss:ClearFocus()
          core.BiddingWindow.cost:ClearFocus()
          if not pass then
            core.BiddingWindow:SetShown(false)
            StaticPopupDialogs["SUGGEST_RELOAD"] = {
              text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
              button1 = L["YES"],
              button2 = L["NO"],
              OnAccept = function()
                ReloadUI();
              end,
              timeout = 0,
              whileDead = true,
              hideOnEscape = true,
              preferredIndex = 3,
            }
            StaticPopup_Show ("SUGGEST_RELOAD")
          end
        end)
        timerToggle = 0;
      end
      core.BiddingInProgress = false;
      CommDKP.BidTimer:SetScript("OnUpdate", nil)
      CommDKP.BidTimer:Hide();
      if #core.BidInterface.LootTableButtons > 0 then
        for i=1, #core.BidInterface.LootTableButtons do
          ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
        end
      end
      C_Timer.After(2, function()
        if core.BidInterface and core.BidInterface:IsShown() then
          core.BidInterface:Hide()
        end
      end)
    end
  end)
end

function CommDKP:CreateTimer()

  local f = CreateFrame("StatusBar", nil, UIParent)
  f:SetSize(300, 25)
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(18)
  f:SetBackdrop({
      bgFile   = "Interface\\ChatFrame\\ChatFrameBackground", tile = true,
    });
  f:SetBackdropColor(0, 0, 0, 0.7)
  f:SetStatusBarTexture([[Interface\TargetingFrame\UI-TargetingFrame-BarFill]])
  f:SetMovable(true);
  f:EnableMouse(true);
  f:SetScale(core.DB.defaults.BidTimerSize)
  f:RegisterForDrag("LeftButton");
  f:SetScript("OnDragStart", f.StartMoving);
  f:SetScript("OnDragStop", function()
    f:StopMovingOrSizing();
    local point, _, relativePoint ,xOff,yOff = f:GetPoint(1)
    if not core.DB.timerpos then
      core.DB.timerpos = {}
    end
    core.DB.timerpos["point"] = point;
    core.DB.timerpos["relativePoint"] = relativePoint;
    core.DB.timerpos["x"] = xOff;
    core.DB.timerpos["y"] = yOff;
  end);

  f.border = CreateFrame("Frame", nil, f);
  f.border:SetPoint("CENTER", f, "CENTER");
  f.border:SetFrameStrata("DIALOG")
  f.border:SetFrameLevel(19)
  f.border:SetSize(300, 25);
  f.border:SetBackdrop( {
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  f.border:SetBackdropColor(0,0,0,0);
  f.border:SetBackdropBorderColor(1,1,1,1)

  f.timerTitle = f:CreateFontString(nil, "OVERLAY")
  f.timerTitle:SetFontObject("CommDKPNormalOutlineLeft")
  f.timerTitle:SetWidth(270)
  f.timerTitle:SetHeight(25)
  f.timerTitle:SetTextColor(1, 1, 1, 1);
  f.timerTitle:SetPoint("LEFT", f, "LEFT", 3, 0);
  f.timerTitle:SetText(nil);

  f.timertext = f:CreateFontString(nil, "OVERLAY")
  f.timertext:SetFontObject("CommDKPSmallOutlineRight")
  f.timertext:SetTextColor(1, 1, 1, 1);
  f.timertext:SetPoint("RIGHT", f, "RIGHT", -5, 0);
  f.timertext:SetText(nil);

  f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
  f.itemIcon:SetPoint("RIGHT", f, "LEFT", 0, 0);
  f.itemIcon:SetColorTexture(0, 0, 0, 1)
  f.itemIcon:SetSize(25, 25);

  f.OpenBid = CreateFrame("Button", nil, f, "CommunityDKPButtonTemplate")
  f.OpenBid:SetPoint("RIGHT", f.itemIcon, "LEFT", -5, 0);
  f.OpenBid:SetSize(40,25)
  f.OpenBid:SetText(L["BID"]);
  f.OpenBid:GetFontString():SetTextColor(1, 1, 1, 1)
  f.OpenBid:SetNormalFontObject("CommDKPSmallCenter");
  f.OpenBid:SetHighlightFontObject("CommDKPSmallCenter");
  f.OpenBid:SetScript("OnClick", function()
    f.OpenBid:Hide()
    CommDKP:BidInterface_Toggle()
  end)
  f.OpenBid:Show()

  return f;
end

local function BidRow_OnClick(self)
  if SelectedBidder.player == strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1) then
    for i=1, numrows do
      core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
      core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
    end
    SelectedBidder = {}
  else
    for i=1, numrows do
      core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
      core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
    end
      self:SetNormalTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\ListBox-Highlight");
      self:GetNormalTexture():SetAlpha(0.7)

      if core.DB.modes.costvalue == "Percent" then
        SelectedBidder = {player=strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1), dkp=tonumber(self.Strings[3]:GetText())}
      else
        SelectedBidder = {player=strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1), bid=tonumber(self.Strings[2]:GetText())}
      end
    end
end

local function RightClickMenu(self)
  local menu;

  menu = {
    { text = L["REMOVEENTRY"], notCheckable = true, func = function()
      if Bids_Submitted[self.index].bid then
        SendChatMessage(L["YOURBIDOF"].." "..Bids_Submitted[self.index].bid.." "..L["DKP"].." "..L["MANUALLYDENIED"], "WHISPER", nil, Bids_Submitted[self.index].player)
      else
        SendChatMessage(L["YOURBID"].." "..L["MANUALLYDENIED"], "WHISPER", nil, Bids_Submitted[self.index].player)
      end
      table.remove(Bids_Submitted, self.index)
      if core.DB.modes.BroadcastBids then
        CommDKP.Sync:SendData("CommDKPBidShare", Bids_Submitted)
      end
      SelectedBidder = {}
      for i=1, #core.BiddingWindow.bidTable.Rows do
        core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
        core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
      end
      CommDKP:BidScrollFrame_Update()
    end },
  }
  EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 1);
end

local function BidWindowCreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.Strings = {}
    f:SetSize(width, height)
    f:SetHighlightTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\ListBox-Highlight");
    f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
    f:GetNormalTexture():SetAlpha(0.2)
    f:SetScript("OnClick", BidRow_OnClick)
    for i=1, 3 do
        f.Strings[i] = f:CreateFontString(nil, "OVERLAY");
        f.Strings[i]:SetTextColor(1, 1, 1, 1);
        if i==1 then
          f.Strings[i]:SetFontObject("CommDKPNormalLeft");
        else
          f.Strings[i]:SetFontObject("CommDKPNormalCenter");
        end
    end
    f.Strings[1].rowCounter = f:CreateFontString(nil, "OVERLAY");
  f.Strings[1].rowCounter:SetFontObject("CommDKPSmallOutlineLeft")
  f.Strings[1].rowCounter:SetTextColor(1, 1, 1, 0.3);
  f.Strings[1].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);

    f.Strings[1]:SetWidth((width/2)-10)
    f.Strings[2]:SetWidth(width/4)
    f.Strings[3]:SetWidth(width/4)
    f.Strings[1]:SetPoint("LEFT", f, "LEFT", 20, 0)
    f.Strings[2]:SetPoint("LEFT", f.Strings[1], "RIGHT", -9, 0)
    f.Strings[3]:SetPoint("RIGHT", 0, 0)

    f:SetScript("OnMouseDown", function(self, button)
      if button == "RightButton" then
        RightClickMenu(self)
      end
    end)

    return f
end

local function SortBidTable()             -- sorts the Loot History Table by date
  mode = core.DB.modes.mode;
  table.sort(Bids_Submitted, function(a, b)
      if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
        return a["bid"] > b["bid"]
      elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
        return a["dkp"] > b["dkp"]
      elseif mode == "Roll Based Bidding" then
        return a["roll"] > b["roll"]
      end
    end)
end

function CommDKP:BidScrollFrame_Update()
  print("Updating bidscroll");
  local numOptions = #Bids_Submitted;
  local index, row
    local offset = FauxScrollFrame_GetOffset(core.BiddingWindow.bidTable) or 0
    local rank;
    local showRows = #Bids_Submitted

    if #Bids_Submitted > numrows then
      showRows = numrows
    end

    SortBidTable()
    for i=1, numrows do
      row = core.BiddingWindow.bidTable.Rows[i]
      row:Hide()
    end
    for i=1, showRows do
        row = core.BiddingWindow.bidTable.Rows[i]
        index = offset + i
        local dkp_total = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), Bids_Submitted[i].player)
        local c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[dkp_total[1][1]].class)
        rank = CommDKP:GetGuildRank(Bids_Submitted[i].player)
        if Bids_Submitted[index] then
            row:Show()
            row.index = index
            row.Strings[1]:SetText(Bids_Submitted[i].player.." |cff666666("..rank..")|r")
            row.Strings[1]:SetTextColor(c.r, c.g, c.b, 1)
            row.Strings[1].rowCounter:SetText(index)
            if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
              row.Strings[2]:SetText(Bids_Submitted[i].bid)
              row.Strings[3]:SetText(CommDKP_round(CommDKP:GetTable(CommDKP_DKPTable, true)[dkp_total[1][1]].dkp, core.DB.modes.rounding))
            elseif mode == "Roll Based Bidding" then
              local minRoll;
              local maxRoll;

              if core.DB.modes.rolls.UsePerc then
                if core.DB.modes.rolls.min == 0 or core.DB.modes.rolls.min == 1 then
                  minRoll = 1;
                else
                  minRoll = CommDKP:GetTable(CommDKP_DKPTable, true)[dkp_total[1][1]].dkp * (core.DB.modes.rolls.min / 100);
                end
                maxRoll = CommDKP:GetTable(CommDKP_DKPTable, true)[dkp_total[1][1]].dkp * (core.DB.modes.rolls.max / 100) + core.DB.modes.rolls.AddToMax;
              elseif not core.DB.modes.rolls.UsePerc then
                minRoll = core.DB.modes.rolls.min;

                if core.DB.modes.rolls.max == 0 then
                  maxRoll = CommDKP:GetTable(CommDKP_DKPTable, true)[dkp_total[1][1]].dkp + core.DB.modes.rolls.AddToMax;
                else
                  maxRoll = core.DB.modes.rolls.max + core.DB.modes.rolls.AddToMax;
                end
              end
              if tonumber(minRoll) < 1 then minRoll = 1 end
              if tonumber(maxRoll) < 1 then maxRoll = 1 end

              row.Strings[2]:SetText(Bids_Submitted[i].roll..Bids_Submitted[i].range)
              row.Strings[3]:SetText(math.floor(minRoll).."-"..math.floor(maxRoll))
            elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
              row.Strings[3]:SetText(CommDKP_round(Bids_Submitted[i].dkp, core.DB.modes.rounding))
            end
        else
            row:Hide()
        end
    end
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      if core.DB.modes.CostSelection == "First Bidder" and Bids_Submitted[1] then
        core.BiddingWindow.cost:SetText(Bids_Submitted[1].bid)
      elseif core.DB.modes.CostSelection == "Second Bidder" then
        if Bids_Submitted[2] then
          core.BiddingWindow.cost:SetText(Bids_Submitted[2].bid)
        elseif Bids_Submitted[1] then
          core.BiddingWindow.cost:SetText(Bids_Submitted[1].bid)
        end
      elseif core.DB.modes.CostSelection == "Second Bidder or Min" then
        if Bids_Submitted[2] then
          core.BiddingWindow.cost:SetText(Bids_Submitted[2].bid)
        else
          core.BiddingWindow.cost:SetText(core.BiddingWindow.minBid:GetText())
        end
      end
  end
    --FauxScrollFrame_Update(core.BiddingWindow.bidTable, numOptions, numrows, height, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function CommDKP:CreateBidWindow()
  local f = CreateFrame("Frame", "CommDKP_BiddingWindow", UIParent, "ShadowOverlaySmallTemplate");
  mode = core.DB.modes.mode;

  f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
  f:SetSize(400, 500);
  f:SetClampedToScreen(true)
  f:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  f:SetBackdropColor(0,0,0,0.9);
  f:SetBackdropBorderColor(1,1,1,1)
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(5)
  f:SetMovable(true);
  f:EnableMouse(true);
  f:RegisterForDrag("LeftButton");
  f:SetScript("OnDragStart", f.StartMoving);
  f:SetScript("OnDragStop", function()
    f:StopMovingOrSizing();
    local point, relativeTo, relativePoint ,xOff,yOff = f:GetPoint(1)
    if not core.DB.bidpos then
      core.DB.bidpos = {}
    end
    core.DB.bidpos.point = point;
    core.DB.bidpos.relativeTo = relativeTo;
    core.DB.bidpos.relativePoint = relativePoint;
    core.DB.bidpos.x = xOff;
    core.DB.bidpos.y = yOff;
  end);
  f:SetScript("OnHide", function ()
    if core.BidInProgress then
      CommDKP:Print(L["CLOSEDBIDINPROGRESS"])
    end
  end)
  f:SetScript("OnMouseDown", function(self)
    self:SetFrameLevel(10)
    if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
    if CommDKP.UIConfig then CommDKP.UIConfig:SetFrameLevel(2) end
  end)
  tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

    -- Close Button
  f.closeContainer = CreateFrame("Frame", "CommDKPBiddingWindowCloseButtonContainer", f)
  f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
  f.closeContainer:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
  });
  f.closeContainer:SetBackdropColor(0,0,0,0.9)
  f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
  f.closeContainer:SetSize(28, 28)

  f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)

  if core.IsOfficer then
    f.bossHeader = f:CreateFontString(nil, "OVERLAY")
    f.bossHeader:SetFontObject("CommDKPLargeRight");
    f.bossHeader:SetScale(0.7)
    f.bossHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 85, -25);
    f.bossHeader:SetText(L["BOSS"]..":")

    f.boss = CreateFrame("EditBox", nil, f)
    f.boss:SetFontObject("CommDKPNormalLeft");
    f.boss:SetAutoFocus(false)
    f.boss:SetMultiLine(false)
    f.boss:SetTextInsets(10, 15, 5, 5)
    f.boss:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
    f.boss:SetBackdropColor(0,0,0,0.6)
    f.boss:SetBackdropBorderColor(1,1,1,0.6)
    f.boss:SetPoint("LEFT", f.bossHeader, "RIGHT", 9, 0);
    f.boss:SetSize(200, 28)
    f.boss:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:HighlightText(0,0)
      self:ClearFocus()
    end)
    f.boss:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
      self:HighlightText(0,0)
      self:ClearFocus()
    end)
    f.boss:SetScript("OnTabPressed", function(self)    -- clears focus on esc
      self:HighlightText(0,0)
      self:ClearFocus()
    end)


    f.itemHeader = f:CreateFontString(nil, "OVERLAY")
    f.itemHeader:SetFontObject("CommDKPLargeRight");
    f.itemHeader:SetScale(0.7)
    f.itemHeader:SetPoint("TOP", f.bossHeader, "BOTTOM", 0, -25);
    f.itemHeader:SetText(L["ITEM"]..":")

    f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);
    f.itemIcon:SetPoint("LEFT", f.itemHeader, "RIGHT", 8, 0);
    f.itemIcon:SetColorTexture(0, 0, 0, 1)
    f.itemIcon:SetSize(28, 28);

    f.ItemIconButton = CreateFrame("Button", "CommDKPBiddingItemTooltipButtonButton", f)
    f.ItemIconButton:SetPoint("TOPLEFT", f.itemIcon, "TOPLEFT", 0, 0);
    f.ItemIconButton:SetSize(28, 28);

    f.item = f:CreateFontString(nil, "OVERLAY")
    f.item:SetFontObject("CommDKPNormalLeft");
    f.item:SetPoint("LEFT", f.itemIcon, "RIGHT", 5, 2);
    f.item:SetSize(200, 28)

    f.ItemTooltipButton = CreateFrame("Button", "CommDKPBiddingItemTooltipButtonButton", f)
    f.ItemTooltipButton:SetPoint("TOPLEFT", f.itemIcon, "TOPLEFT", 0, 0);

    f.itemName = f:CreateFontString(nil, "OVERLAY")       -- hidden itemName field
    f.itemName:SetFontObject("CommDKPNormalLeft");

    f.minBidHeader = f:CreateFontString(nil, "OVERLAY")
    f.minBidHeader:SetFontObject("CommDKPLargeRight");
    f.minBidHeader:SetScale(0.7)
    f.minBidHeader:SetPoint("TOP", f.itemHeader, "BOTTOM", -30, -25);

    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      -- Min Bid
      f.minBidHeader:SetText(L["MINIMUMBID"]..": ")

      f.minBid = CreateFrame("EditBox", nil, f)
      f.minBid:SetPoint("LEFT", f.minBidHeader, "RIGHT", 8, 0)
      f.minBid:SetAutoFocus(false)
      f.minBid:SetMultiLine(false)
      f.minBid:SetSize(70, 28)
      f.minBid:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
      });
      f.minBid:SetBackdropColor(0,0,0,0.6)
      f.minBid:SetBackdropBorderColor(1,1,1,0.6)
      f.minBid:SetMaxLetters(8)
      f.minBid:SetTextColor(1, 1, 1, 1)
      f.minBid:SetFontObject("CommDKPSmallRight")
      f.minBid:SetTextInsets(10, 10, 5, 5)
      f.minBid.tooltipText = L["MINIMUMBID"];
      f.minBid.tooltipDescription = L["MINBIDTTDESC"]
      f.minBid.tooltipWarning = L["MINBIDTTWARN"]
      f.minBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:ClearFocus()
      end)
      f.minBid:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(L["MINIMUMBID"], 0.25, 0.75, 0.90, 1, true);
        GameTooltip:AddLine(L["MINBIDTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["MINBIDTTWARN"], 1.0, 0, 0, true);
        GameTooltip:AddLine(L["MINBIDTTEXT"], 1.0, 0.5, 0, true);
        GameTooltip:Show();
      end)
      f.minBid:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
    end

    f.CustomMinBid = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
    f.CustomMinBid:SetChecked(true)
    f.CustomMinBid:SetScale(0.6);
    f.CustomMinBid.text:SetText("  |cff5151de"..L["CUSTOM"].."|r");
    f.CustomMinBid.text:SetScale(1.5);
    f.CustomMinBid.text:SetFontObject("CommDKPSmallLeft")
    f.CustomMinBid.text:SetPoint("LEFT", f.CustomMinBid, "RIGHT", -10, 0)
    f.CustomMinBid:Hide();
    f.CustomMinBid:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["CUSTOMMINBID"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["CUSTOMMINBIDTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["CUSTOMMINBIDTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show();
    end)
    f.CustomMinBid:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    -- Max Bid
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      f.maxBidHeader = f:CreateFontString(nil, "OVERLAY")
      f.maxBidHeader:SetFontObject("CommDKPLargeRight");
      f.maxBidHeader:SetScale(0.7)
      f.maxBidHeader:SetPoint("TOP", f.minBidHeader, "BOTTOM", -2, -25);
      f.maxBidHeader:SetText(L["MAXIMUMBID"]..": ")

      f.maxBid = CreateFrame("EditBox", nil, f)
      f.maxBid:SetPoint("LEFT", f.maxBidHeader, "RIGHT", 8, 0)
      f.maxBid:SetAutoFocus(false)
      f.maxBid:SetMultiLine(false)
      f.maxBid:SetSize(70, 28)
      f.maxBid:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
      });
      f.maxBid:SetBackdropColor(0,0,0,0.6)
      f.maxBid:SetBackdropBorderColor(1,1,1,0.6)
      f.maxBid:SetMaxLetters(8)
      f.maxBid:SetTextColor(1, 1, 1, 1)
      f.maxBid:SetFontObject("CommDKPSmallRight")
      f.maxBid:SetTextInsets(10, 10, 5, 5)
      f.maxBid.tooltipText = L["MAXIMUMBID"];
      f.maxBid.tooltipDescription = L["MAXBIDTTDESC"]
      f.maxBid.tooltipWarning = L["MAXBIDTTWARN"]
      f.maxBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:ClearFocus()
      end)
      f.maxBid:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(L["MAXIMUMBID"], 0.25, 0.75, 0.90, 1, true);
        GameTooltip:AddLine(L["MAXBIDTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["MAXBIDTTWARN"], 1.0, 0, 0, true);
        GameTooltip:AddLine(L["MAXBIDTTEXT"], 1.0, 0.5, 0, true);
        GameTooltip:Show();
      end)
      f.maxBid:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)

    f.CustomMaxBid = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
    f.CustomMaxBid:SetChecked(core.DB.defaults.CustomMaxBid)
    f.CustomMaxBid:SetScale(0.6);
    f.CustomMaxBid.text:SetText("  |cff5151de"..L["CUSTOM"].."|r");
    f.CustomMaxBid.text:SetScale(1.5);
    f.CustomMaxBid.text:SetFontObject("CommDKPSmallLeft")
    f.CustomMaxBid.text:SetPoint("LEFT", f.CustomMaxBid, "RIGHT", -10, 0)
    f.CustomMaxBid:Hide();
    f.CustomMaxBid:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["CUSTOMMAXBID"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["CUSTOMMAXBIDTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["CUSTOMMAXBIDTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show();
    end)
    f.CustomMaxBid:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  end
    -- Bid Timer
    f.bidTimerHeader = f:CreateFontString(nil, "OVERLAY")
    f.bidTimerHeader:SetFontObject("CommDKPLargeRight");
    f.bidTimerHeader:SetScale(0.7)
  if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    f.bidTimerHeader:SetPoint("TOP", f.maxBidHeader, "BOTTOM", 13, -25);
  else
    f.bidTimerHeader:SetPoint("TOP", f.minBidHeader, "BOTTOM", 13, -25);
  end
    f.bidTimerHeader:SetText(L["BIDTIMER"]..": ")

    f.bidTimer = CreateFrame("EditBox", nil, f)
    f.bidTimer:SetPoint("LEFT", f.bidTimerHeader, "RIGHT", 8, 0)
      f.bidTimer:SetAutoFocus(false)
      f.bidTimer:SetMultiLine(false)
      f.bidTimer:SetSize(70, 28)
      f.bidTimer:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
      });
      f.bidTimer:SetBackdropColor(0,0,0,0.6)
      f.bidTimer:SetBackdropBorderColor(1,1,1,0.6)
      f.bidTimer:SetMaxLetters(4)
      f.bidTimer:SetTextColor(1, 1, 1, 1)
      f.bidTimer:SetFontObject("CommDKPSmallRight")
      f.bidTimer:SetTextInsets(10, 10, 5, 5)
      f.bidTimer.tooltipText = L["BIDTIMER"];
      f.bidTimer.tooltipDescription = L["BIDTIMERTTDESC"]
      f.bidTimer.tooltipWarning = L["BIDTIMERTTWARN"]
      f.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:ClearFocus()
      end)
      f.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:ClearFocus()
      end)
      f.bidTimer:SetScript("OnEnter", function(self)
      if (self.tooltipText) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
      end
      if (self.tooltipDescription) then
        GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
        GameTooltip:Show();
      end
      if (self.tooltipWarning) then
        GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
        GameTooltip:Show();
      end
    end)
    f.bidTimer:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    f.bidTimerFooter = f:CreateFontString(nil, "OVERLAY")
    f.bidTimerFooter:SetFontObject("CommDKPNormalLeft");
    f.bidTimerFooter:SetPoint("LEFT", f.bidTimer, "RIGHT", 5, 0);
    f.bidTimerFooter:SetText(L["SECONDS"])

    f.StartBidding = CreateFrame("Button", "CommDKPBiddingStartBiddingButton", f, "CommunityDKPButtonTemplate")
    f.StartBidding:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -100);
    f.StartBidding:SetSize(90, 25);
    f.StartBidding:SetText(L["STARTBIDDING"]);
    f.StartBidding:GetFontString():SetTextColor(1, 1, 1, 1)
    f.StartBidding:SetNormalFontObject("CommDKPSmallCenter");
    f.StartBidding:SetHighlightFontObject("CommDKPSmallCenter");
    f.StartBidding:SetScript("OnClick", function (self)
      local pass, err = pcall(ToggleTimerBtn, self)

      if f.minBid then f.minBid:ClearFocus(); end
      if f.maxBid then f.maxBid:ClearFocus(); end
      f.bidTimer:ClearFocus()
      f.boss:ClearFocus()
      f.cost:ClearFocus()
      if not pass then
        CommDKP:Print(err)
        core.BiddingWindow:SetShown(false)
        StaticPopupDialogs["SUGGEST_RELOAD"] = {
          text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            ReloadUI();
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("SUGGEST_RELOAD")
      end
    end)
    f.StartBidding:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["STARTBIDDING"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["STARTBIDDINGTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["STARTBIDDINGTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show();
    end)
    f.StartBidding:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    f.ClearBidWindow = CommDKP:CreateButton("TOP", f.StartBidding, "BOTTOM", 0, -10, L["CLEARBIDWINDOW"]);
    f.ClearBidWindow:SetSize(90,25)
    f.ClearBidWindow:SetScript("OnClick", CommDKP.ClearBidWindow)
    f.ClearBidWindow:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["CLEARBIDWINDOW"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["CLEARBIDWINDOWTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:Show();
    end)
    f.ClearBidWindow:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)


    --------------------------------------------------
    -- Bid Table
    --------------------------------------------------
      f.bidTable = CreateFrame("ScrollFrame", "CommDKP_BidWindowTable", f, "FauxScrollFrameTemplate")
      f.bidTable:SetSize(width, height*numrows+3)
    f.bidTable:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
    });
    f.bidTable:SetBackdropColor(0,0,0,0.2)
    f.bidTable:SetBackdropBorderColor(1,1,1,0.4)
      f.bidTable.ScrollBar = FauxScrollFrame_GetChildFrames(f.bidTable)
      f.bidTable.ScrollBar:Hide()
      f.bidTable.Rows = {}
      for i=1, numrows do
          f.bidTable.Rows[i] = BidWindowCreateRow(f.bidTable, i)
          if i==1 then
            f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable, "TOPLEFT", 0, -3)
          else
            f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable.Rows[i-1], "BOTTOMLEFT")
          end
      end
      f.bidTable:SetScript("OnVerticalScroll", function(self, offset)
          FauxScrollFrame_OnVerticalScroll(self, offset, height, CommDKP.BidScrollFrame_Update)
      end)

    ---------------------------------------
    -- Header Buttons
    ---------------------------------------
    local headerButtons = {}
    mode = core.DB.modes.mode;

    f.BidTable_Headers = CreateFrame("Frame", "CommDKPDKPTableHeaders", f)
    f.BidTable_Headers:SetSize(370, 22)
    f.BidTable_Headers:SetPoint("BOTTOMLEFT", f.bidTable, "TOPLEFT", 0, 1)
    f.BidTable_Headers:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
    });
    f.BidTable_Headers:SetBackdropColor(0,0,0,0.8);
    f.BidTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
    f.bidTable:SetPoint("TOP", f, "TOP", 0, -205)
    f.BidTable_Headers:Show()

    headerButtons.player = CreateFrame("Button", "$ParentButtonPlayer", f.BidTable_Headers)
    headerButtons.bid = CreateFrame("Button", "$ParentButtonBid", f.BidTable_Headers)
    headerButtons.dkp = CreateFrame("Button", "$ParentSuttonDkp", f.BidTable_Headers)

    headerButtons.player:SetPoint("LEFT", f.BidTable_Headers, "LEFT", 2, 0)
    headerButtons.bid:SetPoint("LEFT", headerButtons.player, "RIGHT", 0, 0)
    headerButtons.dkp:SetPoint("RIGHT", f.BidTable_Headers, "RIGHT", -1, 0)

    for k, v in pairs(headerButtons) do
      v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
      if k == "player" then
        if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
          v:SetSize((width/2)-1, height)
        elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
          v:SetSize((width*0.75)-1, height)
        end
      else
        if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
          v:SetSize((width/4)-1, height)
        elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
          if k == "bid" then
            v:Hide()
          else
            v:SetSize((width/4)-1, height)
          end
        end

      end
    end

    headerButtons.player.t = headerButtons.player:CreateFontString(nil, "OVERLAY")
    headerButtons.player.t:SetFontObject("CommDKPNormalLeft")
    headerButtons.player.t:SetTextColor(1, 1, 1, 1);
    headerButtons.player.t:SetPoint("LEFT", headerButtons.player, "LEFT", 20, 0);
    headerButtons.player.t:SetText(L["PLAYER"]);

    headerButtons.bid.t = headerButtons.bid:CreateFontString(nil, "OVERLAY")
    headerButtons.bid.t:SetFontObject("CommDKPNormal");
    headerButtons.bid.t:SetTextColor(1, 1, 1, 1);
    headerButtons.bid.t:SetPoint("CENTER", headerButtons.bid, "CENTER", 0, 0);

    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      headerButtons.bid.t:SetText(L["BID"]);
    elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
      headerButtons.bid.t:Hide();
    elseif mode == "Roll Based Bidding" then
      headerButtons.bid.t:SetText(L["PLAYERROLL"])
    end

    headerButtons.dkp.t = headerButtons.dkp:CreateFontString(nil, "OVERLAY")
    headerButtons.dkp.t:SetFontObject("CommDKPNormal")
    headerButtons.dkp.t:SetTextColor(1, 1, 1, 1);
    headerButtons.dkp.t:SetPoint("CENTER", headerButtons.dkp, "CENTER", 0, 0);

    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      headerButtons.dkp.t:SetText(L["TOTALDKP"]);
    elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
      headerButtons.dkp.t:SetText(L["DKP"]);
    elseif mode == "Roll Based Bidding" then
      headerButtons.dkp.t:SetText(L["EXPECTEDROLL"])
    end

      ------------------------------------
      --  AWARD ITEM
      ------------------------------------

      f.cost = CreateFrame("EditBox", nil, f)
    f.cost:SetPoint("TOPLEFT", f.bidTable, "BOTTOMLEFT", 71, -15)
      f.cost:SetAutoFocus(false)
      f.cost:SetMultiLine(false)
      f.cost:SetSize(70, 28)
      f.cost:SetTextInsets(10, 10, 5, 5)
      f.cost:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
      });
      f.cost:SetBackdropColor(0,0,0,0.6)
      f.cost:SetBackdropBorderColor(1,1,1,0.6)
      f.cost:SetMaxLetters(8)
      f.cost:SetTextColor(1, 1, 1, 1)
      f.cost:SetFontObject("CommDKPSmallRight")
      f.cost:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:ClearFocus()
      end)
      f.cost:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(L["ITEMCOST"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["ITEMCOSTTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:Show();
    end)
    f.cost:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    f.costHeader = f:CreateFontString(nil, "OVERLAY")
    f.costHeader:SetFontObject("CommDKPLargeRight");
    f.costHeader:SetScale(0.7)
    f.costHeader:SetPoint("RIGHT", f.cost, "LEFT", -7, 0);
    f.costHeader:SetText(L["ITEMCOST"]..": ")

    if core.DB.modes.costvalue == "Percent" then
      f.cost.perc = f.cost:CreateFontString(nil, "OVERLAY")
      f.cost.perc:SetFontObject("CommDKPNormalLeft");
      f.cost.perc:SetPoint("LEFT", f.cost, "RIGHT", -15, 1);
      f.cost.perc:SetText("%")
      f.cost:SetTextInsets(10, 15, 5, 5)
    end

    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      f.CustomMinBid:SetPoint("LEFT", f.minBid, "RIGHT", 10, 0);
      f.CustomMaxBid:SetPoint("LEFT", f.maxBid, "RIGHT", 10, 0);
    elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
      f.CustomMinBid:SetPoint("LEFT", f.cost, "RIGHT", 10, 0);
    end

    f.StartBidding = CommDKP:CreateButton("LEFT", f.cost, "RIGHT", 80, 0, L["AWARDITEM"]);
    f.StartBidding:SetSize(90,25)
    f.StartBidding:SetScript("OnClick", function ()  -- confirmation dialog to remove user(s)
      if SelectedBidder["player"] then
        if strlen(strtrim(core.BiddingWindow.boss:GetText(), " ")) < 1 then       -- verifies there is a boss name
          StaticPopupDialogs["VALIDATE_BOSS"] = {
            text = L["INVALIDBOSSNAME"],
            button1 = L["OK"],
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          StaticPopup_Show ("VALIDATE_BOSS")
          return;
        end

        CommDKP:AwardConfirm(SelectedBidder["player"], tonumber(f.cost:GetText()), f.boss:GetText(), core.DB.bossargs.CurrentRaidZone, CurrItemForBid)
      else
        local selected = L["PLAYERVALIDATE"];

        StaticPopupDialogs["CONFIRM_AWARD"] = {
          text = selected,
          button1 = L["OK"],
          timeout = 5,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("CONFIRM_AWARD")
      end
    end);

    f.ItemDE = CommDKP:CreateButton("LEFT", f.cost, "RIGHT", 190, 0, "DE");
    f.ItemDE:SetSize(35,25)
    f.ItemDE:SetScript("OnClick", function () 
      CommDKP:ProcessDisenchant(CurrItemForBid)
    end);

    f:SetScript("OnMouseUp", function(self)    -- clears focus on esc
      local item,_,link = GetCursorInfo();

      if item == "item" then

        local itemName,_,_,_,_,_,_,_,_,itemIcon = GetItemInfo(link)

        CurrItemForBid = link
        CurrItemIcon = itemIcon
        CommDKP:ToggleBidWindow(CurrItemForBid, CurrItemIcon, itemName)
        ClearCursor()
      end
      end)
  end

  return f;
end
