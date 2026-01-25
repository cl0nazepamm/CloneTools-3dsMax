-- This maxscript processes SVG logo files by converting them to high-DPI PNGs,
-- applying alpha bleed, and assigning them as textures to 3D models in the scene.

-- Unified Input Rollout (modal dialog for DPI and mode)
rollout processorRollout "SVG Logo Pipeline" width:220 height:140 (
    label lbl_dpi "DPI for Rasterization (100-2000):"
    spinner spn_dpi "DPI:" range:[100,2000,600] type:#integer scale:50 align:#left
    
    group "Processing Mode" (
        radiobuttons rdo_mode "" labels:#("Single File", "Batch Folder") default:1 columns:1
    )
    
    button btn_process "Process SVGs" pos:[20,110] width:90 height:25
    button btn_cancel "Cancel" pos:[120,110] width:90 height:25
    
    local dpiValue = 600
    local modeValue = 1  -- 1=single, 2=batch
    
    on processorRollout open do (
        spn_dpi.value = 600
        rdo_mode.state = 1
    )
    
    on spn_dpi changed val do dpiValue = val
    
    on rdo_mode changed state do modeValue = state
    
    on btn_process pressed do (
        dpiValue = spn_dpi.value
        destroyDialog processorRollout
        if modeValue == 1 then singleSvgToTexture dpiValue else batchSvgToTexture dpiValue
    )
    
    on btn_cancel pressed do (
        destroyDialog processorRollout
    )
)

fn singleSvgToTexture dpiValue = (
    local svgPath = getOpenFileName caption:"Select Single SVG File:" types:"SVG (*.svg)|*.svg|" 
    if svgPath != undefined do (
        print ("Processing single: " + (getFilenameFile svgPath) + " at " + dpiValue as string + " DPI")
        
        -- Import the SVG first
        local importSuccess = importFile svgPath #noPrompt
        if not importSuccess do (
            messageBox ("Failed to import: " + svgPath)
            return undefined
        )
        
        local baseName = getFilenameFile svgPath
        local dir = getFilenamePath svgPath
        local pngPath = dir + baseName + ".png"
        local bleedPng = dir + baseName + "_bleed.png"
        
        -- Fix paths: Replace \ with / for DOS compatibility (double \\ for literal backslash)
        local svgPathFixed = substituteString svgPath "\\" "/"
        local pngPathFixed = substituteString pngPath "\\" "/"
        local bleedPngFixed = substituteString bleedPng "\\" "/"
        
        print ("Fixed paths - SVG: " + svgPathFixed + " PNG: " + pngPathFixed + " Bleed: " + bleedPngFixed)  -- Debug: Verify in listener
        
        -- Convert SVG to high-DPI PNG with ImageMagick (transparent bg, non-blocking)
        local magickCmd = "magick convert -density " + dpiValue as string + " -background none \"" + svgPathFixed + "\" \"" + pngPathFixed + "\""
        print ("Running: " + magickCmd)
        HiddenDOSCommand magickCmd donotwait:true
        sleep 1.0  -- Pause for stability
        if not (doesFileExist pngPath) do (
            messageBox ("Magick failed for " + baseName + ". Cmd: " + magickCmd)
            return undefined
        )
        
        -- Run alpha-bleed.exe
        local bleedCmd = "alpha-bleed.exe \"" + pngPathFixed + "\" \"" + bleedPngFixed + "\""
        print ("Running: " + bleedCmd)
        HiddenDOSCommand bleedCmd donotwait:true
        sleep 1.0
        if not (doesFileExist bleedPng) do (
            messageBox ("Bleed failed for " + baseName + ". Cmd: " + bleedCmd)
            return undefined
        )
        
        -- Find the imported model with SVG import suffix
        local modelName = baseName + ".svg_FillEditPoly"
        local model = getNodeByName modelName exact:true ignoreCase:false
        if model == undefined then (
            model = getNodeByName baseName exact:true ignoreCase:false
        )
        if model != undefined then (
            -- Add UVW Map modifier first for proper texture coords (channel 0 for maps)
            addModifier model (UVWMap maptype:0 channel:0)  -- Planar mapping, channel 0; tweak if needed
            
            -- Add Shell modifier for thickness
            addModifier model (Shell thickness:0.1 outerAmount:1.0 innerAmount:0.0)  -- 0.1 unit thickness, full outer; adjust as needed
            
            -- Apply material
            local mat = StandardMaterial()
            mat.diffuseMap = BitmapTexture filename:bleedPng
            showTextureMap mat true  -- Optional: show map in viewport
            model.material = mat
            
            -- Rename to baseName
            model.name = baseName
            
            print ("Done: " + model.name)
            messageBox ("Single processed: " + model.name + " is thicc and textured at " + dpiValue as string + " DPI.")
        ) else (
            messageBox ("Model not found for: " + baseName)
        )
    )
)

fn batchSvgToTexture dpiValue = (
    local folderPath = getSavePath caption:"Select Folder with SVG Files:"  -- Picks output/input dir
    if folderPath != undefined do (
        -- Fix any trailing BS in folderPath
        folderPath = trimRight folderPath "\\"  -- Strip extra backslashes
        folderPath += "/"  -- Use / for cross-compat, but Windows digs it
        
        print ("Selected folder: " + folderPath)  -- Debug: Confirm path
        
        local searchPath = folderPath + "*.svg"  -- Search string
        print ("Searching: " + searchPath)  -- Debug: Exact glob
        
        local svgFiles = getFiles searchPath  -- Grabs all .svg in folder
        print ("getFiles returned: " + svgFiles.count as string + " matches")  -- Debug: Raw count
        
        -- Extra debug: List all files in dir to see what's actually there
        local allFiles = getFiles (folderPath + "*.*")
        print ("All files in dir (" + allFiles.count as string + "):")
        for f in allFiles do print ("  " + (getFilenameFile f) + getFilenameType f)
        
        if svgFiles.count == 0 do (
            messageBox ("No SVG files found in " + folderPath + "—check extensions (.svg or .SVG?) or subdirs. See listener for file list.")
            return undefined
        )
        
        print ("Batching " + svgFiles.count as string + " SVGs at " + dpiValue as string + " DPI...")
        
        for svgPath in svgFiles do (
            print ("Processing: " + (getFilenameFile svgPath))
            
            -- Import the SVG first
            local importSuccess = importFile svgPath #noPrompt
            if not importSuccess do (
                messageBox ("Failed to import: " + svgPath)
                continue
            )
            
            local baseName = getFilenameFile svgPath
            local dir = getFilenamePath svgPath
            local pngPath = dir + baseName + ".png"
            local bleedPng = dir + baseName + "_bleed.png"
            
            -- Fix paths: Replace \ with / for DOS compatibility (double \\ for literal backslash)
            local svgPathFixed = substituteString svgPath "\\" "/"
            local pngPathFixed = substituteString pngPath "\\" "/"
            local bleedPngFixed = substituteString bleedPng "\\" "/"
            
            print ("Fixed paths - SVG: " + svgPathFixed + " PNG: " + pngPathFixed + " Bleed: " + bleedPngFixed)  -- Debug: Verify in listener
            
            -- Convert SVG to high-DPI PNG with ImageMagick (transparent bg, non-blocking)
            local magickCmd = "magick convert -density " + dpiValue as string + " -background none \"" + svgPathFixed + "\" \"" + pngPathFixed + "\""
            print ("Running: " + magickCmd)
            HiddenDOSCommand magickCmd donotwait:true
            sleep 1.0  -- Upped pause for batch stability
            if not (doesFileExist pngPath) do (
                messageBox ("Magick failed for " + baseName + ". Cmd: " + magickCmd)
                continue
            )
            
            -- Run alpha-bleed.exe
            local bleedCmd = "alpha-bleed.exe \"" + pngPathFixed + "\" \"" + bleedPngFixed + "\""
            print ("Running: " + bleedCmd)
            HiddenDOSCommand bleedCmd donotwait:true
            sleep 1.0
            if not (doesFileExist bleedPng) do (
                messageBox ("Bleed failed for " + baseName + ". Cmd: " + bleedCmd)
                continue
            )
            
            -- Find the imported model with SVG import suffix
            local modelName = baseName + ".svg_FillEditPoly"
            local model = getNodeByName modelName exact:true ignoreCase:false
            if model == undefined then (
                model = getNodeByName baseName exact:true ignoreCase:false
            )
            if model != undefined then (
                -- Add UVW Map modifier first for proper texture coords (channel 0 for maps)
                addModifier model (UVWMap maptype:0 channel:0)  -- Planar mapping, channel 0; tweak if needed
                
                -- Add Shell modifier for thickness
                addModifier model (Shell thickness:0.1 outerAmount:1.0 innerAmount:0.0)  -- 0.1 unit thickness, full outer; adjust as needed
                
                -- Apply material
                local mat = StandardMaterial()
                mat.diffuseMap = BitmapTexture filename:bleedPng
                showTextureMap mat true  -- Optional: show map in viewport
                model.material = mat
                
                -- Rename to baseName
                model.name = baseName
                
                print ("Done: " + model.name)
            ) else (
                messageBox ("Model not found for: " + baseName)
            )
        )
        print "Batch complete—your logos are thicc and ready."
        messageBox ("Batch done: " + svgFiles.count as string + " logos processed at " + dpiValue as string + " DPI.")
    )
)

-- Main launcher: Single unified dialog
fn launchSvgProcessor = (
    createDialog processorRollout
)

launchSvgProcessor()