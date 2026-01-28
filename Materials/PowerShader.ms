/* ================================================================================
   POWER SHADER .NET - USD/OSL EDITION v3.1
   ================================================================================
   CHANGES FROM v3.0:
   - Removed fade animation (instant display)
   - Fixed MaxUsdPreviewSurface instantiation using createInstance
   - Refocused UI on USD and OSL workflows
   ================================================================================
*/

try(if PowerShaderInstance != undefined do (PowerShaderInstance.saveSettings(); PowerShaderInstance.form.Close())) catch()
global PowerShaderInstance

(
    dotNet.loadAssembly "System.Windows.Forms"
    dotNet.loadAssembly "System.Drawing"
    
    struct PowerShaderStruct
    (
        -- ============== FORM & CONTROLS ==============
        form,
        pnlHeader,
        txtSearch,
        tabBar,
        lstResults,
        pnlStatus,
        lblStatus,
        chkApplyToSel,
        pnlPreview,
        picPreview,
        btnCompact,
        
        -- Quick Buttons Row 1 (Shaders - USD focused)
        btnUSD, btnPhys, btnRS, btnPBR, btnGLTF,
        -- Quick Buttons Row 2 (Textures - OSL focused)  
        btnOSL, btnBMP, btnRSTX, btnTY, btnNoise, btnGrad,
        
        -- Tab Buttons
        tabAll, tabMat, tabMap, tabScene, tabFav,
        currentTab = "All",
        
        -- ============== STATE ==============
        isDragging = false,
        allowDrag = true,
        dragStartPos = [0,0],
        dragItem = undefined,
        isCompact = false,
        expandedHeight = 520,
        compactHeight = 180,
        
        -- ============== DATA ==============
        allNames = #(),
        allClasses = #(),
        allCategories = #(),
        currentNames = #(),
        currentClasses = #(),
        favorites = #(),
        recentItems = #(),
        maxRecent = 10,
        
        -- Plugin Availability
        hasRedshift = false,
        hasGLTF = false,
        hasTyFlow = false,
        hasOSL = false,
        hasUSD = false,
        
        -- ============== SETTINGS PATH ==============
        settingsFile = (getDir #userScripts) + "\\PowerShader_settings.ini",
        
        -- ============== UI STYLING ==============
        Color = dotNetClass "System.Drawing.Color",
        Cursors = dotNetClass "System.Windows.Forms.Cursors",
        
        -- Dark theme colors
        cBackground   = (dotNetClass "System.Drawing.Color").FromArgb 22 22 22,
        cPanel        = (dotNetClass "System.Drawing.Color").FromArgb 32 32 32,
        cPanelLight   = (dotNetClass "System.Drawing.Color").FromArgb 45 45 45,
        cPanelHover   = (dotNetClass "System.Drawing.Color").FromArgb 55 55 55,
        cAccent       = (dotNetClass "System.Drawing.Color").FromArgb 0 122 204,
        cAccentHover  = (dotNetClass "System.Drawing.Color").FromArgb 30 144 220,
        cAccentDim    = (dotNetClass "System.Drawing.Color").FromArgb 0 80 140,
        cText         = (dotNetClass "System.Drawing.Color").FromArgb 220 220 220,
        cTextDim      = (dotNetClass "System.Drawing.Color").FromArgb 140 140 140,
        cTextBright   = (dotNetClass "System.Drawing.Color").FromArgb 255 255 255,
        cFavorite     = (dotNetClass "System.Drawing.Color").FromArgb 255 200 50,
        cRecent       = (dotNetClass "System.Drawing.Color").FromArgb 100 200 100,
        cDisabled     = (dotNetClass "System.Drawing.Color").FromArgb 60 60 60,
        cBorder       = (dotNetClass "System.Drawing.Color").FromArgb 50 50 50,
        cUSD          = (dotNetClass "System.Drawing.Color").FromArgb 255 140 50,  -- Orange for USD
        cOSL          = (dotNetClass "System.Drawing.Color").FromArgb 150 100 255, -- Purple for OSL
        
        -- Fonts
        FontSmall  = dotNetObject "System.Drawing.Font" "Segoe UI" 8 (dotNetClass "System.Drawing.FontStyle").Regular,
        FontReg    = dotNetObject "System.Drawing.Font" "Segoe UI" 9 (dotNetClass "System.Drawing.FontStyle").Regular,
        FontMed    = dotNetObject "System.Drawing.Font" "Segoe UI" 10 (dotNetClass "System.Drawing.FontStyle").Regular,
        FontBig    = dotNetObject "System.Drawing.Font" "Segoe UI" 11 (dotNetClass "System.Drawing.FontStyle").Bold,
        FontIcon   = dotNetObject "System.Drawing.Font" "Segoe UI Symbol" 10 (dotNetClass "System.Drawing.FontStyle").Regular,
        
        -- Drawing helpers
        valSelectedState = (dotNetClass "System.Windows.Forms.DrawItemState").Selected.value__,
        StringFormat = dotNetObject "System.Drawing.StringFormat",
        
        -- ============== HELPER FUNCTIONS ==============
        
        fn clamp val minVal maxVal = (amax minVal (amin val maxVal)),
        
        fn sortPairByName a b = (toLower a[1]) < (toLower b[1]),
        
        fn detectPlugins =
        (
            hasRedshift = try(RS_Standard_Material != undefined) catch(false)
            hasGLTF = try(glTFMaterial != undefined) catch(false)
            hasTyFlow = try(tyBitmap != undefined) catch(false)
            hasOSL = try(OSL_uberBitmap2b != undefined) catch(false)
            hasUSD = try(MaxUsdPreviewSurface != undefined) catch(false)
        ),
        
        fn isFavorite className =
        (
            local classStr = className as string
            findItem favorites classStr > 0
        ),
        
        fn toggleFavorite className =
        (
            local classStr = className as string
            local idx = findItem favorites classStr
            if idx > 0 then deleteItem favorites idx
            else append favorites classStr
            PowerShaderInstance.saveSettings()
        ),
        
        fn addToRecent className =
        (
            local classStr = className as string
            local idx = findItem recentItems classStr
            if idx > 0 do deleteItem recentItems idx
            insertItem classStr recentItems 1
            if recentItems.count > maxRecent do recentItems.count = maxRecent
        ),
        
        fn loadSettings =
        (
            favorites = #()
            recentItems = #()
            if doesFileExist settingsFile do
            (
                local f = openFile settingsFile mode:"r"
                if f != undefined do
                (
                    while not eof f do
                    (
                        local line = readLine f
                        if matchPattern line pattern:"FAV:*" do append favorites (substring line 5 -1)
                        if matchPattern line pattern:"REC:*" do append recentItems (substring line 5 -1)
                    )
                    close f
                )
            )
        ),
        
        fn saveSettings =
        (
            local f = createFile settingsFile
            if f != undefined do
            (
                for fav in favorites do format "FAV:%\n" fav to:f
                for rec in recentItems do format "REC:%\n" rec to:f
                close f
            )
        ),
        
        fn setStatus txt col: =
        (
            if col == unsupplied do col = cTextDim
            lblStatus.Text = txt
            lblStatus.ForeColor = col
        ),
        
        fn updatePreview item =
        (
            if pnlPreview == undefined do return()
            
            local showPreview = false
            
            -- Check if it's a bitmap texture with a valid file
            if isKindOf item Bitmaptexture and item.filename != "" do
            (
                if doesFileExist item.filename do
                (
                    try
                    (
                        local bmp = dotNetObject "System.Drawing.Bitmap" item.filename
                        picPreview.Image = bmp
                        showPreview = true
                    )
                    catch()
                )
            )
            
            pnlPreview.Visible = showPreview
        ),
        
        -- ============== MATERIAL OPERATIONS ==============
        
        fn dropMaterialOnViewport mat =
        (
            if mat == undefined do return false
            local ray = mapScreenToWorldRay mouse.pos
            local hits = intersectRayScene ray
            local closestNode = undefined
            local closestDist = 1e9
            
            for h in hits do
            (
                local dist = distance ray.pos h[2].pos 
                if dist < closestDist do
                (
                    closestDist = dist
                    closestNode = h[1]
                )
            )
            
            if closestNode != undefined then
            (
                closestNode.material = mat
                redrawViews()
                return true
            )
            return false
        ),
        
        fn spawnShader matClass applyToSel:false isDrop:false =
        (
            if matClass == undefined do return (messagebox "Class not found." title:"PowerShader")

            local inst = try(matClass()) catch(matClass)
            
            if inst == undefined do
            (
                setStatus "Failed to create instance!" col:cFavorite
                return false
            )
            
            -- Don't rename existing scene materials, only new ones
            if inst != matClass do
            (
                local rndVal = random 1001 9999
                try(inst.name = (classOf inst as string) + "_" + (rndVal as string)) catch()
            )

            -- Track in recents
            addToRecent (if inst == matClass then classOf matClass else matClass)
            
            -- Handle drop to viewport
            if isDrop then
            (
                if dropMaterialOnViewport inst then
                (
                    setStatus ("Applied to object!") col:cRecent
                    try(form.Close())catch()
                    return true
                )
                return false
            )
            
            -- Apply to selection if enabled
            local applyEnabled = try(chkApplyToSel.Checked)catch(false)
            if (applyToSel or applyEnabled) and superClassOf inst == material and selection.count > 0 do
            (
                for obj in selection do obj.material = inst
                redrawViews()
                setStatus ("Applied to " + selection.count as string + " object(s)") col:cRecent
            )
            
            -- Add to Slate or Compact Editor
            if SME.isOpen() then
            (
                local view = SME.getView SME.activeView
                local selNodes = view.GetSelectedNodes()
                local pos = if selNodes.count > 0 then (selNodes[selNodes.count].position + [250, 0]) else [0,0]
                
                local newSmeNode = view.CreateNode inst pos
                
                if newSmeNode != undefined do 
                (
                    view.SelectNone()
                    try(newSmeNode.selected = true) catch()
					try(view.ZoomExtents type:#selected) catch()
                )
            )
            else
            (
                -- Both materials and maps go to active medit slot
                meditMaterials[activeMeditSlot] = inst
            )
            
            try(form.Close())catch()
        ),
        
        -- ============== LIST BUILDING ==============
        
        fn rebuildList =
        (
            local tmp = #()
            
            -- Always add materials and maps
            for c in material.classes do append tmp #("" + (c as string), c, "Mat")
            for c in textureMap.classes do append tmp #("" + (c as string), c, "Map")
            
            -- Scene materials and bitmaps
            for m in sceneMaterials where m != undefined do
            (
                local displayName = if m.name != "" then m.name else (classOf m as string)
                append tmp #(displayName, m, "Scene")
            )
            
            for inst in getClassInstances Bitmaptexture where inst.filename != "" do
            (
                append tmp #(getFilenameFile inst.filename, inst, "Scene")
            )
            
            qsort tmp sortPairByName
            
            allNames = for p in tmp collect p[1]
            allClasses = for p in tmp collect p[2]
            allCategories = for p in tmp collect p[3]
            
            -- Filter by search
            local s = substituteString (toLower txtSearch.Text) " " "*"
            currentNames = #()
            currentClasses = #()
            
            lstResults.BeginUpdate()
            lstResults.Items.Clear()
            
            for i = 1 to allNames.count do
            (
                local matchSearch = matchPattern (toLower allNames[i]) pattern:("*" + s + "*")
                local matchTab = case currentTab of
                (
                    "All": true
                    "Mat": allCategories[i] == "Mat"
                    "Map": allCategories[i] == "Map"
                    "Scene": allCategories[i] == "Scene"
                    "Fav": isFavorite allClasses[i]
                    default: true
                )
                
                if matchSearch and matchTab do
                (
                    append currentNames allNames[i]
                    append currentClasses allClasses[i]
                    
                    -- Build display string with indicators
                    local prefix = ""
                    if isFavorite allClasses[i] do prefix = "★ "
                    if findItem recentItems (allClasses[i] as string) > 0 do prefix = "● "
                    
                    local catTag = case allCategories[i] of
                    (
                        "Mat": " [MAT]"
                        "Map": " [MAP]"
                        "Scene": " [SCENE]"
                        default: ""
                    )
                    
                    lstResults.Items.Add (prefix + allNames[i] + catTag)
                )
            )
            
            lstResults.EndUpdate()
            
            if lstResults.Items.Count > 0 then lstResults.SelectedIndex = 0
            
            setStatus (lstResults.Items.Count as string + " items")
        ),
        
        -- ============== EVENT HANDLERS ==============
        
        fn onBtnDown s e =
        (
            if e.Button == e.Button.Left do
            (
                local psi = PowerShaderInstance
                psi.isDragging = false
                psi.dragStartPos = [e.X, e.Y]
                psi.allowDrag = true
                
                -- Shaders
                if s.Text == "USD"    do psi.dragItem = MaxUsdPreviewSurface
                if s.Text == "PHYS"   do psi.dragItem = PhysicalMaterial
                if s.Text == "RS"     do psi.dragItem = try(RS_Standard_Material)catch(undefined)
                if s.Text == "PBR"    do psi.dragItem = try(OpenPBR_Material)catch(undefined)
                if s.Text == "GLTF"   do psi.dragItem = try(glTFMaterial)catch(undefined)
                
                -- Maps (click only, no drag)
                if s.Text == "OSL"    do (psi.dragItem = try(OSL_uberBitmap2b)catch(undefined); psi.allowDrag = false)
                if s.Text == "BMP"    do (psi.dragItem = Bitmaptexture; psi.allowDrag = false)
                if s.Text == "RS TX"  do (psi.dragItem = try(RS_Texture)catch(undefined); psi.allowDrag = false)
                if s.Text == "TY"     do (psi.dragItem = try(tyBitmap)catch(undefined); psi.allowDrag = false)
                if s.Text == "Noise"  do (psi.dragItem = Noise; psi.allowDrag = false)
                if s.Text == "Grad"   do (psi.dragItem = Gradient_Ramp; psi.allowDrag = false)
            )
        ),
        
        fn onListDown s e =
        (
            local psi = PowerShaderInstance
            
            if e.Button == e.Button.Left do
            (
                psi.isDragging = false
                psi.allowDrag = true
                psi.dragStartPos = [e.X, e.Y]
                
                local idx = s.IndexFromPoint e.Location
                if idx >= 0 then
                (
                    s.SelectedIndex = idx
                    psi.dragItem = psi.currentClasses[idx + 1]
                    psi.updatePreview psi.dragItem
                )
                else psi.dragItem = undefined
            )
            
            -- Right-click to toggle favorite
            if e.Button == e.Button.Right do
            (
                local idx = s.IndexFromPoint e.Location
                if idx >= 0 do
                (
                    s.SelectedIndex = idx
                    local item = psi.currentClasses[idx + 1]
                    psi.toggleFavorite item
                    local isFav = psi.isFavorite item
                    psi.setStatus (if isFav then "Added to favorites ★" else "Removed from favorites") col:(if isFav then psi.cFavorite else psi.cTextDim)
                    psi.rebuildList()
                )
            )
        ),
        
        fn onMouseMove s e =
        (
            local psi = PowerShaderInstance
            
            if e.Button == e.Button.Left and psi.dragItem != undefined and psi.allowDrag do
            (
                local dx = abs(e.X - psi.dragStartPos.x)
                local dy = abs(e.Y - psi.dragStartPos.y)
                
                if dx > 5 or dy > 5 do
                (
                    psi.isDragging = true
                    psi.form.Cursor = psi.Cursors.Hand
                    psi.setStatus "Release over viewport to apply..." col:psi.cAccent
                )
            )
        ),
        
        fn onMouseUp s e =
        (
            local psi = PowerShaderInstance
            psi.form.Cursor = psi.Cursors.Default
            
            if psi.dragItem == undefined do return()
            
            if psi.isDragging then
            (
                if not (s.ClientRectangle.Contains e.Location) then
                    psi.spawnShader psi.dragItem isDrop:true
            )
            else
            (
                if (s != psi.lstResults) and (s.ClientRectangle.Contains e.Location) do
                    psi.spawnShader psi.dragItem
            )
            
            psi.isDragging = false
            psi.dragItem = undefined
            psi.setStatus (psi.lstResults.Items.Count as string + " items")
        ),
        
        fn onSearchKeyDown s e =
        (
            local psi = PowerShaderInstance
            local lst = psi.lstResults
            local Keys = dotNetClass "System.Windows.Forms.Keys"
            
            if e.KeyCode == Keys.Enter do
            (
                if lst.SelectedIndex >= 0 do
                    psi.spawnShader psi.currentClasses[lst.SelectedIndex + 1]
                e.Handled = true
                e.SuppressKeyPress = true
            )
            
            if e.KeyCode == Keys.Down do
            (
                if lst.Items.Count > 0 do
                    lst.SelectedIndex = psi.clamp (lst.SelectedIndex + 1) 0 (lst.Items.Count - 1)
                e.Handled = true
            )
            
            if e.KeyCode == Keys.Up do
            (
                if lst.Items.Count > 0 do
                    lst.SelectedIndex = psi.clamp (lst.SelectedIndex - 1) 0 (lst.Items.Count - 1)
                e.Handled = true
            )
            
            if e.KeyCode == Keys.Tab do
            (
                -- Cycle through tabs
                local tabs = #("All", "Mat", "Map", "Scene", "Fav")
                local idx = findItem tabs psi.currentTab
                idx = mod idx tabs.count + 1
                psi.currentTab = tabs[idx]
                psi.updateTabVisuals()
                psi.rebuildList()
                e.Handled = true
                e.SuppressKeyPress = true
            )
        ),
        
        fn onTabClick s e =
        (
            local psi = PowerShaderInstance
            psi.currentTab = s.Tag
            psi.updateTabVisuals()
            psi.rebuildList()
        ),
        
        fn updateTabVisuals =
        (
            local tabs = #(tabAll, tabMat, tabMap, tabScene, tabFav)
            local names = #("All", "Mat", "Map", "Scene", "Fav")
            
            for i = 1 to tabs.count do
            (
                if names[i] == currentTab then
                (
                    tabs[i].BackColor = cAccent
                    tabs[i].ForeColor = cTextBright
                )
                else
                (
                    tabs[i].BackColor = cPanel
                    tabs[i].ForeColor = cTextDim
                )
            )
        ),
        
        fn toggleCompact =
        (
            isCompact = not isCompact
            
            if isCompact then
            (
                form.Height = compactHeight
                lstResults.Visible = false
                pnlStatus.Visible = false
                tabBar.Visible = false
                chkApplyToSel.Visible = false
                btnCompact.Text = "▼"
            )
            else
            (
                form.Height = expandedHeight
                lstResults.Visible = true
                pnlStatus.Visible = true
                tabBar.Visible = true
                chkApplyToSel.Visible = true
                btnCompact.Text = "▲"
            )
        ),
        
        -- ============== CUSTOM DRAWING ==============
        
        fn onDrawItem s e =
        (
            if e.Index < 0 do return()
            
            local psi = PowerShaderInstance
            local g = e.Graphics
            g.TextRenderingHint = g.TextRenderingHint.ClearTypeGridFit
            
            local stateInt = e.State.value__
            local isSelected = (bit.and stateInt psi.valSelectedState) == psi.valSelectedState
            
            -- Background
            local bgColor = if isSelected then psi.cAccent else psi.cBackground
            local bgBrush = dotNetObject "System.Drawing.SolidBrush" bgColor
            g.FillRectangle bgBrush e.Bounds
            
            local txt = s.Items.Item[e.Index]
            
            -- Determine text color based on content
            local textColor = if isSelected then psi.cTextBright else psi.cText
            if not isSelected do
            (
                if matchPattern txt pattern:"★*" do textColor = psi.cFavorite
                if matchPattern txt pattern:"●*" do textColor = psi.cRecent
                -- Highlight USD and OSL items
                if matchPattern txt pattern:"*USD*" or matchPattern txt pattern:"*Usd*" do textColor = psi.cUSD
                if matchPattern txt pattern:"*OSL*" do textColor = psi.cOSL
            )
            
            local textBrush = dotNetObject "System.Drawing.SolidBrush" textColor
            
            local textRect = dotNetObject "System.Drawing.RectangleF" \
                (e.Bounds.X + 8) (e.Bounds.Y + 3) (e.Bounds.Width - 16) e.Bounds.Height
            
            g.DrawString txt psi.FontReg textBrush textRect
            
            -- Draw subtle separator
            if not isSelected do
            (
                local penColor = psi.cBorder
                local pen = dotNetObject "System.Drawing.Pen" penColor 1
                g.DrawLine pen e.Bounds.Left (e.Bounds.Bottom - 1) e.Bounds.Right (e.Bounds.Bottom - 1)
                pen.Dispose()
            )
            
            bgBrush.Dispose()
            textBrush.Dispose()
        ),
        
        -- ============== BUTTON STYLING ==============
        
        fn styleButton btn tooltip:"" enabled:true highlight:false =
        (
            local psi = PowerShaderInstance
            
            btn.FlatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").Flat
            btn.FlatAppearance.BorderSize = 1
            btn.FlatAppearance.BorderColor = psi.cBorder
            btn.Font = psi.FontReg
            btn.Cursor = psi.Cursors.Hand
            
            if enabled then
            (
                if highlight then
                (
                    -- Special highlight for USD/OSL buttons
                    btn.BackColor = psi.cPanelHover
                    btn.ForeColor = psi.cTextBright
                    btn.FlatAppearance.BorderColor = if btn.Text == "USD" then psi.cUSD else psi.cOSL
                )
                else
                (
                    btn.BackColor = psi.cPanelLight
                    btn.ForeColor = psi.cText
                )
                btn.Enabled = true
            )
            else
            (
                btn.BackColor = psi.cDisabled
                btn.ForeColor = psi.cTextDim
                btn.Enabled = false
            )
            
            -- Tooltip
            if tooltip != "" do
            (
                local tt = dotNetObject "System.Windows.Forms.ToolTip"
                tt.SetToolTip btn tooltip
            )
            
            -- Hover effects
            dotNet.addEventHandler btn "MouseEnter" (fn onEnter s e = (
                if s.Enabled do (
                    s.BackColor = PowerShaderInstance.cAccent
                    s.ForeColor = PowerShaderInstance.cTextBright
                    PowerShaderInstance.setStatus s.Tag col:PowerShaderInstance.cAccent
                )
            ))
            dotNet.addEventHandler btn "MouseLeave" (fn onLeave s e = (
                if s.Enabled do (
                    local isHighlight = (s.Text == "USD" or s.Text == "OSL")
                    s.BackColor = if isHighlight then PowerShaderInstance.cPanelHover else PowerShaderInstance.cPanelLight
                    s.ForeColor = if isHighlight then PowerShaderInstance.cTextBright else PowerShaderInstance.cText
                    PowerShaderInstance.setStatus (PowerShaderInstance.lstResults.Items.Count as string + " items")
                )
            ))
            
            dotNet.addEventHandler btn "MouseDown" onBtnDown
            dotNet.addEventHandler btn "MouseMove" onMouseMove
            dotNet.addEventHandler btn "MouseUp" onMouseUp
        ),
        
        fn styleTabButton btn =
        (
            local psi = PowerShaderInstance
            
            btn.FlatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").Flat
            btn.FlatAppearance.BorderSize = 0
            btn.BackColor = psi.cPanel
            btn.ForeColor = psi.cTextDim
            btn.Font = psi.FontSmall
            btn.Cursor = psi.Cursors.Hand
            
            dotNet.addEventHandler btn "Click" onTabClick
            dotNet.addEventHandler btn "MouseEnter" (fn onEnter s e = (
                if s.BackColor.ToArgb() != PowerShaderInstance.cAccent.ToArgb() do
                    s.BackColor = PowerShaderInstance.cPanelHover
            ))
            dotNet.addEventHandler btn "MouseLeave" (fn onLeave s e = (
                if s.Tag != PowerShaderInstance.currentTab do
                    s.BackColor = PowerShaderInstance.cPanel
            ))
        ),
        
        -- ============== MAIN UI INIT ==============
        
        fn initUI =
        (
            -- Detect available plugins
            detectPlugins()
            
            -- Load settings
            loadSettings()
            
            -- Create Form - NO FADE, instant display
            form = dotNetObject "MaxCustomControls.MaxForm"
            form.Text = "⚡ PowerShader USD/OSL"
            form.Size = dotNetObject "System.Drawing.Size" 360 expandedHeight
            form.FormBorderStyle = (dotNetClass "System.Windows.Forms.FormBorderStyle").FixedToolWindow
            form.StartPosition = (dotNetClass "System.Windows.Forms.FormStartPosition").Manual
            form.Location = dotNetObject "System.Drawing.Point" (mouse.screenpos.x - 180) (mouse.screenpos.y - 30)
            form.BackColor = cBackground
            form.KeyPreview = true
            form.Opacity = 0.95  -- Instant opacity, no fade
            
            local yPos = 8
            
            -- ============== HEADER PANEL ==============
            pnlHeader = dotNetObject "System.Windows.Forms.Panel"
            pnlHeader.Location = dotNetObject "System.Drawing.Point" 8 yPos
            pnlHeader.Size = dotNetObject "System.Drawing.Size" 328 36
            pnlHeader.BackColor = cPanel
            
            -- Search Box
            txtSearch = dotNetObject "System.Windows.Forms.TextBox"
            txtSearch.Location = dotNetObject "System.Drawing.Point" 8 6
            txtSearch.Size = dotNetObject "System.Drawing.Size" 276 24
            txtSearch.Font = FontBig
            txtSearch.BackColor = cPanel
            txtSearch.ForeColor = cTextBright
            txtSearch.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
            pnlHeader.Controls.Add txtSearch
            
            -- Compact Toggle Button
            btnCompact = dotNetObject "System.Windows.Forms.Button"
            btnCompact.Text = "▲"
            btnCompact.Location = dotNetObject "System.Drawing.Point" 292 4
            btnCompact.Size = dotNetObject "System.Drawing.Size" 28 28
            btnCompact.FlatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").Flat
            btnCompact.FlatAppearance.BorderSize = 0
            btnCompact.BackColor = cPanel
            btnCompact.ForeColor = cTextDim
            btnCompact.Font = FontSmall
            btnCompact.Cursor = Cursors.Hand
            dotNet.addEventHandler btnCompact "Click" (fn onClick s e = PowerShaderInstance.toggleCompact())
            pnlHeader.Controls.Add btnCompact
            
            yPos += 44
            
            -- ============== QUICK BUTTONS ROW 1 (SHADERS - USD First) ==============
            local btnW = 50
            local btnH = 26
            local gap = 4
            local xPos = 8
            
            -- USD button first and highlighted
            btnUSD = dotNetObject "System.Windows.Forms.Button"
            btnUSD.Text = "USD"
            btnUSD.Tag = "USD Preview Surface - Universal shader (RECOMMENDED)"
            btnUSD.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnUSD.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnUSD tooltip:"USD Preview Surface (Drag to viewport)" enabled:hasUSD highlight:true
            xPos += btnW + gap
            
            btnPhys = dotNetObject "System.Windows.Forms.Button"
            btnPhys.Text = "PHYS"
            btnPhys.Tag = "Physical Material - Autodesk standard PBR"
            btnPhys.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnPhys.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnPhys tooltip:"Physical Material (Drag to viewport)" enabled:true
            xPos += btnW + gap
            
            btnRS = dotNetObject "System.Windows.Forms.Button"
            btnRS.Text = "RS"
            btnRS.Tag = "Redshift Standard Material"
            btnRS.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnRS.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnRS tooltip:"Redshift Standard Material (Drag to viewport)" enabled:hasRedshift
            xPos += btnW + gap
            
            btnPBR = dotNetObject "System.Windows.Forms.Button"
            btnPBR.Text = "PBR"
            btnPBR.Tag = "OpenPBR Material"
            btnPBR.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnPBR.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnPBR tooltip:"OpenPBR Material (Drag to viewport)" enabled:true
            xPos += btnW + gap

            btnGLTF = dotNetObject "System.Windows.Forms.Button"
            btnGLTF.Text = "GLTF"
            btnGLTF.Tag = "glTF Material"
            btnGLTF.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnGLTF.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnGLTF tooltip:"glTF Material (Drag to viewport)" enabled:hasGLTF
            
            yPos += btnH + gap
            xPos = 8
            
            -- ============== QUICK BUTTONS ROW 2 (MAPS - OSL First) ==============
            -- OSL button first and highlighted
            btnOSL = dotNetObject "System.Windows.Forms.Button"
            btnOSL.Text = "OSL"
            btnOSL.Tag = "OSL UberBitmap - Best for USD workflows (RECOMMENDED)"
            btnOSL.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnOSL.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnOSL tooltip:"OSL UberBitmap (Click to create)" enabled:hasOSL highlight:true
            xPos += btnW + gap
            
            btnBMP = dotNetObject "System.Windows.Forms.Button"
            btnBMP.Text = "BMP"
            btnBMP.Tag = "Bitmap Texture - Click to create"
            btnBMP.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnBMP.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnBMP tooltip:"Bitmap Texture (Click to create)" enabled:true
            xPos += btnW + gap
            
            btnRSTX = dotNetObject "System.Windows.Forms.Button"
            btnRSTX.Text = "RS TX"
            btnRSTX.Tag = "Redshift Texture - Click to create"
            btnRSTX.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnRSTX.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnRSTX tooltip:"Redshift Texture (Click to create)" enabled:hasRedshift
            xPos += btnW + gap
            
            btnTY = dotNetObject "System.Windows.Forms.Button"
            btnTY.Text = "TY"
            btnTY.Tag = "tyBitmap - Click to create"
            btnTY.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnTY.Size = dotNetObject "System.Drawing.Size" btnW btnH
            styleButton btnTY tooltip:"tyBitmap (Click to create)" enabled:hasTyFlow
            xPos += btnW + gap
            
            btnNoise = dotNetObject "System.Windows.Forms.Button"
            btnNoise.Text = "Noise"
            btnNoise.Tag = "Noise Map - Click to create"
            btnNoise.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnNoise.Size = dotNetObject "System.Drawing.Size" 58 btnH
            styleButton btnNoise tooltip:"Noise Map (Click to create)" enabled:true
            xPos += 58 + gap
            
            btnGrad = dotNetObject "System.Windows.Forms.Button"
            btnGrad.Text = "Grad"
            btnGrad.Tag = "Gradient Ramp - Click to create"
            btnGrad.Location = dotNetObject "System.Drawing.Point" xPos yPos
            btnGrad.Size = dotNetObject "System.Drawing.Size" 50 btnH
            styleButton btnGrad tooltip:"Gradient Ramp (Click to create)" enabled:true
            
            yPos += btnH + 8
            
            -- ============== TAB BAR ==============
            tabBar = dotNetObject "System.Windows.Forms.Panel"
            tabBar.Location = dotNetObject "System.Drawing.Point" 8 yPos
            tabBar.Size = dotNetObject "System.Drawing.Size" 328 24
            tabBar.BackColor = cPanel
            
            local tabW = 65
            local tabX = 0
            
            tabAll = dotNetObject "System.Windows.Forms.Button"
            tabAll.Text = "All"
            tabAll.Tag = "All"
            tabAll.Location = dotNetObject "System.Drawing.Point" tabX 0
            tabAll.Size = dotNetObject "System.Drawing.Size" tabW 24
            styleTabButton tabAll
            tabBar.Controls.Add tabAll
            tabX += tabW
            
            tabMat = dotNetObject "System.Windows.Forms.Button"
            tabMat.Text = "Materials"
            tabMat.Tag = "Mat"
            tabMat.Location = dotNetObject "System.Drawing.Point" tabX 0
            tabMat.Size = dotNetObject "System.Drawing.Size" tabW 24
            styleTabButton tabMat
            tabBar.Controls.Add tabMat
            tabX += tabW
            
            tabMap = dotNetObject "System.Windows.Forms.Button"
            tabMap.Text = "Maps"
            tabMap.Tag = "Map"
            tabMap.Location = dotNetObject "System.Drawing.Point" tabX 0
            tabMap.Size = dotNetObject "System.Drawing.Size" tabW 24
            styleTabButton tabMap
            tabBar.Controls.Add tabMap
            tabX += tabW
            
            tabScene = dotNetObject "System.Windows.Forms.Button"
            tabScene.Text = "Scene"
            tabScene.Tag = "Scene"
            tabScene.Location = dotNetObject "System.Drawing.Point" tabX 0
            tabScene.Size = dotNetObject "System.Drawing.Size" tabW 24
            styleTabButton tabScene
            tabBar.Controls.Add tabScene
            tabX += tabW
            
            tabFav = dotNetObject "System.Windows.Forms.Button"
            tabFav.Text = "★ Favs"
            tabFav.Tag = "Fav"
            tabFav.Location = dotNetObject "System.Drawing.Point" tabX 0
            tabFav.Size = dotNetObject "System.Drawing.Size" tabW 24
            styleTabButton tabFav
            tabBar.Controls.Add tabFav
            
            yPos += 32
            
            -- ============== APPLY TO SELECTION CHECKBOX ==============
            chkApplyToSel = dotNetObject "System.Windows.Forms.CheckBox"
            chkApplyToSel.Text = "Apply to Selection"
            chkApplyToSel.Location = dotNetObject "System.Drawing.Point" 12 yPos
            chkApplyToSel.Size = dotNetObject "System.Drawing.Size" 150 20
            chkApplyToSel.ForeColor = cTextDim
            chkApplyToSel.Font = FontSmall
            chkApplyToSel.FlatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").Flat
            
            yPos += 26
            
            -- ============== RESULTS LIST ==============
            lstResults = dotNetObject "System.Windows.Forms.ListBox"
            lstResults.Location = dotNetObject "System.Drawing.Point" 8 yPos
            lstResults.Size = dotNetObject "System.Drawing.Size" 328 240
            lstResults.BackColor = cBackground
            lstResults.ForeColor = cText
            lstResults.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
            lstResults.DrawMode = (dotNetClass "System.Windows.Forms.DrawMode").OwnerDrawFixed
            lstResults.ItemHeight = 26
            lstResults.IntegralHeight = false
            
            yPos += 248
            
            -- ============== PREVIEW PANEL (for bitmaps) ==============
            pnlPreview = dotNetObject "System.Windows.Forms.Panel"
            pnlPreview.Location = dotNetObject "System.Drawing.Point" 240 160
            pnlPreview.Size = dotNetObject "System.Drawing.Size" 96 96
            pnlPreview.BackColor = cPanel
            pnlPreview.Visible = false
            
            picPreview = dotNetObject "System.Windows.Forms.PictureBox"
            picPreview.Dock = (dotNetClass "System.Windows.Forms.DockStyle").Fill
            picPreview.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").Zoom
            pnlPreview.Controls.Add picPreview
            
            -- ============== STATUS BAR ==============
            pnlStatus = dotNetObject "System.Windows.Forms.Panel"
            pnlStatus.Location = dotNetObject "System.Drawing.Point" 8 yPos
            pnlStatus.Size = dotNetObject "System.Drawing.Size" 328 24
            pnlStatus.BackColor = cPanel
            
            lblStatus = dotNetObject "System.Windows.Forms.Label"
            lblStatus.Text = "Ready"
            lblStatus.Dock = (dotNetClass "System.Windows.Forms.DockStyle").Fill
            lblStatus.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleLeft
            lblStatus.ForeColor = cTextDim
            lblStatus.Font = FontSmall
            lblStatus.Padding = dotNetObject "System.Windows.Forms.Padding" 6 0 0 0
            pnlStatus.Controls.Add lblStatus
            
            -- ============== ADD ALL CONTROLS ==============
            form.Controls.AddRange #(
                pnlHeader,
                btnUSD, btnPhys, btnRS, btnPBR, btnGLTF,
                btnOSL, btnBMP, btnRSTX, btnTY, btnNoise, btnGrad,
                tabBar,
                chkApplyToSel,
                lstResults,
                pnlPreview,
                pnlStatus
            )
            
            -- ============== EVENT HANDLERS ==============
            dotNet.addEventHandler form "Load" (fn onFormLoad s e = (
                s.ActiveControl = PowerShaderInstance.txtSearch
                -- NO fadeIn() call - instant display
            ))
            
            dotNet.addEventHandler form "KeyUp" (fn onKey s e = (
                if e.KeyCode == e.KeyCode.Escape do s.Close()
            ))
            
            dotNet.addEventHandler form "Deactivate" (fn onDeactivate s e = (
                if not PowerShaderInstance.isDragging do s.Close()
            ))
            
            dotNet.addEventHandler form "FormClosing" (fn onClose s e = (
                PowerShaderInstance.saveSettings()
            ))
            
            dotNet.addEventHandler txtSearch "TextChanged" (fn onTxtChange s e = (
                PowerShaderInstance.rebuildList()
            ))
            
            dotNet.addEventHandler txtSearch "KeyDown" onSearchKeyDown
            
            dotNet.addEventHandler lstResults "DrawItem" onDrawItem
            dotNet.addEventHandler lstResults "MouseDown" onListDown
            dotNet.addEventHandler lstResults "MouseMove" onMouseMove
            dotNet.addEventHandler lstResults "MouseUp" onMouseUp
            
            dotNet.addEventHandler lstResults "DoubleClick" (fn onDbl s e = (
                local psi = PowerShaderInstance
                if psi.lstResults.SelectedIndex >= 0 do
                    psi.spawnShader psi.currentClasses[psi.lstResults.SelectedIndex + 1]
            ))
            
            dotNet.addEventHandler lstResults "SelectedIndexChanged" (fn onSelChange s e = (
                local psi = PowerShaderInstance
                if psi.lstResults.SelectedIndex >= 0 do
                    psi.updatePreview psi.currentClasses[psi.lstResults.SelectedIndex + 1]
            ))
            
            -- Initialize
            updateTabVisuals()
            rebuildList()
            form.ShowModeless()
        )
    )
    
    -- Create and initialize
    PowerShaderInstance = PowerShaderStruct()
    PowerShaderInstance.initUI()
)
