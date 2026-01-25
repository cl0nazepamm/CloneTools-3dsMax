/*
	CopyUVChannels v2.0
	Description: Provides a UI to copy UV map channels (e.g. UV0 -> UV1) for selected objects.
	Install: Drag and drop into viewport or run script.
	Access: Customize User Interface > "CloneTools" > "Copy UV Channels"
*/

macroscript CopyUVChannels
category:"CloneTools"
tooltip:"Copy UV Channels"
buttonText:"Copy UVs"
(
	-- Define the Rollout (UI)
	rollout roCopyUVs "Copy UV Channels" width:220
	(
		group "Channel Settings"
		(
			spinner spnSource "Source Channel (UV0=1):" range:[1, 99, 1] type:#integer fieldwidth:40 align:#right
			spinner spnTarget "Target Channel (UV1=2):" range:[1, 99, 2] type:#integer fieldwidth:40 align:#right
		)
		
		button btnCopy "Copy Channel" width:190 height:35 align:#center padding:[0,10,0,0]
		
		fn processObject obj srcCh tgtCh =
		(
			-- Check if object supports mapping
			if (canConvertTo obj Editable_Poly) or (canConvertTo obj Editable_Mesh) then
			(
				-- Check map support is safer, but channelInfo usually handles it or throws
				try
				(
					-- Copy Source (Type 3 = Map Channel)
					channelInfo.CopyChannel obj 3 srcCh
					-- Paste to Target
					channelInfo.PasteChannel obj 3 tgtCh
					
					-- Optional: Name the new channel
					channelInfo.NameChannel obj 3 tgtCh ("Map Channel " + (tgtCh as string))
					return true
				)
				catch
				(
					format "Error processing object '%': %\n" obj.name (getCurrentException())
					return false
				)
			)
			else return false
		)

		on btnCopy pressed do
		(
			if selection.count == 0 then
			(
				messageBox "Please select one or more objects first." title:"Selection Error"
			)
			else
			(
				local successCount = 0
				local failCount = 0
				
				undo "Copy UV Channels" on
				(
					for obj in selection do
					(
						if (processObject obj spnSource.value spnTarget.value) then
							successCount += 1
						else
							failCount += 1
					)
				)
				
				local msg = "Copied Channel " + (spnSource.value as string) + " to " + (spnTarget.value as string) + "\n\n"
				msg += "Success: " + (successCount as string) + " objects.\n"
				if failCount > 0 do msg += "Failed: " + (failCount as string) + " objects."
				
				messageBox msg title:"Operation Complete"
			)
		)
	)
	
	-- Open the Dialog
	on execute do
	(
		try(destroyDialog roCopyUVs)catch()
		createDialog roCopyUVs
	)
)
