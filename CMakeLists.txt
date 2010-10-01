# Copyright (C) 2007-2009 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

PROJECT(uri NONE)
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
INCLUDE(dist.cmake)

# Install all files and documentation
INSTALL (FILES uri.lua DESTINATION ${INSTALL_LMOD})
INSTALL (DIRECTORY uri DESTINATION ${INSTALL_LMOD})
INSTALL (FILES COPYRIGHT Changes README TODO DESTINATION ${INSTALL_DATA})
INSTALL (DIRECTORY doc/ DESTINATION ${INSTALL_DOC})
INSTALL (DIRECTORY test/ DESTINATION ${INSTALL_TEST})
INSTALL (FILES lunit.lua uri-test.lua DESTINATION ${INSTALL_FOO})
