require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test uri.rtsp and uri.rtspu")

function testcase:test_rtsp ()
    local u = assert(URI:new("RTSP://MEDIA.EXAMPLE.COM:554/twister/audiotrack"))
    is("rtsp://media.example.com/twister/audiotrack", tostring(u))
    is("media.example.com", u:host())
    is("/twister/audiotrack", u:path())
end

function testcase:test_rtspu ()
    local uri = assert(URI:new("rtspu://media.perl.com/f%C3%B4o.smi/"))
    is("rtspu://media.perl.com/f%C3%B4o.smi/", tostring(uri))
    is("media.perl.com", uri:host())
    is("/f%C3%B4o.smi/", uri:path())
end

function testcase:test_switch_scheme ()
    -- Should be no problem switching between TCP and UDP URIs, because they
    -- have the same syntax.
    local uri = assert(URI:new("rtsp://media.example.com/twister/audiotrack"))
    is("rtsp://media.example.com/twister/audiotrack", tostring(uri))
    is("rtsp", uri:scheme("rtspu"))
    is("rtspu://media.example.com/twister/audiotrack", tostring(uri))
    is("rtspu", uri:scheme("rtsp"))
    is("rtsp://media.example.com/twister/audiotrack", tostring(uri))
    is("rtsp", uri:scheme())
end

function testcase:test_rtsp_default_port ()
    local uri = assert(URI:new("rtsp://host/path/"))
    is(554, uri:port())
    uri = assert(URI:new("rtspu://host/path/"))
    is(554, uri:port())

    is(554, uri:port(8554))
    is("rtspu://host:8554/path/", tostring(uri))
    is(8554, uri:port(554))
    is("rtspu://host/path/", tostring(uri))
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
