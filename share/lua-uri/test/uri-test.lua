require "lunit"
lunit.import "all"
local URI = require "uri"

is = assert_equal

function is_one_of (expecteds, actual, msg)
    for _, v in ipairs(expecteds) do
        if actual == v then return end
    end

    -- Not any of the expected answers matched.  In order to report the error
    -- usefully, we have to list the alternatives in the error message.
    local err = "expected one of {"
    for i, v in ipairs(expecteds) do
        if i > 1 then err = err .. ", " end
        err = err .. "'" .. tostring(v) .. "'"
    end
    err = err .. "}, but was '" .. tostring(actual) .. "'"
    if msg then err = err .. ": " .. msg end
    assert_fail(err)
end

function assert_isa(actual, class)
    assert_table(actual)
    assert_table(class)
    local mt = actual
    while true do
        mt = getmetatable(mt)
        if not mt then error"class not found as metatable at any level" end
        if mt == actual then error"circular metatables" end
        if mt == class then return nil end
    end
end

function assert_array_shallow_equal (expected, actual, msg)
    if not msg then msg = "assert_array_shallow_equal" end
    assert_table(actual, msg .. ", is table")
    is(#expected, #actual, msg .. ", same size")
    if #expected == #actual then
        for i = 1, #expected do
            is(expected[i], actual[i], msg .. ", element " .. i)
        end
    end
    for key in pairs(actual) do
        assert_number(key, msg .. ", non-number key in array")
    end
end

local function _count_hash_pairs (hash)
    local count = 0
    for _, _ in pairs(hash) do count = count + 1 end
    return count
end

function assert_hash_shallow_equal (expected, actual, msg)
    if not msg then msg = "assert_hash_shallow_equal" end
    assert_table(actual, msg .. ", is table")
    local expsize, actualsize = _count_hash_pairs(expected),
                                _count_hash_pairs(actual)
    is(expsize, actualsize, msg .. ", same size")
    if expsize == actualsize then
        for k, v in pairs(expected) do
            is(expected[k], actual[k], msg .. ", element " .. tostring(k))
        end
    end
end

function is_bad_uri (msg, uri)
    local ok, err = URI:new(uri)
    assert_nil(ok, msg)
    assert_string(err, msg)
end

function test_norm (expected, input)
    local uri = assert(URI:new(input))
    is(expected, uri:uri())
    is(expected, tostring(uri))
    assert_false(uri:is_relative())
end

function test_norm_already (input)
    test_norm(input, input)
end

-- vi:ts=4 sw=4 expandtab
