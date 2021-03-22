--------------------------------------------------------------------------------
local bind2key
do
    local key_names = {}
    for i = KEY_FIRST, KEY_LAST do key_names[input.GetKeyName(i) or "none"] = i end
    local bind_cache = {}
    function bind2key( binding, ignore_cache )
        if bind_cache[binding] and not ignore_cache then
            return bind_cache[binding]
        end

        local key_name = input.LookupBinding( binding, true )
        if key_name then
            bind_cache[binding] = key_names[key_name]
            return key_names[key_name] or KEY_NONE
        end
        return KEY_NONE
    end
end
--------------------------------------------------------------------------------

local PANEL = {}

AccessorFunc( PANEL, "m_ViewPos", "ViewPos" )
AccessorFunc( PANEL, "m_ViewAngles", "ViewAngles" )
AccessorFunc( PANEL, "m_Buttons", "Buttons" )
AccessorFunc( PANEL, "m_PointPos", "PointPos" )
AccessorFunc( PANEL, "m_PointNormal", "PointNormal" )
AccessorFunc( PANEL, "m_PointDist", "PointDist" )
AccessorFunc( PANEL, "m_InMainMenu", "InMainMenu" )

function PANEL:Init()
    self:SetCursor( "crosshair" )
    self:SetSize( ScrW(), ScrH() )
    self:SetPos( 0, 0 )
    --self:ParentToHUD()

    self.m_ViewPos = LocalPlayer():EyePos()
    self.m_ViewAngles = LocalPlayer():EyeAngles()
    self.m_Buttons = {}
    self.m_PointPos = Vector()
    self.m_PointNormal = Vector(0,0,1)
    self.m_PointDist = 300
    self.m_InMainMenu = true

    self.CameraControl = false

    local menu = vgui.Create( "MapPatcherEditorMenu", self )
    menu:SetScreen( self )
    self.menu = menu
end

function PANEL:OnRemove()
    self.menu:Remove()
end

local use_key_name = string.upper( language.GetPhrase(input.GetKeyName(bind2key("+use")) or "") )
local menu_key_name = string.upper( language.GetPhrase(input.GetKeyName(bind2key("+menu")) or "") )
local speed_key_name = string.upper( language.GetPhrase(input.GetKeyName(bind2key("+speed")) or "") )
local scores_key_name = string.upper( language.GetPhrase(input.GetKeyName(bind2key("+showscores")) or "") )
local mappatcher_hud_display_mappatcher_menu = (language.GetPhrase("#mappatcher.hud.display_mappatcher_menu"))
local mappatcher_hud_exit = (language.GetPhrase("#mappatcher.hud.exit"))

function PANEL:Paint( w, h )
    surface.SetDrawColor( 0, 0, 0, 200 )
    surface.DrawRect( 50, 50, 300, 70 )

    surface.SetFont( "MapPatcherTitle" )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.SetTextPos( 83, 60 )
    surface.DrawText( "#mappatcher.hud.title" )

    surface.SetDrawColor( 0, 0, 0, 200 )
    surface.DrawRect( 50, 130, 300, 140 )

    surface.SetFont( "MapPatcherGeneric" )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.SetTextPos( 65, 140 )
    surface.DrawText( "#mappatcher.hud.select_object" )
    surface.SetTextPos( 65, 160 )
    surface.DrawText( "#mappatcher.hud.select_object_help" )
    surface.SetTextPos( 65, 180 )
    surface.DrawText( "#mappatcher.hud.create_point" )
    surface.SetTextPos( 65, 200 )
    surface.DrawText( "["..menu_key_name.."]"..mappatcher_hud_display_mappatcher_menu )
    surface.SetTextPos( 65, 220 )
    surface.DrawText( "#mappatcher.hud.change_point_distance" )
    surface.SetTextPos( 65, 240 )
    surface.DrawText( "["..scores_key_name.."]"..mappatcher_hud_exit )
end

function PANEL:Open( )
    CloseDermaMenus()
    self.m_Buttons = {}
    self:MakePopup()
    self:SetCameraControl( true )
end

function PANEL:Close( )
    self:Hide()
end

function PANEL:UpdateMenu( )
    self.menu:UpdateMenu( )
end

function PANEL:OnMousePressed( key_code )
    if not self.CameraControl then -- Restore control
        self:SetCameraControl( true )
        return 
    end

    if self.m_Buttons[bind2key("+menu")] then return end

    if key_code == MOUSE_LEFT then
        MapPatcher.Editor.LeftClick( self.m_PointPos + self.m_PointNormal*math.random()*0.1, self.m_ViewAngles )
    elseif key_code == MOUSE_RIGHT then
        local tr = util.TraceHull( {
            start = self.m_ViewPos,
            endpos = self.m_ViewPos + self.m_ViewAngles:Forward() * self.m_PointDist,
            filter = {},
            mins = Vector( -0.1, -0.1, -0.1 ),
            maxs = Vector( 0.1, 0.1, 0.1 )
        } )

        MapPatcher.Editor.RightClick( tr )
    end
end

function PANEL:OnMouseWheeled( scroll_delta )
    if not self.CameraControl then return end
    self.m_PointDist = math.Clamp( self.m_PointDist + scroll_delta*10, 10, 500 )
end

function PANEL:OnKeyCodePressed( key_code )
    if vgui.GetKeyboardFocus() ~= self then return end
    self.m_Buttons[key_code] = true

    if key_code == bind2key("+showscores") or key_code == bind2key("+score") then
        MapPatcher.Editor.Stop()
    elseif key_code == KEY_F10 then
        MapPatcher.ReloadEntities()
    elseif key_code == bind2key("+menu") then
        self:SetCameraControl(false)
        --gui.InternalKeyCodePressed( KEY_I )
        --timer.Simple( 0.9, function() gui.InternalKeyCodePressed( bind2key("+menu") ) end)
        --self.menu:RequestFocus()
    end

end

function PANEL:OnKeyCodeReleased( key_code )
    if vgui.GetKeyboardFocus() ~= self then return end
    self.m_Buttons[key_code] = false
    if key_code == bind2key("+menu") then
        self:SetCameraControl(true)
    end
end


function PANEL:OnCursorMoved( cursor_x, cursor_y )
    --if not self:HasFocus() then return end
    if not self.CameraControl then return end

    local cursor_x, cursor_y = gui.MousePos()
    local cursor_pos = Vector( cursor_x, cursor_y )
    local center = Vector( math.floor(ScrW()/2), math.floor(ScrH()/2) )
    local offset = cursor_pos - center

    if offset.x ~= 0 or offset.y ~= 0 then
        local fov = LocalPlayer():GetFOV()
        local delta = offset / 5 * math.rad(fov)

        self.m_ViewAngles.p = math.Clamp( self.m_ViewAngles.p + delta.y, -89.9, 89.9 )
        self.m_ViewAngles.y = self.m_ViewAngles.y - delta.x
        input.SetCursorPos( center.x, center.y )
    end
end

function PANEL:SetCameraControl( enable )
    --print("CameraControl", enable)
    self.CameraControl = enable
    --self.m_Buttons = {}
    if enable then
        RememberCursorPosition()
        input.SetCursorPos( ScrW()/2, ScrH()/2 )
        self.menu:Hide()
    else
        RestoreCursorPosition()
        self.menu:Show()
        --self.menu:RequestFocus()
    end
end

function PANEL:OnFocusChanged( gained )
    if not gained then
        self.m_Buttons = {}
    end
end

function PANEL:Think()
    if gui.IsGameUIVisible() then
        if not self.m_InMainMenu then
            RememberCursorPosition()
            self:SetSize(0,0)
            self:SetInMainMenu( true )
        end
        return
    elseif self.m_InMainMenu then
        RestoreCursorPosition()
        self:SetSize(ScrW(), ScrH())
        self:SetInMainMenu( false )
    end
    
    -- Restore control if focus is on this panel
    local keyboardFocusPanel = vgui.GetKeyboardFocus()
    if self.CameraControl and keyboardFocusPanel ~= self then
    	if IsValid(keyboardFocusPanel) then
        	keyboardFocusPanel:FocusPrevious()
    	    keyboardFocusPanel:KillFocus()
	    end
        self:RequestFocus()
    end

    local speed = 500
    if ( self.m_Buttons[bind2key("+speed")] ) then speed = 1500 end
    if ( self.m_Buttons[bind2key("+duck")] ) then speed = 50 end
    
    local ang = self.m_ViewAngles
    local pos = self.m_ViewPos
    local vel = Vector()


    if ( self.m_Buttons[bind2key("+forward")] ) then
        vel = vel + ang:Forward()
    end
    if ( self.m_Buttons[bind2key("+back")] ) then
        vel = vel - ang:Forward()
    end
    if ( self.m_Buttons[bind2key("+moveright")] ) then
        vel = vel + ang:Right()
    end
    if ( self.m_Buttons[bind2key("+moveleft")] ) then
        vel = vel - ang:Right()
    end
    if ( self.m_Buttons[bind2key("+jump")] ) then 
        vel = vel + Vector( 0, 0, 1 )
    end

    vel = vel:GetNormalized() * speed * FrameTime()
    pos = pos + vel

    self.m_ViewPos = pos

    local tr = util.TraceHull( {
        start = self.m_ViewPos,
        endpos = self.m_ViewPos + self.m_ViewAngles:Forward() * self.m_PointDist,
        mask = CONTENTS_PLAYERCLIP + MASK_SOLID,
        filter = {MapPatcher.Editor.Object.entity},
        mins = Vector( -0.1, -0.1, -0.1 ),
        maxs = Vector( 0.1, 0.1, 0.1 )
    } )
    self.m_PointNormal = tr.HitNormal
    self.m_PointPos = tr.HitPos
end

function PANEL:LookAt( vec )
    self.m_ViewAngles = (vec - self.m_ViewPos):Angle()
    self.m_ViewAngles:Normalize()
    if vec:DistToSqr( self.m_ViewPos ) then
        
    end
    self.m_ViewPos = vec + ((self.m_ViewPos - vec):GetNormalized() * 400)
end

vgui.Register( "MapPatcherEditorScreen", PANEL, "EditablePanel" )

