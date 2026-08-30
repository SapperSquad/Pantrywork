**0.6.0 - Ten more dialect bridges, and life support for a tag Farmer's Delight deleted.**

**Fixed: recipes that vanished when FD removed `c:foods/milk`.** FD retired that tag in 1.21.1-1.3.0, but a number of Delight addons still reference it - and an undefined tag doesn't just fail to match, it makes Minecraft drop the whole recipe. Four addon jars were opened to count it: Arbitrary Delight (16 recipes), Cultural Delights (4), Pineapple Delight (3), Nature's Delight (2). Pantrywork now restores the tag with Farmer's Delight's own final contents - milk bucket and milk bottle, nothing more - so those dishes are craftable again.

If you maintain one of those addons, the real fix is to point the recipe at `c:drinks/milk`; Pantrywork already resolves that to every supported mod's milk, buckets included. This shim is for packs that can't patch.

**Ten more dialect collisions bridged**, found by auditing every common tag the supported mods define:
- **Cereals.** Croptopia files them one way, Farm & Charm another, Farmer's Delight a third. All three now see each other's barley, oat, corn and rice.
- **Juices.** Croptopia's `apple_juice` and Pam's `applejuice` are the same drink spelled two ways; same for melon.
- Croptopia's toast and Pam's toast; Croptopia's ground pork and Pam's; Farmer's Delight's cookies into Pam's cookie tag; Farm & Charm's isolated flour tag.

Deliberately left alone: caramel, flour, grain, bread, egg and corn are already declared by two or more mods, so they merge on their own and need no help.
