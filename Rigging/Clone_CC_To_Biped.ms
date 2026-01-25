-- Creates biped from CC base rig (For unreal skeletons use Clone_PowerUE_BIPED.ms)
 -- Clone 2025
 
 -- 1. Create the biped

bipObj = biped.createNew 200 -90 [0,0,0] arms:true neckLinks:2 \ 
spineLinks:3  fingers:5 fingerLinks:3 toes:1 forearmTwistLinks:2 \
upperarmtwistlinks:2 thightwistlinks:2 calftwistlinks:2 \
toelinks:1

$'Bip001'.controller.figureMode = true
global myRoot = #("CC_Base_BoneRoot","CC_Base_Hip","CC_Base_Pelvis")
global mySpine = #("CC_Base_Waist", "CC_Base_Spine01", "CC_Base_Spine02","CC_Base_NeckTwist01","CC_Base_NeckTwist02")
global myNeck = #("CC_Base_NeckTwist01", "CC_Base_NeckTwist02", "CC_Base_Head")
global myLArm = #("CC_Base_L_Clavicle", "CC_Base_L_Upperarm", "CC_Base_L_Forearm", "CC_Base_L_Hand", "CC_Base_L_Mid1")
global myRArm = #("CC_Base_R_Clavicle", "CC_Base_R_UpperarmTwist01", "CC_Base_R_Forearm", "CC_Base_R_Hand", "CC_Base_R_Mid1")
global myRFing = #("CC_Base_R_Thumb1","CC_Base_R_Thumb2","CC_Base_R_Thumb3","CC_Base_R_Index1","CC_Base_R_Index2","CC_Base_R_Index3","CC_Base_R_Mid1","CC_Base_R_Mid2","CC_Base_R_Mid3","CC_Base_R_Ring1","CC_Base_R_Ring2","CC_Base_R_Ring3","CC_Base_R_Pinky1","CC_Base_R_Pinky2","CC_Base_R_Pinky3")
global myLFing = #("CC_Base_L_Thumb1","CC_Base_L_Thumb2","CC_Base_L_Thumb3","CC_Base_L_Index1","CC_Base_L_Index2","CC_Base_L_Index3","CC_Base_L_Mid1","CC_Base_L_Mid2","CC_Base_L_Mid3","CC_Base_L_Ring1","CC_Base_L_Ring2","CC_Base_L_Ring3","CC_Base_L_Pinky1","CC_Base_L_Pinky2","CC_Base_L_Pinky3")
global myLThgh = #("CC_Base_L_Thigh","CC_Base_L_Calf","CC_Base_L_Foot")
global myRThgh = #("CC_Base_R_Thigh","CC_Base_R_Calf","CC_Base_R_Foot")


biped.setTransform $Bip001 #pos $CC_Base_Hip.transform.position false
fn mydisfunc first end trgt =
(
dis1 = (distance first end)
biped.setTransform trgt #scale ([dis1,dis1,dis1]) True 
)

mydisfunc $CC_Base_Waist $CC_Base_Spine01 $'Bip001 Spine'
mydisfunc $CC_Base_Spine01 $CC_Base_Spine02 $'Bip001 Spine1'
mydisfunc $CC_Base_Spine02 $CC_Base_NeckTwist01 $'Bip001 Spine2'
mydisfunc $CC_Base_L_Thigh $CC_Base_R_Thigh	$'Bip001 Pelvis'

biped.setTransform $'Bip001 Spine' #pos $CC_Base_Waist.transform.position false






function myHelpRot inPos inTrg inUpAx =
	(
	-- create  point helper for alignment
	myName = ("myPoint"+inPos.name)
	myObj = Point name:myName centermarker:off axistripod:on cross:off box:on pos:inPos.position isSelected:off
	-- set constraint
	myObj.rotation.controller = LookAt_Constraint ()
	-- set target
	myObj.rotation.controller.appendTarget inTrg 50.0
	-- set initial offset
	myObj.rotation.controller.relative = false
	-- set target axis ( axis 0=x 1=y 2=z)
	myObj.rotation.controller.target_axis = 0
	myObj.rotation.controller.target_axisFlip = false
	-- set up world
	myObj.rotation.controller.upnode_world = true
	-- set up node axis ( axis 0=x 1=y 2=z)
	myObj.rotation.controller.StoUP_axis = inUpAx[1]
	myObj.rotation.controller.StoUP_axisFlip = inUpAx[2]
	-- set upnode axis alignment
	myObj.rotation.controller.upnode_axis = inUpAx[3]
	-- get point`s world matrix
	myMatrix = myObj.transform
	myObj.rotation.controller = Euler_XYZ()
	myObj.transform = myMatrix
	)

-- set spine
	
for i = 1 to mySpine.count-1 do (
	myPos = getNodeByName mySpine[i]
	myTarget = getNodeByName (mySpine[i+1])
	myUpAxis = #(1,true,1)
	myHelpRot myPos myTarget myUpAxis
	)

	
	
	
function myRotation Src Tgt =
	(
	myRot = (in coordsys Src Tgt.rotation as eulerAngles) as angleAxis
	in coordsys Src rotate Src myRot
	)
myRotation $'Bip001 Spine' $'myPointCC_Base_Waist'
myRotation $'Bip001 Spine1' $'myPointCC_Base_Spine01'
myRotation $'Bip001 Spine2' $'myPointCC_Base_Spine02'
	

	
biped.setTransform $'Bip001 Neck' #pos $CC_Base_NeckTwist01.transform.position false
	
	
mydisfunc $CC_Base_NeckTwist01 $CC_Base_NeckTwist02 $'Bip001 Neck'
mydisfunc $CC_Base_NeckTwist02 $CC_Base_Head $'Bip001 Neck1'
	
-- set neck
	
for i = 1 to myNeck.count-1 do (
	myPos = getNodeByName myNeck[i]
	myTarget = getNodeByName (myNeck[i+1])
	myUpAxis = #(1,true,1)
	myHelpRot myPos myTarget myUpAxis
	)

myRotation $'Bip001 Neck' $myPointCC_Base_NeckTwist01
myRotation $'Bip001 Neck1' $myPointCC_Base_NeckTwist02
	
	

biped.setTransform $'Bip001 L Clavicle' #pos $CC_Base_L_Clavicle.transform.position false
		
mydisfunc $CC_Base_L_Clavicle $CC_Base_L_Upperarm $'Bip001 L Clavicle'
mydisfunc $CC_Base_L_Upperarm $CC_Base_L_Forearm $'Bip001 L UpperArm'
mydisfunc $CC_Base_L_Forearm $CC_Base_L_Hand $'Bip001 L Forearm'
mydisfunc $CC_Base_L_Hand $CC_Base_L_Mid1 $'Bip001 L Hand'

 
	
-- set L Arm
	
function myHelpArmRot inPos inTrg = 
(
myName = ("myPoint"+inPos.name)
myObj = Point name:myName centermarker:off axistripod:on cross:off box:on pos:inPos.position isSelected:off
myObj.rotation.controller = LookAt_Constraint ()
myObj.rotation.controller.appendTarget inTrg 50.0
p = myObj.transform
myObj.rotation.controller = Euler_XYZ()
myObj.transform = p
)
	
for i = 1 to myLArm.count-1 do (
	myPos = getNodeByName myLArm[i]
	myTarget = getNodeByName (myLArm[i+1])
	myHelpArmRot myPos myTarget  
	)

myRotation $'Bip001 L Clavicle' $myPointCC_Base_L_Clavicle	
myRotation $'Bip001 L UpperArm' $myPointCC_Base_L_Upperarm
myRotation $'Bip001 L Forearm' 	$myPointCC_Base_L_Forearm
	
biped.setTransform $'Bip001 R Clavicle' #pos $CC_Base_R_Clavicle.transform.position false
		
mydisfunc $CC_Base_R_Clavicle $CC_Base_R_Upperarm $'Bip001 R Clavicle'
mydisfunc $CC_Base_R_Upperarm $CC_Base_R_Forearm $'Bip001 R UpperArm'
mydisfunc $CC_Base_R_Forearm $CC_Base_R_Hand $'Bip001 R Forearm'
mydisfunc $CC_Base_R_Hand $CC_Base_R_Mid1 $'Bip001 R Hand'
	
function myHelpRArmRot inPos inTrg = 
(
myName = ("myPoint"+inPos.name)
myObj = Point name:myName centermarker:off axistripod:on cross:off box:on pos:inPos.position isSelected:off
myObj.rotation.controller = LookAt_Constraint ()
myObj.rotation.controller.appendTarget inTrg 50.0
--myObj.rotation.controller.target_axisFlip = on
myObj.rotation.controller.target_axis = 0
myObj.rotation.controller.upnode_axis = 2
myObj.rotation.controller.StoUP_axis = 2
myObj.rotation.controller.upnode_ctrl = 0
p = myObj.transform
myObj.rotation.controller = Euler_XYZ()
myObj.transform = p
)


for i = 1 to myRArm.count-1 do (
	myPos = getNodeByName myRArm[i]
	myTarget = getNodeByName (myRArm[i+1])
	myHelpRArmRot myPos myTarget  
	)
	
	
myRotation $'Bip001 R Clavicle' $myPointCC_Base_R_Clavicle	
myRotation $'Bip001 R UpperArm' $myPointCC_Base_R_UpperarmTwist01
myRotation $'Bip001 R Forearm' 	$myPointCC_Base_R_Forearm

mydisfunc $CC_Base_R_Thumb1 $CC_Base_R_Thumb2 $'Bip001 R Finger0'	
mydisfunc $CC_Base_R_Thumb2 $CC_Base_R_Thumb3 $'Bip001 R Finger01'	
	
	
biped.setTransform $'Bip001 R Finger0' #pos $CC_Base_R_Thumb1.transform.position false

	
function myHelpRFingRot inPos inTrg = 
(
myName = ("myPoint"+inPos.name)
myObj = Point name:myName centermarker:off axistripod:on cross:off box:on pos:inPos.position isSelected:off
myObj.rotation.controller = LookAt_Constraint ()
myObj.rotation.controller.appendTarget inTrg 50.0
myObj.rotation.controller.relative = false
myObj.rotation.controller.target_axis = 0
myObj.rotation.controller.target_axisFlip = false
myObj.rotation.controller.upnode_world = true
myObj.rotation.controller.StoUp_axis = 1
myObj.rotation.controller.StoUp_axisFlip = true
myObj.rotation.controller.upnode_axis = 2
p = myObj.transform
myObj.rotation.controller = Euler_XYZ()
myObj.transform = p
)


for i = 1 to myRFing.count-1 do (
	myPos = getNodeByName myRFing[i]
	myTarget = getNodeByName (myRFing[i+1])
	myHelpRFingRot myPos myTarget  
	)
myRotation $'Bip001 R Finger0' $myPointCC_Base_R_Thumb1	
myRotation $'Bip001 R Finger01' $myPointCC_Base_R_Thumb2
	
biped.setTransform $'Bip001 R Finger1' #pos $CC_Base_R_Index1.transform.position false
biped.setTransform $'Bip001 R Finger2' #pos $CC_Base_R_Mid1.transform.position false
biped.setTransform $'Bip001 R Finger3' #pos $CC_Base_R_Ring1.transform.position false
biped.setTransform $'Bip001 R Finger4' #pos $CC_Base_R_Pinky1.transform.position false
	
	
mydisfunc $CC_Base_R_Index1 $CC_Base_R_Index2 $'Bip001 R Finger1'	
mydisfunc $CC_Base_R_Index2 $CC_Base_R_Index3 $'Bip001 R Finger11'	
mydisfunc $CC_Base_R_Mid1 $CC_Base_R_Mid2 $'Bip001 R Finger2'	
mydisfunc $CC_Base_R_Mid2 $CC_Base_R_Mid3 $'Bip001 R Finger21'
mydisfunc $CC_Base_R_Ring1 $CC_Base_R_Ring2 $'Bip001 R Finger3'
mydisfunc $CC_Base_R_Ring2 $CC_Base_R_Ring3 $'Bip001 R Finger31'
mydisfunc $CC_Base_R_Pinky1 $CC_Base_R_Pinky2 $'Bip001 R Finger4'
mydisfunc $CC_Base_R_Pinky2 $CC_Base_R_Pinky3 $'Bip001 R Finger41'

myRotation $'Bip001 R Finger1' $myPointCC_Base_R_Index1
myRotation $'Bip001 R Finger11' $myPointCC_Base_R_Index2
myRotation $'Bip001 R Finger2' $myPointCC_Base_R_Mid1
myRotation $'Bip001 R Finger3' $myPointCC_Base_R_Ring1
myRotation $'Bip001 R Finger3' $myPointCC_Base_R_Pinky1
myRotation $'Bip001 R Finger21' $myPointCC_Base_R_Mid2
myRotation $'Bip001 R Finger31' $myPointCC_Base_R_Ring2
myRotation $'Bip001 R Finger41' $myPointCC_Base_R_Pinky2

delete $'myPoint*'

biped.createCopyCollection $'Bip001 R Clavicle'.controller "CC"
select $'Bip001 R Clavicle'
actionMan.executeAction 0 "40180"  -- Selection: Select Children

pc = biped.copyposture ($bip001.controller) #posture false false false
biped.pasteposture ($bip001.controller) #posture true pc



-- Leg alignment: position Thigh/Calf/Foot to match CC (like old UE script)
biped.setTransform $'Bip001 L Thigh' #pos $CC_Base_L_Thigh.transform.position false
biped.setTransform $'Bip001 L Calf' #pos $CC_Base_L_Calf.transform.position false
biped.setTransform $'Bip001 L Foot' #pos $CC_Base_L_Foot.transform.position false
biped.setTransform $'Bip001 R Thigh' #pos $CC_Base_R_Thigh.transform.position false
biped.setTransform $'Bip001 R Calf' #pos $CC_Base_R_Calf.transform.position false
biped.setTransform $'Bip001 R Foot' #pos $CC_Base_R_Foot.transform.position false

thighdis = distance $CC_Base_L_Thigh $CC_Base_L_Calf
biped.setTransform $'Bip001 L Thigh' #scale ([thighdis+(thighdis*0.047),thighdis,thighdis]) True

thighdis = distance $CC_Base_R_Thigh $CC_Base_R_Calf
biped.setTransform $'Bip001 R Thigh' #scale ([thighdis+(thighdis*0.047),thighdis,thighdis]) True

thighdis = distance  $CC_Base_L_Calf $CC_Base_L_Foot
biped.setTransform $'Bip001 L Calf' #scale ([thighdis,thighdis,thighdis]) True

thighdis = distance  $CC_Base_R_Calf $CC_Base_R_Foot
biped.setTransform $'Bip001 R Calf' #scale ([thighdis,thighdis,thighdis]) True
rotate $'Bip001 L Thigh' (angleaxis 8 [1,0,0])
rotate $'Bip001 L Calf' (angleaxis 12 [0,0,1])
rotate $'Bip001 R Thigh' (angleaxis 8 [1,0,0])
rotate $'Bip001 R Calf' (angleaxis 12 [0,0,1])
select $CC_Base_R_ToeBase

maxOps.cloneNodes $CC_Base_R_ToeBase cloneType:#copy newNodes:&nnl
select nnl
max unlink

$.pos.x = $CC_Base_R_Foot.pos.x
$.pos.y = $CC_Base_R_Foot.pos.y

FootDis = distance $ $CC_Base_R_Foot

delete $
select $CC_Base_R_ToeBase
maxOps.cloneNodes $CC_Base_R_ToeBase cloneType:#copy newNodes:&nnl
select nnl
max unlink
$.pos.x = $CC_Base_R_Foot.pos.x
$.pos.z = $CC_Base_R_Foot.pos.z
FootLngth = distance $ $CC_Base_R_Foot
delete $
biped.setTransform $'Bip001 R Foot' #scale ([FootDis,FootLngth+(FootLngth*0.3),FootDis]) True
biped.setTransform $'Bip001 L Foot' #scale ([FootDis,FootLngth+(FootLngth*0.3),FootDis]) True
biped.setTransform $'Bip001 R Toe0' #scale ([FootDis,1,FootDis]) True
biped.setTransform $'Bip001 L Toe0' #scale ([FootDis,1,FootDis]) True

-- Foot rotation: align biped feet to CC Foot->ToeBase direction (like old UE script foot alignment)
fn createFootHelperCC srcBone tgtBone = (
	n = "myPoint" + srcBone.name
	p = point name:n centermarker:off axistripod:on cross:off box:on pos:srcBone.transform.position isSelected:off
	p.rotation.controller = LookAt_Constraint()
	p.rotation.controller.appendTarget tgtBone 50.0
	p.rotation.controller.relative = false
	p.rotation.controller.target_axis = 0
	p.rotation.controller.target_axisFlip = true
	p.rotation.controller.upnode_world = true
	p.rotation.controller.StoUP_axis = 2
	p.rotation.controller.StoUP_axisFlip = true
	p.rotation.controller.upnode_axis = 2
	finalTM = p.transform
	p.rotation.controller = Euler_XYZ()
	p.transform = finalTM
	p
)
lFootHelper = createFootHelperCC $CC_Base_L_Foot $CC_Base_L_ToeBase
rFootHelper = createFootHelperCC $CC_Base_R_Foot $CC_Base_R_ToeBase
biped.setTransform $'Bip001 L Foot' #rotation lFootHelper.transform.rotation true
biped.setTransform $'Bip001 R Foot' #rotation rFootHelper.transform.rotation true
delete lFootHelper
delete rFootHelper

select #($'Bip001 L Finger22', $'Bip001 L Finger32', $'Bip001 L Finger42', $'Bip001 L Finger12')

toolMode.coordsys #local

rotate $ (angleaxis -15 [0,1,0])

select #($'Bip001 R Finger22', $'Bip001 R Finger32', $'Bip001 R Finger42', $'Bip001 R Finger12')


rotate $ (angleaxis 15 [0,1,0])

move $'Bip001 L Foot' [-1.5,0,0]

move $'Bip001 R Foot' [1.5,0,0]	

clearSelection()

$'Bip001'.controller.figureMode = false


function OreinCons nd trg = 
(
nd.rotation.controller = Orientation_Constraint ()
nd.rotation.controller.appendTarget trg 50.0
nd.rotation.controller.relative = on
)

function PosCons ndp trgp = 
(
ndp.Position.controller = Position_Constraint ()
ndp.Position.controller.appendTarget trgp 50.0
ndp.Position.controller.relative = on
)

OreinCons $CC_Base_L_ThighTwist01 $'Bip001 LThighTwist'
OreinCons $CC_Base_L_ThighTwist02 $'Bip001 LThighTwist1'
OreinCons $CC_Base_L_CalfTwist01 $'Bip001 LCalfTwist'
OreinCons $CC_Base_L_CalfTwist02 $'Bip001 LCalfTwist1'
OreinCons $CC_Base_L_Foot $'Bip001 L Foot'
OreinCons $CC_Base_L_ToeBase $'Bip001 L Toe0'

PosCons $CC_Base_L_Calf $'Bip001 L Calf'
PosCons $CC_Base_L_Foot $'Bip001 L Foot'

OreinCons $CC_Base_R_ThighTwist01 $'Bip001 RThighTwist'
OreinCons $CC_Base_R_ThighTwist02 $'Bip001 RThighTwist1'
OreinCons $CC_Base_R_CalfTwist01 $'Bip001 RCalfTwist'
OreinCons $CC_Base_R_CalfTwist02 $'Bip001 RCalfTwist1'
OreinCons $CC_Base_R_Foot $'Bip001 R Foot'
OreinCons $CC_Base_R_ToeBase $'Bip001 R Toe0'

PosCons $CC_Base_R_Calf $'Bip001 R Calf'
PosCons $CC_Base_R_Foot $'Bip001 R Foot'

PosCons $CC_Base_Hip $Bip001
OreinCons $CC_Base_Hip $Bip001
OreinCons $CC_Base_Waist $'Bip001 Spine'
OreinCons $CC_Base_Spine01 $'Bip001 Spine1'
OreinCons $CC_Base_Spine02 $'Bip001 Spine2'
OreinCons $CC_Base_NeckTwist01 $'Bip001 Neck'
OreinCons $CC_Base_NeckTwist02 $'Bip001 Neck1'
OreinCons $CC_Base_Head $'Bip001 Head'

OreinCons $CC_Base_L_Clavicle $'Bip001 L Clavicle'
OreinCons $CC_Base_L_UpperarmTwist01 $'Bip001 LUpArmTwist'
OreinCons $CC_Base_L_UpperarmTwist02 $'Bip001 LUpArmTwist1'
OreinCons $CC_Base_L_ForearmTwist01 $'Bip001 L ForeTwist'
OreinCons $CC_Base_L_ForearmTwist02 $'Bip001 L ForeTwist1'
OreinCons $CC_Base_L_Hand $'Bip001 L Hand'
OreinCons $CC_Base_L_Thumb1 $'Bip001 L Finger0'
OreinCons $CC_Base_L_Thumb2 $'Bip001 L Finger01'
OreinCons $CC_Base_L_Thumb3 $'Bip001 L Finger02'
OreinCons $CC_Base_L_Index1 $'Bip001 L Finger1'
OreinCons $CC_Base_L_Index2 $'Bip001 L Finger11'
OreinCons $CC_Base_L_Index3 $'Bip001 L Finger12'
OreinCons $CC_Base_L_Mid1 $'Bip001 L Finger2'
OreinCons $CC_Base_L_Mid2 $'Bip001 L Finger21'
OreinCons $CC_Base_L_Mid3 $'Bip001 L Finger22'
OreinCons $CC_Base_L_Ring1 $'Bip001 L Finger3'
OreinCons $CC_Base_L_Ring2 $'Bip001 L Finger31'
OreinCons $CC_Base_L_Ring3 $'Bip001 L Finger32'
OreinCons $CC_Base_L_Pinky1 $'Bip001 L Finger4'
OreinCons $CC_Base_L_Pinky2 $'Bip001 L Finger41'
OreinCons $CC_Base_L_Pinky3 $'Bip001 L Finger42'
OreinCons $CC_Base_L_Upperarm $'Bip001 L UpperArm'
OreinCons $CC_Base_L_Forearm $'Bip001 L Forearm'



OreinCons $CC_Base_R_Clavicle $'Bip001 R Clavicle'
OreinCons $CC_Base_R_UpperarmTwist01 $'Bip001 RUpArmTwist'
OreinCons $CC_Base_R_UpperarmTwist02 $'Bip001 RUpArmTwist1'
OreinCons $CC_Base_R_ForearmTwist01 $'Bip001 R ForeTwist'
OreinCons $CC_Base_R_ForearmTwist02 $'Bip001 R ForeTwist1'
OreinCons $CC_Base_R_Hand $'Bip001 R Hand'
OreinCons $CC_Base_R_Thumb1 $'Bip001 R Finger0'
OreinCons $CC_Base_R_Thumb2 $'Bip001 R Finger01'
OreinCons $CC_Base_R_Thumb3 $'Bip001 R Finger02'
OreinCons $CC_Base_R_Index1 $'Bip001 R Finger1'
OreinCons $CC_Base_R_Index2 $'Bip001 R Finger11'
OreinCons $CC_Base_R_Index3 $'Bip001 R Finger12'
OreinCons $CC_Base_R_Mid1 $'Bip001 R Finger2'
OreinCons $CC_Base_R_Mid2 $'Bip001 R Finger21'
OreinCons $CC_Base_R_Mid3 $'Bip001 R Finger22'
OreinCons $CC_Base_R_Ring1 $'Bip001 R Finger3'
OreinCons $CC_Base_R_Ring2 $'Bip001 R Finger31'
OreinCons $CC_Base_R_Ring3 $'Bip001 R Finger32'
OreinCons $CC_Base_R_Pinky1 $'Bip001 R Finger4'
OreinCons $CC_Base_R_Pinky2 $'Bip001 R Finger41'
OreinCons $CC_Base_R_Pinky3 $'Bip001 R Finger42'
OreinCons $CC_Base_R_Upperarm $'Bip001 R UpperArm'
OreinCons $CC_Base_R_Forearm $'Bip001 R Forearm'


