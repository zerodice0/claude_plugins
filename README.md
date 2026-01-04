# zerodice0-plugins

> zerodice0's Claude Code plugin collection

[English](#english) | [한국어](#한국어)

---

## English

A collection of Claude Code plugins developed by zerodice0.

### Available Plugins

| Plugin | Description |
|--------|-------------|
| [gemini-design-updater](./plugins/gemini-design-updater/) | Safe design update workflow using Gemini Pro with Claude review |
| [gemini-image-generator](./plugins/gemini-image-generator/) | Generate app assets (icons, backgrounds, UI elements) using Gemini 3 Pro |

### Installation

```bash
# Add marketplace
/plugin marketplace add zerodice0/zerodice0-plugins

# Install plugin
/plugin install gemini-design-updater@zerodice0-plugins
```

### Requirements

- Claude Code CLI
- Git 2.0+
- Bash 4.0+

### License

MIT License - see [LICENSE](./LICENSE) for details.

---

## 한국어

zerodice0가 개발한 Claude Code 플러그인 모음입니다.

### 사용 가능한 플러그인

| 플러그인 | 설명 |
|----------|------|
| [gemini-design-updater](./plugins/gemini-design-updater/) | Gemini Pro를 활용한 안전한 디자인 업데이트 워크플로우 |
| [gemini-image-generator](./plugins/gemini-image-generator/) | Gemini 3 Pro를 활용한 앱 에셋(아이콘, 배경, UI 요소) 생성 |

### 설치 방법

```bash
# Marketplace 추가
/plugin marketplace add zerodice0/zerodice0-plugins

# 플러그인 설치
/plugin install gemini-design-updater@zerodice0-plugins
```

### 요구사항

- Claude Code CLI
- Git 2.0+
- Bash 4.0+

### 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](./LICENSE)를 참조하세요.

---

## Changelog

### 2026-01-04

- **[CLA-17]** Added short-form trigger keywords to gemini-design-updater skill
  - Added: "gemini-design", "gemini-design 스킬", "gemini-design skill", "gemini-design 사용", "use gemini-design"
  - Issue: Skill was not triggered when using short-form keywords like "gemini-design"

---

## Contributing

Issues and Pull Requests are welcome!

## Author

- **zerodice0** - [GitHub](https://github.com/zerodice0)
