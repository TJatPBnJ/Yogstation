/datum/species/ipc // im fucking lazy mk2 and cant get sprites to normally work
	name = "IPC" //inherited from the real species, for health scanners and things
	id = "ipc"
	say_mod = "states" //inherited from a user's real species
	sexes = FALSE
	species_traits = list(NOTRANSSTING,NOEYESPRITES,NO_DNA_COPY,TRAIT_EASYDISMEMBER,ROBOTIC_LIMBS,NOZOMBIE,MUTCOLORS,NOHUSK,NOMOUTH,AGENDER,NOBLOOD)
	inherent_traits = list(TRAIT_RESISTCOLD,TRAIT_NOBREATH,TRAIT_RADIMMUNE,TRAIT_LIMBATTACHMENT,TRAIT_NOCRITDAMAGE,TRAIT_GENELESS,TRAIT_MEDICALIGNORE,TRAIT_NOCLONE,TRAIT_TOXIMMUNE,TRAIT_EASILY_WOUNDED,TRAIT_NODEFIB)
	inherent_biotypes = list(MOB_ROBOTIC, MOB_HUMANOID)
	mutant_brain = /obj/item/organ/brain/positron
	mutant_heart = /obj/item/organ/heart/cybernetic/ipc
	mutanteyes = /obj/item/organ/eyes/robotic
	mutanttongue = /obj/item/organ/tongue/robot
	mutantliver = /obj/item/organ/liver/cybernetic/upgraded/ipc
	mutantstomach = /obj/item/organ/stomach/cell
	mutantears = /obj/item/organ/ears/robot
	mutant_organs = list(/obj/item/organ/cyberimp/arm/power_cord)
	mutant_bodyparts = list("ipc_screen", "ipc_antenna", "ipc_chassis")
	default_features = list("mcolor" = "#7D7D7D", "ipc_screen" = "Static", "ipc_antenna" = "None", "ipc_chassis" = "Morpheus Cyberkinetics(Greyscale)")
	meat = /obj/item/stack/sheet/plasteel{amount = 5}
	skinned_type = /obj/item/stack/sheet/metal{amount = 10}
	exotic_blood = /datum/reagent/oil
	damage_overlay_type = "synth"
	limbs_id = "synth"
	payday_modifier = 0.6 //Mass producible labor
	burnmod = 1.5
	heatmod = 1
	brutemod = 1
	toxmod = 0
	clonemod = 0
	staminamod = 0.8
	siemens_coeff = 1.75
	reagent_tag = PROCESS_SYNTHETIC
	species_gibs = "robotic"
	attack_sound = 'sound/items/trayhit1.ogg'
	allow_numbers_in_name = TRUE
	deathsound = "sound/voice/borg_deathsound.ogg"
	var/saved_screen //for saving the screen when they die
	changesource_flags = MIRROR_BADMIN | WABBAJACK

	var/datum/action/innate/change_screen/change_screen

/datum/species/ipc/random_name(unique)
	var/ipc_name = "[pick(GLOB.posibrain_names)]-[rand(100, 999)]"
	return ipc_name

/datum/species/ipc/on_species_gain(mob/living/carbon/C) // Let's make that IPC actually robotic.
	. = ..()
	var/obj/item/organ/appendix/A = C.getorganslot(ORGAN_SLOT_APPENDIX) // Easiest way to remove it.
	if(A)
		A.Remove(C)
		QDEL_NULL(A)
	var/obj/item/organ/lungs/L = C.getorganslot(ORGAN_SLOT_LUNGS)
	if(L)
		L.Remove(C)
		QDEL_NULL(L)
	if(ishuman(C) && !change_screen)
		change_screen = new
		change_screen.Grant(C)
	for(var/obj/item/bodypart/O in C.bodyparts)
		O.render_like_organic = TRUE // Makes limbs render like organic limbs instead of augmented limbs, check bodyparts.dm
		var/chassis = C.dna.features["ipc_chassis"]
		var/datum/sprite_accessory/ipc_chassis/chassis_of_choice = GLOB.ipc_chassis_list[chassis]
		C.dna.species.limbs_id = chassis_of_choice.limbs_id
		if(chassis_of_choice.color_src == MUTCOLORS && !(MUTCOLORS in C.dna.species.species_traits)) // If it's a colorable(Greyscale) chassis, we use MUTCOLORS.
			C.dna.species.species_traits += MUTCOLORS
		else if(MUTCOLORS in C.dna.species.species_traits)
			C.dna.species.species_traits -= MUTCOLORS

datum/species/ipc/on_species_loss(mob/living/carbon/C)
	. = ..()
	if(change_screen)
		change_screen.Remove(C)

/datum/species/ipc/proc/handle_speech(datum/source, list/speech_args)
	speech_args[SPEECH_SPANS] |= SPAN_ROBOT

/datum/species/ipc/after_equip_job(datum/job/J, mob/living/carbon/human/H)
	H.grant_language(/datum/language/machine)

/datum/species/ipc/spec_death(gibbed, mob/living/carbon/C)
	saved_screen = C.dna.features["ipc_screen"]
	C.dna.features["ipc_screen"] = "BSOD"
	C.update_body()
	addtimer(CALLBACK(src, .proc/post_death, C), 5 SECONDS)

/datum/species/ipc/proc/post_death(mob/living/carbon/C)
	if(C.stat < DEAD)
		return
	C.dna.features["ipc_screen"] = null //Turns off screen on death
	C.update_body()

/datum/action/innate/change_screen
	name = "Change Display"
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "drone_vision"

/datum/action/innate/change_screen/Activate()
	var/screen_choice = input(usr, "Which screen do you want to use?", "Screen Change") as null | anything in GLOB.ipc_screens_list
	var/color_choice = input(usr, "Which color do you want your screen to be?", "Color Change") as null | color
	if(!screen_choice)
		return
	if(!color_choice)
		return
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.dna.features["ipc_screen"] = screen_choice
	H.eye_color = sanitize_hexcolor(color_choice)
	H.update_body()

/obj/item/apc_powercord
	name = "power cord"
	desc = "An internal power cord hooked up to a battery. Useful if you run on electricity. Not so much otherwise."
	icon = 'icons/obj/power.dmi'
	icon_state = "wire1"

/obj/item/apc_powercord/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!istype(target, /obj/machinery/power/apc) || !ishuman(user) || !proximity_flag)
		return ..()
	user.changeNext_move(CLICK_CD_MELEE)
	var/obj/machinery/power/apc/A = target
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/stomach/cell/cell = locate(/obj/item/organ/stomach/cell) in H.internal_organs
	if(!cell)
		to_chat(H, "<span class='warning'>You try to siphon energy from the [A], but your power cell is gone!</span>")
		return

	if(A.cell && A.cell.charge > 0)
		if(H.nutrition >= NUTRITION_LEVEL_MOSTLY_FULL)
			to_chat(user, "<span class='warning'>You are already fully charged!</span>")
			return
		else
			powerdraw_loop(A, H)
			return

	to_chat(user, "<span class='warning'>There is no charge to draw from that APC.</span>")

/obj/item/apc_powercord/proc/powerdraw_loop(obj/machinery/power/apc/A, mob/living/carbon/human/H)
	H.visible_message("<span class='notice'>[H] inserts a power connector into the [A].</span>", "<span class='notice'>You begin to draw power from the [A].</span>")
	while(do_after(H, 1 SECONDS, target = A))
		if(loc != H)
			to_chat(H, "<span class='warning'>You must keep your connector out while charging!</span>")
			break
		if(A.cell.charge == 0)
			to_chat(H, "<span class='warning'>The [A] doesn't have enough charge to spare.</span>")
			break
		if(H.nutrition > NUTRITION_LEVEL_MOSTLY_FULL)
			to_chat(H, "<span class='notice'>You are now fully charged.</span>")
			break
		A.charging = 1
		if(A.cell.charge >= 500)
			H.nutrition += 50
			A.cell.charge -= 250
			to_chat(H, "<span class='notice'>You siphon off some of the stored charge for your own use.</span>")
		else
			H.nutrition += A.cell.charge/10
			A.cell.charge = 0
			to_chat(H, "<span class='notice'>You siphon off as much as the [A] can spare.</span>")
			break
	H.visible_message("<span class='notice'>[H] unplugs from the [A].</span>", "<span class='notice'>You unplug from the [A].</span>")

/datum/species/ipc/get_hunger_alert(mob/living/carbon/human/H)
	switch(H.nutrition)
		if(NUTRITION_LEVEL_FED to INFINITY)
			H.clear_alert("nutrition")
		if(NUTRITION_LEVEL_HUNGRY to NUTRITION_LEVEL_FED)
			H.throw_alert("nutrition", /obj/screen/alert/lowcell, 2)
		if(NUTRITION_LEVEL_STARVING to NUTRITION_LEVEL_HUNGRY)
			H.throw_alert("nutrition", /obj/screen/alert/lowcell, 3)
		if(0 to NUTRITION_LEVEL_STARVING)
			H.throw_alert("nutrition", /obj/screen/alert/emptycell)

/datum/species/ipc/spec_revival(mob/living/carbon/human/H, admin_revive)
	if(admin_revive)
		return ..()
	to_chat(H, span_notice("You do not remember your death, how you died, or who killed you. <a href='https://forums.yogstation.net/index.php?pages/rules/'>See rule 1.7</a>."))
	H.Stun(9 SECONDS) // No moving either
	H.dna.features["ipc_screen"] = "BSOD"
	H.update_body()
	addtimer(CALLBACK(src, .proc/afterrevive, H), 0)
	return

/datum/species/ipc/proc/afterrevive(mob/living/carbon/human/H)
	H.say("Reactivating [pick("core systems", "central subroutines", "key functions")]...")
	sleep(3 SECONDS)
	H.say("Reinitializing [pick("personality matrix", "behavior logic", "morality subsystems")]...")
	sleep(3 SECONDS)
	H.say("Finalizing setup...")
	sleep(3 SECONDS)
	H.say("Unit [H.real_name] is fully functional. Have a nice day.")
	H.dna.features["ipc_screen"] = saved_screen
	H.update_body()

/datum/species/ipc/spec_life(mob/living/carbon/human/H)
	. = ..()
	if(H.health <= HEALTH_THRESHOLD_FULLCRIT && H.stat != DEAD) // So they die eventually instead of being stuck in crit limbo.
		H.adjustFireLoss(6) // After bodypart_robotic resistance this is ~2/second
		if(prob(5))
			to_chat(H, "<span class='warning'>Alert: Internal temperature regulation systems offline; thermal damage sustained. Shutdown imminent.</span>")
			H.visible_message("[H]'s cooling system fans stutter and stall. There is a faint, yet rapid beeping coming from inside their chassis.")
