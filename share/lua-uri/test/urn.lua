require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test uri.urn")

function testcase:test_urn_parsing ()
    local uri = assert(URI:new("urn:x-FOO-01239-:Nss"))
    is("urn:x-foo-01239-:Nss", uri:uri())
    is("urn", uri:scheme())
    is("x-foo-01239-:Nss", uri:path())
    is("x-foo-01239-", uri:nid())
    is("Nss", uri:nss())
    is(nil, uri:userinfo())
    is(nil, uri:host())
    is(nil, uri:port())
    is(nil, uri:query())
    is(nil, uri:fragment())
end

function testcase:test_set_nss ()
    local uri = assert(URI:new("urn:x-FOO-01239-:Nss"))
    is("Nss", uri:nss("FooBar"))
    is("urn:x-foo-01239-:FooBar", tostring(uri))
    assert_error("bad NSS, empty", function () uri:nss("") end)
    assert_error("bad NSS, illegal character", function () uri:nss('x"y') end)
    is("urn:x-foo-01239-:FooBar", tostring(uri))
end

function testcase:test_bad_urn_syntax ()
    is_bad_uri("missing nid", "urn::bar")
    is_bad_uri("hyphen at start of nid", "urn:-x-foo:bar")
    is_bad_uri("plus in middle of nid", "urn:x+foo:bar")
    is_bad_uri("underscore in middle of nid", "urn:x_foo:bar")
    is_bad_uri("dot in middle of nid", "urn:x.foo:bar")
    is_bad_uri("nid too long", "urn:x-012345678901234567890123456789x:bar")
    is_bad_uri("reserved 'urn' nid", "urn:urn:bar")
    is_bad_uri("missing nss", "urn:x-foo:")
    is_bad_uri("bad char in nss", "urn:x-foo:bar&")
    is_bad_uri("shoudn't have host part", "urn://foo.com/x-foo:bar")
    is_bad_uri("shoudn't have query part", "urn:x-foo:bar?baz")
end

function testcase:test_change_nid ()
    local urn = assert(URI:new("urn:x-foo:14734966"))
    is("urn:x-foo:14734966", tostring(urn))
    is("x-foo", urn:nid())
    is("uri.urn", urn._NAME)

    -- x-foo -> x-bar
    is("x-foo", urn:nid("X-BAR"))
    is("x-bar", urn:nid())
    is("urn:x-bar:14734966", tostring(urn))
    is("uri.urn", urn._NAME)

    -- x-bar -> issn
    is("x-bar", urn:nid("issn"))
    is("issn", urn:nid())
    is("urn:issn:1473-4966", tostring(urn))
    is("uri.urn.issn", urn._NAME)

    -- issn -> x-foo
    is("issn", urn:nid("x-foo"))
    is("x-foo", urn:nid())
    is("urn:x-foo:1473-4966", tostring(urn))
    is("uri.urn", urn._NAME)
end

function testcase:test_change_nid_bad ()
    local urn = assert(URI:new("urn:x-foo:frob"))

    -- Try changing the NID to something invalid
    assert_error("bad NID 'urn'", function () urn:nid("urn") end)
    assert_error("bad NID '-x-foo'", function () urn:nid("-x-foo") end)
    assert_error("bad NID 'x+foo'", function () urn:nid("x+foo") end)

    -- Change to valid NID, but where the NSS is not valid for it
    assert_error("bad NSS for ISSN URN", function () urn:nid("issn") end)

    -- Original URN should be left unchanged
    is("urn:x-foo:frob", tostring(urn))
    is("x-foo", urn:nid())
    is("uri.urn", urn._NAME)
end

function testcase:test_change_path ()
    local urn = assert(URI:new("urn:x-foo:foopath"))
    is("x-foo:foopath", urn:path())

    -- x-foo -> x-bar
    is("x-foo:foopath", urn:path("X-BAR:barpath"))
    is("x-bar:barpath", urn:path())
    is("urn:x-bar:barpath", tostring(urn))
    is("uri.urn", urn._NAME)

    -- x-bar -> issn
    is("x-bar:barpath", urn:path("issn:14734966"))
    is("issn:1473-4966", urn:path())
    is("urn:issn:1473-4966", tostring(urn))
    is("uri.urn.issn", urn._NAME)

    -- issn -> x-foo
    is("issn:1473-4966", urn:path("x-foo:foopath2"))
    is("x-foo:foopath2", urn:path())
    is("urn:x-foo:foopath2", tostring(urn))
    is("uri.urn", urn._NAME)
end

function testcase:test_change_path_bad ()
    local urn = assert(URI:new("urn:x-foo:frob"))

    -- Try changing the NID to something invalid
    assert_error("bad NID 'urn'", function () urn:path("urn:frob") end)
    assert_error("bad NID '-x-foo'", function () urn:path("-x-foo:frob") end)
    assert_error("bad NID 'x+foo'", function () urn:path("x+foo:frob") end)
    assert_error("bad NSS, empty", function () urn:path("x-foo:") end)
    assert_error("bad NSS, bad char", function () urn:path('x-foo:x"y') end)

    -- Change to valid NID, but where the NSS is not valid for it
    assert_error("bad NSS for ISSN URN", function () urn:path("issn:frob") end)

    -- Original URN should be left unchanged
    is("urn:x-foo:frob", tostring(urn))
    is("x-foo:frob", urn:path())
    is("x-foo", urn:nid())
    is("frob", urn:nss())
    is("uri.urn", urn._NAME)
end

function testcase:test_set_disallowed_stuff ()
    local urn = assert(URI:new("urn:x-foo:frob"))
    assert_error("can't set userinfo", function () urn:userinfo("x") end)
    assert_error("can't set host", function () urn:host("x") end)
    assert_error("can't set port", function () urn:port(23) end)
    assert_error("can't set query", function () urn:query("x") end)
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
