## [QuestData] 퀘스트 정보를 담는 데이터 클래스입니다.
class_name QuestData
extends RefCounted

var id: String = ""                    # 퀘스트 고유 ID
var title: String = ""                 # 퀘스트 제목
var description: String = ""           # 퀘스트 전체 설명
var clear_NPC: String = ""             # 완료 보고를 받을 NPC 이름
var accept_condition: Array[String] = [] # 수주 조건 (포맷: "tag:val>1" 등)
var process_condition: Dictionary = {} # 진행/달성 조건 (Key: 조건문, Value: 설명)
var tokens: Array[String] = []         # 수주 시 즉시 획득물
var submits: Dictionary = {}           # 완료 시 제출할 아이템 (Key: 명령문, Value: 설명)
var rewards: Array[String] = []        # 최종 완료 보상 리스트

static func from_dict(dict: Dictionary) -> QuestData:
	var q = QuestData.new()
	q.id = dict.get("id", "")
	q.title = dict.get("title", "")
	q.description = dict.get("description", "")
	q.clear_NPC = dict.get("clear_NPC", "")
	
	q.accept_condition = []
	for s in dict.get("accept_condition", []):
		q.accept_condition.append(str(s))
		
	q.process_condition = dict.get("process_condition", {})
	
	q.tokens = []
	for s in dict.get("tokens", []):
		q.tokens.append(str(s))
		
	q.submits = dict.get("submits", {})
	
	q.rewards = []
	for s in dict.get("rewards", []):
		q.rewards.append(str(s))
		
	return q
