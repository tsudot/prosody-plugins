local st = require "util.stanza";
local jid = require "util.jid";
local http = require "socket.http";
local dataforms_new = require "util.dataforms".new;
local requests = {};


local function generate_captcha(event)
    local session, stanza = event.origin, event.stanza;
    local node, host, resource = jid.split(stanza.attr.to)
    local url = "http://www.google.com/recaptcha/api/"
    local result, statuscode, content = http.request("http://www.google.com/recaptcha/api/noscript","k=6LfCpsMSAAAAANFxM-ji6ct8drXYBHITxNQRnlAx")

    local ip = session.ip;
    local private_key = "6LfCpsMSAAAAAKmUMphjzqNvHZyd3IjtBeNjmyDR"

    local img_src = result:match([[<img .*alt="".* src="([^"]+)"]])
    url = url..img_src
    
    if # requests[session.attr.from] >= 1 then
        table.insert(requests[session.attr.from], img_src)
    else
        requests[session.attr.from] = {};
        requests[session.attr.from][img_src] = true;
    end

    local reply = st.reply(stanza);
    reply:tag("body"):text("Enter the valid keys"):up()
        :tag("x", {xmlns="jabber:x:oob"}):tag("url"):text("some_url"):up():up()
        :tag("captcha", {xmlns="urn:xmpp:captcha"})
        :tag("x", {xmlns="jabber:x:data", type="form"})
        :tag("field", {type="hidden", var="FORM_TYPE"}):tag("value"):text("urn:xmpp:captcha"):up():up()
        :tag("field", {type="hidden", var="from"}):tag("value"):text(host):up():up()
        :tag("field", {type="hidden", var="challenge"}):tag("value"):text(img_src):up():up()
        :tag("field", {type="hidden", var="sid"}):tag("value"):text("Check1"):up():up()
        :tag("field", {var="ocr", label="Enter the text"})
        :tag("media", {xmmlns = "urn:xmpp:media-element", height="80", width="290"})
        :tag("uri", {type="image/jpeg"}):text(url):up():up()

    session.send(reply);

end

local captcha_response_layout = dataforms_new{
    {name = "FORM_TYPE", value = "urn:xmpp:captcha"};
    {name = "challenge", label = "challenge_id"};
    {name = "sid", label = "sid"};
    {name = "ocr", label = "ocr"};
};


local function verify_response(event)
    local pri_key = "6LfCpsMSAAAAAKmUMphjzqNvHZyd3IjtBeNjmyDR";
    local session, stanza = event.origin, event.stanza;
    local node, host, resource = jid.split(stanza.attr.to);
    local captcha_data = {};
    captcha_data.from = stanza.attr.from;
    captcha_data.form = stanza.tags[1]:get_child("x", "jabber:x:data");
    local fields = captcha_response_layout:data(captcha_data.form);
    if requests[session.attr.from] and requests[session.attr.from][fields.challenge] and fields.ocr ~= "" then
        requests[session.attr.from][fields.challenge] = nil;
        local headers = { privatekey = pri_key,
                          remoteip = session.ip,
                          challenge = fields.challenge,
                          response = fields.ocr
                      };

        local r, s, c = http.request{ method="POST",
            url="http://www.google.com/recaptcha/api/verify",
            headers=headers
        }

        if not r then
            session.send(st.error_reply(stanza, "cancel", "service-unavailable", "Not a valid input"));
        else
            origin.send(st.iq({type="result", from=host}));
        end
    else 
        session.send(st.error_reply(stanza, "cancel", "service-unavailable", "Not a valid input"));
    end
end

module:hook("presence/full", generate_captcha, 20);
module:hook("iq-set/host/urn:xmpp:captcha:captcha", verify_response)
