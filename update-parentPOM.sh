#!/bin/bash
if [ -f settings.xml ]; then
    ANYPOINT_CLIENT_ID_ENCRYPTED=$(sed -n "/<id>anypoint-repo<\/id>/,/<\/server>/ s/.*<username>\(.*\)<\/username>.*/\1/p" settings.xml)
    ANYPOINT_CLIENT_SECRET_ENCRYPTED=$(sed -n "/<id>anypoint-repo<\/id>/,/<\/server>/ s/.*<password>\(.*\)<\/password>.*/\1/p" settings.xml)
    echo "Anypoint Client ID: $ANYPOINT_CLIENT_ID_ENCRYPTED"
    echo "Anypoint Client SECRET: $ANYPOINT_CLIENT_SECRET_ENCRYPTED"
    ANYPOINT_ID_DECRYPTED=$(echo "${ANYPOINT_CLIENT_ID_ENCRYPTED}" | openssl enc -aes-256-cbc -d -salt -pbkdf2 -k "wQf9vaGtyBckXAqzNWbNuC50VlgY50fOj2IF2Rn2NHA=" -base64)
    ANYPOINT_SECRET_DECRYPTED=$(echo "${ANYPOINT_CLIENT_SECRET_ENCRYPTED}" | openssl enc -aes-256-cbc -d -salt -pbkdf2 -k "wQf9vaGtyBckXAqzNWbNuC50VlgY50fOj2IF2Rn2NHA=" -base64)
    org_id=$(curl -X GET "https://anypoint.mulesoft.com/accounts/api/me" -H "Authorization: Bearer 32f09c6a-bd2f-4648-a2d6-44df19bd552d" -H "Content-Type: application/json" | jq -r ".user.organization.id")
    env_id=$(curl -X GET "https://anypoint.mulesoft.com/accounts/api/organizations/$org_id/environments?name=developer" -H "Authorization: Bearer 32f09c6a-bd2f-4648-a2d6-44df19bd552d" -H "Content-Type: application/json" | jq -r ".data[0].id")
    apps_cloudhub=$(curl -X GET "https://anypoint.mulesoft.com/cloudhub/api/v2/applications" -H "Authorization: Bearer 32f09c6a-bd2f-4648-a2d6-44df19bd552d" -H "x-anypnt-env-id: $env_id" | jq -r ".[].domain")
    MULE_APP_NAME=$(grep -oPm1 "(?<=<name>)[^<]+" pom.xml)
    found=false
    for app in $apps_cloudhub; do
          if [[ "$app" == "$MULE_APP_NAME" ]]; then
              found=true
                break
          fi
    done
    if $found; then
      version_number=1
      echo "Application $MULE_APP_NAME already deployed in cloudHub."
      while echo "$apps_cloudhub" | grep -q "${MULE_APP_NAME}v$version_number"; do
          echo "Application $MULE_APP_NAMEV$version_number already deployed in cloudHub."
            version_number=$((version_number + 1))
      done
    MULE_APP_NAME="${MULE_APP_NAME}V$version_number"
    echo "MULEOSFT app name: $MULE_APP_NAME"
    fi
    echo "Deploying application: ${MULE_APP_NAME}"
    MULE_RUNTIME_VERSION=$(grep -oPm1 "(?<=<app.runtime>)[^<]+" pom.xml)
    echo "MULE RUNTIME VERSION: $MULE_RUNTIME_VERSION"
cat << EOF > parent_pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.mycompany</groupId>
  <artifactId>parent-pom</artifactId>
  <version>1.0.0-SNAPSHOT</version>
  <packaging>pom</packaging>
  <name>parent-pom</name>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    <app.runtime>${MULE_RUNTIME_VERSION}</app.runtime>
    <mule.maven.plugin.version>4.2.0</mule.maven.plugin.version>
  </properties>
  <build>
    <plugins>
    </plugins>
  </build>
</project>
EOF
PLUGIN_EXISTS=$(grep -c "<groupId>org.mule.tools.maven</groupId>" parent_pom.xml)
if [ "$PLUGIN_EXISTS" -eq 0 ]; then
  if [ "developer" == "main" ] || [ "developer" == "master" ]; then
    CONFIGURATION="<plugin>\n<groupId>org.mule.tools.maven</groupId>\n<artifactId>mule-maven-plugin</artifactId>\n<version>\${mule.maven.plugin.version}</version>\n<extensions>true</extensions>\n<configuration>\n<cloudHubDeployment>\n<uri>https://anypoint.mulesoft.com/</uri>\n<muleVersion>${MULE_RUNTIME_VERSION}</muleVersion>\n<connectedAppClientId>${ANYPOINT_ID_DECRYPTED}</connectedAppClientId>\n<connectedAppClientSecret>${ANYPOINT_SECRET_DECRYPTED}</connectedAppClientSecret>\n<connectedAppGrantType>client_credentials</connectedAppGrantType>\n<applicationName>${MULE_APP_NAME}</applicationName>\n<businessGroup>ITMMA</businessGroup>\n<environment>product</environment>\n<workers>1</workers>\n<objectStoreV2>true</objectStoreV2>\n</cloudHubDeployment>\n</configuration>\n</plugin>"
  else
    CONFIGURATION="<plugin>\n<groupId>org.mule.tools.maven</groupId>\n<artifactId>mule-maven-plugin</artifactId>\n<version>\${mule.maven.plugin.version}</version>\n<extensions>true</extensions>\n<configuration>\n<cloudHubDeployment>\n<uri>https://anypoint.mulesoft.com/</uri>\n<muleVersion>${MULE_RUNTIME_VERSION}</muleVersion>\n<connectedAppClientId>${ANYPOINT_ID_DECRYPTED}</connectedAppClientId>\n<connectedAppClientSecret>${ANYPOINT_SECRET_DECRYPTED}</connectedAppClientSecret>\n<connectedAppGrantType>client_credentials</connectedAppGrantType>\n<applicationName>${MULE_APP_NAME}</applicationName>\n<businessGroup>ITMMA</businessGroup>\n<environment>developer</environment>\n<workers>1</workers>\n<objectStoreV2>true</objectStoreV2>\n</cloudHubDeployment>\n</configuration>\n</plugin>"
  fi
  sed -i "/<\/plugins>/i $CONFIGURATION" parent_pom.xml
  git checkout -b developer || git checkout developer
  git add parent_pom.xml update-parentPOM.sh
  git commit -m "Create and update Parent POM file"
  git push dev developer
fi
fi
