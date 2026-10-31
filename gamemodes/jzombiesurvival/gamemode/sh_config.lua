-- Zombie Survival - sh_config.lua
-- CONFIGURAZIONE ARME E MUNIZIONI DELLO SHOP
--
-- Ogni arma è referenziata per CLASSNAME SWEP (l'ID dell'addon/installato).
-- Se un'arma non esiste sul server viene semplicemente ignorata allo shop.
--
-- Campi arma:
--   class       string    classname SWEP es. "weapon_cs_m4a1"
--   name        string    nome mostrato nello shop
--   price       number    costo in $
--   ammo_class  string    chiave nel blocco AMMO qui sotto (nil se non serve)
--   starting    number    munizioni incluse all'acquisto (default 0)
--   limit       number    cap max scorte che il player può possedere (default 1)
--   category    string    raggruppamento UI: "Pistole", "Fucili", ecc.
--   tier        number    ondata minima per sbloccarla (1 = sempre disponibile)
--   desc        string    descrizione breve opzionale
--
-- Campi munizioni:
--   class       string    AmmoType del gioco es. "SMG1", "Pistol", "AR2"
--   name        string    nome mostrato
--   price       number    costo del pacchetto
--   amount      number    quante munzioni dà il pacchetto
--   max         number    cap totale che il player può portare (opzionale)

if SERVER then AddCSLuaFile() end

ZS = ZS or {}

-- =========================================================================
-- CATEGORIE (solo per ordinamento UI)
-- =========================================================================
ZS.Categories = {
    "Pistole",
    "Mitragliette",
    "Fucili a pompa",
    "Fucili d'assalto",
    "Cecchini",
    "Pesanti",
    "Corpo a corpo",
    "Utilità",
    "Barricate",        -- NUOVA: barricate/oggetti deployabili
}

-- =========================================================================
-- TIPI DI MUNIZION ACQUISTABILI
-- =========================================================================
ZS.AmmoTypes = {
    pistol = {
        class  = "Pistol",
        name   = "9mm Pistol",
        price  = 25,
        amount = 68,
        max    = 250,
    },
    smg = {
        class  = "SMG1",
        name   = "9mm SMG",
        price  = 40,
        amount = 150,
        max    = 600,
    },
    ar2 = {
        class  = "AR2AltAmmo",
        name   = "5.56 AR2",
        price  = 75,
        amount = 120,
        max    = 500,
    },
    buckshot = {
        class  = "Buckshot",
        name   = "Cartucce 12g",
        price  = 60,
        amount = 30,
        max    = 150,
    },
    sniper = {
        class  = "357",
        name   = ".357 Magnum",
        price  = 90,
        amount = 21,
        max    = 100,
    },
    rpg = {
        class  = "RPG_Round",
        name   = "Missili RPG",
        price  = 250,
        amount = 3,
        max    = 10,
    },
    crossbow = {
        class  = "Crossbow",
        name   = "Baleste",
        price  = 30,
        amount = 15,
        max    = 60,
    },
    grenade = {
        class  = "Grenade",
        name   = "Granate",
        price  = 150,
        amount = 2,
        max    = 5,
    },
}

-- =========================================================================
-- ARME IN VENDITA
-- =========================================================================
-- NOTA: i classname sono esempi basati sulle SWEP stock di HL2/GMod.
-- Sostituiscili con quelli degli addon che hai installato.
-- Per trovare l'ID di un'arma: apri la spawnmenu > Armi > tasto destro > Copy classname.
-- =========================================================================
ZS.ShopWeapons = {
    ---------------------------------------------------------------------
    -- PISTOLE
    ---------------------------------------------------------------------
    {
        class      = "weapon_pistol",
        name       = "Desert Eagle",
        category   = "Pistole",
        price      = 150,
        ammo_class = "pistol",
        starting   = 34,
        limit      = 2,
        tier       = 1,
        desc       = "Affidabile, economica, buoni danni.",
    },

    ---------------------------------------------------------------------
    -- MITRAGLIETTE
    ---------------------------------------------------------------------
    {
        class      = "weapon_smg1",
        name       = "MP5",
        category   = "Mitragliette",
        price      = 400,
        ammo_class = "smg",
        starting   = 75,
        limit      = 1,
        tier       = 1,
        desc       = "Alta cadenza, ottimo controllo.",
    },

    ---------------------------------------------------------------------
    -- FUCILI A POMPA
    ---------------------------------------------------------------------
    {
        class      = "weapon_crossbow",
        name       = "Balestra",
        category   = "Fucili a pompa",
        price      = 600,
        ammo_class = "crossbow",
        starting   = 5,
        limit      = 1,
        tier       = 2,
        desc       = "Silenziosa, colpi critici potenti.",
    },
    {
        class      = "weapon_shotgun",
        name       = "SPAS-12",
        category   = "Fucili a pompa",
        price      = 900,
        ammo_class = "buckshot",
        starting   = 8,
        limit      = 1,
        tier       = 3,
        desc       = "Devastante a corto raggio.",
    },

    ---------------------------------------------------------------------
    -- FUCILI D'ASSALTO
    ---------------------------------------------------------------------
    {
        class      = "weapon_ar2",
        name       = "AK-47",
        category   = "Fucili d'assalto",
        price      = 1500,
        ammo_class = "ar2",
        starting   = 60,
        limit      = 1,
        tier       = 4,
        desc       = "Danno elevato, buon rateo.",
    },

    ---------------------------------------------------------------------
    -- CECCHINI
    ---------------------------------------------------------------------
    {
        class      = "weapon_357",
        name       = "Magnum .357",
        category   = "Cecchini",
        price      = 1200,
        ammo_class = "sniper",
        starting   = 6,
        limit      = 2,
        tier       = 3,
        desc       = "Un colpo, un morto (si spera).",
    },

    ---------------------------------------------------------------------
    -- PESANTI
    ---------------------------------------------------------------------
    {
        class      = "weapon_rpg",
        name       = "RPG-7",
        category   = "Pesanti",
        price      = 4000,
        ammo_class = "rpg",
        starting   = 1,
        limit      = 1,
        tier       = 6,
        desc       = "Anti-orde. Attenzione ai rimbalzi.",
    },

    ---------------------------------------------------------------------
    -- CORPO A CORPO
    ---------------------------------------------------------------------
    {
        class      = "weapon_crowbar",
        name       = "Piede di porco",
        category   = "Corpo a corpo",
        price      = 50,
        ammo_class = nil,
        starting   = 0,
        limit      = 1,
        tier       = 1,
        desc       = "Gratuito quasi. Riemergere le scorte.",
    },
    {
        class      = "weapon_physcannon",
        name       = "Gravity Gun",
        category   = "Corpo a corpo",
        price      = 2500,
        ammo_class = nil,
        starting   = 0,
        limit      = 1,
        tier       = 5,
        desc       = "Lancia zombie contro zombie.",
    },

    ---------------------------------------------------------------------
    -- UTILITÀ
    ---------------------------------------------------------------------
    {
        class      = "weapon_frag",
        name       = "Granata a frammentazione",
        category   = "Utilità",
        price      = 300,
        ammo_class = "grenade",
        starting   = 1,
        limit      = 5,
        tier       = 2,
        desc       = "Pulisci gli angoli difficili.",
    },
}

-- =========================================================================
-- BARRICATE / OGGETTI DEPLOYABILI
-- Si comprano dallo shop (categoria "Barricate") e si posizionano con LMB.
-- Campi:
--   class       string    nome entità SENT (deve esistere in entities/)
--   name        string    nome nello shop
--   price       number    costo in $
--   limit       number    max pezzi che un player può avere contemporaneamente (default 1)
--   tier        number    ondata minima per sbloccare (default 1)
--   desc        string    descrizione
--   model       string    modello (override, opzionale)
--   health      number    HP della barricata (default 500)
-- =========================================================================
ZS.Barricades = {
    {
        class   = "zs_barricade_plank",
        name    = "Tavole di legno",
        price   = 80,
        limit   = 6,
        tier    = 1,
        desc    = "Barricata economica, si rompe in fretta.",
        health  = 300,
    },
    {
        class   = "zs_barricade_sandbag",
        name    = "Sacchi di sabbia",
        price   = 250,
        limit   = 4,
        tier    = 2,
        desc    = "Più resistenti, buoni per coperture.",
        health  = 800,
    },
    {
        class   = "zs_barricade_metal",
        name    = "Lamiere metalliche",
        price   = 600,
        limit   = 3,
        tier    = 4,
        desc    = "Massima durata, rallentano i zombie.",
        health  = 2000,
    },
    {
        class   = "zs_barricade_wire",
        name    = "Filo spinato",
        price   = 150,
        limit   = 8,
        tier    = 2,
        desc    = "Danneggia e rallenta i zombie che ci passano.",
        health  = 400,
    },
    {
        class   = "zs_barricade_crate",
        name    = "Cassa rinforzata",
        price   = 400,
        limit   = 2,
        tier    = 3,
        desc    = "Alta, fa da copertura e ostacolo.",
        health  = 1200,
    },
    {
        class   = "zs_barricade_turret",
        name    = "Torretta automatica",
        price   = 2500,
        limit   = 1,
        tier    = 6,
        desc    = "Spara ai zombie in autonomia (munizioni finite).",
        health  = 600,
    },
}

-- =========================================================================
-- RICOMPENSE PER ONDATA (override rispetto alle cvars se valorizzato)
-- key = numero ondata, value = tabella { money = X, bonus = Y }
-- =========================================================================
ZS.WaveRewards = {
    [5]  = { bonus = 500 },   -- traguardo: extra $500 al quinto
    [10] = { bonus = 1500 },
    [20] = { bonus = 5000 },
    [30] = { bonus = 10000 },
}

-- =========================================================================
-- COMPOSIZIONE ZOMBI PER ONDATA (default per ondate non custom)
-- Il wave manager pesca da qui; se l'ondata supera la tabella usa l'ultima entry.
-- =========================================================================
ZS.WaveComposition = {
    { min = 1,  types = { npc_zombie = 1.0 } },
    { min = 3,  types = { npc_zombie = 0.75, npc_zombie_torso = 0.25 } },
    { min = 6,  types = { npc_zombie = 0.55, npc_zombie_torso = 0.25, npc_poisonzombie = 0.20 } },
    { min = 10, types = { npc_zombie = 0.40, npc_zombie_torso = 0.30, npc_poisonzombie = 0.20, npc_headcrab_fast = 0.10 } },
    { min = 15, types = { npc_zombie = 0.30, npc_zombie_torso = 0.30, npc_poisonzombie = 0.25, npc_headcrab_fast = 0.15 } },
}

-- =========================================================================
-- ONDATE PERSONALIZZATE
-- Ogni entry in ZS.Waves overridea i default per QUELLA ondata specifica.
-- Campi (tutti opzionali):
--   count       number   quanti zombie (default: formula hordesize * wavescale^n)
--   types       table    composizione pesata {npc_zombie=0.7, ...} (default: WaveComposition)
--   buytime     number   secondi di shop PRIMA di quest'ondata (default: cvar zs_waveinterval)
--   payout      number   $ base a fine ondata (default: cvar zs_payoutbase + wave*25)
--   bonus       number   $ extra una tantum (default: ZS.WaveRewards[wave])
--   hp_scale    number   moltiplicatore salute zombie (default: 1 + (wave-1)*0.08)
--   spawn_delay number   secondi tra spawn (default: 0.35)
--   special     string   etichetta UI (es. "BOSS", "mini-boss", "horda")
--   announce    string   messaggio mostrato a inizio ondata (default: "ONDATA n in arrivo!")
--
-- Esempi:
-- ZS.Waves[5]  = { buytime = 90, announce = "ONDATA 5 — ULTIMA PREPARAZIONE!" }
-- ZS.Waves[10] = { count = 40, hp_scale = 3.0, special = "BOSS WAVE", announce = "IL BRUTO ARRIVA!" }
-- ZS.Waves[15] = { types = { npc_poisonzombie = 1.0 } }
-- =========================================================================
ZS.Waves = {}

-- Helper: restituisce i parametri EFFECTIVE dell'ondata n (custom > default)
function ZS.GetWaveSettings(n)
    n = math.max(1, tonumber(n) or 1)
    local custom = ZS.Waves and ZS.Waves[n] or nil

    local s = {}
    -- dimensione base
    if custom and custom.count then
        s.count = custom.count
    else
        local base = math.max(1, GetConVarNumber("zs_hordesize"))
        local scale = math.max(1, GetConVarNumber("zs_wavescale"))
        s.count = math.floor(base * math.pow(scale, n - 1))
    end
    -- buytime prima dell'ondata
    s.buytime = (custom and custom.buytime) or math.max(5, GetConVarNumber("zs_waveinterval"))
    -- payout fine ondata
    s.payout = (custom and custom.payout) or (GetConVarNumber("zs_payoutbase") + n * 25)
    -- bonus una tantum
    local rw = ZS.WaveRewards and ZS.WaveRewards[n]
    s.bonus = (custom and custom.bonus) or (rw and rw.bonus) or 0
    -- hp scaling
    s.hp_scale = (custom and custom.hp_scale) or (1 + (n - 1) * 0.08)
    -- delay spawn
    s.spawn_delay = (custom and custom.spawn_delay) or 0.35
    -- composizione types: custom > WaveComposition per min
    s.types = custom and custom.types or nil
    if not s.types then
        local comp = nil
        for _, entry in ipairs(ZS.WaveComposition or {}) do
            if n >= entry.min then comp = entry end
        end
        if not comp then comp = ZS.WaveComposition[#ZS.WaveComposition] end
        s.types = comp and comp.types or { [GetConVarString("zs_zombietype")] = 1 }
    end
    s.special = custom and custom.special or nil
    s.announce = custom and custom.announce or ("ONDATA " .. n .. " in arrivo!")
    return s
end

-- =========================================================================
-- HELPER DI LETTURA (condivisi)
-- =========================================================================

-- Cerca una weapon config per classname
function ZS.FindWeapon(classname)
    for _, w in ipairs(ZS.ShopWeapons or {}) do
        if w.class == classname then return w end
    end
end

-- Cerca una ammo config per chiave
function ZS.FindAmmo(key)
    return ZS.AmmoTypes and ZS.AmmoTypes[key] or nil
end

-- Cerca una barricata per classname
function ZS.FindBarricade(classname)
    for _, b in ipairs(ZS.Barricades or {}) do
        if b.class == classname then return b end
    end
end

-- Restituisce la lista delle armi disponibili per un certo numero di ondata
function ZS.AvailableForWave(wave)
    local out = {}
    for _, w in ipairs(ZS.ShopWeapons or {}) do
        if (w.tier or 1) <= wave then table.insert(out, w) end
    end
    return out
end

-- Restituisce la lista delle barricate disponibili per un certo numero di ondata
function ZS.AvailableBarricadesForWave(wave)
    local out = {}
    for _, b in ipairs(ZS.Barricades or {}) do
        if (b.tier or 1) <= wave then table.insert(out, b) end
    end
    return out
end