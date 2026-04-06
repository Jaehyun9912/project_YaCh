# Quest JSON Schema Documentation

이 문서는 NPC별 퀘스트 목록을 정의하고 관리하기 위한 JSON 구조 및 조건/명령문 포맷을 정의합니다.

### JSON Path
`Data/Quest/*.json`

---

## 1. 파일 구조 (Root: NPC Name Map)

```json
{
  "NPC_NAME": [
    {
      "id": "quest_id_01",
      "title": "퀘스트 이름",
      "description": "퀘스트 전체 설명",
      "clear_NPC": "완료 보고를 받을 NPC 이름",
      "accept_condition": ["조건문1", "조건문2"],
      "process_condition": {
        "조건문1": "조건에 대한 UI 표시 설명"
      },
      "tokens": ["명령문1", "명령문2"],
      "submits": {
        "명령문1": "제출 아이템에 대한 설명"
      },
      "rewards": ["명령문1", "명령문2"]
    }
  ]
}
```

---

## 2. 주요 항목 상세 설명

### 기본 정보
- **id**: 퀘스트 고유 식별자.
- **title**: 게임 내 퀘스트 목록에 표시될 제목.
- **description**: 퀘스트의 배경 및 상세 설명.
- **clear_NPC**: 퀘스트 목표 달성 후 대화해야 하는 대상 NPC.

### 조건 및 로직 (Conditions)
- **accept_condition**: 퀘스트를 수주(시작)하기 위해 만족해야 하는 조건 리스트.
- **process_condition**: 퀘스트 목표 달성 여부를 체크하는 조건 리스트. (Key: 조건문, Value: UI 표시용 텍스트)

### 보상 및 소모 (Actions)
- **tokens**: 퀘스트 수주 시 즉시 지급되는 아이템이나 효과 리스트.
- **submits**: 퀘스트 완료 시 소모(제출)해야 하는 아이템 리스트. (Key: 명령문, Value: UI 표시용 텍스트)
- **rewards**: 퀘스트 완료 시 최종적으로 지급되는 보상 리스트.

---

## 3. 조건문/명령문 포맷 가이드

모든 조건과 명령은 특정 접두사(Prefix)와 연산자를 사용한 문자열로 작성합니다.

### A. 조건문 (Accept / Process Condition)
- **태그**: `tag:태그값[>/</=]개수` (예: `tag:Quest.clear>1`, `Quest.clear`)
- **아이템**: `item:아이템ID[>/</=]개수` (예: `item:bomb>5`)
- **아티팩트**: `artifact:아티팩트ID`
- **스탯**: `stat:스탯명[>/</=]수치` (예: `stat:str>10`)
- **재화**: `money:재화종류[>/</=]금액` (예: `money:gold>=100`)
- **평판**: `renown:길드ID[>/</=]수치` (예: `renown:warrior>50`)
- **맵 해금**: `map:맵이름:지역이름`

### B. 명령문 (Tokens / Submits / Rewards)
조건문 포맷을 기반으로 하되, 부등호 대신 증감 연산자를 사용합니다.
- **획득 (+)**: `item:potion+1`, `money:gold+500`
- **소모 (-)**: `item:bomb-1`, `money:gold-100`
- **활성화/토글 (!)**: `!artifact:ring_of_power`, `!map:forest:entrance` (아티팩트 장착이나 맵 해금 시 사용)

---

## 4. 작성 예시

```json
{
  "Blacksmith": [
    {
      "id": "collect_iron",
      "title": "철광석 수집",
      "description": "대장간 일을 돕기 위해 철광석 5개를 모아오세요.",
      "clear_NPC": "Blacksmith",
      "accept_condition": ["stat:str>5", "money:gold>=10"],
      "process_condition": {
        "item:iron_ore>=5": "철광석 5개 수집"
      },
      "submits": {
        "item:iron_ore-5": "철광석 5개"
      },
      "rewards": ["money:gold+100", "tag:Quest.Blacksmith.Help+1"]
    }
  ]
}
```
