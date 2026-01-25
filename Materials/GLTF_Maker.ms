/*
	GLTF_Maker v1.7
	3ds Max Macroscript for creating glTF Materials with PBR texture maps
	Supports standard PBR workflow and ORM (Occlusion/Roughness/Metallic) packed textures

	Uses .NET OpenFileDialog for multi-file selection

	Install: Run script or place in 3dsMax startup scripts folder
	Access: Customize > Customize User Interface > Category: "CloneTools"
*/

macroscript GLTF_Maker
category:"CloneTools"
tooltip:"GLTF Material Maker"
buttonText:"GLTF Maker"
(
	try(destroyDialog GLTF_Maker_Rollout) catch()

	rollout GLTF_Maker_Rollout "GLTF Maker" width:420 height:650
	(
		-- Variables to store file paths
		local baseColorPath = ""
		local normalPath = ""
		local roughnessPath = ""
		local metalnessPath = ""
		local aoPath = ""
		local ormPath = ""
		local emissionPath = ""
		local alphaPath = ""

		local isORMMode = false

		-- UI Groups
		group "Material Settings"
		(
			edittext edt_matName "Material Name:" text:"M_Objects" width:390
			checkbox chk_autoDetect "Auto-detect ORM from filename" checked:true
		)

		group "Load Textures"
		(
			button btn_loadAll "Select Textures (Multi-Select)" width:390 height:35
			label lbl_hint "Ctrl+Click or Shift+Click to select multiple files" align:#center
		)

		group "Detected Maps"
		(
			label lbl_baseColor "Base Color:" across:2 align:#left
			edittext edt_baseColor "" width:300 readonly:true align:#right

			label lbl_normal "Normal:" across:2 align:#left
			edittext edt_normal "" width:300 readonly:true align:#right

			label lbl_roughness "Roughness:" across:2 align:#left
			edittext edt_roughness "" width:300 readonly:true align:#right

			label lbl_metalness "Metalness:" across:2 align:#left
			edittext edt_metalness "" width:300 readonly:true align:#right

			label lbl_ao "AO:" across:2 align:#left
			edittext edt_ao "" width:300 readonly:true align:#right

			label lbl_orm "ORM Packed:" across:2 align:#left
			edittext edt_orm "" width:300 readonly:true align:#right

			label lbl_emission "Emission:" across:2 align:#left
			edittext edt_emission "" width:300 readonly:true align:#right

			label lbl_alpha "Alpha:" across:2 align:#left
			edittext edt_alpha "" width:300 readonly:true align:#right
		)

		group "Workflow Mode"
		(
			radiobuttons rdo_mode "" labels:#("Standard PBR (Separate Maps)", "ORM Packed (Single Map)") default:1 columns:1
		)

		button btn_clear "Clear All" width:390 height:25
		button btn_create "Create glTF Material" width:390 height:35

		group "Created Material (Drag to Editor)"
		(
			materialButton mtl_slot "" width:80 height:80 align:#center
			label lbl_dragHint "Drag material above to Slate or Material Editor" align:#center
		)

		label lbl_status "" align:#center

		-- Function to check if filename indicates ORM
		fn isORMTexture filename =
		(
			local lowerName = toLower filename
			local ormIndicators = #("occlusionroughnessmetallic", "roughnessmetallicocclusion", "_orm_", "_orm.", "-orm-", "-orm.")
			for indicator in ormIndicators do
			(
				if findString lowerName indicator != undefined then return true
			)
			local ormPos = findString lowerName "orm"
			if ormPos != undefined do
			(
				local beforeChar = if ormPos > 1 then lowerName[ormPos-1] else "_"
				local afterPos = ormPos + 3
				local afterChar = if afterPos <= lowerName.count then lowerName[afterPos] else "_"
				if (beforeChar == "_" or beforeChar == "-" or beforeChar == " " or ormPos == 1) and \
				   (afterChar == "_" or afterChar == "-" or afterChar == "." or afterChar == " " or afterPos > lowerName.count) then
					return true
			)
			return false
		)

		-- Function to get texture type from filename
		fn getTextureType filename =
		(
			local lowerName = toLower (getFilenameFile filename)

			if isORMTexture lowerName then return #orm

			if findString lowerName "basecolor" != undefined then return #baseColor
			if findString lowerName "base_color" != undefined then return #baseColor
			if findString lowerName "albedo" != undefined then return #baseColor
			if findString lowerName "diffuse" != undefined then return #baseColor
			if findString lowerName "_col." != undefined then return #baseColor
			if findString lowerName "_col_" != undefined then return #baseColor
			if findString lowerName "_color" != undefined then return #baseColor

			if findString lowerName "normal" != undefined then return #normal
			if findString lowerName "_nrm" != undefined then return #normal
			if findString lowerName "_nor." != undefined then return #normal
			if findString lowerName "_nor_" != undefined then return #normal

			if findString lowerName "roughness" != undefined then return #roughness
			if findString lowerName "_rough" != undefined then return #roughness
			if findString lowerName "_rgh" != undefined then return #roughness

			if findString lowerName "metallic" != undefined then return #metalness
			if findString lowerName "metalness" != undefined then return #metalness
			if findString lowerName "_met." != undefined then return #metalness
			if findString lowerName "_met_" != undefined then return #metalness
			if findString lowerName "_mtl" != undefined then return #metalness

			if findString lowerName "occlusion" != undefined and findString lowerName "roughness" == undefined then return #ao
			if findString lowerName "_ao." != undefined then return #ao
			if findString lowerName "_ao_" != undefined then return #ao
			if findString lowerName "ambientocclusion" != undefined then return #ao

			if findString lowerName "emission" != undefined then return #emission
			if findString lowerName "emissive" != undefined then return #emission
			if findString lowerName "_emit" != undefined then return #emission
			if findString lowerName "_glow" != undefined then return #emission

			if findString lowerName "alpha" != undefined then return #alpha
			if findString lowerName "opacity" != undefined then return #alpha
			if findString lowerName "transparency" != undefined then return #alpha

			return #unknown
		)

		-- Function to clear all paths
		fn clearAllPaths =
		(
			baseColorPath = ""
			normalPath = ""
			roughnessPath = ""
			metalnessPath = ""
			aoPath = ""
			ormPath = ""
			emissionPath = ""
			alphaPath = ""

			edt_baseColor.text = ""
			edt_normal.text = ""
			edt_roughness.text = ""
			edt_metalness.text = ""
			edt_ao.text = ""
			edt_orm.text = ""
			edt_emission.text = ""
			edt_alpha.text = ""
		)

		-- Function to process files
		fn processFiles files =
		(
			local foundORM = false
			local assignedCount = 0

			for f in files do
			(
				local ext = toLower (getFilenameType f)
				if ext == ".png" or ext == ".jpg" or ext == ".jpeg" or ext == ".tga" or ext == ".tif" or ext == ".tiff" or ext == ".bmp" or ext == ".exr" do
				(
					local texType = getTextureType f

					case texType of
					(
						#baseColor: (baseColorPath = f; edt_baseColor.text = getFilenameFile f; assignedCount += 1)
						#normal: (normalPath = f; edt_normal.text = getFilenameFile f; assignedCount += 1)
						#roughness: (roughnessPath = f; edt_roughness.text = getFilenameFile f; assignedCount += 1)
						#metalness: (metalnessPath = f; edt_metalness.text = getFilenameFile f; assignedCount += 1)
						#ao: (aoPath = f; edt_ao.text = getFilenameFile f; assignedCount += 1)
						#orm: (ormPath = f; edt_orm.text = getFilenameFile f; foundORM = true; assignedCount += 1)
						#emission: (emissionPath = f; edt_emission.text = getFilenameFile f; assignedCount += 1)
						#alpha: (alphaPath = f; edt_alpha.text = getFilenameFile f; assignedCount += 1)
					)
				)
			)

			if foundORM and chk_autoDetect.checked do rdo_mode.state = 2

			return assignedCount
		)

		-- Event Handlers
		on btn_loadAll pressed do
		(
			-- Use .NET OpenFileDialog for multi-select
			local ofd = dotNetObject "System.Windows.Forms.OpenFileDialog"
			ofd.Title = "Select Texture Maps"
			ofd.Filter = "Image Files (*.png;*.jpg;*.jpeg;*.tga;*.tif;*.bmp;*.exr)|*.png;*.jpg;*.jpeg;*.tga;*.tif;*.bmp;*.exr|All Files (*.*)|*.*"
			ofd.Multiselect = true

			local result = ofd.ShowDialog()

			if result == (dotNetClass "System.Windows.Forms.DialogResult").OK do
			(
				local files = ofd.FileNames

				if files.count > 0 do
				(
					clearAllPaths()

					-- Convert .NET array to MaxScript array
					local maxFiles = #()
					for i = 1 to files.count do append maxFiles files[i]

					local cnt = processFiles maxFiles
					lbl_status.text = "Assigned " + (cnt as string) + " of " + (maxFiles.count as string) + " textures"

					-- Try to get material name from first texture
					local firstName = getFilenameFile maxFiles[1]
					local suffixes = #("_basecolor", "_base_color", "_albedo", "_diffuse", "_normal", "_nrm", "_roughness", "_rough", "_metallic", "_metalness", "_ao", "_occlusion", "_orm", "_emission", "_emissive", "_alpha", "_opacity")
					local baseName = firstName
					for suffix in suffixes do
					(
						local pos = findString (toLower baseName) suffix
						if pos != undefined do baseName = substring baseName 1 (pos-1)
					)
					if baseName != "" and baseName != firstName do
						edt_matName.text = "M_" + baseName
				)
			)
		)

		on btn_clear pressed do
		(
			clearAllPaths()
			rdo_mode.state = 1
			lbl_status.text = "Cleared all maps"
		)

		on btn_create pressed do
		(
			if (classof glTFMaterial) == UndefinedClass then
			(
				messageBox "glTFMaterial class not found!\n\nPlease ensure the Babylon.js Exporter plugin is installed." title:"Error"
				return()
			)

			local matName = edt_matName.text
			if matName == "" do matName = "M_Objects"

			local gltfMat = glTFMaterial name:matName

			fn createBitmapNode filePath =
			(
				if filePath != "" and doesFileExist filePath then
				(
					local bmp = Bitmaptexture filename:filePath
					bmp.name = getFilenameFile filePath
					return bmp
				)
				return undefined
			)

			local mapsAssigned = 0

			if baseColorPath != "" do
			(
				local bmp = createBitmapNode baseColorPath
				if bmp != undefined do (gltfMat.baseColorMap = bmp; mapsAssigned += 1)
			)

			if normalPath != "" do
			(
				local bmp = createBitmapNode normalPath
				if bmp != undefined do (gltfMat.normalMap = bmp; mapsAssigned += 1)
			)

			if alphaPath != "" do
			(
				local bmp = createBitmapNode alphaPath
				if bmp != undefined do (gltfMat.alphaMap = bmp; mapsAssigned += 1)
			)

			if emissionPath != "" do
			(
				local bmp = createBitmapNode emissionPath
				if bmp != undefined do (gltfMat.emissionMap = bmp; mapsAssigned += 1)
			)

			if rdo_mode.state == 2 then
			(
				if ormPath != "" do
				(
					local bmp = createBitmapNode ormPath
					if bmp != undefined do
					(
						try(gltfMat.ambientOcclusionMap = bmp)catch()
						try(gltfMat.roughnessMetallicMap = bmp)catch()
						try(gltfMat.roughnessMap = bmp)catch()
						try(gltfMat.metalnessMap = bmp)catch()
						mapsAssigned += 1
					)
				)
			)
			else
			(
				if roughnessPath != "" do
				(
					local bmp = createBitmapNode roughnessPath
					if bmp != undefined do
					(
						try(gltfMat.roughnessMap = bmp; mapsAssigned += 1)catch()
					)
				)

				if metalnessPath != "" do
				(
					local bmp = createBitmapNode metalnessPath
					if bmp != undefined do
					(
						try(gltfMat.metalnessMap = bmp; mapsAssigned += 1)catch()
					)
				)

				if aoPath != "" do
				(
					local bmp = createBitmapNode aoPath
					if bmp != undefined do
					(
						try(gltfMat.ambientOcclusionMap = bmp; mapsAssigned += 1)catch()
					)
				)
			)

			mtl_slot.material = gltfMat

			local modeStr = if rdo_mode.state == 2 then "ORM" else "Standard PBR"
			lbl_status.text = "Created: " + matName + " (" + modeStr + ") - " + (mapsAssigned as string) + " maps"
		)
	)

	createDialog GLTF_Maker_Rollout
)
