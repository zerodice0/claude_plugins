# 범위 지정 예시

Gemini에게 디자인 업데이트를 요청할 때 범위를 지정하는 다양한 방법입니다.

---

## 범위 지정 형식

| 형식 | 예시 | 설명 |
|------|------|------|
| 파일 전체 | `src/Button.tsx` | 파일 전체를 대상으로 |
| IDE 라인 범위 | `@src/Button.tsx#L10-50` | IDE에서 범위 선택 시 자동 생성 |
| 라인 범위 | `src/Button.tsx#L10-50` | 10~50라인만 대상으로 |
| 레거시 형식 | `src/Button.tsx:10-50` | 콜론 구분자 (하위 호환) |
| 여러 파일 | `src/Button.tsx, src/Card.tsx` | 쉼표로 구분 |
| 혼합 | `@src/Button.tsx#L10-50, src/Card.tsx` | 라인 범위 + 전체 파일 |

> **Tip**: IDE에서 코드를 선택한 후 프롬프트에 드래그하면 `@파일명#L시작-종료` 형식으로 자동 입력됩니다.

---

## 좋은 범위 지정 예시

### 예시 1: 특정 컴포넌트만 수정 (IDE 범위 선택)

```
Gemini로 @src/components/Button.tsx#L20-80 버튼 스타일을 모던하게 바꿔줘
```

**범위**: `src/components/Button.tsx#L20-80`
**요청**: 버튼 스타일을 모던하게 바꿔줘

- IDE에서 코드 선택 후 드래그하면 `@파일명#L시작-종료` 형식으로 자동 입력
- 명확한 파일 경로
- 구체적인 라인 범위
- 간단한 요청 (원문 그대로 전달됨)

### 예시 2: 파일 전체 수정

```
Gemini로 src/styles/button.css 파일 스타일 개선해줘
```

**범위**: `src/styles/button.css`
**요청**: 스타일 개선해줘

- 파일 전체가 범위
- 라인 범위 없이 파일명만 지정

### 예시 3: 여러 파일 동시 수정

```
Gemini로 @src/components/Card.tsx#L10-40, src/components/CardHeader.tsx 카드 레이아웃 정리해줘
```

**범위**:
- `src/components/Card.tsx#L10-40`
- `src/components/CardHeader.tsx` (전체)

**요청**: 카드 레이아웃 정리해줘

### 예시 4: 특정 함수/컴포넌트만 수정

```
Gemini로 @src/hooks/useAuth.ts#L45-70 로그인 상태 체크 로직 개선해줘
```

**범위**: `src/hooks/useAuth.ts#L45-70`
**요청**: 로그인 상태 체크 로직 개선해줘

---

## 나쁜 범위 지정 예시

### ❌ 범위 없이 모호한 요청

```
버튼 디자인 바꿔줘
```

**문제**: 어떤 파일의 어떤 버튼인지 불명확

**개선**:
```
Gemini로 src/components/Button.tsx 버튼 디자인 바꿔줘
```

### ❌ 너무 넓은 범위

```
Gemini로 src/components 폴더 전체 디자인 업데이트해줘
```

**문제**: 범위가 너무 넓어 리뷰가 어려움

**개선**: 파일별로 나눠서 요청
```
Gemini로 src/components/Button.tsx 버튼 디자인 업데이트해줘
```

### ❌ 잘못된 라인 범위 형식

```
Gemini로 Button.tsx 20번째 줄부터 50번째 줄까지 수정해줘
```

**문제**: 형식이 표준화되지 않음

**개선** (IDE에서 범위 선택 권장):
```
Gemini로 @src/components/Button.tsx#L20-50 수정해줘
```

---

## 범위 확인하는 방법

### IDE에서 범위 선택 (권장)

1. 파일 열기
2. 수정하고 싶은 코드 영역 선택 (드래그)
3. 선택한 영역을 Claude Code 프롬프트 입력창에 드래그
4. `@파일경로#L시작-끝` 형식으로 자동 입력됨

### VS Code에서 라인 번호 확인 (수동)

1. 파일 열기
2. 수정하고 싶은 영역의 시작 라인 확인 (에디터 좌측 번호)
3. 끝 라인 확인
4. `파일경로#L시작-끝` 형식으로 직접 입력

### CLI에서 확인

```bash
# 파일 내용과 라인 번호 확인
cat -n src/components/Button.tsx | head -60

# 특정 범위만 확인
sed -n '20,50p' src/components/Button.tsx
```

---

## 범위 지정 팁

### 1. 함수/컴포넌트 경계 맞추기

함수나 컴포넌트의 시작(`{`)부터 끝(`}`)까지 포함하면 좋습니다:

```tsx
// 20라인: function Button() {
// ...
// 50라인: }

범위: @src/components/Button.tsx#L20-50
```

### 2. import 영역 제외하기

import는 Gemini가 자동으로 필요한 것을 추가하므로, 본문만 지정해도 됩니다:

```tsx
// 1-10라인: import 문들
// 12-80라인: 컴포넌트 본문

범위: @src/components/Button.tsx#L12-80
```

### 3. 여러 번 나눠서 요청하기

큰 변경은 작은 단위로:

```
1차: Gemini로 @src/components/Button.tsx#L20-40 버튼 기본 스타일 변경
2차: Gemini로 @src/components/Button.tsx#L45-60 hover 상태 스타일 변경
3차: Gemini로 @src/components/Button.tsx#L65-80 disabled 상태 스타일 변경
```

---

## 실제 사용 흐름 예시

### 사용자 입력

```
Gemini로 @src/features/auth/LoginForm.tsx#L30-80 로그인 폼 디자인을 더 깔끔하게 해줘
```

### Claude가 Gemini에게 전달하는 프롬프트

```
[작업 범위 제한]
다음 파일/범위만 수정하세요:
- src/features/auth/LoginForm.tsx#L30-80

[사용자 요청 (원문)]
로그인 폼 디자인을 더 깔끔하게 해줘

[주의사항]
- 지정된 범위 외의 파일은 가능하면 수정하지 마세요
- 범위 외 수정이 불가피한 경우 (예: import 추가) 최소한으로 유지하세요
```

### 핵심 포인트

1. **사용자 요청 원문 유지**: "로그인 폼 디자인을 더 깔끔하게 해줘" 그대로 전달
2. **범위만 명확히 지정**: `src/features/auth/LoginForm.tsx#L30-80`
3. **Gemini의 창의성 보장**: Claude가 "깔끔하다"를 해석하지 않고 Gemini에게 맡김

---

## FAQ

### Q: 라인 번호를 정확히 몰라요

**방법 1 (권장)**: IDE에서 수정하고 싶은 코드를 선택하고 프롬프트 입력창에 드래그하세요. `@파일명#L시작-종료` 형식으로 자동 입력됩니다.

**방법 2**: 파일명만 지정하면 됩니다. Gemini가 필요한 부분을 찾아서 수정합니다:

```
Gemini로 src/components/Button.tsx의 hover 스타일 변경해줘
```

### Q: 여러 파일에 흩어진 변경이 필요해요

각 파일을 쉼표로 구분하거나, 여러 번 나눠서 요청하세요:

```
# 한 번에
Gemini로 src/components/Button.tsx, src/styles/button.css 버튼 스타일 통일해줘

# 또는 나눠서
Gemini로 src/components/Button.tsx 버튼 컴포넌트 수정해줘
Gemini로 src/styles/button.css 버튼 스타일 수정해줘
```

### Q: 범위 외 변경이 많이 발생했어요

리뷰 단계에서 "지정 범위만 적용" 옵션을 선택하면 됩니다.
다음부터는 더 구체적인 범위를 지정하거나, 요청을 더 명확하게 해보세요.
