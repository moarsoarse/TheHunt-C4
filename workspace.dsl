workspace "The Hunt" "Сервис получения охотбилета" {

    model {
        hunter = person "Охотник"
        admin = person "Админ"

        mvd = softwareSystem "МВД"
        fns = softwareSystem "ФНС"
        sso = softwareSystem "ЕГИССО"
        fias = softwareSystem "ФИАС"

        theHunt = softwareSystem "Охота.РФ" {
            web = container "WEB-сервер" "Стат. контент и клиентское прилижение" "Nginx"
            gateway = container "API Gateway" "Общий интерфейс" "Java+SpringBoot"

            group "Data Services" {
                hunters = container "Hunters" "Сервис базы охотников" "Java"
                tickets = container "Tickets" "Сервис охотбилетов" "Java"
                mdm = container "MDM" "Сервис 'статичных' реестров" "Java"
            }

            bpm = container "BPM" "Движок бизнес-процессов" "Camunda"
            bus = container "Bus" "Интеграционный сервис"

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

        hunter -> web "uses"

        admin -> zip "watches"
        admin -> kib "watches"
        admin -> graf "watches"
        admin -> consul "watches"

        kib -> elastic "get logs"
        log -> elastic "push logs"
        filebeat -> log "push logs"

        graf -> prom "get metrics"

        g2c -> consul "update config"
        g2c -> git "read config"

        web -> gateway "redirects"
        gateway -> hunters "redirects"
        gateway -> tickets "redirects"
        gateway -> mdm "redirects"

        hunters -> bpm "triggers"
        tickets -> bpm "triggers"
        mdm -> bpm "triggers"

        bpm -> hunters "calls"
        bpm -> tickets "calls"
        bpm -> mdm "calls"
        bpm -> bus "calls"

        bpm -> mvd "checks"
        bpm -> sso "checks"
        bpm -> fns "checks"

        bus -> mdm "updates"
        bus -> fias "calls"

    }

    views {
    }

}