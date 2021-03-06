//print an error message to world.log


// On Linux/Unix systems the line endings are LF, on windows it's CRLF, admins that don't use notepad++
// will get logs that are one big line if the system is Linux and they are using notepad.  This solves it by adding CR to every line ending
// in the logs.  ascii character 13 = CR

/var/global/log_end= world.system_type == UNIX ? ascii2text(13) : ""

//print an error message to world.log
#define ERROR(MSG) error("[MSG] in [__FILE__] at line [__LINE__] src: [src] usr: [usr].")
/proc/error(msg)
	world.log << "## ERROR: [msg][log_end]"

//print a warning message to world.log
#define WARNING(MSG) warning("[MSG] in [__FILE__] at line [__LINE__] src: [src] usr: [usr].")
/proc/warning(msg)
	world.log << "## WARNING: [msg][log_end]"

//print a testing-mode debug message to world.log
/proc/testing(msg)
	world.log << "## TESTING: [msg][log_end]"

/proc/log_admin(text)
	admin_log.Add(text)
	if (config.log_admin)
		diary << "\[[time_stamp()]]ADMIN: [revert_ja(text)][log_end]"


/proc/log_debug(text)
	if (config.log_debug)
		diary << "\[[time_stamp()]]DEBUG: [text][log_end]"

	for(var/client/C in admins)
		if(C.prefs.chat_toggles & CHAT_DEBUGLOGS)
			to_chat(C, "DEBUG: [text]")


/proc/log_game(text)
	if (config.log_game)
		diary << "\[[time_stamp()]]GAME: [text][log_end]"

/proc/log_vote(text)
	if (config.log_vote)
		diary << "\[[time_stamp()]]VOTE: [revert_ja(text)][log_end]"

/proc/log_access(text)
	if (config.log_access)
		diary << "\[[time_stamp()]]ACCESS: [text][log_end]"

/proc/log_say(text)
	if (config.log_say)
		diary << "\[[time_stamp()]]SAY: [revert_ja(text)][log_end]"

/proc/log_ooc(text)
	if (config.log_ooc)
		diary << "\[[time_stamp()]]OOC: [revert_ja(text)][log_end]"

/proc/log_whisper(text)
	if (config.log_whisper)
		diary << "\[[time_stamp()]]WHISPER: [revert_ja(text)][log_end]"

/proc/log_emote(text)
	if (config.log_emote)
		diary << "\[[time_stamp()]]EMOTE: [revert_ja(text)][log_end]"

/proc/log_attack(text)
	if (config.log_attack)
		diary << "\[[time_stamp()]]ATTACK: [text][log_end]" //Seperate attack logs? Why?  FOR THE GLORY OF SATAN!

/proc/log_adminsay(text)
	if (config.log_adminchat)
		diary << "\[[time_stamp()]]ADMINSAY: [revert_ja(text)][log_end]"

/proc/log_adminwarn(text)
	if (config.log_adminwarn)
		diary << "\[[time_stamp()]]ADMINWARN: [revert_ja(text)][log_end]"

/proc/log_pda(text)
	if (config.log_pda)
		diary << "\[[time_stamp()]]PDA: [revert_ja(text)][log_end]"

/proc/log_misc(text)
	diary << "\[[time_stamp()]]MISC: [text][log_end]"

//pretty print a direction bitflag, can be useful for debugging.
/proc/print_dir(dir)
	var/list/comps = list()
	if(dir & NORTH) comps += "NORTH"
	if(dir & SOUTH) comps += "SOUTH"
	if(dir & EAST) comps += "EAST"
	if(dir & WEST) comps += "WEST"
	if(dir & UP) comps += "UP"
	if(dir & DOWN) comps += "DOWN"

	return english_list(comps, nothing_text="0", and_text="|", comma_text="|")

proc/log_fax(text)
	if (config.log_fax)
		diary << "\[[time_stamp()]]FAX: [revert_ja(text)][log_end]"
