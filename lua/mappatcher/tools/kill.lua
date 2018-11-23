TOOL.Base = "base_brush"
TOOL.Description = "Kill players on touch."
--------------------------------------------------------------------------------
TOOL.TextureColor = Color(255,0,0,200)
TOOL.TextureText = "Kill"
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST )
    if SERVER then ent:SetTrigger( true ) end
end

function TOOL:EntStartTouch( ent )
    if ent:IsPlayer() then
        ent:Kill()
        return
    end
end

function TOOL:EntShouldCollide( ent )
    return false
end
--------------------------------------------------------------------------------
