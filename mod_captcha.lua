local st = require "util.stanza";
local jid = require "util.jid";
local http = require "net.http";
local dataforms_new = require "util.dataforms".new;
local array = require "util.array";
local requests = {};
local events = {};
local private_key = "6LfCpsMSAAAAAKmUMphjzqNvHZyd3IjtBeNjmyDR"

local function generate_captcha_response(event, result, status, r)
    local url = "http://www.google.com/recaptcha/api/";
    local session, stanza = event.origin, event.stanza;
    local node, host, resource = jid.split(stanza.attr.to);
    local ip = session.ip;
    local img_src = result:match([[<img .*alt="".* src="([^"]+)"]])
    url = url..img_src
    local challenge_id = img_src:match("=.+")
    local sid = stanza.attr.id;
    if requests[stanza.attr.from] then
        requests[stanza.attr.from][img_src] = true;
    else
        requests[stanza.attr.from] = {};
        requests[stanza.attr.from][img_src] = true;
    end

    -- Store events here for firing later
    events[challenge_id] = event

    stanza.name = "message";

    local reply = st.reply(stanza);
    reply:tag("body"):text("Please visit "..url.." to unblock your messages"):up()
        :tag("x", {xmlns="jabber:x:oob"}):tag("url"):text("some_url"):up():up()
        :tag("captcha", {xmlns="urn:xmpp:captcha"})
        :tag("x", {xmlns="jabber:x:data", type="form"})
        :tag("field", {type="hidden", var="FORM_TYPE"}):tag("value"):text("urn:xmpp:captcha"):up():up()
        :tag("field", {type="hidden", var="from"}):tag("value"):text(host):up():up()
        :tag("field", {type="hidden", var="challenge"}):tag("value"):text(challenge_id):up():up()
        :tag("field", {type="hidden", var="sid"}):tag("value"):text(sid):up():up()
        :tag("field", {var="ocr", label="Enter the text"})
        :tag("media", {xmmlns = "urn:xmpp:media-element", height="80", width="290"})
        :tag("uri", {type="image/jpeg"}):text(url):up():up()


    if session.type == "component" then
        return
    else
        session.send(reply);
    end
end

local function generate_captcha(event)
    local stanza = event.stanza;
    if stanza.attr.captcha_verified and stanza.attr.captcha_verified == "true" then
        return nil
    else
        local options = {}
        options.body = "k=6LfCpsMSAAAAANFxM-ji6ct8drXYBHITxNQRnlAx";
        local request_url = "http://www.google.com/recaptcha/api/noscript";
        http.request(request_url, options, function(...) return generate_captcha_response(event, ...) end);
    end

end

local captcha_response_layout = dataforms_new{
    title = "Captcha Form";
    instructions = "Enter the valid keys";
    {name = "FORM_TYPE", type="hidden", value = "urn:xmpp:captcha"};
    {name = "from", type="hidden", label = "from"};
    {name = "challenge",type="text-single", label = "challenge"};
    {name = "sid",type="hidden", label = "sid"};
    {name = "ocr",type="text-single", label = "ocr"};
};

local function verify_captcha_response(event, challenge_id, result, status, r)
    local session, stanza = event.origin, event.stanza;
    local node, host, resource = jid.split(stanza.attr.to);
    local entries = {}
    for entry in result:gmatch("[^\n]+") do
        table.insert(entries, entry);
    end

    if entries[1] and entries[1]=="true" then
        session.send(st.iq({type="result", from=host}));
        -- fire the original event again with an added field of captcha_verified = 'true'
        local original_event = events.challenge_id;
        original_event.stanza.attr.verifired = "true";
        module:fire_event("presence/full", original_event)
    else
        session.send(st.error_reply(stanza, "cancel", "service-unavailable", "Not a valid input"));
    end
end

local function verify_captcha(event)
    local pri_key = "6LfCpsMSAAAAAKmUMphjzqNvHZyd3IjtBeNjmyDR";
    local session, stanza = event.origin, event.stanza;
    local captcha_form = stanza.tags[1]:get_child("x", "jabber:x:data");
    local fields = captcha_response_layout:data(captcha_form);
    local url = "http://www.google.com/recaptcha/api/verify";
    if requests[stanza.attr.from] and requests[stanza.attr.from][fields.challenge] and fields.ocr ~= "" then
        requests[stanza.attr.from][fields.challenge] = nil;
        local options = {}
        options.body = "privatekey="..pri_key.."&remoteip="..session.ip.."&challenge="..fields.challenge.."&response="..fields.ocr
        http.request(url, options, function(...) return verify_captcha_response(event, fields.challenge, ...) end);
    end
end


module:hook("presence/full", generate_captcha, 20);
module:hook("iq-set/host/urn:xmpp:captcha:captcha", verify_captcha)
