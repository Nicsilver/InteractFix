local ADDON = ...

local BINDING = "INTERACTMOUSEOVER"
local AUTO_SHOT_ID = 75
local PREFIX = "|cff33ff99InteractFix:|r "

-- Every entry point goes through here: a silent Lua error in an event handler or slash
-- command looks like an addon that does nothing. Repeats are muted because the handler
-- runs on every mouseover change.
local lastError, lastErrorAt
local function guarded(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if ok then return end
        err = tostring(err)
        local now = GetTime()
        if err == lastError and now - lastErrorAt < 30 then return end
        lastError, lastErrorAt = err, now
        print(PREFIX .. "lua error: " .. err)
    end
end

-- The stock INTERACTMOUSEOVER binding calls InteractUnit("mouseover") with loose
-- targeting left on, so it sticks to the current target; with no target it works.
-- InteractUnit is protected, so an addon can't call the strict form or follow a
-- target change with an interact in the same key press. The key is rerouted only
-- while a target is stuck in the way, and Blizzard's binding does the rest:
--   enemy under the cursor: target it and start attacking, which is what interact did.
--   anything else: get the old target out of the way, then the next press interacts.
-- Two options add the pet to that (both off by default, see the settings panel):
--   petMouseover: the enemy line also sends the pet, and the override stays on when
--     the enemy is the only thing in play (no target yet).
--   petTarget: with nothing under the cursor, a hostile target gets the pet sent at it.
local function attackLines(petMouseover)
    local lines = {
        "/target [@mouseover,harm,nodead]",
        "/startattack [harm,nodead]",
    }
    if select(2, UnitClass("player")) == "HUNTER" then
        -- Macros only take the localized spell name.
        local name = C_Spell.GetSpellName(AUTO_SHOT_ID) or "Auto Shot"
        lines[#lines + 1] = "/cast [harm,nodead] !" .. name
    end
    if petMouseover then
        lines[#lines + 1] = "/petattack [@mouseover,harm,nodead,pet]"
    end
    return lines
end

-- Combat can't tell whether the unit is already the target, so it clears instead:
-- retargeting the same corpse or NPC would swallow every press.
local retarget = {
    "/cleartarget [combat]",
    "/target [nocombat,@mouseover,exists]",
}

local petTarget = {
    "/petattack [@target,harm,nodead,pet]",
}

local function makeButton(name, lines)
    local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetAttribute("useOnKeyDown", true)
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", table.concat(lines, "\n"))
    return button
end
local attackButton = makeButton("InteractFixAttackButton", attackLines(false))
makeButton("InteractFixRetargetButton", retarget)
makeButton("InteractFixPetButton", petTarget)

local driver = CreateFrame("Frame", "InteractFixDriver", UIParent, "SecureHandlerAttributeTemplate")
driver:SetAttribute("_onattributechanged", [[
    if name ~= "state-hover" and name ~= "state-pettarget" and name ~= "same" and name ~= "key1" and name ~= "key2" then return end
    self:ClearBindings()
    local button
    local state = self:GetAttribute("state-hover")
    if state == "enemy" then
        button = "InteractFixAttackButton"
    elseif state == "nomouse" then
        if self:GetAttribute("state-pettarget") == "hostile" then
            button = "InteractFixPetButton"
        end
    elseif state == "friendcombat" or (state == "friend" and not self:GetAttribute("same")) then
        button = "InteractFixRetargetButton"
    end
    if not button then return end
    -- Restricted snippets reject brace characters anywhere, even in comments.
    for i = 1, 2 do
        local key = self:GetAttribute("key" .. i)
        if key then self:SetBindingClick(true, key, button) end
    end
]])

-- "same" is only refreshed outside combat, so in combat the state itself carries
-- the fact: a stale "same" would otherwise leave a friendly unit on the stock key
-- for the whole fight.
-- With petMouseover and a pet, an enemy under the cursor is "enemy" before the
-- no-target clause can hand the key back to the game. With petTarget, "no unit under
-- the cursor" becomes its own state, because one driver can't test two units at once;
-- a second driver reports whether the target is a living hostile with a pet around.
local TARGET_CONDITIONS = "[@target,harm,nodead,pet] hostile; none"

local function hoverConditions(options)
    local clauses = { "[@mouseover,noexists] " .. (options.target and "nomouse" or "none") }
    if options.mouse then
        clauses[#clauses + 1] = "[@mouseover,harm,nodead,pet] enemy"
    end
    clauses[#clauses + 1] = "[@target,noexists] none"
    clauses[#clauses + 1] = "[@mouseover,harm,nodead] enemy"
    clauses[#clauses + 1] = "[combat] friendcombat"
    clauses[#clauses + 1] = "friend"
    return table.concat(clauses, "; ")
end

local function currentOptions()
    local db = InteractFixDB or {}
    return { mouse = db.petMouseover == true, target = db.petTarget == true }
end

local applied = { mouse = false, target = false }
local pending = false
local announced

RegisterAttributeDriver(driver, "state-hover", hoverConditions(applied))

-- Secure attributes and state drivers can't be written in combat.
local function apply()
    local options = currentOptions()
    attackButton:SetAttribute("macrotext", table.concat(attackLines(options.mouse), "\n"))
    RegisterAttributeDriver(driver, "state-hover", hoverConditions(options))
    if options.target then
        RegisterAttributeDriver(driver, "state-pettarget", TARGET_CONDITIONS)
    elseif applied.target then
        UnregisterAttributeDriver(driver, "state-pettarget")
        driver:SetAttribute("state-pettarget", nil)
    end
    applied = options
    pending = false
    announced = nil
end

local function optionsChanged()
    local options = currentOptions()
    return options.mouse ~= applied.mouse or options.target ~= applied.target
end

local function optionChanged()
    if not InCombatLockdown() then
        apply()
        return
    end
    pending = optionsChanged()
    if not pending then announced = nil end
    -- The panel notifies every setting it touches, not only the one clicked.
    local options = currentOptions()
    local key = tostring(options.mouse) .. tostring(options.target)
    if pending and key ~= announced then
        announced = key
        print(PREFIX .. "setting saved, it takes effect when combat ends.")
    end
end

-- State drivers ignore mouseover changes and only poll every 0.2s, which is slow
-- enough to miss a quick hover-and-scroll.
SecureStateDriverManager:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

-- UnitIsUnit can return a secret value that errors on any test, hence the pcall.
local function mouseoverIsTarget()
    local ok, same = pcall(function()
        return UnitIsUnit("mouseover", "target") and true or false
    end)
    return ok and same
end

-- Follows the player's own binding so the addon works on whatever key they chose.
local function update()
    if InCombatLockdown() then return end
    local key1, key2 = GetBindingKey(BINDING)
    driver:SetAttribute("key1", key1)
    driver:SetAttribute("key2", key2)
    driver:SetAttribute("same", mouseoverIsTarget())
end

local category
local function registerPanel()
    category = Settings.RegisterVerticalLayoutCategory("InteractFix")
    local function addCheckbox(variable, key, label, tooltip)
        local setting = Settings.RegisterAddOnSetting(category, variable, key, InteractFixDB,
            Settings.VarType.Boolean, label, Settings.Default.False)
        setting:SetValueChangedCallback(guarded(optionChanged))
        Settings.CreateCheckbox(category, setting, tooltip)
    end
    addCheckbox("INTERACTFIX_PET_MOUSEOVER", "petMouseover",
        "Pet attacks the enemy under the cursor",
        "Pressing the key on a living hostile unit under the cursor also sends your pet at it.")
    addCheckbox("INTERACTFIX_PET_TARGET", "petTarget",
        "Pet attacks your hostile target when nothing is under the cursor",
        "With nothing under the cursor and a living hostile target, the key sends your pet at the target instead of the stock interact.")
    Settings.RegisterAddOnCategory(category)
end

local function onAddonLoaded()
    -- Older saved variables lack the option keys.
    if type(InteractFixDB) ~= "table" then InteractFixDB = {} end
    for _, key in ipairs({ "petMouseover", "petTarget" }) do
        if type(InteractFixDB[key]) ~= "boolean" then InteractFixDB[key] = false end
    end
    registerPanel()
end

SLASH_INTERACTFIX1 = "/interactfix"
SlashCmdList["INTERACTFIX"] = guarded(function()
    if not category then
        print(PREFIX .. "the settings panel is not available.")
        return
    end
    Settings.OpenToCategory(category:GetID())
end)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", guarded(function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            self:UnregisterEvent("ADDON_LOADED")
            onAddonLoaded()
        end
        return
    end
    if event == "PLAYER_LOGIN" then
        -- Spell names aren't reliably loaded when the file runs.
        if InCombatLockdown() then pending = true else apply() end
    elseif event == "PLAYER_REGEN_ENABLED" and pending then
        apply()
    end
    update()
    if event ~= "PLAYER_LOGIN" then return end

    if InteractFixDB.softTargetEnabled or InteractFixDB.softTargetRestored then return end
    -- The fallback "anyinteract" path needs soft interact targeting.
    if (tonumber(C_CVar.GetCVar("SoftTargetInteract")) or 0) < 1 then
        C_CVar.SetCVar("SoftTargetInteract", "1")
    end
    InteractFixDB.softTargetEnabled = true
    print(PREFIX .. "on. Bind a key to Interact with Mouseover and use it over anything to switch to it. Options: /interactfix")
end))
