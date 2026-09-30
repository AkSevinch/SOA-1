// Архитектура маркетплейса — каноническое описание модели в формате
// Structurizr DSL. Этот файл является источником для C4-диаграмм: его можно
// открыть на https://structurizr.com/help/dsl и экспортировать в PNG/PDF.
//
// Диаграммы в docs/c4/01-context.md и docs/c4/02-container.md продублированы
// на Mermaid, чтобы они рисовались прямо в README на GitHub и GitLab.

workspace "Marketplace Platform" "Проектирование архитектуры сервиса маркетплейса" {

    model {

        // ------------------------------------------------------------------
        // Акторы
        // ------------------------------------------------------------------
        buyer = person "Покупатель" "Просматривает ленту и каталог, собирает корзину, оформляет и оплачивает заказ, отслеживает доставку, оставляет отзыв"
        seller = person "Продавец" "Размещает товары, управляет ценами и остатками, обрабатывает заказы своего магазина, получает выплаты"
        moderator = person "Модератор платформы" "Проверяет каталог продавцов, разрешает споры, блокирует нарушителей"

        // ------------------------------------------------------------------
        // Внешние системы
        // ------------------------------------------------------------------
        paymentGateway = softwareSystem "Платёжный шлюз" "Внешний эквайринг: авторизация, захват и возврат средств" {
            tags "External"
        }
        carrier = softwareSystem "API служб доставки" "Создание отправлений, тарифы, трекинг статусов" {
            tags "External"
        }
        msgProviders = softwareSystem "Провайдеры уведомлений" "Доставка email, SMS и push" {
            tags "External"
        }
        idp = softwareSystem "Внешний провайдер входа" "OAuth 2.0 / OIDC, второй фактор" {
            tags "External"
        }

        // ------------------------------------------------------------------
        // Маркетплейс
        // ------------------------------------------------------------------
        marketplace = softwareSystem "Маркетплейс" "Платформа для продажи товаров продавцами: персонализированная лента, каталог, корзина, заказы, платежи, уведомления" {

            web = container "Web Portal" "SPA, TypeScript / React" "Интерфейс покупателя и кабинет продавца. Доменной логики не содержит"

            gateway = container "API Gateway" "Go, net/http" "Единая точка входа: проверка токена, rate limit, маршрутизация, единый формат ошибок"

            identity = container "Identity Service" "Go, HTTP / JSON" "Регистрация и вход, роли покупателя и продавца, профиль продавца, проверка документов"
            identityDb = container "identity_db" "PostgreSQL 16" "Пользователи, роли, профили продавцов. Доступ имеет только Identity Service" {
                tags "Database"
            }

            catalog = container "Catalog Service" "Go, HTTP / JSON" "Товары, категории, атрибуты, описания, медиа, жизненный цикл карточки товара" {
                tags "Implemented"
            }
            catalogDb = container "catalog_db" "PostgreSQL 16" "Карточки товаров, категории, атрибуты, ссылки на медиа. Доступ имеет только Catalog Service" {
                tags "Database"
            }

            search = container "Search & Personalization Service" "Go, gRPC, OpenSearch" "Поиск по каталогу, сборка персональной ленты: признаки, отбор кандидатов, ранжирование"
            searchDb = container "search_db" "PostgreSQL 16" "Профиль интересов, история показов и кликов, признаки для ранжирования" {
                tags "Database"
            }
            searchIndex = container "Индекс каталога" "OpenSearch 2" "Инвертированный индекс товаров, реплицируется из событий каталога" {
                tags "Search"
            }

            cart = container "Cart Service" "Go, HTTP / JSON" "Корзина покупателя: позиции, предварительный расчёт суммы"
            cartDb = container "cart_db" "PostgreSQL 16" "Корзины и их позиции. Доступ имеет только Cart Service" {
                tags "Database"
            }

            order = container "Order Service" "Go, HTTP / JSON" "Оформление заказа и оркестрация саги: подтверждение, оплата, отправка, компенсации"
            orderDb = container "order_db" "PostgreSQL 16" "Заказы, позиции, состояние саги, журнал переходов статусов" {
                tags "Database"
            }

            payment = container "Payment Service" "Go, HTTP / JSON" "Расчёт и учёт платежей: авторизация, захват, возврат, взаиморасчёты с продавцами"
            paymentDb = container "payment_db" "PostgreSQL 16" "Платежи, транзакции, ledger выплат продавцам. Доступ имеет только Payment Service" {
                tags "Database"
            }

            fulfillment = container "Fulfillment Service" "Go, HTTP / JSON" "Отправления: склад, передача перевозчику, трекинг, возвраты"
            fulfillmentDb = container "fulfillment_db" "PostgreSQL 16" "Отправления, события трекинга, условия возврата" {
                tags "Database"
            }

            notification = container "Notification Service" "Go, consumer" "Уведомления о статусах заказа, шаблоны, выбор канала, защита от дублей"
            notificationDb = container "notification_db" "PostgreSQL 16" "Шаблоны уведомлений, журнал отправок, признаки прочитанного" {
                tags "Database"
            }

            broker = container "Шина событий" "Kafka 3" "Обмен событиями между сервисами: транспорт асинхронных взаимодействий" {
                tags "Queue"
            }
            cache = container "Кэш" "Redis 7" "Кэш горячих выборок и результатов поиска, распределённая блокировка" {
                tags "Cache"
            }
            media = container "Хранилище медиа" "S3-совместимое" "Фотографии товаров, документы продавцов, выписки" {
                tags "ObjectStore"
            }

            // --- Доступ людей ---------------------------------------------
            buyer -> web "Покупает товары, оформляет заказ, следит за доставкой" "HTTPS"
            seller -> web "Управляет товарами, остатками и заказами магазина" "HTTPS"
            moderator -> web "Модерирует каталог и споры" "HTTPS"
            web -> idp "Вход через внешний аккаунт" "OAuth 2.0 / OIDC"

            // --- Вход в систему --------------------------------------------
            web -> gateway "Запросы к API" "REST / JSON, HTTPS"
            gateway -> identity "Проверка токена, профиль, роли" "REST / JSON, sync"
            gateway -> catalog "Каталог товаров продавца" "REST / JSON, sync"
            gateway -> search "Поиск и персонализированная лента" "gRPC, sync"
            gateway -> cart "Работа с корзиной" "REST / JSON, sync"
            gateway -> order "Оформление и статусы заказов" "REST / JSON, sync"

            // --- Владение данными -----------------------------------------
            identity -> identityDb "Чтение и запись" "SQL"
            catalog -> catalogDb "Чтение и запись" "SQL"
            search -> searchDb "Признаки и профиль интересов" "SQL"
            search -> searchIndex "Поиск и фильтрация" "HTTP"
            cart -> cartDb "Чтение и запись" "SQL"
            order -> orderDb "Чтение и запись" "SQL"
            payment -> paymentDb "Чтение и запись" "SQL"
            fulfillment -> fulfillmentDb "Чтение и запись" "SQL"
            notification -> notificationDb "Шаблоны и журнал отправок" "SQL"

            // --- Вспомогательная инфраструктура ---------------------------
            catalog -> cache "Горячие выборки каталога" "RESP"
            search -> cache "Кэш результатов ленты" "RESP"
            catalog -> media "Фото товаров, документы продавца" "S3 API, async"

            // --- Синхронные вызовы между сервисами ------------------------
            search -> catalog "Карточка товара и наличие" "REST / JSON, sync"
            search -> identity "Профиль покупателя и его интересы" "REST / JSON, sync"
            order -> catalog "Проверка цены и наличия на момент заказа" "REST / JSON, sync"
            order -> identity "Данные покупателя и продавца" "REST / JSON, sync"
            order -> cart "Списание и очистка корзины" "REST / JSON, sync"
            order -> payment "Создание, авторизация и захват платежа" "REST / JSON, sync"
            order -> fulfillment "Создание отправления" "REST / JSON, sync"

            // --- Асинхронные взаимодействия --------------------------------
            catalog -> broker "product.created / updated / removed" "Kafka, async"
            order -> broker "order.created / paid / closed" "Kafka, async"
            payment -> broker "payment.captured / payment.refunded" "Kafka, async"
            fulfillment -> broker "shipment.created / delivered" "Kafka, async"
            broker -> search "Перестраивает индекс и признаки для ленты" "Kafka, async"
            broker -> payment "Заказ оплачен: авторизация и захват" "Kafka, async"
            broker -> fulfillment "Заказ оплачен: создать отправление" "Kafka, async"
            broker -> notification "Изменения статусов заказа, оплаты, доставки" "Kafka, async"
            broker -> catalog "Снятие товара с продажи при нулевом остатке" "Kafka, async"

            // --- Внешние интеграции ----------------------------------------
            payment -> paymentGateway "Авторизация, захват, возврат" "HTTPS, sync"
            fulfillment -> carrier "Создание отправления и трекинг" "HTTPS, sync"
            notification -> msgProviders "Отправка email, SMS, push" "HTTPS / SMTP, async"
        }

        // ------------------------------------------------------------------
        // Допущения
        // ------------------------------------------------------------------
        !docs "Показан выбранный вариант декомпозиции — микросервисы по доменам. Сравнение с модульным монолитом и крупнозернистыми сервисами приведено в README.md"
    }

    // ----------------------------------------------------------------------
    // Представления
    // ----------------------------------------------------------------------
    views {

        systemContext marketplace "SystemContext" {
            title "C4 Level 1 — Контекст платформы-маркетплейса"
            include *
            autolayout lr
        }

        container marketplace "Containers" {
            title "C4 Level 2 — Контейнерная диаграмра маркетплейса"
            include *
            autolayout topDown
        }

        styles {
            element "Person" {
                shape person
                background #c8e6c9
                color #0b2e0f
            }
            element "External" {
                background #eceff1
                color #263238
            }
            element "Implemented" {
                background #1168b3
                color #ffffff
            }
            element "Database" {
                shape cylinder
                background #fff3e0
                color #4e342e
            }
            element "Queue" {
                shape pipe
                background #6c4ba6
                color #ffffff
            }
            element "Cache" {
                shape cylinder
                background #fffde7
                color #827717
            }
            element "ObjectStore" {
                shape folder
                background #e0f7fa
                color #006064
            }
            element "Search" {
                background #e8eaf6
                color #283593
            }
        }
    }
}
