#!/bin/bash
# cleanup-branch.sh - 작업 브랜치 정리 스크립트
# Gemini 작업 브랜치를 삭제하고 원래 브랜치로 복귀합니다.
#
# 사용법: ./cleanup-branch.sh <original_branch> <work_branch> [--force]
# 옵션:
#   --force: 확인 없이 강제 삭제

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 인자 확인
if [[ $# -lt 2 ]]; then
    echo "사용법: $0 <original_branch> <work_branch> [--force]" >&2
    exit 1
fi

ORIGINAL_BRANCH="$1"
WORK_BRANCH="$2"
FORCE_MODE="${3:-}"

# 브랜치 존재 확인
if ! git show-ref --verify --quiet "refs/heads/${ORIGINAL_BRANCH}"; then
    echo -e "${RED}Error: 원래 브랜치를 찾을 수 없습니다: ${ORIGINAL_BRANCH}${NC}" >&2
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)

# 현재 작업 브랜치에 있는지 확인
if [[ "$CURRENT_BRANCH" == "$WORK_BRANCH" ]]; then
    # 원래 브랜치로 전환
    echo "원래 브랜치로 전환 중: ${ORIGINAL_BRANCH}"
    if ! git checkout "$ORIGINAL_BRANCH" 2>/dev/null; then
        echo -e "${RED}Error: 브랜치 전환 실패${NC}" >&2
        exit 1
    fi
fi

# 작업 브랜치 존재 확인
if ! git show-ref --verify --quiet "refs/heads/${WORK_BRANCH}"; then
    echo -e "${YELLOW}작업 브랜치가 이미 삭제되었거나 존재하지 않습니다: ${WORK_BRANCH}${NC}"
    exit 0
fi

# 강제 모드가 아닌 경우 확인
if [[ "$FORCE_MODE" != "--force" ]]; then
    echo ""
    echo -e "${YELLOW}다음 브랜치를 삭제합니다:${NC}"
    echo "  브랜치: ${WORK_BRANCH}"
    echo ""
    echo "이 작업은 되돌릴 수 없습니다."
    echo ""
    read -p "정말 삭제하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi
fi

# 브랜치 삭제
echo "작업 브랜치 삭제 중: ${WORK_BRANCH}"
if git branch -D "$WORK_BRANCH" 2>/dev/null; then
    echo -e "${GREEN}성공: 작업 브랜치가 삭제되었습니다.${NC}"
    echo ""
    echo "현재 브랜치: $(git branch --show-current)"
else
    echo -e "${RED}Error: 브랜치 삭제 실패${NC}" >&2
    exit 1
fi
