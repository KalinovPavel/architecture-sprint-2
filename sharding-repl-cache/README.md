# pymongo-api

## Как запустить

Запускаем mongodb и приложение

```shell
docker compose up -d
```

Удалить докер контейнеры

```shell
docker compose down -v
```

Заполняем mongodb данными

```shell
./scripts/mongo-init.sh
```

http://localhost:8080
