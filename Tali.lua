Tali = LibStub("AceAddon-3.0"):NewAddon("Tali", "AceEvent-3.0", "AceConsole-3.0", "AceComm-3.0")

-- == local VERSION = "0.0.1 alpha" == --

-- == TO DO LIST == --
--
-- Add proper AMR values instead of the current ones (which seem weird!) which kinda work
--
-- Crap stat support (Avoidance / Speed / Leach)
--
-- Between-spec support. Eg. If it's an item that has *both* int/agility 
-- but one isn't active "pretend" it is (for calculating the off-specs correctly)
--
-- Item Proc support (Trinket Support!)
--
-- Main-hand + offhand VS. 2h (for spell casters)
--
-- Set bonus support
--
-- =================================== --

AceGUI = LibStub("AceGUI-3.0")
local TipHooker = LibStub("LibTipHooker-1.1")
local libS = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local libCE = libC:GetAddonEncodeTable()
local AceConfig = LibStub("AceConfig-3.0")
local tablePrio = {}

------------------------------------------------------------------------------------------------------------------------

function Tali:OnInitialize()
	Tali.enabled = true
	local guildName = GetGuildInfo(UnitName("player"))
	self.db = LibStub("AceDB-3.0"):New("TaliDB1", defaults)
	Tali.db.profile.isOpen = false
	Tali:RegisterChatCommand("", "ChatCommand")
end

------------------------------------------------------------------------------------------------------------------------

function Tali:OnEnable()
end

------------------------------------------------------------------------------------------------------------------------

function Tali:ChatCommand(input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("Tali")
	elseif input == "enable" then
		Tali:Enable()
		Tali:Print("Tali is now Enabled")
	elseif input == "disable" then
		Tali:Disable()
		Tali:Print("Tali is now Disabled")
	end
end

------------------------------------------------------------------------------------------------------------------------

-- The while loop below replaces something like this and is fantastic!
-- if ( ShoppingTooltip1:IsShown() ) then NewTooltip(ShoppingTooltip1) end
-- if ( ShoppingTooltip2:IsShown() ) then NewTooltip(ShoppingTooltip2) end
-- if ( ShoppingTooltip3:IsShown() ) then NewTooltip(ShoppingTooltip3) end
-- if ( ShoppingTooltip4:IsShown() ) then NewTooltip(ShoppingTooltip4) end
-- if ( ShoppingTooltip5:IsShown() ) then NewTooltip(ShoppingTooltip5) end
-- if ( ShoppingTooltip6:IsShown() ) then NewTooltip(ShoppingTooltip6) end
-- if ( ShoppingTooltip7:IsShown() ) then NewTooltip(ShoppingTooltip7) end

function Tali.OnTooltipSetItem(tooltip, ...)
	-- target the compare tooltips (ShoppingTooltip1 & ShoppingTooltip2)
	local n = 7 -- an arbitrary number, though I think only 2 are allowed by default
	while(n > 0) do
		local string = "ShoppingTooltip" .. n
		if ( _G[string] ~= nil and _G[string]:IsShown() ) then
			NewTooltip( _G[string] )
		end
		n = n - 1
	end

	local _, linkTool = tooltip:GetItem()
	if (IsEquippableItem(linkTool)) then
		local sName, sLink, iRarity, dropppediLevel, _, sType, sSubType, _, sEquip, sTexture = GetItemInfo(linkTool)
		NewTooltip(tooltip)
	end

-- local prof1, prof2, prof3, prof4, prof5, prof6 = GetProfessions()

-- --if (prof1 ~= nil) then
--    name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof1)
--    CastSpellByName(name)
--end

-- if (prof2 ~= nil) then
--    name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof2)
--    CastSpellByName(name)
-- end

-- if (prof3 ~= nil) then
--    name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof3)
--    CastSpellByName(name)
-- end

-- if (prof4 ~= nil) then
--    name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof4)
--    CastSpellByName(name)
-- end

-- if (prof5 ~= nil) then
--    name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof5)
--    CastSpellByName(name)
-- end

-- if (prof6 ~= nil) then
--    name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof6)
--    CastSpellByName(name)
-- end

-- local prof1, prof2, prof3, prof4, prof5, prof6 = GetProfessions()

-- local n = 6 -- an arbitrary number, though I think only 2 are allowed by default
-- while(n > 0) do
--    local warper = "prof" .. n
--    print(warper)
--    print(_G[warper])
--    if (warper ~= nil) then
      
--       --name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine,
--       -- skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(_G[warper])
      
--       --CastSpellByName(name)
--    end
--    n = n - 1
-- end

end -- function end

------------------------------------------------------------------------------------------------------------------------

function NewTooltip(tooltip)
	tablePrio = Tali:PriorityTable()

	local _, sLink =  tooltip:GetItem()
	calculateItemValueForMyCharacter(sLink)
	EquipPrioSelf() -- remove other classes besides self
	sort(tablePrio, function(a,b) return a.prio > b.prio end)
	AddTooltip(tooltip)

	table.wipe(tablePrio)
end

------------------------------------------------------------------------------------------------------------------------

function AddTooltip(tooltip)
	tooltip:AddLine("|cffffcc00 ---===--- |r|cff6666ffT|r|cff9966ffa|r|cffcc66ffl|r|cffff66ffi|r|cffffcc00 ---===---|r") 
	for _, v in ipairs(tablePrio) do
		if (v.prio > 0) then
			local R, G, B = 0, 1, 1
			local currentSpec = GetSpecialization()
			local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
			if (v.spec == currentSpecName) then
				B = 0
			end

			tooltip:AddLine(v.prio.." - "..v.spec, R, G, B) -- important line		

			local tipTextLeft = tooltip:GetName().."TextLeft"
			tooltip:Show()
			for i = 2, tooltip:NumLines() do
				local fontString = _G[tipTextLeft..i] 
				_, relativeTo, _, xOfs, _ = fontString:GetPoint(0)
				fontString:ClearAllPoints()
				fontString:SetPoint("TOPLEFT",relativeTo, "BOTTOMLEFT", xOfs, -2)
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------

TipHooker:Hook(Tali.OnTooltipSetItem, "item")

------------------------------------------------------------------------------------------------------------------------

function EquipPrioSelf()
	local class = UnitClass("player")
	for i, v in pairs(tablePrio) do
		if (v.class ~= class) then
			v.prio = 0
		end
	end
end

------------------------------------------------------------------------------------------------------------------------

-- calculateItemValueForMyCharacter(itemLink) uses the Tali:PriorityTable() to calculate the value of an item.
-- @itemLink - the item you wish to tally 
function calculateItemValueForMyCharacter(itemLink) 
   local itemStats = {} -- empty array for stats
   local dummyArrayForGetItemStats = {}
   itemStats = GetItemStats(itemLink, dummyArrayForGetItemStats)

   for key, value in pairs(itemStats) do
   		if (key == 'EMPTY_SOCKET_PRISMATIC') then
   			local name, link = GetItemGem(itemLink, 1)
   			--print(name) -- YOU  ARE HER
   			local modifier = "none"
   			local val = 0

   			-- switch of all gems --
   			if (name == 'Deadly Eye of Prophecy') then modifier = 'Critical Strike' val = 150
   			elseif (name == 'Masterful Shadowruby') then modifier = 'Mastery' val = 150
   			elseif (name == 'Quick Dawnlight') then modifier = 'Haste' val = 150
   			elseif (name == 'Versatile Maelstrom Sapphire') then modifier = 'Versatility' val = 150
   			elseif (name == 'Deadly Deep Amber' ) then modifier = 'Critical Strike' val = 100
   			elseif (name == "Masterful Queen's Opal") then modifier = 'Mastery' val = 100
   			elseif (name == 'Quick Azsunite') then modifier = 'Haste' val = 100
   			elseif (name == 'Versatile Skystone') then modifier = 'Versatility' val = 100
   			elseif (name == "Saber's Eye of Intellect") then modifier = 'Intellect' val = 200
   			elseif (name == "Saber's Eye of Strength") then modifier = 'Strength' val = 200
   			elseif (name == "Saber's Eye of Agility") then modifier = 'Agility' val = 200
   			else
   				modifier = none val = 0
   			end
   			--print(modifier) -- YOU ARE HERE
			for _, classSpec in pairs(tablePrio) do 
				for statName, statWeight in pairs(classSpec) do 
					--print(statName, statWeight)
					if (statName == modifier) then
						classSpec.prio = classSpec.prio + (val * statWeight)
						--print (statWeight, val)
					end 
				end
			end

   		end	
   	end

   for _, classSpec in pairs(tablePrio) do -- our database
      for statName, statWeight in pairs(classSpec) do -- a line in our database
         for key, value in pairs(itemStats) do 	-- A pair in the line
            --print(statName, _G[key], key, value, statWeight)
            if (statName == _G[key]) then
               classSpec.prio = classSpec.prio + (value * statWeight) -- calculate the value of this stat and add it
            end
         end
      end
   end
end

------------------------------------------------------------------------------------------------------------------------