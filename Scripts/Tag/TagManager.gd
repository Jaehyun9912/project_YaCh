extends Node

var dict : Dictionary
#노드 오브젝트(key) : 딕셔너리(문자열 : 카운트)

func get_tags(node : Node)-> PackedStringArray:
	#노드가 가지고 있는 태그 반환
	if dict.has(node):
		return dict[node].keys()
	#없으면 새 딕셔너리 반환
	return PackedStringArray()

func get_tag_tree(node :Node, tag : String) -> PackedStringArray:
	if dict.has(node):
		if dict[node].has(tag):
			return dict[node][tag]
	return PackedStringArray()

#노드에 태그가 붙은 횟수 반환
func get_tag_count(node : Node, tag : String)-> int:
	if has_tag(node,tag):
		return dict[node][tag]
	#없으면 0 반환
	return 0

#단일 태그 추가(외부 사용 X)
func add_tag(node : Node, tag : String, count = 1) -> void:
	#태그가 1개 이상 있을 경우
	if dict.has(node):
		var tags = dict[node] as Dictionary
		#태그를 가지고 있을 경우 count 추가
		if tags.has(tag):
			tags[tag]+=count
			return
		#태그 추가
		tags[tag] = count
	else:
		#없으면 태그 딕셔너리 추가
		var arr = { tag : count}
		dict[node] = arr

#태그 트리 추가(.으로 구분해서 상위부터 하위태그까지 전부 추가)
func add_tag_tree(node : Node, tag : String, count =1):
	#해당 태그를 각 태그 부분으로 분류
	var tag_tree = tag.split(".")
	
	#상위 태그부터 .하위태그 추가
	var lower_tag = tag_tree[0]
	tag_tree.remove_at(0)
	add_tag(node,lower_tag,count)
	for str in tag_tree:
		lower_tag += "." + str
		add_tag(node,lower_tag,count)

#단일 태그 제거 성공 시 true 실패 시 false
func remove_tag(node : Node, tag : String) -> bool:
	if dict.has(node):
		var tags = dict[node] as Dictionary
		#태그가 있으면 제거
		tags.erase(tag)
		#print(tags)
		return true
	return false


#태그 제거 시 하위 태그도 동시에 제거(하위 태그는 상위태그.태그로 구분)
#하위 태그 삭제 시 상위태그를 동시에 작성 요망(상위태그.하위태그)
func remove_tag_tree(node : Node, tag : String) -> bool:
	#시작 태그가 있으면 삭제 없으면 반환
	var count = get_tag_count(node,tag)
	if !remove_tag(node,tag):
		return false
	var tags = dict[node] as Dictionary
	#상위태그 존재시 모든 태그 순회 후 하위태그 삭제
	for str in tags.keys():
		var upper_tag = tag + "."
		#해당 태그가 상위태그로 시작하면 제거
		if str.begins_with(upper_tag):
			remove_tag(node,str)
	#삭제한 태그의 상위 태그에 카운트 값 감소
	decrease_tag_tree(node,get_upper_tag(tag),count)
	return true
	

#해당 태그가 있는지 확인
func has_tag(node : Node, tag : String) -> bool:
	#해당 노드가 태그가 없을 경우 false 반환
	if !dict.has(node):
		return false
	var tags = dict[node] as Dictionary
	#찾는 태그가 있을 경우 true 반환
	if tags.has(tag):
		return true
	#태그가 없으면 false
	return false
	
#태그 일정 부분으로 해당 태그 찾기
func find_tag(node : Node, tag : String) -> String:
	var tags = get_tags(node)
	tag = "." + tag
	for i in tags:
		#해당 태그를 가지고 있으면 반환(앞뒤로 .추가해서 단어속 태그 방지)
		if i.ends_with(tag):
			return i
	return String()



#앞의 !비교해서 있으면 뒤의 값비교가 false일때 true 반환
func tag_check(node : Node, tag : String):
	var negative = false
	if tag.begins_with("!"):
		tag = tag.split("!",true,2)[1]
		negative = true
	var check = tag_compare(node,tag)
	#print(tag," is ","Negative : ",negative," , TagCompare : ",check)
	return check != negative
	
#태그의 부등호 비교해서 충족 시 true 반환
func tag_compare(node : Node,tag : String) -> bool:
	#퀘스트에 필요한 태그 확인(부등호로 태그 카운트 세기)
	var comparer = [">" , "<", "="]#필요하면 이상 이하도 추가
	for i in comparer:
		var str = tag.split(i,true,2)
		if str.size()==2:
			print(TagManager.get_tag_count(node,str[0])," ",i," ",str[1])
			#태그가 있는지 없는지부터 확인
			if !TagManager.has_tag(node,str[0]):
				return false
			if i == ">" && TagManager.get_tag_count(node,str[0]) > str[1].to_int():
				return true
			if i == "<" && TagManager.get_tag_count(node,str[0]) < str[1].to_int():
				return true
			if i == "=" && TagManager.get_tag_count(node,str[0]) == str[1].to_int():
				return true
	#태그가 있는지 없는지만 확인(태그에 부등호가 없는경우)
	if TagManager.has_tag(node,tag):
		return true
	return false
	
#씬 로드 될때 할당 해제된 노드 제거
func clean_dict():
	for i in dict.keys():
		if i == null:
			print(i)
			dict.erase(i)

#태그의 카운트 1 감소. 0이면 태그 삭제
func decrease_tag(node : Node, tag : String, count = 1) -> int:
	if !dict.has(node):
		return 0
	var tags = dict[node] as Dictionary
	if !tags.has(tag):
		return 0
	tags[tag] -=count
	if tags[tag] <=0 :
		remove_tag(node,tag)
		return 0
	return tags[tag]

#하위 태그부터 하나씩 카운트 만큼 감소(0보다 작아지면 해당 태그 삭제)
func decrease_tag_tree(node : Node, tag :String, count = 1):
	decrease_tag(node,tag,count)
	var upper_tag = get_upper_tag(tag)
	if upper_tag == "":
		return
	decrease_tag_tree(node,upper_tag,count)

func get_upper_tag(tag : String):
	var s = tag.reverse()
	var str = s.split(".",true,1)
	if str.size() < 2:
		return ""
	return str[1].reverse()
	



