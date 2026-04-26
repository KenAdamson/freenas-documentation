# Storage Expansion Plan

*Last updated: 2026-04-25 — maintenance window executed: slot swap, P4800X install, Marvell pull, Backups internal CMR replacement.*

## Current situation

- **Mir1**: **20.9 TB, 69% full** (14.6 TB used, 6.32 TB free), 1.25x dedup, ONLINE. All resilvers complete; no scrubs running.
- **Backups**: 1.81 TB, 71% full. Now **1× internal WD Red Plus 2 TB CMR (`da8`) + 1× USB Seagate Portable (`da15`)** — BUP Slim USB replaced 2026-04-25. BUP Slim (`da14`) physically still attached but detached from the pool; pending physical pull.
- **boot-pool**: 448 GB on `ada0` (Seagate ST500LM021 500 GB 2.5" spinner — same physical disk, renumbered from `ada6` after AHCI reshuffle), 0.7% used. **Migration to M10 Optane is drafted** — see `freenas-boot-migration-runbook.md` on `/mnt/media`.
- **SLOG**: Intel Optane P4800X 750 GB, 16 G partition (`nvd0p1`); healthy, never saturated.
- **L2ARC**: Intel Optane P4800X 750 GB, 683 G partition (`nvd0p2`); ~205 GB warm (~30 % of partition).
- **Backups SLOG**: M10 32 GB MEMPEK1J032GAH (`nvd1p1`) — interim assignment 2026-04-25 to give the ex-Mir1-SLOG a job. Still earmarked as the boot-migration target; needs to detach from Backups first.
- **Backups L2ARC**: Samsung 840 EVO 250 GB (`da6p1`) — interim assignment 2026-04-25, ex-Mir1-L2ARC.
- **HBA**: LSI SAS3008 in **slot 2, CPU-direct PCIe 3.0 x8 (~7.88 GB/s)** post-2026-04-25 swap. Confirmed at link width via `mprutil show adapter`.
- **Expander**: Adaptec AEC-82885T in **slot 3** (power only, demoted from slot 2 in the swap). 12 Mir1 drives + 1 Backups drive + 2 idle drives (840 EVO `da6`, BUP Slim `da14`) attached; 14 drives behind it total. Reliable since April install.
- **Marvell 88SE9215**: **REMOVED 2026-04-25**. No drives were attached. Reserved for the P520 Postgres build.
- **PSU**: Seasonic Prime GX-1300 — still clean, no rail issues.

## Recently completed

- ✅ **2026-04-25 maintenance window** — physical slot swap (LSI from chipset x4 in slot 3 to CPU x8 in slot 2; Adaptec demoted to slot 3); Intel Optane **P4800X 750 GB installed in slot 4**, gpart-partitioned and rolled into Mir1 as 16 G SLOG + 683 G L2ARC; old M10 SLOG and Samsung 840 EVO L2ARC removed (M10 idle, 840 EVO in chassis as `da6` pending physical pull). Marvell 88SE9215 card pulled. All remaining AHCI drives migrated onto the Adaptec (only `ada0` boot disk left on AHCI). Backups BUP Slim USB replaced with internal WD Red Plus 2 TB (4 h 8 m resilver, 0 errors). L2ARC tunables (`vfs.zfs.l2arc_write_max`, `write_boost`, `noprefetch`) set persistently via the TrueNAS tunables API.
- ✅ **mirror-5 full upgrade to 2× 8 TB IronWolves** (2026-04-20 / 2026-04-24) — ada4 WDS200T1R0A SSD → new Seagate ST8000VN004 (first half, 12 h 39 m resilver); da5 WDS200T1R0A SSD → new Seagate ST8000VN0022 (second half, 6 h 41 m resilver). Mir1 gained ~5.5 TB of free space; capacity pressure resolved.
- ✅ **mirror-3 full upgrade to all-SSD** (2026-04-21 / 2026-04-24) — USB WD My Passport → WDS200T1R0A SSD (13 h 41 m, the liberated ada4 drive); WD Red Plus 2 TB HDD → WDS200T1R0A SSD (7 h 54 m, the liberated da5). **No more USB in a production mirror; no more HDD in mirror-3.**
- ✅ **da9 SMR removal** (2026-04-23) — ejected from Backups pool, physically pulled. Was only there as an interim for a mirror-3 replacement that got superseded by the SSD cascade.
- ✅ **Seasonic Prime GX-1300 PSU** — replaced the previous PSU; single 12V rail. Resolved the earlier mirror-4 SA500 "failure" (which was a power/cable issue).
- ✅ **Adaptec AEC-82885T SAS expander** — installed 2026-04-05, replaces the failing HP SAS expander. Reliable since install.
- ✅ **Intel Optane 32 GB SLOG** — installed March 2026 with HR10 2280 PRO heatsink. Operational, never saturated.
- ✅ **mirror-1** — upgraded to 2× 8 TB (WD Red Plus + IronWolf) on 2026-03-01.

## Pending near-term

- ⏳ **Mir1 vdev count reduction: 6 → 5 via mirror-3 evacuation** — informed by the new 5-bay drive enclosures (the prior 6-mirror layout matched the previous 6-bay enclosures; new chassis fits 5 vdevs naturally). After the current scrub completes (started 2026-04-26 10:20):
  1. `zpool remove Mir1 mirror-3` → 1.78 TB of data evacuates onto remaining vdevs (mostly mirror-5, which has 5.38 TB free). Pool capacity drops from 20.9 TB to ~19.1 TB; alloc moves from 70 % to ~76 %.
  2. The two WDS200T1R0A 2 TB SSDs (`da11`, `da13`) are liberated → go to the **P520 Postgres build** (the WDS pair has lower resale value than the SA500 pairs, so this is the pragmatic match-up).
  3. Both SA500 pairs (mirror-0 + mirror-4) stay in Mir1 as the SSD performance vdevs. mirror-6 (1 TB HDD pair) stays for now — its eventual retirement is independent.
  - **Permanent cost**: ZFS retains an indirect-mapping table for the ~14M relocated 128 K records (~500 MB RAM) for the life of the pool. Acceptable; negligible read-time overhead.
  - **No undo** past evacuation completion. Cancellable via `zpool remove -s Mir1` while still in progress.
- ⏳ **8 TB IronWolf pair acquisition** — second pair on order ($225 ST8000VN0004 + $252 ST8000VN0022). When they arrive, they'll be added as a new mirror to grow the pool back, possibly enabling future evacuation of mirror-6.
- ⏳ **Boot-pool migration `ada0` → `nvd1` (M10 Optane)** — full procedure drafted at `/mnt/media/freenas-boot-migration-runbook.md`. Requires a brief reboot through TrueNAS install USB for a pool-rename swap (M10 is too small for `boot.attach`'s standard layout, so we replicate via `zfs send | zfs recv` and rename in rescue). **Pre-step**: `zpool remove Backups <m10-slog-gptid>` to free the M10 from its current Backups SLOG role.
- ⏳ **Physical pull of retired drives** — Seagate BUP Slim 2 TB (`da14`, ex-Backups) detached from pool, just needs unplug. (Samsung 840 EVO `da6` is no longer pending — it's now Backups L2ARC.) Add the 1 TB WD10JFCX 2.5" pair after the mirror-6 evacuation.
- ⏳ **New 5-bay 3.5" enclosure install** — already acquired, awaiting install. Enables splitting mirror-1 and mirror-5 across two enclosures for enclosure-fault tolerance.

## Next maintenance window

### Boot-pool migration to M10 Optane
The standard `boot.attach` path is blocked because TrueNAS demands a layout (EFI + 16 G swap + ZFS sized to match the source disk, ~466 G total) that won't fit on the M10's 27 G. The runbook works around this with `zfs send | zfs recv` into a fresh small pool on the M10, then a one-time pool-rename swap from rescue media. Source disk (`ada0`) stays untouched until the very end, so rollback is just "boot off ada0 again." See `/mnt/media/freenas-boot-migration-runbook.md` for the per-phase commands and rollback table.

## Opportunistic (any window)

- **RAM upgrade 32 → 64 GB** — 2× Kingston KSM24ED8/16ME (DDR4-2400 ECC UDIMM) to match the existing 2× 16 GB. ~$200 eBay watchlist. More ARC = less pressure on L2ARC and spinners.
- **Xeon E-2288G** — 8c/16t, 5.0 GHz boost, same socket. ~$150 eBay watchlist. Current i3-8100 becomes the spare. Nice-to-have, not a bottleneck.

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

**Order of mirrors to convert (revised 2026-04-26 — switching to evacuate-then-grow strategy):**
1. **mirror-3 evacuation** (post-scrub) — `zpool remove Mir1 mirror-3` liberates the WDS200T1R0A pair for the P520 Postgres build. Drops the pool from 6 vdevs to 5 (matches the new 5-bay enclosures). 1.78 TB redistributes onto remaining vdevs, mostly mirror-5.
2. **8 TB pair (`mirror-7`) addition** when the new IronWolves arrive — adds ~7.28 TB of capacity, restoring headroom. Pool ends ~26 TB usable.
3. **mirror-6 retirement (later)** — the 1 TB pair stays for now. Eventual eviction either via another `zpool remove` (after another 8 TB pair) or attrition.
4. **mirror-0 and mirror-4** stay as SSD performance vdevs in Mir1 indefinitely. Both SA500 pairs are matched and near-new; no compelling reason to disturb them.

**Why the strategy switched:** the new 5-bay drive enclosures naturally fit 5 vdevs, not 6. The "swap one drive at a time" arbitrage produced no defragmentation and required two long resilvers per mirror. `zpool remove` evacuates a vdev and rewrites its blocks freshly onto remaining vdevs — drive-liberation outcome plus partial defrag as a side effect. Permanent cost: indirect-mapping table for relocated blocks (~500 MB RAM for ~14M records on the mirror-3 evacuation alone). Acceptable.

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

- ❌ Samsung 870 EVO 2 TB to replace USB Passport in mirror-3 — **not needed.** Superseded by the April 2026 WDS200T1R0A cascade: USB replaced by the SSD liberated from mirror-5's first-half upgrade.
- ❌ Seagate Barracuda da9 as mirror-3 interim — **not needed.** The SSD cascade made it obsolete; da9 was ejected from Backups on 2026-04-23 and physically pulled.
- ❌ "Replace mirror-1's dying Seagate batch" — **done.** The ST2000LM015 batch is all gone; mirror-1 is on 2× 8 TB NAS drives.
- ❌ HP SAS Expander replacement — **done** 2026-04-05. AEC-82885T installed.
- ❌ **mirror-5 to all-8 TB** — **done** 2026-04-24.
- ❌ **mirror-3 USB eviction** — **done** 2026-04-22.
- ❌ **HBA slot swap to CPU-direct x8** — **done** 2026-04-25.
- ❌ **P4800X 750 GB SLOG+L2ARC** — **done** 2026-04-25.
- ❌ **Marvell 88SE9215 pull** — **done** 2026-04-25.
- ❌ **Backups BUP Slim USB → internal CMR** — **done** 2026-04-25 (4 h 8 m resilver, 0 errors).
- ❌ "Re-attach liberated WD Red Plus 2 TB to Backups" — superseded; the WD Red Plus 2 TB went directly into Backups as an internal mirror replacement for the worn BUP Slim, not as a third member behind the USB pair. Same drive, more direct outcome.
- ❌ "Second Intel Optane 32 GB ordered from China for boot" — superseded by the maintenance-window plan: the *existing* M10 (ex-SLOG) is now the boot target instead. The China-incoming M10 is reassigned to the P520 Postgres build.

## Related

- [Physical Drive Layout](Physical-Drive-Layout.md) — current controller/drive map
- [SAS Expander Configuration](SAS-Expander-Configuration.md) — AEC-82885T + LSI HBA details
- [ZPools](ZPools.md) — pool state and vdev membership
- [Maintenance Procedures](Maintenance-Procedures.md)
