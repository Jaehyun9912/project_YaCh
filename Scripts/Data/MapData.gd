## [MapData] 월드 맵 및 지점 정보를 담는 데이터 클래스입니다.
class_name MapData
extends RefCounted

## 맵 전역 설정 클래스
class MapConfig:
	var name: String = ""              # 맵 이름
	var theme: String = "meadow"       # 테마 (meadow, desert 등)
	var background: String = ""        # 배경 텍스처 경로
	var auto_connect_range: float = 1.5 # 자동 연결 범위
	var grid_size: int = 32            # 격자 픽셀 크기

	static func from_dict(dict: Dictionary) -> MapConfig:
		var c = MapConfig.new()
		c.name = dict.get("name", "")
		c.theme = dict.get("theme", "meadow")
		c.background = dict.get("background", "")
		c.auto_connect_range = dict.get("auto_connect_range", 1.5)
		c.grid_size = dict.get("grid_size", 32)
		return c

## 맵의 개별 지점(노드) 클래스
class Point:
	## 지점의 격자 좌표 클래스
	class Position:
		var x: float = 0
		var y: float = 0

		static func from_dict(dict: Dictionary) -> Position:
			var p = Position.new()
			p.x = dict.get("x", 0)
			p.y = dict.get("y", 0)
			return p

	## 추가 메타데이터 클래스
	class Metadata:
		var has_facility: bool = false # 시설 존재 여부
		var description: String = ""   # 지점 상세 설명

		static func from_dict(dict: Dictionary) -> Metadata:
			var m = Metadata.new()
			m.has_facility = dict.get("has_facility", false)
			m.description = dict.get("description", "")
			return m

	var id: String = ""                # 지점 고유 ID
	var display_name: String = ""      # 표시 이름
	var type: String = "path"          # 유형 (settlement, path, dungeon 등)
	var position: Position             # 좌표 정보
	var visibility: String = "visible" # 가시성 (visible, hidden, fog_of_war)
	var content_id: String = ""        # 연결된 콘텐츠 ID (전투 ID 등)
	var unlock_conditions: Array[String] = [] # 해금 조건 리스트
	var metadata: Metadata             # 메타데이터 정보

	static func from_dict(point_id: String, dict: Dictionary) -> Point:
		var p = Point.new()
		p.id = point_id
		p.display_name = dict.get("display_name", "")
		p.type = dict.get("type", "path")
		p.position = Position.from_dict(dict.get("position", {}))
		p.visibility = dict.get("visibility", "visible")
		p.content_id = dict.get("content_id", "")
		p.unlock_conditions = []
		for s in dict.get("unlock_conditions", []):
			p.unlock_conditions.append(str(s))
		p.metadata = Metadata.from_dict(dict.get("metadata", {}))
		return p

## 경로 예외 및 스타일 설정 클래스
class NavigationOverride:
	var from: String = ""              # 시작 노드 ID
	var to: String = ""                # 대상 노드 ID
	var type: String = "blocked"       # 경로 특성 (blocked, one_way 등)
	var line_style: String = "default" # UI 연결선 스타일

	static func from_dict(dict: Dictionary) -> NavigationOverride:
		var n = NavigationOverride.new()
		n.from = dict.get("from", "")
		n.to = dict.get("to", "")
		n.type = dict.get("type", "blocked")
		n.line_style = dict.get("line_style", "default")
		return n

var config: MapConfig                  # 전역 설정
var points: Dictionary = {}            # 지점 리스트 (Key: ID, Value: Point)
var navigation_overrides: Array[NavigationOverride] = [] # 경로 예외 리스트

static func from_dict(dict: Dictionary) -> MapData:
	var m = MapData.new()
	m.config = MapConfig.from_dict(dict.get("map_config", {}))
	
	m.points = {}
	var points_dict = dict.get("points", {})
	for p_id in points_dict:
		m.points[p_id] = Point.from_dict(p_id, points_dict[p_id])
		
	m.navigation_overrides = []
	for n_dict in dict.get("navigation_overrides", []):
		m.navigation_overrides.append(NavigationOverride.from_dict(n_dict))
		
	return m
