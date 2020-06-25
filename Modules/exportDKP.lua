local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;



local function GenerateDKPTables(table, format)
	local ExportString;
	local ExportDefinition;

	if format == "HTML" then
		if table == CommDKP:GetTable(CommDKP_DKPTable, true) then
			ExportString = "<html>\n<script>\nfunction openTab(tabName) {\n   var i;\n   var x = document.getElementsByClassName(\"tab\");\n   for (i = 0; i < x.length; i++) {\n      x[i].style.display = \"none\";\n   }\n   document.getElementById(tabName).style.display = \"block\";\n}\n</script>\n";
			ExportString = ExportString.."<script>var whTooltips = {colorLinks: true, iconizeLinks: true, renameLinks: true};</script><script src=\"https://wow.zamimg.com/widgets/power.js\"></script>\n"
			ExportString = ExportString.."<style>\nhtml { background-color: #000; };\n.divTable{ display: table; float: left; margin: 10px 10px; }\n.divTableRow { display: table-row; background-color: #000}\n.divTableRow:hover { background-color: #222; }\n.divTableHeading { background-color: #EEE; display: table-header-group; }\n.divTableCell, .divTableHead { border: 1px solid #999999; display: table-cell; padding: 3px 10px; }\n";
			ExportString = ExportString..".divPlayer { border: 1px solid #999999; display: table-cell; width: 700px; padding: 3px 10px; text-align: left; vertical-align: middle; word-wrap: normal; color: #ffffff; }\n.divClass { border: 1px solid #999999; display: table-cell; padding: 3px 10px; text-align: center; vertical-align: middle; color: #ffffff; }\n.divDKP { border: 1px solid #999999; display: table-cell; width: 200px%; padding: 3px 10px; text-align: center; vertical-align: middle; color: #ffffff; }\n"
			ExportString = ExportString..".divPlayerHeader { border: 1px solid #999999; display: table-cell; font-weight: bold; width: 50%; padding: 3px 10px; text-align: left; background-color: #bbb; }\n.divClassHeader { border: 1px solid #999999; display: table-cell; font-weight: bold; width: 150px; padding: 3px 10px; text-align: center; background-color: #bbb; }\n.divDKPHeader { border: 1px solid #999999; display: table-cell; font-weight: bold; width: 30%; padding: 3px 10px; text-align: center; background-color: #bbb; }\n"
			ExportString = ExportString..".divTableHeading { background-color: #EEE; display: table-header-group; font-weight: bold; }\n.divTableFoot { background-color: #EEE; display: table-footer-group; font-weight: bold; }\n.divTableBody { display: table-row-group; }\n</style>\n\n"
			ExportString = ExportString.."<br /><br />\n<div>\n   <button onclick=\"openTab('DKP')\">DKP Table</button>\n   <button onclick=\"openTab('DKPHistory')\">DKP History</button>\n   <button onclick=\"openTab('LootHistory')\">Loot History</button>\n</div>\n<br /><br />\n"

			ExportString = ExportString.."<div id=\"DKP\" class=\"tab\"><div class=\"divTable\" style=\"width: 30%;border: 1px solid #000;\">\n   <div class=\"divTableBody\">\n      <div class=\"divTableRow\">\n         <div class=\"divPlayerHeader\">Player</div>\n         <div class=\"divClassHeader\">Class</div>\n         <div class=\"divDKPHeader\">DKP</div>\n      </div>\n"

			for i=1, #CommDKP:GetTable(CommDKP_DKPTable, true) do
				ExportString = ExportString.."      <div class=\"divTableRow\">\n         <div class=\"divPlayer\">"..CommDKP:GetTable(CommDKP_DKPTable, true)[i].player.."</div>\n         <div class=\"divClass\" style=\"width: 150px;\"><img src=\"https://wow.zamimg.com/images/wow/icons/large/classicon_"..strlower(CommDKP:GetTable(CommDKP_DKPTable, true)[i].class)..".jpg\" height=\"24\" width=\"24\" /></div>\n         <div class=\"divDKP\">"..CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp.."</div>\n      </div>\n"
			end

			ExportString = ExportString.."   </div>\n</div>\n</div>"
		elseif table == CommDKP:GetTable(CommDKP_DKPHistory, true) then
			local numrows;

			if #CommDKP:GetTable(CommDKP_DKPHistory, true) > 200 then
				numrows = 200;
			else
				numrows = #CommDKP:GetTable(CommDKP_DKPHistory, true)
			end

			ExportString = "<div id=\"DKPHistory\" class=\"tab\" style=\"display:none;\"><div class=\"divTable\" style=\"width: 95%;border: 1px solid #000;\">\n   <div class=\"divTableBody\">\n      <div class=\"divTableRow\">\n         <div class=\"divPlayerHeader\">Players</div>\n         <div class=\"divClassHeader\" style=\"width: 4%;\">DKP</div>\n         <div class=\"divDKPHeader\">Date/Reason</div>\n      </div>\n"

			for i=1, numrows do
				ExportString = ExportString.."      <div class=\"divTableRow\">\n         <div class=\"divPlayer\" style=\"font-size: 0.7em; width: 71%;\">"..gsub(CommDKP:GetTable(CommDKP_DKPHistory, true)[i].players, ",", ", ").."</div>\n         <div class=\"divClass\" style=\"width: 4%;\">"..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].dkp.."</div>\n         <div class=\"divDKP\" style=\"width: 25%; font-size: 0.7em;\">"..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].reason.."<br />("..date("%m/%d/%y %H:%M:%S", CommDKP:GetTable(CommDKP_DKPHistory, true)[i].date)..") </div>\n      </div>\n"
			end
			ExportString = ExportString.."   </div>\n</div>\n</div>"

		elseif table == CommDKP:GetTable(CommDKP_Loot, true) then
			local numrows;

			if #CommDKP:GetTable(CommDKP_Loot, true) > 200 then
				numrows = 200;
			else
				numrows = #CommDKP:GetTable(CommDKP_Loot, true)
			end
			ExportString = "<div id=\"LootHistory\" class=\"tab\" style=\"display:none;\"><div class=\"divTable\" style=\"width: 50%;border: 1px solid #000;\">\n   <div class=\"divTableBody\">\n      <div class=\"divTableRow\">\n         <div class=\"divPlayerHeader\">Loot</div>\n         <div class=\"divClassHeader\">Player</div>\n         <div class=\"divDKPHeader\">From</div>\n      </div>\n"
			for i=1, numrows do
				local cur = CommDKP:GetTable(CommDKP_Loot, true)[i].loot
				local itemNumber = strsub(cur, string.find(cur, "Hitem:")+6, string.find(cur, ":", string.find(cur, "Hitem:")+6)-1)
				ExportString = ExportString.."      <div class=\"divTableRow\">\n         <div class=\"divPlayer\" style=\"width: 40%;\"><a href=\"https://classic.wowhead.com/item="..itemNumber.."\" data-wowhead=\"item="..itemNumber.."\"></a> ("..CommDKP:GetTable(CommDKP_Loot, true)[i].cost.." DKP)</div>\n         <div class=\"divClass\" style=\"width: 20%;\">"..CommDKP:GetTable(CommDKP_Loot, true)[i].player.."</div>\n         <div class=\"divDKP\" style=\"width: 40%; font-size: 0.7em;\">"..CommDKP:GetTable(CommDKP_Loot, true)[i].zone..": "..CommDKP:GetTable(CommDKP_Loot, true)[i].boss.."<br />("..date("%m/%d/%y %H:%M:%S", CommDKP:GetTable(CommDKP_Loot, true)[i].date)..") </div>\n      </div>\n"
			end
			ExportString = ExportString.."   </div>\n</div>\n</div>\n</html>"
		end
	elseif format == "CSV" then
		if table == CommDKP:GetTable(CommDKP_DKPTable, true) then
			Headers = "player,class,DKP,previousDKP,lifetimeGained,lifetimeSpent\n"
			ExportString = Headers.."";
			for i=1, #CommDKP:GetTable(CommDKP_DKPTable, true) do
				if i == #CommDKP:GetTable(CommDKP_DKPTable, true) then
					ExportString = ExportString..CommDKP:GetTable(CommDKP_DKPTable, true)[i].player..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].class..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].previous_dkp..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_gained..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_spent;
				else
					ExportString = ExportString..CommDKP:GetTable(CommDKP_DKPTable, true)[i].player..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].class..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].previous_dkp..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_gained..","..CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_spent.."\n";
				end
			end
		elseif table == CommDKP:GetTable(CommDKP_DKPHistory, true) then
			local numrows;

			if #CommDKP:GetTable(CommDKP_DKPHistory, true) > 200 then
				numrows = 200;
			else
				numrows = #CommDKP:GetTable(CommDKP_DKPHistory, true)
			end

			Headers = "player,DKP,date,reason\n"
			ExportString = Headers.."";
			for i=1, numrows do
				local PlayerString = strsub(CommDKP:GetTable(CommDKP_DKPHistory, true)[i].players, 1, -2)

				if i == numrows then
					ExportString = ExportString.."\""..PlayerString.."\""..","..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].dkp..","..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].date..",".."\""..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].reason.."\"";
				else
					ExportString = ExportString.."\""..PlayerString.."\""..","..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].dkp..","..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].date..",".."\""..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].reason.."\"".."\n";
				end
			end
		elseif table == CommDKP:GetTable(CommDKP_Loot, true) then
			local numrows;

			if #CommDKP:GetTable(CommDKP_Loot, true) > 200 then
				numrows = 200;
			else
				numrows = #CommDKP:GetTable(CommDKP_Loot, true)
			end
			
			Headers = "player,itemName,itemNumber,zone,boss,date,cost\n"
			ExportString = Headers.."";
			for i=1, numrows do
				local cur = CommDKP:GetTable(CommDKP_Loot, true)[i].loot
				local itemNumber = strsub(cur, string.find(cur, "Hitem:")+6, string.find(cur, ":", string.find(cur, "Hitem:")+6)-1)
				local itemName = strsub(cur, string.find(cur, "::|h%[")+5, string.find(cur, "%]", string.find(cur, "::|h%[")+5)-1)
				
				if i == numrows then
					ExportString = ExportString..CommDKP:GetTable(CommDKP_Loot, true)[i].player..",".."\""..itemName.."\""..","..itemNumber..",".."\""..CommDKP:GetTable(CommDKP_Loot, true)[i].zone.."\""..","..CommDKP:GetTable(CommDKP_Loot, true)[i].boss..","..CommDKP:GetTable(CommDKP_Loot, true)[i].date..","..CommDKP:GetTable(CommDKP_Loot, true)[i].cost;
				else
					ExportString = ExportString..CommDKP:GetTable(CommDKP_Loot, true)[i].player..",".."\""..itemName.."\""..","..itemNumber..",".."\""..CommDKP:GetTable(CommDKP_Loot, true)[i].zone.."\""..","..CommDKP:GetTable(CommDKP_Loot, true)[i].boss..","..CommDKP:GetTable(CommDKP_Loot, true)[i].date..","..CommDKP:GetTable(CommDKP_Loot, true)[i].cost.."\n";
				end
			end
		end
	elseif format == "XML" then
		if table == CommDKP:GetTable(CommDKP_DKPTable, true) then
			ExportString = "<dkptable>\n";
			for i=1, #CommDKP:GetTable(CommDKP_DKPTable, true) do
				ExportString = ExportString.."    <dkpentry>\n        <player>"..CommDKP:GetTable(CommDKP_DKPTable, true)[i].player.."</player>\n        <class>"..CommDKP:GetTable(CommDKP_DKPTable, true)[i].class.."</class>\n        <dkp>"..CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp.."</dkp>\n        <lifetimegained>"..CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_gained.."</lifetimegained>\n        <lifetimespent>"..CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_spent.."</lifetimespent>\n    </dkpentry>\n";
			end
			ExportString = ExportString.."</dkptable>"
		elseif table == CommDKP:GetTable(CommDKP_DKPHistory, true) then
			local numrows;

			if #CommDKP:GetTable(CommDKP_DKPHistory, true) > 200 then
				numrows = 200;
			else
				numrows = #CommDKP:GetTable(CommDKP_DKPHistory, true)
			end

			ExportString = "<dkphistory>\n";
			for i=1, numrows do
				local deletes;
				local deletedby;
				if CommDKP:GetTable(CommDKP_DKPHistory, true)[i].deletes == nil then 
					deletes = ''
				else
					deletes = CommDKP:GetTable(CommDKP_DKPHistory, true)[i].deletes
				end
	
				if CommDKP:GetTable(CommDKP_DKPHistory, true)[i].deletedby == nil then 
					deletedby = ''
				else
					deletedby = CommDKP:GetTable(CommDKP_DKPHistory, true)[i].deletedby
				end
	
				ExportString = ExportString.."    <historyentry>\n        <playerstring>"..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].players.."</playerstring>\n        <dkp>"..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].dkp.."</dkp>\n        <timestamp>"..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].date.."</timestamp>\n        <reason>"..CommDKP:GetTable(CommDKP_DKPHistory, true)[i].reason.."</reason>\n        <deletes>"..deletes.."</deletes>\n        <deletedby>"..deletedby.."</deletedby>\n    </historyentry>\n";
			end
			ExportString = ExportString.."</dkphistory>";
		elseif table == CommDKP:GetTable(CommDKP_Loot, true) then
			local numrows;

			if #CommDKP:GetTable(CommDKP_Loot, true) > 200 then
				numrows = 200;
			else
				numrows = #CommDKP:GetTable(CommDKP_Loot, true)
			end
			
			ExportString = "<loothistory>\n";
			for i=1, numrows do
				local cur = CommDKP:GetTable(CommDKP_Loot, true)[i].loot
				local itemNumber = strsub(cur, string.find(cur, "Hitem:")+6, string.find(cur, ":", string.find(cur, "Hitem:")+6)-1)
				local itemName = strsub(cur, string.find(cur, "::|h%[")+5, string.find(cur, "%]", string.find(cur, "::|h%[")+5)-1)
				
				local deletes;
				local deletedby;
				if CommDKP:GetTable(CommDKP_Loot, true)[i].deletes == nil then 
					deletes = ''
				else
					deletes = CommDKP:GetTable(CommDKP_Loot, true)[i].deletes
				end
	
				if CommDKP:GetTable(CommDKP_Loot, true)[i].deletedby == nil then 
					deletedby = ''
				else
					deletedby = CommDKP:GetTable(CommDKP_Loot, true)[i].deletedby
				end
	
				ExportString = ExportString.."    <lootentry>\n        <player>"..CommDKP:GetTable(CommDKP_Loot, true)[i].player.."</player>\n        <itemname>"..itemName.."</itemname>\n        <itemnumber>"..itemNumber.."</itemnumber>\n        <zone>"..CommDKP:GetTable(CommDKP_Loot, true)[i].zone.."</zone>\n        <boss>"..CommDKP:GetTable(CommDKP_Loot, true)[i].boss.."</boss>\n        <timestamp>"..CommDKP:GetTable(CommDKP_Loot, true)[i].date.."</timestamp>\n        <cost>"..CommDKP:GetTable(CommDKP_Loot, true)[i].cost.."</cost>\n        <deletes>"..deletes.."</deletes>\n        <deletedby>"..deletedby.."</deletedby>\n    </lootentry>\n";
			end
			ExportString = ExportString.."</loothistory>";
		end
	end


	CommDKPExportBoxEditBox:SetText(ExportString)
end

function CommDKP:ExportBox_Show(text)
    if not CommDKPExportBox then
        local f = CreateFrame("Frame", "CommDKPExportBox", UIParent)
        f:SetPoint("CENTER")
        f:SetSize(700, 590)
        
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
            edgeSize = 17,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue
        
        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)

        -- Close Button
		f.closeContainer = CreateFrame("Frame", "CommDKPTitle", f)
		f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
		f.closeContainer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
		});
		f.closeContainer:SetBackdropColor(0,0,0,0.9)
		f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
		f.closeContainer:SetSize(28, 28)

		f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)
		tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"
        
        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "CommDKPExportBoxScrollFrame", CommDKPExportBox, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 20, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -20)
        sf:SetPoint("BOTTOM", 0, 160)

        -- Description
        f.desc = f:CreateFontString(nil, "OVERLAY")
		f.desc:SetFontObject("CommDKPSmallLeft");
		f.desc:SetPoint("TOPLEFT", sf, "BOTTOMLEFT", 10, -10);
		f.desc:SetText("|CFFAEAEDDExport below one at a time in order. Copy all html and paste into local .html file one after the other. DKP and Loot History often take a few seconds to generate and will lock your screen briefly. As a result they are limited to the most recent 200 entries for each. All tables will be tabbed for convenience.|r");
		f.desc:SetWidth(sf:GetWidth()-30)
        
        -- EditBox
        local eb = CreateFrame("EditBox", "CommDKPExportBoxEditBox", CommDKPExportBoxScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        
        -- Resizable
        f:SetResizable(true)
        f:SetMinResize(650, 500)
        
        local rb = CreateFrame("Button", "CommDKPExportBoxResizeButton", CommDKPExportBox)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)
        
        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        
        rb:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                f:StartSizing("BOTTOMRIGHT")
            end
        end)
        rb:SetScript("OnMouseUp", function(self, button)
            f:StopMovingOrSizing()
            self:GetHighlightTexture():Show()
            eb:SetWidth(sf:GetWidth())
            desc:SetWidth(sf:GetWidth()-30)
        end)
        f:Show()

        -- Format DROPDOWN box 
        local CurFormat;

		f.FormatDropDown = CreateFrame("FRAME", "CommDKPModeSelectDropDown", f, "CommunityDKPUIDropDownMenuTemplate")
		f.FormatDropDown:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 55)
		UIDropDownMenu_SetWidth(f.FormatDropDown, 100)
		UIDropDownMenu_SetText(f.FormatDropDown, "Select Format")

		-- Create and bind the initialization function to the dropdown menu
		UIDropDownMenu_Initialize(f.FormatDropDown, function(self, level, menuList)
		local Format = UIDropDownMenu_CreateInfo()
			Format.func = self.SetValue
			Format.fontObject = "CommDKPSmallCenter"
			Format.text, Format.arg1, Format.checked, Format.isNotRadio = "HTML", "HTML", "HTML" == CurFormat, false
			UIDropDownMenu_AddButton(Format)
			Format.text, Format.arg1, Format.checked, Format.isNotRadio = "CSV", "CSV", "CSV" == CurFormat, false
			UIDropDownMenu_AddButton(Format)
			Format.text, Format.arg1, Format.checked, Format.isNotRadio = "XML", "XML", "XML" == CurFormat, false
			UIDropDownMenu_AddButton(Format)
		end)

		-- Dropdown Menu Function
		function f.FormatDropDown:SetValue(arg1)
			CurFormat = arg1;
			if arg1 == "HTML" then
				ExportDefinition = "|CFFAEAEDDExport below one at a time in order. Copy all html and paste into local .html file one after the other. DKP and Loot History often take a few seconds to generate and will lock your screen briefly. As a result they are limited to the most recent 200 entries for each. All tables will be tabbed for convenience.|r"
			elseif arg1 == "CSV" then
				ExportDefinition = "|CFFAEAEDDCSV can only be used for applications designed specifically to distribute each value to the correct variable. Generate them one at a time (in order) and copy/paste all contents, one after the other, and use as needed.|r"
			elseif arg1 == "XML" then
				ExportDefinition = "|CFFAEAEDDGenerate tables one at a time and copy/paste all contents into a new .xml file on your desktop. XML files are for use with web applications designed to parse this XML format.|r"
			end

			f.desc:SetText(ExportDefinition);
			UIDropDownMenu_SetText(f.FormatDropDown, CurFormat)
			CloseDropDownMenus()
		end

		f.FormatDropDown:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("Export Format", 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine("Select the format you wish to export data with.", 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.FormatDropDown:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		StaticPopupDialogs["NO_FORMAT"] = {
			text = "You do not have a format selected.",
			button1 = "Ok",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}

        f.GenerateDKPButton = CommDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -355, 20, "1) "..L["GENDKPTABLE"]);
		f.GenerateDKPButton:SetSize(150, 24)
		f.GenerateDKPButton:SetScript("OnClick", function()
			if CurFormat then
				GenerateDKPTables(CommDKP:GetTable(CommDKP_DKPTable, true), CurFormat)
			else
				StaticPopup_Show ("NO_FORMAT")
			end
		end)

		f.GenerateDKPHistoryButton = CommDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -200, 20, "2) "..L["GENDKPHIST"]);
		f.GenerateDKPHistoryButton:SetSize(150, 24)
		f.GenerateDKPHistoryButton:SetScript("OnClick", function()
			if CurFormat then
				GenerateDKPTables(CommDKP:GetTable(CommDKP_DKPHistory, true), CurFormat)
			else
				StaticPopup_Show ("NO_FORMAT")
			end
		end)

		f.GenerateDKPLootButton = CommDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -45, 20, "3) "..L["GENLOOTHIST"]);
		f.GenerateDKPLootButton:SetSize(150, 24)
		f.GenerateDKPLootButton:SetScript("OnClick", function()
			if CurFormat then
				GenerateDKPTables(CommDKP:GetTable(CommDKP_Loot, true), CurFormat)
			else
				StaticPopup_Show ("NO_FORMAT")
			end
		end)

		f.SelectAllButton = CommDKP:CreateButton("BOTTOMLEFT", f, "BOTTOMLEFT", 45, 20, L["SELECTALL"]);
		f.SelectAllButton:SetSize(100, 20)
		f.SelectAllButton:SetScript("OnClick", function()
			CommDKPExportBoxEditBox:HighlightText()
			CommDKPExportBoxEditBox:SetFocus()
		end)
    end
    
    if text then
        CommDKPExportBoxEditBox:SetText(text)
    end
    CommDKPExportBox:Show()
end

function CommDKP:ToggleExportWindow()
	CommDKP:ExportBox_Show()
end
