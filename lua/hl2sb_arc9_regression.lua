-- Run with exec hl2sb_arc9_regression after loading a local map.
local realm = SERVER and "SERVER" or "CLIENT"
local prefix = "[ARC9 regression " .. realm .. "]"
local passed, failed, skipped = 0, 0, 0
local suiteKey = "HL2SBArc9Regression"
if _G[suiteKey] then
    print(prefix, "SKIP", "A regression run is still in progress")
    return
end

local function report(name, ok, result)
    if not ok then
        failed = failed + 1
        print(prefix, "FAIL", name, tostring(result))
    elseif type(result) == "string" then
        skipped = skipped + 1
        print(prefix, "SKIP", name, result)
    else
        passed = passed + 1
        print(prefix, "PASS", name)
    end
end

local function check(name, run)
    report(name, pcall(run))
end

local function summary()
    print(prefix, string.format("TOTAL %d PASS, %d FAIL, %d SKIP", passed, failed, skipped))
end

local function near(a, b)
    return math.abs(a - b) < 0.001
end

local player = SERVER and Entity(1) or LocalPlayer()
local workshopID = "2910505837"

check("ARC9 localization files and HUD phrase", function()
    assert(ARC9 and type(ARC9.GetPhrase) == "function", "ARC9 Base was not initialized")
    for _, language in ipairs({"en", "zh-cn"}) do
        local files = file.Find("arc9/common/localization/*_" .. language .. ".lua", "LUA")
        assert(type(files) == "table" and #files > 0, "language glob returned no files for " .. language)
    end
    local phrase = ARC9:GetPhrase("hud.version")
    assert(type(phrase) == "string" and phrase ~= "", "3D HUD version phrase was not loaded")
end)

check("Workshop ARC9 Base ID", function()
    local visible, archivePresent = 0, false
    local addons = engine.GetAddons()
    assert(type(addons) == "table", "expected an addons table")
    for _, addon in ipairs(addons) do
        if addon.wsid == workshopID and addon.mounted then
            visible = visible + 1
            assert(type(addon.file) == "string" and addon.file:match("^addons/" .. workshopID .. "/"), "wrong package path")
        end
    end
    local files = file.Find("addons/" .. workshopID .. "/*.gma", "MOD")
    archivePresent = type(files) == "table" and #files > 0
    if not archivePresent and visible == 0 then return "No local ARC9 Workshop GMA to test" end
    assert(visible == 1, "expected exactly one mounted entry for " .. workshopID .. ", found " .. visible)
end)

check("JSON Workshop ID round trip", function()
    local encoded = assert(util.TableToJSON({[workshopID] = true}))
    assert(util.JSONToTable(encoded)[tonumber(workshopID)] == true, "numeric Workshop key lost")
    assert(util.JSONToTable(encoded, false, true)[workshopID] == true, "string key lost")
    assert(not pcall(util.TableToJSON, false), "non-table argument did not raise")
end)

check("Config default and revert", function()
    local config = assert(CreateConVar("hl2sb_arc9_regression_default", string.format("arc9-%d", 173421), 0))
    local old = config:GetString()
    local ok, err = pcall(function()
        if collectgarbage then collectgarbage("collect") end
        assert(config:GetDefault() == "arc9-173421", "default string lost")
        config:SetString("arc9-temporary")
        assert(config:GetString() == "arc9-temporary")
        config:Revert()
        assert(config:GetString() == config:GetDefault(), "revert failed")
    end)
    config:SetString(old)
    assert(ok, err)
end)

check("Vector length and distance", function()
    local vec = Vector(3, 4, 0)
    assert(near(vec:Length(), 5))
    assert(near(vec:DistToSqr(Vector()), 25))
end)

check("Angle arithmetic and basis", function()
    local ang = Angle(0, 15, 0)
    ang:Add(Angle(0, 30, 0))
    ang:Mul(2)
    assert(near(ang.y, 90))
    assert(near(ang:Forward().y, 1) and near(ang:Right().x, 1) and near(ang:Up().z, 1))
end)

check("Matrix copy and local translation", function()
    local matrix = Matrix()
    matrix:SetAngles(Angle(0, 90, 0))
    matrix:SetTranslation(Vector(3, 4, 5))
    local copy = Matrix(matrix)
    copy:Translate(Vector(2, 0, 0))
    local rotated = copy:GetTranslation()
    assert(near(rotated.x, 3) and near(rotated.y, 6) and near(rotated.z, 5))
    assert(near(matrix:GetTranslation().y, 4), "matrix copy changed original")
end)

check("Matrix rotation preserves scaling", function()
    local matrix = Matrix()
    matrix:Scale(Vector(2, 3, 4))
    matrix:SetAngles(Angle(0, 90, 0))
    local scale = matrix:GetScale()
    assert(near(scale.x, 2) and near(scale.y, 3) and near(scale.z, 4))
end)

check("DamageInfo field isolation and NULL handles", function()
    local damage = DamageInfo()
    local other = DamageInfo()
    damage:SetDamage(23.5)
    damage:SetDamageType(2.9)
    assert(near(damage:GetDamage(), 23.5) and damage:GetDamageType() == 2)
    assert(not near(other:GetDamage(), 23.5), "DamageInfo objects share storage")
    damage:SetAttacker(NULL)
    damage:SetInflictor(NULL)
    assert(not IsValid(damage:GetAttacker()) and not IsValid(damage:GetInflictor()))
end)

check("EffectData field round trip", function()
    local effect = EffectData()
    local original = {effect:GetAngles(), effect:GetNormal(), effect:GetStart()}
    effect:SetAngles(Angle(6, 12, 18))
    effect:SetNormal(Vector(0, 0, 1))
    effect:SetStart(Vector(4, 5, 6))
    local pass = near(effect:GetAngles().y, 12)
        and near(effect:GetNormal().z, 1) and near(effect:GetStart().y, 5)
    effect:SetAngles(original[1])
    effect:SetNormal(original[2])
    effect:SetStart(original[3])
    assert(pass)
end)

check("Game time and server type", function()
    local scale = game.GetTimeScale()
    assert(type(scale) == "number" and scale == scale and math.abs(scale) < math.huge)
    assert(type(game.IsDedicated()) == "boolean")
end)

check("Player accessors", function()
    if not IsValid(player) then return "No local player. Load a single-player map." end
    assert(type(player:Armor()) == "number")
    assert(type(player:InVehicle()) == "boolean" and isentity(player:GetVehicle()))
    assert(type(player:IsListenServerHost()) == "boolean")
    assert(player:KeyDown(0) == false)
end)

check("Bodygroup Lua sequence", function()
    if not IsValid(player) then return "No player model" end
    local groups = player:GetBodyGroups()
    if next(groups) == nil then return "Player model has no bodygroups" end
    assert(groups[0] == nil and groups[1].id == 0, "wrong bodygroup indexes")
end)

if CLIENT then
    check("VGUI position and dock margins", function()
        local panel = assert(vgui.Create("DPanel"))
        panel:SetVisible(false)
        local ok, err = pcall(function()
            panel:SetPos(23.9, 17.9)
            local x, y = panel:GetPos()
            assert(x == 23 and y == 17, "panel position was not truncated")
            panel:DockMargin(4.9, 5.2, 6, 7)
            local left, top, right, bottom = panel:GetDockMargin()
            assert(left == 4 and top == 5 and right == 6 and bottom == 7)
        end)
        panel:Remove()
        assert(ok, err)
    end)

    check("ParticleEmitter create and finish", function()
        if not IsValid(player) then return "No local player" end
        local emitter = assert(ParticleEmitter(player:EyePos()))
        emitter:Finish()
        emitter:Finish()
    end)
end

local umpClass = "arc9_gfl_ump45"

local function checkActiveWeapon(weapon)
    assert(IsValid(weapon) and weapon.ARC9, "ARC9 weapon did not become active")
    assert(weapon:GetOwner() == player, "active weapon has the wrong owner")
    assert(type(weapon:GetInSights()) == "boolean", "invalid sights state")
    assert(type(weapon:GetCustomize()) == "boolean", "invalid customization state")
    assert(type(weapon:GetCurrentFiremode()) == "number", "invalid fire mode")
    local size = weapon:GetProcessedValue("ClipSize")
    assert(type(size) == "number" and size > 0, "invalid processed magazine size")
    print(prefix, "Active ARC9 weapon", weapon:GetClass())
end

local function checkEquippedWeapon(weapon)
    check("Temporary ARC9 equip and state", function() checkActiveWeapon(weapon) end)
    check("UMP45 primary ammo ID and reserve", function()
        if not IsValid(weapon) or weapon:GetClass() ~= umpClass then
            return "The active weapon is not the ARC9 UMP45"
        end
        local ammo = weapon:GetValue("Ammo")
        if type(ammo) == "string" and ammo:lower() ~= "pistol" then
            return "UMP45 configuration overrides its default pistol ammunition"
        end
        local primaryAmmo = weapon.Primary and weapon.Primary.Ammo
        assert(type(primaryAmmo) == "string" and primaryAmmo:lower() == "pistol",
            "the UMP45 Lua Primary.Ammo is not pistol")
        local expectedID = game.GetAmmoID("pistol")
        local actualID = weapon:GetPrimaryAmmoType()
        assert(type(expectedID) == "number" and expectedID >= 0, "pistol ammo type is not registered")
        assert(actualID == expectedID, string.format("expected pistol ID %d, got %s", expectedID, tostring(actualID)))

        local reserve = player:GetAmmoCount(primaryAmmo)
        assert(player:GetAmmoCount(actualID) == reserve, "ammo ID and ammo name return different reserve counts")
        print(prefix, "UMP45 reserve", reserve,
            reserve == 0 and "(no reserve in inventory; the test does not grant ammo)" or "")
    end)
end

if not game.SinglePlayer() or not IsValid(player) or not player:Alive() then
    local reason = "Requires a living player on a local single-player map"
    report("Single-player network round trip", true, reason)
    report("Temporary ARC9 equip and state", true, reason)
    if CLIENT then report("ARC9 viewmodel draw", true, reason) end
    summary()
    return
end

local request = "hl2sb_arc9_regression_request_v2"
local response = "hl2sb_arc9_regression_response_v2"
local done = "hl2sb_arc9_regression_done_v2"
local preset = string.rep("arc9-preset-", 96)
local edgeValues = {0, 0x7fffffff, 0x80000000, 0xffffffff}

local function writePayload()
    net.WriteUInt(5, 3)
    net.WriteString(preset)
    net.WriteString("")
    for _, value in ipairs(edgeValues) do net.WriteUInt(value, 32) end
    net.WriteUInt(0, 0)
    net.WriteUInt(0x1d, 5)
end

local function checkPayload()
    assert(net.ReadUInt(3) == 5, "bit prefix changed")
    assert(net.ReadString() == preset, "long preset string truncated")
    assert(net.ReadString() == "", "empty string or string cursor changed")
    for _, value in ipairs(edgeValues) do
        assert(net.ReadUInt(32) == value, "incorrect unsigned value " .. tostring(value))
    end
    assert(net.ReadUInt(0) == 0, "zero-width unsigned read should return zero")
    assert(net.ReadUInt(5) == 0x1d, "read cursor lost trailing bits")
end

local function installReceiver(name, callback)
    assert(net.Receivers[name] == nil, "regression receiver already in use")
    net.Receive(name, callback)
    return function()
        if net.Receivers[name] == callback then net.Receivers[name] = nil end
    end
end

local removeRequest, removeResponse, removeDone
local oldWeapon, temporaryWeapon, testWeapon, oldZoom, oldTimeScale, token, viewmodelWeapon, testProp
local physicsPending, clientDone, cleanupStarted
if CLIENT then oldZoom = player:GetCanZoom() end

local function finishCleanup(showSummary)
    if IsValid(player) then
        if oldZoom ~= nil and (SERVER or viewmodelWeapon) then player:SetCanZoom(oldZoom) end
    end
    if oldTimeScale and game.SetTimeScale and game.GetTimeScale() ~= oldTimeScale then
        game.SetTimeScale(oldTimeScale)
    end
    if IsValid(testProp) then testProp:Remove() end
    _G[suiteKey] = nil
    if showSummary then summary() end
end

local function cleanup(showSummary)
    if cleanupStarted then return end
    cleanupStarted = true
    timer.Remove(suiteKey)
    timer.Remove(suiteKey .. "Physics")
    hook.Remove("PostDrawViewModel", suiteKey)
    if removeRequest then removeRequest() end
    if removeResponse then removeResponse() end
    if removeDone then removeDone() end

    if not SERVER or not IsValid(testWeapon) then
        finishCleanup(showSummary)
        return
    end

    -- ARC9's attachment setup schedules anonymous callbacks for 0 and 0.1 s.
    -- The named timer runs after those callbacks, outside the net receiver.
    local settleDelay = 0.15
    local cleanupTimer = suiteKey .. "WeaponCleanup"
    timer.Create(cleanupTimer, settleDelay, 1, function()
        local restoreWeapon = IsValid(player) and IsValid(testWeapon) and IsValid(oldWeapon)
            and player:GetActiveWeapon() == testWeapon
        if restoreWeapon then
            if testWeapon == temporaryWeapon and type(testWeapon.SetHolsterTime) == "function" then
                testWeapon:SetHolsterTime(-1)
            end
            player:SelectWeapon(oldWeapon:GetClass())
        end
        if not IsValid(temporaryWeapon) then
            finishCleanup(showSummary)
            return
        end

        -- Holstering may also enqueue attachment updates. Keep the weapon
        -- valid through the next timer pass before removing the test instance.
        timer.Create(cleanupTimer .. "Remove", settleDelay, 1, function()
            local retrySelection = restoreWeapon and IsValid(player) and IsValid(oldWeapon)
                and player:GetActiveWeapon() == testWeapon
            if IsValid(temporaryWeapon) then temporaryWeapon:Remove() end
            if retrySelection and player:GetActiveWeapon() ~= oldWeapon then
                player:SelectWeapon(oldWeapon:GetClass())
            end
            finishCleanup(showSummary)
        end)
    end)
end

_G[suiteKey] = cleanup

if SERVER then
    for _, name in ipairs({request, response, done}) do util.AddNetworkString(name) end

    local function startPhysicsCheck()
        testProp = assert(ents.Create("prop_physics"))
        assert(IsValid(testProp), "failed to create temporary physics prop")
        testProp:SetModel("models/props_junk/wood_crate001a.mdl")
        testProp:SetPos(player:GetPos() + Vector(0, 0, 32))
        testProp:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        testProp:SetNoDraw(true)
        testProp:SetNotSolid(true)
        testProp:Spawn()
        testProp:SetNotSolid(true)
        local physics = testProp:GetPhysicsObject()
        assert(physics:IsValid(), "new prop has no valid physics object")
        physics:EnableMotion(false)

        local originalOwner = testProp:GetOwner()
        testProp:SetPhysicsAttacker(player, 600)
        assert(testProp:GetPhysicsAttacker() == player, "600-second physics attacker was not recorded")
        assert(testProp:GetOwner() == originalOwner, "physics attribution changed entity owner")
        testProp:SetPhysicsAttacker(player, 0.03)
        return physics
    end

    local physicsOK, physics = pcall(startPhysicsCheck)
    report("Temporary prop and physics attacker", physicsOK, not physicsOK and physics or nil)
    if physicsOK then
        physicsPending = true
        timer.Create(suiteKey .. "Physics", 0.15, 1, function()
            check("Temporary physics attribution expires", function()
                assert(not IsValid(testProp:GetPhysicsAttacker()), "expired attacker was still returned")
            end)
            check("Physics handle invalidation", function()
                assert(physics:IsValid(), "physics unexpectedly invalid before destroying it")
                testProp:PhysicsDestroy()
                assert(not physics:IsValid(), "old physics handle still claims to be valid")
                assert(not pcall(physics.GetMass, physics), "old physics handle still accepts GetMass")
                local current = testProp:GetPhysicsObject()
                assert(not current or not current:IsValid(), "destroyed prop still exposes a physics object")
            end)
            if IsValid(testProp) then testProp:Remove() end
            testProp = nil
            physicsPending = false
            if clientDone then cleanup(true) end
        end)
    elseif IsValid(testProp) then
        testProp:Remove()
        testProp = nil
    end

    local function equipARC9()
        local active = player:GetActiveWeapon()
        if IsValid(active) and active.ARC9 then return active end
        if not IsValid(active) then return nil, "No current weapon to restore" end
        if not weapons.GetStored(umpClass) then return nil, "ARC9 UMP45 addon is unavailable" end
        if player:InVehicle() then return nil, "Cannot safely switch weapon in a vehicle" end
        oldWeapon = active
        oldZoom = player:GetCanZoom()
        oldTimeScale = game.GetTimeScale()
        local weapon = player:GetWeapon(umpClass)
        if not IsValid(weapon) then
            temporaryWeapon = player:Give(umpClass, true)
            weapon = temporaryWeapon
        end
        assert(IsValid(weapon), "failed to give test UMP45")
        testWeapon = weapon
        if player:GetActiveWeapon() ~= weapon then player:SelectWeapon(umpClass) end
        return weapon
    end

    local equipped, equipReported
    local function reportEquipped()
        if not equipped or equipReported then return end
        equipReported = true
        checkEquippedWeapon(player:GetActiveWeapon())
    end

    removeRequest = installReceiver(request, function(_, sender)
        if sender ~= player or token ~= nil then return end
        token = net.ReadUInt(31)
        check("Client to server string and UInt32", checkPayload)
        local ok, weapon, skip = pcall(equipARC9)
        if ok and IsValid(weapon) then
            equipped = weapon
        else
            report("Temporary ARC9 equip and state", ok, ok and skip or weapon)
        end
        net.Start(response)
        net.WriteUInt(token, 31)
        net.WriteUInt(ok and IsValid(weapon) and weapon:EntIndex() or 0, 16)
        writePayload()
        net.Send(sender)
    end)

    removeDone = installReceiver(done, function(_, sender)
        if sender ~= player or token == nil or net.ReadUInt(31) ~= token then return end
        reportEquipped()
        clientDone = true
        if not physicsPending then cleanup(true) end
    end)

    timer.Create(suiteKey, 9, 1, function()
        if token == nil then report("Client to server string and UInt32", false, "local client did not respond") end
        reportEquipped()
        cleanup(true)
    end)
else
    local deadline = RealTime() + 6
    local expectedIndex

    local function finish()
        net.Start(done)
        net.WriteUInt(token, 31)
        net.SendToServer()
        cleanup(true)
    end

    removeResponse = installReceiver(response, function()
        if token == nil or expectedIndex ~= nil or net.ReadUInt(31) ~= token then return end
        expectedIndex = net.ReadUInt(16)
        check("Server to client string and UInt32", checkPayload)
        if expectedIndex == 0 then
            report("Temporary ARC9 equip and state", true, "Server could not safely select an ARC9 weapon")
            report("ARC9 viewmodel draw", true, "No active ARC9 weapon to observe")
            finish()
        end
    end)

    hook.Add("PostDrawViewModel", suiteKey, function(model, owner, weapon)
        if expectedIndex and owner == player and IsValid(weapon) and weapon:EntIndex() == expectedIndex then
            viewmodelWeapon = weapon
        end
    end)

    timer.Create(suiteKey, 0.1, 0, function()
        if token == nil and util.NetworkStringToID(request) > 0 then
            token = math.floor(SysTime() * 1000) % 0x80000000
            net.Start(request)
            net.WriteUInt(token, 31)
            writePayload()
            net.SendToServer()
        end
        if viewmodelWeapon then
            checkEquippedWeapon(viewmodelWeapon)
            report("ARC9 viewmodel draw", true)
            finish()
        elseif RealTime() >= deadline then
            if expectedIndex == nil then report("Server to client string and UInt32", false, "local round trip timed out") end
            if expectedIndex == nil then
                report("Temporary ARC9 equip and state", true, "No server equip response")
            else
                local weapon = player:GetActiveWeapon()
                if IsValid(weapon) and weapon:EntIndex() == expectedIndex then
                    checkEquippedWeapon(weapon)
                else
                    report("Temporary ARC9 equip and state", false, "test weapon did not replicate")
                end
            end
            report("ARC9 viewmodel draw", true, "No first-person draw observed before timeout")
            if token then finish() else cleanup(true) end
        end
    end)
end
