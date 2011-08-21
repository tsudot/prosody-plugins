-- STUN server

local _G = _G;

local prosody = _G.prosody;
local hosts = prosody.hosts;
local connlisteners_register = require "net.connlisteners".register;

local stun_listener = { default_port = 3478; default_mode = "*a"; default_interface = "*" };

function hex_to_bin(hex)
	if hex then
		return (hex:gsub("..", function (c) return string.char(tonumber(c, 16)); end));
	end
end

function dec_to_bin(dec)
	hex = string.format("%x", dec)
	while string.len(hex) < 4 do
		hex = "0"..hex
	end
		
	return hex_to_bin(hex)
end


stun = {};

function stun:new_session(conn)
        local w = function(s) conn:write(s); end;
        local session = { conn = conn;
                        send = function (t) w(tostring(t)); end;
                        disconnect = function () conn:close(); end;
                        };
        return session;
end

local sessions = {};

function stun_listener.onconnect(conn)
        -- Handle new connection
        local session = console:new_session(conn);
        sessions[conn] = session;
end


function stun_listener.onincoming(conn, data)
        local session = sessions[conn];

        -- Handle data
        (function(session, data)

                if data:match(0x0001) then
			port = conn:port()
			ip = conn:ip()
			local ip_parts = ""
			for ip_part in string.gmatch(ip, "%d+") do 
				ip_parts..dec_to_bin(ip_part)
			end

                        d = hex_to_bin("0000")..hex_to_bin("0001")..dec_to_bin(tostring(port))..ip_parts
			session.send(d);
		end
	end)(session, data);
end


function stun_listener.ondisconnect(conn, err)
	local session = sessions[conn]
	if session then
		session.disconnect();
		sessions[conn] = nil;
	end
end
