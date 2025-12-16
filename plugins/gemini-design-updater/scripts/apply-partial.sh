#!/bin/bash
# apply-partial.sh - 부분 적용/원복 스크립트
# 지정 범위만 적용하거나, 범위 외 변경만 원복합니다.
#
# 사용법:
#   ./apply-partial.sh <original_branch> <work_branch> <scope_spec> --scope-only
#   ./apply-partial.sh <original_branch> <work_branch> <scope_spec> --revert-out-of-scope
#
# 옵션:
#   --scope-only          : 지정 범위 내 변경만 적용 (범위 외 변경 원복)
#   --revert-out-of-scope : 범위 외 변경만 원복 (범위 내 변경 유지)

set -euo pipefail

# 인자 확인
if [[ $# -lt 4 ]]; then
    echo "사용법:" >&2
    echo "  $0 <original_branch> <work_branch> <scope_spec> --scope-only" >&2
    echo "  $0 <original_branch> <work_branch> <scope_spec> --revert-out-of-scope" >&2
    exit 1
fi

ORIGINAL_BRANCH="$1"
WORK_BRANCH="$2"
SCOPE_SPEC="$3"
MODE="$4"

# 범위 파싱 함수
# 지원 형식:
#   - @파일명#L시작-종료 (Claude Code IDE 형식)
#   - 파일명#L시작-종료 (@ 없이도 지원)
#   - 파일명:시작-종료 (레거시 형식)
#   - 파일명 (라인 범위 없이 전체 파일)
parse_scope() {
    local spec="$1"
    local file line_range start_line end_line

    # @ 접두사 제거 (있는 경우)
    spec="${spec#@}"

    if [[ "$spec" == *"#L"* ]]; then
        # Claude Code IDE 형식: 파일명#L시작-종료
        file="${spec%%#L*}"
        line_range="${spec##*#L}"
        start_line="${line_range%%-*}"
        end_line="${line_range##*-}"
    elif [[ "$spec" == *":"* ]]; then
        # 레거시 형식: 파일명:시작-종료
        file="${spec%%:*}"
        line_range="${spec##*:}"
        start_line="${line_range%%-*}"
        end_line="${line_range##*-}"
    else
        file="$spec"
        start_line=""
        end_line=""
    fi

    echo "$file|$start_line|$end_line"
}

# scope_spec에서 파일 목록 추출
get_scope_files() {
    local scope_list="$1"
    local files=()

    IFS=',' read -ra SCOPES <<< "$scope_list"
    for scope in "${SCOPES[@]}"; do
        scope=$(echo "$scope" | xargs)  # trim
        local parsed
        parsed=$(parse_scope "$scope")
        local file
        IFS='|' read -r file _ _ <<< "$parsed"
        files+=("$file")
    done

    printf '%s\n' "${files[@]}" | sort -u
}

# 파일이 범위에 포함되는지 확인
is_file_in_scope() {
    local target_file="$1"
    local scope_list="$2"

    IFS=',' read -ra SCOPES <<< "$scope_list"
    for scope in "${SCOPES[@]}"; do
        scope=$(echo "$scope" | xargs)
        local parsed
        parsed=$(parse_scope "$scope")
        local file
        IFS='|' read -r file _ _ <<< "$parsed"

        if [[ "$target_file" == "$file" ]]; then
            return 0
        fi
    done

    return 1
}

# 현재 브랜치 확인
CURRENT_BRANCH=$(git branch --show-current)

# 브랜치 존재 확인
for branch in "$ORIGINAL_BRANCH" "$WORK_BRANCH"; do
    if ! git show-ref --verify --quiet "refs/heads/${branch}"; then
        echo "Error: 브랜치를 찾을 수 없습니다: ${branch}" >&2
        exit 1
    fi
done

# 변경된 파일 목록
CHANGED_FILES=$(git diff --name-only "${ORIGINAL_BRANCH}".."${WORK_BRANCH}")

if [[ -z "$CHANGED_FILES" ]]; then
    echo "변경된 파일이 없습니다."
    exit 0
fi

echo "=============================================="
echo "부분 적용/원복 처리"
echo "=============================================="
echo ""
echo "모드: $MODE"
echo "지정 범위: $SCOPE_SPEC"
echo ""

# 범위 내/외 파일 분류
IN_SCOPE_FILES=()
OUT_OF_SCOPE_FILES=()

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    if is_file_in_scope "$file" "$SCOPE_SPEC"; then
        IN_SCOPE_FILES+=("$file")
    else
        OUT_OF_SCOPE_FILES+=("$file")
    fi
done <<< "$CHANGED_FILES"

echo "범위 내 파일: ${#IN_SCOPE_FILES[@]}개"
for f in "${IN_SCOPE_FILES[@]:-}"; do
    [[ -n "$f" ]] && echo "  - $f"
done

echo "범위 외 파일: ${#OUT_OF_SCOPE_FILES[@]}개"
for f in "${OUT_OF_SCOPE_FILES[@]:-}"; do
    [[ -n "$f" ]] && echo "  - $f"
done
echo ""

case "$MODE" in
    --scope-only)
        # 지정 범위만 적용: 먼저 전체 머지 후 범위 외 파일 원복
        echo "### 지정 범위만 적용 중..."
        echo ""

        # 작업 브랜치에서 원래 브랜치로 이동
        if [[ "$CURRENT_BRANCH" != "$ORIGINAL_BRANCH" ]]; then
            git checkout "$ORIGINAL_BRANCH"
        fi

        # 범위 내 파일만 작업 브랜치에서 가져오기
        if [[ ${#IN_SCOPE_FILES[@]} -gt 0 ]]; then
            echo "범위 내 파일 적용 중..."
            for file in "${IN_SCOPE_FILES[@]}"; do
                if [[ -n "$file" ]]; then
                    echo "  - $file"
                    git checkout "$WORK_BRANCH" -- "$file" 2>/dev/null || true
                fi
            done
            echo ""
        fi

        echo "✓ 지정 범위 변경사항만 적용되었습니다."
        echo "  - 적용된 파일: ${#IN_SCOPE_FILES[@]}개"
        echo "  - 무시된 파일: ${#OUT_OF_SCOPE_FILES[@]}개"
        ;;

    --revert-out-of-scope)
        # 범위 외만 원복: 현재 상태에서 범위 외 파일만 원래대로
        echo "### 범위 외 변경 원복 중..."
        echo ""

        # 현재 작업 브랜치에 있어야 함
        if [[ "$CURRENT_BRANCH" != "$WORK_BRANCH" ]]; then
            git checkout "$WORK_BRANCH"
        fi

        # 범위 외 파일을 원래 브랜치 상태로 복원
        if [[ ${#OUT_OF_SCOPE_FILES[@]} -gt 0 ]]; then
            echo "범위 외 파일 원복 중..."
            for file in "${OUT_OF_SCOPE_FILES[@]}"; do
                if [[ -n "$file" ]]; then
                    echo "  - $file"
                    git checkout "$ORIGINAL_BRANCH" -- "$file" 2>/dev/null || true
                fi
            done
            echo ""
        fi

        # 변경사항 스테이징
        git add -A

        echo "✓ 범위 외 변경사항이 원복되었습니다."
        echo "  - 유지된 파일 (범위 내): ${#IN_SCOPE_FILES[@]}개"
        echo "  - 원복된 파일 (범위 외): ${#OUT_OF_SCOPE_FILES[@]}개"

        # 원래 브랜치로 머지
        echo ""
        echo "원래 브랜치에 머지하시겠습니까? (y/n)"
        read -r answer
        if [[ "$answer" == "y" ]]; then
            git checkout "$ORIGINAL_BRANCH"
            git merge "$WORK_BRANCH" --no-ff -m "Gemini design update (scope-limited): $SCOPE_SPEC"
            echo "✓ 머지 완료"
        fi
        ;;

    *)
        echo "Error: 알 수 없는 모드: $MODE" >&2
        echo "사용 가능한 모드: --scope-only, --revert-out-of-scope" >&2
        exit 1
        ;;
esac

echo ""
echo "=============================================="
echo "완료"
echo "=============================================="
