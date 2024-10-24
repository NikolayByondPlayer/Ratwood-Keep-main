/datum/migrant_role
	abstract_type = /datum/migrant_role
	/// Name of the role
	var/name = "MIGRANT ROLE"
	/// Restricts species if the list is not null
	var/list/allowed_races = RACES_VERY_SHUNNED_UP	//QUICK FIX TO EXCLUDE SEELIE
	/// Restricts sexes if list is not null
	var/list/allowed_sexes
	/// Restricts ages if list is not null
	var/list/allowed_ages
	/// Typepath of outfit for the migrant role
	var/outfit
	/// Typepath of the antag datum for the migrant role
	var/antag_datum
	/// If defined they'll get adv class rolls
	var/list/advclass_cat_rolls
	/// Text to greet player of this role in the wave
	var/greet_text
	/// Whether to grant a lit torch upon spawn
	var/grant_lit_torch = FALSE
	//Whether to display "wandering Human" rather than their job title
	var/show_wanderer_examine = TRUE
	var/advjob_examine = TRUE
	var/banned_leprosy = TRUE
	var/banned_lunatic = TRUE

/datum/migrant_role/proc/after_spawn(mob/living/carbon/human/character)
	return

/datum/migrant_role/adventurer
	name = "Adventurer"
	advclass_cat_rolls = list(CTAG_ADVENTURER = 5)

/datum/migrant_role/bandit
	name = "Bandit"
	antag_datum = /datum/antagonist/bandit
	grant_lit_torch = TRUE