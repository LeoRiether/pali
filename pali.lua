--[[
                      888 d8b 
                      888 Y8P 
                      888     
    88888b.   8888b.  888 888 
    888 "88b     "88b 888 888 
    888  888 .d888888 888 888 
    888 d88P 888  888 888 888 
    88888P"  "Y888888 888 888 
    888                       
    888                       
    888                        ]]

--[[ Package List ]]

local M = {}

M.spec_path = os.getenv('HOME') .. '/.config/pali.lua'
M.lock_path = os.getenv('HOME') .. '/.local/share/pali.lock.lua'

local columns = (function()
    local handle = io.popen('tput cols')
    if not handle then return 0 end
    return tonumber(handle:read('*a')) or 0
end)()

function M.loadspec()
    return loadfile(M.spec_path)()
end

function M.loadlock()
    local lock = loadfile(M.lock_path)
    if lock == nil then
        return {}
    end
    return lock()
end

function M.savelock(table)
    local file = io.open(M.lock_path, "w")
    if file == nil then
        print("Couldn't open the lockfile <" .. M.lock_path .. ">")
        os.exit(1)
        return
    end
    file:write('return ')
    file:write(M.serialize(table))
    file:close()
end

function M.serialize(x)
    if type(x) == 'table' then
        local res = { "{" }
        for k, v in pairs(x) do
            if type(k) == 'number' then
                res[#res + 1] = M.serialize(v) .. ","
            else
                res[#res + 1] = tostring(k) .. "=" .. M.serialize(v) .. ","
            end
        end
        res[#res + 1] = "}"
        return table.concat(res, "\n")
    elseif type(x) == 'string' then
        return '"' .. x .. '"'
    else
        return tostring(x)
    end
end

-- Transforms the array part of a table to a set
-- { 'a', 'b', 'c' } => { a=true, b=true, c=true }
function M.to_set(table)
    if type(table) ~= "table" then
        return table
    end

    local set = {}
    for key, value in pairs(table) do
        if type(key) == "number" then
            -- table[i] = value => table[value] = true
            set[value] = true
        else
            set[key] = M.to_set(value)
        end
    end
    return set
end

local function set_to_array(set)
    local arr = {}
    for key, value in pairs(set) do
        if value == true then
            arr[#arr + 1] = key
        end
    end
    return arr
end

-- A \ B
function M.diff(A, B)
    if B == nil then
        return A
    end

    local D = {}
    for k, v in pairs(A) do
        if type(v) == 'table' then
            D[k] = M.diff(v, B[k])
        elseif v ~= B[k] then
            D[k] = v
        end
    end
    return D
end

local function run(cmd)
    print("\27[92m> " .. cmd .. "\27[0m")
    os.execute(cmd)
    -- local handle = assert(io.popen(cmd))
    -- local _ = handle:read('*a')
    -- handle:close()
    -- if not handle:close() then
    --     print("Exiting pali...")
    --     os.exit(0)
    -- end

    -- -------------------------------------------------------------------------
    io.stdout:write("\27[92m")
    for _ = 1, columns do
        io.stdout:write('-')
    end
    io.stdout:write("\27[0m")
end

local function empty(table)
    return next(table) == nil
end

-- Syncs packages
-- lua -e "require'pali'.sync()"
function M.sync()
    print("Pali is syncing...")
    local spec = M.loadspec()
    local lock = M.loadlock()
    local spec_set = M.to_set(spec)
    local lock_set = M.to_set(lock)

    if os.getenv("DEBUG") then
        print("spec \\ lock = " .. M.serialize(M.diff(spec_set, lock_set)))
        print()
        print("lock \\ spec = " .. M.serialize(M.diff(lock_set, spec_set)))
    end

    -- Get a value from a namespace, either from spec or lock
    local changed = false
    local function process_diff(diff, op)
        for ns, pkgset in pairs(diff) do
            local is_cmd = (spec[ns] or {}).cmd or (lock[ns] or {}).cmd
            local op_str = (spec[ns] or {})[op] or (lock[ns] or {})[op]

            if not empty(pkgset) then
                changed = true
                if is_cmd then
                    -- command
                    run(op_str)
                else
                    -- list of packages
                    local pkgs = table.concat(set_to_array(pkgset), ' ')
                    run(op_str .. ' ' .. pkgs)
                end
            end
        end
    end

    -- Packages that were added
    process_diff(M.diff(spec_set, lock_set), 'add')

    -- Packages that were removed
    process_diff(M.diff(lock_set, spec_set), 'remove')

    if changed then
        print("Saving lock...")
        M.savelock(spec)
    else
        print("Nothing to do...")
    end
end

-- Overrides lock with current spec
function M.override()
    M.savelock(M.loadspec())
end

-- Updates namespaces that have an `update` key
function M.update()
    print("Pali is updating...")
    local spec = M.loadspec()
    for ns, pkgset in pairs(spec) do
        if pkgset.update ~= nil then
            print("> Updating \27[92m" .. ns .. "\27[0m")
            run(pkgset.update)
        end
    end
end

return M
