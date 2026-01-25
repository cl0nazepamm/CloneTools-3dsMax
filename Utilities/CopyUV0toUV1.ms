/*
	CopyUV0toUV1 v1.2
	Copies UV Channel 1 (UV0) to UV Channel 2 (UV1) for selected objects

	Install: Run script or place in 3dsMax startup scripts folder
	Access: Customize > Customize User Interface > Category: "CloneTools"
*/

macroscript CopyUV0toUV1
category:"CloneTools"
tooltip:"Copy UV0 to UV1"
buttonText:"Copy UV0 to UV1"
(
	if selection.count == 0 then
	(
		messageBox "No objects selected.\n\nPlease select one or more editable mesh/poly objects." title:"Copy UV0 to UV1"
	)
	else
	(
		local processedCount = 0
		local skippedCount = 0

		for obj in selection do
		(
			local hasUV1 = false

			-- Check for UV channel 1 based on object type
			if classof obj == Editable_Poly then
			(
				hasUV1 = polyop.getMapSupport obj 1
			)
			else if classof obj == Editable_Mesh then
			(
				hasUV1 = meshop.getMapSupport obj 1
			)

			if hasUV1 then
			(
				try
				(
					channelInfo.CopyChannel obj 3 1
					channelInfo.PasteChannel obj 3 2
					processedCount += 1
				)
				catch
				(
					skippedCount += 1
				)
			)
			else
			(
				skippedCount += 1
			)
		)

		if processedCount > 0 then
			format "Copied UV0 to UV1 on % object(s)\n" processedCount

		if skippedCount > 0 then
			format "Skipped % object(s) - no UV channel or unsupported type\n" skippedCount
	)
)
