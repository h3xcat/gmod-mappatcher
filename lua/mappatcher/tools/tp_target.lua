local TOOL = TOOL

TOOL.Base = "base_point"
TOOL.Description = "Teleport target used by teleport brush. You can find more detail by reading description by selecting teleport brush. The teleport target will be oriented to the same direction as editor camera."

--------------------------------------------------------------------------------

TOOL.TextureColor = Color(255,100,0,150)
TOOL.TextureText = "TP Target"

--------------------------------------------------------------------------------

function TOOL:PreviewPaint( panel, w, h )
    local x, y = panel:LocalToScreen( 0, 0 )
    cam.Start3D(Vector(-35,-35,74), Angle(35,45,0), 90, x, y, w, h)
        render.Model( {
            model = "models/editor/playerstart.mdl",
            pos = self.point,
            angle = Angle(0,RealTime()*40,0),
        } )

        render.SetColorMaterial()
        render.DrawBox( Vector(), Angle(0,RealTime()*40,0), Vector(-16.5,-16.5,0), Vector(16.5,16.5,73), self.TextureColor, true )
        render.DrawWireframeBox( Vector(), Angle(0,RealTime()*40,0), Vector(-16.5,-16.5,0), Vector(16.5,16.5,73), Color(255,255,255), true )
    cam.End3D()
end

function TOOL:ObjectCreated()
    self.point = nil
    self.ang = nil
    self.name = ""
end

function TOOL:LeftClick( pos, ang )
    self.point = pos
    self.ang = ang.y
end

function TOOL:EditorRender( selected )
    render.Model( {
        model = "models/editor/playerstart.mdl",
        pos = self.point,
        angle = Angle(0, self.ang, 0),
    } )
    
    render.SetColorMaterial()
    render.DrawBox( self.point, Angle(), Vector(-16.5,-16.5,0), Vector(16.5,16.5,73), self.TextureColor, true )

    if selected then
        render.DrawWireframeBox( self.point, Angle(), Vector(-16.5,-16.5,0), Vector(16.5,16.5,73), Color(255,255,255), false )
    else
        render.DrawWireframeBox( self.point, Angle(), Vector(-16.5,-16.5,0), Vector(16.5,16.5,73), Color(255,255,255,20), false )
    end
end

function TOOL:SetupObjectPanel( panel )
    local DLabel = vgui.Create( "DLabel", panel )
    DLabel:SetTextColor( Color( 255, 255, 255, 255 ) )
    DLabel:SetPos( 10, 10 )
    DLabel:SetText( "Name:" )

    local TextEntry = vgui.Create( "DTextEntry", panel ) -- create the form as a child of frame
    TextEntry:SetPos( 50, 10 )
    TextEntry:SetSize( 100, 20 )
    TextEntry:SetText( self.name )
    TextEntry.OnChange = function( text_entry )
        self.name = text_entry:GetValue()
    end
end

function TOOL:GetOrigin( )
    return self.point
end

function TOOL:IsValid( )
    return self.point ~= nil
end

function TOOL:ToString( )
    if getmetatable(self) == self then
        return "[class] " .. self.ClassName
    end
    return "["..self.ID.."] "..self.ClassName.." \""..self.name.."\""
end

--------------------------------------------------------------------------------
function TOOL:WriteToBuffer( buffer )
    buffer:WriteVector( self.point or Vector() )
    buffer:WriteUInt16( self.ang or 0 )
    buffer:WriteString( self.name )
end

function TOOL:ReadFromBuffer( buffer, len )
    self.point = buffer:ReadVector( )
    self.ang = buffer:ReadUInt16()
    self.name = buffer:ReadString()
end
--------------------------------------------------------------------------------
