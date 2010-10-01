require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test 'resolve' and 'relativize' methods")

-- Test data from RFC 3986.  The 'http' prefix has been changed throughout
-- to 'x-foo' so as not to trigger any scheme-specific normalization.
local resolve_tests = {
    -- 5.4.1.  Normal Examples
    ["g:h"]             = "g:h",
    ["g"]               = "x-foo://a/b/c/g",
    ["./g"]             = "x-foo://a/b/c/g",
    ["g/"]              = "x-foo://a/b/c/g/",
    ["/g"]              = "x-foo://a/g",
    ["//g"]             = "x-foo://g",
    ["?y"]              = "x-foo://a/b/c/d;p?y",
    ["g?y"]             = "x-foo://a/b/c/g?y",
    ["#s"]              = "x-foo://a/b/c/d;p?q#s",
    ["g#s"]             = "x-foo://a/b/c/g#s",
    ["g?y#s"]           = "x-foo://a/b/c/g?y#s",
    [";x"]              = "x-foo://a/b/c/;x",
    ["g;x"]             = "x-foo://a/b/c/g;x",
    ["g;x?y#s"]         = "x-foo://a/b/c/g;x?y#s",
    [""]                = "x-foo://a/b/c/d;p?q",
    ["."]               = "x-foo://a/b/c/",
    ["./"]              = "x-foo://a/b/c/",
    [".."]              = "x-foo://a/b/",
    ["../"]             = "x-foo://a/b/",
    ["../g"]            = "x-foo://a/b/g",
    ["../.."]           = "x-foo://a/",
    ["../../"]          = "x-foo://a/",
    ["../../g"]         = "x-foo://a/g",

    -- 5.4.2.  Abnormal Examples
    ["../../../g"]      = "x-foo://a/g",
    ["../../../../g"]   = "x-foo://a/g",
    ["/./g"]            = "x-foo://a/g",
    ["/../g"]           = "x-foo://a/g",
    ["g."]              = "x-foo://a/b/c/g.",
    [".g"]              = "x-foo://a/b/c/.g",
    ["g.."]             = "x-foo://a/b/c/g..",
    ["..g"]             = "x-foo://a/b/c/..g",
    ["./../g"]          = "x-foo://a/b/g",
    ["./g/."]           = "x-foo://a/b/c/g/",
    ["g/./h"]           = "x-foo://a/b/c/g/h",
    ["g/../h"]          = "x-foo://a/b/c/h",
    ["g;x=1/./y"]       = "x-foo://a/b/c/g;x=1/y",
    ["g;x=1/../y"]      = "x-foo://a/b/c/y",
    ["g?y/./x"]         = "x-foo://a/b/c/g?y/./x",
    ["g?y/../x"]        = "x-foo://a/b/c/g?y/../x",
    ["g#s/./x"]         = "x-foo://a/b/c/g#s/./x",
    ["g#s/../x"]        = "x-foo://a/b/c/g#s/../x",
    ["x-foo:g"]         = "x-foo:g",

    -- Some extra tests for good measure
    ["#foo?"]           = "x-foo://a/b/c/d;p?q#foo?",
    ["?#foo"]           = "x-foo://a/b/c/d;p?#foo",
}

local function test_abs_rel (base, uref, expect)
    local bad = false

    -- Test 'resolve' method with object as argument.
    local u = assert(URI:new(uref))
    local b = assert(URI:new(base))
    u:resolve(b)
    local got = tostring(u)
    if got ~= expect then
        bad = true
        print("URI:new(" .. uref .. "):resolve(URI:new(" .. base .. ") ===> " ..
              expect .. " (not " .. got .. ")")
    end

    -- Test 'resolve' method with string as argument.
    u = assert(URI:new(uref))
    u:resolve(base)
    local got = tostring(u)
    if got ~= expect then
        bad = true
        print("URI:new(" .. uref .. "):resolve(URI:new(" .. base .. ") ===> " ..
              expect .. " (not " .. got .. ")")
    end

    -- Test resolving relative URI using the constructor.
    local u = assert(URI:new(uref, base))
    local got = tostring(u)
    if got ~= expect then
        bad = true
        print("URI:new(" .. uref .. ", " .. base .. ") ==> " .. expect ..
              " (not " .. got .. ")")
    end

    return bad
end

function testcase:test_resolve ()
    local base = "x-foo://a/b/c/d;p?q"
    local testno = 1
    local bad = false

    for rel, abs in pairs(resolve_tests) do
        if test_abs_rel(base, rel, abs) then bad = true end
    end

    if bad then assert_fail("one of the checks went wrong") end
end

function testcase:test_resolve_error ()
    local base = assert(URI:new("urn:oid:1.2.3"))
    local uri = assert(URI:new("not-valid-path-for-urn"))

    -- The 'resolve' method should throw an exception if the absolute URI
    -- that results from the resolution would be invalid.
    assert_error("calling resolve() creates invalid URI",
                 function () uri:resolve(base) end)
    assert_true(uri:is_relative())
    is("not-valid-path-for-urn", tostring(uri))

    -- But the constructor should return an error in its normal fashion.
    local ok, err = URI:new(uri, base)
    assert_nil(ok)
    assert_string(err)
end

local relativize_tests = {
    -- Empty path if the path is the same as the base URI's.
    { "http://ex/", "http://ex/", "" },
    { "http://ex/a/b", "http://ex/a/b", "" },
    { "http://ex/a/b/", "http://ex/a/b/", "" },
    -- Absolute path if the base URI's path doesn't help.
    { "http://ex/", "http://ex/a/b", "/" },
    { "http://ex/", "http://ex/a/b/", "/" },
    { "http://ex/x/y", "http://ex/", "/x/y" },
    { "http://ex/x/y/", "http://ex/", "/x/y/" },
    { "http://ex/x", "http://ex/a", "/x" },
    { "http://ex/x", "http://ex/a/", "/x" },
    { "http://ex/x/", "http://ex/a", "/x/" },
    { "http://ex/x/", "http://ex/a/", "/x/" },
    { "http://ex/x/y", "http://ex/a/b", "/x/y" },
    { "http://ex/x/y", "http://ex/a/b/", "/x/y" },
    { "http://ex/x/y/", "http://ex/a/b", "/x/y/" },
    { "http://ex/x/y/", "http://ex/a/b/", "/x/y/" },
    -- Add to the end of the base path.
    { "x-a://ex/a/b/c", "x-a://ex/a/b/", "c" },
    { "x-a://ex/a/b/c/", "x-a://ex/a/b/", "c/" },
    { "x-a://ex/a/b/c/d", "x-a://ex/a/b/", "c/d" },
    { "x-a://ex/a/b/c/d/", "x-a://ex/a/b/", "c/d/" },
    { "x-a://ex/a/b/c/d/e", "x-a://ex/a/b/", "c/d/e" },
    { "x-a://ex/a/b/c:foo/d/e", "x-a://ex/a/b/", "./c:foo/d/e" },
    -- Change last segment in base path, and add to it.
    { "x-a://ex/a/b/", "x-a://ex/a/b/c", "./" },
    { "x-a://ex/a/b/x", "x-a://ex/a/b/c", "x" },
    { "x-a://ex/a/b/x/", "x-a://ex/a/b/c", "x/" },
    { "x-a://ex/a/b/x/y", "x-a://ex/a/b/c", "x/y" },
    { "x-a://ex/a/b/x:foo/y", "x-a://ex/a/b/c", "./x:foo/y" },
    -- Use '..' segments.
    { "x-a://ex/a/b/c", "x-a://ex/a/b/c/d", "../c" },
    { "x-a://ex/a/b/c", "x-a://ex/a/b/c/", "../c" },
    { "x-a://ex/a/b/", "x-a://ex/a/b/c/", "../" },
    { "x-a://ex/a/b/", "x-a://ex/a/b/c/d", "../" },
    { "x-a://ex/a/b", "x-a://ex/a/b/c/", "../../b" },
    { "x-a://ex/a/b", "x-a://ex/a/b/c/d", "../../b" },
    { "x-a://ex/a/", "x-a://ex/a/b/c/", "../../" },
    { "x-a://ex/a/", "x-a://ex/a/b/c/d", "../../" },
    -- Preserve query and fragment parts.
    { "http://ex/a/b", "http://ex/a/b?baseq#basef", "b" },
    { "http://ex/a/b:c", "http://ex/a/b:c?baseq#basef", "./b:c" },
    { "http://ex/a/b?", "http://ex/a/b?baseq#basef", "?" },
    { "http://ex/a/b?foo", "http://ex/a/b?baseq#basef", "?foo" },
    { "http://ex/a/b?foo#", "http://ex/a/b?baseq#basef", "?foo#" },
    { "http://ex/a/b?foo#bar", "http://ex/a/b?baseq#basef", "?foo#bar" },
    { "http://ex/a/b#bar", "http://ex/a/b?baseq#basef", "b#bar" },
    { "http://ex/a/b:foo#bar", "http://ex/a/b:foo?baseq#basef", "./b:foo#bar" },
    { "http://ex/a/b:foo#bar", "http://ex/a/b:foo#basef", "#bar" },
}

function testcase:test_relativize ()
    for _, test in ipairs(relativize_tests) do
        local uri = assert(URI:new(test[1]))
        uri:relativize(test[2])
        is(test[3], tostring(uri))

        -- Make sure it will resolve back to the original value.
        uri:resolve(test[2])
        is(test[1], tostring(uri))
    end
end

function testcase:test_relativize_already_is ()
    local uri = assert(URI:new("../foo"))
    uri:relativize("http://host/")
    is("../foo", tostring(uri))
end

function testcase:test_relativize_urn ()
    local uri = assert(URI:new("urn:oid:1.2.3"))
    uri:relativize("urn:oid:1")
    is("urn:oid:1.2.3", tostring(uri))
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
