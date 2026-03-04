macroScript ToggleTrackViewEditor
category:"CloneTools"
tooltip:"Toggle Dope Sheet / FCurve Editor"
(
    global gTrackViewMode
    if gTrackViewMode == #fcurve then
    (
        macros.run "Track View" "SwitchDopeSheetEditor"
        gTrackViewMode = #dopesheet
    )
    else
    (
        macros.run "Track View" "SwitchToFCurveEditor"
        gTrackViewMode = #fcurve
    )
)