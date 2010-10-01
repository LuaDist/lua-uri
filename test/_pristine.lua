require "lunit"
local testcase = lunit.TestCase("Test library loading doesn't affect globals")

function testcase:test_no_global_clobbering ()
    local globals = {}
    for key in pairs(_G) do globals[key] = true end

    -- Load all the modules for the different types of URIs, in case any one
    -- of those treads on a global.  I keep them around in a table to make
    -- sure they're all loaded at the same time, just in case that does
    -- anything interesting.
    local schemes = {
        "_login", "_relative", "_util", "data",
        "file", "file.unix", "file.win32",
        "ftp", "http", "https",
        "pop", "rtsp", "rtspu", "telnet",
        "urn", "urn.isbn", "urn.issn", "urn.oid"
    }
    local loaded = {}
    local URI = require "uri"
    for _, name in ipairs(schemes) do
        loaded[name] = require("uri." .. name)
    end

    for key in pairs(_G) do
        lunit.assert_not_nil(globals[key],
                             "global '" .. key .. "' created by lib")
    end
    for key in pairs(globals) do
        lunit.assert_not_nil(_G[key],
                             "global '" .. key .. "' destroyed by lib")
    end
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
