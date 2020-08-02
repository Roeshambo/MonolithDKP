local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local OptionsLoaded = false;

function CommDKP_RestoreFilterOptions()  		-- restores default filter selections
	CommDKP.UIConfig.search:SetText(L["SEARCH"])
	CommDKP.UIConfig.search:SetTextColor(0.3, 0.3, 0.3, 1)
	CommDKP.UIConfig.search:ClearFocus()
	core.WorkingTable = CopyTable(CommDKP:GetTable(CommDKP_DKPTable, true))
	core.CurView = "all"
	core.CurSubView = "all"
	for i=1, 9 do
		CommDKP.ConfigTab1.checkBtn[i]:SetChecked(true)
	end
	CommDKP.ConfigTab1.checkBtn[10]:SetChecked(false)
	CommDKP.ConfigTab1.checkBtn[11]:SetChecked(false)
	CommDKP.ConfigTab1.checkBtn[12]:SetChecked(false)
	CommDKPFilterChecks(CommDKP.ConfigTab1.checkBtn[1])
end

function CommDKP:Toggle()        -- toggles IsShown() state of CommDKP.UIConfig, the entire addon window
	core.CommDKPUI = CommDKP.UIConfig or CommDKP:CreateMenu();
	core.CommDKPUI:SetShown(not core.CommDKPUI:IsShown())
	CommDKP.UIConfig:SetFrameLevel(10)
	CommDKP.UIConfig:SetClampedToScreen(true)
	if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
	if core.ModesWindow then core.ModesWindow:SetFrameLevel(2) end
		
	if core.IsOfficer == nil then
		CommDKP:CheckOfficer()
	end
	--core.IsOfficer = C_GuildInfo.CanEditOfficerNote()  -- seemingly removed from classic API
	if core.IsOfficer == false then
		_G["CommDKPCommDKP.ConfigTabMenuTab2"]:Hide(); --Adjust DKP
		_G["CommDKPCommDKP.ConfigTabMenuTab3"]:Hide(); -- Manage
		--_G["CommDKPCommDKP.ConfigTabMenuTab7"]:Hide(); -- Loot Prices
		_G["CommDKPCommDKP.ConfigTabMenuTab4"]:SetPoint("TOPLEFT", _G["CommDKPCommDKP.ConfigTabMenuTab1"], "TOPRIGHT", -14, 0)
		_G["CommDKPCommDKP.ConfigTabMenuTab5"]:SetPoint("TOPLEFT", _G["CommDKPCommDKP.ConfigTabMenuTab4"], "TOPRIGHT", -14, 0)
		_G["CommDKPCommDKP.ConfigTabMenuTab6"]:SetPoint("TOPLEFT", _G["CommDKPCommDKP.ConfigTabMenuTab5"], "TOPRIGHT", -14, 0)
	end

	if not OptionsLoaded then
		core.CommDKPOptions = core.CommDKPOptions or CommDKP:Options()
		OptionsLoaded = true;
	end

	if #CommDKP:GetTable(CommDKP_Whitelist) > 0 and core.IsOfficer then 				-- broadcasts whitelist any time the window is opened if one exists (help ensure everyone has the information even if they were offline when it was created)
		CommDKP.Sync:SendData("CDKPWhitelist", CommDKP:GetTable(CommDKP_Whitelist))   -- Only officers propagate the whitelist, and it is only accepted by players that are NOT the GM (prevents overwriting new Whitelist set by GM, if any.)
	end

	if core.CurSubView == "raid" then
		CommDKP:ViewLimited(true)
	elseif core.CurSubView == "standby" then
		CommDKP:ViewLimited(false, true)
	elseif core.CurSubView == "raid and standby" then
		CommDKP:ViewLimited(true, true)
	elseif core.CurSubView == "core" then
		CommDKP:ViewLimited(false, false, true)
	elseif core.CurSubView == "all" then
		CommDKP:ViewLimited()
	end

	core.CommDKPUI:SetScale(core.DB.defaults.CommDKPScaleSize)
	if CommDKP.ConfigTab6.history and CommDKP.ConfigTab6:IsShown() then
		CommDKP:DKPHistory_Update(true)
	elseif CommDKP.ConfigTab5 and CommDKP.ConfigTab5:IsShown() then
		CommDKP:LootHistory_Update(L["NOFILTER"]);
	end

	CommDKP:StatusVerify_Update()
	CommDKP:DKPTable_Update()
end

---------------------------------------
-- Sort Function
---------------------------------------
local SortButtons = {}

function CommDKP:FilterDKPTable(sort, reset)          -- filters core.WorkingTable based on classes in classFiltered table. core.currentSort should be used in most cases
	local parentTable;

	if not CommDKP.UIConfig then 
		return
	end

	if core.CurSubView ~= "all" then
		if core.CurSubView == "raid" then
			CommDKP:ViewLimited(true)
		elseif core.CurSubView == "standby" then
			CommDKP:ViewLimited(false, true)
		elseif core.CurSubView == "raid and standby" then
			CommDKP:ViewLimited(true, true)
		elseif core.CurSubView == "core" then
			CommDKP:ViewLimited(false, false, true)
		end
		parentTable = core.WorkingTable;
	else
		parentTable = CommDKP:GetTable(CommDKP_DKPTable, true);
	end

	core.WorkingTable = {}
	for k,v in ipairs(parentTable) do
		local IsOnline = false;
		local name;
		local InRaid = false;
		local searchFilter = true

		if CommDKP.UIConfig.search:GetText() ~= L["SEARCH"] and CommDKP.UIConfig.search:GetText() ~= "" then
			if not strfind(string.upper(v.player), string.upper(CommDKP.UIConfig.search:GetText())) and not strfind(string.upper(v.class), string.upper(CommDKP.UIConfig.search:GetText()))
			and not strfind(string.upper(v.role), string.upper(CommDKP.UIConfig.search:GetText())) and not strfind(string.upper(v.rankName), string.upper(CommDKP.UIConfig.search:GetText())) 
			and not strfind(string.upper(v.spec), string.upper(CommDKP.UIConfig.search:GetText())) then
				searchFilter = false;
			end
		end
		
		if CommDKP.ConfigTab1.checkBtn[11]:GetChecked() then
			local guildSize,_,_ = GetNumGuildMembers();
			for i=1, guildSize do
				local name,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
				name = strsub(name, 1, string.find(name, "-")-1)
				
				if name == v.player then
					IsOnline = online;
					break;
				end
			end
		end
		if(core.classFiltered[parentTable[k]["class"]] == true) and searchFilter == true then
			if CommDKP.ConfigTab1.checkBtn[10]:GetChecked() or CommDKP.ConfigTab1.checkBtn[12]:GetChecked() then
				for i=1, 40 do
					tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
					if tempName and tempName == v.player and CommDKP.ConfigTab1.checkBtn[10]:GetChecked() then
						tinsert(core.WorkingTable, v)
					elseif tempName and tempName == v.player and CommDKP.ConfigTab1.checkBtn[12]:GetChecked() then
						InRaid = true;
					end
				end
			else
				if ((CommDKP.ConfigTab1.checkBtn[11]:GetChecked() and IsOnline) or not CommDKP.ConfigTab1.checkBtn[11]:GetChecked()) then
					tinsert(core.WorkingTable, v)
				end
			end
			if CommDKP.ConfigTab1.checkBtn[12]:GetChecked() and InRaid == false then
				if CommDKP.ConfigTab1.checkBtn[11]:GetChecked() then
					if IsOnline then
						tinsert(core.WorkingTable, v)
					end
				else
					tinsert(core.WorkingTable, v)
				end
			end
		end
		InRaid = false;
	end

	if #core.WorkingTable == 0 then  		-- removes all filter settings if the filter combination results in an empty table
		--CommDKP_RestoreFilterOptions()
		CommDKP.DKPTable.Rows[1].DKPInfo[1]:SetText("|cffff0000No Entries Returned.|r")
		CommDKP.DKPTable.Rows[1]:Show()
	end
	CommDKP:SortDKPTable(sort, reset);
end

function CommDKP:SortDKPTable(id, reset)        -- reorganizes core.WorkingTable based on id passed. Avail IDs are "class", "player" and "dkp"
	local button;                                 -- passing "reset" forces it to do initial sort (A to Z repeatedly instead of A to Z then Z to A toggled)

	if id == "class" or id == "rank" or id == "role" or id == "spec" or id == "version" then
		button = SortButtons.class
	elseif id == "spec" then                -- doesn't allow "spec" to be sorted.
		CommDKP:DKPTable_Update()
		return;
	else
		button = SortButtons[id]
	end

	if button == nil then
		return;
	end

	if reset and reset ~= "Clear" then                         -- reset is useful for check boxes when you don't want it repeatedly reversing the sort
		button.Ascend = button.Ascend
	else
		button.Ascend = not button.Ascend
	end
	for k, v in pairs(SortButtons) do
		if v ~= button then
			v.Ascend = nil
		end
	end
	table.sort(core.WorkingTable, function(a, b)
		-- Validate Data and Fix Discrepencies
		if a[button.Id] == nil then
			print("[CommunityDKP] Bad DKP Player Record Found: "..a.player)
			core.RepairWorking = true;
			return false;
		end
		if b[button.Id] == nil then
			print("[CommunityDKP] Bad DKP Player Record Found: "..b.player)
			core.RepairWorking = true;
			return false;
		end

		if button.Ascend then
			if id == "dkp" then
				return a[button.Id] > b[button.Id]
			elseif id == "class" or id == "rank" or id == "role" or id == "spec" or id == "version" then
				if a[button.Id] < b[button.Id] then
					return true
				elseif a[button.Id] > b[button.Id] then
					return false
				else
					return a.dkp > b.dkp
				end
			else
				return a[button.Id] < b[button.Id]
			end
		else
			if id == "dkp" then
				return a[button.Id] < b[button.Id]
			elseif id == "class" or id == "rank" or id == "role" or id == "spec" or id == "version" then
				if a[button.Id] > b[button.Id] then
					return true
				elseif a[button.Id] < b[button.Id] then
					return false
				else
					return a.dkp > b.dkp
				end
			else
				return a[button.Id] > b[button.Id]
			end
		end
	end)
	core.currentSort = id;
	CommDKP:DKPTable_Update()
end

function CommDKP:CreateMenu()

	CommDKP.UIConfig = CreateFrame("Frame", "CommDKPConfig", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
	CommDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
	CommDKP.UIConfig:SetSize(550, 590);
	CommDKP.UIConfig:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CommDKP.UIConfig:SetBackdropColor(0,0,0,0.8);
	CommDKP.UIConfig:SetMovable(true);
	CommDKP.UIConfig:EnableMouse(true);
	--CommDKP.UIConfig:SetResizable(true);
	--CommDKP.UIConfig:SetMaxResize(1400, 875)
	--CommDKP.UIConfig:SetMinResize(1000, 590)
	CommDKP.UIConfig:RegisterForDrag("LeftButton");
	CommDKP.UIConfig:SetScript("OnDragStart", CommDKP.UIConfig.StartMoving);
	CommDKP.UIConfig:SetScript("OnDragStop", CommDKP.UIConfig.StopMovingOrSizing);
	CommDKP.UIConfig:SetFrameStrata("DIALOG")
	CommDKP.UIConfig:SetFrameLevel(10)
	CommDKP.UIConfig:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(2) end
	end)
	-- Close Button
	CommDKP.UIConfig.closeContainer = CreateFrame("Frame", "CommDKPTitle", CommDKP.UIConfig)
	CommDKP.UIConfig.closeContainer:SetPoint("CENTER", CommDKP.UIConfig, "TOPRIGHT", -4, 0)
	CommDKP.UIConfig.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CommDKP.UIConfig.closeContainer:SetBackdropColor(0,0,0,0.9)
	CommDKP.UIConfig.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	CommDKP.UIConfig.closeContainer:SetSize(28, 28)

	CommDKP.UIConfig.closeBtn = CreateFrame("Button", nil, CommDKP.UIConfig, "UIPanelCloseButton")
	CommDKP.UIConfig.closeBtn:SetPoint("CENTER", CommDKP.UIConfig.closeContainer, "TOPRIGHT", -14, -14)
	tinsert(UISpecialFrames, CommDKP.UIConfig:GetName()); -- Sets frame to close on "Escape"
	---------------------------------------
	-- Create and Populate Tab Menu and DKP Table
	---------------------------------------
	CommDKP.TabMenu = CommDKP:ConfigMenuTabs();        -- Create and populate Config Menu Tabs
	CommDKP:DKPTable_Create();                        -- Create DKPTable and populate rows
	CommDKP.UIConfig.TabMenu:Hide()                   -- Hide menu until expanded
	---------------------------------------
	-- DKP Table Header and Sort Buttons
	---------------------------------------
	CommDKP.DKPTable_Headers = CreateFrame("Frame", "CommDKPDKPTableHeaders", CommDKP.UIConfig)
	CommDKP.DKPTable_Headers:SetSize(500, 22)
	CommDKP.DKPTable_Headers:SetPoint("BOTTOMLEFT", CommDKP.DKPTable, "TOPLEFT", 0, 1)
	CommDKP.DKPTable_Headers:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
	});
	CommDKP.DKPTable_Headers:SetBackdropColor(0,0,0,0.8);
	CommDKP.DKPTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
	CommDKP.DKPTable_Headers:Show()
	---------------------------------------
	-- Sort Buttons
	--------------------------------------- 
	SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", CommDKP.DKPTable_Headers)
	SortButtons.class = CreateFrame("Button", "$ParentSortButtonClass", CommDKP.DKPTable_Headers)
	SortButtons.dkp = CreateFrame("Button", "$ParentSortButtonDkp", CommDKP.DKPTable_Headers)
	SortButtons.class:SetPoint("BOTTOM", CommDKP.DKPTable_Headers, "BOTTOM", 0, 2)
	SortButtons.player:SetPoint("RIGHT", SortButtons.class, "LEFT")
	SortButtons.dkp:SetPoint("LEFT", SortButtons.class, "RIGHT")
	 
	for k, v in pairs(SortButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		v:SetSize((core.TableWidth/3)-1, core.TableRowHeight)
		if v.Id == "class" then
			v:SetScript("OnClick", function(self) CommDKP:SortDKPTable(core.CenterSort, "Clear") end)
		else
			v:SetScript("OnClick", function(self) CommDKP:SortDKPTable(self.Id, "Clear") end)
		end
	end
	SortButtons.player:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)
	SortButtons.class:SetSize((core.TableWidth*0.2)-1, core.TableRowHeight)
	SortButtons.dkp:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)

	SortButtons.player.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
	SortButtons.player.t:SetFontObject("CommDKPNormal")
	SortButtons.player.t:SetTextColor(1, 1, 1, 1);
	SortButtons.player.t:SetPoint("LEFT", SortButtons.player, "LEFT", 50, 0);
	SortButtons.player.t:SetText(L["PLAYER"]); 

	--[[SortButtons.class.t = SortButtons.class:CreateFontString(nil, "OVERLAY")
	SortButtons.class.t:SetFontObject("CommDKPNormal");
	SortButtons.class.t:SetTextColor(1, 1, 1, 1);
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 0, 0);
	SortButtons.class.t:SetText(L["CLASS"]); --]]

	-- center column dropdown (class, rank, spec etc..)
	SortButtons.class.t = CreateFrame("FRAME", "CommDKPSortColDropdown", SortButtons.class, "CommunityDKPTableHeaderDropDownMenuTemplate")
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 4, -3)
	UIDropDownMenu_JustifyText(SortButtons.class.t, "CENTER")
	UIDropDownMenu_SetWidth(SortButtons.class.t, 80)
	UIDropDownMenu_SetText(SortButtons.class.t, L["CLASS"])
	UIDropDownMenu_Initialize(SortButtons.class.t, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "CommDKPSmallCenter"
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["CLASS"], "class", L["CLASS"], "class" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["SPEC"], "spec", L["SPEC"], "spec" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["RANK"], "rank", L["RANK"], "rank" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["ROLE"], "role", L["ROLE"], "role" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["VERSION"], "version", L["VERSION"], "version" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
	end)
	-- Dropdown Menu Function
	function SortButtons.class.t:SetValue(newValue, arg2)
		core.CenterSort = newValue
		SortButtons.class.Id = newValue;
		UIDropDownMenu_SetText(SortButtons.class.t, arg2)
		CommDKP:SortDKPTable(newValue, "reset")
		core.currentSort = newValue;
		CloseDropDownMenus()
	end
	SortButtons.dkp.t = SortButtons.dkp:CreateFontString(nil, "OVERLAY")
	SortButtons.dkp.t:SetFontObject("CommDKPNormal")
	SortButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	if core.DB.modes.mode == "Roll Based Bidding" then
		SortButtons.dkp.t:SetPoint("RIGHT", SortButtons.dkp, "RIGHT", -50, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);

		SortButtons.dkp.roll = SortButtons.dkp:CreateFontString(nil, "OVERLAY");
		SortButtons.dkp.roll:SetFontObject("CommDKPNormal")
		SortButtons.dkp.roll:SetScale("0.8")
		SortButtons.dkp.roll:SetTextColor(1, 1, 1, 1);
		SortButtons.dkp.roll:SetPoint("LEFT", SortButtons.dkp, "LEFT", 20, -1);
		SortButtons.dkp.roll:SetText(L["ROLLRANGE"])
	else
		SortButtons.dkp.t:SetPoint("CENTER", SortButtons.dkp, "CENTER", 20, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);
	end
	----- Counter below DKP Table
	CommDKP.DKPTable.counter = CreateFrame("Frame", "CommDKPDisplayFrameCounter", CommDKP.UIConfig);
	CommDKP.DKPTable.counter:SetPoint("TOP", CommDKP.DKPTable, "BOTTOM", 0, 0)
	CommDKP.DKPTable.counter:SetSize(400, 30)

	CommDKP.DKPTable.counter.t = CommDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	CommDKP.DKPTable.counter.t:SetFontObject("CommDKPNormal");
	CommDKP.DKPTable.counter.t:SetTextColor(1, 1, 1, 0.7);
	CommDKP.DKPTable.counter.t:SetPoint("CENTER", CommDKP.DKPTable.counter, "CENTER");

	CommDKP.DKPTable.counter.s = CommDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	CommDKP.DKPTable.counter.s:SetFontObject("CommDKPTiny");
	CommDKP.DKPTable.counter.s:SetTextColor(1, 1, 1, 0.7);
	CommDKP.DKPTable.counter.s:SetPoint("CENTER", CommDKP.DKPTable.counter, "CENTER", 0, -15);
	------------------------------
	-- Search Box
	------------------------------
	CommDKP.UIConfig.search = CreateFrame("EditBox", nil, CommDKP.UIConfig)
	CommDKP.UIConfig.search:SetPoint("BOTTOMLEFT", CommDKP.UIConfig, "BOTTOMLEFT", 50, 18)
	CommDKP.UIConfig.search:SetAutoFocus(false)
	CommDKP.UIConfig.search:SetMultiLine(false)
	CommDKP.UIConfig.search:SetSize(140, 24)
	CommDKP.UIConfig.search:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CommDKP.UIConfig.search:SetBackdropColor(0,0,0,0.9)
	CommDKP.UIConfig.search:SetBackdropBorderColor(1,1,1,0.6)
	CommDKP.UIConfig.search:SetMaxLetters(50)
	CommDKP.UIConfig.search:SetTextColor(0.4, 0.4, 0.4, 1)
	CommDKP.UIConfig.search:SetFontObject("CommDKPNormalLeft")
	CommDKP.UIConfig.search:SetTextInsets(10, 10, 5, 5)
	CommDKP.UIConfig.search:SetText(L["SEARCH"])
	CommDKP.UIConfig.search:SetScript("OnKeyUp", function(self)    -- clears text and focus on esc
		if (CommDKP.UIConfig.search:GetText():match("[%^%$%(%)%%%.%[%]%*%+%-%?]")) then
			CommDKP.UIConfig.search:SetText(string.gsub(CommDKP.UIConfig.search:GetText(), "[%^%$%(%)%%%.%[%]%*%+%-%?]", ""))
			--CommDKP.UIConfig.search:SetText(strsub(CommDKP.UIConfig.search:GetText(), 1, -2))
		else
			CommDKP:FilterDKPTable(core.currentSort, "reset")
		end
	end)
	CommDKP.UIConfig.search:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText(L["SEARCH"])
		self:SetTextColor(0.3, 0.3, 0.3, 1)
		self:ClearFocus()
		CommDKP:FilterDKPTable(core.currentSort, "reset")
	end)
	CommDKP.UIConfig.search:SetScript("OnEnterPressed", function(self)    -- clears text and focus on enter
		self:ClearFocus()
	end)
	CommDKP.UIConfig.search:SetScript("OnTabPressed", function(self)    -- clears text and focus on tab
		self:ClearFocus()
	end)
	CommDKP.UIConfig.search:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() ==  L["SEARCH"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		else
			self:HighlightText();
		end
	end)
	CommDKP.UIConfig.search:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["SEARCH"])
			self:SetTextColor(0.3, 0.3, 0.3, 1)
		end
	end)
	CommDKP.UIConfig.search:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SEARCH"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SEARCHDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	CommDKP.UIConfig.search:SetScript("OnLeave", function(self)
		GameTooltip:Hide();
	end)

	------------------------------
	-- Team view changer Drop Down
	------------------------------

		CommDKP.UIConfig.TeamViewChangerDropDown = CreateFrame("FRAME", "CommDKPConfigReasonDropDown", CommDKP.UIConfig, "CommunityDKPUIDropDownMenuTemplate")
		--CommDKP.ConfigTab3.TeamManagementContainer.TeamListDropDown:ClearAllPoints()
		CommDKP.UIConfig.TeamViewChangerDropDown:SetPoint("BOTTOMLEFT", CommDKP.UIConfig, "BOTTOMLEFT", 340, 4)
		-- tooltip on mouseOver
		CommDKP.UIConfig.TeamViewChangerDropDown:SetScript("OnEnter", 
			function(self) 
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["TEAMCURRENTLIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["TEAMCURRENTLISTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["WARNING"], 1.0, 0, 0, true);
				GameTooltip:AddLine(L["TEAMCURRENTLISTDESC2"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CommDKP.UIConfig.TeamViewChangerDropDown:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		UIDropDownMenu_SetWidth(CommDKP.UIConfig.TeamViewChangerDropDown, 150)
		UIDropDownMenu_SetText(CommDKP.UIConfig.TeamViewChangerDropDown, CommDKP:GetCurrentTeamName())

		-- Create and bind the initialization function to the dropdown menu
		UIDropDownMenu_Initialize(CommDKP.UIConfig.TeamViewChangerDropDown, 
			function(self, level, menuList)

				local dropDownMenuItem = UIDropDownMenu_CreateInfo()
				dropDownMenuItem.func = self.SetValue
				dropDownMenuItem.fontObject = "CommDKPSmallCenter"
			
				teamList = CommDKP:GetGuildTeamList()

				for i=1, #teamList do
					dropDownMenuItem.text = teamList[i][2]
					dropDownMenuItem.arg1 = teamList[i][2] -- name
					dropDownMenuItem.arg2 = teamList[i][1] -- index
					dropDownMenuItem.checked = teamList[i][1] == tonumber(CommDKP:GetCurrentTeamIndex())
					dropDownMenuItem.isNotRadio = true
					UIDropDownMenu_AddButton(dropDownMenuItem)
				end
			end
		)

		-- Dropdown Menu on SetValue()
		function CommDKP.UIConfig.TeamViewChangerDropDown:SetValue(arg1, arg2)

			if tonumber(CommDKP:GetCurrentTeamIndex()) ~= arg2 then
				if core.RaidInProgress == false and core.RaidInPause == false then
					CommDKP:SetCurrentTeam(arg2)
					CommDKP:SortDKPTable(core.currentSort, "reset")
					UIDropDownMenu_SetText(CommDKP.UIConfig.TeamViewChangerDropDown, arg1)
				else
					StaticPopupDialogs["RAID_IN_PROGRESS"] = {
						text = L["TEAMCHANGERAIDINPROGRESS"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("RAID_IN_PROGRESS")
				end
			else
				CloseDropDownMenus()
			end
		end

		CommDKP.UIConfig.TeamViewChangerLabel = CommDKP.UIConfig.TeamViewChangerDropDown:CreateFontString(nil, "OVERLAY")
		CommDKP.UIConfig.TeamViewChangerLabel:SetPoint("TOPLEFT", CommDKP.UIConfig.TeamViewChangerDropDown, "TOPLEFT", 17, 13);
		CommDKP.UIConfig.TeamViewChangerLabel:SetFontObject("CommDKPTiny");
		CommDKP.UIConfig.TeamViewChangerLabel:SetTextColor(1, 1, 1, 0.7);
		CommDKP.UIConfig.TeamViewChangerLabel:SetText(L["TEAMCURRENTLISTLABEL"]);

	---------------------------------------
	-- Expand / Collapse Arrow
	---------------------------------------
	CommDKP.UIConfig.expand = CreateFrame("Frame", "CommDKPTitle", CommDKP.UIConfig)
	CommDKP.UIConfig.expand:SetPoint("LEFT", CommDKP.UIConfig, "RIGHT", 0, 0)
	CommDKP.UIConfig.expand:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
	});
	CommDKP.UIConfig.expand:SetBackdropColor(0,0,0,0.7)
	CommDKP.UIConfig.expand:SetSize(15, 60)
	
	CommDKP.UIConfig.expandtab = CommDKP.UIConfig.expand:CreateTexture(nil, "OVERLAY", nil);
	CommDKP.UIConfig.expandtab:SetColorTexture(0, 0, 0, 1)
	CommDKP.UIConfig.expandtab:SetPoint("CENTER", CommDKP.UIConfig.expand, "CENTER");
	CommDKP.UIConfig.expandtab:SetSize(15, 60);
	CommDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\expand-arrow.tga");

	CommDKP.UIConfig.expand.trigger = CreateFrame("Button", "$ParentCollapseExpandButton", CommDKP.UIConfig.expand)
	CommDKP.UIConfig.expand.trigger:SetSize(15, 60)
	CommDKP.UIConfig.expand.trigger:SetPoint("CENTER", CommDKP.UIConfig.expand, "CENTER", 0, 0)
	CommDKP.UIConfig.expand.trigger:SetScript("OnClick", function(self) 
		if core.ShowState == false then
			CommDKP.UIConfig:SetWidth(1106)
			CommDKP.UIConfig.TabMenu:Show()
			CommDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\collapse-arrow");
		else
			CommDKP.UIConfig:SetWidth(550)
			CommDKP.UIConfig.TabMenu:Hide()
			CommDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\expand-arrow");
		end
		PlaySound(62540)
		core.ShowState = not core.ShowState
	end)

	-- Title Frame (top/center)
	CommDKP.UIConfig.TitleBar = CreateFrame("Frame", "CommDKPTitle", CommDKP.UIConfig, "ShadowOverlaySmallTemplate")
	CommDKP.UIConfig.TitleBar:SetPoint("BOTTOM", SortButtons.class, "TOP", 0, 10)
	CommDKP.UIConfig.TitleBar:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CommDKP.UIConfig.TitleBar:SetBackdropColor(0,0,0,0.9)
	CommDKP.UIConfig.TitleBar:SetSize(166, 54)

	-- Addon Title
	CommDKP.UIConfig.Title = CommDKP.UIConfig.TitleBar:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
	CommDKP.UIConfig.Title:SetColorTexture(0, 0, 0, 1)
	CommDKP.UIConfig.Title:SetPoint("CENTER", CommDKP.UIConfig.TitleBar, "CENTER");
	CommDKP.UIConfig.Title:SetSize(160, 48);
	CommDKP.UIConfig.Title:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\community-dkp.tga");
	---------------------------------------
	-- CHANGE LOG WINDOW
	---------------------------------------
	if core.DB.defaults.HideChangeLogs < core.BuildNumber then
		CommDKP.ChangeLogDisplay = CreateFrame("Frame", "CommDKP_ChangeLogDisplay", UIParent, "ShadowOverlaySmallTemplate");

		CommDKP.ChangeLogDisplay:SetPoint("TOP", UIParent, "TOP", 0, -200);
		CommDKP.ChangeLogDisplay:SetSize(600, 100);
		CommDKP.ChangeLogDisplay:SetBackdrop( {
			bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
			edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
		});
		CommDKP.ChangeLogDisplay:SetBackdropColor(0,0,0,0.9);
		CommDKP.ChangeLogDisplay:SetBackdropBorderColor(1,1,1,1)
		CommDKP.ChangeLogDisplay:SetFrameStrata("DIALOG")
		CommDKP.ChangeLogDisplay:SetFrameLevel(1)
		CommDKP.ChangeLogDisplay:SetMovable(true);
		CommDKP.ChangeLogDisplay:EnableMouse(true);
		CommDKP.ChangeLogDisplay:RegisterForDrag("LeftButton");
		CommDKP.ChangeLogDisplay:SetScript("OnDragStart", CommDKP.ChangeLogDisplay.StartMoving);
		CommDKP.ChangeLogDisplay:SetScript("OnDragStop", CommDKP.ChangeLogDisplay.StopMovingOrSizing);

		CommDKP.ChangeLogDisplay.ChangeLogHeader = CommDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CommDKP.ChangeLogDisplay.ChangeLogHeader:ClearAllPoints();
		CommDKP.ChangeLogDisplay.ChangeLogHeader:SetFontObject("CommDKPLargeLeft")
		CommDKP.ChangeLogDisplay.ChangeLogHeader:SetPoint("TOPLEFT", CommDKP.ChangeLogDisplay, "TOPLEFT", 10, -10);
		CommDKP.ChangeLogDisplay.ChangeLogHeader:SetText("CommunityDKP Change Log");

		CommDKP.ChangeLogDisplay.Notes = CommDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CommDKP.ChangeLogDisplay.Notes:ClearAllPoints();
		CommDKP.ChangeLogDisplay.Notes:SetWidth(580)
		CommDKP.ChangeLogDisplay.Notes:SetFontObject("CommDKPNormalLeft")
		CommDKP.ChangeLogDisplay.Notes:SetPoint("TOPLEFT", CommDKP.ChangeLogDisplay.ChangeLogHeader, "BOTTOMLEFT", 0, -10);

		CommDKP.ChangeLogDisplay.VerNumber = CommDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CommDKP.ChangeLogDisplay.VerNumber:ClearAllPoints();
		CommDKP.ChangeLogDisplay.VerNumber:SetWidth(580)
		CommDKP.ChangeLogDisplay.VerNumber:SetScale(0.8)
		CommDKP.ChangeLogDisplay.VerNumber:SetFontObject("CommDKPLargeLeft")
		CommDKP.ChangeLogDisplay.VerNumber:SetPoint("TOPLEFT", CommDKP.ChangeLogDisplay.Notes, "BOTTOMLEFT", 0, -10);

		CommDKP.ChangeLogDisplay.ChangeLogText = CommDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CommDKP.ChangeLogDisplay.ChangeLogText:ClearAllPoints();
		CommDKP.ChangeLogDisplay.ChangeLogText:SetWidth(540)
		CommDKP.ChangeLogDisplay.ChangeLogText:SetFontObject("CommDKPNormalLeft")
		CommDKP.ChangeLogDisplay.ChangeLogText:SetPoint("TOPLEFT", CommDKP.ChangeLogDisplay.VerNumber, "BOTTOMLEFT", 5, -0);

		-- Change Log Close Button
		CommDKP.ChangeLogDisplay.closeContainer = CreateFrame("Frame", "CommDKPChangeLogClose", CommDKP.ChangeLogDisplay)
		CommDKP.ChangeLogDisplay.closeContainer:SetPoint("CENTER", CommDKP.ChangeLogDisplay, "TOPRIGHT", -4, 0)
		CommDKP.ChangeLogDisplay.closeContainer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
		});
		CommDKP.ChangeLogDisplay.closeContainer:SetBackdropColor(0,0,0,0.9)
		CommDKP.ChangeLogDisplay.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
		CommDKP.ChangeLogDisplay.closeContainer:SetSize(28, 28)

		CommDKP.ChangeLogDisplay.closeBtn = CreateFrame("Button", nil, CommDKP.ChangeLogDisplay, "UIPanelCloseButton")
		CommDKP.ChangeLogDisplay.closeBtn:SetPoint("CENTER", CommDKP.ChangeLogDisplay.closeContainer, "TOPRIGHT", -14, -14)

		CommDKP.ChangeLogDisplay.DontShowCheck = CreateFrame("CheckButton", nil, CommDKP.ChangeLogDisplay, "UICheckButtonTemplate");
		CommDKP.ChangeLogDisplay.DontShowCheck:SetChecked(false)
		CommDKP.ChangeLogDisplay.DontShowCheck:SetScale(0.6);
		CommDKP.ChangeLogDisplay.DontShowCheck.text:SetText("  |cff5151de"..L["DONTSHOW"].."|r");
		CommDKP.ChangeLogDisplay.DontShowCheck.text:SetScale(1.5);
		CommDKP.ChangeLogDisplay.DontShowCheck.text:SetFontObject("CommDKPSmallLeft")
		CommDKP.ChangeLogDisplay.DontShowCheck:SetPoint("LEFT", CommDKP.ChangeLogDisplay.ChangeLogHeader, "RIGHT", 10, 0);
		CommDKP.ChangeLogDisplay.DontShowCheck:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.defaults.HideChangeLogs = core.BuildNumber
			else
				core.DB.defaults.HideChangeLogs = 0
			end
		end)
		
		if L["BESTPRACTICES"] ~= "" then
			CommDKP.ChangeLogDisplay.Notes:SetText("|CFFAEAEDD"..L["BESTPRACTICES"].."|r")
		end
		CommDKP.ChangeLogDisplay.VerNumber:SetText("Version: "..core.MonVersion)

		--------------------------------------
		-- ChangeLog variable calls (bottom of localization files)
		--------------------------------------
		CommDKP.ChangeLogDisplay.ChangeLogText:SetText(L["CHANGELOG1"].."\n\n"..L["CHANGELOG2"].."\n\n"..L["CHANGELOG3"].."\n\n"..L["CHANGELOG4"].."\n\n"..L["CHANGELOG5"].."\n\n"..L["CHANGELOG6"].."\n\n"..L["CHANGELOG7"].."\n\n"..L["CHANGELOG8"].."\n\n"..L["CHANGELOG9"].."\n\n"..L["CHANGELOG10"]);

		local logHeight = CommDKP.ChangeLogDisplay.ChangeLogHeader:GetHeight() + CommDKP.ChangeLogDisplay.Notes:GetHeight() + CommDKP.ChangeLogDisplay.VerNumber:GetHeight() + CommDKP.ChangeLogDisplay.ChangeLogText:GetHeight();
		CommDKP.ChangeLogDisplay:SetSize(800, logHeight);  -- resize container
	end
	---------------------------------------
	-- VERSION IDENTIFIER
	---------------------------------------
	local c = CommDKP:GetThemeColor();
	CommDKP.UIConfig.Version = CommDKP.UIConfig.TitleBar:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
	CommDKP.UIConfig.Version:ClearAllPoints();
	CommDKP.UIConfig.Version:SetFontObject("CommDKPSmallCenter");
	CommDKP.UIConfig.Version:SetScale("0.9")
	CommDKP.UIConfig.Version:SetTextColor(c[1].r, c[1].g, c[1].b, 0.5);
	CommDKP.UIConfig.Version:SetPoint("BOTTOMRIGHT", CommDKP.UIConfig.TitleBar, "BOTTOMRIGHT", -8, 4);
	CommDKP.UIConfig.Version:SetText(core.SemVer); 

	CommDKP.UIConfig:Hide(); -- hide menu after creation until called.
	CommDKP:FilterDKPTable(core.currentSort)   -- initial sort and populates data values in DKPTable.Rows{} CommDKP:FilterDKPTable() -> CommDKP:SortDKPTable() -> CommDKP:DKPTable_Update()
	core.Initialized = true
	return CommDKP.UIConfig;
end
