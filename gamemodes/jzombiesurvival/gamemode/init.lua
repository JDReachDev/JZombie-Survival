-- JZombie Survival - init.lua
-- Entry point SERVER (nome obbligatorio: init.lua)

-- Invia ai client i file che gli servono
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_config.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_shop.lua")
AddCSLuaFile("cl_notifications.lua")

-- Entità custom (devono essere inviate al client per prediction/rendering)
AddCSLuaFile("entities/base_barricade/shared.lua")
AddCSLuaFile("entities/zs_barricade_plank/shared.lua")
AddCSLuaFile("entities/zs_barricade_sandbag/shared.lua")
AddCSLuaFile("entities/zs_barricade_metal/shared.lua")
AddCSLuaFile("entities/zs_barricade_wire/shared.lua")
AddCSLuaFile("entities/zs_barricade_crate/shared.lua")
AddCSLuaFile("entities/zs_barricade_turret/shared.lua")

include("shared.lua")
include("sh_config.lua")
include("sv_wave.lua")
include("sv_shop.lua")

-- ============================================================================
-- REGISTRAZIONE NET MESSAGES
-- ============================================================================
util.AddNetworkString("ZS_SyncState")       -- S->C: aggiorna stato globale
util.AddNetworkString("ZS_Notify")          -- S->C: notifica testuale
util.AddNetworkString("ZS_MoneyUpdate")     -- S->C: saldo aggiornato
util.AddNetworkString("ZS_PurchaseWeapon")  -- C->S: richiesta acquisto arma
util.AddNetworkString("ZS_PurchaseAmmo")    -- C->S: richiesta acquisto munizioni
util.AddNetworkString("ZS_OpenShop")        -- S->C: forza apertura shop
util.AddNetworkString("ZS_CloseShop")       -- S->C: chiude shop
util.AddNetworkString("ZS_SellWeapon")      -- C->S: vendi arma posseduta

-- ============================================================================
-- STATO DEL GIOCO (server-side, autorevole)
-- ============================================================================
ZS.Wave          = 0
ZS.CurrentState  = ZS.State.WAITING   -- stato corrente (numero), NON sovrascrivere ZS.State (tabella)
ZS.CountdownEnd  = 0
ZS.ZombiesAlive  = 0
ZS.PendingSpawns = 0
ZS.KillsThisWave = 0
ZS.SpawnPoints   = {}
ZS.ActiveZombies = {}   -- set di entità zombie vive

-- ============================================================================
-- FUNZIONI DI SYNC VERSO I CLIENT
-- ============================================================================
function ZS.BroadcastState()
    net.Start("ZS_SyncState")
        net.WriteInt(ZS.Wave, 16)
        net.WriteUInt(ZS.CurrentState, 8)
        net.WriteFloat(math.max(0, ZS.CountdownEnd - CurTime()))
        net.WriteInt(ZS.ZombiesAlive, 16)
    net.Broadcast()
end

function ZS.Notify(text, typ)
    net.Start("ZS_Notify")
        net.WriteString(text or "")
        net.WriteString(typ or "info")
    net.Broadcast()
end

function ZS.SyncMoney(ply)
    if not IsValid(ply) then return end
    net.Start("ZS_MoneyUpdate")
        net.WriteInt(ply:GetNWInt(ZS.NW_MONEY, 0), 32)
    net.Send(ply)
end

-- ============================================================================
-- ECONOMIA
-- ============================================================================
function ZS.GetMoney(ply)
    return ply:GetNWInt(ZS.NW_MONEY, 0)
end

function ZS.SetMoney(ply, amount)
    amount = math.max(0, math.floor(amount))
    ply:SetNWInt(ZS.NW_MONEY, amount)
    ZS.SyncMoney(ply)
end

function ZS.AddMoney(ply, amount)
    ZS.SetMoney(ply, ZS.GetMoney(ply) + amount)
end

function ZS.TrySpend(ply, amount)
    if ZS.GetMoney(ply) >= amount then
        ZS.SetMoney(ply, ZS.GetMoney(ply) - amount)
        return true
    end
    return false
end

-- ============================================================================
-- INIZIALIZZAZIONE MAPPA / SPAWN POINTS
-- ============================================================================
function ZS.BuildSpawnPoints()
    ZS.SpawnPoints = {}

    -- 1. Entità posizionate dal mapper / dalla mappa
    for _, cls in ipairs({ "info_player_deathmatch", "info_player_start", "info_player_combine", "info_player_enemy" }) do
        for _, ent in ipairs(ents.FindByClass(cls)) do
            table.insert(ZS.SpawnPoints, ent:GetPos())
        end
    end

    -- Centro approssimativo dell'area di gioco
    local center = Vector(0, 0, 0)
    if #ZS.SpawnPoints > 0 then
        for _, p in ipairs(ZS.SpawnPoints) do
            center = center + p
        end
        center = center / #ZS.SpawnPoints
    end

    -- 2. Bordi mappa: anello di punti attorno al centro, traced verso il basso
    local radius  = math.max(1000, GetConVarNumber("zs_spawnradius"))
    local numEdge = 32

    for i = 1, numEdge do
        local angle = (i / numEdge) * math.pi * 2
        local x = center.x + math.cos(angle) * radius
        local y = center.y + math.sin(angle) * radius

        -- Partiamo dall'alto (tetto della mappa) per trovare il pavimento solido
        local tr = util.TraceLine({
            start  = Vector(x, y, center.z + 2000),
            endpos = Vector(x, y, center.z - 4000),
            mask   = MASK_SOLID_BRUSHONLY,
        })

        if tr.Hit then
            local spawnPos = tr.HitPos + Vector(0, 0, 48)

            -- Il punto dev'essere libero da brush solidi
            local blocked = util.TraceHull({
                mins   = Vector(-16, -16, 0),
                maxs   = Vector(16, 16, 72),
                start  = spawnPos,
                endpos = spawnPos,
                mask   = MASK_SOLID,
            })

            -- E dev'esserci pavimento sotto le feet (il TraceLine lo garantisce)
            -- + dev'essere raggiungibile dalla navmesh, altrimenti l'NPC non si muove
            if not blocked.Hit then
                table.insert(ZS.SpawnPoints, spawnPos)
            end
        end
    end

    print("[ZS] Spawn points pronti: " .. #ZS.SpawnPoints)
end

-- ============================================================================
-- SELEZIONE PUNTO DI SPAWN (lontano dai giocatori, anti spawn-in-faccia)
-- ============================================================================
function ZS.PickSpawnPoint()
    if #ZS.SpawnPoints == 0 then return nil end

    local players = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then table.insert(players, ply:GetPos()) end
    end
    if #players == 0 then
        return ZS.SpawnPoints[math.random(#ZS.SpawnPoints)]
    end

    local best, bestScore = nil, -math.huge
    for _, pt in ipairs(ZS.SpawnPoints) do
        local minDist = math.huge
        for _, pp in ipairs(players) do
            local d = pt:Distance(pp)
            if d < minDist then minDist = d end
        end
        local score
        if minDist > 1200 and minDist < 6000 then
            score = minDist
        elseif minDist >= 6000 then
            score = 6000 - (minDist - 6000) * 0.5
        else
            score = -1
        end
        if score > bestScore then
            bestScore = score
            best = pt
        end
    end

    return best or ZS.SpawnPoints[math.random(#ZS.SpawnPoints)]
end

-- ============================================================================
-- COMPOSIZIONE ONDATA: scegli classe NPC pesata dalle impostazioni onda
-- ============================================================================
function ZS.PickZombieClass(wave)
    local cfg = ZS.GetWaveSettings(wave)
    local types = cfg.types
    if not types then return GetConVarString("zs_zombietype") end

    local total = 0
    for _, w in pairs(types) do total = total + w end
    local roll = math.Rand(0, total)
    local acc = 0
    for cls, w in pairs(types) do
        acc = acc + w
        if roll <= acc then return cls end
    end
    return GetConVarString("zs_zombietype")
end

-- ============================================================================
-- SPAWN DI UN SINGOLO ZOMBIE
-- ============================================================================
function ZS.SpawnOneZombie()
    if ZS.ZombiesAlive >= GetConVarNumber("zs_maxzombies") then return false end

    local pos = ZS.PickSpawnPoint()
    if not pos then return false end

    local cls = ZS.PickZombieClass(ZS.Wave)
    local npc = ents.Create(cls)
    if not IsValid(npc) then return false end

    npc:SetPos(pos)
    npc:SetAngles(Angle(0, math.Rand(0, 360), 0))
    npc:Spawn()
    npc:Activate()

    -- Scala la salute con le impostazioni dell'ondata (hp_scale)
    local cfg = ZS.CurrentWaveSettings or ZS.GetWaveSettings(ZS.Wave)
    local hpScale = cfg.hp_scale or (1 + (ZS.Wave - 1) * 0.08)
    npc:SetHealth(math.floor(npc:Health() * hpScale))

    -- Gli zombie HL2 sono già ostili ai player di default;
    -- il target è gestito dalla schedula nativa (closest player).

    ZS.ZombiesAlive = ZS.ZombiesAlive + 1
    ZS.ActiveZombies[npc] = true
    return true
end

-- ============================================================================
-- GESTIONE KILL/ZOMBIE RIMOSSI
-- ============================================================================
function ZS.OnZombieRemoved(npc, killer)
    if not ZS.ActiveZombies[npc] then return end
    ZS.ActiveZombies[npc] = nil
    ZS.ZombiesAlive = math.max(0, ZS.ZombiesAlive - 1)
    ZS.KillsThisWave = ZS.KillsThisWave + 1

    -- Ricompensa per kill solo se l'attacker è un player
    if IsValid(killer) and killer:IsPlayer() then
        local bonus = GetConVarNumber("zs_payoutperkill")
        ZS.AddMoney(killer, bonus)
        killer:SetNWInt(ZS.NW_KILLS, killer:GetNWInt(ZS.NW_KILLS, 0) + 1)
        killer:SetNWInt(ZS.NW_SCORE, killer:GetNWInt(ZS.NW_SCORE, 0) + 10)
    end

    ZS.BroadcastState()
end

-- NPCKilled passa attacker/inflictor; EntityRemoved è il fallback per
-- zombie rimossi in altri modi (map cleanup, admin). Usiamo un flag per
-- non contare due volte la stessa entità.
hook.Add("NPCKilled", "ZS_TrackKill", function(npc, attacker, inflictor)
    if ZS.ActiveZombies[npc] then
        npc.ZS_Killer = attacker
    end
end)

hook.Add("EntityRemoved", "ZS_CleanupZombie", function(ent)
    if ZS.ActiveZombies[ent] then
        ZS.OnZombieRemoved(ent, ent.ZS_Killer)
    end
end)

-- ============================================================================
-- PULIZIA MONDO: blocca spawn casuali di NPC di sandbox e entity inutili
-- ============================================================================
hook.Add("OnNPCSpawn", "ZS_BlockRandomNPCs", function(npc)
    -- Blocca NPC creati fuori dal nostro controllo (spawnmenu/merge)
    -- durante la partita; gli admin possono comunque generare con zs_
    if ZS.CurrentState == ZS.State.WAVE or ZS.CurrentState == ZS.State.BUYTIME then
        if not ZS.ActiveZombies[npc] then
            timer.Simple(0, function()
                if IsValid(npc) and not ZS.ActiveZombies[npc] and not npc:CreatedByMap() then
                    npc:Remove()
                end
            end)
        end
    end
end)

-- Niente oggettiPhysgun in buytime per non bloccare gli spawn point
-- (i player possono comunque divertirsi con la physgun in sandbox base)

-- ============================================================================
-- CONCOMMAND: POSIZIONAMENTO BARRICATA (dal client ghost)
-- ============================================================================
concommand.Add("zs_placebarricade", function(ply, cmd, args)
    if not IsValid(ply) or not ply:Alive() then return end
    if ZS.CurrentState ~= ZS.State.BUYTIME and GetConVarNumber("zs_allowbuyduringwave") == 0 then
        ply:ChatPrint("Puoi posizionare barricate solo durante il buytime.")
        return
    end

    local class = args[1]
    local cfg = ZS.FindBarricade(class)
    if not cfg then return end

    -- Verifica limite (double-check)
    local count = 0
    for _, ent in ipairs(ents.FindByClass(class)) do
        if IsValid(ent) and ent:GetBarricadeOwner() == ply then count = count + 1 end
    end
    if count >= (cfg.limit or 1) then
        ply:ChatPrint("Hai già il massimo di '" .. cfg.name .. "' piazzate.")
        return
    end

    -- Trace davanti al player
    local tr = util.TraceLine({
        start  = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 120,
        filter = ply,
        mask   = MASK_SOLID_BRUSHONLY,
    })

    if not tr.Hit then
        ply:ChatPrint("Nessuna superficie valida davanti a te.")
        return
    end

    -- Crea entità
    local ent = ents.Create(class)
    if not IsValid(ent) then return end

    ent:SetPos(tr.HitPos + tr.HitNormal * 16)
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    ent:Spawn()
    ent:Activate()
    ent:SetBarricadeOwner(ply)

    -- Assicura che la fisica sia ferma
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    ply:EmitSound("physics/wood/wood_plank_impact_hard" .. math.random(1, 3) .. ".wav", 65, 100)

    net.Start("ZS_Notify")
        net.WriteString("Piazzata: " .. cfg.name)
        net.WriteString("success")
    net.Send(ply)
end)
