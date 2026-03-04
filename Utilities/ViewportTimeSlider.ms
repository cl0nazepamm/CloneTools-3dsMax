-- ViewportTimeSlider_NoJump.ms
tool viewportTimeSlider
(
    local lastMouseX
    local currentFloatFrame
    local minFrame, maxFrame
    local pixelsPerFrame = 10.0 
    local dragging = false
    local snapToKeys = true
    local snapLockModifier = #ctrl 
    local snapKeyFrames = #()
    local snapThreshold = 2.0 -- Only snaps if you are within 2 frames of a key

    fn collectControllerKeyFrames anim frames =
    (
        if anim != undefined do
        (
            local keyCount = 0
            try (keyCount = numKeys anim) catch ()
            if keyCount > 0 do
            (
                for k = 1 to keyCount do
                (
                    local kt = undefined
                    try (kt = getKeyTime anim k) catch ()
                    if kt != undefined do append frames (kt.frame as float)
                )
            )

            local subCount = 0
            try (subCount = numSubs anim) catch ()
            if subCount > 0 do
            (
                for i = 1 to subCount do
                (
                    local subAnim = undefined
                    try (subAnim = getSubAnim anim i) catch ()
                    if subAnim != undefined do collectControllerKeyFrames subAnim frames
                )
            )
        )
        frames
    )

    fn getSelectedKeyFrames =
    (
        local frames = #()
        if selection.count == 0 then return frames

        for n in selection do collectControllerKeyFrames n frames

        sort frames
        local uniqueFrames = #()
        local lastFrame = undefined
        for f in frames do
        (
            if f != lastFrame do
            (
                append uniqueFrames f
                lastFrame = f
            )
        )
        uniqueFrames
    )

    -- MODIFIED: Added a threshold so it only snaps when you are close to a key
    fn snapFrameToNearest frame frames =
    (
        if frames.count == 0 then return frame

        local nearest = frame -- Default to normal smooth frame to prevent jumping
        local bestDist = snapThreshold 
        
        for f in frames do
        (
            local d = abs (frame - f)
            if d <= bestDist do
            (
                bestDist = d
                nearest = f
            )
        )
        nearest
    )

    fn isSnapLockPressed =
    (
        case snapLockModifier of
        (
            #shift: keyboard.shiftPressed
            #ctrl: keyboard.controlPressed
            #alt: keyboard.altPressed
            default: false
        )
    )

    on mousePoint clickno do
    (
        if clickno == 1 then 
        (
            minFrame = animationRange.start.frame as float
            maxFrame = animationRange.end.frame as float
            
            lastMouseX = mouse.screenpos.x
            currentFloatFrame = sliderTime.frame as float 
            
            snapKeyFrames = if snapToKeys then getSelectedKeyFrames() else #()
            dragging = true
        )
        else if clickno == 2 then 
        (
            dragging = false
            #stop
        )
    )

    on mouseMove clickno do
    (
        if dragging and lastMouseX != undefined do
        (
            local currentMouseX = mouse.screenpos.x
            local deltaX = currentMouseX - lastMouseX
            lastMouseX = currentMouseX 
            
            local speedMult = 1.0
            if keyboard.shiftPressed do speedMult = 4.0 
            if keyboard.altPressed do speedMult = 0.2   

            local frameDelta = (deltaX / pixelsPerFrame) * speedMult
            currentFloatFrame += frameDelta
            
            currentFloatFrame = amin maxFrame (amax minFrame currentFloatFrame)
            
            local outputFrame = currentFloatFrame
            
            -- Will only snap if a keyframe is inside the 'snapThreshold' radius
            if snapToKeys and snapKeyFrames.count > 0 and isSnapLockPressed() do
            (
                outputFrame = snapFrameToNearest outputFrame snapKeyFrames
            )

            -- Added * 1f to ensure Max treats it perfectly as a Time value
            sliderTime = outputFrame * 1f
        )
    )

    on mouseAbort clickno do
    (
        dragging = false
        #stop
    )
)

startTool viewportTimeSlider