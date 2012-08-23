# Copyright (C) 2007-2012 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( lua-uri NONE )
cmake_minimum_required ( VERSION 2.8 )
include ( cmake/dist.cmake )
include ( lua )

# Install all files and documentation
install_lua_module ( uri uri.lua )
install ( DIRECTORY uri DESTINATION ${INSTALL_LMOD} COMPONENT Runtime )
install_data ( COPYRIGHT Changes README TODO )
install_doc ( doc/ )
install_test ( test/ uri-test.lua )
