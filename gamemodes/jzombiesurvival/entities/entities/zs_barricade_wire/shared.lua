-- JZombie Survival - entities/entities/zs_barricade_wire/shared.lua
-- Filo spinato - danneggia e rallenta zombie

ENT.Type            = "anim"
ENT.Base            = "base_barricade"
ENT.PrintName       = "Filo spinato"
ENT.Author          = "JDReach"
ENT.Category        = "Zombie Survival - Barricate"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.Model           = "models/props_wasteland/barricade001a.mdl"
ENT.BarricadeClass  = "zs_barricade_wire"
ENT.BarricadeHealth = 400

if SERVER then
    function ENT:Initialize()
        self.BaseClass.Initialize(self)
        -- Trigger volume per danneggiare zombie
        self:SetTrigger(true)
        self:UseTriggerBounds(true, 16)
    end

    function ENT:Touch(ent)
        if not IsValid(ent) then return end
        if ent:IsNPC() and ZS.ActiveZombies and ZS.ActiveZombies[ent] then
            local dmg = DamageInfo()
            dmg:SetDamage(8)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(self)
            dmg:SetInflictor(self)
            dmg:SetDamagePosition(ent:GetPos())
            ent:TakeDamageInfo(dmg)

            -- Rallenta
            if ent.SetSpeedMult then
                ent:SetSpeedMult(math.max(0.3, (ent:GetSpeedMult() or 1) * 0.7))
            end
        end
    end
end