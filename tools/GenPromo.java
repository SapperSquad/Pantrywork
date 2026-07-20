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
        write(icon(),       "promo/icon-512.png");
        write(banner(),     "promo/banner-1920x640.png");
        write(galleryTag(), "promo/gallery-1-one-tag.png");
        write(galleryCraft(),"promo/gallery-2-four-mod-craft.png");
        write(galleryRole(), "promo/gallery-3-role-tags.png");
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
        g.drawString("The food-mod interop layer for NeoForge 1.21.1", 100, 470);

        // right: three dialect cheeses converge into one canonical tag
        int cx = 1250, s = 120;
        int[] ys = {90, 260, 430};
        BufferedImage[] items = {tex("cheese"), tex("cheeseitem"), tex("wheat_dough")};
        Color[] mods = {C_CROP, C_PAMS, C_FD};
        String[] labels = {"c:cheeses", "c:cheese", "c:foods/dough/wheat"};
        for (int i = 0; i < 3; i++) {
            slotItem(g, items[i], mods[i], cx, ys[i], s);
            g.setFont(new Font("Consolas", Font.PLAIN, 26));
            g.setColor(mods[i]);
            g.drawString(labels[i], cx - g.getFontMetrics().stringWidth(labels[i]) - 18, ys[i] + s / 2 + 8);
            arrow(g, new Color(245, 233, 208, 150), cx + s + 14, ys[i] + s / 2, 1560, 320);
        }
        tagShape(g, AMBER, 1585, 250, 290, 140);
        g.setFont(new Font("Consolas", Font.BOLD, 34));
        g.setColor(BG_DARK);
        g.drawString("#c:foods", 1668, 310);
        g.drawString("one tag", 1672, 352);
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
        headline(g, "Three dialects. One vocabulary.", 76, 180, 64);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 30));
        g.setColor(BODY);
        g.drawString("The big food mods already ship common tags - in naming dialects that never reference each other.", 80, 250);

        // bottom: dialect chips, three fixed lanes with measured widths
        int rowY = 710;
        int[] laneX = {110, 700, 1140};
        Color[] laneC = {C_CROP, C_PAMS, C_FD};
        String[] laneName = {"Croptopia (701 tags)", "Pam's HC2 (196 tags)", "Farmer's Delight (70 tags)"};
        String[][] laneChips = {{"c:cheeses", "c:doughs", "c:milks"},
                                {"c:cheese", "c:rawpork"},
                                {"c:foods/raw_pork"}};
        g.setFont(new Font("Segoe UI", Font.BOLD, 28));
        for (int i = 0; i < 3; i++) {
            g.setColor(laneC[i]);
            g.drawString(laneName[i], laneX[i], rowY - 28);
            int cx2 = laneX[i];
            for (String c : laneChips[i]) cx2 += chip(g, c, laneC[i], BG_DARK, cx2, rowY, 54, 26) + 12;
        }

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
        arrow(g, new Color(245, 233, 208, 140), 300, rowY - 64, 300, midY + 100);
        arrow(g, new Color(245, 233, 208, 140), 840, rowY - 64, 700, midY + 100);
        arrow(g, new Color(245, 233, 208, 140), 1290, rowY - 64, 1030, midY + 100);
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
        headline(g, "Four mods. One sandwich.", 76, 180, 64);
        g.setFont(new Font("Segoe UI", Font.PLAIN, 30));
        g.setColor(BODY);
        g.drawString("Pam's own Grilled Cheese & Ham recipe - crafted from Croptopia dairy and Farmer's Delight bacon.", 80, 250);

        // 3x3 grid
        int s = 150, gx = 240, gy = 330, gap = 14;
        BufferedImage[] grid = {tex("skilletitem"), tex("bread"), tex("butter"),
                                tex("cheese"), tex("bacon"), null, null, null, null};
        Color[] gmods = {C_PAMS, C_VANILLA, C_CROP, C_CROP, C_FD, null, null, null, null};
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
                             {C_CROP, "Croptopia"}, {C_FD, "Farmer's Delight"}};
        int lx = 1250, ly = 350;
        g.setFont(new Font("Segoe UI", Font.BOLD, 30));
        for (Object[] row : legend) {
            g.setColor((Color) row[0]);
            g.fillOval(lx, ly - 22, 26, 26);
            g.setColor(BODY);
            g.drawString((String) row[1], lx + 42, ly);
            ly += 58;
        }
        g.setFont(new Font("Segoe UI", Font.ITALIC, 26));
        g.setColor(BODY);
        g.drawString("Zero config.", lx, ly + 20);
        g.drawString("Zero hard dependencies.", lx, ly + 56);
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
        BufferedImage[] prot = {tex("cooked_beef"), tex("cooked_chicken"), tex("cooked_bacon"),
                                tex("roasted_dragon_meat"), tex("cooked_guardian_tail")};
        Color[] pmods = {C_VANILLA, C_VANILLA, C_FD, C_ENDS, C_OCEANS};
        String[] pnames = {"Steak", "Chicken", "Bacon", "Dragon meat", "Guardian tail"};
        int ix = ax, iy = ay + 90, is = 110;
        g.setFont(new Font("Segoe UI", Font.PLAIN, 22));
        for (int i = 0; i < prot.length; i++) {
            slotItem(g, prot[i], pmods[i], ix, iy, is);
            g.setColor(BODY);
            g.drawString(pnames[i], ix + (is - g.getFontMetrics().stringWidth(pnames[i])) / 2, iy + is + 30);
            ix += is + 24;
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
