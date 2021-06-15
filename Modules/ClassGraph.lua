local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;


function CommDKP:ClassGraph()

	local graph;

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		graph = CreateFrame("Frame", "CommDKPClassIcons", CommDKP.ConfigTab1)
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		graph = CreateFrame("Frame", "CommDKPClassIcons", CommDKP.ConfigTab1, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end

	graph:SetPoint("TOPLEFT", CommDKP.ConfigTab1, "TOPLEFT", 0, 0)
	graph:SetBackdropColor(0,0,0,0)
	graph:SetSize(460, 495)

	local icons = {}
	graph.icons = icons;
	local classCount = {}
	local perc_height = {}
	local perc = {}
	local BarMaxHeight = 400
	local BarWidth = 25

	for k, v in pairs(core.classes) do
		local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), v)
		if classSearch and #classSearch > 0 then
			tinsert(classCount, #classSearch)
			local classPerc = CommDKP_round(#classSearch / #CommDKP:GetTable(CommDKP_DKPTable, true), 4);
			tinsert(perc, classPerc * 100)
			local adjustBar = BarMaxHeight * classPerc;
			tinsert(perc_height, adjustBar)
		else
			tinsert(classCount, 0)
			local classPerc = 0;
			tinsert(perc, 0)
			local adjustBar = 3;
			tinsert(perc_height, adjustBar)
		end
	end

	for i=1, 9 do
		graph.icons[i] = graph:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
		if i==1 then
	  		graph.icons[i]:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", 74, 40);
		else
			graph.icons[i]:SetPoint("LEFT", graph.icons[i-1], "RIGHT", 15, 0);
		end
  		graph.icons[i]:SetColorTexture(0, 0, 0, 1)
  		graph.icons[i]:SetSize(28, 28);

		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			graph.icons[i].bar = CreateFrame("Frame", "CommDKP"..i.."Graph", graph)
		elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
			graph.icons[i].bar = CreateFrame("Frame", "CommDKP"..i.."Graph", graph, BackdropTemplateMixin and "BackdropTemplate" or nil)
		end
  		
		graph.icons[i].bar:SetPoint("BOTTOM", icons[i], "TOP", 0, 5)
		graph.icons[i].bar:SetBackdropBorderColor(1,1,1,0)
  		graph.icons[i].bar:SetSize(BarWidth, perc_height[i])
  		graph.icons[i].bar:SetBackdrop({
			bgFile   = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\graph-bar", tile = false,
			insets = { left = 1, right = 1, top = 1, bottom = 1}
		});
  		graph.icons[i]:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes");

  		local c = CommDKP:GetCColors(core.classes[i])
		graph.icons[i].bar:SetBackdropColor(c.r, c.g, c.b, 1)

		graph.icons[i].percentage = graph.icons[i].bar:CreateFontString(nil, "OVERLAY")
		graph.icons[i].percentage:SetPoint("BOTTOM", graph.icons[i].bar, "TOP", 0, 3)
		graph.icons[i].percentage:SetFontObject("CommDKPSmallCenter")
		graph.icons[i].percentage:SetText(CommDKP_round(perc[i] or 0, 1).."%")
		graph.icons[i].percentage:SetTextColor(1, 1, 1, 1)

		graph.icons[i].count = graph.icons[i].bar:CreateFontString(nil, "OVERLAY")
		graph.icons[i].count:SetPoint("BOTTOM", graph.icons[i].bar, "BOTTOM", 0, -55)
		graph.icons[i].count:SetFontObject("CommDKPSmallCenter")
		graph.icons[i].count:SetText(classCount[i])
		graph.icons[i].count:SetTextColor(1, 1, 1, 1)

		local className = core.classes[i] or "nil";

		local coords = CLASS_ICON_TCOORDS[className]
		
		graph.icons[i]:SetTexCoord(unpack(coords))

		--CommDKP.ConfigTab2.header:SetScale(1.2)
	end

	return graph;
end

function CommDKP:ClassGraph_Update()
	local classCount = {}
	local perc_height = {}
	local perc = {}
	local BarMaxHeight = 400
	local BarWidth = 25

	for k, v in pairs(core.classes) do
		local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), v)
		if classSearch and #classSearch > 0 then
			tinsert(classCount, #classSearch)
			local classPerc = CommDKP_round(#classSearch / #CommDKP:GetTable(CommDKP_DKPTable, true), 4);
			tinsert(perc, classPerc * 100)
			local adjustBar = BarMaxHeight * classPerc;
			tinsert(perc_height, adjustBar)
		else
			tinsert(classCount, 0)
			local classPerc = 0;
			tinsert(perc, 0)
			local adjustBar = 3;
			tinsert(perc_height, adjustBar)
		end
	end

	for i=1, 8 do
  		core.ClassGraph.icons[i].bar:SetSize(BarWidth, perc_height[i])
		core.ClassGraph.icons[i].percentage:SetText(CommDKP_round(perc[i], 1).."%")
		core.ClassGraph.icons[i].count:SetText(classCount[i])
	end
end
