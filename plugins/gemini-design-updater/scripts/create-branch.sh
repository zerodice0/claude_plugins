#!/bin/bash
# create-branch.sh - Git 브랜치 생성 스크립트
# Gemini 작업을 위한 격리된 브랜치를 생성합니다.
#
# 사용법: ./create-branch.sh
# 출력: JSON {"original_branch": "...", "work_branch": "...", "status": "success|error"}

set -euo pipefail

# 색상 정의
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 에러 출력 함수
error_exit() {
    echo "{\"status\": \"error\", \"message\": \"$1\"}"
    exit 1
}

# Git 저장소 확인
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error_exit "현재 디렉토리가 Git 저장소가 아닙니다."
fi

# uncommitted changes 확인
if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    echo -e "${YELLOW}Warning: uncommitted changes가 있습니다.${NC}" >&2
    echo -e "${YELLOW}변경사항을 commit하거나 stash하세요:${NC}" >&2
    echo -e "  git stash push -m 'before-gemini'" >&2
    echo -e "  git add . && git commit -m 'WIP: before gemini update'" >&2
    error_exit "uncommitted changes가 있습니다. commit 또는 stash 후 다시 시도하세요."
fi

# 현재 브랜치 저장
ORIGINAL_BRANCH=$(git branch --show-current 2>/dev/null)
if [[ -z "$ORIGINAL_BRANCH" ]]; then
    # detached HEAD 상태
    ORIGINAL_BRANCH=$(git rev-parse --short HEAD)
fi

# 타임스탬프로 고유 브랜치명 생성
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
WORK_BRANCH="gemini-design-${TIMESTAMP}"

# 브랜치 이름 충돌 확인
if git show-ref --verify --quiet "refs/heads/${WORK_BRANCH}"; then
    # 밀리초 추가
    WORK_BRANCH="gemini-design-${TIMESTAMP}-$(date +%N | cut -c1-3)"
fi

# 작업 브랜치 생성 및 전환
if ! git checkout -b "$WORK_BRANCH" 2>/dev/null; then
    error_exit "브랜치 생성 실패: ${WORK_BRANCH}"
fi

# 성공 결과 출력
echo "{\"status\": \"success\", \"original_branch\": \"${ORIGINAL_BRANCH}\", \"work_branch\": \"${WORK_BRANCH}\"}"
