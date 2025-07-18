/*
    Do not modify this file at all
    If you want to change your configurations then do so in data folder
    This file is for initialization and load the Framework and Dispatch from prp_lib
*/

local context = IsDuplicityVersion() and 'server' or 'client'

local frameworkName = GetResourceState('es_extended') == 'started' and 'esx' or 'qb'
local framework = LoadResourceFile('prp_lib', ('resource/callbacks/%s/%s.lua'):format(context, frameworkName))

local dispatch = LoadResourceFile('prp_lib', ('resource/dispatch/%s.lua'):format(context))

Framework = assert(load(framework))()
Dispatch = context == 'server' and assert(load(dispatch))()