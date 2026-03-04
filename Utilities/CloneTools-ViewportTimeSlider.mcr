macroScript CloneToolsViewportTimeSlider
category: "CloneTools"
tooltip: "Viewport Time Slider"
buttonText: "Time Slider"
(
    tool cloneToolsViewportTimeSliderTool
    (
        local lastMouseX
        local currentFloatFrame
        local minFrame, maxFrame
        local pixelsPerFrame = 10.0
        local dragging = false
        local snapToKeys = true
        local snapLockModifier = #ctrl -- hold Ctrl to lock to nearest key
        local snapKeyFrames = #()

        fn collectControllerKeyFrames ctrl frames =
        (
            if ctrl == undefined then return frames

            local keyCount = 0
            try keyCount = numKeys ctrl catch keyCount = 0
            if keyCount > 0 do
            (
                for k = 1 to keyCount do
                (
                    local keyTime = undefined
                    try keyTime = getKeyTime ctrl k catch keyTime = undefined
                    if keyTime != undefined do append frames (keyTime.frame as float)
                )
            )

            local subCount = 0
            try subCount = numSubs ctrl catch subCount = 0
            if subCount > 0 do
            (
                for i = 1 to subCount do
                (
                    local subAnim = undefined
                    local subCtrl = undefined
                    try subAnim = getSubAnim ctrl i catch subAnim = undefined
                    if subAnim != undefined do
                    (
                        try subCtrl = subAnim.controller catch subCtrl = undefined
                        if subCtrl != undefined do frames = collectControllerKeyFrames subCtrl frames
                    )
                )
            )

            frames
        )

        fn getSelectedKeyFrames =
        (
            local frames = #()
            if selection.count == 0 then return frames

            for n in selection do
            (
                local nodeCtrl = undefined
                try nodeCtrl = n.controller catch nodeCtrl = undefined
                if nodeCtrl != undefined do frames = collectControllerKeyFrames nodeCtrl frames

                local nodeKeyCount = 0
                try nodeKeyCount = numKeys n catch nodeKeyCount = 0
                if nodeKeyCount > 0 do
                (
                    for k = 1 to nodeKeyCount do
                    (
                        local kt = undefined
                        try kt = getKeyTime n k catch kt = undefined
                        if kt != undefined do append frames (kt.frame as float)
                    )
                )
            )

            sort frames
            local uniqueFrames = #()
            for f in frames do
            (
                if findItem uniqueFrames f == 0 do append uniqueFrames f
            )
            uniqueFrames
        )

        fn snapFrameToNearest frame frames =
        (
            if frames.count == 0 then return frame

            local nearest = frames[1]
            local bestDist = abs (frame - nearest)
            for i = 2 to frames.count do
            (
                local d = abs (frame - frames[i])
                if d < bestDist do
                (
                    bestDist = d
                    nearest = frames[i]
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
                if snapToKeys and snapKeyFrames.count > 0 and isSnapLockPressed() do
                    outputFrame = snapFrameToNearest outputFrame snapKeyFrames

                sliderTime = outputFrame
            )
        )

        on mouseAbort clickno do
        (
            dragging = false
            #stop
        )
    )

    startTool cloneToolsViewportTimeSliderTool
)
