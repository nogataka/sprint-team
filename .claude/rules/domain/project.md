---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "supabase/**"
---

# ドメイン知識

## ビジネスモデル

- **プラットフォーム型:** オーナー（車両提供者）↔ ゲスト（外国人旅行者）をつなぐ
- **収益:** 予約手数料（Stripe Connect の application_fee）+ 月額掲載料
- **市場:** 訪日外国人（英語・中国語・韓国語・日本語対応）

## ドメイン用語（コード内でも統一）

| 日本語 | コード内の用語 | 説明 |
|-------|--------------|------|
| 車両 | `vehicle` | キャンピングカー・RV等 |
| オーナー | `owner` | 車両を提供するユーザー |
| ゲスト | `guest` | 予約・利用するユーザー |
| 予約 | `booking` | チェックイン〜チェックアウト |
| 掲載 | `listing` | 車両の公開情報 |
| 価格 | `price_per_day` | 1日あたりの基本料金（JPY） |

## DB スキーマ（主要テーブル）

```sql
-- ユーザー（Supabase Auth と連携）
profiles (
  id UUID PRIMARY KEY REFERENCES auth.users,
  role TEXT CHECK (role IN ('guest', 'owner', 'admin')),
  stripe_customer_id TEXT,
  stripe_account_id TEXT  -- オーナーのみ
)

-- 車両
vehicles (
  id UUID PRIMARY KEY,
  owner_id UUID REFERENCES profiles,
  title TEXT,
  description_en TEXT,
  description_ja TEXT,
  description_zh TEXT,
  description_ko TEXT,
  price_per_day INTEGER,  -- JPY
  status TEXT CHECK (status IN ('draft', 'active', 'inactive'))
)

-- 予約
bookings (
  id UUID PRIMARY KEY,
  vehicle_id UUID REFERENCES vehicles,
  guest_id UUID REFERENCES profiles,
  check_in DATE,
  check_out DATE,
  total_amount INTEGER,   -- JPY
  platform_fee INTEGER,   -- プラットフォーム手数料
  status TEXT CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  stripe_payment_intent_id TEXT
)
```

## 料金計算ルール

```typescript
const PLATFORM_FEE_RATE = 0.10  // 10%

const calculateBookingAmount = (pricePerDay: number, nights: number) => {
  const subtotal = pricePerDay * nights
  const platformFee = Math.round(subtotal * PLATFORM_FEE_RATE)
  const ownerAmount = subtotal - platformFee
  return { subtotal, platformFee, ownerAmount }
}
```

## 多言語対応（next-intl）

対応言語: `en`（デフォルト）/ `ja` / `zh` / `ko`

```typescript
// messages/en.json, ja.json, zh.json, ko.json を必ずセットで更新
// 新しい UI テキストは必ず全言語に追加する
```

## Stripe Connect フロー

1. オーナーが Stripe Connect オンボーディング（`/api/stripe/connect`）
2. ゲストが予約 → Payment Intent 作成（`application_fee_amount` に手数料設定）
3. Webhook で `payment_intent.succeeded` を受信 → booking を `confirmed` に更新
4. チェックアウト後 → Stripe が自動でオーナーへ送金

## カレンダー・空き状況

- 予約済み日程は `bookings` テーブルから計算
- `check_in` と `check_out` は重複不可（DB 制約でも保証）
- タイムゾーン: 全て JST（UTC+9）で保存・表示
