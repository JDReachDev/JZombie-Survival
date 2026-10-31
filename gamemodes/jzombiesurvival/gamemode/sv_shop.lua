-- JZombie Survival - sv_shop.lua
-- Logica acquisti lato server (autorevole)

util.AddNetworkString("ZS_PurchaseBarricade")
util.AddNetworkString("ZS_StartBarricadePlacement")

-- ============================================================================
-- CONTATORI POSSEDUTE
-- ============================================================================
local function CountOfClass(ply, class)
    local n = 0
    for _, wep in ipairs(ply:GetWeapons()) do
        if wep:GetClass() == class then n = n + 1 end
    end
    return n
end

local function CountBarricades(ply, class)
    local n = 0
    for _, ent in ipairs(ents.FindByClass(class)) do
        if IsValid(ent) and ent:GetBarricadeOwner() == ply then
            n = n + 1
        end
    end
    return n
end

-- ============================================================================
-- ACQUISTO ARMA
-- ============================================================================
net.Receive("ZS_PurchaseWeapon", function(_, ply)
    local class = net.ReadString()
    local cfg = ZS.FindWeapon(class)

    if not cfg then
        ply:ChatPrint("[Shop] Arma sconosciuta o non configurata.")
        return
    end

    -- Tier gate
    if (cfg.tier or 1) > ZS.Wave and ZS.Wave > 0 then
        ply:ChatPrint("[Shop] '" .. cfg.name .. "' si sblocca all'ondata " .. cfg.tier .. ".")
        return
    end

    -- Buytime gate (a meno che la cvar non permetta acquisti durante l'ondata)
    if ZS.CurrentState ~= ZS.State.BUYTIME and GetConVarNumber("zs_allowbuyduringwave") == 0 then
        ply:ChatPrint("[Shop] Puoi acquistare solo tra un'ondata e l'altra.")
        return
    end

    -- Limite possidenza
    local limit = cfg.limit or 1
    if CountOfClass(ply, cfg.class) >= limit then
        ply:ChatPrint("[Shop] Possiedi già il massimo di '" .. cfg.name .. "'.")
        return
    end

    -- Verifica che la SWEP esista davvero sul server
    if not list.Get("Weapon")[cfg.class] and not scripted_ents.Get(cfg.class) then
        ply:ChatPrint("[Shop] L'arma '" .. cfg.class .. "' non è installata su questo server.")
        return
    end

    -- Addebito
    if not ZS.TrySpend(ply, cfg.price) then
        ply:ChatPrint("[Shop] Soldi insufficienti: servono " .. ZS.FormatMoney(cfg.price) .. ".")
        return
    end

    -- Consegna arma + munizioni incluse
    local wep = ply:Give(cfg.class)
    if IsValid(wep) and cfg.ammo_class then
        local ammoCfg = ZS.FindAmmo(cfg.ammo_class)
        if ammoCfg and (cfg.starting or 0) > 0 then
            ply:GiveAmmo(cfg.starting, ammoCfg.class)
        end
    end

    net.Start("ZS_Notify")
        net.WriteString("Acquistato: " .. cfg.name .. " (-" .. ZS.FormatMoney(cfg.price) .. ")")
        net.WriteString("success")
    net.Send(ply)
end)

-- ============================================================================
-- ACQUISTO MUNIZIONI
-- ============================================================================
net.Receive("ZS_PurchaseAmmo", function(_, ply)
    local key = net.ReadString()
    local cfg = ZS.FindAmmo(key)

    if not cfg then
        ply:ChatPrint("[Shop] Tipo di munizione sconosciuto.")
        return
    end

    if ZS.CurrentState ~= ZS.State.BUYTIME and GetConVarNumber("zs_allowbuyduringwave") == 0 then
        ply:ChatPrint("[Shop] Puoi acquistare solo tra un'ondata e l'altra.")
        return
    end

    -- Cap sulle munizioni trasportabili
    if cfg.max then
        local current = ply:GetAmmoCount(cfg.class)
        if current >= cfg.max then
            ply:ChatPrint("[Shop] Hai già il massimo di " .. cfg.name .. ".")
            return
        end
        -- Limita il pacchetto se supera il cap
        local giveAmount = math.min(cfg.amount, cfg.max - current)
        if giveAmount <= 0 then return end

        -- Prezzo proporzionale se tagliamo il pacchetto
        local price = math.ceil(cfg.price * (giveAmount / cfg.amount))
        if not ZS.TrySpend(ply, price) then
            ply:ChatPrint("[Shop] Soldi insufficienti: servono " .. ZS.FormatMoney(price) .. ".")
            return
        end
        ply:GiveAmmo(giveAmount, cfg.class)
        net.Start("ZS_Notify")
            net.WriteString("+" .. giveAmount .. " " .. cfg.name .. " (-" .. ZS.FormatMoney(price) .. ")")
            net.WriteString("success")
        net.Send(ply)
    else
        if not ZS.TrySpend(ply, cfg.price) then
            ply:ChatPrint("[Shop] Soldi insufficienti: servono " .. ZS.FormatMoney(cfg.price) .. ".")
            return
        end
        ply:GiveAmmo(cfg.amount, cfg.class)
        net.Start("ZS_Notify")
            net.WriteString("+" .. cfg.amount .. " " .. cfg.name .. " (-" .. ZS.FormatMoney(cfg.price) .. ")")
            net.WriteString("success")
        net.Send(ply)
    end
end)

-- ============================================================================
-- VENDITA ARMA (metà prezzo)
-- ============================================================================
net.Receive("ZS_SellWeapon", function(_, ply)
    local class = net.ReadString()
    local cfg = ZS.FindWeapon(class)
    if not cfg then return end

    if CountOfClass(ply, class) <= 0 then
        ply:ChatPrint("[Shop] Non possiedi '" .. cfg.name .. "'.")
        return
    end

    if ZS.CurrentState ~= ZS.State.BUYTIME then
        ply:ChatPrint("[Shop] Puoi vendere solo tra un'ondata e l'altra.")
        return
    end

    local refund = math.floor(cfg.price * 0.5)
    ply:StripWeapon(class)
    ZS.AddMoney(ply, refund)

    net.Start("ZS_Notify")
        net.WriteString("Venduto: " .. cfg.name .. " (+" .. ZS.FormatMoney(refund) .. ")")
        net.WriteString("info")
    net.Send(ply)
end)

-- ============================================================================
-- ACQUISTO BARRICATA
-- Invia al client l'entità da posizionare (ghost preview + click per posizionare)
-- ============================================================================
net.Receive("ZS_PurchaseBarricade", function(_, ply)
    local class = net.ReadString()
    local cfg = ZS.FindBarricade(class)

    if not cfg then
        ply:ChatPrint("[Shop] Barricata sconosciuta.")
        return
    end

    -- Tier gate
    if (cfg.tier or 1) > ZS.Wave and ZS.Wave > 0 then
        ply:ChatPrint("[Shop] '" .. cfg.name .. "' si sblocca all'ondata " .. cfg.tier .. ".")
        return
    end

    -- Buytime gate
    if ZS.CurrentState ~= ZS.State.BUYTIME and GetConVarNumber("zs_allowbuyduringwave") == 0 then
        ply:ChatPrint("[Shop] Puoi acquistare solo tra un'ondata e l'altra.")
        return
    end

    -- Limite possidenza
    local limit = cfg.limit or 1
    if CountBarricades(ply, cfg.class) >= limit then
        ply:ChatPrint("[Shop] Hai già il massimo di '" .. cfg.name .. "' piazzate.")
        return
    end

    -- Verifica entità SENT esiste
    if not scripted_ents.Get(cfg.class) then
        ply:ChatPrint("[Shop] L'entità '" .. cfg.class .. "' non è installata.")
        return
    end

    -- Addebito
    if not ZS.TrySpend(ply, cfg.price) then
        ply:ChatPrint("[Shop] Soldi insufficienti: servono " .. ZS.FormatMoney(cfg.price) .. ".")
        return
    end

    -- Invia al client: inizia modalità posizionamento
    net.Start("ZS_StartBarricadePlacement")
        net.WriteString(cfg.class)
        net.WriteString(cfg.name)
    net.Send(ply)

    net.Start("ZS_Notify")
        net.WriteString("Posiziona: " .. cfg.name .. " (LMB=piazza, RMB=annulla)")
        net.WriteString("info")
    net.Send(ply)
end)