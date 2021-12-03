if (heapSize < 200000) then
        heapSize = 2000000

fn readFixedString bstream fixedLen = 
(
    local str = ""
    for i = 1 to fixedLen do (
    str += bit.intAsChar (ReadByte bstream #unsigned))
    str
)

fn ReadSuperString f =
(
		local str = "" , ch, b
		while true do
		(
			b = readbyte f
			if (b == 0) then return str
			append str (bit.intaschar b)
		)
)

fn SkipStream f d =
(
    for x = 1 to d do
    (
        ReadByte f
    )
)

fn ReadPoint f = 
(
	local x = readfloat f
	local z = readfloat f
	local y = readfloat f
	return [x, y, z]
)

fn ReadPointD f = 
(
	local x = ReadDouble f
	local z = ReadDouble f
	local y = ReadDouble f
	return [x, y, z]
)

fn ReadVertexColor f = 
(
	local x = ReadByte f
	local z = ReadByte f
	local y = ReadByte f
    local w = ReadByte f
	return [x, y, z, w]
)

fn ReadQuat f =
(
    local x = readfloat f
	local z = readfloat f
	local y = readfloat f
    local w = readfloat f
    return [x, y, z, w]
)

fn GetNodeParents node = if isvalidnode node do  
(
    --Print ("GEG")
    local parents = #()
    while node.parent != undefined do
    (
        append parents node.parent
        --Print("Append is " + node.parent as string)
        node  = node.parent
    )
    return parents
)

fn ReadQuatD f =
(
    local x = ReadDouble f
	local z = ReadDouble f
	local y = ReadDouble f
    local w = ReadDouble f
    return [x, y, z, w]
)

fname = getOpenFileName \
caption:"Open .seanim animation file" \
types:"SEAnim|*.seanim" \
historyCategory:"SEMODELObjectPresets"

f = fopen fname "rb"

struct frame_data
(
    translations,rotations,scales
)

struct bone_data
(
    BoneName,KeyFrames,BoneModif
)

clearlistener()

Magic = readFixedString f 6

if (Magic == "SEAnim") then
(
    local Version = ReadShort f
    local HeaderSize = ReadShort f
    local AnimType = ReadByte f #unsigned
    local AnimFlags = ReadByte f #unsigned

    local Looping = (bit.and AnimFlags 1 )

    local DataPresentFlags = ReadByte f #unsigned
    local DataPropertyFlags = ReadByte f #unsigned

    -- skip 2 bytes
    SkipStream f 2

    local FrameRate = ReadFloat f
    local NumFrames = ReadLong f
    local NumBones = ReadLong f
    local NumMods = ReadByte f

    local DeltaTagName = ""
    local BoneArray = #()

    local AnimationBoneModifiers = #()

    

    fn GetBoneModif bone =
    (
        local parents = GetNodeParents bone

        if parents == undefined then return -1

        for bn in parents do
            for br in BoneArray do
                if (stricmp br.BoneName bn.name) == 0 then return br.BoneModif
        
        return -1
    )

    -- skip 3 bytes
    SkipStream f 3

    local NumNotes = ReadLong f

    for i = 1 to NumBones do 
    (
        str = ReadSuperString f
        bone = (bone_data BoneName:str KeyFrames:#() BoneModif:0 )
        append BoneArray bone
    )
        --If we're delta, set delta name
    if AnimType == 3 then DeltaTagName = BoneNames[1]

    for i = 1 to NumMods do 
    (
        local bone_idx = if NumBones <= 0xFF then ReadByte f else ReadShort f
        BoneArray[bone_idx +1].BoneModif = ReadByte f
    )

    for i = 1 to NumBones do
    (
        local BoneFlags = ReadByte f -- Read bone flags (unused)

        if(bit.and DataPresentFlags 1) then
        (
            local NumTranslations = 0

            if (NumFrames <= 0xFF) then
            (
                NumTranslations = ReadByte f #unsigned
            )
            else if (NumFrames <= 0xFFFF) then
            (
                NumTranslations = ReadShort f #unsigned
            )
            else
            (
                NumTranslations = ReadLong f #unsigned
            )

            for ii = 1 to NumTranslations do
            (
                local KeyFrame = -1
                if (NumFrames <= 0xFF) then
                (
                    KeyFrame = (ReadByte f #unsigned) + 1
                )
                else if (NumFrames <= 0xFFFF) then
                (
                    KeyFrame = (ReadShort f #unsigned) + 1
                )
                else
                (
                    KeyFrame = (ReadLong f #unsigned) + 1
                )

                if BoneArray[i].KeyFrames[KeyFrame] == undefined then
                (
                    --frame = frame_data (translations:undefined rotations:undefined scales:undefined)
					frame = frame_data()
                    BoneArray[i].KeyFrames[KeyFrame] = frame
                )

                if(bit.and DataPropertyFlags 1) then
                (
                    BoneArray[i].KeyFrames[KeyFrame].translations = ReadPointD f
                )
                else
                (
                    BoneArray[i].KeyFrames[KeyFrame].translations = ReadPoint f
                )
            )
        )

        if(bit.and DataPresentFlags 2) then
        (
            local NumRotations = 0

            if (NumFrames <= 0xFF) then
            (
                NumRotations = ReadByte f #unsigned
            )
            else if (NumFrames <= 0xFFFF) then
            (
                NumRotations = ReadShort f #unsigned
            )
            else
            (
                NumRotations = ReadLong f #unsigned
            )

            for ii = 1 to NumRotations do
            (
                local KeyFrame = -1
                if (NumFrames <= 0xFF) then
                (
                    KeyFrame = (ReadByte f #unsigned) + 1
                )
                else if (NumFrames <= 0xFFFF) then
                (
                    KeyFrame = (ReadShort f #unsigned) + 1
                )
                else
                (
                    KeyFrame = (ReadLong f #unsigned) + 1
                )

                if BoneArray[i].KeyFrames[KeyFrame] == undefined then
                (
                    --frame = frame_data (translations:undefined rotations:undefined scales:undefined)
					frame = frame_data()
                    BoneArray[i].KeyFrames[KeyFrame] = frame
                )

                if(bit.and DataPropertyFlags 1) then
                (
                    BoneArray[i].KeyFrames[KeyFrame].rotations = ReadQuatD f
                )
                else
                (
                    BoneArray[i].KeyFrames[KeyFrame].rotations = ReadQuat f
                )
            )
        )

        if(bit.and DataPresentFlags 4) then
        (
            local NumScales = 0

            if (NumFrames <= 0xFF) then
            (
                NumScales = ReadByte f #unsigned
            )
            else if (NumFrames <= 0xFFFF) then
            (
                NumScales = ReadShort f #unsigned
            )
            else
            (
                NumScales = ReadLong f #unsigned
            )

            for ii = 1 to NumScales do
            (
                local KeyFrame = -1
                if (NumFrames <= 0xFF) then
                (
                    KeyFrame = (ReadByte f #unsigned) + 1
                )
                else if (NumFrames <= 0xFFFF) then
                (
                    KeyFrame = (ReadShort f #unsigned) + 1
                )
                else
                (
                    KeyFrame = (ReadLong f #unsigned) + 1
                )

                if BoneArray[i].KeyFrames[KeyFrame] == undefined then
                (
                    --frame = frame_data (translations:undefined rotations:undefined scales:undefined)
                    frame = frame_data()
                    BoneArray[i].KeyFrames[KeyFrame] = frame
                )

                if(bit.and DataPropertyFlags 1) then
                (
                    BoneArray[i].KeyFrames[KeyFrame].scales = ReadPointD f
                )
                else
                (
                    BoneArray[i].KeyFrames[KeyFrame].scales = ReadPoint f
                )
            )
        )

        --Print("Sucess!")

    )

    for i = 1 to NumNotes do
    (
        local KeyFrame = -1
        if (NumFrames <= 0xFF) then
        (
            KeyFrame = (ReadByte f #unsigned) + 1
        )
        else if (NumFrames <= 0xFFFF) then
        (
            KeyFrame = (ReadShort f #unsigned) + 1
        )
        else
        (
            KeyFrame = (ReadLong f #unsigned) + 1
        )

        ReadSuperString f
    )

    --Print(BoneArray[1] as string)
    --Print(BoneArray[1].KeyFrames.Count as string)
    
    -- for x = 1 to BoneArray[1].KeyFrames.Count do
    -- (
    --     Print(BoneArray[1].KeyFrames[x] as string)
    -- )

    local ctime, _pos, _rot, _scale

    for i = 1 to BoneArray.Count do
    (
        current_bone = undefined

        for xo in selection do
            if (stricmp BoneArray[i].BoneName xo.name) == 0 then (current_bone = xo ; exit)
        
        local ANM_TYPE = GetBoneModif current_bone
        
        print( ANM_TYPE as string)

        --ctr = for j = 1 to 3 collect linear_float ()
        _pos = linear_position ()
        _rot = linear_rotation ()
        _scale = linear_scale ()
        ctime = linear_float ()


        --Print("DEBUG")


        
        for x = 1 to BoneArray[i].KeyFrames.Count do
        (
            if BoneArray[i].KeyFrames[x] != undefined then
            (

                local pos = if BoneArray[i].KeyFrames[x].translations != undefined then BoneArray[i].KeyFrames[x].translations else undefined
                local rot = if BoneArray[i].KeyFrames[x].rotations != undefined then Quat BoneArray[i].KeyFrames[x].rotations.x BoneArray[i].KeyFrames[x].rotations.y BoneArray[i].KeyFrames[x].rotations.z BoneArray[i].KeyFrames[x].rotations.w else undefined
                local scal = if BoneArray[i].KeyFrames[x].scales != undefined then BoneArray[i].KeyFrames[x].scales else undefined
                --local rot = Quat 0 0 0 1
                --local pos = Point3 0 0 0

                if pos != undefined then animate on at time (x-1) _pos.value = pos
                if rot != undefined then animate on at time (x-1) _rot.value = rot
                if scal != undefined then animate on at time (x-1) _scale.value = scal

                addNewKey ctime (x-1)

                animate on at time (x-1) ctime.value = 1
            )
        )

        if current_bone != undefined then
        (
            setBeforeORT current_bone.rotation.controller #constant
            setAfterORT current_bone.rotation.controller #constant
            setBeforeORT current_bone.position.controller #constant
            setAfterORT current_bone.position.controller #constant
            setBeforeORT current_bone.scale.controller #constant
            setAfterORT current_bone.scale.controller #constant

            for k in ctime.keys do
            (
                t = k.time

                

                if ANM_TYPE == 0 and current_bone.parent != undefined then
                (
                    if _pos.value != undefined then
                    (
                        --animate on at time t current_bone.transform.translation += _pos.value
                        animate on at time t current_bone.position.controller.value = _pos.value
                    )
                        
                    --
                )
                else
                (

                    if _pos.value != undefined then
                    (
                        animate on at time t current_bone.transform.translation = _pos.value
                        --animate on at time t current_bone.position.controller.value = _pos.value
                        --animate on at time t current_bone.position.controller.value += _pos.value
                    )
                        
                )
                
                if _rot.value != undefined then
                    animate on at time t current_bone.rotation.controller.value = _rot.value

                --pb = undefined --current_bone.parent
                --tm = if pb == undefined then matrix3 1 else at time t pb.transform
                --animate on at time t current_bone.transform *= tm

                --animate on at time t current_bone.scale.controller.value = _scale.value

                --addEaseCurve current_bone.rotation.controller.value _rot.value
                --addEaseCurve current_bone.position.controller.value _pos.value
            )

            deletekeys current_bone.scale.controller.keys #allkeys

        )
    )
)
else
(
    Print("Bad SEAnim file, magic was invalid")
)

fclose f