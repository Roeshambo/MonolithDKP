local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local raidLootList = {};

function MonDKP:LootList_Add(lootList)
  for _, item in pairs(lootList) do
        table.insert(raidLootList, item.link)
  end
end

function MonDKP:LootList_Print()
  for _, itemLink in pairs(raidLootList) do
        ChatFrame1:AddMessage(itemLink)
  end
end