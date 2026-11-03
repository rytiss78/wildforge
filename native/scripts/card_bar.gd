extends Control
class_name CardBar

# The four card slots (big update MB) beside the weapon bar: each held card's
# stat medallion with its level; empty slots are dim outlines. Name and level
# in the tooltip, nothing else written.

const TILE=Vector2(54,62)
const GAP=8.0
var game
var signature=""

func _init():
	mouse_filter=Control.MOUSE_FILTER_PASS
	custom_minimum_size=Vector2(TILE.x*Loadout.CARD_SLOTS+GAP*(Loadout.CARD_SLOTS-1),TILE.y)

func refresh():
	if game==null: return
	var now=str(game.cards)
	if now==signature: return
	signature=now
	var parts=[]
	for stat in game.cards: parts.append("%s Lv %d" % [Loadout.CARDS[stat].name,int(game.cards[stat])])
	tooltip_text="Cards %d/%d" % [game.cards.size(),Loadout.CARD_SLOTS]+("\n"+"\n".join(parts) if not parts.is_empty() else "")
	queue_redraw()

func _draw():
	if game==null: return
	var font=ThemeDB.fallback_font;var stats=game.cards.keys()
	for i in range(Loadout.CARD_SLOTS):
		var rect=Rect2(Vector2(i*(TILE.x+GAP),0),TILE)
		var look=StyleBoxFlat.new();look.set_corner_radius_all(8);look.set_border_width_all(2)
		if i<stats.size():
			look.bg_color=Color(.1,.12,.16,.85);look.border_color=ThemeTokens.STAR_GOLD
			draw_style_box(look,rect)
			StatGlyphs.draw_medallion(self,str(stats[i]),rect.position+Vector2(TILE.x*.5,24),19)
			draw_string_outline(font,Vector2(rect.position.x,rect.end.y-5),str(int(game.cards[stats[i]])),HORIZONTAL_ALIGNMENT_CENTER,TILE.x,15,4,Color(0,0,0,.85))
			draw_string(font,Vector2(rect.position.x,rect.end.y-5),str(int(game.cards[stats[i]])),HORIZONTAL_ALIGNMENT_CENTER,TILE.x,15,Color("fff0c9"))
		else:
			look.bg_color=Color(.1,.12,.16,.35);look.border_color=Color(ThemeTokens.STAR_GOLD,.3)
			draw_style_box(look,rect)
			draw_string(font,Vector2(rect.position.x,rect.position.y+TILE.y*.5+7),"+",HORIZONTAL_ALIGNMENT_CENTER,TILE.x,20,Color(1,1,1,.25))
