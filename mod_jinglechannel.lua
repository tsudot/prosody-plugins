--Jingle Channel Implementation

local _G = _G;
local prosody = _G.prosody;
local hosts = prosody.hosts;

local connlistener_register = require "net.connlisteners".register;

local localport = module:get_option_number("jingle_channel_read_port") or 35800;
local remoteport = module:get_option_number("jingle_channel_write_port") or 35802;

local jinglerelay_listener_localport_rtp = {default_port = localport; default_mode = "*a"; default_interface = "*" };
local jinglerelay_listener_remoteport_rtp = {default_port = remoteport; default_mode = "*a"; default_interface = "*" };
local jinglerelay_listener_localport_rtcp = {default_port = localport+1; default_mode = "*a"; default_interface = "*" };
local jinglerelay_listener_remoteport_rtcp = {default_port = remoteport+1; default_mode = "*a"; default_interface = "*" };


local def_env = {};
local default_env_mt = { __index = def_env };

prosody.jinglerelay = { commands = commands, env = def_env };

jinglerelay = {};
function jinglerelay:new_session(conn)
    local w = function(s) conn:write(s); end;
    local session = { conn = conn;
        send = function (t) w(tostring(t)); end;
        disconnect = function () conn:close() end;
    };

    return session
end

local sessions = {  localport_rtp = nil;
                    localport_rtcp = nil;
                    remoteport_rtp = nil;
                    remoteport_rtcp = nil;
                };

-- Localport RTP connection

function jinglerelay_listener_localport_rtp.onconnect(conn)
    local session = jinglerelay:new_session(conn);
    if sessions.localport_rtp == nil then
        sessions.localport_rtp = session;
    end
end
        
function jinglerelay_listener_localport_rtp.onincoming(conn, data)
    local session = sessions.remoteport_rtp;

    (function(session, data)
        if session  then
            session.send(data);
        end
    end)(session, data);
end

function jinglerelay_listener_localport_rtp.ondisconnect(conn, err)
    local session = sessions.localport_rtp;
    if session then
        session.disconnect();
        sessions.localport_rtp = nil;
    end
end


-- Localport RTCP connection

function jinglerelay_listener_localport_rtcp.onconnect(conn)
    local session = jinglerelay:new_session(conn);
    if sessions.localport_rtcp = nil then
        sessions.localport_rtcp = session;
    end
end

function jinglerelay_listener_localport_rtcp.onincoming(conn, data)
    local session = sessions.remoteport_rtcp;

    (function(session, data)
        if session then
            session.send(data);
        end
    end)(session, data);
end

function jinglerelay_listener_localport_rtcp.ondisconnect(conn, err)
    local session = sessions.localport_rtcp;
    if session then
        session.disconnect();
        sessions.localport_rtcp = nil;
    end
end

-- Remoteport RTP connection

function jinglerelay_listener_remoteport_rtp.onconnect(conn)
    local session = jinglerelay:new_session(conn);
    if sessions.remoteport_rtp = nil then
        sessions.remoteport_rtp = session;
    end
end

function jinglerelay_listener_remoteport_rtp.onincoming(conn, data)
    local session = sessions.localport_rtp;

    (function(session, data)
        if session then
            session.send(data);
        end
    end)(session, data);
end

function jinglerelay_listener_remoteport_rtp.ondisconnect(conn, err)
    local session = sessions.remoteport_rtp;
    if session then
        session.disconnect();
        sessions.remoteport_rtp = nil;
    end
end


-- Remoteport RTCP connection

function jinglerelay_listener_remoteport_rtcp.onconnect(conn)
    local session = concole:new_session(conn);
    if sessions.remoteport_rtcp = nil then
        sessions.remoteport_rtcp = session;
    end
end

function jinglerelay_listener_remoteport_rtcp.onincoming(conn, data)
    local session = sessions.localport_rtcp;

    (function(session, data)
        if session then
            session.send(data);
        end
    end)(session, data);
end

function jinglerelay_listener_remoteport_rtcp.ondisconnect(conn, err)
    local session = sessions.remoteport_rtcp;
    if session then
        session.disconnect();
        sessions.remoteport_rtcp = nil;
    end
end

connlisteners_register('jinglerelay', jinglerelay_listener_localport_rtp);
connlisteners_register('jinglerelay', jinglerelay_listener_localport_rtcp);
connlisteners_register('jinglerelay', jinglerelay_listener_remoteport_rtp);
connlisteners_register('jinglerelay', jinglerelay_listener_remoteport_rtcp);


prosody.net_activate_ports("jinglerelay", "jinglerelay", {localport}, "tcp");
prosody.net_activate_ports("jinglerelay", "jinglerelay", {localport+1}, "tcp");
prosody.net_activate_ports("jinglerelay", "jinglerelay", {remoteport}, "tcp");
prosody.net_activate_ports("jinglerelay", "jinglerelay", {remoteport+1}, "tcp");
