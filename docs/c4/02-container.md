# C4 Level 2 — Container Diagram

| Правило нотации C4 | Как применено здесь |
|---|---|
| Контейнер = то, что **запускается отдельно** | Сервисы, базы данных, брокер, кэш, объектное хранилище, веб-клиент. Внутренние пакеты Go-сервиса сюда **не** попадают — это уровень 3 |
| У каждого контейнера указаны **имя, технология и назначение** | Все три поля заполнены у каждого элемента |
| У каждой связи указана **технология** | Подпись на стрелке: `REST/JSON`, `gRPC`, `Kafka`, `SQL`, `HTTPS` |
| Границы показаны явно | Пунктирная рамка `System_Boundary` — всё, что является маркетплейсом |
| Внешние системы не смешаны со своими | Платёжный шлюз, API доставки, провайдеры уведомлений и входа вынесены наружу и помечены как внешние |



![C4 Level 2 — контейнерная диаграмма маркетплейса](images/02-container.svg)

<details>
<summary>Mermaid-исходник диаграммы</summary>

```mermaid
C4Container
    title C4 Level 2 — Контейнерная диаграмра маркетплейса

    Person(buyer, "Покупатель", "Браузер или мобильное приложение")
    Person(seller, "Продавец", "Личный кабинет магазина")
    Person(moderator, "Модератор", "Проверка каталога, споры, блокировки")

    System_Ext(paymentGateway, "Платёжный шлюз", "Внешний эквайринг: авторизация, захват, возврат")
    System_Ext(carrier, "API служб доставки", "Отправления, тарифы, трекинг")
    System_Ext(msgProviders, "Провайдеры уведомлений", "Email, SMS, push")
    System_Ext(idp, "Внешний провайдер входа", "OAuth 2.0 / OIDC, второй фактор")

    System_Boundary(marketplace, "Маркетплейс") {

        Container(web, "Web Portal", "SPA, TypeScript / React", "Интерфейс покупателя и кабинет продавца. Только представление, доменной логики не содержит")
        Container(gateway, "API Gateway", "Go, net/http", "Единая точка входа: проверка токена, rate limit, маршрутизация запросов к сервисам, единый формат ошибок")

        Container(identity, "Identity Service", "Go, HTTP / JSON", "Регистрация и вход, роли покупателя и продавца, профиль продавца, проверка документов")
        ContainerDb(identityDb, "identity_db", "PostgreSQL 16", "Пользователи, роли, профиль продавца, документы, адресная книга, избранное. Доступ имеет только Identity Service")

        Container(catalog, "Catalog Service", "Go, HTTP / JSON", "Товары, категории, атрибуты, описания, медиа, жизненный цикл карточки: черновик → на проверке → опубликован")
        ContainerDb(catalogDb, "catalog_db", "PostgreSQL 16", "Карточки товаров, категории, атрибуты, ссылки на медиа, отзывы и оценки. Доступ имеет только Catalog Service")

        Container(search, "Search & Personalization Service", "Go, gRPC, OpenSearch", "Поиск по каталогу, сборка персональной ленты: признаки поведения, отбор кандидатов, ранжирование")
        ContainerDb(searchDb, "search_db", "PostgreSQL 16", "Профиль интересов пользователя, история показов и кликов, признаки для ранжирования. Доступ имеет только Search & Personalization")
        Container(searchIndex, "Индекс каталога", "OpenSearch 2", "Инвертированный индекс товаров, реплицируется из событий каталога")

        Container(cart, "Cart Service", "Go, HTTP / JSON", "Корзина покупателя, добавление и удаление позиций, предварительный расчёт суммы")
        ContainerDb(cartDb, "cart_db", "PostgreSQL 16", "Корзины и их позиции. Доступ имеет только Cart Service")

        Container(order, "Order Service", "Go, HTTP / JSON", "Оформление заказа и оркестрация саги: подтверждение, оплата, отправка, компенсации. Единственный владелец жизненного цикла заказа")
        ContainerDb(orderDb, "order_db", "PostgreSQL 16", "Заказы, позиции заказа, состояние саги, журнал переходов статусов. Доступ имеет только Order Service")

        Container(payment, "Payment Service", "Go, HTTP / JSON", "Расчёт и учёт платежей: авторизация, захват, возврат, взаиморасчёты с продавцами и комиссия платформы")
        ContainerDb(paymentDb, "payment_db", "PostgreSQL 16", "Платежи, транзакции, ledger выплат продавцам. Доступ имеет только Payment Service")

        Container(fulfillment, "Fulfillment Service", "Go, HTTP / JSON", "Отправления: выбор склада, передача перевозчику, трекинг, приём возврата")
        ContainerDb(fulfillmentDb, "fulfillment_db", "PostgreSQL 16", "Отправления, события трекинга, условия возврата. Доступ имеет только Fulfillment Service")

        Container(notification, "Notification Service", "Go, consumer", "Уведомления о статусах заказа, шаблоны, выбор канала, защита от дублей")
        ContainerDb(notificationDb, "notification_db", "PostgreSQL 16", "Шаблоны уведомлений, журнал отправок, признаки прочитанного. Доступ имеет только Notification Service")

        Container(broker, "Шина событий", "Kafka 3", "Единая точка обмена событиями между сервисами. Транспорт асинхронных взаимодействий")
        Container(cache, "Кэш", "Redis 7", "Кэш горячих выборок и результатов поиска, распределённая блокировка")
        Container(media, "Хранилище медиа", "S3-совместимое", "Фотографии товаров, документы продавцов, выписки")
    }

    %% --- Доступ людей -----------------------------------------------------
    Rel(buyer, web, "Покупает, оформляет", "HTTPS")
    Rel(seller, web, "Товары магазина", "HTTPS")
    Rel(moderator, web, "Модерирует каталог и споры", "HTTPS")
    Rel(web, idp, "Вход через внешний аккаунт", "OAuth 2.0 / OIDC")

    %% --- Вход в систему ---------------------------------------------------
    Rel(web, gateway, "Запросы к API", "REST / JSON, HTTPS")
    Rel(gateway, identity, "Токен, профиль, роли", "REST / JSON, sync")
    Rel(gateway, catalog, "Каталог товаров продавца", "REST / JSON, sync")
    Rel(gateway, search, "Поиск и персонализированная лента", "gRPC, sync")
    Rel(gateway, cart, "Работа с корзиной", "REST / JSON, sync")
    Rel(gateway, order, "Оформление и статусы заказов", "REST / JSON, sync")

    %% --- Владение данными: сервис -> только своя БД ------------------------
    Rel(identity, identityDb, "SQL", "SQL")
    Rel(catalog, catalogDb, "SQL", "SQL")
    Rel(search, searchDb, "Признаки интересов", "SQL")
    Rel(search, searchIndex, "Поиск и фильтрация", "HTTP")
    Rel(cart, cartDb, "SQL", "SQL")
    Rel(order, orderDb, "SQL", "SQL")
    Rel(payment, paymentDb, "SQL", "SQL")
    Rel(fulfillment, fulfillmentDb, "SQL", "SQL")
    Rel(notification, notificationDb, "Шаблоны и журнал отправок", "SQL")

    %% --- Вспомогательная инфраструктура ------------------------------------
    Rel(catalog, cache, "Горячие выборки каталога", "RESP")
    Rel(search, cache, "Кэш результатов ленты", "RESP")
    Rel(catalog, media, "Фото и документы", "S3 API, async")

    %% --- Синхронные вызовы между сервисами (внутри одного запроса) ---------
    Rel(search, catalog, "Карточка товара и наличие", "REST / JSON, sync")
    Rel(search, identity, "Профиль и интересы", "REST / JSON, sync")
    Rel(order, catalog, "Цена и наличие", "REST / JSON, sync")
    Rel(order, identity, "Данные покупателя", "REST / JSON, sync")
    Rel(order, cart, "Списание и очистка корзины", "REST / JSON, sync")
    Rel(order, payment, "Создание и захват платежа", "REST / JSON, sync")
    Rel(order, fulfillment, "Создание отправления", "REST / JSON, sync")

    %% --- Асинхронные взаимодействия через шину -----------------------------
    Rel(catalog, broker, "", "")
    Rel(order, broker, "", "")
    Rel(payment, broker, "", "")
    Rel(fulfillment, broker, "", "")
    Rel(broker, search, "", "")
    Rel(broker, payment, "", "")
    Rel(broker, fulfillment, "", "")
    Rel(broker, notification, "", "")
    Rel(broker, catalog, "", "")

    %% --- Внешние интеграции ------------------------------------------------
    Rel(payment, paymentGateway, "Авторизация, захват, возврат средств", "HTTPS, sync")
    Rel(fulfillment, carrier, "Создание отправления и запрос трекинга", "HTTPS, sync")
    Rel(notification, msgProviders, "Отправка email, SMS, push", "HTTPS / SMTP, async")

    UpdateElementStyle(catalog, $bgColor="#1168b3", $borderColor="#0b4f87", $fontColor="#ffffff")
    UpdateElementStyle(catalogDb, $bgColor="#1168b3", $borderColor="#0b4f87", $fontColor="#ffffff")
    UpdateElementStyle(broker, $bgColor="#6c4ba6", $borderColor="#4a3273", $fontColor="#ffffff")
    UpdateElementStyle(buyer, $bgColor="#c8e6c9", $borderColor="#2e7d32", $fontColor="#0b2e0f")
    UpdateElementStyle(seller, $bgColor="#c8e6c9", $borderColor="#2e7d32", $fontColor="#0b2e0f")
    UpdateElementStyle(moderator, $bgColor="#c8e6c9", $borderColor="#2e7d32", $fontColor="#0b2e0f")
    UpdateRelStyle(buyer, web, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(seller, web, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(moderator, web, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(web, idp, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(web, gateway, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(gateway, identity, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(gateway, catalog, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetX="24")
    UpdateRelStyle(gateway, search, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(gateway, cart, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(gateway, order, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetX="-24")
    UpdateRelStyle(identity, identityDb, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(catalog, catalogDb, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="-20")
    UpdateRelStyle(search, searchDb, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="20")
    UpdateRelStyle(search, searchIndex, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="-18")
    UpdateRelStyle(cart, cartDb, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(order, orderDb, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(payment, paymentDb, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(fulfillment, fulfillmentDb, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(notification, notificationDb, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="20")
    UpdateRelStyle(catalog, cache, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(search, cache, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(catalog, media, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(search, catalog, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetX="-16")
    UpdateRelStyle(search, identity, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="-14")
    UpdateRelStyle(order, catalog, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="16")
    UpdateRelStyle(order, identity, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetX="18")
    UpdateRelStyle(order, cart, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(order, payment, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(order, fulfillment, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(catalog, broker, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(order, broker, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(payment, broker, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(fulfillment, broker, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(broker, search, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(broker, payment, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(broker, fulfillment, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(broker, notification, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(broker, catalog, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(payment, paymentGateway, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(fulfillment, carrier, $textColor="#0b2e0f", $lineColor="#0b2e0f")
    UpdateRelStyle(notification, msgProviders, $textColor="#0b2e0f", $lineColor="#0b2e0f")```

</details>


| Вызывающий | Вызываемый | Способ | Синхронность | Зачем |
|---|---|---|---|---|
| Web Portal | API Gateway | REST/JSON | sync | Единый вход для клиента |
| API Gateway | Identity, Catalog, Cart, Order | REST/JSON | sync | Маршрутизация запросов |
| API Gateway | Search & Personalization | gRPC | sync | Лента и поиск: высокая частота, нужна низкая латентность |
| Search | Catalog | REST/JSON | sync | Актуальные цена и наличие для карточки в выдаче |
| Search | Identity | REST/JSON | sync | Кто смотрит ленту |
| Order | Catalog | REST/JSON | sync | Проверка цены и остатка в момент заказа |
| Order | Identity | REST/JSON | sync | Данные участников заказа |
| Order | Cart | REST/JSON | sync | Списание корзины после оформления |
| Order | Payment | REST/JSON | sync | Авторизация и захват платежа в рамках саги |
| Order | Fulfillment | REST/JSON | sync | Создание отправления |
| Payment | Платёжный шлюз | HTTPS | sync | Внешний эквайринг требует ответа |
| Fulfillment | API доставки | HTTPS | sync | Внешний трекинг требует ответа |
| Catalog → шина | Search, Notification | Kafka | **async** | Реактивное обновление индекса, уведомления |
| Catalog → шина | сам Catalog (снятие товара) | Kafka | **async** | Карточка уходит с продажи, если закончился остаток |
| Order → шина | Payment, Fulfillment, Notification | Kafka | **async** | Дальнейшие шаги не держат на критическом пути |
| Payment → шина | Search, Notification | Kafka | **async** | Известить о зачислении средств продавцу |
| Fulfillment → шина | Notification | Kafka | **async** | Уведомить об отправке и трекинге |
| Шина → Notification | Notification Service | Kafka | **async** | Единственный потребитель, слабая связность |
| Notification | Провайдеры уведомлений | HTTPS/SMTP | **async** | Отправка не должна блокировать потребителя |
