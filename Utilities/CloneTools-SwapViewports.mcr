macroScript SwapViewports
category: "CloneTools"
tooltip: "Swap left and right viewports"
(
	fn swapVP v1:1 v2:2 = (
		viewport.activeViewport = v1
		local tm1 = viewport.GetTM()
		local fov1 = viewport.GetFOV()
		local cam1 = viewport.getCamera()
		local type1 = viewport.getType()

		viewport.activeViewport = v2
		local tm2 = viewport.GetTM()
		local fov2 = viewport.GetFOV()
		local cam2 = viewport.getCamera()
		local type2 = viewport.getType()

		viewport.activeViewport = v2
		if cam1 != undefined then
			viewport.setCamera cam1
		else (
			try(viewport.setCamera undefined)catch()
			viewport.setType type1
			viewport.SetTM tm1
		)
		viewport.SetFOV fov1

		viewport.activeViewport = v1
		if cam2 != undefined then
			viewport.setCamera cam2
		else (
			try(viewport.setCamera undefined)catch()
			viewport.setType type2
			viewport.SetTM tm2
		)
		viewport.SetFOV fov2
	)

	swapVP v1:1 v2:2
	completeredraw()
)
