/obj/item/organ/heart
	name = "heart"
	desc = ""
	icon_state = "heart-on"
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_HEART

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = 5 * STANDARD_ORGAN_DECAY		//designed to fail about 5 minutes after death

	low_threshold_passed = span_info("Prickles of pain appear then die out from within my chest...")
	high_threshold_passed = span_warning("Something inside my chest hurts, and the pain isn't subsiding. You notice myself breathing far faster than before.")
	now_fixed = span_info("My heart begins to beat again.")
	high_threshold_cleared = span_info("The pain in my chest has died down, and my breathing becomes more relaxed.")

	// Heart attack code is in code/modules/mob/living/carbon/human/life.dm
	var/beating = 1
	var/icon_base = "heart"
	attack_verb = list("beat", "thumped")
	var/beat = BEAT_NONE//is this mob having a heatbeat sound played? if so, which?
	var/failed = FALSE		//to prevent constantly running failing code
	var/operated = FALSE	//whether the heart's been operated on to fix some of its damages

	/// Markings on this heart for the maniac antagonist.
	/// Assoc list using Maniac antag datums as keys. One for each maniac, but not for each wonder.
	var/inscryptions = list()
	/// Assoc list tracking antag datums to 4-letter maniac keys
	var/inscryption_keys = list()
	/// Assoc list tracking antag datums to wonder ID number (1-4)
	var/maniacs2wonder_ids = list()
	/// List of Maniac datums that have inscribed on this heart
	var/maniacs = list()

/obj/item/organ/heart/examine(mob/user)
	. = ..()
	if(isadminobserver(user) && inscryptions)
		for(var/datum/antagonist/maniac/maniaque in maniacs)
			var/N = maniaque.owner?.name
			var/W = LAZYACCESS(maniacs2wonder_ids, maniaque)
			var/P = LAZYACCESS(inscryptions, maniaque)
			. += span_notice("Marked by [N ? "[N]'s " : ""]Wonder[W ? " #[W]" : ""]: [P].")
		return .
	var/datum/antagonist/maniac/dreamer = user.mind?.has_antag_datum(/datum/antagonist/maniac)
	if(dreamer)
		if(!maniacs)
			. += "<span class='danger'><b>There is NOTHING on this heart. \
				Should be? Following the TRUTH - not here. I need to keep LOOKING. Keep FOLLOWING my heart.</b></span>"
		else
			if(!(dreamer in maniacs))
				. += "<span class='danger'><b>This heart has INDECIPHERABLE etching. \
					Following the TRUTH - not here. I need to keep LOOKING. Keep FOLLOWING my heart.</b></span>"
				return .
			var/my_inscryption = LAZYACCESS(inscryptions, dreamer)
			. += "<b><span class='warning'>There's something CUT on this HEART.</span>\n\"[my_inscryption]. Add it to the other keys to exit INRL.\"</b>"
			if(!(my_inscryption in dreamer.hearts_seen))
				var/wonder_code = LAZYACCESS(maniacs2wonder_ids, dreamer)
				dreamer.hearts_seen += my_inscryption
				SEND_SOUND(dreamer, 'sound/villain/newheart.ogg')
				user.log_message("got the Maniac inscryption [wonder_code ? " for Wonder #[wonder_code]" : ""][my_inscryption ? ": \"[strip_html_simple(my_inscryption)].\"" : ""]", LOG_GAME)
				if(wonder_code == 4)
					message_admins("Maniac [ADMIN_LOOKUPFLW(user)] has obtained the fourth and final heart code.")

/obj/item/organ/heart/update_icon()
	if(beating)
		icon_state = "[icon_base]-on"
	else
		icon_state = "[icon_base]-off"

/obj/item/organ/heart/Remove(mob/living/carbon/M, special = 0)
	..()
	if(!special)
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 120)

/obj/item/organ/heart/proc/stop_if_unowned()
	if(!owner)
		Stop()

/obj/item/organ/heart/attack_self(mob/user)
	..()
	if(!beating)
		user.visible_message("<span class='notice'>[user] squeezes [src] to \
			make it beat again!</span>",span_notice("I squeeze [src] to make it beat again!"))
		Restart()
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 80)

/obj/item/organ/heart/proc/Stop()
	beating = 0
	update_icon()
	return 1

/obj/item/organ/heart/proc/Restart()
	beating = 1
	update_icon()
	return 1

/obj/item/organ/heart/prepare_eat(mob/living/carbon/human/user)
	var/obj/item/reagent_containers/food/snacks/organ/S = ..()
	S.icon_state = "heart-off"
	var/nothing = FALSE
/*	if(user.mind)
		var/datum/antagonist/werewolf/C = user.mind.has_antag_datum(/datum/antagonist/werewolf)
		if(C)
			var/datum/objective/hearteating/H = locate(/datum/objective/hearteating) in C.objectives
			if(H)
				testing("heartseaten++")
				H.hearts_eaten++
				nothing = TRUE
				S.eat_effect = /datum/status_effect/buff/foodbuff*/
	if(!nothing)
		S.eat_effect = /datum/status_effect/debuff/uncookedfood
	return S

/obj/item/organ/heart/on_life()
	..()
	if(owner.client && beating)
		failed = FALSE
		var/sound/slowbeat = sound('sound/blank.ogg', repeat = TRUE)
		var/sound/fastbeat = sound('sound/blank.ogg', repeat = TRUE)
		var/mob/living/carbon/H = owner


		if(H.health <= H.crit_threshold && beat != BEAT_SLOW)
			beat = BEAT_SLOW
			H.playsound_local(get_turf(H), slowbeat,40,0, channel = CHANNEL_HEARTBEAT)
//			to_chat(owner, span_notice("I feel my heart slow down..."))
		if(beat == BEAT_SLOW && H.health > H.crit_threshold)
			H.stop_sound_channel(CHANNEL_HEARTBEAT)
			beat = BEAT_NONE

		if(H.jitteriness)
			if(H.health > HEALTH_THRESHOLD_FULLCRIT && (!beat || beat == BEAT_SLOW))
				H.playsound_local(get_turf(H),fastbeat,40,0, channel = CHANNEL_HEARTBEAT)
				beat = BEAT_FAST
		else if(beat == BEAT_FAST)
			H.stop_sound_channel(CHANNEL_HEARTBEAT)
			beat = BEAT_NONE

	if(organ_flags & ORGAN_FAILING)	//heart broke, stopped beating, death imminent
		if(owner.stat == CONSCIOUS)
			owner.visible_message(span_danger("[owner] clutches at [owner.p_their()] chest as if [owner.p_their()] heart is stopping!"), \
				span_danger("I feel a terrible pain in my chest, as if my heart has stopped!"))
		owner.set_heartattack(TRUE)
		failed = TRUE

/obj/item/organ/heart/cursed
	name = "cursed heart"
	desc = ""
	icon_state = "cursedheart-off"
	icon_base = "cursedheart"
	decay_factor = 0
	actions_types = list(/datum/action/item_action/organ_action/cursed_heart)
	var/last_pump = 0
	var/add_colour = TRUE //So we're not constantly recreating colour datums
	var/pump_delay = 30 //you can pump 1 second early, for lag, but no more (otherwise you could spam heal)
	var/blood_loss = 100 //600 blood is human default, so 5 failures (below 122 blood is where humans die because reasons?)

	//How much to heal per pump, negative numbers would HURT the player
	var/heal_brute = 0
	var/heal_burn = 0
	var/heal_oxy = 0


/obj/item/organ/heart/cursed/attack(mob/living/carbon/human/H, mob/living/carbon/human/user, obj/target)
	if(H == user && istype(H))
		playsound(user,'sound/blank.ogg',40,TRUE)
		user.temporarilyRemoveItemFromInventory(src, TRUE)
		Insert(user)
	else
		return ..()

/obj/item/organ/heart/cursed/on_life()
	if(world.time > (last_pump + pump_delay))
		if(ishuman(owner) && owner.client) //While this entire item exists to make people suffer, they can't control disconnects.
			var/mob/living/carbon/human/H = owner
			if(H.dna && !(NOBLOOD in H.dna.species.species_traits))
				H.blood_volume = max(H.blood_volume - blood_loss, 0)
				to_chat(H, span_danger("I have to keep pumping my blood!"))
				if(add_colour)
					H.add_client_colour(/datum/client_colour/cursed_heart_blood) //bloody screen so real
					add_colour = FALSE
		else
			last_pump = world.time //lets be extra fair *sigh*

/obj/item/organ/heart/cursed/Insert(mob/living/carbon/M, special = 0)
	..()
	if(owner)
		to_chat(owner, span_danger("My heart has been replaced with a cursed one, you have to pump this one manually otherwise you'll die!"))

/obj/item/organ/heart/cursed/Remove(mob/living/carbon/M, special = 0)
	..()
	M.remove_client_colour(/datum/client_colour/cursed_heart_blood)

/datum/action/item_action/organ_action/cursed_heart
	name = "Pump my blood"

//You are now brea- pumping blood manually
/datum/action/item_action/organ_action/cursed_heart/Trigger()
	. = ..()
	if(. && istype(target, /obj/item/organ/heart/cursed))
		var/obj/item/organ/heart/cursed/cursed_heart = target

		if(world.time < (cursed_heart.last_pump + (cursed_heart.pump_delay-10))) //no spam
			to_chat(owner, span_danger("Too soon!"))
			return

		cursed_heart.last_pump = world.time
		playsound(owner,'sound/blank.ogg',40,TRUE)
		to_chat(owner, span_notice("My heart beats."))

		var/mob/living/carbon/human/H = owner
		if(istype(H))
			if(H.dna && !(NOBLOOD in H.dna.species.species_traits))
				H.blood_volume = min(H.blood_volume + cursed_heart.blood_loss*0.5, BLOOD_VOLUME_MAXIMUM)
				H.remove_client_colour(/datum/client_colour/cursed_heart_blood)
				cursed_heart.add_colour = TRUE
				H.adjustBruteLoss(-cursed_heart.heal_brute)
				H.adjustFireLoss(-cursed_heart.heal_burn)
				H.adjustOxyLoss(-cursed_heart.heal_oxy)


/datum/client_colour/cursed_heart_blood
	priority = 100 //it's an indicator you're dying, so it's very high priority
	colour = "red"

/obj/item/organ/heart/cybernetic
	name = "cybernetic heart"
	desc = ""
	icon_state = "heart-c"
	organ_flags = ORGAN_SYNTHETIC
	maxHealth = 1.1 * STANDARD_ORGAN_THRESHOLD

	var/dose_available = TRUE
	var/rid = /datum/reagent/medicine/epinephrine
	var/ramount = 10

/obj/item/organ/heart/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	Stop()
	addtimer(CALLBACK(src, PROC_REF(Restart)), 20/severity SECONDS)
	damage += 100/severity

/obj/item/organ/heart/cybernetic/on_life()
	. = ..()
	if(dose_available && owner.health <= owner.crit_threshold && !owner.reagents.has_reagent(rid))
		owner.reagents.add_reagent(rid, ramount)
		used_dose()

/obj/item/organ/heart/cybernetic/proc/used_dose()
	dose_available = FALSE

/obj/item/organ/heart/cybernetic/upgraded
	name = "upgraded cybernetic heart"
	desc = ""
	icon_state = "heart-c-u"
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD

/obj/item/organ/heart/cybernetic/upgraded/used_dose()
	. = ..()
	addtimer(VARSET_CALLBACK(src, dose_available, TRUE), 5 MINUTES)

/obj/item/organ/heart/freedom
	name = "heart of freedom"
	desc = ""
	organ_flags = ORGAN_SYNTHETIC //the power of freedom prevents heart attacks
	var/min_next_adrenaline = 0

/obj/item/organ/heart/freedom/on_life()
	. = ..()
	if(owner.health < 5 && world.time > min_next_adrenaline)
		min_next_adrenaline = world.time + rand(250, 600) //anywhere from 4.5 to 10 minutes
		to_chat(owner, span_danger("I feel myself dying, but you refuse to give up!"))
		owner.heal_overall_damage(15, 15, 0, BODYPART_ORGANIC)
		if(owner.reagents.get_reagent_amount(/datum/reagent/medicine/ephedrine) < 20)
			owner.reagents.add_reagent(/datum/reagent/medicine/ephedrine, 10)