---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "app/**"
  - "lib/**"
  - "components/**"
---

# アーキテクチャルール

## ディレクトリ構成

```
app/
  (auth)/            # 認証（ログイン・サインアップ）
  [locale]/          # 多言語ルート（en/ja/zh/ko）
    (booking)/       # 予約フロー（ゲスト向け）
    (dashboard)/     # ダッシュボード（オーナー向け）
    (admin)/         # 管理画面
  api/               # API Routes
    webhooks/        # Stripe Webhook など外部 Webhook
components/
  ui/                # 汎用 UI コンポーネント
  booking/           # 予約関連コンポーネント
  vehicle/           # 車両関連コンポーネント
  dashboard/         # ダッシュボード関連
lib/
  supabase/
    client.ts        # ブラウザ用クライアント
    server.ts        # サーバー用クライアント
    types.ts         # 生成された型定義
  stripe/
    client.ts
    webhook.ts
  validations/       # Zod スキーマ（共有）
  utils/             # ユーティリティ関数
supabase/
  migrations/        # DB マイグレーション（時系列）
  seed/              # 開発用シードデータ
```

## 依存関係のルール

- `app/` → `components/` → `lib/` の単方向依存
- `lib/` から `components/` や `app/` への参照禁止
- `api/` routes は必ず `lib/` の関数を呼び出す（ロジックを直書きしない）

## データフェッチの原則

1. **Server Components でのフェッチを優先**（ウォーターフォール回避）
2. **Client Components での直接 DB アクセス禁止**（API Routes 経由）
3. **キャッシュ戦略:** `fetch()` の `next.revalidate` または `unstable_cache` を使用
