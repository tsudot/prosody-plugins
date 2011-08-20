--Jingle Channel Implementation

socket = require "socket"
local localport = module:get_option_number("jingle_channel_read_port") or 35800;
local remoteport = module:get_option_number("jingle_channel_write_port") or 35802;

local connlistener_register = require "net.connlisteners".register;

local udp_localport_rtp = socket.udp();
local udp_localport_rtcp = socket.udp();
local udp_remoteport_rtp = socket.udp();
local udp_remotrport_rtcp = socket.udp();

-- RTP localport
function read_rtp_localport(data)
    udp_localport_rtp:setsockname("*", data.localport);
    udp_localport_rtp:settimeout(data.expire);
    return udp_localport_rtp:receivefrom()
end

function write_rtp_localport(msg, ip, port)
    return udp_localport_rtp:sendto(msg, ip, port)
end

--RTP remoteport
function read_rtp_remoteport(data)
    udp_remoteport_rtp:setsockname("*", data.remoteport);
    udp_remoteport_rtp:settimeout(data.expire);
    return udp_remoteport_rtp:receivefrom()
end

function write_rtp_remoteport(msg, ip, port)
    return udp_remoteport_rtp:sendto(msg, ip, port)
end

--RTCP localport
function read_rtcp_localport(data)
    udp_localport_rtp:setsockname("*", data.localport+1);
    udp_localport_rtp:settimeout(data.expire);
    return udp_localport_rtp:receivefrom()
end

function write_rtcp_localport(msg, ip, port)
    return udp_localport_rtcp:sendto(msg, ip, port)
end

--RTCP remoteport
function read_rtcp_remoteport(data)
    udp_remoteport_rtcp:setsockname("*", data.remoteport+1);
    udp_remoteport_rtcp:settimeout(data.expire)
    return udp_remoteport_rtp:receivefrom()
end

function write_rtcp_remoteport(msg, ip, port)
    return udp_remoteport_rtcp:sendto(msg, ip, port)
end

module:hook('jingle/channel', function(data)

    -- Listening on RTP localport
    local msg, ip, port = read_rtp_localport(data);
