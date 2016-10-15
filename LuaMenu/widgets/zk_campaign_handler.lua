--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Campaign Handler ZK",
		desc      = "Tells epic sagas of good versus evil",
		author    = "KingRaptor",
		date      = "2016.07.05",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local CAMPAIGN_DIR = "campaign/"

local STARMAP_WINDOW_WIDTH = 1280
local STARMAP_WINDOW_HEIGHT = 768
local PLANET_IMAGE_SIZE = 259
local PLANET_BACKGROUND_SIZE = 1280
local CAMPAIGN_SELECTOR_BUTTON_HEIGHT = 96
local SAVEGAME_BUTTON_HEIGHT = 128
local OUTLINE_COLOR = {0.54,0.72,1,0.3}
local CODEX_BUTTON_FONT_SIZE = 14
local SAVE_DIR = "saves/campaign/"
local MAX_SAVES = 999
local AUTOSAVE_ID = "auto"
local AUTOSAVE_FILENAME = "autosave"
local RESULTS_FILE_PATH = "cache/mission_results.lua"
--------------------------------------------------------------------------------
-- Chili elements
--------------------------------------------------------------------------------
local Chili
local Window
local Panel
local StackPanel
local ScrollPanel
local Label
local Button

-- chili elements
local window
local screens = {}	-- main, newGame, save, load, intermission, codex
local currentScreenID = "main"
local lastScreenID = "main"

local startButton
local newGameCampaignScroll
local newGameCampaignButtons = {}
local newGameCampaignDetails = {}	-- panel, stackPanel, titleLabel, authorLabel, versionLabel, lengthLabel, descTextBox
local intermissionButtonCodex
local saveScroll, loadScroll, saveDescEdit
local saveLoadControls = {}	-- {id, container, titleLabel, descTextBox, image (someday), isNew}
local codexText, codexImage, codexTree, codexTreeScroll
local codexTreeControls = {}	-- {[entry ID] = Button}
local starmapWindow, starmapBackgroundHolder, starmapBackground, starmapBackground2, starmapPlanetImage, starmapInfoPanel

local timer = Spring.GetTimer()
local starmapAnimation = nil

-- mission launcher variables
local runningMission = false
local missionCompletionFunc = nil	-- function
local missionArchive = nil
local requiredMap = nil

--------------------------------------------------------------------------------
-- data
--------------------------------------------------------------------------------
-- this stores anything that goes into a save file
local gamedata = {
	chapterTitle = "",
	--[[
	campaignID = nil
	vnStory = nil
	nextMissionScript = nil
	chapterTitle = ""
	]]
	mapEnabled = false,
	completedMissions = {},
	unlockedScenes = {},
	codexUnlocked = {},
	codexRead = {},
	vars = {},
}

local campaignDefs = {}	-- {name, author, image, definition, starting function call}
local campaignDefsByID = {}
local currentCampaignID = nil

-- loaded when campaign is loaded
local planetDefs = {}
local planetDefsByID = {}
local missionDefs = {}
local codexEntries = {}

local saves = {}
local savesOrdered = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Makes a control grey for disabled, or whitish for enabled
local function SetControlGreyout(control, state)
	if state then
		control.backgroundColor = {0.4, 0.4, 0.4, 1}
		control.font.color = {0.4, 0.4, 0.4, 1}
		control:Invalidate()
	else
		control.backgroundColor = {.8,.8,.8,1}
		control.font.color = nil
		control:Invalidate()
	end
end

local function WriteDate(dateTable)
	return string.format("%02d/%02d/%04d", dateTable.day, dateTable.month, dateTable.year)
	.. " " .. string.format("%02d:%02d:%02d", dateTable.hour, dateTable.min, dateTable.sec)
end

local function ResetGamedata()
	gamedata = {
		chapterTitle = "",
		mapEnabled = false,
		completedMissions = {},
		unlockedScenes = {},
		codexUnlocked = {},
		codexRead = {},
		vars = {},
	}
	currentCampaignID = nil
	planetDefs = {}
	planetDefsByID = {}
	missionDefs = {}
	codexEntries = {}
	
	SetControlGreyout(startButton, true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function IsCodexEntryVisible(id)
	return gamedata.codexUnlocked[id] or codexEntries[id].alwaysUnlocked
end

-- Makes the codex button in intermission screen have a blue textshadow if any entries are unread
-- removes the shadow if not
local function UpdateCodexButtonState(unread)
	if unread == nil then
		unread = false
		for id, entry in pairs(codexEntries) do
			if IsCodexEntryVisible(id) then
				if not gamedata.codexRead[id] then
					unread = true
					break
				end
			end
		end
	end
	intermissionButtonCodex.font.shadow = unread,
	intermissionButtonCodex:Invalidate()
end

-- This happens when a button for a codex entry is clicked
-- It removes the "unread" blue shadow from the text, and writes the entry contents to the text box
local function UpdateCodexEntry(entryID)
	if not gamedata.codexRead[entryID] then
		if codexTreeControls[entryID] then
			local button = codexTreeControls[entryID]
			--button.font.outline = false
			button.font.shadow = false
			--button.font.size = CODEX_BUTTON_FONT_SIZE
			button:Invalidate()
		end
	end
	gamedata.codexRead[entryID] = true
	local entry = codexEntries[entryID]
	codexText:SetText(entry.text)
end

local function UnlockCodexEntry(entryID)
	gamedata.codexUnlocked[entryID] = true
	if codexEntries[entryID] then	-- don't mark codex button as having unread if the entry we just unlocked doesn't actually exist
		UpdateCodexButtonState(true)
	end
end

local function SortCodexEntries(a, b)
	local entryA = codexEntries[a]
	local entryB = codexEntries[b]
	if (not entryA) or (not entryB) then
		return false
	end
	local aKey = entryA.sortkey or entryA.name
	local bKey = entryB.sortkey or entryB.name
	aKey = string.lower(aKey)
	bKey = string.lower(bKey)
	return aKey < bKey
end

local function LoadCodexEntries()
	-- list all categories and which entries they have
	local nodes = {}
	local categories = {}
	local categoriesOrdered = {}
	for id, entry in pairs(codexEntries) do
		if IsCodexEntryVisible(id) then
			categories[entry.category] = categories[entry.category] or {}
			local cat = categories[entry.category]
			cat[#cat + 1] = id
		end
	end
	
	-- sort categories
	for catID in pairs(categories) do
		categoriesOrdered[#categoriesOrdered + 1] = catID
	end
	table.sort(categoriesOrdered)
	
	-- make tree view nodes
	for i=1,#categoriesOrdered do
		local catID = categoriesOrdered[i]
		local cat = categories[catID]
		table.sort(cat, SortCodexEntries)
		local node = {catID, {}}
		local subnode = node[2]
		for j=1,#cat do
			local entryID = cat[j]
			local entry = codexEntries[entryID]
			--local unlocked = gamedata.codexUnlocked[entryID]
			local read = gamedata.codexRead[entryID]
			local button = Button:New{
				caption = entry.name,
				backgroundColor = {0,0,0,0},
				borderColor = {0,0,0,0},
				OnClick = { function()
					UpdateCodexEntry(entryID)
				end},
				font = {
					size = CODEX_BUTTON_FONT_SIZE,	-- - (read and 0 or 1),
					shadow = (read ~= true),
					--outline = (read ~= true),
					outlineWidth = 6,
					outlineHeight = 6,
					outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
					autoOutlineColor = false,
				}
			}
			codexTreeControls[entryID] = button
			subnode[#subnode + 1] = button
			--Spring.Echo(catID, entry.name)
		end
		nodes[#nodes + 1] = node
	end
	
	-- make treeview
	if codexTree then
		codexTree:Dispose()	
	end
	codexTree = Chili.TreeView:New{
		parent = codexTreeScroll,
		name = 'chobby_campaign_codexTree',
		nodes = nodes,	--{"wtf", "lololol", {"omg"}},
		font = {size = CODEX_BUTTON_FONT_SIZE}
	}
	UpdateCodexButtonState()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Called on Initialize
local function LoadCampaignDefs()
	local success, err = pcall(function()
		local subdirs = VFS.SubDirs(CAMPAIGN_DIR)
		for i,subdir in pairs(subdirs) do
			local success2, err2 = pcall(function()
				if VFS.FileExists(subdir .. "campaigninfo.lua") then
					local def = VFS.Include(subdir .. "campaigninfo.lua")
					def.dir = subdir
					def.vnDir = subdir .. (def.vnDir or 'vn')
					campaignDefs[#campaignDefs+1] = def
					campaignDefsByID[def.id] = def
				end
			end)
			if (not success2) then
				Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading campaign defs: " .. err2)
			end
		end
		table.sort(campaignDefs, function(a, b) return (a.order or 100) < (b.order or 100) end) 
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading campaign defs: " .. err)
	end
end

-- This is called when a new game is started or a save is loaded
local function LoadCampaign(campaignID)
	local def = campaignDefsByID[campaignID]
	local success, err = pcall(function()
		local planetDefPath = def.dir .. "planetdefs.lua"
		local missionDefPath = def.dir .. "missiondefs.lua"
		local codexDefPath = def.dir .. "codex.lua"
		planetDefs = VFS.FileExists(planetDefPath) and VFS.Include(planetDefPath) or {}
		missionDefs = VFS.FileExists(missionDefPath) and VFS.Include(missionDefPath) or {}
		codexEntries = VFS.FileExists(codexDefPath) and VFS.Include(codexDefPath) or {}
		for i=1,#planetDefs do
			planetDefsByID[planetDefs[i].id] = planetDefs[i]	
		end
		
		if def.startFunction then
			def.startFunction()
		end
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading campaign " .. campaignID .. ": " .. err)
	end
end

-- Sets the next Visual Novel script to be played on clicking the Next Episode button in intermission
local function SetNextMissionScript(script)
	gamedata.nextMissionScript = script
end

-- Tells Visual Novel widget to load a story
local function SetVNStory(story, dir)
	if (not story) or story == "" then
		return
	end
	dir = dir or campaignDefsByID[currentCampaignID].vnDir
	gamedata.vnStory = story
	WG.VisualNovel.LoadStory(story, dir)
end

-- chapter titles are visible on save file
local function SetChapterTitle(title)
	gamedata.chapterTitle = title
end

local function CleanupAfterMission()
	runningMission = false
	missionCompletionFunc = nil
	if missionArchive then
		VFS.UnmapArchive(missionArchive)
		missionArchive = nil	
	end
end

local function GetMissionStartscriptString(missionID)
	local dir = campaignDefsByID[currentCampaignID].dir
	local startscript = missionDefs[missionID].startscript
	startscript = dir .. startscript
	local scriptString = VFS.LoadFile(startscript)
	return scriptString
end

local function GetMapNameFromStartscript(startscript)
	return string.match(startscript, "MapName%s?=%s?(.-);")
end

-- Checks if we have the map specified in the mission's startscript, if not download it
local function GetMapForMissionIfNeeded(missionID, startscriptStr)
	if not startscriptStr then
		startscriptStr = GetMissionStartscriptString(missionID)
	end
	local map = GetMapNameFromStartscript(startscriptStr)
	if not VFS.HasArchive(map) then
		VFS.DownloadArchive(map, "map")
		requiredMap = map
		return map
	end
	return nil
end

local function LaunchMission(missionID, func)
	local success, err = pcall(function()
		local dir = campaignDefsByID[currentCampaignID].dir
		local startscript = missionDefs[missionID].startscript
		startscript = dir .. startscript
		local scriptString = VFS.LoadFile(startscript)
		--missionArchive = dir .. missionDefs[missionName].archive
		--VFS.MapArchive(missionArchive)
		
		-- check for map
		local needMap = GetMapForMissionIfNeeded(missionID, scriptString)
		if needMap then
			WG.VisualNovel.scriptFunctions.Exit()
			WG.Chobby.InformationPopup("You do not have the map " .. needMap .. " required for this mission. It will now be downloaded.")
			return
		end
		
		-- TODO: might want to edit startscript before we run Spring with it
		WG.LibLobby.localLobby:StartGameFromString(scriptString)
		runningMission = true
		missionCompletionFunc = func
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error launching mission: " .. err)
	end
end

--------------------------------------------------------------------------------
-- Savegame utlity functions
--------------------------------------------------------------------------------
-- FIXME: currently unused as it doesn't seem to give the correct order
local function SortSavesByDate(a, b)
	if a == nil or b == nil then
		return false
	end
	--Spring.Echo(a.id, b.id, a.date.hour, b.date.hour, a.date.hour>b.date.hour)
	if a.id == AUTOSAVE_ID then
		return true
	elseif b.id == AUTOSAVE_ID then
		return false
	end
	
	if a.date.year > b.date.year then return true end
	if a.date.yday > b.date.yday then return true end
	if a.date.hour > b.date.hour then return true end
	if a.date.min > b.date.min then return true end
	if a.date.sec > b.date.sec then return true end
	return false
end

-- Returns the data stored in a save file
local function GetSave(filename)
	local ret = nil
	local success, err = pcall(function()
		local saveData = VFS.Include(filename)
		local campaignDef = campaignDefsByID[saveData.campaignID]
		--if (campaignDef) then
			ret = saveData
		--end
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error getting saves: " .. err)
	else
		return ret
	end
end

-- Loads the list of save files and their contents
local function GetSaves()
	Spring.CreateDir(SAVE_DIR)
	saves = {}
	savesOrdered = {}
	local savefiles = VFS.DirList(SAVE_DIR, "save*.lua")
	for i=1,#savefiles do
		local savefile = savefiles[i]
		local saveData = GetSave(savefile)
		if saveData then
			saveData.id = saveData.id or i
			saves[saveData.id] = saveData
			savesOrdered[#savesOrdered + 1] = saveData
		end
	end
	if VFS.FileExists(SAVE_DIR .. AUTOSAVE_FILENAME .. ".lua") then
		local saveData = GetSave(SAVE_DIR .. AUTOSAVE_FILENAME .. ".lua")
		if saveData then
			saveData.id = AUTOSAVE_ID
			saves[saveData.id] = saveData
			savesOrdered[#savesOrdered + 1] = saveData
		end
	end
	--table.sort(savesOrdered, SortSavesByDate)
end

-- e.g. if save slots 1, 2, 5, and 7 are used, return 3
local function FindFirstEmptySaveSlot()
	local start = #saves
	if start == 0 then start = 1 end
	for i=start,MAX_SAVES do
		if saves[i] == nil then
			return i
		end
	end
	return MAX_SAVES
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function HideScreens(noHide)
	for windowID, control in pairs(screens) do
		if (windowID ~= noHide) and (control.visible) then
			control:Hide()
		end
	end
end

local function ShowScreen(screenID)
	if not screens[screenID].visible then
		screens[screenID]:Show()
	end
end

local function SwitchToScreen(screenID)
	lastScreenID = currentScreenID
	currentScreenID = screenID
	HideScreens(screenID)
	ShowScreen(screenID)
end

local function EnableStartButton()
	if not currentCampaignID then
		return
	end
	SetControlGreyout(startButton, false)
end

--[[
local function SetSaveLoadButtonStates()
	local canSave, canLoad = false, false
	if currentSaveID then
		if saves[currentSaveID] then
			canLoad = true
		end
		if saveEnabled then
			canSave = true
		end
	end
	SetControlGreyout(saveButton, not canSave)
	SetControlGreyout(loadButton, not canLoad)
end
]]

-- Called when player clicks a campaign selection button in new game screen
-- Writes details of the campaign to the details panel
local function UpdateCampaignDetailsPanel(campaignID)
	local def = campaignDefsByID[campaignID]
	if not def then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "could not find campaign with def " .. campaignID)
		return
	end
	newGameCampaignDetails.titleLabel:SetCaption(def.name)
	newGameCampaignDetails.authorLabel:SetCaption("by " .. def.author)
	newGameCampaignDetails.versionLabel:SetCaption("Version: " .. (def.version or "1"))
	newGameCampaignDetails.lengthLabel:SetCaption("Length: " .. (def.length or "unknown"))
	-- make sure text box is right width
	newGameCampaignDetails.descTextBox.width = newGameCampaignDetails.stackPanel.width - newGameCampaignDetails.stackPanel.padding[1] - newGameCampaignDetails.stackPanel.padding[3]
	newGameCampaignDetails.descTextBox:SetText(def.description)
	--newGameCampaignDetails.descTextBox:Invalidate()
	EnableStartButton()
end

-- Called when player clicks a campaign selection button in new game screen
local function SelectCampaign(campaignID)
	local def = campaignDefsByID[campaignID]
	currentCampaignID = def.id
	-- grey out the buttons of the unselected campaigns, highlight the selected one
	for id,button in pairs(newGameCampaignButtons) do
		if id == campaignID then
			button.backgroundColor = {1,1,1,1}
		else
			button.backgroundColor = {0.4,0.4,0.4,1}
		end
		button:Invalidate()
	end
	UpdateCampaignDetailsPanel(campaignID)
end

--------------------------------------------------------------------------------
-- star map stuff
--------------------------------------------------------------------------------
local function IsMissionUnlocked(missionID)
	local mission = missionDefs[missionID]
	if not mission then
		return false
	end
	-- any completed missions are considered unlocked
	if gamedata.completedMissions[missionID] then
		return true
	-- no missions required to lock this
	elseif #(mission.requiredMissions or {}) == 0 then
		return true
	end
	-- check if we have completed any set of required missions
	for j, requiredMissionSet in ipairs(mission.requiredMissions) do
		for k, requiredMissionID in ipairs(requiredMissionSet) do
			if gamedata.completedMissions[requiredMissionID] then
				return true
			end
		end
	end
	return false
end

-- returns true if any missions on the planet have been completed or unlocked
local function IsPlanetVisible(planetDef)
	for i=1,#planetDef.missions do
		local missionID = planetDef.missions[i]
		if IsMissionUnlocked(missionID) then
			return true
		end
	end
	return false
end

local function CloseStarMap()
	if starmapWindow then
		starmapWindow:Dispose()
		starmapWindow = nil
	end
end

-- Called when clicking back button on planet detail panel
local function BackToStarmap()
	starmapAnimation = "out"
	--starmapBackground2.file = nil
	--starmapPlanetImage.file = nil
	--starmapBackground2:Invalidate()
	--starmapPlanetImage:Invalidate()
	starmapInfoPanel:Dispose()
	starmapClose:SetLayer(1)
end

-- Called when clicking a planet button on the galaxy map
local function SelectPlanet(planetID)
	local planetDef = planetDefsByID[planetID]
	starmapAnimation = "in"
	starmapBackground2.file = campaignDefsByID[currentCampaignID].dir .. planetDef.background
	starmapPlanetImage.file = campaignDefsByID[currentCampaignID].dir .. planetDef.image
	starmapPlanetImage.fullWidth = planetDef.size[1]
	starmapPlanetImage.fullHeight = planetDef.size[2]
	starmapBackground2:Invalidate()
	starmapPlanetImage:Invalidate()
	
	local font_large = 20
	local font_normal = 20
	
	-- display planet info panel
	starmapInfoPanel = Panel:New{
		name = "chobby_campaign_starmapInfoPanel",
		parent = starmapWindow,
		y = "20%",
		right = 16,
		width = "60%",
		bottom = "20%",
		backgroundColor = {0.3, 0.3, 0.3, 1},
		children = {
			-- title
			Label:New{
				x = 4,
				y = 4,
				caption = string.upper(planetDef.name),
				font = {size = 30}
			},
			-- grid of details
			Grid:New{
				x = 4,
				y = 40,
				right = 4,
				bottom = "60%",
				columns = 2,
				rows = 4,
				children = {
					Label:New{caption = "Type", font = {size = font_large}},
					Label:New{caption = planetDef.type or "<UNKNOWN>", font = {size = font_normal}},
					Label:New{caption = "Radius", font = {size = font_large}},
					Label:New{caption = planetDef.radius or "<UNKNOWN>", font = {size = font_normal}},
					Label:New{caption = "Primary", font = {size = font_large}},
					Label:New{caption = planetDef.primary .. " (" .. planetDef.primaryType .. ") ", font = {size = font_normal}},
					Label:New{caption = "Military rating", font = {size = font_large}},
					Label:New{caption = tostring(planetDef.milRating or "<UNKNOWN>"), font = {size = font_normal}},
				},
			},
			-- desc text
			TextBox:New {
				x = 4,
				y = "45%",
				right = 4,
				bottom = "25%",
				text = planetDef.text,
				font = {size = 18},
			},
			-- mission list
			--missionsStack,
			-- back button
			Button:New{
				right = 0,
				y = 0,
				width = 64,
				height = 48,
				caption = i18n("back"),
				font = {size = 20},
				OnClick = {BackToStarmap}
			}
		}
	}
	-- list of missions on this planet
	local missionsStack = StackPanel:New {
		parent = starmapInfoPanel,
		orientation = "vertical",
		x = 4,
		right = 4,
		height = "25%",
		bottom = 0,
		resizeItems = false,
		autoArrangeV = false,
	}
	for i=1,#planetDef.missions do
		local missionID = planetDef.missions[i]
		if IsMissionUnlocked(missionID) then
			local missionDef = missionDefs[missionID]
			if missionDef then
				local completed = gamedata.completedMissions[missionID]
				missionsStack:AddChild(Button:New{
					width = "100%",
					x = 0,
					height = 36,
					caption = (completed and "(completed) " or "") .. missionDef.text,
					font = {size = 22, color = completed and {0.2, 1, 0.4, 1} or nil},
					OnClick = {function()
						if missionDef.script then
							WG.VisualNovel.StartScript(missionDef.script)
							CloseStarMap()
						end
					end}
				})
			end
		end
	end
	starmapInfoPanel:SetLayer(1)
end

local function MakePlanetButton(planetDef)
	--Spring.Echo("Making planet image for "..planetDef.name)
	local x = math.floor(planetDef.pos[1]*starmapBackground.width + 0.5)
	local y = math.floor(planetDef.pos[2]*starmapBackground.height + 0.5)
	
	local allMissionsCompleted = true
	for i=1,#planetDef.missions do
		local missionID = planetDef.missions[i]
		local completed = gamedata.completedMissions[missionID]
		if not completed then
			allMissionsCompleted = false
			break
		end
	end
	
	local button = Button:New{
		parent = starmapBackgroundHolder,
		width = planetDef.sizeMap[1],
		height = planetDef.sizeMap[2],
		x = x,
		y = y,
		padding = {0, 0, 0, 0},
		caption = "",
		--backgroundColor = {0, 0, 0, 0},
		children = {
			Image:New {
				file = campaignDefsByID[currentCampaignID].dir .. planetDef.image,
				x = 0,
				y = 0,
				width = "100%",
				height = "100%",
				keepAspect = true,
				padding = {0, 0, 0, 0},
			},
		},
		OnClick = { function(self)
				SelectPlanet(planetDef.id)
			end
		}
	}
	button:SetLayer(1)
	
	local label = Label:New {
		parent = starmapBackgroundHolder,
		x = x - 24,
		y = y - 16,
		width = planetDef.sizeMap[1] + 48,
		align = "center",
		caption = planetDef.name,
		font = {color = allMissionsCompleted and {0.2, 1, 0.4, 1} or nil}
	}
	label:SetLayer(1)
end

local function MakeStarMap()
	CloseStarMap()
	
	starmapWindow = Window:New{
		name = "chobby_campaign_starmap",
		caption = "Starmap",
		--fontSize = 50,
		x = screen0.width*0.5 - STARMAP_WINDOW_WIDTH/2,
		y = screen0.height/2 - STARMAP_WINDOW_HEIGHT/2 - 8,
		width  = STARMAP_WINDOW_WIDTH,
		height = STARMAP_WINDOW_HEIGHT + 32,
		padding = {8, 8, 8, 8};
		--autosize   = true;
		parent = screen0,
		draggable = true,
		resizable = false,
	}
	-- back button
	starmapClose = Button:New{
		name = "chobby_campaign_starmapClose",
		parent = starmapWindow,
		right = 0,
		y = 32,
		width = 64,
		height = 48,
		caption = i18n("close"),
		font = {size = 20},
		OnClick = {CloseStarMap}
	}
	starmapBackgroundHolder = Panel:New{
		name = "chobby_campaign_starmapBackgroundHolder",
		parent = starmapWindow,
		x = 0,
		y = 32,
		right = 0,
		bottom = 0,
		backgroundColor = {0, 0, 0, 0},
		padding = {0,0,0,0}
	}
	-- this is the "local" star background that gets drawn in planet detail screen
	starmapBackground2 = Image:New{
		name = "chobby_campaign_starmapBackground2",
		parent = starmapBackgroundHolder,
		x = 0,
		y = 0,
		width = PLANET_BACKGROUND_SIZE,
		height = PLANET_BACKGROUND_SIZE,
		file = "",
		keepAspect = false,
		color = {1,1,1,0}
	}
	-- force offscreen
	starmapBackground2.x = (-PLANET_BACKGROUND_SIZE + starmapBackgroundHolder.width)/2
	starmapBackground2.y = (-PLANET_BACKGROUND_SIZE + starmapBackgroundHolder.height)/2
	--starmapBackground2.width = 0
	--starmapBackground2.height = 0
	
	-- Planet image in detail screen
	starmapPlanetImage = Image:New{
		name = "chobby_campaign_starmapPlanetImage",
		parent = starmapBackground2,
		x = (PLANET_BACKGROUND_SIZE - starmapBackgroundHolder.width)/2 + 128,
		y = (PLANET_BACKGROUND_SIZE - starmapBackgroundHolder.height)/2 + 192,
		height = PLANET_IMAGE_SIZE,
		width = PLANET_IMAGE_SIZE,
		file = "",
		color = {1,1,1,0}
	}
	-- this background is for the galaxy overview
	starmapBackground = Image:New{
		name = "chobby_campaign_starmapBackground",
		parent = starmapBackgroundHolder,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		file = campaignDefsByID[currentCampaignID].dir .. campaignDefsByID[currentCampaignID].mapImage,
		keepAspect = false,
	}
	-- planet loop
	for i=1,#planetDefs do
		local planetDef = planetDefs[i]
		if IsPlanetVisible(planetDef) then
			MakePlanetButton(planetDef)
		end
	end
	starmapBackground2:SetLayer(1)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SaveGame(id)
	local success, err = pcall(function()
		Spring.CreateDir(SAVE_DIR)
		id = id or FindFirstEmptySaveSlot()
		local isAutosave = (id == AUTOSAVE_ID)
		path = SAVE_DIR .. (isAutosave and AUTOSAVE_FILENAME or ("save" .. string.format("%03d", id))) .. ".lua"
		local saveData = Spring.Utilities.CopyTable(gamedata, true)
		saveData.date = os.date('*t')
		saveData.id = id
		saveData.description = isAutosave and "" or saveDescEdit.text
		saveData.campaignID = currentCampaignID
		table.save(saveData, path)
		--Spring.Log(widget:GetInfo().name, LOG.INFO, "Saved game to " .. path)
		Spring.Echo(widget:GetInfo().name .. ": Saved game to " .. path)
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error saving game: " .. err)
	end
end

local function LoadGame(saveData)
	local success, err = pcall(function()
		Spring.CreateDir(SAVE_DIR)
		ResetGamedata()
		currentCampaignID = saveData.campaignID
		LoadCampaign(currentCampaignID)
		gamedata = Spring.Utilities.MergeTable(saveData, gamedata, true)
		gamedata.id = nil
		if saveData.description then
			saveDescEdit:SetText(saveData.description)
		end
		SetVNStory(gamedata.vnStory, campaignDefsByID[currentCampaignID].vnDir)
		--Spring.Log(widget:GetInfo().name, LOG.INFO, "Save file " .. path .. " loaded")
		UpdateCodexButtonState()
		SwitchToScreen("intermission")
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: " .. err)
	end
end

local function LoadGameByID(id)
	LoadGame(saves[id])
end
-- don't really need this
--[[
local function LoadGameFromFile(path)
	if VFS.FileExists(path) then
		local saveData = VFS.Include(path)
		LoadGame(saveData)
		Spring.Echo(widget:GetInfo().name .. ": Save file " .. path .. " loaded")
	else
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save file " .. path .. " does not exist")
	end
end
]]

local function DeleteSave(id)
	local success, err = pcall(function()
		local path = SAVE_DIR .. (id == AUTOSAVE_ID and AUTOSAVE_FILENAME or ("save" .. string.format("%03d", id))) .. ".lua"
		os.remove(path)
		local num = 0
		local parent = nil
		for i=1,#saveLoadControls do
			num = i
			local entry = saveLoadControls[i]
			if entry.id == id then
				parent = entry.container.parent
				entry.container:Dispose()
				table.remove(saveLoadControls, i)
				break
			end
		end
		-- reposition save entry controls
		for i=num,#saveLoadControls do
			local entry = saveLoadControls[i]
			entry.container.y = entry.container.y - (SAVEGAME_BUTTON_HEIGHT)
		end
		parent:Invalidate()
		
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error deleting save " .. id .. ": " .. err)
	end
end

local function StartNewGame()
	if not currentCampaignID then
		return
	end
			
	ChiliFX:AddFadeEffect({
		obj = screens.newGame, 
		time = 0.15,
		endValue = 0,
		startValue = 1,
		after = function()
			LoadCampaign(currentCampaignID)
			SwitchToScreen("intermission")
		end
	})
end

local function UnlockScene(id)
	gamedata.unlockedScenes[id] = true
end

local function AdvanceCampaign(completedMissionID, nextScript, chapterTitle)
	SetNextMissionScript(nextScript)
	SetChapterTitle(chapterTitle)
	gamedata.completedMissions[completedMissionID] = true
	SaveGame(AUTOSAVE_ID)
end
--------------------------------------------------------------------------------
-- Save/Load UI
--------------------------------------------------------------------------------
-- Generates a button for each available campaign, in the New Game screen
local function AddCampaignSelectorButtons()
	for i=1,#campaignDefs do
		local def = campaignDefs[i]
		newGameCampaignButtons[def.id] = Button:New {
			parent = newGameCampaignScroll,
			width = "100%",
			height = CAMPAIGN_SELECTOR_BUTTON_HEIGHT,
			x = 0,
			y = (CAMPAIGN_SELECTOR_BUTTON_HEIGHT + 4) * (i-1),
			caption = "",
			--padding = {0, 0, 0, 0},
			children = {
				Image:New {
					file = def.dir .. "image.png",
					y = 0,
					right = 16,
					width = CAMPAIGN_SELECTOR_BUTTON_HEIGHT * 160/128,
					height = "100%",
					keepAspect = true,
					padding = {0, 0, 0, 0},
				},
				Label:New {
					caption = def.name,
					--height = "100%",
					valign = "center",
					x = 8,
					y = 8,
					font = { size = 32 },
				}
			},
			backgroundColor = {0.4,0.4,0.4,1},
			OnClick = { function(self)
					SelectCampaign(def.id)
				end
			}
		}
	end
end

local function SaveLoadConfirmationDialogPopup(saveID, saveMode)
	local text = saveMode and i18n("save_overwrite_confirm") or i18n("load_confirm")
	local yesFunc = function()
			if (saveMode) then
				SaveGame(saveID)
				SwitchToScreen("intermission")
			else
				LoadGameByID(saveID)
			end
		end
	WG.Chobby.ConfirmationPopup(yesFunc, text, nil, 360, 200)
end

local function RemoveSaveEntryButtons()
	for i=1,#saveLoadControls do
		saveLoadControls[i].container:Dispose()
	end
	saveLoadControls = {}
end

-- Makes a button for a save game on the save/load screen
local function AddSaveEntryButton(saveFile, allowSave, count)
	local id = saveFile and saveFile.id or #savesOrdered + 1
	local controlsEntry = {id = id}
	saveLoadControls[#saveLoadControls + 1] = controlsEntry
	local parent = allowSave and saveScroll or loadScroll
	
	controlsEntry.container = Panel:New {
		parent = parent,
		height = SAVEGAME_BUTTON_HEIGHT,
		width = "100%",
		x = 0,
		y = (SAVEGAME_BUTTON_HEIGHT) * count,
		caption = "",
		--backgroundColor = {1,1,1,0},
	}
	controlsEntry.button = Button:New {
		parent = controlsEntry.container,
		x = 4,
		right = (saveFile and 96 + 8 or 0) + 4,
		y = 4,
		bottom = 4,
		caption = "",
		OnClick = { function(self)
				if allowSave then
					if saveFile then
						SaveLoadConfirmationDialogPopup(id, true)
					else
						SaveGame()
						SwitchToScreen("intermission")
					end
				else
					if lastScreenID == "main" then
						LoadGameByID(id)
					else
						SaveLoadConfirmationDialogPopup(id, false)
					end
				end
			end
		}
	}
	local caption = saveFile and i18n("save") .. " " .. saveFile.id or i18n("save_new_game")
	if saveFile and saveFile.id == AUTOSAVE_ID then
		caption = i18n("autosave")
	end
	controlsEntry.titleLabel = Label:New {
		parent = controlsEntry.button,
		caption = caption,
		valign = "center",
		x = 8,
		y = 8,
		font = { size = 20 },
	}
	if saveFile then
		controlsEntry.descTextbox = TextBox:New {
			parent = controlsEntry.button,
			x = 8,
			y = 40,
			right = 8,
			bottom = 8,
			text = (saveFile.description or "no description") .. "\n" .. saveFile.chapterTitle
				.. "\n" .. (campaignDefsByID[saveFile.campaignID] and campaignDefsByID[saveFile.campaignID].name or saveFile.campaignID),
			font = { size = 16 },
		}
		controlsEntry.dateLabel = Label:New {
			parent = controlsEntry.button,
			caption = WriteDate(saveFile.date),
			right = 8,
			y = 8,
			font = { size = 18 },
		}
		
		controlsEntry.deleteButton = Button:New {
			parent = controlsEntry.container,
			width = 96,
			right = 4,
			y = 4,
			bottom = 4,
			caption = i18n("delete"),
			--backgroundColor = {0.4,0.4,0.4,1},
			OnClick = { function(self)
					WG.Chobby.ConfirmationPopup(function(self) DeleteSave(id) end, i18n("delete_confirm"), nil, 360, 200)
				end
			}
		}
	end

end

-- Generates the buttons for the savegames on the save/load screen
local function AddSaveEntryButtons(allowSave)
	local startIndex = #savesOrdered
	local count = 0
	if (allowSave and #savesOrdered < 999) then
		-- add new game panel
		AddSaveEntryButton(nil, true, count)
		count = 1
	end
	
	for i=startIndex,1,-1 do
		AddSaveEntryButton(savesOrdered[i], allowSave, count)
		count = count + 1;
	end
end

local function OpenSaveOrLoadMenu(save)
	currentSaveID = nil
	GetSaves()
	RemoveSaveEntryButtons()
	AddSaveEntryButtons(save)
	if (save) then
		SwitchToScreen("save")
	else
		SwitchToScreen("load")
	end
end

--------------------------------------------------------------------------------
-- Make Chili controls
--------------------------------------------------------------------------------
local function InitializeMainControls()
	-- main menu
	screens.main = Panel:New {
		parent = window,
		name = 'chobby_campaign_main',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		backgroundColor = {0, 0, 0, 0},
		children = {
			Label:New {
				name = 'chobby_campaign_mainTitle',
				caption = string.upper(i18n("campaign")),
				align = "center",
				y = 24,
				x = 0,
				right = 0,
				height = 56,
				autosize = false,
				font = {
					size = 48,
					outlineWidth = 12,
					outlineHeight = 12,
					outline = true,
					outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
					autoOutlineColor = false,
				}
			},
			StackPanel:New{
				name = 'chobby_campaign_mainStack',
				orientation = "vertical",
				x = 0,
				y = "20%",
				width = "100%",
				height = "80%",
				resizeItems = false,
				children = {
					Button:New {
						name = 'chobby_campaign_mainLoad',
						width = 192,
						height = 64,
						caption = i18n("load_game"),
						font = {size = 28},
						OnClick = {function() OpenSaveOrLoadMenu(false) end}
						
					},
					Button:New {
						name = 'chobby_campaign_mainNew',
						width = 192,
						height = 64,
						caption = i18n("new_game"),
						font = {size = 28},
						OnClick = {function() SwitchToScreen("newGame") end}
					},
				}
			}
		}
	}
end

local function InitializeNewGameControls()
	-- New Game screen
	startButton = Button:New {
		name = 'chobby_campaign_newGameStart',
		width = 60,
		height = 40,
		y = 4,
		right = 4,
		caption = i18n("start_verb"),
		OnClick = { function(self)
			StartNewGame()
		end},
		font = {size = 18}
	}
	newGameCampaignScroll = ScrollPanel:New {
		name = 'chobby_campaign_newGameScroll',
		orientation = "vertical",
		x = 0,
		y = "15%",
		width = "100%",
		height = "45%",
		children = {}
	}
	newGameCampaignDetails.panel = Panel:New {
		name = 'chobby_campaign_newGameDetails',
		x = 0,
		y = "60%",
		width = "100%",
		height = "40%",
	}
	newGameCampaignDetails.stackPanel = StackPanel:New {
		parent = newGameCampaignDetails.panel,
		orientation = "vertical",
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizeItems = false,
		--autoArrangeV = true,
		centerItems = false,
		itemMargin = {5, 5, 5, 5},
	}
	newGameCampaignDetails.titleLabel = Label:New {
		parent = newGameCampaignDetails.stackPanel,
		caption = "",
		font = { size = 36 },
	}
	newGameCampaignDetails.authorLabel = Label:New {
		parent = newGameCampaignDetails.stackPanel,
		caption = "",
		font = { size = 20 },
	}
	newGameCampaignDetails.versionLabel = Label:New {
		parent = newGameCampaignDetails.stackPanel,
		caption = "",
		font = { size = 18 },
	}
	newGameCampaignDetails.lengthLabel = Label:New {
		parent = newGameCampaignDetails.stackPanel,
		caption = "",
		font = { size = 18 },
	}
	newGameCampaignDetails.descTextBox = TextBox:New {
		parent = newGameCampaignDetails.stackPanel,
		text = "",
		font = { size = 16 },
	}
	
	screens.newGame = Panel:New {
		parent = window,
		name = 'chobby_campaign_newGame',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		backgroundColor = {0, 0, 0, 0},
		children = {
			Label:New {
				name = 'chobby_campaign_newGameTitle',
				caption = string.upper(i18n("new_game")),
				x = 4,
				y = 24,
				font = {
					size = 40,
					outlineWidth = 10,
					outlineHeight = 10,
					outline = true,
					outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
					autoOutlineColor = false,
				}
			},
			startButton,
			Button:New {
				name = 'chobby_campaign_newGameBack',
				width = 60,
				height = 40,
				y = 4,
				right = 4 + 60 + 4,
				caption = i18n("back"),
				OnClick = {function() SwitchToScreen("main") end},
				font = {size = 18}
			},
			newGameCampaignScroll,
			newGameCampaignDetails.panel,
		}
	}
end

local function InitializeIntermissionControls()
	--intermission screen
	intermissionButtonCodex = Button:New {
		name = 'chobby_campaign_intermissionCodex',
		width = 160,
		height = 48,
		caption = i18n("codex"),
		font = {
			size = 20,
			shadow = false,
			outlineWidth = 6,
			outlineHeight = 6,
			outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
			autoOutlineColor = false,
		},
		OnClick = { function()
			LoadCodexEntries(); SwitchToScreen("codex")
		end}
	}
	
	screens.intermission = Panel:New {
		parent = window,
		name = 'chobby_campaign_intermission',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		backgroundColor = {0, 0, 0, 0},
		children = {
			Label:New {
				name = 'chobby_campaign_intermissionTitle',
				caption = string.upper(i18n("intermission")),
				y = 24,
				x = 8,
				font = {
					size = 40,
					outlineWidth = 12,
					outlineHeight = 12,
					outline = true,
					outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
					autoOutlineColor = false,
				}
			},
			StackPanel:New{
				name = 'chobby_campaign_intermissionStack',
				orientation = "vertical",
				x = 0,
				y = "20%",
				width = "100%",
				height = "80%",
				resizeItems = false,
				--autoArrangeV = true,
				centerItems = false,
				children = {
					-- TODO functions
					Button:New {
						name = 'chobby_campaign_intermissionNext',
						width = 160,
						height = 48,
						caption = i18n("next_episode"),
						font = {size = 20},
						OnClick = { function()
							if gamedata.mapEnabled then
								MakeStarMap()
							elseif gamedata.nextMissionScript then
								WG.VisualNovel.Cleanup()
								WG.VisualNovel.StartScript(gamedata.nextMissionScript)
							end
						end}
					},
					Button:New {
						name = 'chobby_campaign_intermissionSave',
						width = 160,
						height = 48,
						caption = i18n("save"),
						font = {size = 20},
						OnClick = { function()
							OpenSaveOrLoadMenu(true)
						end},
					},
					Button:New {
						name = 'chobby_campaign_intermissionLoad',
						width = 160,
						height = 48,
						caption = i18n("load"),
						font = {size = 20},
						OnClick = { function()
							OpenSaveOrLoadMenu(false)
						end}
					},
					intermissionButtonCodex,
					Button:New {
						name = 'chobby_campaign_intermissionQuit',
						width = 160,
						height = 48,
						caption = i18n("quit"),
						font = {size = 20},
						OnClick = { function(self)
							WG.Chobby.ConfirmationPopup(function() ChiliFX:AddFadeEffect({
								obj = screens.intermission, 
								time = 0.15,
								endValue = 0,
								startValue = 1,
								after = function()
									CleanupAfterMission()
									SwitchToScreen("main")
									ResetGamedata()
									if WG.MusicHandler then
										WG.MusicHandler.StartTrack()
									end
								end
							}) end,
							i18n("quit_confirm"), nil, 360, 200)
						end }
					},
				}
			}
		}
	}
end

local function InitializeSaveLoadWindow()
	saveScroll = ScrollPanel:New {
		name = 'chobby_campaign_saveScroll',
		orientation = "vertical",
		x = 0,
		y = 84,
		width = "100%",
		bottom = 8,
		children = {}
	}
	saveDescEdit = Chili.EditBox:New {
		name = 'chobby_campaign_saveDesc',
		x = 0,
		y = 56,
		height = 20,
		width = "50%",
		text = "Save description",
		font = { size = 16 },
	}
	
	screens.save = Panel:New {
		parent = window,
		name = 'chobby_campaign_save',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		backgroundColor = {0, 0, 0, 0},
		children = {
			Label:New {
				name = 'chobby_campaign_saveTitle',
				caption = string.upper(i18n("save")),
				x = 4,
				y = 8,
				font = {
					size = 40,
					outlineWidth = 10,
					outlineHeight = 10,
					outline = true,
					outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
					autoOutlineColor = false,
				}
			},
			Button:New {
				name = 'chobby_campaign_saveBack',
				width = 60,
				height = 40,
				y = 4,
				right = 4,
				caption = i18n("back"),
				OnClick = {function() SwitchToScreen(lastScreenID) end},
				font = {size = 18}
			},
			saveDescEdit,
			saveScroll,
		}
	}
	
	loadScroll = ScrollPanel:New {
		name = 'chobby_campaign_loadScroll',
		orientation = "vertical",
		x = 0,
		y = 56,
		width = "100%",
		bottom = 8,
		children = {}
	}
	
	screens.load = Panel:New {
		parent = window,
		name = 'chobby_campaign_load',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		backgroundColor = {0, 0, 0, 0},
		children = {
			Label:New {
				name = 'chobby_campaign_loadTitle',
				caption = string.upper(i18n("load")),
				x = 4,
				y = 8,
				font = {
					size = 40,
					outlineWidth = 10,
					outlineHeight = 10,
					outline = true,
					outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
					autoOutlineColor = false,
				}
			},
			Button:New {
				name = 'chobby_campaign_loadBack',
				width = 60,
				height = 40,
				y = 4,
				right = 4,
				caption = i18n("back"),
				OnClick = {function() SwitchToScreen(lastScreenID) end},
				font = {size = 18}
			},
			loadScroll,
		}
	}
end

local function InitializeCodexControls()
	local codexTextScroll = ScrollPanel:New{
		name = 'chobby_campaign_codexTextScroll',
		x = 4,
		y = "40%",
		bottom = 4,
		right = 4,
		orientation = "vertical",
		children = {}
	}
	codexText = TextBox:New {
		name = 'chobby_campaign_codexText',
		parent = codexTextScroll,
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		text = "",
		font = {size = 18},
	}
	
	local codexImagePanel = Panel:New{
		name = 'chobby_campaign_codexImagePanel',
		y = 64,
		right = 4,
		height = 72,
		width = 72,
	}
	codexImage = Image:New{
		parent = codexImagePanel,
		name = 'chobby_campaign_codexImage',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
	}
	
	codexTreeScroll = ScrollPanel:New{
		name = 'chobby_campaign_codexTreeScroll',
		x = 4,
		y = 64,
		bottom = "60%",
		right = "50%",
		orientation = "vertical",
		children = {}
	}
	codexTree = Chili.TreeView:New{
		parent = codexTreeScroll,
		name = 'chobby_campaign_codexTree',
	}
	
	screens.codex = Panel:New {
		parent = window,
		name = 'chobby_campaign_codex',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		backgroundColor = {0, 0, 0, 0},
		children = {
			Label:New {
				name = 'chobby_campaign_codexTitle',
				caption = string.upper(i18n("codex")),
				x = 4,
				y = 8,
				font = {
					size = 40,
					outlineWidth = 10,
					outlineHeight = 10,
					outline = true,
					outlineColor = Spring.Utilities.CopyTable(OUTLINE_COLOR),
					autoOutlineColor = false,
				}
			},
			Button:New {
				name = 'chobby_campaign_codexBack',
				width = 60,
				height = 36,
				y = 4,
				right = 4,
				caption = i18n("back"),
				OnClick = {function() UpdateCodexButtonState(); SwitchToScreen(lastScreenID) end},
				font = {size = 18}
			},
			codexImagePanel,
			codexTextScroll,
			codexTreeScroll,
		}
	}
end

local function InitializeControls()
	Chili = WG.Chili
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	ScrollPanel = Chili.ScrollPanel
	Label = Chili.Label
	Button = Chili.Button
	
	-- window to hold things
	window = Panel:New {
		name = 'chobby_campaign_window',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {0, 0, 0, 0}
	}
	
	InitializeMainControls()
	InitializeNewGameControls()	
	InitializeIntermissionControls()
	InitializeSaveLoadWindow()
	InitializeCodexControls()
	SwitchToScreen("main")
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------
local animElapsed = 0
local ANIMATION_TIME = 0.6

function widget:Update()
	local currentTime = Spring.GetTimer()
	local dt = Spring.DiffTimers(currentTime, timer)
	timer = currentTime
	
	-- animation in: expands the planet image and star background image when opening a planet detail screen
	-- animation out: shrinks and disappears those images when returning to galaxy map
	if starmapAnimation then
		animElapsed = animElapsed + dt
		local stage = animElapsed/ANIMATION_TIME
		if stage > 1 then stage = 1 end
		if starmapAnimation == "out" then
			stage = 1 - stage
		end
		starmapBackground2.color[4] = stage
		starmapBackground2.width = math.floor(PLANET_BACKGROUND_SIZE * stage + 0.5)
		starmapBackground2.height = math.floor(PLANET_BACKGROUND_SIZE * stage + 0.5)
		starmapBackground2:Invalidate()
		
		starmapPlanetImage.color[4] = stage
		starmapPlanetImage.width = math.floor(starmapPlanetImage.fullWidth * stage + 0.5)
		starmapPlanetImage.height = math.floor(starmapPlanetImage.fullHeight * stage + 0.5)
		starmapPlanetImage:Invalidate()
		
		if animElapsed >= ANIMATION_TIME then
			animElapsed = 0
			starmapAnimation = nil
		end
	end
end

-- called when returning to menu from a game
function widget:ActivateMenu()
	--Spring.Log(widget:GetInfo().name, LOG.INFO, "ActivateMenu called", runningMission)
	if runningMission then
		Spring.Log(widget:GetInfo().name, LOG.INFO, "Finished running mission")
		if VFS.FileExists(RESULTS_FILE_PATH) then
			local results = VFS.Include(RESULTS_FILE_PATH)
			missionCompletionFunc(results)
		else
			Spring.Log(widget:GetInfo().name, LOG.ERROR, "Unable to load mission results file")
		end
		CleanupAfterMission()
	end
end

function widget:DownloadFinished()
	if requiredMap and VFS.HasArchive(requiredMap) then
		requiredMap = nil
	end
end

function widget:Initialize()
	CHOBBY_DIR = "LuaMenu/widgets/chobby/"
	VFS.Include("LuaMenu/widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	
	InitializeControls()
	
	WG.CampaignHandler = {
		GetWindow = function() return window end,
		SetVNStory = SetVNStory,
		SetNextMissionScript = SetNextMissionScript,
		AdvanceCampaign = AdvanceCampaign,
		UnlockScene = UnlockScene,
		UnlockCodexEntry = UnlockCodexEntry,
		SetChapterTitle = SetChapterTitle,
		SetMapEnabled = function(bool) gamedata.mapEnabled = bool end,
		GetMapForMissionIfNeeded = GetMapForMissionIfNeeded,
		LaunchMission = LaunchMission,
	}
	
	ResetGamedata()
	LoadCampaignDefs()
	AddCampaignSelectorButtons()
end

function widget:Shutdown()
	WG.CampaignHandler = nil
end