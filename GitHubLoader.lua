
local url = "RAW_GITHUB_URL"

local success, result = pcall(function()
    local source = game:HttpGet(url)
    local scriptFunction = loadstring(source)

    assert(scriptFunction, "Unable to compile script")

    return scriptFunction()
end)

if not success then
    warn("[Sprout Collector Loader]", result)
end
