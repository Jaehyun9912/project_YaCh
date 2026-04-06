# Map JSON Schema (v2.1) - Grid Based

이 문서는 게임 내 월드 맵의 노드 구성과 격자 좌표 기반의 자동 경로 판별 및 시각적 연결 시스템을 정의합니다.

### JSON Path

`Data/Map/*.json`

## 1. 파일 구조 ({map_id}.json)

```json
{
  "map_config": {
    "name": "string",
    "theme": "string (e.g., meadow, desert, urban)",
    "background": "res://path/to/map_texture.png",
    "auto_connect_range": 1.5, // 격자 단위 거리 (기본값: 1.0~1.5)
    "grid_size": 32 // UI 렌더링을 위한 한 칸의 픽셀 크기
  },
  "points": {
    "LOCATION_ID": {
      "display_name": "string",
      "type": "settlement | path | dungeon | interest",
      "position": { "x": 0, "y": 0 }, // 맵 격자 상의 정수 좌표
      "visibility": "visible | hidden | fog_of_war",
      "content_id": "string (optional)",
      "unlock_conditions": [
        "node:prev_node_id:state:cleared"
      ],
      "metadata": {
        "has_facility": "boolean",
        "description": "string"
      }
    }
  },
  "navigation_overrides": [
    {
      "from": "node_a",
      "to": "node_b",
      "type": "blocked | one_way | hidden_path",
      "line_style": "default | hazard | shortcut" // UI 연결선 스타일
    }
  ]
}
```

## 2. 주요 항목 설명

### Map Config (맵 설정)

- **auto_connect_range**: 인접한 격자 간의 자동 연결을 판별하는 임계값입니다. 값이 작을수록 인접 노드끼리만 연결됩니다.
- **grid_size**: 격자 좌표를 실제 화면상의 픽셀 위치로 변환할 때 사용되는 배율입니다.

### Points (지역/노드 리스트)

- **type**:
    - `settlement`: 마을이나 도시와 같은 거점 지역.
    - `path`: 거점 사이를 잇는 일반적인 이동 경로.
    - `dungeon`: 내부 맵으로 진입할 수 있는 특수한 지점.
    - `interest`: 아이템 획득이나 특정 이벤트가 발생하는 지점.
- **position**: 맵 상의 논리적 위치를 정수 단위의 격자 좌표로 정의합니다.
- **visibility**:
    - `visible`: 초기부터 맵에 노출됨.
    - `hidden`: 조건 충족 전까지 노드와 경로가 보이지 않음.
    - `fog_of_war`: 위치는 인지할 수 있으나 방문 전까지 세부 정보가 가려짐.

### Navigation Overrides (경로 예외 및 스타일)

- **type**:
    - `blocked`: 좌표상 가깝지만 지형지물에 의해 이동이 차단된 경로.
    - `one_way`: 특정 방향으로만 이동 가능한 경로 (예: 낙하지점).
- **line_style**: 맵 UI에서 노드 사이의 연결선을 그릴 때 참조할 스타일 식별자입니다.

## 3. 작성 예시 (region_main_01.json)

```json
{
  "map_config": {
    "name": "중앙 대륙",
    "auto_connect_range": 1.2,
    "grid_size": 40
  },
  "points": {
    "starting_village": {
      "display_name": "시작의 마을",
      "type": "settlement",
      "position": { "x": 5, "y": 10 }
    },
    "meadow_path_1": {
      "display_name": "들판 길 1",
      "type": "path",
      "position": { "x": 5, "y": 9 },
      "unlock_conditions": ["node:starting_village:state:visited"]
    },
    "north_city": {
      "display_name": "북부 도시",
      "type": "settlement",
      "position": { "x": 5, "y": 8 }
    }
  },
  "navigation_overrides": [
    { "from": "north_city", "to": "meadow_path_1", "type": "one_way", "line_style": "default" }
  ]
}
```

## 4. 시스템 로직 가이드

1. **격자 자동 연결**: 모든 노드를 순회하며 `auto_connect_range` 이내에 있는 인접 노드를 찾아 이동 가능한 경로로 자동 등록합니다.
2. **시각적 경로 생성**: 로드된 경로 정보를 기반으로 맵 UI에 연결선을 렌더링하며, `line_style`을 적용하여 지형적 특징을 표시합니다.
3. **진입 제한 관리**: 플레이어의 상태(아이템, 퀘스트, 노드 방문 여부 등)가 `unlock_conditions`를 만족할 때만 해당 노드로의 이동을 활성화합니다.
