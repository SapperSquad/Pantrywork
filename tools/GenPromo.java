// Pantrywork promo art generator.
//
// Generates the icon, banner, and gallery images from code + the real item
// textures of the bridged mods (extracted to tools/work/tex by the session
// that built this; re-extract from the jars in tools/work/jars if missing).
// Same philosophy as ReelRivals/tools/GenCards.java: art that carries
// content claims must be regenerable, never a source-less PNG.
//
// Run:  java tools/GenPromo.java     (from the project root; Java 11+)
// Out:  promo/icon-512.png, promo/banner-1920x640.png, promo/gallery-*.png
//
// Style: SapperSquad gallery language (dark gradient, heavy white headline,
// amber underline slab, eyebrow text) in warm pantry browns. ASCII only.

import java.awt.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;

public class GenPromo {

    // ---- palette ----------------------------------------------------------
    static final Color BG_DARK  = new Color(0x261509);
    static final Color BG_LIGHT = new Color(0x54331A);
    static final Color CREAM    = new Color(0xF5E9D0);
    static final Color AMBER    = new Color(0xFFC845);
    static final Color BODY     = new Color(0xD8C7B0);
    static final Color PANEL    = new Color(0x1C1008);

    // one color per source mod, used consistently across every image
    static final Color C_VANILLA = new Color(0x9DB29D);
    static final Color C_FD      = new Color(0xE07A3F);
    static final Color C_CROP    = new Color(0x7FBF5A);
    static final Color C_PAMS    = new Color(0xC77FD0);
    static final Color C_ENDS    = new Color(0x9B6BD8);
    static final Color C_OCEANS  = new Color(0x5FB7D4);
    static final Color C_VINERY  = new Color(0xB0455F);
    static final Color C_FARM    = new Color(0xE0B84A);
    static final Color C_MEADOW  = new Color(0x6FA88C);
    static final Color C_AQUA    = new Color(0x3E7BB8);
    static final Color C_BREW    = new Color(0xB07A35);
    static final Color C_CREATE  = new Color(0x8C9AA6);
    static final Color C_BOUNTY  = new Color(0xCFD65A);
    static final Color C_FOT     = new Color(0x2FB59C);
    static final Color C_REFURB  = new Color(0xCFC8BC);
    static final Color C_KALEIDO = new Color(0xE08A3C);
    static final Color C_HEARTH  = new Color(0xC75B3F);
    static final Color C_CULTURE = new Color(0x7FA653);
    static final Color C_COOKS   = new Color(0xD9B23A);
    static final Color C_RUSTIC  = new Color(0xB5342C);
    static final Color C_HYBRID  = new Color(0x5FA8C9);
    static final Color C_BYG     = new Color(0x5A62B8);

    // Bumped whenever a compat module ships. Baked into gallery art, so it must
    // be re-checked every release - images can't be grepped when they go stale.
    // galleryRoster() refuses to render when its roster disagrees with this count.
    // 0.8.0: 14 -> 20, matching the optional AFTER deps in
    // src/main/templates/META-INF/neoforge.mods.toml (Origins is a consumer, not a
    // bridged food mod, and has the card's footer line to itself).
    static final int FOOD_MOD_COUNT = 21;
    static final int DIALECT_COUNT = 4;
    static final String[] NUMBER_WORDS = {"Zero", "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen",
        "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen", "Twenty", "Twenty-one"};

    static final String TEX = "tools/work/tex/";

    public static void main(String[] args) throws Exception {
        new File("promo").mkdirs();
        if (args.length > 0 && args[0].equals("icons")) {
            new File("promo/icon-candidates").mkdirs();
            write(iconShelf(),  "promo/icon-candidates/icon-a-shelf.png");
            write(iconCheese(), "promo/icon-candidates/icon-b-tagged-cheese.png");
            write(iconRings(),  "promo/icon-candidates/icon-c-rings.png");
            System.out.println("done");
            return;
        }
        write(icon(),        "promo/icon-512.png");
        write(banner(),      "promo/banner-1920x640.png");
        write(galleryTag(),  "promo/gallery-1-one-tag.png");
        write(galleryCraft(),"promo/gallery-2-four-mod-craft.png");
        write(galleryRole(), "promo/gallery-3-role-tags.png");
        write(galleryRoster(),"promo/gallery-4-supported-mods.png");
        System.out.println("done");
    }

    // ---- icon candidates (pick one, then make icon() delegate to it) ------

    /** A: pantry shelves holding recognizable foods. */
    static BufferedImage iconShelf() throws Exception {
        int S = 512;
        BufferedImage img = new BufferedImage(S, S, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = canvas(img);
        Shape rr = new RoundRectangle2D.Double(0, 0, S, S, 96, 96);
        g.setClip(rr);
        pantryBackground(g, S, S);
        // cupboard inner frame
        g.setColor(new Color(0, 0, 0, 70));
        g.fillRoundRect(36, 36, S - 72, S - 72, 48, 48);
        // two shelves
        Color plank = new Color(0x8A5527), plankEdge = new Color(0x5E3517);
        for (int sy : new int[]{250, 430}) {
            g.setColor(plank);
            g.fillRect(48, sy, S - 96, 26);
            g.setColor(plankEdge);
            g.fillRect(48, sy + 26, S - 96, 10);
        }
        // foods resting on the shelves (top: bread + cheese, bottom: bacon + milk)
        item(g, tex("bread"),       70, 250 - 150, 150);
        item(g, tex("cheese"),     290, 250 - 150, 150);
        item(g, tex("bacon"),       70, 430 - 150, 150);
        item(g, tex("milk_bucket"),290, 430 - 150, 150);
        g.setClip(null);
        g.dispose();
        return img;
    }

    /** B: one big cheese wearing a small c: tag. */
    static BufferedImage iconCheese() throws Exception {
        int S = 512;
        BufferedImage img = new BufferedImage(S, S, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = canvas(img);
        Shape rr = new RoundRectangle2D.Double(0, 0, S, S, 96, 96);
        g.setClip(rr);
        pantryBackground(g, S, S);
        g.setClip(null);
        // soft glow behind the cheese so it pops
        g.setPaint(new RadialGradientPaint(new Point(256, 236), 230,
            new float[]{0f, 1f}, new Color[]{new Color(255, 200, 69, 70), new Color(255, 200, 69, 0)}));
        g.fillOval(26, 6, 460, 460);
        item(g, tex("cheeseitem"), 66, 46, 380);
        // small amber tag hanging off the lower right, tilted
        g.rotate(Math.toRadians(14), 360, 380);
        tagShape(g, AMBER, 250, 330, 200, 96);
        g.setFont(new Font("Consolas", Font.BOLD, 64));
        g.setColor(BG_DARK);
        g.drawString("c:", 320, 402);
        g.rotate(Math.toRadians(-14), 360, 380);
        g.dispose();
        return img;
    }

    /** C: three interlocked mod-colored rings around a cheese. */
    static BufferedImage iconRings() throws Exception {
        int S = 512;
        BufferedImage img = new BufferedImage(S, S, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = canvas(img);
        Shape rr = new RoundRectangle2D.Double(0, 0, S, S, 96, 96);
        g.setClip(rr);
        pantryBackground(g, S, S);
        g.setClip(null);
        g.setStroke(new BasicStroke(34f));
        int r = 150;
        g.setColor(C_CROP);
        g.drawOval(96, 116, 2 * r, 2 * r);
        g.setColor(C_PAMS);
        g.drawOval(166, 116, 2 * r, 2 * r);
        g.setColor(C_FD);
        g.drawOval(131, 176, 2 * r, 2 * r);
        item(g, tex("cheeseitem"), 181, 201, 150);
        g.dispose();
        return img;
    }

    static void write(BufferedImage img, String path) throws Exception {
        ImageIO.write(img, "png", new File(path));
        System.out.println("wrote " + path + " (" + img.getWidth() + "x" + img.getHeight() + ")");
    }

    // ---- shared helpers ---------------------------------------------------

    static Graphics2D canvas(BufferedImage img) {
        Graphics2D g = img.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL, RenderingHints.VALUE_STROKE_PURE);
        return g;
    }

    static void pantryBackground(Graphics2D g, int w, int h) {
        g.setPaint(new GradientPaint(0, h, BG_DARK, w, 0, BG_LIGHT));
        g.fillRect(0, 0, w, h);
        // faint plank lines, a nod to the pantry-shelf theme
        g.setColor(new Color(0, 0, 0, 26));
        for (int y = h / 5; y < h; y += h / 5) g.fillRect(0, y, w, 3);
    }

    static BufferedImage tex(String name) throws Exception {
        return ImageIO.read(new File(TEX + name + ".png"));
    }

    /** Draw an item texture pixel-crisp at the given square size. */
    static void item(Graphics2D g, BufferedImage t, int x, int y, int size) {
        Object old = g.getRenderingHint(RenderingHints.KEY_INTERPOLATION);
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_NEAREST_NEIGHBOR);
        g.drawImage(t, x, y, size, size, null);
        if (old != null) g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, old);
    }

    /** Minecraft-style inventory slot. */
    static void slot(Graphics2D g, int x, int y, int s) {
        g.setColor(new Color(0x14, 0x0C, 0x06));
        g.fillRoundRect(x, y, s, s, 10, 10);
        g.setColor(new Color(255, 255, 255, 22));
        g.fillRoundRect(x, y, s, 8, 10, 10);
        g.setColor(new Color(0, 0, 0, 120));
        g.setStroke(new BasicStroke(3f));
        g.drawRoundRect(x, y, s, s, 10, 10);
    }

    /** Item in a slot with a mod-color badge in the corner. */
    static void slotItem(Graphics2D g, BufferedImage t, Color mod, int x, int y, int s) {
        slot(g, x, y, s);
        int pad = s / 8;
        item(g, t, x + pad, y + pad, s - 2 * pad);
        if (mod != null) {
            g.setColor(mod);
            g.fillOval(x + s - 26, y + 8, 18, 18);
            g.setColor(new Color(0, 0, 0, 140));
            g.setStroke(new BasicStroke(2f));
            g.drawOval(x + s - 26, y + 8, 18, 18);
        }
    }

    /** Rounded tag chip with text, returns width. */
    static int chip(Graphics2D g, String text, Color bg, Color fg, int x, int y, int h, int fontPx) {
        g.setFont(new Font("Consolas", Font.BOLD, fontPx));
        int w = g.getFontMetrics().stringWidth(text) + h;
        g.setColor(bg);
        g.fillRoundRect(x, y, w, h, h, h);
        g.setColor(fg);
        g.drawString(text, x + h / 2, y + h / 2 + fontPx / 3);
        return w;
    }

    /** Stops the render when text in the current font is wider than the space it is given. */
    static void fitOrFail(Graphics2D g, String text, int maxWidth) {
        int w = g.getFontMetrics().stringWidth(text);
        if (w > maxWidth) {
            throw new IllegalStateException("'" + text + "' is " + w + "px wide; only " + maxWidth + "px available");
        }
    }

    static void arrow(Graphics2D g, Color c, int x1, int y1, int x2, int y2) {
        g.setColor(c);
        g.setStroke(new BasicStroke(5f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g.drawLine(x1, y1, x2, y2);
        double a = Math.atan2(y2 - y1, x2 - x1);
        int L = 16;
        g.drawLine(x2, y2, (int) (x2 - L * Math.cos(a - 0.5)), (int) (y2 - L * Math.sin(a - 0.5)));
        g.drawLine(x2, y2, (int) (x2 - L * Math.cos(a + 0.5)), (int) (y2 - L * Math.sin(a + 0.5)));
    }

    static void eyebrow(Graphics2D g, String s, int x, int y) {
        g.setFont(new Font("Segoe UI", Font.BOLD, 34));
        g.setColor(AMBER);
        // manual letter-spacing
        int cx = x;
        for (char ch : s.toCharArray()) {
            g.drawString(String.valueOf(ch), cx, y);
            cx += g.getFontMetrics().charWidth(ch) + 10;
        }
    }

    static void headline(Graphics2D g, String s, int x, int y, int px) {
        g.setFont(new Font("Segoe UI", Font.BOLD, px));
        g.setColor(new Color(0, 0, 0, 55));
        g.drawString(s, x + 2, y + 3);
        g.setColor(Color.WHITE);
        g.drawString(s, x, y);
        int w = g.getFontMetrics().stringWidth(s);
        g.setColor(AMBER);
        g.fillRoundRect(x + 4, y + px / 4 + 8, w - 8, Math.max(10, px / 11), 7, 7);
    }

    /** Luggage-tag shape (the mod's motif), pointing left, with hole. */
    static void tagShape(Graphics2D g, Color fill, int x, int y, int w, int h) {
        int notch = h / 2;
        Path2D p = new Path2D.Double();
        p.moveTo(x + notch, y);
        p.lineTo(x + w - h / 4.0, y);
        p.quadTo(x + w, y, x + w, y + h / 4.0);
        p.lineTo(x + w, y + h - h / 4.0);
        p.quadTo(x + w, y + h, x + w - h / 4.0, y + h);
        p.lineTo(x + notch, y + h);
        p.lineTo(x, y + h / 2.0);
        p.closePath();
        g.setColor(new Color(0, 0, 0, 90));
        g.translate(4, 6); g.fill(p); g.translate(-4, -6);
        g.setColor(fill);
        g.fill(p);
        g.setColor(new Color(0, 0, 0, 60));
        g.setStroke(new BasicStroke(4f));
        g.draw(p);
        int hole = h / 7;
        g.setColor(BG_DARK);
        g.fillOval(x + notch - hole / 2, y + h / 2 - hole / 2, hole, hole);
    }

    // ---- icon -------------------------------------------------------------

    /** The shipped icon: candidate A (pantry shelf), picked by SapperSquad 2026-07-19. */
    static BufferedImage icon() throws Exception {
        return iconShelf();
    }

    // ---- banner -----------------------------------------------------------

    static BufferedImage banner() throws Exception {
        int W = 1920, H = 640;
        BufferedImage img = new BufferedImage(W, H, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = canvas(img);
        pantryBackground(g, W, H);

        eyebrow(g, "SAPPERSQUAD", 100, 150);
        headline(g, "PANTRYWORK", 92, 300, 150);
        g.setFont(new Font("Segoe UI", Font.BOLD, 52));
        g.setColor(CREAM);
        g.drawString("One cheese. Every recipe.", 100, 410);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 34));
        g.setColor(BODY);
        g.drawString("The food-mod interop layer - NeoForge & Fabric", 100, 470);

        // Right: four mods' cheeses converge into one canonical tag. Labelled by
        // mod rather than tag - several of them legitimately use the same tag
        // name, so tag labels would read as duplicates.
        //
        // Labels sit to the RIGHT of their slot on purpose: left-aligned labels
        // grow leftwards as mod names get longer and collide with the headline
        // (0.3.0 shipped with "Pam's HC2" overlapping the K in PANTRYWORK).
        // This way a longer name can never reach the wordmark.
        int cx = 1180, s = 100;
        int[] ys = {70, 205, 340, 475};
        BufferedImage[] items = {tex("cheese"), tex("cheeseitem"),
                                 tex("meadow__cheese_slice"), tex("brewinandchewin__flaxen_cheese_wedge")};
        Color[] mods = {C_CROP, C_PAMS, C_MEADOW, C_BREW};
        String[] labels = {"Croptopia", "Pam's HC2", "Meadow", "Brewin' & Chewin'"};
        int labelX = cx + s + 16;
        // Arrows start past the WIDEST label, measured rather than guessed, so a
        // longer mod name can never be crossed out by its own arrow.
        g.setFont(new Font("Segoe UI", Font.BOLD, 22));
        int widest = 0;
        for (String l : labels) widest = Math.max(widest, g.getFontMetrics().stringWidth(l));
        int arrowX = labelX + widest + 20;
        for (int i = 0; i < items.length; i++) {
            slotItem(g, items[i], mods[i], cx, ys[i], s);
            g.setFont(new Font("Segoe UI", Font.BOLD, 22));
            g.setColor(mods[i]);
            g.drawString(labels[i], labelX, ys[i] + s / 2 + 8);
            arrow(g, new Color(245, 233, 208, 140), arrowX, ys[i] + s / 2, 1608, 320);
        }
        tagShape(g, AMBER, 1632, 252, 258, 136);
        g.setFont(new Font("Consolas", Font.BOLD, 25));
        g.setColor(BG_DARK);
        g.drawString("#c:foods", 1726, 302);
        g.drawString("/cheese", 1732, 334);
        g.setFont(new Font("Segoe UI", Font.BOLD, 19));
        g.drawString("one tag", 1736, 364);
        g.dispose();
        return img;
    }

    // ---- gallery 1: three dialects, one tag -------------------------------

    static BufferedImage galleryTag() throws Exception {
        int W = 1600, H = 900;
        BufferedImage img = new BufferedImage(W, H, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = canvas(img);
        pantryBackground(g, W, H);
        eyebrow(g, "PANTRYWORK", 80, 100);
        headline(g, "Four dialects. One vocabulary.", 76, 180, 64);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 30));
        g.setColor(BODY);
        g.drawString("The big food mods already ship common tags - in naming dialects that never reference each other.", 80, 250);

        // bottom: dialect chips, four fixed lanes with measured widths
        int rowY = 715;
        int[] laneX = {90, 470, 850, 1230};
        Color[] laneC = {C_CROP, C_PAMS, C_FD, C_FARM};
        String[] laneName = {"Croptopia (701)", "Pam's HC2 (196)", "Farmer's Delight (70)", "Farm & Charm (39)"};
        String[][] laneChips = {{"c:cheeses", "c:doughs"},
                                {"c:cheese", "c:rawpork"},
                                {"c:foods/raw_pork"},
                                {"c:raw_pork", "c:butter"}};
        g.setFont(new Font("Segoe UI", Font.BOLD, 25));
        for (int i = 0; i < laneX.length; i++) {
            g.setColor(laneC[i]);
            g.drawString(laneName[i], laneX[i], rowY - 26);
            int cx2 = laneX[i];
            for (String c : laneChips[i]) cx2 += chip(g, c, laneC[i], BG_DARK, cx2, rowY, 48, 22) + 10;
        }
        // the punchline: three of those mean the same thing
        g.setFont(new Font("Segoe UI", Font.ITALIC, 25));
        g.setColor(BODY);
        g.drawString("rawpork / raw_pork / foods/raw_pork - three spellings, one ingredient", 90, 830);

        // middle: canonical band
        int midY = 470;
        g.setColor(new Color(255, 255, 255, 18));
        g.fillRoundRect(80, midY - 20, W - 160, 116, 24, 24);
        g.setFont(new Font("Segoe UI", Font.BOLD, 28));
        g.setColor(CREAM);
        g.drawString("Identity layer - the official convention, every dialect bridged in", 110, midY + 16);
        int x = 110;
        x += chip(g, "#c:foods/cheese", CREAM, BG_DARK, x, midY + 34, 50, 26) + 16;
        x += chip(g, "#c:foods/dough", CREAM, BG_DARK, x, midY + 34, 50, 26) + 16;
        x += chip(g, "#c:foods/raw_pork", CREAM, BG_DARK, x, midY + 34, 50, 26) + 16;
        chip(g, "#c:drinks/milk", CREAM, BG_DARK, x, midY + 34, 50, 26);

        // top: role band (short names, namespace stated once in the title)
        int topY = 300;
        g.setColor(new Color(255, 200, 69, 26));
        g.fillRoundRect(80, topY - 20, W - 160, 116, 24, 24);
        g.setFont(new Font("Segoe UI", Font.BOLD, 28));
        g.setColor(AMBER);
        g.drawString("Role layer - pantrywork:food_component/* - what an ingredient does in a dish", 110, topY + 16);
        x = 110;
        String[] roles = {"protein", "starch", "dairy", "garnish", "liquid_base", "sweetener"};
        for (String r : roles) x += chip(g, r, AMBER, BG_DARK, x, topY + 34, 50, 26) + 14;

        // arrows dialect -> canonical -> role
        arrow(g, new Color(245, 233, 208, 140), 250, rowY - 62, 280, midY + 100);
        arrow(g, new Color(245, 233, 208, 140), 620, rowY - 62, 600, midY + 100);
        arrow(g, new Color(245, 233, 208, 140), 990, rowY - 62, 900, midY + 100);
        arrow(g, new Color(245, 233, 208, 140), 1350, rowY - 62, 1180, midY + 100);
        arrow(g, new Color(255, 200, 69, 170), 500, midY - 25, 500, topY + 100);
        g.dispose();
        return img;
    }

    // ---- gallery 2: the four-mod craft ------------------------------------

    static BufferedImage galleryCraft() throws Exception {
        int W = 1600, H = 900;
        BufferedImage img = new BufferedImage(W, H, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = canvas(img);
        pantryBackground(g, W, H);
        eyebrow(g, "PANTRYWORK", 80, 100);
        // Vanilla is not a mod: the legend shows three mods (Pam's, Farm & Charm, Brewin')
        // plus vanilla bread and porkchop. The 0.7.0 draft said "Four mods." (critic CRIT-5).
        headline(g, "Three mods and vanilla. One sandwich.", 76, 180, 64);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 30));
        g.setColor(BODY);
        // The exact craft verified live in 0.7.0 (tagtest-reverse.txt Craft B and the
        // pamsRecipeAcceptsForeignIngredients GameTest). Until 0.6.0 this card showed Croptopia
        // butter/cheese and Farmer's Delight bacon; 0.7.0's cost floor took those out of Pam's
        // c:butter / c:cheese / c:rawpork, so the card had to change with the data.
        String sub = "Pam's own Grilled Cheese & Ham recipe - crafted with Farm & Charm butter and Brewin' & Chewin' cheese.";
        fitOrFail(g, sub, W - 160);
        g.drawString(sub, 80, 250);

        // 3x3 grid
        int s = 150, gx = 240, gy = 330, gap = 14;
        BufferedImage[] grid = {tex("skilletitem"), tex("bread"), tex("farm_and_charm__butter"),
                                tex("brewinandchewin__flaxen_cheese_wedge"), tex("porkchop"), null, null, null, null};
        Color[] gmods = {C_PAMS, C_VANILLA, C_FARM, C_BREW, C_VANILLA, null, null, null, null};
        for (int i = 0; i < 9; i++) {
            int x = gx + (i % 3) * (s + gap), y = gy + (i / 3) * (s + gap);
            if (grid[i] == null) slot(g, x, y, s);
            else slotItem(g, grid[i], gmods[i], x, y, s);
        }
        // arrow and result
        arrow(g, CREAM, gx + 3 * (s + gap) + 40, gy + s + s / 2, gx + 3 * (s + gap) + 190, gy + s + s / 2);
        int rs = 240, rx = gx + 3 * (s + gap) + 240, ry = gy + s + s / 2 - rs / 2;
        slotItem(g, tex("grilledcheeseandhamitem"), C_PAMS, rx, ry, rs);
        g.setFont(new Font("Segoe UI", Font.BOLD, 30));
        g.setColor(CREAM);
        g.drawString("Grilled Cheese & Ham", rx - 20, ry + rs + 46);

        // legend
        Object[][] legend = {{C_PAMS, "Pam's HarvestCraft 2"}, {C_VANILLA, "Vanilla"},
                             {C_FARM, "Farm & Charm"}, {C_BREW, "Brewin' & Chewin'"}};
        int lx = 1250, ly = 350;
        g.setFont(new Font("Segoe UI", Font.BOLD, 30));
        for (Object[] row : legend) {
            fitOrFail(g, (String) row[1], W - 12 - (lx + 42));
            g.setColor((Color) row[0]);
            g.fillOval(lx, ly - 22, 26, 26);
            g.setColor(BODY);
            g.drawString((String) row[1], lx + 42, ly);
            ly += 58;
        }
        g.setFont(new Font("Segoe UI", Font.ITALIC, 26));
        g.setColor(BODY);
        // Not "Zero hard dependencies": the Fabric files need Fabric API (without it the mod's
        // data never loads - measured 2026-09-13). What is true everywhere: no food mod is required.
        g.drawString("Zero config.", lx, ly + 20);
        g.drawString("No food mod required.", lx, ly + 56);
        g.dispose();
        return img;
    }

    // ---- gallery 4: the supported-mod roster ------------------------------

    static BufferedImage galleryRoster() throws Exception {
        int W = 1600, H = 900;
        BufferedImage img = new BufferedImage(W, H, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = canvas(img);
        pantryBackground(g, W, H);
        eyebrow(g, "PANTRYWORK", 80, 100);

        String[][] roster = {
            {"cheese",                              "Croptopia"},
            {"cheeseitem",                          "Pam's HarvestCraft 2"},
            {"cooked_bacon",                        "Farmer's Delight"},
            {"cooked_guardian_tail",                "Ocean's Delight"},
            {"roasted_dragon_meat",                 "End's Delight"},
            {"vinery__red_grape",                   "Let's Do Vinery"},
            {"farm_and_charm__butter",              "Let's Do Farm & Charm"},
            {"meadow__cheese_slice",                "Let's Do Meadow"},
            {"aquaculture__atlantic_cod",           "Aquaculture 2"},
            {"brewinandchewin__flaxen_cheese_wedge","Brewin' & Chewin'"},
            {"create__dough",                       "Create"},
            {"bountifulfares__maize",               "Bountiful Fares"},
            {"fishofthieves__pineapple",            "Fish of Thieves"},
            {"refurbished_furniture__cheese",       "Refurbished Furniture"},
            {"kaleidoscope_cookery__fried_egg",     "Kaleidoscope Cookery"},
            {"hearthandharvest__butter",            "Hearth and Harvest"},
            {"culturaldelights__avocado",           "Cultural Delights"},
            {"cookscollection__lemon",              "Cook's Collection"},
            {"rusticdelight__bell_pepper_red",      "Rustic Delight"},
            {"hybrid_delights__salt",               "Hybrid Delights"},
            // 0.8.0: a WORLDGEN mod that happens to grow food. It is counted here because
            // the count is the 1.21.1 toml's optional-AFTER list, and Pantrywork bridges
            // four of its fruits - not because it is a cooking mod.
            {"biomeswevegone__blueberries",         "Oh The Biomes We've Gone"}
        };
        Color[] cols = {C_CROP, C_PAMS, C_FD, C_OCEANS, C_ENDS,
                        C_VINERY, C_FARM, C_MEADOW, C_AQUA, C_BREW,
                        C_CREATE, C_BOUNTY, C_FOT, C_REFURB,
                        C_KALEIDO, C_HEARTH, C_CULTURE, C_COOKS, C_RUSTIC, C_HYBRID,
                        C_BYG};
        // The headline count is derived, never typed: a roster that disagrees with
        // FOOD_MOD_COUNT stops the render instead of shipping a stale number.
        if (roster.length != FOOD_MOD_COUNT || cols.length != roster.length) {
            throw new IllegalStateException("roster lists " + roster.length + " mods (" + cols.length
                + " colors) but FOOD_MOD_COUNT is " + FOOD_MOD_COUNT);
        }
        headline(g, NUMBER_WORDS[FOOD_MOD_COUNT] + " mods bridged.", 76, 180, 64);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 30));
        g.setColor(BODY);
        g.drawString("Install all of them, a few of them, or none - Pantrywork bridges whatever it finds.", 80, 250);

        // Rows of seven (0.8.0: three FULL rows, 7/7/7), each row centered on its own
        // count so a short last row is not left-aligned. Every label line must fit
        // its column with a gutter - measured and enforced here, because a label
        // collision is exactly the kind of defect that survives when art is only
        // eyeballed. The slot size and row pitch shrank at 0.8.0 to fit the third
        // row above the footer; the guard below still proves it.
        int perRow = 7, s = 92, pitch = 205, y0 = 296, gapY = 186;
        int maxLabel = pitch - 20;
        int lowestLabel = 0;
        for (int i = 0; i < roster.length; i++) {
            int row = i / perRow;
            int inRow = Math.min(perRow, roster.length - row * perRow);
            int x0 = (W - ((inRow - 1) * pitch + s)) / 2;
            int cx = x0 + (i % perRow) * pitch;
            int cy = y0 + row * gapY;
            slotItem(g, tex(roster[i][0]), cols[i], cx, cy, s);
            g.setFont(new Font("Segoe UI", Font.BOLD, 22));
            FontMetrics fm = g.getFontMetrics();
            String name = roster[i][1];
            java.util.List<String> lines = new java.util.ArrayList<>();
            if (fm.stringWidth(name) <= maxLabel) {
                lines.add(name);
            } else {
                // wrap at the space that leaves the narrower widest half, but never
                // start a line with "&" ("Let's Do Farm / & Charm" splits the name)
                int best = -1, bestW = Integer.MAX_VALUE;
                for (int k = name.indexOf(' '); k >= 0; k = name.indexOf(' ', k + 1)) {
                    if (name.startsWith("&", k + 1)) continue;
                    int w = Math.max(fm.stringWidth(name.substring(0, k)), fm.stringWidth(name.substring(k + 1)));
                    if (w < bestW) { bestW = w; best = k; }
                }
                if (best < 0) throw new IllegalStateException("label '" + name + "' is too wide and has no space to wrap at");
                lines.add(name.substring(0, best));
                lines.add(name.substring(best + 1));
            }
            int ty = cy + s + 34;
            for (String ln : lines) {
                fitOrFail(g, ln, maxLabel);
                g.setColor(CREAM);
                g.drawString(ln, cx + (s - fm.stringWidth(ln)) / 2, ty);
                ty += 26;
            }
            if (ty - 26 + fm.getDescent() >= cy + gapY && row < (roster.length - 1) / perRow) {
                throw new IllegalStateException("label '" + name + "' runs into the next row");
            }
            lowestLabel = Math.max(lowestLabel, ty - 26 + fm.getDescent());
        }

        g.setFont(new Font("Segoe UI", Font.ITALIC, 26));
        g.setColor(BODY);
        String foot = "Plus Origins diet compat - carnivores and vegetarians can finally eat modded food.";
        int footY = 876;
        // The last row has no row below it to collide with, so the footer is the
        // guard: a roster that grows another row must fail here, not ship overlapped.
        if (lowestLabel >= footY - g.getFontMetrics().getAscent()) {
            throw new IllegalStateException("the last row of labels (bottom " + lowestLabel
                + "px) runs into the footer line at " + footY + "px");
        }
        if (footY + g.getFontMetrics().getDescent() > H) {
            throw new IllegalStateException("the footer line falls off the card");
        }
        fitOrFail(g, foot, W - 2 * 118);
        g.drawString(foot, 118, footY);
        g.dispose();
        return img;
    }

    // ---- gallery 3: role tags for recipe authors --------------------------

    static BufferedImage galleryRole() throws Exception {
        int W = 1600, H = 900;
        BufferedImage img = new BufferedImage(W, H, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = canvas(img);
        pantryBackground(g, W, H);
        eyebrow(g, "PANTRYWORK", 80, 100);
        headline(g, "Write one recipe. Support them all.", 76, 180, 64);

        // code panel
        int px = 80, py = 260, pw = 700, ph = 460;
        g.setColor(PANEL);
        g.fillRoundRect(px, py, pw, ph, 24, 24);
        g.setColor(new Color(255, 255, 255, 30));
        g.setStroke(new BasicStroke(2f));
        g.drawRoundRect(px, py, pw, ph, 24, 24);
        String[][] code = {
            {"{", "w"},
            {"  \"type\":", "w"},
            {"    \"minecraft:crafting_shapeless\",", "w"},
            {"  \"ingredients\": [", "w"},
            {"    { \"tag\": \"c:foods/bread\" },", "b"},
            {"    { \"tag\": \"pantrywork:", "a"},
            {"        food_component/protein\" },", "a"},
            {"    { \"tag\": \"pantrywork:", "a"},
            {"        food_component/garnish\" }", "a"},
            {"  ],", "w"},
            {"  \"result\": { \"id\": \"mymod:sandwich\" }", "w"},
            {"}", "w"}
        };
        g.setFont(new Font("Consolas", Font.PLAIN, 26));
        int cy = py + 52;
        for (String[] line : code) {
            g.setColor(line[1].equals("a") ? AMBER : line[1].equals("b") ? CREAM : new Color(0xA8B5A8));
            g.drawString(line[0], px + 36, cy);
            cy += 34;
        }

        // right: what protein accepts
        int ax = 840, ay = 300;
        g.setFont(new Font("Consolas", Font.BOLD, 32));
        g.setColor(AMBER);
        g.drawString("#pantrywork:food_component/protein", ax, ay);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 30));
        g.setColor(BODY);
        g.drawString("accepts, today:", ax, ay + 44);
        BufferedImage[] prot = {tex("cooked_beef"), tex("cooked_bacon"), tex("roasted_dragon_meat"),
                                tex("cooked_guardian_tail"), tex("aquaculture__fish_fillet_cooked"),
                                tex("meadow__cooked_buffalo_meat")};
        Color[] pmods = {C_VANILLA, C_FD, C_ENDS, C_OCEANS, C_AQUA, C_MEADOW};
        String[] pnames = {"Steak", "Bacon", "Dragon", "Guardian", "Fillet", "Buffalo"};
        int ix = ax, iy = ay + 90, is = 96;
        g.setFont(new Font("Segoe UI", Font.PLAIN, 20));
        for (int i = 0; i < prot.length; i++) {
            slotItem(g, prot[i], pmods[i], ix, iy, is);
            g.setColor(BODY);
            g.drawString(pnames[i], ix + (is - g.getFontMetrics().stringWidth(pnames[i])) / 2, iy + is + 28);
            ix += is + 18;
        }
        g.setFont(new Font("Segoe UI", Font.BOLD, 30));
        g.setColor(CREAM);
        g.drawString("...and every mod that joins the c:foods/*", ax, iy + is + 110);
        g.drawString("convention later - with no update from you.", ax, iy + is + 150);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 28));
        g.setColor(BODY);
        g.drawString("PantryworkTagKeys ships the constants", ax, iy + is + 196);
        g.drawString("for compile-time use.", ax, iy + is + 234);
        g.dispose();
        return img;
    }
}
