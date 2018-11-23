TOOL.Base = "base_brush"
TOOL.Description = "Doesn't let entities pass through that has prop physics (e.g. props, grenades, etc)."

--------------------------------------------------------------------------------

TOOL.TextureColor = Color(139,69,19,200)
TOOL.TextureText = "Prop Clip"
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST )
end

function TOOL:EntStartTouch( ent )
end

function TOOL:EntShouldCollide( ent )
    return ent:GetMoveType() == MOVETYPE_VPHYSICS
end
--------------------------------------------------------------------------------
