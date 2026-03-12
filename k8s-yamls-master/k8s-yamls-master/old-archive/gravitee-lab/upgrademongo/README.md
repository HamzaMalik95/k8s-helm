# Download scripts
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.5.14/1-fix-cors-env-vars.js
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.8.0/1-page-acl-migration.js
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.9.0/1-tags-and-tenants-migration.js
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.9.0/2-events-migration.js
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.10.1/1-upgrade-parameters-for-theme-console.js
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.11.1/1-event-debug-migration.js
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.12.0/api-keys-migration.js
wget https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.17.0/api-keys-cleanup.js
wget https://gh.gravitee.io/gravitee-io/gravitee-api-management/master/gravitee-apim-repository/gravitee-apim-repository-mongodb/src/main/resources/scripts/3.18.0/audit-set-environmentId-organizationId.js

# run scripts

mongo localhost:27017/gravitee 1-fix-cors-env-vars.js
mongo localhost:27017/gravitee 1-page-acl-migration.js
mongo localhost:27017/gravitee 1-tags-and-tenants-migration.js
mongo localhost:27017/gravitee 2-events-migration.js
mongo localhost:27017/gravitee 1-upgrade-parameters-for-theme-console.js
mongo localhost:27017/gravitee 1-event-debug-migration.js
mongo localhost:27017/gravitee api-keys-migration.js
mongo localhost:27017/gravitee api-keys-cleanup.js
mongo localhost:27017/gravitee 3-audit-set-environmentId-organizationId.js
mongo localhost:27017/gravitee 3-clientRegistrationProvider-set-environmentId.js
