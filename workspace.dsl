workspace "The Hunt" "Сервис получения охотбилета" {
    !impliedRelationships true
    !identifiers hierarchical

    #Брэндбук
    !constant GREY "#8D98A7"
    !constant CYAN "#9DDADF"
    !constant B_BASE "#003DA7"
    !constant B_DARK "#3B69B7"
    !constant B_NORM "#94AAD1"
    !constant O_BASE "#F7642C"
    !constant O_DARK "#F77E25"
    !constant O_NORM "#F8981D"
    !constant O_THIN "#F8C684"

    model {

        #Люди
        anal = person "Аналитик" "Low-code разработчик\nНастраивает Систему" "anal"
        oper = person "Оператор" "Бизнес-пользователь Системы\nУполномоченное лицо" "oper"
        admin = person "DevOps" "Системный администратор\nПоддерживает Систему" "adm, devops"
        hunter = person "Охотник" "Любит убивать\nбеспомощных тварей" "external, hunter"
        seq = person "Администратор безопасности" "Управление пользователями,\nполитиками доступа" "seq"

        modeler = softwareSystem "Camunda Modeler" "Графичекий инструмент моделирования процессов" "desktop, camunda"

        #Системы
        egisso = softwareSystem "ЕГИССО" "Данные о социальном статусе" "external,egisso"
        consumer = softwareSystem "Потребитель" "Система, забирающая данные" "external, dummy"
        
        group "МВД" {
            justice = softwareSystem "ГАС «Правосудие»" "Данные о судимости" "external,mvd,justice"
            passport = softwareSystem "АС «Российский Паспорт»" "Паспортные данные" "external,mvd,passport"
        }
        smev = softwareSystem "СМЭВ 3" "Система межведомственного электронного взаимодействия" "external, smev"
        epgu = softwareSystem "Госуслуги" "" "external, epgu"
        esia = softwareSystem "ЕСИА" "Единая система идентификации и аутентификации" "external, esia"
        ldap = softwareSystem "LDAP-каталог" "" "dummy,ldap"

        hunt = softwareSystem "Охотуправление" "" "Hunt"{
            group "Front-End" {
                webApp = container "WEB сервер" "Предоставляет статический контент и SPA" "Nginx" "tool"

                spa = container "Клиентское приложение" "Single-Page Application" "JavaScript and D3.js" "browser" 
                camAdmin = container "Camunda Admin" "" "AngularJS" "browser,tool"
                cockpit = container "Cockpit" "Деплой и мониторинг бизнес-процессов" "AngularJS" "browser,tool"
                tasklist = container "Tasklist" "Работа с пользовательскими задачами (User Task)" "AngularJS" "browser,tool"
                keycloakJS = container "Keycloak UI" "Доступ к управлению настройками IAM" "" "browser,tool"
            }
            
            keycloak = container "Keycloak" "Аутентификация и авторизация пользователей" "Java" "iam, tool"{
                realm = component "Realm" "Области безопасности позволяют задавать индивидуальные настройки для подключенных систем"  
                api = component "REST API" "" "REST" "interface"
                dbInt = component "Storage connector" "" "JPA" "connector"
                fim = component "User Federation" "Федеративная идентификация" " SAML, OpenID Connect, OAuth2" "connector"
                sso = component "SSO" "" "ODIC, SAML" "interface"
                broker = component "Identity Broker" "" "" "connector"
                esia = component "Провайдер ЕСИА" "Сертификационный шлюз" "SAML2.0, HTTPS" "connector, plugin"
            }
            keycloakDB = container "User Storage" "Хранение пользователей, политик, релмов и пр." "PostreSQL" "db"
            
            service = container "Внутренний сервис" "Любой сервис системы" "" "dummy"

            gateway = container "API gateway" "REST интерфейс. Маршрутизация запросов" "Java"
            redis = container "Database" "Хранилище информации о сессиях пользователей" "Redis" "db"

            bpm = container "Camunda" "Сервис бизнес-процессов. Оркестратор API и сервисов" "Java, Maven" "camunda" {
                api = component "Oбщедоступный API" "" "Java" "interface"
                engine =  component "Процессный движок" "Process Repository, Runtime Process Interaction, Task Management" "Java"
                dbAdapter = component "БД адаптер" "Persistence Layer" "Java, SQL" "connector"
                jober = component "Job Executor" "Выполнение асинхронных задач" "Java"
                msgAdapter = component  "AMQP коннектор" "" "Java, Spring bean, AMQP" "connector, plugin" 
                httpConnector = component "HTTP коннектор" "Синхронные ServiceTask" "connector"
            }
            bpmClient = container "Camunda client" "Запускает выполнение процессов" "Java"
            bpmDb = container "Camunda DB" "Хранение процессов и их инстансов" "PostgreSQL" "db, sql"

            mq = container "Брокер сообщений" "Обеспечивает асинхронное взаимодействие, шина событий" "RabbitMQ" "bus" {
                exchange = component "Обменник" "Маршрутизиурет входящие события" "AMQP" "multi, interface" 
                queue = component "Очередь" "Хранит события и сообщения для подписчиков" "AMQP, RPC" "multi, interface"
            }

            smevAdp = container "Адаптер СМЭВ-3" "Реализует интерфейсы взаимодействия со СМЭВ" "tool, connector, smev" {
                service = component "Web-сервис"  "Взаимодействие по SOAP или REST API протоколу" "REST/SOAP" "interface"
                mqInt = component "AMQP-интерфейс" "Взаимодействие через брокер сообщений Rabbit MQ" "AMQP" "connector"
                client = component "СМЭВ Gateway" "Взаимодействие со СМЭВ"  "" "connector"
                ecp = component "ЭЦП"
                s3Int = component "Адаптер к S3-хранилищу" "Прикрепление файлов к запросу" "" "connector"
                dbInt = component "Адаптер к БД" "" "connector"
                
            }
            smevAdpDb = container "БД адаптера СМЭВ" "Хранение отправленных и полученных запросов" "PostgreSQL" "db, sql"



            group "Microservices" {
                metaSrv = container "Meta" "Сервис управления мета-данными" "Java" "microservice,java"{
                    api = component "REST API" "API сервиса управления мета-данными" "Java"
                    extTaskClient = component "External Task Client" "Забирает (fetch/lock) топики из Camunda, реализует интерфейсы handle() и complete()"
                    !include common/amqpAdapter.dsl
                }

                ticketsSrv = container "Tickets" "Сервис охотбилетов" "Java" "microservice"{
                    api = component "REST API" "API сервиса охотбилетов" "Java"
                    extTaskClient = component "External Task Client" "Забирает (fetch/lock) топики из Camunda, реализует интерфейсы handle() и complete()"
                    !include common/amqpAdapter.dsl
                }
                registrySrv = container "Registry" "Сервис реестров" "Java" "microservice"{
                    api = component "REST API" "API сервиса реестров" "Java"
                    extTaskClient = component "External Task Client" "Забирает (fetch/lock) топики из Camunda, реализует интерфейсы handle() и complete()"
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

        #Взаимодействия пользователей
        anal -> modeler "Разрабатывает бизнес-процессы"
        anal -> hunt.cockpit "Внедряет и отслеживает бизнес-процессы"

        oper -> hunt.spa "Использует"
        oper -> hunt.tasklist "Выполняет"

               
        admin -> hunt.camAdmin "Настраивает" 
        admin -> hunt.zip "Настраивает"
        admin -> hunt.kib "Мониторит"
        admin -> hunt.graf "Мониторит"
        admin -> hunt.consul "Настраивает"

        hunter -> epgu "Использует"

        seq -> hunt.keycloakJS "Управляет"

        #Внешние взаимодействия
        hunt.bpm.httpConnector -> egisso "Запрос статуса" "HTTP"
        consumer -> hunt.mq.queue  "Подписка на события" "AMQP|RPC"
        hunt.bpm.httpConnector -> passport "Проверка данных" "HTTP"
        hunt.bpm.httpConnector -> justice "Запрос данных" "HTTP"
        consumer -> hunt.bpm.engine "Подписка на External Task топик" "HTTP"
        hunt.smevAdp.client -> smev "Межведомственное взаимодействие" "HTTP"
        smev -> epgu "Трансляция запросов" "" "unknown"

        #Фронты
        hunt.spa -> hunt.gateway "Вызовы API" "JSON/HTTPS"
        hunt.webApp -> hunt.spa "Доставляет frontend-приложение до браузера пользователя"
        hunt.webApp -> hunt.camAdmin "Доставляет frontend-приложение до браузера пользователя"
        hunt.webApp -> hunt.cockpit "Доставляет frontend-приложение до браузера пользователя"
        hunt.webApp -> hunt.tasklist "Доставляет frontend-приложение до браузера пользователя"

        #IAM
        hunt -> esia "Логин" "SAML/HTTPS"
        hunt.gateway -> hunt.keycloak.api "Запрос JWT" "HTTP"
        hunt.keycloakJS -> hunt.keycloak.api "" "HTTPS"
        hunt.keycloak.api -> hunt.gateway "Токен|Assertion"
        hunt.keycloak.api -> hunt.keycloak.realm 
        hunt.keycloak.realm -> hunt.keycloak.dbInt
        hunt.keycloak.dbInt -> hunt.keycloakDB "JDBC"
        hunt.keycloak.fim -> hunt.keycloak.dbInt
        hunt.keycloak.broker -> esia "SAML"        
        hunt.keycloak.realm -> hunt.keycloak.fim
        hunt.keycloak.broker -> hunt.keycloak.esia "применяет"
        hunt.keycloak.realm -> hunt.keycloak.broker
        hunt.keycloak.sso -> hunt.keycloak.broker
        #Разобрать!!!!!!
        hunt.smevAdp.dbInt -> hunt.smevAdpDb "" "JDBC"

        
        


        hunt.gateway ->  hunt.bpmClient "Операции, запускающие процесс" "JSON/HTTP"
        hunt.bpmClient ->  hunt.bpm.api "Запускает процесс" "JSON/HTTP"
        hunt.gateway ->  hunt.metaSrv.api  "" "JSON/HTTP"
        hunt.gateway ->  hunt.ticketsSrv.api  "" "JSON/HTTP"
        hunt.gateway ->  hunt.registrySrv.api  "" "JSON/HTTP"

        hunt.gateway -> hunt.redis "Кэширует"

        hunt.mq.exchange -> hunt.mq.queue "Привязка (Binding by Routink Key)" "AMQP" "msg"
        hunt.bpm.msgAdapter ->  hunt.mq.exchange "Публикует событие" "AMQP"
        hunt.bpmClient ->  hunt.mq.queue "Забирает событие" "AMQP|RPC"
        

        hunt.bpm.httpConnector -> hunt.metaSrv.api  "" "JSON/HTTP" "deprecated"
        hunt.bpm.httpConnector -> hunt.ticketsSrv.api  "" "JSON/HTTP" "deprecated"
        hunt.bpm.httpConnector -> hunt.registrySrv.api  "" "JSON/HTTP" "deprecated"    
        hunt.bpm.httpConnector -> hunt.smevAdp.service "Запросы к СМЭВ (send, get)" "XML/REST|SOAP"

        

        
        hunt.metaSrv.extTaskClient -> hunt.bpm.engine "Подписка на External Task топик" "HTTP"
        hunt.ticketsSrv.extTaskClient -> hunt.bpm.engine "Подписка на External Task топик" "HTTP"
        hunt.registrySrv.extTaskClient -> hunt.bpm.engine "Подписка на External Task топик" "HTTP"

        hunt.bpm.engine -> hunt.bpm.jober "Оптимизирует выполнение процессов"
        hunt.bpm.dbAdapter -> hunt.bpmDb "Соединяется с БД" "JDBC"
        hunt.bpm.engine -> hunt.bpm.dbAdapter "Обращается к данным"
        hunt.bpm.engine -> hunt.bpm.msgAdapter "Использует для отправки сообщений по событиям в процессах"
        hunt.bpm.engine -> hunt.bpm.httpConnector "Использует для REST-запросов в процессах"
        hunt.bpm.api -> hunt.bpm.dbAdapter "Query API"
        hunt.bpm.api -> hunt.bpm.engine "Services API"




        hunt.kib -> hunt.elastic "get logs"
        hunt.log -> hunt.elastic "push logs"
        hunt.filebeat -> hunt.log "push logs"

        hunt.graf -> hunt.prom "get metrics"

        hunt.g2c -> hunt.consul "update config"
        hunt.g2c -> hunt.git "read config"

    }

    views {
        systemLandscape  landscape "Системный ландшафт" {
            include *            
            exclude "element.tag==dummy"
            exclude "element.tag==deprecated"
            exclude "relationship.tag==deprecated"
            exclude "*->hunt"
        }
        systemContext hunt "sef" "Контекст системы"{
            include *  
            exclude "element.tag==dummy"
            exclude "element.tag==deprecated"
            exclude "relationship.tag==deprecated"
            exclude "*->hunt"
        }
        container hunt "huntArchitecture" "Общая архитектура системы"{
            default
            include *
            exclude "element.tag==dummy"
            exclude "element.tag==adm"
            exclude "element.tag==deprecated"
            exclude "relationship.tag==deprecated"
            exclude "*->hunt"
            exclude "element.tag==db"
            exclude "element.tag==bus"
        }
        component hunt.bpm "Camunda"{
            include *
            exclude "element.tag==deprecated"
            exclude "relationship.tag==deprecated"
        }
        component hunt.keycloak "Keycloak" "Подсистема аутентификации и авторизации"{
            include *
            include seq
            exclude "element.tag==deprecated"
            exclude "relationship.tag==deprecated"
        }
        #Стили
        branding {
            logo /icons/fox-horizontal-logo.png
            font Bodoni "https://xn--b1agj5adjn3a5a.xn--p1ai/fonts/besplatnye-shrifty/bodoni-cyrillic/"
        }

        terminology {
            person "Пользователь"
            softwareSystem "Информационная система"
            container "Сервис"
            component "Компонент"
            #deploymentNode 
            #infrastructureNode 
            relationship "Взаимодействие"
        }

        styles {
            relationship "Relationship"{
                thickness 3
                style solid
                fontSize 20
            }
            relationship "unknown" {
                thickness 1
                style dotted
            }
            element "Element" {
                color white
                strokeWidth 8
            }
            element "dummy"{
                strokeWidth 3
                color ${GREY}
            }
            element "Group" {                
                fontSize 60
                color ${CYAN}
                strokeWidth 8
            }
            element "Person" {
                width 350
                color black
                shape Person
                stroke ${O_NORM}
                background white
                strokeWidth 5
                fontSize 17
                metadata false
            }
           
            element "Software System" {
                color black
                stroke ${B_BASE}
                shape RoundedBox
                background white
            }
            
            element "Container" {
                background ${B_DARK}
                shape RoundedBox
            }
            element "Component"{
                shape Component
                background ${B_NORM}
                height 250
            }
            element "desktop"{
                shape Window
            }
            element "tool"{
                border solid
                stroke ${O_THIN}
                strokeWidth 6
            }
            element "bus" {
                shape Pipe
                height 200
                width 500
                background ${GREY}
            }
            element "db" {
                shape Cylinder
                width 350
                height 300
                background ${GREY}
            }
            element "interface" {
                shape Circle
                width 300
            }
            element "plugin" {
                stroke ${O_BASE}
                border dashed
                strokeWidth 6
                shape ellipse
                fontSize 16
                width 400
                height 100
                metadata false
            }
            element "microservice" {
                shape Hexagon
                width 350
            }
            element "browser" {
                shape WebBrowser            
            }
            #Custom объекты
            element "hunter" {
                icon "/icons/hunter.png"
            }
            element "devops" {
                icon "/icons/devops.png"
            }
            element "oper" {
                icon "/icons/oper.png"
            }
            element "seq" {
                icon "/icons/seq.png"
            }
            element "anal" {
                icon "/icons/anal.png"
            }
            #Продукты            
            element "camunda" {
                icon "/icons/camunda.png"
            }
            element "Hunt"{
                stroke ${O_BASE}
                icon "/icons/hunt-logo.png"
            }
            element "justice" {
                icon "/icons/justice.jpg"
            }
            element "passport" {
                icon "/icons/passport.png"
            }
            element "Group:МВД" {
                icon "/icons/mvd.png"
            }
            element "egisso" {
                icon "/icons/egisso.png"
            }
            element "esia" {
                icon "/icons/esia.png"
            }
            element "epgu" {
                icon "/icons/epgu.jpg"
            }
            element "smev" {
                icon "/icons/smev.png"
            }
        }
    }

}
