--[[
  Usage so far:  CommDKP.Sync:SendData(prefix, core.WorkingTable)  --sends table through comm channel for updates
--]]  

local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

CommDKP.Sync = LibStub("AceAddon-3.0"):NewAddon("CommDKP", "AceComm-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
--local LibCompress = LibStub:GetLi7brary("LibCompress")
--local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()

function CommDKP:ValidateSender(sender)                -- returns true if "sender" has permission to write officer notes. false if not or not found.
  local rankIndex = CommDKP:GetGuildRankIndex(sender);

  if rankIndex == 1 then             -- automatically gives permissions above all settings if player is guild leader
    return true;
  end
  if #CommDKP:GetTable(CommDKP_Whitelist) > 0 then                  -- if a whitelist exists, checks that rather than officer note permissions
    for i=1, #CommDKP:GetTable(CommDKP_Whitelist) do
      if CommDKP:GetTable(CommDKP_Whitelist)[i] == sender then
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

function CommDKP.Sync:OnEnable()
  CommDKP.Sync:RegisterComm("CommDKPDelUsers", CommDKP.Sync:OnCommReceived())      -- Broadcasts deleted users (archived users not on the DKP table)
  CommDKP.Sync:RegisterComm("CommDKPAddUsers", CommDKP.Sync:OnCommReceived())   -- Broadcasts newly added users (or recovers)
  CommDKP.Sync:RegisterComm("CommDKPMerge", CommDKP.Sync:OnCommReceived())      -- Broadcasts 2 weeks of data from officers (for merging)
  -- Normal broadcast Prefixs
  CommDKP.Sync:RegisterComm("CommDKPDecay", CommDKP.Sync:OnCommReceived())        -- Broadcasts a weekly decay adjustment
  CommDKP.Sync:RegisterComm("CommDKPBCastMsg", CommDKP.Sync:OnCommReceived())      -- broadcasts a message that is printed as is
  CommDKP.Sync:RegisterComm("CommDKPCommand", CommDKP.Sync:OnCommReceived())      -- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
  CommDKP.Sync:RegisterComm("CommDKPLootDist", CommDKP.Sync:OnCommReceived())      -- broadcasts individual loot award to loot table
  CommDKP.Sync:RegisterComm("CommDKPDelLoot", CommDKP.Sync:OnCommReceived())      -- broadcasts deleted loot award entries
  CommDKP.Sync:RegisterComm("CommDKPDelSync", CommDKP.Sync:OnCommReceived())      -- broadcasts deleated DKP history entries
  CommDKP.Sync:RegisterComm("CommDKPDKPDist", CommDKP.Sync:OnCommReceived())      -- broadcasts individual DKP award to DKP history table
  CommDKP.Sync:RegisterComm("CommDKPMinBid", CommDKP.Sync:OnCommReceived())      -- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
  CommDKP.Sync:RegisterComm("CommDKPMaxBid", CommDKP.Sync:OnCommReceived())      -- broadcasts maximum dkp values (set in Options tab or custom values in bid window)
  CommDKP.Sync:RegisterComm("CDKPWhitelist", CommDKP.Sync:OnCommReceived())      -- broadcasts whitelist
  CommDKP.Sync:RegisterComm("CommDKPDKPModes", CommDKP.Sync:OnCommReceived())      -- broadcasts DKP Mode settings
  CommDKP.Sync:RegisterComm("CommDKPStand", CommDKP.Sync:OnCommReceived())        -- broadcasts standby list
  CommDKP.Sync:RegisterComm("CommDKPRaidTime", CommDKP.Sync:OnCommReceived())      -- broadcasts Raid Timer Commands
  CommDKP.Sync:RegisterComm("CommDKPZSumBank", CommDKP.Sync:OnCommReceived())    -- broadcasts ZeroSum Bank
  CommDKP.Sync:RegisterComm("CommDKPQuery", CommDKP.Sync:OnCommReceived())        -- Querys guild for spec/role data
  CommDKP.Sync:RegisterComm("CommDKPSeed", CommDKP.Sync:OnCommReceived())
  CommDKP.Sync:RegisterComm("CommDKPBuild", CommDKP.Sync:OnCommReceived())        -- broadcasts Addon build number to inform others an update is available.
  CommDKP.Sync:RegisterComm("CommDKPTalents", CommDKP.Sync:OnCommReceived())      -- broadcasts current spec
  CommDKP.Sync:RegisterComm("CommDKPRoles", CommDKP.Sync:OnCommReceived())        -- broadcasts current role info
  CommDKP.Sync:RegisterComm("CommDKPBossLoot", CommDKP.Sync:OnCommReceived())      -- broadcast current loot table
  CommDKP.Sync:RegisterComm("CommDKPBidShare", CommDKP.Sync:OnCommReceived())      -- broadcast accepted bids
  CommDKP.Sync:RegisterComm("CommDKPBidder", CommDKP.Sync:OnCommReceived())      -- Submit bids
  CommDKP.Sync:RegisterComm("CommDKPAllTabs", CommDKP.Sync:OnCommReceived())      -- Full table broadcast
  CommDKP.Sync:RegisterComm("CommDKPSetPrice", CommDKP.Sync:OnCommReceived())      -- Set Single Item Price
  CommDKP.Sync:RegisterComm("CommDKPCurTeam", CommDKP.Sync:OnCommReceived())      -- Sets Current Raid Team
  CommDKP.Sync:RegisterComm("CommDKPTeams", CommDKP.Sync:OnCommReceived())
  CommDKP.Sync:RegisterComm("CommDKPPreBroad", CommDKP.Sync:OnCommReceived()) -- send info that full broadcast is starting
  --CommDKP.Sync:RegisterComm("CommDKPEditLoot", CommDKP.Sync:OnCommReceived())    -- not in use
  --CommDKP.Sync:RegisterComm("CommDKPDataSync", CommDKP.Sync:OnCommReceived())    -- not in use
  --CommDKP.Sync:RegisterComm("CommDKPDKPLogSync", CommDKP.Sync:OnCommReceived())  -- not in use
  --CommDKP.Sync:RegisterComm("CommDKPLogSync", CommDKP.Sync:OnCommReceived())    -- not in use
  CommDKP.Sync:RegisterComm("CDKProfileSend", CommDKP.Sync:OnCommReceived()) -- Broadcast Player Profile for Update or Create
end

function GetNameFromLink(link)
  if link == nil then
    return "Item Name Not Found - Bad Link";
  end

  local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(link,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
  return Name;
end

-- main functions that receives all communication via appropriate channels
function CommDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
  
  if not core.Initialized or core.IsOfficer == nil then 
    return; 
  end

  if prefix then
    local decoded = LibDeflate:DecodeForWoWAddonChannel(message);
    local decompressed = LibDeflate:DecompressDeflate(decoded);

    if decompressed == nil then  -- this checks if message was previously encoded and compressed, only case we allow this is CommDKPBuild
      CommDKP:Print("Unknown comm Received with prefix "..prefix.." from "..sender);
    end

    -- decompresed is not null meaning data is coming from 2.3.0 or CommunityDKP
    success, _objReceived = LibAceSerializer:Deserialize(decompressed);
    
    --[[ 
      _objReceived = {
        Teams = {},
        CurrentTeam = "0",
        Data = string | {} | nil
      }
    --]]

    if success then
      if prefix == "CommDKPQuery" then
        ------------------------------
        -- This has been deprecated --
        ------------------------------
        return;
      elseif prefix == "CommDKPSeed" then
        CommDKPSeedReceived(_objReceived, sender);
        return;
      elseif prefix == "CommDKPBidder" then
        CommDKPBidderReceived(_objReceived, sender);
        return;
      elseif prefix == "CommDKPTeams" then
        CommDKPTeamsReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKProfileSend" then
        CDKProfileSendReceived(_objReceived, sender);
        return;
      elseif prefix == "CommDKPCurTeam" then
        CommDKPCurTeamReceived(_objReceived, sender);
        return;
      elseif prefix == "CommDKPTalents" then
        CommDKPTalentsReceived(_objReceived, sender);
        return;
      elseif prefix == "CommDKPRoles" then
        CommDKPRolesReceived(_objReceived, sender);
        return;
      elseif prefix == "CommDKPBuild" then
        CommDKPBuildReceived(_objReceived, sender);
        return;
      end

      ---
      -- OFFICER LEVEL DATA
      ---
      if CommDKP:ValidateSender(sender) then    -- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table

        if (prefix == "CommDKPBCastMsg") and sender ~= UnitName("player") then
          CommDKP:Print(_objReceived.Data);
          return;
        elseif prefix == "CommDKPPreBroad" then
          CommDKPPreBroadReceived(_objReceived, sender);
          return;
        elseif prefix == "CommDKPCommand" then
          CommDKPCommandReceived(_objReceived, sender);
          return;
        elseif prefix == "CommDKPRaidTime" then
          CommDKPRaidTimeReceived(_objReceived, sender);
          return;
        end

        if (sender ~= UnitName("player")) then
          if prefix == "CommDKPAllTabs" then   -- receives full table broadcast
            FullBroadcastReceived(_objReceived);
            return;
          elseif prefix == "CommDKPMerge" then
            TableMergeReceived(_objReceived);
            return;
          elseif prefix == "CommDKPLootDist" then
            CommDKPLootDistReceived(_objReceived);
            return;
          elseif prefix == "CommDKPDKPDist" then
            CommDKPDKPDistReceived(_objReceived);
            return;
          elseif prefix == "CommDKPDecay" then
            CommDKPDKPDecayReceived(_objReceived);
            return;
          elseif prefix == "CommDKPAddUsers" then
            CommDKPAddUsersReceived(_objReceived);
            return;
          elseif prefix == "CommDKPDelUsers" then
            CommDKPDelUsersReceived(_objReceived);
            return;
          elseif prefix == "CommDKPDelLoot" then
            CommDKPDelLootReceived(_objReceived);
            return;
          elseif prefix == "CommDKPDelSync" then
            CommDKPDelSyncReceived(_objReceived);
            return;
          elseif prefix == "CommDKPMinBid" then
            CommDKPMinBidReceived(_objReceived);
            return;
          elseif prefix == "CommDKPMaxBid" then
            CommDKPMaxbidReceived(_objReceived);
            return;
          elseif prefix == "CDKPWhitelist" then 
            CommDKPWhiteListReceived(_objReceived);
            return;
          elseif prefix == "CommDKPStand" then
            CommDKPStandByReceived(_objReceived);
            return;
          elseif prefix == "CommDKPSetPrice" then
            CommDKPSetPriceReceived(_objReceived);
            return;
          elseif prefix == "CommDKPZSumBank" then
            CommDKPZSumBankReceived(_objReceived);
            return;
          elseif prefix == "CommDKPDKPModes" then
            CommDKPDKPModesReceived(_objReceived);
            return;
          elseif prefix == "CommDKPBidShare" then
            CommDKPBidShareReceived(_objReceived);
            return;
          elseif prefix == "CommDKPBossLoot" then
            CommDKPBossLootReceived(_objReceived);
          end 
        end
      end
    else -- success == false
      CommDKP:Print("OnCommReceived ERROR: "..prefix)  -- error reporting if string doesn't get deserialized correctly
    end
  end
end

function CommDKP.Sync:SendData(prefix, data, target, targetTeam)

  -- 2.3.0 object being sent with almost everything?
  -- the idea is to envelope the old message into another object and then decode it on receiving end
  -- that way we won't have to do too much diging in the old code
  -- expect to send everything through SendData
  -- the only edge case is CommDKPBuild which for now stays the same as it was in 2.1.2

  targetTeam = targetTeam or CommDKP:GetCurrentTeamIndex();

  local _objToSend = {
    Teams = CommDKP:GetTable(CommDKP_DB, false)["teams"],
    CurrentTeam = CommDKP:GetCurrentTeamIndex(),
    TargetTeam = targetTeam,
    Data = nil,
    Prefix = prefix
  };

  if prefix == "CommDKPBuild" then
    CommDKP.Sync:SendCommMessage(prefix, data, "GUILD");
    return;
  end

  -- everything else but CommDKPBuild is getting compressed
  _objToSend.Data = data; -- if we send table everytime we have to serialize / deserialize anyway
  
  local _compressedObj = CommDKP.Sync:SerializeTableToString(_objToSend);

  if _compressedObj == nil then
    CommDKP:Print("prefix"..prefix.." ");
    CommDKP:Print("Compressing is fucked mate");
  end

  if data == nil or data == "" then data = " " end -- just in case, to prevent disconnects due to empty/nil string AddonMessages

  --AceComm Communication doesn't work if the prefix is longer than 15.  And if sucks if you try.
  if #prefix > 15 then
    CommDKP:Print("CommunityDKP Error: Prefix ["..prefix.."] is longer than 15. Please shorten.");
    return;
  end

  -- at this point object is ready to be sent

  if IsInGuild() then
    if prefix == "CommDKPQuery" then
      CommDKPQuerySend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CommDKPTalents" then
      CommDKPTalentsSend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CommDKPRoles" then
      CommDKPRolesSend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CDKProfileSend" then
      CommDKPProfileSend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CommDKPBidder" then -- bid submissions. Keep to raid.
      CommDKPBidderSend(prefix, _compressedObj, "RAID");
      return;
    end

    if core.IsOfficer then
      if prefix == "CommDKPCommand" then
        CommDKPCommandSend(prefix, _compressedObj, "RAID");
        return;
      end
  
      if prefix == "CommDKPRaidTime" then
        CommDKPRaidTimeSend(prefix, _compressedObj, "RAID");
        return;
      end
  
      if prefix == "CommDKPBCastMsg" then
        CommDKPCastMsgSend(prefix, _compressedObj, "RAID");
        return;
      end  
  
      if prefix == "CommDKPZSumBank" then
        CommDKPZSumBankSend(prefix, _compressedObj, "RAID");
        return;
      end  
  
      if prefix == "CommDKPBossLoot" then
        CommDKPBossLootSend(prefix, _compressedObj, "RAID");
        return;
      end  
  
      if prefix == "CommDKPBidShare" then
        CommDKPBidShareSend(prefix, _compressedObj, "RAID");
        return;
      end  
  
      if prefix == "CommDKPPreBroad" then
        CommDKPPreBroadSend(prefix, _compressedObj, target);
        return;
      end
  
      if prefix == "CommDKPAllTabs" then
        FullBroadcastSend(prefix, _compressedObj, target);
        return;
      end
  
      if prefix == "CommDKPMerge" then
        TableMergeSend(prefix, _compressedObj, target);
        return;
      end
      
      -- what is being sent here?
      if target then
        CommDKP.Sync:SendCommMessage(prefix, _compressedObj, "WHISPER", target)
      else
        CommDKP.Sync:SendCommMessage(prefix, _compressedObj, "GUILD")
      end
    end

  end
end


function CommDKP.Sync:SerializeTableToString(data) 

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


function CommDKP.Sync:DeserializeStringToTable(_string)

  if not _string == nil then

    local decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(_string))
    local success, _obj  = LibAceSerializer:Deserialize(decoded);

    CommDKP:Print("success: "..success)  -- error reporting if string doesn't get deserialized correctly
    if not success then
      CommDKP:Print("_string: ".._string)  -- error reporting if string doesn't get deserialized correctly
      CommDKP:Print("decoded: "..decoded)  -- error reporting if string doesn't get deserialized correctly
    end

    return success, _obj;
  end

end


----------
-- FULL BROADCAST HANDLERS
----------

function FullBroadcastSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CommDKPAllTabs";

  if channel then -- check if we are targeting specific player
    print("[CommunityDKP] COMMS: You started Full Broadcast for team "..CommDKP:GetTeamName(CommDKP:GetCurrentTeamIndex()).." to player "..channel);
    CommDKP.Sync:SendCommMessage(prefix, commObject, "WHISPER", channel, "NORMAL", CommDKP_BroadcastFull_Callback, nil);
  else
    CommDKP.Sync:SendData("CommDKPPreBroad", prefix, nil);
    CommDKP.Sync:SendCommMessage(prefix, commObject, _channel, nil, "NORMAL", CommDKP_BroadcastFull_Callback, nil);
  end
end


function FullBroadcastReceived(commObject)
  --[[ 
      commObject = {
        Teams = {},
        CurrentTeam = "0",
        Data = {
          DKPTable = {},
          DKP = {}, 
          Loot = {}, 
          Archive = {}, 
          MinBids = {},
          Teams= {} 
        }
      }
    --]]

  table.sort(commObject.Data.Loot, function(a, b)
    return a["date"] > b["date"]
  end)

  table.sort(commObject.Data.DKP, function(a, b)
    return a["date"] > b["date"]
  end)

  if commObject.Data.MinBids ~= nil then
    table.sort(commObject.Data.MinBids, function(a, b)
      --Ensure that if there is a data issue, we detect and move on during syncs.
      local aItem = a["item"] or GetNameFromLink(a["link"]);
      local bItem = b["item"] or GetNameFromLink(b["link"]);

      return aItem < bItem
    end)
  end

  if (#CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam) > 0 and #CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam) > 0) and 
    (
      commObject.Data.DKP[1].date < CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam)[1].date or 
      commObject.Data.Loot[1].date < CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam)[1].date
    ) then

    local entry1 = "Loot: "..commObject.Data.Loot[1].loot.." |cff616ccf"..L["WONBY"].." "..commObject.Data.Loot[1].player.." ("..date("%b %d @ %H:%M:%S", commObject.Data.Loot[1].date)..") by "..strsub(commObject.Data.Loot[1].index, 1, strfind(commObject.Data.Loot[1].index, "-")-1).."|r"
    local entry2 = "DKP: |cff616ccf"..commObject.Data.DKP[1].reason.." ("..date("%b %d @ %H:%M:%S", commObject.Data.DKP[1].date)..") - "..strsub(commObject.Data.DKP[1].index, 1, strfind(commObject.Data.DKP[1].index, "-")-1).."|r"

    StaticPopupDialogs["FULL_TABS_ALERT"] = {
      text = "|CFFFF0000"..L["WARNING"].."|r: "..string.format(L["NEWERTABS1"], sender).."\n\n"..entry1.."\n\n"..entry2.."\n\n"..L["NEWERTABS2"],
      button1 = L["YES"],
      button2 = L["NO"],
      OnAccept = function()
        CommDKP:SetTable(CommDKP_DKPTable, true, commObject.Data.DKPTable, commObject.CurrentTeam);
        CommDKP:SetTable(CommDKP_DKPHistory, true, commObject.Data.DKP, commObject.CurrentTeam);
        CommDKP:SetTable(CommDKP_Loot, true, commObject.Data.Loot, commObject.CurrentTeam);
        CommDKP:SetTable(CommDKP_Archive, true, commObject.Data.Archive, commObject.CurrentTeam);
        
        local minBidTable = CommDKP:FormatPriceTable(commObject.Data.MinBids, true);
        local newMinBidTable = {}
        for i=1, #minBidTable do
          local id = minBidTable[i].itemID;
          if id == nil and minBidTable[i].link ~= nil then
            id = minBidTable[i].link:match("|Hitem:(%d+):")
          end
          if id ~= nil then
            newMinBidTable[id] = minBidTable[i];
          end
        end

        CommDKP:SetTable(CommDKP_MinBids, true, newMinBidTable, commObject.CurrentTeam);
        core.DB["teams"] = commObject.Teams;

        CommDKP:SetCurrentTeam(commObject.CurrentTeam)
        
        CommDKP:FilterDKPTable(core.currentSort, "reset")
        CommDKP:StatusVerify_Update()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("FULL_TABS_ALERT")
  else
    CommDKP:SetTable(CommDKP_DKPTable, true, commObject.Data.DKPTable, commObject.CurrentTeam);
    CommDKP:SetTable(CommDKP_DKPHistory, true, commObject.Data.DKP, commObject.CurrentTeam);
    CommDKP:SetTable(CommDKP_Loot, true, commObject.Data.Loot, commObject.CurrentTeam);
    CommDKP:SetTable(CommDKP_Archive, true, commObject.Data.Archive, commObject.CurrentTeam);

    local minBidTable = CommDKP:FormatPriceTable(commObject.Data.MinBids, true);
    local newMinBidTable = {}
    for i=1, #minBidTable do
      local id = minBidTable[i].itemID;
      if id == nil and minBidTable[i].link ~= nil then
        id = minBidTable[i].link:match("|Hitem:(%d+):")
      end
      if id ~= nil then
        newMinBidTable[id] = minBidTable[i];
      end
    end

    CommDKP:SetTable(CommDKP_MinBids, true, newMinBidTable, commObject.CurrentTeam);

    core.DB["teams"] = commObject.Teams;
    CommDKP:SetCurrentTeam(commObject.CurrentTeam)
    -- reset seeds since this is a fullbroadcast   
    CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam).seed = 0 
    CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam).seed = 0
    CommDKP:FilterDKPTable(core.currentSort, "reset");
    CommDKP:StatusVerify_Update();
  end
  
  print("[CommunityDKP] COMMS: Full broadcast receive finished for team "..CommDKP:GetTeamName(commObject.CurrentTeam));
end


----------
-- 2-WEEK MERGE HANDLERS
----------

function TableMergeSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CommDKPMerge";

  if channel then -- check if we are targeting specific player
    print("[CommunityDKP] COMMS: You started 2-week broadcast for team "..CommDKP:GetTeamName(CommDKP:GetCurrentTeamIndex()).." to player "..channel);
    CommDKP.Sync:SendCommMessage(prefix, commObject, "WHISPER", channel, "NORMAL", CommDKP_BroadcastFull_Callback, nil);
  else
    CommDKP.Sync:SendData("CommDKPPreBroad", prefix, nil);
    CommDKP.Sync:SendCommMessage(prefix, commObject, _channel, nil, "NORMAL", CommDKP_BroadcastFull_Callback, nil);
  end
end


function TableMergeReceived(commObject, channel, sender)
  for i=1, #commObject.Data.DKP do
    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i].index, "index")

    if not search and ((CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam).DKPMeta and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam).DKPMeta < commObject.Data.DKP[i].date) or (not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam).DKPMeta)) then   -- prevents adding entry if this entry has already been archived
      local players = {strsplit(",", strsub(commObject.Data.DKP[i].players, 1, -2))}
      local dkp

      if strfind(commObject.Data.DKP[i].dkp, "%-%d*%.?%d+%%") then
        dkp = {strsplit(",", commObject.Data.DKP[i].dkp)}
      end

      if commObject.Data.DKP[i].deletes then      -- adds deletedby field to entry if the received table is a delete entry
        local search_del = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i].deletes, "index")

        if search_del then
          CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam)[search_del[1][1]].deletedby = commObject.Data.DKP[i].index
        end
      end
      
      if not commObject.Data.DKP[i].deletedby then
        local search_del = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i].index, "deletes")

        if search_del then
          commObject.Data.DKP[i].deletedby = CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam)[search_del[1][1]].index
        end
      end

      table.insert(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i])

      for j=1, #players do
        if players[j] then
          local findEntry = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), players[j], "player")

          if strfind(commObject.Data.DKP[i].dkp, "%-%d*%.?%d+%%") then     -- handles decay entries
            if findEntry then
              CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp + tonumber(dkp[j])
            else
              if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[j]] or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[j]] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[j]].deleted ~= true) then
                CommDKP_Profile_Create(players[j], tonumber(dkp[j]), nil, nil, commObject.CurrentTeam)
              end
            end
          else
            if findEntry then
              CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp + tonumber(commObject.Data.DKP[i].dkp)
              if (tonumber(commObject.Data.DKP[i].dkp) > 0 and not commObject.Data.DKP[i].deletes) or (tonumber(commObject.Data.DKP[i].dkp) < 0 and commObject.Data.DKP[i].deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain 
                CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_gained = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_gained + commObject.Data.DKP[i].dkp   -- NOT if it's a DKP penalty or deleteing a DKP penalty
              end
            else
              if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[j]] or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[j]] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[j]].deleted ~= true) then
                local class

                if (tonumber(commObject.Data.DKP[i].dkp) > 0 and not commObject.Data.DKP[i].deletes) or (tonumber(commObject.Data.DKP[i].dkp) < 0 and commObject.Data.DKP[i].deletes) then
                  CommDKP_Profile_Create(players[j], tonumber(commObject.Data.DKP[i].dkp), tonumber(commObject.Data.DKP[i].dkp), nil, commObject.CurrentTeam)
                else
                  CommDKP_Profile_Create(players[j], tonumber(commObject.Data.DKP[i].dkp), nil, nil, commObject.CurrentTeam)
                end
              end
            end
          end
        end
      end
    end
  end

  if CommDKP.ConfigTab6 and CommDKP.ConfigTab6.history and CommDKP.ConfigTab6:IsShown() then
    CommDKP:DKPHistory_Update(true)
  end

  for i=1, #commObject.Data.Loot do
    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i].index, "index")

    if not search and ((CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam).LootMeta and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam).LootMeta < commObject.Data.Loot[i].date) or (not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam).LootMeta)) then -- prevents adding entry if this entry has already been archived
      if commObject.Data.Loot[i].deletes then
        local search_del = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i].deletes, "index")

        if search_del and not CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam)[search_del[1][1]].deletedby then
          CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam)[search_del[1][1]].deletedby = commObject.Data.Loot[i].index
        end
      end

      if not commObject.Data.Loot[i].deletedby then
        local search_del = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i].index, "deletes")

        if search_del then
          commObject.Data.Loot[i].deletedby = CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam)[search_del[1][1]].index
        end
      end

      table.insert(CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i])

      local findEntry = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.Loot[i].player, "player")

      if findEntry then
        CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp + commObject.Data.Loot[i].cost
        CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_spent = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_spent + commObject.Data.Loot[i].cost
      else
        if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.Loot[i].player] or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.Loot[i].player] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.Loot[i].player].deleted ~= true) then
          CommDKP_Profile_Create(commObject.Data.Loot[i].player, commObject.Data.Loot[i].cost, 0, commObject.Data.Loot[i].cost, commObject.CurrentTeam)
        end
      end
    end
  end

  for i=1, #commObject.Data.Profiles do

    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.Profiles[i].player, "player")

    if search then
      if CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].class == "NONE" then
        CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].class = commObject.Data.Profiles[i].class
      end
    else
      tinsert(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam),commObject.Data.Profiles[i])
    end
  end

  CommDKP:LootHistory_Reset()
  CommDKP:LootHistory_Update(L["NOFILTER"])
  CommDKP:FilterDKPTable(core.currentSort, "reset")
  CommDKP:StatusVerify_Update()
  return
end


----------
-- CommDKPQuery message HANDLERS
----------

function CommDKPQuerySend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CommDKPQuery";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end

----------
-- CommDKPBuild message HANDLERS
----------

function CommDKPBuildReceived(commObject, sender)
  if sender ~= UnitName("player") then
    local LastVerCheck = time() - core.LastVerCheck;

        if LastVerCheck > 900 then             -- limits the Out of Date message from firing more than every 15 minutes 
          if tonumber(_objReceived.Data) > core.BuildNumber then
            core.LastVerCheck = time();
            CommDKP:Print(L["OUTOFDATEANNOUNCE"])
          end
        end

        if tonumber(_objReceived.Data) < core.BuildNumber then   -- returns build number if receiving party has a newer version
          CommDKP.Sync:SendData("CommDKPBuild", tostring(core.BuildNumber))
        end
        return;
  end
end

----------
-- CommDKPTalents message HANDLERS
----------

function CommDKPTalentsSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CommDKPTalents";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPTalentsReceived(commObject, sender)
  for teamIndex,team in pairs(commObject.Teams) do
    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex), sender, "player")

    if search then
      local curSelection = CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]]
      curSelection.spec = commObject.Data;
      
      if CommDKP:GetTable(CommDKP_Profiles, true, teamIndex)[sender] == nil then
        CommDKP:GetTable(CommDKP_Profiles, true, teamIndex)[sender] = CommDKP:GetDefaultEntity();
      end

      CommDKP:GetTable(CommDKP_Profiles, true, teamIndex)[sender].spec = commObject.Data;
    end
    
  end

  return
end

----------
-- CommDKPRoles message HANDLERS
----------

function CommDKPRolesSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CommDKPRoles";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPRolesReceived(commObject, sender)
  for teamIndex,team in pairs(commObject.Teams) do
    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex), sender, "player")
    local curClass = "None";

    if search then
      local curSelection = CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]]
      curClass = CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]].class
    
      if curClass == "WARRIOR" then
        local a,b,c = strsplit("/", commObject.Data)
        if strfind(commObject.Data, "Protection") or (tonumber(c) and tonumber(strsub(c, 1, -2)) > 15) then
          curSelection.role = L["TANK"]
        else
          curSelection.role = L["MELEEDPS"]
        end
      elseif curClass == "PALADIN" then
        if strfind(commObject.Data, "Protection") then
          curSelection.role = L["TANK"]
        elseif strfind(commObject.Data, "Holy") then
          curSelection.role = L["HEALER"]
        else
          curSelection.role = L["MELEEDPS"]
        end
      elseif curClass == "HUNTER" then
        curSelection.role = L["RANGEDPS"]
      elseif curClass == "ROGUE" then
        curSelection.role = L["MELEEDPS"]
      elseif curClass == "PRIEST" then
        if strfind(commObject.Data, "Shadow") then
          curSelection.role = L["CASTERDPS"]
        else
          curSelection.role = L["HEALER"]
        end
      elseif curClass == "SHAMAN" then
        if strfind(commObject.Data, "Restoration") then
          curSelection.role = L["HEALER"]
        elseif strfind(commObject.Data, "Elemental") then
          curSelection.role = L["CASTERDPS"]
        else
          curSelection.role = L["MELEEDPS"]
        end
      elseif curClass == "MAGE" then
        curSelection.role = L["CASTERDPS"]
      elseif curClass == "WARLOCK" then
        curSelection.role = L["CASTERDPS"]
      elseif curClass == "DRUID" then
        if strfind(commObject.Data, "Feral") then
          curSelection.role = L["TANK"]
        elseif strfind(commObject.Data, "Balance") then
          curSelection.role = L["CASTERDPS"]
        else
          curSelection.role = L["HEALER"]
        end
      else
        curSelection.role = L["NOROLEDETECTED"]
      end

      if CommDKP:GetTable(CommDKP_Profiles, true, teamIndex)[sender] == nil then
        CommDKP:GetTable(CommDKP_Profiles, true, teamIndex)[sender] = CommDKP:GetDefaultEntity();
      end

      CommDKP:GetTable(CommDKP_Profiles, true, teamIndex)[sender].role = curSelection.role;
      CommDKP:GetTable(CommDKP_DKPTable, true, teamIndex)[search[1][1]].role = curSelection.role;
    end
  end
  return;
end

----------
-- CDKProfileSend message HANDLERS
----------

function CommDKPProfileSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKProfileSend";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CDKProfileSendReceived(commObject, sender)
  local profile = commObject.Data;
  CommDKP:GetTable(CommDKP_Profiles, true, commObject.CurrentTeam)[profile.player] = profile;
  
  --Legacy Version Tracking
  local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), profile.player, "player")
  if search then
    CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].version = profile.version;
  end
end

----------
-- CommDKPBidder message HANDLERS
----------

function CommDKPBidderSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CommDKPBidder";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPBidderReceived(commObject, sender)
  if core.BidInProgress and core.IsOfficer then
    if commObject.Data == "pass" then
        -- CommDKP:Print(sender.." has passed.")  --TODO: Let's do something different here at some point.
      return;
    else
      CommDKP_CHAT_MSG_WHISPER(commObject.Data, sender);
      return;
    end
  else
    return;
  end
end

----------
-- CommDKPCommand message HANDLERS
----------

function CommDKPCommandSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CommDKPCommand";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPCommandReceived(commObject, sender)
  local command, arg1, arg2, arg3, arg4 = strsplit("#", commObject.Data);
  if sender ~= UnitName("player") then
    if command == "StartTimer" then
      CommDKP:StartTimer(arg1, arg2)
    elseif command == "StartBidTimer" then
      CommDKP:StartBidTimer(arg1, arg2, arg3)
      core.BiddingInProgress = true;
      if strfind(arg1, "{") then
        CommDKP:Print("Bid timer extended by "..tonumber(strsub(arg1, strfind(arg1, "{")+1)).." seconds.")
      end
    elseif command == "StopBidTimer" then
      if CommDKP.BidTimer then
        CommDKP.BidTimer:SetScript("OnUpdate", nil)
        CommDKP.BidTimer:Hide()
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
        core.BidInterface = core.BidInterface or CommDKP:BidInterface_Create()  -- initiates bid window if it hasn't been created
      end
      if core.DB.defaults.AutoOpenBid and not core.BidInterface:IsShown() then  -- toggles bid window if option is set to
        CommDKP:BidInterface_Toggle()
      end

      CommDKP:CurrItem_Set(arg1, arg2, arg3, arg4)  -- populates bid window
    end
  end
end


----------
-- CommDKPRaidTime message HANDLERS
----------

function CommDKPRaidTimeSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CommDKPRaidTime";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPRaidTimeReceived(commObject, sender)
  local command, args = strsplit(",", commObject.Data);

  if sender ~= UnitName("player") and core.IsOfficer and CommDKP.ConfigTab2 then
    if command == "start" then
      CommDKP:SetCurrentTeam(commObject.CurrentTeam); -- on start change the currentTeam
      local arg1, arg2, arg3, arg4, arg5, arg6 = strsplit(" ", args, 6)

      if arg1 == "true" then arg1 = true else arg1 = false end
      if arg4 == "true" then arg4 = true else arg4 = false end
      if arg5 == "true" then arg5 = true else arg5 = false end
      if arg6 == "true" then arg6 = true else arg6 = false end

      if arg2 ~= nil then
        CommDKP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(arg2));
        core.DB.modes.increment = tonumber(arg2);
      end
      if arg3 ~= nil then
        CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(arg3));
        core.DB.DKPBonus.IntervalBonus = tonumber(arg3);
      end
      if arg4 ~= nil then
        CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(arg4);
        core.DB.DKPBonus.GiveRaidStart = arg4;
      end
      if arg5 ~= nil then
        CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(arg5);
        core.DB.DKPBonus.GiveRaidEnd = arg5;
      end
      if arg6 ~= nil then
        CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(arg6);
        core.DB.DKPBonus.IncStandby = arg6;
      end

      CommDKP:StartRaidTimer(arg1)
    elseif command == "stop" then
      CommDKP:StopRaidTimer()
    elseif strfind(command, "sync", 1) then
      local _, syncTimer, syncSecondCount, syncMinuteCount, syncAward = strsplit(" ", command, 5)
      CommDKP:StartRaidTimer(nil, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
      CommDKP:SetCurrentTeam(_objReceived.CurrentTeam);
      core.RaidInProgress = true
    end
  elseif sender ~= UnitName("player") and not core.IsOfficer and not CommDKP.ConfigTab2 then
    CommDKP:SetCurrentTeam(_objReceived.CurrentTeam);
  end

end

----------
-- CommDKPBCastMsg message HANDLERS
----------

function CommDKPCastMsgSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CommDKPBCastMsg";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


----------
-- CommDKPZSumBank message HANDLERS
----------

function CommDKPZSumBankSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CommDKPZSumBank";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPZSumBankReceived(commObject)
  if core.IsOfficer then
    core.DB.modes.ZeroSumBank = commObject.Data;
    if core.ZeroSumBank then
      if commObject.Data.balance == 0 then
        core.ZeroSumBank.LootFrame.LootList:SetText("")
      end
      CommDKP:ZeroSumBank_Update()
    end
  end
end

----------
-- CommDKPBossLoot message HANDLERS
----------

function CommDKPBossLootSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CommDKPBossLoot";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPBossLootReceived(commObject)

  local lootList = {};
  core.DB.bossargs.LastKilledBoss = commObject.Data.boss;

  for i=1, #commObject.Data do
    local item = Item:CreateFromItemLink(commObject.Data[i]);
    item:ContinueOnItemLoad(function()
      local icon = item:GetItemIcon()
      table.insert(lootList, {icon=icon, link=item:GetItemLink()})
    end);
  end
  CommDKP:LootTable_Set(lootList)
end

----------
-- CommDKPBidShare message HANDLERS
----------

function CommDKPBidShareSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CommDKPBidShare";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end

function CommDKPBidShareReceived(commObject)
  if core.BidInterface then
    CommDKP:Bids_Set(commObject.Data)
  end
  return
end

----------
-- CommDKPPreBroad message HANDLERS
----------

function CommDKPPreBroadSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CommDKPPreBroad";
  CommDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CommDKPPreBroadReceived(commObject, sender)
  
  if sender ~= UnitName("player") then
    if commObject.Data == "CommDKPAllTabs" then
      print("[CommunityDKP] COMMS: You started Full Broadcast for team "..CommDKP:GetTeamName(commObject.CurrentTeam));
    elseif commObject.Data == "CommDKPMerge" then
      print("[CommunityDKP] COMMS: You started 2-week broadcast for team "..CommDKP:GetTeamName(commObject.CurrentTeam));
    end
  else
    if commObject.Data == "CommDKPAllTabs" then
      print("[CommunityDKP] COMMS: Full broadcast started by "..sender.." for team "..CommDKP:GetTeamName(commObject.CurrentTeam));
    elseif commObject.Data == "CommDKPMerge" then
      print("[CommunityDKP] COMMS: 2-week merge broadcast started by "..sender.." for team "..CommDKP:GetTeamName(commObject.CurrentTeam));
    end
  end
end

----------
-- CommDKPLootDist message HANDLERS
----------

function CommDKPLootDistReceived(commObject)

  local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.player, "player")
  if search then
    local DKPTable = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]]
    DKPTable.dkp = DKPTable.dkp + commObject.Data.cost
    DKPTable.lifetime_spent = DKPTable.lifetime_spent + commObject.Data.cost
  else
    if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] or 
    (
      CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] and 
      CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player].deleted ~= true
    ) then
      CommDKP_Profile_Create(commObject.Data.player, commObject.Data.cost, 0, commObject.Data.cost, commObject.CurrentTeam);
    end
  end
  tinsert(CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam), 1, commObject.Data)

  CommDKP:LootHistory_Reset()
  CommDKP:LootHistory_Update(L["NOFILTER"])
  CommDKP:FilterDKPTable(core.currentSort, "reset")
  
end


----------
-- CommDKPDKPDist message HANDLERS
----------

function CommDKPDKPDistReceived(commObject)

  local players = {strsplit(",", strsub(commObject.Data.players, 1, -2))}
  local dkp = commObject.Data.dkp

  tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), 1, commObject.Data)

  for i=1, #players do
    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

    if search then
      CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp + tonumber(dkp)
      if tonumber(dkp) > 0 then
        CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].lifetime_gained = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].lifetime_gained + tonumber(dkp)
      end
    else
      if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] or
       (
         CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] and 
         CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true
      ) then
        CommDKP_Profile_Create(players[i], tonumber(dkp), tonumber(dkp), nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
      end
    end
  end

  if CommDKP.ConfigTab6 and CommDKP.ConfigTab6.history and CommDKP.ConfigTab6:IsShown() then
    CommDKP:DKPHistory_Update(true)
  end
  CommDKP:FilterDKPTable(core.currentSort, "reset")
end

----------
-- CommDKPDecay message HANDLERS
----------

function CommDKPDKPDecayReceived(commObject)

  local players = {strsplit(",", strsub(commObject.Data.players, 1, -2))}
  local dkp = {strsplit(",", commObject.Data.dkp)}

  tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), 1, commObject.Data)
  
  for i=1, #players do
    local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

    if search then
      CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp + tonumber(dkp[i])
    else
      if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true) then
        CommDKP_Profile_Create(players[i], tonumber(dkp[i]), nil, nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
      end
    end
  end

  if CommDKP.ConfigTab6 and CommDKP.ConfigTab6.history and CommDKP.ConfigTab6:IsShown() then
    CommDKP:DKPHistory_Update(true)
  end
  CommDKP:FilterDKPTable(core.currentSort, "reset")
end

----------
-- CommDKPAddUsers message HANDLERS
----------

function CommDKPAddUsersReceived(commObject)
  if UnitName("player") ~= sender then
    CommDKP:AddEntitiesToDKPTable(commObject.Data, commObject.TargetTeam);
  end
  return;
end

----------
-- CommDKPDelUsers message HANDLERS
----------

function CommDKPDelUsersReceived(commObject)
  local numPlayers = 0
  local removedUsers = ""

  if UnitName("player") ~= sender then
    for i=1, #commObject.Data do
      local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data[i].player, "player")

      if search and commObject.Data[i].deleted and commObject.Data[i].deleted ~= "Recovered" then
        if commObject.Data[i].edited == nil then
          commObject.Data[i].edited = time();
        end

        if (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] and commObject.Data[i].deleted) or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited < commObject.Data[i].edited) or (not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player]) then
          --delete user, archive data
          if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] then    -- creates/adds to archive entry for user
            CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=commObject.Data[i].deleted, edited=commObject.Data[i].edited }
          else
            CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].deleted = commObject.Data[i].deleted
            CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited = commObject.Data[i].edited
          end
          
          c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].class)
          if i==1 then
            removedUsers = "|c"..c.hex..CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].player.."|r"
          else
            removedUsers = removedUsers..", |c"..c.hex..CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].player.."|r"
          end
          numPlayers = numPlayers + 1

          tremove(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), search[1][1])
          CommDKP:GetTable(CommDKP_Profiles, true, commObject.CurrentTeam)[commObject.Data[i].player] = nil;

          local search2 = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Standby, true, commObject.CurrentTeam), commObject.Data[i].player, "player");

          if search2 then
            table.remove(CommDKP:GetTable(CommDKP_Standby,true, commObject.CurrentTeam), search2[1][1])
          end
        end
      elseif not search and commObject.Data[i].deleted == "Recovered" then
        if CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] and (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited == nil or CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited < commObject.Data[i].edited) then
          CommDKP_Profile_Create(commObject.Data[i].player, nil, nil, nil, commObject.CurrentTeam);  -- User was recovered, create/request profile as needed
          CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].deleted = "Recovered"
          CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited = commObject.Data[i].edited
        end
      end
    end
    if numPlayers > 0 then
      CommDKP:FilterDKPTable(core.currentSort, "reset")
      CommDKP:Print("["..CommDKP:GetTeamName(commObject.CurrentTeam).."] ".."Removed "..numPlayers.." player(s): "..removedUsers)
    end
  end
  return
end

----------
-- CommDKPDelLoot message HANDLERS
----------

function CommDKPDelLootReceived(commObject)
  local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam), commObject.Data.deletes, "index")

  if search then
    CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam)[search[1][1]].deletedby = commObject.Data.index
  end

  local search_player = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.player, "player")

  if search_player then
    CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].dkp + commObject.Data.cost                  -- refund previous looter
    CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].lifetime_spent = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].lifetime_spent + commObject.Data.cost       -- remove from lifetime_spent
  else
    if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player].deleted ~= true) then
      CommDKP_Profile_Create(commObject.Data.player, commObject.Data.cost, 0, commObject.Data.cost, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
    end
  end

  table.insert(CommDKP:GetTable(CommDKP_Loot, true, commObject.CurrentTeam), 1, commObject.Data)
  CommDKP:SortLootTable()
  CommDKP:LootHistory_Reset()
  CommDKP:LootHistory_Update(L["NOFILTER"]);
  CommDKP:FilterDKPTable(core.currentSort, "reset")
end

----------
-- CommDKPDelSync message HANDLERS
----------

function CommDKPDelSyncReceived(commObject)
  local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.deletes, "index")
  local players = {strsplit(",", strsub(commObject.Data.players, 1, -2))}   -- cuts off last "," from string to avoid creating an empty value
  local dkp, mod;

  if strfind(commObject.Data.dkp, "%-%d*%.?%d+%%") then     -- determines if it's a mass decay
    dkp = {strsplit(",", commObject.Data.dkp)}
    mod = "perc";
  else
    dkp = commObject.Data.dkp
    mod = "whole"
  end

  for i=1, #players do
    if mod == "perc" then
      local search2 = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

      if search2 then
        CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].dkp + tonumber(dkp[i])
      else
        if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true) then
          CommDKP_Profile_Create(players[i], tonumber(dkp[i]), nil, nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
        end
      end
    else
      local search2 = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

      if search2 then
        CommDKP:GetTable(CommDKP_DKPTable, true)[search2[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].dkp + tonumber(dkp)

        if tonumber(dkp) < 0 then
          CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].lifetime_gained = CommDKP:GetTable(CommDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].lifetime_gained + tonumber(dkp)
        end
      else
        if not CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] or (CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]] and CommDKP:GetTable(CommDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true) then
          local gained;
          if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end

          CommDKP_Profile_Create(players[i], tonumber(dkp), gained, nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
        end
      end
    end
  end

  if search then
    CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam)[search[1][1]].deletedby = commObject.Data.index;    -- adds deletedby field if the entry exists
  end

  table.insert(CommDKP:GetTable(CommDKP_DKPHistory, true, commObject.CurrentTeam), 1, commObject.Data)

  if CommDKP.ConfigTab6 and CommDKP.ConfigTab6.history then
    CommDKP:DKPHistory_Update(true)
  end
  CommDKP:DKPTable_Update()
end

----------
-- CommDKPMinBid message HANDLERS
----------

function CommDKPMinBidReceived(commObject)
  if core.IsOfficer then
    core.DB.MinBidBySlot = commObject.Data[1]

    for i=1, #commObject.Data[2] do
      local bidInfo = commObject.Data[2][i]
      local bidTeam = bidInfo[1]
      local bidItems = bidInfo[2]
      if bidItems ~= nil then
        for j=1, #bidItems do
          local search = CommDKP:GetTable(CommDKP_MinBids, true, bidTeam)[bidItems[j].itemID];
          if search then
            CommDKP:GetTable(CommDKP_MinBids, true, bidTeam)[bidItems[j].itemID].minbid = bidItems[j].minbid
            if bidItems[j]["link"] ~= nil then
              CommDKP:GetTable(CommDKP_MinBids, true, bidTeam)[bidItems[j].itemID].link = bidItems[j].link
            end
            if bidItems[j]["icon"] ~= nil then
              CommDKP:GetTable(CommDKP_MinBids, true, bidTeam)[bidItems[j].itemID].icon = bidItems[j].icon
            end
          else
            CommDKP:GetTable(CommDKP_MinBids, true, bidTeam)[bidItems[j].itemID] = bidItems[j];
          end
        end 
      end
    end
  end
end

----------
-- CommDKPMaxBid message HANDLERS
----------

function CommDKPMaxbidReceived(commObject)
  if core.IsOfficer then

    core.DB.MaxBidBySlot = commObject.Data[1];
    _objMaxBidValues = commObject.Data[1];

    for i=1, #commObject.Data[2] do
      local bidInfo = commObject.Data[2][i]
      local bidTeam = bidInfo[1]
      local bidItems = bidInfo[2] or {}

      for j=1, #bidItems do
        local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_MaxBids, true, bidTeam), bidItems[j].item)
        if search then
          CommDKP:GetTable(CommDKP_MaxBids, true, bidTeam)[search[1][1]].maxbid = bidItems[j].maxbid
        else
          table.insert(CommDKP:GetTable(CommDKP_MaxBids, true, bidTeam), bidItems[j])
        end
      end 
    end
  end
end

----------
-- CDKPWhitelist message HANDLERS
----------

function CommDKPWhiteListReceived(commObject)
  if CommDKP:GetGuildRankIndex(UnitName("player")) > 1 then -- only applies if not GM
    CommDKP:SetTable(CommDKP_Whitelist, false, commObject.Data, commObject.CurrentTeam);
  end
end

----------
-- CommDKPStand message HANDLERS
----------

function CommDKPStandByReceived(commObject)
  CommDKP:SetTable(CommDKP_Standby, true, commObject.Data, commObject.CurrentTeam); -- issues/153
end

----------
-- CommDKPSetPrice message HANDLERS
----------

function CommDKPSetPriceReceived(commObject)

  local _objSetPrice = _objReceived.Data;
  local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(_objSetPrice.link,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

  local search = CommDKP:GetTable(CommDKP_MinBids, true, _objReceived.CurrentTeam)[itemID];

  if not search then
    CommDKP:GetTable(CommDKP_MinBids, true, _objReceived.CurrentTeam)[itemID] = _objSetPrice;
  elseif search then
    CommDKP:GetTable(CommDKP_MinBids, true, _objReceived.CurrentTeam)[itemID] = _objSetPrice;
  end
  
  core.PriceTable = CommDKP:FormatPriceTable();
  CommDKP:PriceTable_Update(0);

end

----------
-- CommDKPDKPModes message HANDLERS
----------

function CommDKPDKPModesReceived(commObject)
  if (core.DB.modes.mode ~= commObject.Data[1].mode) or (core.DB.modes.MaxBehavior ~= commObject.Data[1].MaxBehavior) then
    CommDKP:Print(L["RECOMMENDRELOAD"])
  end
  core.DB.modes = commObject.Data[1]
  core.DB.DKPBonus = commObject.Data[2]
  core.DB.raiders = commObject.Data[3]
end

----------
-- CommDKPSeed message HANDLERS
----------

function CommDKPSeedReceived(commObject, sender)

  --[[ 
      Data = {
        ["0"] = {
          ["Loot"] = "name-date",
          ["DKPHistory"] = "name-date"
        },
        ["1"] = {
          ["Loot"] = "start",
          ["DKPHistory"] = "start"
        }
      }
    --]]

  if sender ~= UnitName("player") then
    for tableIndex,v in pairs(commObject.Data) do
      if(type(v) == "table") then
        for property,value in pairs(v) do
          if value ~= "start" then

            local off1,date1 = strsplit("-", value);

            if CommDKP:ValidateSender(off1) then
              if property == "Loot" then

                local searchLoot = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true, tostring(tableIndex)), value, "index")

                if not searchLoot then
                  CommDKP:GetTable(CommDKP_Loot, true, tostring(tableIndex)).seed = value
                end

              elseif property == "DKPHistory" then
                local searchDKPHistory = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true, tostring(tableIndex)), value, "index")
                
                if not searchDKPHistory then
                  CommDKP:GetTable(CommDKP_DKPHistory, true, tostring(tableIndex)).seed = value
                end
              end
            end
          end
        end
      end
    end
  end
end

----------
-- CommDKPTeams message HANDLERS
----------

function CommDKPTeamsReceived(commObject, sender)
  CommDKP:GetTable(CommDKP_DB, false)["teams"] = commObject.Teams
end

----------
-- CommDKPCurTeam message HANDLERS
----------

function CommDKPCurTeamReceived(commObject, sender)
  CommDKP:SetCurrentTeam(commObject.CurrentTeam) -- this also refreshes all the tables/views/graphs
end

----------
-- TODO message HANDLERS
----------