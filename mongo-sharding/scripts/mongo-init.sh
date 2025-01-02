#!/bin/bash

###
# Инициализируем configSrv
###

docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({_id : 'config_server',configsvr:true,members: [{ _id : 0, host : 'configSrv:27017' }]});
EOF

###
# Инициализируем Shard1
###

sleep 5
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({_id : "shard1",members: [{ _id : 0, host : "shard1:27018" }]});
EOF

###
# Инициализируем Shard2
###

sleep 5
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({_id : "shard2",members: [{ _id : 0, host : "shard2:27019" }]});
EOF

###
# Добавление шардов в кластер
###

sleep 5
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
EOF

###
# Заполняем данными и проверка данных в бд
###

sleep 5
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
use somedb;
sh.enableSharding("somedb");
db.createCollection("helloDoc")
db.helloDoc.createIndex({ "name": "hashed" });
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });

for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
EOF

###
# Проверка 1 шарда
###

sleep 5
echo -e "\n\nПроверяем данные в Shard1..."
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

###
# Проверка 2 шарда
###

sleep 5
echo -e "\n\nПроверяем данные в Shard2..."
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF


