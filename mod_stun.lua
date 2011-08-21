-- STUN server

local _G = _G;

local prosody = _G.prosody;
local hosts = prosody.hosts;
local connlisteners_register = require "net.connlisteners".register;

local stun_listener = { default_port = 3478; default_mode = "*a"; default_interface = "*" };

local hex2bin = {
	["0"] = "0000",
	["1"] = "0001",
	["2"] = "0010",
	["3"] = "0011",
	["4"] = "0100",
	["5"] = "0101",
	["6"] = "0110",
	["7"] = "0111",
	["8"] = "1000",
	["9"] = "1001",
	["a"] = "1010",
        ["b"] = "1011",
        ["c"] = "1100",
        ["d"] = "1101",
        ["e"] = "1110",
        ["f"] = "1111"
	}

function hex_to_bin(data)
	local ret = ""
	local i = 0
	
	for i in string.gfind(data, ".") do
		i = string.lower(i)
		ret = ret..hex2bin[i]
	end
	
	return ret
end

function dec_to_bin(data, num)
	local n
	if (num = nil) then
		n = 0
	else
		n = data
	end

	data = string.format("%x", data)
	data = hex_to_bin(data)
	
	while string.len(s) < n do
		s = "0"..s
	end

	return s
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

                if data:match("0x0001") then
			port = conn:port()
			ip = conn:ip()
			local ip_parts = ""
			for ip_part in string.gmatch(ip, "%d+") do 
				ip_parts..dec_to_bin(ip_part, 8)
			end

                        d = "00000000".."00000001"..dec_to_bin(port, 8)..ip_parts
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
