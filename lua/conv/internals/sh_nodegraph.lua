NODE_TYPE_GROUND = 2
NODE_TYPE_AIR = 3
NODE_TYPE_CLIMB = 4
NODE_TYPE_WATER = 5

local SIZEOF_INT = 4
local SIZEOF_SHORT = 2

local AINET_VERSION_NUMBER = 37
local NUM_HULLS = 10
local MAX_NODES = 4096

CONV_AINNET_VER     = CONV_AINNET_VER or 0
CONV_MAP_VER        = CONV_MAP_VER or 0
CONV_NODES_ALL      = CONV_NODES_ALL or {}
CONV_NODES_GROUND   = CONV_NODES_GROUND or {}
CONV_NODES_AIR      = CONV_NODES_AIR or {}
CONV_NODES_CLIMB    = CONV_NODES_CLIMB or {}
CONV_NODES_WATER    = CONV_NODES_WATER or {}
--CONV_NODES_LINKS    = CONV_NODES_LINKS or {}
CONV_NODES_LOOKUP   = CONV_NODES_LOOKUP or {}

local function toUShort(b)

	local i = { string.byte( b, 1, SIZEOF_SHORT ) }

	return i[1] + i[2] * 256

end

local function toInt(b)

	local i = { string.byte( b, 1, SIZEOF_INT) }

	i = i[1] + i[2] * 256 + i[3] * 65536 + i[4] * 16777216

	if ( i > 2147483647 ) then return i -4294967296 end

	return i

end

local function ReadInt(f) return toInt( f:Read( SIZEOF_INT ) ) end
local function ReadUShort(f) return toUShort( f:Read( SIZEOF_SHORT ) ) end



-- Reads the .ain file for the current map and returns a table of AI nodes
function conv.parseNodeFile()

	local f = file.Open( "maps/graphs/" .. game.GetMap() .. ".ain", "rb", "GAME" )

    if (!f) then return end

    CONV_AINNET_VER     =  0
    CONV_MAP_VER        =  0
    CONV_NODES_ALL      = {}
    CONV_NODES_GROUND   = {}
    CONV_NODES_AIR      = {}
    CONV_NODES_CLIMB    = {}
    CONV_NODES_WATER    = {}
    --CONV_NODES_LINKS    = {}
    CONV_NODES_LOOKUP   = {}

    local ainet_ver = ReadInt(f)
    local map_ver = ReadInt(f)

    CONV_AINNET_VER = ainet_ver
    CONV_MAP_VER = map_ver

    if( ainet_ver != AINET_VERSION_NUMBER ) then

        MsgN( "Unknown graph file" )

        return
    end

    local numNodes = ReadInt(f)

    if ( numNodes > MAX_NODES or numNodes < 0 ) then

        MsgN( "Graph file has an unexpected amount of nodes" )
        return
    end

    for i = 1, numNodes do

        local v = Vector( f:ReadFloat(), f:ReadFloat(), f:ReadFloat() )
        local yaw = f:ReadFloat()
        local flOffsets = {}

        for i = 1, NUM_HULLS do
            flOffsets[i] = f:ReadFloat()
        end

        local nodetype = f:ReadByte()
        local nodeinfo = ReadUShort(f)
        local zone = f:ReadShort()

        local node = {
            pos = v,
            --yaw = yaw,
            --offset = flOffsets,
            type = nodetype,
            --info = nodeinfo,
            --zone = zone,
            --neighbor = {},
            --numneighbors = 0,
            --link = {},
            --numlinks = 0
        }

        table.insert( CONV_NODES_ALL, node )

    end

    --[[
    local numLinks = ReadInt(f)
    for i = 1, numLinks do

        local link = {}
        local srcID = f:ReadShort()
        local destID = f:ReadShort()
        local nodesrc = CONV_NODES_ALL[ srcID + 1 ]
        local nodedest = CONV_NODES_ALL[ destID + 1 ]

        if ( nodesrc and nodedest ) then
            table.insert( nodesrc.neighbor, nodedest )
            nodesrc.numneighbors = nodesrc.numneighbors + 1

            nodesrc.numlinks = nodesrc.numlinks + 1
            link.src = nodesrc
            link.srcID = srcID + 1
            table.insert( nodesrc.link, link )

            nodedest.numneighbors = nodedest.numneighbors + 1
            table.insert( nodedest.neighbor, nodesrc )

            nodedest.numlinks = nodedest.numlinks + 1
            link.dest = nodedest
            link.destID = destID + 1
            table.insert( nodedest.link, link )

        else
            MsgN("Unknown link source or destination " .. srcID .. " " .. destID)
        end

        local moves = {}

        for i = 1, NUM_HULLS do
            moves[i] = f:ReadByte()
        end

        link.move = moves
        table.insert( CONV_NODES_LINKS, link )
    end
    ]]

    for i = 1, numNodes do
        table.insert( CONV_NODES_LOOKUP, ReadInt(f) )
    end

	f:Close()

    for i = 1, #CONV_NODES_ALL do

        local node = CONV_NODES_ALL[i]
        local nodetype = node.type

        if nodetype == 2 then table.insert( CONV_NODES_GROUND, node )
		elseif nodetype == 3 then table.insert( CONV_NODES_AIR, node )
		elseif nodetype == 4 then table.insert( CONV_NODES_CLIMB, node )
		elseif nodetype == 5 then table.insert( CONV_NODES_WATER, node )
		end
    end

end


--[[
==================================================================================================
					AI NODEGRAPH CONVENIENCE
==================================================================================================
--]]


-- Returns a table with selected type of nodes
function conv.aiNodesGet(nType)
	return ( not nType or nType == 1 ) and CONV_NODES_ALL or nType == 2 and CONV_NODES_GROUND or nType == 3 and CONV_NODES_AIR or nType == 4 and CONV_NODES_CLIMB or nType == 5 and CONV_NODES_WATER
end

-- Ain net version
function conv.ainGetVersion()
	return CONV_AINNET_VER
end

-- Map version
function conv.mapGetVersion()
	return CONV_MAP_VER
end

---- Returns nodes that are in uhhhh
-- pos: Vector - position to check from
-- distMin, distMax: number - horizontal distance range
-- nType: node type
-- visible: see aiNodesFindInSphere
-- posOffset, nodePosOffset: optional offsets
function conv.aiNodesFindInSphere(pos, distMin, distMax, nType, visible, posOffset, nodePosOffset)

	if !conv.aiNodesGet( nType ) || #conv.aiNodesGet( nType ) == 0 then return end

    local nodes = {}
    local nodePosOffset = nodePosOffset or Vector( 0, 0, 3 )
    local posOffset = posOffset or Vector( 0, 0, 3 )
    distMin = distMin * distMin
    distMax = distMax * distMax

	for i = 1, #conv.aiNodesGet( nType ) do

        local node = conv.aiNodesGet( nType )[i]
		local dist = conv.getDistVector( node.pos, pos )

        local tr
        if visible != nil then
            tr = util.TraceLine({
                start = pos + posOffset,
                endpos = node.pos + nodePosOffset,
                mask = MASK_SOLID_BRUSHONLY
		    })
        end

        if ( visible == true && !tr.HitWorld || visible == false && tr.HitWorld || visible == nil ) then
            if dist >= distMin && dist <= distMax then
                nodes[#nodes + 1] = node
            end
        end
	end

    return nodes
end

---- Returns nodes within a certain horizontal distance and height difference
-- pos: Vector - position to check from
-- distMin, distMax: number - horizontal distance range
-- heightMin, heightMax: number - vertical (Z) difference range (optional, can be nil)
-- nType: node type
-- visible: see aiNodesFindInSphere
-- posOffset, nodePosOffset: optional offsets
function conv.aiNodesFindInSphereHeight(pos, distMin, distMax, heightMin, heightMax, nType, visible, posOffset, nodePosOffset)
    if not conv.aiNodesGet( nType ) or #conv.aiNodesGet( nType ) == 0 then return end

    local nodes = {}
    local nodePosOffset = nodePosOffset or Vector( 0, 0, 3 )
    local posOffset = posOffset or Vector( 0, 0, 3 )
    distMin = distMin * distMin
    distMax = distMax * distMax

    for i = 1, #conv.aiNodesGet( nType ) do
        local node = conv.aiNodesGet( nType )[i]
        local nodePos = node.pos
        local horizDist = conv.getDistVector( Vector( nodePos.x, nodePos.y, 0 ), Vector( pos.x, pos.y, 0 ) )
        local heightDiff = nodePos.z - pos.z

        local tr
        if visible != nil then
            tr = util.TraceLine({
                start = pos + posOffset,
                endpos = node.pos + nodePosOffset,
                mask = MASK_SOLID_BRUSHONLY
		    })
        end

        local inDist = horizDist >= distMin and horizDist <= distMax
        local inHeight = true
        if heightMin or heightMax then
            inHeight = ( not heightMin or heightDiff >= heightMin ) and ( not heightMax or heightDiff <= heightMax )
        end

        if ( visible == true and not tr.HitWorld or visible == false and tr.HitWorld or visible == nil ) then
            if inDist and inHeight then
                nodes[#nodes + 1] = node
            end
        end
    end

    return nodes
end

-- Finds all node positions within a box defined by min and max vectors from a given position
function conv.aiNodesFindInBox(pos, mins, maxs, nType, visible, posOffset, nodePosOffset)
    local nodes = {}
    local nodePosOffset = nodePosOffset or Vector( 0, 0, 3 )
    local posOffset = posOffset or Vector( 0, 0, 3 )
    local minVec = pos + mins
    local maxVec = pos + maxs

    for i = 1, #conv.aiNodesGet( nType ) do
        local node = conv.aiNodesGet( nType )[i]
        local nodePos = node.pos

        local tr
        if visible != nil then
            tr = util.TraceLine({
                start = pos + posOffset,
                endpos = nodePos + nodePosOffset,
                mask = MASK_SOLID_BRUSHONLY
            })
        end

        if ( visible == true and not tr.HitWorld or visible == false and tr.HitWorld or visible == nil ) then
            if nodePos.x >= minVec.x and nodePos.x <= maxVec.x and nodePos.y >= minVec.y and nodePos.y <= maxVec.y and nodePos.z >= minVec.z and nodePos.z <= maxVec.z then
                nodes[#nodes + 1] = node
            end
        end
    end

    return nodes
end

-- Returns the closest node to the provided position
-- pos: Vector - position to check from
-- nType: node type
-- visible: see aiNodesFindInSphere
-- posOffset, nodePosOffset: optional offsets
function conv.aiNodeFindClosest(pos, nType, visible, posOffset, nodePosOffset)
    if not conv.aiNodesGet( nType ) or #conv.aiNodesGet( nType ) == 0 then return end

	local distClosest = math.huge
	local nodeClosest
    local nodePosOffset = nodePosOffset or Vector( 0, 0, 3 )
    local posOffset = posOffset or Vector( 0, 0, 3 )

	for i = 1, #conv.aiNodesGet( nType ) do

        local node = conv.aiNodesGet( nType )[i]
		local dist = conv.getDistVector( node.pos, pos )
        local tr
        if visible != nil then
            tr = util.TraceLine({
                start = pos + posOffset,
                endpos = node.pos + nodePosOffset,
                mask = MASK_SOLID_BRUSHONLY
		    })
        end

        if ( visible == true && !tr.HitWorld || visible == false && tr.HitWorld || visible == nil ) then
            if dist < distClosest then
                distClosest = dist
                nodeClosest = node
            end
        end
	end

	return nodeClosest, distClosest
end

-- Returns the furthest node to the provided position but not further than set distance
-- pos: Vector - position to check from
-- distMax: number - distance range
-- nType: node type
-- visible: see aiNodesFindInSphere
-- posOffset, nodePosOffset: optional offsets
function conv.aiNodeFindFurthest(pos, distMax, nType, visible, posOffset, nodePosOffset)
	if not conv.aiNodesGet( nType ) or #conv.aiNodesGet( nType ) == 0 then return end

	local distFurthest = 0
	local nodeFurthest
    distMax = distMax * distMax
    local nodePosOffset = nodePosOffset or Vector( 0, 0, 3 )
    local posOffset = posOffset or Vector( 0, 0, 3 )

	for i = 1, #conv.aiNodesGet( nType ) do

        local node = conv.aiNodesGet( nType )[i]
		local dist = conv.getDistVector( node.pos, pos )
        local tr
        if visible != nil then
            tr = util.TraceLine({
                start = pos + posOffset,
                endpos = node.pos + nodePosOffset,
                mask = MASK_SOLID_BRUSHONLY
		    })
        end

        if ( visible == true && !tr.HitWorld || visible == false && tr.HitWorld || visible == nil ) then

            if dist > distFurthest && dist <= distMax then
                distFurthest = dist
                nodeFurthest = node
            end
        end
	end

	return nodeFurthest, distFurthest
end

--[[
function conv.aiNodeGetLink(src, dest, nType)
	local nodes = conv.aiNodesGet(nType)
	local nodeSrc = nodes[src]
	local nodeDest = nodes[dest]

	if ( not nodeSrc or not nodeDest ) then return end

    for i = 1, #nodeSrc.link do
        local link = nodeSrc.link[i]
        if ( link.src == nodeDest or link.dest == nodeDest ) then return link end
    end

    for i = 1, #nodeDest.link do
        local link = nodeDest.link[i]
        if ( link.src == nodeSrc or link.dest == nodeSrc ) then return link end
    end
end

function conv.aiNodeHasLink(src, dest, nType)
	return conv.aiNodeGetLink( src, dest, nType ) != nil
end
]]
