require "uri-test"
local URI = require "uri"
local URIFile = require "uri.file"
local testcase = TestCase("Test uri.file")

function testcase:test_normalize ()
    test_norm("file:///foo", "file://LocalHost/foo")
    test_norm("file:///", "file://localhost/")
    test_norm("file:///", "file://localhost")
    test_norm("file:///", "file://")
    test_norm("file:///", "file:/")
    test_norm("file:///foo", "file:/foo")
    test_norm("file://foo/", "file://foo")
end

function testcase:test_invalid ()
    is_bad_uri("just scheme", "file:")
    is_bad_uri("scheme with relative path", "file:foo/bar")
end

function testcase:test_set_host ()
    local uri = assert(URI:new("file:///foo"))
    is("", uri:host())
    is("", uri:host("LocalHost"))
    is("file:///foo", tostring(uri))
    is("", uri:host("host.name"))
    is("file://host.name/foo", tostring(uri))
    is("host.name", uri:host(""))
    is("file:///foo", tostring(uri))
end

function testcase:test_set_path ()
    local uri = assert(URI:new("file:///foo"))
    is("/foo", uri:path())
    is("/foo", uri:path(nil))
    is("file:///", tostring(uri))
    is("/", uri:path(""))
    is("file:///", tostring(uri))
    is("/", uri:path("/bar/frob"))
    is("file:///bar/frob", tostring(uri))
    is("/bar/frob", uri:path("/"))
    is("file:///", tostring(uri))
end

function testcase:test_bad_usage ()
    local uri = assert(URI:new("file:///foo"))
    assert_error("nil host", function () uri:host(nil) end)
    assert_error("set userinfo", function () uri:userinfo("foo") end)
    assert_error("set port", function () uri:userinfo(23) end)
    assert_error("set relative path", function () uri:userinfo("foo/") end)
end

local function uri_to_fs (os, uristr, expected)
    local uri = assert(URI:new(uristr))
    is(expected, uri:filesystem_path(os))
end

local function fs_to_uri (os, path, expected)
    is(expected, tostring(URIFile.make_file_uri(path, os)))
end

function testcase:test_uri_to_fs_unix ()
    uri_to_fs("unix", "file:///", "/")
    uri_to_fs("unix", "file:///c:", "/c:")
    uri_to_fs("unix", "file:///C:/", "/C:/")
    uri_to_fs("unix", "file:///C:/Program%20Files", "/C:/Program Files")
    uri_to_fs("unix", "file:///C:/Program%20Files/", "/C:/Program Files/")
    uri_to_fs("unix", "file:///Program%20Files/", "/Program Files/")
end

function testcase:test_uri_to_fs_unix_bad ()
    -- On Unix platforms, there's no equivalent of UNC paths.
    local uri = assert(URI:new("file://laptop/My%20Documents/FileSchemeURIs.doc"))
    assert_error("Unix path with host name",
                 function () uri:filesystem_path("unix") end)
    -- Unix paths can't contain null bytes or encoded slashes.
    uri = assert(URI:new("file:///frob/foo%00bar/quux"))
    assert_error("Unix path with null byte",
                 function () uri:filesystem_path("unix") end)
    uri = assert(URI:new("file:///frob/foo%2Fbar/quux"))
    assert_error("Unix path with encoded slash",
                 function () uri:filesystem_path("unix") end)
end

function testcase:test_fs_to_uri_unix ()
    fs_to_uri("unix", "/", "file:///")
    fs_to_uri("unix", "//", "file:///")
    fs_to_uri("unix", "///", "file:///")
    fs_to_uri("unix", "/foo/bar", "file:///foo/bar")
    fs_to_uri("unix", "/foo/bar/", "file:///foo/bar/")
    fs_to_uri("unix", "//foo///bar//", "file:///foo/bar/")
    fs_to_uri("unix", "/foo bar/%2F", "file:///foo%20bar/%252F")
end

function testcase:test_fs_to_uri_unix_bad ()
    -- Relative paths can't be converted to URIs, because URIs are inherently
    -- absolute.
    assert_error("relative Unix path",
                 function () FileURI.make_file_uri("foo/bar", "unix") end)
    assert_error("relative empty Unix path",
                 function () FileURI.make_file_uri("", "unix") end)
end

function testcase:test_uri_to_fs_win32 ()
    uri_to_fs("win32", "file:///", "\\")
    uri_to_fs("win32", "file:///c:", "c:\\")
    uri_to_fs("win32", "file:///C:/", "C:\\")
    uri_to_fs("win32", "file:///C:/Program%20Files", "C:\\Program Files")
    uri_to_fs("win32", "file:///C:/Program%20Files/", "C:\\Program Files\\")
    uri_to_fs("win32", "file:///Program%20Files/", "\\Program Files\\")
    -- http://blogs.msdn.com/ie/archive/2006/12/06/file-uris-in-windows.aspx
    uri_to_fs("win32", "file://laptop/My%20Documents/FileSchemeURIs.doc",
              "\\\\laptop\\My Documents\\FileSchemeURIs.doc")
    uri_to_fs("win32",
              "file:///C:/Documents%20and%20Settings/davris/FileSchemeURIs.doc",
              "C:\\Documents and Settings\\davris\\FileSchemeURIs.doc")
    -- For backwards compatibility with deprecated way of indicating drives.
    uri_to_fs("win32", "file:///c%7C", "c:\\")
    uri_to_fs("win32", "file:///c%7C/", "c:\\")
    uri_to_fs("win32", "file:///C%7C/foo/", "C:\\foo\\")
end

function testcase:test_fs_to_uri_win32 ()
    fs_to_uri("win32", "", "file:///")
    fs_to_uri("win32", "\\", "file:///")
    fs_to_uri("win32", "c:", "file:///c:/")
    fs_to_uri("win32", "C:\\", "file:///C:/")
    fs_to_uri("win32", "C:/", "file:///C:/")
    fs_to_uri("win32", "C:\\Program Files", "file:///C:/Program%20Files")
    fs_to_uri("win32", "C:\\Program Files\\", "file:///C:/Program%20Files/")
    fs_to_uri("win32", "C:/Program Files/", "file:///C:/Program%20Files/")
    fs_to_uri("win32", "\\Program Files\\", "file:///Program%20Files/")
    fs_to_uri("win32", "\\\\laptop\\My Documents\\FileSchemeURIs.doc",
              "file://laptop/My%20Documents/FileSchemeURIs.doc")
    fs_to_uri("win32", "c:\\foo bar\\%2F", "file:///c:/foo%20bar/%252F")
end

function testcase:test_convert_on_unknown_os ()
    local uri = assert(URI:new("file:///foo"))
    assert_error("filesystem_path, unknown os",
                 function () uri:filesystem_path("NonExistent") end)
    assert_error("make_file_uri, unknown os",
                 function () URIFile.make_file_uri("/foo", "NonExistent") end)
end

lunit.run()
-- vi:ts=4 sw=4 expandtab
