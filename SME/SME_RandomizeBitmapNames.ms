macroScript RenameNodesRandom
category:"CloneTools"
tooltip:"Rename Selected Nodes (Random)"
buttonText:"RnmRand"
(
    on execute do (
        -- Check if Slate Material Editor is open
        if sme.IsOpen() then (
            local currentView = sme.GetView (sme.activeView)
            local selectedNodes = currentView.GetSelectedNodes()
            
            if selectedNodes.count > 0 then (
                -- Enable undo functionality
                undo "Rename Nodes" on (
                    for n in selectedNodes do (
                        -- Generate random seed
                        local randNum = random 10000 99999
                        n.name = "Bitmap_" + (randNum as string)
                    )
                )
                print ("Renamed " + (selectedNodes.count as string) + " nodes.")
            ) 
            else (
                print "No nodes selected in the active view."
            )
        ) 
        else (
            messageBox "Please open the Slate Material Editor first."
        )
    )
)