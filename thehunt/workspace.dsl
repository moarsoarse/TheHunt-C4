workspace "The Hunt" "Сервис получения охотбилета" {
    !impliedRelationships true
    !identifiers hierarchical

    model {
        oper = person "Оператор"
        admin = person "Админ" "" "adm"

        consumer = softwareSystem "Потребитель" "Система, забирающая данные" "external"
        producer = softwareSystem "Поставщик" "Система, отправляющая данные" "external"
        source = softwareSystem "Источник" "Система, в которую обращатся за данными" "external"

        modeler = softwareSystem "Camunda Modeler" "Графичекий инструмент моделирования процессов" "desktop"

        hunt = softwareSystem "Охота.РФ" {
            spa = container "Клиентское приложение" "Single-Page Application" "JavaScript and D3.js" "Browser"

            webApp = container "WEB приложение" "Предоставляет статический контент и SPA" "Nginx"
            redis = container "Database" "Хранилище информации о сессиях пользователей" "Redis"

            gateway = container "API gateway" "REST интерфейс. Маршрутизация запросов" "Java"

            bpmClient = container "Camunda client" "Запускает выполнение процессов" "Java"

            bpm = container "Camunda" "Сервис бизнес-процессов. Оркестратор API и сервисов" "Java, Maven" {
                api = component "Oбщедоступный API" "" "Java"
                engine =  component "Процессный движок" "Process Repository, Runtime Process Interaction, Task Management" "Java"
                dbAdapter = component "БД адаптер" "Persistence Layer" "Java, SQL"
                jober = component "Job Executor" "Выполнение асинхронных задач" "Java"
                msgAdapter = component  "AMQP коннектор" "Обеспечиват AMQP-интерфейс к брокеру" "Java, Spring bean, AMQP"
                httpConnector = component "HTTP коннектор" "HTTP-интерфейс External tasks"
            }
            bpmDb = container "Camunda DB" "Хранение процессов и их инстансов" "PostgreSQL"

            mq = container "Брокер сообщений" "Обеспечивает асинхронное взаимодействие, шина событий" "RabbitMQ" "bus" {
                exchange = component "Обменник" "Маршрутизиурет входящие события" "AMQP" "multi"
                queue = component "Очередь" "Хранит события и сообщения для подписчиков" "AMQP, RPC" "multi"
            }

            group "Microservices" {
                metaSrv = container "Meta" "Сервис управления мета-данными" "Java"{
                    api = component "REST API" "API сервиса управления мета-данными" "Java"
                    !include common/amqpAdapter.dsl
                }

                ticketsSrv = container "Tickets" "Сервис охотбилетов" "Java"{
                    api = component "REST API" "API сервиса охотбилетов" "Java"
                    !include common/amqpAdapter.dsl
                }
                registrySrv = container "Registry" "Сервис реестров" "Java"{
                    api = component "REST API" "API сервиса реестров" "Java"
                    !include common/amqpAdapter.dsl
                }
            }

            group "Admin Services" {
                zip = container "Zipkin" "Cистема распределенной трассировки" "" "adm"
                kib = container "Kibana" "Просмотр логов микросервисов" "" "adm"
                graf = container "Grafana" "Построение графиков метрик" "" "adm"
                prom =  container "Prometheus" "Сборщик метрик с сервисов" "" "adm"
                consul = container "Consul" "Service Discovery & Distributed Config" "" "adm"
                g2c =  container "git2consul" "Синхронизирует конфиги сервисов с git" "" "adm"
                git =  container "GitRepo" "Репозиторий конфигураций сервисов" "" "adm"
                elastic = container "ElasticSearch" "Хранение логов + движок поиска" "" "adm"
                log =  container "Logstash" "Обработчик логов" "" "adm"
                filebeat =  container "Filebeat" "Сборщик логов докер-контейнеров" "" "adm"
            }


        }


        hunt.spa -> hunt.gateway "Вызовы API" "JSON/HTTPS"

        hunt.webApp -> hunt.spa "Доставляет frontend-приложение до браузера пользователя"


        hunt.gateway ->  hunt.bpmClient "Операции, запускающие процесс" "JSON/HTTP"
        hunt.bpmClient ->  hunt.bpm.api "Запускает процесс" "JSON/HTTP"
        hunt.gateway ->  hunt.metaSrv.api  "" "JSON/HTTP"
        hunt.gateway ->  hunt.ticketsSrv.api  "" "JSON/HTTP"
        hunt.gateway ->  hunt.registrySrv.api  "" "JSON/HTTP"

        hunt.gateway -> hunt.redis "Кэширует"

        hunt.mq.exchange -> hunt.mq.queue "Привязка (Binding by Routink Key)" "AMQP" "msg"
        hunt.bpm.msgAdapter ->  hunt.mq.exchange "Публикует событие" "AMQP"
        hunt.bpmClient ->  hunt.mq.queue "Забирает событие" "AMQP, RPC"

        hunt.bpm.httpConnector -> hunt.metaSrv.api  "" "JSON/HTTP"
        hunt.bpm.httpConnector -> hunt.ticketsSrv.api  "" "JSON/HTTP"
        hunt.bpm.httpConnector -> hunt.registrySrv.api  "" "JSON/HTTP"

        hunt.bpm.engine -> hunt.bpm.jober "Оптимизирует выполнение процессов"
        hunt.bpm.dbAdapter -> hunt.bpmDb "Соединяется с БД" "JDBC"
        hunt.bpm.engine -> hunt.bpm.dbAdapter "Обращается к данным"
        hunt.bpm.engine -> hunt.bpm.msgAdapter "Использует для отправки сообщений по событиям в процессах"
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
        systemContext hunt "huntMainView" {
            autoLayout tb
            include *
            exclude "element.tag==adm"
        }
        container hunt "huntArchitecture" {
            default
            include *
            exclude "element.tag==adm"
        }
    }

}
