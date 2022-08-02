local uci = require "uci"
local os = require "os"

local M = {}

function M.updateIns(params)
  local id = params.sid
  local options = params.options
  local c = uci.cursor()
  for _, option in ipairs(options) do
    if c:get("openvpn", id, option) ~= nil then
      os.remove(c:get("openvpn", id, option))
      c:delete("openvpn", id, option)
    end
  end
  c:commit("openvpn")
  return params.elem
end

function M.getFile(params)
  local file = io.open(params.path, "r")
  if file ~= nil then
    io.close(file)
    params.exists = 1
  else
    params.exists = 0
  end
  return params
end

return M
