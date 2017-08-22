--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	
	local planetData = {
		name = "Walchice",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.24,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.84,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "5930 km",
			primary = "Chukon",
			primaryType = "G1V",
			milRating = 1,
			text = [[The enemy surrounds you on all sides; construct Stinger and Stardust defence structures and hold out for 15 minutes.]]
		},
		gameConfig = {
			missionStartscript = false,
			mapName = "Archers_Valley_v6",
			playerConfig = {
				startX = 3000,
				startZ = 3300,
				allyTeam = 0,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"turretheavylaser",
					"turretriot",
				},
				startUnits = {
					{
						name = "staticmex",
						x = 2856,
						z = 3080,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3000,
						z = 2376,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3160,
						z = 3784,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 1832,
						z = 2632,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 2800,
						z = 2464,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 3376,
						z = 3136,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2920,
						z = 3096,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2840,
						z = 3144,
						facing = 3,
					},
					{
						name = "energysolar",
						x = 2792,
						z = 3064,
						facing = 2,
					},
					{
						name = "energysolar",
						x = 2872,
						z = 3016,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 1896,
						z = 2648,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 1816,
						z = 2696,
						facing = 3,
					},
					{
						name = "energysolar",
						x = 1768,
						z = 2616,
						facing = 2,
					},
					{
						name = "energysolar",
						x = 1848,
						z = 2568,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 3224,
						z = 3800,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3144,
						z = 3848,
						facing = 3,
					},
					{
						name = "energysolar",
						x = 3096,
						z = 3768,
						facing = 2,
					},
					{
						name = "energysolar",
						x = 3176,
						z = 3720,
						facing = 1,
					},
					{
						name = "energywind",
						x = 3048,
						z = 2376,
						facing = 3,
					},
					{
						name = "energywind",
						x = 3048,
						z = 2424,
						facing = 3,
					},
					{
						name = "energywind",
						x = 3000,
						z = 2424,
						facing = 2,
					},
					{
						name = "energywind",
						x = 2952,
						z = 2424,
						facing = 2,
					},
					{
						name = "energywind",
						x = 2952,
						z = 2376,
						facing = 1,
					},
					{
						name = "energywind",
						x = 2952,
						z = 2328,
						facing = 1,
					},
					{
						name = "energywind",
						x = 3000,
						z = 2328,
						facing = 0,
					},
					{
						name = "energywind",
						x = 3048,
						z = 2328,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 2912,
						z = 2288,
						facing = 2,
					},
					{
						name = "turretheavylaser",
						x = 2296,
						z = 2488,
						facing = 2,
					},
					{
						name = "turretriot",
						x = 3160,
						z = 4072,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 3424,
						z = 3952,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 1808,
						z = 2896,
						facing = 3,
					},
					{
						name = "turretlaser",
						x = 2528,
						z = 3712,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 1952,
						z = 3216,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 2048,
						z = 3296,
						facing = 0,
					},
					{
						name = "spideremp",
						x = 2666,
						z = 3430,
						facing = 0,
					},
					{
						name = "spideremp",
						x = 2777,
						z = 3430,
						facing = 0,
					},
					{
						name = "spiderriot",
						x = 2666,
						z = 3500,
						facing = 0,
					},
					{
						name = "spiderriot",
						x = 2777,
						z = 3500,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 3680,
						z = 3232,
						facing = 1,
					},
					{
						name = "turretmissile",
						x = 3680,
						z = 3136,
						facing = 1,
					},
				}
			},
			aiConfig = {
				{
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					humanName = "Oppressors",
					allyTeam = 1,
					unlocks = {
						"staticradar",
						"staticmex",
						"energysolar",
						"turretlaser",
						"cloakraid",
						"cloakskirm",
						"cloakriot",
						"shieldraid",
						"shieldskirm",
						"shieldriot",
						"amphraid",
						"amphimpulse",
					},
					difficultyDependantUnlocks = {
						[2] = {"amphfloater"},
					},
					commander = false,
					startUnits = {
						{
							name = "turretriot",
							x = 4648,
							z = 4792,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3880,
							z = 5432,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4488,
							z = 5848,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4728,
							z = 5704,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5048,
							z = 5992,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1240,
							z = 5144,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 536,
							z = 5016,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 856,
							z = 5256,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 296,
							z = 4424,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2840,
							z = 248,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3144,
							z = 760,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3496,
							z = 392,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1672,
							z = 312,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 2296,
							z = 888,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 2888,
							z = 1256,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 3224,
							z = 1240,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 4120,
							z = 1576,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 3064,
							z = 1336,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 2152,
							z = 920,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 4248,
							z = 1640,
							facing = 0,
						},
						{
							name = "factoryamph",
							x = 3176,
							z = 104,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 2696,
							z = 392,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 3640,
							z = 680,
							facing = 0,
						},
						{
							name = "cloakcon",
							x = 807,
							z = 4966,
							facing = 0,
						},
						{
							name = "cloakcon",
							x = 870,
							z = 5008,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1080,
							z = 5144,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 936,
							z = 5160,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 760,
							z = 5128,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 632,
							z = 5016,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 504,
							z = 4856,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 440,
							z = 4712,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 360,
							z = 4552,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 600,
							z = 4904,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 376,
							z = 4424,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 2920,
							z = 360,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3016,
							z = 504,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3128,
							z = 632,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3256,
							z = 584,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3368,
							z = 440,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4600,
							z = 5784,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4808,
							z = 5800,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4952,
							z = 5912,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4376,
							z = 5800,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4216,
							z = 5704,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4040,
							z = 5576,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3960,
							z = 5496,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4184,
							z = 5592,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 3472,
							z = 704,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2848,
							z = 672,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 3680,
							z = 304,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2640,
							z = 160,
							facing = 0,
						},
						{
							name = "factorycloak",
							x = 920,
							z = 4792,
							facing = 2,
						},
						{
							name = "factoryshield",
							x = 4512,
							z = 5520,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x = 3416,
							z = 4968,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x = 4616,
							z = 4600,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x = 2328,
							z = 4664,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x = 888,
							z = 3800,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 1048,
							z = 3896,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 2152,
							z = 4632,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 3624,
							z = 4872,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 4192,
							z = 5008,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 2896,
							z = 4848,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 1296,
							z = 4896,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 480,
							z = 4256,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 1120,
							z = 4384,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3648,
							z = 5584,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 4976,
							z = 5504,
							facing = 2,
						},
						{
							name = "turretaalaser",
							x = 680,
							z = 4536,
							facing = 2,
						},
						{
							name = "turretaalaser",
							x = 1144,
							z = 4952,
							facing = 2,
						},
						{
							name = "turretaalaser",
							x = 3912,
							z = 5816,
							facing = 2,
						},
						{
							name = "turretaalaser",
							x = 4888,
							z = 5208,
							facing = 2,
						},
						{
							name = "shieldcon",
							x = 4431,
							z = 5625,
							facing = 0,
						},
						{
							name = "shieldcon",
							x = 4501,
							z = 5648,
							facing = 0,
						},
						{
							name = "amphcon",
							x = 3143,
							z = 198,
							facing = 0,
						},
						{
							name = "amphraid",
							x = 3138,
							z = 332,
							facing = 0,
						},
						{
							name = "amphraid",
							x = 3342,
							z = 266,
							facing = 0,
						},
						{
							name = "amphraid",
							x = 3580,
							z = 274,
							facing = 0,
						},
						{
							name = "amphcon",
							x = 3245,
							z = 214,
							facing = 0,
						},
						{
							name = "cloakskirm",
							x = 820,
							z = 4654,
							facing = 0,
						},
						{
							name = "cloakskirm",
							x = 940,
							z = 4659,
							facing = 0,
						},
						{
							name = "cloakskirm",
							x = 1046,
							z = 4752,
							facing = 0,
						},
						{
							name = "shieldassault",
							x = 4369,
							z = 5441,
							facing = 0,
						},
						{
							name = "shieldassault",
							x = 4466,
							z = 5388,
							facing = 0,
						},
					}
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = false,
					loseAfterSeconds = 900,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Survive for 15 minutes",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Have 12 Metal Extractors
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 12,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 12 Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Do not lose any Stingers
					satisfyForever = true,
					onlyCountRemovedUnits = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					unitTypes = {
						"turretheavylaser",
					},
					image = planetUtilities.ICON_DIR .. "turretheavylaser.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Do not lose any Stingers",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Destroy an enemy factory
					satisfyOnce = true,
					onlyCountRemovedUnits = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					enemyUnitTypes = {
						"factorycloak",
						"factoryshield",
						"factoryamph",
					},
					image = planetUtilities.ICON_DIR .. "factoryamph.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy one of the enemy factories",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"turretheavylaser",
				"turretriot",
			},
			modules = {
				"module_ablative_armor_LIMIT_C_2",
			},
			abilities = {
			}
		},
	}
	
	return planetData
end

return GetPlanet
