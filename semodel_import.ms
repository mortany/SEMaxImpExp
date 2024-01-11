if (heapSize < 200000) then
        heapSize = 2000000

fn readFixedString bstream fixedLen = 
(
    local str = ""
    for i = 1 to fixedLen do (
    str += bit.intAsChar (ReadByte bstream #unsigned))
    str
)

fn ReadPoint f = 
(
	local x = readfloat f
	local z = readfloat f
	local y = readfloat f
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

fname = getOpenFileName \
caption:"Open .semodel mesh file" \
types:"SEModel|*.semodel" \
historyCategory:"SEMODELObjectPresets"

if fname != undefined then
(
    f = fopen fname "rb"

    clearlistener()

    str = readFixedString f 7

    if (str == "SEModel") then
    (

        Version = ReadShort f

        HeaderSize = ReadShort f

        DataPresentFlags = ReadByte f-- Data present flags

        BoneDataPresentFlags = ReadByte f -- Bone data present flags

        MeshDataPresentFlags = ReadByte f -- Mesh data present flags

        --Read counts

        BoneCount = ReadLong f
        MeshCount = ReadLong f 
        MatCount = ReadLong f

        -- Skip 3 reserved bytes
        ReadByte f
        ReadByte f
        ReadByte f

        Print("Bones: "+BoneCount as string)
        Print("Meshes: "+MeshCount as string)
        Print("Materials: "+MatCount as string)

        BoneNames = #()
        Bones = #()

        AllBones = #()

        struct SEModelBone (bone_name, parent_index, global_pos, global_rot, local_pos, local_rot, bone_scale )

        for i = 1 to BoneCount Do 
        (
            append BoneNames ( ReadString f)
        )

        for i = 1 to BoneCount Do
        (
            
            BoneFlags = ReadByte f -- Read bone flags (unused)

            ParentIndex = (ReadLong f) + 1

            GlobalPosition = undefined
            GlobalRotation = undefined
            LocalPosition = undefined
            LocalRotation = undefined
            BoneScale = undefined

            if( bit.and BoneDataPresentFlags 1) > 0 then 
            (
                GlobalPosition = ReadPoint f
                GlobalRotation = ReadQuat f
            )

            if( bit.and BoneDataPresentFlags 2) > 0 then 
            (
                LocalPosition = ReadPoint f
                LocalRotation = ReadQuat f
            )
            
            if( bit.and BoneDataPresentFlags 4) > 0 then 
            (
                BoneScale = ReadPoint f
            )

            local new_bone = SEModelBone BoneNames[i] ParentIndex GlobalPosition GlobalRotation LocalPosition LocalRotation BoneScale

            append Bones (new_bone)

            --Print("Bone: "+ new_bone as string)
        )

        for i = 1 to BoneCount Do
        (
            obj = dummy name:Bones[i].bone_name boxsize:([1,1,1] * .0) pos:[0,0,0] showlinks:true wirecolor:(color 255 255 0)

            --in coordsys #world 

            in coordsys #local obj.rotation.controller.value = Quat Bones[i].local_rot.x Bones[i].local_rot.y Bones[i].local_rot.z Bones[i].local_rot.w  --eulertoquat (eulerangles (radtodeg Bones[i].local_rot.x) (radtodeg Bones[i].local_rot.y) (radtodeg Bones[i].local_rot.z)) order:4
            in coordsys #local obj.position.controller.value = Bones[i].local_pos
            
            -- if ( Bones[i].global_rot != undefined ) then
            -- (
            --     in coordsys #world obj.rotation.controller.value = Quat Bones[i].global_rot.x Bones[i].global_rot.y Bones[i].global_rot.z Bones[i].global_rot.w
            -- )

            -- if ( Bones[i].global_pos != undefined ) then
            -- (
            --     in coordsys #world obj.position.controller.value = Bones[i].global_pos
            -- )

            --if PutToLayers.checked then	Lif.addnode obj
            obj.setSkinPose()

            append AllBones obj
        )

        for i = 1 to BoneCount Do
        (
            pb = undefined
            if (Bones[i].parent_index > 0) then
            (
                pb = AllBones[Bones[i].parent_index]
            )

            tm = if pb == undefined then matrix3 1 else pb.transform

            AllBones[i].parent = pb
            AllBones[i].transform *= tm
        )

        struct weight_data
        (
            boneids,weights
        )

        for i = 1 to MeshCount do 
        (
            local vmas = #()
            local fmas = #()
            local uvmas = #()
            local vnmas = #()
            local vcolor = #()
            local mat_ind = #()
            local Weight_array =#()

            local MeshFlags = ReadByte f --Read mesh flags (unused)
            local MatIndiciesCount = ReadByte f
            local MaxSkinInfluenceCount = ReadByte f
            local VertexCount = ReadLong f
            local FaceCount = ReadLong f

            vmas = for x = 1 to VertexCount collect ((ReadPoint f))

            if( bit.and MeshDataPresentFlags 1) then
            (
                for x = 1 to VertexCount do
                (
                    uv_x = ReadFloat f
                    uv_y = ReadFloat f

                    append uvmas [uv_x,uv_y,0]
                )
            )

            if( bit.and MeshDataPresentFlags 2) then
            (
                vnmas = for x = 1 to VertexCount collect ((ReadPoint f))
            )

            if( bit.and MeshDataPresentFlags 4) then
            (
                vcolor = for x = 1 to VertexCount collect (( ReadVertexColor f))
            )

            if( bit.and MeshDataPresentFlags 8) then
            (
                for x = 1 to VertexCount do
                (
                    w = (weight_data boneids:#() weights:#())
                    for y = 1 to MaxSkinInfluenceCount do
                    (
                        bone_id = 0

                        if(BoneCount <= 0xFF) then
                            bone_id = ReadByte f #unsigned
                        else if(BoneCount <= 0xFFFF) then
                            bone_id = ReadShort f #unsigned
                        else
                            bone_id = ReadLong f #unsigned

                        bone_weight = ReadFloat f

                        if(bone_weight != 0) then
                        (
                            w1 = bone_weight as float
                            append w.boneids (bone_id + 1)
                            append w.weights (w1)
                        )
                    )

                    append Weight_array w
                )


            )

            --Print ("Bone Weights loaded: " +(i as string) +"   "+ (Weight_array.count as string))

            for x = 1 to FaceCount do
            (
                if (VertexCount <= 0xFF) then
                (
                    local v1 = ReadByte f #unsigned
                    local v2 = ReadByte f #unsigned
                    local v3 = ReadByte f #unsigned

                    append fmas [ v1+1, v2+1, v3+1]
                )
                else if (VertexCount <= 0xFFFF) then
                (
                    local v1 = ReadShort f #unsigned
                    local v2 = ReadShort f #unsigned
                    local v3 = ReadShort f #unsigned

                    append fmas [ v1+1, v2+1, v3+1]
                )
                else
                (
                    local v1 = ReadLong f #unsigned
                    local v2 = ReadLong f #unsigned
                    local v3 = ReadLong f #unsigned

                    append fmas [ v1+1, v2+1, v3+1]
                )

            )
            
            --Print ("Faces loaded: " +(i as string) +"   "+ (fmas.count as string))

            for x = 1 to MatIndiciesCount do
            (
                append mat_ind (ReadLong f)
            )

            --Print ("Mat inds loaded: " +(i as string) +"   "+ (mat_ind.count as string))
            --exit

            msh = mesh vertices:vmas faces:fmas
            msh.name = "mesh_" + (i as string)
            for j = 1 to vnmas.count do setnormal msh j vnmas[j]

            if(Weight_array.count > 0) then
            (
                smod = skin bone_Limit:10
                obj = msh

                max modify mode
                select obj
                addmodifier obj smod

                for ii = 1 to AllBones.count do
                (
                    maxbone = AllBones[ii]
                    if ii != AllBones.count then 
                        skinOps.addBone smod AllBones[ii] 0
                    else
                        skinOps.addBone smod AllBones[ii] 1
                    --skinOps.addBone smod AllBones[ii] 0
                    --print( AllBones[ii] as string)
                )
                
                
                for v = 1 to obj.numVerts do
                (
                    w = Weight_array[v]
                    bi = #() --bone index array
                    wv = #() --weight value array

                    for j = 1 to w.boneids.count do
                    (
                        boneid = w.boneids[j]
                        weight = w.weights[j]
                        append bi boneid
                        append wv weight
                    )   
                    skinOps.ReplaceVertexWeights smod v bi wv
                )
            )

        )
    )
    else
    (
        Print("Bad SEModel file, magic was invalid")
    )

    fclose f
)



