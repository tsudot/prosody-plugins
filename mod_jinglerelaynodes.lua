local st = require "util.stanza";
local host = module:get_host();
local stun_ip = module:get_option('stun_ip');
local stun_port = module:get_option_number('stun_port');
local uuid = require "util.uuid";

module:add_feature('http://jabber.org/protocol/jinglenodes');

module:hook('iq-get/host/http://jabber.org/protocol/jinglenodes', function(event)
    local session, stanza = event.origin, event.stanza;
    local reply =  st.iq({type='result', id=stanza.attr.id, from=host, to=stanza.attr.from})
    
    reply:tag("services", {xmlns="http://jabber.org/protocol/jinglenodes"})
        :tag("relay", {policy="public", address=host, protocol="udp"}):up()
        :tag("tracker", {policy="public", address=host, protocol="udp"}):up()
        :tag("stun", {policy="public", address=stun_ip, port=stun_port, protocol="udp"}):up()

    session.send(reply);
end);

module:hook('iq-get/host/http://jabber.org/protocol/jinglenodes#channel', function(event)
    local session, stanza = event.origin, event.stanza;
    local reply = st.iq({type='result', id=stanza.attr.id, from=host, to=stanza.attr.from})

    reply:tag("channel", { id = uuid.generate(),
                           host = host,
                           localport = "35800",
                           remoteport = "35802",
                           protocol = "udp",
                           expire = "60"
                       })

    session.send(reply)
end);
