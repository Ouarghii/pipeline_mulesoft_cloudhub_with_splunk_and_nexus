#!/bin/bash
ANYPOINT_ID=$(sed -n "/<id>anypoint-repo<\/id>/,/<\/server>/ s/.*<username>\(.*\)<\/username>.*/\1/p" settings.xml)
ANYPOINT_SECRET=$(sed -n "/<id>anypoint-repo<\/id>/,/<\/server>/ s/.*<password>\(.*\)<\/password>.*/\1/p" settings.xml)
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
    <app.runtime>4.7.0</app.runtime>
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
  if [ "staging" == "main" ] || [ "staging" == "master" ]; then
    CONFIGURATION="<plugin>\n<groupId>org.mule.tools.maven</groupId>\n<artifactId>mule-maven-plugin</artifactId>\n<version>\${mule.maven.plugin.version}</version>\n<extensions>true</extensions>\n<configuration>\n<cloudHubDeployment>\n<uri>https://anypoint.mulesoft.com/</uri>\n<muleVersion>4.7.0</muleVersion>\n<connectedAppClientId>${ANYPOINT_ID}</connectedAppClientId>\n<connectedAppClientSecret>${ANYPOINT_SECRET}</connectedAppClientSecret>\n<connectedAppGrantType>client_credentials</connectedAppGrantType>\n<applicationName></applicationName>\n<businessGroup>ITMMA</businessGroup>\n<environment>product</environment>\n<workers>1</workers>\n<objectStoreV2>true</objectStoreV2>\n</cloudHubDeployment>\n</configuration>\n</plugin>"
  else
    CONFIGURATION="<plugin>\n<groupId>org.mule.tools.maven</groupId>\n<artifactId>mule-maven-plugin</artifactId>\n<version>\${mule.maven.plugin.version}</version>\n<extensions>true</extensions>\n<configuration>\n<cloudHubDeployment>\n<uri>https://anypoint.mulesoft.com/</uri>\n<muleVersion>4.7.0</muleVersion>\n<connectedAppClientId>${ANYPOINT_ID}</connectedAppClientId>\n<connectedAppClientSecret>${ANYPOINT_SECRET}</connectedAppClientSecret>\n<connectedAppGrantType>client_credentials</connectedAppGrantType>\n<applicationName>mulesoftcicd</applicationName>\n<businessGroup>ITMMA</businessGroup>\n<environment>developer</environment>\n<workers>1</workers>\n<objectStoreV2>true</objectStoreV2>\n</cloudHubDeployment>\n</configuration>\n</plugin>"
  fi
  sed -i "/<\/plugins>/i $CONFIGURATION" parent_pom.xml
  git checkout -b staging || git checkout staging
  git add parent_pom.xml update-parentPOM.sh
  git commit -m "Create and update Parent POM file"
  git push dev staging
fi
