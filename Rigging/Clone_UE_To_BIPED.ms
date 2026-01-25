-- Clone UE to Biped Alignment Script
-- Aligns 3ds Max Biped to match UE skeleton structure with precise joint matching
-- M3org - Clone
-- Fixed: Dynamic spine detection, proper matrix-based alignment for ALL joints

--=====================================================================
-- 1. Detect UE Skeleton Structure (BEFORE creating biped)
--=====================================================================

-- Detect spine bones (spine_01 through spine_05)
global detectedSpines = #()
for i = 1 to 5 do (
    boneName = "spine_0" + (i as string)
    boneObj = getNodeByName boneName
    if boneObj != undefined then (
        append detectedSpines boneName
    )
)
global spineCount = detectedSpines.count
format "Detected % spine bones: %\n" spineCount detectedSpines

-- Detect neck bones (neck_01, neck_02)
global detectedNecks = #()
for i = 1 to 2 do (
    boneName = "neck_0" + (i as string)
    boneObj = getNodeByName boneName
    if boneObj != undefined then (
        append detectedNecks boneName
    )
)
global neckCount = detectedNecks.count
format "Detected % neck bones: %\n" neckCount detectedNecks

-- Ensure minimum counts
if spineCount < 1 then spineCount = 1
if neckCount < 1 then neckCount = 1

--=====================================================================
-- 2. Create the biped with detected spine/neck count
--=====================================================================
bipObj = biped.createNew 200 -90 [0,0,0] \
    arms:true neckLinks:neckCount spineLinks:spineCount fingers:5 fingerLinks:3 toes:1 \
    forearmTwistLinks:2 upperarmTwistLinks:2 thighTwistLinks:2 calfTwistLinks:2 toelinks:1

$'Bip001'.controller.figureMode = true
format "Created Biped with % spine links and % neck links\n" spineCount neckCount

--=====================================================================
-- 2b. Build dynamic bone name tables
--=====================================================================
global myRoot = #("root", "pelvis")

-- Build spine chain: pelvis -> spine_01 -> spine_02 -> ... -> first neck
global mySpine = #("pelvis")
for s in detectedSpines do append mySpine s
if detectedNecks.count > 0 then (
    append mySpine detectedNecks[1]  -- End with first neck bone
) else (
    append mySpine "head"  -- Fallback if no neck
)
format "Spine chain: %\n" mySpine

-- Build neck chain: neck_01 -> neck_02 -> head
global myNeck = #()
for n in detectedNecks do append myNeck n
append myNeck "head"
format "Neck chain: %\n" myNeck

global myLArm = #("clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "middle_01_l")
global myRArm = #("clavicle_r", "upperarm_r", "lowerarm_r", "hand_r", "middle_01_r")
global myRFing  = #(
    "thumb_01_r", "thumb_02_r", "thumb_03_r",
    "index_01_r", "index_02_r", "index_03_r",
    "middle_01_r", "middle_02_r", "middle_03_r",
    "ring_01_r", "ring_02_r", "ring_03_r",
    "pinky_01_r", "pinky_02_r", "pinky_03_r"
)
global myLFing  = #(
    "thumb_01_l", "thumb_02_l", "thumb_03_l",
    "index_01_l", "index_02_l", "index_03_l",
    "middle_01_l", "middle_02_l", "middle_03_l",
    "ring_01_l", "ring_02_l", "ring_03_l",
    "pinky_01_l", "pinky_02_l", "pinky_03_l"
)
global myLLeg   = #("thigh_l", "calf_l", "foot_l", "ball_l")
global myRLeg   = #("thigh_r", "calf_r", "foot_r", "ball_r")

--=====================================================================
-- 3. Helper functions
--=====================================================================

-- Scale biped bone to match distance between two source bones
fn scaleBone firstBone endBone bipBone = (
    d = distance firstBone.transform.position endBone.transform.position
    biped.setTransform bipBone #scale [d, d, d] true
)

-- Get Biped spine bone name by index (1-based)
-- Index 1 = "Bip001 Spine", Index 2 = "Bip001 Spine1", etc.
fn getBipSpineName idx = (
    if idx == 1 then "Bip001 Spine"
    else "Bip001 Spine" + ((idx - 1) as string)
)

-- Get Biped neck bone name by index (1-based)
-- Index 1 = "Bip001 Neck", Index 2 = "Bip001 Neck1", etc.
fn getBipNeckName idx = (
    if idx == 1 then "Bip001 Neck"
    else "Bip001 Neck" + ((idx - 1) as string)
)

-- Create rotation helper using LookAt constraint (for spine/neck)
fn createSpineHelper srcBone tgtBone upAxisParams = (
    helperName = "myPoint" + srcBone.name
    p = point name:helperName centermarker:off axistripod:on cross:off box:on pos:srcBone.transform.position isSelected:off

    p.rotation.controller = LookAt_Constraint()
    p.rotation.controller.appendTarget tgtBone 50.0
    p.rotation.controller.relative = false
    p.rotation.controller.target_axis = 0
    p.rotation.controller.target_axisFlip = false
    p.rotation.controller.upnode_world = true
    p.rotation.controller.StoUP_axis = upAxisParams[1]
    p.rotation.controller.StoUP_axisFlip = upAxisParams[2]
    p.rotation.controller.upnode_axis = upAxisParams[3]

    -- Bake the transform and remove constraint
    finalTM = p.transform
    p.rotation.controller = Euler_XYZ()
    p.transform = finalTM
    p
)

-- Create rotation helper using matrix math (preserves source bone roll)
-- Used for arms - X points to child, Z from source bone's Z axis
fn createArmHelper srcBone tgtBone = (
    helperName = "myPoint" + srcBone.name

    p1 = srcBone.transform.position
    p2 = tgtBone.transform.position

    -- X axis: aim direction (parent to child)
    vX = normalize (p2 - p1)

    -- Get source bone's Z axis for roll reference
    vSrcZ = normalize srcBone.transform.row3

    -- Y axis: perpendicular to X and source Z
    vY = normalize (cross vSrcZ vX)

    -- Z axis: complete the orthonormal basis
    vZ = normalize (cross vX vY)

    -- Construct matrix
    tm = matrix3 vX vY vZ p1

    p = point name:helperName centermarker:off axistripod:on cross:off box:on transform:tm isSelected:off
    p
)

-- Create rotation helper for legs
-- Directly uses source bone's rotation with axis remapping for Biped compatibility
-- UE legs: X down, Y forward, Z outward | Biped legs: X down, Z twist axis
fn createLegHelper srcBone tgtBone isLeft = (
    helperName = "myPoint" + srcBone.name

    p1 = srcBone.transform.position
    p2 = tgtBone.transform.position

    -- Get source bone's actual orientation axes
    srcX = normalize srcBone.transform.row1  -- Source bone's X (typically down the bone)
    srcY = normalize srcBone.transform.row2  -- Source bone's Y (typically forward)
    srcZ = normalize srcBone.transform.row3  -- Source bone's Z (typically outward)

    -- Calculate aim direction (parent to child) - this is the bone's actual direction
    aimDir = normalize (p2 - p1)

    -- For Biped legs:
    -- X axis = aim direction (down to child)
    -- Y axis = forward direction (from source bone's Y, orthogonalized)
    -- Z axis = outward/twist axis (perpendicular to X and Y)

    vX = aimDir

    -- Project source Y onto plane perpendicular to vX to get forward direction
    -- This preserves the leg's "forward facing" orientation
    vY = normalize (srcY - (dot srcY vX) * vX)

    -- If vY is degenerate (srcY parallel to vX), fall back to world forward
    if (length vY) < 0.001 then (
        worldFwd = [0, -1, 0]  -- Max world -Y is forward
        vY = normalize (worldFwd - (dot worldFwd vX) * vX)
    )

    -- Z axis completes orthonormal basis
    vZ = normalize (cross vX vY)

    -- Re-orthogonalize Y to ensure perfect orthonormal matrix
    vY = normalize (cross vZ vX)

    -- Construct matrix
    tm = matrix3 vX vY vZ p1

    p = point name:helperName centermarker:off axistripod:on cross:off box:on transform:tm isSelected:off
    p
)

-- Create rotation helper for foot
-- Uses source foot bone's orientation for proper alignment
-- Foot X points to ball/toe (Forward), Z points Up, Y points Side
fn createFootHelper srcBone tgtBone = (
    helperName = "myPoint" + srcBone.name

    p1 = srcBone.transform.position
    p2 = tgtBone.transform.position

    -- X axis: aim direction to ball/toe (Forward)
    vX = normalize (p2 - p1)

    -- Z axis: Use source bone's Z axis (Attempt 1 logic - was 'correct angle')
    srcZ = normalize srcBone.transform.row3

    -- Project Z onto plane perpendicular to vX
    vZ = normalize (srcZ - (dot srcZ vX) * vX)

    -- If degenerate (Z parallel to aim), use World Z
    if (length vZ) < 0.001 then (
        worldUp = [0, 0, 1]
        vZ = normalize (worldUp - (dot worldUp vX) * vX)
    )

    -- Y axis: Side (Z cross X)
    vY = normalize (cross vZ vX)

    -- Re-orthogonalize Z
    vZ = normalize (cross vX vY)

    -- Construct matrix
    tm = matrix3 vX vY vZ p1
    
    -- Apply User requested offset: "Rotate Z -90"
    -- This rotates around the Local Z (Up) axis
    preRotateZ tm -90

    p = point name:helperName centermarker:off axistripod:on cross:off box:on transform:tm isSelected:off
    p
)

-- Create finger rotation helper
fn createFingerHelper srcBone tgtBone = (
    helperName = "myPoint" + srcBone.name
    p = point name:helperName centermarker:off axistripod:on cross:off box:on pos:srcBone.transform.position isSelected:off

    p.rotation.controller = LookAt_Constraint()
    p.rotation.controller.appendTarget tgtBone 50.0
    p.rotation.controller.relative = false
    p.rotation.controller.target_axis = 0
    p.rotation.controller.target_axisFlip = false
    p.rotation.controller.upnode_world = true
    p.rotation.controller.StoUP_axis = 1
    p.rotation.controller.StoUP_axisFlip = true
    p.rotation.controller.upnode_axis = 2

    finalTM = p.transform
    p.rotation.controller = Euler_XYZ()
    p.transform = finalTM
    p
)

-- Apply rotation from helper to biped bone (relative rotation method)
fn applyRotation bipBone helper = (
    rot = (in coordsys bipBone helper.rotation as eulerAngles) as angleaxis
    in coordsys bipBone rotate bipBone rot
)

-- Apply rotation from helper directly using world space (for legs)
fn applyWorldRotation bipBone helper = (
    biped.setTransform bipBone #rotation helper.transform.rotation true
)

-- Direct transform copy from source bone to biped (for precise alignment)
fn alignBipedToSource bipBone srcBone = (
    -- Get source bone's world rotation
    srcRot = srcBone.transform.rotation
    biped.setTransform bipBone #rotation srcRot true
)

-- Create rotation matrix that aligns biped bone to source bone orientation
-- This is the most precise method - constructs rotation from source bone's actual transform
fn createDirectAlignHelper srcBone tgtBone = (
    helperName = "myPoint" + srcBone.name

    p1 = srcBone.transform.position
    p2 = tgtBone.transform.position

    -- Use source bone's actual rotation axes
    srcX = normalize srcBone.transform.row1
    srcY = normalize srcBone.transform.row2
    srcZ = normalize srcBone.transform.row3

    -- Calculate the actual aim direction to child
    aimDir = normalize (p2 - p1)

    -- Calculate the rotation needed to align srcX to aimDir
    -- while preserving the roll (twist) from the source bone

    -- Start with source bone's orientation
    vX = aimDir

    -- Project source bone's Y and Z onto plane perpendicular to new X
    -- This preserves the roll/twist
    dotYX = dot srcY vX
    vY = normalize (srcY - dotYX * vX)

    -- Handle degenerate case
    if (length vY) < 0.001 then (
        dotZX = dot srcZ vX
        vZ = normalize (srcZ - dotZX * vX)
        vY = normalize (cross vZ vX)
    ) else (
        vZ = normalize (cross vX vY)
        vY = normalize (cross vZ vX)  -- Re-orthogonalize
    )

    tm = matrix3 vX vY vZ p1

    p = point name:helperName centermarker:off axistripod:on cross:off box:on transform:tm isSelected:off
    p
)

--=====================================================================
-- 4. Root / Pelvis Alignment
--=====================================================================
biped.setTransform $'Bip001' #pos $pelvis.transform.position false

--=====================================================================
-- 5. Spine Alignment (Dynamic - handles 1-5 spine bones)
--=====================================================================
format "Aligning % spine bones...\n" spineCount

-- Create arrays to hold biped spine references
bipSpines = #()
for i = 1 to spineCount do (
    bipName = getBipSpineName i
    bipBone = getNodeByName bipName
    if bipBone != undefined then (
        append bipSpines bipBone
        format "  Found Biped spine: %\n" bipName
    )
)

-- Position each spine bone at its source location
for i = 1 to spineCount do (
    srcBone = getNodeByName detectedSpines[i]
    if srcBone != undefined and bipSpines[i] != undefined then (
        biped.setTransform bipSpines[i] #pos srcBone.transform.position false
        format "  Positioned % at %\n" (getBipSpineName i) detectedSpines[i]
    )
)

-- Create rotation helpers for spine chain (pelvis -> spines -> neck)
spineHelpers = #()
for i = 1 to (mySpine.count - 1) do (
    src = getNodeByName mySpine[i]
    tgt = getNodeByName mySpine[i + 1]
    if src != undefined and tgt != undefined then (
        h = createSpineHelper src tgt #(1, true, 1)
        append spineHelpers h
    )
)

-- Apply rotations to each spine (helpers[1] is pelvis->spine_01, helpers[2] is spine_01->spine_02, etc.)
-- We skip helpers[1] (pelvis rotation) and start from helpers[2] for Bip001 Spine
for i = 1 to spineCount do (
    if (i + 1) <= spineHelpers.count and bipSpines[i] != undefined then (
        applyRotation bipSpines[i] spineHelpers[i + 1]
        format "  Rotated % using helper %\n" (getBipSpineName i) (i + 1)
    )
)

-- Scale each spine bone to match distance to next bone
for i = 1 to spineCount do (
    srcBone = getNodeByName detectedSpines[i]
    -- Get next bone in chain (either next spine or first neck)
    nextBoneName = if i < spineCount then detectedSpines[i + 1] else (if detectedNecks.count > 0 then detectedNecks[1] else "head")
    nextBone = getNodeByName nextBoneName
    if srcBone != undefined and nextBone != undefined and bipSpines[i] != undefined then (
        scaleBone srcBone nextBone bipSpines[i]
        format "  Scaled % (distance to %)\n" (getBipSpineName i) nextBoneName
    )
)

--=====================================================================
-- 6. Neck / Head Alignment (Dynamic - handles 1-2 neck bones)
--=====================================================================
format "Aligning % neck bones...\n" neckCount

-- Create array to hold biped neck references
bipNecks = #()
for i = 1 to neckCount do (
    bipName = getBipNeckName i
    bipBone = getNodeByName bipName
    if bipBone != undefined then (
        append bipNecks bipBone
        format "  Found Biped neck: %\n" bipName
    )
)

-- Position each neck bone
for i = 1 to neckCount do (
    srcBone = getNodeByName detectedNecks[i]
    if srcBone != undefined and bipNecks[i] != undefined then (
        biped.setTransform bipNecks[i] #pos srcBone.transform.position false
        format "  Positioned % at %\n" (getBipNeckName i) detectedNecks[i]
    )
)

-- Create rotation helpers for neck chain
neckHelpers = #()
for i = 1 to (myNeck.count - 1) do (
    src = getNodeByName myNeck[i]
    tgt = getNodeByName myNeck[i + 1]
    if src != undefined and tgt != undefined then (
        h = createSpineHelper src tgt #(1, true, 1)
        append neckHelpers h
    )
)

-- Apply rotations to each neck
for i = 1 to neckCount do (
    if i <= neckHelpers.count and bipNecks[i] != undefined then (
        applyRotation bipNecks[i] neckHelpers[i]
        format "  Rotated %\n" (getBipNeckName i)
    )
)

-- Scale each neck bone
for i = 1 to neckCount do (
    srcBone = getNodeByName detectedNecks[i]
    nextBoneName = if i < neckCount then detectedNecks[i + 1] else "head"
    nextBone = getNodeByName nextBoneName
    if srcBone != undefined and nextBone != undefined and bipNecks[i] != undefined then (
        scaleBone srcBone nextBone bipNecks[i]
        format "  Scaled % (distance to %)\n" (getBipNeckName i) nextBoneName
    )
)

-- Head: copy rotation directly from source, then flip 180 on local X
headRot = $head.transform.rotation
biped.setTransform $'Bip001 Head' #rotation headRot true
in coordsys local rotate $'Bip001 Head' (angleaxis 180 [1, 0, 0])
format "  Aligned Head\n"

--=====================================================================
-- 7. Left Arm Alignment
--=====================================================================
-- Position
biped.setTransform $'Bip001 L Clavicle' #pos $clavicle_l.transform.position false
biped.setTransform $'Bip001 L UpperArm' #pos $upperarm_l.transform.position false
biped.setTransform $'Bip001 L Forearm' #pos $lowerarm_l.transform.position false
biped.setTransform $'Bip001 L Hand' #pos $hand_l.transform.position false

-- Scale
scaleBone $clavicle_l $upperarm_l $'Bip001 L Clavicle'
scaleBone $upperarm_l $lowerarm_l $'Bip001 L UpperArm'
scaleBone $lowerarm_l $hand_l $'Bip001 L Forearm'
handLen = distance $hand_l.transform.position $middle_01_l.transform.position
biped.setTransform $'Bip001 L Hand' #scale [handLen, handLen, handLen] true

-- Create rotation helpers
lArmHelpers = #()
for i = 1 to (myLArm.count - 1) do (
    src = getNodeByName myLArm[i]
    tgt = getNodeByName myLArm[i + 1]
    h = createArmHelper src tgt
    append lArmHelpers h
)

-- Apply rotations
applyRotation $'Bip001 L Clavicle' lArmHelpers[1]
applyRotation $'Bip001 L UpperArm' lArmHelpers[2]
applyRotation $'Bip001 L Forearm' lArmHelpers[3]
lHandHelper = createArmHelper $hand_l $middle_01_l
applyRotation $'Bip001 L Hand' lHandHelper

--=====================================================================
-- 8. Right Arm Alignment
--=====================================================================
-- Position
biped.setTransform $'Bip001 R Clavicle' #pos $clavicle_r.transform.position false
biped.setTransform $'Bip001 R UpperArm' #pos $upperarm_r.transform.position false
biped.setTransform $'Bip001 R Forearm' #pos $lowerarm_r.transform.position false
biped.setTransform $'Bip001 R Hand' #pos $hand_r.transform.position false

-- Scale
scaleBone $clavicle_r $upperarm_r $'Bip001 R Clavicle'
scaleBone $upperarm_r $lowerarm_r $'Bip001 R UpperArm'
scaleBone $lowerarm_r $hand_r $'Bip001 R Forearm'
handLen = distance $hand_r.transform.position $middle_01_r.transform.position
biped.setTransform $'Bip001 R Hand' #scale [handLen, handLen, handLen] true

-- Create rotation helpers
rArmHelpers = #()
for i = 1 to (myRArm.count - 1) do (
    src = getNodeByName myRArm[i]
    tgt = getNodeByName myRArm[i + 1]
    h = createArmHelper src tgt
    append rArmHelpers h
)

-- Apply rotations
applyRotation $'Bip001 R Clavicle' rArmHelpers[1]
applyRotation $'Bip001 R UpperArm' rArmHelpers[2]
applyRotation $'Bip001 R Forearm' rArmHelpers[3]
rHandHelper = createArmHelper $hand_r $middle_01_r
applyRotation $'Bip001 R Hand' rHandHelper

--=====================================================================
-- 9. Right Fingers
--=====================================================================
biped.setTransform $'Bip001 R Finger0' #pos $thumb_01_r.transform.position false
scaleBone $thumb_01_r $thumb_02_r $'Bip001 R Finger0'
scaleBone $thumb_02_r $thumb_03_r $'Bip001 R Finger01'

rfingHelpers = #()
for i = 1 to (myRFing.count - 1) do (
    src = getNodeByName myRFing[i]
    tgt = getNodeByName myRFing[i + 1]
    h = createFingerHelper src tgt
    append rfingHelpers h
)

applyRotation $'Bip001 R Finger0' rfingHelpers[1]
applyRotation $'Bip001 R Finger01' rfingHelpers[2]

biped.setTransform $'Bip001 R Finger1' #pos $index_01_r.transform.position false
biped.setTransform $'Bip001 R Finger2' #pos $middle_01_r.transform.position false
biped.setTransform $'Bip001 R Finger3' #pos $ring_01_r.transform.position false
biped.setTransform $'Bip001 R Finger4' #pos $pinky_01_r.transform.position false

scaleBone $index_01_r $index_02_r $'Bip001 R Finger1'
scaleBone $index_02_r $index_03_r $'Bip001 R Finger11'
scaleBone $middle_01_r $middle_02_r $'Bip001 R Finger2'
scaleBone $middle_02_r $middle_03_r $'Bip001 R Finger21'
scaleBone $ring_01_r $ring_02_r $'Bip001 R Finger3'
scaleBone $ring_02_r $ring_03_r $'Bip001 R Finger31'
scaleBone $pinky_01_r $pinky_02_r $'Bip001 R Finger4'
scaleBone $pinky_02_r $pinky_03_r $'Bip001 R Finger41'

applyRotation $'Bip001 R Finger1' rfingHelpers[4]
applyRotation $'Bip001 R Finger11' rfingHelpers[5]
applyRotation $'Bip001 R Finger2' rfingHelpers[7]
applyRotation $'Bip001 R Finger21' rfingHelpers[8]
applyRotation $'Bip001 R Finger3' rfingHelpers[10]
applyRotation $'Bip001 R Finger31' rfingHelpers[11]
applyRotation $'Bip001 R Finger4' rfingHelpers[13]
applyRotation $'Bip001 R Finger41' rfingHelpers[14]

--=====================================================================
-- 10. Left Fingers
--=====================================================================
biped.setTransform $'Bip001 L Finger0' #pos $thumb_01_l.transform.position false
scaleBone $thumb_01_l $thumb_02_l $'Bip001 L Finger0'
scaleBone $thumb_02_l $thumb_03_l $'Bip001 L Finger01'

lfingHelpers = #()
for i = 1 to (myLFing.count - 1) do (
    src = getNodeByName myLFing[i]
    tgt = getNodeByName myLFing[i + 1]
    h = createFingerHelper src tgt
    append lfingHelpers h
)

applyRotation $'Bip001 L Finger0' lfingHelpers[1]
applyRotation $'Bip001 L Finger01' lfingHelpers[2]

biped.setTransform $'Bip001 L Finger1' #pos $index_01_l.transform.position false
biped.setTransform $'Bip001 L Finger2' #pos $middle_01_l.transform.position false
biped.setTransform $'Bip001 L Finger3' #pos $ring_01_l.transform.position false
biped.setTransform $'Bip001 L Finger4' #pos $pinky_01_l.transform.position false

scaleBone $index_01_l $index_02_l $'Bip001 L Finger1'
scaleBone $index_02_l $index_03_l $'Bip001 L Finger11'
scaleBone $middle_01_l $middle_02_l $'Bip001 L Finger2'
scaleBone $middle_02_l $middle_03_l $'Bip001 L Finger21'
scaleBone $ring_01_l $ring_02_l $'Bip001 L Finger3'
scaleBone $ring_02_l $ring_03_l $'Bip001 L Finger31'
scaleBone $pinky_01_l $pinky_02_l $'Bip001 L Finger4'
scaleBone $pinky_02_l $pinky_03_l $'Bip001 L Finger41'

applyRotation $'Bip001 L Finger1' lfingHelpers[4]
applyRotation $'Bip001 L Finger11' lfingHelpers[5]
applyRotation $'Bip001 L Finger2' lfingHelpers[7]
applyRotation $'Bip001 L Finger21' lfingHelpers[8]
applyRotation $'Bip001 L Finger3' lfingHelpers[10]
applyRotation $'Bip001 L Finger31' lfingHelpers[11]
applyRotation $'Bip001 L Finger4' lfingHelpers[13]
applyRotation $'Bip001 L Finger41' lfingHelpers[14]

--=====================================================================
-- 11. Leg Helper Function - Simple aim rotation for legs
--=====================================================================
fn createSimpleLegHelper srcBone tgtBone = (
    helperName = "myPoint" + srcBone.name
    p = point name:helperName centermarker:off axistripod:on cross:off box:on pos:srcBone.transform.position isSelected:off

    -- LookAt for legs - X axis aims down at target, Y axis forward (world -Y)
    p.rotation.controller = LookAt_Constraint()
    p.rotation.controller.appendTarget tgtBone 50.0
    p.rotation.controller.relative = false
    p.rotation.controller.target_axis = 0        -- X axis aims at target (down the leg)
    p.rotation.controller.target_axisFlip = false
    p.rotation.controller.upnode_world = true
    p.rotation.controller.StoUP_axis = 1         -- Y as source up axis
    p.rotation.controller.StoUP_axisFlip = true  -- Flip to point forward (-Y world)
    p.rotation.controller.upnode_axis = 1        -- World Y as up node reference

    -- Bake and remove constraint
    finalTM = p.transform
    p.rotation.controller = Euler_XYZ()
    p.transform = finalTM
    p
)

--=====================================================================
-- 12. Left Leg Alignment (Position -> Rotate -> Scale)
--=====================================================================
-- Position left thigh at exact source location
biped.setTransform $'Bip001 L Thigh' #pos $thigh_l.transform.position true

-- Create rotation helper and apply to thigh
lThighHelper = createSimpleLegHelper $thigh_l $calf_l
applyRotation $'Bip001 L Thigh' lThighHelper

-- Scale left thigh to reach calf
thighDis = distance $thigh_l.transform.position $calf_l.transform.position
biped.setTransform $'Bip001 L Thigh' #scale [thighDis, thighDis, thighDis] true

-- Position calf and create rotation helper
biped.setTransform $'Bip001 L Calf' #pos $calf_l.transform.position true
lCalfHelper = createSimpleLegHelper $calf_l $foot_l
applyRotation $'Bip001 L Calf' lCalfHelper

-- Scale calf to reach foot
calfDis = distance $calf_l.transform.position $foot_l.transform.position
biped.setTransform $'Bip001 L Calf' #scale [calfDis, calfDis, calfDis] true

-- Position foot
biped.setTransform $'Bip001 L Foot' #pos $foot_l.transform.position true

--=====================================================================
-- 13. Right Leg Alignment (Position -> Rotate -> Scale)
--=====================================================================
-- Position right thigh at exact source location
biped.setTransform $'Bip001 R Thigh' #pos $thigh_r.transform.position true

-- Create rotation helper and apply to thigh
rThighHelper = createSimpleLegHelper $thigh_r $calf_r
applyRotation $'Bip001 R Thigh' rThighHelper

-- Scale right thigh to reach calf
thighDis = distance $thigh_r.transform.position $calf_r.transform.position
biped.setTransform $'Bip001 R Thigh' #scale [thighDis, thighDis, thighDis] true

-- Position calf and create rotation helper
biped.setTransform $'Bip001 R Calf' #pos $calf_r.transform.position true
rCalfHelper = createSimpleLegHelper $calf_r $foot_r
applyRotation $'Bip001 R Calf' rCalfHelper

-- Scale calf to reach foot
calfDis = distance $calf_r.transform.position $foot_r.transform.position
biped.setTransform $'Bip001 R Calf' #scale [calfDis, calfDis, calfDis] true

-- Position foot
biped.setTransform $'Bip001 R Foot' #pos $foot_r.transform.position true



--=====================================================================
-- 15. Foot & Toe Alignment (from old working version)
--=====================================================================
select $ball_r
maxOps.cloneNodes $ball_r cloneType:#copy newNodes:&nnl
select nnl ; max unlink
$.pos.x = $foot_r.pos.x ; $.pos.y = $foot_r.pos.y
footDis = distance $ $foot_r ; delete $
select $ball_r
maxOps.cloneNodes $ball_r cloneType:#copy newNodes:&nnl
select nnl ; max unlink
$.pos.x = $foot_r.pos.x ; $.pos.z = $foot_r.pos.z
footLng = distance $ $foot_r ; delete $

footHeight = footDis * 1.5
biped.setTransform $'Bip001 R Foot' #scale [footHeight, footLng+(footLng*0.3), footHeight] true
biped.setTransform $'Bip001 L Foot' #scale [footHeight, footLng+(footLng*0.3), footHeight] true
biped.setTransform $'Bip001 R Toe0' #scale [footDis,1,footDis] true
biped.setTransform $'Bip001 L Toe0' #scale [footDis,1,footDis] true

--=====================================================================
-- 14. Exit figure mode
--=====================================================================
$'Bip001'.controller.figureMode = false


clearSelection()

--=====================================================================
-- 15. Constraint Functions
--=====================================================================
fn OrientationConstraint node target = (
    node.rotation.controller = Orientation_Constraint()
    node.rotation.controller.appendTarget target 50.0
    node.rotation.controller.relative = on
)

fn PositionConstraint node target = (
    node.position.controller = Position_Constraint()
    node.position.controller.appendTarget target 50.0
    node.position.controller.relative = on
)

--=====================================================================
-- 16. Apply Constraints - Spine & Head (Dynamic)
--=====================================================================
PositionConstraint $pelvis $'Bip001'
OrientationConstraint $pelvis $'Bip001'

-- Dynamic spine constraints
for i = 1 to spineCount do (
    srcBone = getNodeByName detectedSpines[i]
    bipBone = getNodeByName (getBipSpineName i)
    if srcBone != undefined and bipBone != undefined then (
        PositionConstraint srcBone bipBone
        OrientationConstraint srcBone bipBone
        format "  Constrained % -> %\n" detectedSpines[i] (getBipSpineName i)
    )
)

-- Dynamic neck constraints
for i = 1 to neckCount do (
    srcBone = getNodeByName detectedNecks[i]
    bipBone = getNodeByName (getBipNeckName i)
    if srcBone != undefined and bipBone != undefined then (
        PositionConstraint srcBone bipBone
        OrientationConstraint srcBone bipBone
        format "  Constrained % -> %\n" detectedNecks[i] (getBipNeckName i)
    )
)

PositionConstraint $head $'Bip001 Head'
OrientationConstraint $head $'Bip001 Head'

--=====================================================================
-- 17. Apply Constraints - Left Arm
--=====================================================================
PositionConstraint $clavicle_l $'Bip001 L Clavicle'
OrientationConstraint $clavicle_l $'Bip001 L Clavicle'

PositionConstraint $upperarm_l $'Bip001 L UpperArm'
OrientationConstraint $upperarm_l $'Bip001 L UpperArm'

PositionConstraint $lowerarm_l $'Bip001 L Forearm'
OrientationConstraint $lowerarm_l $'Bip001 L Forearm'

PositionConstraint $hand_l $'Bip001 L Hand'
OrientationConstraint $hand_l $'Bip001 L Hand'

if $upperarm_twist_01_l != undefined do
    OrientationConstraint $upperarm_twist_01_l $'Bip001 LUpArmTwist'
if $lowerarm_twist_01_l != undefined do
    OrientationConstraint $lowerarm_twist_01_l $'Bip001 L ForeTwist'

--=====================================================================
-- 18. Apply Constraints - Right Arm
--=====================================================================
PositionConstraint $clavicle_r $'Bip001 R Clavicle'
OrientationConstraint $clavicle_r $'Bip001 R Clavicle'

PositionConstraint $upperarm_r $'Bip001 R UpperArm'
OrientationConstraint $upperarm_r $'Bip001 R UpperArm'

PositionConstraint $lowerarm_r $'Bip001 R Forearm'
OrientationConstraint $lowerarm_r $'Bip001 R Forearm'

PositionConstraint $hand_r $'Bip001 R Hand'
OrientationConstraint $hand_r $'Bip001 R Hand'

if $upperarm_twist_01_r != undefined do
    OrientationConstraint $upperarm_twist_01_r $'Bip001 RUpArmTwist'
if $lowerarm_twist_01_r != undefined do
    OrientationConstraint $lowerarm_twist_01_r $'Bip001 R ForeTwist'

--=====================================================================
-- 19. Apply Constraints - Left Leg
--=====================================================================
PositionConstraint $thigh_l $'Bip001 L Thigh'
OrientationConstraint $thigh_l $'Bip001 L Thigh'

PositionConstraint $calf_l $'Bip001 L Calf'
OrientationConstraint $calf_l $'Bip001 L Calf'

PositionConstraint $foot_l $'Bip001 L Foot'
OrientationConstraint $foot_l $'Bip001 L Foot'

if $ball_l != undefined do (
    PositionConstraint $ball_l $'Bip001 L Toe0'
    OrientationConstraint $ball_l $'Bip001 L Toe0'
)

if $thigh_twist_01_l != undefined do
    OrientationConstraint $thigh_twist_01_l $'Bip001 LThighTwist'
if $calf_twist_01_l != undefined do
    OrientationConstraint $calf_twist_01_l $'Bip001 LCalfTwist'

--=====================================================================
-- 20. Apply Constraints - Right Leg
--=====================================================================
PositionConstraint $thigh_r $'Bip001 R Thigh'
OrientationConstraint $thigh_r $'Bip001 R Thigh'

PositionConstraint $calf_r $'Bip001 R Calf'
OrientationConstraint $calf_r $'Bip001 R Calf'

PositionConstraint $foot_r $'Bip001 R Foot'
OrientationConstraint $foot_r $'Bip001 R Foot'

if $ball_r != undefined do (
    PositionConstraint $ball_r $'Bip001 R Toe0'
    OrientationConstraint $ball_r $'Bip001 R Toe0'
)

if $thigh_twist_01_r != undefined do
    OrientationConstraint $thigh_twist_01_r $'Bip001 RThighTwist'
if $calf_twist_01_r != undefined do
    OrientationConstraint $calf_twist_01_r $'Bip001 RCalfTwist'

--=====================================================================
-- 21. Apply Constraints - Right Fingers
--=====================================================================
OrientationConstraint $thumb_01_r $'Bip001 R Finger0'
OrientationConstraint $thumb_02_r $'Bip001 R Finger01'
OrientationConstraint $thumb_03_r $'Bip001 R Finger02'

OrientationConstraint $index_01_r $'Bip001 R Finger1'
OrientationConstraint $index_02_r $'Bip001 R Finger11'
OrientationConstraint $index_03_r $'Bip001 R Finger12'

OrientationConstraint $middle_01_r $'Bip001 R Finger2'
OrientationConstraint $middle_02_r $'Bip001 R Finger21'
OrientationConstraint $middle_03_r $'Bip001 R Finger22'

OrientationConstraint $ring_01_r $'Bip001 R Finger3'
OrientationConstraint $ring_02_r $'Bip001 R Finger31'
OrientationConstraint $ring_03_r $'Bip001 R Finger32'

OrientationConstraint $pinky_01_r $'Bip001 R Finger4'
OrientationConstraint $pinky_02_r $'Bip001 R Finger41'
OrientationConstraint $pinky_03_r $'Bip001 R Finger42'

--=====================================================================
-- 22. Apply Constraints - Left Fingers
--=====================================================================
OrientationConstraint $thumb_01_l $'Bip001 L Finger0'
OrientationConstraint $thumb_02_l $'Bip001 L Finger01'
OrientationConstraint $thumb_03_l $'Bip001 L Finger02'

OrientationConstraint $index_01_l $'Bip001 L Finger1'
OrientationConstraint $index_02_l $'Bip001 L Finger11'
OrientationConstraint $index_03_l $'Bip001 L Finger12'

OrientationConstraint $middle_01_l $'Bip001 L Finger2'
OrientationConstraint $middle_02_l $'Bip001 L Finger21'
OrientationConstraint $middle_03_l $'Bip001 L Finger22'

OrientationConstraint $ring_01_l $'Bip001 L Finger3'
OrientationConstraint $ring_02_l $'Bip001 L Finger31'
OrientationConstraint $ring_03_l $'Bip001 L Finger32'

OrientationConstraint $pinky_01_l $'Bip001 L Finger4'
OrientationConstraint $pinky_02_l $'Bip001 L Finger41'
OrientationConstraint $pinky_03_l $'Bip001 L Finger42'

--=====================================================================
-- 23. Cleanup
--=====================================================================
helpersToDelete = for obj in helpers where matchPattern obj.name pattern:"myPoint*" collect obj
delete helpersToDelete

clearSelection()
print "Biped alignment complete! All joints aligned using matrix math."
