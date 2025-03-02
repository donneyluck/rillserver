-------------------------------------------------------------------------------
-- Copyright(C)   machine studio                                              --
-- Author:        donney                                                     --
-- Email:         donney_luck@sina.cn                                        --
-- Date:          2021-05-25                                                 --
-- Description:   agent info (player data)                                   --
-- Modification:  null                                                       --
-------------------------------------------------------------------------------

local hash   = require "hash"
local env = require "faci.env"
local skynet = require "skynet"
local json      = require "cjson"
local libdbproxy = require "libdbproxy"
local runconf = require(skynet.getenv("runconfig"))

-- 玩家数据
local playerdata = {
    baseinfo = {}, --基本信息
    bag = {}, --背包
    task = {}, --任务
    friend = {}, --好友
    mail = {}, --邮件
    achieve = {}, --成就
    title = {}, --称号
}

local agent_info = {
    base_info ={
        uid = 0,
        uid_str = "",
        platform_id = 0,
        platform_id_str = "",
        sex = -1,
        token = "",
        gold = 0,
        account = "",
    },
    ext_info = {
        nick_name = "",
        sdk = -1,
        addr = 0,
    },
    other_info = {

    }
}

function agent_info:init_agent(uid, platform_id, sex, token, gold, account, addr)
    self.base_info.uid = uid or 0
    if self.base_info.uid == 0 then
        self.base_info.uid_str = ""
    else
        self.base_info.uid_str = tostring(uid)
    end
    self.base_info.platform_id = platform_id or 0
    if self.base_info.platform_id == 0 then
        self.base_info.platform_id_str = ""
    else
        self.base_info.platform_id_str = tostring(platform_id)
    end
    self.base_info.sex = sex or -1
    self.base_info.token = token or ""
    self.base_info.gold = gold or 0
    self.base_info.account = account

    self.ext_info.addr = addr
    self.ext_info.nick_name = self.base_info.account.account
end

local InitPlayerCMD = {}
function InitPlayerCMD.init_baseinfo_data()
    local ret = {}
    local now = os.time()
    local data_time = os.date("%Y-%m-%d %H:%M:%S",now)
    ret.login_time = data_time
    ret.register_time = data_time
    return ret
end

local function get_init_data(cname)
    local funname = string.format("init_%s_data", cname)
    local func = InitPlayerCMD[funname]
    assert(type(func) == "function")
    return func()
end

--[[
    baseinfo = {data = {}, hashcode = 0}
]]
local function load_info(cname, uid)
    local ret = {data=nil, hashcode=nil}

    ret.data = libdbproxy.get_playerdata(cname, uid)
    ret.data = ret.data or get_init_data(cname)
    if ret.data._id then
        ret.data._id = nil
    end

    if not ret.data.uid then
        ret.data.uid = uid
    end
    return ret
end

local function load_account_info(cname, uid)
    local data = libdbproxy.get_accountdata_by_uid(uid)
    assert(data)
    --for k, v in pairs(data) do
    --    DEBUG("---------->   k: ", k, ' v: ', v)
    --end
    return data
end

function agent_info:load_agent_info()
    local data = load_account_info('account', self.base_info.uid)
    --更新账户信息
    self.base_info.platform_id = data.platform_id
    self.base_info.sex = data.sex
    self.base_info.gold = data.gold
    self.ext_info.sdk = data.sdk

    for k, v in pairs(runconf.playerdata) do
        self.other_info[k] = load_info(k, self.base_info.uid)
    end
end

function agent_info:update_agent_info()
    local data_time = os.date("%Y-%m-%d %H:%M:%S", os.time())
    self.other_info.baseinfo.data.login_time = data_time
end

local function delay_load_update ()
    agent_info:load_agent_info()
    agent_info:update_agent_info()

end

function agent_info:load_and_update_agent_info_delay(delay)
    skynet.timeout(delay, delay_load_update)
end


local function save_agent_info(agent_info)
    for k, v in pairs(agent_info.other_info) do
        local now_code = hash.hashcode(v.data or {})
        if not v.hashcode or  v.hashcode ~= now_code then --第一次登陆保存一次
            v.hashcode = now_code
            --skynet.error('login_time: ', v.data.login_time)
            libdbproxy.set_playerdata(k, agent_info.base_info.uid, v.data)
        end
    end
end

function agent_info:save()
    save_agent_info(self)
end

local save_tick = 10 * 100
local need_loop = true
local function check_save_agent_info()
    if need_loop then
        skynet.timeout(save_tick, check_save_agent_info)
    end
    save_agent_info(agent_info)
end

function agent_info:start_save_agent_info_timer()
    check_save_agent_info()
end

function agent_info:stop_save_agent_info_timer()
    need_loop = false
    save_agent_info(self)
end


function env.get_agent()
    local agent = {
        base_info = agent_info.base_info,
        ext_info = agent_info.ext_info,
    }
    return agent
end


return agent_info
