#!/bin/bash
if [ -f settings.xml ]; then
    ANYPOINT_CLIENT_ID_ENCRYPTED=$(sed -n "/<id>anypoint-repo<\/id>/,/<\/server>/ s/.*<username>\(.*\)<\/username>.*/\1/p" settings.xml)
    ANYPOINT_CLIENT_SECRET_ENCRYPTED=$(sed -n "/<id>anypoint-repo<\/id>/,/<\/server>/ s/.*<password>\(.*\)<\/password>.*/\1/p" settings.xml)
    ANYPOINT_ID_DECRYPTED=$(echo "${ANYPOINT_CLIENT_ID_ENCRYPTED}" | openssl enc -aes-256-cbc -d -salt -pbkdf2 -k "wQf9vaGtyBckXAqzNWbNuC50VlgY50fOj2IF2Rn2NHA=" -base64)
    ANYPOINT_SECRET_DECRYPTED=$(echo "${ANYPOINT_CLIENT_SECRET_ENCRYPTED}" | openssl enc -aes-256-cbc -d -salt -pbkdf2 -k "wQf9vaGtyBckXAqzNWbNuC50VlgY50fOj2IF2Rn2NHA=" -base64)
    MULE_APP_NAME=$(grep -oPm1 "(?<=<name>)[^<]+" pom.xml)
    echo "Deploying application: ${MULE_APP_NAME}"
    MULE_RUNTIME_VERSION=$(grep -oPm1 "(?<=<app.runtime>)[^<]+" pom.xml)
cat << EOF > parent_pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>394989c8-ee4c-4f8c-805d-f393165ac9a3</groupId>
  <artifactId>parent-pom</artifactId>
  <version>1.0.0</version>
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
    CONFIGURATION="<plugin>\n<groupId>org.mule.tools.maven</groupId>\n<artifactId>mule-maven-plugin</artifactId>\n<version>\${mule.maven.plugin.version}</version>\n<extensions>true</extensions>\n<configuration>\n<cloudhub2Deployment>\n<uri>https://anypoint.mulesoft.com/</uri>\n<provider>MC</provider>\n<environment>product</environment>\n<target>Cloudhub-US-East-2</target>\n<muleVersion>${MULE_RUNTIME_VERSION}</muleVersion>\n<username>${ANYPOINT_ID_DECRYPTED}</username>\n<password>${ANYPOINT_SECRET_DECRYPTED}</password>\n<applicationName>${MULE_APP_NAME}</applicationName>\n<businessGroup>ITMMA</businessGroup>\n<replicas>1</replicas>\n<vCores>1</vCores>\n</cloudhub2Deployment>\n</configuration>\n</plugin>"
  else
    CONFIGURATION="<plugin>\n<groupId>org.mule.tools.maven</groupId>\n<artifactId>mule-maven-plugin</artifactId>\n<version>\${mule.maven.plugin.version}</version>\n<extensions>true</extensions>\n<configuration>\n<cloudhub2Deployment>\n<uri>https://anypoint.mulesoft.com/</uri>\n<provider>MC</provider>\n<environment>developer</environment>\n<target>Cloudhub-US-East-2</target>\n<muleVersion>${MULE_RUNTIME_VERSION}</muleVersion>\n<username>${ANYPOINT_ID_DECRYPTED}</username>\n<password>${ANYPOINT_SECRET_DECRYPTED}</password>\n<applicationName>${MULE_APP_NAME}</applicationName>\n<businessGroup>ITMMA</businessGroup>\n<replicas>1</replicas>\n<vCores>1</vCores>\n</cloudhub2Deployment>\n</configuration>\n</plugin>"
  fi
  sed -i "/<\/plugins>/i $CONFIGURATION" parent_pom.xml
  git checkout -b developer || git checkout developer
  git add parent_pom.xml update-parentPOM.sh
  git commit -m "Create and update Parent POM file"
  git push dev developer
fi
fi
