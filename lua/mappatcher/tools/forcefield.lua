TOOL.Base = "base_brush"
TOOL.Description = "Works similarly to clip brush, but with addition of forcefield effect."
--------------------------------------------------------------------------------
TOOL.TextureColor = Color(100,100,255,200)
TOOL.TextureText = "Force Field"
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST + FSOLID_CUSTOMRAYTEST )

    if CLIENT then
        local origin = self:GetOrigin()
        local min = Vector()
        local max = Vector()

        for k, point in pairs(self.points) do
            local lp = point - origin
            min.x = math.min(min.x, lp.x)
            min.y = math.min(min.y, lp.y)
            min.z = math.min(min.z, lp.z)
            max.x = math.max(max.x, lp.x)
            max.y = math.max(max.y, lp.y)
            max.z = math.max(max.z, lp.z)
        end

        ent:SetRenderBounds( min, max )
        
        ent.snd_forcefield_loop = "mappatcher_forcefield_loop_"..(ent:EntIndex())
        sound.Add( {
            name = "mappatcher_forcefield_loop_"..(ent:EntIndex()),
            channel = CHAN_AUTO,
            volume = 0.5,
            level = 55,
            pitch = 100,
            sound = "ambient/energy/force_field_loop1.wav"
        } )
        ent:EmitSound( ent.snd_forcefield_loop )
    end
end

function TOOL:EntRemove( ent )
    if CLIENT then
        if ent.snd_forcefield_loop then
            ent:StopSound( ent.snd_forcefield_loop )
        end
    end
end

function TOOL:EntStartTouch( ent )
end

function TOOL:EntShouldCollide( ent )
    return true
end

local mat_forcefield = Material("effects/combineshield/comshieldwall2")
function TOOL:EntDraw( ent )
    self:BuildMesh()
    render.SetMaterial( mat_forcefield )

    self.render_mesh:Draw()
    self.render_mesh:Draw()
    self.render_mesh:Draw()
    self.render_mesh:Draw()
    self.render_mesh:Draw()
    self.render_mesh:Draw()
    self.render_mesh:Draw()
    self.render_mesh:Draw()
end

local hit_sounds = {}
for i=1, 4 do
    hit_sounds[#hit_sounds + 1] = Sound("ambient/energy/spark"..i..".wav")
end

function TOOL:EntImpactTrace( ent, trace, dmgtype, customimpactname )
    if IsFirstTimePredicted() then
        EmitSound( hit_sounds[math.random(1,#hit_sounds)], trace.HitPos, ent:EntIndex(), CHAN_AUTO, 1, 80, 0, 100 )
    end

    local effectdata = EffectData()
    effectdata:SetOrigin( trace.HitPos )
    effectdata:SetNormal( trace.HitNormal )
    util.Effect( "AR2Impact", effectdata )
    return true
end
--------------------------------------------------------------------------------
