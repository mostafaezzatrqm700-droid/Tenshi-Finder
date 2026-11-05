-- Tenshi Finder public v0.4.3 / UI18
-- Based on public commit 7fd7826415b94846abc924aa0ce9308b541c0653.
-- Public host/config; broadcast contract preserved from public v0.4.3.
-- NYX Spawn Panel: current-server field eggs, read-only display.
-- Schema reference: monthonsova/Steal-An-Egg, EggESP/esp/EggData.lua.
-- Reports egg sightings and server IDs to the shared Finder host.
-- V4: field snapshot + separately replicated Halloween world eggs.
-- Records are never filtered by distance or by model availability.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local player = Players.LocalPlayer
assert(player, 'Join the game first')
local parent = player:WaitForChild('PlayerGui', 15)
assert(parent, 'PlayerGui unavailable')
local old = parent:FindFirstChild('TENSHI_FINDER_BETA')
if old then old:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'TENSHI_FINDER_BETA'
gui:SetAttribute('TenshiUIBuild','PUBLIC-V05-TOP10')
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
pcall(function() gui.ClipToDeviceSafeArea = false end)
gui.DisplayOrder = 1200
gui.Parent = parent
local alive = true
local highlight
gui.Destroying:Connect(function() alive = false; if highlight then highlight:Destroy() end end)
local function make(class, props, holder)
    local obj = Instance.new(class)
    for key, value in pairs(props) do obj[key] = value end
    obj.Parent = holder
    return obj
end
local function label(holder, text, pos, size, color, fontSize)
    return make('TextLabel', {Text=text,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=color or Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=fontSize or 13,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},holder)
end
local function module(path)
    local obj = RS
    for part in path:gmatch('[^.]+') do
        obj = obj:FindFirstChild(part)
        assert(obj, 'Missing game module: '..path)
    end
    return require(obj)
end
local function numberField(record, keys)
    for _, key in ipairs(keys) do
        local value = record and record[key]
        if type(value)=='number' and value==value and math.abs(value)<math.huge then return value end
    end
end
local function modelFor(uid)
    if type(uid)~='string' then return end
    local folder = workspace:FindFirstChild('AreaEggSlotsClient')
    local obj = (folder and folder:FindFirstChild(uid)) or workspace:FindFirstChild(uid)
    if obj and obj:IsA('Model') then return obj end
end
local function displayedRate(model)
    if not model then return end
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA('TextLabel') or obj:IsA('TextButton') then
            local text=obj.Text:gsub('<[^>]+>',''):gsub(',','')
            local amount,suffix=text:match('%$?%s*(%d+%.?%d*)%s*(%a*)%s*/[sS]')
            local powers={['']=1,k=1e3,m=1e6,b=1e9,t=1e12,qa=1e15,q=1e15,qi=1e18}
            local factor=suffix and powers[suffix:lower()]
            if amount and factor then return tonumber(amount)*factor end
        end
    end
end
local function money(value)
    if not value then return 'Income unavailable' end
    for _,entry in ipairs({{1e18,'Qi'},{1e15,'Qa'},{1e12,'T'},{1e9,'B'},{1e6,'M'},{1e3,'K'}}) do
        if value>=entry[1] then return string.format('$%.2f%s/s',value/entry[1],entry[2]) end
    end
    return string.format('$%.2f/s',value)
end
local function valid(value)
    return type(value)=='number' and value==value and value>=0 and value<math.huge
end
local function computedRate(base, scale, muts, mutationModule)
    if not valid(base) or not valid(scale) or scale==0 then return nil end
    local multi=1
    if type(muts)~='table' then return nil end
    if next(muts) then
        local fn=mutationModule and mutationModule.EarningsFor
        if type(fn)~='function' then return nil end
        local ok,result=pcall(fn,muts)
        if not ok or not valid(result) then return nil end
        multi=result
    end
    -- Observed public implementation; displayed model income takes precedence.
    local factor=scale>5 and (scale/5)^1.2*19.637875755794113 or scale^1.85
    local result=base*factor*multi
    return valid(result) and result or nil
end
local function compare(a,b,sortMode)
    -- Unknown event species are visibly pinned for inspection, not called Divine.
    local av,bv
    if sortMode==1 then av,bv=a.rate,b.rate
    elseif sortMode==2 then av,bv=a.scale,b.scale
    else av,bv=a.tier,b.tier end
    -- Unavailable values are never replaced with invented zeroes.
    if av==nil and bv~=nil then return false end
    if bv==nil and av~=nil then return true end
    if av~=bv then return av>bv end
    if sortMode~=1 and a.rate~=b.rate then return (a.rate or -1)>(b.rate or -1) end
    if a.tier~=b.tier then return a.tier>b.tier end
    return tostring(a.key)<tostring(b.key)
end
local function canonical(value)
    return tostring(value or ''):lower():gsub('^halloween%s*',''):gsub('%s*egg$',''):gsub('[^%w]','')
end
local function resolveSpec(specs, source, modelName)
    if source and specs[source] then return specs[source] end
    local result
    local wanted=canonical(source or modelName)
    if wanted=='' then return nil end
    for key,spec in pairs(specs) do
        if type(spec)=='table' then
            for _,alias in pairs({key,spec.Id,spec.DisplayName,spec.Source,spec.EggSource,spec.EggModel}) do
                if canonical(alias)==wanted then
                    if result and result~=spec then return nil end -- ambiguous aliases stay unresolved
                    result=spec
                end
            end
        end
    end
    return result
end
local function eventTraits(model,record)
    local names,seen,sources={},{},{}
    local known=false
    local function insert(v)
        if type(v)=='string' and v~='' and v~='None' and v~='Normal' and not seen[v] then
            seen[v]=true; names[#names+1]=v
        end
    end
    local function parse(value)
        if type(value)=='table' then
            for key,v in pairs(value) do
                if v==true and type(key)=='string' then insert(key)
                elseif type(v)=='string' then insert(v) end
            end
        elseif type(value)=='string' then
            local ok,parsed=pcall(function() return game:GetService('HttpService'):JSONDecode(value) end)
            if ok and type(parsed)=='table' then parse(parsed)
            else for v in value:gmatch('[^,;|]+') do insert(v:match('^%s*(.-)%s*$')) end end
        end
    end
    local keys={'Mutations','Mutation','BaseMutation','MutationIds','MutationId'}
    local function inspect(attrs,source,authoritative)
        for _,key in ipairs(keys) do
            local value=attrs[key]
            if type(value)=='string' or type(value)=='table' then
                parse(value)
                if authoritative or #names>0 then known=true end
                sources[source]=true
            end
        end
    end
    if type(record)=='table' then inspect(record,'UID record',true) end
    inspect(model:GetAttributes(),'model attrs',true)
    for _,child in ipairs(model:GetDescendants()) do
        inspect(child:GetAttributes(),'child attrs',false)
        if child:IsA('StringValue') then
            for _,key in ipairs(keys) do
                if child.Name==key then parse(child.Value); sources['StringValue']=true; if #names>0 then known=true end end
            end
        end
    end
    table.sort(names)
    local origin={}; for source in pairs(sources) do origin[#origin+1]=source end; table.sort(origin)
    return names,known,table.concat(origin,' + ')
end
local function meshSignature(model)
    local ids={}
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA('MeshPart') or obj:IsA('SpecialMesh') then
            local id=tostring(obj.MeshId):match('%d+')
            if id then ids[#ids+1]=id end
        end
    end
    table.sort(ids)
    return #ids>0 and table.concat(ids,':') or nil
end
local function uniqueMatch(candidates)
    local found
    for _,candidate in ipairs(candidates) do
        if found and found~=candidate then return nil end
        found=candidate
    end
    return found
end
local function readTraitNames(record)
    local names,seen={},{}
    local known=record.Mutations~=nil or record.BaseMutation~=nil
    local function add(value)
        if type(value)=='string' and value~='' and value~='None' and value~='Normal' and not seen[value] then seen[value]=true;names[#names+1]=value end
    end
    if type(record.Mutations)=='table' then
        for key,value in pairs(record.Mutations) do
            if value==true and type(key)=='string' then add(key)
            elseif type(value)=='string' then add(value)
            elseif type(value)=='table' then local id=value.Id or value._id or value.Name; if type(id)=='string' then add(id) else known=false end end
        end
    elseif type(record.Mutations)=='string' then
        for value in record.Mutations:gmatch('[^,;|]+') do add(value:match('^%s*(.-)%s*$')) end
    end
    add(record.BaseMutation);table.sort(names)
    return names,known
end
local function createFinder(D)
    local cycleModule
    pcall(function() cycleModule=module('Shared.Util.AreaEggCycle') end)
    local function cycleInfo()
        if not cycleModule then return nil end
        local ok,info=pcall(function()
            local now=workspace:GetServerTimeNow()
            local running=cycleModule.IsRunning()
            local remaining=cycleModule.SecondsUntilReset(now)
            local respawnAt
            if type(cycleModule.PeriodStartTime)=='function' and type(cycleModule.PeriodIndexAt)=='function' then
                local known,value=pcall(function() return cycleModule.PeriodStartTime(cycleModule.PeriodIndexAt(now))*1000 end)
                if known and type(value)=='number' then respawnAt=value end
            end
            return {resetAt=cycleModule.NextResetTime(now)*1000,respawnAt=respawnAt,remaining=remaining,running=running}
        end)
        return ok and info or nil
    end
    -- Display/join quarantine only. This never filters broadcast snapshots.
    D.publicPrioritySeen={}
    D.publicPriorityVisible=function(entry,rank)
        if rank~=1 then return true end
        local first=D.publicPrioritySeen[entry.key]
        if not first then first=os.clock();D.publicPrioritySeen[entry.key]=first end
        return os.clock()-first>=5
    end
    D.publicSightings={}
    D.publicSightingsDirty=false
    D.publicSightingsWriteAt=-math.huge
    D.publicSightingsPath='tenshi_public_sighting_lifecycle_v1.json'
    if type(readfile)=='function' then
        pcall(function()
            local saved=game:GetService('HttpService'):JSONDecode(readfile(D.publicSightingsPath))
            if type(saved)=='table' and saved.version==1 and type(saved.items)=='table' then
                local count=0
                for key,value in pairs(saved.items) do
                    if count>=60000 then break end
                    if type(key)=='string' and #key<=512 and type(value)=='table' and (value.retired==true or type(value.deadline)=='number' and value.deadline==value.deadline and math.abs(value.deadline)<math.huge) then D.publicSightings[key]=value;count+=1 end
                end
            end
        end)
    end
    -- This exact sighting was confirmed to predate multiple resets.
    D.publicSightings['107778070777162:10d3ade5-36f6-42c6-b25e-b4cbaa61977e:845e5200c4984a26bb83680e068ac9c5']={retired=true}
    D.publicEntryAllowed=function(entry,now)
        if type(entry)~='table' then return false end
        local key=entry.key
        if type(key)~='string' then return true end
        if not D.publicPrioritySeen[key] then D.publicPrioritySeen[key]=os.clock() end
        local prior=D.publicSightings[key]
        if prior and prior.retired then return false end
        if prior and prior.deadline<=now then prior.retired=true;D.publicSightingsDirty=true;return false end
        if entry.resetEstimated==false and type(entry.expiresAt)=='number' then
            if not prior then
                prior={deadline=entry.expiresAt};D.publicSightings[key]=prior;D.publicSightingsDirty=true
            elseif entry.expiresAt<prior.deadline then prior.deadline=entry.expiresAt;D.publicSightingsDirty=true end
            if prior.deadline<=now then prior.retired=true;return false end
        end
        return true
    end
    D.savePublicSightings=function()
        if not D.publicSightingsDirty or os.clock()-D.publicSightingsWriteAt<2 or type(writefile)~='function' then return end
        D.publicSightingsWriteAt=os.clock()
        local ok=pcall(function() writefile(D.publicSightingsPath,game:GetService('HttpService'):JSONEncode({version=1,items=D.publicSightings})) end)
        if ok then D.publicSightingsDirty=false end
    end

    local PREMIUM_EDITION=false
    local AUTO_KEY=''
    local originalMake,originalLabel=D.make,D.label
    D.make=function(class,props,parent)
        if class=='TextButton' or class=='TextBox' then props.Font=Enum.Font.GothamBold;props.TextSize=math.max(props.TextSize or 15,15) end
        if class=='TextBox' then props.TextColor3=Color3.fromRGB(25,25,30) end
        local obj=originalMake(class,props,parent)
        if class=='TextButton' or class=='TextBox' then originalMake('UICorner',{CornerRadius=UDim.new(0,5)},obj) end
        return obj
    end
    D.label=function(parent,text,pos,size,color,fontSize)
        local obj=originalLabel(parent,text,pos,size,color or Color3.fromRGB(240,242,255),math.max(fontSize or 15,14))
        obj.Font=Enum.Font.GothamBold;obj.TextStrokeColor3=Color3.new(0,0,0);obj.TextStrokeTransparency=0.45;return obj
    end
    local DISCORD='https://discord.gg/Z65aABK2TT'
    local Http=game:GetService('HttpService')
    local Teleports=game:GetService('TeleportService')
    local requestFn=request or http_request or (syn and syn.request) or (http and http.request)
    local active,othersOnly=true,false
    local reporterId=Http:GenerateGUID(false)
    local config,configAt=nil,-math.huge
    local feed,feedAt={},0
    local clockOffset=0
    local networkBusy=false
    local networkTicket=0
    local localStates={}
    local reportStatus='Connecting'
    local queryStatus=''
    local minRate,minRank=0,6
    local joining=false
    local localHighlight
    local viewerCode=PREMIUM_EDITION and AUTO_KEY or ''
    local pageOffset,nextOffset=0,nil
    local queryEpoch=0
    local settingsPath=PREMIUM_EDITION and 'tenshi_beta_premium_ui.json' or 'tenshi_beta_ui.json'
    local settings={}
    if type(readfile)=='function' then pcall(function() local data=Http:JSONDecode(readfile(settingsPath));if type(data)=='table' then settings=data end end) end
    if type(settings.myServer)=='boolean' then othersOnly=settings.myServer end
    if type(settings.minRank)=='number' then
        local saved=math.floor(settings.minRank)
        if saved>=6 and saved<=10 then minRank=saved
        elseif saved==0 and settings.rarityMenu=='mythic-up-v1' then minRank=0 end
    end
    local menuHotkey=Enum.KeyCode.F
    if type(settings.menuHotkey)=='string' then
        pcall(function() local saved=Enum.KeyCode[settings.menuHotkey];if saved and saved~=Enum.KeyCode.Unknown and not (settings.menuHotkey=='RightShift' and settings.hotkeyDefaultVersion~=2) then menuHotkey=saved end end)
    end
    local themeModal,loadUiAsset,syncCloseArt
    local sharingNotice=D.label(D.gui,'EGG FINDER ON • Sharing egg sightings & server ID',UDim2.new(0,12,1,-28),UDim2.new(1,-24,0,22),Color3.fromRGB(245,245,245),12)
    sharingNotice.Visible=false;sharingNotice.TextSize=12;sharingNotice.TextWrapped=true;sharingNotice.TextStrokeTransparency=0.15
    local panel=D.make('Frame',{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-18,0.5,0),Size=UDim2.new(0.94,0,0.86,0),BackgroundColor3=Color3.fromRGB(22,23,27),Visible=false},D.gui)
    local responsiveScale=D.make('UIScale',{Scale=0.8},panel)

    D.make('UICorner',{CornerRadius=UDim.new(0,4)},panel)
    D.make('UIStroke',{Color=Color3.fromRGB(125,128,138),Thickness=2},panel)
    local wallpaper=D.make('ImageLabel',{Name='TenshiWallpaper',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ImageTransparency=0.22,Image='',ScaleType=Enum.ScaleType.Crop,Active=false,ZIndex=1},panel)
    D.make('UICorner',{CornerRadius=UDim.new(0,4)},wallpaper)
    local wallpaperShade=D.make('Frame',{Name='WallpaperShade',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(10,13,26),BackgroundTransparency=0.25,BorderSizePixel=0,Active=false,ZIndex=1},wallpaper)
    D.make('UICorner',{CornerRadius=UDim.new(0,4)},wallpaperShade)
    local function contentLayer(child)
        if child:IsA('GuiObject') and child~=wallpaper and not child:IsDescendantOf(wallpaper) and child.ZIndex<2 then child.ZIndex=2 end
    end
    for _,child in ipairs(panel:GetDescendants()) do contentLayer(child) end
    panel.DescendantAdded:Connect(contentLayer)
    local bar=D.make('Frame',{Position=UDim2.fromOffset(1,1),Size=UDim2.new(1,-2,0,45),BackgroundColor3=Color3.fromRGB(46,47,52),BorderSizePixel=0},panel)
    D.make('UICorner',{CornerRadius=UDim.new(0,4)},bar)
    D.make('UICorner',{CornerRadius=UDim.new(0,4)},bar)
    D.make('UIGradient',{Color=ColorSequence.new(Color3.fromRGB(125,130,137),Color3.fromRGB(70,72,80)),Rotation=0},bar)
    local heading=D.label(panel,PREMIUM_EDITION and 'Tenshi Finder / PREMIUM' or 'Tenshi Finder',UDim2.fromOffset(14,8),UDim2.new(1,-55,0,32),nil,22)
    local open=D.make('ImageButton',{Image='',Position=UDim2.fromOffset(18,80),Size=UDim2.fromOffset(82,82),BackgroundColor3=Color3.fromRGB(250,250,250),ScaleType=Enum.ScaleType.Fit,ClipsDescendants=true},D.gui)
    D.make('UICorner',{CornerRadius=UDim.new(1,0)},open)
    D.make('UIStroke',{Color=Color3.fromRGB(185,25,40),Thickness=3},open)
    local fallback=D.label(open,'Tenshi',UDim2.new(),UDim2.fromScale(1,1),Color3.fromRGB(150,25,40),19)
    local iconCaption=D.label(open,'FINDER',UDim2.new(0.5,-44,1,5),UDim2.fromOffset(88,27),Color3.new(1,1,1),18)
    open.ClipsDescendants=false
    iconCaption.TextStrokeTransparency=0.15;iconCaption.TextXAlignment=Enum.TextXAlignment.Center
    local function restorePosition(target,value)
        if type(value)~='table' then return end
        for i=1,4 do if type(value[i])~='number' or value[i]~=value[i] or math.abs(value[i])>5000 then return end end
        target.Position=UDim2.new(value[1],value[2],value[3],value[4])
    end
    restorePosition(panel,settings.panel);restorePosition(open,settings.icon)
    D.publicGuiPercent=function(value,factor)
        local n=tonumber(value) or (tonumber(factor) or 1)*100
        if n~=n or math.abs(n)==math.huge then n=100 end
        return math.clamp(math.floor(n/10+0.5)*10,70,150)
    end
    do
        local latest
        local function consider(value)
            if type(value)=='table' and type(value.percent)=='number' and value.percent>=70 and value.percent<=150 and type(value.at)=='number' and (not latest or value.at>latest.at) then latest=value end
        end
        if type(readfile)=='function' then pcall(function() consider(Http:JSONDecode(readfile('tenshi_public_gui_size_v2.json'))) end) end
        pcall(function() local data=Teleports:GetTeleportSetting('TenshiPublicGuiSizeV2');if type(data)=='string' then consider(Http:JSONDecode(data)) end end)
        if latest then settings.sizePercent=latest.percent end
    end
    D.savePublicGuiSize=function(percent)
        local data=Http:JSONEncode({percent=percent,at=workspace:GetServerTimeNow()*1000})
        if type(writefile)=='function' then pcall(writefile,'tenshi_public_gui_size_v2.json',data) end
        pcall(function() Teleports:SetTeleportSetting('TenshiPublicGuiSizeV2',data) end)
    end
    local sizePercent=D.publicGuiPercent(settings.sizePercent,settings.sizeFactor)
    local sizeFactor=sizePercent/100
    local launcherScale=D.make('UIScale',{Scale=0.8},open)
    local function fitFinder()
        local view=D.gui.AbsoluteSize
        if view.X<=0 or view.Y<=0 then return end
        local landscape=view.X>view.Y
        local width=math.min(321.6*sizeFactor,view.X*(landscape and 0.40 or 0.92),view.X-16)
        local height=math.min(592*sizeFactor,view.Y*0.90)
        local scale=math.min(0.8*sizeFactor,width/402,height/680)
        responsiveScale.Scale=scale
        panel.Size=UDim2.fromOffset(402,height/scale)
        launcherScale.Scale=math.min(0.8,math.max(0.5,math.min(view.X,view.Y)/650))
        local function keepVisible(target,caption)
            local size=target.AbsoluteSize
            local p=target.Position
            local anchor=target.AnchorPoint
            local x=p.X.Scale*view.X+p.X.Offset
            local y=p.Y.Scale*view.Y+p.Y.Offset
            x=math.clamp(x,8+size.X*anchor.X,math.max(8+size.X*anchor.X,view.X-8-size.X*(1-anchor.X)))
            y=math.clamp(y,8+size.Y*anchor.Y,math.max(8+size.Y*anchor.Y,view.Y-8-caption-size.Y*(1-anchor.Y)))
            target.Position=UDim2.fromScale(x/view.X,y/view.Y)
        end
        task.defer(function()
            if panel.Parent then keepVisible(panel,0);keepVisible(open,28*launcherScale.Scale) end
        end)
    end
    local resizeConnection=D.gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fitFinder)
    D.gui.Destroying:Connect(function() resizeConnection:Disconnect() end)
    task.defer(fitFinder)

    local function saveSettings()
        pcall(D.savePublicGuiSize,sizePercent)
        if type(writefile)~='function' then return end
        pcall(function()
            local function coords(p) return {p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset} end
            writefile(settingsPath,Http:JSONEncode({myServer=othersOnly,minRank=minRank,rarityMenu='mythic-up-v1',menuHotkey=menuHotkey.Name,hotkeyDefaultVersion=2,sizeFactor=sizeFactor,sizePercent=sizePercent,panel=coords(panel.Position),icon=coords(open.Position)}))
        end)
    end
    D.saveGuiBeforeTeleport=saveSettings
    heading.Size=UDim2.fromOffset(185,32)
    heading.TextSize=19
    local brandLogo=D.make('ImageLabel',{Name='TenshiBrandLogo',Position=UDim2.fromOffset(10,2),Size=UDim2.fromOffset(180,42),BackgroundTransparency=1,Image='',ScaleType=Enum.ScaleType.Fit,Active=true},panel)
    brandLogo.Visible=false
    heading.Text='Tenshi beta v0.5'
    heading.TextSize=18
    heading.Font=Enum.Font.Arcade
    heading.TextScaled=true
    heading.TextWrapped=false
    heading.TextTruncate=Enum.TextTruncate.None
    D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=20},heading)
    heading.Size=UDim2.fromOffset(205,25)
    heading.Position=UDim2.fromOffset(10,2)
    heading.TextStrokeTransparency=0.65
    open.BackgroundTransparency=1
    iconCaption.Visible=false
    for _,decoration in ipairs(open:GetChildren()) do
        if decoration:IsA('UIStroke') then decoration.Enabled=false end
    end
    task.spawn(function()
        local asset=getcustomasset or getsynasset
        if type(asset)~='function' or type(writefile)~='function' then return end
        local ok,result=pcall(function()
            local bytes=game:HttpGet('https://raw.githubusercontent.com/syss1211/Tenshi-script/main/Tenshi-Finder-Beta-Ghost.png')
            if #bytes<100 then return end
            writefile('tenshi_beta_ghost_v2.png',bytes)
            return asset('tenshi_beta_ghost_v2.png')
        end)
        if ok and type(result)=='string' and open.Parent then open.Image=result;fallback.Visible=false end
    end)

    local sizeMinus=D.make('TextButton',{Name='SizeMinus',Text='',Position=UDim2.new(1,-182,0,3),Size=UDim2.fromOffset(40,40),BackgroundColor3=Color3.fromRGB(190,45,55),TextColor3=Color3.new(1,1,1)},panel)
    local sizePlus=D.make('TextButton',{Name='SizePlus',Text='',Position=UDim2.new(1,-94,0,3),Size=UDim2.fromOffset(40,40),BackgroundColor3=Color3.fromRGB(45,150,80),TextColor3=Color3.new(1,1,1)},panel)
    local sizeLabel=D.label(panel,'100%',UDim2.new(1,-138,0,13),UDim2.fromOffset(40,20),Color3.new(1,1,1),14)
    sizeLabel.TextXAlignment=Enum.TextXAlignment.Center
    sizeLabel.TextScaled=true;sizeLabel.TextWrapped=false
    D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=14},sizeLabel)
    for _,button in ipairs({sizeMinus,sizePlus}) do
        local corner=button:FindFirstChildOfClass('UICorner')
        if corner then corner.CornerRadius=UDim.new(0,6) end
        local line=D.make('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(16,4),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},button)
        D.make('UICorner',{CornerRadius=UDim.new(1,0)},line)
    end
    local upright=D.make('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(4,16),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},sizePlus)
    D.make('UICorner',{CornerRadius=UDim.new(1,0)},upright)
    local function paintSize()
        sizeLabel.Text=tostring(sizePercent)..'%'
        sizeMinus.Active=sizePercent>70;sizeMinus.Selectable=sizePercent>70
        sizePlus.Active=sizePercent<150;sizePlus.Selectable=sizePercent<150
    end
    local function changeSizeBy(delta)
        local nextPercent=math.clamp(sizePercent+delta,70,150)
        if nextPercent==sizePercent then return end
        sizePercent=nextPercent;sizeFactor=sizePercent/100
        paintSize();fitFinder();saveSettings()
    end
    sizeMinus.Activated:Connect(function() changeSizeBy(-10) end)
    sizePlus.Activated:Connect(function() changeSizeBy(10) end)
    paintSize()
    local close=D.make('TextButton',{Text='×',Position=UDim2.new(1,-33,0,4),Size=UDim2.fromOffset(27,27),BackgroundColor3=Color3.fromRGB(160,35,50),TextColor3=Color3.new(1,1,1),TextSize=22},panel)
    local closeArt=D.make('ImageLabel',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image='',ScaleType=Enum.ScaleType.Fit,Active=false},close)
    task.spawn(function()
        local asset=getcustomasset or getsynasset
        if type(asset)~='function' or type(writefile)~='function' then return end
        local ok,result=pcall(function()
            local bytes=game:HttpGet('https://raw.githubusercontent.com/syss1211/Tenshi-script/main/Tenshi-Finder-Beta-Close.png')
            writefile('tenshi_beta_close_v1.png',bytes)
            return asset('tenshi_beta_close_v1.png')
        end)
        if ok and type(result)=='string' and close.Parent then
            closeArt.Image=result;close.Text='';close.BackgroundTransparency=1
        end
    end)
    local suppressOpenUntil=0
    open.Activated:Connect(function() if os.clock()<suppressOpenUntil then return end; panel.Visible=not panel.Visible; D.localPanel.Visible=not panel.Visible end)
    close.Activated:Connect(function() panel.Visible=false; D.localPanel.Visible=true end)
    local Input=game:GetService('UserInputService')
    local drag
    local function draggable(target,handle,isLauncher)
        handle.Active=true
        handle.InputBegan:Connect(function(input)
            if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
            drag={target=target,input=input,start=input.Position,position=target.Position,absolute=target.AbsolutePosition,size=target.AbsoluteSize,launcher=isLauncher,moved=false}
        end)
    end
    draggable(panel,heading,false)
    draggable(panel,brandLogo,false)
    -- Window dragging is confined to its header; scrollbar has no drag overlay.
    draggable(panel,bar,false)

    draggable(open,open,true)
    local launcherHit=D.make('TextButton',{Name='LauncherHitArea',Text='',AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromOffset(-8,-8),Size=UDim2.new(1,16,1,16),ZIndex=5},open)
    draggable(open,launcherHit,true)
    launcherHit.Activated:Connect(function()
        if os.clock()<suppressOpenUntil then return end
        panel.Visible=not panel.Visible;D.localPanel.Visible=not panel.Visible
    end)
    local moveConnection=Input.InputChanged:Connect(function(input)
        if not drag then return end
        local mouse=drag.input.UserInputType==Enum.UserInputType.MouseButton1
        if (mouse and input.UserInputType~=Enum.UserInputType.MouseMovement) or (not mouse and input~=drag.input) then return end
        local dx,dy=input.Position.X-drag.start.X,input.Position.Y-drag.start.Y
        if dx*dx+dy*dy>25 then drag.moved=true end
        if not drag.moved then return end
        if drag.launcher then suppressOpenUntil=os.clock()+0.5 end
        local view=D.gui.AbsoluteSize
        local origin=D.gui.AbsolutePosition
        if view.X<=0 or view.Y<=0 then return end
        local left=drag.absolute.X-origin.X
        local top=drag.absolute.Y-origin.Y
        local x=math.clamp(left+dx,0,math.max(0,view.X-drag.size.X))
        local y=math.clamp(top+dy,0,math.max(0,view.Y-drag.size.Y-(drag.launcher and 28*launcherScale.Scale or 0)))
        local anchor=drag.target.AnchorPoint
        drag.target.Position=UDim2.fromScale((x+anchor.X*drag.size.X)/view.X,(y+anchor.Y*drag.size.Y)/view.Y)
    end)
    local endConnection=Input.InputEnded:Connect(function(input)
        if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then
            if drag.moved and drag.launcher then suppressOpenUntil=os.clock()+0.3 end
            if drag.moved then saveSettings() end
            drag=nil
        end
    end)
    D.gui.Destroying:Connect(function() moveConnection:Disconnect();endConnection:Disconnect();drag=nil end)
    local status=D.label(panel,'Connecting…',UDim2.fromOffset(14,52),UDim2.new(1,-28,0,48),Color3.fromRGB(210,218,240),14)
    status.Visible=false
    status.TextWrapped=true
    if not PREMIUM_EDITION then status.Size=UDim2.new(1,-28,0,24) end
    local discordSubtitle=D.label(panel,DISCORD,UDim2.fromOffset(10,27),UDim2.fromOffset(205,14),Color3.new(1,1,1),11)
    discordSubtitle.TextSize=11
    discordSubtitle.TextScaled=true;discordSubtitle.TextWrapped=false;discordSubtitle.Visible=true
    D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=11},discordSubtitle)
    local page={Text=''}
    local scope=D.make('TextButton',{Name='AllServers',Text='ALL SERVERS',Position=UDim2.new(0,10,1,-136),Size=UDim2.new(0.5,-15,0,34),BackgroundColor3=Color3.fromRGB(67,70,80),TextColor3=Color3.new(1,1,1),TextSize=14},panel)
    local myScope=D.make('TextButton',{Name='MyServer',Text='MY SERVER',Position=UDim2.new(0.5,5,1,-136),Size=UDim2.new(0.5,-15,0,34),BackgroundColor3=Color3.fromRGB(67,70,80),TextColor3=Color3.new(1,1,1),TextSize=14},panel)
    for _,button in ipairs({scope,myScope}) do
        button.TextScaled=true;button.TextWrapped=false
        D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=14},button)
    end
    local function styleScope()
        scope.BackgroundColor3=othersOnly and Color3.fromRGB(67,70,80) or Color3.fromRGB(45,130,75)
        myScope.BackgroundColor3=othersOnly and Color3.fromRGB(45,130,75) or Color3.fromRGB(67,70,80)
        scope.TextColor3=Color3.new(1,1,1);myScope.TextColor3=Color3.new(1,1,1)
    end
    local requestScopeRender
    local function setScope(myServer)
        if othersOnly==myServer then return end
        othersOnly=myServer;styleScope()
        page.Text=othersOnly and 'LOCAL EGGS' or PREMIUM_EDITION and 'GLOBAL TOP 10' or 'TOP 30'
        queryEpoch+=1;pageOffset=0;feedAt=-math.huge;task.defer(saveSettings)
        if requestScopeRender then requestScopeRender() end
    end
    scope.Activated:Connect(function() setScope(false) end)
    myScope.Activated:Connect(function() setScope(true) end)
    styleScope()
    local rarityOptions={{name='Mythic',rank=6},{name='Cosmic',rank=7},{name='Secret',rank=8},{name='Eternal',rank=9},{name='Divine',rank=10},{name='Any',rank=0}}
    local rarityIndex=1
    for i,option in ipairs(rarityOptions) do if option.rank==minRank then rarityIndex=i;break end end
    minRank=rarityOptions[rarityIndex].rank
    local function rarityButtonText()
        local name=rarityOptions[rarityIndex].name
        local colors={Mythic='#FF4B55',Cosmic='#BE55FF',Secret='#FFFFFF',Eternal='#DACAEC',Divine='#FFCD37',Any='#FFFFFF'}
        return 'MIN RARITY: <font color="'..colors[name]..'">'..name..'</font>'
    end
    local rarity=D.make('TextButton',{Text=rarityButtonText(),RichText=true,Position=UDim2.new(0,10,1,-96),Size=UDim2.new(0.60,-15,0,36),BackgroundColor3=Color3.fromRGB(45,90,175),TextColor3=Color3.new(1,1,1),TextSize=12},panel)
    rarity.Activated:Connect(function()
        rarityIndex=rarityIndex%#rarityOptions+1;minRank=rarityOptions[rarityIndex].rank
        rarity.Text=rarityButtonText()
        queryEpoch+=1;feed={};pageOffset=0;feedAt=-math.huge;saveSettings()
    end)
    local access=PREMIUM_EDITION and AUTO_KEY=='' and D.make('TextBox',{Text='',PlaceholderText='PREMIUM code (top 10)',Position=UDim2.new(0,10,1,-44),Size=UDim2.new(1,-20,0,34),ClearTextOnFocus=false,BackgroundColor3=Color3.fromRGB(45,48,60),TextColor3=Color3.new(1,1,1),TextSize=12},panel) or {Text=''} 
    local unlock=D.make('TextButton',{Text='PREMIUM',Position=UDim2.new(0.60,5,1,-96),Size=UDim2.new(0.40,-15,0,36),BackgroundColor3=Color3.fromRGB(210,170,35),TextColor3=Color3.new(1,1,1),TextSize=12},panel)
    access.Visible=PREMIUM_EDITION and AUTO_KEY==''
    if PREMIUM_EDITION and AUTO_KEY~='' then
        unlock.Visible=false
        D.label(panel,'PREMIUM',UDim2.new(0.60,5,0,106),UDim2.new(0.40,-15,0,36),Color3.new(1,1,1),15)
    end
    local copy=D.make('TextButton',{Text='COPY DISCORD LINK',Position=UDim2.fromOffset(10,176),Size=UDim2.new(1,-110,0,27),BackgroundColor3=Color3.fromRGB(65,75,135),TextColor3=Color3.new(1,1,1),TextSize=12,Visible=not PREMIUM_EDITION},panel)
    copy.Visible=false -- Discord copying is now inside the Premium dialog.
    local function copyLink()
        if type(setclipboard)=='function' then
            local ok=pcall(setclipboard,DISCORD)
            if ok then
                copy.Text='LINK COPIED'
                task.delay(1.5,function() if active then copy.Text='COPY DISCORD LINK' end end)
                return true
            end
        end
        copy.Text='discord.gg/Z65aABK2TT'; copy.TextWrapped=true; queryStatus='Discord: '..DISCORD; return false
    end
    copy.Activated:Connect(copyLink)
    local premiumPopup
    local function showPremiumPopup()
        if premiumPopup then premiumPopup.Visible=true;return end
        premiumPopup=D.make('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.3,Active=true,ZIndex=30},panel)
        local box=D.make('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(1,-28,0,232),BackgroundColor3=Color3.fromRGB(43,45,50),ZIndex=31},premiumPopup)
        D.make('UICorner',{CornerRadius=UDim.new(0,4)},box)
        themeModal(box)
        local discordMark=D.make('ImageLabel',{Name='PremiumDiscordIcon',Image='',AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,8),Size=UDim2.fromOffset(80,66),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Active=false,ZIndex=32},box)
        loadUiAsset(discordMark,'discord')
        local title=D.label(box,'JOIN DISCORD TO GET PREMIUM',UDim2.fromOffset(12,76),UDim2.new(1,-24,0,52),Color3.new(1,1,1),20)
        title.Font=Enum.Font.FredokaOne;title.TextScaled=true;title.TextWrapped=true;title.TextXAlignment=Enum.TextXAlignment.Center;title.ZIndex=32
        D.make('UITextSizeConstraint',{MinTextSize=12,MaxTextSize=21},title)
        local bar=D.make('Frame',{Position=UDim2.fromOffset(12,148),Size=UDim2.new(1,-24,0,64),BackgroundColor3=Color3.fromRGB(57,60,68),ZIndex=32},box)
        D.make('UICorner',{CornerRadius=UDim.new(0,5)},bar)
        local link=D.label(bar,DISCORD,UDim2.fromOffset(8,6),UDim2.new(1,-116,1,-12),Color3.fromRGB(200,210,255),12)
        link.TextSize=12;link.TextWrapped=true;link.ZIndex=33
        local popupCopy=D.make('TextButton',{Font=Enum.Font.FredokaOne,Text='COPY LINK',Position=UDim2.new(1,-103,0.5,-18),Size=UDim2.fromOffset(96,36),BackgroundColor3=Color3.fromRGB(85,105,220),TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=33},bar)
        popupCopy.Font=Enum.Font.FredokaOne
        popupCopy.Activated:Connect(function()
            if type(setclipboard)=='function' and pcall(setclipboard,DISCORD) then
                popupCopy.Text='COPIED'
                task.delay(1.5,function() if active then popupCopy.Text='COPY LINK' end end)
            else popupCopy.Text='COPY UNAVAILABLE' end
        end)
        local dismiss=D.make('TextButton',{Text='×',Position=UDim2.new(1,-34,0,5),Size=UDim2.fromOffset(28,26),BackgroundColor3=Color3.fromRGB(135,55,90),TextColor3=Color3.new(1,1,1),TextSize=22,ZIndex=32},box)
        syncCloseArt(dismiss)
        dismiss.Activated:Connect(function() premiumPopup.Visible=false end)
    end
    unlock.Activated:Connect(function()
        if not PREMIUM_EDITION then
            showPremiumPopup()
            return
        end
        pageOffset=0
        if viewerCode~='' then viewerCode=''; feed={}; feedAt=-math.huge; unlock.Text='PREMIUM'; queryStatus='Public Finder'; return end
        viewerCode=access.Text:match('^%s*(.-)%s*$'); access.Text=''; feed={}; feedAt=-math.huge
        queryStatus='Checking access code'
    end)
    local refreshButton=D.make('TextButton',{Text='REFRESH',Position=UDim2.fromOffset(10,54),Size=UDim2.new(1,-20,0,30),BackgroundColor3=Color3.fromRGB(115,215,45),BackgroundTransparency=0.15,TextColor3=Color3.new(1,1,1),TextSize=14},panel)
    local resetTimer=D.label(refreshButton,'RESET --:--',UDim2.fromOffset(8,0),UDim2.new(0.28,-8,1,0),Color3.fromRGB(230,245,255),13)
    resetTimer.TextXAlignment=Enum.TextXAlignment.Left
    resetTimer.TextTruncate=Enum.TextTruncate.AtEnd
    resetTimer.Active=false
    local refreshing=false
    local list=D.make('ScrollingFrame',{Position=UDim2.fromOffset(14,92),Size=UDim2.new(1,-16,1,-238),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.None,CanvasSize=UDim2.new(),ScrollBarThickness=6,ScrollBarImageColor3=Color3.fromRGB(137,140,150),ScrollBarImageTransparency=0},panel)
    D.make('UIListLayout',{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},list)
    local loadingVisible=true
    local function loadingText(now)
        return 'Loading '..string.rep('.',math.floor(now/0.4)%3+1)
    end
    local aliveMessage=D.label(list,loadingText(os.clock()),UDim2.new(),UDim2.new(1,-10,0,40),nil,12)
    local function network(url,method,body,headers,raw)
        if type(requestFn)~='function' then return nil,'Executor HTTP POST unavailable' end
        if networkBusy then return nil,'Network request still pending' end
        networkBusy=true
        networkTicket+=1
        local ticket=networkTicket
        local done,result=false,nil
        local worker=task.spawn(function()
            result=table.pack(pcall(requestFn,{Url=url,Method=method,Headers=headers or {},Body=body,Timeout=10}))
            done=true; if networkTicket==ticket then networkBusy=false end
        end)
        local deadline=os.clock()+12
        while active and not done and os.clock()<deadline do task.wait(0.1) end
        if not done then
            if networkTicket==ticket then networkTicket+=1;networkBusy=false end
            pcall(task.cancel,worker)
            return nil,'Network timeout'
        end
        if not result[1] then return nil,'Network request failed' end
        local response=result[2]
        if type(response)~='table' then return nil,'Invalid HTTP response' end
        local code=tonumber(response.StatusCode or response.Status)
        if code~=200 then
            local message='HTTP '..tostring(code)
            local good,details=pcall(Http.JSONDecode,Http,response.Body or '')
            if good and type(details)=='table' and type(details.error)=='string' then message=message..': '..details.error:sub(1,120) end
            return nil,message
        end
        if raw then return response.Body end
        local ok,decoded=pcall(Http.JSONDecode,Http,response.Body or '')
        if not ok then return nil,'Invalid JSON response' end
        return decoded
    end
    -- Roblox public-server directory, independent of the Finder report feed.
    status.Size=UDim2.new(0.53,-14,0,24)
    status.TextSize=11
    local randomJoin=D.make('TextButton',{Name='RandomServer',Text='JOIN RANDOM SERVER',Position=UDim2.new(0,10,1,-52),Size=UDim2.new(1,-20,0,40),BackgroundColor3=Color3.fromRGB(195,38,55),TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.GothamBold},panel)
    D.make('UICorner',{CornerRadius=UDim.new(0,6)},randomJoin)
    randomJoin.TextScaled=true;randomJoin.TextWrapped=false
    D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=14},randomJoin)
    local randomBusy=false
    local randomRetryAt=0
    local recentRandom={}
    local recentRandomPath='tenshi_beta_random_recent_v1.json'
    pcall(function()
        if type(readfile)=='function' then
            local saved=Http:JSONDecode(readfile(recentRandomPath))
            if type(saved)=='table' then for _,id in ipairs(saved) do if type(id)=='string' and #recentRandom<20 then recentRandom[#recentRandom+1]=id end end end
        end
    end)
    local function rememberRandom(id)
        for i=#recentRandom,1,-1 do if recentRandom[i]==id then table.remove(recentRandom,i) end end
        recentRandom[#recentRandom+1]=id
        while #recentRandom>20 do table.remove(recentRandom,1) end
        if type(writefile)=='function' then pcall(function() writefile(recentRandomPath,Http:JSONEncode(recentRandom)) end) end
    end
    local function friendServerExclusions()
        local ok,friends=pcall(function() return D.player:GetFriendsOnlineAsync(200) end)
        if not ok then ok,friends=pcall(function() return D.player:GetFriendsOnline(200) end) end
        if not ok or type(friends)~='table' then error('Cannot check friend servers; try again') end
        local excluded={[game.JobId]=true}
        for _,friend in ipairs(friends) do
            local place=tonumber(friend.PlaceId or friend.placeId)
            local id=friend.GameId or friend.gameId or friend.JobId or friend.jobId
            if type(id)=='string' and id~='' then
                excluded[id]=true
            elseif place==game.PlaceId then
                local success,current,_,friendPlace,friendJob=pcall(function() return Teleports:GetPlayerPlaceInstanceAsync(friend.VisitorId or friend.visitorId) end)
                if success and tonumber(friendPlace)==game.PlaceId and type(friendJob)=='string' and friendJob~='' then excluded[friendJob]=true
                elseif success and current==true then excluded[game.JobId]=true
                else error('Friend server location unavailable; try again') end
            end
        end
        return excluded
    end
    randomJoin.Activated:Connect(function()
        if randomBusy or joining or os.clock()<randomRetryAt then return end
        D.randomAttempt=(D.randomAttempt or 0)+1
        local attempt=D.randomAttempt
        randomBusy=true;joining=true;randomJoin.Active=false;randomJoin.AutoButtonColor=false;randomJoin.Text='SEARCHING...'
        task.spawn(function()
            local ok,err=pcall(function()
                local excluded=friendServerExclusions()
                local candidates,seen={},{}
                if not config then error('Finder connection not ready; try again') end
                local response=requestFn({Url=config.endpoint..'/v1/random-servers',Method='GET',Headers={['X-NYX-Room']=config.roomKey},Timeout=10})
                local code=type(response)=='table' and tonumber(response.StatusCode or response.Status)
                local parsed,data=pcall(Http.JSONDecode,Http,type(response)=='table' and response.Body or '')
                if code~=200 then
                    local seconds=parsed and type(data)=='table' and tonumber(data.retryAfterSeconds) or 30
                    randomRetryAt=os.clock()+math.max(1,seconds or 30)
                    error('Roblox server list busy; wait '..tostring(math.ceil(seconds or 30))..'s')
                end
                if not parsed or type(data)~='table' or type(data.data)~='table' then error('Invalid server list') end
                for _,server in ipairs(data.data) do
                    local playing,maxPlayers=tonumber(server.playing),tonumber(server.maxPlayers)
                    if type(server.id)=='string' and not seen[server.id] and not excluded[server.id] and playing and maxPlayers and playing<maxPlayers then
                        candidates[#candidates+1]=server.id;seen[server.id]=true
                    end
                end
                local fresh={}
                for _,id in ipairs(candidates) do if not table.find(recentRandom,id) then fresh[#fresh+1]=id end end
                if #fresh>0 then candidates=fresh end
                if #candidates==0 then error('No available random server without known friends; try again') end
                if not active then return end
                local target=candidates[math.random(1,#candidates)]
                D.saveGuiBeforeTeleport()
                if type(D.flushReport)=='function' then pcall(D.flushReport) end
                if not active then return end
                randomJoin.Text='JOINING...'
                rememberRandom(game.JobId);rememberRandom(target)
                D.stopFarm()
                Teleports:TeleportToPlaceInstance(game.PlaceId,target,D.player)
            end)
            if not ok then
                randomBusy=false;joining=false;randomJoin.Active=true;randomJoin.AutoButtonColor=true;randomJoin.Text='TRY AGAIN'
                local seconds=math.ceil(math.max(0,randomRetryAt-os.clock()))
                if seconds>0 then
                    randomJoin.Text='WAIT '..tostring(seconds)..'s';randomJoin.Active=false;randomJoin.AutoButtonColor=false
                    task.delay(seconds,function() if randomJoin.Parent then randomJoin.Active=true;randomJoin.AutoButtonColor=true;randomJoin.Text='TRY AGAIN' end end)
                else randomRetryAt=os.clock()+0.75 end
                queryStatus='Random server: '..tostring(err)
                pcall(function() game:GetService('StarterGui'):SetCore('SendNotification',{Title='Random server',Text=queryStatus,Duration=7}) end)
                return
            end
            task.delay(5,function()
                if not active or D.randomAttempt~=attempt or not randomBusy then return end
                D.randomAttempt+=1;randomBusy=false;joining=false
                randomRetryAt=os.clock()+0.75
                if randomJoin.Parent then randomJoin.Active=true;randomJoin.AutoButtonColor=true;randomJoin.Text='TRY AGAIN' end
            end)
        end)
    end)

    local publicBroadcastConfig=nil
    local featureConfig=nil
    local featureSending=false
    local featureTicket=0
    local function optionalFeatureSync(payload)
        if not featureConfig or featureSending or type(requestFn)~='function' then return end
        local endpoint,key=featureConfig.endpoint,featureConfig.roomKey
        featureSending=true;featureTicket+=1
        local ticket=featureTicket
        local worker=task.spawn(function()
            local ok,response=pcall(function()
                return requestFn({Url=endpoint..'/v1/report',Method='POST',Timeout=6,
                    Headers={['Content-Type']='application/json',['X-NYX-Room']=key},Body=Http:JSONEncode(payload)})
            end)
            if featureTicket~=ticket then return end
            featureSending=false
            if D.gui then pcall(function() D.gui:SetAttribute('TenshiFeatureReportOK',ok and type(response)=='table' and tonumber(response.StatusCode or response.Status)==200) end) end
        end)
        task.delay(8,function()
            if featureTicket==ticket and featureSending then featureTicket+=1;featureSending=false;pcall(task.cancel,worker) end
        end)
    end
    -- Feature configuration is optional. Its requests never own the primary
    -- broadcast/feed network lock and cannot gate the classic public sender.
    task.spawn(function()
        while active do
            local ok,data=pcall(function()
                local response=requestFn({Url='https://raw.githubusercontent.com/syss1211/Tenshi-script/experimental/NYX-Finder-Experimental-Config.json?features='..os.time(),Method='GET',Timeout=6})
                if tonumber(response.StatusCode or response.Status)~=200 then return nil end
                return Http:JSONDecode(response.Body)
            end)
            if ok and type(data)=='table' and type(data.endpoint)=='string' and data.endpoint:match('^https://[%w%.%-]+$') and type(data.roomKey)=='string' then
                featureConfig=data
                if publicBroadcastConfig then config=data;feedAt=-math.huge end
            end
            task.wait(60)
        end
    end)
    local function loadConfig()
        local data,err=network('https://raw.githubusercontent.com/syss1211/Tenshi-script/main/NYX-Finder-Config.json?nyx='..os.time(),'GET')
        if not data then return false,err end
        if type(data.endpoint)~='string' or not data.endpoint:match('^https://[%w%.%-]+$') or type(data.roomKey)~='string' then return false,'Finder configuration unavailable' end
        publicBroadcastConfig=data;config=featureConfig or data; configAt=os.clock()
        if false and type(writefile)=='function' then
            local asset=getcustomasset or getsynasset
            if type(asset)=='function' then
                local bytes=network(config.endpoint..'/assets/finder.jpg','GET',nil,nil,true)
                if bytes then
                    pcall(function() writefile('nyx_finder_icon_v19.jpg',bytes);open.Image=asset('nyx_finder_icon_v19.jpg');fallback.Visible=false end)
                end
            end
        end
        return true
    end
    local function headers(read) return {['Content-Type']='application/json',['X-NYX-Room']=config.roomKey,['X-NYX-Viewer']=read and viewerCode~='' and viewerCode or nil} end
    local broadcastInterval=15
    local function snapshot()
        local eggs={}
        for _,entry in ipairs(D.entries()) do
            if not entry.unresolved and entry.uid and entry.rate and entry.rate>0 then
                eggs[#eggs+1]={uid=tostring(entry.uid),name=entry.name,category=entry.category,rarity=entry.rarity,rank=entry.tier,rate=entry.rate,scale=entry.scale,weight=entry.weight,icon=entry.icon,area=entry.areaKey or entry.area,mutations=entry.mutationText or (entry.traitsKnown==false and 'UNKNOWN' or ''),traitsKnown=entry.traitsKnown~=false,estimated=entry.estimated==true or entry.unmutatedRate~=nil or entry.scaleFromModel==true,visualId=entry.visualId==true,source=entry.isEvent and 'event' or 'field'}
            end
        end
        table.sort(eggs,function(a,b) return a.rate>b.rate end)
        while #eggs>10 do eggs[#eggs]=nil end
        return eggs
    end
    local function report()
        if game.JobId=='' then return false,'No live server ID' end
        if not D.ready() then return false,'Waiting for a fresh field scan' end
        if not publicBroadcastConfig then return false,'Public broadcast configuration unavailable' end
        local eggs=snapshot()
        local good,metadata=pcall(function() return D.metadata and D.metadata() end)
        if not good then metadata=nil end
        local classicEggs=eggs
        -- Match the classic sender's native spawn-slot behavior. Optional state
        -- parsing is protected and never becomes a prerequisite for reporting.
        if metadata and type(metadata.states)=='table' then
            local parsed,filtered=pcall(function()
                local states={}
                for _,state in ipairs(metadata.states) do states[state.uid]=state.state end
                local values={}
                for _,e in ipairs(eggs) do if e.source=='event' or states[e.uid]=='Slot' then values[#values+1]=e end end
                return values
            end)
            if parsed then classicEggs=filtered end
        end
        local body={placeId=game.PlaceId,jobId=game.JobId,reporterId=reporterId,eggs=classicEggs}
        local data,err=network(publicBroadcastConfig.endpoint..'/v1/report','POST',Http:JSONEncode(body),
            {['Content-Type']='application/json',['X-NYX-Room']=publicBroadcastConfig.roomKey})
        if not data or data.ok~=true or type(data.accepted)~='number' then return false,err or 'Public broadcast not acknowledged' end
        if #classicEggs>0 and data.accepted<=0 then return false,'Public broadcast accepted zero eggs' end
        if D.gui then pcall(function() D.gui:SetAttribute('TenshiPublicAccepted',data.accepted);D.gui:SetAttribute('TenshiPublicSent',#classicEggs) end) end
        -- A separate, bounded worker sends feature metadata after primary ACK.
        -- The feature service must not relay this already-published report.
        local native={placeId=game.PlaceId,jobId=game.JobId,reporterId=reporterId,eggs=eggs,publicDirect=true,primaryAccepted=data.accepted,primarySent=#classicEggs}
        pcall(function()
            if metadata then
                native.eggStates=metadata.states;native.resetAt=metadata.resetAt;native.scanAt=metadata.scanAt
                native.scanAgeMs=math.max(0,(os.clock()-metadata.scanClock)*1000)
                native.resetRemainingMs=metadata.resetAt and math.max(0,metadata.resetAt-workspace:GetServerTimeNow()*1000) or nil
            end
            native.userId=D.player.UserId;native.playerIds={}
            for _,member in ipairs(game:GetService('Players'):GetPlayers()) do native.playerIds[#native.playerIds+1]=member.UserId end
            optionalFeatureSync(native)
        end)
        return true,'Shared '..tostring(data.accepted)..' eggs'
    end
    D.flushReport=report
    local function refresh()
        local epoch=queryEpoch
        local query='?localJob='..Http:UrlEncode(game.JobId)..'&placeId='..game.PlaceId..'&limit='..(viewerCode~='' and '10&tier=premium' or '30&tier=public')..'&offset=0&minRate='..tostring(minRate)..'&minRank='..tostring(minRank)
        local requestedCycle=cycleInfo()
        if requestedCycle then query=query..'&cycleRemainingMs='..tostring(math.max(0,requestedCycle.remaining*1000))..'&cycleId='..tostring(requestedCycle.resetAt) end
        if othersOnly then query=query..'&onlyJob='..Http:UrlEncode(game.JobId) end
        local data,err=network(config.endpoint..'/v1/eggs'..query,'GET',nil,headers(true))
        if epoch~=queryEpoch then return true end
        if not data or type(data.items)~='table' then
            if err=='HTTP 401' then viewerCode=''; unlock.Text='PREMIUM'; feed={}; pageOffset=0 end
            return false,err=='HTTP 401' and 'Wrong access code' or err or 'Invalid finder feed'
        end
        unlock.Text=data.tier=='premium' and 'PREMIUM ON' or 'PREMIUM'
        nextOffset=tonumber(data.nextOffset)
        page.Text=data.tier=='premium' and 'GLOBAL TOP 10' or 'TOP 30'
        clockOffset=(tonumber(data.serverTime) or os.time()*1000)/1000-os.clock()
        localStates={}
        for _,entry in ipairs(data.localStates or {}) do localStates[entry.key]=entry end
        feed={}
        for _,entry in ipairs(data.items) do if D.publicEntryAllowed(entry,(os.clock()+clockOffset)*1000) then feed[#feed+1]=entry end end
        D.savePublicSightings();feedAt=os.clock()
        queryStatus=data.tier=='premium' and string.format('PREMIUM | %d servers | %d reporters',data.servers or 0,data.participants or 0) or 'Updated'
        return true
    end
    local lastRender
    local rarityColors={
        divine=Color3.fromRGB(255,205,55),eternal=Color3.fromRGB(218,202,236),
        secret=Color3.fromRGB(255,255,255),cosmic=Color3.fromRGB(190,85,255),
        mythic=Color3.fromRGB(255,75,85),legendary=Color3.fromRGB(255,155,45),
        epic=Color3.fromRGB(255,110,200),rare=Color3.fromRGB(65,165,255),
        uncommon=Color3.fromRGB(105,220,120),common=Color3.fromRGB(220,225,235)
    }
    local function weightPresentation(entry)
        local isKg=type(entry.weight)=='number'
        local value=isKg and entry.weight or entry.scale
        local neutral=Color3.fromRGB(220,224,235)
        if type(value)~='number' or value~=value or value<0 or value==math.huge then return '—',neutral end
        local compact=value>=1000
        local number
        if value>=1e15 then number=string.format('%.2g',value)
        elseif value>=1e12 then number=string.format('%.2f',value/1e12):gsub('0+$',''):gsub('%.$','')..'T'
        elseif value>=1e9 then number=string.format('%.2f',value/1e9):gsub('0+$',''):gsub('%.$','')..'B'
        elseif value>=1e6 then number=string.format('%.2f',value/1e6):gsub('0+$',''):gsub('%.$','')..'M'
        elseif compact then number=string.format('%.2f',value/1000):gsub('0+$',''):gsub('%.$','')..'K'
        else number=string.format('%.2f',value) end
        local color=neutral
        if not isKg and not compact then
            if value<0.60 then color=Color3.fromRGB(245,85,85)
            elseif value<0.80 then color=Color3.fromRGB(255,210,75)
            elseif value>2.50 then color=Color3.fromRGB(100,240,140) end
        end
        return (isKg and number..' KG' or '×'..number),color
    end
    local function mutationNames(entry)
        if entry.isEvent or entry.source=='event' then return {} end
        local raw=tostring(entry.mutations or entry.mutationText or ''):gsub('%s*%[[^%]]*%]',''):match('^%s*(.-)%s*$')
        raw=raw:gsub('^[Mm]utation[sS]?%s*:%s*','')
        local lower=raw:lower()
        if entry.traitsKnown==false or lower:find('unknown',1,true) or lower:find('unverified',1,true) then return {'Unknown'} end
        if raw=='' or lower=='none' or lower=='normal' or lower=='none (explicit data)' then return {} end
        local result,seen={},{}
        for token in raw:gmatch('[^,;|+]+') do
            local name=token:match('^%s*(.-)%s*$')
            local key=name:lower()
            if key=='gold' or key=='golden' then name='Golden';key='golden'
            elseif key=='silver' then name='Silver'
            elseif key=='rainbow' then name='Rainbow' end
            if name~='' and not seen[key] then result[#result+1]=name;seen[key]=true end
        end
        local order={golden=1,silver=2,rainbow=3}
        table.sort(result,function(a,b)
            local left,right=order[a:lower()] or 4,order[b:lower()] or 4
            if left~=right then return left<right end
            return a:lower()<b:lower()
        end)
        return result
    end
    -- Glyph masks rendered from Minecraft.ttf by Craftron Gaming:
    -- https://www.dafont.com/minecraft.font
    local mutationSpriteData={
        studs_v05={width=512,height=512,data='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'},
        kindly_full={width=82,height=32,data='iVBORw0KGgoAAAANSUhEUgAAAFIAAAAgCAYAAACBxi9RAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAPTSURBVGhD7ZqNUeMwEEYpIA3QAA3QABVQAR3QQVqgBWqgCbqgmHDvW1ZCsn6d081ALm9GY0W7+iStZdmyc3Plys/n8/PzcDqdHklH0psSZVWwfZBeyN579QzKpSW7Qf7opgzKn91FPq+kOzcVYLslpZrvHB7cPM0qnSqIPX7JfkOZBvbqP5uorssYFCmI7yQFW502bY5ZMPld1aa8GkzKNeAIv+1Ec3x2lylW6RSg8SAhoUY8vW5tPfC/NTFQXS+TztEcvjm4T3HiAtg+TCiBsjs3qz+hTweS5bHH9nus0qmijpM06FuJcoyX2yzUeZIW2Xvpccwu7QRbCrBls2IL9myW67fqeD4uOeTtRHG09kes0imgYjhDCkBzloygrl0WHLUcqLM6KTVsLfJ8E+nILyB9T6G/GbK5a5dVOgVU1KDtUnKts/CO6RIRrdkobEZ6foQtA0IDDMltGSp31y6rdApcVFP8/ktqP9R/cS2dlBdSazYKC47nR8Q7qfpIWhHIJToFLnpWIKmndTWuZeT12GTBdJcM+bvrVCDxj4MirwDoJK0I5F/rFFBRa5oW/nBZGpS9uV2PL0/uY5BvPZ5YJ92tQDruOhtIm+lC2l5cBft0IL1KlVmdgpFwDerEAaa4uQn14qOFF3VR39z9YgMZB5ji5irUiZe14Lcekbqk7Yz6if0yAklxd42lznZXM2w3bWfkj/3/CCRke9mZdtN2Rv7Yf2Ugs12HoHg0I7MblDrspibqm7tfXiDxr77FwdQNpLtF1GE3NcHnsu7a+BQzcAs+1S1XwN0iFA2fW9NBKe/FVVLfHqt0Cqg4DKS7DnH3FnG7J/g9DCSkO5vfH0iovrzd4r4tMg3affLyJvikr+Z+fCCbO5HAjk42T4racTej5yuwZ+8kKQrvDqvgb7sz99WbLNv6krLXYtiW6BTI0RQ64FPdyWwZaWG3tVad8qIm+GQ3NYpmloIqaKV7/CU6BRhnAtkWSMCve8PZA1rZm2qKsncBe9E4V+oUYOtO9YC7D6Gh4dZvBBpn7eVHuMwynQw6PTWL5OdVuuiMeZWzQaP63YTymRtjkzCGVToFbh8xe+f+N5cOYNt+SNtL+F60RKdg8gxNf/eV71eVfdCP7DvNFlzOvlEIl1mmU8AAhh+98Jm6tAP4Dx+rUhREDtlDew38zlqDqZfN9FU6BTj03mxPPf5sUaMu0WXYuQTcd812tBWw4mpSmTlM0tKpgqMeQOO/H1R5zyBrUN/+HiItlzX4bQ+5ZIezcItrhm9NGZTZnxtI+jzSvYqwL9G5cuWncHPzB0AK0axMbE74AAAAAElFTkSuQmCC'},
        filter_divine={width=111,height=44,data='iVBORw0KGgoAAAANSUhEUgAAAG8AAAAsCAYAAABrCeaiAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAQDSURBVHhe7ZoNcdwwEIUD4AiEQAgcgSIIgjAog1AIhWAIibIomLTv2c/u6VZayTr5nHT2m/HE2j/Jeo4se+4hCIL/nc/Pzycc738Ezj9ok3t3ju7/24K5Os1TZsEEPipsN9DNof3vCi7gp67FRXfrG45nNE9Kr4L4l7mChX0rbDeO7n9XeAG6lk0gj0JW71yvPnyvCtuNo/vfFe/iWkD+i0ploV+hBvatsN04uv9d4QXoWrpBjTeVM8Adz7y9GCEe8QSEL3abe4CLGCIeQS13CQ0GM1I80bwTDW7EEw++D8U84nhmW64irDcVDvaHk615N1Asha3AfJ69ZRQ6gaYXf2YM+nlUO8ePqVAG+uYQC2sqpto/8eZBIYwxNzDafJaudVpQnXccv+cqM6yNg7vjttULwZvEI7A/KaTEOuE4b5285EIWYPc2Qm8KS2AthQwRD5zgd1cdb5wLCDtzbHOGD+KelVbGGzQHrDBDJW9dOtFsnbyqENfQp7AE1lLIEPHg+6VTl8t+r4GPX6Y2wTEpPU9l0EXx4Pben9Y8NFsnr3hx8Jn3MdrkNrCWwoaItxGzzNM2u7ooPja6xSP0KzThMg/N1slrEmOBNrkNrKWwu4uHOslKAROX3KalMsd1vQRv0PDdTTyCvOzyBLtZjmiTO4E1FDIB073/8ziG9QMAzjcvl9ewhsqleIOGr1e8dQLR3CLeq+wGhazIbGANhUzANEQ8+HmzTLtA/PVqMnZ9VuG8+LyEb/qogVP+d2ZvRgLf+1TsGnakGAN8d/3PQ9vb+l/ezd5uN3lGoH2zePCZyfPGAN/l9WdBTG41Ke5oFZKChC7x4B66YSFoezXXT288lzlH8o6E9gjxst9BeZ0KSYB9WnmYJ9PNTB1eUxl0UbxK3uZXhQX2KV8C7Ovdz3OZE5irkBWYbxZPIYZaDv54fW/FzFVNhKx4sA9/SV9omUQ1DcxVyArMId4CzNUBKXQCzU3i0Ta7stA3tJ7C7i4ecqtfZKq0iIe/3R+mYdo02UQ+A2vzUNOg9ASYDxOPqFkie/3NeAPopGvDcAnGVHym8VAzgTlKT4DrUPEQ435ag5+vCGYeYOejid9CXxjDtlz/gHGYeKhlXiZh7hHP201mYY7SE+A6WrybX9KFnStvAFtAnewaDlePeJu32MxRegJch4pHENf9eeyCfcRDjeLDF+7N4hH5m1GaAa6vIN6I973x4iHf/d0KQrrEQ93scy8HY5VmgPtw8QhibxVwnHjIa/rRLUJ7xWt+VjBWaQa4v4R4BGb3G2aFfvEQ1/Vzd8T2iuf9NCKBsUozwP1lxFuAmyLy1YvzWdo9L/PN3Wb2eR4EQRAEQRAEQRAEQRAEQfB9eHj4C9ICM72pnaD1AAAAAElFTkSuQmCC'},
        filter_cosmic={width=126,height=44,data='iVBORw0KGgoAAAANSUhEUgAAAH4AAAAsCAYAAACjZQx0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAATbSURBVHhe7ZsLcdwwEIYDIARKoARCoAiCIAzKoBRCIRhKIiwKJu336357zqeHJfvuEnf2m9HE2l2t1lo/JPnyEARBENybj4+P75S3v4bj35JZHfyPkOfHU7pzSP43m30eCoLyQnmjvDu2GWR/KLpSf1Ge3SxYgbF68RBmoPtps/tD/08EMD+GenHzYAUl10OWge6Xze4H/T6q41MI49hNsAJj/HXuePpU0rPH+Qh2FazAUH2Ndzz97U66sLugA8b782f16tT978LugiNA0p+dt93YZXAESPwf562KH0PPlMX7B5XeVU+UH+juPxsNtqGEUZoo4TbfBa40j5j2BLKLDZkuLum7Jzc007JTewjZqwrZO+WVkl2w1IvLKeS/rdf+xavFCep6Hz8lBxegUx/zHEnHFPXxaJMFyHWz1Cj2MYFe46j+ansraV+Fw7ofDBYndwn63UnHzfASUXFRqheAdJTueYls3TRBvZp4yndXi6BfjAn16hiiU2Ky5CMbTjxyjWN1/V+hnHwcVR/z6BaDtQV8aOa6+ippkAWOrLoUqnF5LtRrie+N9Yf9rF7Q2LynTs9APJR4fGwdxzzxCJsDSEe77nbaf7OrXeik7TJBvfmUKkGbrsT3QnttVXefH7aLsUTUnXjqwxf6GcXEtzrPBnwU2l9liahB5k96XOpvEg6iWFJQhvquxAvH1YVs3XUCUXfiFbvlWxhPvM02QfPVSeMISpT9NmOuocFLgRn5s+pu0Od8I1HtSryOT6LN3DfxnGTzAw967R3Mkx6OtRys7hyiS3cMh9WY1SdlnhDqGLFm/T9VLE6ofmpVJQ0YdtU99Qls9OrRxEsTztY5zDFQ7Uo8bdbGUed2ucTWOWvWr9VO/tSWQWpdodioE7sochnoBCoNXmvgNMFpvVfThKsH/FQTj25k1r54hLfiQ/dms+7Eu14Ef9vyQ9ubTO4UkF1koGt+ecKk9YqYZtLVdx463fVKqq761nKwdccvll/UqzHhJ9u0Qla8eJHPrxuqq4nHvjWO+zbLcFCdoJwHOgJNu67mEuirFyPxTO/55pPhHJ0fJbuA5csmGTaZwbZ1F7/YbAZZ8QmBfCjx+nuqFmmO4yq1ICfQD9/1NLtp4icUmwbT6iayc7OEfFm14NJuwuoS2fn0+Kb6uYnHwdW3bLG/6aO+BH51V2qC2Hofz33r2OIFyL9M4rG/3aNe4GR1PaqgKdmeNyrdoTqJxUcatalx6WMC1erkzqZNFIebLJBvmxwi8cL1IvjbPPlO4ODqn2XxeZPlnOBYH3LUXoN37kMXYfMJZtPDJJ4211/OnYPBVXbZ7G7txIYhvvPH9OZY7eIwidfxSbSZLL4FGHTPlFvYXUInavEu8DNv2Yqtfmk3r6M5PkTihdpZvoV24gVGu5NvVwl8tTZbusHP4nG1dSBoN09SOT5M4qk391tWWE+8wFDJv9rPq/F19c+yGkDruqHNq5snqB8m8YK21/ss28IdNScWJdx8AeLhiwn76g8xkA8lHvtsCSmZ1Qvk2yYLrC5xl8QL5BrHou8GY4mfoCN9eNAMUYkoDrjklNV/ocJUge/+6ZX0tpOfLCZk2q2TruoL+eESP4Fe46ic6ByzV7P6oehG25b0IAiCIAiCIAiCIAiCIAiCIAhuwMPDP7/xa7YQIwtaAAAAAElFTkSuQmCC'},
        filter_prefix={width=213,height=44,data='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'},
        filter_eternal={width=124,height=44,data='iVBORw0KGgoAAAANSUhEUgAAAHwAAAAsCAYAAACnkNxJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAQCSURBVHhe7ZqLcdwwDERdgBtwA27ADbgCV3AdpAO34BZcQ5pwFynmkl3e6ksSJCUmR2fwZjSSCCwACrJ+5wfHcRzHcb431+v1x+8TUK9Qzh2w+gfbT7kteMO/N0M1HLYLk06Lhp2O8PirFRHJY24JaqBeoSJg+yW3gIadjgzTcJhebx4LMjkdGabhTCaXGZmcjgzRcIw9ybxBZqcjXRueFFQA3btCbJDZ6chdGg7Xl5uiDcmTIPcblk8smwc/1oTlgs1HuUbAnpwTtXIJNWP/A8vXzbrUk9MTuUz1bW5b2P/E6kUuWeD3JP07Y2DZzJFwTLZDcyXUy22hWZAArt0ajmE2IjoAKeD3JtmG3Jw4H6wetY6Q3DwmIKufgP1DoZKU9CmguUi+waqVeeS2YAksJA9gt0vDUcubTNWwfslncnPC+BcX7UZIXjqIWf0a+GWbDltzwwnrUoiZQq3jNhy70WtcA68KEzg7p6P6BJu6JtgI2ZuB9klhAlatzCO3haOTkzyA3VMNxyYvk1WX8RTUKlTg7JyO6vfs65rA+JmGb64cVq3MI7cFS2AheQC7pxqOGpov5XsYQ+FOz+moPgViPSvsDMYON5woTMCqlXnktnB0cpJHWPHkEgFN9r4IW3hYwSavAh+30RjYPkMwYNUwwZxY+KScaoiph511hCdnrM2TnbFC0BUcUw4+oG7ycx8Ln/azrDWKkwS2MRsucwRiRQ8+nITMEXIpzol2uSax9LDNJ9YExp5ljoAtPugVMI9CpJhf/Qq1jtdw+GcPVisKWToIUcP2FPTRFYFgPHkiYvxLLk0wj0JEwFZ1+2JNcltoFhSw4sllA4YP3f8zhDO/MKdkw9a0zoG0aDDE21P46fjmscAx2rD5eBuJYS6Fau9fs6CAFU8uGzD8TxsekhY4oq/VwK/HA+r/2XDEMr9Y5cjVUDuf1jmQGg02z3xrmGEuhWzvX7OggBVPLhEy5yh+m96Tq6F2PkfmUKOBT/JbA8b5xjB/UMG2eRVgLrmaeWFra3gN6+SkEC/35cn8XAk7X4OixmOcDzZ8teH9kD+EhPsz1skaMH63hrM27aZIzS37NsJccjPzMobcFixBDevkBEPVl62pIKxP39eEeQ+f8pXI6YlcIkoarKxb17f+C0/+80OKdUHYPvxpdcWwDYe92+snc4WkwMoL299vOMGY+aVoYl0QtnsckGEbTuDT46QesuFVf+X7grB/tulDNxybYz+l17BOvgbjxealCsKw+c28wNANJ/Ab9z28hnXyPTBnvyiRZEECZmr54wafvrN62Zmj+IMC/eViktMTuUS0aDB0vy9tzrio+akl+a9djuM4juM4juM4juM4juM4TkceHv4APa4U8/FY6EsAAAAASUVORK5CYII='},
        filter_mythic={width=119,height=44,data='iVBORw0KGgoAAAANSUhEUgAAAHcAAAAsCAYAAABfcCe+AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAASiSURBVHhe7ZuNVeMwEIQpgAZogAZogAquguuADmiBFqiBJuiCYribkUfGykpryYkdO+h7zy/R/mglT+zIdnLX6XQ6HY/v7+9HbO//BN5/0CZ356hAy/tBUgsEflDYOqDAiwr9kemisF/1/yLTLon7IQd8HwprBrl/1Y1h9X0ynRTeX1Rg9qeuf7O4Xr+vCluH0+JoX0Rg9JN8YllHrk3hOLDxOy5sMhs4Pg3V4OXNgdx9HLkR2M4SGPlv6mpk9YkUQN0vDSEgsyG3HyLwLRYX6df/zj0F9kUCI88IS1hHIZuBss9D9R/kMpT2A4FvsbgE+ddZLaOIN6kmgRGfFZawjsI2AzU/VH5ELsPMfjhL3KvhTYrAXyUw4orCEtZR6Cag3oNKJ8ht8PYDfLcpLkGMKzD8rrCEdRS+Caj3qtIJchu8/QDf7YpLEJcVGPZZYQnrKMWtqZAEmJ8Gb5anipgioQDwxgRfEBevf/he5gDa/C4NY8hBXwjMU8wj8N+r5ju2zyHlB44FGz/E+X7grBKXIDYRGO0qYQnrKO2I4n5yUzML/G/qKgGuZnFhp6jVugjbV2sniA8CczIyVcE6oSDwaiokAearilsL94m6G4G5SVz0wZV1cvlWyfniEuSYVegcrKOSNyuueFaXAbSrxUW7eE1cwWXEXcJvERf9fKnLAEzV4iK3+aCZ0MU9JRQAl9wP6Gu8QYFmlbh8P5gWc7viTmntn8ztB/nvGYtXV4jpXNGsGjtyxjtYOdgntuR2JcxPsHE1/YrN3vFi0pBugY9L7dpLHXOZMIV1VPJw4nJeChuB7VFuwzQezaqxq52FtRTWRs2k8OoKDH9cQf8acQns2csj2hVSNXbEex+U5Y8FkVw1KRaROQH28dqX8TIbWEdhbk2FJMC8V3Fn6+Dt7Nj5OjSzmPlV0zIptMeH74RtuQKMl8vAOgqr2ilTYO7iLqF1UrDFn80kwhLGh8QMrKOwuZrmGSds2bOGOLy46Oe6p+UpsGcfMjNeqQbWURjjkjPAlGkcgYm34rw7NocXl6idBXXWW1DVwnilGlhHYYwrflIJ/HGB9oDNvUQATeKC5A5SxMuBb3Vx5+bJWtgueymksCoYr1QD6ygsgPaS+6c5jLiwmV9glIhz5PhkMsSYU7wchbQcuV5cDWY/XFPcYt1Gckdu9kF9jjhHbzwx5hQvRyHV4hLWkX0J+xEXpnNukk+xkwKoN3c6D8Q5cnwyGWLMKV6OQprERXu7BwelSZVgvFINrKOwEdiKC6spiPOepZbErTp6OWbFX11cgj63eeRXmlQJxivVwDoKS4DdFRh+3h1r2kER5LoLN8IxK3YX4hLY139YX5pUCcYr1cA6CjPAzVVfchpVO6xs8bpIXAI/d1T4YfoQnkI74/C6G3Ej8J/3M5sjwAkO08ly3Il1/DMCCI/hOgdk5qgdT3+dHQHR3rTxj1L8XkqOQNrop4Al4H9XeGdPQBjvVFtL/77dI+eKy3x11dkbFxB33b8/dpazVFzkfWFb9gissw1LxEUOF1j90mfvUCRszxCMzyl5pyV3B4b/0eHdGa6ou6idTudmubv7DwiIO8uNEMiQAAAAAElFTkSuQmCC'},
        filter_secret={width=113,height=44,data='iVBORw0KGgoAAAANSUhEUgAAAHEAAAAsCAYAAABSblf5AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAQSSURBVHhe7ZrrVa0wEEYtwAZswAZswAqswA7swBZswRpswi5uMXr3FwYuHPKAZI7eH7PXYkGSL0MmA+Rxzk0QBEEQBG2+vr7uOV44Pjj+fGewMh3SPZF1a9WD34RgKHgfU5hO82Bmgt/C3qYRIogOEIdnvUjzYdltEN9ZIEaIIDpALDbDl2W3oeKb1RkhgjgIffg4deU/rKiN6UeJIA6iz6f15YIV1aHivelHiSAOUBrSrLgOuodJngfjn5z0mm+WEBb8B84aiN+UtqKgA/rvVf19iRXXQdcK4p1Jh8DOE8c7x2bgJq1Z2DOXp9aZ0q9s6kHbYHbVMcsXgvTLVLpFWpOk/iCth3KxaUVZ0HX5RX6130tY9S3cqDozVblJu8CEOiW7YXAJuierVgSZgpcNRoUUyFI98jUWyW52jZxufAHZQ36R7RdEYeVZaMA7p67dGDV+snIc6rxY9R2UaTPiUMdd0Aripw5L7kg3X4F22C+yfINYcm4NGi1DHq1KE2lTxT529yHvdirqohrEFqkBBkkXv7h2fxP1KSk+iZdYQIuzUcpkr+eNSaiumVogr3c7ULgEkUs3v0j6BlFwg9OfKvQavHezUvJGt/BkexlHSHY5vMIliJ5+cekfRIFGT9rp3RvqbAJJuvhWU/YsDZfVe1H2noyBri07C+X6JWUzASNbEw/NHF85Uvukm2qUQaPxUfVyD6erXzPkFdtlkvNg9I5Dzh9+M1XHqsuRLGjeTLJAXvEzaZKiPUH9w+tTtNUgqtykWUy2o9evmVq7TDIGdtK6aTJZBk16wjh77QAlB2r2KHuV5ijoi501t7+Et19rau0yiQ/Y02ei+lkDzSBHx681slWzV5xc5WgEsfpGI3H1y8wmfiyIAputaX6r08/yY0E0SREk/28QMaDx79C4gs2hIHKf3djRQm2z6jsoc/mckt/88RWZq19rSu0SJqmDbmmcGsOh/T6Ng7nZXmutlhazdl3i1NsjrF4W2jQ8sZFfJqli8hKn/ZoptUuYpA46988EjapuHFCe3SwgP/vLCOerLjHIPxREdK5+zZAuBhHau2SI3IJIY1JHch5eFBupQ3Sekt3MD9doEF39miF9eCsv21byXYKI8U8zmSDdvT21YnFWjbe8HlyCKLz9Etg8/B+nbFvJ93oTN689N/NYVy3Ocn21DfBsxxTw9msGu63lWyLbVvKHg6jOMXMbHBy+fGKv9VPU4SAKb78ENg+9jdm2qjLHoafgEuqpQ6sDL+Vd+7HGzlnyZK82EcjhGkRBNVe/BPaaD0e1rZSrUfNsTr9OZGdiVqa/PbRnTSvQz/Y1O8uOb2Y7LXM4qksH5LM9179nnIXq1/BLuqItkwZBEARBEARBEARBEARBEAQ7bm7+AieAv2/JJn6AAAAAAElFTkSuQmCC'},
        filter_any={width=73,height=44,data='iVBORw0KGgoAAAANSUhEUgAAAEkAAAAsCAYAAAApSpU1AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAMISURBVGhD7ZoNceMwEIUDIARK4AiEQBAcgmMQBkehFIqhJMoiYNJ7b/PsiSxpLfnvppa/GY9r7Y+9L7aqdXI6ODg4+Gk8Ho+P7woU1haqvRiI+kuhbcCCVXsxiPmj8DZgwaq9GD6eCm8DFqzaq1B4G6jmaiDum1LsGxaqmqtB7G+l2TcsVDVXg9h3pdk3LFQ1V4PYu9JEwHaTW4Rc7APC9qlhA8ecHy9yiSjJ+wqGL09rkux5AnDSuwKSwP6lP5PAnpyXvGLAGfZAnCGwJ+9SL69cAjA8TyQWKGePq/ZJkCM5L3nFwOYK3wG/SCgvr1wCMDxPJDi5AhD64cKydxtsfy3ZAK+YSq5KaWwuEguUcxLYbcHIvYYiYPuyZAO8YmpAnmDe8/LKJQDDs0Uam2+s9eBeQznOlvAFr5hakKvvE728cgnA8HSR4HB++rlYEl6kjnMEjwQZEwl2/lc1cbH3CqHvzZKCrUUqmo86NJQEFx7NS14xsEV9H8ayHwRsn3LbViTvZOT1wgiOvXkp8CVeftiSr1mYRy4BGO/nPS+vXAIwPEskd51Si9L21BZDSmI2FUlOSxKc8MeLROPTZzl48Upv/A+RYItW/xjzljl5kbwTTQU5h3PYWiJlG3LGy83AENsfr+1yRVp0PupQeqOk4CElMfBxlyOwW5uE/Ru2sZeJ7uO2CixAp1hNJAI/tymvIC0SC5HD4iB3/+XAyiJl/SrJiuS2GLAne7EO2uUaAVu/SPQKkUtEaQwOS7qFErIiuc8p7O7bRtjdplhuq4pE4Fv0RhV+Xn+aFknGLDy5XJPAZez9ks1LNQV31MbwWmVOAjv7w7p1EguQMQt83G9A4OLe6rxw+mG/ukgEpgvigqdDx9Z0Yz99xd0K/NAkSIpDJAKRvDVh9B6sOUbuouwjvAtQ/Ls2Lmc45wR3BMdopxA5YN/3bxlQ4BJt1b7no7kiMV6p9ssCIu3/hx5TRULcHVsbv9CbIhJi+m9nmoDFYrui8BsFwxb1ZxzD9oGN/wGP9dDBJpxO/wBE6iojlRTS+wAAAABJRU5ErkJggg=='},
        varesco_b08={width=157,height=32,data='iVBORw0KGgoAAAANSUhEUgAAAJ0AAAAgCAYAAAAIcnp9AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAUxSURBVHhe7ZyNcds4FIRdgBtIA24gDaSCVOAOroO0kBZcQ5pwFynGd7vU4gnEHx9AUPQl/GY0JPEWuwCM6IfS5Oni4uLi7+Hj4+Off51A+47HGx6vuHyWRZEB3594fMdl05f0eJdg/9iHuYvxZDQfyyMhswRqvyRz61JQ/npTlZHslLkbIXwE9P2JQ3GT7PRl3+rm2+NN2D/1wfnUxaefrFcLH2emoPbwTUdw/pC5G3H4Dr7Kztjri/589nuR3YoJ3tmmI7iesvjw4SuBEfJImhmD2imbjuD68LkbafgOVhtvli98vsjS2OsdFqLkg7Zdi4/+fPZfEfJIKTOA2mmbjqDt0LkbpfAd2EviLF/4vMvS2OsdFqLmg/ahxUe/bNFJyCO1TILaqZuOoP2wuRu18BEYLNvZvquF2OvN/ls+aeYW0BcXnYQ8spF5+qYjqB0yd6MVPoJsp/rC67dsF/Z6h4XY8kHdtfjQVRedhDzSykTtU2w6gvr0uRutcNTiRXhpaSOW93advs2BE2jsvZ3Xe4uWTwCa5uKj7hn7/27TEWimzt1ohaOWTQ5tLyoXQf1Vul5f+5hd4Zuk3d41Wj4xHJu6rED75qIT5qiLe+xeXQrK0zYdgW7a3I1WOGrFyalcJIQc5UtGvEu0fFKgXS0+rl2LTpijbu6xe3UpKE/ddATaKXM3WuGoZZND2yHPdETlIvSTrGvBYtTd6PWBfll8HN2LTrxjR+1TbjoC/e65G61w1OJFOOQ9XQBtU15eW6i7MeLDsevUDXMU6V4Xry4F5UM2HWGuTt0wR5F3RsJbyLZncad+kGih7saoTy/MUWTPurh0KSgftulGYI4i78wMh9dR9+lWN4hHvdXdmDnGFsxRZDMTtWvTDTD9GwlhL61k1FvdjTMWvpWJ2rXpOjnqu9c3WRqj3uputHxQ+4WH600zdN+p12UGcxS5mSmZW5eC8u5NR388ps/dYKPqe5j+KxMCj3ccsp84jXqru9HyQW35w+LYXHzUw6e6P2rTSTN17gYbVe9Gg5r+ezqC/j9kldHyRq36B0nx+nAsal6Bdrt/Rb2aM5gjWU/m0BxRnrbpCM6nzd1go+qbQHvIL4dT0Lf4O7pAyxu16ZuO4Hp1S4fXKi1Qr1IGcyRzZ27oVt9Fx6C2+j1bimTucRBcT5m7wUbVM2gmWTcbvr9Z51FNK1iTTZEN70M2HUHbsvg8qsmgfulYgDmSuTNbOoL6chM+Bs3PaC+uKWFN0lPmbrBR9QyaSdaNxxfH6r9K9scjvjfH+3nLNWuSZaDmHvOITxhDCvXqmsEcydyZuGy+TBLo7RUH51wfvgeugrp9KMP5w+dujIR78Pji2PxKLYWeW94ePD6odc2denXNCHmkJ1PN04B//D7s4XM3ZobHeH1x3vzXGUNP9al6e/D4oHb6pmtpB3HdR03HsQX16prBHMnuzAyP8frifOs7V4Oe6rPrj+HxQe30TYem51tlP/BevQfsGccW1KtrBnMkuzMzPKbHF9euZzt6Sl/19uDxQe30TUfQ/O1WHQe+XTfYS+NoQb26ZjBHsjszw2N6fHHtem9HT+mr3h48Pqh9ik1H0O5+NUhB3zccum6w18ZRg3p1zWCOZHdmhsf0+qJtc+PRU9qqtwePD2qfZtMR1PjptJpRAvrstkpgdBwlWuNijmR3ZobHjPiixPtMr6zflDd4jQfvjIfbA1VvD+y/5cNMarxQr64ZIY/szYSGm+8HtepmoM3+ew7Jq0Dz8LlfXFxc/Ok8Pf0HcLxyU2WIgC4AAAAASUVORK5CYII='},
        varesco_b12={width=169,height=32,data='iVBORw0KGgoAAAANSUhEUgAAAKkAAAAgCAYAAABpalg/AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAT/SURBVHhe7ZwNceMwEIULoARKoARKoAgOQRkcg6NQCsVwJI5FwfTue87Kozj6WclKqtz4m/FEXj09b6RNnDpOHw4ODg4ObsXX19fPvxno+22yKmif2N7YPtj+mMWKYtYnzZMNq4LWlZ90bDruo4VctPhb+IKtju1qedRA/oj+B9u7xp0czlHcNh3zxYbOiyWaRE/EZFmQvUh3GuHHxlQnyJtf0PHYVCCt/ilSOh6vkkcOZFqHj9MIPx7vb6d3cujWK7Z5Urbg8YuH7GJ684t1tN0F0uO/JaejPTyPLXRrHd5PynZK3tPQMznEn9m0AEMwr+RievPb6kqeMb3+MSUd+0PziCG+ex1y3lPROjmE9cr9PCnGYZN9sZje/FK6nGfMHv9ATUdsWB4Bwo+n3n2kvKejdXIUs+7h4P1hh1nx5pfTES8WyF5/4dERH5JHwPx2k/KejpbJYf+HdV2TVzvcgje/ii5bIIP8b5aHYP/Nunaz9Z6SxsmpnuY1hk2XQNbLTGpbrPoujObThi2wv7s4BP3JAhnh79UJ+nflISxchDGfbCrmiysoxJ8U51Fr8mbheSFJ1+Sw+3qK5tGTNnkWTYrJS6wT682vpAuguSiQEf5eXQDNnjyqZzN5mfz/oGFyipc56He/IkvHFPT/MmlLftXiCKB9tmFD/L26LWh78ihe9qN//nfGVhomJ3uqp++Pydx4/WgPLw6BfimQEf5eXQr0TXlYKEms+6/wTA7N4uUOdNXT/BbGFE/7JrtacQjG6Drjbn+vLgdjXHnQbFoHby7Bf1qck/NyimRp/v5XY05D03Ds5Q8vT36ipCvBuOzp0+t/qzxo1uZs/fggvLkE/2kpPRHv5CxGjTDMVfie/ERJ14vX/1Z50GxaB28ucf5TUnoivZPjgWFHkToJ/jSPIt3inRyY+nRPn24T1GWfJhr8b5IHzaZ1KOUSE/ynpfREosm56z+cpONB9xw0FUiLv8munoeFkqArXn7K5Rb7T0kucREnT/tuL0EFHc2mAmn1Fx4dzT15lObt7Nu6LfQnc4v9p4QEdT9nkjh52nd7MT/WsesukB5/r47d3jxq6/Bu0gvoS+YW+08JCZZemfGk3u3XorFOEHIVSI+/VycINefBrmcd9DOdi5/oEJuzSMlh+VkB29nNBnoSbE2vSvazBR1AM90NJrEuQLhaID3+Xl2AcFMegv3qOgh0Wt9XHovfam39bw451P4izKInZTYL7N/rrXrJRaCrWCA9/l5dDF3uPASh6rtpC7E/u8plffOivdxNZd0LhIdoVujvLlK4uLTEge7qpmcR67bQnS2QHn+vbgvdrjwCxIpnwRZif7UtvGV98xilWSHYXaRmcQZhTabrdNMCnlqgq9/vmQJJskB6/L26FEiqeQQIZ4u6leDPo+4zTaJjjdScQbyrSDHL3pNI3/Q/xIuJdTmQXSx6j79XlwNZMY8YuqQd8YvdxZ9msVZGas4g1lykNknJogmof9AEDf9J85ZYVwLpWYH0+Ht1JZBm80hBv+eKSZbgz+P3vJMSfLZ+F+j1WaJYoDFop/rnECliXQ3ka4H0+Ht1NZAn88hhev33lOaPYrG/2hbecr3PpIIOPQFdAkr+6xVi+k55uVxhQ5ph/Lf/mx0LXxDrPDBkKZAef6/OA0Mu8vCAfrk/lS25FkKe1i/deosfXTrmbf+6Pzg4ODjo4uHhHx0JHOY9OmuWAAAAAElFTkSuQmCC'},
        varesco_b13={width=288,height=32,data='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'},
        varesco_b05={width=346,height=33,data='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'},
        varesco_b07={width=295,height=42,data='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'},
        varesco_b04={width=335,height=32,data='iVBORw0KGgoAAAANSUhEUgAAAU8AAAAgCAYAAACSGPrJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAsYSURBVHhe7Z2Nldw4DoQdgBNwApuAE3AEG4Ez2AycglNwDJfEZuFgfFdFlXSiSICgSPXMs/m9168logCCEoXWT/fMh8VisVgsFovF4rX8+vXrn/8CvP+tpqkwruL/o6ajzxqw/UeypMPrXzR/VFOIaPwe5B6CfSj3v+TeDX0VLgT0X+VqImmI3jHIzeIzNYyp9SGYl+KZ+5nsOotR/9mgy4/o82+8vuNV3VZo/5c2aYbm2GIQ7gDtF+6YqQWU8RQ6m4jnPq/AlhVPtXUV0Gj8HuTeDfvDWyoePcDv6xYhBvQ/5GoiaTeRMWxKk0eKJxY/bi0u1XmDGJ9krwL7T0lfAsekrrvgNlWIxau57jSsTymgiJMd/OxHJneiwFYUT4LlcAGNxu9B7rdhTgoVAvofcg0jVxPJbuONQRKLR4on4bKaq1g5o/27JFVgf+RK7Aq64tkm5/Yt4LuK5yDYjNwHPJvfX7F9D2Ex+cLOBvAvJib7kdmd8LBViyfBeqiARuP3IPch0Pc3hWsily4Q372Ek2wIawwyWzxWPLHKif9zs5hkcwb6d3PWib7cIt4C/qt4DoJteFwhE6ybJwkZFMongwEl6QJ+1clwTsjqk8BmFk+CtmYBjcbvQe4z+KKQJsix637nDvzc+56SzaAYg9otHiueBOvZ5L8C+3dJE1yXqQrjSfoo6Mct4hEQYxXPQbANszN/rI8VTwJb1ySC3pyU54QafbrFk6DdLaDR+D3IfRj03zyrgabrfucO/LIicUWyYWpjkMni0eJJmJPMVWD/JN17Ous052kUxFjFcwBsws/blvw/3C8y+7R2IOyhAgpd69N8WvEksJkFNBq/B7lPATm42xT2W5dy8HMPfMmmcB2Dmi1eUTxDZ594b91LTrm+gkAuTRBjFc8BOC+0KQ/QNqd4EmiGD/ZzQl6fsIWKJ4G9WkCj8XuQu0U64PC+f9WkdRbkniG2/D3gm86wakhiMTQGNVuYBYm2TVJHshCBnFsFtjk3IMvyjfhY0FdhqsBefBUJzfyGAXP4Inv4PvoiR9uygNtVEh8K5eMCXbWAoj10lnROyOsTtnDxJNAUBTQavwe5W2TFAevuE1TaJC2Abeg+GPzNDzpJLIbGoGaLlxRPyL9sXrcx89yhZpNuYDs8Ujxhcz9goyDOJ7y+XfvC+k/2gcXmmK/A769aTII2fg/1B178AD4+yGWukfrHO+fbV7yOmFg2ixhj49U9rqs+AnzqedAgTRNoswNTSYY4J+D1CVtX8dyB9viEjsbvQe4WxY5q5S5ZAfzcsyMCjXmGBZt50EliMTQGNVmYByhtm6SOZGGQc/fBQeinEC6Qziye5vFDm2S3QAgWo29bNB+OAW/uQ1gCzWdpQ1ArV29+MGZ1zqO9KFpoHhqX2rqo5ZGgQZoQ0KcCivdw4STnBLw+YbtVPAn0qYBG4/cgd4uZxdPdrrDzU9076Mz7npJY/BbFEy5uPAczxzPUbfINbKOR4tl6MNj8ZkYN+LlXDTU4b/Ayb/nAFipYZ+DTLJ7QeHM5K1poGh4Xlt+ueJLRBLw+GVuyu7nxkiIUvwe5W2QHHtbdnUybpAWeH4Gdlzats9PqWYRsFkNjULPFy4onQW5d8xP65q+zngBdN38hxe2MF/e5Wdiu0EfuXdBPITLQ3n0cEvg1i6cH+5V7Ysa4mJOaw1zzOKBBmkc5J+D1ycFJNrLTzKeY5/g9yN0iFQe8s+DcfmAEU+Rg4odD63ug1TMW2SyGxqBmi5cWT7h1nX1iLOHCNBtua6XRBNpUSLFoXmLLfhvmo1AJNN09k2esacVz1riYk5rCnPPIoEGaRzkn4PXJwUn2SG7n+D3IfRZWcWs+8JDUzQdjvPMroF6yMajN4qXFk3A/K4QLdFMezIzA/aV0wsCnekCj3f3Qa0F/hUpgvbvY7NBXYW7NvfMYZ43rznjOeWTQIM2jnBPw+uTgJHskt3P8HuQ+DPr3Ltndg+iybbyz62ofMg9Tiy+TxVsUz9CvtKB7s7POM0iFXz3qKhDQX8/+zQ9f7rN9rFh1tzl0+7MDdxvCzkKUfYiyD7TxIRC/RnUc88mhAfS8/8ncsjNrrE8d146aC855u1AonwLY0p++0qoLdLzUM6s6+1GXzT4la+m40brvgZzj9yD3YdB/tgPPtMYD+3kbti5jiks7tQ9TG4NMFi8vngR5th6+vflZ5xXkxOMo/OV5aI+rDCx7x0v2IYEmc7tDm37m24jXte3kVgWxeCx7x8XUce2ouYD9SeLTSCwVGry3JmHzfgL7oYZwWc0FjCFZU4e3O0/f3qx4ou/sftIVyTyOIoRYrTOromCpfQhrDDJbvEnxhHvrTORdnHXWQHqc23xQ1JzfnAv0wfvwL5YI4qRjtRHPvO9aQz5V9vwtZo9rR80FV50JhfIpgO1cyKqXlGg/Dibq1VzAfiTr6bOpw2JXAT3H70Hut0Cf/LqEO0Egcw/0XtBfMQFkukVrDJJZvMviKdm7B6m698KxX9LZJ97N468HxvHi7fYe5FqAWM1vOswe146aC6CbWzwJ1rMng1yXKUG9TAXsR7Jwn1EdVsMF9OzXg9y7QX+hr8F4Y71DbZwydRMZg6QWq3gOgn1g3g/f9zXf1TREK95u70GuBYjVLFSzx7Wj5oJITgkK5VNw7YygLRVQvqvpgPrkWIH9SBbuM6ojaAoV0KtfFLlXQUz+SwTv1kbzEod5STsNhT5Qc5XRMUhjsYpnBaTA/EKXv9g3Q8UTtu5bFPB5xWW7OTd2Zo9rRyEKEPOZ4kmshKmXa8E5oWifUd0OmpsFtOYXQe4WaQJouUA5HU8lsZz+uINWE9Q9QE8fQ2OgxiHL4wxtm6SOZLeA+7sunpyLzIPbFi/OdV6eZ9sK7fwNt/twkP7SescLC2FXwWvEm/XAyJwbO7PHtbNFKGF/kvg0EusqNNTLteCcULTPqO4MTG4BtfxayN0iTQDE7rqxnQIDLLoH+V24/dRFQs0Wo2PwWMWzAueiUhlin9NYbN0b5X3r7A92EJjSByFe2V9qwvsrvqrULJ7QTB3XDn1rQMdxtQsyg24uJQwiWQh1WoX9SBbuM6q7ArNZQD0/D7lbpAmAd3cnX0mBgTfOERA3u1epZouhMWjVYhXPCpyLSmUIxDnOArE89GVywrwUbijHcxw11WgWTzJ7XATr7lXqhTJPBPjtiieBpFpAW34Wcrc4Nizih3eyXOjTdbbXg7pIqMliaAxatVjFswLnolIZ5Tj7Q8zwzz0tmJfCNbehxyWORbR4Th0XwXroO+zizymeBLKigEb8asjd4tiwWA6fucmlFZtkl0ZnaNskdTDe4+tFarJ4cgy/TfGEWxbz7nwi9FWY23B+K9wB2nqKQsF1TFg3j0OPcxw11QgVT/LAuEK/QhN/VvEkkGYFNOp3Re4W2YZFH6GdLG1zB0JjPlGE2f1jIvA9flWhJovbYyBatVjFswJ9FeYW8M/+3NqZ6P6rURsT2u78/v6Io6Ya4eJJ3nBcf17xJJAfBbTH7wx9HYoNi36aO1m61pPU5j8k28dWA7bjvqeaLG6PgWjVYhXPCvDlL4hu3cvTvnEfasDe/Xt5Yo0Jpkf+GLIkYeAzdVxojxTkP7N4ErikAtrrt7P1alKdAGxHf/z+5LGjuYwX73GmS3Etm9A/BXOAxvsO4FF81WRxewxks5is4umAGOlv0HKbMp5CZ6Cdc5f2rr/tSaDf4/NvVRRFB23puKAGq7xl4xZl6Kb/G447IP60ccFWzPMLt/NcLBaLxWKxWCzu8OHD/wB9ELfcvcDThQAAAABJRU5ErkJggg=='},
        varesco_b03={width=347,height=34,data='iVBORw0KGgoAAAANSUhEUgAAAVsAAAAiCAYAAADxlXpQAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAukSURBVHhe7Z2NsZ04EoUdgBNwApOAE3AEE4Ez2AycglNwDJvEZjHBePYcOFAIdbdagvvjV/qqqHtR/0lCNEJw3/s0mUwmk8lkMplMJpPJ5E/n9+/f/8H2z7+C+xJNJpPJ5A6YWJVjC1D+Qyr3swXF598quhX6lf/9qrHFtIDsv1Lbrjz/Q/FnFaXI+u9B5ikYQ3X/S+bd0FbuUkD/u0xdpJqitw0y8/hKHfrU/iVYL/lzjzPZ9Dyu2j8DVOMb6vEDm9l3LMf2i3XF9kVmkwbqPhOp3A8PkmLwwN2acOlProuBe4x5BrIi2aqsK+Fm/fcg824YDx9LsukBdt9XDzmg/0umLlLtJtOGVdPlIckWXz+vJSHmuIGPL5KbQP6PVJ8Own9mG1mHtTY5tn6ZtFGXeXRN7tLwACnAAvZvSbjwUySL40A4xzwCWZVsCb6nE27Wfw8yH4Z1kqsU0P8l0zQydZHaMFEbpOLxkGRL+F3FJl6dUf5TKiaQP+ROrwVCf0XsriS74bV1UqMuM5HK/fAAKcbO1YEG+2ogHweCFXMDMjPZEuynEm7Wfw8yvwRip9eDZNIF/Ie3/FK7hNcGiT0elmyxy1lgKzkVYwb6bzmrRdz9TnCEY79MYthX6rYClD9+zfYMD7xUuoCdOWNgHKm4MQlkbrIlKGsm3Kz/HmR+B9/k0gV17Fqv3YBduG4rtTuo2qByj4clW4L9MElB/lOqC9yXyIT+pPo0Wm3IAB8z2XbA/sL2vLcRGECxKiDrGnTQdwfxsSGNmGGyJSgPE27Wfw8yvwziN2dN0Olar92AXZFUzkjtMlYbJPJ4aLIlrJPEJpAvD4/4qSIT+lkcPhGE/bpGv4bVL5M3ggdIx8oE8lTChV5rtnBbsiWQuQk3678Hmd8C6hD2KeRhX3rALkwUUruFcxtU7PGMZJua3eKztRa+1PWZoE5Da7RnrH6ZvBE8QDpWLtC5nByOAyGKCVkq2RLIzYSb9d+DzD2WExSfXD/8G1trlhXOQFv2EbB1X/+RiselNqjYw01glK0qNlJLkahzKyE3xwbUivpmbCJaddqA3g98VP2Ici458aEa74aaS1STF4KD1Ey2hINCJgUoT83CGEcmYUzI0smWQKdKuFn/PcjcozgJsM+ExXqZUCbVCsjC29wWsHcvjFLxuNQGFXs8JdlC/dtqNYxbzw3qrKor6IerydbtYyJ5+IwiC/wwKZvv7DIONp7L6YQNXY6R79j4nm91oUPZ8q42vlb9umqYLLqw4wV/7xt+ly9rcvUFW5GHsM87GPd4Qm7eZbFcKiaQ/4Ut6kP2BeteT3pQ2ExoG3QiswXsp293GUdmYUzIupLtBnT3J/FZ/z3I3KM6qK26S60Cds2ZDnTcGRxk7qxZKh6X2qAiD3fQU7aq2EgtDeo8tFRBO7kIgeptyRa2rfXjWxItfHS9TkZdbK272d7nCsUYUJkF6+rmFciKPsF++DDZawfKu5ItRKxXemyZflCYTmgE+kvl8ZlOtIRxloAgignZXslIzwL6S8LN+u9B5h53JtuwXyHnlTMajO66rVQ8PkSyhUnoL8Ct4xHqreor6KMrybZ1YU3VKQIxuPwwBGw5zqyZZNd5KYq2qKwCvsOZPqEOfeAzexdYzdZhm062KOvuQ8vPUMd5FY1gHIUMYx4rOVg3TvNT/nuQucd5IF1ZRggHG+S8bWudpOZsSDKPS21QsYebNChbVWyk1gXq1jU+od/89d0jQFz3JIbs8lsRkf8s577B/ugyVyrZZkE9eKuemvBBr+pLlKWSLfZHLiyVn4VRZ70wjkKGMY+VHK0b7Nwnzkf/PcjcYxlI+GSCGn5ABlHz56ew5cWk9R6uue4mmcelNqjY46nJFmZds1u05SV/UwBx3YsCZJcuAHAxOsOvQF3297fxfTSB351s08siBPrnJdBmssXucB8e/eyg8MMl24ij/x5kfhdeMmw+4JFqWB+0ceRXXr0UbVCZx1OTLeFxlosQ6IVvhjySqI6Q7efLCLBv3o53stwtZfvV4NZk2wvqfZ6hN5PthbYWfnZQOJNtAplfBvGjJYRw1nDqm2j2bsaQ+DKWf4k8XpFsU7/Cg97L/lIWYj8k2bbaDjnX/Y8PlPk0PzzXIN+e1UR1LmaPKOJDJd4l8el98VPy1cIGustaMT5Zr8xFYxlf0A0f2i2BBXTDZIvPVh/SvphwoIxLLGwzf5lWHz8WLtYGdIgtuy7CTk0NHn5XcQV9SK2lx9csuq/eR/89yPwyiO/+/YJWeyA/9mHraXC1bqvyy1htkMjj6cmWoJ7h2KVcqi8B8aPzZXgZAbbReeP+9h8y91nAVh98mn2KcncSYSGzCvgp1lex33pj47w84B5zyI4XmFayjfpwbNw0nG6BW4M2c9W7O9kyVvgQx+LovweZXwKxi4FxRmoRe9KCr9bMrUpwKr+E1waJPV6SbGEe+kZbXjarJYj/kAdksI1+JWc+PN2ArXk+sZxyfHX7lHXGxlksk7Z7zMlqUUN7qewwtsQWRXuwHy3FHc+fVrId7kMXOM0mPnNgoHw/+aiv4grGkVpPzKYevnYl3KP/HmQ+BGJyELozWgK1MDH0gnjVbYxEQ7TaIDWPt0y2UnsZ6M+HvPoFv2EiiYCOewGQSqbeO9D9ia26qElcAd3qjynRh8QVUtlhLIksepLtcB+6wDiV+Aj2i07mvkQL1JeognGklo6Z1cNuOuEe7XqQeTeIl7odjNo6gtVOibrJtEGqHjPZGqBfW7fIHNPdsyge+9VDiTUmzkCnmWwJ646NiTT7VkD2gWo1VhDDPDdQbrZHYos/J9kSlC0Jl58q2qH+YmjAOFJLx8zqERSlEu7ZLovMTeCTgy5aammeMKyXdG9DrndUbHK1DdLxmMnWAX0ejlnJuxIubB62jOABFT4Y4jvgUfLdY2vf4l2S7euWEY6g3Fzror5MKxhHaumYWb0NFDcTrmWXQeYey0HU9wrVab+y4zvfpy0GFfUeQE+MS22gTkBRjyOUrSo2UhsC5n9Csk3dkkOPM86qH1HOtfsl0eFzOT74Hp03lx6QtYBq9K74cfx4WG18RbKN+vBxD8iyUF+mFYwjtXTMrN4RiMKE69m1kLnHchDhO7oaViyOAb6GSWEU9p9CLKjY42obIqoTaIOyVcVGakPA/O2TLUGfd72g77Edb3w+8tWv7ReaTPDFGr5k0dsA+3hUkcW7JNvnv/oltRTUl2nFMXg2ZlbvDMRuwo3sImTusRxEfHb91anFMYjaeQX4LWYjKva41AbtesxkG4Cq3HKx5TiSy/BcHGS5dcbncF1Rp/3hl4os3iLZEk8ng1k3FH64ZEugYibclp2HzD2OBzE9S5EJbbpmkz0oxIKKPC61QbseM9k2QJ+nn/B7wMdx5nhLAifwe0ySV5LtPhNWkcXbJFvsXmlrXTevIcRrjIfXAMI4UkvHzOp5QK1KuBk7C5l77AcR39MzQ5m0fJPiduUIZauKDdqbGeDkkW34MMkWZoXP0fFkAV+XEi7s93OMYN99syALfJzvjoYSEPwU7w2r2OJtki3xYrcw6xY5Mw0CqC/TCsaRWjpmVi8CqkXCzdqdkblHMUAQI/wRyIZ0Wz9OYJ3dl+8hDv94DWwzt25kuA1Eux4z2SaBS675Da3hwq5ItgRlwwlXY6B48o790WRbrO+q2OKtki1BWXcfmnVD4YdOtgTqe8LtsTtC2wBrgDSTlfTCn91C3vwl0dY2C8j2mYmKPIbbQLTrMZNtJ/Bb/OfXDLSReQFEXQmcuti8Xwp2JVv44c/qi0RLJLZ4u2RLIGIfuvntjOkHhR8+2RKYLAm3125jjepiJhOWI17x4je/Y+Ma7faaTrheS/vFWQB03Csv40ntYW0gq8RlJttBEIL9z8TLv1NSJUyUbf+KhTrhz4+hTl+X/y0OdTY/2Kw6sZxjMlr+8njLZLsB+fi/xZlMJpPJZDKZTP5gPn36P+T1IXZnXHUNAAAAAElFTkSuQmCC'},
        varesco_b09={width=221,height=32,data='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'},