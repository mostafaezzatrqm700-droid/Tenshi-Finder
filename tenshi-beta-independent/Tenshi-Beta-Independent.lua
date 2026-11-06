-- Tenshi Finder independent client loader
local base='https://raw.githubusercontent.com/mostafaezzatrqm700-droid/Tenshi-Finder/tenshi-beta-independent/tenshi-beta-independent/client-source/'
local source={}
for i=1,4 do
    local name=string.format('part-%02d.lua',i)
    local ok,data=pcall(function() return game:HttpGet(base..name) end)
    assert(ok and type(data)=='string' and #data>0,'Tenshi Finder: failed to download '..name)
    source[i]=data
end
local fn,err=loadstring(table.concat(source))
assert(fn,'Tenshi Finder: invalid client source: '..tostring(err))
return fn()
