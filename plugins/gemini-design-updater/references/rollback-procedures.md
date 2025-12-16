# 4가지 옵션 처리 절차

Gemini 변경사항을 처리하는 4가지 옵션에 대한 상세 절차입니다.

---

## 옵션 개요

| 옵션 | 설명 | 언제 사용 |
|------|------|----------|
| **1. 전체 적용** | 모든 변경사항 적용 | 범위 외 변경이 없거나 모두 허용 가능할 때 |
| **2. 지정 범위만 적용** | 범위 내 변경만 적용 | 범위 외 변경이 과도할 때 |
| **3. 전체 원복** | 모든 변경 폐기 | Critical 이슈가 있거나 결과가 마음에 들지 않을 때 |
| **4. 범위 외만 원복** | 범위 외 변경만 되돌림 | 범위 내는 좋지만 범위 외 변경이 불필요할 때 |

---

## 옵션 1: 전체 적용

모든 변경사항을 원래 브랜치에 머지합니다.

### 일반 머지

```bash
# 원래 브랜치로 전환
git checkout <original_branch>

# 작업 브랜치 머지 (커밋 기록 유지)
git merge <work_branch> --no-ff -m "Gemini design update: <설명>"

# 작업 브랜치 삭제
git branch -d <work_branch>
```

### 스쿼시 머지 (커밋 합치기)

```bash
# 원래 브랜치로 전환
git checkout <original_branch>

# 스쿼시 머지 (모든 변경을 하나의 커밋으로)
git merge --squash <work_branch>
git commit -m "Gemini design update: <설명>"

# 작업 브랜치 삭제
git branch -d <work_branch>
```

### 권장 상황

- 범위 외 변경이 없을 때
- 범위 외 변경이 모두 "필연적" 분류일 때
- 리뷰 결과 Critical/Major 이슈가 없을 때

---

## 옵션 2: 지정 범위만 적용

요청한 범위 내 변경만 적용하고, 범위 외 변경은 무시합니다.

### 스크립트 사용 (권장)

```bash
bash ~/.claude/skills/gemini-design-updater/scripts/apply-partial.sh \
  <original_branch> <work_branch> "<scope_spec>" --scope-only
```

### 수동 실행

```bash
# 원래 브랜치로 전환
git checkout <original_branch>

# 범위 내 파일만 작업 브랜치에서 가져오기
git checkout <work_branch> -- path/to/in_scope_file1.tsx
git checkout <work_branch> -- path/to/in_scope_file2.tsx

# 변경사항 확인
git diff --staged

# 커밋
git commit -m "Gemini design update (scope-limited): <설명>"

# 작업 브랜치 삭제
git branch -D <work_branch>
```

### 라인 범위가 있는 경우

파일 전체가 아닌 특정 라인만 적용해야 할 때:

```bash
# 작업 브랜치의 변경된 파일 내용 확인
git show <work_branch>:path/to/file.tsx > /tmp/new_file.tsx

# 원래 파일에서 지정 라인만 교체 (sed 사용)
# 예: 20-50 라인만 교체
head -n 19 path/to/file.tsx > /tmp/merged.tsx
sed -n '20,50p' /tmp/new_file.tsx >> /tmp/merged.tsx
tail -n +51 path/to/file.tsx >> /tmp/merged.tsx
mv /tmp/merged.tsx path/to/file.tsx

# 커밋
git add path/to/file.tsx
git commit -m "Gemini design update (lines 20-50): <설명>"
```

### 권장 상황

- 범위 외 변경이 "과도함" 분류일 때
- 범위 외 변경이 많고 검토가 어려울 때
- 최소한의 변경만 원할 때

---

## 옵션 3: 전체 원복

모든 변경사항을 버립니다.

### 스크립트 사용 (권장)

```bash
bash ~/.claude/skills/gemini-design-updater/scripts/cleanup-branch.sh \
  <original_branch> <work_branch> --force
```

### 수동 실행

```bash
# 원래 브랜치로 전환
git checkout <original_branch>

# 작업 브랜치 강제 삭제
git branch -D <work_branch>
```

### 권장 상황

- Critical 이슈가 발견됐을 때
- 결과물이 기대와 완전히 다를 때
- 다시 시도하고 싶을 때

---

## 옵션 4: 범위 외만 원복

범위 외 변경만 되돌리고, 범위 내 변경은 유지합니다.

### 스크립트 사용 (권장)

```bash
bash ~/.claude/skills/gemini-design-updater/scripts/apply-partial.sh \
  <original_branch> <work_branch> "<scope_spec>" --revert-out-of-scope
```

### 수동 실행

```bash
# 작업 브랜치에서 작업
git checkout <work_branch>

# 범위 외 파일을 원래 브랜치 상태로 복원
git checkout <original_branch> -- path/to/out_of_scope_file1.tsx
git checkout <original_branch> -- path/to/out_of_scope_file2.css

# 변경사항 커밋
git add -A
git commit --amend -m "Gemini design update (scope-limited)"

# 원래 브랜치에 머지
git checkout <original_branch>
git merge <work_branch> --no-ff -m "Gemini design update: <설명>"

# 작업 브랜치 삭제
git branch -d <work_branch>
```

### 권장 상황

- 범위 내 변경은 만족스럽지만 범위 외 변경이 불필요할 때
- import 추가 외의 범위 외 변경을 제거하고 싶을 때

---

## 옵션 2 vs 옵션 4 차이점

| 항목 | 옵션 2 (지정 범위만 적용) | 옵션 4 (범위 외만 원복) |
|------|------------------------|----------------------|
| 시작점 | 원래 브랜치 | 작업 브랜치 |
| 동작 | 범위 내 파일만 복사 | 범위 외 파일만 복원 |
| import | 수동 추가 필요할 수 있음 | 유지될 수 있음 |
| 적합한 상황 | 범위 외 변경이 많을 때 | 범위 외 변경이 적을 때 |

---

## 머지 후 롤백 (비상시)

이미 머지한 후 문제를 발견한 경우입니다.

### 방법 1: 머지 커밋 되돌리기 (revert)

기록을 유지하면서 변경사항을 되돌립니다.

```bash
# 머지 커밋 해시 확인
git log --oneline

# 머지 커밋 되돌리기
# -m 1: 첫 번째 부모(원래 브랜치)를 유지
git revert -m 1 <merge_commit_hash>
```

### 방법 2: 하드 리셋 (주의!)

**⚠️ 주의: 커밋 기록이 삭제됩니다. 공유된 브랜치에서는 사용하지 마세요.**

```bash
# 머지 전 커밋으로 리셋
git reset --hard <commit_before_merge>

# 원격에 이미 푸시한 경우 (매우 주의!)
git push --force-with-lease
```

### 방법 3: 특정 파일만 되돌리기

```bash
# 머지 전 상태의 특정 파일 복원
git checkout <commit_before_merge> -- path/to/file.tsx

# 커밋
git commit -m "Revert Gemini changes to file.tsx"
```

---

## 문제 상황별 대응

### 충돌 발생 시

```bash
# 충돌 상태 확인
git status

# 충돌 파일 열어서 수정
# <<<<<<< HEAD
# 현재 브랜치 내용
# =======
# 머지하려는 브랜치 내용
# >>>>>>> work_branch

# 충돌 해결 후
git add <resolved_file>
git commit -m "Resolve merge conflict"
```

### 작업 브랜치를 실수로 삭제한 경우

```bash
# 최근 삭제된 브랜치의 커밋 찾기
git reflog

# 브랜치 복구
git checkout -b <work_branch> <commit_hash>
```

### 원래 브랜치가 변경된 경우

작업 중 원래 브랜치에 다른 변경이 있었다면:

```bash
# 작업 브랜치에서 rebase
git checkout <work_branch>
git rebase <original_branch>

# 충돌 해결 후
git rebase --continue

# 또는 머지 방식 사용
git merge <original_branch>
```

---

## 의사결정 흐름도

```
리뷰 결과 확인
    │
    ├─ Critical 이슈 있음? ─── Yes ──→ 옵션 3: 전체 원복
    │         │
    │        No
    │         │
    ├─ 범위 외 변경 있음? ─── No ───→ 옵션 1: 전체 적용
    │         │
    │        Yes
    │         │
    ├─ 범위 외 변경이 필연적? ─ Yes ──→ 옵션 1: 전체 적용
    │         │
    │        No
    │         │
    ├─ 범위 외 변경이 많음? ─── Yes ──→ 옵션 2: 지정 범위만 적용
    │         │
    │        No
    │         │
    └─────────────────────────────────→ 옵션 4: 범위 외만 원복
```

---

## 유용한 Git 명령어

```bash
# 브랜치 간 차이 요약
git diff --stat <branch1>..<branch2>

# 특정 파일의 변경 이력
git log --oneline -- path/to/file.tsx

# 브랜치 목록 (gemini 관련)
git branch --list "gemini-*"

# 오래된 gemini 브랜치 정리
git branch --list "gemini-*" | xargs -r git branch -D

# 특정 파일만 diff 보기
git diff <original_branch> -- path/to/file.tsx

# 라인별 변경 확인
git diff -U0 <original_branch> -- path/to/file.tsx
```
