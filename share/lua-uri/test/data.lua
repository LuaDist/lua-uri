require "uri-test"
local URI = require "uri"
local Util = require "uri._util"
local testcase = TestCase("Test uri.data")

local Filter = Util.attempt_require("datafilter")

function testcase:test_data_uri_encoded ()
    local uri = assert(URI:new("data:,A%20brief%20note"))
    is("uri.data", uri._NAME)
    is(",A%20brief%20note", uri:path())
    is("data", uri:scheme())

    is("text/plain;charset=US-ASCII", uri:data_media_type())
    is("A brief note", uri:data_bytes())

    local old = uri:data_bytes("F\229r-i-k\229l er tingen!")
    is("A brief note", old)
    is("data:,F%E5r-i-k%E5l%20er%20tingen!", tostring(uri))

    old = uri:data_media_type("text/plain;charset=iso-8859-1")
    is("text/plain;charset=US-ASCII", old)
    is("data:text/plain;charset=iso-8859-1,F%E5r-i-k%E5l%20er%20tingen!",
       tostring(uri))
end

function testcase:test_data_big_base64_chunk ()
    local imgdata = "R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"
    local uri = assert(URI:new("data:image/gif;base64," .. imgdata))
    is("image/gif", uri:data_media_type())

    if Filter then
        local gotdata = uri:data_bytes()
        is(273, gotdata:len())
        is(imgdata, Filter.base64_encode(gotdata))
    end
end

function testcase:test_data_containing_commas ()
    local uri = assert(URI:new("data:application/vnd-xxx-query,select_vcount,fcol_from_fieldtable/local"))
    is("application/vnd-xxx-query", uri:data_media_type())
    is("select_vcount,fcol_from_fieldtable/local", uri:data_bytes())
    uri:data_bytes("")
    is("data:application/vnd-xxx-query,", tostring(uri))

    uri:data_bytes("a,b")
    uri:data_media_type(nil)
    is("data:,a,b", tostring(uri))

    is("a,b", uri:data_bytes(nil))
    is("", uri:data_bytes())
end

function testcase:test_automatic_selection_of_uri_or_base64_encoding ()
    local uri = assert(URI:new("data:,"))
    uri:data_bytes("")
    is("data:,", tostring(uri))

    uri:data_bytes(">")
    is("data:,%3E", tostring(uri))
    is(">", uri:data_bytes())

    uri:data_bytes(">>>>>")
    is("data:,%3E%3E%3E%3E%3E", tostring(uri))

    if Filter then
        uri:data_bytes(">>>>>>")
        is("data:;base64,Pj4+Pj4+", tostring(uri))

        uri:data_media_type("text/plain;foo=bar")
        is("data:text/plain;foo=bar;base64,Pj4+Pj4+", tostring(uri))

        uri:data_media_type("foo")
        is("data:foo;base64,Pj4+Pj4+", tostring(uri))

        uri:data_bytes((">"):rep(3000))
        is("data:foo;base64," .. ("Pj4+"):rep(1000), tostring(uri))
        is((">"):rep(3000), uri:data_bytes())
    else
        uri:data_bytes(">>>>>>")
        is("data:,%3E%3E%3E%3E%3E%3E", tostring(uri))
        uri:data_media_type("foo")
        is("data:foo,%3E%3E%3E%3E%3E%3E", tostring(uri))
    end

    uri:data_media_type(nil)
    uri:data_bytes(nil)
    is("data:,", tostring(uri))
end

function testcase:test_bad_uri ()
    is_bad_uri("missing comma", "data:foo")
    is_bad_uri("no path at all", "data:")
    is_bad_uri("has host", "data://host/,")
end

function testcase:test_set_path ()
    local uri = assert(URI:new("data:image/gif,foobar"))
    is("image/gif,foobar", uri:path("image/jpeg;foo=bar,x y,?"))
    is("image/jpeg;foo=bar,x%20y,%3F", uri:path(",blah"))
    is(",blah", uri:path(","))
    is(",", uri:path())
    is("data:,", tostring(uri))
end

function testcase:test_set_path_bad ()
    local uri = assert(URI:new("data:image/gif,foobar"))
    assert_error("no path", function () uri:path(nil) end)
    assert_error("empty path", function () uri:path("") end)
    assert_error("no comma", function () uri:path("foo;bar") end)
    assert_error("bad base64 encoding", function () uri:path(";base64,x_0") end)
    is("image/gif,foobar", uri:path())
    is("data:image/gif,foobar", tostring(uri))
end

function testcase:test_set_disallowed_stuff ()
    local uri = assert(URI:new("data:,"))
    assert_error("can't set userinfo", function () uri:userinfo("x") end)
    assert_error("can't set host", function () uri:host("x") end)
    assert_error("can't set port", function () uri:port(23) end)
    is("data:,", tostring(uri))
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
