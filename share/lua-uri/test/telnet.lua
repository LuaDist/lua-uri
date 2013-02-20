require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test uri.telnet and uri._login")

-- This tests the generic login stuff ('username' and 'password' methods, and
-- additional userinfo validation), as well as the stuff specific to telnet.

function testcase:test_telnet ()
    local uri = assert(URI:new("telnet://telnet.example.com/"))
    is("telnet://telnet.example.com/", uri:uri())
    is("telnet://telnet.example.com/", tostring(uri))
    is("uri.telnet", uri._NAME)
    is("telnet", uri:scheme())
    is("telnet.example.com", uri:host())
    is("/", uri:path())
end

function testcase:test_telnet_normalize ()
    local uri = assert(URI:new("telnet://user:password@host.com"))
    is("telnet://user:password@host.com/", tostring(uri))
    is("/", uri:path())
    is(23, uri:port())
    uri = assert(URI:new("telnet://user:password@host.com:23/"))
    is("telnet://user:password@host.com/", tostring(uri))
    is("/", uri:path())
    is(23, uri:port())
end

function testcase:test_telnet_invalid ()
    is_bad_uri("no authority, empty path", "telnet:")
    is_bad_uri("no authority, normal path", "telnet:/")
    is_bad_uri("empty authority, empty path", "telnet://")
    is_bad_uri("empty authority, normal path", "telnet:///")
    is_bad_uri("bad path /x", "telnet://host/x")
    is_bad_uri("bad path //", "telnet://host//")
end

function testcase:test_telnet_set_path ()
    local uri = assert(URI:new("telnet://foo/"))
    is("/", uri:path("/"))
    is("/", uri:path(""))
    is("/", uri:path(nil))
    is("/", uri:path())
end

function testcase:test_telnet_set_bad_path ()
    local uri = assert(URI:new("telnet://foo/"))
    assert_error("bad path x", function () uri:path("x") end)
    assert_error("bad path /x", function () uri:path("/x") end)
    assert_error("bad path //", function () uri:path("//") end)
end

-- These test the generic stuff in uri._login.  Some of the examples are
-- directly from RFC 1738 section 3.1, but substituting 'telnet' for 'ftp'.
function testcase:test_telnet_userinfo ()
    local uri = assert(URI:new("telnet://host.com/"))
    is(nil, uri:userinfo())
    is(nil, uri:username())
    is(nil, uri:password())
    uri = assert(URI:new("telnet://foo:bar@host.com/"))
    is("foo:bar", uri:userinfo())
    is("foo", uri:username())
    is("bar", uri:password())
    uri = assert(URI:new("telnet://%3a%40:%3a%40@host.com/"))
    is("%3A%40:%3A%40", uri:userinfo())
    is(":@", uri:username())
    is(":@", uri:password())
    uri = assert(URI:new("telnet://foo:@host.com/"))
    is("foo:", uri:userinfo())
    is("foo", uri:username())
    is("", uri:password())
    uri = assert(URI:new("telnet://@host.com/"))
    is("", uri:userinfo())
    is("", uri:username())
    is(nil, uri:password())
    uri = assert(URI:new("telnet://:@host.com/"))
    is(":", uri:userinfo())
    is("", uri:username())
    is("", uri:password())
end

function testcase:test_telnet_set_userinfo ()
    local uri = assert(URI:new("telnet://host.com/"))
    is(nil, uri:userinfo(""))
    is("telnet://@host.com/", tostring(uri))
    is("", uri:userinfo(":"))
    is("telnet://:@host.com/", tostring(uri))
    is(":", uri:userinfo("foo:"))
    is("telnet://foo:@host.com/", tostring(uri))
    is("foo:", uri:userinfo(":bar"))
    is("telnet://:bar@host.com/", tostring(uri))
    is(":bar", uri:userinfo("foo:bar"))
    is("telnet://foo:bar@host.com/", tostring(uri))
    is("foo:bar", uri:userinfo())
end

function testcase:test_telnet_set_bad_userinfo ()
    local uri = assert(URI:new("telnet://host.com/"))
    assert_error("more than one colon", function () uri:userinfo("x::y") end)
    assert_error("invalid character", function () uri:userinfo("x/y") end)
end

function testcase:test_telnet_set_username ()
    local uri = assert(URI:new("telnet://host.com/"))
    is(nil, uri:username("foo"))
    is(nil, uri:password())
    is("telnet://foo@host.com/", tostring(uri))
    is("foo", uri:username("x:y@z%"))
    is(nil, uri:password())
    is("telnet://x%3Ay%40z%25@host.com/", tostring(uri))
    is("x:y@z%", uri:username(""))
    is(nil, uri:password())
    is("telnet://@host.com/", tostring(uri))
    is("", uri:username(nil))
    is(nil, uri:password())
    is("telnet://host.com/", tostring(uri))
    is(nil, uri:username())
end

function testcase:test_telnet_set_password ()
    local uri = assert(URI:new("telnet://host.com/"))
    is(nil, uri:password("foo"))
    is("", uri:username())
    is("telnet://:foo@host.com/", tostring(uri))
    is("foo", uri:password("x:y@z%"))
    is("", uri:username())
    is("telnet://:x%3Ay%40z%25@host.com/", tostring(uri))
    is("x:y@z%", uri:password(""))
    is("", uri:username())
    is("telnet://:@host.com/", tostring(uri))
    is("", uri:password(nil))
    is("", uri:username())
    is("telnet://@host.com/", tostring(uri))
    is("", uri:username(nil))
    is(nil, uri:password(nil))
    is("telnet://host.com/", tostring(uri))
    is(nil, uri:password())
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
