local TOOL = TOOL

TOOL.Base = "base_brush"
TOOL.Description = "Brush which teleport players when player touches the brush. Use \"TP Target\" to set destination, the name of the target must match with the name of teleport brush. When multiple targets exist with same name, a random target will be chosen to teleport player to. As of right now, if collisions between players are enabled and multiple players teleports to same spot, the players will get stuck. Thefore, it's better to place multiple teleport targets in mid air."

--------------------------------------------------------------------------------

TOOL.TextureColor = Color(255,100,0,200)
TOOL.TextureText = "Teleport"

--------------------------------------------------------------------------------

function TOOL:WriteToBuffer( buffer )
    TOOL:GetBase().WriteToBuffer( self, buffer )
    buffer:WriteString( self.name )
end

function TOOL:ReadFromBuffer( buffer, len )
    TOOL:GetBase().ReadFromBuffer(self, buffer)
    self.name = buffer:ReadString( )
end

function TOOL:SetupObjectPanel( panel )
    local DLabel = vgui.Create( "DLabel", panel )
    DLabel:SetTextColor( Color( 255, 255, 255, 255 ) )
    DLabel:SetPos( 10, 10 )
    DLabel:SetText( "Name:" )

    local TextEntry = vgui.Create( "DTextEntry", panel ) 
    TextEntry:SetPos( 50, 10 )
    TextEntry:SetSize( 100, 20 )
    TextEntry:SetText( self.name )
    TextEntry.OnChange = function( text_entry )
        self.name = text_entry:GetValue()
    end
end

function TOOL:ToString( )
    if getmetatable(self) == self then
        return "[class] " .. self.ClassName
    end
    return "["..self.ID.."] "..self.ClassName.." \""..self.name.."\""
end

function TOOL:ObjectCreated()
    TOOL:GetBase().ObjectCreated(self)
    self.name = ""
end

--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST )
    if SERVER then ent:SetTrigger( true ) end
end

function TOOL:EntStartTouch( ent )
    if ent:IsPlayer() then
        local destinations = {}
        for object_id, object in pairs(MapPatcher.Objects) do
            if object:IsDerivedFrom("tp_target") and object.name == self.name then
                destinations[#destinations + 1] = object
            end
        end

        if #destinations > 0 then
            local ang_src = ent:EyeAngles()
            local dest = destinations[math.random(1,#destinations)]
            local ang_dest = Angle(ang_src.p, dest.ang, ang_src.r)
            local pos_dest = dest:GetOrigin()

            ent:SetPos( dest:GetOrigin() )
            ent:SetVelocity( -ent:GetVelocity() )
            ent:SetEyeAngles( ang_dest )
        end
    end
end

function TOOL:EntShouldCollide( ent )
    return false
end
--------------------------------------------------------------------------------
