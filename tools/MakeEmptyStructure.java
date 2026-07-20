import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.zip.GZIPOutputStream;

/**
 * Writes the empty 1x1x1 structure template the gametests use as their
 * arena (data/pantrywork/structure/empty.nbt). Vanilla structure NBT with
 * empty blocks/palette/entities lists.
 *
 *   javac tools/MakeEmptyStructure.java -d tools/work
 *   java -cp tools/work MakeEmptyStructure
 */
public class MakeEmptyStructure {

    private static final int DATA_VERSION_1_21_1 = 3955;

    public static void main(String[] args) throws IOException {
        File out = new File(args.length > 0 ? args[0]
            : "src/main/resources/data/pantrywork/structure/empty.nbt");
        out.getParentFile().mkdirs();
        try (DataOutputStream d = new DataOutputStream(
                new GZIPOutputStream(new FileOutputStream(out)))) {
            d.writeByte(10); d.writeUTF("");              // root compound
            d.writeByte(9); d.writeUTF("size");           // size: [1,1,1]
            d.writeByte(3); d.writeInt(3);
            d.writeInt(1); d.writeInt(1); d.writeInt(1);
            d.writeByte(9); d.writeUTF("entities");       // empty list
            d.writeByte(0); d.writeInt(0);
            d.writeByte(9); d.writeUTF("blocks");         // empty list
            d.writeByte(0); d.writeInt(0);
            d.writeByte(9); d.writeUTF("palette");        // empty list
            d.writeByte(0); d.writeInt(0);
            d.writeByte(3); d.writeUTF("DataVersion");
            d.writeInt(DATA_VERSION_1_21_1);
            d.writeByte(0);                               // end root
        }
        System.out.println("wrote " + out.getAbsolutePath());
    }
}
