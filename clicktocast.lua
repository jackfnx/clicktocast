--
-- clicktocast - clickcast module
--

clicktocast		= LibStub("AceAddon-3.0"):NewAddon("clicktocast", "AceEvent-3.0")
clicktocast.F	= {}
clicktocast.CLICK_TO_CAST_SPELL = 0


function clicktocast:OnInitialize()
	local _, _, cls = UnitClass("player")
	if cls == 3 then -- only for hunter
		clicktocast.CLICK_TO_CAST_SPELL = 34477
	else
		return
	end
	-- clicktocast tries to wait for all variables to be loaded before configuring itself.
	clicktocast:RegisterEvent("VARIABLES_LOADED")
end

function clicktocast:VARIABLES_LOADED()
	clicktocast:UnregisterEvent("VARIABLES_LOADED")
	clicktocast.globalConfigs = {}
	clicktocast.globalConfigs["MOD_CLICKTOCAST"] = clicktocast.Setup

	clicktocast.ReconfigureClickToCast()
end

-- This is the reconfiguration function that gets called when ClickToCast needs to be globally reconfigured.
function clicktocast.ReconfigureClickToCast()
	local key, val
	for key, val in pairs(clicktocast.globalConfigs) do
		val()
	end
	--collectgarbage("collect")
end

function clicktocast.CanUseClicktocast(spell)
	-- Check if they can use the spell, maybe they have not trained it...
	local spellExists = C_Spell.DoesSpellExist(spell)
	if (not spellExists) then
		if (select(1, C_Spell.GetSpellCooldown(spell)) == 0) then
			return false
		end
	end
	-- Conditions met, we're good to go!
	return true
end

function clicktocast.Setup()
    local spellToCast = C_Spell.GetSpellName(clicktocast.CLICK_TO_CAST_SPELL)
	clicktocast.macroStr = "/cast [@mouseover,exists,nounithasvehicleui,novehicleui] "..spellToCast

	if InCombatLockdown() then
		-- Be sure we don't register this event more than one time, ever!
		clicktocast:UnregisterEvent("PLAYER_REGEN_ENABLED")
		clicktocast:RegisterEvent("PLAYER_REGEN_ENABLED")
		clicktocast.delayedUpdate = true
		return
	else
		clicktocast.delayedUpdate = nil
	end

	-- Check they are proper level and have learned the spell, no point doing anything if they can't!
	if not clicktocast.CanUseClicktocast(clicktocast.CLICK_TO_CAST_SPELL) then return end

	-- Deconstruction
	clicktocast:UnregisterEvent("PLAYER_REGEN_ENABLED")

	if clicktocast.clicktocastFrames then
		for key, val in pairs(clicktocast.clicktocastFrames) do
			if _G[key] and (_G[key]:GetAttribute("macrotext") == clicktocast.macroStr) then
				_G[key]:SetAttribute("type2", nil)
				_G[key]:SetAttribute("macrotext", nil)
			end
		end
	end

	clicktocast.clicktocastFrames = nil

	if clicktocast.F.Core then
		clicktocast.F.Core:Hide()
		clicktocast.F.Core:UnregisterAllEvents()
		clicktocast.F.Core:SetScript("OnUpdate", nil)
		clicktocast.F.Core:SetParent(nil)
	end

	if clicktocast.F.Core then -- This causes major stacking errors if we don't unregister first!
		clicktocast.F.Core:UnregisterAllEvents()
		clicktocast.F.Core:SetScript("OnUpdate", nil)
	end

	-- Construction
	local ctcFrames = {}
	ctcFrames[#ctcFrames+1] = "target"
	ctcFrames[#ctcFrames+1] = "pet"
	ctcFrames[#ctcFrames+1] = "focus"
	ctcFrames[#ctcFrames+1] = "targettarget"

	for i=1, 40 do
		if i <= 4 then
			ctcFrames[#ctcFrames+1] = "party"..i
			ctcFrames[#ctcFrames+1] = "partypet"..i
		end
		if i <= 40 then
			ctcFrames[#ctcFrames+1] = "raid"..i
			ctcFrames[#ctcFrames+1] = "raidpet"..i
		end
	end

	if (#ctcFrames == 0) then
		ctcFrames = {}
		return
	end

	-- This is a fix for Grid, add's a delay to when an update is triggered
	clicktocast.F.Core = clicktocast.F.Core or CreateFrame("Frame", "clicktocast_CLICKTOCAST", UIParent) -- Handler frame, nothing more.
	clicktocast.clicktocastFrames = {}

--[[
-- AUTHOR NOTE TO OTHER AUTHORS: If you add "<frame>.cmctc_unit" variable to a frame that should be clickable for clicktocast spells,
-- this will make clicktocast easily pickup your frames with no guess work...
--]]
    local frame = EnumerateFrames()
	while frame do
		if (frame:GetName()) then
			if (frame.cmctc_unit) and tContains(ctcFrames, frame.cmctc_unit) then
				clicktocast.clicktocastFrames[frame:GetName()] = frame:GetName()
				_G[frame:GetName()]:SetAttribute("type2", "macro")
				_G[frame:GetName()]:SetAttribute("macrotext", clicktocast.macroStr)
			-- TukUI
			elseif (strsub(frame:GetName(),1,5) == "Tukui") and (frame.unit) and (tContains(ctcFrames, frame.unit) ) then
				clicktocast.clicktocastFrames[frame:GetName()] = frame:GetName()
				_G[frame:GetName()]:SetAttribute("type2", "macro")
				_G[frame:GetName()]:SetAttribute("macrotext", clicktocast.macroStr)
			-- ElvUI
			elseif (strsub(frame:GetName(),1,5) == "ElvUF") and (frame.unit) and (tContains(ctcFrames, frame.unit) ) then
				clicktocast.clicktocastFrames[frame:GetName()] = frame:GetName()
				_G[frame:GetName()]:SetAttribute("type2", "macro")
				_G[frame:GetName()]:SetAttribute("macrotext", clicktocast.macroStr)
			-- Perl Classic
			elseif (not (strsub(frame:GetName(),1,5) == "ElvUF") ) and (frame:GetAttribute("unit") and tContains(ctcFrames, frame:GetAttribute("unit") ) ) then
				clicktocast.clicktocastFrames[frame:GetName()] = frame:GetName()
				_G[frame:GetName()]:SetAttribute("type2", "macro")
				_G[frame:GetName()]:SetAttribute("macrotext", clicktocast.macroStr)
			-- Normal frames
			elseif (frame.unit and (frame.menu or (strsub(frame:GetName(),1,4) == "Grid") ) and tContains(ctcFrames, frame.unit) ) then
				clicktocast.clicktocastFrames[frame:GetName()] = frame:GetName()
				_G[frame:GetName()]:SetAttribute("type2", "macro")
				_G[frame:GetName()]:SetAttribute("macrotext", clicktocast.macroStr)
			-- XPerl - it does not use standard setup for frames so we have to do this the hard way
			elseif (frame.partyid and (frame.menu or (strsub(frame:GetName(),1,5) == "XPerl") ) and tContains(ctcFrames, frame.partyid) ) then
				clicktocast.clicktocastFrames[frame:GetName()] = frame:GetName()
				_G[frame:GetName()]:SetAttribute("type2", "macro")
				_G[frame:GetName()]:SetAttribute("macrotext", clicktocast.macroStr)

				if _G[frame:GetName().."nameFrame"] then -- Need to add ctc to the name frame too.  GG Non-standard frame stuff
					clicktocast.clicktocastFrames[frame:GetName().."nameFrame"] = frame:GetName().."nameFrame"
					_G[frame:GetName().."nameFrame"]:SetAttribute("type2", "macro")
					_G[frame:GetName().."nameFrame"]:SetAttribute("macrotext", clicktocast.macroStr)
				end
			end
		end
		frame = EnumerateFrames(frame)
	end

	clicktocast.F.Core:RegisterEvent("GROUP_ROSTER_UPDATE")
	clicktocast.F.Core:RegisterEvent("RAID_ROSTER_UPDATE")
	clicktocast.F.Core:RegisterUnitEvent("UNIT_PET", "player")
	clicktocast.F.Core:SetScript("OnEvent", function(self, event, ...) clicktocast.Setup() end)
end

function clicktocast:PLAYER_REGEN_ENABLED()
	if clicktocast.delayedUpdate then
		clicktocast.Setup()
		clicktocast:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end