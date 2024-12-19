#!/bin/bash
PARENT_GROUP_ID=$(grep -oPm1 "(?<=<groupId>)[^<]+" parent_pom.xml)
PARENT_ARTIFACT_ID=$(grep -oPm1 "(?<=<artifactId>)[^<]+" parent_pom.xml)
PARENT_VERSION=$(grep -oPm1 "(?<=<version>)[^<]+" parent_pom.xml)
PARENT_EXISTS=$(grep -c "<parent>" pom.xml)
if [ "$PARENT_EXISTS" -eq 0 ]; then
  PARENT_INCLUSION="<parent>\n<groupId>${PARENT_GROUP_ID}</groupId>\n<artifactId>${PARENT_ARTIFACT_ID}</artifactId>\n<version>${PARENT_VERSION}</version>\n<relativePath>./parent_pom.xml</relativePath>\n</parent>"
  sed -i "/<\/project>/i $PARENT_INCLUSION" pom.xml
  org_id=$(curl -X GET "https://anypoint.mulesoft.com/accounts/api/me" -H "Authorization: Bearer 8a254ead-e45f-4711-b2d9-d2b9800675b2" -H "Content-Type: application/json" | jq -r ".user.organization.id")
  sed -i "0,/<groupId>[^<]*<\/groupId>/s|<groupId>[^<]*</groupId>|<groupId>$org_id</groupId>|" pom.xml
  sed -i "0,/<version>[^<]*<\/version>/s|<version>[^<]*</version>|<version>1.0.0</version>|" pom.xml
  sed -i "/<\/repositories>/i \<repository>\\<id>Repository</id>\\<name>Private Exchange repository</name>\\<url>https://maven.anypoint.mulesoft.com/api/v3/organizations/\${project.groupId}/maven</url>\\<layout>default</layout>\\</repository>" pom.xml
  sed -i "/<\/repositories>/i \<repository>\\<id>nexus</id>\\<url>https://wanted-ostrich-singularly.ngrok-free.app/repository/mule4-jars/</url>\\<releases>\\<enabled>true</enabled>\\<updatePolicy>never</updatePolicy>\\</releases>\\<snapshots>\\<enabled>false</enabled>\\</snapshots>\\</repository>" pom.xml
  sed -i "/<\/project>/i \<distributionManagement>\\<repository>\\<id>Repository</id>\\<url>https://maven.anypoint.mulesoft.com/api/v3/organizations/\${project.groupId}/maven</url>\\</repository>\\</distributionManagement>" pom.xml
  git checkout -b developer || git checkout developer
  git add pom.xml
  git add update-projectPOM.sh
  git commit -m "Update project POM to include Parent POM"
  git push dev developer
fi
