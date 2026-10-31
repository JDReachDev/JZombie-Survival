# JZombie Survival — Documentazione della gamemode

> **Versione:** 1.0
> **Autore:** JDReach
> **Base:** Garry's Mod (compatibile con `base = "sandbox"`)
> **Questo file è la fonte di verità della modalità.** Ogni modifica alla gamemode va riflessa qui.

---

## 1. Panoramica

JZombie Survival è una gamemode **coop multiplayer** in cui i giocatori sopravvivono a ondate
successive di zombie che spawnano dai bordi della mappa e convergono verso i vivi.

Il ciclo di gioco:

```
LOBBY → BUYTIME (si compra) → ONDATA (si spara) → BUYTIME → ONDATA → ... → GAME OVER → LOBBY
```

- **BUYTIME** — finestra di ~45s (configurabile) tra un'ondata e l'altra. Tutti sono invulnerabili,
  i morti respawnano, si apre l'armeria.
- **ONDATA** — spawn graduale di zombie fino a azzerare la coda. L'ondata finisce quando tutti
  gli zombie sono morti e la coda di spawn è vuota.
- **GAME OVER** — quando **tutti** i player sono morti durante un'ondata. Reset dopo 10s.

---

## 2. Struttura dei file

```
gamemodes/jzombiesurvival/
├── jzombiesurvival.txt          # manifesto gamemode (title, base, maps)
├── logo.png                     # 288x128 banner menu selezione gamemode
├── icon24.png                   # 24x24 iconcina lista gamemode
├── materials/
│   └── zombiesurvival/icons/    # icone shop procedurali (PNG+VMT)
└── gamemode/
    ├── shared.lua               # tabelle ZS, stati, chiavi NW, cvar, helper (server+client)
    ├── sh_config.lua            # ⚙️ CONFIG ARMI/MUNIZIONI/BARRICATE/ONDATE
    ├── init.lua                 # entry SERVER: sync, economia, spawn system, tracking kill, place barricade
    ├── sv_wave.lua              # wave manager (macchina a stati), respawn, comandi admin
    ├── sv_shop.lua              # logica acquisti autorevole (armi, ammo, barricate)
    ├── cl_init.lua              # entry CLIENT: net receive, hotkey shop (tasto 4)
    ├── cl_hud.lua               # HUD: ondata, countdown, zombie rimasti, saldo, kill
    ├── cl_shop.lua              # finestra armeria con icone procedurali + ghost placement barricate
    └── cl_notifications.lua     # toast/notifiche centrate in alto
entities/
└── entities/
    ├── base_barricade/          # base SENT per barricate (HP, danni, pickup, UI)
    ├── zs_barricade_plank/      # tavole di legno
    ├── zs_barricade_sandbag/    # sacchi di sabbia
    ├── zs_barricade_metal/      # lamiere metalliche
    ├── zs_barricade_wire/       # filo spinato (danni + rallenta)
    ├── zs_barricade_crate/      # cassa rinforzata
    └── zs_barricade_turret/     # torretta automatica
tools/
└── make_icons.ps1               # genera icone shop (PNG+VMT)
└── make_gamemode_icons.ps1      # genera logo.png + icon24.png
```

**Per installare:** copia la cartella `gamemodes/jzombiesurvival` in
`steamapps/common/GarrysMod/garrysmod/gamemodes/`, poi avvia una mappa con
`sandbox` → cambia game mode → `JZombie Survival`, oppure `gamemode jzombiesurvival` in console.

> Richiede HL2 content mounted (per gli NPC zombie e le SWEP stock).

---

## 3. Flusso di una partita

1. Un player entra in mappa → stato `WAITING`.
2. Dopo 5s dal primo player: calcolo spawn points → `BUYTIME` (45s). Shop si apre in automatico
   su tutti i client. Soldi iniziali: **$500** (cvar `zs_startmoney`).
3. Fine buytime → **Ondata 1** → spawn di `hordesize=8` zombie con coda di 0.35s tra uno e l'altro.
4. Zombie uccisi → **+$5/kill** (`zs_payoutperkill`) subito, e **+$100 + 25×ondata** a fine ondata
   (`zs_payoutbase`), più bonus da `ZS.WaveRewards`.
5. Riparte il buytime. Gli zombie crescono: `8 × 1.15^n` (`zs_wavescale`), cap **64 vivi**
   contemporaneamente (`zs_maxzombies`); la coda di spawn tiene e riprova quando si libera un posto.
6. Tutti morti → game over, reset round (strip weapons + respawn + soldi base).

### Composizione zombie per ondata
Definita in `sh_config.lua` → `ZS.WaveComposition` (pesi % default):

| Ondata | Composizione |
|---|---|
| 1–2 | 100% `npc_zombie` |
| 3–5 | 75% zombie + 25% torso |
| 6–9 | 55% zombie + 25% torso + 20% poison |
| 10–14 | 40/30/20/10 con `npc_headcrab_fast` |
| 15+ | 30/30/25/15 |

### **Ondate personalizzate (`ZS.Waves`)** — **NUOVO**
Override per ondata specifica in `sh_config.lua`:

```lua
ZS.Waves[5]  = { buytime = 90, announce = "ONDATA 5 — ULTIMA PREPARAZIONE!" }
ZS.Waves[10] = { count = 40, hp_scale = 3.0, special = "BOSS WAVE", announce = "IL BRUTO ARRIVA!" }
ZS.Waves[15] = { types = { npc_poisonzombie = 1.0 } }
```

Campi supportati: `count`, `types`, `buytime`, `payout`, `bonus`, `hp_scale`, `spawn_delay`, `special`, `announce`.

La salute degli zombie scala **+8% per ondata** di default (`hp_scale`), override per onda con `hp_scale` in `ZS.Waves[n]`.

### Spawn system
- Punti spawn = `info_player_deathmatch`/`info_player_start`/`info_player_combine`/`info_player_enemy`
  presenti in mappa **+ 32 punti generati su un anello** di raggio `zs_spawnradius` (2500) attorno
  al centro degli spawn, traced dall'alto verso il basso.
- Scelta punto: il più lontano dai player vivi (preferiti 1200–6000 units), per evitare spawn in faccia.
- Gli zombie HL2 inseguono il player più vicino con il pathfinding nativo.

### Economia
- Ogni player ha `ZS_Money` (NW su player, replicato ai client).
- In buytime: invulnerabilità (`EntityTakeDamage` hook) e respawn automatico ogni 2s con `weapon_pistol` gratis.
- Acquisti **solo in buytime**, a meno che `zs_allowbuyduringwave 1`.

---

## 4. SHOP E CONFIG (`sh_config.lua`)

È **il** file di configurazione. Tutto quello che si compra (armi, munizioni, barricate) è definito qui.

### Come trovare l'ID di un'arma
- Spawnmenu → Weapons → tasto destro sull'arma → **Copy SWEP Name**, oppure
- il classname corrisponde al nome della cartella in `garrysmod/lua/weapons/`.

### Blocco arma (`ZS.ShopWeapons`)

```lua
{
    class      = "weapon_cs_m4a1",  -- CLASSNAME SWEP (ID addon)  ← obbligatorio
    name       = "M4A1",            -- nome mostrato nello shop
    category   = "Fucili d'assalto",-- tab UI (deve esistere in ZS.Categories)
    price      = 1800,              -- costo in $
    ammo_class = "ar2",             -- chiave in ZS.AmmoTypes (nil = niente ammo)
    starting   = 60,                -- munizioni incluse nell'acquisto
    limit      = 1,                 -- max copie possedibili
    tier       = 4,                 -- ondata minima per sbloccare (1 = sempre)
    desc       = "Descrizione...",  -- testo piccolo nella riga shop
    icon       = "zs_weapons/m4.png", -- OPZIONALE: material custom (vedi §8)
},
```

### Blocco munizioni (`ZS.AmmoTypes`)

```lua
pistol = {
    class  = "Pistol",   -- AmmoType del gioco ("Pistol", "SMG1", "AR2", "Buckshot", "357"...)
    name   = "9mm Pistol",
    price  = 25,         -- costo del pacco
    amount = 68,         -- quante munizioni dà
    max    = 250,        -- cap trasportabile (opzionale; se hai 240/250 compra solo 10 al prezzo proporzionato)
},
```

### Blocco barricate (`ZS.Barricades`) — **NUOVO**
Ogni entry è una entità SENT deployabile (da `entities/entities/<class>/shared.lua`).

```lua
{
    class   = "zs_barricade_plank",    -- NOME ENTITÀ SENT (obbligatorio)
    name    = "Tavole di legno",       -- nome nello shop
    price   = 80,                      -- costo in $
    limit   = 6,                       -- max pezzi piazzabili contemporaneamente
    tier    = 1,                       -- ondata minima per sbloccare
    desc    = "Barricata economica...",-- descrizione
    model   = "models/...",            -- OPZIONALE: override modello
    health  = 300,                     -- HP della barricata
},
```

### Categorie (`ZS.Categories`)
L'ordine delle tab nello shop. Aggiungi `"Barricate"` per la tab barricate.

### Ricompense traguardo (`ZS.WaveRewards`)
Bonus extra `$` a ondate specifiche, es. `[10] = { bonus = 1500 }`.

### Costanti rapide
- Prezzi/soldi base → **cvar** (vedi §5), non hardcoded.
- Arma starter: la pistola viene data gratis al respawn. **Se vuoi gratis in shop, metti `price = 0`.**

---

## 5. CVAR di bilanciamento (console server)

| Cvar | Default | Descrizione |
|---|---|---|
| `zs_startmoney` | 500 | $ iniziali per player (a round/nuovo join) |
| `zs_waveinterval` | 45 | secondi di buytime tra le ondate |
| `zs_hordesize` | 8 | zombie all'ondata 1 |
| `zs_wavescale` | 1.15 | crescita × per ondata |
| `zs_maxzombies` | 64 | cap zombie vivi in simultanea |
| `zs_spawnradius` | 2500 | raggio anello spawn points |
| `zs_payoutbase` | 100 | $ base a fine ondata |
| `zs_payoutperkill` | 5 | $ per ogni kill |
| `zs_allowbuyduringwave` | 0 | 1 = compra anche durante l'ondata |

## 6. Comandi admin (console/RPT)

- `zs_skipwave` — salta il buytime (o spazza gli zombie se in onda)
- `zs_setmoney <n>` — set saldo a tutti
- `gamemode jzombiesurvival` — cambia modalità

---

## 7. HUD & CONTROLLI

**HUD** (client): pannello alto-centrale con stato + numero ondata + countdown/zombie rimasti;
pannello basso-destro con saldo e kill; hint "[4] per aprire l'armeria" durante il buytime;
toast notifiche colorate (info/success/warn/error).

**Controlli shop:**
- **Tasto `4`** → apre/chiude l'armeria in ogni momento (l'acquisto è validato server-side solo in buytime)
- `ESC` o `X` del frame → chiude
- La finestra ha **tab per categoria armi + tab "Munizioni" + tab "Barricate"**;
  ogni riga: icona, nome, descrizione/blocco tier, prezzo verde (comprabile) / rosso (soldi insufficienti) / grigio "BLOCCATA".

**Posizionamento barricate:**
1. Compra una barricata dalla tab "Barricate" → lo shop si chiude
2. Vedi un **fantasma trasparente (ghost)** davanti a te che segue il mirino
3. **LMB** = piazza la barricata (consuma l'acquisto, la possiedi tu)
4. **RMB** = annulla (rimborso automatico)
5. **E (Use)** su tua barricata = recupera (40% rimborso, solo proprietario)

---

## 8. ICONE

Le icone sono **disegnate proceduralmente** in `cl_shop.lua` (silhouette stilizzate per categoria:
pistola, SMG, pompa, fucile, cecchino, pesante, melee, granata + scatolina munizioni).
**Nessun file .png obbligatorio.**

Per usare un'icona custom per una specifica arma, aggiungi al suo blocco config:

```lua
icon = "zs_weapons/m4",   -- path senza estensione
```

e metti il file in `garrysmod/materials/zs_weapons/m4.png` (o `gamemodes/jzombiesurvival/materials/...`
dentro l'addon). Materiali standard GMod tipo `"icon16/wrench"` funzionano pure.
Le icone VGUI delle SWEP addon (`GetIcon`) **non** sono usate dallo shop — è una scelta: i pannelli
Derma usano le nostre silhouette per coerenza visiva.

---

## 9. PROTOCOLLO NET (per futuri sviluppi)

| Messaggio | Direzione | Payload | Uso |
|---|---|---|---|
| `ZS_SyncState` | S→C | wave(i16), state(i16), countdown(f32), zombies(i16) | broadcast su ogni cambio/tick buytime |
| `ZS_Notify` | S→C | text(str), type(str) | toast globali |
| `ZS_MoneyUpdate` | S→C | money(i32) | sync saldo personale |
| `ZS_PurchaseWeapon` | C→S | class(str) | richiesta acquisto arma |
| `ZS_PurchaseAmmo` | C→S | key(str) | richiesta pacco munizioni |
| `ZS_SellWeapon` | C→S | class(str) | vendita al 50% (solo buytime) |
| `ZS_PurchaseBarricade` | C→S | class(str) | richiesta acquisto barricata |
| `ZS_StartBarricadePlacement` | S→C | class(str), name(str) | attiva ghost placement client-side |
| `ZS_OpenShop` / `ZS_CloseShop` | S→C | — | auto-open/close buytime |

NW su player: `ZS_Money`, `ZS_Kills`, `ZS_Score`.

NW su entità barricata: `BarricadeOwner` (Entity), `BarricadeHealth` (Int), `BarricadeMaxHealth` (Int).

---

## 10. DECISIONI DI DESIGN (per per non rompere tutto)

- **NPC stock HL2** (`npc_zombie`, `npc_zombie_torso`, `npc_poisonzombie`, `npc_headcrab_fast`):
  pathfinding e animazioni gratis; niente nextbot custom.
- **Validazione server-side**: tier, cap armi (`limit`), soldi, buytime, esistenza SWEP.
- **Spawn graduale** (0.35s) per non laggare; coda che aspetta il cap zombie.
- **Invulnerabilità in buytime** per evitare kill da zombie residui durante gli acquisti.
- **Prezzi/prozzi munizioni proporzionali** quando il pacco supera il `max` di quel tipo.

## 11. IDEE FUTURE (TODO / backlog)

- [ ] Boss ogni 10 ondate (NPC più grosso, HP moltiplicati, ricompensa dedicata)
- [ ] Perk/passive acquistabili (salute max, velocità, reload)
- [ ] Barricate/placeable (tavoli, filo spinato) venduti nello shop "Utilità"
- [ ] Persistenza soldi/kill tra le sessioni (SQLite o file JSON)
- [ ] Scoreboard con classifica per ondata massima raggiunta
- [ ] Suoni ondata-in-arrivo / jingle buytime
- [ ] Supporto a `icon` custom per singola arma (già previsto nel config, solo da testare)
- [ ] Difficoltà dinamica (più player = più zombie)
- [ ] Drop casuali di casse munizioni/soldi dagli zombie

---

## 12. CHANGELOG

- **1.0** — Prima versione: wave manager + spawn ai bordi + economia + shop (armi/munizioni)
  configurabile da `sh_config.lua`, HUD, notifiche, comandi admin.
