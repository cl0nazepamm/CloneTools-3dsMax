-- Offset Material IDs Script for 3ds Max
-- This script offsets the material IDs of faces in selected Editable Poly or Editable Mesh objects by a specified number.

macroScript OffsetMaterialIDs
category:"CloneTools"
toolTip:"Offset Material IDs"
buttonText:"Offset Mat IDs"
(
    rollout OffsetMatIDRollout "Offset Material IDs" width:200 height:80
    (
        spinner offsetSpinner "Offset Amount:" range:[-1000,1000,2] type:#integer align:#center
        button applyButton "Apply Offset" width:140 height:30 align:#center
        
        on applyButton pressed do
        (
            local offset = offsetSpinner.value
            if offset == 0 then 
            (
                messageBox "Offset is 0. No changes will be made."
                return()
            )
            
            undo "Offset Mat IDs" on
            (
                for obj in selection where (superClassOf obj == GeometryClass) do
                (
                    local base = obj.baseObject
                    if (classOf base == Editable_Poly) then
                    (
                        for f = 1 to polyOp.getNumFaces obj do
                        (
                            local currentID = polyOp.getFaceMatID obj f
                            local newID = currentID + offset
                            if newID < 1 then newID = 1 -- Clamp to minimum 1 to avoid invalid IDs
                            polyOp.setFaceMatID obj f newID
                        )
                    )
                    else if (classOf base == Editable_Mesh) then
                    (
                        for f = 1 to meshOp.getNumFaces obj do
                        (
                            local currentID = getFaceMatID obj f
                            local newID = currentID + offset
                            if newID < 1 then newID = 1
                            setFaceMatID obj f newID
                        )
                        update obj
                    )
                    else
                    (
                        messageBox ("Object " + obj.name + " is not an Editable Poly or Mesh. Skipping.")
                    )
                )
            )
            messageBox "Material IDs offset complete!"
        )
    )
    
    createDialog OffsetMatIDRollout
)