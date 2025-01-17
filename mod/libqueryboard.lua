local skynet = require "skynet"
local log = require "log"
-- local M = {}
local env = require "faci.env"
local M = env.dispatch

local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service
local boardconf = runconf.queryboard
local node = skynet.getenv("nodename")

local function fetch_global()
    local index = 1
    return boardconf.global[index]
end

function M.query(msg)
	local global = fetch_global()
	assert(global)
	return skynet.call(global, "lua", "queryboard.query", msg.uid)
end


return M
