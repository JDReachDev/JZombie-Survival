-- JZombie Survival - cl_notifications.lua
-- Sistema di popup/toast temporanei sullo schermo

ZS = ZS or {}
ZS.Notifications = ZS.Notifications or {}

local COLORS = {
    info    = Color(80, 160, 255),
    success = Color(90, 220, 110),
    warn    = Color(255, 190, 60),
    error   = Color(255, 80, 80),
}

-- Definisci il font per le notifiche (deve essere creato prima dell'uso)
surface.CreateFont("ZS_Notify", { font = "Trebuchet22", size = 16, weight = 600 })

function ZS.PushNotify(text, typ)
    table.insert(ZS.Notifications, {
        text  = text,
        typ   = typ or "info",
        start = RealTime(),
        life  = 4,
    })
end

hook.Add("HUDPaint", "ZS_DrawNotifications", function()
    local scrH = ScrH()
    local y = ScrH() * 0.18

    for i = #ZS.Notifications, 1, -1 do
        local n = ZS.Notifications[i]
        local t = RealTime() - n.start
        if t > n.life then
            table.remove(ZS.Notifications, i)
        else
            -- fade in/out
            local alpha = 255
            if t < 0.3 then alpha = math.Round(255 * (t / 0.3)) end
            if t > n.life - 0.5 then alpha = math.Round(255 * ((n.life - t) / 0.5)) end

            surface.SetFont("ZS_Notify")
            local w = surface.GetTextSize(n.text)
            local padX, padY = 18, 10
            local bx = ScrW() / 2 - (w + padX * 2) / 2

            draw.RoundedBox(6, bx, y, w + padX * 2, 34, Color(15, 15, 18, alpha * 0.85))
            surface.SetDrawColor(COLORS[n.typ] or COLORS.info)
            surface.DrawRect(bx, y, 4, 34)

            draw.SimpleText(n.text, "ZS_Notify", ScrW() / 2, y + 6, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
            y = y + 42
        end
    end
end)