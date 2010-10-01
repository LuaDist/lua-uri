require "uri-test"
local URI = require "uri"
local testcase = TestCase("Test uri.urn.issn")

local good_issn_digits = {
    "02613077", -- The Guardian
    "14734966", -- Photography Monthly

    -- From the Wikipedia article on ISSN.
    "03178471",
    "15340481",

    -- From RFC 3044 section 5.
    "0259000X",
    "15601560",
}

function testcase:test_parse_and_normalize ()
    local uri = assert(URI:new("urn:ISSN:1560-1560"))
    is("uri.urn.issn", uri._NAME)
    is("urn:issn:1560-1560", uri:uri())
    is("15601560", uri:issn_digits())
    uri = assert(URI:new("URN:Issn:0259-000X"))
    is("urn:issn:0259-000X", uri:uri())
    is("0259000X", uri:issn_digits())
    uri = assert(URI:new("urn:issn:0259000x"))
    is("urn:issn:0259-000X", uri:uri())
    is("0259000X", uri:issn_digits())
end

function testcase:test_bad_syntax ()
    is_bad_uri("too many digits", "urn:issn:026130707")
    is_bad_uri("not enough digits", "urn:issn:0261377")
    is_bad_uri("too many hyphens in middle", "urn:issn:0261--3077")
    is_bad_uri("hyphen in wrong place", "urn:issn:026-13077")
    is_bad_uri("X digit in wrong place", "urn:issn:025900X0")
end

-- Try all the known-good sequences of digits with all possible checksums
-- other than the right one, to make sure they're all detected as errors.
function testcase:test_bad_checksum ()
    for _, issn in ipairs(good_issn_digits) do
        local digits, good_checksum = issn:sub(1, 7), issn:sub(8, 8)
        good_checksum = (good_checksum == "X") and 10 or tonumber(good_checksum)
        for i = 0, 10 do
            if i ~= good_checksum then
                local urn = "urn:issn:" .. digits .. (i == 10 and "X" or i)
                is_bad_uri("bad checksum in " .. urn, urn)
            end
        end
    end
end

function testcase:test_set_nss ()
    local uri = assert(URI:new("urn:issn:0261-3077"))
    is("0261-3077", uri:nss("14734966"))
    is("urn:issn:1473-4966", tostring(uri))
    is("1473-4966", uri:nss("0259-000x"))
    is("urn:issn:0259-000X", tostring(uri))
    is("0259-000X", uri:nss())
end

function testcase:test_set_bad_nss ()
    local uri = assert(URI:new("urn:ISSN:02613077"))
    assert_error("set NSS to non-string value", function () uri:nss({}) end)
    assert_error("set NSS to empty", function () uri:nss("") end)
    assert_error("set NSS to bad char", function () uri:nss("x") end)

    -- None of that should have had any affect
    is("urn:issn:0261-3077", tostring(uri))
    is("0261-3077", uri:nss())
    is("02613077", uri:issn_digits())
    is("uri.urn.issn", uri._NAME)
end

function testcase:test_set_path ()
    local uri = assert(URI:new("urn:ISSN:02613077"))
    is("issn:0261-3077", uri:path("ISsn:14734966"))
    is("urn:issn:1473-4966", tostring(uri))

    assert_error("bad path", function () uri:path("issn:1234567") end)
    is("urn:issn:1473-4966", tostring(uri))
    is("issn:1473-4966", uri:path())
end

function testcase:test_set_issn_digits ()
    local uri = assert(URI:new("urn:ISSN:0261-3077"))
    is("02613077", uri:issn_digits(nil))
    local old = uri:issn_digits("14734966")
    is("02613077", old)
    is("14734966", uri:issn_digits())
    is("urn:issn:1473-4966", uri:uri())
    old = uri:issn_digits("0259-000x")
    is("14734966", old)
    is("0259000X", uri:issn_digits())
    is("urn:issn:0259-000X", uri:uri())
end

function testcase:test_set_bad_issn_digits ()
    local uri = assert(URI:new("urn:ISSN:0261-3077"))
    assert_error("set ISSN with bad char",
                 function () uri:issn_digits("0261-3077Y") end)
    assert_error("set ISSN with too many digits",
                 function () uri:issn_digits("0261-30770") end)
    assert_error("set ISSN of empty string",
                 function () uri:issn_digits("") end)
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
