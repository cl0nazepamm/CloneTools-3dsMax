try(destroyDialog ro_PureRenamer)catch()

rollout ro_PureRenamer "UE5 <-> Mixamo Renamer" width:200
(
    button btn_swap "Swap Names" width:180 height:40 toolTip:"Swaps names between UE5 and Mixamo formats. Does NOT change hierarchy."
    
    -- DATA MAPPING: #("UE5_Name", "Mixamo_Name")
    local boneMap = #(
        -- HIPS & SPINE
        #("pelvis", "mixamorig:Hips"),
        #("spine_01", "mixamorig:Spine"),
        #("spine_02", "mixamorig:Spine1"),
        #("spine_03", "mixamorig:Spine2"),
        -- spine_04 and spine_05 are left alone as there is no standard Mixamo equivalent
        
        #("neck_01", "mixamorig:Neck"),
        #("head", "mixamorig:Head"),
        
        -- LEGS (Left)
        #("thigh_l", "mixamorig:LeftUpLeg"),
        #("calf_l", "mixamorig:LeftLeg"),
        #("foot_l", "mixamorig:LeftFoot"),
        #("ball_l", "mixamorig:LeftToeBase"),
        
        -- LEGS (Right)
        #("thigh_r", "mixamorig:RightUpLeg"),
        #("calf_r", "mixamorig:RightLeg"),
        #("foot_r", "mixamorig:RightFoot"),
        #("ball_r", "mixamorig:RightToeBase"),

        -- ARMS (Left)
        #("clavicle_l", "mixamorig:LeftShoulder"),
        #("upperarm_l", "mixamorig:LeftArm"),
        #("lowerarm_l", "mixamorig:LeftForeArm"),
        #("hand_l", "mixamorig:LeftHand"),

        -- ARMS (Right)
        #("clavicle_r", "mixamorig:RightShoulder"),
        #("upperarm_r", "mixamorig:RightArm"),
        #("lowerarm_r", "mixamorig:RightForeArm"),
        #("hand_r", "mixamorig:RightHand"),

        -- FINGERS LEFT (Mapping 01->1, 02->2, 03->3)
        -- Metacarpals are ignored (they stay as 'metacarpal')
        #("thumb_01_l", "mixamorig:LeftHandThumb1"),
        #("thumb_02_l", "mixamorig:LeftHandThumb2"),
        #("thumb_03_l", "mixamorig:LeftHandThumb3"),
        
        #("index_01_l", "mixamorig:LeftHandIndex1"),
        #("index_02_l", "mixamorig:LeftHandIndex2"),
        #("index_03_l", "mixamorig:LeftHandIndex3"),
        
        #("middle_01_l", "mixamorig:LeftHandMiddle1"),
        #("middle_02_l", "mixamorig:LeftHandMiddle2"),
        #("middle_03_l", "mixamorig:LeftHandMiddle3"),
        
        #("ring_01_l", "mixamorig:LeftHandRing1"),
        #("ring_02_l", "mixamorig:LeftHandRing2"),
        #("ring_03_l", "mixamorig:LeftHandRing3"),
        
        #("pinky_01_l", "mixamorig:LeftHandPinky1"),
        #("pinky_02_l", "mixamorig:LeftHandPinky2"),
        #("pinky_03_l", "mixamorig:LeftHandPinky3"),

        -- FINGERS RIGHT
        #("thumb_01_r", "mixamorig:RightHandThumb1"),
        #("thumb_02_r", "mixamorig:RightHandThumb2"),
        #("thumb_03_r", "mixamorig:RightHandThumb3"),
        
        #("index_01_r", "mixamorig:RightHandIndex1"),
        #("index_02_r", "mixamorig:RightHandIndex2"),
        #("index_03_r", "mixamorig:RightHandIndex3"),
        
        #("middle_01_r", "mixamorig:RightHandMiddle1"),
        #("middle_02_r", "mixamorig:RightHandMiddle2"),
        #("middle_03_r", "mixamorig:RightHandMiddle3"),
        
        #("ring_01_r", "mixamorig:RightHandRing1"),
        #("ring_02_r", "mixamorig:RightHandRing2"),
        #("ring_03_r", "mixamorig:RightHandRing3"),
        
        #("pinky_01_r", "mixamorig:RightHandPinky1"),
        #("pinky_02_r", "mixamorig:RightHandPinky2"),
        #("pinky_03_r", "mixamorig:RightHandPinky3")
    )

    on btn_swap pressed do
    (
        undo "Bone Rename" on
        (
            local count = 0
            -- Use 'objects' to scan whole scene, or 'selection' for selected bones only
            local targetObjects = objects 
            
            for o in targetObjects do
            (
                local renamed = false
                
                for pair in boneMap do
                (
                    if not renamed then
                    (
                        -- IF CURRENT NAME IS UE5 -> SWITCH TO MIXAMO
                        if o.name == pair[1] then
                        (
                            o.name = pair[2]
                            renamed = true
                            count += 1
                        )
                        -- IF CURRENT NAME IS MIXAMO -> SWITCH TO UE5
                        else if o.name == pair[2] then
                        (
                            o.name = pair[1]
                            renamed = true
                            count += 1
                        )
                    )
                )
            )
            print ("Swapped names for " + (count as string) + " bones.")
        )
    )
)

createDialog ro_PureRenamer