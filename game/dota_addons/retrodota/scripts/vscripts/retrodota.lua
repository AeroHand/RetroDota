--[[
Retro Dota game mode
]]

print("Retro Dota game mode loaded.")

RETRODOTA_VERSION = "1.0.0"

if RetroDota == nil then
	RetroDota = class({})
end

function RetroDota:InitGameMode()
	RetroDota = self
	print('[RETRODOTA] Starting to load retrodota RetroDota...')

	-- Enable the standard Dota PvP game rules
	GameRules:GetGameModeEntity():SetTowerBackdoorProtectionEnabled(true)

	-- Register Think
	--RetroDota:SetContextThink("RetroDota:GameThink", function() return self:GameThink() end, 0.25)
	
	-- Register Game Events
	ListenToGameEvent('player_connect', Dynamic_Wrap(RetroDota, 'PlayerConnect'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(RetroDota, 'OnConnectFull'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(RetroDota, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(RetroDota, 'OnPlayerPickHero'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(RetroDota, 'OnNPCSpawned'), self)
	--ListenToGameEvent('last_hit', Dynamic_Wrap(RetroDota, 'OnLastHit'), self)

	-- Vote Data
	GameRules.player_count = 0
	GameRules.players_voted = 0
	GameRules.players_skipped_vote = 0
	GameRules.win_condition_votes = {}
	GameRules.level_votes = {}
	GameRules.gold_votes = {}
	GameRules.invoke_cd_votes = {}
	GameRules.invoke_slots_votes = {}
	GameRules.mana_cost_reduction_votes = {}
	GameRules.wtf_votes = {}
	GameRules.fast_respawn_votes = {}
	GameRules.gold_multiplier_votes = {}
	GameRules.xp_multiplier_votes = {}

	GameRules.vote_options = LoadKeyValues("scripts/npc/kv/vote_options.txt")
end

function RetroDota:GameThink()
	return 0.25
end

-- This function is called 1 to 2 times as the player connects initially but before they have completely connected
function RetroDota:PlayerConnect(keys)
	print('[RETRODOTA] PlayerConnect')

end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function RetroDota:OnConnectFull(keys)
	print ('[RETRODOTA] OnConnectFull')
	RetroDota:CaptureGameMode()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	GameRules.player_count = GameRules.player_count + 1

end

-- This function is called as the first player loads and sets up the GameMode parameters
function RetroDota:CaptureGameMode()
	if mode == nil then
		-- Set GameMode parameters
		mode = GameRules:GetGameModeEntity()

		-- Custom Settings (not used)
		--[[mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
		mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
		mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
		mode:SetBuybackEnabled( BUYBACK_ENABLED )
		mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
		mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
		mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
		mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
		mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

		--mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
		mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

		mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
		mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
		mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )]]

		RetroDota:OnFirstPlayerLoaded()
	end
end

-- This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.

function RetroDota:OnFirstPlayerLoaded()
	print("[BAREBONES] First Player has loaded")
end

-- The overall game state has changed
function RetroDota:OnGameRulesStateChange(keys)
	print("[RETRODOTA] GameRules State Changed")

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		
		local et = 6
		if self.bSeenWaitForPlayers then
			et = .01
		end

		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
				
				if PlayerResource:HaveAllPlayersJoined() then

					RetroDota:OnAllPlayersLoaded()
					return
				end
				return 1
			end})
	end
end

function RetroDota:OnAllPlayersLoaded()
	print("[RETRODOTA] All Players have loaded into the game")

	-- Show Vote Panel
	FireGameEvent( 'show_vote_panel', {} )

end

function RetroDota:OnPlayerPickHero(keys)
	local hero = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
	local playerID = hero:GetPlayerID()
	
	FireGameEvent( 'send_hero_ent', { player_ID = playerID, _ent = PlayerResource:GetSelectedHeroEntity(playerID):GetEntityIndex() } )
	FireGameEvent( 'show_spell_list_button', { player_ID = playerID } )

	local level = 25
	for i=1,level-1 do
		hero:HeroLevelUp(false)
	end
end

--Remove movement speed spawn modifiers on lane creeps, and alter the creeps' models.
function RetroDota:OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)
	
	if IsValidEntity(npc) then
		local npc_name = npc:GetUnitName()
		
		-- Creep custom models are changed directly through the npc_units.txt override file
		--[[if npc_name == "npc_dota_creep_goodguys_melee" then
			npc:SetOriginalModel("models/heroes/furion/treant.vmdl")
			npc:SetModel("models/heroes/furion/treant.vmdl")
		elseif npc_name == "npc_dota_creep_goodguys_ranged" then
			npc:SetOriginalModel("models/items/furion/treant/furion_treant_nelum_red/furion_treant_nelum_red.vmdl")
			npc:SetModel("models/items/furion/treant/furion_treant_nelum_red/furion_treant_nelum_red.vmdl")
		elseif npc_name == "npc_dota_creep_badguys_melee" then
			npc:SetOriginalModel("models/heroes/undying/undying_minion.vmdl")
			npc:SetModel("models/heroes/undying/undying_minion.vmdl")
		elseif npc_name == "npc_dota_creep_badguys_ranged" then
			npc:SetOriginalModel("models/items/undying/idol_of_ruination/ruin_wight_minion.vmdl")
			npc:SetModel("models/items/undying/idol_of_ruination/ruin_wight_minion.vmdl")
		end]]
	end
	
	--Remove movement speed modifiers that are automatically applied to lane creeps spawned from the npc_dota_spawner entities.
	--We have to wait around 1 second for unknown reasons, or the modifiers won't be removed.
	Timers:CreateTimer({
		endTime = 1,
		callback = function()
			if IsValidEntity(npc) then
				if npc:HasModifier("modifier_creep_haste") or npc:HasModifier("modifier_creep_slow")then
					npc:RemoveModifierByName("modifier_creep_haste")
					npc:RemoveModifierByName("modifier_creep_slow")
				end
			end
		end
	})
end



-- register the 'player_voted' command in our console
Convars:RegisterCommand( "player_voted", function(name, win_condition, level, gold, invoke_cd, invoke_slots, mana_cost_reduction, 
												wtf, fast_respawn, gold_multiplier, xp_multiplier)
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			--if the player is valid, register the vote
        	return RetroDota:RegisterVote( cmdPlayer , win_condition, level, gold, invoke_cd, invoke_slots, mana_cost_reduction, 
												wtf, fast_respawn, gold_multiplier, xp_multiplier)
		else
			print("nil or -1 playerID",playerID)
		end
	end
end, "VOTE button", 0 )


Convars:RegisterCommand( "player_skip_vote", function(name, p)
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			--if the player is valid, register the vote
        	return RetroDota:IgnoreVote()
		end
	end
end, "DONT CARE button", 0 )

function RetroDota:IgnoreVote()
	GameRules.players_skipped_vote = GameRules.players_skipped_vote + 1
end


function RetroDota:RegisterVote( player, win_condition, level, gold, invoke_cd, invoke_slots, mana_cost_reduction, wtf, fast_respawn, gold_multiplier, xp_multiplier )
 
    --get the player's ID
    local pID = player:GetPlayerID()
    print("RegisterVote", pID, win_condition, level, gold, invoke_cd, invoke_slots, mana_cost_reduction, wtf, fast_respawn, gold_multiplier, xp_multiplier)

	GameRules.players_voted = GameRules.players_voted + 1

    -- Insert the different values in each table
    table.insert(GameRules.win_condition_votes, win_condition)
	table.insert(GameRules.level_votes, level)
	table.insert(GameRules.gold_votes, gold)
	table.insert(GameRules.invoke_cd_votes, invoke_cd)
	table.insert(GameRules.invoke_slots_votes, invoke_slots)
	table.insert(GameRules.mana_cost_reduction_votes, mana_cost_reduction)
	table.insert(GameRules.wtf_votes, wtf)
	table.insert(GameRules.fast_respawn_votes, fast_respawn)
	table.insert(GameRules.gold_multiplier_votes, gold_multiplier)
	table.insert(GameRules.xp_multiplier_votes, xp_multiplier)	

    if (GameRules.players_voted + GameRules.players_skipped_vote == GameRules.player_count ) then
    	RetroDota:OnEveryoneVoted()
    else
    	print( GameRules.players_voted + GameRules.players_skipped_vote .. " out of " .. GameRules.player_count .. " have voted")
    end

end


-- Auxiliar function to return the average numeric value of the votes rounded down
function RoundedDownAverage( table )
    	
	local value = 0
	local cant = GameRules.players_voted

	for k,v in pairs(table) do
		value = value + v
	end

	print("   Averaging: " .. value.."/"..GameRules.players_voted)
	value = value / cant
    value = math.floor(value+0.5)
    print("   Rounded: ".. value)

	return tostring(value)
end

function RetroDota:OnEveryoneVoted()
	
	print("All Players have voted. Averaging the values now")

	print("-> Win Condition")
    GameRules.win_condition = RoundedDownAverage(GameRules.win_condition_votes)
    print("=> "..GameRules.vote_options.kills_to_win[GameRules.win_condition])

	print("-> Starting Level")
	GameRules.starting_level = RoundedDownAverage(GameRules.level_votes)
	print("==> "..GameRules.vote_options.starting_level[GameRules.starting_level])

	print("-> Starting Gold")
	GameRules.starting_gold = RoundedDownAverage(GameRules.gold_votes)
	print("==> "..GameRules.vote_options.starting_gold[GameRules.starting_gold])

	print("-> Invoke Cooldown")
	GameRules.invoke_cd = RoundedDownAverage(GameRules.invoke_cd_votes)
	print("==> "..GameRules.vote_options.invoke_cd[GameRules.invoke_cd])

	print("-> Mana Cost")
	GameRules.mana_cost = RoundedDownAverage(GameRules.mana_cost_reduction_votes)
	print("==> "..GameRules.vote_options.mana_cost[GameRules.mana_cost])

	print("-> Invoke Slots")
	GameRules.invoke_slots = RoundedDownAverage(GameRules.invoke_slots_votes)
	print("==> "..GameRules.invoke_slots)

	print("-> WTF?")
	GameRules.wtf = RoundedDownAverage(GameRules.wtf_votes)
	print("==> "..GameRules.wtf)

	print("-> Fast Respawn?")
	GameRules.fast_respawn = RoundedDownAverage(GameRules.fast_respawn_votes)
	print("==> "..GameRules.fast_respawn)

	print("-> Gold Multiplier")
	GameRules.gold_multiplier = RoundedDownAverage(GameRules.gold_multiplier_votes)
	print("==> "..GameRules.gold_multiplier)

	print("-> XP Multiplier")
	GameRules.xp_multiplier = RoundedDownAverage(GameRules.xp_multiplier_votes)
	print("==> "..GameRules.xp_multiplier)

	print("=== FINISHED VOTE AVERAGING ===")

    GameRules:SendCustomMessage("<font color='#2EFE2E'>Finished voting!</font>", 0, 0)

 --[[  
    -- Add settings to our stat collector
    statcollection.addStats({
        modes = {
            difficulty = GameRules.DIFFICULTY
        }
    })

    -- Find the barrier_voting and obstructions_voting entities in the map and disable them
    local barrier = Entities:FindByName(nil,"barrier_voting")
	barrier:RemoveSelf()

	local obstructions = Entities:FindAllByName("obstructions_voting")
	for _,v in pairs(obstructions) do
		v:SetEnabled(false,false)
		print("Obstructions disabled")
	end]]
	
end



--Remove ancient invulnerability if both towers have been destroyed.
--[[function RetroDota:OnLastHit(keys)
	if keys.TowerKill == 1 then
		local killed_tower = EntIndexToHScript(keys.EntKilled)
		if killed_tower:IsTower() then
			local tower_team = killed_tower:GetTeam()
			if tower_team == DOTA_TEAM_GOODGUYS then
				--
			elseif tower_team == DOTA_TEAM_BADGUYS then
				local dire_tower_still_alive = false
				
				local towers = Entities:FindAllByClassname("npc_dota_tower")
				for i, individual_tower in ipairs(towers) do
					if individual_tower:GetTeam() == DOTA_TEAM_BADGUYS and individual_tower:IsAlive() then
						dire_tower_still_alive = true
						--print("tower still alive")
					end
				end
				
				if not dire_tower_still_alive then  --Remove invulnerability from the ancient if the towers have been destroyed.
					--local dire_ancient = Entities:FindAllByClassname("npc_dota_badguys_fort")
					local dire_ancient = Entities:FindAllByName("npc_dire_fort")  --This does not appear to return anything.
					for i, individual_ancient in ipairs(dire_ancient) do
						individual_ancient:SetInvulnCount(0)
						print("ancient invulnerability lost")
					end
				end
			end
		end
	end
end]]