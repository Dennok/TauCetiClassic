var/global/datum/controller/gameticker/ticker

#define GAME_STATE_PREGAME		1
#define GAME_STATE_SETTING_UP	2
#define GAME_STATE_PLAYING		3
#define GAME_STATE_FINISHED		4


/datum/controller/gameticker
	var/const/restart_timeout = 600
	var/current_state = GAME_STATE_PREGAME

	var/hide_mode = 0
	var/datum/game_mode/mode = null
	var/event_time = null
	var/event = 0

	var/login_music			// music played in pregame lobby

	var/list/datum/mind/minds = list()//The people in the game. Used for objective tracking.

	var/Bible_icon_state	// icon_state the chaplain has chosen for his bible
	var/Bible_item_state	// item_state the chaplain has chosen for his bible
	var/Bible_name			// name of the bible
	var/Bible_deity_name

	var/random_players = 0 	// if set to nonzero, ALL players who latejoin or declare-ready join will have random appearances/genders

	var/list/syndicate_coalition = list() // list of traitor-compatible factions
	var/list/factions = list()			  // list of all factions
	var/list/availablefactions = list()	  // list of factions with openings

	var/pregame_timeleft = 0

	var/delay_end = 0	//if set to nonzero, the round will not restart on it's own

	var/triai = 0//Global holder for Triumvirate

/datum/controller/gameticker/proc/pregame()
	login_music = pick(\
	/*
	'sound/music/space.ogg',\
	'sound/music/clouds.s3m',\
	'sound/music/title1.ogg',\	//disgusting
	*/
	'sound/music/space_oddity.ogg',\
	'sound/music/b12_combined_start.ogg',\
	'sound/music/title2.ogg',\
	'sound/music/traitor.ogg',\
	'tauceti/sounds/lobby/sundown.ogg',\
	'tauceti/sounds/lobby/hanging_masses.ogg',\
	'tauceti/sounds/lobby/admiral-station-13.ogg',\
	'tauceti/sounds/lobby/robocop_gb_intro.ogg')
	/*
	//New year part
	'tauceti/modules/_holidays/new_year/music/Carol_of_the_Bells.ogg',\
	'tauceti/modules/_holidays/new_year/music/Last_Christmas.ogg',\
	'tauceti/modules/_holidays/new_year/music/Pop_Culture.ogg',\
	'tauceti/modules/_holidays/new_year/music/Zov_Ktulhu.ogg')
	*/
	do
		pregame_timeleft = 180
		world << "<B><FONT color='blue'>Welcome to the pre-game lobby!</FONT></B>"
		world << "Please, setup your character and select ready. Game will start in [pregame_timeleft] seconds"
		while(current_state == GAME_STATE_PREGAME)
			for(var/i=0, i<10, i++)
				sleep(1)
				vote.process()
			if(going)
				pregame_timeleft--
			if(pregame_timeleft == config.vote_autogamemode_timeleft)
				if(!vote.time_remaining)
					vote.autogamemode()	//Quit calling this over and over and over and over.
					while(vote.time_remaining)
						for(var/i=0, i<10, i++)
							sleep(1)
							vote.process()
			if(pregame_timeleft <= 0)
				current_state = GAME_STATE_SETTING_UP
	while (!setup())


/datum/controller/gameticker/proc/setup()
	//Create and announce mode
	if(master_mode=="secret")
		src.hide_mode = 1
	if(master_mode=="bs12" || master_mode=="tau classic" || master_mode=="ayyy lmao" || master_mode=="WTF?")
		src.hide_mode = 1
	var/list/datum/game_mode/runnable_modes
	if((master_mode=="random") || (master_mode=="secret"))
		runnable_modes = config.get_runnable_modes()
		if (runnable_modes.len==0)
			current_state = GAME_STATE_PREGAME
			world << "<B>Unable to choose playable game mode.</B> Reverting to pre-game lobby."
			return 0
		if(secret_force_mode != "secret")
			var/datum/game_mode/M = config.pick_mode(secret_force_mode)
			if(M.can_start())
				src.mode = config.pick_mode(secret_force_mode)
		job_master.ResetOccupations()
		if(!src.mode)
			src.mode = pickweight(runnable_modes)
		if(src.mode)
			var/mtype = src.mode.type
			src.mode = new mtype
	else if(master_mode=="bs12" || master_mode=="tau classic" || master_mode=="ayyy lmao" || master_mode=="WTF?")
		runnable_modes = config.get_custom_modes(master_mode)
		if (runnable_modes.len==0)
			current_state = GAME_STATE_PREGAME
			world << "<B>Unable to choose playable game mode.</B> Reverting to pre-game lobby."
			return 0
		job_master.ResetOccupations()
		if(!src.mode)
			src.mode = pick(runnable_modes)
		if(src.mode)
			var/mtype = src.mode.type
			src.mode = new mtype
	else
		src.mode = config.pick_mode(master_mode)
	if (!src.mode.can_start())
		world << "<B>Unable to start [mode.name].</B> Not enough players, [mode.required_players] players needed. Reverting to pre-game lobby."
		qdel(mode)
		current_state = GAME_STATE_PREGAME
		job_master.ResetOccupations()
		return 0

	//Configure mode and assign player to special mode stuff
	job_master.DivideOccupations() //Distribute jobs
	var/can_continue = src.mode.pre_setup()//Setup special modes
	if(!can_continue)
		qdel(mode)
		current_state = GAME_STATE_PREGAME
		world << "<B>Error setting up [master_mode].</B> Reverting to pre-game lobby."
		job_master.ResetOccupations()
		return 0

	if(hide_mode)
		var/list/modes = new
		for (var/datum/game_mode/M in runnable_modes)
			modes+=M.name
		modes = sortList(modes)
		world << "<B>The current game mode is - Secret!</B>"
		world << "<B>Possibilities:</B> [english_list(modes)]"
	else
		src.mode.announce()

	create_characters() //Create player characters and transfer them
	collect_minds()
	equip_characters()
	data_core.manifest()
	current_state = GAME_STATE_PLAYING

	callHook("roundstart")

	//here to initialize the random events nicely at round start
	setup_economy()

	spawn(0)//Forking here so we dont have to wait for this to finish
		mode.post_setup()
		//Cleanup some stuff
		for(var/obj/effect/landmark/start/S in landmarks_list)
			//Deleting Startpoints but we need the ai point to AI-ize people later
			if (S.name != "AI")
				qdel(S)
		world << "<FONT color='blue'><B>Enjoy the game!</B></FONT>"
		world << sound('sound/AI/welcome.ogg') // Skie
		//Holiday Round-start stuff	~Carn
		Holiday_Game_Start()

	//start_events() //handles random events and space dust.
	//new random event system is handled from the MC.

	var/admins_number = 0
	for(var/client/C)
		if(C.holder)
			admins_number++
	if(admins_number == 0)
		send2adminirc("Round has started with no admins online.")

	supply_shuttle.process() 		//Start the supply shuttle regenerating points -- TLE
	master_controller.process()		//Start master_controller.process()

	processScheduler.start()

	for(var/obj/multiz/ladder/L in world) L.connect() //Lazy hackfix for ladders. TODO: move this to an actual controller. ~ Z

	if(config.sql_enabled)
		spawn(3000)
		statistic_cycle() // Polls population totals regularly and stores them in an SQL DB -- TLE

	config.allow_vote_restart = 0
	config.allow_vote_mode = 0
	spawn(36000)
		if(!( config.allow_vote_restart && config.allow_vote_mode))
			world << "\b Voting allowed"
			config.allow_vote_restart = 1
			config.allow_vote_mode = 1

	return 1

/datum/controller/gameticker
	//station_explosion used to be a variable for every mob's hud. Which was a waste!
	//Now we have a general cinematic centrally held within the gameticker....far more efficient!
	var/obj/screen/cinematic = null

	//Plus it provides an easy way to make cinematics for other events. Just use this as a template :)
	proc/station_explosion_cinematic(var/station_missed=0, var/override = null)
		if( cinematic )	return	//already a cinematic in progress!

		//initialise our cinematic screen object
		cinematic = new(src)
		cinematic.icon = 'icons/effects/station_explosion.dmi'
		cinematic.icon_state = "station_intact"
		cinematic.layer = 20
		cinematic.mouse_opacity = 0
		cinematic.screen_loc = "1,0"

		var/obj/structure/stool/bed/temp_buckle = new(src)
		//Incredibly hackish. It creates a bed within the gameticker (lol) to stop mobs running around
		if(station_missed)
			for(var/mob/living/M in living_mob_list)
				M.buckled = temp_buckle				//buckles the mob so it can't do anything
				if(M.client)
					M.client.screen += cinematic	//show every client the cinematic
		else	//nuke kills everyone on z-level 1 to prevent "hurr-durr I survived"
			for(var/mob/living/M in living_mob_list)
				M.buckled = temp_buckle
				if(M.client)
					M.client.screen += cinematic

				switch(M.z)
					if(0)	//inside a crate or something
						var/turf/T = get_turf(M)
						if(T && T.z==1)				//we don't use M.death(0) because it calls a for(/mob) loop and
							M.health = 0
							M.stat = DEAD
					if(1)	//on a z-level 1 turf.
						M.health = 0
						M.stat = DEAD

		//Now animate the cinematic
		switch(station_missed)
			if(1)	//nuke was nearby but (mostly) missed
				if( mode && !override )
					override = mode.name
				switch( override )
					if("nuclear emergency") //Nuke wasn't on station when it blew up
						flick("intro_nuke",cinematic)
						sleep(35)
						world << sound('sound/effects/explosionfar.ogg')
						flick("station_intact_fade_red",cinematic)
						cinematic.icon_state = "summary_nukefail"
					else
						flick("intro_nuke",cinematic)
						sleep(35)
						world << sound('sound/effects/explosionfar.ogg')
						//flick("end",cinematic)


			if(2)	//nuke was nowhere nearby	//TODO: a really distant explosion animation
				sleep(50)
				world << sound('sound/effects/explosionfar.ogg')


			else	//station was destroyed
				if( mode && !override )
					override = mode.name
				switch( override )
					if("nuclear emergency") //Nuke Ops successfully bombed the station
						flick("intro_nuke",cinematic)
						sleep(35)
						flick("station_explode_fade_red",cinematic)
						world << sound('sound/effects/explosionfar.ogg')
						cinematic.icon_state = "summary_nukewin"
					if("AI malfunction") //Malf (screen,explosion,summary)
						flick("intro_malf",cinematic)
						sleep(76)
						flick("station_explode_fade_red",cinematic)
						world << sound('sound/effects/explosionfar.ogg')
						cinematic.icon_state = "summary_malf"
					if("blob") //Station nuked (nuke,explosion,summary)
						flick("intro_nuke",cinematic)
						sleep(35)
						flick("station_explode_fade_red",cinematic)
						world << sound('sound/effects/explosionfar.ogg')
						cinematic.icon_state = "summary_selfdes"
					else //Station nuked (nuke,explosion,summary)
						flick("intro_nuke",cinematic)
						sleep(35)
						flick("station_explode_fade_red", cinematic)
						world << sound('sound/effects/explosionfar.ogg')
						cinematic.icon_state = "summary_selfdes"
				for(var/mob/living/M in living_mob_list)
					if(M.loc.z == 1)
						M.death()//No mercy
		//If its actually the end of the round, wait for it to end.
		//Otherwise if its a verb it will continue on afterwards.
		sleep(300)

		if(cinematic)	qdel(cinematic)		//end the cinematic
		if(temp_buckle)	qdel(temp_buckle)	//release everybody
		return


	proc/create_characters()
		for(var/mob/new_player/player in player_list)
			sleep(1)
			if(player && player.ready && player.mind)
				joined_player_list += player.ckey
				if(player.mind.assigned_role=="AI")
					player.close_spawn_windows()
					player.AIize()
				else if(!player.mind.assigned_role)
					continue
				else
					player.create_character()
					qdel(player)


	proc/collect_minds()
		for(var/mob/living/player in player_list)
			if(player.mind)
				ticker.minds += player.mind


	proc/equip_characters()
		var/captainless=1
		for(var/mob/living/carbon/human/player in player_list)
			if(player && player.mind && player.mind.assigned_role)
				if(player.mind.assigned_role == "Captain")
					captainless=0
				if(player.mind.assigned_role != "MODE")
					job_master.EquipRank(player, player.mind.assigned_role, 0)
					EquipCustomItems(player)
		if(captainless)
			for(var/mob/M in player_list)
				if(!istype(M,/mob/new_player))
					M << "Captainship not forced on anyone."


	proc/process()
		if(current_state != GAME_STATE_PLAYING)
			return 0

		mode.process()

		emergency_shuttle.process()

		var/mode_finished = mode.check_finished() || (emergency_shuttle.location == 2 && emergency_shuttle.alert == 1)
		if(!mode.explosion_in_progress && mode_finished)
			current_state = GAME_STATE_FINISHED

			spawn
				declare_completion()

			spawn(50)
				callHook("roundend")

				if (mode.station_was_nuked)
					feedback_set_details("end_proper","nuke")
					if(!delay_end)
						world << "\blue <B>Rebooting due to destruction of station in [restart_timeout/10] seconds</B>"
				else
					feedback_set_details("end_proper","proper completion")
					if(!delay_end)
						world << "\blue <B>Restarting in [restart_timeout/10] seconds</B>"

				for(var/client/C in clients)
					C.log_client_ingame_age_to_db()

				world.save_last_mode(ticker.mode.name)

				if(blackbox)
					blackbox.save_all_data_to_sql()

				if(!delay_end)
					sleep(restart_timeout)
					if(!delay_end)
						world.Reboot()
					else
						world << "\blue <B>An admin has delayed the round end</B>"
						send2slack_service("An admin has delayed the round end")
				else
					world << "\blue <B>An admin has delayed the round end</B>"
					send2slack_service("An admin has delayed the round end")

		return 1

	proc/getfactionbyname(var/name)
		for(var/datum/faction/F in factions)
			if(F.name == name)
				return F


/datum/controller/gameticker/proc/declare_completion()
	var/station_evacuated
	if(emergency_shuttle.location > 0)
		station_evacuated = 1
	var/num_survivors = 0
	var/num_escapees = 0

	world << "<BR><BR><BR><FONT size=3><B>The round has ended.</B></FONT>"

	//Player status report
	for(var/mob/Player in mob_list)
		if(Player.mind)
			if(Player.stat != DEAD && !isbrain(Player))
				num_survivors++
				if(station_evacuated) //If the shuttle has already left the station
					var/turf/playerTurf = get_turf(Player)
					if(playerTurf.z != 2)
						Player << "<span class='danger>You managed to survive, but were marooned on [station_name()]...</span>"
					else
						num_escapees++
						Player << "<span class='green'><b>You managed to survive the events on [station_name()] as [Player.real_name].</b></span>"
				else
					Player << "<span class='green'><b>You managed to survive the events on [station_name()] as [Player.real_name].</b></span>"
			else
				Player << "<span class='danger>You did not survive the events on [station_name()]...</span>"

	//Round statistics report
	var/datum/station_state/end_state = new /datum/station_state()
	end_state.count()
	var/station_integrity = "---"
	if(start_state)
		station_integrity = round( 100.0 *  start_state.score(end_state), 0.1)
	if(!joined_player_list.len)	//we can't into division by zero
		joined_player_list += 1

	world << "<BR>[TAB]Shift Duration: <B>[round(world.time / 36000)]:[add_zero(world.time / 600 % 60, 2)]:[world.time / 100 % 6][world.time / 100 % 10]</B>"
	world << "<BR>[TAB]Station Integrity: <B>[mode.station_was_nuked ? "<font color='red'>Destroyed</font>" : "[station_integrity]%"]</B>"
	world << "<BR>[TAB]Total Population: <B>[joined_player_list.len]</B>"
	world << "<BR>[TAB]Survival Rate: <B>[num_survivors] ([round((num_survivors/joined_player_list.len)*100, 0.1)]%)</B>"
	if(station_evacuated)
		world << "<BR>[TAB]Evacuation Rate: <B>[num_escapees] ([round((num_escapees/joined_player_list.len)*100, 0.1)]%)</B>"
	world << "<BR>"

	//Silicon laws report
	var/ai_completions = "<h1>Round End Information</h1><HR>"

	var/ai_or_borgs_in_round = 0
	for (var/mob/living/silicon/silicon in mob_list)
		if(silicon)
			ai_or_borgs_in_round = 1
			break

	if(ai_or_borgs_in_round)
		ai_completions += "<H3>Silicons Laws</H3>"
		for (var/mob/living/silicon/ai/aiPlayer in mob_list)
			if(!aiPlayer)
				continue
			var/icon/flat = getFlatIcon(aiPlayer)
			end_icons += flat
			var/tempstate = end_icons.len
			if (aiPlayer.stat != 2)
				ai_completions += {"<BR><B><img src="logo_[tempstate].png"> [aiPlayer.name] (Played by: [aiPlayer.key])'s laws at the end of the game were:</B>"}
			else
				ai_completions += {"<BR><B><img src="logo_[tempstate].png"> [aiPlayer.name] (Played by: [aiPlayer.key])'s laws when it was deactivated were:</B>"}
			ai_completions += "<BR>[aiPlayer.write_laws()]"

			if (aiPlayer.connected_robots.len)
				var/robolist = "<BR><B>The AI's loyal minions were:</B> "
				for(var/mob/living/silicon/robot/robo in aiPlayer.connected_robots)
					robolist += "[robo.name][robo.stat?" (Deactivated) (Played by: [robo.key]), ":" (Played by: [robo.key]), "]"
				ai_completions += "[robolist]"

		var/dronecount = 0

		for (var/mob/living/silicon/robot/robo in mob_list)
			if(!robo)
				continue
			if(istype(robo,/mob/living/silicon/robot/drone))
				dronecount++
				continue
			var/icon/flat = getFlatIcon(robo,exact=1)
			end_icons += flat
			var/tempstate = end_icons.len
			if (!robo.connected_ai)
				if (robo.stat != 2)
					ai_completions += {"<BR><B><img src="logo_[tempstate].png"> [robo.name] (Played by: [robo.key]) survived as an AI-less borg! Its laws were:</B>"}
				else
					ai_completions += {"<BR><B><img src="logo_[tempstate].png"> [robo.name] (Played by: [robo.key]) was unable to survive the rigors of being a cyborg without an AI. Its laws were:</B>"}
			else
				ai_completions += {"<BR><B><img src="logo_[tempstate].png"> [robo.name] (Played by: [robo.key]) [robo.stat!=2?"survived":"perished"] as a cyborg slaved to [robo.connected_ai]! Its laws were:</B>"}
			ai_completions += "<BR>[robo.write_laws()]"

		if(dronecount)
			ai_completions << "<B>There [dronecount>1 ? "were" : "was"] [dronecount] industrious maintenance [dronecount>1 ? "drones" : "drone"] this round.</B>"

		ai_completions += "<HR>"

	mode.declare_completion()//To declare normal completion.

	ai_completions += "<BR><h2>Mode Result</h2>"
	ai_completions += "[mode.completion_text]<HR>"

	scoreboard(ai_completions)

	return 1

/datum/controller/gameticker/proc/achievement_declare_completion()
	var/text = "<br><FONT size = 5><b>Additionally, the following players earned achievements:</b></FONT>"
	var/icon/cup = icon('icons/obj/drinks.dmi', "golden_cup")
	end_icons += cup
	var/tempstate = end_icons.len
	for(var/winner in achievements)
		text += {"<br><img src="logo_[tempstate].png"> [winner]"}

	return text
