TOOL.Base = "base_brush"
TOOL.Description = "Removes any entities that touches this brush. Except for players, in which they would just silently die."
--------------------------------------------------------------------------------
TOOL.TextureColor = Color(255,0,0,200)
TOOL.TextureText = "Remove"
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST )
    if SERVER then ent:SetTrigger( true ) end
end

function TOOL:EntStartTouch( ent )
    if ent.MapPatcherObject then return end
    
    if ent:IsPlayer() then
        ent:KillSilent()
    else
        ent:Remove()
    end
end

function TOOL:EntShouldCollide( ent )
    return false
end
--------------------------------------------------------------------------------
