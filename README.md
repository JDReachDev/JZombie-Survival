# JZombie Survival

**Gamemode Coop Survival per Garry's Mod (GMod)**

---

## 🎮 Panoramica

JZombie Survival è una gamemode **coop multiplayer** in cui i giocatori devono sopravvivere a ondate successive di zombie che spawnano dai bordi della mappa. Il ciclo di gioco si ripete fino a quando tutti i giocatori non muoiono.

**Fasi del ciclo:**
1. **WAITING** (Lobby) → **BUYTIME** (si compra) → **ONDATA** (si spara) → **BUYTIME** → **ONDATA** → ... → **GAME OVER** → Ripete

---

## 📂 Struttura del Repository

```
JZombie-Survival/
├── data/
│   └── jzsconfig.txt              ← Config dati "style JDeathmatch"
├── gamemodes/
│   └── jzombiesurvival/
│       ├── jzombiesurvival.txt
│       ├── logo.png
│       ├── icon24.png
│       ├── gamemode/
│       │   ├── cl_init.lua
│       │   ├── cl_shop.lua
│       │   ├── cl_hud.lua
│       │   ├── init.lua
│       │   ├── sh_config.lua
│       │   ├── sv_shop.lua
│       │   └── sv_wave.lua
│       ├── entities/
│       │   └── entities/
│       │       ├── base_barricade/
│       │       ├── zs_barricade_plank/
│       │       ├── zs_barricade_sandbag/
│       │       ├── zs_barricade_metal/
│       │       ├── zs_barricade_wire/
│       │       ├── zs_barricade_crate/
│       │       └── zs_barricade_turret/
│       ├── materials/
│       │   └── zombiesurvival/icons/ ; PNG + VMT generati
│       └── tools/
│           ├── make_icons.ps1
│           └── make_gamemode_icons.ps1
├── JZOMBIE-SURVIVAL.md            ← Documentazione dettagliata
└── tools/                         ; script generazione icone
```

---

## ⚙️ Configurazione

Il cuore della configurazione è il file **`data/jzsconfig.txt`** (stile `JDeathmatch`). L'amministratore del server può modificarlo con il Blocco note **senza mai toccare i file `.lua`**.

### Formato `data/jzsconfig.txt`

```txt
; ==========================================
; JZombie Survival
; ==========================================

; --- Armi shop ---
weapon_pistol,Desert Eagle,150,Pistol,34,1,1,"Affidabile, economia, buoni danni"
weapon_smg1,MP5,400,SMG1,75,1,1,"Alta cadenza, ottimo controllo"
; (vedi file completo per tutte le armi)

; --- Barricate ---
zs_barricade_plank,Tavole di legno,80,6,1,"Barricata economica, si rompe in fretta.",300
zs_barricade_sandbag,Sacchi di sabbia,250,4,2,"Più resistenti, buoni per coperture.",800
; (vedi file completo per tutte le barricate)

; --- Zombie per ondata ---
1,8,npc_zombie,1.0,npc_zombie_torso,0.25
3,12,npc_zombie,0.75,npc_zombie_torso,0.25
; (vedi file completo per tutte le onde)

; --- CVAR di bilanciamento ---
zs_startmoney,500
zs_waveinterval,45
zs_hordesize,8
zs_wavescale,1.15
zs_maxzombies,64
zs_payoutbase,100
zs_payoutperkill,5
```

### Come modificare i valori

1. Apri `data/jzsconfig.txt` con qualsiasi editor di testo (Blocco note, VS Code, ecc.).
2. Cambia i numeri (prezzi, hp, zombie counts, cvari).
3. Riavvia il server (o usa `rcon reload` se configurato).

### CVAR disponibili (possono essere sovrascritti dal file di config)

| Cvar | Default | Descrizione |
|---|---|---|
| `zs_startmoney` | 500 | $ iniziali per player |
| `zs_waveinterval` | 45 | secondi di buytime tra le ondate |
| `zs_hordesize` | 8 | zombie all'ondata 1 |
| `zs_wavescale` | 1.15 | moltiplicatore crescita ondata |
| `zs_maxzombies` | 64 | cap zombie vivi in simultanea |
| `zs_payoutbase` | 100 | $ base a fine ondata |
| `zs_payoutperkill` | 5 | $ per ogni zombie ucciso |

---

## 🛠️ Installazione

1. Copia la cartella `gamemodes/jzombiesurvival` in:
   ```
   steamapps/common/GarrysMod/garrysmod/gamemodes/
   ```
2. Avvia una mappa e cambia game mode:
   - In console: `gamemode jzombiesurvival`
   - Oppure seleziona "JZombie Survival" dal menu gamemode
3. Il gamemode leggerà automaticamente `data/jzsconfig.txt` all'avvio.

---

## 📜 Licenza

Questa gamemode è distribuita con licenza aperta. Puoi modificarla e redistribuirla secondo i termini della licenza MIT (o indicare la tua preferenza).

---

## 👤 Autore

**JDReach** – [GitHub](https://github.com/JDReachDev/JZombie-Survival)

---

## 🙏 Ringraziamenti

- Ispirato allo stile di configurazione di **JDeathmatch** (file `.txt` dati separati dalla logica Lua)
- NPC e asset basati su contenuti di **Half-Life 2 / GMod**