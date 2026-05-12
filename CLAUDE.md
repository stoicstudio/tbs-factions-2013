# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository scope

A 2013-era snapshot of the Banner Saga Factions service (Java, Maven, single
module). Two distinct trees:

- **`src/`, `pom.xml`, `db/`, `config/`, `Procfile`** — the live service code.
  This is what gets built and deployed.
- **`tbs-2013/`** — a curated AS3 client reference mirror (385 files copied
  from the 2013 client repo). **Reference only — do not attempt to compile.**
  ~73 imports are intentionally unresolved because the deferred packages
  (`engine.saga.*`, `engine.resource.*`, `engine.gui.*`, `engine.scene.*`,
  `engine.anim.*`, `engine.sound.*`, `engine.landscape.*`, `engine.vfx.*`,
  `engine.automator.*`, `engine.fmod.*`, `game.gui.*`, `game.view.*`,
  `game.saga.*`) were excluded as out-of-scope client-runtime concerns. If
  expanding the mirror, follow the same skip policy.

The full deployment story (Heroku, AWS RDS, AWS RabbitMQ/Amazon MQ) and the
complete env-var matrix live in `README.md`. Reach for that before duplicating
its content here.

## Commands

```bash
# Build classes + collect dependency jars (Procfile expects target/dependency/*)
mvn -DskipTests package dependency:copy-dependencies

# Test (JUnit, only 2 test classes exist)
mvn test
mvn test -Dtest=BattleRankingTest          # single test class
mvn test -Dtest=BattleRankingTest#methodName

# Local run (all 4 procs via foreman)
./setup_foreman.sh                          # interactive: writes foreman.rc
foreman start                               # uses Procfile + foreman.rc env

# Schema bootstrap / migration (the source of truth for DB version is
# GameConfig.RDS_VERSION; the running DB's version_number row must match)
./db/dbtool.sh -a -i game    -r <release> -H <host> -u 88
./db/dbtool.sh -a -i metrics -r <release> -H <host> -u 4

# Heroku deploy
git push heroku master
```

`upload.sh` is the 2013 one-liner: `git init . && git push --force` to Heroku.
**Destructive — overwrites history. Do not run on a repo you care about.**

`bin/shutdown.sh <minutes> <server> <admin_key>` posts countdown messages to
`/services/admin/system_msg` over a period of minutes. Useful for graceful
restarts; requires `ADMIN_KEY`.

The pom does not pin `maven.compiler.source`/`target`. Medium uncertainty:
current Maven defaults to Java 8+; the source predates lambdas and should
compile clean against 8 or 11.

## Architecture

### Two JVM entry points, four Procfile dynos

All four dynos run from the same classpath (`target/classes:target/dependency/*:config`)
and differ only in main class + args:

| Dyno | Main | Args | Role |
|---|---|---|---|
| `web`    | `tbs.srv.web.WebMain`       | —                               | Jetty + Jersey HTTP service |
| `worker` | `tbs.srv.worker.WorkerMain` | `--battle_authority --chat_authority` | Battle + chat authority workers |
| `vs`     | `tbs.srv.worker.WorkerMain` | `--battle_authority Vs`         | Versus matchmaker authority only |
| `other`  | `tbs.srv.worker.WorkerMain` | `--chat_authority Session Renown Friend Achievement UnitAdd Tourney Unlock SteamUser Leaderboard SteamDlc` | All other workers |

The Procfile encodes a **single-authority sharding model**: only one process
in the deployment holds `battle_authority` (the `worker` dyno) and only one
holds `chat_authority` (also `worker` — but in production it can be split).
`WorkerMain.workerClasses` is the registry of all workers; the CLI args
select which ones run, defaulting to all when no shortnames are given.

### Config hierarchy

```
BaseConfig            (env-var helpers, ehcache, rabbit handle)
  └─ GameConfig       (RDS datasource, def loading, Steam, RabbitConfig)
       ├─ WebConfig   (vBulletin auth datasource, Jetty thread pool, session cache)
       └─ WorkerConfig (worker-specific tuning)
```

`GameConfig` is the source of truth for env-var-driven configuration. It also
sets `RDS_VERSION = 88` — boot fails if the DB's `version` row doesn't match.
All worker/web boot paths construct a `*Config` subclass which transitively
loads game definitions (from `DATA_URL`), opens the RDS connection pool, and
wires RabbitMQ. The full env-var matrix is in `README.md`.

### Web layer (Jersey JAX-RS)

`src/main/webapp/WEB-INF/web.xml` registers ~25 Jersey servlets, one per
service package under `tbs.srv.web.svc.*`. URL pattern is
`/services/<area>/...`. Each service area is a self-contained package with
its own POJOs and a single `*Svc.java` resource class. Admin endpoints
(`tbs.srv.web.svc.admin`) gate on the `ADMIN_KEY` env var.

### Worker / messaging layer

Workers extend `BaseWorker` and consume from RabbitMQ queues defined by
`RabbitConfig`. The web layer publishes messages; workers process them
asynchronously and may publish results back. The "authority" flags decide
which process owns mutable battle/chat state.

### Persistence

- **Game DB** (`db/game/`): schema 88, partial schema in `0/schema.sql` then
  numbered `apply.sql` migrations. Bootstrapped via `db/dbtool.sh`. Per-table
  Java models under `tbs.srv.db.models`; access goes through `DbHelper`.
- **Metrics DB** (`db/metrics/`): schema 4, separate database, same tooling.
- **vBulletin DB** (`VBB_*` env vars): the original 2013 auth backend was the
  Stoic forum's vBulletin user table on a separate MySQL host. Disable with
  `VBB_ENABLED=false` and use `AD_HOC_ACCOUNTS=true` for dev environments.

### External integrations

- **Steam** (`tbs.srv.util.steam.*`): Steam Web API for session auth, Steam
  Micro-Transaction API for IAP. Behavior gated by `STEAM_*` env vars;
  `STEAM_MICRO_TXN_SANDBOX` + `STEAM_TXN_FORCE_FINALIZE` for dev/test.
- **New Relic**: agent-based, injected via `-javaagent:newrelic/newrelic.jar`
  in the Procfile. `newrelic.yml` reads license from `NEW_RELIC_LICENSE_KEY`
  env var (the YAML literal was removed in a prior cleanup; an ERB-style
  placeholder remains).

## Operational notes

- **Repo history was orphan-init'd** to scrub a previously-leaked New Relic
  license key. The current git log starts at the orphan `init` commit. The
  old Heroku remote retains the original history and must not be used as a
  history source.
- **New Relic key rotation is still required** if the repo is shared or
  pushed publicly; removing it from the working tree does not invalidate the
  leaked credential.
- When extending the AS3 mirror under `tbs-2013/`: re-use the skip policy
  documented above. The mirror was built by ring-by-ring import-following
  from a seed of `lib.engine.core/src/tbs/srv/**` plus
  `lib.game/src/game/session/{actions,GameFsm,GameFsmEvent,GameState}`.
- `setup_foreman.sh` has historical defaults (e.g. `tbs-game-db.stoicstudio.com`,
  `dev-<user>-<host>` env names) that reflect the 2013 staging environment.
  Override every value when running outside that environment.
