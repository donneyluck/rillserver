local skynet=require "skynet"

--init module--
local faci = require "faci.module"
local module = faci.get_module("roomManager")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

local roomManagerLogic = require("manager.roomManagerLogic")

local Room_Map={}

function dispatch.create(room_id, room_type, roomMode)
    local room_addr = roomManagerLogic.get_one_room('room', room_type, room_id)
    Room_Map[room_id] = {addr = room_addr, room_id = room_id, room_type = room_type, roomMode = roomMode}

    local isok = skynet.call(room_addr,"lua", "roomAction.start", room_type)
    return isok, skynet.self(), Room_Map[room_id]
end

function dispatch.enter(room_id, data)
    local room = Room_Map[room_id]
    if not room then
        ERROR("------room_manager enter not room------ " .. room_id)
        return false
    end

    local isok = skynet.call(room.addr,"lua","roomAction.enter",data)
    return isok, skynet.self(), room
end

function dispatch.leave(room_id,uid)
    local room = Room_Map[room_id]
    if not room then
        ERROR("room_manager leave not room " .. room_id)
        return false
    end

    local isok = skynet.call(room.addr,"lua", "roomAction.leave", uid)
    if room.roomMode ~= 2 then
        roomManagerLogic.recycle(room.addr)
        Room_Map[room_id] = nil
    end

    return isok, skynet.self()
end

function event.start(name)
    -- roomManagerLogic.init()
end