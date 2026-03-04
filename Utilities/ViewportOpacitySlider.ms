-- ViewportOpacitySlider.ms
tool viewportOpacitySlider
(
    local lastMouseX
    local currentOpacity
    local retopoMaterial
    local pixelsPerOpacity = 8.0
    local dragging = false

    fn findRetopoMaterial =
    (
        local mats = #()
        try (mats = getClassInstances Standardmaterial) catch (mats = #())

        for m in mats do
        (
            if m != undefined and m.name == "m_retopo" do return m
        )
        undefined
    )

    on mousePoint clickno do
    (
        if clickno == 1 then
        (
            retopoMaterial = findRetopoMaterial()
            if retopoMaterial == undefined then
            (
                messageBox "Standard material named \"m_retopo\" was not found." title:"Viewport Opacity Slider"
                dragging = false
                #stop
            )

            lastMouseX = mouse.screenpos.x
            currentOpacity = retopoMaterial.opacity as float
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
        if dragging and lastMouseX != undefined and retopoMaterial != undefined do
        (
            local currentMouseX = mouse.screenpos.x
            local deltaX = currentMouseX - lastMouseX
            lastMouseX = currentMouseX

            local speedMult = 1.0
            if keyboard.shiftPressed do speedMult = 4.0
            if keyboard.altPressed do speedMult = 0.2

            local opacityDelta = (deltaX / pixelsPerOpacity) * speedMult
            currentOpacity += opacityDelta
            currentOpacity = amin 100.0 (amax 0.0 currentOpacity)

            retopoMaterial.opacity = currentOpacity
            completeRedraw()
        )
    )

    on mouseAbort clickno do
    (
        dragging = false
        #stop
    )
)

startTool viewportOpacitySlider
