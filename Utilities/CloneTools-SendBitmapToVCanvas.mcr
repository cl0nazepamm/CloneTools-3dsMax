macroScript SendBitmapToVCanvas
	category:"CloneTools"
	tooltip:"Send Bitmap to Viewport Canvas"
	buttontext:"Send to VCanvas"
(
	-- Ensure Viewport Canvas is loaded
	if VCanvas == undefined do
		filein ((GetDir #maxroot) + "stdplugs\\stdscripts\\(PolyTools)\\ViewportCanvas.ms")

	if $ == undefined do (
		messageBox "Select a scene object first." title:"Send to Viewport Canvas"
		return false
	)
	if $.material == undefined do (
		messageBox "Selected object has no material." title:"Send to Viewport Canvas"
		return false
	)

	-- Get selected BitmapTexture from Slate Material Editor via GetSelectedNodes
	local smeView = ::sme.GetView (::sme.activeView)
	if smeView == undefined do (
		messageBox "No active SME view." title:"Send to Viewport Canvas"
		return false
	)

	local selectedBitmap = undefined
	local selNodes = smeView.GetSelectedNodes()
	for i = 1 to selNodes.count do (
		try (
			local ref = selNodes[i].reference
			if classOf ref == BitmapTexture do (
				selectedBitmap = ref
				exit
			)
		) catch ()
	)

	if selectedBitmap == undefined do (
		messageBox "Select a BitmapTexture node in the Slate Material Editor." title:"Send to Viewport Canvas"
		return false
	)

	---------------------------------------------------------------
	-- If bitmap file doesn't exist, offer to create a blank one
	---------------------------------------------------------------
	if selectedBitmap.filename == "" or not (doesFileExist selectedBitmap.filename) do
	(
		local createdFile = false

		rollout rlCreateTex "Create Blank Texture" width:300 height:200
		(
			label lblInfo "No texture file found. Create one:" align:#left offset:[0,4]

			group "Size"
			(
				dropdownlist ddSize "" items:#("512", "1024", "2048", "4096") selection:3
			)

			group "Save As"
			(
				edittext edPath "" width:250 align:#left
				button btnBrowse "..." width:30 height:20 align:#right offset:[0,-26]
			)

			button btnOK "Create" width:80 height:24 align:#right offset:[0,6]
			button btnCancel "Cancel" width:80 height:24 align:#right offset:[0,-28]

			on rlCreateTex open do
			(
				local defName = selectedBitmap.name
				if defName == "" do defName = "untitled"
				edPath.text = (getDir #image) + "\\" + defName + ".png"
			)

			on btnBrowse pressed do
			(
				local f = getSaveFileName caption:"Save Texture" filename:edPath.text \
					types:"PNG (*.png)|*.png|JPEG (*.jpg)|*.jpg|BMP (*.bmp)|*.bmp|"
				if f != undefined do edPath.text = f
			)

			on btnOK pressed do
			(
				local filePath = edPath.text
				if filePath == "" do (
					messageBox "Pick a save location." title:"Create Texture"
					return()
				)

				local sz = (ddSize.items[ddSize.selection]) as integer

				-- Make directory if needed
				local dir = getFilenamePath filePath
				if dir != "" and not (doesFileExist dir) do makeDir dir

				-- Create and save blank bitmap
				local bmp = bitmap sz sz color:(color 128 128 128)
				bmp.filename = filePath
				save bmp
				close bmp

				-- Wire it into the BitmapTexture node
				selectedBitmap.filename = filePath
				selectedBitmap.bitmap = openBitmap filePath

				createdFile = true
				destroyDialog rlCreateTex
			)

			on btnCancel pressed do
			(
				destroyDialog rlCreateTex
			)
		)

		createDialog rlCreateTex modal:true style:#(#style_titlebar, #style_border, #style_sysmenu)

		if not createdFile do return false
	)

	---------------------------------------------------------------
	-- Walk material tree to find which slot holds this bitmap
	---------------------------------------------------------------
	global _vcWalkTexmap
	fn _vcWalkTexmap tex targetRef &slotName &parentNode =
	(
		if slotName != undefined do return true
		local numMaps = 0
		try (numMaps = getNumSubTexmaps tex) catch (return false)
		for i = 1 to numMaps do (
			if slotName != undefined do exit
			local subTex = undefined
			try (subTex = getSubTexmap tex i) catch ()
			if subTex != undefined do (
				if subTex == targetRef then (
					slotName = getSubTexmapSlotName tex i
					parentNode = tex
				) else (
					_vcWalkTexmap subTex targetRef &slotName &parentNode
				)
			)
		)
		slotName != undefined
	)

	global _vcWalkMaterial
	fn _vcWalkMaterial mat targetRef &slotName &parentNode =
	(
		if slotName != undefined do return true
		local numSubs = 0
		try (numSubs = getNumSubMtls mat) catch ()
		for i = 1 to numSubs do (
			if slotName != undefined do exit
			local sm = undefined
			try (sm = getSubMtl mat i) catch ()
			if sm != undefined do
				_vcWalkMaterial sm targetRef &slotName &parentNode
		)
		if slotName != undefined do return true
		local numMaps = 0
		try (numMaps = getNumSubTexmaps mat) catch ()
		for i = 1 to numMaps do (
			if slotName != undefined do exit
			local tex = undefined
			try (tex = getSubTexmap mat i) catch ()
			if tex != undefined do (
				if tex == targetRef then (
					slotName = getSubTexmapSlotName mat i
					parentNode = mat
				) else (
					_vcWalkTexmap tex targetRef &slotName &parentNode
				)
			)
		)
		slotName != undefined
	)

	local foundSlotName = undefined
	local foundParent = undefined
	_vcWalkMaterial $.material selectedBitmap &foundSlotName &foundParent

	if foundSlotName == undefined do (
		messageBox "Could not find this bitmap in the selected object's material tree." title:"Send to Viewport Canvas"
		return false
	)

	---------------------------------------------------------------
	-- Assign to Viewport Canvas and start painting
	---------------------------------------------------------------
	VCanvas.currentTextureFile = selectedBitmap.filename
	VCanvas.mapSlotName = foundSlotName
	VCanvas.currentMaterial = $.material
	VCanvas.usedMapSlot = selectedBitmap
	VCanvas.currentObject = $

	try (
		VCSetSetting 4 selectedBitmap.coords.mapchannel
		VCOptionsRoll.mapch.value = selectedBitmap.coords.mapchannel
	) catch ()

	try ( VCOptionsRoll.mapbut.text = foundSlotName ) catch ()
	try ( VCSetUsingNewTexture() ) catch ()

	if VCanvas.doRestartTool do
		VCanvas.StartPaintTool VCanvas.currentTool

	format "Viewport Canvas: painting on '%' (%)\n" foundSlotName selectedBitmap.filename
)