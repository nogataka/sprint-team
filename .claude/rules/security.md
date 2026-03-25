---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "supabase/**"
  - "app/api/**"
---

# セキュリティルール

## 最重要ルール（違反時は即 PR ブロック）

1. `.env` / `.env.local` をコードにハードコード禁止
2. Supabase Service Role Key をクライアントサイドで使用禁止
3. RLS（Row Level Security）が設定されていないテーブルへの書き込み禁止
4. Stripe Webhook のシグネチャ検証なしに処理を実行禁止

## Supabase RLS チェックリスト

新規テーブルを作成する場合は必ず以下を実装する：

```sql
-- 1. RLS を有効化
ALTER TABLE [table_name] ENABLE ROW LEVEL SECURITY;

-- 2. 匿名アクセスをデフォルト禁止
-- （RLS 有効化でデフォルト拒否になる）

-- 3. 必要な SELECT ポリシーを定義
CREATE POLICY "[table]_select_own"
  ON [table_name] FOR SELECT
  USING (auth.uid() = user_id);

-- 4. INSERT ポリシー（認証済みユーザーのみ）
CREATE POLICY "[table]_insert_authenticated"
  ON [table_name] FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

## API Routes のセキュリティ

```typescript
// ✅ 全 API Route で認証チェック必須
export async function POST(req: Request) {
  const supabase = createClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (!user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  // ...
}

// ✅ 全入力を Zod でバリデーション
const body = bodySchema.safeParse(await req.json())
if (!body.success) {
  return Response.json({ error: body.error }, { status: 400 })
}
```

## Stripe Webhook

```typescript
// ✅ シグネチャ検証必須
export async function POST(req: Request) {
  const body = await req.text()
  const signature = req.headers.get('stripe-signature')!
  
  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch {
    return Response.json({ error: 'Invalid signature' }, { status: 400 })
  }
}
```

## 環境変数の使い方

```typescript
// ✅ サーバーサイドのみ
process.env.SUPABASE_SERVICE_ROLE_KEY  // API Routes・Server Components のみ
process.env.STRIPE_SECRET_KEY

// ✅ クライアントサイドは NEXT_PUBLIC_ プレフィックスのみ
process.env.NEXT_PUBLIC_SUPABASE_URL
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

// ❌ Service Role Key をクライアントで使用禁止
```
