/*
    Do not modify this file at all
    If you want to change your configurations then do so in data folder
    This file is for initialization and load the Framework from prp_lib
*/

local context = IsDuplicityVersion() and 'server' or 'client'

local frameworkName = GetResourceState('es_extended') == 'started' and 'esx' or 'qb'
local framework = LoadResourceFile('prp_lib', ('resource/callbacks/%s/%s.lua'):format(context, frameworkName))

Framework = assert(load(framework))()