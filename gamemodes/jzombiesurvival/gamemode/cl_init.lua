-- Zombie Survival - cl_init.lua
-- Entry point client

include("shared.lua")
include("sh_config.lua")

include("cl_hud.lua")
include("cl_shop.lua")
include("cl_notifications.lua")

-- Replica stato globale -> locale perché derma/netstring funzionino subito
net.Receive("ZS_SyncState", function()
    ZS.CurrentWave      = net.ReadInt(16)
    ZS.CurrentState     = net.ReadShort()
    ZS.CurrentCountdown = net.ReadFloat()
    ZS.ZombiesAlive     = net.ReadInt(16)
end)

-- Notifica testuale rapida (es. "Ondata 5 completata!")
net.Receive("ZS_Notify", function()
    local text = net.ReadString()
    local typ  = net.ReadString()   -- info | success | warn | error
    ZS.PushNotify(text, typ)
end)

-- Soldi aggiornati dal server
net.Receive("ZS_MoneyUpdate", function()
    LocalPlayer().ZS_MoneyCache = net.ReadInt(32)
end)

-- Apertura/chiusura shop remota
net.Receive("ZS_OpenShop", function()
    ZS.OpenShop()
end)
net.Receive("ZS_CloseShop", function()
    ZS.CloseShop()
end)

-- TASTO SHOP: premi "4" per aprire/chiudere la finestra armeria.
-- Il 4 è bindato alla selezione slot armi, quindi intercettiamo sia il
-- PlayerBindPress sia il polling del tasto (edge detection).
local wasDown = false
hook.Add("Think", "ZS_ShopHotkey", function()
    if gui.IsGameUIVisible() then return end
    local down = input.IsKeyDown(KEY_4)
    if down and not wasDown then
        ZS.ToggleShop()
    end
    wasDown = down
end)

-- Se lo shop è aperto, blocca la selezione slot 4
hook.Add("PlayerBindPress", "ZS_BlockSlot4", function(ply, bind, pressed)
    if ZS.ShopOpen and (bind == "slot4" or bind == "num4") then
        return true
    end
end)