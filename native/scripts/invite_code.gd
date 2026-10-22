extends RefCounted
class_name InviteCode

# Internet invite codes: the host's public IPv4 address and UDP port packed into
# ten characters, "WF-XXXXX-XXXXX". The alphabet leaves out 0/O and 1/I/L so a
# code read aloud or retyped survives. Decoding also accepts lower case, spaces
# and missing dashes.
const ALPHABET="23456789ABCDEFGHJKMNPQRSTUVWXYZ*"

static func encode(address: String,port: int) -> String:
	var parts=address.split(".")
	if parts.size()!=4 or port<=0 or port>65535: return ""
	var value=0
	for part in parts:
		if not part.is_valid_int() or int(part)<0 or int(part)>255: return ""
		value=value*256+int(part)
	value=value*65536+port
	var text=""
	for i in range(10):
		text=ALPHABET[value%32]+text;value=value/32
	return "WF-"+text.substr(0,5)+"-"+text.substr(5,5)

# {"address":..,"port":..} or {} when the text is not a valid code.
static func decode(text: String) -> Dictionary:
	var clean=text.strip_edges().to_upper().replace(" ","").replace("-","")
	if clean.begins_with("WF"): clean=clean.substr(2)
	if clean.length()!=10: return {}
	var value=0
	for character in clean:
		var digit=ALPHABET.find(character)
		if digit<0: return {}
		value=value*32+digit
	var port=value%65536;value=value/65536
	if port==0 or value>=4294967296: return {}
	var octets=[]
	for i in range(4): octets.push_front(str(value%256));value=value/256
	return {"address":".".join(octets),"port":port}

# A router that reports one of these as its "public" address is itself behind
# another network (carrier-grade NAT or a second router): friends cannot reach it.
static func unreachable(address: String) -> bool:
	var parts=address.split(".")
	if parts.size()!=4: return true
	var a=int(parts[0]);var b=int(parts[1])
	return a==10 or a==127 or a==0 or (a==100 and b>=64 and b<=127) or (a==172 and b>=16 and b<=31) or (a==192 and b==168) or (a==169 and b==254)
