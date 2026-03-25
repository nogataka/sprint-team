---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "tests/**"
---

# テスト戦略

## テストピラミッド

```
        [E2E: 予約フロー・認証]
      [統合: API Routes・RLS]
    [ユニット: lib/・バリデーション]
```

## カバレッジ目標

- `lib/` 以下: **80%** 以上
- `app/api/` 以下: **70%** 以上
- RLS ポリシー: **各ポリシー 1 テスト以上**

## ユニットテスト（Vitest）

```typescript
import { describe, it, expect } from 'vitest'

describe('calculateBookingPrice', () => {
  it('正常な日数で料金を計算する', () => {
    const result = calculateBookingPrice({
      pricePerDay: 10000,
      checkIn: new Date('2025-04-01'),
      checkOut: new Date('2025-04-05'),
    })
    expect(result.total).toBe(40000)
    expect(result.nights).toBe(4)
  })

  it('checkOut が checkIn より前の場合エラーを返す', () => {
    const result = calculateBookingPrice({ ... })
    expect(result.error).toBeDefined()
  })
})
```

## 統合テスト（Supabase Local）

```typescript
// RLS ポリシーのテスト必須
it('ゲストは他ユーザーの予約を取得できない', async () => {
  const otherClient = createTestClient({ userId: 'other-user' })
  const { data } = await otherClient.from('bookings').select().eq('id', targetId)
  expect(data).toHaveLength(0) // RLS により空
})
```

## E2E テスト（Playwright）

```typescript
// メインフローは必ずカバー
test('予約完了フロー', async ({ page }) => {
  await page.goto('/en/vehicles')
  // Stripe テストカード: 4242424242424242
})
```

## テストファイルの配置

- コンポーネント: `components/[Name]/[Name].test.tsx`（同階層）
- lib 関数: `tests/unit/lib/[name].test.ts`
- API Routes: `tests/integration/api/[route].test.ts`
- E2E: `tests/e2e/[flow].spec.ts`
