require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test 'uri' base class")

function testcase:test_normalize_percent_encoding ()
    -- Don't use unnecessary percent encoding for unreserved characters.
    test_norm("x:ABCDEFGHIJKLM", "x:%41%42%43%44%45%46%47%48%49%4A%4b%4C%4d")
    test_norm("x:NOPQRSTUVWXYZ", "x:%4E%4f%50%51%52%53%54%55%56%57%58%59%5A")
    test_norm("x:abcdefghijklm", "x:%61%62%63%64%65%66%67%68%69%6A%6b%6C%6d")
    test_norm("x:nopqrstuvwxyz", "x:%6E%6f%70%71%72%73%74%75%76%77%78%79%7A")
    test_norm("x:0123456789", "x:%30%31%32%33%34%35%36%37%38%39")
    test_norm("x:-._~", "x:%2D%2e%5F%7e")

    -- Keep percent encoding for other characters in US-ASCII.
    test_norm_already("x:%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F")
    test_norm_already("x:%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F")
    test_norm_already("x:%20%21%22%23%24%25%26%27%28%29%2A%2B%2C")
    test_norm_already("x:%2F")
    test_norm_already("x:%3A%3B%3C%3D%3E%3F%40")
    test_norm_already("x:%5B%5C%5D%5E")
    test_norm_already("x:%60")
    test_norm_already("x:%7B%7C%7D")
    test_norm_already("x:%7F")

    -- Normalize hex digits in percent encoding to uppercase.
    test_norm("x:%0A%0B%0C%0D%0E%0F", "x:%0a%0b%0c%0d%0e%0f")
    test_norm("x:%AA%BB%CC%DD%EE%FF", "x:%aA%bB%cC%dD%eE%fF")

    -- Keep percent encoding, and normalize hex digit case, for all characters
    -- outside US-ASCII.
    for i = 0x80, 0xFF do
        test_norm_already(string.format("x:%%%02X", i))
        test_norm(string.format("x:%%%02X", i), string.format("x:%%%02x", i))
    end
end

function testcase:test_bad_percent_encoding ()
    assert_error("double percent", function () URI:new("x:foo%%2525") end)
    assert_error("no hex digits", function () URI:new("x:foo%") end)
    assert_error("no hex digits 2nd time", function () URI:new("x:f%20o%") end)
    assert_error("1 hex digit", function () URI:new("x:foo%2") end)
    assert_error("1 hex digit 2nd time", function () URI:new("x:f%20o%2") end)
    assert_error("bad hex digit 1", function () URI:new("x:foo%G2bar") end)
    assert_error("bad hex digit 2", function () URI:new("x:foo%2Gbar") end)
    assert_error("bad hex digit both", function () URI:new("x:foo%GGbar") end)
end

function testcase:test_scheme ()
    test_norm_already("foo:")
    test_norm_already("foo:-+.:")
    test_norm_already("foo:-+.0123456789:")
    test_norm_already("x:")
    test_norm("example:FooBar:Baz", "ExAMplE:FooBar:Baz")

    local uri = assert(URI:new("Foo-Bar:Baz%20Quux"))
    is("foo-bar", uri:scheme())
end

function testcase:test_change_scheme ()
    local uri = assert(URI:new("x-foo://example.com/blah"))
    is("x-foo://example.com/blah", tostring(uri))
    is("x-foo", uri:scheme())
    is("uri", uri._NAME)

    -- x-foo -> x-bar
    is("x-foo", uri:scheme("x-bar"))
    is("x-bar", uri:scheme())
    is("x-bar://example.com/blah", tostring(uri))
    is("uri", uri._NAME)

    -- x-bar -> http
    is("x-bar", uri:scheme("http"))
    is("http", uri:scheme())
    is("http://example.com/blah", tostring(uri))
    is("uri.http", uri._NAME)

    -- http -> x-foo
    is("http", uri:scheme("x-foo"))
    is("x-foo", uri:scheme())
    is("x-foo://example.com/blah", tostring(uri))
    is("uri", uri._NAME)
end

function testcase:test_change_scheme_bad ()
    local uri = assert(URI:new("x-foo://foo@bar/"))

    -- Try changing the scheme to something invalid
    assert_error("bad scheme '-x-foo'", function () uri:scheme("-x-foo") end)
    assert_error("bad scheme 'x,foo'", function () uri:scheme("x,foo") end)
    assert_error("bad scheme 'x:foo'", function () uri:scheme("x:foo") end)
    assert_error("bad scheme 'x-foo:'", function () uri:scheme("x-foo:") end)

    -- Change to valid scheme, but where the rest of the URI is not valid for it
    assert_error("bad HTTP URI", function () uri:scheme("http") end)

    -- Original URI should be left unchanged
    is("x-foo://foo@bar/", tostring(uri))
    is("x-foo", uri:scheme())
    is("uri", uri._NAME)
end

function testcase:test_auth_userinfo ()
    local uri = assert(URI:new("X://a-zA-Z09!$:&%40@FOO.com:80/"))
    is("x://a-zA-Z09!$:&%40@foo.com:80/", tostring(uri))
    is("x", uri:scheme())
    is("a-zA-Z09!$:&%40", uri:userinfo())
    is("foo.com", uri:host())
    is(80, uri:port())
end

function testcase:test_auth_userinfo_bad ()
    is_bad_uri("bad character in userinfo", "x-a://foo^bar@example.com/")
end

function testcase:test_auth_set_userinfo ()
    local uri = assert(URI:new("X-foo://user:pass@FOO.com:80/"))
    is("user:pass", uri:userinfo("newuserinfo"))
    is("newuserinfo", uri:userinfo())
    is("x-foo://newuserinfo@foo.com:80/", tostring(uri))

    -- Userinfo should be supplied already percent-encoded, but the percent
    -- encoding should be normalized.
    is("newuserinfo", uri:userinfo("foo%3abar%3A:%78"))
    is("foo%3Abar%3A:x", uri:userinfo())

    -- It should be OK to use more than one colon in userinfo for generic URIs,
    -- although not for ones which specificly divide it into username:password.
    is("foo%3Abar%3A:x", uri:userinfo("foo:bar:baz::"))
    is("foo:bar:baz::", uri:userinfo())
end

function testcase:test_auth_set_bad_userinfo ()
    local uri = assert(URI:new("X-foo://user:pass@FOO.com:80/"))
    assert_error("/ in userinfo", function () uri:userinfo("foo/bar") end)
    assert_error("@ in userinfo", function () uri:userinfo("foo@bar") end)
    is("user:pass", uri:userinfo())
    is("x-foo://user:pass@foo.com:80/", tostring(uri))
end

function testcase:test_auth_reg_name ()
    local uri = assert(URI:new("x://azAZ0-9--foo.bqr_baz~%20!$;/"))
    -- TODO - %20 should probably be rejected.  Apparently only UTF-8 pctenc
    -- should be produced, so after unescaping unreserved chars there should
    -- be nothing left percent encoded other than valid UTF-8 sequences.  If
    -- that's right I could safely decode the host before returning it.
    is("azaz0-9--foo.bqr_baz~%20!$;", uri:host())
end

function testcase:test_auth_ip4 ()
    local uri = assert(URI:new("x://0.0.0.0/path"))
    is("0.0.0.0", uri:host())
    uri = assert(URI:new("x://192.168.0.1/path"))
    is("192.168.0.1", uri:host())
    uri = assert(URI:new("x://255.255.255.255/path"))
    is("255.255.255.255", uri:host())
end

function testcase:test_auth_ip4_or_reg_name_bad ()
    is_bad_uri("bad character in host part", "x://foo:bar/")
end

function testcase:test_auth_ip6 ()
    -- The example addresses in here are all from RFC 4291 section 2.2, except
    -- that they get normalized to lowercase here in the results.
    local uri = assert(URI:new("x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]"))
    is("[abcd:ef01:2345:6789:abcd:ef01:2345:6789]", uri:host())
    uri = assert(URI:new("x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]/"))
    is("[abcd:ef01:2345:6789:abcd:ef01:2345:6789]", uri:host())
    uri = assert(URI:new("x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]:"))
    is("[abcd:ef01:2345:6789:abcd:ef01:2345:6789]", uri:host())
    uri = assert(URI:new("x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]:/"))
    is("[abcd:ef01:2345:6789:abcd:ef01:2345:6789]", uri:host())
    uri = assert(URI:new("x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]:0/"))
    is("[abcd:ef01:2345:6789:abcd:ef01:2345:6789]", uri:host())
    uri = assert(URI:new("x://y:z@[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]:80/"))
    is("[abcd:ef01:2345:6789:abcd:ef01:2345:6789]", uri:host())
    uri = assert(URI:new("x://[2001:DB8:0:0:8:800:200C:417A]/"))
    is("[2001:db8:0:0:8:800:200c:417a]", uri:host())
    uri = assert(URI:new("x://[FF01:0:0:0:0:0:0:101]/"))
    is("[ff01:0:0:0:0:0:0:101]", uri:host())
    uri = assert(URI:new("x://[ff01::101]/"))
    is("[ff01::101]", uri:host())
    uri = assert(URI:new("x://[0:0:0:0:0:0:0:1]/"))
    is("[0:0:0:0:0:0:0:1]", uri:host())
    uri = assert(URI:new("x://[::1]/"))
    is("[::1]", uri:host())
    uri = assert(URI:new("x://[0:0:0:0:0:0:0:0]/"))
    is("[0:0:0:0:0:0:0:0]", uri:host())
    uri = assert(URI:new("x://[0:0:0:0:0:0:13.1.68.3]/"))
    is("[0:0:0:0:0:0:13.1.68.3]", uri:host())
    uri = assert(URI:new("x://[::13.1.68.3]/"))
    is("[::13.1.68.3]", uri:host())
    uri = assert(URI:new("x://[0:0:0:0:0:FFFF:129.144.52.38]/"))
    is("[0:0:0:0:0:ffff:129.144.52.38]", uri:host())
    uri = assert(URI:new("x://[::FFFF:129.144.52.38]/"))
    is("[::ffff:129.144.52.38]", uri:host())

    -- These try all the cominations of abbreviating using '::'.
    uri = assert(URI:new("x://[08:19:2a:3B:4c:5D:6e:7F]/"))
    is("[08:19:2a:3b:4c:5d:6e:7f]", uri:host())
    uri = assert(URI:new("x://[::19:2a:3B:4c:5D:6e:7F]/"))
    is("[::19:2a:3b:4c:5d:6e:7f]", uri:host())
    uri = assert(URI:new("x://[::2a:3B:4c:5D:6e:7F]/"))
    is("[::2a:3b:4c:5d:6e:7f]", uri:host())
    uri = assert(URI:new("x://[::3B:4c:5D:6e:7F]/"))
    is("[::3b:4c:5d:6e:7f]", uri:host())
    uri = assert(URI:new("x://[::4c:5D:6e:7F]/"))
    is("[::4c:5d:6e:7f]", uri:host())
    uri = assert(URI:new("x://[::5D:6e:7F]/"))
    is("[::5d:6e:7f]", uri:host())
    uri = assert(URI:new("x://[::6e:7F]/"))
    is("[::6e:7f]", uri:host())
    uri = assert(URI:new("x://[::7F]/"))
    is("[::7f]", uri:host())
    uri = assert(URI:new("x://[::]/"))
    is("[::]", uri:host())
    uri = assert(URI:new("x://[08::]/"))
    is("[08::]", uri:host())
    uri = assert(URI:new("x://[08:19::]/"))
    is("[08:19::]", uri:host())
    uri = assert(URI:new("x://[08:19:2a::]/"))
    is("[08:19:2a::]", uri:host())
    uri = assert(URI:new("x://[08:19:2a:3B::]/"))
    is("[08:19:2a:3b::]", uri:host())
    uri = assert(URI:new("x://[08:19:2a:3B:4c::]/"))
    is("[08:19:2a:3b:4c::]", uri:host())
    uri = assert(URI:new("x://[08:19:2a:3B:4c:5D::]/"))
    is("[08:19:2a:3b:4c:5d::]", uri:host())
    uri = assert(URI:new("x://[08:19:2a:3B:4c:5D:6e::]/"))
    is("[08:19:2a:3b:4c:5d:6e::]", uri:host())

    -- Try extremes of good IPv4 addresses mapped to IPv6.
    uri = assert(URI:new("x://[::FFFF:0.0.0.0]/path"))
    is("[::ffff:0.0.0.0]", uri:host())
    uri = assert(URI:new("x://[::ffff:255.255.255.255]/path"))
    is("[::ffff:255.255.255.255]", uri:host())
end

function testcase:test_auth_ip6_bad ()
    is_bad_uri("empty brackets", "x://[]")
    is_bad_uri("just colon", "x://[:]")
    is_bad_uri("3 colons only", "x://[:::]")
    is_bad_uri("3 colons at start", "x://[:::1234]")
    is_bad_uri("3 colons at end", "x://[1234:::]")
    is_bad_uri("3 colons in middle", "x://[1234:::5678]")
    is_bad_uri("non-hex char", "x://[ABCD:EF01:2345:6789:ABCD:EG01:2345:6789]")
    is_bad_uri("chunk too big",
               "x://[ABCD:EF01:2345:6789:ABCD:EFF01:2345:6789]")
    is_bad_uri("too many chunks",
               "x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789:1]")
    is_bad_uri("not enough chunks", "x://[ABCD:EF01:2345:6789:ABCD:EF01:2345]")
    is_bad_uri("too many chunks with ellipsis in middle",
               "x://[ABCD:EF01:2345:6789:ABCD::EF01:2345:6789]")
    is_bad_uri("too many chunks with ellipsis at end",
               "x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789::]")
    is_bad_uri("too many chunks with ellipsis at start",
               "x://[::ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]")
    is_bad_uri("two elipses, middle and end",
               "x://[EF01:2345::6789:ABCD:EF01:2345::]")
    is_bad_uri("two elipses, start and middle",
               "x://[::EF01:2345::6789:ABCD:EF01:2345]")
    is_bad_uri("two elipses, both ends",
               "x://[::EF01:2345:6789:ABCD:EF01:2345::]")
    is_bad_uri("two elipses, both middle",
               "x://[EF01:2345::6789:ABCD:::EF01:2345]")
    is_bad_uri("extra colon at start",
               "x://[:ABCD:EF01:2345:6789:ABCD:EF01:2345:6789]")
    is_bad_uri("missing chunk at start",
               "x://[:EF01:2345:6789:ABCD:EF01:2345:6789]")
    is_bad_uri("extra colon at end",
               "x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:6789:]")
    is_bad_uri("missing chunk at end",
               "x://[ABCD:EF01:2345:6789:ABCD:EF01:2345:]")

    -- Bad IPv4 addresses mapped to IPv6.
    is_bad_uri("octet 1 too big", "x://[::FFFF:256.2.3.4]/")
    is_bad_uri("octet 2 too big", "x://[::FFFF:1.256.3.4]/")
    is_bad_uri("octet 3 too big", "x://[::FFFF:1.2.256.4]/")
    is_bad_uri("octet 4 too big", "x://[::FFFF:1.2.3.256]/")
    is_bad_uri("octet 1 leading zeroes", "x://[::FFFF:01.2.3.4]/")
    is_bad_uri("octet 2 leading zeroes", "x://[::FFFF:1.02.3.4]/")
    is_bad_uri("octet 3 leading zeroes", "x://[::FFFF:1.2.03.4]/")
    is_bad_uri("octet 4 leading zeroes", "x://[::FFFF:1.2.3.04]/")
    is_bad_uri("only 2 octets", "x://[::FFFF:1.2]/")
    is_bad_uri("only 3 octets", "x://[::FFFF:1.2.3]/")
    is_bad_uri("5 octets", "x://[::FFFF:1.2.3.4.5]/")
end

function testcase:test_auth_ipvfuture ()
    local uri = assert(URI:new("x://[v123456789ABCdef.foo=bar]/"))
    is("[v123456789abcdef.foo=bar]", uri:host())
end

function testcase:test_auth_ipvfuture_bad ()
    is_bad_uri("missing dot", "x://[v999]")
    is_bad_uri("missing hex num", "x://[v.foo]")
    is_bad_uri("missing bit after dot", "x://[v999.]")
    is_bad_uri("bad character in hex num", "x://[v99g.foo]")
    is_bad_uri("bad character after dot", "x://[v999.foo:bar]")
end

function testcase:test_auth_set_host ()
    local uri = assert(URI:new("x-a://host/path"))
    is("host", uri:host("FOO.BAR"))
    is("x-a://foo.bar/path", tostring(uri))
    is("foo.bar", uri:host("[::6e:7F]"))
    is("x-a://[::6e:7f]/path", tostring(uri))
    is("[::6e:7f]", uri:host("[v7F.foo=BAR]"))
    is("x-a://[v7f.foo=bar]/path", tostring(uri))
    is("[v7f.foo=bar]", uri:host(""))
    is("x-a:///path", tostring(uri))
    is("", uri:host(nil))
    is(nil, uri:host())
    is("x-a:/path", tostring(uri))
end

function testcase:test_auth_set_host_bad ()
    local uri = assert(URI:new("x-a://host/path"))
    assert_error("bad char in host", function () uri:host("foo^bar") end)
    assert_error("invalid IPv6 host", function () uri:host("[::3G]") end)
    assert_error("invalid IPvFuture host", function () uri:host("[v7.]") end)
    is("host", uri:host())
    is("x-a://host/path", tostring(uri))
    -- There must be a hsot when there is a userinfo or port.
    uri = assert(URI:new("x-a://foo@/"))
    assert_error("userinfo but no host", function () uri:host(nil) end)
    is("x-a://foo@/", tostring(uri))
    uri = assert(URI:new("x-a://:123/"))
    assert_error("port but no host", function () uri:host(nil) end)
    is("x-a://:123/", tostring(uri))
end

function testcase:test_auth_port ()
    local uri = assert(URI:new("x://localhost:0/path"))
    is(0, uri:port())
    uri = assert(URI:new("x://localhost:0"))
    is(0, uri:port())
    uri = assert(URI:new("x://foo:bar@localhost:0"))
    is(0, uri:port())
    uri = assert(URI:new("x://localhost:00/path"))
    is(0, uri:port())
    uri = assert(URI:new("x://localhost:00"))
    is(0, uri:port())
    uri = assert(URI:new("x://foo:bar@localhost:00"))
    is(0, uri:port())
    uri = assert(URI:new("x://localhost:54321/path"))
    is(54321, uri:port())
    uri = assert(URI:new("x://localhost:54321"))
    is(54321, uri:port())
    uri = assert(URI:new("x://foo:bar@localhost:54321"))
    is(54321, uri:port())
    uri = assert(URI:new("x://foo:bar@localhost:"))
    is(nil, uri:port())
    uri = assert(URI:new("x://foo:bar@localhost:/"))
    is(nil, uri:port())
    uri = assert(URI:new("x://foo:bar@localhost"))
    is(nil, uri:port())
    uri = assert(URI:new("x://foo:bar@localhost/"))
    is(nil, uri:port())
end

function testcase:test_auth_set_port ()
    -- Test unusual but valid values for port.
    local uri = assert(URI:new("x://localhost/path"))
    is(nil, uri:port("12345"))  -- string
    is(12345, uri:port())
    is("x://localhost:12345/path", tostring(uri))
    uri = assert(URI:new("x://localhost/path"))
    is(nil, uri:port(12345.0))  -- float
    is(12345, uri:port())
    is("x://localhost:12345/path", tostring(uri))
end

function testcase:test_auth_set_port_without_host ()
    local uri = assert(URI:new("x:///path"))
    is(nil, uri:port(80))
    is(80, uri:port())
    is("", uri:host())
    is("x://:80/path", tostring(uri))
    uri = assert(URI:new("x:/path"))
    is(nil, uri:port(80))
    is(80, uri:port())
    is("", uri:host())
    is("x://:80/path", tostring(uri))
end

function testcase:test_auth_set_port_bad ()
    local uri = assert(URI:new("x://localhost:54321/path"))
    assert_error("negative port number", function () uri:port(-23) end)
    assert_error("port not integer", function () uri:port(23.00001) end)
    assert_error("string not number", function () uri:port("x") end)
    assert_error("string not all number", function () uri:port("x23") end)
    assert_error("string negative number", function () uri:port("-23") end)
    assert_error("string empty", function () uri:port("") end)
    is(54321, uri:port())
    is("x://localhost:54321/path", tostring(uri))
end

function testcase:test_path ()
    local uri = assert(URI:new("x:"))
    is("", uri:path())
    uri = assert(URI:new("x:?"))
    is("", uri:path())
    uri = assert(URI:new("x:#"))
    is("", uri:path())
    uri = assert(URI:new("x:/"))
    is("/", uri:path())
    uri = assert(URI:new("x://"))
    is("", uri:path())
    uri = assert(URI:new("x://?"))
    is("", uri:path())
    uri = assert(URI:new("x://#"))
    is("", uri:path())
    uri = assert(URI:new("x:///"))
    is("/", uri:path())
    uri = assert(URI:new("x:////"))
    is("//", uri:path())
    uri = assert(URI:new("x:foo"))
    is("foo", uri:path())
    uri = assert(URI:new("x:/foo"))
    is("/foo", uri:path())
    uri = assert(URI:new("x://foo"))
    is("", uri:path())
    uri = assert(URI:new("x://foo?"))
    is("", uri:path())
    uri = assert(URI:new("x://foo#"))
    is("", uri:path())
    uri = assert(URI:new("x:///foo"))
    is("/foo", uri:path())
    uri = assert(URI:new("x:////foo"))
    is("//foo", uri:path())
    uri = assert(URI:new("x://foo/"))
    is("/", uri:path())
    uri = assert(URI:new("x://foo/bar"))
    is("/bar", uri:path())
end

function testcase:test_path_bad ()
    is_bad_uri("bad character in path", "x-a://host/^/")
end

function testcase:test_set_path_without_auth ()
    local uri = assert(URI:new("x:blah"))
    is("blah", uri:path("frob%25%3a%78/%2F"))
    is("frob%25%3Ax/%2F", uri:path("/foo/bar"))
    is("/foo/bar", uri:path("//foo//bar"))
    is("/%2Ffoo//bar", uri:path("x ?#\"\0\127\255"))
    is("x%20%3F%23%22%00%7F%FF", uri:path(""))
    is("", uri:path(nil))
    is("", uri:path())
    is("x:", tostring(uri))
end

function testcase:test_set_path_with_auth ()
    local uri = assert(URI:new("x://host/wibble"))
    is("/wibble", uri:path("/foo/bar"))
    is("/foo/bar", uri:path("//foo//bar"))
    is("//foo//bar", uri:path(nil))
    is("", uri:path(""))
    is("", uri:path())
    is("x://host", tostring(uri))
end

function testcase:test_set_path_bad ()
    local uri = assert(URI:new("x://host/wibble"))
    tostring(uri)
    assert_error("with authority, path must start with /",
                 function () uri:path("foo") end)
    assert_error("bad %-encoding, % at end", function () uri:path("foo%") end)
    assert_error("bad %-encoding, %2 at end", function () uri:path("foo%2") end)
    assert_error("bad %-encoding, %gf", function () uri:path("%gf") end)
    assert_error("bad %-encoding, %fg", function () uri:path("%fg") end)
    is("/wibble", uri:path())
    is("x://host/wibble", tostring(uri))
end

function testcase:test_query ()
    local uri = assert(URI:new("x:?"))
    is("", uri:query())
    uri = assert(URI:new("x:"))
    is(nil, uri:query())
    uri = assert(URI:new("x:/foo"))
    is(nil, uri:query())
    uri = assert(URI:new("x:/foo#"))
    is(nil, uri:query())
    uri = assert(URI:new("x:/foo#bar?baz"))
    is(nil, uri:query())
    uri = assert(URI:new("x:/foo?"))
    is("", uri:query())
    uri = assert(URI:new("x://foo?"))
    is("", uri:query())
    uri = assert(URI:new("x://foo/?"))
    is("", uri:query())
    uri = assert(URI:new("x:/foo?bar"))
    is("bar", uri:query())
    uri = assert(URI:new("x:?foo?bar?"))
    is("foo?bar?", uri:query())
    uri = assert(URI:new("x:?foo?bar?#quux?frob"))
    is("foo?bar?", uri:query())
    uri = assert(URI:new("x://foo/bar%3Fbaz?"))
    is("", uri:query())
    uri = assert(URI:new("x:%3F?foo"))
    is("%3F", uri:path())
    is("foo", uri:query())
end

function testcase:test_query_bad ()
    is_bad_uri("bad character in query", "x-a://host/path/?foo^bar")
end

function testcase:test_set_query ()
    local uri = assert(URI:new("x://host/path"))
    is(nil, uri:query("foo/bar?baz"))
    is("x://host/path?foo/bar?baz", tostring(uri))
    is("foo/bar?baz", uri:query(""))
    is("x://host/path?", tostring(uri))
    is("", uri:query("foo^bar#baz"))
    is("x://host/path?foo%5Ebar%23baz", tostring(uri))
    is("foo%5Ebar%23baz", uri:query(nil))
    is(nil, uri:query())
    is("x://host/path", tostring(uri))
end

function testcase:test_fragment ()
    local uri = assert(URI:new("x:"))
    is(nil, uri:fragment())
    uri = assert(URI:new("x:#"))
    is("", uri:fragment())
    uri = assert(URI:new("x://#"))
    is("", uri:fragment())
    uri = assert(URI:new("x:///#"))
    is("", uri:fragment())
    uri = assert(URI:new("x:////#"))
    is("", uri:fragment())
    uri = assert(URI:new("x:#foo"))
    is("foo", uri:fragment())
    uri = assert(URI:new("x:%23#foo"))
    is("%23", uri:path())
    is("foo", uri:fragment())
    uri = assert(URI:new("x:?foo?bar?#quux?frob"))
    is("quux?frob", uri:fragment())
end

function testcase:test_fragment_bad ()
    is_bad_uri("bad character in fragment", "x-a://host/path/#foo^bar")
end

function testcase:test_set_fragment ()
    local uri = assert(URI:new("x://host/path"))
    is(nil, uri:fragment("foo/bar#baz"))
    is("x://host/path#foo/bar%23baz", tostring(uri))
    is("foo/bar%23baz", uri:fragment(""))
    is("x://host/path#", tostring(uri))
    is("", uri:fragment("foo^bar?baz"))
    is("x://host/path#foo%5Ebar?baz", tostring(uri))
    is("foo%5Ebar?baz", uri:fragment(nil))
    is(nil, uri:fragment())
    is("x://host/path", tostring(uri))
end

function testcase:test_bad_usage ()
    assert_error("missing uri arg", function () URI:new() end)
    assert_error("nil uri arg", function () URI:new(nil) end)
end

function testcase:test_clone_with_new ()
    -- Test cloning with as many components set as possible.
    local uri = assert(URI:new("x-foo://user:pass@bar.com:123/blah?q#frag"))
    tostring(uri)
    local clone = URI:new(uri)
    assert_table(clone)
    is("x-foo://user:pass@bar.com:123/blah?q#frag", tostring(uri))
    is("x-foo://user:pass@bar.com:123/blah?q#frag", tostring(clone))
    is("uri", getmetatable(uri)._NAME)
    is("uri", getmetatable(clone)._NAME)

    -- Test cloning with less stuff specified, but not in the base class.
    uri = assert(URI:new("http://example.com/"))
    clone = URI:new(uri)
    assert_table(clone)
    is("http://example.com/", tostring(uri))
    is("http://example.com/", tostring(clone))
    is("uri.http", getmetatable(uri)._NAME)
    is("uri.http", getmetatable(clone)._NAME)
end

function testcase:test_set_uri ()
    local uri = assert(URI:new("x-foo://user:pass@bar.com:123/blah?q#frag"))
    is("x-foo://user:pass@bar.com:123/blah?q#frag",
       uri:uri("http://example.com:81/blah2?q2#frag2"))
    is("http://example.com:81/blah2?q2#frag2", uri:uri())
    is("uri.http", getmetatable(uri)._NAME)
    is("http", uri:scheme())
    is("q2", uri:query())
    is("http://example.com:81/blah2?q2#frag2", uri:uri("Urn:X-FOO:bar"))
    is("uri.urn", getmetatable(uri)._NAME)
    is("x-foo", uri:nid())
    is("urn:x-foo:bar", tostring(uri))
end

function testcase:test_set_uri_bad ()
    local uri = assert(URI:new("x-foo://user:pass@bar.com:123/blah?q#frag"))
    assert_error("can't set URI to nil", function () uri:uri(nil) end)
    assert_error("invalid authority", function () uri:uri("foo://@@") end)
    is("x-foo://user:pass@bar.com:123/blah?q#frag", uri:uri())
    is("uri", getmetatable(uri)._NAME)
    is("x-foo", uri:scheme())
end

function testcase:test_eq ()
    local uri1str, uri2str = "x-a://host/foo", "x-a://host/bar"
    local uri1obj, uri2obj = assert(URI:new(uri1str)), assert(URI:new(uri2str))
    assert_true(URI.eq(uri1str, uri1str), "str == str")
    assert_false(URI.eq(uri1str, uri2str), "str ~= str")
    assert_true(URI.eq(uri1str, uri1obj), "str == obj")
    assert_false(URI.eq(uri1str, uri2obj), "str ~= obj")
    assert_true(URI.eq(uri1obj, uri1str), "obj == str")
    assert_false(URI.eq(uri1obj, uri2str), "obj ~= str")
    assert_true(URI.eq(uri1obj, uri1obj), "obj == obj")
    assert_false(URI.eq(uri1obj, uri2obj), "obj ~= obj")
end

function testcase:test_eq_bad_uri ()
    -- Check that an exception is thrown when 'eq' is given a bad URI string,
    -- and also that it's not just the error from trying to call the 'uri'
    -- method on nil, because that won't be very helpful to the caller.
    local ok, err = pcall(URI.eq, "^", "x-a://x/")
    assert_false(ok)
    assert_not_match("a nil value", err)
    ok, err = pcall(URI.eq, "x-a://x/", "^")
    assert_false(ok)
    assert_not_match("a nil value", err)
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
