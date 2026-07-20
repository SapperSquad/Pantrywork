package com.pantrywork;

import net.neoforged.fml.common.Mod;

/**
 * Pantrywork — cross-mod food interoperability layer.
 *
 * The payload is data, not code: a shared tag taxonomy extending the
 * built-in c:foods/* convention, plus per-mod tag assignments whose
 * entries are all optional (required=false), so any subset of supported
 * mods can be installed without errors. This class exists so the data
 * ships as a mod and downstream mods have something to compile against.
 */
@Mod(Pantrywork.MOD_ID)
public class Pantrywork {

    public static final String MOD_ID = "pantrywork";
}
