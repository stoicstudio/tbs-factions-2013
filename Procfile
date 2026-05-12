web: java -cp target/classes:target/dependency/*:config -Dlog4j.root.level=$LOG4J_ROOT_LEVEL -Dlog4j.configuration=log4j.xml $JAVA_OPTS -javaagent:newrelic/newrelic.jar tbs.srv.web.WebMain
worker: java -cp target/classes:target/dependency/*:config -Dlog4j.root.level=$LOG4J_ROOT_LEVEL -Dlog4j.configuration=log4j.xml $JAVA_OPTS  -javaagent:newrelic/newrelic.jar tbs.srv.worker.WorkerMain --battle_authority --chat_authority
vs: java -cp target/classes:target/dependency/*:config -Dlog4j.root.level=$LOG4J_ROOT_LEVEL -Dlog4j.configuration=log4j.xml $JAVA_OPTS  -javaagent:newrelic/newrelic.jar tbs.srv.worker.WorkerMain --battle_authority Vs
other: java -cp target/classes:target/dependency/*:config -Dlog4j.root.level=$LOG4J_ROOT_LEVEL -Dlog4j.configuration=log4j.xml $JAVA_OPTS  -javaagent:newrelic/newrelic.jar tbs.srv.worker.WorkerMain --chat_authority Session Renown Friend Achievement UnitAdd Tourney Unlock SteamUser Leaderboard SteamDlc

