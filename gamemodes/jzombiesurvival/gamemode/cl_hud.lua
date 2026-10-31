-- JZombie Survival - cl_hud.lua
-- HUD: onda corrente, countdown, zombie rimasti, soldi, kills

ZS = ZS or {}

surface.CreateFont("ZS_WaveBig",   { font = "Trebuchet24", size = 34, weight = 1000, blursize = 2 })
surface.CreateFont("ZS_HudSmall",  { font = "Trebuchet",   size = 16, weight = 600 })
surface.CreateFont("ZS_Money",     { font = "Trebuchet24", size = 26, weight = 1000 })

local STATE_COLORS = {
    [1] = Color(120, 160, 200),  -- WAITING
    [2] = Color(90, 220, 110),   -- BUYTIME
    [3] = Color(255, 80, 60),    -- WAVE
    [4] = Color(200, 60, 60),    -- GAMEOVER
}

local function DrawPanel(x, y, w, h, alpha)
    draw.RoundedBox(5, x, y, w, h, Color(12, 12, 15, alpha or 200))
    surface.SetDrawColor(Color(60, 60, 70, alpha or 200))
    surface.DrawOutlinedRect(x, y, w, h)
end

hook.Add("HUDPaint", "ZS_DrawHUD", function()
    local wave      = ZS.CurrentWave      or 0
    local state     = ZS.CurrentState     or 1
    local countdown = ZS.CurrentCountdown or 0
    local zombies   = ZS.ZombiesAlive     or 0
    local ply       = LocalPlayer()
    local money     = ply:GetNWInt(ZS.NW_MONEY, 0)
    local kills     = ply:GetNWInt(ZS.NW_KILLS, 0)

    local sw = ScrW()

    ---------------------------------------------------------------
    -- PANNELLO SUPERIORE CENTRALE: stato + onda + timer/zombie
    ---------------------------------------------------------------
    local pw, ph = 300, 72
    local px, py = (sw - pw) / 2, 12
    DrawPanel(px, py, pw, ph)

    -- Titolo stato
    local stateName = "ATTESA"
    if state == 2 then stateName = "ACQUISTI"
    elseif state == 3 then stateName = "ONDATA IN CORSO"
    elseif state == 4 then stateName = "GAME OVER" end

    draw.SimpleText(stateName, "ZS_HudSmall", px + pw / 2, py + 6,
        STATE_COLORS[state] or color_white, TEXT_ALIGN_CENTER)

    -- Numero onda grande
    draw.SimpleText("ONDATA " .. wave, "ZS_WaveBig", px + pw / 2, py + 22,
        color_white, TEXT_ALIGN_CENTER, Color(0, 0, 0, 200))

    -- Sotto: countdown o zombie rimasti
    if state == 2 then
        local s = math.max(0, math.ceil(countdown))
        draw.SimpleText("Prossima ondata tra " .. s .. "s", "ZS_HudSmall",
            px + pw / 2, py + ph - 22, Color(255, 220, 120), TEXT_ALIGN_CENTER)
    elseif state == 3 then
        draw.SimpleText(zombies .. " zombie rimasti", "ZS_HudSmall",
            px + pw / 2, py + ph - 22, Color(255, 120, 100), TEXT_ALIGN_CENTER)
    end

    ---------------------------------------------------------------
    -- PANNELLO SOLDI/KILL: angolo in basso a destra
    ---------------------------------------------------------------
    local mw, mh = 210, 56
    local mx, my = sw - mw - 16, ScrH() - mh - 90
    DrawPanel(mx, my, mw, mh)

    draw.SimpleText(ZS.FormatMoney(money), "ZS_Money", mx + mw - 12, my + 6,
        Color(120, 255, 140), TEXT_ALIGN_RIGHT)
    draw.SimpleText("Kills: " .. kills, "ZS_HudSmall", mx + mw - 12, my + 34,
        Color(200, 200, 200), TEXT_ALIGN_RIGHT)

    ---------------------------------------------------------------
    -- HINT APERTURA SHOP durante buytime
    ---------------------------------------------------------------
    if state == 2 and not ZS.ShopOpen then
        draw.SimpleText("Premi [4] per aprire l'armeria", "ZS_HudSmall",
            sw / 2, ScrH() - 130, Color(255, 255, 255, 180), TEXT_ALIGN_CENTER)
    end
end)

-- Nasconde elementi HUD di sandbox inutili
hook.Add("HUDShouldDraw", "ZS_HideDefaults", function(name)
    if name == "CHudVehicle" then return false end
end)