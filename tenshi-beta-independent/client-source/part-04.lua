            if not ok then return end
        end
        local ok,image=pcall(asset,filename)
        if ok and premiumStar.Parent then premiumStar.Image=image end
    end)
    do
    -- Settings and artwork are independent of the report worker/network lock.
    local uiAssetUris={}
    local uiAssetTargets={}
    local uiAssetsLoading=false
    loadUiAsset=function(target,key)
        if uiAssetUris[key] then target.Image=uiAssetUris[key];return end
        uiAssetTargets[#uiAssetTargets+1]={object=target,key=key}
        if uiAssetsLoading then return end
        uiAssetsLoading=true
        task.spawn(function()
            local asset=getcustomasset or getsynasset
            if type(asset)~='function' or type(writefile)~='function' or type(D.decodeAsset)~='function' then return end
            local missing={}
            for _,name in ipairs({'gear','discord'}) do
                local filename='tenshi_beta_settings_v1_'..name..'.png'
                local exists=false
                if type(isfile)=='function' then pcall(function() exists=isfile(filename) end) end
                if exists then
                    local ok,uri=pcall(asset,filename)
                    if ok then uiAssetUris[name]=uri end
                end
                if not uiAssetUris[name] then missing[#missing+1]=name end
            end
            if #missing>0 then
                local ok,data=pcall(function() return Http:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/syss1211/Tenshi-script/ebde34bfef44bce389f0a6a276455f8019f34051/assets/nyx-settings-art-v1.json')) end)
                if ok and type(data)=='table' then
                    for _,name in ipairs(missing) do
                        local encoded=data[name]
                        if type(encoded)=='string' then
                            pcall(function()
                                local bytes=D.decodeAsset(encoded)
                                if bytes:sub(1,8)~=string.char(137)..'PNG'..string.char(13,10,26,10) then return end
                                local filename='tenshi_beta_settings_v1_'..name..'.png'
                                writefile(filename,bytes);uiAssetUris[name]=asset(filename)
                            end)
                        end
                    end
                else warn('Tenshi UI artwork: unable to load settings icons') end
            end
            for _,item in ipairs(uiAssetTargets) do
                if item.object.Parent and uiAssetUris[item.key] then item.object.Image=uiAssetUris[item.key] end
            end
            uiAssetTargets={};uiAssetsLoading=false
        end)
    end
    themeModal=function(box)
        box.BackgroundColor3=Color3.fromRGB(43,45,50);box.BackgroundTransparency=0.03
        D.make('UIGradient',{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(165,168,178)),Rotation=90},box)
        D.make('UIStroke',{Color=Color3.fromRGB(100,104,116),Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},box)
        if mutationSprites.studs_v05 then
            D.make('ImageLabel',{Name='ModalStuds',Image=mutationSprites.studs_v05.image,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(256,256),ImageColor3=Color3.fromRGB(145,148,158),ImageTransparency=0.7,Active=false,ZIndex=box.ZIndex},box)
        end
    end
    heading.Text='TENSHI FINDER BETA 0.6'
    heading.AnchorPoint=Vector2.new(0.5,0)
    heading.Position=UDim2.new(0.5,-10,0,2);heading.Size=UDim2.new(1,-112,0,24)
    heading.TextXAlignment=Enum.TextXAlignment.Center
    heading.Font=Enum.Font.Arcade;heading.TextTransparency=0
    discordSubtitle.AnchorPoint=Vector2.new(0.5,0)
    discordSubtitle.Position=UDim2.new(0.5,0,0,27);discordSubtitle.Size=UDim2.new(1,-112,0,14)
    discordSubtitle.TextXAlignment=Enum.TextXAlignment.Center
    local settingsButton=D.make('TextButton',{Name='OpenSettings',Text='⚙',TextSize=30,Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(6,3),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),ZIndex=6},panel)
    local gear=D.make('ImageLabel',{Name='SettingsGear',Image='',Position=UDim2.fromOffset(-1,-1),Size=UDim2.fromOffset(42,42),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Active=false,ZIndex=7},settingsButton)
    gear:GetPropertyChangedSignal('IsLoaded'):Connect(function() if gear.IsLoaded and gear.Image~='' then settingsButton.TextTransparency=1 end end)
    loadUiAsset(gear,'gear')
    local settingsOverlay=D.make('TextButton',{Name='SettingsOverlay',Text='',Visible=false,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.32,AutoButtonColor=false,Active=true,ZIndex=50},panel)
    local settingsBox=D.make('Frame',{Name='SettingsBox',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(1,-28,0,414),BackgroundColor3=Color3.fromRGB(43,45,50),Active=true,ZIndex=51},settingsOverlay)
    D.make('UICorner',{CornerRadius=UDim.new(0,4)},settingsBox)
    themeModal(settingsBox)
    local function settingsLabel(text,y)
        local label=D.label(settingsBox,text,UDim2.fromOffset(14,y),UDim2.new(1,-28,0,28),Color3.new(1,1,1),20)
        label.Font=Enum.Font.FredokaOne;label.TextXAlignment=Enum.TextXAlignment.Center;label.TextScaled=true;label.ZIndex=54
        D.make('UITextSizeConstraint',{MinTextSize=12,MaxTextSize=20},label)
        return label
    end
    settingsLabel('SETTINGS',10)
    settingsLabel('CUSTOM GUI',59)
    settingsLabel('CUSTOM HOTKEY MENU',160)
    sizeMinus.Parent=settingsBox;sizePlus.Parent=settingsBox;sizeLabel.Parent=settingsBox
    sizeMinus.Position=UDim2.new(0.5,-78,0,94);sizeMinus.Size=UDim2.fromOffset(48,48)
    sizePlus.Position=UDim2.new(0.5,30,0,94);sizePlus.Size=UDim2.fromOffset(48,48)
    sizeLabel.Position=UDim2.new(0.5,-28,0,107);sizeLabel.Size=UDim2.fromOffset(56,22)
    for _,obj in ipairs({sizeMinus,sizePlus,sizeLabel}) do
        obj.ZIndex=55
        for _,child in ipairs(obj:GetDescendants()) do if child:IsA('GuiObject') then child.ZIndex=56 end end
    end
    local hotkeyButton=D.make('TextButton',{Name='HotkeyBind',Text=menuHotkey.Name,Font=Enum.Font.FredokaOne,Position=UDim2.new(0,14,0,199),Size=UDim2.new(1,-28,0,42),BackgroundColor3=Color3.fromRGB(67,71,82),TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=55},settingsBox)
    hotkeyButton.Font=Enum.Font.FredokaOne
    local waitingForHotkey=false
    local function stopSettings()
        waitingForHotkey=false;settingsOverlay.Visible=false;hotkeyButton.Text=menuHotkey.Name
    end
    do
        local visuals=D.baseEggVisuals
        local function toggle(name,y,value,set,waiting)
            local button=D.make('TextButton',{Text='',Position=UDim2.fromOffset(14,y),Size=UDim2.new(1,-28,0,38),BackgroundColor3=Color3.fromRGB(65,70,80),TextColor3=Color3.new(1,1,1),TextSize=18,Font=Enum.Font.FredokaOne,ZIndex=55},settingsBox)
            styleRaisedButton(button)
            local caption=button:FindFirstChild('RaisedCaption')
            if caption then
                caption.Font=Enum.Font.FredokaOne
                caption.TextScaled=true
                D.make('UITextSizeConstraint',{MinTextSize=11,MaxTextSize=19},caption)
                D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.8},caption)
            end
            local function paint()
                local enabled=value()
                local text=name..': '..(enabled and (waiting and waiting() and 'LOADING...' or 'ON') or 'OFF')
                local color=enabled and Color3.fromRGB(40,135,70) or Color3.fromRGB(65,70,80)
                if button.Text~=text then button.Text=text end
                if button.BackgroundColor3~=color then button.BackgroundColor3=color end
            end
            button.Activated:Connect(function() set(not value());paint() end)
            paint()
            return paint
        end
        D.paintNightSkyOption=toggle('NIGHT SKY',250,function() return D.nightSky.enabled end,D.setNightSky)
        D.paintMyEggOption=toggle('HIDE MY EGGS',294,function() return visuals.hideMine end,D.setHideMyEggs,function() return not visuals.renderer end)
        D.paintBaseEggOption=toggle('HIDE OTHERS EGGS',338,function() return visuals.enabled end,D.setHideBaseEggs,function() return not visuals.renderer end)
    end
    local settingsClose=D.make('TextButton',{Name='CloseSettings',Text='×',Position=UDim2.new(1,-46,0,4),Size=UDim2.fromOffset(40,40),BackgroundColor3=Color3.fromRGB(170,45,55),TextColor3=Color3.new(1,1,1),TextSize=24,ZIndex=55},settingsBox)
    settingsClose.Activated:Connect(stopSettings)
    settingsOverlay.Activated:Connect(stopSettings)
    settingsButton.Activated:Connect(function()
        if settingsOverlay.Visible then stopSettings() else settingsOverlay.Visible=true end
    end)
    hotkeyButton.Activated:Connect(function() waitingForHotkey=true;hotkeyButton.Text='PRESS A KEY  (ESC TO CANCEL)' end)
    local hotkeyConnection=Input.InputBegan:Connect(function(input,processed)
        if input.UserInputType~=Enum.UserInputType.Keyboard or input.KeyCode==Enum.KeyCode.Unknown then return end
        if waitingForHotkey then
            waitingForHotkey=false
            if input.KeyCode~=Enum.KeyCode.Escape then menuHotkey=input.KeyCode;saveSettings() end
            hotkeyButton.Text=menuHotkey.Name
            return
        end
        if processed or Input:GetFocusedTextBox() then return end
        if input.KeyCode==menuHotkey then
            panel.Visible=not panel.Visible;D.localPanel.Visible=not panel.Visible
            if not panel.Visible then stopSettings() end
        end
    end)
    D.gui.Destroying:Connect(function() hotkeyConnection:Disconnect() end)
    -- Reserve a separate star slot. Its right edge never touches the caption.
    premiumStar.Position=UDim2.new(0,7,0.5,-11);premiumStar.Size=UDim2.fromOffset(22,22)
    if premiumCaption then
        premiumCaption.Position=UDim2.fromOffset(34,2);premiumCaption.Size=UDim2.new(1,-42,1,-4)
        local limit=premiumCaption:FindFirstChildOfClass('UITextSizeConstraint')
        if limit then limit.MaxTextSize=20 end
    end

    do
    -- Header title and egg are laid out as one centered visual group.
    do
        local service=game:GetService('TextService')
        heading.Font=discordSubtitle.Font
        local available=(panel.Size.X.Offset>0 and panel.Size.X.Offset or 402)-100
        local fontSize=22
        local textWidth
        repeat
            textWidth=math.ceil(service:GetTextSize(heading.Text,fontSize,discordSubtitle.Font,Vector2.new(1000,1000)).X)+4
            if textWidth<=available or fontSize<=14 then break end
            fontSize-=1
        until false
        heading.AnchorPoint=Vector2.new(0.5,0);heading.Position=UDim2.new(0.5,0,0,1);heading.Size=UDim2.fromOffset(textWidth,26)
        heading.TextSize=fontSize;heading.TextScaled=false;heading.TextXAlignment=Enum.TextXAlignment.Center;heading.TextStrokeTransparency=1
        local limit=heading:FindFirstChildOfClass('UITextSizeConstraint');if limit then limit.MaxTextSize=22 end
        D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.4},heading)
        discordSubtitle.TextSize=14;discordSubtitle.TextScaled=true;discordSubtitle.Size=UDim2.new(1,-108,0,16)
        discordSubtitle.Position=UDim2.new(0.5,0,0,27);discordSubtitle.TextStrokeTransparency=1
        local discordLimit=discordSubtitle:FindFirstChildOfClass('UITextSizeConstraint');if discordLimit then discordLimit.MaxTextSize=14 end
        D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.3},discordSubtitle)
    end
    sizeLabel.Font=Enum.Font.FredokaOne;sizeLabel.TextStrokeTransparency=1;sizeLabel.TextSize=20
    local sizeLimit=sizeLabel:FindFirstChildOfClass('UITextSizeConstraint');if sizeLimit then sizeLimit.MaxTextSize=20 end
    D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.6},sizeLabel)
    refreshButton.Font=Enum.Font.FredokaOne
    local refreshCaption=refreshButton:FindFirstChild('RaisedCaption')
    if refreshCaption then
        refreshCaption.Font=Enum.Font.FredokaOne;refreshCaption.TextSize=20;refreshCaption.TextScaled=true;refreshCaption.TextStrokeTransparency=1
        refreshCaption.Position=UDim2.fromOffset(4,2);refreshCaption.Size=UDim2.new(1,-8,1,-4)
        D.make('UITextSizeConstraint',{MinTextSize=12,MaxTextSize=20},refreshCaption)
        D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.7},refreshCaption)
    end
    resetTimer.Font=Enum.Font.FredokaOne;resetTimer.TextSize=16;resetTimer.TextScaled=true;resetTimer.TextStrokeTransparency=1
    D.make('UITextSizeConstraint',{MinTextSize=10,MaxTextSize=16},resetTimer)
    D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.4},resetTimer)
    local controlImages={}
    local controlLayout={plus={x=-2.644934804413241,y=-2.2657973921765304,w=53.289869608826486,h=52.405215646940825},minus={x=-31.89664429530201,y=1.6469798657718115,w=111.79328859060402,h=44.70604026845638}}
    local function pngControl(button,key,fallback,color)
        for _,child in ipairs(button:GetChildren()) do child:Destroy() end
        button.BackgroundTransparency=1;button.AutoButtonColor=false;button.ClipsDescendants=true
        button.Text='';button.TextTransparency=1;button.TextStrokeTransparency=1
        local fallbackLabel=D.make('TextLabel',{Name='SizeFallback',Text=fallback,Font=Enum.Font.FredokaOne,TextSize=34,TextColor3=color,TextStrokeTransparency=1,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Active=false,ZIndex=button.ZIndex+1},button)
        local fallbackStroke=D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.8},fallbackLabel)
        local layout=controlLayout[key]
        local image=D.make('ImageLabel',{Name='SizePNG',Image='',BackgroundTransparency=1,Position=UDim2.fromOffset(layout.x,layout.y),Size=UDim2.fromOffset(layout.w,layout.h),ScaleType=Enum.ScaleType.Stretch,Active=false,ZIndex=button.ZIndex+2},button)
        local outlines={}
        for _,offset in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
            outlines[#outlines+1]=D.make('ImageLabel',{Name='SizeIconOutline',Image='',ImageColor3=Color3.new(0,0,0),ImageTransparency=1,BackgroundTransparency=1,Position=UDim2.fromOffset(layout.x+offset[1],layout.y+offset[2]),Size=UDim2.fromOffset(layout.w,layout.h),ScaleType=Enum.ScaleType.Stretch,Active=false,ZIndex=button.ZIndex+1},button)
        end
        image:GetPropertyChangedSignal('IsLoaded'):Connect(function()
            if image.IsLoaded and image.Image~='' then
                fallbackLabel.Visible=false;fallbackStroke.Enabled=false
                for _,outline in ipairs(outlines) do outline.Image=image.Image;outline.ImageTransparency=0 end
            end
        end)
        controlImages[key]=image
    end
    pngControl(sizePlus,'plus','+',Color3.fromRGB(45,90,245))
    pngControl(sizeMinus,'minus','−',Color3.fromRGB(235,30,55))
    task.spawn(function()
        local asset=getcustomasset or getsynasset
        if type(asset)~='function' or type(writefile)~='function' or type(D.decodeAsset)~='function' then return end
        local pending={}
        for name,image in pairs(controlImages) do
            local filename='tenshi_beta_size_png_v1_'..name..'.png'
            local exists=false;if type(isfile)=='function' then pcall(function() exists=isfile(filename) end) end
            if exists then local ok,uri=pcall(asset,filename);if ok then image.Image=uri end end
            if image.Image=='' then pending[#pending+1]=name end
        end
        if #pending==0 then return end
        local ok,data=pcall(function() return Http:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/syss1211/Tenshi-script/609430c9c12e125ebdcdd94edbc9101691e7f863/assets/nyx-size-controls-v1.json')) end)
        if not ok or type(data)~='table' then warn('Tenshi UI: size icons unavailable');return end
        for _,name in ipairs(pending) do
            if type(data[name])=='string' then
                pcall(function()
                    local bytes=D.decodeAsset(data[name])
                    if bytes:sub(1,8)~=string.char(137)..'PNG'..string.char(13,10,26,10) then return end
                    local filename='tenshi_beta_size_png_v1_'..name..'.png'
                    writefile(filename,bytes)
                    if controlImages[name].Parent then controlImages[name].Image=asset(filename) end
                end)
            end
        end
    end)
    syncCloseArt=function(button)
        button.BackgroundTransparency=1;button.Font=Enum.Font.FredokaOne;button.TextSize=30
        button.TextColor3=Color3.fromRGB(245,45,45);button.TextStrokeColor3=Color3.new(0,0,0)
        local art=D.make('ImageLabel',{Name='SharedClosePNG',Image='',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(1,-8,1,-8),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Active=false,ZIndex=button.ZIndex+1},button)
        local function sync()
            if not art.Parent then return end
            local uri=closeArt.Image
            art.Image=uri
            local hasImage=type(uri)=='string' and uri~=''
            -- Clear the native X on URI assignment, before any IsLoaded signal.
            button.Text=hasImage and '' or '×'
            button.TextTransparency=hasImage and 1 or 0
            button.TextStrokeTransparency=hasImage and 1 or 0
        end
        closeArt:GetPropertyChangedSignal('Image'):Connect(sync)
        sync()
    end
    syncCloseArt(settingsClose)
    end
    end
    local mutationPalettes={
        title={Color3.fromRGB(223,221,221),Color3.fromRGB(225,223,223),Color3.fromRGB(226,225,225),Color3.fromRGB(228,227,227),Color3.fromRGB(230,229,229),Color3.fromRGB(231,231,231),Color3.fromRGB(233,233,233),Color3.fromRGB(236,236,236),Color3.fromRGB(239,239,239),Color3.fromRGB(242,242,242),Color3.fromRGB(246,246,246),Color3.fromRGB(249,249,249),Color3.fromRGB(252,252,252),Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255),Color3.fromRGB(252,252,252),Color3.fromRGB(249,249,249),Color3.fromRGB(246,246,246),Color3.fromRGB(242,242,242),Color3.fromRGB(239,239,239),Color3.fromRGB(236,236,236),Color3.fromRGB(233,233,233),Color3.fromRGB(230,230,230),Color3.fromRGB(227,227,227),Color3.fromRGB(224,224,224),Color3.fromRGB(220,220,220),Color3.fromRGB(217,217,217),Color3.fromRGB(214,214,214)},
        discord={Color3.fromRGB(255,0,225),Color3.fromRGB(251,0,226),Color3.fromRGB(247,0,227),Color3.fromRGB(244,0,229),Color3.fromRGB(240,0,230),Color3.fromRGB(236,0,231),Color3.fromRGB(232,0,232),Color3.fromRGB(229,0,233),Color3.fromRGB(225,0,235),Color3.fromRGB(221,0,236),Color3.fromRGB(217,0,237),Color3.fromRGB(214,0,238),Color3.fromRGB(210,0,239),Color3.fromRGB(206,0,241),Color3.fromRGB(202,0,242),Color3.fromRGB(199,0,243),Color3.fromRGB(195,0,244),Color3.fromRGB(191,0,245),Color3.fromRGB(187,0,247),Color3.fromRGB(184,0,248),Color3.fromRGB(180,0,249),Color3.fromRGB(176,0,250),Color3.fromRGB(172,0,251),Color3.fromRGB(169,0,253),Color3.fromRGB(165,0,254),Color3.fromRGB(161,0,255)},
        golden={Color3.fromRGB(206,164,0),Color3.fromRGB(222,173,0),Color3.fromRGB(239,182,0),Color3.fromRGB(255,191,0),Color3.fromRGB(254,209,46),Color3.fromRGB(253,227,92)},
        rainbow={Color3.fromRGB(255,0,0),Color3.fromRGB(255,113,0),Color3.fromRGB(255,169,0),Color3.fromRGB(255,248,0),Color3.fromRGB(139,255,0),Color3.fromRGB(0,255,7),Color3.fromRGB(0,255,154)},
        silver={Color3.fromRGB(71,71,71),Color3.fromRGB(104,104,104),Color3.fromRGB(137,137,137),Color3.fromRGB(170,170,170),Color3.fromRGB(137,137,137),Color3.fromRGB(104,104,104),Color3.fromRGB(71,71,71)}
    }
    local mutationGradients={golden={},silver={},rainbow={},discord={},title={}}
    local function mutationSequence(palette,now)
        local phase=(now/4)%1
        local points={}
        for i=0,16 do
            local sample=((i/16-phase)%1)*#palette
            local index=math.floor(sample)
            points[#points+1]=ColorSequenceKeypoint.new(i/16,palette[index+1]:Lerp(palette[(index+1)%#palette+1],sample-index))
        end
        return ColorSequence.new(points)
    end
    local function mutationStyle(object,name)
        local key=name:lower()
        if key=='gold' then key='golden' end
        local palette=mutationPalettes[key]
        if not palette then return end
        if object:IsA('TextLabel') then
            object.TextColor3=Color3.new(1,1,1);object.TextStrokeTransparency=1
        else object.ImageColor3=Color3.new(1,1,1) end
        local gradient=D.make('UIGradient',{Color=mutationSequence(palette,os.clock()),Rotation=0},object)
        local bucket=mutationGradients[key];bucket[#bucket+1]=gradient
    end
    mutationStyle(discordSubtitle,'discord')
    mutationStyle(heading,'title')
    local filterPalettes={
        cosmic={Color3.fromRGB(67,37,239),Color3.fromRGB(113,29,255),Color3.fromRGB(90,37,230),Color3.fromRGB(67,44,204),Color3.fromRGB(63,44,244),Color3.fromRGB(41,12,217)},
        secret={Color3.fromRGB(40,40,40),Color3.fromRGB(66,62,59),Color3.fromRGB(90,90,87),Color3.fromRGB(118,124,118),Color3.fromRGB(144,152,152),Color3.fromRGB(195,195,201)},
        eternal={Color3.fromRGB(143,203,193),Color3.fromRGB(179,236,227),Color3.fromRGB(192,236,229),Color3.fromRGB(205,236,230),Color3.fromRGB(216,236,232),Color3.fromRGB(227,236,234),Color3.fromRGB(182,165,198),Color3.fromRGB(82,28,125),Color3.fromRGB(141,92,164),Color3.fromRGB(183,125,193),Color3.fromRGB(216,151,220),Color3.fromRGB(230,171,234),Color3.fromRGB(227,187,236),Color3.fromRGB(218,202,236),Color3.fromRGB(212,216,236)}
    }
    local filterWords=D.make('Frame',{Name='RarityFontParts',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(1,26),BackgroundTransparency=1,Active=false,ZIndex=rarity.ZIndex+5},rarity)
    local function filterLabel(text)
        local label=D.make('TextLabel',{Text=text,Font=Enum.Font.FredokaOne,TextSize=20,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=1,BackgroundTransparency=1,TextWrapped=false,TextScaled=false,Active=false,ZIndex=filterWords.ZIndex},filterWords)
        D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=2},label)
        return label
    end
    local filterPrefix=filterLabel('MIN RARITY:')
    local filterWord=filterLabel('Any')
    local filterGradient=D.make('UIGradient',{Enabled=false,Rotation=0},filterWord)
    local filterName=rarityOptions[rarityIndex].name:lower()
    local function updateFilterColor(now)
        local palette=filterPalettes[filterName]
        if palette then
            filterWord.TextColor3=Color3.new(1,1,1);filterGradient.Enabled=true
            filterGradient.Color=mutationSequence(palette,now)
        else
            filterGradient.Enabled=false;filterWord.TextColor3=rarityColors[filterName] or Color3.new(1,1,1)
        end
    end
    local function refreshFilterWord()
        local name=rarityOptions[rarityIndex].name
        filterName=name:lower();filterWord.Text=name
        filterGradient.Rotation=filterName=='eternal' and 90 or 0
        rarity.TextTransparency=1
        local caption=rarity:FindFirstChild('RaisedCaption');if caption then caption.Visible=false end
        local panelWidth=panel.Size.X.Offset>0 and panel.Size.X.Offset or 402
        local available=math.max(20,panelWidth*rarity.Size.X.Scale+rarity.Size.X.Offset-20)
        local service=game:GetService('TextService')
        local size,prefixWidth,wordWidth=22,0,0
        repeat
            prefixWidth=math.ceil(service:GetTextSize(filterPrefix.Text,size,Enum.Font.FredokaOne,Vector2.new(1000,1000)).X)+4
            wordWidth=math.ceil(service:GetTextSize(name,size,Enum.Font.FredokaOne,Vector2.new(1000,1000)).X)+4
            if prefixWidth+wordWidth+6<=available or size<=10 then break end
            size-=1
        until false
        filterWords.Size=UDim2.fromOffset(prefixWidth+wordWidth+6,26)
        filterPrefix.Position=UDim2.new();filterPrefix.Size=UDim2.fromOffset(prefixWidth,26);filterPrefix.TextSize=size
        filterWord.Position=UDim2.fromOffset(prefixWidth+6,0);filterWord.Size=UDim2.fromOffset(wordWidth,26);filterWord.TextSize=size
        updateFilterColor(os.clock())
    end
    rarity:GetPropertyChangedSignal('Text'):Connect(refreshFilterWord)
    refreshFilterWord()
    local rarityGradientBuckets={cosmic={},secret={},eternal={}}
    local function styleRarityLabel(label,key)
        local palette=filterPalettes[key]
        if not palette then return end
        label.TextColor3=Color3.new(1,1,1)
        if key=='secret' then label.TextStrokeColor3=Color3.new(0,0,0);label.TextStrokeTransparency=0.25 end
        local gradient=D.make('UIGradient',{Color=mutationSequence(palette,os.clock()),Rotation=key=='eternal' and 90 or 0},label)
        rarityGradientBuckets[key][gradient]=true
    end
    local lastMutationUpdate=0
    local mutationMotion=game:GetService('RunService').Heartbeat:Connect(function()
        local now=os.clock()
        if now-lastMutationUpdate<1/20 then return end
        lastMutationUpdate=now
        if refreshing then
            local text='REFRESHING'..string.rep('.',math.floor(now/0.4)%3+1)
            if refreshButton.Text~=text then refreshButton.Text=text end
        end
        if loadingVisible and aliveMessage.Visible then
            local text=loadingText(now);if aliveMessage.Text~=text then aliveMessage.Text=text end
        end
        updateFilterColor(now)
        for key,bucket in pairs(rarityGradientBuckets) do
            if next(bucket) then
                local colors=mutationSequence(filterPalettes[key],now)
                for gradient in pairs(bucket) do
                    if gradient.Parent then gradient.Color=colors else bucket[gradient]=nil end
                end
            end
        end
        for key,bucket in pairs(mutationGradients) do
            if #bucket>0 then
                local colors=mutationSequence(mutationPalettes[key],now)
                for i=#bucket,1,-1 do
                    local gradient=bucket[i]
                    if not gradient.Parent then table.remove(bucket,i) else gradient.Color=colors end
                end
            end
        end
    end)
    D.gui.Destroying:Connect(function() mutationMotion:Disconnect() end)
    local function mutationWidth(name,textService,available)
        local spec=mutationSpriteData[name:lower()]
        if spec then return math.min(available,math.ceil(spec.width/spec.height*24)+8) end
        return math.min(available,math.ceil(textService:GetTextSize(name,22,Enum.Font.Arcade,Vector2.new(1000,28)).X)+8)
    end
    local function mutationWord(row,name,position,width)
        local word=D.label(row,name,position,UDim2.fromOffset(width,28),Color3.fromRGB(245,210,125),22)
        word.Font=Enum.Font.Arcade
        word.TextXAlignment=Enum.TextXAlignment.Center
        word.TextTruncate=Enum.TextTruncate.None;word.TextScaled=true;word.TextWrapped=false
        D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=22},word)
        mutationStyle(word,name)
        word.TextStrokeColor3=Color3.new(0,0,0);word.TextStrokeTransparency=0
        local fallbackStroke=D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.1},word)
        local spec=mutationSprites[name:lower()]
        if spec then
            local glyph=D.make('ImageLabel',{Image=spec.image,ImageTransparency=1,BackgroundTransparency=1,ImageColor3=Color3.new(1,1,1),Size=UDim2.new(1,-4,1,-4),Position=UDim2.fromOffset(2,2),ScaleType=Enum.ScaleType.Fit,Active=false,ZIndex=word.ZIndex+2},word)
            pcall(function() glyph.ResampleMode=Enum.ResamplerMode.Pixelated end)
            local shadows={}
            for _,offset in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
                local shadow=D.make('ImageLabel',{Image=spec.image,ImageTransparency=1,ImageColor3=Color3.new(0,0,0),BackgroundTransparency=1,Size=UDim2.new(1,-4,1,-4),Position=UDim2.fromOffset(2+offset[1],2+offset[2]),ScaleType=Enum.ScaleType.Fit,Active=false,ZIndex=word.ZIndex+1},word)
                pcall(function() shadow.ResampleMode=Enum.ResamplerMode.Pixelated end)
                shadows[#shadows+1]=shadow
            end
            mutationStyle(glyph,name)
            local function ready()
                if glyph.IsLoaded then fallbackStroke.Enabled=false;word.TextStrokeTransparency=1;word.TextTransparency=1;glyph.ImageTransparency=0;for _,shadow in ipairs(shadows) do shadow.ImageTransparency=0 end end
            end
            glyph:GetPropertyChangedSignal('IsLoaded'):Connect(ready)
            ready()
        end
        return word
    end
    local ageLabels={}
    local function resetAgeText(cycle)
        if not cycle or type(cycle.remaining)~='number' or cycle.remaining~=cycle.remaining then return '--' end
        local remaining=math.clamp(math.ceil(cycle.remaining),0,300)
        return tostring(math.floor((300-remaining)/60))..'m ago'
    end
    local function resetAgeColor(cycle)
        local text=resetAgeText(cycle)
        local minutes=tonumber(text:match('^(%d+)m ago$'))
        if minutes and minutes>=4 then return Color3.fromRGB(255,85,85) end
        if minutes and minutes>=2 then return Color3.fromRGB(255,215,65) end
        return Color3.fromRGB(210,216,230)
    end
    local function updateSpawnAges(cycle)
        local text=resetAgeText(cycle)
        local color=resetAgeColor(cycle)
        for _,item in ipairs(ageLabels) do
            if item.label.Parent then
                if item.label.Text~=text then item.label.Text=text end
                if item.label.TextColor3~=color then item.label.TextColor3=color end
            end
        end
    end

    local joiningKey=nil
    D.joinAttempt=nil
    D.joinNotice=function(message)
        queryStatus=message
        if not active then return end
        D.gui:SetAttribute('TenshiLastJoinResult',message)
        warn('[Tenshi JOIN] '..tostring(message))
    end
    D.finishJoin=function(attempt)
        if D.joinAttempt~=attempt then return end
        D.joinAttempt=nil;joining=false;joiningKey=nil;feedAt=-math.huge
    end
    local joinRetryAt=0
    local cardsByKey={}
    local function compactCardHeight()
        return math.clamp(math.floor((panel.Size.Y.Offset-238-16)/5),76,112)
    end
    D.fullJobs={}
    D.populationReports={}
    D.populationFull=function(entry)
        local noted=D.fullJobs[entry.jobId]
        local count,capacity,seen=tonumber(entry.playerCount),tonumber(entry.maxPlayers),tonumber(entry.populationAt)
        local now=(os.clock()+clockOffset)*1000
        local report=D.populationReports[entry.jobId]
        if report and os.clock()-report.observedAt<=45 then
            local reportedAt=(report.observedAt+clockOffset)*1000
            if not seen or reportedAt>seen then
                count=report.count
                capacity=capacity or tonumber(game:GetService('Players').MaxPlayers)
                seen=reportedAt
            end
        end
        if noted and seen and seen>noted.at and count and capacity and count<capacity then
            D.fullJobs[entry.jobId]=nil
            noted=nil
        end
        if noted and now<noted.expiresAt then return tostring(noted.capacity)..'/'..tostring(noted.capacity) end
        if noted then D.fullJobs[entry.jobId]=nil end
        if count and capacity and capacity>0 and seen and now-seen<30000 and count>=capacity then
            return tostring(capacity)..'/'..tostring(capacity)
        end
    end
    D.noteFull=function(entry)
        local capacity=tonumber(entry.maxPlayers) or tonumber(game:GetService('Players').MaxPlayers)
        if capacity and capacity>0 then
            D.fullJobs[entry.jobId]={capacity=capacity,at=(os.clock()+clockOffset)*1000,expiresAt=math.min(entry.expiresAt,(os.clock()+clockOffset)*1000+30000)}
        end
    end
    D.isFullFailure=function(result,message)
        return result==Enum.TeleportResult.GameFull or tostring(message):lower():find('server is full',1,true)~=nil
    end
    local function joinPresentation(entry)
        local here=entry.isLocal or entry.jobId==game.JobId
        if entry.takenConfirmed then return 'TAKEN',Color3.fromRGB(235,55,65),false end
        if here then return 'HERE',Color3.fromRGB(86,90,100),false end
        local capacity=D.populationFull(entry)
        if capacity then return capacity,Color3.fromRGB(220,59,72),false end
        if entry.unavailable then return 'UNAVAILABLE',Color3.fromRGB(86,90,100),false end
        if joining and joiningKey==entry.key then
            local attempt=D.joinAttempt
            if attempt and os.clock()-attempt.startedAt<0.5 then
                return 'JOINING...',Color3.fromRGB(40,160,85),false
            end
        end
        return 'JOIN',Color3.fromRGB(40,160,85),true
    end
    local rankWidthCache={}
    local raritySizeCache={}
    local function cardSignature(entry)
        return Http:JSONEncode({tostring(entry.rarity),tostring(entry.mutations),tostring(entry.mutationText),tostring(entry.traitsKnown),tostring(entry.isEvent),tostring(entry.source)})
    end
    local function compactWeightToFit(text,available,size,service)
        local function fits(value) return service:GetTextSize(value,size,Enum.Font.FredokaOne,Vector2.new(1000,1000)).X<=available end
        local result=text
        while not fits(result) do
            local prefix,whole,fraction,suffix=result:match('^(.-)(%d+)%.(%d+)(.*)$')
            if not fraction then break end
            fraction=fraction:sub(1,-2)
            result=prefix..whole..(#fraction>0 and '.'..fraction or '')..suffix
        end
        return result
    end
    local function fitFinanceText(card)
        local rowWidth=panel.Size.X.Offset-28
        local width=rowWidth-184
        local service=game:GetService('TextService')
        local weightSize=type(card.entry.weight)=='number' and 16 or 19
        local weightAvailable=width*0.46-10
        local text=weightPresentation(card.entry)
        card.weightLabel.Text=compactWeightToFit(text,weightAvailable,weightSize,service)
        for _,spec in ipairs({{card.incomeLabel,width*0.54-10,20},{card.weightLabel,weightAvailable,weightSize}}) do
            local label,available,size=spec[1],spec[2],spec[3]
            while size>8 and service:GetTextSize(label.Text,size,label.Font,Vector2.new(1000,1000)).X>available do size-=1 end
            label.TextSize=size
        end
    end
    local function updateCard(card,entry,i)
        local height=compactCardHeight()
        if card.compactHeight~=height or card.renderScale~=responsiveScale.Scale then
            card.renderScale=responsiveScale.Scale
            card.compactHeight=height;card.row.Size=UDim2.new(1,-12,0,height)
            local renderScale=responsiveScale.Scale
            if type(renderScale)~='number' or renderScale<=0 then renderScale=1 end
            local iconSize=math.floor(math.min(80,height-22)*renderScale)/renderScale
            card.icon.Size=UDim2.fromOffset(iconSize,iconSize);card.icon.Position=UDim2.fromOffset(math.floor((4+(78-iconSize)/2)*renderScale)/renderScale,0)
            card.spotlight.Position=card.icon.Position
            card.spotlight.Size=card.icon.Size
            card.join.Position=UDim2.new(1,-98,0,math.min(29,height-54))
        end
        local rankText='#'..tostring(entry.displayRank or entry.globalRank or i)
        if card.rankLabel.Text~=rankText then
            local width=rankWidthCache[rankText]
            if not width then
                width=math.ceil(game:GetService('TextService'):GetTextSize(rankText,20,Enum.Font.FredokaOne,Vector2.new(1000,28)).X)+4
                rankWidthCache[rankText]=width
            end
            card.rankLabel.Text=rankText;card.rankLabel.Size=UDim2.fromOffset(width,28)
            card.nameLabel.Position=UDim2.fromOffset(86+width,3);card.nameLabel.Size=UDim2.new(1,-94-width,0,26)
        end
        if card.nameLabel.Text~=tostring(entry.name) then card.nameLabel.Text=tostring(entry.name) end
        if card.icon.Image~=(entry.icon or '') then card.icon.Image=entry.icon or '' end
        if not card.financeReady or card.rate~=entry.rate or card.missingRate~=entry.missingRate then
            card.incomeLabel.Text=entry.missingRate and 'Income unavailable' or D.money(entry.rate)
            card.rate=entry.rate;card.missingRate=entry.missingRate
        end
        if not card.financeReady or card.scale~=entry.scale or card.weight~=entry.weight then
            local text,color=weightPresentation(entry)
            local isScale=type(entry.weight)~='number' and type(entry.scale)=='number'
            card.weightLabel.Text=text;card.weightLabel.TextColor3=color
            card.weightLabel.Font=Enum.Font.FredokaOne
            card.weightLabel.TextSize=isScale and 19 or 16
            card.weightLimit.MaxTextSize=isScale and 19 or 16
            card.scale=entry.scale;card.weight=entry.weight
        end
        if not card.financeReady or card.fittedRate~=entry.rate or card.fittedWeight~=entry.weight or card.fittedScale~=entry.scale then
            fitFinanceText(card);card.fittedRate=entry.rate;card.fittedWeight=entry.weight;card.fittedScale=entry.scale
        end
        card.multiplierLabel.Text,card.multiplierLabel.TextColor3=D.scalePresentation(entry)
        card.financeReady=true
        local text,color,enabled=joinPresentation(entry)
        if card.join.Text~=text then card.join.Text=text end
        if card.buttonText~=text or card.buttonEnabled~=enabled then
            card.join.BackgroundColor3=color
            card.join.Active=enabled;card.join.AutoButtonColor=enabled;card.join.Selectable=enabled
            card.buttonText=text;card.buttonEnabled=enabled
        end
    end
    local rendering,renderPending,renderQueued=false,false,false
    local function queueRender()
        if renderQueued or not active then return end
        renderQueued=true
        task.defer(function() renderQueued=false;if active then render() end end)
    end
    D.mergeOwnTaken=function(source,validLocal,metadata,now,gameNow)
        if not validLocal then return end
        local takenByKey={}
        for key,entry in pairs(D.hostTaken or {}) do
            if D.publicEntryAllowed(entry,now) then
                local row=table.clone(entry);row.isLocal=true
                takenByKey[key]=row
            end
        end
        if metadata and metadata.resetAt then
            local expiresAt=now+metadata.resetAt-gameNow-2000
            for _,entry in ipairs(D.takenEntries()) do
                local uid=tostring(entry.uid)
                local key=game.PlaceId..':'..game.JobId..':'..uid
                if not takenByKey[key] then
                    takenByKey[key]={key=key,uid=uid,name=entry.name,rate=entry.rate,scale=entry.scale,weight=entry.weight,
                        icon=entry.icon,rarity=entry.rarity,rank=entry.tier,mutations=entry.mutationText,traitsKnown=entry.traitsKnown,
                        area=entry.areaKey,isLocal=true,takenConfirmed=true,source='field',placeId=game.PlaceId,jobId=game.JobId,expiresAt=expiresAt,seenAt=0}
                end
            end
        end
        for i=#source,1,-1 do if takenByKey[source[i].key] then table.remove(source,i) end end
        for _,entry in pairs(takenByKey) do
            if (entry.rate or 0)>=minRate and (entry.rank or 0)>=minRank then source[#source+1]=entry end
        end
    end
    local function renderOnce()
        local passEpoch,passScope=queryEpoch,othersOnly
        local batchStarted=os.clock()
        local passDeadline=math.huge
        local function checkpoint()
            if os.clock()-batchStarted<0.003 then return true end
            task.wait()
            batchStarted=os.clock()
            if not active then return false end
            if queryEpoch~=passEpoch or othersOnly~=passScope or (os.clock()+clockOffset)*1000>=passDeadline then
                renderPending=true
                return false
            end
            return true
        end
        local now=(os.clock()+clockOffset)*1000
        local resetAge=resetAgeText(cycleInfo())
        local entries={}
        local source,seen={},{}
        local metadata=D.metadata and D.metadata()
        local gameNow=workspace:GetServerTimeNow()*1000
        local validLocal=not metadata or not metadata.resetAt or metadata.resetAt-2000>gameNow
        local current=validLocal and D.entries() or {}
        if othersOnly then
            -- MY SERVER is a live local view. ALL-only cache/tombstone rules
            -- must never suppress a record returned by the current field scan.
            local live=D.entries()
            local localCycle=cycleInfo()
            for _,e in ipairs(live) do
                if (e.rate or 0)>=minRate and (e.tier or 0)>=minRank then
                    local uid=tostring(e.uid or e.key)
                    source[#source+1]={key=game.PlaceId..':'..game.JobId..':'..uid,uid=uid,
                        name=e.name,rate=e.rate or 0,missingRate=e.rate==nil,scale=e.scale,weight=e.weight,
                        icon=e.icon,rarity=e.rarity,rank=e.tier,localTier=e.tier,mutations=e.mutationText,
                        traitsKnown=e.traitsKnown~=false,area=e.areaKey or e.area,model=e.model,isLocal=true,
                        source=e.isEvent and 'event' or 'field',estimated=e.estimated or e.unmutatedRate~=nil,
                        placeId=game.PlaceId,jobId=game.JobId,expiresAt=now+5000,seenAt=0,
                        spawnedAt=not e.isEvent and localCycle and localCycle.respawnAt or nil}
                end
            end
            if D.gui then pcall(function() D.gui:SetAttribute('TenshiLocalScanCount',#live);D.gui:SetAttribute('TenshiLocalVisibleCount',#source) end) end
        else
        if not othersOnly then
            for _,e in ipairs(feed) do
                if e.jobId~=game.JobId and (e.cached~=true or e.takenConfirmed==true) and (e.rate or 0)>=minRate and (e.rank or 0)>=minRank and type(e.expiresAt)=='number' and e.expiresAt>now then source[#source+1]=e;seen[e.key]=true end
            end
        end
            local localCycle=cycleInfo()
            for _,e in ipairs(current) do
                if e.broadcastEligible and (e.rate or 0)>=minRate and (e.tier or 0)>=minRank then
                    local key=game.PlaceId..':'..game.JobId..':'..tostring(e.uid or e.key)
                    if not seen[key] then
                        seen[key]=true
                        source[#source+1]={key=key,uid=tostring(e.uid or e.key),name=e.name,rate=e.rate or 0,missingRate=e.rate==nil,scale=e.scale,weight=e.weight,icon=e.icon,rarity=e.rarity,mutations=e.mutationText,traitsKnown=e.traitsKnown~=false,area=e.areaKey or e.area,model=e.model,isLocal=true,localTier=e.tier,full=false,source=e.isEvent and 'event' or 'field',estimated=e.estimated or e.unmutatedRate~=nil,placeId=game.PlaceId,jobId=game.JobId,expiresAt=now+5000,seenAt=0,spawnedAt=not e.isEvent and localCycle and localCycle.respawnAt or nil,spawnTimeKnown=not e.isEvent and localCycle~=nil and type(localCycle.respawnAt)=='number'}
                    end
                end
            end
        end
            D.mergeOwnTaken(source,validLocal,metadata,now,gameNow)
            table.sort(source,function(a,b) if a.rate~=b.rate then return a.rate>b.rate end; return a.key<b.key end)
            for _,entry in ipairs(source) do
                if #entries>=25 then break end
                if (othersOnly or entry.key~=D.hiddenPublicTopKey) and D.publicEntryAllowed(entry,now) and (entry.jobId==game.JobId or not D.populationFull(entry)) then
                local visible=table.clone(entry)
                visible.displayRank=#entries+1
                entries[#entries+1]=visible
            end
        end
        -- Keep the old canvas extent while rebuilding so Roblox does not clamp
        -- the scroll position to zero when the rows are temporarily removed.
        local savedScroll=list.CanvasPosition
        local canvasHeight=#entries==0 and 40 or 0
        ageLabels={}
        local wanted={}
        for _,entry in ipairs(entries) do wanted[entry.key]=true;passDeadline=math.min(passDeadline,entry.expiresAt) end
        for key,card in pairs(cardsByKey) do
            if not wanted[key] then
                card.row:Destroy();cardsByKey[key]=nil
                if not checkpoint() then return end
            end
        end
        loadingVisible=#entries==0 and (othersOnly and type(D.ready)=='function' and not D.ready() or not othersOnly and feedAt<=0)
        aliveMessage.Visible=#entries==0
        aliveMessage.Text=loadingVisible and loadingText(os.clock()) or othersOnly and (type(D.ready)=='function' and not D.ready() and 'Reading current server eggs...' or 'No matching eggs in this server') or PREMIUM_EDITION and viewerCode=='' and 'Enter your Premium access code' or 'No matching eggs right now'
        for i,entry in ipairs(entries) do
            local signature=cardSignature(entry)
            local card=cardsByKey[entry.key]
            if not card or not card.row.Parent or card.signature~=signature then
            if card and card.row.Parent then card.row:Destroy() end
            card={entry=entry,signature=signature}
            local row=D.make('Frame',{Size=UDim2.new(1,-12,0,90),LayoutOrder=i,BackgroundColor3=Color3.fromRGB(105,106,110),BackgroundTransparency=0.24,BorderSizePixel=0},list)
            card.row=row
            row.ClipsDescendants=true
            D.make('UICorner',{CornerRadius=UDim.new(0,1)},row)
            D.make('UIGradient',{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(145,148,155)),Rotation=90},row)
            D.make('UIStroke',{Color=Color3.fromRGB(20,21,24),Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},row)
            D.make('Frame',{Name='CardBevelTop',Position=UDim2.fromOffset(2,1),Size=UDim2.new(1,-4,0,1),BackgroundColor3=Color3.fromRGB(190,192,198),BackgroundTransparency=0.3,BorderSizePixel=0,Active=false},row)
            D.make('Frame',{Name='CardBevelBottom',Position=UDim2.new(0,2,1,-2),Size=UDim2.new(1,-4,0,1),BackgroundColor3=Color3.fromRGB(24,25,28),BorderSizePixel=0,Active=false},row)
            -- Static native UI rays: no downloads, image compression or animation work.
            local spotlight=D.make('Frame',{Name='PetSpotlight',Position=UDim2.fromOffset(2,0),Size=UDim2.new(0,82,1,-22),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=false,Active=false,ZIndex=row.ZIndex+1},row)
            for n=0,11 do
                local ray=D.make('Frame',{Name='WhiteRay',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(0.94,0,0,n%2==0 and 8 or 4),Rotation=n*15+8,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.66,BorderSizePixel=0,Active=false,ZIndex=spotlight.ZIndex},spotlight)
                D.make('UIGradient',{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.97),NumberSequenceKeypoint.new(0.4,0.65),NumberSequenceKeypoint.new(0.5,0.2),NumberSequenceKeypoint.new(0.6,0.65),NumberSequenceKeypoint.new(0.8,0.97),NumberSequenceKeypoint.new(1,1)}),Rotation=0},ray)
            end
            for n=1,12 do
                local glow=D.make('Frame',{Name='SoftCenter',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(1-n*0.065,1-n*0.065),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.985-n*0.002,BorderSizePixel=0,Active=false,ZIndex=spotlight.ZIndex},spotlight)
                D.make('UICorner',{CornerRadius=UDim.new(1,0)},glow)
            end
            card.spotlight=spotlight
            card.icon=D.make('ImageLabel',{Name='PetIcon',Image=entry.icon or '',ZIndex=spotlight.ZIndex+1,BackgroundTransparency=1,Size=UDim2.fromOffset(88,88),Position=UDim2.fromOffset(4,4),ScaleType=Enum.ScaleType.Fit},row)
            local rarityKey=tostring(entry.rarity):lower():gsub('%s+','')
            local nameColor=rarityColors[rarityKey] or Color3.fromRGB(225,225,235)
            local rankText='#'..tostring(entry.displayRank or entry.globalRank or i)
            local textService=game:GetService('TextService')
            local rankWidth=rankWidthCache[rankText]
            if not rankWidth then
                rankWidth=math.ceil(textService:GetTextSize(rankText,20,Enum.Font.FredokaOne,Vector2.new(1000,28)).X)+4
                rankWidthCache[rankText]=rankWidth
            end
            local rankLabel=D.label(row,rankText,UDim2.fromOffset(86,3),UDim2.fromOffset(rankWidth,26),Color3.fromRGB(220,224,235),20)
            rankLabel.Font=Enum.Font.FredokaOne
            D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.5},rankLabel)
            card.rankLabel=rankLabel
            rankLabel.TextTruncate=Enum.TextTruncate.None
            local nameLabel=D.label(row,tostring(entry.name),UDim2.fromOffset(86+rankWidth,3),UDim2.new(1,-94-rankWidth,0,26),nameColor,21)
            card.nameLabel=nameLabel
            nameLabel.Font=Enum.Font.GothamBlack
            D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.1},nameLabel)
            nameLabel.TextStrokeColor3=Color3.new(0,0,0);nameLabel.TextStrokeTransparency=1
            rankLabel.TextStrokeColor3=Color3.new(0,0,0);rankLabel.TextStrokeTransparency=1
            pcall(function() card.icon.ResampleMode=Enum.ResamplerMode.Default end)
            local rarityCell=D.make('Frame',{Name='RarityCell',Position=UDim2.new(0,2,1,-26),Size=UDim2.fromOffset(82,22),BackgroundTransparency=1},row)
            local rarityText=tostring(entry.rarity)
            local rarityTextSize=raritySizeCache[rarityText]
            if not rarityTextSize then
                rarityTextSize=20
                while rarityTextSize>1 do
                    local bounds=textService:GetTextSize(rarityText,rarityTextSize,Enum.Font.GothamBlack,Vector2.new(1000,1000))
                    if bounds.X<=76 and bounds.Y<=20 then break end
                    rarityTextSize-=1
                end
                raritySizeCache[rarityText]=rarityTextSize
            end
            local rarityLabel=D.label(rarityCell,rarityText,UDim2.fromOffset(3,1),UDim2.new(1,-6,1,-2),nameColor,rarityTextSize)
            rarityLabel.Font=Enum.Font.GothamBlack
            rarityLabel.TextStrokeColor3=Color3.new(0,0,0);rarityLabel.TextStrokeTransparency=0.2
            rarityLabel.TextXAlignment=Enum.TextXAlignment.Center
            rarityLabel.TextYAlignment=Enum.TextYAlignment.Center
            rarityLabel.TextTruncate=Enum.TextTruncate.None
            rarityLabel.TextScaled=false
            rarityLabel.TextWrapped=false
            styleRarityLabel(nameLabel,rarityKey)
            local finance=D.make('Frame',{Name='IncomeAndWeight',Position=UDim2.fromOffset(86,31),Size=UDim2.new(1,-184,0,22),BackgroundTransparency=1},row)
            local incomeCell=D.make('Frame',{Name='IncomeCell',Position=UDim2.new(),Size=UDim2.new(0.54,-4,1,0),BackgroundTransparency=1,ClipsDescendants=false},finance)
            local incomeLabel=D.label(incomeCell,entry.missingRate and 'Income unavailable' or D.money(entry.rate),UDim2.fromOffset(3,2),UDim2.new(1,-6,1,-4),Color3.fromRGB(135,240,140),20)
            card.incomeLabel=incomeLabel
            incomeLabel.TextStrokeColor3=Color3.new(0,0,0);incomeLabel.TextStrokeTransparency=1
            incomeLabel.Font=Enum.Font.GothamBlack
            D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.1},incomeLabel)
            incomeLabel.TextTruncate=Enum.TextTruncate.None
            incomeLabel.TextScaled=false
            incomeLabel.TextWrapped=false
            D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=20},incomeLabel)
            local weightText,weightColor=weightPresentation(entry)
            local isScale=type(entry.weight)~='number' and type(entry.scale)=='number'
            local weightCell=D.make('Frame',{Name='WeightCell',Position=UDim2.new(0.54,4,0,0),Size=UDim2.new(0.46,-4,0,22),BackgroundTransparency=1,ClipsDescendants=false},finance)
            local weightLabel=D.label(weightCell,weightText,UDim2.fromOffset(3,2),UDim2.new(1,-6,1,-4),weightColor,isScale and 19 or 16)
            card.weightLabel=weightLabel
            card.multiplierLabel=D.label(weightCell,'',UDim2.fromOffset(3,21),UDim2.new(1,-6,0,18),Color3.fromRGB(220,224,235),18)
            card.multiplierLabel.Font=Enum.Font.FredokaOne;card.multiplierLabel.TextScaled=true
            card.multiplierLabel.TextWrapped=false;card.multiplierLabel.TextStrokeTransparency=1
            D.make('UITextSizeConstraint',{MinTextSize=10,MaxTextSize=18},card.multiplierLabel)
            D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.8},card.multiplierLabel)
            D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.8},weightLabel)
            weightLabel.TextStrokeColor3=Color3.new(0,0,0);weightLabel.TextStrokeTransparency=1
            weightLabel.Font=Enum.Font.FredokaOne
            weightLabel.TextTruncate=Enum.TextTruncate.None
            weightLabel.TextScaled=false
            weightLabel.TextWrapped=false
            card.weightLimit=D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=isScale and 19 or 16},weightLabel)
            local ageLabel=D.label(finance,resetAge,UDim2.new(1,-98,1,-23),UDim2.fromOffset(90,22),Color3.fromRGB(210,216,230),17)
            ageLabel.Font=Enum.Font.FredokaOne
            ageLabel.TextXAlignment=Enum.TextXAlignment.Center;ageLabel.TextYAlignment=Enum.TextYAlignment.Center
            ageLabel.TextStrokeColor3=Color3.new(0,0,0);ageLabel.TextStrokeTransparency=1
            D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=1.8},ageLabel)
            ageLabel.Parent=row
            ageLabel.Name='SpawnAge';ageLabel.TextScaled=true;ageLabel.TextWrapped=false;ageLabel.TextTruncate=Enum.TextTruncate.None
            D.make('UITextSizeConstraint',{MinTextSize=1,MaxTextSize=17},ageLabel)
            card.ageLabel=ageLabel
            rarityLabel.TextColor3=nameLabel.TextColor3
            local nameGradient=nameLabel:FindFirstChildOfClass('UIGradient')
            if nameGradient then
                local gradient=nameGradient:Clone();gradient.Parent=rarityLabel
                rarityGradientBuckets[rarityKey][gradient]=true
            end

            local names=mutationNames(entry)
            local available=math.max(100,panel.Size.X.Offset-130)
            local widths,total={},0
            for i,name in ipairs(names) do widths[i]=mutationWidth(name,textService,available);total+=widths[i]+5 end
            local strip=D.make('Frame',{Name='MutationStrip',Position=UDim2.new(0,86,1,-29),Size=UDim2.new(1,-94,0,28),BackgroundTransparency=1,ClipsDescendants=true},row)
            local words=D.make('Frame',{Name='MutationWords',Position=UDim2.fromOffset(4,0),Size=UDim2.fromOffset(math.max(1,total),28),BackgroundTransparency=1},strip)
            D.make('UIScale',{Scale=math.min(1,available/math.max(1,total))},words)
            local x=0
            for i,name in ipairs(names) do mutationWord(words,name,UDim2.fromOffset(x,0),widths[i]);x+=widths[i]+5 end
            row.Size=UDim2.new(1,-12,0,compactCardHeight())
            local here=entry.isLocal or entry.jobId==game.JobId
            local join=D.make('TextButton',{Text=select(1,joinPresentation(entry)),Position=UDim2.new(1,-98,0,29),Size=UDim2.fromOffset(90,32),BackgroundColor3=(entry.full or entry.unavailable) and Color3.fromRGB(255,75,85) or here and Color3.fromRGB(86,90,100) or Color3.fromRGB(40,160,85),TextColor3=Color3.new(1,1,1),TextSize=13},row)
            card.join=join
            local joinCorner=join:FindFirstChildOfClass('UICorner')
            if joinCorner then joinCorner.CornerRadius=UDim.new(0,3) end
            join.Font=Enum.Font.FredokaOne
            styleRaisedButton(join)
            local caption=join:FindFirstChild('RaisedCaption')
            if caption then
                caption.Font=Enum.Font.FredokaOne;caption.TextScaled=true;caption.TextSize=20
                caption.TextStrokeTransparency=1
                caption.Position=UDim2.fromOffset(5,2);caption.Size=UDim2.new(1,-10,1,-4)
                D.make('UITextSizeConstraint',{MinTextSize=10,MaxTextSize=20},caption)
                D.make('UIStroke',{Color=Color3.new(0,0,0),Thickness=2},caption)
            end
            join.Active=not (entry.full or entry.unavailable)
            join.AutoButtonColor=not (entry.full or entry.unavailable)
            join.Selectable=not (entry.full or entry.unavailable)
            join.Activated:Connect(function()
                local entry=card.entry
                if not D.publicEntryAllowed(entry,(os.clock()+clockOffset)*1000) or entry.takenConfirmed or entry.unavailable or D.populationFull(entry) or randomBusy or os.clock()<joinRetryAt or entry.jobId==game.JobId then return end
                if (os.clock()+clockOffset)*1000>=entry.expiresAt then queryStatus='Report expired; refreshing'; feedAt=0; return end
                joining=true;joiningKey=entry.key;joinRetryAt=os.clock()+0.5
                local attempt={startedAt=os.clock(),replacedPending=D.joinAttempt~=nil,id=Http:GenerateGUID(false),jobId=entry.jobId,uid=entry.uid,placeId=entry.placeId,entry=entry}
                D.joinAttempt=attempt
                task.delay(14,function()
                    if not active or D.joinAttempt~=attempt then return end
                    D.testReloadQueued=false
                    D.finishJoin(attempt)
                    queueRender()
                    D.joinNotice(attempt.teleportStarted and 'Roblox teleport timed out. Try again.' or 'Join request timed out. Try again.')
                end)
                queryStatus='Joining '..entry.name
                updateCard(card,entry,card.row.LayoutOrder or 1)
                task.delay(0.5,queueRender)
                entry=card.entry
                if not active or D.joinAttempt~=attempt then return end
                if not D.publicEntryAllowed(entry,(os.clock()+clockOffset)*1000) or entry.takenConfirmed or entry.unavailable or D.populationFull(entry) then
                    D.finishJoin(attempt);updateCard(card,entry,card.row.LayoutOrder or 1);return
                end
                if (os.clock()+clockOffset)*1000>=entry.expiresAt then
                    D.finishJoin(attempt);feedAt=-math.huge;render();return
                end
                D.saveGuiBeforeTeleport()
                D.stopFarm()
                attempt.teleportStarted=true;attempt.failureDeadline=os.clock()+30
                D.lastTeleportAttempt=attempt
                if not active or D.joinAttempt~=attempt then return end
                print('[Tenshi JOIN] Requesting Roblox teleport')
                local ok,err=pcall(function() Teleports:TeleportToPlaceInstance(entry.placeId,entry.jobId,D.player) end)
                if not ok and D.joinAttempt==attempt then
                    D.lastTeleportAttempt=nil
                    D.testReloadQueued=false
                    if D.isFullFailure(nil,err) then D.noteFull(entry);queueRender() end
                    D.finishJoin(attempt);D.joinNotice('Roblox: '..tostring(err));queueRender()
                end
            end)
            end
            card.entry=entry
            updateCard(card,entry,i)
            card.row.LayoutOrder=i
            cardsByKey[entry.key]=card
            ageLabels[#ageLabels+1]={label=card.ageLabel,entry=entry}
            canvasHeight+=card.row.Size.Y.Offset+4
            if not checkpoint() then return end
        end
        list.CanvasSize=UDim2.fromOffset(0,canvasHeight)
        list.CanvasPosition=savedScroll
        list.Visible=true
    end
    render=function()
        if not active then return end
        if rendering then renderPending=true;return end
        rendering=true
        local ok,err=pcall(renderOnce)
        rendering=false
        if renderPending then renderPending=false;queueRender() end
        if not ok then list.Visible=true;error(err) end
    end
    requestScopeRender=function()
        -- Hide old-tab rows immediately; never expose remote JOINs as MY SERVER.
        list.Visible=false
        list.CanvasPosition=Vector2.new(0,0)
        queueRender()
    end
    refreshButton.Activated:Connect(function()
        if refreshing or not active then return end
        refreshing=true;refreshButton.Text='REFRESHING.'
        task.spawn(function()
            local ok,err=pcall(function()
                local deadline=os.clock()+12
                while active and networkBusy and os.clock()<deadline do task.wait(0.1) end
                if not active then return end
                if networkBusy then error('Network busy; try again') end
                if not othersOnly then
                    local loaded,message=refresh();if not loaded then error(message) end
                end
                lastRender=nil;render()
            end)
            refreshing=false
            if active then
                refreshButton.Text='REFRESH'
                queryStatus=ok and 'List refreshed' or ('Refresh failed: '..tostring(err))
            end
        end)
    end)
    do
        local Tweens=game:GetService('TweenService')
        local states={}
        local function attachButtonMotion(button)
            if not (button:IsA('TextButton') or button:IsA('ImageButton')) then return end
            if button.Name=='SettingsOverlay' or button.Name=='LauncherHitArea' or button:GetAttribute('TenshiButtonMotion') then return end
            button:SetAttribute('TenshiButtonMotion',true)
            local motion=D.make('UIScale',{Name='ButtonMotion',Scale=1},button)
            local state={button=button,motion=motion,base=button.Position,hover=false,input=nil,tween=nil,writing=false,alive=true}
            states[button]=state
            local function enabled() return button.Active~=false and button.Selectable~=false end
            local function center()
                if not state.alive or not button.Parent then return end
                local delta=motion.Scale-1
                local x,y=0.5-button.AnchorPoint.X,0.5-button.AnchorPoint.Y
                local size=button.Size
                local goal=UDim2.new(state.base.X.Scale-size.X.Scale*delta*x,state.base.X.Offset-size.X.Offset*delta*x,state.base.Y.Scale-size.Y.Scale*delta*y,state.base.Y.Offset-size.Y.Offset*delta*y)
                state.lastPosition=goal
                if button.Position==goal then return end
                state.writing=true
                button.Position=goal
                state.writing=false
            end
            local function update()
                if not state.alive then return end
                if state.tween then state.tween:Cancel();state.tween=nil end
                local target=1
                if enabled() then
                    if state.input then target=0.95
                    elseif state.hover then
                        local width=math.max(1,button.AbsoluteSize.X/math.max(0.01,motion.Scale))
                        target=math.min(1.06,1+5/width)
                    end
                else state.input=nil;state.hover=false end
                state.tween=Tweens:Create(motion,TweenInfo.new(state.input and 0.08 or 0.13,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=target})
                state.tween:Play()
            end
            state.update=update
            motion:GetPropertyChangedSignal('Scale'):Connect(center)
            button:GetPropertyChangedSignal('Position'):Connect(function()
                if not state.writing and button.Position~=state.lastPosition then state.base=button.Position;center() end
            end)
            button:GetPropertyChangedSignal('Size'):Connect(center)
            button:GetPropertyChangedSignal('AnchorPoint'):Connect(center)
            button:GetPropertyChangedSignal('Active'):Connect(update)
            button:GetPropertyChangedSignal('Selectable'):Connect(update)
            button.MouseEnter:Connect(function()
                if Input:GetLastInputType()==Enum.UserInputType.Touch then return end
                state.hover=true;update()
            end)
            button.MouseLeave:Connect(function() state.hover=false;update() end)
            button.SelectionGained:Connect(function() state.hover=true;update() end)
            button.SelectionLost:Connect(function() state.hover=false;update() end)
            button.InputBegan:Connect(function(input)
                if not enabled() then return end
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    if input.UserInputType==Enum.UserInputType.Touch then state.hover=false end
                    state.input=input;update()
                end
            end)
            button.Destroying:Connect(function()
                state.alive=false
                if state.tween then state.tween:Cancel() end
                states[button]=nil
            end)
        end
        local release=Input.InputEnded:Connect(function(input)
            for _,state in pairs(states) do
                if state.input and (state.input==input or state.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1) then
                    state.input=nil;state.update()
                end
            end
        end)
        for _,button in ipairs(panel:GetDescendants()) do attachButtonMotion(button) end
        local added=panel.DescendantAdded:Connect(function(button)
            if button:IsA('TextButton') or button:IsA('ImageButton') then
                task.defer(function() if active and button.Parent then attachButtonMotion(button) end end)
            end
        end)
        local hidden=panel:GetPropertyChangedSignal('Visible'):Connect(function()
            if panel.Visible then return end
            for _,state in pairs(states) do state.input=nil;state.hover=false;state.update() end
        end)
        D.gui.Destroying:Connect(function()
            release:Disconnect();added:Disconnect();hidden:Disconnect()
            for _,state in pairs(states) do
                state.alive=false;if state.tween then state.tween:Cancel() end
            end
            table.clear(states)
        end)
    end

    do
        local Tweens=game:GetService('TweenService')
        local hovered,moving,scheduled=false,false,false
        local lastMovement=0
        local tween
        local function paint()
            if tween then tween:Cancel() end
            local highlighted=hovered or moving
            tween=Tweens:Create(list,TweenInfo.new(0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                ScrollBarThickness=highlighted and 9 or 6,
                ScrollBarImageColor3=highlighted and Color3.fromRGB(200,205,220) or Color3.fromRGB(137,140,150),
                ScrollBarImageTransparency=highlighted and 0 or 0.18
            })
            tween:Play()
        end
        local function idle()
            if not active or not list.Parent then scheduled=false;return end
            if os.clock()-lastMovement<0.22 then task.delay(0.12,idle);return end
            scheduled=false;moving=false;paint()
        end
        local enter=list.MouseEnter:Connect(function()
            if Input:GetLastInputType()==Enum.UserInputType.Touch then return end
            hovered=true;paint()
        end)
        local leave=list.MouseLeave:Connect(function() hovered=false;paint() end)
        local scrolled=list:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
            lastMovement=os.clock()
            if not moving then moving=true;paint() end
            if not scheduled then scheduled=true;task.delay(0.24,idle) end
        end)
        local hidden=panel:GetPropertyChangedSignal('Visible'):Connect(function()
            if not panel.Visible then hovered=false;moving=false;paint() end
        end)
        D.gui.Destroying:Connect(function()
            enter:Disconnect();leave:Disconnect();scrolled:Disconnect();hidden:Disconnect()
            if tween then tween:Cancel() end
        end)
        paint()
    end

    fitFinder()
    panel.Visible=true
    local failed=Teleports.TeleportInitFailed:Connect(function(who,result,message,_,options)
        if who==D.player then
            local instance=options and options.ServerInstanceId
            local run=D.randomRun
            if run and run.target and (not instance or instance=='' or instance==run.target) then
                D.handleRandomFailure(run,run.target,result,message)
                return
            end
            local attempt=D.lastTeleportAttempt
            if not randomBusy then D.testReloadQueued=false end
            if attempt and os.clock()<attempt.failureDeadline and (instance==attempt.jobId or (not instance or instance=='') and not randomBusy and not attempt.replacedPending) then
                D.lastTeleportAttempt=nil
                if D.isFullFailure(result,message) then D.noteFull(attempt.entry) end
                D.finishJoin(attempt);queueRender()
                D.joinNotice('Roblox: '..tostring(message))
            elseif not attempt and not randomBusy then joining=false end
            queryStatus='Join failed: '..tostring(message)
        end
    end)
    D.gui.Destroying:Connect(function() active=false; failed:Disconnect();if localHighlight then localHighlight:Destroy() end end)
    task.spawn(function()
        while active do
            if featureConfig and not refreshing and (not PREMIUM_EDITION or viewerCode~='') and os.clock()-feedAt>=3 then
                local ok,loaded,message=pcall(refresh)
                if not ok or not loaded then
                    queryStatus='Finder: '..tostring(ok and message or loaded)
                    D.gui:SetAttribute('TenshiFeedStatus',queryStatus)
                else
                    D.gui:SetAttribute('TenshiFeedStatus','Updated')
                end
            end
            task.wait(1)
        end
    end)
    task.spawn(function()
        local lastReport=-math.huge
        local lastPeakSignature=nil
        while active do
            local ok,err=pcall(function()
                if networkBusy then return end
                if (not publicBroadcastConfig or os.clock()-configAt>60) and os.clock()>=(D.primaryConfigRetry or 0) then
                    D.primaryConfigRetry=os.clock()+5;loadConfig()
                end
                local peak=snapshot()
                local ids={}
                for i=1,math.min(4,#peak) do ids[#ids+1]=peak[i].uid end
                local meta=D.metadata()
                for _,record in ipairs(meta and meta.states or {}) do ids[#ids+1]=record.uid..':'..tostring(record.state) end
                ids[#ids+1]='players:'..tostring(#game:GetService('Players'):GetPlayers())
                table.sort(ids)
                local signature=table.concat(ids,';')
                if publicBroadcastConfig and os.clock()>=(D.primaryReportRetry or 0) and (os.clock()-lastReport>=broadcastInterval or (#peak>0 and signature~=lastPeakSignature)) then
                    D.primaryReportRetry=os.clock()+3
                    local success,message=report(3)
                    if success then lastPeakSignature=signature;lastReport=os.clock() end
                    reportStatus=message
                    if not success then warn('Tenshi broadcast: '..tostring(message)) end
                end
            end)
            if not ok then reportStatus='BCAST: '..tostring(err);queryStatus=tostring(err);warn('Tenshi broadcast: '..tostring(err)) end
            task.wait(1)
        end
    end)
    task.spawn(function()
        while active do
            status.Text=PREMIUM_EDITION and (tostring(reportStatus)..'\n'..tostring(queryStatus)) or (joining and 'Joining server…' or tostring(reportStatus))
            local cycle=cycleInfo()
            if cycle then
                local seconds=math.max(0,math.ceil(cycle.remaining))
                resetTimer.Text=cycle.running and string.format('RESET %02d:%02d',math.floor(seconds/60),seconds%60) or 'RESET PAUSED'
                resetTimer.TextColor3=cycle.running and seconds<=60 and Color3.fromRGB(255,85,85) or cycle.running and seconds<=150 and Color3.fromRGB(255,215,65) or Color3.fromRGB(230,245,255)
            else
                resetTimer.Text='RESET --:--'
                resetTimer.TextColor3=Color3.fromRGB(230,245,255)
            end
            sharingNotice.Visible=false
            local ok=pcall(render)
            if not ok then queryStatus='Unable to display finder feed' end
            updateSpawnAges(cycle)
            task.wait(1)
        end
    end)
end


local function run()
    local EggState=module('Client.EggState')
    local Assets=module('Data.Assets')
    local States=module('Shared.Types.AreaEggs').States
    local mutations,eggRecords
    pcall(function() mutations=module('Shared.Modules.Mutations') end)
    pcall(function() eggRecords=module('Shared.Util.EggRecords') end)
    assert(type(EggState.ReadFieldEggs)=='function','ReadFieldEggs unavailable')
    assert(type(Assets.Directory)=='table' and States and States.Slot~=nil,'Game schema changed')
    local latestEntries={}
    local latestMetadata=nil
    local scanCycle
    pcall(function() scanCycle=module('Shared.Util.AreaEggCycle') end)
    local function parseValue(text)
        local amount,suffix=tostring(text):gsub(',',''):match('^%s*%$?%s*(%d+%.?%d*)%s*(%a*)%s*$')
        local powers={['']=1,k=1e3,m=1e6,b=1e9,t=1e12,qa=1e15,qi=1e18}
        local factor=suffix and powers[suffix:lower()]
        if not amount or not factor then return nil end
        local value=tonumber(amount)*factor
        return valid(value) and value or nil
    end
    local function newCycleSlots()
        local cycle,slots,count=nil,{},0
        local seenCycle,previousCycle={},{}
        return function(entries,states,resetAt)
            if resetAt and resetAt~=cycle then
                if cycle then previousCycle,seenCycle=seenCycle,{} end
                cycle,slots,count=resetAt,{},0
            end
            local ranked,byUid,stateByUid={},{},{}
            for _,state in ipairs(states) do stateByUid[state.uid]=state.state;seenCycle[state.uid]=true end
            for _,entry in ipairs(entries) do
                local uid=tostring(entry.uid)
                byUid[uid]=entry
                if entry.rate and entry.rate>0 and stateByUid[uid]=='Slot' and not previousCycle[uid] then ranked[#ranked+1]=entry end
            end
            table.sort(ranked,function(a,b)
                if a.rate~=b.rate then return a.rate>b.rate end
                return tostring(a.uid)<tostring(b.uid)
            end)
            for _,entry in ipairs(ranked) do
                if count==4 then break end
                local uid=tostring(entry.uid)
                if not slots[uid] then slots[uid]={entry=entry,missing=0};count+=1 end
            end
            local reports,tracked,taken={},{},{}
            for uid,slot in pairs(slots) do
                local state=stateByUid[uid]
                if state=='Claimed' then slot.taken=true
                elseif state then slot.missing=0
                else slot.missing+=1;if slot.missing>=2 then slot.taken=true end end
                if byUid[uid] and byUid[uid].rate and not slot.taken then slot.entry=byUid[uid] end
                if slot.taken then
                    tracked[#tracked+1]={uid=uid,state='Claimed'}
                    taken[#taken+1]=slot.entry
                elseif state then
                    tracked[#tracked+1]={uid=uid,state=state}
                    if byUid[uid] then reports[#reports+1]=byUid[uid] end
                else
                    tracked[#tracked+1]={uid=uid,state='Unknown'}
                end
            end
            return reports,tracked,taken
        end
    end
    local selectCycleSlots=newCycleSlots()
    local reportEntries,takenEntries={},{}
    local lastScan=0
    createFinder({gui=gui,localPanel={Visible=false},player=player,make=make,label=label,entries=function() return os.clock()-lastScan<10 and latestEntries or {} end,metadata=function() return latestMetadata end,reportEntries=function() return reportEntries end,takenEntries=function() return takenEntries end,ready=function() return lastScan>0 and os.clock()-lastScan<10 end,parseValue=parseValue,money=money,stopFarm=function() end})
    while alive do
        local ok,err=pcall(function()
            local scanStartedClock=os.clock()
            local snapshot=EggState.ReadFieldEggs()
            assert(type(snapshot)=='table' and type(snapshot.Records)=='table','Field snapshot unavailable')
            local eggs={}
            local fieldStates={}
            local allStates={}
            local scanAt=workspace:GetServerTimeNow()*1000
            local resetAt
            if scanCycle then pcall(function() if scanCycle.IsRunning() then resetAt=scanCycle.NextResetTime(scanAt/1000)*1000 end end) end
            for recordKey,record in pairs(snapshot.Records) do
                local stateUid=tostring(record.Uid or recordKey)
                allStates[stateUid]=record.State
                local area=tostring(record.AreaId):lower():gsub("[^%a]", "")
                local broadcastEligible=area~="forest" and area~="lake" and area~="desert" and area~="volcano" and area~="volcanox"
                local asset=Assets.Directory[record.AssetCategory]
                if excludedFinderEgg(record.AssetCategory) or excludedFinderEgg(asset and asset.DisplayName) then continue end
                local rarity=asset and asset.Rarity
                if not rarity or not finderRarityRank(rarity.DisplayName or rarity._id) then continue end
                fieldStates[#fieldStates+1]={uid=tostring(record.Uid or recordKey),state=record.State}
                if record.State==States.Slot or record.State==States.Carried or record.State==States.Dropped or record.State==States.GuardCarried then
                    local uid=record.Uid or recordKey
                    local model=modelFor(uid)
                    local scale=numberField(record,{'AssetScale'})
                    local weight
                    if eggRecords and type(eggRecords.WeightKg)=='function' then
                        local good,result=pcall(eggRecords.WeightKg,record)
                        if good and valid(result) then weight=result end
                    end
                    local rate=displayedRate(model)
                    local estimated=false
                    if not rate then
                        rate=computedRate(asset.EarningRate,scale,record.Mutations or {},mutations)
                        estimated=rate~=nil
                    end
                    local traits,traitsKnown=readTraitNames(record)
                    table.insert(eggs,{key='field:'..tostring(uid),uid=uid,broadcastEligible=broadcastEligible,traitsKnown=traitsKnown,category=record.AssetCategory,areaKey=record.AreaId,worldPos=typeof(record.BottomCFrame)=='CFrame' and record.BottomCFrame.Position or nil,area=tostring(record.AreaId)..' | Mut: '..(#traits>0 and table.concat(traits,', ') or traitsKnown and 'None' or 'UNKNOWN'),model=model,icon=asset.Icon,name=asset.DisplayName or record.AssetCategory or 'Unknown',rarity=rarity.DisplayName or rarity._id or 'Unknown',tier=finderRarityRank(rarity.DisplayName or rarity._id),color=typeof(rarity.Color)=='Color3' and rarity.Color or Color3.new(1,1,1),scale=scale,weight=weight,rate=rate,estimated=estimated})
                end
            end
            for _,entry in ipairs(eggs) do
                entry.mutationText=tostring(entry.area or ''):match('Mut:%s*(.*)') or ''
            end
            local broadcastEggs={}
            for _,egg in ipairs(eggs) do
                if egg.broadcastEligible then broadcastEggs[#broadcastEggs+1]=egg end
            end
            reportEntries,fieldStates,takenEntries=selectCycleSlots(broadcastEggs,fieldStates,resetAt)
            for _,record in ipairs(fieldStates) do allStates[record.uid]=record.state end
            local completeStates={}
            for uid,state in pairs(allStates) do completeStates[#completeStates+1]={uid=uid,state=state} end
            latestEntries=eggs
            latestMetadata={states=completeStates,resetAt=resetAt,scanAt=scanAt,scanClock=scanStartedClock}
            lastScan=os.clock()
        end)
        if not ok then warn('NYX Finder scan:',err) end
        task.wait(2)
    end
end
 task.spawn(function()
    local ok,err=pcall(run)
    if not ok then warn('NYX Finder startup:',err) end
end)
