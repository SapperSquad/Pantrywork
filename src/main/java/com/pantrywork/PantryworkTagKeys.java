package com.pantrywork;

import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.TagKey;
import net.minecraft.world.item.Item;

/**
 * TagKey constants for downstream mods. The role axis is the stable API:
 * recipes and mechanics should target these rather than any single mod's
 * items. Identity constants cover only the categories Pantrywork itself
 * canonicalizes; the rest of c:foods/* ships with NeoForge/FD.
 */
public final class PantryworkTagKeys {

    // --- role axis (pantrywork namespace) ---
    public static final TagKey<Item> FOOD_COMPONENT = own("food_component");
    public static final TagKey<Item> PROTEIN = own("food_component/protein");
    public static final TagKey<Item> STARCH = own("food_component/starch");
    public static final TagKey<Item> DAIRY = own("food_component/dairy");
    public static final TagKey<Item> GARNISH = own("food_component/garnish");
    public static final TagKey<Item> LIQUID_BASE = own("food_component/liquid_base");
    public static final TagKey<Item> SWEETENER = own("food_component/sweetener");

    // --- canonical identity tags Pantrywork introduces or bridges ---
    public static final TagKey<Item> CHEESE = common("foods/cheese");
    public static final TagKey<Item> BUTTER = common("foods/butter");
    public static final TagKey<Item> DOUGH = common("foods/dough");
    public static final TagKey<Item> COOKED_RICE = common("foods/cooked_rice");
    // both Croptopia and Pam's independently chose c:flour — already shared
    public static final TagKey<Item> FLOUR = common("flour");

    private static TagKey<Item> own(String path) {
        return TagKey.create(Registries.ITEM,
            ResourceLocation.fromNamespaceAndPath(Pantrywork.MOD_ID, path));
    }

    private static TagKey<Item> common(String path) {
        return TagKey.create(Registries.ITEM,
            ResourceLocation.fromNamespaceAndPath("c", path));
    }

    private PantryworkTagKeys() {}
}
