$rootDir = (get-item $PSScriptRoot).Parent.FullName
$containerName = "tomcat"

docker container rm "$containerName" --force 2>&1 | Out-Null

docker container run `
  --name "$containerName" `
  --publish 8080:8080 `
  --publish 8081:8081 `
  --volume "$rootDir\app:/usr/local/tomcat/webapps/app" `
  --volume "$rootDir\.ssl:/usr/local/tomcat/ssl/" `
  --volume "$rootDir\.tomcat\server.xml:/usr/local/tomcat/conf/server.xml" `
  --env-file $rootDir\.env `
  --detach `
  tomcat:9.0.54
