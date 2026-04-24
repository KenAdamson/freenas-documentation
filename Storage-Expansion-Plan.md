# Storage Expansion Plan

*Last updated: 2026-04-24 — mirror-5 and mirror-3 upgrades complete; capacity pressure resolved.*

## Current situation

- **Mir1**: **20.9 TB, 69% full** (14.6 TB used, 6.32 TB free), 1.25x dedup, ONLINE. All resilvers complete; no scrubs running.
- **Backups**: 1.81 TB on 2× USB spinners (SMR member da9 ejected 2026-04-23), 71% full. Awaiting re-attach of liberated WD Red Plus 2 TB to restore 3-way.
- **boot-pool**: 448 GB on ada6 500 GB 2.5" spinner, 0.7% used. Optane replacement still pending hardware arrival.
- **SLOG**: Intel Optane 32 GB M.2 (nvd0), healthy, never saturated.
- **L2ARC**: Samsung 840 EVO 250 GB (ada3), warm with metadata after recent resilver activity.
- **HBA**: LSI SAS3008 in slot 3, still link-limited to PCIe 3.0 x4. Planned swap with Adaptec remains a next-window task.
- **Expander**: Adaptec AEC-82885T in slot 2. Eight pool drives attached (da0–da6 + da11); reliable since April install.
- **PSU**: Seasonic Prime GX-1300 — still clean, no rail issues.

## Recently completed

- ✅ **mirror-5 full upgrade to 2× 8 TB IronWolves** (2026-04-20 / 2026-04-24) — ada4 WDS200T1R0A SSD → new Seagate ST8000VN004 (first half, 12 h 39 m resilver); da5 WDS200T1R0A SSD → new Seagate ST8000VN0022 (second half, 6 h 41 m resilver). Mir1 gained ~5.5 TB of free space; capacity pressure resolved.
- ✅ **mirror-3 full upgrade to all-SSD** (2026-04-21 / 2026-04-24) — USB WD My Passport → WDS200T1R0A SSD (13 h 41 m, the liberated ada4 drive); WD Red Plus 2 TB HDD → WDS200T1R0A SSD (7 h 54 m, the liberated da5). **No more USB in a production mirror; no more HDD in mirror-3.**
- ✅ **da9 SMR removal** (2026-04-23) — ejected from Backups pool, physically pulled. Was only there as an interim for a mirror-3 replacement that got superseded by the SSD cascade.
- ✅ **Seasonic Prime GX-1300 PSU** — replaced the previous PSU; single 12V rail. Resolved the earlier mirror-4 SA500 "failure" (which was a power/cable issue).
- ✅ **Adaptec AEC-82885T SAS expander** — installed 2026-04-05, replaces the failing HP SAS expander. Reliable since install.
- ✅ **Intel Optane 32 GB SLOG** — installed March 2026 with HR10 2280 PRO heatsink. Operational, never saturated.
- ✅ **mirror-1** — upgraded to 2× 8 TB (WD Red Plus + IronWolf) on 2026-03-01.

## Pending near-term

- ⏳ **Re-attach liberated WD Red Plus 2 TB to Backups** — the HDD pulled from mirror-3 on 2026-04-24 is available as a CMR internal third member for Backups. Restores 3-way redundancy.
- ⏳ **New 5-bay 3.5" enclosure install** — already acquired, awaiting install. Enables splitting mirror-1 and mirror-5 across two enclosures for enclosure-fault tolerance.
- ⏳ **HBA slot swap (LSI to PCIEX16_2 CPU-direct x8)** — covered in "Next maintenance window" below.
- ⏳ **Marvell 88SE9215 pull** — card has no drives attached, scheduled for removal and migration to the P520 Postgres server build.
- ⏳ **Second Optane 32 GB / P4800X boot** — pending hardware arrival.

## Next maintenance window

### 1. HBA slot swap (no parts cost)
Move the **LSI SAS3008** from slot 3 (Gen3 x4) to slot 2 (Gen3 x8). Demote the **Adaptec expander** to slot 3 (it only draws power, doesn't care about lane width). Doubles HBA upstream bandwidth from ~3.94 GB/s to ~7.88 GB/s.

**Verify before the window:** the two 0.5 m SFF-8643 uplink cables need to reach from the new HBA position to the Adaptec — eyeball the bend radius.

### 2. Optane P4800X 750 GB L2ARC — *pending purchase, ~$284 eBay watchlist*
Install in slot 4 (Gen3 x4) as the new L2ARC. `zpool remove Mir1 cache <840-evo>` then `zpool add Mir1 cache <p4800x>`. Retires the Samsung 840 EVO 250 GB on ada3, which frees an AHCI port *and* gives the pool ~2.5 GB/s of warm-cache read bandwidth with sub-microsecond latency.

## Later maintenance window

### Second Optane 32 GB + boot pool migration
Install a second Intel Optane 32 GB in M.2_2 **(ordered, shipping from China, ~2 weeks+)**, verify it enumerates as `nvme1`, then attach it as a mirror to the boot pool. After resilver completes (~30 seconds for 3 GB of data), detach ada6 and retire it. Frees an onboard AHCI SATA port. Before install, confirm M.2_2 is set to PCIe/NVMe mode in BIOS and check for any lane-sharing conflict with onboard SATA ports.

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

**Order of mirrors to convert (revised 2026-04-24 — mirror-5 and mirror-3 done):**
1. **mirror-6** — smallest (928 G), both 1 TB HDDs; big capacity gain, HDD-to-HDD so slow resilvers
2. **mirror-0** — matched near-new SA500 pair, liberates 2 SSDs (one goes to P520 Postgres build, one resale)
3. **mirror-4** — matched SA500 pair, same story
4. **mirror-3** and **mirror-5** — **already converted in April 2026** (mirror-5 → 8 TB HDD pair; mirror-3 → 2 TB SSD pair). No further work needed on these.

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

## Related

- [Physical Drive Layout](Physical-Drive-Layout.md) — current controller/drive map
- [SAS Expander Configuration](SAS-Expander-Configuration.md) — AEC-82885T + LSI HBA details
- [ZPools](ZPools.md) — pool state and vdev membership
- [Maintenance Procedures](Maintenance-Procedures.md)
