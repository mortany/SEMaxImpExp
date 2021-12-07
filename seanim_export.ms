if (heapSize < 200000) then
        heapSize = 2000000

--if selection.Count == 0 then "No any bones selected"

fn WritePoint f value = 
(

    WriteFloat f value.x
    WriteFloat f value.z
    WriteFloat f value.y
)

fn WriteQuat f value =
(
    WriteFloat f value.x
    WriteFloat f value.z
    WriteFloat f value.y
    WriteFloat f value.w
)

struct note_frame
(
    keyframe ,note 
)


wname = getOpenFileName \
caption:"Open .notetrack anim data file" \
types:"notetrack|*.notetrack" \
historyCategory:"SEMODELObjectPresets"

NoteTracks = #()

if wname != undefined then
(
    wr = fopen wname "rb"

    local NumNotes = ReadLong wr

    for i = 1 to NumNotes do
    (
        KeyFrame = (ReadByte wr #unsigned)

        str = ReadSuperString wr

        note = ( note_frame keyframe:KeyFrame note: str)

        append NoteTracks note
    )

    fclose wr
)



FStart = animationRange.start.frame
FEnd = animationRange.end.frame

FEnd = FEnd as integer
FStart = FStart as integer

NumFrames = FEnd + 1

Print(FStart as string)
Print(FEnd as string)
Print("Frames: "+NumFrames as string)

struct bone_mod
(
    index, modif 
)


BoneModArray = #()

idx = 0
for obj in selection do
(
    _mod = getUserProp obj "Bone Type"
    if(_mod != -1 and _mod != undefined) then 
    (
        bnm = (bone_mod index:idx modif:_mod)
        append BoneModArray bnm
    )

    idx += 1
)

fname = getsavefilename \
caption:"Open .seanim animation file" \
types:"SEAnim|*.seanim" \
historyCategory:"SEMODELObjectPresets"


if fname != undefined then
(
    f = fopen fname "wb"

    WriteByte f 83
    WriteByte f 69
    WriteByte f 65
    WriteByte f 110
    WriteByte f 105
    WriteByte f 109
    
    WriteShort f 1

    WriteShort f 28

    WriteByte f 0

    WriteByte f 0

    WriteByte f 3

    WriteByte f 0

    --skip 2
    WriteByte f 0
    WriteByte f 0


    WriteFloat f 30 -- Framerate

    

    WriteLong f (NumFrames)
    WriteLong f selection.count
    WriteByte f BoneModArray.count

    -- skip 3
    WriteByte f 0
    WriteByte f 0
    WriteByte f 0

    WriteLong f NoteTracks.count -- NumNotes

    for xo in selection do
    (
        WriteString f xo.name
    )

    for bm in BoneModArray do
    (
        if selection.Count <= 0xFF then WriteByte f bm.index else  WriteShort f bm.index
        WriteByte f bm.modif
    )

    for bn in selection do 
    (
        WriteByte f 0 -- BoneFlags (unused)

        key_pos = bn.position.controller.keys

        Print(key_pos as string)

        if key_pos.count == 0 then
        (
            if NumFrames <= 0xFF then
            (
                WriteByte f 1
                WriteByte f 0
            )
            else if NumFrames <= 0xFFFF then 
            (
                WriteShort f 1
                WriteShort f 0
            )
            else
            (
                WriteLong f 1
                WriteLong f 0
            )

            WritePoint f (Point3 0 0 0)
        )
        else if key_pos.count == -1 then
        (
            if NumFrames <= 0xFF then
                WriteByte f 0
            else if NumFrames <= 0xFFFF then 
                WriteShort f 0
            else 
                WriteLong f 0
        )
        else
        (
            if NumFrames <= 0xFF then 
                WriteByte f key_pos.count
            else if NumFrames <= 0xFFFF then 
                WriteShort f key_pos.count
            else 
                WriteLong f key_pos.count

            for k in key_pos do
            (
                if NumFrames <= 0xFF then 
                    WriteByte f k.time.frame
                else if NumFrames <= 0xFFFF then 
                    WriteShort f k.time.frame
                else 
                    WriteLong f k.time.frame
                
                WritePoint f ( at time k.time bn.position.controller.value )
            )
        )

        key_rot = bn.rotation.controller.keys

        if (key_rot.count == -1) then
        (
            if NumFrames <= 0xFF then 
                WriteByte f 0
            else if NumFrames <= 0xFFFF then 
                WriteShort f 0
            else 
                WriteLong f 0
        )
        else
        (
            if NumFrames <= 0xFF then 
                WriteByte f key_rot.count
            else if NumFrames <= 0xFFFF then 
                WriteShort f key_rot.count
            else 
                WriteLong f key_rot.count

            for k in key_rot do
            (
                if NumFrames <= 0xFF then 
                    WriteByte f k.time.frame
                else if NumFrames <= 0xFFFF then 
                    WriteShort f k.time.frame
                else 
                    WriteLong f k.time.frame
                
                WriteQuat f ( at time k.time bn.rotation.controller.value )
            )       
        )

         
    )

    if NoteTracks.count > 0 then
    (
        for note in NoteTracks do
        (
            if (NumFrames <= 0xFF) then
            (
                WriteByte f note.keyframe #unsigned
            )
            else if (NumFrames <= 0xFFFF) then
            (
                WriteShort f note.keyframe #unsigned
            )
            else
            (
                WriteLong f note.keyframe #unsigned
            )

            WriteString f note.note
        )
    )

    fclose f

)



