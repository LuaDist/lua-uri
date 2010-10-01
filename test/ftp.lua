require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test uri.ftp")

function testcase:test_ftp ()
    local uri = assert(URI:new("ftp://ftp.example.com/path"))
    is("ftp", uri:scheme())
    is("ftp.example.com", uri:host())
    is(21, uri:port())
    is(nil, uri:userinfo())
    is(nil, uri:username())
    is(nil, uri:password())
end

function testcase:test_ftp_typecode ()
    local uri = assert(URI:new("ftp://host/path"))
    is(nil, uri:ftp_typecode())
    is(nil, uri:ftp_typecode("d"))
    is("/path;type=d", uri:path())
    is("ftp://host/path;type=d", tostring(uri))
    is("d", uri:ftp_typecode("a"))
    is("/path;type=a", uri:path())
    is("ftp://host/path;type=a", tostring(uri))
    is("a", uri:ftp_typecode(""))
    is("/path", uri:path())
    is("ftp://host/path", tostring(uri))

    local uri = assert(URI:new("ftp://host/path;type=xyzzy"))
    is("/path;type=xyzzy", uri:path())
    is("ftp://host/path;type=xyzzy", tostring(uri))
    is("xyzzy", uri:ftp_typecode())
    is("xyzzy", uri:ftp_typecode(nil))
    is(nil, uri:ftp_typecode())
    is("/path", uri:path())
    is("ftp://host/path", tostring(uri))
end

function testcase:test_normalize_path ()
    local uri = assert(URI:new("ftp://host"))
    is("ftp://host/", tostring(uri))
    is("/", uri:path("/foo"))
    is("/foo", uri:path(""))
    is("/", uri:path("/foo"))
    is("/foo", uri:path(nil))
    is("/", uri:path())
end

function testcase:test_bad_host ()
    is_bad_uri("missing authority, just scheme", "ftp:")
    is_bad_uri("missing authority, just scheme and path", "ftp:/foo")
    is_bad_uri("empty host", "ftp:///foo")
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
