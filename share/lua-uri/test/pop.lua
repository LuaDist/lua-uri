require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test uri.pop")

function testcase:test_pop_parse_1 ()
    local uri = assert(URI:new("Pop://rg@MAILSRV.qualcomm.COM"))
    is("pop://rg@mailsrv.qualcomm.com", tostring(uri))
    is("pop", uri:scheme())
    is("rg", uri:userinfo())
    is("mailsrv.qualcomm.com", uri:host())
    is(110, uri:port())
    is("rg", uri:pop_user())
    is("*", uri:pop_auth())
end

function testcase:test_pop_parse_2 ()
    local uri = assert(URI:new("pop://rg;AUTH=+APOP@mail.eudora.com:8110"))
    is("pop://rg;auth=+APOP@mail.eudora.com:8110", tostring(uri))
    is("rg;auth=+APOP", uri:userinfo())
    is("mail.eudora.com", uri:host())
    is(8110, uri:port())
    is("rg", uri:pop_user())
    is("+APOP", uri:pop_auth())
end

function testcase:test_pop_parse_3 ()
    local uri = assert(URI:new("pop://baz;AUTH=SCRAM-MD5@foo.bar"))
    is("pop://baz;auth=SCRAM-MD5@foo.bar", tostring(uri))
    is("baz;auth=SCRAM-MD5", uri:userinfo())
    is("foo.bar", uri:host())
    is(110, uri:port())
    is("baz", uri:pop_user())
    is("SCRAM-MD5", uri:pop_auth())
end

function testcase:test_pop_normalize ()
    local uri = assert(URI:new("Pop://Baz;Auth=*@Foo.Bar:110"))
    is("pop://Baz@foo.bar", tostring(uri))
    is("Baz", uri:userinfo())
    is("foo.bar", uri:host())
    is(110, uri:port())
    is("Baz", uri:pop_user())
    is("*", uri:pop_auth())
end

function testcase:test_pop_set_user ()
    local uri = assert(URI:new("pop://host"))
    is(nil, uri:pop_user("foo ;bar"))
    is("pop://foo%20%3Bbar@host", tostring(uri))
    assert_error("empty user not allowed", function () uri:pop_user("") end)
    is("foo ;bar", uri:pop_user(nil))
    is(nil, uri:pop_user())
    is("pop://host", tostring(uri))
end

function testcase:test_pop_set_user_bad ()
    local uri = assert(URI:new("pop://foo@host"))
    assert_error("empty user not allowed", function () uri:pop_user("") end)
    is("foo", uri:pop_user())
    is("pop://foo@host", tostring(uri))
    uri = assert(URI:new("pop://foo;auth=+APOP@host"))
    assert_error("user required when auth specified",
                 function () uri:pop_user(nil) end)
    is("foo", uri:pop_user())
    is("+APOP", uri:pop_auth())
    is("pop://foo;auth=+APOP@host", tostring(uri))
end

function testcase:test_pop_set_auth ()
    local uri = assert(URI:new("pop://user@host"))
    is("*", uri:pop_auth("foo ;bar"))
    is("pop://user;auth=foo%20%3Bbar@host", tostring(uri))
    is("foo ;bar", uri:pop_auth("*"))
    is("*", uri:pop_auth())
    is("pop://user@host", tostring(uri))
end

function testcase:test_pop_set_auth_bad ()
    local uri = assert(URI:new("pop://host"))
    assert_error("auth not allowed without user",
                 function () uri:pop_auth("+APOP") end)
    uri:pop_user("user")
    assert_error("empty auth not allowed", function () uri:pop_auth("") end)
    assert_error("nil auth not allowed", function () uri:pop_auth(nil) end)
    is("pop://user@host", tostring(uri))
end

function testcase:test_pop_bad_syntax ()
    is_bad_uri("path not empty", "pop://foo@host/")
    is_bad_uri("user empty", "pop://@host")
    is_bad_uri("user empty with auth", "pop://;auth=+APOP@host")
    is_bad_uri("auth empty", "pop://user;auth=@host")
end

function testcase:test_set_userinfo ()
    local uri = assert(URI:new("pop://host"))
    is(nil, uri:userinfo("foo ;bar"))
    is("pop://foo%20%3Bbar@host", tostring(uri))
    is("foo%20%3Bbar", uri:userinfo("foo;auth=+APOP"))
    is("pop://foo;auth=+APOP@host", tostring(uri))
    is("foo;auth=+APOP", uri:userinfo("foo;AUTH=+APOP"))
    is("pop://foo;auth=+APOP@host", tostring(uri))
    is("foo;auth=+APOP", uri:userinfo("bar;auth=*"))
    is("pop://bar@host", tostring(uri))
    is("bar", uri:userinfo(nil))
    is("pop://host", tostring(uri))
end

function testcase:test_set_userinfo_bad ()
    local uri = assert(URI:new("pop://host"))
    assert_error("empty userinfo", function () uri:userinfo("") end)
    assert_error("empty user with auth",
                 function () uri:userinfo(";auth=*") end)
    assert_error("empty auth on its own",
                 function () uri:userinfo(";auth=") end)
    assert_error("empty auth with user",
                 function () uri:userinfo("foo;auth=") end)
end

function testcase:test_set_path ()
    local uri = assert(URI:new("pop://host"))
    is("", uri:path(""))
    is("", uri:path(nil))
    is("", uri:path())
    assert_error("non-empty path", function () uri:path("/") end)
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
