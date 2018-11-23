TOOL.Base = "base_brush"
TOOL.Description = "Does not let the bullets to go pass through."
--------------------------------------------------------------------------------
TOOL.TextureColor = Color(147,112,219,200)
TOOL.TextureText = "Bullet Clip"
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST + FSOLID_CUSTOMRAYTEST )
    ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
end

function TOOL:EntStartTouch( ent )
end

function TOOL:EntShouldCollide( ent )
    return true
end
--------------------------------------------------------------------------------