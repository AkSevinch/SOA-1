# C4 Level 1 — Context Diagram

| Ящик на L1 (контекст) | Что раскрывает L2 (контейнеры) |
|---|---|
| `Маркетплейс` — один чёрный ящик | граница с 22 контейнерами: Web Portal, API Gateway, 8 сервисов, 8 баз данных, Kafka, Redis, S3 |
| `Покупатель` | ничего — люди не раскрываются ни на каком уровне |
| `Продавец` | ничего — люди не раскрываются ни на каком уровне |
| `Модератор` | ничего — люди не раскрываются ни на каком уровне |
| `Платёжный шлюз` | `Payment` → шлюз, HTTPS, sync |
| `API служб доставки` | `Fulfillment` → доставка, HTTPS, sync |
| `Провайдеры уведомлений` | `Notification` → провайдеры, HTTPS/SMTP, async |
| `Внешний провайдер входа` | `Web Portal` → OAuth 2.0 / OIDC |


![C4 Level 1 — контекст платформы-маркетплейса](images/01-context.svg)

| Отправитель | Получатель | Способ | Синхронность | Зачем |
|---|---|---|---|---|
| Покупатель | Маркетплейс | HTTPS | sync | Лента, каталог, корзина, оформление и оплата заказа |
| Продавец | Маркетплейс | HTTPS | sync | Свои товары, цены и остатки, заказы магазина, выплаты |
| Модератор | Маркетплейс | HTTPS | sync | Проверка каталога, споры, блокировки нарушителей |
| Маркетплейс | Платёжный шлюз | HTTPS | sync | Эквайринг: авторизация, захват и возврат средств |
| Маркетплейс | API служб доставки | HTTPS | sync | Тарифы, создание отправления, трекинг статусов |
| Маркетплейс | Провайдеры уведомлений | HTTPS / SMTP | **async** | Email, SMS и push о статусах заказа |
| Маркетплейс | Внешний провайдер входа | HTTPS / OAuth 2.0 | sync | Вход через существующий аккаунт, второй фактор |


<details>
<summary>Mermaid-исходник диаграммы</summary>

```mermaid
    C4Context
        title C4 Level 1 — Контекст платформы-маркетплейса

        %% Акторы — люди вне границы системы
        Person(buyer, "Покупатель", "Просматривает ленту и каталог, собирает корзину, оформляет и оплачивает заказ, отслеживает доставку, оставляет отзыв")
        Person(seller, "Продавец", "Регистрируется и проходит проверку, размещает товары, управляет ценами и остатками, обрабатывает заказы своего магазина, получает выплаты")
        Person(moderator, "Модератор платформы", "Проверяет каталог продавцов, разрешает споры и жалобы, блокирует нарушителей")

        %% Наша система — чёрный ящик
        System(marketplace, "Маркетплейс", "Платформа для продажи товаров продавцами: персонализированная лента, каталог, корзина, заказы, расчёт и учёт платежей, уведомления о статусах")

        %% Внешние системы
        System_Ext(paymentGateway, "Платёжный шлюз", "Внешний эквайринг: авторизация, захват и возврат средств, выдача подтверждения платежа")
        System_Ext(carrier, "API служб доставки", "Создание отправления, расчёт стоимости, трекинг и статусы доставки")
        System_Ext(notificationProvider, "Провайдеры уведомлений", "Доставка email, SMS и push-уведомлений о статусах заказа")
        System_Ext(identityProvider, "Внешний провайдер входа", "OAuth 2.0 / OIDC: вход через существующие аккаунты, второй фактор")

        Rel(buyer, marketplace, "Покупает и оплачивает заказы", "HTTPS")
        Rel(seller, marketplace, "Управляет товарами магазина", "HTTPS")
        Rel(moderator, marketplace, "Модерирует каталог и разрешает споры", "HTTPS")

        Rel(marketplace, paymentGateway, "Авторизует, захватывает и возвращает платежи", "HTTPS, синхронно")
        Rel(marketplace, carrier, "Создаёт отправление, запрашивает трекинг", "HTTPS, синхронно")
        Rel(marketplace, notificationProvider, "Отправляет уведомления о статусах", "HTTPS/SMTP, асинхронно")
        Rel(marketplace, identityProvider, "Делегирует вход и второй фактор", "HTTPS/OAuth 2.0")

        UpdateElementStyle(marketplace, $bgColor="#1168b3", $borderColor="#0b4f87", $fontColor="#ffffff")
        UpdateElementStyle(buyer, $bgColor="#c8e6c9", $borderColor="#2e7d32", $fontColor="#0b2e0f")
        UpdateElementStyle(seller, $bgColor="#c8e6c9", $borderColor="#2e7d32", $fontColor="#0b2e0f")
        UpdateElementStyle(moderator, $bgColor="#c8e6c9", $borderColor="#2e7d32", $fontColor="#0b2e0f")
        UpdateRelStyle(buyer, marketplace, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="-8")
        UpdateRelStyle(seller, marketplace, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="8")
        UpdateRelStyle(moderator, marketplace, $textColor="#0b2e0f", $lineColor="#0b2e0f")
        UpdateRelStyle(marketplace, paymentGateway, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="20")
        UpdateRelStyle(marketplace, carrier, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="-20")
        UpdateRelStyle(marketplace, notificationProvider, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="20")
        UpdateRelStyle(marketplace, identityProvider, $textColor="#0b2e0f", $lineColor="#0b2e0f", $offsetY="-20")
```


