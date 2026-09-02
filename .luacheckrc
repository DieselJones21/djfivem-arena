-- luacheck configuration for the cursor_arena FiveM resource.
-- FiveM/CitizenFX, ox_lib, oxmysql and project-defined globals so luacheck
-- does not flag the CitizenFX runtime as "undefined".
std = "lua54"
max_line_length = false

-- Globals the resource intentionally defines/assigns.
globals = {
  "Config",
  "Arena",
  "ArenaDiscord",
  "Locales",
  "L",
  "Framework",
  "Lang",
}

read_globals = {
  -- CitizenFX runtime
  "Citizen", "CreateThread", "Wait", "SetTimeout",
  "RegisterNetEvent", "AddEventHandler", "RemoveEventHandler",
  "TriggerEvent", "TriggerServerEvent", "TriggerClientEvent",
  "TriggerLatentClientEvent", "TriggerLatentServerEvent",
  "RegisterCommand", "RegisterKeyMapping",
  "exports", "GetCurrentResourceName", "GetInvokingResource",
  "GetResourceState", "GetNumResources", "GetResourceByFindIndex",
  "GetHashKey", "joaat", "msgpack", "json", "promise", "Deferrals",
  "source", "cache", "lib", "MySQL",
  -- NUI
  "SendNUIMessage", "RegisterNUICallback", "SetNUIFocus",
  "GetParentResourceName", "SetNUIFocusKeepInput",
  -- vector/quat helpers
  "vector2", "vector3", "vector4", "vec", "vec2", "vec3", "vec4", "quat",
}

-- Native game functions (GTA5) are numerous; ignore "undefined global" for
-- ALL_CAPS-style natives to keep the report focused on real issues.
ignore = {
  "212", -- unused argument
  "213", -- unused loop variable
  "631", -- line too long (handled by max_line_length)
}
