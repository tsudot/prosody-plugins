local st = require "util.stanza";
local jid = require "util.jid";
local http = require "socket.http";


local function generate_captcha()
--    local session, stanza = event.origin, event.stanza;
--    local node, host, resource = jid.split(stanza.attr.to)
    local url = "http://www.google.com/recaptcha/api/"
    local result, statuscode, content = http.request("http://www.google.com/recaptcha/api/noscript","k=6LfCpsMSAAAAANFxM-ji6ct8drXYBHITxNQRnlAx")

--    local ip = session.ip;
    local private_key = "6LfCpsMSAAAAAKmUMphjzqNvHZyd3IjtBeNjmyDR"

    local img_src = result:match([[<img .*alt="".* src="([^"]+)"]])
    url = url..img_src

--    local dataform_new = require "util.dataforms".new
--    local captcha_layout = dataform_new{
--        {name = "FORM_TYPE", type = "hidden", value = "urn:xmpp:captcha" };
--        {name = "from", type = "hidden", value = host };
--        {name = "challenge", type = "hidden", value = img_src };
--        {name = "sid", type = "hidden", value = "Check 1" };
--    };

--    local fields = captcha_layout:data(data.form);

    local reply = st.stanza("message");
    reply:tag("body"):text("Enter the valid keys"):up()
        :tag("x", {xmlns="jabber:x:oob"}):tag("url"):text("some_url"):up():up()
        :tag("captcha", {xmlns="urn:xmpp:captcha"})
        :tag("x", {xmlns="jabber:x:data", type="form"})
        :tag("field", {type="hidden", var="FORM_TYPE"}):tag("value"):text("urn:xmpp:captcha"):up():up()
        :tag("field", {type="hidden", var="from"}):tag("value"):text("host"):up():up()
        :tag("field", {type="hidden", var="challenge"}):tag("value"):text(img_src):up():up()
        :tag("field", {type="hidden", var="sid"}):tag("value"):text("Check 1"):up():up()
        :tag("field", {var="ocr", label="Enter the text"})
        :tag("media", {xmmlns = "urn:xmpp:media-element", height="80", width="290"})
        :tag("uri", {type="image/jpeg"}):text(url):up():up()

    print (reply);
end

generate_captcha()

