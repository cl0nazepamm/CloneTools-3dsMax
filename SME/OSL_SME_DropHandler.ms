-- cs_sme_drop v1.2
-- by Changsoo Eun
-- www.changsooeun.com
(
	local maxver = (maxversion())
	if maxver.count > 7 and ( maxver[8] > 2024 or (maxver[8] == 2024 and maxver[5] > 0)) then (
		fn cs_sme_drop test urls pos = (
			if not test then (			
				for f in urls do (
					-- Set this to true if you want OSL UberBitmap
					local useOSL = true
					local amap = (bitmaptexture())
					amap.filename = f					
					if useOSL then 
					(
						amap = (osl_UberBitmap2b())
						amap.filename = f		
					)
					else
					(
						if Corona != undefined and ((classof renderers.current) == Corona) then (
							amap = (CoronaBitmap())
							amap.filename = f
						)
						if vray != undefined and (matchpattern (renderers.current as string) pattern:"*v_ray*") then (
							amap = (vrayhdri())
							amap.HDRIMapName = f
						)	
						if (matchpattern (renderers.current as string) pattern:"*FStorm*") then (
							amap = (FStormBitmap())
							amap.filename = f
						)	
						if (matchpattern (renderers.current as string) pattern:"*octane*") then (
							amap = (RGB_image())
							amap.filename = f
						)		
						if (matchpattern (renderers.current as string) pattern:"*redshift*") then (
							amap = (RS_Bitmap())
							amap.tex0_filename = f
						)		
						if Arnold != undefined and ((classof renderers.current) == Arnold) then (
							amap = (ai_image())
							amap.filename = f
						)			
					)
					if useOSL then (
						pos.x += 100
					)
					else(
						pos.y += 100
					)
					amap.name = (getFilenameFile f)
					(sme.getview sme.activeview).createnode amap pos
				)
			)
			true
		)
		sme.fileDropCallback = cs_sme_drop
	)
	else (
		messagebox "3dssMax 2024.1+ is required"
	)
)