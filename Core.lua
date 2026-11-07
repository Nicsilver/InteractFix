local BINDING = "INTERACTMOUSEOVER"
local AUTO_SHOT_ID = 75

-- The stock INTERACTMOUSEOVER binding calls InteractUnit("mouseover") with loose
-- targeting left on, so it sticks to the current target; with no target it works.
-- InteractUnit is protected, so an addon can't call the strict form or follow a
-- target change with an interact in the same key press. The key is rerouted only
-- while a target is stuck in the way, and Blizzard's binding does the rest:
--   enemy under the cursor: target it and start attacking, which is what interact did.
--   anything else: get the old target out of the way, then the next press interacts.
local function attackLines()
    local lines = {
        "/target [@mouseover,harm,nodead]",
        "/startattack [harm,nodead]",
    }
    if select(2, UnitClass("player")) == "HUNTER" then
        -- Macros only take the localized spell name.
        local name = C_Spell.GetSpellName(AUTO_SHOT_ID) or "Auto Shot"
        lines[#lines + 1] = "/cast [harm,nodead] !" .. name
    end
    return lines
end

-- Combat can't tell whether the unit is already the target, so it clears instead:
-- retargeting the same corpse or NPC would swallow every press.
local retarget = {
    "/cleartarget [combat]",
    "/target [nocombat,@mouseover,exists]",
}

local function makeButton(name, lines)
    local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetAttribute("useOnKeyDown", true)
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", table.concat(lines, "\n"))
    return button
end
local attackButton = makeButton("InteractFixAttackButton", attackLines())
makeButton("InteractFixRetargetButton", retarget)

local driver = CreateFrame("Frame", "InteractFixDriver", UIParent, "SecureHandlerAttributeTemplate")
driver:SetAttribute("_onattributechanged", [[
    if name ~= "state-hover" and name ~= "same" and name ~= "key1" and name ~= "key2" then return end
    self:ClearBindings()
    local button
    local state = self:GetAttribute("state-hover")
    if state == "enemy" then
        button = "InteractFixAttackButton"
    elseif state == "friend" and not self:GetAttribute("same") then
        button = "InteractFixRetargetButton"
    end
    if not button then return end
    for _, attribute in ipairs({ "key1", "key2" }) do
        local key = self:GetAttribute(attribute)
        if key then self:SetBindingClick(true, key, button) end
    end
]])
RegisterAttributeDriver(driver, "state-hover",
    "[@mouseover,noexists] none; [@target,noexists] none; [@mouseover,harm,nodead] enemy; friend")

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

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" and not InCombatLockdown() then
        -- Spell names aren't reliably loaded when the file runs.
        attackButton:SetAttribute("macrotext", table.concat(attackLines(), "\n"))
    end
    update()
    if event ~= "PLAYER_LOGIN" then return end

    InteractFixDB = InteractFixDB or {}
    if InteractFixDB.softTargetEnabled or InteractFixDB.softTargetRestored then return end
    -- The fallback "anyinteract" path needs soft interact targeting.
    C_CVar.SetCVar("SoftTargetInteract", "1")
    InteractFixDB.softTargetEnabled = true
    print("|cff33ff99InteractFix:|r on. Bind a key to Interact with Mouseover and use it over anything to switch to it.")
end)
