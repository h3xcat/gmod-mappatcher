surface.CreateFont( "MapPatcherMenuTitle", {
    font    = "Helvetica",
    size    = 20,
    weight  = 1000
} )
surface.CreateFont( "MapPatcherTitle", {
    font    = "Helvetica",
    size    = 50,
    weight  = 1000
} )
surface.CreateFont( "MapPatcherGeneric", {
    font    = "Helvetica",
    size    = 16,
    weight  = 1000
} )
surface.CreateFont( "MapPatcherHelp", {
    font    = "Helvetica",
    size    = 16,
    weight  = 1000
} )
surface.CreateFont( "MapPatcherMenuButton", {
    font    = "Helvetica",
    size    = 24,
    weight  = 1000
} )


--------------------------------------------------------------------------------
local PANEL = {}

function PANEL:Init()
    self:SetSize( 800, 600 )
    self:Center()

    ----------------------------------------------------------------------------
    local title_panel = vgui.Create( "DPanel", self )
    local mappatcher_menu_title = (language.GetPhrase("#mappatcher.menu.title"))
    title_panel:SetSize(self:GetWide(),30)
    title_panel:SetPos(0,0)
    function title_panel:Paint( w, h)
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
        
        surface.SetFont( "MapPatcherMenuTitle" )
        surface.SetTextColor( 255, 255, 255, 255 )
        surface.SetTextPos( 5, 5 )
        surface.DrawText( mappatcher_menu_title..MAPPATCHER_VERSION )
    end
    
    local title_close = vgui.Create( "DButton", title_panel )
    title_close:SetSize(30,30)
    title_close:Dock( RIGHT )
    title_close:SetText("")
    function title_close:Paint( w, h )
        if self:IsDown() then
            surface.SetDrawColor( 180, 180, 180 )
        else
            surface.SetDrawColor( 255, 255, 255 )
        end
        draw.NoTexture()
        surface.DrawTexturedRectRotated( w/2, h/2, 4, h*0.7, 45 )
        surface.DrawTexturedRectRotated( w/2, h/2, 4, h*0.7, -45 )
    end
    function title_close:DoClick()
        self:GetParent():GetParent():GetParent():SetCameraControl(true)
    end

    ----------------------------------------------------------------------------
    local meshes_panel = vgui.Create( "DScrollPanel", self )
    meshes_panel:SetSize( 112, self:GetTall() - (30+5) - 5 )
    meshes_panel:SetPos( 5, 30+5 )
    
    function meshes_panel:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w-15, h )
        --surface.DrawRect( w-10, 0, 10, h )
    end

    local tools_list  = vgui.Create( "DIconLayout", meshes_panel )
    tools_list:SetSize( 87, self:GetParent():GetTall() )
    tools_list:SetPos( 5, 5 )
    tools_list:SetSpaceY( 5 )
    tools_list:SetSpaceX( 5 )

    for k, class_name in pairs(MapPatcher.Editor.Tools) do
        local tool_class = MapPatcher.Tools[class_name]
        if not tool_class then continue end
        local tool_button = tools_list:Add( "DButton" )
        tool_button:SetSize( 87, 43 )
        tool_button:SetText(tool_class.TextureText)
        tool_button:SetTextColor( Color( 255, 255, 255 ) )
        tool_button:SetFont( "MapPatcherHelp" )

        local button_color = table.Copy(tool_class.TextureColor)
        button_color.a = 255
        local button_color_dark = Color(button_color.r*0.7, button_color.g*0.7, button_color.b*0.7, 255 )
        
        function tool_button:Paint( w, h )
            if self:IsDown() then
                surface.SetDrawColor( button_color_dark )
            else
                surface.SetDrawColor( button_color )
            end
            --surface.DrawRect( 0, 0, w, h )
            draw.RoundedBox( 5, 0, 0, w, h, button_color_dark )
            draw.RoundedBox( 5, 2, 2, w-4, h-4, self:IsDown() and button_color_dark or button_color )

            if MapPatcher.Editor.Tool == class_name then
                surface.SetDrawColor( 255, 255, 255 )
                for i=1, 2 do
                    surface.DrawOutlinedRect( (2+i), (2+i), w-(2+i)*2, h-(2+i)*2 )
                end
            end
        end

        function tool_button:DoClick()
            MapPatcher.Editor.SetTool(class_name)
        end
    end

    -- Add padding
    local tool_list_padding = tools_list:Add( "DLabel" )
    tool_list_padding:SetSize(0,0)

    ----------------------------------------------------------------------------

    local preview_panel = vgui.Create( "DPanel", self )
    preview_panel:SetSize(100,100)
    preview_panel:SetPos(117+5,35)

    local preview_material = MapPatcher.GetToolMaterial( "" )
    function preview_panel:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    local info_panel = vgui.Create( "DPanel", self )
    info_panel:SetSize(self:GetWide()-(117+100+5)-10,100)
    info_panel:SetPos(117+100+10,35)
    function info_panel:Paint( w, h)
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    local info_richtext = vgui.Create( "RichText", info_panel )
    info_richtext:Dock( FILL )
    info_richtext:DockMargin( 5, 5, 5, 5 )

    function info_richtext:PerformLayout()
        self:SetFontInternal( "MapPatcherGeneric" )
        self:SetFGColor( Color( 255, 255, 255 ) )
    end

    self.preview_panel = preview_panel
    self.info_richtext = info_richtext

    ----------------------------------------------------------------------------
    local button_panel = vgui.Create( "DPanel", self )
    
    button_panel:SetSize(673,65)
    button_panel:SetPos(117+5,self:GetTall() - 70 )

    function button_panel:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end


    local submit_button = vgui.Create( "DButton", button_panel )
    submit_button:SetPos( 10, 10 )
    submit_button:SetSize( submit_button:GetParent():GetWide()/2-10, submit_button:GetParent():GetTall()-20 )
    submit_button:SetText( "#mappatcher.menu.submit_changes" )
    submit_button:SetTextColor( Color( 255, 255, 255 ) )
    submit_button:SetFont( "MapPatcherMenuButton" )

    local submit_button_color = Color(0,235,0)
    local submit_button_color_down = Color(0,180,0)
    
    function submit_button:Paint(w,h)
        draw.RoundedBox( 5, 0, 0, w, h, submit_button_color_down )
        draw.RoundedBox( 5, 4, 4, w-8, h-8, self:IsDown() and submit_button_color_down or submit_button_color )
    end

    function submit_button:DoClick()
        MapPatcher.Editor.SubmitObject()
    end

    local remove_button = vgui.Create( "DButton", button_panel )
    remove_button:SetPos( remove_button:GetParent():GetWide()/2+10, 10 )
    remove_button:SetSize( remove_button:GetParent():GetWide()/2-20, remove_button:GetParent():GetTall()-20 )
    remove_button:SetText( "#mappatcher.menu.remove_object" )
    remove_button:SetTextColor( Color( 255, 255, 255 ) )
    remove_button:SetFont( "MapPatcherMenuButton" )

    local remove_button_color = Color(235,0,0)
    local remove_button_color_down = Color(180,0,0)

    function remove_button:Paint( w, h )
        draw.RoundedBox( 5, 0, 0, w, h, remove_button_color_down )
        draw.RoundedBox( 5, 4, 4, w-8, h-8, self:IsDown() and remove_button_color_down or remove_button_color )
    end

    function remove_button:DoClick()
        MapPatcher.Editor.RemoveObject()
    end
    ----------------------------------------------------------------------------

    local object_list_scroll = vgui.Create( "DScrollPanel", self )
    object_list_scroll:SetPos(117+5,140 )
    object_list_scroll:SetSize( 200, object_list_scroll:GetParent():GetTall()-215 )
    object_list_scroll:SetPaintBackground( true )
    object_list_scroll:SetBackgroundColor( Color( 0, 0, 0 ) )

    local object_list = vgui.Create( "DListLayout", object_list_scroll )
    object_list:Dock( FILL )

    self.object_list_scroll = object_list_scroll
    self.object_list = object_list
    self.object_buttons = {}
    ----------------------------------------------------------------------------
    local object_panel = vgui.Create( "DPanel", self )
    
    object_panel:SetPos(317+10,140 )
    object_panel:SetSize( 468, object_panel:GetParent():GetTall()-215 )

    function object_panel:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end
    self.object_panel = object_panel
end

function PANEL:UpdateMenu( )
    local Editor = MapPatcher.Editor

    local tool = MapPatcher.Editor.Tool
    local tool_class = MapPatcher.Tools[tool]
    self.info_richtext:SetText(tool_class.Description)
    timer.Simple(0, function() self.info_richtext:GotoTextStart() end)

    function self.preview_panel:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
        
        tool_class:PreviewPaint( self, w, h )
    end

    for k, button in pairs( self.object_buttons ) do
        button:Remove()
    end
    self.object_buttons = {}

    for object_id, object in pairs(MapPatcher.Objects) do
        if object.ClassName ~= tool then continue end
        local button = self.object_list:Add( "DButton" )
        button:SetText( tostring(object) ) 
        function button:Paint( w, h )
            if self:IsDown() then
                surface.SetDrawColor( 130, 130, 130, 255 )
            else
                if object_id == Editor.Object.ID then
                    surface.SetDrawColor( 230, 255, 230, 255 )
                else
                    surface.SetDrawColor( 230, 230, 230, 255 )
                end
            end
            surface.DrawRect( 0, 0, w, h )

            surface.SetDrawColor( 0, 0, 0, 255 )
            surface.DrawOutlinedRect( 0, 0, w, h )
        end

        function button:DoClick()
            MapPatcher.Editor.SelectObject( object, true )
        end
        self.object_buttons[#self.object_buttons + 1] = button
    end
    
    self.object_list:InvalidateLayout(true)
    self.object_list_scroll:InvalidateLayout(true)
    ----------------------------------------------------------------------------
    for k, child in pairs(self.object_panel:GetChildren()) do
        child:Remove()
    end
    Editor.Object:SetupObjectPanel( self.object_panel )
end

function PANEL:SetScreen( screen )
    self.screen = screen
end

function PANEL:OnMousePressed( key_code )
    --self:RequestFocus()
end

function PANEL:Paint( w, h)
    surface.SetDrawColor( 40, 40, 40, 200 )
    surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "MapPatcherEditorMenu", PANEL, "DPanel" )