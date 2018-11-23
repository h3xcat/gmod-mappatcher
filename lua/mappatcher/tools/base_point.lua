TOOL.Base = "base"
--------------------------------------------------------------------------------
function TOOL:ShouldSave( )
    if self:IsObject() and self.point and self.point ~= Vector() then
        return true
    end
    return false
end
--------------------------------------------------------------------------------
function TOOL:ObjectCreated()
    self.point = nil
end

function TOOL:LeftClick( pos )
    self.point = pos
end
--------------------------------------------------------------------------------
function TOOL:WriteToBuffer( buffer )
    buffer:WriteVector( self.point or Vector() )
end

function TOOL:ReadFromBuffer( buffer, len )
    self.point = buffer:ReadVector( )
end
--------------------------------------------------------------------------------
