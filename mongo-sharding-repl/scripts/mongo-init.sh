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
docker compose exec -T shard1-primary mongosh --port 27018 --quiet <<EOF
rs.initiate({
    _id : "rs1",
    members: [
        { _id : 0, host : "shard1-primary:27018" },
        { _id : 1, host : "shard1-secondary1:27019" },
        { _id : 2, host : "shard1-secondary2:27020" }
    ]
});
EOF

###
# Инициализируем Shard2
###

sleep 5
docker compose exec -T shard2-primary mongosh --port 27021 --quiet <<EOF
rs.initiate({
    _id : "rs2",
    members: [
        { _id : 0, host : "shard2-primary:27021" },
        { _id : 1, host : "shard2-secondary1:27022" },
        { _id : 2, host : "shard2-secondary2:27023" }
    ]
});
EOF

###
# Добавление шардов в кластер
###

sleep 5
docker compose exec -T mongos_router mongosh --port 27024 --quiet <<EOF
sh.addShard("rs1/shard1-primary:27018,shard1-secondary1:27019,shard1-secondary2:27020");
sh.addShard("rs2/shard2-primary:27021,shard2-secondary1:27022,shard2-secondary2:27023");
EOF

###
# Заполняем данными и проверка данных в бд
###

sleep 5
docker compose exec -T mongos_router mongosh --port 27024 --quiet <<EOF
use somedb;
sh.enableSharding("somedb");
db.createCollection("helloDoc")
db.helloDoc.createIndex({ "name": "hashed" });
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });

for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
EOF

###
# Проверка 1 шарда с репликами
###

sleep 5
docker compose exec -T shard1-primary mongosh --port 27018 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

sleep 5
docker compose exec -T shard1-secondary1 mongosh --port 27019 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

sleep 5
docker compose exec -T shard1-secondary2 mongosh --port 27020 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF


###
# Проверка 2 шарда с репликами
###

sleep 5
docker compose exec -T shard2-primary mongosh --port 27021 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

sleep 5
docker compose exec -T shard2-secondary1 mongosh --port 27022 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

sleep 5
docker compose exec -T shard2-secondary2 mongosh --port 27023 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

