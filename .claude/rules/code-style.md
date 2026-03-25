---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# コーディング規約

## TypeScript

- `any` 型は**絶対禁止**。不明な型は `unknown` を使い narrowing する
- `as` キャストは型生成（Supabase/Zod）の結果のみ許可
- `interface` より `type` を優先（拡張が必要な場合のみ `interface`）
- `strict: true` を維持する

## 関数スタイル

```typescript
// ✅ アロー関数統一
const createBooking = async (input: BookingInput): Promise<Result<Booking>> => {
  // ...
}

// ✅ 明示的な戻り値型
export const getVehicle = async (id: string): Promise<Vehicle | null> => {
  // ...
}

// ❌ function 宣言（Next.js の export default は除く）
function createBooking(input) { ... }
```

## エラーハンドリング（Result パターン）

```typescript
type Result<T, E = string> =
  | { data: T; error: null }
  | { data: null; error: E }

// ✅ Result 型で返す
const result = await createBooking(input)
if (result.error) {
  // エラー処理
}
```

## インポート順序（ESLint で自動整列）

1. React / Next.js
2. 外部ライブラリ
3. `@/lib/`
4. `@/components/`
5. 型のみのインポート（`import type`）

## ファイル命名規則

- コンポーネント: `PascalCase.tsx`（例: `BookingForm.tsx`）
- ユーティリティ: `kebab-case.ts`（例: `format-date.ts`）
- API Routes: `route.ts`（Next.js 規約）
- テスト: `*.test.ts` / `*.spec.ts`
- 型定義のみ: `*.types.ts`

## コメント

- **なぜ**を書く（何をするかはコードが語る）
- TODOは `// TODO(taka): [内容] #Issue番号` 形式
- ハック・回避策は `// HACK:` で明示
