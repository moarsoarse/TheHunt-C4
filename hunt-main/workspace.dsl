workhunt.space "The Hunt" "Сервис получения охотбилета" {
    !impliedRelationships true

    model {
        oper = person "Оператор"
        admin = person "Админ"

        consumer = softwareSystem "Потребитель" "Система, забирающая данные" "external"
        producer = softwareSystem "Поставщик" "Система, отправляющая данные" "external"
        source = softwareSystem "Источник" "Система, в которую обращатся за данными" "external"

        modeler = softwareSystem "Camunda Modeler" "Графичекий инструмент моделирования процессов" "desktop"

        hunt = softwareSystem "Охота.РФ" {
            spa = container "Клиентское приложение" "Single-Page Application" "JavaScript and D3.js" "Browser"

            webApp = container "WEB приложение" "Предоставляет статический контент и hunt.spa" "Nginx"
            redis = container "Database" "Хранилище информации о сессиях пользователей" "hunt.redis"

            gateway = container "API gateway" "REST интерфейс. Маршрутизация запросов, маппинг API Охоты с API Camunda" ""

            bpm = container "Camunda" "Сервис бизнес-процессов. Оркестратор API и сервисов" "Java, Maven" {
                api = component "Oбщедоступный API" "" "Java"
                engine =  component "Процессный движок" "Process Repository, Runtime Process Interaction, Task Management" "Java"
                dbAdapter = component "БД адаптер" "Persistence Layer" "Java, SQL"
                jober = component "Job Executor" "Выполнение асинхронных задач" "Java"
                msgAdapter = component  "AMQP коннектор" "Обеспечиват AMQP-интерфейс к брокеру" "Java, Spring bean, AMQP"
            }
            bpmDb = container "Camunda DB" "Хранение процессов и их инстансов" "PostgreSQL"

            mq = container "Брокер сообщений" "Обеспечивает асинхронное взаимодействие, шина событий" "RabbitMQ" "bus" {
                exchange = component "Обменник" "Маршрутизиурет входящие события" "AMQP" "multi"
                queue = component "Очередь" "Хранит события и сообщения для подписчиков" "AMQP, RPC" "multi"
            }

            group "Data Services" {
                metaSrv = container "Meta" "Сервис управления мета-данными" "Java"{
                    !include amqpAdapter.dsl
                }

                ticketsSrv = container "Tickets" "Сервис охотбилетов" "Java"
                registrySrv = container "MDM" "Сервис 'статичных' реестров" "Java"
            }

            group "Admin Services" {
                zip = container "Zipkin" "Cистема распределенной трассировки"
                kib = container "Kibana" "Просмотр логов микросервисов"
                graf = container "Grafana" "Построение графиков метрик"
                prom =  container "Prometheus" "Сборщик метрик с сервисов"
                consul = container "Consul" "Service Discovery & Distributed Config"
                g2c =  container "git2consul" "Синхронизирует конфиги сервисов с git"
                git =  container "GitRepo" "Репозиторий конфигураций сервисов"
                elastic = container "ElasticSearch" "Хранение логов + движок поиска"
                log =  container "Logstash" "Обработчик логов"
                filebeat =  container "Filebeat" "Сборщик логов докер-контейнеров"
            }


        }


        hunt.spa -> hunt.gateway "Вызовы API" "JSON/HTTPS"
        hunt.mq.exchange -> hunt.mq.queue "Привязка (Binding by Routink Key)" "AMQP" "msg"
        hunt.webApp -> hunt.spa "Доставляет frontend-приложение до браузера пользователя"
        hunt.gateway ->  hunt.bpm.api "Запускает процесс" "JSON/HTTPS"
        hunt.gateway -> hunt.redis "Кэширует"


        hunt.bpm.msgAdapter ->  hunt.mq.exchange "Публикует событие" "AMQP"
        hunt.bpm.engine -> hunt.bpm.jober "Оптимизирует выполнение процессов"
        hunt.bpm.dbAdapter -> hunt.bpm.bpmDb "Соединяется с БД" "JDBC"
        engine -> hunt.bpm.dbAdapter "Обращается к данным"
        engine -> hunt.bpm.msgAdapter "Использует для отправки сообщений по событиям в процессах"
        hunt.bpm.api -> hunt.bpm.dbAdapter "Query API"
        hunt.bpm.api -> hunt.bpm.engine "Services API"
        oper -> modeler "Администрирует бизнес-процессы"
        oper -> hunt.spa "Использует"
        oper -> hunt.webApp "Посещает URL системы" "HTTPS"

        admin -> hunt.zip "watches"
        admin -> hunt.kib "watches"
        admin -> hunt.graf "watches"
        admin -> hunt.consul "watches"

        hunt.kib -> hunt.elastic "get logs"
        hunt.log -> hunt.elastic "push logs"
        hunt.filebeat -> hunt.log "push logs"

        hunt.graf -> hunt.prom "get metrics"

        hunt.g2c -> hunt.consul "update config"
        hunt.g2c -> hunt.git "read config"



    }

    views {
    }

}

