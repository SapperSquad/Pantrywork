package com.pantrywork.gametest;

import com.pantrywork.Pantrywork;
import com.pantrywork.PantryworkTagKeys;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.registries.Registries;
import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.TagKey;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.crafting.CraftingInput;
import net.minecraft.world.item.crafting.RecipeType;
import net.neoforged.neoforge.gametest.GameTestHolder;
import net.neoforged.neoforge.gametest.PrefixGameTestTemplate;

/**
 * CI-style verification: `gradlew runGameTestServer` boots a headless
 * server with every compat jar on the dev classpath, runs these, and
 * exits nonzero on failure. Mirrors the RCON suites in tools/, but
 * queries tags and the RecipeManager directly instead of driving chests
 * and crafter blocks. Stripped from release jars (-Prelease).
 */
@GameTestHolder(Pantrywork.MOD_ID)
@PrefixGameTestTemplate(false)
public class PantryworkGameTests {

    private static final TagKey<Item> C_CHEESES = commonTag("cheeses");
    private static final TagKey<Item> C_CHEESE = commonTag("cheese");
    private static final TagKey<Item> C_RAWPORK = commonTag("rawpork");

    @GameTest(template = "empty")
    public static void vanillaRoleTags(GameTestHelper helper) {
        assertInTag(helper, Items.BREAD, PantryworkTagKeys.STARCH);
        assertInTag(helper, Items.COOKED_BEEF, PantryworkTagKeys.PROTEIN);
        assertInTag(helper, Items.CARROT, PantryworkTagKeys.GARNISH);
        assertInTag(helper, Items.MILK_BUCKET, PantryworkTagKeys.DAIRY);
        assertInTag(helper, Items.SUGAR, PantryworkTagKeys.SWEETENER);
        helper.assertFalse(new ItemStack(Items.STONE).is(PantryworkTagKeys.FOOD_COMPONENT),
            "stone must not be a food component");
        helper.succeed();
    }

    @GameTest(template = "empty")
    public static void crossModIdentityAndRoles(GameTestHelper helper) {
        assertInTag(helper, modItem(helper, "croptopia:cheese"), PantryworkTagKeys.CHEESE);
        assertInTag(helper, modItem(helper, "pamhc2foodcore:cheeseitem"), PantryworkTagKeys.CHEESE);
        assertInTag(helper, modItem(helper, "croptopia:flour"), PantryworkTagKeys.FLOUR);
        assertInTag(helper, modItem(helper, "pamhc2foodcore:flouritem"), PantryworkTagKeys.FLOUR);
        assertInTag(helper, modItem(helper, "farmersdelight:wheat_dough"), PantryworkTagKeys.DOUGH);
        assertInTag(helper, modItem(helper, "ends_delight:roasted_dragon_meat"), PantryworkTagKeys.PROTEIN);
        assertInTag(helper, modItem(helper, "oceansdelight:cooked_guardian_tail"), PantryworkTagKeys.PROTEIN);
        helper.succeed();
    }

    @GameTest(template = "empty")
    public static void reverseBridges(GameTestHelper helper) {
        assertInTag(helper, modItem(helper, "pamhc2foodcore:cheeseitem"), C_CHEESES);
        assertInTag(helper, modItem(helper, "brewinandchewin:flaxen_cheese_wedge"), C_CHEESE);
        assertInTag(helper, modItem(helper, "farmersdelight:bacon"), commonTag("raw_pork"));
        helper.succeed();
    }

    @GameTest(template = "empty")
    public static void croptopiaRecipeAcceptsPamsCheese(GameTestHelper helper) {
        ItemStack result = craft(helper, List.of(
            new ItemStack(Items.BREAD),
            new ItemStack(modItem(helper, "pamhc2foodcore:cheeseitem")),
            new ItemStack(modItem(helper, "croptopia:frying_pan"))));
        helper.assertTrue(result.is(modItem(helper, "croptopia:grilled_cheese")),
            "expected croptopia:grilled_cheese, got " + result);
        helper.succeed();
    }

    /**
     * Pam's grilled cheese and ham (c:tool_skillet + c:bread + c:butter +
     * c:cheese + c:rawpork) from three mods' items plus vanilla bread and porkchop. Then the same recipe with ONE
     * ingredient swapped for an item 0.7.0 keeps below that slot's cost floor -
     * Croptopia's butter or cheese (made from its 1/16-bucket bottle) or Farmer's
     * Delight's bacon (half a porkchop) - must not produce the sandwich. One swap
     * per attempt, so each exclusion is proven on its own.
     */
    @GameTest(template = "empty")
    public static void pamsRecipeAcceptsForeignIngredients(GameTestHelper helper) {
        Item sandwich = modItem(helper, "pamhc2foodcore:grilledcheeseandhamitem");
        List<ItemStack> valid = List.of(
            new ItemStack(modItem(helper, "pamhc2foodcore:skilletitem")),
            new ItemStack(Items.BREAD),
            new ItemStack(modItem(helper, "farm_and_charm:butter")),
            new ItemStack(modItem(helper, "brewinandchewin:flaxen_cheese_wedge")),
            new ItemStack(Items.PORKCHOP));
        ItemStack result = craft(helper, valid);
        helper.assertTrue(result.is(sandwich),
            "expected pamhc2foodcore:grilledcheeseandhamitem, got " + result);

        String[][] swaps = {
            {"2", "croptopia:butter"},
            {"3", "croptopia:cheese"},
            {"4", "farmersdelight:bacon"},
        };
        for (String[] swap : swaps) {
            List<ItemStack> input = new ArrayList<>();
            for (ItemStack stack : valid) {
                input.add(stack.copy());
            }
            input.set(Integer.parseInt(swap[0]), new ItemStack(modItem(helper, swap[1])));
            Optional<ItemStack> diluted = tryCraft(helper, input);
            helper.assertFalse(diluted.map(stack -> stack.is(sandwich)).orElse(false),
                swap[1] + " must NOT satisfy Pam's grilled cheese and ham (below the slot's cost floor)");
        }
        helper.succeed();
    }

    /**
     * 0.7.0: player-feedback bridges (Create, Bountiful Fares, Fish of Thieves,
     * Refurbished Furniture, cooked eggs), the non-food block fix, and the
     * economic-dilution floors (milk, cheese/butter, half-portion cuts). Every
     * mod named here is on the dev classpath unconditionally (build.gradle), so a
     * missing id FAILS through modItem() exactly like the tests above: a jar that
     * drops off the classpath turns this red instead of quietly skipping checks.
     */
    @GameTest(template = "empty")
    public static void feedbackBridges(GameTestHelper helper) {
        // blocks never reach canonical food tags (0.6.0 shipped both)
        assertNotInTag(helper, Items.MELON, commonTag("foods/fruit"));
        assertInTag(helper, Items.MELON_SLICE, commonTag("foods/fruit"));
        assertNotInTag(helper, Items.PUMPKIN, commonTag("foods/vegetable"));

        // Create dough/flour reach Pam's and Croptopia's dialect names
        Item createDough = modItem(helper, "create:dough");
        assertInTag(helper, createDough, commonTag("dough"));
        assertInTag(helper, createDough, commonTag("doughs"));
        // reachability only: F&C's own c:flour -> #c:flours also satisfies this without the flour
        // gate overlay (costFloorGatesAndExclusions asserts the overlay's own tag; review TV-2)
        assertInTag(helper, modItem(helper, "create:wheat_flour"), commonTag("flour"));
        assertNotInTag(helper, modItem(helper, "create:cinder_flour"), commonTag("flour"));

        // Fish of Thieves fruit: generic c:fruits, and Croptopia's per-fruit tag
        Item fotBanana = modItem(helper, "fishofthieves:banana");
        assertInTag(helper, fotBanana, commonTag("fruits"));
        assertInTag(helper, fotBanana, commonTag("bananas"));
        assertNotInTag(helper, modItem(helper, "fishofthieves:raw_mango"), commonTag("mangos"));

        // cooked eggs join FD's c:foods/cooked_egg and therefore the protein role
        Item friedEgg = modItem(helper, "pamhc2foodcore:friedeggitem");
        assertInTag(helper, friedEgg, commonTag("foods/cooked_egg"));
        assertInTag(helper, friedEgg, PantryworkTagKeys.PROTEIN);
        assertNotInTag(helper, modItem(helper, "pamhc2foodcore:scrambledeggitem"), commonTag("foods/cooked_egg"));
        assertNotInTag(helper, Items.EGG, commonTag("foods/cooked_egg"));

        // BF's "coconut" is the palm sapling item: never spread by Pantrywork
        Item bfCoconut = modItem(helper, "bountifulfares:coconut");
        assertNotInTag(helper, bfCoconut, commonTag("foods/fruit"));
        assertNotInTag(helper, bfCoconut, commonTag("fruits/coconut"));

        // Refurbished: identity-safe items bridged, 6-per-bread toast never
        assertInTag(helper, modItem(helper, "refurbished_furniture:cheese"), C_CHEESES);
        Item rfToast = modItem(helper, "refurbished_furniture:toast");
        assertNotInTag(helper, rfToast, commonTag("toast"));
        assertNotInTag(helper, rfToast, commonTag("toasts"));

        // milk floors: c:milk = Pam's 1/8 fresh milk, c:drinks/milk = FD's 1/4 bottle
        Item cropBottle = modItem(helper, "croptopia:milk_bottle");
        Item soyMilk = modItem(helper, "croptopia:soy_milk");
        Item freshMilk = modItem(helper, "pamhc2foodcore:freshmilkitem");
        TagKey<Item> drinksMilk = commonTag("drinks/milk");
        assertNotInTag(helper, cropBottle, commonTag("milk"));
        assertNotInTag(helper, soyMilk, commonTag("milk"));
        assertNotInTag(helper, cropBottle, drinksMilk);
        assertNotInTag(helper, soyMilk, drinksMilk);
        assertNotInTag(helper, freshMilk, drinksMilk);
        assertInTag(helper, modItem(helper, "farmersdelight:milk_bottle"), drinksMilk);
        assertInTag(helper, modItem(helper, "meadow:wooden_milk_bucket"), drinksMilk);
        assertInTag(helper, Items.MILK_BUCKET, drinksMilk);
        // ...while the dairy role (our own semantic tag, not a recipe slot) keeps every milk
        assertInTag(helper, cropBottle, PantryworkTagKeys.DAIRY);
        assertInTag(helper, freshMilk, PantryworkTagKeys.DAIRY);

        // Croptopia's bottle-made cheese/butter stay in its own plural tags only
        Item cropCheese = modItem(helper, "croptopia:cheese");
        Item cropButter = modItem(helper, "croptopia:butter");
        assertNotInTag(helper, cropCheese, C_CHEESE);
        assertInTag(helper, cropCheese, C_CHEESES);
        assertNotInTag(helper, cropButter, commonTag("butter"));
        assertInTag(helper, cropButter, commonTag("butters"));

        // half-portion cuts never enter whole-item dialect tags
        assertNotInTag(helper, modItem(helper, "farmersdelight:bacon"), C_RAWPORK);
        assertInTag(helper, Items.PORKCHOP, C_RAWPORK);
        Item fdMince = modItem(helper, "farmersdelight:minced_beef");
        assertNotInTag(helper, fdMince, commonTag("rawbeef"));
        assertNotInTag(helper, fdMince, commonTag("raw_beef"));
        assertInTag(helper, modItem(helper, "farm_and_charm:minced_beef"), commonTag("rawbeef"));
        assertNotInTag(helper, modItem(helper, "farm_and_charm:chicken_parts"), commonTag("rawchicken"));
        assertNotInTag(helper, modItem(helper, "oceansdelight:fugu_slice"), commonTag("rawfish"));
        Item fillet = modItem(helper, "aquaculture:fish_fillet_cooked");
        assertNotInTag(helper, fillet, commonTag("cookedfish"));
        assertInTag(helper, fillet, commonTag("foods/cooked_fish"));
        assertNotInTag(helper, modItem(helper, "farm_and_charm:roasted_chicken"), commonTag("cookedchicken"));

        // one real recipe: FD's egg sandwich from Pam's fried egg + BF cooked egg
        ItemStack result = craft(helper, List.of(
            new ItemStack(Items.BREAD),
            new ItemStack(friedEgg),
            new ItemStack(modItem(helper, "bountifulfares:cooked_egg"))));
        helper.assertTrue(result.is(modItem(helper, "farmersdelight:egg_sandwich")),
            "expected farmersdelight:egg_sandwich, got " + result);
        helper.succeed();
    }

    /**
     * Cost-floor pass (SapperSquad 2026-09-13). Every gate mod (Pam's, Croptopia, Farm &
     * Charm, Create, Bountiful Fares) is on the dev classpath, so every gate overlay must
     * apply. Each is proven on the overlay's OWN tag (pantrywork:gated/&lt;mods&gt;/...), which
     * exists only when that overlay applied: a c:* membership alone is not proof, because a
     * third mod's ref can satisfy it without the overlay (F&C's c:flour -> #c:flours reaches
     * Create's flour; Croptopia's c:salts / c:vegetables reach Pam's salt and FD's leaf -
     * review TV-1/TV-2). The c:* lines after them are reachability checks. Every EXCLUDEd
     * entry must be absent. Closed gates are proven on the release jar by
     * tools/tagtest-gates*.txt (S5: the flour gate) and live on the dev server by
     * tools/tagtest-nofandc.txt.
     */
    @GameTest(template = "empty")
    public static void costFloorGatesAndExclusions(GameTestHelper helper) {
        // GATE, open on this classpath: one assertion per gated tag, on the overlay's own tag
        Item fdMilk = modItem(helper, "farmersdelight:milk_bottle");
        Item fdDough = modItem(helper, "farmersdelight:wheat_dough");
        Item pamDough = modItem(helper, "pamhc2foodcore:doughitem");
        Item createFlour = modItem(helper, "create:wheat_flour");
        assertInTag(helper, fdMilk, gatedTag("pamhc2foodcore/c/milk"));
        assertInTag(helper, fdMilk, gatedTag("croptopia/c/milks"));
        assertInTag(helper, fdDough, gatedTag("farm_and_charm/c/doughs"));
        assertInTag(helper, pamDough, gatedTag("create/bridged/foods_dough"));
        assertInTag(helper, createFlour, gatedTag("bountifulfares_or_farm_and_charm_or_pamhc2foodcore/c/flour"));
        assertInTag(helper, modItem(helper, "pamhc2foodcore:cheeseitem"), gatedTag("croptopia/c/cheeses"));
        assertInTag(helper, modItem(helper, "pamhc2foodcore:saltitem"), gatedTag("croptopia/c/salts"));
        assertInTag(helper, modItem(helper, "farmersdelight:cabbage_leaf"), gatedTag("croptopia/c/vegetables"));
        // ...and reachability through the base tags' optional refs
        assertInTag(helper, fdMilk, commonTag("milk"));
        assertInTag(helper, fdMilk, commonTag("milks"));
        assertInTag(helper, fdDough, commonTag("doughs"));
        assertInTag(helper, pamDough, PantryworkTagKeys.DOUGH);
        assertInTag(helper, createFlour, PantryworkTagKeys.FLOUR);

        // review fixes: the c:foods/milk shim holds the bucket only (CF-1); Croptopia's
        // tofu-route ground pork is out of Pam's ground pork (CF-3); Croptopia's melon juice is
        // 1 slice with its bottle returned (craft remainder), 2x below Pam's 2 slices, so it stays
        // out of Pam's tag (final check FC1-1, reversing CF-4)
        assertNotInTag(helper, fdMilk, commonTag("foods/milk"));
        assertInTag(helper, Items.MILK_BUCKET, commonTag("foods/milk"));
        Item groundPork = modItem(helper, "croptopia:ground_pork");
        assertNotInTag(helper, groundPork, commonTag("groundmeats/groundpork"));
        assertNotInTag(helper, groundPork, commonTag("groundmeats"));
        assertInTag(helper, modItem(helper, "pamhc2foodcore:groundporkitem"), commonTag("ground_pork"));
        assertNotInTag(helper, modItem(helper, "croptopia:melon_juice"), commonTag("juices/melonjuice"));

        // EXCLUDE: below every defining mod's floor, no rescuer
        assertNotInTag(helper, modItem(helper, "pamhc2foodcore:toastitem"), commonTag("toasts"));
        assertNotInTag(helper, modItem(helper, "pamhc2foodcore:cookingoilitem"), commonTag("olive_oils"));
        assertNotInTag(helper, modItem(helper, "croptopia:apple_juice"), commonTag("juices/applejuice"));
        assertNotInTag(helper, modItem(helper, "farm_and_charm:dough"), PantryworkTagKeys.DOUGH);
        assertNotInTag(helper, modItem(helper, "farm_and_charm:raw_pasta"), commonTag("foods/pasta"));
        assertNotInTag(helper, modItem(helper, "pamhc2foodcore:pastaitem"), commonTag("foods/pasta"));
        assertNotInTag(helper, modItem(helper, "farm_and_charm:farmers_bread"), commonTag("foods/bread"));
        assertNotInTag(helper, modItem(helper, "farm_and_charm:roasted_chicken"), commonTag("foods/cooked_chicken"));
        assertNotInTag(helper, modItem(helper, "farm_and_charm:bacon_with_eggs"), commonTag("cookedpork"));
        assertNotInTag(helper, modItem(helper, "farmersdelight:cabbage_leaf"), commonTag("foods/vegetable"));
        // PASS, not EXCLUDE: a melon slice is raw gathered produce (the melon block's drop), one
        // base unit like an apple (SapperSquad, FC2-4)
        assertInTag(helper, Items.MELON_SLICE, commonTag("fruits"));
        Item fugu = modItem(helper, "oceansdelight:fugu_slice");
        assertNotInTag(helper, fugu, commonTag("foods/raw_fish"));
        assertNotInTag(helper, fugu, commonTag("foods/safe_raw_fish"));
        // ...while the role layer (classification, not recipe currency) keeps the cheap dishes
        Item buffalo = modItem(helper, "meadow:cooked_buffalo_meat");
        assertNotInTag(helper, buffalo, commonTag("foods/cooked_meat"));
        assertInTag(helper, buffalo, PantryworkTagKeys.PROTEIN);

        // non-food blocks never cross a bridge: B&C's cheese wheels are food-less BlockItems
        Item wheel = modItem(helper, "brewinandchewin:flaxen_cheese_wheel");
        assertNotInTag(helper, wheel, C_CHEESE);
        assertNotInTag(helper, wheel, C_CHEESES);
        assertNotInTag(helper, wheel, PantryworkTagKeys.CHEESE);
        assertNotInTag(helper, wheel, PantryworkTagKeys.DAIRY);
        assertInTag(helper, modItem(helper, "brewinandchewin:flaxen_cheese_wedge"), PantryworkTagKeys.CHEESE);
        helper.succeed();
    }

    private static Optional<ItemStack> tryCraft(GameTestHelper helper, List<ItemStack> stacks) {
        CraftingInput input = CraftingInput.of(stacks.size(), 1, stacks);
        return helper.getLevel().getRecipeManager()
            .getRecipeFor(RecipeType.CRAFTING, input, helper.getLevel())
            .map(holder -> holder.value().assemble(input, helper.getLevel().registryAccess()));
    }

    private static ItemStack craft(GameTestHelper helper, List<ItemStack> stacks) {
        Optional<ItemStack> result = tryCraft(helper, stacks);
        if (result.isEmpty()) {
            helper.fail("no crafting recipe matched " + stacks);
            return ItemStack.EMPTY;
        }
        return result.get();
    }

    private static Item modItem(GameTestHelper helper, String id) {
        Optional<Item> item = BuiltInRegistries.ITEM.getOptional(ResourceLocation.parse(id));
        if (item.isEmpty()) {
            helper.fail("item " + id + " missing - is its mod on the dev classpath?");
        }
        return item.orElse(Items.AIR);
    }

    private static void assertInTag(GameTestHelper helper, Item item, TagKey<Item> tag) {
        helper.assertTrue(new ItemStack(item).is(tag),
            item + " missing from #" + tag.location());
    }

    private static void assertNotInTag(GameTestHelper helper, Item item, TagKey<Item> tag) {
        helper.assertFalse(new ItemStack(item).is(tag),
            item + " must NOT be in #" + tag.location());
    }

    private static TagKey<Item> commonTag(String path) {
        return TagKey.create(Registries.ITEM, ResourceLocation.fromNamespaceAndPath("c", path));
    }

    /** A cost-floor gate overlay's own tag: defined only while that overlay applies. */
    private static TagKey<Item> gatedTag(String path) {
        return TagKey.create(Registries.ITEM, ResourceLocation.fromNamespaceAndPath(Pantrywork.MOD_ID, "gated/" + path));
    }
}
