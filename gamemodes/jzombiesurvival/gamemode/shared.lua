-- Zombie Survival - shared.lua
-- Caricato sia su server che su client

AddCSLuaFile()

GM.Name     = "Zombie Survival"
GM.Author   = "JDReach"
GM.Email    = ""
GM.Website  = ""
GM.Version  = "1.0"

-- ============================================================================
-- COSTANTI GLOBALI DELLA GAMEMODE
-- ============================================================================
ZS = ZS or {}

ZS.State = {
    WAITING  = 1,  -- pre-partita / lobby
    BUYTIME  = 2,  -- tra un'ondata e l'altra, si compra allo shop
    WAVE     = 3,  -- ondata in corso
    GAMEOVER = 4   -- tutti morti
}

-- Chiavi network usate ovunque
ZS.NW_WAVE       = "ZS_Wave"
ZS.NW_STATE      = "ZS_State"
ZS.NW_COUNTDOWN  = "ZS_Countdown"
ZS.NW_ZOMBIES    = "ZS_ZombiesLeft"
ZS.NW_MONEY      = "ZS_Money"        -- NW su ogni player
ZS.NW_SCORE      = "ZS_Score"        -- NW su ogni player
ZS.NW_KILLS      = "ZS_Kills"        -- NW su ogni player

-- Config di rete (cvar lato server)
CreateConVar("zs_startmoney",   "500",  FCVAR_NOTIFY,  "Soldi iniziali di ogni giocatore")
CreateConVar("zs_waveinterval", "45",   FCVAR_NOTIFY,  "Secondi di buytime tra le ondate")
CreateConVar("zs_maxzombies",   "64",   FCVAR_NOTIFY,  "Numero massimo di zombie contemporanei")
CreateConVar("zs_wavescale",    "1.15", FCVAR_NOTIFY,  "Moltiplicatore crescita zombie per ondata")
CreateConVar("zs_hordesize",    "8",    FCVAR_NOTIFY,  "Zombie base alla prima ondata")
CreateConVar("zs_spawnradius",  "2500", FCVAR_NOTIFY,  "Raggio dai bordi mappa dove spawnano gli zombie")
CreateConVar("zs_payoutbase",   "100",  FCVAR_NOTIFY,  "Soldi base a fine ondata")
CreateConVar("zs_payoutperkill","5",    FCVAR_NOTIFY,  "Soldi per ogni zombie ucciso")
CreateConVar("zs_zombietype",   "npc_zombie", FCVAR_NOTIFY|FCVAR_REPLICATED, "Class NPC base degli zombie normali")
CreateConVar("zs_fasttype",     "npc_zombie_torso", FCVAR_NOTIFY|FCVAR_REPLICATED, "Class NPC zombie veloci")
CreateConVar("zs_poisonType",   "npc_poisonzombie", FCVAR_NOTIFY|FCVAR_REPLICATED, "Class NPC zombie velenosi")
CreateConVar("zs_allowbuyduringwave", "0", FCVAR_NOTIFY, "Permette di comprare durante l'ondata")

-- ============================================================================
-- FUNZIONI SHARED UTILI
-- ============================================================================

-- Formatta un numero come valuta ($1,234)
function ZS.FormatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    local neg = amount < 0
    amount = math.abs(amount)
    local formatted = tostring(amount)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return (neg and "-$" or "$") .. formatted
end

-- Stato corrente leggibile (client usa la variabile replicata)
function ZS.GetStateName(state)
    state = state or ZS.State.WAITING
    for k, v in pairs(ZS.State) do
        if v == state then return k end
    end
    return "UNKNOWN"
end