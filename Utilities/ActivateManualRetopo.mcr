--simple script to activate manual retopology. Literally made it bcuz 3dsmax ribbon is ASS.
macroScript ActivateManualRetopo
category: "CloneTools"
tooltip: "ActivateManualRetopo"
buttonText: "ActivateManualRetopo"

(	
	macros.run "PolyTools" "EmptyObject"
	macros.run "PolyTools" "PolyDrawTypeSurface"
	macros.run "Ribbon - Modeling" "PolyDrawPickButton"
)