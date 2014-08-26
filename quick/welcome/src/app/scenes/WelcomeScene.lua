local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

local WelcomeScene = class("WelcomeScene", function()
    return display.newScene("WelcomeScene")
end)

function string:spliteBySep(sep)
    local sep, fields = sep or device.directorySeparator, {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function WelcomeScene:ctor()
    local bg = cc.LayerColor:create(cc.c4b(56, 56, 56, 255))
    self:addChild(bg)

    self:createTitleBar(bg)
    self:createLogo(bg)
    self:createTabWidget(bg)
    self:createCopyright(bg)
end

local function stripPath(path, maxLen)
    local l = string.len(path)
    if l <= maxLen then
        return path
    else
        local arr = string.split(path, device.directorySeparator)
        -- return arr[#arr - 1]
        return "... " .. string.sub(path, l - maxLen)
    end
end

function WelcomeScene:createLogo(node)
    display.newSprite("#Logo.png")
        :align(display.LEFT_TOP, display.left + 48, display.top - 24)
        :addTo(node)

    local label = ui.newTTFLabel({
        text = "quick-cocos2d-x",
        size = 38,
        color = display.COLOR_WHITE,
        x = 140,
        y = display.top - 55,
        align = ui.TEXT_ALIGN_LEFT,
        })
    node:addChild(label)


    label = ui.newTTFLabel({
        text = "v3.2 beta1",
        size = 14,
        color = cc.c3b(243,156,18),
        x = 140 + label:getContentSize().width,
        y = display.top - 36,
        align = ui.TEXT_ALIGN_LEFT,
        })
    node:addChild(label)
end

function WelcomeScene:createButtons(node)
    local top = display.top - 140

    local buttonWidth = 170
    local buttonHeight = 48
    local padding = 120
    local images = {
        normal = "#ButtonNormal.png",
        pressed = "#ButtonPressed.png",
        disabled = "#ButtonDisabled.png",
    }

    cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(buttonWidth, buttonHeight)
    :setButtonLabel("normal", ui.newTTFLabel({
            text = "打开",
            size = 18
        }))
    :pos(display.width-padding, top)
    :addTo(node)
    :onButtonClicked(function()
        local projectConfig = ProjectConfig:new()
        local argumentVector = vector_string_:new_local()
        if self.localProjectListView_.currentIndex and self.localProjectListView_.currentIndex > 0 then
            local arguments = cc.player.settings.PLAYER_OPEN_RECENTS[self.localProjectListView_.currentIndex].args
            for _,v in ipairs(arguments) do
                argumentVector:push_back(v)
            end
            projectConfig:parseCommandLine(argumentVector)
            PlayerProtocol:getInstance():openNewPlayerWithProjectConfig(projectConfig)
        end
    end)

    top = top - 68
    cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(buttonWidth, buttonHeight)
    :setButtonLabel("normal", ui.newTTFLabel({
            text = "打包",
            size = 18
        }))
    :pos(display.width-padding, top)
    :addTo(node)
    :setButtonEnabled(false)
    :onButtonClicked(function()
        print("[[TODO]]")
    end)

    top = top - 68  
    cc.ui.UIPushButton.new({normal="#RedButtonNormal.png", pressed="#RedButtonPressed.png", disabled = "#ButtonDisabled.png",}, {scale9 = true})
    :setButtonSize(buttonWidth, buttonHeight)
    :setButtonLabel("normal", ui.newTTFLabel({
            text = "删除",
            size = 18
        }))
    :pos(display.width-padding, top)
    :addTo(node)
    :onButtonClicked(function()
        if self.localProjectListView_.currentItem then
            self.localProjectListView_:removeItem(self.localProjectListView_.currentItem, true)
            self.localProjectListView_.currentItem = nil

            table.remove(cc.player.settings.PLAYER_OPEN_RECENTS, self.localProjectListView_.currentIndex)
            cc.player:saveSetting()
        end

        self.localProjectListView_.currentIndex = 0
        self.localProjectListView_.localProjectsPreSelectedItem_ = nil
    end)


    top = top - 180
    cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(buttonWidth, buttonHeight)
    :setButtonLabel("normal", ui.newTTFLabel({
            text = "新建项目",
            size = 18
        }))
    :pos(display.width-padding, top)
    :addTo(node)
    :onButtonClicked(function()
        require("app.scenes.CreateProjectUI"):new()
        :addTo(self)
    end)

    top = top - 68
    cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(buttonWidth, buttonHeight)
    :setButtonLabel("normal", ui.newTTFLabel({
            text = "导入项目",
            size = 18
        }))
    :pos(display.width-padding, top)
    :addTo(node)
    :onButtonClicked(function()
        require("app.scenes.OpenProjectUI"):new()
        :addTo(self)
    end)
end

function WelcomeScene:createListItem(icon, title, path)
    local container = display.newNode()
    container:setContentSize(40*16, 90) 
    container.path = path

    -- background
    local bgItem = cc.ui.UIImage.new("#ItemSelected.png", {scale9 = true})
    bgItem:setLayoutSize(40*16-20, 80)
    bgItem:addTo(container)
    bgItem:pos(10, 0)
    bgItem:setVisible(false)
    container.bgItem_ = bgItem

    -- icon
    cc.ui.UIImage.new(icon, {scale9 = true})
    :setLayoutSize(48, 48)
    :pos(10, 20)
    :addTo(container)

    -- title
    title = title:spliteBySep('/')
    local titleLabel = cc.ui.UILabel.new({
            text = title[#title],
            size = 28,
            font = "Monaco",
            align = cc.ui.TEXT_ALIGN_LEFT,
            color = display.COLOR_WHITE})
    titleLabel:pos(70, 50)
    titleLabel:addTo(container)

    -- path
    cc.ui.UILabel.new({
        text = stripPath(path, 80),
        size = 12,
        font = "Monaco",
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = display.COLOR_WHITE,
        })
    :pos(70,15)
    :addTo(container)

    display.newLine(
        {{70, 1}, {40*16 -10, 1}},
        {borderColor = cc.c4f(0, 0, 0, 1.0)})
    :addTo(container)
    return container 
end


function WelcomeScene:createTabWidget(node)
    self.tabWidget = {}
    self.tabWidget.headers_ = {}
    self.tabWidget.widgets_ = {}

    self:createOpenRecents(cc.player.settings.PLAYER_OPEN_RECENTS, node)
    self:createButtons(node)
    self:createSamples(node)
    self:createHeaders(node)
end

function WelcomeScene:createOpenRecents(recents, node)
    local localProjectListView = cc.ui.UIListView.new {
        bg = "#TabButtonSelected.png",
        viewRect = cc.rect(40,92, 40*17, 40*9+28),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        scrollbarImgV = "#ScrollBarHandler.png"}
        :onTouch(function(event)
            if not event.listView:isItemInViewRect(event.itemPos) then
                return
            end
            
            local listView = event.listView
            if "clicked" == event.name then
                if listView.localProjectsPreSelectedItem_ then
                    listView.localProjectsPreSelectedItem_:setVisible(false)
                end

               local selectedItemBg = event.item:getContent().bgItem_
                if selectedItemBg then
                    selectedItemBg:setVisible(true)
                end
                listView.localProjectsPreSelectedItem_ = selectedItemBg
                listView.currentItem = event.item
                listView.currentIndex = event.itemPos
            end -- "clicked" end
            end)
        :addTo(node)

    for i,v in ipairs(recents) do
        local container = self:createListItem("#Logo.png", v.title, v.title)

        local item = localProjectListView:newItem()
        item:addContent(container)
        item:setItemSize(40*16, 96)

        localProjectListView:addItem(item)
    end
    localProjectListView:reload()


    self.tabWidget.widgets_[#self.tabWidget.widgets_ +1] = localProjectListView
    self.localProjectListView_ = localProjectListView
    
end

function WelcomeScene:createHeaders(node)
    local left = display.left + 130
    local top  = display.top - 136

    local buttonWidth = 150
    local buttonHeight = 48
    local images = {
        on = "#TabButtonSelected.png",
        off = "#TabButtonNormal.png",
    }

    local headers = {{title="我的项目",widget=self.localProjectListView_}, {title="示例",widget=self.lvGrid}, {title="帮助"}}
    for i,v in ipairs(headers) do

        local header = 
        cc.ui.UICheckBoxButton.new(images, {scale9 = true})
        :setButtonLabel(cc.ui.UILabel.new({text = v.title, size = 18}))
        :setButtonSize(buttonWidth, buttonHeight)
        :setButtonLabelAlignment(display.CENTER)
        :pos(left, top)

        header.index = i
        header.widget = v.widget
        header:onButtonClicked(function()
            if self.tabWidget then

                self.tabWidget.currentWidget.header:setButtonSelected(false)
                if self.tabWidget.currentWidget.widget then 
                    self.tabWidget.currentWidget.widget:setVisible(false)
                end

                self.tabWidget.currentWidget = {
                    index = header.index,
                    header = self.tabWidget.headers_[header.index],
                    widget = self.tabWidget.widgets_[header.index],
                }

                self.tabWidget.currentWidget.header:setButtonSelected(true)
                if self.tabWidget.currentWidget.widget then 
                    if self.tabWidget.currentWidget.widget.hasItemLoaded == false then
                        self:loadSampleItems()
                        self.tabWidget.currentWidget.widget.hasItemLoaded = true
                    end
                    self.tabWidget.currentWidget.widget:setVisible(true)
                end
            end

        end)

        node:addChild(header, 1)
        self.tabWidget.headers_[#self.tabWidget.headers_+1] = header
        left = left + 170
    end


    self.tabWidget.currentWidget = {index = 1, 
                                          header = self.tabWidget.headers_[1], 
                                          widget = self.tabWidget.widgets_[1]}
    self.tabWidget.currentWidget.header:setButtonSelected(true)
end

function WelcomeScene:createCopyright(node)
    local bg = cc.LayerColor:create(cc.c4b(83, 83, 83, 255))
    bg:setContentSize(cc.size(display.width, 48))
    node:addChild(bg)

    local label = ui.newTTFLabel({
        text = "Copyright (c) 2012-2014 chukong-inc.com, Powered by quick-cocos2d-x.",
        size = 17,
        color = cc.c3b(128, 128, 128),
        x = 48,
        y = display.bottom + 24,
        align = ui.TEXT_ALIGN_LEFT,
    })
    node:addChild(label)

    label = ui.newTTFLabel({
        text = "Code Less, Play More",
        size = 17,
        color = cc.c3b(128, 128, 128),
        x = display.width - 96,
        y = display.bottom + 24,
        align = ui.TEXT_ALIGN_RIGHT,
        })
    node:addChild(label)
end

function WelcomeScene:createTitleBar(node)
    local bar = display.newNode()
    bar:pos(0, display.height - 28)
    node:addChild(bar)

    cc.ui.UIPushButton.new("#SettingsIcon.png", {scale9 = true})
    :pos(display.width-48, 0)
    :addTo(bar)
    :onButtonClicked(function()
        print("open settings")
    end)

    cc.ui.UILabel.new({
        text = "0",
        align = ui.TEXT_ALIGN_LEFT,
        color = cc.c3b(255,255,255,255),
        size = 18,
    })
    :align(display.LEFT_TOP, display.width-80, 10)
    :addTo(bar)

    cc.ui.UIPushButton.new("#MessagesIcon.png", {scale9 = true})
    :pos(display.width-48*2, 0)
    :addTo(bar)
    :onButtonClicked(function()
        print("show message here")
    end)

    cc.ui.UILabel.new({
        text = stripPath("<user>", 9),
        align = ui.TEXT_ALIGN_LEFT,
        color = cc.c3b(255,255,255,255),
        size = 18,
    })
    :align(display.LEFT_TOP, display.width-170, 10)
    :addTo(bar)

    cc.ui.UIPushButton.new("#UserIcon.png", {scale9 = true})
    :pos(display.width-48*4, 0)
    :addTo(bar)
    :onButtonClicked(function()
        print("user icon")
    end)
end

function WelcomeScene:createSamples(node)
    self.samples     = dofile(cc.player.quickRootPath .. "quick/samples/samples.lua")
    self.lvGrid = cc.ui.UIListView.new {
        bg = "#TabButtonSelected.png",
        viewRect = cc.rect(40,92, 40*17, 40*9+28),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        scrollbarImgV = "#ScrollBarHandler.png"}
    
    self.lvGrid:onTouch(function(event)
        if not event.listView:isItemInViewRect(event.itemPos) then
            return
        end
        
        local listView = event.listView
        if "clicked" == event.name then
            self.lvGrid.currentItem = event.item
        end
    end)


    self.lvGrid:setTouchSwallowEnabled(false)
    self.lvGrid:setVisible(false)
    self.lvGrid:addTo(node)
    self.lvGrid.hasItemLoaded = false
    self.tabWidget.widgets_[#self.tabWidget.widgets_ +1] = self.lvGrid
end

function WelcomeScene:loadSampleItems()
    for i=1,#self.samples,3 do
        local item = self.lvGrid:newItem()
        local content = display.newNode()

        local left = 20
        local lenght = i + 2
        if lenght > #self.samples then lenght = #self.samples end
        for k=i,lenght do
            local sample = self.samples[k]

            self:createOneSampleUI(sample, item)
                :addTo(content)
                :pos(left, 0)

            left = left + 220
        end

        content:setContentSize(40*17, 190)
        item:addContent(content)
        item:setItemSize(40*17, 190)
        self.lvGrid:addItem(item)
    end
    self.lvGrid:reload()
end

function WelcomeScene:createOneSampleUI(sample, item)
    local node = display.newNode()

    self:createDemoTitle(sample)
        :addTo(node)
    
    self:createDemoDescription(sample)
        :addTo(node)

    local button = self:createDemoButton(sample)
    button.listItem = item
    
    button:addTo(node)

    return node
end

function WelcomeScene:createDemoTitle(sample)
    local label = ui.newTTFLabel({
        text = sample.title,
        align = ui.TEXT_ALIGNMENT_CENTER,
        color = cc.c3b(144,144,144),
        size = 14,
        font = "Monaco",
    })
    label:setAnchorPoint(0.5, 0.5)
    label:setPosition(100, 160)
    return label
end

function WelcomeScene:createDemoDescription(sample)
    local title =  sample.description
    local color = cc.c3b(50,144,144)
    
    local sampleAbsPath = cc.player.quickRootPath .. "quick/" .. sample.path
    if not cc.FileUtils:getInstance():isDirectoryExist(sampleAbsPath) then
        title = title .. " (unfinished)"
        color = cc.c3b(255,0,0)
    end

    local label = ui.newTTFLabel({
        text = title,
        align = ui.TEXT_ALIGNMENT_CENTER,
        color = color,
        size = 12,
    })
    label:setAnchorPoint(0.5, 0.5)
    label:setPosition(100, 150)
    return label
end

function WelcomeScene:createDemoButton(sample)
    local demoImage = sample.image or "#ItemSelected.png"
    local button = cc.ui.UIPushButton.new(demoImage, {scale9 = true})
    button.isTouchMoved_ = false
    button:setTouchSwallowEnabled(false)
    button:pos(100, 65)
    button:setButtonSize(188, 130)
    button:addNodeEventListener(cc.NODE_TOUCH_EVENT, function ( event )
            if event.name == "began" then
                return true

            elseif event.name == "moved" then
                button.isTouchMoved_ = true

            elseif event.name == "ended" then
                if button.isTouchMoved_ == false then
                    self:openProjectWithPath(sample.path)
                end
                button.isTouchMoved_ = false
            end
        end)
    
    return button
end

function WelcomeScene:openProjectWithPath(path)
    local configPath = cc.player.quickRootPath .. "quick/" .. path .. "/src/config.lua"
    local projectConfig = ProjectConfig:new()
    projectConfig:resetToWelcome()
    projectConfig:setProjectDir(cc.player.quickRootPath .. "quick/" .. path)

    if cc.FileUtils:getInstance():isFileExist(configPath) then
        local data = ""
        for line in io.lines(configPath) do
            if string.find(line, "CONFIG_SCREEN_WIDTH") then
                data = data .. line .. ',\n'
            elseif string.find(line, "CONFIG_SCREEN_HEIGHT") then
                data = data .. line .. ',\n'
            elseif string.find(line, "CONFIG_SCREEN_ORIENTATION") then
                data = data .. line .. ',\n'
            end
        end

        local config = assert(loadstring("local settings = {" .. data .. "} return settings"))()

        local with = tonumber(config.CONFIG_SCREEN_WIDTH)
        local height = tonumber(config.CONFIG_SCREEN_HEIGHT)
        projectConfig:setProjectDir(cc.player.quickRootPath .. "quick/" .. path)
        projectConfig:setFrameSize(with, height)

        -- screen direction
        if config.CONFIG_SCREEN_ORIENTATION == "portrait" then
            projectConfig:changeFrameOrientationToPortait()
        else
            projectConfig:changeFrameOrientationToLandscape()
        end
    end
    PlayerProtocol:getInstance():openNewPlayerWithProjectConfig(projectConfig)
end


return WelcomeScene
