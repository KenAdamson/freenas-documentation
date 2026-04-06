# Storage Expansion Plan

*Last updated: 2026-04-06 — major refresh after PSU swap, Adaptec install, and SA500 vindication.*

## Current situation

- **Mir1**: 15.4 TB, 90% full, 1.25x dedup, ONLINE (mirror-3 resilver in progress)
- **Backups**: 1.81 TB on 2× USB spinners, 79% full
- **boot-pool**: 448 GB on a 500 GB laptop spinner (ada6), 1% used — replacement Optane already installed but not yet migrated
- **SLOG**: Intel Optane 32 GB M.2, healthy, never saturated
- **L2ARC**: Samsung 840 EVO 250 GB, barely used (1.21 GB)
- **HBA**: LSI SAS3008 in slot 3, currently link-limited to PCIe 3.0 x4
- **Expander**: Adaptec AEC-82885T in slot 2 with dual SFF-8643 wide-port uplink at 8 × 12 Gbps
- **PSU**: Seasonic Prime GX-1300 — resolved all prior power-rail gremlins

## Recently completed

- ✅ **Seasonic Prime GX-1300 PSU** — replaced the previous PSU; single 12V rail with proper SATA distribution. Resolved the mirror-4 SA500 "failure" (which turned out to be a power/cable issue, not a dead drive).
- ✅ **Adaptec AEC-82885T SAS expander** — installed in slot 2, dual SFF-8643 uplinks to the LSI HBA. Replaces the long-failing HP SAS expander. Half the pool drives are now behind the expander.
- ✅ **Intel Optane 32 GB SLOG** — installed March 2026 with HR10 2280 PRO heatsink. Operational, never saturated, thermally stable.
- ✅ **mirror-1** — upgraded to 2× 8 TB (WD Red Plus + IronWolf). Large free-space sink absorbing most new writes.
- ✅ **mirror-3 interim fix** — USB WD My Passport being replaced by a 2 TB Seagate Barracuda (da9). Resilver in progress.
- ✅ **Second Optane 32 GB M.2** — physically installed in M.2_2 with an active heatsink, reserved for boot pool migration. **Still pending OS-level migration.**

## Next maintenance window (single downtime pass)

Everything below shares a "cards out, screws out" access window, so batch them all:

### 1. HBA slot swap (no parts cost)
Move the **LSI SAS3008** from slot 3 (Gen3 x4) to slot 2 (Gen3 x8). Demote the **Adaptec expander** to slot 3 (it only draws power, doesn't care about lane width). Doubles HBA upstream bandwidth from ~3.94 GB/s to ~7.88 GB/s.

**Verify before the window:** the two 0.5 m SFF-8643 uplink cables need to reach from the new HBA position to the Adaptec — eyeball the bend radius.

### 2. Boot pool migration
Create a new boot pool on the already-installed Optane 32 GB in M.2_2, copy the current boot environment, switch the active BE, and retire ada6. Frees an onboard AHCI SATA port.

### 3. Optane P4800X 750 GB L2ARC — *pending purchase, ~$284 eBay watchlist*
Install in slot 4 (Gen3 x4) as the new L2ARC. Retires the Samsung 840 EVO 250 GB on ada3, which frees another AHCI port *and* gives the pool ~2.5 GB/s of warm-cache read bandwidth with sub-microsecond latency.

### 4. RAM upgrade 32 → 64 GB — *pending purchase, ~$200 eBay watchlist*
2× Kingston KSM24ED8/16ME (DDR4-2400 ECC UDIMM) to match the existing 2× 16 GB, filling 4 of 4 slots. More RAM = more ARC = less pressure on L2ARC and spinners.

### 5. Xeon E-2288G (optional, ~$150) — *nice-to-have, not priority*

## SSD → 8 TB spinner arbitrage (self-funding, opportunistic)

The economics flipped: SA500 2TB SSDs resell for ~$100-150 each, and 8 TB IronWolf/WD Red Plus spinners are $150-180 each. A single SSD pays for a pair of 8 TB spinners, **quadrupling** per-mirror capacity on roughly a zero-net trade.

**Workload fit:**
- Media (Plex) is sequential — spinners are fine at 250 MB/s
- Audio projects fit entirely in ARC after first read — SSDs aren't buying anything
- Reaper writebacks are small, rare, and hit the Optane SLOG first
- Renders peak at ~5 Mbps for audio — trivial
- No workload on Mir1 actually needs SSD random IOPS once the working set is cached

**Sequencing:**
1. PSU upgrade ✅ *done* (prerequisite — don't add spinners to a PSU you don't trust)
2. Sell one SA500, buy two 8 TB IronWolfs
3. Add first 8 TB to a target vdev, resilver, detach one SA500
4. Add second 8 TB, resilver, detach second SA500
5. Repeat per mirror, one at a time — pool stays online and redundant the whole time

**Order of mirrors to convert:**
1. **mirror-6** first — it's the smallest (928 G) and biggest capacity bottleneck
2. **mirror-0** next — matched SA500 pair, easy to trade
3. **mirror-4** then **mirror-5** — same story
4. **mirror-3 cleanup** — retire the interim Barracuda in favor of 8 TB drives once the arbitrage reaches that far

**Result:** fully spinner-based pool, ~40 TB+ usable, all on the Adaptec expander, all matched NAS-rated drives. Fewer small drives = fewer SATA ports used = more expansion headroom.

**Risks to manage:**
- Power: two more spinners per mirror adds load. The Seasonic GX-1300 has the headroom, but monitor temps on the 12V rail.
- Heat: 7200 RPM spinners run hotter than SSDs. The case airflow redesign should handle it; revisit fan speeds if temps climb.
- Burn-in: infant mortality is real on spinners. Run long SMART + badblocks on every new drive before trusting it in a vdev.

## Long-term plans

- **Replace Backups pool** with internal spinners on the Adaptec, drop the USB enclosures entirely.
- **Second Icy Dock 3.5" 5-bay cage** to host the expanded spinner count once arbitrage fills the first cage.
- **HBA/controller heat management** — LSI SAS3008 runs ~76 °C under load with its added fan. Fine for now, revisit if the card's fan ever fails.
- **Consider draid2** only if we ever do a full wipe-and-rebuild of the Backups pool with 11+ drives at once — distributed spares and fast sequential resilvers would be a real win on a cold archive pool. Not worth restructuring Mir1 for; mirrors are the right shape for that workload.

## Superseded plans (archived for context)

- ❌ Samsung 870 EVO 2 TB to replace USB Passport in mirror-3 — **not needed.** The Barracuda covers the interim, and the eventual fix is an 8 TB spinner via the arbitrage plan.
- ❌ "Replace mirror-1's dying Seagate batch" — **done.** The ST2000LM015 batch is all gone; mirror-1 is on 2× 8 TB NAS drives.
- ❌ HP SAS Expander replacement — **done.** AEC-82885T installed.

## Related

- [Physical Drive Layout](Physical-Drive-Layout.md) — current controller/drive map
- [SAS Expander Configuration](SAS-Expander-Configuration.md) — AEC-82885T + LSI HBA details
- [ZPools](ZPools.md) — pool state and vdev membership
- [Maintenance Procedures](Maintenance-Procedures.md)
