# GenForge1201Suites.py - generate the Forge 1.20.1 probe datapack and both 1.20.1 suites.
#
#   python tools/GenForge1201Suites.py solo
#   python tools/GenForge1201Suites.py compat --candidates          # phase 1, writes existence.txt
#   python tools/GenForge1201Suites.py compat --final <existence.out>  # phase 2, writes the suite
#
# WHY THIS EXISTS, AND WHY IT IS PYTHON
# -------------------------------------
# Every other tool here is PowerShell (plus two .java). This one is Python because it does
# nothing but read zip entries and resolve a JSON tag graph, and the project already has a
# second language precedent (tools/GenPromo.java). Python 3.12 is installed on this machine.
# If that ever stops being true, the logic is ~150 lines and ports cleanly - but DO port it
# rather than hand-editing the suites, because both suite files say "re-derive, do not edit".
#
# WHY THE 1.20.1 SUITES CANNOT LOOK LIKE tagtest.txt
# --------------------------------------------------
# `execute if items` and minecraft:crafter are both 1.21 features. On 1.20.1 the only way to
# ask "is this item in this tag" without a player is a predicate, so this script emits one
# predicate per probed tag into tools/testpack-1201 (a test instrument - it is NEVER shipped
# and holds no tag of its own), and the suite sets each item into an armor stand's mainhand
# and asks `execute as ... if predicate`.
#
# Every assertion is phrased so the expected answer is "Test passed": positives with `if`,
# negatives with `unless`. That is not cosmetic - inside an `execute as` fork 1.20.1 SWALLOWS
# the "Test failed" message, so a failed assertion answers nothing at all. tools/CountSuite.ps1
# already counts a missing answer as failed, so the suites stay sound; but it means a suite
# written with `# expect:` annotations would silently classify wrong. Do not add them here.
#
# WHAT IS DERIVED AND WHAT IS DECLARED
# ------------------------------------
# Expectations come from the shipped payload's own tag closure (solo) or from the merged tag
# graph of the jars actually in the harness mods/ folder (compat). Two things are declared by
# hand, both with their reason in the output: SOLO_PINNED and KNOWN_ABSENT. Everything else is
# measured. The compat scenario additionally runs a one-off runtime existence pass, because the
# merged graph names items from mods that are not in the boot, and `item replace` with an
# unknown item would leave the previous item in the hand and silently test the wrong thing.
import zipfile
import json
import os
import io
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRV = os.path.join(ROOT, 'tools', 'forge-server-1201')
MODS = os.path.join(SRV, 'mods')
MCJAR = os.path.join(SRV, 'libraries', 'net', 'minecraft', 'server',
                     '1.20.1-20230612.114412', 'server-1.20.1-20230612.114412-srg.jar')
PACK = os.path.join(ROOT, 'tools', 'testpack-1201')
PRED = os.path.join(PACK, 'data', 'pwtest', 'predicates')
BUILT = os.path.join(ROOT, 'build', 'libs')

ROLES = ['starch', 'protein', 'dairy', 'garnish', 'liquid_base', 'sweetener']

# Canonical tags the SOLO suite asserts: the ones that hold a vanilla item with no mod present.
SOLO_CANON = ['forge:foods/bread', 'forge:foods/cooked_chicken', 'forge:foods/fruit',
              'forge:foods/raw_fish', 'forge:foods/raw_beef', 'forge:foods/raw_chicken',
              'forge:foods/raw_mutton', 'forge:foods/raw_pork', 'forge:foods/vegetable',
              'forge:foods/milk', 'forge:drinks', 'forge:drinks/milk', 'forge:crops/grain']

# Solo semantics pinned on purpose: these items DO sit in a canonical forge: tag but reach no
# role tag until the mod owning the intermediate shows up. Asserted so that wiring one up later
# is a deliberate, visible change rather than a drift.
SOLO_PINNED = [
    ('minecraft:cooked_chicken',
     'in forge:foods/cooked_chicken, but the hop to protein runs through forge:foods/cooked_meat,\n'
     "#   which Farmer's Delight defines and a solo boot does not have"),
    ('minecraft:apple',
     'canonicalised into forge:foods/fruit but intentionally not a role component'),
    ('minecraft:wheat',
     'a crop (forge:crops/grain), not a prepared component'),
]

# The COMPAT merged graph says these belong in the tag; this line deliberately does not deliver
# them. Asserted as negatives so the gap is tested rather than implied.
KNOWN_ABSENT = [
    ('forge:doughs', 'farmersdelight:wheat_dough'),
    ('forge:doughs', 'kaleidoscope_cookery:raw_dough'),
    ('forge:doughs', 'pamhc2foodcore:doughitem'),
    ('forge:doughs', 'create:dough'),
]
KNOWN_ABSENT_NOTE = (
    "GATE-DROPPED ON THIS LINE. forge:doughs carries Croptopia's 2.1-wheat floor and these\n"
    "#     doughs all undercut it (FD 1.083, Kaleidoscope 1.013, Pam's 0.6, Create 2/3), so they\n"
    '#     are legitimate only alongside Farm & Charm, which declares its own 0.094 floor. 1.21\n'
    '#     ships that condition as a pack overlay; pack format 15 has no overlays at all, so on\n'
    '#     1.20.1 the four entries are dropped instead (docs/FORGE-1201.md). Upstream compounds\n'
    "#     it: Croptopia's forge:doughs -> #forge:dough edge is OPTIONAL and sits in a cycle with\n"
    "#     Kaleidoscope's forge:dough -> #forge:doughs, so the game drops that edge in silence.\n"
    '#     Net effect, measured: forge:dough holds all six doughs, forge:doughs holds two. This\n'
    '#     is a real capability difference between the 1.21 and 1.20.1 jars, not an oversight.')

# Cases from the design record. Asserted by name so sampling can never drop them.
NAMED = [
    ('forge:fruits', ['croptopia:strawberry', 'farm_and_charm:strawberry'],
     "the third-mod rule: both mods' strawberries land here, and neither arrives via the other"),
    ('forge:cookingoil', None,
     "the 0.8.0 flagship - Kaleidoscope's wok oil tag is what unlocked 225 recipes"),
    ('forge:foods/cheese', None,
     "the store-copy audit case: cheese comes from these mods and NOT from Farmer's Delight"),
    ('forge:dough', None, 'the dialect pair forge:dough / forge:doughs'),
    ('forge:doughs', None, 'the dialect pair forge:dough / forge:doughs'),
    ('forge:raw_fishes', None, "Pam's dialect (rawfish) against the canonical spelling"),
    ('forge:rawfish', None, "Pam's dialect (rawfish) against the canonical spelling"),
]

NONFOOD = ['minecraft:stone', 'minecraft:iron_ingot', 'farmersdelight:iron_knife',
           'croptopia:frying_pan', 'minecraft:wheat_seeds', 'aquaculture:iron_fishing_rod']


def payload_jar():
    cands = [f for f in os.listdir(BUILT) if f.startswith('pantrywork-') and
             f.endswith('-forge-mc1201.jar')]
    if not cands:
        raise SystemExit('No pantrywork-*-forge-mc1201.jar in build/libs - run: gradlew forgeJar1201')
    cands.sort(key=lambda f: os.path.getmtime(os.path.join(BUILT, f)))
    return os.path.join(BUILT, cands[-1])


def load(defs, path_or_zip):
    zf = path_or_zip if isinstance(path_or_zip, zipfile.ZipFile) else zipfile.ZipFile(path_or_zip)
    for n in zf.namelist():
        # 1.20.1 is PLURAL tags/items/. A 1.21-shaped payload (singular tags/item/) is silently
        # dead on this line, which is exactly what the suites' positives are there to catch.
        if '/tags/items/' not in n or not n.endswith('.json'):
            continue
        ns = n.split('data/', 1)[1].split('/', 1)[0]
        tid = '%s:%s' % (ns, n.split('/tags/items/', 1)[1][:-5])
        try:
            d = json.loads(zf.read(n).decode('utf-8-sig'))
        except ValueError:
            continue
        if d.get('replace'):
            defs[tid] = []
        defs.setdefault(tid, []).extend(d.get('values', []))
    return defs


def resolver(defs):
    def resolve(tid, seen=None):
        if seen is None:
            seen = set()
        if tid in seen or tid not in defs:
            return set()
        seen.add(tid)
        out = set()
        for v in defs[tid]:
            i = v if isinstance(v, str) else v.get('id')
            if not i:
                continue
            out |= resolve(i[1:], seen) if i.startswith('#') else {i}
        return out
    return resolve


def slug(tid):
    return tid.replace(':', '__').replace('/', '_')


def write_pack(tags):
    # ADDITIVE on purpose: the two scenarios probe overlapping but different tag sets, and they
    # are generated by separate runs, so clearing here would leave whichever suite was generated
    # first without its predicates - every one of its probes would then answer nothing and read
    # as a few hundred failures. A predicate nobody asks for costs nothing. To reset the pack
    # from scratch, delete tools/testpack-1201/data and regenerate BOTH scenarios.
    os.makedirs(PRED, exist_ok=True)
    for tid in sorted(tags):
        body = {'condition': 'minecraft:entity_properties', 'entity': 'this',
                'predicate': {'equipment': {'mainhand': {'tag': tid}}}}
        with io.open(os.path.join(PRED, slug(tid) + '.json'), 'w',
                     encoding='utf-8', newline='\n') as fh:
            fh.write(json.dumps(body, indent=2) + '\n')
    with io.open(os.path.join(PACK, 'pack.mcmeta'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(json.dumps({'pack': {
            'description': 'Pantrywork 1.20.1 tag probes (test instrument, never shipped)',
            'pack_format': 15}}, indent=2) + '\n')


HEADER_COMMON = [
    '#',
    '# Mechanism: 1.20.1 has neither `execute if items` nor minecraft:crafter - both are 1.21 -',
    "# so membership is asserted through a predicate on an armor stand's mainhand",
    '# (tools/testpack-1201, copied into world/datapacks by tools/boot-forge1201.ps1 BEFORE the',
    '# world loads; skip that copy and every probe answers nothing). Inside an `execute as` fork',
    '# 1.20.1 swallows "Test failed", so EVERY assertion here is phrased to answer "Test passed":',
    '# positives with `if`, negatives with `unless`. A broken assertion answers nothing at all,',
    '# and tools/CountSuite.ps1 counts a missing answer as failed. Do NOT add `# expect:` lines.',
    '#',
    '# GENERATED by tools/GenForge1201Suites.py - re-derive, do not hand-edit.',
]
SETUP = [
    'forceload add 0 0',
    'kill @e[type=minecraft:armor_stand]',
    'summon minecraft:armor_stand 8 -60 8 {Tags:["pwprobe"],Invulnerable:1b,NoGravity:1b,Marker:1b}',
]
TEARDOWN = ['kill @e[tag=pwprobe]', 'forceload remove 0 0']


def emit(lines, item, tid, positive):
    lines.append('item replace entity @e[tag=pwprobe,limit=1] weapon.mainhand with %s' % item)
    lines.append('execute as @e[tag=pwprobe,limit=1] %s predicate pwtest:%s'
                 % ('if' if positive else 'unless', slug(tid)))


def one_per_ns(items):
    by = collections.OrderedDict()
    for i in sorted(items, key=lambda x: (x.split(':')[0] != 'minecraft', x)):
        by.setdefault(i.split(':')[0], i)
    return list(by.values())


def write_suite(name, lines, npos, nneg, tags):
    out = os.path.join(ROOT, 'tools', name)
    with io.open(out, 'w', encoding='utf-8', newline='\r\n') as fh:
        fh.write('\n'.join(lines) + '\n')
    print('suite: %d assertions (%d positive / %d negative) over %d tags -> tools/%s'
          % (npos + nneg, npos, nneg, len(tags), name))


# ------------------------------------------------------------------ solo
def gen_solo():
    defs = load(load({}, MCJAR), payload_jar())
    resolve = resolver(defs)

    def vanilla(tid):
        return sorted(i for i in resolve(tid) if i.startswith('minecraft:'))

    tags = ['pantrywork:food_component'] + \
           ['pantrywork:food_component/%s' % r for r in ROLES] + SOLO_CANON
    write_pack(tags)

    L = ['# Pantrywork on FORGE 1.20.1, SOLO boot: powershell -File tools\\boot-forge1201.ps1 -Scenario solo',
         '# (mods/ = the forge jar alone).'] + HEADER_COMMON + [
        '#',
        "# Expectations are DERIVED from the shipped payload's tag closure with no other mod",
        '# present. Only the section-5 pins are declared by hand, each with its reason.']
    L += SETUP
    npos = nneg = 0

    L += ['', '# --- 1. ROLE TAGS: the headline promise, an item resolving by role ---']
    for r in ROLES:
        tid = 'pantrywork:food_component/%s' % r
        items = vanilla(tid)
        if not items:
            L.append('# %s holds no vanilla item solo - all of its content arrives via other mods.'
                     % tid)
            continue
        for it in items:
            emit(L, it, tid, True)
            npos += 1

    L += ['', '# --- 2. THE UMBRELLA: every role rolls up into one tag ---']
    for it in vanilla('pantrywork:food_component'):
        emit(L, it, 'pantrywork:food_component', True)
        npos += 1

    L += ['', '# --- 3. CANONICAL forge: TAGS - proves the `forge:` namespace AND the plural',
          '#     data/<ns>/tags/items/ path resolve on this line. A 1.21-shaped payload (`c:` +',
          '#     singular tags/item/) is silently dead here, so these carry the port. ---']
    for tid in SOLO_CANON:
        for it in vanilla(tid):
            emit(L, it, tid, True)
            npos += 1

    L += ['', '# --- 4. PURITY: a non-food must reach no food tag, by any route ---']
    for tid in ['pantrywork:food_component'] + ['pantrywork:food_component/%s' % r for r in ROLES]:
        emit(L, 'minecraft:stone', tid, False)
        nneg += 1
    emit(L, 'minecraft:stone', 'forge:foods/fruit', False)
    nneg += 1

    L += ['', '# --- 5. SOLO SEMANTICS, pinned deliberately (see SOLO_PINNED in the generator) ---']
    for item, why in SOLO_PINNED:
        L.append('# %s: %s' % (item.split(':')[1], why))
        emit(L, item, 'pantrywork:food_component', False)
        nneg += 1

    L += [''] + TEARDOWN
    write_suite('tagtest-forge1201.txt', L, npos, nneg, tags)


# ------------------------------------------------------------------ compat
def gen_compat(phase, existence_out):
    defs = load({}, MCJAR)
    jars = sorted(f for f in os.listdir(MODS) if f.endswith('.jar'))
    for f in jars:
        load(defs, os.path.join(MODS, f))
    resolve = resolver(defs)

    ours = set(load({}, payload_jar()).keys())
    # EVERY tag the payload writes except the role layer (handled by the role/umbrella
    # sections above). A `forge:`-only filter stood here first, and it quietly excluded the
    # three mod-namespaced tags the payload also writes - kaleidoscope_cookery:oil,
    # rusticdelight:cooking_oil and origins:meat. The first of those is the single
    # highest-value bridge in the whole payload: Kaleidoscope's wok checks it before it will
    # cook, so all 225 of its wok recipes sit behind it. Leaving it unasserted meant the one
    # claim the 0.8.0 release was built on had no coverage on this line.
    canon = sorted(t for t in ours if not t.startswith('pantrywork:'))

    probes = []   # (section, item, tag, positive, note)

    def add(sec, item, tid, positive=True, note=None):
        probes.append((sec, item, tid, positive, note))

    for r in ROLES:
        tid = 'pantrywork:food_component/%s' % r
        for it in one_per_ns(resolve(tid)):
            add('role', it, tid)
    for it in one_per_ns(resolve('pantrywork:food_component')):
        add('umbrella', it, 'pantrywork:food_component')
    for tid in canon:
        items = resolve(tid)
        if len({i.split(':')[0] for i in items} - {'minecraft'}) < 2:
            continue
        for it in one_per_ns(items):
            add('canon', it, tid)
    for tid, fixed, note in NAMED:
        for it in (fixed if fixed else one_per_ns(resolve(tid))):
            add('named', it, tid, True, note)
    for it in NONFOOD:
        add('purity', it, 'pantrywork:food_component', False)

    absent = {(t, i) for t, i in KNOWN_ABSENT}
    probes = [p for p in probes if (p[2], p[1]) not in absent]
    for tid, it in KNOWN_ABSENT:
        add('gate', it, tid, False, KNOWN_ABSENT_NOTE)

    seen, uniq = set(), []
    for p in probes:
        if (p[1], p[2], p[3]) in seen:
            continue
        seen.add((p[1], p[2], p[3]))
        uniq.append(p)
    probes = uniq
    items_needed = sorted({p[1] for p in probes})

    if phase == '--candidates':
        out = os.path.join(ROOT, 'tools', 'work', 'forge1201-existence.txt')
        with io.open(out, 'w', encoding='utf-8', newline='\r\n') as fh:
            fh.write('\n'.join(SETUP) + '\n')
            for it in items_needed:
                fh.write('item replace entity @e[tag=pwprobe,limit=1] weapon.mainhand with %s\n'
                         % it)
        print('phase 1: %d candidate items, %d probes, %d jars in mods/ -> %s'
              % (len(items_needed), len(probes), len(jars), out))
        print('  run it:  powershell -File tools\\rcon.ps1 -File %s > out.txt' % out)
        return

    bad, cur = set(), None
    for line in io.open(existence_out, encoding='utf-8', errors='replace').read().splitlines():
        if line.startswith('>> item replace'):
            cur = line.rsplit(' with ', 1)[1].strip()
        elif cur and line.strip() and not line.startswith('>> '):
            if 'Replaced a slot' not in line:
                bad.add(cur)
            cur = None
    print('phase 2: server rejected %d of %d candidate items (mods not in this boot)'
          % (len(bad), len(items_needed)))
    for b in sorted(bad):
        print('   absent:', b)

    probes = [p for p in probes if p[1] not in bad]
    tags = sorted({p[2] for p in probes})
    write_pack(tags)
    # The server reads world/datapacks/pwtest, which boot-forge1201.ps1 copies ONCE at boot.
    # Phase 2 necessarily runs against a LIVE server (that is where the existence pass came
    # from), so the pack it just wrote is newer than the world's copy and the suite would come
    # back with a few hundred empty answers. Say so rather than leaving it to be rediscovered.
    print('')
    print('  NOTE: the running server still has the OLD probe pack. Re-boot before trusting the')
    print('        suite:  powershell -File tools\\boot-forge1201.ps1 -Scenario compat')

    sections = [
        ('role', '1. ROLE CONVERGENCE - the headline promise. Each line is a DIFFERENT mod\'s\n'
                 "#     ingredient landing in the same role tag, which is what lets one mod's\n"
                 "#     recipe accept another mod's food."),
        ('umbrella', '2. THE UMBRELLA - every role rolls up into one tag.'),
        ('canon', '3. CANONICAL forge: TAGS WE DEFINE OR INJECT INTO - one item per contributing\n'
                  "#     namespace, so a tag that silently loses a mod's contribution shows up here."),
        ('named', '4. NAMED CASES FROM THE DESIGN RECORD - asserted by name, never sampled.'),
        ('purity', '5. PURITY - a non-food must reach no food tag by any route.'),
        ('gate', '6. GATE DROPS, ASSERTED AS ABSENT.'),
    ]

    L = ['# Pantrywork on FORGE 1.20.1, COMPAT boot: powershell -File tools\\boot-forge1201.ps1 -Scenario compat',
         '# (mods/ = the forge jar + the 18 roster jars that load on this line; the script holds',
         '# the list and tools/work/jars-1201/SOURCES.md says why the other mods are excluded).'
         ] + HEADER_COMMON + [
        '#',
        '# Expectations are DERIVED from the merged tag graph of the jars in mods/, then filtered',
        '# by a one-off runtime existence pass. Declared by hand: the section-6 gate drops and the',
        '# section-4 named cases.',
        '#',
        '# UPSTREAM NOISE on this boot - 16 TagLoader missing-reference errors (pamhc2foodextended',
        '# referencing pamhc2crops/pamhc2trees items; those two mods have NO Forge 1.20.1 build,',
        '# their only 1.20.x builds declaring javafml loaderVersion [49,) where 1.20.1 supplies 47),',
        "# 6 recipe parse errors from the two Pam's jars, and 4 empty-file + 5 loot-table errors from",
        '# culturaldelights 0.16.7, which ships zero-byte vanilla recipe overrides that 1.20.1 cannot',
        '# read as removals. All 31 are byte-identical on a boot with Pantrywork REMOVED',
        '# (-Scenario control), so none of them is ours.']
    L += SETUP

    npos = nneg = 0
    notes = set()
    for key, title in sections:
        sel = [p for p in probes if p[0] == key]
        if not sel:
            continue
        L += ['', '# --- %s ---' % title]
        last = None
        for _, item, tid, positive, note in sel:
            if note and note not in notes:
                L.append('# %s' % note)
                notes.add(note)
            if tid != last:
                L.append('#   -> %s' % tid)
                last = tid
            emit(L, item, tid, positive)
            if positive:
                npos += 1
            else:
                nneg += 1

    L += [''] + TEARDOWN
    write_suite('tagtest-forge1201-compat.txt', L, npos, nneg, tags)


if __name__ == '__main__':
    args = sys.argv[1:]
    if not args or args[0] not in ('solo', 'compat'):
        raise SystemExit(__doc__ or 'usage: GenForge1201Suites.py solo|compat [--candidates|'
                                    '--final <existence.out>]')
    if args[0] == 'solo':
        gen_solo()
    else:
        if len(args) < 2 or args[1] not in ('--candidates', '--final'):
            raise SystemExit('compat needs --candidates or --final <existence.out>')
        gen_compat(args[1], args[2] if len(args) > 2 else None)
