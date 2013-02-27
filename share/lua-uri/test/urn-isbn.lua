require "uri-test"
local URI = require "uri"
local Util = require "uri._util"
local testcase = TestCase("Test uri.urn.isbn")

local have_isbn_module = Util.attempt_require("isbn")

function testcase:test_isbn ()
    -- Example from RFC 2288
    local u = URI:new("URN:ISBN:0-395-36341-1")
    is(have_isbn_module and "urn:isbn:0-395-36341-1" or "urn:isbn:0395363411",
       u:uri())
    is("urn", u:scheme())
    is("isbn", u:nid())
    is(have_isbn_module and "0-395-36341-1" or "0395363411", u:nss())
    is("0395363411", u:isbn_digits())

    u = URI:new("URN:ISBN:0395363411")
    is(have_isbn_module and "urn:isbn:0-395-36341-1" or "urn:isbn:0395363411",
       u:uri())
    is("urn", u:scheme())
    is("isbn", u:nid())
    is(have_isbn_module and "0-395-36341-1" or "0395363411", u:nss())
    is("0395363411", u:isbn_digits())

    if have_isbn_module then
        local isbn = u:isbn()
        assert_table(isbn)
        is("0-395-36341-1", tostring(isbn))
        is("0", isbn:group_code())
        is("395", isbn:publisher_code())
        is("978-0-395-36341-6", tostring(isbn:as_isbn13()))
    end

    assert_true(URI.eq("urn:isbn:088730866x", "URN:ISBN:0-88-73-08-66-X"))
end

function testcase:test_set_nss ()
    local uri = assert(URI:new("urn:isbn:039-53-63411"))
    is(have_isbn_module and "0-395-36341-1" or "0395363411",
       uri:nss("088-7308-66x"))
    is(have_isbn_module and "urn:isbn:0-88730-866-X" or "urn:isbn:088730866X",
       tostring(uri))
    is(have_isbn_module and "0-88730-866-X" or "088730866X", uri:nss())
end

function testcase:test_set_bad_nss ()
    local uri = assert(URI:new("urn:ISBN:039-53-63411"))
    assert_error("set NSS to non-string value", function () uri:nss({}) end)
    assert_error("set NSS to empty", function () uri:nss("") end)
    assert_error("set NSS to wrong length", function () uri:nss("123") end)

    -- None of that should have had any affect
    is(have_isbn_module and "urn:isbn:0-395-36341-1" or "urn:isbn:0395363411",
       tostring(uri))
    is(have_isbn_module and "0-395-36341-1" or "0395363411", uri:nss())
    is("0395363411", uri:isbn_digits())
    is("uri.urn.isbn", uri._NAME)
end

function testcase:test_set_path ()
    local uri = assert(URI:new("urn:ISBN:039-53-63411"))
    is(have_isbn_module and "isbn:0-395-36341-1" or "isbn:0395363411",
       uri:path("ISbn:088-73-0866x"))
    is(have_isbn_module and "urn:isbn:0-88730-866-X" or "urn:isbn:088730866X",
       tostring(uri))

    assert_error("bad path", function () uri:path("isbn:1234567") end)
    is(have_isbn_module and "urn:isbn:0-88730-866-X" or "urn:isbn:088730866X",
       tostring(uri))
    is(have_isbn_module and "isbn:0-88730-866-X" or "isbn:088730866X",
       uri:path())
end

function testcase:test_isbn_setting_digits ()
    local u = assert(URI:new("URN:ISBN:0395363411"))
    local old = u:isbn_digits("0-88730-866-x")
    is("0395363411", old)
    is("088730866X", u:isbn_digits())
    is(have_isbn_module and "0-88730-866-X" or "088730866X", u:nss())
    if have_isbn_module then
        is("0-88730-866-X", tostring(u:isbn()))
    end
end

function testcase:test_isbn_setting_object ()
    if have_isbn_module then
        local ISBN = require "isbn"
        local u = assert(URI:new("URN:ISBN:0395363411"))
        local old = u:isbn(ISBN:new("0-88730-866-x"))
        assert_table(old)
        is("0-395-36341-1", tostring(old))
        is("088730866X", u:isbn_digits())
        is("0-88730-866-X", u:nss())
        local new = u:isbn()
        assert_table(new)
        is("0-88730-866-X", tostring(new))
    end
end

function testcase:test_illegal_isbn ()
    is_bad_uri("invalid characters", "urn:ISBN:abc")
    if have_isbn_module then
        is_bad_uri("bad checksum", "urn:isbn:0395363412")
        is_bad_uri("wrong length", "urn:isbn:03953634101")
    end
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
