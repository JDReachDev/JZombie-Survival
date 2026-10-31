-- JZombie Survival - sv_wave.lua
-- Wave manager: macchina a stati WAITING -> BUYTIME -> WAVE -> (ripeti) / GAMEOVER
-- (incluso da init.lua: niente include qui)

-- ============================================================================
-- CALCOLO NUMERO ZOMBIE PER ONDATA
-- ============================================================================
local function WaveSize(wave)
    local base = math.max(1, GetConVarNumber("zs_hordesize"))
    local scale = math.max(1, GetConVarNumber("zs_wavescale"))
    return math.floor(base * math.pow(scale, wave - 1))
end

-- ============================================================================
-- TRANSIZIONI DI STATO
-- ============================================================================
function ZS.EnterBuyTime()
    ZS.CurrentState = ZS.State.BUYTIME
    local nextWaveSettings = ZS.GetWaveSettings(ZS.Wave + 1)
    local duration = nextWaveSettings.buytime
    ZS.CountdownEnd = CurTime() + duration
    ZS.BroadcastState()
    ZS.Notify("Acquisti abilitati! Prossima ondata (" .. (ZS.Wave + 1) .. ") tra " .. math.ceil(duration) .. "s", "info")

    timer.Create("ZS_BuyTimer", 1, 0, function()
        if ZS.CurrentState ~= ZS.State.BUYTIME then timer.Remove("ZS_BuyTimer") return end
        ZS.BroadcastState()
        if CurTime() >= ZS.CountdownEnd then
            timer.Remove("ZS_BuyTimer")
            ZS.StartWave()
        end
    end)

    -- Auto-apre lo shop a tutti i player vivi
    net.Start("ZS_OpenShop")
    net.Broadcast()
end

function ZS.StartWave()
    ZS.Wave = ZS.Wave + 1
    ZS.CurrentState = ZS.State.WAVE
    ZS.KillsThisWave = 0

    local cfg = ZS.GetWaveSettings(ZS.Wave)
    ZS.CurrentWaveSettings = cfg
    ZS.PendingSpawns = cfg.count
    ZS.CountdownEnd = 0
    ZS.BroadcastState()
    ZS.Notify(cfg.announce or ("ONDATA " .. ZS.Wave .. " in arrivo!"), cfg.special and "error" or "warn")

    net.Start("ZS_CloseShop")
    net.Broadcast()

    -- Spawna gradualmente usando il delay dell'ondata
    timer.Create("ZS_SpawnTimer", cfg.spawn_delay or 0.35, 0, function()
        if ZS.CurrentState ~= ZS.State.WAVE then timer.Remove("ZS_SpawnTimer") return end
        if ZS.PendingSpawns <= 0 then timer.Remove("ZS_SpawnTimer") return end
        if ZS.SpawnOneZombie() then
            ZS.PendingSpawns = ZS.PendingSpawns - 1
            ZS.BroadcastState()
        end
    end)
end

function ZS.CompleteWave()
    local cfg = ZS.GetWaveSettings(ZS.Wave)
    local payout = cfg.payout + (cfg.bonus or 0)

    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            ZS.AddMoney(ply, payout)
        end
    end

    ZS.Notify("Ondata " .. ZS.Wave .. " completata! +" .. ZS.FormatMoney(payout) .. " a testa", "success")
    ZS.EnterBuyTime()
end

function ZS.GameOver()
    ZS.CurrentState = ZS.State.GAMEOVER
    ZS.BroadcastState()
    ZS.Notify("GAME OVER — siete arrivati all'ondata " .. ZS.Wave, "error")
    timer.Simple(10, ZS.ResetRound)
end

function ZS.ResetRound()
    -- Uccide tutti gli zombie residui
    for npc in pairs(ZS.ActiveZombies) do
        if IsValid(npc) then npc:Remove() end
    end
    ZS.ActiveZombies = {}
    ZS.ZombiesAlive = 0
    ZS.PendingSpawns = 0
    ZS.Wave = 0

    for _, ply in ipairs(player.GetAll()) do
        ZS.SetMoney(ply, GetConVarNumber("zs_startmoney"))
        ply:SetNWInt(ZS.NW_KILLS, 0)
        ply:SetNWInt(ZS.NW_SCORE, 0)
        ply:StripWeapons()
        ply:Spawn()
    end

    ZS.EnterBuyTime()
end

-- ============================================================================
-- TICK PRINCIPALE: controlla condizioni di fine ondata / game over
-- ============================================================================
hook.Add("Think", "ZS_WaveTick", function()
    if not ZS.CurrentState then return end

    if ZS.CurrentState == ZS.State.WAITING then
        -- Avvia la partita appena c'è almeno un player
        if #player.GetAll() > 0 and not timer.Exists("ZS_FirstStart") then
            timer.Create("ZS_FirstStart", 5, 1, function()
                if ZS.CurrentState == ZS.State.WAITING then
                    ZS.BuildSpawnPoints()
                    ZS.EnterBuyTime()
                end
            end)
        end

    elseif ZS.CurrentState == ZS.State.WAVE then
        -- Fine ondata: nessun alive e nessuna coda di spawn
        if ZS.ZombiesAlive <= 0 and ZS.PendingSpawns <= 0 then
            ZS.CompleteWave()
        end

        -- Game over: tutti i player morti
        local anyAlive = false
        for _, ply in ipairs(player.GetAll()) do
            if ply:Alive() then anyAlive = true break end
        end
        if #player.GetAll() > 0 and not anyAlive then
            ZS.GameOver()
        end
    end
end)

-- ============================================================================
-- PLAYER SETUP / RESPAWN
-- ============================================================================
hook.Add("PlayerInitialSpawn", "ZS_InitPly", function(ply)
    ply:SetNWInt(ZS.NW_MONEY, GetConVarNumber("zs_startmoney"))
    ply:SetNWInt(ZS.NW_KILLS, 0)
    ply:SetNWInt(ZS.NW_SCORE, 0)
    timer.Simple(1, function()
        if IsValid(ply) then ZS.BroadcastState() end
    end)
end)

-- In buytime sei invulnerabile e puoi rigenerarti
hook.Add("EntityTakeDamage", "ZS_BuyProtect", function(target, dmg)
    if not target:IsPlayer() then return end
    if ZS.CurrentState == ZS.State.BUYTIME then
        return true -- blocca ogni danno durante gli acquisti
    end
end)

-- Respawn automatico dei morti durante il buytime
timer.Create("ZS_RespawnCheck", 2, 0, function()
    if ZS.CurrentState ~= ZS.State.BUYTIME then return end
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then
            ply:Spawn()
            ply:StripWeapons()
            -- Ridai la pistola base gratis
            ply:Give("weapon_pistol")
        end
    end
end)

-- ============================================================================
-- COMANDI CONSOLE/CHAT ADMIN
-- ============================================================================
concommand.Add("zs_skipwave", function(caller)
    if IsValid(caller) and not caller:IsSuperAdmin() then return end
    if ZS.CurrentState == ZS.State.WAVE then
        for npc in pairs(ZS.ActiveZombies) do
            if IsValid(npc) then npc:Remove() end
        end
    elseif ZS.CurrentState == ZS.State.BUYTIME then
        ZS.StartWave()
    end
end)

concommand.Add("zs_setmoney", function(caller, args, argv)
    if IsValid(caller) and not caller:IsSuperAdmin() then return end
    local amount = tonumber(argv[1])
    if not amount then return end
    for _, ply in ipairs(player.GetAll()) do
        ZS.SetMoney(ply, amount)
    end
end)