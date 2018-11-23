TOOL.Base = "base_brush"
TOOL.Description = "Collides only with players."

--------------------------------------------------------------------------------

TOOL.TextureColor = Color(255,200,0,200)
TOOL.TextureText = "Player Clip"
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST )
end

function TOOL:EntStartTouch( ent )
end

function TOOL:EntShouldCollide( ent )
    return ent:IsPlayer()
end
--------------------------------------------------------------------------------
