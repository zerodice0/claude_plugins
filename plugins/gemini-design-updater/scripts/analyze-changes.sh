#!/bin/bash
# analyze-changes.sh - 변경사항 분석 스크립트 (범위 검증 포함)
# Gemini가 수정한 내용을 분석하고 지정 범위와 비교합니다.
#
# 사용법: ./analyze-changes.sh <original_branch> [scope_spec]
# 입력:
#   - original_branch: 원래 브랜치명
#   - scope_spec (선택): 지정 범위 (예: "src/Button.tsx:10-50,src/Card.tsx")
# 출력: 변경된 파일 목록, 범위 분석, diff 통계

set -euo pipefail

# 인자 확인
if [[ $# -lt 1 ]]; then
    echo "사용법: $0 <original_branch> [scope_spec]" >&2
    exit 1
fi

ORIGINAL_BRANCH="$1"
SCOPE_SPEC="${2:-}"
CURRENT_BRANCH=$(git branch --show-current)

# 브랜치 존재 확인
if ! git show-ref --verify --quiet "refs/heads/${ORIGINAL_BRANCH}"; then
    echo "Error: 원래 브랜치를 찾을 수 없습니다: ${ORIGINAL_BRANCH}" >&2
    exit 1
fi

# 범위 파싱 함수
# 입력: "src/Button.tsx:10-50" -> 파일경로, 시작라인, 끝라인
parse_scope() {
    local spec="$1"
    local file line_range start_line end_line

    if [[ "$spec" == *":"* ]]; then
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

# 라인이 범위 내에 있는지 확인
is_line_in_scope() {
    local line="$1"
    local start="$2"
    local end="$3"

    # 범위 지정 없으면 전체가 범위
    if [[ -z "$start" ]] || [[ -z "$end" ]]; then
        return 0
    fi

    if [[ "$line" -ge "$start" ]] && [[ "$line" -le "$end" ]]; then
        return 0
    fi
    return 1
}

# 파일이 scope_spec에 있는지 확인
get_scope_for_file() {
    local target_file="$1"
    local scope_list="$2"

    IFS=',' read -ra SCOPES <<< "$scope_list"
    for scope in "${SCOPES[@]}"; do
        scope=$(echo "$scope" | xargs)  # trim
        local parsed
        parsed=$(parse_scope "$scope")
        local file start_line end_line
        IFS='|' read -r file start_line end_line <<< "$parsed"

        if [[ "$target_file" == "$file" ]]; then
            echo "$start_line|$end_line"
            return 0
        fi
    done

    echo ""
    return 1
}

# 변경된 라인 범위 추출 (git diff -U0 파싱)
# @@ -old_start,old_count +new_start,new_count @@ 형식
get_changed_line_ranges() {
    local file="$1"
    local base_branch="$2"

    git diff -U0 "$base_branch" -- "$file" 2>/dev/null | \
        grep -E "^@@" | \
        sed -E 's/@@ -[0-9,]+ \+([0-9]+)(,([0-9]+))? @@.*/\1 \3/' | \
        while read -r start count; do
            count="${count:-1}"
            end=$((start + count - 1))
            echo "$start-$end"
        done
}

echo "=============================================="
echo "Gemini 변경사항 분석 결과"
echo "=============================================="
echo ""
echo "원래 브랜치: ${ORIGINAL_BRANCH}"
echo "작업 브랜치: ${CURRENT_BRANCH}"
if [[ -n "$SCOPE_SPEC" ]]; then
    echo "지정 범위: ${SCOPE_SPEC}"
fi
echo ""

# 변경된 파일 목록
CHANGED_FILES=$(git diff --name-only "${ORIGINAL_BRANCH}")
FILE_COUNT=$(echo "$CHANGED_FILES" | grep -c . || echo "0")

if [[ "$FILE_COUNT" -eq 0 ]]; then
    echo "(변경된 파일 없음)"
    echo ""
    echo "=============================================="
    exit 0
fi

echo "### 변경된 파일 목록"
echo ""
echo "총 ${FILE_COUNT}개 파일 변경됨:"
echo ""

echo "$CHANGED_FILES" | while read -r file; do
    if [[ -n "$file" ]]; then
        STAT=$(git diff --stat "${ORIGINAL_BRANCH}" -- "$file" | tail -1 | sed 's/.*|//')
        echo "  - $file ($STAT)"
    fi
done
echo ""

# 범위 분석 (scope_spec이 제공된 경우)
if [[ -n "$SCOPE_SPEC" ]]; then
    echo "=============================================="
    echo "### 범위 분석"
    echo "=============================================="
    echo ""

    IN_SCOPE_CHANGES=""
    OUT_OF_SCOPE_CHANGES=""
    NECESSARY_OUT_OF_SCOPE=""
    EXCESSIVE_OUT_OF_SCOPE=""

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        scope_range=$(get_scope_for_file "$file" "$SCOPE_SPEC" || echo "")

        if [[ -z "$scope_range" ]]; then
            # 파일 자체가 범위에 없음
            OUT_OF_SCOPE_CHANGES+="$file (파일 전체)\n"

            # import 관련 파일인지 확인 (필연적 변경 가능성)
            if echo "$file" | grep -qE '\.(d\.ts|types\.ts|index\.ts)$'; then
                NECESSARY_OUT_OF_SCOPE+="$file (타입/인덱스 파일)\n"
            elif git diff "$ORIGINAL_BRANCH" -- "$file" | grep -qE "^[+-](import|export|from)"; then
                # import/export 변경만 있는지 확인
                non_import_changes=$(git diff "$ORIGINAL_BRANCH" -- "$file" | grep -E "^[+-]" | grep -vE "^[+-](import|export|from|$)" | wc -l || echo "0")
                if [[ "$non_import_changes" -lt 3 ]]; then
                    NECESSARY_OUT_OF_SCOPE+="$file (import/export 변경)\n"
                else
                    EXCESSIVE_OUT_OF_SCOPE+="$file\n"
                fi
            else
                EXCESSIVE_OUT_OF_SCOPE+="$file\n"
            fi
        else
            # 파일은 범위에 있음, 라인 확인
            IFS='|' read -r start_line end_line <<< "$scope_range"

            if [[ -z "$start_line" ]]; then
                # 전체 파일이 범위
                IN_SCOPE_CHANGES+="$file (전체)\n"
            else
                # 라인 범위 비교
                changed_ranges=$(get_changed_line_ranges "$file" "$ORIGINAL_BRANCH")
                in_scope_count=0
                out_of_scope_count=0
                out_of_scope_lines=""

                while IFS= read -r range; do
                    [[ -z "$range" ]] && continue
                    change_start="${range%%-*}"
                    change_end="${range##*-}"

                    # 변경된 각 라인이 범위 내인지 확인
                    for ((line=change_start; line<=change_end; line++)); do
                        if is_line_in_scope "$line" "$start_line" "$end_line"; then
                            ((in_scope_count++))
                        else
                            ((out_of_scope_count++))
                            out_of_scope_lines+="$line,"
                        fi
                    done
                done <<< "$changed_ranges"

                if [[ $out_of_scope_count -eq 0 ]]; then
                    IN_SCOPE_CHANGES+="$file:$start_line-$end_line\n"
                elif [[ $in_scope_count -eq 0 ]]; then
                    OUT_OF_SCOPE_CHANGES+="$file (라인: ${out_of_scope_lines%,})\n"

                    # import 영역인지 확인 (보통 파일 상단)
                    if [[ "${change_start:-0}" -lt 20 ]]; then
                        NECESSARY_OUT_OF_SCOPE+="$file (상단 영역 - import 가능성)\n"
                    else
                        EXCESSIVE_OUT_OF_SCOPE+="$file (라인: ${out_of_scope_lines%,})\n"
                    fi
                else
                    IN_SCOPE_CHANGES+="$file:$start_line-$end_line (부분)\n"

                    # 범위 외 변경도 있음
                    if [[ "${change_start:-0}" -lt "$start_line" ]] && [[ "${change_start:-0}" -lt 20 ]]; then
                        NECESSARY_OUT_OF_SCOPE+="$file (import 추가)\n"
                    else
                        OUT_OF_SCOPE_CHANGES+="$file (라인: ${out_of_scope_lines%,})\n"
                    fi
                fi
            fi
        fi
    done <<< "$CHANGED_FILES"

    # 범위 내 변경
    echo "#### 범위 내 변경"
    if [[ -n "$IN_SCOPE_CHANGES" ]]; then
        echo -e "$IN_SCOPE_CHANGES" | while read -r line; do
            [[ -n "$line" ]] && echo "  ✓ $line"
        done
    else
        echo "  (없음)"
    fi
    echo ""

    # 범위 외 변경 - 필연적
    echo "#### 범위 외 변경 - 필연적 (import/type 등)"
    if [[ -n "$NECESSARY_OUT_OF_SCOPE" ]]; then
        echo -e "$NECESSARY_OUT_OF_SCOPE" | while read -r line; do
            [[ -n "$line" ]] && echo "  △ $line"
        done
    else
        echo "  (없음)"
    fi
    echo ""

    # 범위 외 변경 - 과도함
    echo "#### 범위 외 변경 - 과도한 변경 (주의!)"
    if [[ -n "$EXCESSIVE_OUT_OF_SCOPE" ]]; then
        echo -e "$EXCESSIVE_OUT_OF_SCOPE" | while read -r line; do
            [[ -n "$line" ]] && echo "  ⚠ $line"
        done
    else
        echo "  (없음)"
    fi
    echo ""
fi

# Diff 통계
echo "=============================================="
echo "### 변경 통계"
echo ""
git diff --stat "${ORIGINAL_BRANCH}" | tail -3
echo ""

# 파일 유형별 분류
echo "### 파일 유형별 분류"
echo ""

# 코드 파일
CODE_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(dart|kt|swift|ts|tsx|js|jsx|py|java|go|rs)$' || true)
if [[ -n "$CODE_FILES" ]]; then
    CODE_COUNT=$(echo "$CODE_FILES" | grep -c . || echo "0")
    echo "코드 파일: ${CODE_COUNT}개"
    echo "$CODE_FILES" | while read -r file; do
        [[ -n "$file" ]] && echo "  - $file"
    done
fi

# 스타일/UI 파일
STYLE_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(css|scss|sass|less|xml|json)$' || true)
if [[ -n "$STYLE_FILES" ]]; then
    STYLE_COUNT=$(echo "$STYLE_FILES" | grep -c . || echo "0")
    echo "스타일/설정 파일: ${STYLE_COUNT}개"
    echo "$STYLE_FILES" | while read -r file; do
        [[ -n "$file" ]] && echo "  - $file"
    done
fi

# 기타 파일
OTHER_FILES=$(echo "$CHANGED_FILES" | grep -vE '\.(dart|kt|swift|ts|tsx|js|jsx|py|java|go|rs|css|scss|sass|less|xml|json)$' || true)
if [[ -n "$OTHER_FILES" ]]; then
    OTHER_COUNT=$(echo "$OTHER_FILES" | grep -c . || echo "0")
    echo "기타 파일: ${OTHER_COUNT}개"
    echo "$OTHER_FILES" | while read -r file; do
        [[ -n "$file" ]] && echo "  - $file"
    done
fi

echo ""

# 잠재적 위험 파일 확인
echo "### 잠재적 주의 파일"
echo ""
RISK_FILES=$(echo "$CHANGED_FILES" | grep -E '(config|env|secret|credential|key|password|token|\.lock|pubspec|package\.json|build\.gradle|Podfile)' || true)
if [[ -n "$RISK_FILES" ]]; then
    echo "다음 파일들은 설정/보안 관련일 수 있으므로 주의 깊게 검토하세요:"
    echo "$RISK_FILES" | while read -r file; do
        [[ -n "$file" ]] && echo "  ⚠ $file"
    done
else
    echo "(특별히 주의가 필요한 파일 없음)"
fi
echo ""

# 상세 Diff 출력
echo "=============================================="
echo "### 상세 변경사항 (Diff)"
echo "=============================================="
echo ""
git diff "${ORIGINAL_BRANCH}" --color=always
