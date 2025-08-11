extends BagContent
class_name CountableItem


# 사용하기
func use() -> bool:
	if true:
		#기능 실행
		discard()
		return true
	return false

# 버리기
func discard() -> bool:
	if data.has("count"):
		data["count"] -=1
		print(data)
		if data["count"] ==0:
			return true
	return false
	
