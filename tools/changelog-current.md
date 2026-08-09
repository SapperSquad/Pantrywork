**0.3.0 - Aquaculture 2 and Brewin' & Chewin' support.**

- **Aquaculture 2**: its 27 fish already use the official `c:foods/raw_fish` dialect, so they now flow into the other mods' fish tags too - a Pam's, Ocean's Delight, or Farm & Charm recipe that wants fish will accept any Aquaculture catch, and its cooked fillet counts as a protein everywhere.
- **Brewin' & Chewin'**: its four ripe cheeses join the shared cheese pool (so they work in any mod's cheese recipe, and vice versa), its sixteen fermented drinks join `c:drinks`, and its soups were already canonical.
- Under the hood, the reverse-bridge generator now follows food that a mod files behind its own namespaced tags (like Brewin's), not just `c:` tags - so future mods that do the same are handled automatically.

No changes for existing users; every cross-mod entry stays optional, so any subset of the supported mods (or none) works.
