--[[
  Usage so far:  MonDKP.Sync:SendData(prefix, core.WorkingTable)  --sends table through comm channel for updates
--]]  

local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

MonDKP.Sync = LibStub("AceAddon-3.0"):NewAddon("MonDKP", "AceComm-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
--local LibCompress = LibStub:GetLi7brary("LibCompress")
--local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()

function MonDKP:ValidateSender(sender)                -- returns true if "sender" has permission to write officer notes. false if not or not found.
  local rankIndex = MonDKP:GetGuildRankIndex(sender);

  if rankIndex == 1 then             -- automatically gives permissions above all settings if player is guild leader
    return true;
  end
  if #MonDKP:GetTable(MonDKP_Whitelist) > 0 then                  -- if a whitelist exists, checks that rather than officer note permissions
    for i=1, #MonDKP:GetTable(MonDKP_Whitelist) do
      if MonDKP:GetTable(MonDKP_Whitelist)[i] == sender then
        return true;
      end
    end
    return false;
  else
    if rankIndex then
      return C_GuildInfo.GuildControlGetRankFlags(rankIndex)[12]    -- returns true/false if player can write to officer notes
    else
      return false;
    end
  end
end

-------------------------------------------------
-- Register Broadcast Prefixs
-------------------------------------------------

function MonDKP.Sync:OnEnable()
  MonDKP.Sync:RegisterComm("MonDKPDelUsers", MonDKP.Sync:OnCommReceived())      -- Broadcasts deleted users (archived users not on the DKP table)
  MonDKP.Sync:RegisterComm("MonDKPMerge", MonDKP.Sync:OnCommReceived())      -- Broadcasts 2 weeks of data from officers (for merging)
  -- Normal broadcast Prefixs
  MonDKP.Sync:RegisterComm("MonDKPDecay", MonDKP.Sync:OnCommReceived())        -- Broadcasts a weekly decay adjustment
  MonDKP.Sync:RegisterComm("MonDKPBCastMsg", MonDKP.Sync:OnCommReceived())      -- broadcasts a message that is printed as is
  MonDKP.Sync:RegisterComm("MonDKPCommand", MonDKP.Sync:OnCommReceived())      -- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
  MonDKP.Sync:RegisterComm("MonDKPLootDist", MonDKP.Sync:OnCommReceived())      -- broadcasts individual loot award to loot table
  MonDKP.Sync:RegisterComm("MonDKPDelLoot", MonDKP.Sync:OnCommReceived())      -- broadcasts deleted loot award entries
  MonDKP.Sync:RegisterComm("MonDKPDelSync", MonDKP.Sync:OnCommReceived())      -- broadcasts deleated DKP history entries
  MonDKP.Sync:RegisterComm("MonDKPDKPDist", MonDKP.Sync:OnCommReceived())      -- broadcasts individual DKP award to DKP history table
  MonDKP.Sync:RegisterComm("MonDKPMinBid", MonDKP.Sync:OnCommReceived())      -- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
  MonDKP.Sync:RegisterComm("MonDKPMaxBid", MonDKP.Sync:OnCommReceived())      -- broadcasts maximum dkp values (set in Options tab or custom values in bid window)
  MonDKP.Sync:RegisterComm("MonDKPWhitelist", MonDKP.Sync:OnCommReceived())      -- broadcasts whitelist
  MonDKP.Sync:RegisterComm("MonDKPDKPModes", MonDKP.Sync:OnCommReceived())      -- broadcasts DKP Mode settings
  MonDKP.Sync:RegisterComm("MonDKPStand", MonDKP.Sync:OnCommReceived())        -- broadcasts standby list
  MonDKP.Sync:RegisterComm("MonDKPRaidTime", MonDKP.Sync:OnCommReceived())      -- broadcasts Raid Timer Commands
  MonDKP.Sync:RegisterComm("MonDKPZSumBank", MonDKP.Sync:OnCommReceived())    -- broadcasts ZeroSum Bank
  MonDKP.Sync:RegisterComm("MonDKPQuery", MonDKP.Sync:OnCommReceived())        -- Querys guild for spec/role data
  MonDKP.Sync:RegisterComm("MonDKPBuild", MonDKP.Sync:OnCommReceived())        -- broadcasts Addon build number to inform others an update is available.
  MonDKP.Sync:RegisterComm("MonDKPTalents", MonDKP.Sync:OnCommReceived())      -- broadcasts current spec
  MonDKP.Sync:RegisterComm("MonDKPRoles", MonDKP.Sync:OnCommReceived())        -- broadcasts current role info
  MonDKP.Sync:RegisterComm("MonDKPBossLoot", MonDKP.Sync:OnCommReceived())      -- broadcast current loot table
  MonDKP.Sync:RegisterComm("MonDKPBidShare", MonDKP.Sync:OnCommReceived())      -- broadcast accepted bids
  MonDKP.Sync:RegisterComm("MonDKPBidder", MonDKP.Sync:OnCommReceived())      -- Submit bids
  MonDKP.Sync:RegisterComm("MonDKPAllTabs", MonDKP.Sync:OnCommReceived())      -- Full table broadcast
  MonDKP.Sync:RegisterComm("MonDKPSetPrice", MonDKP.Sync:OnCommReceived())      -- Set Single Item Price
  MonDKP.Sync:RegisterComm("MonDKPCurTeam", MonDKP.Sync:OnCommReceived())      -- Sets Current Raid Team
  MonDKP.Sync:RegisterComm("MonDKPTeams", MonDKP.Sync:OnCommReceived())
  --MonDKP.Sync:RegisterComm("MonDKPEditLoot", MonDKP.Sync:OnCommReceived())    -- not in use
  --MonDKP.Sync:RegisterComm("MonDKPDataSync", MonDKP.Sync:OnCommReceived())    -- not in use
  --MonDKP.Sync:RegisterComm("MonDKPDKPLogSync", MonDKP.Sync:OnCommReceived())  -- not in use
  --MonDKP.Sync:RegisterComm("MonDKPLogSync", MonDKP.Sync:OnCommReceived())    -- not in use
end

function MonDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
  if not core.Initialized or core.IsOfficer == nil then return end
  if prefix then

    local success, _objReceived = MonDKP.Sync:DeserializeStringToTable(message);

    if success then
      if prefix == "MonDKPQuery" then
        -- set remote seed
        if sender ~= UnitName("player") and _objReceived.Data ~= "start" then  -- logs seed. Used to determine if the officer has entries required.
          local DKP, Loot = strsplit(",", _objReceived.Data)
          local off1,date1 = strsplit("-", DKP)
          local off2,date2 = strsplit("-", Loot)

          if MonDKP:ValidateSender(off1) and MonDKP:ValidateSender(off2) and tonumber(date1) > core.DB.defaults.installed210 and tonumber(date2) > core.DB.defaults.installed210 then  -- send only if posting officer validates and the post was made after 2.1s installation
            local search1 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), DKP, "index")
            local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), Loot, "index")
            
            if not search1 then
              MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam).seed = DKP
            end
            if not search2 then
              MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam).seed = Loot
            end
          end
        end
        -- talents check
        local TalTrees={}; table.insert(TalTrees, {GetTalentTabInfo(1)}); table.insert(TalTrees, {GetTalentTabInfo(2)}); table.insert(TalTrees, {GetTalentTabInfo(3)}); 
        local talBuild = "("..TalTrees[1][3].."/"..TalTrees[2][3].."/"..TalTrees[3][3]..")"
        local talRole;

        table.sort(TalTrees, function(a, b)
          return a[3] > b[3]
        end)
        
        talBuild = TalTrees[1][1].." "..talBuild;
        talRole = TalTrees[1][4];
        
        MonDKP.Sync:SendData("MonDKPTalents", talBuild)
        MonDKP.Sync:SendData("MonDKPRoles", talRole)

        table.wipe(TalTrees);
        return;
      elseif prefix == "MonDKPBidder" then
        if core.BidInProgress and core.IsOfficer then
          if _objReceived.Data == "pass" then
            MonDKP:Print(sender.." has passed.")
            return
          else
            MonDKP_CHAT_MSG_WHISPER(_objReceived.Data, sender)
            return
          end
        else
          return
        end
      elseif prefix == "MonDKPTeams" then
        MonDKP:GetTable(MonDKP_DB, false)["teams"] = _objReceived.Teams
        return;
      elseif prefix == "MonDKPCurTeam" then
        MonDKP:SetCurrentTeam(_objReceived.CurrentTeam) -- this also refreshes all the tables/views/graphs
        return;
      elseif prefix == "MonDKPTalents" then
        local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), sender, "player")

        if search then
          local curSelection = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]]
          curSelection.spec = _objReceived.Data;
        end
        return
      elseif prefix == "MonDKPRoles" then
        local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), sender, "player")
        local curClass = "None";

        if search then
          local curSelection = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]]
          curClass = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].class
        
          if curClass == "WARRIOR" then
            local a,b,c = strsplit("/", _objReceived.Data)
            if strfind(_objReceived.Data, "Protection") or (tonumber(c) and tonumber(strsub(c, 1, -2)) > 15) then
              curSelection.role = L["TANK"]
            else
              curSelection.role = L["MELEEDPS"]
            end
          elseif curClass == "PALADIN" then
            if strfind(_objReceived.Data, "Protection") then
              curSelection.role = L["TANK"]
            elseif strfind(_objReceived.Data, "Holy") then
              curSelection.role = L["HEALER"]
            else
              curSelection.role = L["MELEEDPS"]
            end
          elseif curClass == "HUNTER" then
            curSelection.role = L["RANGEDPS"]
          elseif curClass == "ROGUE" then
            curSelection.role = L["MELEEDPS"]
          elseif curClass == "PRIEST" then
            if strfind(_objReceived.Data, "Shadow") then
              curSelection.role = L["CASTERDPS"]
            else
              curSelection.role = L["HEALER"]
            end
          elseif curClass == "SHAMAN" then
            if strfind(_objReceived.Data, "Restoration") then
              curSelection.role = L["HEALER"]
            elseif strfind(_objReceived.Data, "Elemental") then
              curSelection.role = L["CASTERDPS"]
            else
              curSelection.role = L["MELEEDPS"]
            end
          elseif curClass == "MAGE" then
            curSelection.role = L["CASTERDPS"]
          elseif curClass == "WARLOCK" then
            curSelection.role = L["CASTERDPS"]
          elseif curClass == "DRUID" then
            if strfind(_objReceived.Data, "Feral") then
              curSelection.role = L["TANK"]
            elseif strfind(_objReceived.Data, "Balance") then
              curSelection.role = L["CASTERDPS"]
            else
              curSelection.role = L["HEALER"]
            end
          else
            curSelection.role = L["NOROLEDETECTED"]
          end
        end
        return;
      elseif prefix == "MonDKPBuild" and sender ~= UnitName("player") then
        local LastVerCheck = time() - core.LastVerCheck;

        if LastVerCheck > 900 then             -- limits the Out of Date message from firing more than every 15 minutes 
          if tonumber(_objReceived.Data) > core.BuildNumber then
            core.LastVerCheck = time();
            MonDKP:Print(L["OUTOFDATEANNOUNCE"])
          end
        end

        if tonumber(_objReceived.Data) < core.BuildNumber then   -- returns build number if receiving party has a newer version
          MonDKP.Sync:SendData("MonDKPBuild", tostring(core.BuildNumber))
        end
        return;
      end

      ---
      -- OFFICER LEVEL DATA
      ---
      if MonDKP:ValidateSender(sender) then    -- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
        if (prefix == "MonDKPBCastMsg") and sender ~= UnitName("player") then
          MonDKP:Print(_objReceived.Data)
        elseif (prefix == "MonDKPCommand") then
          local command, arg1, arg2, arg3, arg4 = strsplit(",", _objReceived.Data);
          if sender ~= UnitName("player") then
            if command == "StartTimer" then
              MonDKP:StartTimer(arg1, arg2)
            elseif command == "StartBidTimer" then
              MonDKP:StartBidTimer(arg1, arg2, arg3)
              core.BiddingInProgress = true;
              if strfind(arg1, "{") then
                MonDKP:Print("Bid timer extended by "..tonumber(strsub(arg1, strfind(arg1, "{")+1)).." seconds.")
              end
            elseif command == "StopBidTimer" then
              if MonDKP.BidTimer then
                MonDKP.BidTimer:SetScript("OnUpdate", nil)
                MonDKP.BidTimer:Hide()
                core.BiddingInProgress = false;
              end
              if core.BidInterface and #core.BidInterface.LootTableButtons > 0 then
                for i=1, #core.BidInterface.LootTableButtons do
                  ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
                end
              end
              C_Timer.After(2, function()
                if core.BidInterface and core.BidInterface:IsShown() and not core.BiddingInProgress then
                  core.BidInterface:Hide()
                end
              end)
            elseif command == "BidInfo" then
              if not core.BidInterface then
                core.BidInterface = core.BidInterface or MonDKP:BidInterface_Create()  -- initiates bid window if it hasn't been created
              end
              if core.DB.defaults.AutoOpenBid and not core.BidInterface:IsShown() then  -- toggles bid window if option is set to
                MonDKP:BidInterface_Toggle()
              end
              local subarg1, subarg2, subarg3, subarg4 = strsplit("#", arg1);
              MonDKP:CurrItem_Set(subarg1, subarg2, subarg3, subarg4)  -- populates bid window
            end
          end
        elseif prefix == "MonDKPRaidTime" and sender ~= UnitName("player") and core.IsOfficer and MonDKP.ConfigTab2 then
          local command, args = strsplit(",", _objReceived.Data);
          if command == "start" then
            local arg1, arg2, arg3, arg4, arg5, arg6 = strsplit(" ", args, 6)

            if arg1 == "true" then arg1 = true else arg1 = false end
            if arg4 == "true" then arg4 = true else arg4 = false end
            if arg5 == "true" then arg5 = true else arg5 = false end
            if arg6 == "true" then arg6 = true else arg6 = false end

            if arg2 ~= nil then
              MonDKP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(arg2));
              core.DB.modes.increment = tonumber(arg2);
            end
            if arg3 ~= nil then
              MonDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(arg3));
              core.DB.DKPBonus.IntervalBonus = tonumber(arg3);
            end
            if arg4 ~= nil then
              MonDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(arg4);
              core.DB.DKPBonus.GiveRaidStart = arg4;
            end
            if arg5 ~= nil then
              MonDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(arg5);
              core.DB.DKPBonus.GiveRaidEnd = arg5;
            end
            if arg6 ~= nil then
              MonDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(arg6);
              core.DB.DKPBonus.IncStandby = arg6;
            end

            MonDKP:StartRaidTimer(arg1)
          elseif command == "stop" then
            MonDKP:StopRaidTimer()
          elseif strfind(command, "sync", 1) then
            local _, syncTimer, syncSecondCount, syncMinuteCount, syncAward = strsplit(" ", command, 5)
            MonDKP:StartRaidTimer(nil, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
            core.RaidInProgress = true
          end
        end

        if (sender ~= UnitName("player")) then
          if prefix == "MonDKPLootDist" or prefix == "MonDKPDKPDist" or prefix == "MonDKPDelLoot" or prefix == "MonDKPDelSync" or prefix == "MonDKPMinBid" or prefix == "MonDKPWhitelist"
          or prefix == "MonDKPDKPModes" or prefix == "MonDKPStand" or prefix == "MonDKPZSumBank" or prefix == "MonDKPBossLoot" or prefix == "MonDKPDecay" or prefix == "MonDKPDelUsers" or
          prefix == "MonDKPAllTabs" or prefix == "MonDKPBidShare" or prefix == "MonDKPMerge" or prefix == "MonDKPSetPrice" then

            if prefix == "MonDKPAllTabs" then   -- receives full table broadcast
              print("[MonolithDKP] COMMS: Full Broadcast Receive Started");

              table.sort(_objReceived.Data.Loot, function(a, b)
                return a["date"] > b["date"]
              end)

              table.sort(_objReceived.Data.DKP, function(a, b)
                return a["date"] > b["date"]
              end)

              if _objReceived.Data.MinBids ~= nil then
                table.sort(_objReceived.Data.MinBids, function(a, b)
                  return a["item"] < b["item"]
                end)
              end

              if (#MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam) > 0 and #MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam) > 0) and 
                (
                  _objReceived.Data.DKP[1].date < MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam)[1].date or 
                  _objReceived.Data.Loot[1].date < MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam)[1].date
                ) then

                local entry1 = "Loot: ".._objReceived.Data.Loot[1].loot.." |cff616ccf"..L["WONBY"].." ".._objReceived.Data.Loot[1].player.." ("..date("%b %d @ %H:%M:%S", _objReceived.Data.Loot[1].date)..") by "..strsub(_objReceived.Data.Loot[1].index, 1, strfind(_objReceived.Data.Loot[1].index, "-")-1).."|r"
                local entry2 = "DKP: |cff616ccf".._objReceived.Data.DKP[1].reason.." ("..date("%b %d @ %H:%M:%S", _objReceived.Data.DKP[1].date)..") - "..strsub(_objReceived.Data.DKP[1].index, 1, strfind(_objReceived.Data.DKP[1].index, "-")-1).."|r"

                StaticPopupDialogs["FULL_TABS_ALERT"] = {
                  text = "|CFFFF0000"..L["WARNING"].."|r: "..string.format(L["NEWERTABS1"], sender).."\n\n"..entry1.."\n\n"..entry2.."\n\n"..L["NEWERTABS2"],
                  button1 = L["YES"],
                  button2 = L["NO"],
                  OnAccept = function()
                    MonDKP:SetTable(MonDKP_DKPTable, true, _objReceived.Data.DKPTable, _objReceived.CurrentTeam);
                    MonDKP:SetTable(MonDKP_DKPHistory, true, _objReceived.Data.DKP, _objReceived.CurrentTeam);
                    MonDKP:SetTable(MonDKP_Loot, true, _objReceived.Data.Loot, _objReceived.CurrentTeam);
                    MonDKP:SetTable(MonDKP_Archive, true, _objReceived.Data.Archive, _objReceived.CurrentTeam);
                    MonDKP:SetTable(MonDKP_MinBids, true, _objReceived.Data.MinBids, _objReceived.CurrentTeam);
                    core.DB["teams"] = _objReceived.Teams;

                    MonDKP:SetCurrentTeam(_objReceived.CurrentTeam)
                    
                    MonDKP:FilterDKPTable(core.currentSort, "reset")
                    MonDKP:StatusVerify_Update()
                  end,
                  timeout = 0,
                  whileDead = true,
                  hideOnEscape = true,
                  preferredIndex = 3,
                }
                StaticPopup_Show ("FULL_TABS_ALERT")
              else
                MonDKP:SetTable(MonDKP_DKPTable, true, _objReceived.Data.DKPTable, _objReceived.CurrentTeam);
                MonDKP:SetTable(MonDKP_DKPHistory, true, _objReceived.Data.DKP, _objReceived.CurrentTeam);
                MonDKP:SetTable(MonDKP_Loot, true, _objReceived.Data.Loot, _objReceived.CurrentTeam);
                MonDKP:SetTable(MonDKP_Archive, true, _objReceived.Data.Archive, _objReceived.CurrentTeam);
                MonDKP:SetTable(MonDKP_MinBids, true, _objReceived.Data.MinBids, _objReceived.CurrentTeam);
                core.DB["teams"] = _objReceived.Teams;
                
                MonDKP:SetCurrentTeam(_objReceived.CurrentTeam)

                MonDKP:FilterDKPTable(core.currentSort, "reset")
                MonDKP:StatusVerify_Update()
              end
              print("[MonolithDKP] COMMS: Full Broadcast Receive Finished");
              return
            elseif prefix == "MonDKPMerge" then
              for i=1, #_objReceived.Data.DKP do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), _objReceived.Data.DKP[i].index, "index")

                if not search and ((MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam).DKPMeta and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam).DKPMeta < _objReceived.Data.DKP[i].date) or (not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam).DKPMeta)) then   -- prevents adding entry if this entry has already been archived
                  local players = {strsplit(",", strsub(_objReceived.Data.DKP[i].players, 1, -2))}
                  local dkp

                  if strfind(_objReceived.Data.DKP[i].dkp, "%-%d*%.?%d+%%") then
                    dkp = {strsplit(",", _objReceived.Data.DKP[i].dkp)}
                  end

                  if _objReceived.Data.DKP[i].deletes then      -- adds deletedby field to entry if the received table is a delete entry
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), _objReceived.Data.DKP[i].deletes, "index")

                    if search_del then
                      MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam)[search_del[1][1]].deletedby = _objReceived.Data.DKP[i].index
                    end
                  end
                  
                  if not _objReceived.Data.DKP[i].deletedby then
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), _objReceived.Data.DKP[i].index, "deletes")

                    if search_del then
                      _objReceived.Data.DKP[i].deletedby = MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam)[search_del[1][1]].index
                    end
                  end

                  table.insert(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), _objReceived.Data.DKP[i])

                  for j=1, #players do
                    if players[j] then
                      local findEntry = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), players[j], "player")

                      if strfind(_objReceived.Data.DKP[i].dkp, "%-%d*%.?%d+%%") then     -- handles decay entries
                        if findEntry then
                          MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].dkp + tonumber(dkp[j])
                        else
                          if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[j]] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[j]] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[j]].deleted ~= true) then
                            MonDKP_Profile_Create(players[j], tonumber(dkp[j]), nil, nil, _objReceived.CurrentTeam)
                          end
                        end
                      else
                        if findEntry then
                          MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].dkp + tonumber(_objReceived.Data.DKP[i].dkp)
                          if (tonumber(_objReceived.Data.DKP[i].dkp) > 0 and not _objReceived.Data.DKP[i].deletes) or (tonumber(_objReceived.Data.DKP[i].dkp) < 0 and _objReceived.Data.DKP[i].deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain 
                            MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].lifetime_gained = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].lifetime_gained + _objReceived.Data.DKP[i].dkp   -- NOT if it's a DKP penalty or deleteing a DKP penalty
                          end
                        else
                          if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[j]] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[j]] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[j]].deleted ~= true) then
                            local class

                            if (tonumber(_objReceived.Data.DKP[i].dkp) > 0 and not _objReceived.Data.DKP[i].deletes) or (tonumber(_objReceived.Data.DKP[i].dkp) < 0 and _objReceived.Data.DKP[i].deletes) then
                              MonDKP_Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp), tonumber(deserialized.DKP[i].dkp), nil, _objReceived.CurrentTeam)
                            else
                              MonDKP_Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp), nil, nil, _objReceived.CurrentTeam)
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end

              if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
                MonDKP:DKPHistory_Update(true)
              end

              for i=1, #_objReceived.Data.Loot do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), _objReceived.Data.Loot[i].index, "index")

                if not search and ((MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam).LootMeta and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam).LootMeta < _objReceived.Data.DKP[i].date) or (not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam).LootMeta)) then -- prevents adding entry if this entry has already been archived
                  if _objReceived.Data.Loot[i].deletes then
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), _objReceived.Data.Loot[i].deletes, "index")

                    if search_del and not MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam)[search_del[1][1]].deletedby then
                      MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam)[search_del[1][1]].deletedby = _objReceived.Data.Loot[i].index
                    end
                  end

                  if not _objReceived.Data.Loot[i].deletedby then
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), _objReceived.Data.Loot[i].index, "deletes")

                    if search_del then
                      _objReceived.Data.Loot[i].deletedby = MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam)[search_del[1][1]].index
                    end
                  end

                  table.insert(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), _objReceived.Data.Loot[i])

                  local findEntry = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), _objReceived.Data.Loot[i].player, "player")

                  if findEntry then
                    MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].dkp + _objReceived.Data.Loot[i].cost
                    MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].lifetime_spent = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[findEntry[1][1]].lifetime_spent + _objReceived.Data.Loot[i].cost
                  else
                    if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.Loot[i].player] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.Loot[i].player] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.Loot[i].player].deleted ~= true) then
                      MonDKP_Profile_Create(_objReceived.Data.Loot[i].player, _objReceived.Data.Loot[i].cost, 0, _objReceived.Data.Loot[i].cost, _objReceived.CurrentTeam)
                    end
                  end
                end
              end

              for i=1, #MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam) do
                if MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[i].class == "NONE" then
                  local search = MonDKP:Table_Search(_objReceived.Data.Profiles, MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[i].player, "player")

                  if search then
                    MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[i].class = _objReceived.Data.Profiles[search[1][1]].class
                  end
                end
              end

              MonDKP:LootHistory_Reset()
              MonDKP:LootHistory_Update(L["NOFILTER"])
              MonDKP:FilterDKPTable(core.currentSort, "reset")
              MonDKP:StatusVerify_Update()
              return
            elseif prefix == "MonDKPLootDist" then
              local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), _objReceived.Data.player, "player")
              if search then
                local DKPTable = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]]
                DKPTable.dkp = DKPTable.dkp + _objReceived.Data.cost
                DKPTable.lifetime_spent = DKPTable.lifetime_spent + _objReceived.Data.cost
              else
                if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.player] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.player] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.player].deleted ~= true) then
                  MonDKP_Profile_Create(_objReceived.Data.player, _objReceived.Data.cost, 0, _objReceived.Data.cost, _objReceived.CurrentTeam);
                end
              end
              tinsert(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), 1, _objReceived.Data)

              MonDKP:LootHistory_Reset()
              MonDKP:LootHistory_Update(L["NOFILTER"])
              MonDKP:FilterDKPTable(core.currentSort, "reset")
            elseif prefix == "MonDKPDKPDist" then
              local players = {strsplit(",", strsub(_objReceived.Data.players, 1, -2))}
              local dkp = _objReceived.Data.dkp

              tinsert(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), 1, _objReceived.Data)

              for i=1, #players do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), players[i], "player")

                if search then
                  MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].dkp + tonumber(dkp)
                  if tonumber(dkp) > 0 then
                    MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].lifetime_gained = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].lifetime_gained + tonumber(dkp)
                  end
                else
                  if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]].deleted ~= true) then
                    MonDKP_Profile_Create(players[i], tonumber(dkp), tonumber(dkp), nil, _objReceived.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                  end
                end
              end

              if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
                MonDKP:DKPHistory_Update(true)
              end
              MonDKP:FilterDKPTable(core.currentSort, "reset")
            elseif prefix == "MonDKPDecay" then
              local players = {strsplit(",", strsub(_objReceived.Data.players, 1, -2))}
              local dkp = {strsplit(",", _objReceived.Data.dkp)}

              tinsert(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), 1, _objReceived.Data)
              
              for i=1, #players do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), players[i], "player")

                if search then
                  MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].dkp + tonumber(dkp[i])
                else
                  if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]].deleted ~= true) then
                    MonDKP_Profile_Create(players[i], tonumber(dkp[i]), nil, nil, _objReceived.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                  end
                end
              end

              if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
                MonDKP:DKPHistory_Update(true)
              end
              MonDKP:FilterDKPTable(core.currentSort, "reset")
            elseif prefix == "MonDKPDelUsers" and UnitName("player") ~= sender then
              local numPlayers = 0
              local removedUsers = ""

              for i=1, #_objReceived.Data do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), _objReceived.Data[i].player, "player")

                if search and _objReceived.Data[i].deleted and _objReceived.Data[i].deleted ~= "Recovered" then
                  if (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player].edited < _objReceived.Data[i].edited) or not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player] then
                    --delete user, archive data
                    if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player] then    -- creates/adds to archive entry for user
                      MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=deserialized[i].deleted, edited=deserialized[i].edited }
                    else
                      MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player].deleted = _objReceived.Data[i].deleted
                      MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player].edited = _objReceived.Data[i].edited
                    end
                    
                    c = MonDKP:GetCColors(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].class)
                    if i==1 then
                      removedUsers = "|cff"..c.hex..MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].player.."|r"
                    else
                      removedUsers = removedUsers..", |cff"..c.hex..MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search[1][1]].player.."|r"
                    end
                    numPlayers = numPlayers + 1

                    tremove(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), search[1][1])

                    local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Standby, true, _objReceived.CurrentTeam), _objReceived.Data[i].player, "player");

                    if search2 then
                      table.remove(MonDKP:GetTable(MonDKP_Standby,true, _objReceived.CurrentTeam), search2[1][1])
                    end
                  end
                elseif not search and _objReceived.Data[i].deleted == "Recovered" then
                  if MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player] and (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player].edited == nil or MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player].edited < _objReceived.Data[i].edited) then
                    MonDKP_Profile_Create(_objReceived.Data[i].player, nil, nil, nil, _objReceived.CurrentTeam);  -- User was recovered, create/request profile as needed
                    MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player].deleted = "Recovered"
                    MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data[i].player].edited = _objReceived.Data[i].edited
                  end
                end
              end
              if numPlayers > 0 then
                MonDKP:FilterDKPTable(core.currentSort, "reset")
                MonDKP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
              end
              return
            elseif prefix == "MonDKPDelLoot" then
              local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), _objReceived.Data.deletes, "index")

              if search then
                MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam)[search[1][1]].deletedby = _objReceived.Data.index
              end

              local search_player = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), _objReceived.Data.player, "player")

              if search_player then
                MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search_player[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search_player[1][1]].dkp + _objReceived.Data.cost                  -- refund previous looter
                MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search_player[1][1]].lifetime_spent = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search_player[1][1]].lifetime_spent + _objReceived.Data.cost       -- remove from lifetime_spent
              else
                if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.player] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.player] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[_objReceived.Data.player].deleted ~= true) then
                  MonDKP_Profile_Create(_objReceived.Data.player, _objReceived.Data.cost, 0, _objReceived.Data.cost, _objReceived.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                end
              end

              table.insert(MonDKP:GetTable(MonDKP_Loot, true, _objReceived.CurrentTeam), 1, _objReceived.Data)
              MonDKP:SortLootTable()
              MonDKP:LootHistory_Reset()
              MonDKP:LootHistory_Update(L["NOFILTER"]);
              MonDKP:FilterDKPTable(core.currentSort, "reset")
            elseif prefix == "MonDKPDelSync" then
              local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), _objReceived.Data.deletes, "index")
              local players = {strsplit(",", strsub(_objReceived.Data.players, 1, -2))}   -- cuts off last "," from string to avoid creating an empty value
              local dkp, mod;

              if strfind(_objReceived.Data.dkp, "%-%d*%.?%d+%%") then     -- determines if it's a mass decay
                dkp = {strsplit(",", _objReceived.Data.dkp)}
                mod = "perc";
              else
                dkp = _objReceived.Data.dkp
                mod = "whole"
              end

              for i=1, #players do
                if mod == "perc" then
                  local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), players[i], "player")

                  if search2 then
                    MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search2[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search2[1][1]].dkp + tonumber(dkp[i])
                  else
                    if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]].deleted ~= true) then
                      MonDKP_Profile_Create(players[i], tonumber(dkp[i]), nil, nil, _objReceived.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                    end
                  end
                else
                  local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam), players[i], "player")

                  if search2 then
                    MonDKP:GetTable(MonDKP_DKPTable, true)[search2[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search2[1][1]].dkp + tonumber(dkp)

                    if tonumber(dkp) < 0 then
                      MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search2[1][1]].lifetime_gained = MonDKP:GetTable(MonDKP_DKPTable, true, _objReceived.CurrentTeam)[search2[1][1]].lifetime_gained + tonumber(dkp)
                    end
                  else
                    if not MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true, _objReceived.CurrentTeam)[players[i]].deleted ~= true) then
                      local gained;
                      if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end

                      MonDKP_Profile_Create(players[i], tonumber(dkp), gained, nil, _objReceived.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                    end
                  end
                end
              end

              if search then
                MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam)[search[1][1]].deletedby = _objReceived.Data.index;    -- adds deletedby field if the entry exists
              end

              table.insert(MonDKP:GetTable(MonDKP_DKPHistory, true, _objReceived.CurrentTeam), 1, _objReceived.Data)

              if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history then
                MonDKP:DKPHistory_Update(true)
              end
              DKPTable_Update()
            elseif prefix == "MonDKPMinBid" then
              if core.IsOfficer then
                core.DB.MinBidBySlot = _objReceived.Data[1]

                for i=1, #_objReceived.Data[2] do
                  local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam), _objReceived.Data[2][i].item)
                  if search then
                    MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam)[search[1][1]].minbid = _objReceived.Data[2][i].minbid
                    if _objReceived.Data[2][i]["link"] ~= nil then
                      MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam)[search[1][1]].link = _objReceived.Data[2][i].link
                    end
                    if _objReceived.Data[2][i]["icon"] ~= nil then
                      MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam)[search[1][1]].icon = _objReceived.Data[2][i].icon
                    end
                  else
                    table.insert(MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam), _objReceived.Data[2][i])
                  end
                end
              end
            elseif prefix == "MonDKPMaxBid" then
              if core.IsOfficer then
                core.DB.MaxBidBySlot = _objReceived.Data[1]

                for i=1, #_objReceived.Data[2] do
                  local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_MaxBids, true, _objReceived.CurrentTeam), _objReceived.Data[2][i].item)
                  if search then
                    MonDKP:GetTable(MonDKP_MaxBids, true, _objReceived.CurrentTeam)[search[1][1]].maxbid = _objReceived.Data[2][i].maxbid
                  else
                    table.insert(MonDKP:GetTable(MonDKP_MaxBids, true, _objReceived.CurrentTeam), _objReceived.Data[2][i])
                  end
                end
              end
            elseif prefix == "MonDKPWhitelist" and MonDKP:GetGuildRankIndex(UnitName("player")) > 1 then -- only applies if not GM
              MonDKP:SetTable(MonDKP_Whitelist, false, _objReceived.Data, _objReceived.CurrentTeam);
            elseif prefix == "MonDKPStand" then
              MonDKP:GetTable(MonDKP_Standby, true, _objReceived.Data, _objReceived.CurrentTeam);
            elseif prefix == "MonDKPSetPrice" then
              local mode = core.DB.modes.mode;

              if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam), itemName)
            
                if not search then
                  tinsert(MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam), _objReceived.Data)
                elseif search and cost ~= tonumber(val) then
                  MonDKP:GetTable(MonDKP_MinBids, true, _objReceived.CurrentTeam)[search[1][1]] = _objReceived.Data;
                end

                MonDKP:PriceTable_Update(0);
              end
            
            elseif prefix == "MonDKPZSumBank" then
              if core.IsOfficer then
                core.DB.modes.ZeroSumBank = _objReceived.Data;
                if core.ZeroSumBank then
                  if _objReceived.Data.balance == 0 then
                    core.ZeroSumBank.LootFrame.LootList:SetText("")
                  end
                  MonDKP:ZeroSumBank_Update()
                end
              end
            elseif prefix == "MonDKPDKPModes" then
              if (core.DB.modes.mode ~= _objReceived.Data[1].mode) or (core.DB.modes.MaxBehavior ~= _objReceived.Data[1].MaxBehavior) then
                MonDKP:Print(L["RECOMMENDRELOAD"])
              end
              core.DB.modes = _objReceived.Data[1]
              core.DB.DKPBonus = _objReceived.Data[2]
              core.DB.raiders = _objReceived.Data[3]
            elseif prefix == "MonDKPBidShare" then
              if core.BidInterface then
                MonDKP:Bids_Set(_objReceived.Data)
              end
              return
            elseif prefix == "MonDKPBossLoot" then
              local lootList = {};
              core.DB.bossargs.LastKilledBoss = _objReceived.Data.boss;
            
              for i=1, #_objReceived.Data do
                local item = Item:CreateFromItemLink(_objReceived.Data[i]);
                item:ContinueOnItemLoad(function()
                  local icon = item:GetItemIcon()
                  table.insert(lootList, {icon=icon, link=item:GetItemLink()})
                end);
              end

              MonDKP:LootTable_Set(lootList)
            end
            
          end
        end
      end
    else
      MonDKP:Print("Report the following error on Curse or Github: "..deserialized)  -- error reporting if string doesn't get deserialized correctly
    end
  end
end

function MonDKP.Sync:SendData(prefix, data, target)

  -- 2.3.0 object being sent with almost everything?
  -- the idea is to envelope the old message into another object and then decode it on receiving end
  -- that way we won't have to do too much diging in the old code
  -- expect to send everything through SendData
  local _objToSend = {
    Teams = MonDKP:GetTable(MonDKP_DB, false)["teams"],
    CurrentTeam = MonDKP:GetCurrentTeamIndex(),
    Data = nil
  } 
  

  if data == nil or data == "" then data = " " end -- just in case, to prevent disconnects due to empty/nil string AddonMessages

  --AceComm Communication doesn't work if the prefix is longer than 15.  And if sucks if you try.
  if #prefix > 15 then
    MonDKP:Print("MonolithDKP Error: Prefix ["..prefix.."] is longer than 15. Please shorten.");
    return;
  end

  _objToSend.Data = data; -- if we send table everytime we have to serialize / deserialize anyway

  -- non officers / not encoded
  if IsInGuild() then
    if prefix == "MonDKPQuery" or prefix == "MonDKPBuild" or prefix == "MonDKPTalents" or prefix == "MonDKPRoles" then
      MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "GUILD")
      return;
    elseif prefix == "MonDKPBidder" then    -- bid submissions. Keep to raid.
      MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "RAID")
      return;
    end
  end

  -- officers
  if IsInGuild() and core.IsOfficer then
    
    if prefix == "MonDKPCommand" or prefix == "MonDKPRaidTime" then
      MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "RAID")
      return;
    end

    if prefix == "MonDKPBCastMsg" then
      MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "RAID") -- changed to raid from guild
      return;
    end  

    -- encoded
    if (prefix == "MonDKPZSumBank" or prefix == "MonDKPBossLoot" or prefix == "MonDKPBidShare") then    -- Zero Sum bank/loot table/bid table data and bid submissions. Keep to raid.
      MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "RAID")
      return;
    end

    if prefix == "MonDKPAllTabs" or prefix == "MonDKPMerge" then
      if target then
        MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "WHISPER", target, "NORMAL", MonDKP_BroadcastFull_Callback, nil)
      else
        MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "GUILD", nil, "NORMAL", MonDKP_BroadcastFull_Callback, nil)
      end
      return
    end
    
    if target then
      MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "WHISPER", target)
    else
      MonDKP.Sync:SendCommMessage(prefix, MonDKP.Sync:SerializeTableToString(_objToSend), "GUILD")
    end
  end
end

function MonDKP.Sync:SerializeTableToString(data) 

  local serialized = nil;
  local packet = nil;

  if data then
    serialized = LibAceSerializer:Serialize(data); -- serializes tables to a string
  end
  
  local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    if compressed then
      packet = LibDeflate:EncodeForWoWAddonChannel(compressed)
    end
  return packet;
end

function MonDKP.Sync:DeserializeStringToTable(_string)

  if _string then
    local decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(_string))
    local success, _obj  = LibAceSerializer:Deserialize(decoded);

    return success, _obj;
  end

end