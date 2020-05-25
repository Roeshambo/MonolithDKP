local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

 
local function CreateRow(parent, id) -- Create 3 buttons for each row in the list
	local f = CreateFrame("Button", "$parentLine"..id, parent)
	f.PriceInfo = {}
	f:SetSize(core.TableWidth, core.TableRowHeight)
	f:SetHighlightTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight");
	f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
	f:GetNormalTexture():SetAlpha(0.2)
	--f:SetScript("OnClick", DKPTable_OnClick)
	for i=1, 3 do
		f.PriceInfo[i] = f:CreateFontString(nil, "OVERLAY");
		f.PriceInfo[i]:SetFontObject("MonDKPSmallOutlineLeft")
		f.PriceInfo[i]:SetTextColor(1, 1, 1, 1);
		if (i==1) then
			f.PriceInfo[i].rowCounter = f:CreateFontString(nil, "OVERLAY");
			f.PriceInfo[i].rowCounter:SetFontObject("MonDKPSmallOutlineLeft")
			f.PriceInfo[i].rowCounter:SetTextColor(1, 1, 1, 0.3);
			f.PriceInfo[i].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);
			f.PriceInfo[i]:SetSize((370)-1, core.TableRowHeight);
			
		end
		if (i==2) then
			f.PriceInfo[i]:SetFontObject("MonDKPSmallLeft")
			f.PriceInfo[i]:SetSize((60)-1, core.TableRowHeight);
		end
		if (i==3) then
			f.PriceInfo[i]:SetFontObject("MonDKPSmallLeft")
			f.PriceInfo[i]:SetSize((70)-1, core.TableRowHeight);
		end
	end
	f.PriceInfo[1]:SetPoint("LEFT", 30, 0);
	f.PriceInfo[2]:SetPoint("CENTER", 155, 0)
	f.PriceInfo[3]:SetPoint("RIGHT", 15, 0)

	--f:SetScript("OnMouseDown", function(self, button)
	--	if button == "RightButton" then
	--		RightClickMenu(self)
	--	end
	--end)

	return f
end

function MonDKP:ProcessDisenchant(loot)
	local itemName,itemLink,_,_,_,_,_,_,_,itemIcon = GetItemInfo(loot)
	local mode = core.DB.modes.mode;

	if core.BiddingWindow and core.BiddingWindow:IsShown() then  -- can only process through bidding process
		if _G["MonDKPBiddingStartBiddingButton"] then
			_G["MonDKPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
			_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
				ToggleTimerBtn(self)
			end)
			timerToggle = 0;
		end

		core.BidInProgress = false;
		MonDKP:BroadcastStopBidTimer()

		if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
			local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_MinBids, true), itemName);
			local numOfDisenchants = MonDKP:GetTable(MonDKP_Player_MinBids, true)[search[1][1]]["disenchants"] or 0;
			local updatedDisenchants = numOfDisenchants + 1;
			local cost = core.BiddingWindow.cost:GetNumber();

			SendChatMessage("No votes for ".." "..itemLink.." for "..cost.." "..L["DKP"].." and will be disenchanted. This will be disenchant number "..updatedDisenchants, "RAID_WARNING");
			
			--If cost is 0, dont' track.
			if cost == 0 then
				updatedDisenchants = 0;
			end

			--Adjust Price
			if updatedDisenchants >= 3 then
				cost = MonDKP_round(cost/2, core.DB.modes.rounding);
				if cost < 5 then
					cost = 5
				end
			end

			local newItem = {item=itemName, minbid=cost, link=itemLink, icon=itemIcon, disenchant=updatedDisenchants};

			if not search then

				tinsert(MonDKP:GetTable(MonDKP_Player_MinBids, true), newItem)
				core.BiddingWindow.CustomMinBid:SetShown(true);
				core.BiddingWindow.CustomMinBid:SetChecked(true);
			else

				MonDKP:GetTable(MonDKP_Player_MinBids, true)[search[1][1]].minbid = cost;
				MonDKP:GetTable(MonDKP_Player_MinBids, true)[search[1][1]].link = itemLink;
				MonDKP:GetTable(MonDKP_Player_MinBids, true)[search[1][1]].icon = itemIcon;
				MonDKP:GetTable(MonDKP_Player_MinBids, true)[search[1][1]].disenchants = updatedDisenchants;
				newItem = MonDKP:GetTable(MonDKP_Player_MinBids, true)[search[1][1]];
			end

			MonDKP.Sync:SendData("MonDKPSetPrice", newItem);
		else

			SendChatMessage("No votes for ".." "..itemLink.." for "..-cost.." "..L["DKP"].." and will be disenchanted.", "RAID_WARNING")
		end

		core.BiddingWindow:Hide()

		ClearBidWindow()

	end

end

function MonDKP:PriceTable_Update(scrollOffset)

	local numOptions = #core.PriceTable
	local numOfRows = core.PriceNumRows;
	local index, row
	local offset = MonDKP_round(scrollOffset / core.TableRowHeight, 0)

	for i=1, numOfRows do     -- hide all rows before displaying them 1 by 1 as they show values
		row = MonDKP.ConfigTab7.PriceTable.Rows[i];
		row:Hide();
	end
	for i=1, numOfRows do     -- show rows if they have values
		row = MonDKP.ConfigTab7.PriceTable.Rows[i]
		index = tonumber(offset) + i;
		if core.PriceTable[index] then
			row:Show()
			row.index = index
			local curItemName = core.PriceTable[index].item;
			local curItemPrice = core.PriceTable[index].minbid;

			local curDisenchants = 0;

			if core.PriceTable[index]["disenchants"] ~= nil then
				curDisenchants = core.PriceTable[index].disenchants;
			else
				core.PriceTable[index]["disenchants"] = curDisenchants;
			end

			if core.PriceTable[index]["link"] ~= nil then
				curItemName = core.PriceTable[index].link;
				MonDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self:GetParent(), "ANCHOR_BOTTOMRIGHT", 0, 500);
					GameTooltip:SetHyperlink(curItemName)
					GameTooltip:Show();
				end)
				MonDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
			else
				MonDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnEnter", nil)
				MonDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnLeave", nil)
			end
			row.PriceInfo[1]:SetText(curItemName)
			row.PriceInfo[1].rowCounter:SetText(index)
		
			row.PriceInfo[2]:SetText(curItemPrice)
			
			row.PriceInfo[3]:SetText(curDisenchants)
		else
			row:Hide()
		end
	end

	if #core.PriceTable == 0 then  		-- Displays "No Entries Returned" if the result of filter combinations yields an empty table
		--MonDKP_RestoreFilterOptions()
		MonDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[1].rowCounter:SetText("")
		MonDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[1]:SetText("")
		MonDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[2]:SetText("|cffff6060"..L["NOENTRIESRETURNED"].."|r")
		MonDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[3]:SetText("")

		if MonDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[3].rollrange then MonDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[3].rollrange:SetText("") end
		MonDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnEnter", nil)
		MonDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnMouseDown", function()
			MonDKP_RestoreFilterOptions() 		-- restores filter selections to default on click.
		end)
		MonDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnClick", function()
			MonDKP_RestoreFilterOptions() 		-- restores filter selections to default on click.
		end)
		MonDKP.ConfigTab7.PriceTable.Rows[1]:Show()
	--else
		--MonDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnMouseDown", function(self, button)
		--	if button == "RightButton" then
		--		RightClickMenu(self)
		--	end
		--end)
		--MonDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnClick", DKPTable_OnClick)
	end


	FauxScrollFrame_Update(MonDKP.ConfigTab7.PriceTable, numOptions, numOfRows, core.TableRowHeight, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding

end

function MonDKP:PriceListSort(id, reset)
	local button;                                 -- passing "reset" forces it to do initial sort (A to Z repeatedly instead of A to Z then Z to A toggled)
	local PriceSortButtons = core.PriceSortButtons

	button = PriceSortButtons[id]

	if reset and reset ~= "Clear" then                         -- reset is useful for check boxes when you don't want it repeatedly reversing the sort
		button.Ascend = button.Ascend
	else
		button.Ascend = not button.Ascend
	end
	for k, v in pairs(PriceSortButtons) do
		if v ~= button then
			v.Ascend = nil
		end
	end
	table.sort(core.PriceTable, function(a, b)

		if id == "disenchants" then
			if a[button.Id] == nil then
				a[button.Id] = 0;
			end
			if b[button.Id] == nil then
				b[button.Id] = 0;
			end
		end

		if button.Ascend then
			if id == "item" then
				return a[button.Id] < b[button.Id]
			else
				return a[button.Id] > b[button.Id]
			end
		else
			if id == "item" then
				return a[button.Id] > b[button.Id]
			else
				return a[button.Id] < b[button.Id]
			end
		end
	end)
	core.currentSort = id;
	MonDKP:PriceTable_Update(0)

end

function MonDKP:PriceTab_Create()

	local numOfRows = core.PriceNumRows;
	local PriceSortButtons = core.PriceSortButtons

	MonDKP.ConfigTab7.header = MonDKP.ConfigTab7:CreateFontString(nil, "OVERLAY");
	MonDKP.ConfigTab7.header:ClearAllPoints();
	MonDKP.ConfigTab7.header:SetPoint("TOPLEFT", MonDKP.ConfigTab7, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab7.header:SetFontObject("MonDKPLargeCenter");
	MonDKP.ConfigTab7.header:SetText(L["PRICETITLE"]);
	MonDKP.ConfigTab7.header:SetScale(1.2);

	MonDKP.ConfigTab7.description = MonDKP.ConfigTab7:CreateFontString(nil, "OVERLAY");
	MonDKP.ConfigTab7.description:ClearAllPoints();
	MonDKP.ConfigTab7.description:SetPoint("TOPLEFT", MonDKP.ConfigTab7.header, "BOTTOMLEFT", 7, -10);
	MonDKP.ConfigTab7.description:SetWidth(400);
	MonDKP.ConfigTab7.description:SetFontObject("MonDKPNormalLeft");
	MonDKP.ConfigTab7.description:SetText(L["PRICEDESC"]);

	MonDKP.ConfigTab7.PriceTable = CreateFrame("ScrollFrame", "MonDKPPriceScrollFrame", MonDKP.ConfigTab7, "FauxScrollFrameTemplate")
		MonDKP.ConfigTab7.PriceTable:SetSize(core.TableWidth, core.TableRowHeight*numOfRows)
	MonDKP.ConfigTab7.PriceTable:SetPoint("TOPLEFT", 0, -95)
	MonDKP.ConfigTab7.PriceTable:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});

	MonDKP.ConfigTab7.PriceTable:SetBackdropColor(0,0,0,0.4);
	MonDKP.ConfigTab7.PriceTable:SetBackdropBorderColor(1,1,1,0.5)
	MonDKP.ConfigTab7.PriceTable:SetClipsChildren(false);

	MonDKP.ConfigTab7.PriceTable.ScrollBar = FauxScrollFrame_GetChildFrames(MonDKP.ConfigTab7.PriceTable)
	MonDKP.ConfigTab7.PriceTable.Rows = {}

	for i=1, numOfRows do
		MonDKP.ConfigTab7.PriceTable.Rows[i] = CreateRow(MonDKP.ConfigTab7.PriceTable, i)
		if i==1 then
			MonDKP.ConfigTab7.PriceTable.Rows[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab7.PriceTable, "TOPLEFT", 0, -2)
		else  
			MonDKP.ConfigTab7.PriceTable.Rows[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab7.PriceTable.Rows[i-1], "BOTTOMLEFT")
		end
	end

	MonDKP.ConfigTab7.PriceTable:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, core.TableRowHeight, MonDKP:PriceTable_Update(offset))
	end)

	MonDKP.ConfigTab7.PriceTable.Headers = CreateFrame("Frame", "MonDKPPriceTableHeaders", MonDKP.ConfigTab7)
	MonDKP.ConfigTab7.PriceTable.Headers:SetSize(500, 22)
	MonDKP.ConfigTab7.PriceTable.Headers:SetPoint("BOTTOMLEFT", MonDKP.ConfigTab7.PriceTable, "TOPLEFT", 0, 1)
	MonDKP.ConfigTab7.PriceTable.Headers:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
	});
	MonDKP.ConfigTab7.PriceTable.Headers:SetBackdropColor(0,0,0,0.8);
	MonDKP.ConfigTab7.PriceTable.Headers:SetBackdropBorderColor(1,1,1,0.5)
	MonDKP.ConfigTab7.PriceTable.Headers:Show()

	PriceSortButtons.item = CreateFrame("Button", "$ParentPriceSortButtonItem", MonDKP.ConfigTab7.PriceTable.Headers)
	PriceSortButtons.disenchants = CreateFrame("Button", "$ParentPriceSortButtonDisenchants", MonDKP.ConfigTab7.PriceTable.Headers)
	PriceSortButtons.minbid = CreateFrame("Button", "$ParentPriceSortButtonDkp", MonDKP.ConfigTab7.PriceTable.Headers)

	PriceSortButtons.minbid:SetPoint("BOTTOM", MonDKP.ConfigTab7.PriceTable.Headers, "BOTTOM", 130, 2)
	PriceSortButtons.item:SetPoint("RIGHT", PriceSortButtons.minbid, "LEFT", 0, 0)
	PriceSortButtons.disenchants:SetPoint("LEFT", PriceSortButtons.minbid, "RIGHT")

	for k, v in pairs(PriceSortButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		if k == "minbid" then
			v:SetSize((60), core.TableRowHeight)
		elseif k == "item" then
			v:SetSize((370), core.TableRowHeight)
		else
			v:SetSize((70), core.TableRowHeight)
		end
		v:SetScript("OnClick", function(self) MonDKP:PriceListSort(self.Id, "Clear") end)
	end

	PriceSortButtons.item.t = PriceSortButtons.item:CreateFontString(nil, "OVERLAY")
	PriceSortButtons.item.t:SetFontObject("MonDKPNormal")
	PriceSortButtons.item.t:SetTextColor(1, 1, 1, 1);
	PriceSortButtons.item.t:SetPoint("LEFT", PriceSortButtons.item, "LEFT", 50, 0);
	PriceSortButtons.item.t:SetText("Item Name");

 	PriceSortButtons.disenchants.t = PriceSortButtons.disenchants:CreateFontString(nil, "OVERLAY")
	PriceSortButtons.disenchants.t:SetFontObject("MonDKPNormal");
	PriceSortButtons.disenchants.t:SetTextColor(1, 1, 1, 1);
	PriceSortButtons.disenchants.t:SetPoint("CENTER", PriceSortButtons.disenchants, "CENTER", 0, 0);
	PriceSortButtons.disenchants.t:SetText("Disenchants");
	
	PriceSortButtons.minbid.t = PriceSortButtons.minbid:CreateFontString(nil, "OVERLAY")
	PriceSortButtons.minbid.t:SetFontObject("MonDKPNormal")
	PriceSortButtons.minbid.t:SetTextColor(1, 1, 1, 1);
	PriceSortButtons.minbid.t:SetPoint("CENTER", PriceSortButtons.minbid, "CENTER", 0, 0);
	PriceSortButtons.minbid.t:SetText("DKP");
	core.PriceSortButtons = PriceSortButtons;

	MonDKP:PriceTable_Update(0)
end