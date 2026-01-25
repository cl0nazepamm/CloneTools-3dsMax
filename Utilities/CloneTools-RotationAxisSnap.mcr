macroScript RotationAxisSnap
category: "CloneTools"
tooltip: "Switch active viewport to the view closely aligned to the screen axis"
(
	global sType;
	
	vpType = viewport.getType()
	
	if (vpType==#view_left or vpType==#view_right or vpType==#view_front or vpType==#view_back or vpType==#view_bottom or vpType==#view_top) 
	then(
			try(
				viewport.setType sType
				actionMan.executeAction 0 "40228"  -- Views: Restore Active View
			)catch()
	)	
	else (
			temp = viewport.getTM() as EulerAngles
			
			sType = viewport.getType()
			actionMan.executeAction 0 "40227"  -- Views: Save Active View
			
			case of
				(
					(45<=temp.y and temp.y<=135): viewport.setType #view_left
					(-45>=temp.y and temp.y>=-135): viewport.setType #view_right
					((-45>=temp.x and temp.x>=-135) and (-45<=temp.y and temp.y<=45)): viewport.setType #view_front
					((45<=temp.x and temp.x<=135) and (-45<=temp.y and temp.y<=45)): viewport.setType #view_back
					((135<=temp.x and temp.x<=180) or (-135>=temp.x and temp.x>=-180)): viewport.setType #view_bottom
					default: viewport.setType #view_top
				)	 
			max zoomext sel
	)
	completeredraw()
)
