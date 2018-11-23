TOOL.Base = "base_brush"
TOOL.Description = "Collides with everything."
--------------------------------------------------------------------------------
TOOL.TextureColor = Color(100,100,100,200)
TOOL.TextureText = "Clip"
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST + FSOLID_CUSTOMRAYTEST )
end

function TOOL:EntStartTouch( ent )
end

function TOOL:EntShouldCollide( ent )
    return true
end
--------------------------------------------------------------------------------
