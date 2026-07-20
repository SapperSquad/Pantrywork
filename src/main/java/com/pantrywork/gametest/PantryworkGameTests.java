package com.pantrywork.gametest;

import com.pantrywork.Pantrywork;
import com.pantrywork.PantryworkTagKeys;
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
import net.minecraft.world.item.crafting.CraftingRecipe;
import net.minecraft.world.item.crafting.RecipeHolder;
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
        assertInTag(helper, modItem(helper, "croptopia:cheese"), C_CHEESE);
        assertInTag(helper, modItem(helper, "farmersdelight:bacon"), C_RAWPORK);
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

    @GameTest(template = "empty")
    public static void pamsRecipeAcceptsForeignIngredients(GameTestHelper helper) {
        ItemStack result = craft(helper, List.of(
            new ItemStack(modItem(helper, "pamhc2foodcore:skilletitem")),
            new ItemStack(Items.BREAD),
            new ItemStack(modItem(helper, "croptopia:butter")),
            new ItemStack(modItem(helper, "croptopia:cheese")),
            new ItemStack(modItem(helper, "farmersdelight:bacon"))));
        helper.assertTrue(result.is(modItem(helper, "pamhc2foodcore:grilledcheeseandhamitem")),
            "expected pamhc2foodcore:grilledcheeseandhamitem, got " + result);
        helper.succeed();
    }

    private static ItemStack craft(GameTestHelper helper, List<ItemStack> stacks) {
        CraftingInput input = CraftingInput.of(stacks.size(), 1, stacks);
        Optional<RecipeHolder<CraftingRecipe>> recipe = helper.getLevel().getRecipeManager()
            .getRecipeFor(RecipeType.CRAFTING, input, helper.getLevel());
        if (recipe.isEmpty()) {
            helper.fail("no crafting recipe matched " + stacks);
            return ItemStack.EMPTY;
        }
        return recipe.get().value().assemble(input, helper.getLevel().registryAccess());
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

    private static TagKey<Item> commonTag(String path) {
        return TagKey.create(Registries.ITEM, ResourceLocation.fromNamespaceAndPath("c", path));
    }
}
