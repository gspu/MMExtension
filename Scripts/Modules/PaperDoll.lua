--[=[!File
To use, first place the PaperDol.txt file #[[https://github.com/GrayFace/MMExtension/tree/master/Misc/Paper%20Doll]]from here# corresponding to your game of choice into DataFiles folder (create it right next to Data folder of the game if it doesn't exist). Modifiy it as needed. You'll later distribute this file inside your mod's LOD achive.

Including the module:
!LUA[[
require'PaperDoll'
]]

]=]
local abs, floor, ceil, round, max, min = math.abs, math.floor, math.ceil, math.round, math.max, math.min
local i4, i2, i1, u4, u2, u1, pchar = mem.i4, mem.i2, mem.i1, mem.u4, mem.u2, mem.u1, mem.pchar

local mmver = Game.Version
local function mmv(...)
	return (select(mmver - 5, ...))
end
local function mm78(...)
	return (select(mmver - 5, nil, ...))
end

--!v Maps category name to a !lua[[function(i)]] that returns 'true' if player face number 'i' belongs to the category. Use #PaperDollAddBodies:# or #PaperDollAddRace:# to populate.
PaperDollCategories = {}
PaperDollGraphics = {}
--!v Specifies which pieces inherit item graphics by default. Default:
-- !Lua[[{ItemExtraHand = {hand2 = true, shield = true}}]]
-- For slots not specified here piece with empty name is the main one.
PaperDollMainPieces = {ExtraHand = {hand2 = true, shield = true}}
local PaperDollMainPiecesStd = {[''] = true}
--!v
PaperDollCount = mmv(12, 25, 28)
local CurDollGraphics

-- populate categories:

local sex = {[false] = 'm', [true] = 'f', ''}

function PaperDollAddRace(name, races)
	name = name:lower()
	for sex, ssex in pairs(sex) do
		PaperDollCategories[ssex..name] = function(i)
			local pl = Party.PlayersArray[0]
			local old1, old2 = pl.Face, pl.Voice
			pl.Face, pl.Voice = i, i
			local r = (sex == 1 or (pl:GetSex() ~= 0) == sex) and (not races or races[pl:GetRace()])
			pl.Face, pl.Voice = old1, old2
			return r
		end
	end
end

-- Defines doll categories for 'bodies' array together with male and female variations of each.
-- If 'bodies' table isn't specified, uses #PaperDollSpecialBodies:# table and defines the "Base" paper dolls as well.
function PaperDollAddBodies(bodies)
	local t = bodies and {} or {base = true}
	bodies = bodies or PaperDollSpecialBodies
	for i, s in pairs(bodies) do
		t[s:lower()] = true
	end
	for sex, ssex in pairs(sex) do
		for s in pairs(t) do
			PaperDollCategories[ssex..s] = function(i)
				local pl = Party.PlayersArray[0]
				local old1, old2 = pl.Face, pl.Voice
				pl.Face, pl.Voice = i, i
				local r = (bodies[i] or 'base'):lower() == s and (sex == 1 or (pl:GetSex() ~= 0) == sex)
				pl.Face, pl.Voice = old1, old2
				return r
			end
		end
	end
end

PaperDollAddRace('')
if mmver == 7 then
	for k, v in pairs(const.Race) do
		PaperDollAddRace(k, {[v] = true})
	end
	--!v [MM7] Races that share the "Base" paper doll. Default:
	-- !Lua[[{[const.Race.Human] = true, [const.Race.Goblin] = true, [const.Race.Elf] = true}]]
	-- After altering it, call this command:
	-- !Lua[[PaperDollAddRace('Base', PaperDollBaseRace)]]
	PaperDollBaseRace = PaperDollBaseRace or {[0] = true, true, true}
	-- [MM7]
	PaperDollAddRace('base', PaperDollBaseRace)
elseif mmver == 8 then
	--!v After altering it, call #PaperDollAddBodies:#. Here are default MM8 values:
	-- !Lua[[{[20] = 'Minotaur', [21] = 'Minotaur', [22] = 'Troll', [23] = 'Troll', [24] = 'Dragon', [25] = 'Dragon'}]]
	PaperDollSpecialBodies = PaperDollSpecialBodies or {[20] = 'Minotaur', [21] = 'Minotaur', [22] = 'Troll', [23] = 'Troll', [24] = 'Dragon', [25] = 'Dragon'}
	PaperDollAddBodies()
end
PaperDollSpecialBodies = PaperDollSpecialBodies or {}

local function GetCats(s)
	local q = s:lower():split(', *')
	local t = {}
	for i, s in ipairs(q) do
		local n = tonumber(s)
		if n then
			q[i] = nil
			t[n - 1] = true
		else
			q[i] = PaperDollCategories[s]
		end
	end
	for i = 0, PaperDollCount - 1 do
		for _, f in pairs(q) do
			if f(i) then
				t[i] = true
			end
		end
	end
	return t
end

-- 't' can be a string following the "PaperDol.txt" convention or a table that's similar to the result of calling #ParseNamedColTable:# for such file.
-- Example - loading additional paper doll file for mods:
-- !Lua[[events.ReloadPaperDollGraphics = || AddPaperDollGraphics(Game.LoadTextFileFromLod'PaperMod.txt')]]
function AddPaperDollGraphics(t)
	if type(t) == 'string' then
		t = ParseNamedColTable(t)
	end
	for _, a in ipairs(t) do
		local a1 = {X = tonumber(a.X), Y = tonumber(a.Y)}
		if (a.Mul or '') ~= '' then
			local t = (a.Mul or ''):split(', *')
			if not t[2] then
				t = {t[1], 0, 0, t[1]}
			end
			for i = 1, #t do
				t[i] = tonumber(t[i])
			end
			a1.Mul = t
		end
		for i in pairs(GetCats(a.Doll or '')) do
			local a1 = table.copy(a1)
			a1.Image = a.Image and a.Image:format(i+1) or ''
			tget(tget(PaperDollGraphics, i), a.Piece or '')[(a.ItemPicture or ''):lower()] = a1
		end
	end
end

-- Reloads "PaperDol.txt" and calls #ReloadPaperDollGraphics:events.ReloadPaperDollGraphics# event. Very handy while tweaking "PaperDol.txt"
function ReloadPaperDollGraphics()
	PaperDollGraphics = {}
	AddPaperDollGraphics(Game.LoadTextFileFromLod'PaperDol.txt')
	-- When corresponding #ReloadPaperDollGraphics:# function is called
	events.cocall('ReloadPaperDollGraphics')
end

if GameInitialized2 then
	ReloadPaperDollGraphics()
else
	events.GameInitialized2 = ReloadPaperDollGraphics
end

--!v Defaults to #Game.Version:#. If set to '6' prior to including 'PaperDoll' module, #PaperDollDrawOrder:# would be different. If set to '8', spears aren't treated as 2-handed weapons.
PaperDollMode = PaperDollMode or mmver
local mm6 = (PaperDollMode == 6)

--!v Default (depending on #PaperDollMode:#):
-- !Lua[[{'Bow', 'Cloak',
-- 	'Player', 'Player.arm1', 'Player.arm1f', 'Player.arm2hb', 'Player.arm2f', 'Player.shield', 'Player.hair2', 'Player.hair',
-- 	mm6 and 'Helm' or 'Helm.mm6', mm6 and 'Boots' or 'Boots.mm6',
-- 	'Armor', 'Armor.arm1', 'Armor.arm1f',
-- 	mm6 and 'Boots.boots' or 'Boots',
-- 	'Belt',
-- 	'Player.arm2', 'Player.arm2h', 'Armor.arm2', 'Armor.arm2h',
-- 	'Cloak.scarf', 'Player.scarf', mm6 and 'Helm.scarf' or 'Helm', 'Cloak.scarf2',
-- 	'MainHand',
-- 	'Player.hand1a', 'Player.hand1', 'Armor.hand1a', 'Armor.hand1',
-- 	'ExtraHand.hand2', 'ExtraHand.shield',
-- 	'Player.hand2', 'Player.hand2h', 'Armor.hand2', 'Armor.hand2h',
-- }]]
PaperDollDrawOrder = {'Bow', 'Cloak',
	'Player', 'Player.arm1', 'Player.arm1f', 'Player.arm2hb', 'Player.arm2f', 'Player.shield', 'Player.hair2', 'Player.hair',
	mm6 and 'Helm' or 'Helm.mm6', mm6 and 'Boots' or 'Boots.mm6',
	'Armor', 'Armor.arm1', 'Armor.arm1f',
	mm6 and 'Boots.boots' or 'Boots',
	'Belt',
	'Player.arm2', 'Player.arm2h', 'Armor.arm2', 'Armor.arm2h',
	'Cloak.scarf', 'Player.scarf', mm6 and 'Helm.scarf' or 'Helm', 'Cloak.scarf2',
	'MainHand',
	'Player.hand1a', 'Player.hand1', 'Armor.hand1a', 'Armor.hand1',
	'ExtraHand.hand2', 'ExtraHand.shield',
	'Player.hand2', 'Player.hand2h', 'Armor.hand2', 'Armor.hand2h',
}

local function Is2Handed(it)
	local a = it:T()
	return a.EquipStat == 1 or (PaperDollMode ~= 8) and a.Skill == 4
end

local function IsShield(it)
	return it:T().EquipStat == 4
end

local function GetItemGraphics(it, i)
	local a = it:T()
	return {Image = a.Picture:lower(), X = a.EquipX, Y = a.EquipY, Item = it, Index = i}
end

local DrawCache
local DrawStyles = {[0] = 'green', false, 'red', 'red'}  -- unid, norm, brk, brk
local RingsShown = mmv(0x4D50F0, 0x511760, 0x523040)
local EffectItem

local function draw(a, it, idx, off)
	if not a or a.Image == '' then
		return
	end
	off = off or {}
	local m = a.Mul or off.Mul or {}
	local x = a.X*(m[1] or 1) + a.Y*(m[2] or 0) + (off.X or 0)
	local y = a.X*(m[3] or 0) + a.Y*(m[4] or 1) + (off.Y or 0)
	local rot = m[3] or 0
	if mmver > 6 then
		local p = mm78(0x4E4BF8, 0x4F5890)
		x = x + i4[p]
		y = y + i4[p + 4]
	end
	-- DrawLog[#DrawLog+1] = table.concat({a.Image, x, y}, ", ")
	local pic = DrawCache[a.Image] or Game.IconsLod:LoadBitmap(a.Image)
	DrawCache[a.Image] = pic
	if rot ~= 0 then
		y = y - Game.IconsLod.Bitmaps[pic].Width
	end
	local cond = it and it.Condition or 1
	local ef = cond:And(0xf0)
	if ef ~= 0 and mmver > 6 then
		local s = ef == 32 and "sp28a" or ef == 64 and "sp30a" or ef == 128 and "sp91a" or "sptext01"
		Screen:DrawItemEffect(x, y, pic, s, nil, nil, nil, rot)
		EffectItem = it
	else
		Screen:Draw(x, y, pic, DrawStyles[cond:And(3)], rot)
	end
	if idx and i4[RingsShown] == 0 then
		Screen:DrawToObjectByPixel(x, y, pic, idx, rot)
	end
end

-- only used in MM7
local function draw2(x, y, img)
	draw(tget(CurDollGraphics, '')[img:lower()] or {X = x - 481, Y = y, Image = img})
end

local function GetHiddenPieces(pl)
	local hide = {}
	-- 2nd arm for 2-handed weapon
	hide.arm2h = true  -- dual wield off by default
	if pl.ItemExtraHand == 0 then
		-- 2nd hand for dual-wielding
		hide.hand2 = true  -- 2nd hand off
		-- drawn when holding a shield
		hide.shield = true  -- hand under shield off
		local n = pl.ItemMainHand
		if n ~= 0 and Is2Handed(pl.Items[n]) then
			-- 2nd arm without 2-handed weapon
			hide.arm2 = true
			hide.arm2h = nil
			-- 2nd arm when not holding anything, drawn behind armor
			hide.arm2f = true  -- no free hand
		end
	else
		hide.arm2f = true  -- no free hand
		hide.hand2 = IsShield(pl.Items[pl.ItemExtraHand])  -- 2nd hand
		hide.shield = not hide.hand2  -- hand under shield
	end
	-- 2nd hand for 2-handed weapon
	hide.hand2h = hide.arm2h
	-- 2nd arm for 2-handed weapon, drawn behind armor
	hide.arm2hb = hide.arm2h
	-- 1st arm when holding a weapon
	hide.arm1 = pl.ItemMainHand == 0
	-- 1st arm without a weapon
	hide.arm1f = not hide.arm1
	-- 1st hand when holding a weapon
	hide.hand1 = hide.arm1
	local player = pl
	--!k{hand1a 1st hand (always drawn)} Here I've described pieces that 'PaperDoll' module handles automatically. You can define your own pieces through #PaperDollDrawOrder:# array and hide them conditionally here.
	events.cocall('PaperDollHiddenPieces', hide, player)
	hide.Player = nil
	return hide
end

local function GetItems(pl)
	local t = {Player = true}
	for k, v in pairs(const.ItemSlot) do
		t[k] = pl.EquippedItems[v]
	end
	--!(t, player) Lets you modify weared items, such as add new weared item slots. E.g. setting !Lua[[t.My = 1]] would draw !Lua[[pl.Items[1]]]. Setting !Lua[[t.My = true]] would make ":My" drawn the same way ":Player" is drawn. You'll also need to add "My" to #PaperDollDrawOrder:#.
	events.cocall('PaperDollGetItems', t, pl)
	for k, i in pairs(t) do
		t[k] = (i == true and {} or i ~= 0 and GetItemGraphics(pl.Items[i], i) or nil)
	end
	return t
end

local function Override(pl, t, wear, s, fmt)
	for k, a in pairs(wear) do
		a = a.Image and t[s..fmt:format(k:lower())..a.Image]
		if a then
			return a
		end
	end
end

local function DrawDoll(pl)
	-- DrawLog = {P = || table.concat(DrawLog, "\n")}
	CurDollGraphics = tget(PaperDollGraphics, pl.Face)
	EffectItem = nil
	local hide = GetHiddenPieces(pl)
	local wear = GetItems(pl)
	local face = pl.Face

	for _, s in ipairs(PaperDollDrawOrder) do
		local s, piece = s:match('^([^.]*)%.?([^.]*)$')
		local a = wear[s]
		if a and not hide[piece] then
			local class, t = ':'..s:lower(), tget(CurDollGraphics, piece)
			local it, idx = a.Item, a.Index
			a = Override(pl, t, wear, class, ':%s.') or Override(pl, t, wear, class, '.') or a
			if not a.Item then       -- :Player or override
				a = a.Image and a or t[class]
			elseif t[a.Image] then   -- special item image
				a = table.copy(t[a.Image], table.copy(a), true)
			elseif not (PaperDollMainPieces[s] or PaperDollMainPiecesStd)[piece] then
				a = nil                -- only draw item as the main piece
			end
			draw(a, it, idx, it and t[class])
		end
	end
	
	-- decrease effect time
	if EffectItem then
		local EffectTime = mm78(0x50C828, 0x51E100)
		local time = max(i4[EffectTime] - Game.TimeDelta, 0)
		i4[EffectTime] = time
		if time == 0 then
			i4[mm78(0x50C824, 0x51E0FC)] = 0
			EffectItem.Condition = EffectItem.Condition:AndNot(0xf0)
		end
	end
end

if mmver == 6 then
	mem.hook(0x4123A6, |d| do
		DrawDoll(Party[i4[d.esp + 0x28 - 4] - 1])
		d.ebx = u4[0x9B108C]
		u4[d.esp] = 0x412D24
	end)
	
	-- don't load old graphics
	local oldIconsCount
	mem.autohook2(0x411ED8, (|| oldIconsCount, Game.IconsLod.Count, DrawCache = Game.IconsLod.Count, 0, {}))
	mem.autohook(0x41235C, || Game.IconsLod.Count = oldIconsCount)
elseif mmver == 7 then
	mem.hook(0x43CD55, |d| do
		DrawDoll(Party[d.eax - 1])
		if i4[RingsShown] == 0 then
			draw2(603, 299, "MAGNIF-B")
			if PaperDollDrawCustomBorder then
				draw2(PaperDollDrawCustomBorder())
			else
				Screen:Draw(468, 0, i4[0x507984])
			end
		end
		u4[d.esp] = 0x43E840
	end)

	if PaperDollDrawCustomBorder then
		mem.nop2(0x43E8A2, 0x43E8C9)
		mem.hook(0x43E8A2, |d| do
			draw2(PaperDollDrawCustomBorder())
		end)
	end

	-- don't load old graphics
	mem.nop2(0x43BD56, 0x43BE9D)  -- wetsuit
	mem.nop2(0x43BEA9, 0x43C009)  -- no wetsuit

	local oldIconsCount
	mem.autohook2(0x43C0C1, (|| oldIconsCount, Game.IconsLod.Count, DrawCache = Game.IconsLod.Count, 0, {}))
	mem.autohook(0x43C938, || Game.IconsLod.Count = oldIconsCount)
else
	mem.hook(0x43A4D9, |d| do
		DrawDoll(Party.PlayersArray[(d.eax - Party.PlayersArray['?ptr']):div(0x1D28)])
		u4[d.esp] = 0x43BAD8
	end)
	
	-- don't load old graphics
	mem.nop2(0x43999D, 0x439AB0)
	
	local oldIconsCount
	mem.hook(0x43999D, (|| oldIconsCount, Game.IconsLod.Count, DrawCache = Game.IconsLod.Count, 0, {}))
	mem.autohook(0x43A073, || if oldIconsCount then
		Game.IconsLod.Count, oldIconsCount = oldIconsCount, nil
	end)
end