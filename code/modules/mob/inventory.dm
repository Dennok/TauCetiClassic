//This proc is called whenever someone clicks an inventory ui slot.
/mob/proc/attack_ui(slot)
	var/obj/item/W = get_active_hand()
	if(istype(W))
		if (istype(W, /obj/item/clothing))
			var/obj/item/clothing/C = W
			if(C.rig_restrict_helmet)
				to_chat(src, "<span class='red'>You must fasten the helmet to a hardsuit first. (Target the head)</span>")// Stop eva helms equipping.
			else
				if(C.equip_time > 0)
					delay_clothing_equip_to_slot_if_possible(C, slot)
				else
					equip_to_slot_if_possible(C, slot)
		else
			equip_to_slot_if_possible(W, slot)

/mob/proc/put_in_any_hand_if_possible(obj/item/W, del_on_fail = 0, disable_warning = 1, redraw_mob = 1)
	if(equip_to_slot_if_possible(W, slot_l_hand, del_on_fail, disable_warning, redraw_mob))
		return 1
	else if(equip_to_slot_if_possible(W, slot_r_hand, del_on_fail, disable_warning, redraw_mob))
		return 1
	return 0

//This is a SAFE proc. Use this instead of equip_to_slot()!
//set del_on_fail to have it delete W if it fails to equip
//set disable_warning to disable the 'you are unable to equip that' warning.
//unset redraw_mob to prevent the mob from being redrawn at the end.
/mob/proc/equip_to_slot_if_possible(obj/item/W, slot, del_on_fail = 0, disable_warning = 0, redraw_mob = 1)
	if(!istype(W)) return 0

	if(!W.mob_can_equip(src, slot, disable_warning))
		if(del_on_fail)
			qdel(W)
		else
			if(!disable_warning)
				to_chat(src, "<span class='red'>You are unable to equip that.</span>")//Only print if del_on_fail is false
		return 0

	equip_to_slot(W, slot, redraw_mob) //This proc should not ever fail.
	return 1

//This is an UNSAFE proc. It merely handles the actual job of equipping. All the checks on whether you can or can't eqip need to be done before! Use mob_can_equip() for that task.
//In most cases you will want to use equip_to_slot_if_possible()
/mob/proc/equip_to_slot(obj/item/W, slot)
	return

//This is just a commonly used configuration for the equip_to_slot_if_possible() proc, used to equip people when the rounds tarts and when events happen and such.
/mob/proc/equip_to_slot_or_del(obj/item/W, slot)
	return equip_to_slot_if_possible(W, slot, 1, 1, 0)

//The list of slots by priority. equip_to_appropriate_slot() uses this list. Doesn't matter if a mob type doesn't have a slot.
var/list/slot_equipment_priority = list( \
		slot_back,\
		slot_wear_id,\
		slot_w_uniform,\
		slot_wear_suit,\
		slot_wear_mask,\
		slot_head,\
		slot_shoes,\
		slot_gloves,\
		slot_l_ear,\
		slot_r_ear,\
		slot_glasses,\
		slot_belt,\
		slot_s_store,\
		slot_l_store,\
		slot_r_store\
	)

//puts the item "W" into an appropriate slot in a human's inventory
//returns 0 if it cannot, 1 if successful
/mob/proc/equip_to_appropriate_slot(obj/item/W)
	if(!istype(W)) return 0

	for(var/slot in slot_equipment_priority)
		if(equip_to_slot_if_possible(W, slot, del_on_fail=0, disable_warning=1, redraw_mob=1))
			return 1

	return 0

//These procs handle putting s tuff in your hand. It's probably best to use these rather than setting l_hand = ...etc
//as they handle all relevant stuff like adding it to the player's screen and updating their overlays.

//Returns the thing in our active hand


//Returns the thing in our active hand
/mob/proc/get_active_hand()
	if(hand)	return l_hand
	else		return r_hand

//Returns the thing in our inactive hand
/mob/proc/get_inactive_hand()
	if(hand)	return r_hand
	else		return l_hand

//Puts the item into your l_hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_l_hand(obj/item/W)
	if(lying && !(W.flags&ABSTRACT))	return 0
	if(!istype(W))		return 0
	if(W.anchored)		return 0	//Anchored things shouldn't be picked up because they... anchored?!
	if(!l_hand)
		W.loc = src		//TODO: move to equipped?
		l_hand = W
		W.layer = 20	//TODO: move to equipped?
		W.appearance_flags = APPEARANCE_UI
//		l_hand.screen_loc = ui_lhand
		W.equipped(src,slot_l_hand)
		if(client)	client.screen |= W
		if(pulling == W) stop_pulling()
		update_inv_l_hand()
		W.pixel_x = initial(W.pixel_x)
		W.pixel_y = initial(W.pixel_y)
		return 1
	return 0

//Puts the item into your r_hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_r_hand(obj/item/W)
	if(lying && !(W.flags&ABSTRACT))	return 0
	if(!istype(W))		return 0
	if(W.anchored)		return 0	//Anchored things shouldn't be picked up because they... anchored?!
	if(!r_hand)
		W.loc = src
		r_hand = W
		W.layer = 20
		W.appearance_flags = APPEARANCE_UI
//		r_hand.screen_loc = ui_rhand
		W.equipped(src,slot_r_hand)
		if(client)	client.screen |= W
		if(pulling == W) stop_pulling()
		update_inv_r_hand()
		W.pixel_x = initial(W.pixel_x)
		W.pixel_y = initial(W.pixel_y)
		return 1
	return 0

//Puts the item into our active hand if possible. returns 1 on success.
/mob/proc/put_in_active_hand(obj/item/W)
	if(hand)	return put_in_l_hand(W)
	else		return put_in_r_hand(W)

//Puts the item into our inactive hand if possible. returns 1 on success.
/mob/proc/put_in_inactive_hand(obj/item/W)
	if(hand)	return put_in_r_hand(W)
	else		return put_in_l_hand(W)

//Puts the item our active hand if possible. Failing that it tries our inactive hand. Returns 1 on success.
//If both fail it drops it on the floor and returns 0.
//This is probably the main one you need to know :)
/mob/proc/put_in_hands(obj/item/W)
	if(!W)		return 0
	if(put_in_active_hand(W))
		update_inv_l_hand()
		update_inv_r_hand()
		return 1
	else if(put_in_inactive_hand(W))
		update_inv_l_hand()
		update_inv_r_hand()
		return 1
	else
		W.forceMove(get_turf(src))
		W.layer = initial(W.layer)
		W.appearance_flags = 0
		W.dropped()
		return 0

// Removes an item from inventory and places it in the target atom
/mob/proc/drop_from_inventory(obj/item/W, atom/target = null)
	if(W)
		remove_from_mob(W, target)
		if(!(W && W.loc))
			return 1 // self destroying objects (tk, grabs)
		update_icons()
		return 1
	return 0

//Drops the item in our left hand
/mob/proc/drop_l_hand(atom/Target)
	return drop_from_inventory(l_hand, Target)

//Drops the item in our right hand
/mob/proc/drop_r_hand(atom/Target)
	return drop_from_inventory(r_hand, Target)

//Drops the item in our active hand.
/mob/proc/drop_item(atom/Target)
	if(hand)	return drop_l_hand(Target)
	else		return drop_r_hand(Target)

/*
	Removes the object from any slots the mob might have, calling the appropriate icon update proc.
	Does nothing else.

	DO NOT CALL THIS PROC DIRECTLY. It is meant to be called only by other inventory procs.
	It's probably okay to use it if you are transferring the item between slots on the same mob,
	but chances are you're safer calling remove_from_mob() or drop_from_inventory() anyways.

	As far as I can tell the proc exists so that mobs with different inventory slots can override
	the search through all the slots, without having to duplicate the rest of the item dropping.
*/
/mob/proc/u_equip(obj/W)
	if (W == r_hand)
		r_hand = null
		update_inv_r_hand()
	else if (W == l_hand)
		l_hand = null
		update_inv_l_hand()
	else if (W == back)
		back = null
		update_inv_back()
	else if (W == wear_mask)
		wear_mask = null
		update_inv_wear_mask()
	return

//This differs from remove_from_mob() in that it checks canremove first.
/mob/proc/unEquip(obj/item/I, force = 0) //Force overrides NODROP for things like wizarditis and admin undress.
	if(!I) //If there's nothing to drop, the drop is automatically successful.
		return 1

	if(!I.canremove && !force)
		return 0

	drop_from_inventory(I)
	return 1

//Attemps to remove an object on a mob.  Will not move it to another area or such, just removes from the mob.
/mob/proc/remove_from_mob(obj/O, atom/target)
	if(!O) return
	src.u_equip(O)
	if (src.client)
		src.client.screen -= O
	O.layer = initial(O.layer)
	O.appearance_flags = 0
	O.screen_loc = null
	if(istype(O, /obj/item))
		var/obj/item/I = O
		if(target)
			I.forceMove(target)
		else
			I.forceMove(loc)
		I.dropped(src)
	return 1


//Outdated but still in use apparently. This should at least be a human proc.
/mob/proc/get_equipped_items()
	var/list/items = new/list()

	if(hasvar(src,"back")) if(src:back) items += src:back
	if(hasvar(src,"belt")) if(src:belt) items += src:belt
	if(hasvar(src,"l_ear")) if(src:l_ear) items += src:l_ear
	if(hasvar(src,"r_ear")) if(src:r_ear) items += src:r_ear
	if(hasvar(src,"glasses")) if(src:glasses) items += src:glasses
	if(hasvar(src,"gloves")) if(src:gloves) items += src:gloves
	if(hasvar(src,"head")) if(src:head) items += src:head
	if(hasvar(src,"shoes")) if(src:shoes) items += src:shoes
	if(hasvar(src,"wear_id")) if(src:wear_id) items += src:wear_id
	if(hasvar(src,"wear_mask")) if(src:wear_mask) items += src:wear_mask
	if(hasvar(src,"wear_suit")) if(src:wear_suit) items += src:wear_suit
//	if(hasvar(src,"w_radio")) if(src:w_radio) items += src:w_radio  commenting this out since headsets go on your ears now PLEASE DON'T BE MAD KEELIN
	if(hasvar(src,"w_uniform")) if(src:w_uniform) items += src:w_uniform

	//if(hasvar(src,"l_hand")) if(src:l_hand) items += src:l_hand
	//if(hasvar(src,"r_hand")) if(src:r_hand) items += src:r_hand

	return items

//Create delay for equipping
/mob/proc/delay_clothing_u_equip(obj/item/clothing/C) // Bone White - delays unequipping by parameter.  Requires W to be /obj/item/clothing/

	if(!istype(C)) return 0

	if(C.equipping) return 0 // Item is already being (un)equipped

	var/tempX = usr.x
	var/tempY = usr.y
	to_chat(usr, "<span class='notice'>You start unequipping the [C].</span>")
	C.equipping = 1
	var/equip_time = round(C.equip_time/10)
	var/i
	for(i=1; i<=equip_time; i++)
		sleep (10) // Check if they've moved every 10 time units
		if ((tempX != usr.x) || (tempY != usr.y))
			to_chat(src, "<span class='red'>\The [C] is too fiddly to unequip whilst moving.</span>")
			C.equipping = 0
			return 0
	remove_from_mob(C)
	to_chat(usr, "<span class='notice'>You have finished unequipping the [C].</span>")
	C.equipping = 0

/mob/proc/delay_clothing_equip_to_slot_if_possible(obj/item/clothing/C, slot, del_on_fail = 0, disable_warning = 0, redraw_mob = 1, delay_time = 0)
	if(!istype(C)) return 0

	if(ishuman(usr))
		var/mob/living/carbon/human/H = usr
		if(H.wear_suit)
			to_chat(H, "<span class='red'>You need to take off [H.wear_suit.name] first.</span>")
			return

	if(C.equipping) return 0 // Item is already being equipped

	var/tempX = usr.x
	var/tempY = usr.y
	to_chat(usr, "<span class='notice'>You start equipping the [C].</span>")
	C.equipping = 1
	var/equip_time = round(C.equip_time/10)
	var/i
	for(i=1; i<=equip_time; i++)
		sleep (10) // Check if they've moved every 10 time units
		if ((tempX != usr.x) || (tempY != usr.y))
			to_chat(src, "<span class='red'>\The [C] is too fiddly to fasten whilst moving.</span>")
			C.equipping = 0
			return 0
	equip_to_slot_if_possible(C, slot)
	to_chat(usr, "<span class='notice'>You have finished equipping the [C].</span>")
	C.equipping = 0

/mob/proc/get_item_by_slot(slot_id)
	switch(slot_id)
		if(slot_l_hand)
			return l_hand
		if(slot_r_hand)
			return r_hand
	return null
