local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

--
--  When clicking a box off, unchecks "All" as well and flags checkAll to false
--
local checkAll = true;                    -- changes to false when less than all of the boxes are checked
local curReason;                          -- stores user input in dropdown 

local function ScrollFrame_OnMouseWheel(self, delta)          -- scroll function for all but the DKPTable frame
	local newValue = self:GetVerticalScroll() - (delta * 20);   -- DKPTable frame uses FauxScrollFrame_OnVerticalScroll()
	
	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end
	
	self:SetVerticalScroll(newValue);
end

function CommDKPFilterChecks(self)         -- sets/unsets check boxes in conjunction with "All" button, then runs CommDKP:FilterDKPTable() above
	local verifyCheck = true; -- switches to false if the below loop finds anything unchecked
	if (self:GetChecked() == false and not CommDKP.ConfigTab1.checkBtn[10]) then
		core.CurView = "limited"
		core.CurSubView = "raid"
		CommDKP.ConfigTab1.checkBtn[9]:SetChecked(false);
		checkAll = false;
		verifyCheck = false
	end
	for i=1, 8 do             -- checks all boxes to see if all are checked, if so, checks "All" as well
		if CommDKP.ConfigTab1.checkBtn[i]:GetChecked() == false then
			verifyCheck = false;
		end
	end
	if (verifyCheck == true) then
		CommDKP.ConfigTab1.checkBtn[9]:SetChecked(true);
	else
		CommDKP.ConfigTab1.checkBtn[9]:SetChecked(false);
	end
	for k,v in pairs(core.classes) do
		if (CommDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
			core.classFiltered[v] = true;
		else
			core.classFiltered[v] = false;
		end
	end
	PlaySound(808)
	CommDKP:FilterDKPTable(core.currentSort, "reset");
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID());
	
	if self:GetID() > 4 then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	elseif self:GetID() == 4 and core.IsOfficer == true then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	else
		self:GetParent().ScrollFrame.ScrollBar:Hide()
	end

	if self:GetID() == 5 then
		CommDKP:LootHistory_Update(L["NOFILTER"]);
	elseif self:GetID() == 6 then
		CommDKP:DKPHistory_Update(true)
	end

	if self:GetID() == 7 then
		self:GetParent().ScrollFrame.ScrollBar:Hide()
	end

	local scrollChild = self:GetParent().ScrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end
	
	PlaySound(808)
	self:GetParent().ScrollFrame:SetScrollChild(self.content);
	self.content:Show();
	self:GetParent().ScrollFrame:SetVerticalScroll(0)
end

function CommDKP:SetTabs(frame, numTabs, width, height, ...)
	frame.numTabs = numTabs;
	
	local contents = {};
	local frameName = frame:GetName();
	
	for i = 1, numTabs do 
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CommDKPTabButtonTemplate");
		tab:SetID(i);
		tab:SetText(select(i, ...));
		tab:GetFontString():SetFontObject("CommDKPSmallOutlineCenter")
		tab:GetFontString():SetTextColor(0.7, 0.7, 0.86, 1)
		tab:SetScript("OnClick", Tab_OnClick);
		
		tab.content = CreateFrame("Frame", nil, frame.ScrollFrame);
		tab.content:SetSize(width, height);
		tab.content:Hide();
				
		table.insert(contents, tab.content);
		
		if (i == 1) then
			tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -5, 1);
		else
			tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -17, 0);
		end 
	end
	
	Tab_OnClick(_G[frameName.."Tab1"]);
	
	return unpack(contents);
end

---------------------------------------
-- Populate Tabs 
---------------------------------------
function CommDKP:ConfigMenuTabs()
	---------------------------------------
	-- TabMenu
	---------------------------------------
	CommDKP.UIConfig.TabMenu = CreateFrame("Frame", "CommDKPCommDKP.ConfigTabMenu", CommDKP.UIConfig);
	CommDKP.UIConfig.TabMenu:SetPoint("TOPRIGHT", CommDKP.UIConfig, "TOPRIGHT", -25, -25); --Moves the entire tabframe (defaults -25, -25)
	CommDKP.UIConfig.TabMenu:SetSize(535, 510);  --default: 477,510
	CommDKP.UIConfig.TabMenu:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	CommDKP.UIConfig.TabMenu:SetBackdropColor(0,0,0,0.9);
	CommDKP.UIConfig.TabMenu:SetBackdropBorderColor(1,1,1,0.5)

	CommDKP.UIConfig.TabMenuBG = CommDKP.UIConfig.TabMenu:CreateTexture(nil, "OVERLAY", nil);
	CommDKP.UIConfig.TabMenuBG:SetColorTexture(0, 0, 0, 1)
	CommDKP.UIConfig.TabMenuBG:SetPoint("TOPLEFT", CommDKP.UIConfig.TabMenu, "TOPLEFT", 2, -2);
	CommDKP.UIConfig.TabMenuBG:SetSize(536, 511);
	CommDKP.UIConfig.TabMenuBG:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\menu-bg");

	-- TabMenu ScrollFrame and ScrollBar
	CommDKP.UIConfig.TabMenu.ScrollFrame = CreateFrame("ScrollFrame", nil, CommDKP.UIConfig.TabMenu, "UIPanelScrollFrameTemplate");
	CommDKP.UIConfig.TabMenu.ScrollFrame:ClearAllPoints();
	CommDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("TOPLEFT",  CommDKP.UIConfig.TabMenu, "TOPLEFT", 4, -8);
	CommDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", CommDKP.UIConfig.TabMenu, "BOTTOMRIGHT", -3, 4);
	CommDKP.UIConfig.TabMenu.ScrollFrame:SetClipsChildren(false);
	CommDKP.UIConfig.TabMenu.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
	
	CommDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:Hide();
	CommDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, CommDKP.UIConfig.TabMenu.ScrollFrame, "UIPanelScrollBarTrimTemplate")
	CommDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:ClearAllPoints();
	CommDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", CommDKP.UIConfig.TabMenu.ScrollFrame, "TOPRIGHT", -20, -12);
	CommDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", CommDKP.UIConfig.TabMenu.ScrollFrame, "BOTTOMRIGHT", -2, 15);

	CommDKP.ConfigTab1, CommDKP.ConfigTab2, CommDKP.ConfigTab3, CommDKP.ConfigTab4, CommDKP.ConfigTab5, CommDKP.ConfigTab6, CommDKP.ConfigTab7 = CommDKP:SetTabs(CommDKP.UIConfig.TabMenu, 7, 533, 490, L["FILTERS"], L["ADJUSTDKP"], L["MANAGE"], L["OPTIONS"], L["LOOTHISTORY"], L["DKPHISTORY"], L["PRICETAB"]);

	---------------------------------------
	-- MENU TAB 1
	---------------------------------------
	CommDKP.ConfigTab1.text = CommDKP.ConfigTab1:CreateFontString(nil, "OVERLAY")   -- Filters header
	CommDKP.ConfigTab1.text:ClearAllPoints();
	CommDKP.ConfigTab1.text:SetFontObject("CommDKPLargeCenter")
	CommDKP.ConfigTab1.text:SetPoint("TOPLEFT", CommDKP.ConfigTab1, "TOPLEFT", 15, -10);
	CommDKP.ConfigTab1.text:SetText(L["FILTERS"]);
	CommDKP.ConfigTab1.text:SetScale(1.2)

	local checkBtn = {}
	CommDKP.ConfigTab1.checkBtn = checkBtn;

	-- Create CheckBoxes
	for i=1, 10 do
		CommDKP.ConfigTab1.checkBtn[i] = CreateFrame("CheckButton", nil, CommDKP.ConfigTab1, "UICheckButtonTemplate");
		if i <= 9 then CommDKP.ConfigTab1.checkBtn[i]:SetChecked(true) else CommDKP.ConfigTab1.checkBtn[i]:SetChecked(false) end;
		CommDKP.ConfigTab1.checkBtn[i]:SetID(i)
		if i <= 8 then
			CommDKP.ConfigTab1.checkBtn[i].text:SetText("|cff5151de"..API_CLASSES[core.classes[i]].."|r");
		end
		if i==9 then
			CommDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick",
				function()
					for j=1, 9 do
						if (checkAll) then
							CommDKP.ConfigTab1.checkBtn[j]:SetChecked(false)
						else
							CommDKP.ConfigTab1.checkBtn[j]:SetChecked(true)
						end
					end
					checkAll = not checkAll;
					CommDKPFilterChecks(CommDKP.ConfigTab1.checkBtn[9]);
				end)

			for k,v in pairs(core.classes) do               -- sets core.classFiltered table with all values
				if (CommDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
					core.classFiltered[v] = true;
				else
					core.classFiltered[v] = false;
				end
			end
		elseif i==10 then
			CommDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick", function(self)
				CommDKP.ConfigTab1.checkBtn[12]:SetChecked(false);
				CommDKPFilterChecks(self)
			end)
		else
			CommDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick", CommDKPFilterChecks)
		end
		CommDKP.ConfigTab1.checkBtn[i].text:SetFontObject("CommDKPSmall")
	end

	-- Class Check Buttons:
	CommDKP.ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", CommDKP.ConfigTab1, "TOPLEFT", 85, -70);
	CommDKP.ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
	CommDKP.ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
	CommDKP.ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
	CommDKP.ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
	CommDKP.ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
	CommDKP.ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
	CommDKP.ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);

	CommDKP.ConfigTab1.checkBtn[9]:SetPoint("BOTTOMRIGHT", CommDKP.ConfigTab1.checkBtn[2], "TOPLEFT", 50, 0);
	CommDKP.ConfigTab1.checkBtn[9].text:SetText("|cff5151de"..L["ALLCLASSES"].."|r");
	CommDKP.ConfigTab1.checkBtn[10]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[5], "BOTTOMLEFT", 0, 0);
	CommDKP.ConfigTab1.checkBtn[10].text:SetText("|cff5151de"..L["INPARTYRAID"].."|r");         -- executed in filterDKPTable (CommunityDKP.lua)

	CommDKP.ConfigTab1.checkBtn[11] = CreateFrame("CheckButton", nil, CommDKP.ConfigTab1, "UICheckButtonTemplate");
	CommDKP.ConfigTab1.checkBtn[11]:SetID(11)
	CommDKP.ConfigTab1.checkBtn[11].text:SetText("|cff5151de"..L["ONLINE"].."|r");
	CommDKP.ConfigTab1.checkBtn[11].text:SetFontObject("CommDKPSmall")
	CommDKP.ConfigTab1.checkBtn[11]:SetScript("OnClick", CommDKPFilterChecks)
	CommDKP.ConfigTab1.checkBtn[11]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[10], "TOPRIGHT", 100, 0);

	CommDKP.ConfigTab1.checkBtn[12] = CreateFrame("CheckButton", nil, CommDKP.ConfigTab1, "UICheckButtonTemplate");
	CommDKP.ConfigTab1.checkBtn[12]:SetID(12)
	CommDKP.ConfigTab1.checkBtn[12].text:SetText("|cff5151de"..L["NOTINRAIDFILTER"].."|r");
	CommDKP.ConfigTab1.checkBtn[12].text:SetFontObject("CommDKPSmall")
	CommDKP.ConfigTab1.checkBtn[12]:SetScript("OnClick", function(self)
		CommDKP.ConfigTab1.checkBtn[10]:SetChecked(false);
		CommDKPFilterChecks(self)
	end)
	CommDKP.ConfigTab1.checkBtn[12]:SetPoint("TOPLEFT", CommDKP.ConfigTab1.checkBtn[11], "TOPRIGHT", 65, 0);

	core.ClassGraph = CommDKP:ClassGraph()  -- draws class graph on tab1

	---------------------------------------
	-- Adjust DKP TAB
	---------------------------------------
	CommDKP:AdjustDKPTab_Create()

	---------------------------------------
	-- Price  TAB
	---------------------------------------
	CommDKP:PriceTab_Create()

	---------------------------------------
	-- Manage DKP TAB
	---------------------------------------
	CommDKP.ConfigTab3.header = CommDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab3.header:ClearAllPoints();
	CommDKP.ConfigTab3.header:SetFontObject("CommDKPLargeCenter");
	CommDKP.ConfigTab3.header:SetPoint("TOPLEFT", CommDKP.ConfigTab3, "TOPLEFT", 15, -10);
	CommDKP.ConfigTab3.header:SetText(L["MANAGEDKP"]);
	CommDKP.ConfigTab3.header:SetScale(1.2)

	-- Populate Manage Tab
	CommDKP:ManageEntries()

	---------------------------------------
	-- Loot History TAB
	---------------------------------------
	CommDKP.ConfigTab5.text = CommDKP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab5.text:ClearAllPoints();
	CommDKP.ConfigTab5.text:SetFontObject("CommDKPLargeLeft");
	CommDKP.ConfigTab5.text:SetPoint("TOPLEFT", CommDKP.ConfigTab5, "TOPLEFT", 15, -10);
	CommDKP.ConfigTab5.text:SetText(L["LOOTHISTORY"]);
	CommDKP.ConfigTab5.text:SetScale(1.2)
	CommDKP.ConfigTab5.inst = CommDKP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab5.inst:ClearAllPoints();
	CommDKP.ConfigTab5.inst:SetFontObject("CommDKPSmallRight");
	CommDKP.ConfigTab5.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	CommDKP.ConfigTab5.inst:SetPoint("TOPRIGHT", CommDKP.ConfigTab5, "TOPRIGHT", -40, -43);
	CommDKP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"]);
	-- Populate Loot History (LootHistory.lua)
	local looter = {}
	CommDKP.ConfigTab5.looter = looter
	local lootFrame = {}
	CommDKP.ConfigTab5.lootFrame = lootFrame
	for i=1, #CommDKP:GetTable(CommDKP_Loot, true) do
		CommDKP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "CommDKPLootHistoryFrame"..i, CommDKP.ConfigTab5);
	end
	if #CommDKP:GetTable(CommDKP_Loot, true) > 0 then
		CommDKP:LootHistory_Update(L["NOFILTER"])
		CommDKP:CreateSortBox();
	end
	---------------------------------------
	-- DKP History Tab
	---------------------------------------
	CommDKP.ConfigTab6.text = CommDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab6.text:ClearAllPoints();
	CommDKP.ConfigTab6.text:SetFontObject("CommDKPLargeLeft");
	CommDKP.ConfigTab6.text:SetPoint("TOPLEFT", CommDKP.ConfigTab6, "TOPLEFT", 15, -10);
	CommDKP.ConfigTab6.text:SetText(L["DKPHISTORY"]);
	CommDKP.ConfigTab6.text:SetScale(1.2)

	CommDKP.ConfigTab6.inst = CommDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab6.inst:ClearAllPoints();
	CommDKP.ConfigTab6.inst:SetFontObject("CommDKPSmallRight");
	CommDKP.ConfigTab6.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	CommDKP.ConfigTab6.inst:SetPoint("TOPRIGHT", CommDKP.ConfigTab6, "TOPRIGHT", -40, -43);
	if #CommDKP:GetTable(CommDKP_DKPHistory, true) > 0 then
		CommDKP:DKPHistory_Update()
	end
	CommDKP:DKPHistoryFilterBox_Create()
end
