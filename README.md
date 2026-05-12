This is a snapshot of the Banner Saga Factions service code from 2013.

There is a snapshot of the relevant parts of the Banner Saga Factions client code in the ./tbs-2013/ folder.

see LICENSE.md

## Deployment

> **Caveat (high uncertainty):** The instructions below mix what the repo encodes from the 2013 deploy (Procfile, `config/ec2/*`, `setup_foreman.sh`, `db/dbtool.sh`) with modern equivalents on AWS/Heroku. Anything labeled *modern* has not been verified end-to-end against current platform APIs — treat it as a starting point, not a tested recipe.

### Build

Maven multi-module is not used; a single `pom.xml` at the root produces classes
under `target/classes` and dependencies under `target/dependency`.

```
mvn -DskipTests package dependency:copy-dependencies
```

The Procfile launches four JVM processes from the same classpath
(`target/classes:target/dependency/*:config`):

| Process | Main class | Role |
|---|---|---|
| `web`    | `tbs.srv.web.WebMain`        | Jetty HTTP service (Jersey JAX-RS) |
| `worker` | `tbs.srv.worker.WorkerMain`  | Battle + Chat authority workers |
| `vs`     | `tbs.srv.worker.WorkerMain`  | Versus matchmaker authority |
| `other`  | `tbs.srv.worker.WorkerMain`  | Session/Renown/Friend/Achievement/etc. authorities |

### Deploy to Heroku

This is the original deploy path (medium-high confidence the mechanics still
work; low confidence on Heroku's current Java version defaults — verify
`system.properties` or set a buildpack pin if the JVM target matters).

```bash
# one-time
heroku create tbs-factions-dev --buildpack heroku/java
heroku git:remote -a tbs-factions-dev
heroku addons:create newrelic:wayne     # optional; original used New Relic Java agent

# scale dynos to match the 4 Procfile process types
heroku ps:scale web=1 worker=1 vs=1 other=1

# set required config (see matrix below) -- example only
heroku config:set GAME_ENVIRONMENT=dev BUILD_NUMBER=$(git rev-parse --short HEAD) \
                  STEAM_APP_ID=237990 ...

# deploy
git push heroku master
```

`upload.sh` in the repo is the original one-liner used in 2013 — it force-pushes
the working tree to a Heroku remote and recreates history. Do not run it against
a repo you care about preserving.

### Required configuration

These environment variables are read at startup. Variables marked **required**
will cause `WebMain`/`WorkerMain` to fail-fast on boot. Defaults are shown
where the source provides one.

| Var | Required | Default | Purpose | Source |
|---|---|---|---|---|
| `RDS_URL` | yes | — | JDBC host + DB name, e.g. `host.amazonaws.com/tbs_dev` | `GameConfig.java` |
| `RDS_USERNAME` | yes | — | MySQL user | `GameConfig.java` |
| `RDS_PASSWORD` | no\* | — | MySQL password | `GameConfig.java` |
| `RABBIT_URL` | yes | — | `amqp://user:pass@host:5672/vhost` | `RabbitConfig.java` |
| `GAME_ENVIRONMENT` | yes | — | Environment tag, e.g. `dev`, `qa`, `live` | `GameConfig.java` |
| `BUILD_NUMBER` | yes | — | Build id; used in `DATA_URL` default | `GameConfig.java` |
| `STEAM_APP_ID` | yes | `0` | Steam app id (237990 for Factions) | `GameConfig.java` |
| `STEAM_API_KEY` | no | — | Steam Web API key for auth/microtxn | `GameConfig.java` |
| `VBB_PASSWORD` | yes | — | vBulletin forum DB password (auth backend) | `WebConfig.java` |
| `VBB_USER`/`VBB_SERVER`/`VBB_DB` | no | `gameserver_vbb` / `mysql.stoicstudio.com` / `stoic_vbb_forum` | vBulletin auth backend | `WebConfig.java` |
| `VBB_ENABLED` | no | `true` | Disable vBulletin auth (set `false` for ad-hoc) | `WebConfig.java` |
| `AD_HOC_ACCOUNTS` | no | `false` | Allow ad-hoc account creation | `WebConfig.java` |
| `ADMIN_KEY` | no | — | Bearer for `/services/admin/*` endpoints | `WebConfig.java` |
| `PORT` | no | `8080` | Jetty bind port (Heroku sets this) | `WebConfig.java` |
| `KIOSK` | no | `false` | Local-only mode | `GameConfig.java` |
| `DATA_URL` | no | `http://stoicstudio.com/deploy/dev/<BUILD>` | Asset CDN base | `GameConfig.java` |
| `STEAM_MICRO_TXN_SANDBOX` | no | `false` | Use Steam microtxn sandbox | `GameConfig.java` |
| `STEAM_TXN_FORCE_FINALIZE` | no | `false` | Skip Steam txn verification (dev only) | `GameConfig.java` |
| `JAVA_OPTS` | no | — | JVM flags (original: `-Xmx384m -Xss512k -XX:+UseCompressedOops`) | Procfile |
| `LOG4J_ROOT_LEVEL` | no | — | Log4j root level (`INFO`/`DEBUG`/etc.) | Procfile |
| `NEW_RELIC_APP_NAME` | no | — | NR app name | newrelic agent |
| `NEW_RELIC_LICENSE_KEY` | no | — | NR license (read from env, overrides `newrelic.yml`) | newrelic agent |
| `AWS_ACCESS_KEY` / `AWS_SECRET_KEY` | no | — | Used by `setup_foreman.sh` for legacy EC2 tooling | `setup_foreman.sh` |

\* `RDS_PASSWORD` is technically optional in the source but practically required
unless the DB user has no password.

`setup_foreman.sh` is an interactive helper from the 2013 repo that prompts for
the common vars and writes `foreman.rc` for `foreman start` local runs.

### Provision MySQL on AWS RDS *(modern path)*

Schema version 88 is the latest in `db/game/`; the bootstrap loop in
`tbs.srv.util.GameConfig` checks `version_number` against `RDS_VERSION = 88`
and exits if mismatched.

```bash
aws rds create-db-instance \
  --db-instance-identifier tbs-factions-game-db \
  --engine mysql --engine-version 8.0 \
  --db-instance-class db.t4g.micro \
  --allocated-storage 20 --storage-type gp3 \
  --master-username stoicdb --manage-master-user-password \
  --backup-retention-period 7 \
  --vpc-security-group-ids sg-xxxxxxxx \
  --publicly-accessible
```

Then bootstrap the schema using `db/dbtool.sh` (legacy script, written for
MySQL 5.x — uncertain whether it runs unchanged against MySQL 8 due to
`utf8`/`utf8mb4` and password plugin differences):

```bash
export DB_PASSWD="..."        # password for the admin user
./db/dbtool.sh -a -i game -r live -H <rds-endpoint> -u 88
./db/dbtool.sh -a -i metrics -r live -H <rds-endpoint> -u 4
```

Set the application's `RDS_URL` to `<rds-endpoint>/dev_<release>` (or your
chosen DB name), and `RDS_USERNAME`/`RDS_PASSWORD` to a non-admin user with
DML access to that DB.

A second smaller schema lives under `db/metrics/` (current version 4) and is
deployed the same way to a separate database.

### Provision RabbitMQ on AWS

Two options:

**Modern (recommended): Amazon MQ for RabbitMQ.** Managed broker, no host
to maintain. Uncertainty: medium — I have not verified that this codebase's
RabbitMQ client (`rabbitmq-java-client-bin-3.1.3`) connects cleanly to current
Amazon MQ RabbitMQ versions; protocol-level compatibility is likely but the
old client is past EOL.

```bash
aws mq create-broker \
  --broker-name tbs-rabbit \
  --engine-type RABBITMQ --engine-version 3.13 \
  --host-instance-type mq.t3.micro \
  --deployment-mode SINGLE_INSTANCE \
  --users '[{"Username":"tbs","Password":"<strong-pw>"}]' \
  --publicly-accessible \
  --security-groups sg-xxxxxxxx
```

The broker returns an `amqps://b-xxx.mq.<region>.amazonaws.com:5671` endpoint
which becomes `RABBIT_URL`:

```
amqps://tbs:<password>@b-xxx.mq.us-east-1.amazonaws.com:5671
```

**Legacy (matches 2013 repo): self-managed RabbitMQ on EC2.** The scripts
under `config/ec2/` use deprecated tooling (`ec2-run-instances`, AMI
`ami-3d4ff254`, `m1.small`). Translated to current AWS CLI:

```bash
# Replace AMI with a current Debian/Ubuntu AMI ID for your region
aws ec2 run-instances \
  --image-id ami-xxxxxxxxxxxxxxxxx \
  --instance-type t3.small \
  --key-name rabbitserver \
  --security-group-ids sg-default sg-rabbitmq \
  --user-data file://config/ec2/rabbit-ec2-user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rabbit}]'
```

The user-data script in `config/ec2/rabbit-ec2-user-data.sh` is from 2013 — it
adds an http:// rabbitmq.com apt source that no longer serves packages over
HTTP and uses `apt-key add` which is deprecated on current Debian/Ubuntu. Use
the [current RabbitMQ install instructions](https://www.rabbitmq.com/install-debian.html)
to bootstrap a current broker; the script is included as historical context.

Security-group needs: inbound `5672/tcp` (AMQP) from the Heroku dynos'
egress (Heroku publishes ranges) or a NAT, plus `15672/tcp` from your admin IPs
for the management UI.
