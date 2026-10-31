-- JZombie Survival - cl_shop.lua
-- Menu armeria con icone disegnate proceduralmente (nessun file .png necessario).
-- Ogni categoria ha la sua silhouette stilizzata; se nel config armi metti
--   icon = "some/material/path"
-- quella viene usata al posto del disegno procedurale.

ZS = ZS or {}
ZS.ShopOpen = false

-- ============================================================================
-- ICONE PROCEDURALI — silhouette per categoria, disegnate in un DPanel 48x48
-- ============================================================================
local IconPainters = {
    ["Pistole"] = function(p, w, h, col)
        p.DrawCol = col
        -- canna + impugnatura
        surface.SetDrawColor(col)
        surface.DrawRect(w*0.18, h*0.34, w*0.62, h*0.14)  -- carrello
        surface.DrawRect(w*0.62, h*0.40, w*0.12, h*0.10)  -- canna bassa
        surface.DrawRect(w*0.24, h*0.48, w*0.16, h*0.30)  -- impugnatura
        surface.DrawRect(w*0.30, h*0.48, w*0.10, h*0.12)  -- grilletto area
    end,
    ["Mitragliette"] = function(p, w, h, col)
        surface.SetDrawColor(col)
        surface.DrawRect(w*0.14, h*0.36, w*0.66, h*0.16)  -- corpo
        surface.DrawRect(w*0.72, h*0.40, w*0.18, h*0.06)  -- canna
        surface.DrawRect(w*0.30, h*0.52, w*0.10, h*0.30)  -- caricatore curvo
        surface.DrawRect(w*0.16, h*0.52, w*0.12, h*0.22)  -- impugnatura
    end,
    ["Fucili a pompa"] = function(p, w, h, col)
        surface.SetDrawColor(col)
        surface.DrawRect(w*0.10, h*0.38, w*0.78, h*0.10)  -- canna lunga
        surface.DrawRect(w*0.10, h*0.50, w*0.78, h*0.06)  -- tubo serbatoio
        surface.DrawRect(w*0.12, h*0.44, w*0.14, h*0.28)  -- calcio legno
        surface.DrawRect(w*0.36, h*0.50, w*0.10, h*0.18)  -- impugnatura
    end,
    ["Fucili d'assalto"] = function(p, w, h, col)
        surface.SetDrawColor(col)
        surface.DrawRect(w*0.08, h*0.36, w*0.80, h*0.12)  -- corpo
        surface.DrawRect(w*0.68, h*0.40, w*0.24, h*0.05)  -- canna
        surface.DrawRect(w*0.34, h*0.48, w*0.12, h*0.32)  -- caricatore
        surface.DrawRect(w*0.10, h*0.46, w*0.14, h*0.20)  -- calcio
        surface.DrawRect(w*0.44, h*0.30, w*0.10, h*0.06)  -- mirino
    end,
    ["Cecchini"] = function(p, w, h, col)
        surface.SetDrawColor(col)
        surface.DrawRect(w*0.08, h*0.40, w*0.84, h*0.09)  -- canna lunga
        surface.DrawRect(w*0.30, h*0.26, w*0.26, h*0.10)  -- ottica
        surface.DrawRect(w*0.34, h*0.49, w*0.10, h*0.22)  -- caricatore
        surface.DrawRect(w*0.08, h*0.46, w*0.16, h*0.22)  -- calcio
    end,
    ["Pesanti"] = function(p, w, h, col)
        surface.SetDrawColor(col)
        surface.DrawRect(w*0.14, h*0.34, w*0.70, h*0.16)  -- tubo RPG
        surface.DrawRect(w*0.78, h*0.30, w*0.14, h*0.24)  -- testata
        surface.DrawRect(w*0.30, h*0.50, w*0.12, h*0.24)  -- impugnatura
        surface.DrawRect(w*0.10, h*0.38, w*0.08, h*0.10)  -- imboccatura
    end,
    ["Corpo a corpo"] = function(p, w, h, col)
        surface.SetDrawColor(col)
        surface.DrawRect(w*0.20, h*0.60, w*0.58, h*0.09)  -- manico piede di porco
        surface.DrawRect(w*0.70, h*0.42, w*0.10, h*0.24)  -- curva testa
        surface.DrawRect(w*0.62, h*0.42, w*0.14, h*0.08)  -- punta
    end,
    ["Utilità"] = function(p, w, h, col)
        surface.SetDrawColor(col)
        -- granata: corpo ovale + cappuccio
        draw.NoTexture()
        surface.SetDrawColor(col)
        local cx, cy = w*0.5, h*0.58
        for yy = -12, 12 do
            local ww = math.floor(math.sqrt(144 - yy*yy) * 0.9)
            surface.DrawRect(cx - ww, cy + yy, ww*2, 1)
        end
        surface.DrawRect(cx - 4, h*0.28, 8, 6)   -- collo
        surface.DrawRect(cx - 6, h*0.22, 12, 4)  -- leva
    end,
}

local DEFAULT_ICON_COLOR = Color(210, 210, 220)

local function CreateIconPanel(parent, category, materialOverride, size)
    size = size or 48
    local p = vgui.Create("DPanel", parent)
    p:SetSize(size, size)
    p.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 26, 30, 255))
        surface.SetDrawColor(Color(70, 72, 80, 255))
        surface.DrawOutlinedRect(0, 0, w, h)

        if materialOverride and materialOverride ~= "" then
            surface.SetMaterial(materialOverride)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawTexturedRect(4, 4, w - 8, h - 8)
            return
        end

        local painter = IconPainters[category]
        if painter then
            painter(self, w, h, DEFAULT_ICON_COLOR)
        else
            -- fallback: croce + punto
            surface.SetDrawColor(DEFAULT_ICON_COLOR)
            surface.DrawRect(w*0.45, h*0.2, w*0.10, h*0.6)
            surface.DrawRect(w*0.2, h*0.45, w*0.6, h*0.10)
        end
    end
    return p
end

-- ============================================================================
-- PANNELLO SHOP
-- ============================================================================
local ShopFrame = nil

local function BuildWeaponRow(listPanel, wCfg)
    local affordable = LocalPlayer():GetNWInt(ZS.NW_MONEY, 0) >= wCfg.price
    local locked = (wCfg.tier or 1) > math.max(1, ZS.CurrentWave or 0)

    local row = vgui.Create("DPanel", listPanel)
    row:SetTall(60)
    row:Dock(TOP)
    row:DockMargin(2, 2, 2, 2)
    row.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 31, 36, 230))
        if self.Hovered then
            surface.SetDrawColor(Color(60, 90, 140, 120))
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    end

    -- Icona
    local mat = nil
    if wCfg.icon and wCfg.icon ~= "" then mat = Material(wCfg.icon, "noclamp smooth") end
    local icon = CreateIconPanel(row, wCfg.category, mat, 52)
    icon:SetPos(4, 4)

    -- Nome + descrizione
    local nameLabel = vgui.Create("DLabel", row)
    nameLabel:SetPos(64, 8)
    nameLabel:SetSize(row:GetWide() - 200, 20)
    nameLabel:SetText(wCfg.name)
    nameLabel:SetFont("DermaDefaultBold")
    nameLabel:SetTextColor(locked and Color(150, 150, 150) or color_white)

    local descLabel = vgui.Create("DLabel", row)
    descLabel:SetPos(64, 30)
    descLabel:SetSize(row:GetWide() - 200, 24)
    descLabel:SetText(locked and ("Si sblocca all'ondata " .. wCfg.tier)
                                or (wCfg.desc or ""))
    descLabel:SetFont("DermaDefault")
    descLabel:SetTextColor(Color(160, 160, 170))
    descLabel:Wrap()

    -- Prezzo + pulsante compra
    local buyBtn = vgui.Create("DButton", row)
    buyBtn:SetSize(110, 40)
    buyBtn:AlignRight(8)
    buyBtn:CenterVertical()
    buyBtn:SetText("")
    buyBtn.DoClick = function()
        if locked then return end
        net.Start("ZS_PurchaseWeapon")
            net.WriteString(wCfg.class)
        net.SendToServer()
    end
    buyBtn.Paint = function(self, w, h)
        local bg = Color(40, 110, 60, 230)
        if locked then bg = Color(70, 70, 75, 230)
        elseif not affordable then bg = Color(130, 45, 45, 230) end
        draw.RoundedBox(4, 0, 0, w, h, bg)
        if self:IsDown() then
            surface.SetDrawColor(Color(0, 0, 0, 80))
            surface.DrawRect(0, 0, w, h)
        end
        draw.SimpleText(locked and "BLOCCATA" or ZS.FormatMoney(wCfg.price),
            "DermaDefaultBold", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return row
end

local function BuildAmmoRow(listPanel, key, aCfg)
    local affordable = LocalPlayer():GetNWInt(ZS.NW_MONEY, 0) >= aCfg.price

    local row = vgui.Create("DPanel", listPanel)
    row:SetTall(48)
    row:Dock(TOP)
    row:DockMargin(2, 2, 2, 2)
    row.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 31, 36, 230))
    end

    -- icona munizioni: scatolina
    local icon = vgui.Create("DPanel", row)
    icon:SetSize(40, 40)
    icon:SetPos(4, 4)
    icon.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 26, 30, 255))
        surface.SetDrawColor(Color(200, 170, 80))
        surface.DrawRect(w*0.18, h*0.30, w*0.64, h*0.50)  -- scatola
        surface.SetDrawColor(Color(150, 120, 50))
        surface.DrawRect(w*0.18, h*0.30, w*0.64, h*0.10)  -- coperchio
        surface.SetDrawColor(Color(230, 210, 140))
        for i = 0, 3 do
            surface.DrawRect(w*0.26 + i*w*0.13, h*0.48, w*0.06, h*0.22) -- proiettili
        end
    end

    local nameLabel = vgui.Create("DLabel", row)
    nameLabel:SetPos(52, 6)
    nameLabel:SetText(aCfg.name .. "  x" .. aCfg.amount)
    nameLabel:SetFont("DermaDefaultBold")
    nameLabel:SetTextColor(color_white)

    local subLabel = vgui.Create("DLabel", row)
    subLabel:SetPos(52, 26)
    subLabel:SetText("Munizioni — max " .. (aCfg.max or "∞"))
    subLabel:SetFont("DermaDefault")
    subLabel:SetTextColor(Color(160, 160, 170))

    local buyBtn = vgui.Create("DButton", row)
    buyBtn:SetSize(110, 32)
    buyBtn:AlignRight(8)
    buyBtn:CenterVertical()
    buyBtn:SetText("")
    buyBtn.DoClick = function()
        net.Start("ZS_PurchaseAmmo")
            net.WriteString(key)
        net.SendToServer()
    end
    buyBtn.Paint = function(self, w, h)
        local bg = affordable and Color(40, 110, 60, 230) or Color(130, 45, 45, 230)
        draw.RoundedBox(4, 0, 0, w, h, bg)
        draw.SimpleText(ZS.FormatMoney(aCfg.price), "DermaDefaultBold",
            w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ============================================================================
-- RIGA BARRICATA
-- ============================================================================
local function BuildBarricadeRow(listPanel, bCfg)
    local affordable = LocalPlayer():GetNWInt(ZS.NW_MONEY, 0) >= bCfg.price
    local locked = (bCfg.tier or 1) > math.max(1, ZS.CurrentWave or 0)

    local row = vgui.Create("DPanel", listPanel)
    row:SetTall(60)
    row:Dock(TOP)
    row:DockMargin(2, 2, 2, 2)
    row.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 31, 36, 230))
        if self.Hovered then
            surface.SetDrawColor(Color(140, 90, 60, 120))
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    end

    -- Icona procedurale (mattoncino/struttura)
    local icon = vgui.Create("DPanel", row)
    icon:SetSize(52, 52)
    icon:SetPos(4, 4)
    icon.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 26, 30, 255))
        surface.SetDrawColor(Color(160, 120, 80))
        surface.DrawRect(w*0.15, h*0.30, w*0.70, h*0.55)  -- base
        surface.SetDrawColor(Color(120, 90, 60))
        surface.DrawRect(w*0.15, h*0.30, w*0.70, h*0.12)   -- bordo sup
        -- mattoni
        surface.SetDrawColor(Color(180, 140, 100))
        for yy = 0, 2 do
            local y = h*0.42 + yy * h*0.18
            for xx = 0, 3 do
                local x = w*0.2 + xx * w*0.17
                surface.DrawRect(x, y, w*0.14, h*0.12)
            end
        end
    end

    local nameLabel = vgui.Create("DLabel", row)
    nameLabel:SetPos(64, 8)
    nameLabel:SetSize(row:GetWide() - 200, 20)
    nameLabel:SetText(bCfg.name)
    nameLabel:SetFont("DermaDefaultBold")
    nameLabel:SetTextColor(locked and Color(150, 150, 150) or color_white)

    local descLabel = vgui.Create("DLabel", row)
    descLabel:SetPos(64, 30)
    descLabel:SetSize(row:GetWide() - 200, 24)
    descLabel:SetText(locked and ("Si sblocca all'ondata " .. bCfg.tier)
                                or (bCfg.desc or ""))
    descLabel:SetFont("DermaDefault")
    descLabel:SetTextColor(Color(160, 160, 170))
    descLabel:Wrap()

    local buyBtn = vgui.Create("DButton", row)
    buyBtn:SetSize(110, 40)
    buyBtn:AlignRight(8)
    buyBtn:CenterVertical()
    buyBtn:SetText("")
    buyBtn.DoClick = function()
        if locked then return end
        net.Start("ZS_PurchaseBarricade")
            net.WriteString(bCfg.class)
        net.SendToServer()
    end
    buyBtn.Paint = function(self, w, h)
        local bg = Color(140, 90, 40, 230)
        if locked then bg = Color(70, 70, 75, 230)
        elseif not affordable then bg = Color(130, 45, 45, 230) end
        draw.RoundedBox(4, 0, 0, w, h, bg)
        if self:IsDown() then
            surface.SetDrawColor(Color(0, 0, 0, 80))
            surface.DrawRect(0, 0, w, h)
        end
        draw.SimpleText(locked and "BLOCCATA" or ZS.FormatMoney(bCfg.price),
            "DermaDefaultBold", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ============================================================================
-- MODALITÀ POSIZIONAMENTO BARRICATA (ghost preview)
-- ============================================================================
ZS.PlacingBarricade = nil
ZS.GhostEntity = nil

net.Receive("ZS_StartBarricadePlacement", function()
    local class = net.ReadString()
    local name = net.ReadString()
    ZS.PlacingBarricade = class
    ZS.CloseShop()

    -- Crea entità ghost (trasparente, follows mouse)
    local ghost = ClientsideModel("models/props_debris/concrete_chunk05g.mdl", RENDERGROUP_TRANSLUCENT)
    if IsValid(ghost) then
        ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
        ghost:SetColor(Color(100, 200, 120, 180))
        ghost:SetMaterial("models/debug/debugwhite")
        ZS.GhostEntity = ghost
    end
end)

-- Think per aggiornare ghost
hook.Add("Think", "ZS_BarricadeGhost", function()
    if not ZS.PlacingBarricade then return end
    if not IsValid(ZS.GhostEntity) then ZS.CancelPlacement() return end

    local ply = LocalPlayer()
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 120,
        filter = ply,
        mask = MASK_SOLID_BRUSHONLY,
    })

    if tr.Hit then
        ZS.GhostEntity:SetPos(tr.HitPos + tr.HitNormal * 16)
        ZS.GhostEntity:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    else
        ZS.GhostEntity:SetPos(ply:GetPos() + ply:GetForward() * 80)
        ZS.GhostEntity:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    end
end)

-- Input per posizionare/annullare
hook.Add("GUIMousePressed", "ZS_BarricadePlace", function(mcode)
    if not ZS.PlacingBarricade then return end
    if mcode == MOUSE_LEFT then
        -- Piazza
        RunConsoleCommand("zs_placebarricade", ZS.PlacingBarricade)
        ZS.CancelPlacement()
        return true
    elseif mcode == MOUSE_RIGHT then
        -- Annulla
        ZS.CancelPlacement()
        return true
    end
end)

function ZS.CancelPlacement()
    ZS.PlacingBarricade = nil
    if IsValid(ZS.GhostEntity) then
        ZS.GhostEntity:Remove()
        ZS.GhostEntity = nil
    end
end

function ZS.OpenShop()
    if IsValid(ShopFrame) then return end
    ZS.ShopOpen = true

    ShopFrame = vgui.Create("DFrame")
    ShopFrame:SetSize(math.min(920, ScrW() - 100), math.min(640, ScrH() - 100))
    ShopFrame:Center()
    ShopFrame:SetTitle("")
    ShopFrame:MakePopup()
    ShopFrame:SetDeleteOnClose(true)
    ShopFrame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(18, 19, 23, 245))
        surface.SetDrawColor(Color(70, 72, 82, 255))
        surface.DrawOutlinedRect(0, 0, w, h)
        -- header
        surface.SetDrawColor(Color(30, 60, 40, 255))
        surface.DrawRect(0, 0, w, 32)
        draw.SimpleText("ARMERIA", "DermaDefaultBold", 12, 8, Color(140, 255, 160), TEXT_ALIGN_LEFT)
        local moneyTxt = ZS.FormatMoney(LocalPlayer():GetNWInt(ZS.NW_MONEY, 0))
        draw.SimpleText("Saldo: " .. moneyTxt, "DermaDefaultBold", w - 40, 8,
            Color(140, 255, 160), TEXT_ALIGN_RIGHT)
    end

    -- ESC/X chiudono il frame (DFrame CloseOnEsc di default), il toggle
    -- del tasto 4 è gestito in cl_init.lua via polling
    ShopFrame.OnClose = function()
        ZS.CloseShop()
    end

    -- Tabs: una per categoria + Munizioni
    local sheets = vgui.Create("DPropertySheet", ShopFrame)
    sheets:SetPos(8, 40)
    sheets:SetSize(ShopFrame:GetWide() - 16, ShopFrame:GetTall() - 48)

    -- Armi divise per categoria
    local byCat = {}
    for _, wCfg in ipairs(ZS.ShopWeapons or {}) do
        local cat = wCfg.category or "Altro"
        byCat[cat] = byCat[cat] or {}
        table.insert(byCat[cat], wCfg)
    end

    for _, cat in ipairs(ZS.Categories or {}) do
        local items = byCat[cat]
        if items and #items > 0 then
            local scroll = vgui.Create("DScrollPanel")
            scroll:AddItem(vgui.Create("DLabel")):SetText("")
            for _, wCfg in ipairs(items) do
                BuildWeaponRow(scroll, wCfg)
            end
            sheets:AddSheet(cat, scroll, nil, false, false, "Armi: " .. cat)
        end
    end

    -- Tab munizioni
    local ammoScroll = vgui.Create("DScrollPanel")
    for key, aCfg in SortedPairs(ZS.AmmoTypes or {}) do
        BuildAmmoRow(ammoScroll, key, aCfg)
    end
    sheets:AddSheet("Munizioni", ammoScroll, nil, false, false, "Compra munizioni")

    -- Tab barricate
    local barricadeScroll = vgui.Create("DScrollPanel")
    for _, bCfg in ipairs(ZS.Barricades or {}) do
        BuildBarricadeRow(barricadeScroll, bCfg)
    end
    sheets:AddSheet("Barricate", barricadeScroll, nil, false, false, "Compra barricate")
end

function ZS.CloseShop()
    if IsValid(ShopFrame) then
        ShopFrame:Remove()
    end
    ShopFrame = nil
    ZS.ShopOpen = false
end

function ZS.ToggleShop()
    if ZS.ShopOpen then ZS.CloseShop() else ZS.OpenShop() end
end