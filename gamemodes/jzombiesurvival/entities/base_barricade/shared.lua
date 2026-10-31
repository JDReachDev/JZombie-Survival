-- JZombie Survival - entities/entities/base_barricade/shared.lua
-- Base SENT per tutte le barricate

ENT.Type            = "anim"
ENT.Base            = "base_gmodentity"
ENT.PrintName       = "Barricata Base"
ENT.Author          = "JDReach"
ENT.Category        = "Zombie Survival - Barricate"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.Barricade       = true
ENT.BarricadeHealth = 500
ENT.BarricadeOwner  = nil
ENT.BarricadeClass  = "base"

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "BarricadeOwner")
    self:NetworkVar("Int", 0, "BarricadeHealth")
    self:NetworkVar("Int", 0, "BarricadeMaxHealth")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel(self.Model or "models/props_debris/concrete_chunk05g.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
            phys:Wake()
        end

        self:SetBarricadeHealth(self.BarricadeHealth or 500)
        self:SetBarricadeMaxHealth(self.BarricadeHealth or 500)
    end

    function ENT:OnTakeDamage(dmg)
        local hp = self:GetBarricadeHealth()
        hp = hp - dmg:GetDamage()
        self:SetBarricadeHealth(math.max(0, hp))

        -- Effetto visivo danno
        local effect = EffectData()
        effect:SetOrigin(dmg:GetDamagePosition())
        effect:SetNormal(dmg:GetDamageForce():GetNormalized())
        effect:SetMagnitude(1)
        effect:SetScale(1)
        util.Effect("Impact", effect)

        if hp <= 0 then
            self:Break()
        end
    end

    function ENT:Break()
        -- Esplosione pezzi
        local effect = EffectData()
        effect:SetOrigin(self:GetPos())
        effect:SetScale(2)
        util.Effect("GlassImpact", effect)

        self:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 3) .. ".wav", 75, math.random(90, 110))
        self:Remove()
    end

    function ENT:Use(activator, caller, useType, value)
        -- Pickup se il proprietario preme E (opzionale: restituisce metà soldi)
        if IsValid(activator) and activator:IsPlayer() and activator == self:GetBarricadeOwner() then
            if ZS and ZS.FindBarricade then
                local cfg = ZS.FindBarricade(self.BarricadeClass)
                if cfg then
                    local refund = math.floor((cfg.price or 0) * 0.4)
                    if refund > 0 then
                        ZS.AddMoney(activator, refund)
                        net.Start("ZS_Notify")
                            net.WriteString("Barricata recuperata (+" .. ZS.FormatMoney(refund) .. ")")
                            net.WriteString("info")
                        net.Send(activator)
                    end
                end
            end
            self:Remove()
        end
    end
end

if CLIENT then
    local matBeam = Material("cable/redlaser")
    local matGlow = Material("sprites/glow04_noz")

    function ENT:Draw()
        self:DrawModel()

        -- Barba HP sopra la barricata (se guardi)
        local dist = self:GetPos():Distance(EyePos())
        if dist < 200 then
            local ang = (EyePos() - self:GetPos()):Angle()
            ang:RotateAroundAxis(ang:Up(), 90)
            ang:RotateAroundAxis(ang:Forward(), 90)

            local hp = self:GetBarricadeHealth()
            local maxhp = self:GetBarricadeMaxHealth()
            local frac = maxhp > 0 and (hp / maxhp) or 0

            cam.Start3D2D(self:GetPos() + Vector(0, 0, 40), ang, 0.1)
                surface.SetDrawColor(0, 0, 0, 180)
                surface.DrawRect(-50, -8, 100, 16)
                surface.SetDrawColor(200, 50, 50, 220)
                surface.DrawRect(-48, -6, 96 * frac, 12)
                surface.SetDrawColor(100, 200, 100, 220)
                surface.DrawRect(-48, -6, 96 * frac, 12)
                draw.SimpleTextOutlined(hp .. " / " .. maxhp, "Default", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
            cam.End3D2D()
        end
    end

    -- Highlight quando si mira (halo)
    function ENT:DrawTranslucent()
        self:Draw()
    end
end