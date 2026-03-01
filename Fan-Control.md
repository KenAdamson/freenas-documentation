# Fan Control

## The Problem

The ASUS WS C246 PRO motherboard manages chassis fans entirely through its own BIOS firmware. The temperature probes it reads are:

- **LM78A** on the motherboard (VRM/ambient)
- **Power unit** sensor

Both of these track board-level temperatures (typically 28-32°C), which have nothing to do with drive temperatures. The IronWolf 8TB (ada5) has been observed hitting 49-51°C while the BIOS sensors read under 30°C, meaning the chassis fans idle at minimum RPM while drives cook.

### What Doesn't Work

| Approach | Why Not |
|----------|---------|
| IPMI/ipmitool | No BMC chip on this board — `ipmi.ko` loads but no `/dev/ipmi0` device |
| ACPI thermal zones | Read-only (`_ACx` thresholds set by BIOS, not writable from OS) |
| Super I/O (Winbond) | No PWM controls exposed to FreeBSD |
| Software fan control (fancontrol, etc.) | No kernel interface to write fan speeds |

The only BIOS-level option is selecting a fan profile (Silent/Standard/Turbo/Full Speed) or setting a manual fan curve in UEFI setup — but these curves still reference the LM78A sensor, not drive temps.

## Solution: FanPico

[FanPico](https://github.com/tjko/fanpico) is an open-source programmable PWM fan controller built on the Raspberry Pi Pico (RP2040). It plugs into the system via USB and can control fans independently of the motherboard BIOS.

### Specifications (FANPICO-0804D)

| Feature | Spec |
|---------|------|
| Fan channels | 8 x 4-pin PWM |
| Motherboard fan inputs | 4 (can mirror/override mobo signals) |
| External temp probes | 2 x NTC thermistor (10k or 100k) |
| 1-Wire temp sensors | Up to 8 (e.g., DS18B20) |
| I2C temp sensors | Up to 8 |
| Onboard sensor | 1 (ambient) |
| Display | 128x64 OLED |
| Interfaces | USB serial, HTTP/HTTPS, MQTT (TLS), SNMP, Telnet, SSH |
| WiFi | Yes (with Pico W) |
| OS dependency | None — config stored on-device, runs standalone |

### Why This Fits

- **USB serial** — no driver needed, shows up as a serial device on FreeBSD
- **MQTT client** — can subscribe to temperature topics published by a script that reads SMART data
- **Standalone operation** — once configured, runs independently even if the NAS reboots or the OS can't talk to it
- **8 fan channels** — more than enough for the Thermaltake case
- **Programmable fan curves** — per-channel, with configurable temp sources

### Integration Options

#### Option A: Direct Sensors (No Software Dependency)

Attach 1-Wire (DS18B20) or NTC thermistor probes directly to drive cages or drive surfaces. FanPico reads them natively and applies fan curves without any OS involvement.

**Pros:** Zero software dependency, works even if NAS is unresponsive
**Cons:** Measures cage/surface temp, not actual drive temp from SMART

#### Option B: MQTT Bridge (SMART-Aware)

Run a lightweight script on TrueNAS that publishes drive temperatures to MQTT:

```sh
#!/bin/sh
# Publish SMART temps to MQTT for FanPico consumption
# Run via cron every 60 seconds

MQTT_HOST="localhost"  # or FanPico IP if using WiFi
MQTT_TOPIC="fanpico/temps"

for dev in ada4 ada5 ada6 ada7 ada9 ada13; do
    temp=$(smartctl -A /dev/$dev | awk '/Temperature_Celsius/{print $10}')
    if [ -n "$temp" ]; then
        mosquitto_pub -h "$MQTT_HOST" -t "${MQTT_TOPIC}/${dev}" -m "$temp"
    fi
done
```

FanPico subscribes to these topics and uses the hottest drive temp (or per-zone temps) to drive fan curves.

**Pros:** Actual SMART temperatures, most accurate
**Cons:** Requires MQTT broker and cron job; if script stops, FanPico loses temp updates (but can fall back to onboard/probe sensors)

#### Option C: Hybrid

Use physical probes on the drive cages as the baseline/fallback, with MQTT SMART temps as the primary source when available. FanPico can be configured to use the maximum of multiple temp sources.

### Where to Buy

- [FanPico-0804D (8-fan, OLED, DIY kit) on eBay](https://www.ebay.com/itm/285011546392)
- [FanPico-0401D (4-fan, OLED, DIY kit) on eBay](https://www.ebay.com/itm/286029640883)
- [FanPico GitHub — firmware and documentation](https://github.com/tjko/fanpico)
- [FanPico Wiki](https://github.com/tjko/fanpico/wiki)

### Current Workaround

A small desk fan pointed into the open side of the case. Dropped the IronWolf (ada5) from 49°C to 43°C. SMART alert thresholds were also raised to avoid false alarms:

- Critical: 60°C (was 50°C)
- Informational: 55°C (was 40°C)
