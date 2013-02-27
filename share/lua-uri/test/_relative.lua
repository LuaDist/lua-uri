require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test 'uri._relative' class")

local function test_rel (input, userinfo, host, port, path, query, frag,
                         expected)
    local uri = assert(URI:new(input))
    assert_true(uri:is_relative())
    is("uri._relative", getmetatable(uri)._NAME)
    is(nil, uri:scheme())
    is(userinfo, uri:userinfo())
    is(host, uri:host())
    is(port, uri:port())
    is(path, uri:path())
    is(query, uri:query())
    is(frag, uri:fragment())
    if not expected then expected = input end
    is(expected, uri:uri())
    is(expected, tostring(uri))
end

function testcase:test_relative ()
    test_rel("", nil, nil, nil, "", nil, nil)
    test_rel("foo/bar", nil, nil, nil, "foo/bar", nil, nil)
    test_rel("/foo/bar", nil, nil, nil, "/foo/bar", nil, nil)
    test_rel("?query", nil, nil, nil, "", "query", nil)
    test_rel("?", nil, nil, nil, "", "", nil)
    test_rel("#foo", nil, nil, nil, "", nil, "foo")
    test_rel("#", nil, nil, nil, "", nil, "")
    test_rel("?q#f", nil, nil, nil, "", "q", "f")
    test_rel("?#", nil, nil, nil, "", "", "")
    test_rel("foo?q#f", nil, nil, nil, "foo", "q", "f")
    test_rel("//host.com", nil, "host.com", nil, "", nil, nil)
    test_rel("//host.com/blah?q#f", nil, "host.com", nil, "/blah", "q", "f")
    test_rel("//host.com:123/blah?q#f", nil, "host.com", 123, "/blah", "q", "f")
    test_rel("//u:p@host.com:123/blah?q#f",
             "u:p", "host.com", 123, "/blah", "q", "f")

    -- Paths shouldn't be normalized in a relative reference, only after it
    -- has been used to create an absolute one.
    test_rel("./foo/bar", nil, nil, nil, "./foo/bar", nil, nil)
    test_rel("././foo/./bar", nil, nil, nil, "././foo/./bar", nil, nil)
    test_rel("../foo/bar", nil, nil, nil, "../foo/bar", nil, nil)
    test_rel("../../foo/../bar", nil, nil, nil, "../../foo/../bar", nil, nil)
end

function testcase:test_bad_usage ()
    local uri = assert(URI:new("foo"))
    assert_error("set scheme on relative ref",
                 function () uri:scheme("x-foo") end)
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
