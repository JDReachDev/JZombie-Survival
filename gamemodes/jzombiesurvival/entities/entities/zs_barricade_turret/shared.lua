-- JZombie Survival - entities/entities/zs_barricade_turret/shared.lua
-- Torretta automatica

ENT.Type            = "anim"
ENT.Base            = "base_barricade"
ENT.PrintName       = "Torretta automatica"
ENT.Author          = "JDReach"
ENT.Category        = "Zombie Survival - Barricate"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.Model           = "models/props_lab/turret01.mdl"  -- HL2 turret
ENT.BarricadeClass  = "zs_barricade_turret"
ENT.BarricadeHealth = 600
ENT.TurretAmmo      = 150
ENT.TurretRange     = 1000
ENT.TurretFireRate  = 0.15

if SERVER then
    function ENT:Initialize()
        self.BaseClass.Initialize(self)
        self:SetAngles(Angle(0, self:GetAngles().y, 0))
        self.TurretAmmo = 150
        self.NextFire = 0
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    end

    function ENT:Think()
        if self.TurretAmmo <= 0 then
            self:SetColor(Color(100, 100, 100))
            return
        end

        if CurTime() >= self.NextFire then
            local target = self:FindTarget()
            if IsValid(target) then
                self:FireAt(target)
            end
        end
        self:NextThink(CurTime() + 0.1)
        return true
    end

    function ENT:FindTarget()
        local best = nil
        local bestDist = self.TurretRange
        local pos = self:GetPos() + Vector(0, 0, 40)

        for npc in pairs(ZS.ActiveZombies or {}) do
            if IsValid(npc) then
                local d = pos:Distance(npc:GetPos())
                if d < bestDist then
                    local tr = util.TraceLine({
                        start = pos,
                        endpos = npc:EyePos(),
                        filter = {self, npc},
                        mask = MASK_SHOT,
                    })
                    if not tr.Hit then
                        best = npc
                        bestDist = d
                    end
                end
            end
        end
        return best
    end

    function ENT:FireAt(target)
        if self.TurretAmmo <= 0 then return end
        self.TurretAmmo = self.TurretAmmo - 1
        self.NextFire = CurTime() + self.TurretFireRate

        local pos = self:GetPos() + Vector(0, 0, 45)
        local dir = (target:EyePos() - pos):GetNormalized()

        -- Muzzle flash
        local effect = EffectData()
        effect:SetOrigin(pos)
        effect:SetNormal(dir)
        effect:SetScale(1)
        util.Effect("MuzzleEffect", effect)

        self:EmitSound("npc/turret_floor/shoot" .. math.random(1, 3) .. ".wav", 80, math.random(95, 105))

        -- Bullet
        local bullet = {}
        bullet.Num = 1
        bullet.Src = pos
        bullet.Dir = dir
        bullet.Spread = Vector(0.03, 0.03, 0)
        bullet.Tracer = 1
        bullet.TracerName = "Tracer"
        bullet.Force = 5
        bullet.Damage = 12
        bullet.Attacker = self:GetBarricadeOwner()
        bullet.Callback = function(att, tr, dmg)
            if IsValid(tr.Entity) and tr.Entity:IsNPC() then
                dmg:SetDamageType(DMG_BULLET)
            end
        end
        self:FireBullets(bullet)

        -- Rotazione visuale verso target
        local ang = dir:Angle()
        self:SetAngles(Angle(0, ang.y, 0))
    end

    function ENT:OnTakeDamage(dmg)
        self.BaseClass.OnTakeDamage(self, dmg)
        -- Lampo se colpita
        self:SetColor(Color(255, 100, 100))
        timer.Simple(0.1, function() if IsValid(self) then self:SetColor(color_white) end end)
    end
end