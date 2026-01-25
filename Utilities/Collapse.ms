-- Collapse Under Top TurboSmooth & Shell
-- Logic: 
-- 1. Scan from the top of the stack down.
-- 2. Keep "Shell" and "TurboSmooth" modifiers.
-- 3. STOP scanning if:
--    - We hit a modifier that isn't Shell or TurboSmooth.
--    - We hit a SECOND TurboSmooth (so the lower one gets collapsed).
-- 4. Temporarily remove the kept modifiers, collapse the rest to Poly, then put them back.

macroScript CollapseUnderTopTS
category:"CloneTools"
toolTip:"Collapse Under TurboSmooth"
(
    undo "Collapse Under TurboSmooth" on
    (
        for o in selection do
        (
            if isValidNode o then
            (
                local modsToKeep = #()
                local foundTS = false
                
                -- 1. Identify which modifiers at the top to preserve
                for m in o.modifiers do
                (
                    if classOf m == TurboSmooth then
                    (
                        -- If we already found a TurboSmooth, stop here.
                        -- This ensures we only keep the TOP one. Lower ones get collapsed.
                        if foundTS then exit 
                        
                        foundTS = true
                        append modsToKeep m
                    )
                    else if classOf m == Shell then
                    (
                        -- Always keep Shell if it's in this top "block" of modifiers
                        append modsToKeep m
                    )
                    else
                    (
                        -- We hit something else (like Edit Poly, Bend, Symmetry, etc.)
                        -- Stop scanning; everything from here down gets collapsed.
                        exit 
                    )
                )

                -- 2. Execute the collapse
                if modsToKeep.count > 0 then
                (
                    -- Remove the modifiers we want to keep from the stack temporarily
                    -- We repeat 'deleteModifier o 1' because indices shift up after deletion
                    for i = 1 to modsToKeep.count do deleteModifier o 1
                    
                    -- Collapse the rest of the object/stack to Editable Poly
                    convertToPoly o
                    
                    -- Add the kept modifiers back in REVERSE order to restore original stack order
                    -- (Last one removed is the first one added back to the bottom of the new stack)
                    for i = modsToKeep.count to 1 by -1 do addModifier o modsToKeep[i]
                )
                else
                (
                    -- Nothing to keep at the top, just collapse everything
                    convertToPoly o
                )
            )
        )
    )
)