### Goal
Run the Flux project locally (build, set up databases, start the runtime, and execute an example workflow) on Windows using PowerShell.

### Prerequisites
- Java JDK 8 (project targets 1.8)
- Apache Maven 3.x on PATH
- MySQL Server running on localhost:3306
    - Default configuration in the repo expects MySQL user root with no password
    - If your MySQL setup differs (e.g., password), you can either adjust the DB and user to match the defaults or update the configuration before building (see “Changing DB settings” below).

### 1) Clone and build
In PowerShell from the project root (C:\Users\srinath\IdeaProjects\flux):
- mvn -q clean install -DskipTests

This compiles all modules in the multi-module build (model, common, scheduler, persistence, persistence-mysql, runtime, task, client, examples, api).

### 2) Initialize the databases
Start MySQL service, then create and migrate the two required schemas. The repo’s setup_db.sh uses MySQL root with no password; here are equivalent steps in PowerShell:

- Create schemas:
    - You can do this in MySQL Workbench or via mysql CLI:
        - mysql -uroot -e "DROP DATABASE IF EXISTS flux; CREATE DATABASE flux;"
        - mysql -uroot -e "DROP DATABASE IF EXISTS flux_scheduler; CREATE DATABASE flux_scheduler;"

- Run Liquibase migrations using Maven (from project root):
    - mvn -pl :persistence-mysql liquibase:update -Dliquibase-maven-plugin.dbname=flux
    - mvn -pl :persistence-mysql liquibase:update -Dliquibase-maven-plugin.dbname=flux_scheduler

If these fail due to authentication, see “Changing DB settings” below.

### 3) Prepare a Deployment Unit (DU) for examples
Flux loads workflows from a deployment directory specified in runtime/config (default is /tmp/workflows which on Windows typically resolves to C:\tmp\workflows). We’ll create a DU and copy the example artifacts.

- Build the examples module and copy its runtime dependencies:
    - cd .\examples
    - mvn -q package dependency:copy-dependencies -DincludeScope=runtime -DskipTests
    - cd ..

- Create the DU directory structure (PowerShell):
    - New-Item -ItemType Directory -Force -Path C:\tmp\workflows\DU1\1\main | Out-Null
    - New-Item -ItemType Directory -Force -Path C:\tmp\workflows\DU1\1\lib  | Out-Null

- Copy JARs and config into the DU:
    - Copy-Item .\examples\target\examples-*.jar C:\tmp\workflows\DU1\1\main\
    - Copy-Item .\examples\target\dependency\* C:\tmp\workflows\DU1\1\lib\
    - Copy-Item .\examples\src\main\resources\flux_config.yml C:\tmp\workflows\DU1\1\

Note: The config file name in the DU must be flux_config.yml to match the runtime’s expectation.

### 4) Start the Flux runtime
Start Flux in “combined” mode (orchestration + execution) in one PowerShell window from the project root:

- java -Dlog4j.configurationFile=.\examples\target\classes\log4j2.xml -cp "examples\target\dependency\*;examples\target\*" com.flipkart.flux.initializer.FluxInitializer start

What you should see
- Startup banner with “Flux startup complete”
- By default, services bind to these ports (from runtime\src\main\resources\packaged\configuration.yml):
    - Dashboard: 9999
    - API: 9998
    - Execution Node API: 9997

Open the dashboard
- http://localhost:9999/admin/dashboard
- FSM view is also under the dashboard app (http://localhost:9999/admin/fsmview)

### 5) Run an example workflow
In another PowerShell window, from the project root:

- java -Dlog4j.configurationFile=.\examples\target\classes\log4j2.xml -cp "examples\target\*;examples\target\dependency\*" com.flipkart.flux.examples.decision.RunUserVerificationWorkflow

Other example main classes you can try (fully qualified names):
- com.flipkart.flux.examples.concurrent.RunEmailMarketingWorkflow
- com.flipkart.flux.examples.decision.RunUserVerificationWorkflow
- com.flipkart.flux.examples.cancelpath.RunCancelPathWorkflow
- com.flipkart.flux.examples.eventupdate.RunEventUpdateWorkflow
- com.flipkart.flux.examples.externalevents.RunManualSellerVerificationWorkflow
- com.flipkart.flux.examples.replayevents.RunReplayEventWorkflow

As they execute, watch the DAG and task progression in the dashboard.

### Running in separate modes (advanced)
You can run orchestration and execution as separate processes (in two terminals):
- Orchestration:
    - java -Dlog4j.configurationFile=.\examples\target\classes\log4j2.xml -cp "examples\target\dependency\*;examples\target\*" com.flipkart.flux.initializer.FluxInitializer start orchestration
- Execution:
    - java -Dlog4j.configurationFile=.\examples\target\classes\log4j2.xml -cp "examples\target\dependency\*;examples\target\*" com.flipkart.flux.initializer.FluxInitializer start execution

Then run one of the example main classes as shown above.

### Changing DB settings (if your MySQL root has a password or different host)
Default DB settings are in runtime\src\main\resources\packaged\configuration.yml:
- flux DB: jdbc:mysql://localhost:3306/flux user root password ""
- flux_scheduler DB: jdbc:mysql://localhost:3306/flux_scheduler user root password ""

If you need to change these:
- Update those properties to match your MySQL credentials before building, or
- Create a user with no password for local testing (less secure), or
- Pass through equivalent changes wherever your deployment picks up configuration (the project loads the packaged configuration.yml at runtime; it doesn’t expose an obvious external override parameter in the provided scripts).

### Common issues and fixes
- MySQL auth errors during Liquibase
    - Ensure the root user can connect with no password, or use a root password and update configuration.yml accordingly, then rebuild.
- Port already in use (9997/9998/9999)
    - Change the ports in configuration.yml, rebuild, and restart; or free the ports.
- Classpath problems on Windows
    - Ensure you use semicolons (;) as classpath separators and backslashes in paths, as shown above.
- Dashboard not reachable
    - Validate the runtime process is running and bound to 9999. Re-check logs printed to console.

### Short version (all commands)
1) Build
- mvn -q clean install -DskipTests

2) DB migrate
- mysql -uroot -e "DROP DATABASE IF EXISTS flux; CREATE DATABASE flux;"
- mysql -uroot -e "DROP DATABASE IF EXISTS flux_scheduler; CREATE DATABASE flux_scheduler;"
- mvn -pl :persistence-mysql liquibase:update -Dliquibase-maven-plugin.dbname=flux
- mvn -pl :persistence-mysql liquibase:update -Dliquibase-maven-plugin.dbname=flux_scheduler

3) Prepare DU
- cd .\examples
- mvn -q package dependency:copy-dependencies -DincludeScope=runtime -DskipTests
- cd ..
- New-Item -ItemType Directory -Force -Path C:\tmp\workflows\DU1\1\main | Out-Null
- New-Item -ItemType Directory -Force -Path C:\tmp\workflows\DU1\1\lib  | Out-Null
- Copy-Item .\examples\target\examples-*.jar C:\tmp\workflows\DU1\1\main\
- Copy-Item .\examples\target\dependency\* C:\tmp\workflows\DU1\1\lib\
- Copy-Item .\examples\src\main\resources\flux_config.yml C:\tmp\workflows\DU1\1\

4) Start runtime
- java -Dlog4j.configurationFile=.\examples\target\classes\log4j2.xml -cp "examples\target\dependency\*;examples\target\*" com.flipkart.flux.initializer.FluxInitializer start

5) Run an example
- java -Dlog4j.configurationFile=.\examples\target\classes\log4j2.xml -cp "examples\target\*;examples\target\dependency\*" com.flipkart.flux.examples.decision.RunUserVerificationWorkflow

Open the dashboard at http://localhost:9999/admin/dashboard and observe execution.

If you run into any errors, share the console output and I’ll help troubleshoot.