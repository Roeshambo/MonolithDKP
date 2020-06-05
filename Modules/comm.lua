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
    --if prefix ~= "MDKPProfile" then print("|cffff0000Received: "..prefix.." from "..sender.."|r") end
    if prefix == "MonDKPQuery" then
      -- set remote seed
      if sender ~= UnitName("player") and message ~= "start" then  -- logs seed. Used to determine if the officer has entries required.
        local DKP, Loot = strsplit(",", message)
        local off1,date1 = strsplit("-", DKP)
        local off2,date2 = strsplit("-", Loot)

        if MonDKP:ValidateSender(off1) and MonDKP:ValidateSender(off2) and tonumber(date1) > core.DB.defaults.installed210 and tonumber(date2) > core.DB.defaults.installed210 then  -- send only if posting officer validates and the post was made after 2.1s installation
          local search1 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true), DKP, "index")
          local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true), Loot, "index")
          
          if not search1 then
            MonDKP:GetTable(MonDKP_DKPHistory, true).seed = DKP
          end
          if not search2 then
            MonDKP:GetTable(MonDKP_Loot, true).seed = Loot
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
        if message == "pass" then
          MonDKP:Print(sender.." has passed.")
          return
        else
          MonDKP_CHAT_MSG_WHISPER(message, sender)
          return
        end
      else
        return
      end
    elseif prefix == "MonDKPTeams" then
      decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
      local success, deserialized = LibAceSerializer:Deserialize(decoded);
      if success then
        MonDKP:GetTable(MonDKP_DB, false)["teams"] = deserialized.Teams
      end
      return;
    elseif prefix == "MonDKPCurTeam" then
      MonDKP:SetCurrentTeam(message) -- this also refreshes all the tables/views/graphs
      return
    elseif prefix == "MonDKPTalents" then
      local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), sender, "player")

      if search then
        local curSelection = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]]
        curSelection.spec = message;
      end
      return
    elseif prefix == "MonDKPRoles" then
      local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), sender, "player")
      local curClass = "None";

      if search then
        local curSelection = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]]
        curClass = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].class
      
        if curClass == "WARRIOR" then
          local a,b,c = strsplit("/", message)
          if strfind(message, "Protection") or (tonumber(c) and tonumber(strsub(c, 1, -2)) > 15) then
            curSelection.role = L["TANK"]
          else
            curSelection.role = L["MELEEDPS"]
          end
        elseif curClass == "PALADIN" then
          if strfind(message, "Protection") then
            curSelection.role = L["TANK"]
          elseif strfind(message, "Holy") then
            curSelection.role = L["HEALER"]
          else
            curSelection.role = L["MELEEDPS"]
          end
        elseif curClass == "HUNTER" then
          curSelection.role = L["RANGEDPS"]
        elseif curClass == "ROGUE" then
          curSelection.role = L["MELEEDPS"]
        elseif curClass == "PRIEST" then
          if strfind(message, "Shadow") then
            curSelection.role = L["CASTERDPS"]
          else
            curSelection.role = L["HEALER"]
          end
        elseif curClass == "SHAMAN" then
          if strfind(message, "Restoration") then
            curSelection.role = L["HEALER"]
          elseif strfind(message, "Elemental") then
            curSelection.role = L["CASTERDPS"]
          else
            curSelection.role = L["MELEEDPS"]
          end
        elseif curClass == "MAGE" then
          curSelection.role = L["CASTERDPS"]
        elseif curClass == "WARLOCK" then
          curSelection.role = L["CASTERDPS"]
        elseif curClass == "DRUID" then
          if strfind(message, "Feral") then
            curSelection.role = L["TANK"]
          elseif strfind(message, "Balance") then
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
        if tonumber(message) > core.BuildNumber then
          core.LastVerCheck = time();
          MonDKP:Print(L["OUTOFDATEANNOUNCE"])
        end
      end

      if tonumber(message) < core.BuildNumber then   -- returns build number if receiving party has a newer version
        MonDKP.Sync:SendData("MonDKPBuild", tostring(core.BuildNumber))
      end
      return;
    end
    if MonDKP:ValidateSender(sender) then    -- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
      if (prefix == "MonDKPBCastMsg") and sender ~= UnitName("player") then
        MonDKP:Print(message)
      elseif (prefix == "MonDKPCommand") then
        local command, arg1, arg2, arg3, arg4 = strsplit(",", message);
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
        local command, args = strsplit(",", message);
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
          decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
          local success, deserialized = LibAceSerializer:Deserialize(decoded);
          if success then
            if prefix == "MonDKPAllTabs" then   -- receives full table broadcast
              print("[MonolithDKP] COMMS: Full Broadcast Receive Started");
              table.sort(deserialized.Loot, function(a, b)
                return a["date"] > b["date"]
              end)
              table.sort(deserialized.DKP, function(a, b)
                return a["date"] > b["date"]
              end)

              if deserialized.MinBids ~= nil then
                table.sort(deserialized.MinBids, function(a, b)
                  return a["item"] < b["item"]
                end)
              end

              if (#MonDKP:GetTable(MonDKP_DKPHistory, true) > 0 and #MonDKP:GetTable(MonDKP_Loot, true) > 0) and (deserialized.DKP[1].date < MonDKP:GetTable(MonDKP_DKPHistory, true)[1].date or deserialized.Loot[1].date < MonDKP:GetTable(MonDKP_Loot, true)[1].date) then
                local entry1 = "Loot: "..deserialized.Loot[1].loot.." |cff616ccf"..L["WONBY"].." "..deserialized.Loot[1].player.." ("..date("%b %d @ %H:%M:%S", deserialized.Loot[1].date)..") by "..strsub(deserialized.Loot[1].index, 1, strfind(deserialized.Loot[1].index, "-")-1).."|r"
                local entry2 = "DKP: |cff616ccf"..deserialized.DKP[1].reason.." ("..date("%b %d @ %H:%M:%S", deserialized.DKP[1].date)..") - "..strsub(deserialized.DKP[1].index, 1, strfind(deserialized.DKP[1].index, "-")-1).."|r"

                StaticPopupDialogs["FULL_TABS_ALERT"] = {
                  text = "|CFFFF0000"..L["WARNING"].."|r: "..string.format(L["NEWERTABS1"], sender).."\n\n"..entry1.."\n\n"..entry2.."\n\n"..L["NEWERTABS2"],
                  button1 = L["YES"],
                  button2 = L["NO"],
                  OnAccept = function()
                    MonDKP:SetTable(MonDKP_DKPTable, true, deserialized.DKPTable);
                    MonDKP:SetTable(MonDKP_DKPHistory, true, deserialized.DKP);
                    MonDKP:SetTable(MonDKP_Loot, true, deserialized.Loot);
                    MonDKP:SetTable(MonDKP_Archive, true, deserialized.Archive);
                    MonDKP:SetTable(MonDKP_MinBids, true, deserialized.MinBids);
                    core.DB["teams"] = deserialized.Teams;

                    UIDropDownMenu_SetText(MonDKP.UIConfig.TeamViewChangerDropDown, core.DB.teams[MonDKP:GetCurrentTeamIndex()].name)
                    
                    if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
                      MonDKP:DKPHistory_Update(true)
                    elseif MonDKP.ConfigTab5 and MonDKP.ConfigTab5:IsShown() then
                      MonDKP:LootHistory_Reset()
                      MonDKP:LootHistory_Update(L["NOFILTER"]);
                    elseif MonDKP.ConfigTab7 and MonDKP.ConfigTab7:IsShown() then
                      core.PriceTable	= MonDKP:GetTable(MonDKP_MinBids, true);
                      MonDKP:PriceTable_Update(0);
                    end
                    if core.ClassGraph then
                      MonDKP:ClassGraph_Update()
                    else
                      MonDKP:ClassGraph()
                    end
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
                MonDKP:SetTable(MonDKP_DKPTable, true, deserialized.DKPTable);
                MonDKP:SetTable(MonDKP_DKPHistory, true, deserialized.DKP);
                MonDKP:SetTable(MonDKP_Loot, true, deserialized.Loot);
                MonDKP:SetTable(MonDKP_Archive, true, deserialized.Archive);
                MonDKP:SetTable(MonDKP_MinBids, true, deserialized.MinBids);
                core.DB["teams"] = deserialized.Teams;
                
                UIDropDownMenu_SetText(MonDKP.UIConfig.TeamViewChangerDropDown, core.DB.teams[MonDKP:GetCurrentTeamIndex()].name)

        
                if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
                  MonDKP:DKPHistory_Update(true)
                elseif MonDKP.ConfigTab5 and MonDKP.ConfigTab5:IsShown() then
                  MonDKP:LootHistory_Reset()
                  MonDKP:LootHistory_Update(L["NOFILTER"]);
                elseif MonDKP.ConfigTab7 and MonDKP.ConfigTab7:IsShown() then
                  core.PriceTable	= MonDKP:GetTable(MonDKP_MinBids, true);
                  MonDKP:PriceTable_Update(0);
                end
                if core.ClassGraph then
                  MonDKP:ClassGraph_Update()
                else
                  MonDKP:ClassGraph()
                end
                MonDKP:FilterDKPTable(core.currentSort, "reset")
                MonDKP:StatusVerify_Update()
              end
              print("[MonolithDKP] COMMS: Full Broadcast Receive Finished");
              return
            elseif prefix == "MonDKPMerge" then
              for i=1, #deserialized.DKP do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true), deserialized.DKP[i].index, "index")

                if not search and ((MonDKP:GetTable(MonDKP_Archive, true).DKPMeta and MonDKP:GetTable(MonDKP_Archive, true).DKPMeta < deserialized.DKP[i].date) or (not MonDKP:GetTable(MonDKP_Archive, true).DKPMeta)) then   -- prevents adding entry if this entry has already been archived
                  local players = {strsplit(",", strsub(deserialized.DKP[i].players, 1, -2))}
                  local dkp

                  if strfind(deserialized.DKP[i].dkp, "%-%d*%.?%d+%%") then
                    dkp = {strsplit(",", deserialized.DKP[i].dkp)}
                  end

                  if deserialized.DKP[i].deletes then      -- adds deletedby field to entry if the received table is a delete entry
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true), deserialized.DKP[i].deletes, "index")

                    if search_del then
                      MonDKP:GetTable(MonDKP_DKPHistory, true)[search_del[1][1]].deletedby = deserialized.DKP[i].index
                    end
                  end
                  
                  if not deserialized.DKP[i].deletedby then
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true), deserialized.DKP[i].index, "deletes")

                    if search_del then
                      deserialized.DKP[i].deletedby = MonDKP:GetTable(MonDKP_DKPHistory, true)[search_del[1][1]].index
                    end
                  end

                  table.insert(MonDKP:GetTable(MonDKP_DKPHistory, true), deserialized.DKP[i])

                  for j=1, #players do
                    if players[j] then
                      local findEntry = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), players[j], "player")

                      if strfind(deserialized.DKP[i].dkp, "%-%d*%.?%d+%%") then     -- handles decay entries
                        if findEntry then
                          MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].dkp + tonumber(dkp[j])
                        else
                          if not MonDKP:GetTable(MonDKP_Archive, true)[players[j]] or (MonDKP:GetTable(MonDKP_Archive, true)[players[j]] and MonDKP:GetTable(MonDKP_Archive, true)[players[j]].deleted ~= true) then
                            MonDKP_Profile_Create(players[j], tonumber(dkp[j]))
                          end
                        end
                      else
                        if findEntry then
                          MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].dkp + tonumber(deserialized.DKP[i].dkp)
                          if (tonumber(deserialized.DKP[i].dkp) > 0 and not deserialized.DKP[i].deletes) or (tonumber(deserialized.DKP[i].dkp) < 0 and deserialized.DKP[i].deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain 
                            MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].lifetime_gained = MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].lifetime_gained + deserialized.DKP[i].dkp   -- NOT if it's a DKP penalty or deleteing a DKP penalty
                          end
                        else
                          if not MonDKP:GetTable(MonDKP_Archive, true)[players[j]] or (MonDKP:GetTable(MonDKP_Archive, true)[players[j]] and MonDKP:GetTable(MonDKP_Archive, true)[players[j]].deleted ~= true) then
                            local class

                            if (tonumber(deserialized.DKP[i].dkp) > 0 and not deserialized.DKP[i].deletes) or (tonumber(deserialized.DKP[i].dkp) < 0 and deserialized.DKP[i].deletes) then
                              MonDKP_Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp), tonumber(deserialized.DKP[i].dkp))
                            else
                              MonDKP_Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp))
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

              for i=1, #deserialized.Loot do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true), deserialized.Loot[i].index, "index")

                if not search and ((MonDKP:GetTable(MonDKP_Archive, true).LootMeta and MonDKP:GetTable(MonDKP_Archive, true).LootMeta < deserialized.DKP[i].date) or (not MonDKP:GetTable(MonDKP_Archive, true).LootMeta)) then -- prevents adding entry if this entry has already been archived
                  if deserialized.Loot[i].deletes then
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true), deserialized.Loot[i].deletes, "index")

                    if search_del and not MonDKP:GetTable(MonDKP_Loot, true)[search_del[1][1]].deletedby then
                      MonDKP:GetTable(MonDKP_Loot, true)[search_del[1][1]].deletedby = deserialized.Loot[i].index
                    end
                  end

                  if not deserialized.Loot[i].deletedby then
                    local search_del = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true), deserialized.Loot[i].index, "deletes")

                    if search_del then
                      deserialized.Loot[i].deletedby = MonDKP:GetTable(MonDKP_Loot, true)[search_del[1][1]].index
                    end
                  end

                  table.insert(MonDKP:GetTable(MonDKP_Loot, true), deserialized.Loot[i])

                  local findEntry = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), deserialized.Loot[i].player, "player")

                  if findEntry then
                    MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].dkp + deserialized.Loot[i].cost
                    MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].lifetime_spent = MonDKP:GetTable(MonDKP_DKPTable, true)[findEntry[1][1]].lifetime_spent + deserialized.Loot[i].cost
                  else
                    if not MonDKP:GetTable(MonDKP_Archive, true)[deserialized.Loot[i].player] or (MonDKP:GetTable(MonDKP_Archive, true)[deserialized.Loot[i].player] and MonDKP:GetTable(MonDKP_Archive, true)[deserialized.Loot[i].player].deleted ~= true) then
                      MonDKP_Profile_Create(deserialized.Loot[i].player, deserialized.Loot[i].cost, 0, deserialized.Loot[i].cost)
                    end
                  end
                end
              end

              for i=1, #MonDKP:GetTable(MonDKP_DKPTable, true) do
                if MonDKP:GetTable(MonDKP_DKPTable, true)[i].class == "NONE" then
                  local search = MonDKP:Table_Search(deserialized.Profiles, MonDKP:GetTable(MonDKP_DKPTable, true)[i].player, "player")

                  if search then
                    MonDKP:GetTable(MonDKP_DKPTable, true)[i].class = deserialized.Profiles[search[1][1]].class
                  end
                end
              end

              MonDKP:LootHistory_Reset()
              MonDKP:LootHistory_Update(L["NOFILTER"])
              MonDKP:FilterDKPTable(core.currentSort, "reset")
              MonDKP:StatusVerify_Update()
              return
            elseif prefix == "MonDKPLootDist" then
              local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), deserialized.player, "player")
              if search then
                local DKPTable = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]]
                DKPTable.dkp = DKPTable.dkp + deserialized.cost
                DKPTable.lifetime_spent = DKPTable.lifetime_spent + deserialized.cost
              else
                if not MonDKP:GetTable(MonDKP_Archive, true)[deserialized.player] or (MonDKP:GetTable(MonDKP_Archive, true)[deserialized.player] and MonDKP:GetTable(MonDKP_Archive, true)[deserialized.player].deleted ~= true) then
                  MonDKP_Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);
                end
              end
              tinsert(MonDKP:GetTable(MonDKP_Loot, true), 1, deserialized)

              MonDKP:LootHistory_Reset()
              MonDKP:LootHistory_Update(L["NOFILTER"])
              MonDKP:FilterDKPTable(core.currentSort, "reset")
            elseif prefix == "MonDKPDKPDist" then
              local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
              local dkp = deserialized.dkp

              tinsert(MonDKP:GetTable(MonDKP_DKPHistory, true), 1, deserialized)

              for i=1, #players do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), players[i], "player")

                if search then
                  MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].dkp + tonumber(dkp)
                  if tonumber(dkp) > 0 then
                    MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].lifetime_gained = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].lifetime_gained + tonumber(dkp)
                  end
                else
                  if not MonDKP:GetTable(MonDKP_Archive, true)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true)[players[i]].deleted ~= true) then
                    MonDKP_Profile_Create(players[i], tonumber(dkp), tonumber(dkp));  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                  end
                end
              end

              if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
                MonDKP:DKPHistory_Update(true)
              end
              MonDKP:FilterDKPTable(core.currentSort, "reset")
            elseif prefix == "MonDKPDecay" then
              local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
              local dkp = {strsplit(",", deserialized.dkp)}

              tinsert(MonDKP:GetTable(MonDKP_DKPHistory, true), 1, deserialized)
              
              for i=1, #players do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), players[i], "player")

                if search then
                  MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].dkp + tonumber(dkp[i])
                else
                  if not MonDKP:GetTable(MonDKP_Archive, true)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true)[players[i]].deleted ~= true) then
                    MonDKP_Profile_Create(players[i], tonumber(dkp[i]));  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
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

              for i=1, #deserialized do
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), deserialized[i].player, "player")

                if search and deserialized[i].deleted and deserialized[i].deleted ~= "Recovered" then
                  if (MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player] and MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player].edited < deserialized[i].edited) or not MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player] then
                    --delete user, archive data
                    if not MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player] then    -- creates/adds to archive entry for user
                      MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=deserialized[i].deleted, edited=deserialized[i].edited }
                    else
                      MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player].deleted = deserialized[i].deleted
                      MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player].edited = deserialized[i].edited
                    end
                    
                    c = MonDKP:GetCColors(MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].class)
                    if i==1 then
                      removedUsers = "|cff"..c.hex..MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].player.."|r"
                    else
                      removedUsers = removedUsers..", |cff"..c.hex..MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]].player.."|r"
                    end
                    numPlayers = numPlayers + 1

                    tremove(MonDKP:GetTable(MonDKP_DKPTable, true), search[1][1])

                    local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Standby,true), deserialized[i].player, "player");

                    if search2 then
                      table.remove(MonDKP:GetTable(MonDKP_Standby,true), search2[1][1])
                    end
                  end
                elseif not search and deserialized[i].deleted == "Recovered" then
                  if MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player] and (MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player].edited == nil or MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player].edited < deserialized[i].edited) then
                    MonDKP_Profile_Create(deserialized[i].player);  -- User was recovered, create/request profile as needed
                    MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player].deleted = "Recovered"
                    MonDKP:GetTable(MonDKP_Archive, true)[deserialized[i].player].edited = deserialized[i].edited
                  end
                end
              end
              if numPlayers > 0 then
                MonDKP:FilterDKPTable(core.currentSort, "reset")
                MonDKP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
              end
              return
            elseif prefix == "MonDKPDelLoot" then
              local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Loot, true), deserialized.deletes, "index")

              if search then
                MonDKP:GetTable(MonDKP_Loot, true)[search[1][1]].deletedby = deserialized.index
              end

              local search_player = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), deserialized.player, "player")

              if search_player then
                MonDKP:GetTable(MonDKP_DKPTable, true)[search_player[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[search_player[1][1]].dkp + deserialized.cost                  -- refund previous looter
                MonDKP:GetTable(MonDKP_DKPTable, true)[search_player[1][1]].lifetime_spent = MonDKP:GetTable(MonDKP_DKPTable, true)[search_player[1][1]].lifetime_spent + deserialized.cost       -- remove from lifetime_spent
              else
                if not MonDKP:GetTable(MonDKP_Archive, true)[deserialized.player] or (MonDKP:GetTable(MonDKP_Archive, true)[deserialized.player] and MonDKP:GetTable(MonDKP_Archive, true)[deserialized.player].deleted ~= true) then
                  MonDKP_Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                end
              end

              table.insert(MonDKP:GetTable(MonDKP_Loot, true), 1, deserialized)
              MonDKP:SortLootTable()
              MonDKP:LootHistory_Reset()
              MonDKP:LootHistory_Update(L["NOFILTER"]);
              MonDKP:FilterDKPTable(core.currentSort, "reset")
            elseif prefix == "MonDKPDelSync" then
              local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPHistory, true), deserialized.deletes, "index")
              local players = {strsplit(",", strsub(deserialized.players, 1, -2))}   -- cuts off last "," from string to avoid creating an empty value
              local dkp, mod;

              if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then     -- determines if it's a mass decay
                dkp = {strsplit(",", deserialized.dkp)}
                mod = "perc";
              else
                dkp = deserialized.dkp
                mod = "whole"
              end

              for i=1, #players do
                if mod == "perc" then
                  local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), players[i], "player")

                  if search2 then
                    MonDKP:GetTable(MonDKP_DKPTable, true)[search2[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[search2[1][1]].dkp + tonumber(dkp[i])
                  else
                    if not MonDKP:GetTable(MonDKP_Archive, true)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true)[players[i]].deleted ~= true) then
                      MonDKP_Profile_Create(players[i], tonumber(dkp[i]));  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                    end
                  end
                else
                  local search2 = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), players[i], "player")

                  if search2 then
                    MonDKP:GetTable(MonDKP_DKPTable, true)[search2[1][1]].dkp = MonDKP:GetTable(MonDKP_DKPTable, true)[search2[1][1]].dkp + tonumber(dkp)

                    if tonumber(dkp) < 0 then
                      MonDKP:GetTable(MonDKP_DKPTable, true)[search2[1][1]].lifetime_gained = MonDKP:GetTable(MonDKP_DKPTable, true)[search2[1][1]].lifetime_gained + tonumber(dkp)
                    end
                  else
                    if not MonDKP:GetTable(MonDKP_Archive, true)[players[i]] or (MonDKP:GetTable(MonDKP_Archive, true)[players[i]] and MonDKP:GetTable(MonDKP_Archive, true)[players[i]].deleted ~= true) then
                      local gained;
                      if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end

                      MonDKP_Profile_Create(players[i], tonumber(dkp), gained);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
                    end
                  end
                end
              end

              if search then
                MonDKP:GetTable(MonDKP_DKPHistory, true)[search[1][1]].deletedby = deserialized.index;    -- adds deletedby field if the entry exists
              end

              table.insert(MonDKP:GetTable(MonDKP_DKPHistory, true), 1, deserialized)

              if MonDKP.ConfigTab6 and MonDKP.ConfigTab6.history then
                MonDKP:DKPHistory_Update(true)
              end
              DKPTable_Update()
            elseif prefix == "MonDKPMinBid" then
              if core.IsOfficer then
                core.DB.MinBidBySlot = deserialized[1]

                for i=1, #deserialized[2] do
                  local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_MinBids, true), deserialized[2][i].item)
                  if search then
                    MonDKP:GetTable(MonDKP_MinBids, true)[search[1][1]].minbid = deserialized[2][i].minbid
                    if deserialized[2][i]["link"] ~= nil then
                      MonDKP:GetTable(MonDKP_MinBids, true)[search[1][1]].link = deserialized[2][i].link
                    end
                    if deserialized[2][i]["icon"] ~= nil then
                      MonDKP:GetTable(MonDKP_MinBids, true)[search[1][1]].icon = deserialized[2][i].icon
                    end
                  else
                    table.insert(MonDKP:GetTable(MonDKP_MinBids, true), deserialized[2][i])
                  end
                end
              end
            elseif prefix == "MonDKPMaxBid" then
              if core.IsOfficer then
                core.DB.MaxBidBySlot = deserialized[1]

                for i=1, #deserialized[2] do
                  local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_MaxBids, true), deserialized[2][i].item)
                  if search then
                    MonDKP:GetTable(MonDKP_MaxBids, true)[search[1][1]].maxbid = deserialized[2][i].maxbid
                  else
                    table.insert(MonDKP:GetTable(MonDKP_MaxBids, true), deserialized[2][i])
                  end
                end
              end
            elseif prefix == "MonDKPWhitelist" and MonDKP:GetGuildRankIndex(UnitName("player")) > 1 then -- only applies if not GM
              MonDKP:SetTable(MonDKP_Whitelist, false, deserialized);
            elseif prefix == "MonDKPStand" then
              MonDKP:GetTable(MonDKP_Standby,true, deserialized);
            elseif prefix == "MonDKPSetPrice" then
              local mode = core.DB.modes.mode;

              if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
                local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_MinBids, true), itemName)
            
                if not search then
                  tinsert(MonDKP:GetTable(MonDKP_MinBids, true), deserialized)
                elseif search and cost ~= tonumber(val) then
                  MonDKP:GetTable(MonDKP_MinBids, true)[search[1][1]] = deserialized;
                end

                MonDKP:PriceTable_Update(0);
              end
            
            elseif prefix == "MonDKPZSumBank" then
              if core.IsOfficer then
                core.DB.modes.ZeroSumBank = deserialized;
                if core.ZeroSumBank then
                  if deserialized.balance == 0 then
                    core.ZeroSumBank.LootFrame.LootList:SetText("")
                  end
                  MonDKP:ZeroSumBank_Update()
                end
              end
            elseif prefix == "MonDKPDKPModes" then
              if (core.DB.modes.mode ~= deserialized[1].mode) or (core.DB.modes.MaxBehavior ~= deserialized[1].MaxBehavior) then
                MonDKP:Print(L["RECOMMENDRELOAD"])
              end
              core.DB.modes = deserialized[1]
              core.DB.DKPBonus = deserialized[2]
              core.DB.raiders = deserialized[3]
            elseif prefix == "MonDKPBidShare" then
              if core.BidInterface then
                MonDKP:Bids_Set(deserialized)
              end
              return
            elseif prefix == "MonDKPBossLoot" then
              local lootList = {};
              core.DB.bossargs.LastKilledBoss = deserialized.boss;
            
              for i=1, #deserialized do
                local item = Item:CreateFromItemLink(deserialized[i]);
                item:ContinueOnItemLoad(function()
                  local icon = item:GetItemIcon()
                  table.insert(lootList, {icon=icon, link=item:GetItemLink()})
                end);
              end

              MonDKP:LootTable_Set(lootList)
            end
          else
            MonDKP:Print("Report the following error on Curse or Github: "..deserialized)  -- error reporting if string doesn't get deserialized correctly
          end
        end
      end
    end
  end
end

function MonDKP.Sync:SendData(prefix, data, target)
  --if prefix ~= "MDKPProfile" then print("|cff00ff00Sent: "..prefix.."|r") end
  if data == nil or data == "" then data = " " end -- just in case, to prevent disconnects due to empty/nil string AddonMessages

    --AceComm Communication doesn't work if the prefix is longer than 15.  And if sucks if you try.
    if #prefix > 15 then
      MonDKP:Print("MonolithDKP Error: Prefix ["..prefix.."] is longer than 15. Please shorten.");
      return;
    end

  -- non officers / not encoded
  if IsInGuild() then
    if prefix == "MonDKPQuery" or prefix == "MonDKPBuild" or prefix == "MonDKPTalents" or prefix == "MonDKPRoles" then
      MonDKP.Sync:SendCommMessage(prefix, data, "GUILD")
      return;
    elseif prefix == "MonDKPBidder" then    -- bid submissions. Keep to raid.
      MonDKP.Sync:SendCommMessage(prefix, data, "RAID")
      return;
    end
  end

  -- officers
  if IsInGuild() and core.IsOfficer then
    local serialized = nil;
    local packet = nil;

    if prefix == "MonDKPCommand" or prefix == "MonDKPRaidTime" then
      MonDKP.Sync:SendCommMessage("MonDKPCurTeam", MonDKP:GetCurrentTeamIndex(), "RAID")
      MonDKP.Sync:SendCommMessage(prefix, data, "RAID")
      return;
    end

    if prefix == "MonDKPBCastMsg" then
      MonDKP.Sync:SendCommMessage("MonDKPCurTeam", MonDKP:GetCurrentTeamIndex(), "RAID")
      MonDKP.Sync:SendCommMessage(prefix, data, "RAID") -- changed to raid from guild
      return;
    end  

    if data then
      serialized = LibAceSerializer:Serialize(data);  -- serializes tables to a string
    end

    local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    if compressed then
      packet = LibDeflate:EncodeForWoWAddonChannel(compressed)
    end

    -- encoded
    if (prefix == "MonDKPZSumBank" or prefix == "MonDKPBossLoot" or prefix == "MonDKPBidShare") then    -- Zero Sum bank/loot table/bid table data and bid submissions. Keep to raid.
      MonDKP.Sync:SendCommMessage("MonDKPCurTeam", MonDKP:GetCurrentTeamIndex(), "RAID")
      MonDKP.Sync:SendCommMessage(prefix, packet, "RAID")
      return;
    end

    if prefix == "MonDKPAllTabs" or prefix == "MonDKPMerge" then
      if target then
        MonDKP.Sync:SendCommMessage("MonDKPCurTeam", MonDKP:GetCurrentTeamIndex(), "WHISPER", target, "NORMAL", nil, nil)
        MonDKP.Sync:SendCommMessage(prefix, packet, "WHISPER", target, "NORMAL", MonDKP_BroadcastFull_Callback, nil)
      else
        MonDKP.Sync:SendCommMessage("MonDKPCurTeam", MonDKP:GetCurrentTeamIndex(), "GUILD")
        MonDKP.Sync:SendCommMessage(prefix, packet, "GUILD", nil, "NORMAL", MonDKP_BroadcastFull_Callback, nil)
      end
      return
    end
    
    if target then
      MonDKP.Sync:SendCommMessage(prefix, packet, "WHISPER", target)
    else
      MonDKP.Sync:SendCommMessage(prefix, packet, "GUILD")
    end
  end
end