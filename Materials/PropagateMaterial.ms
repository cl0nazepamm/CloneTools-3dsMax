-- Propagate Multi-Material to Single Material Based on Material ID
-- Assigns the correct sub-material from a multi-material based on Material ID usage

macroScript PropagateMaterial
category:"CloneTools"
tooltip:"Propagate Material by ID"
(
    for obj in selection where superclassof obj == GeometryClass do
    (
        if obj.material != undefined and classof obj.material == Multimaterial then
        (
            -- Get unique material IDs used on this object
            local matIDs = #()
            
            for i = 1 to obj.material.numsubs do
            (
                polyop.setFaceSelection obj #{}
                obj.selectByMaterial i
                local faces = polyop.getFaceSelection obj
                
                if faces.numberset > 0 do
                (
                    append matIDs i
                )
            )
            
            -- If object uses only one material ID, propagate it
            if matIDs.count == 1 then
            (
                local matID = matIDs[1]
                obj.material = obj.material[matID]
                format "% - Propagated Material ID % (%)\n" obj.name matID obj.material.name
            )
            else if matIDs.count > 1 then
            (
                format "% - Skipped (uses % material IDs)\n" obj.name matIDs.count
            )
            else
            (
                format "% - Warning: No material IDs found\n" obj.name
            )
        )
        else if obj.material == undefined then
        (
            format "% - Skipped (no material)\n" obj.name
        )
        else
        (
            format "% - Already has single material\n" obj.name
        )
    )
    
    format "\nDone!\n"
)