"""Builds assets/story/act1.json from the Act I scenes in the story bible."""
import json

FIRST_VISIT = "!(seen.a1_house || seen.a1_square || seen.a1_cove)"
SALT_WORKS = "The old salt works, three days up the coast: where the buyer's men collect."


def c(cid, text, to=None, **kw):
    d = {"id": cid, "text": text}
    if to:
        d["nextNodeId"] = to
    d.update(kw)
    return d


def p(text, cond=None):
    return {"if": cond, "text": text} if cond else text


nodes = {}


def node(nid, title, paragraphs, choices=(), on_enter=None):
    n = {"id": nid, "title": title, "paragraphs": list(paragraphs), "choices": list(choices)}
    if on_enter:
        n["onEnter"] = on_enter
    nodes[nid] = n


# ─── Scene 1 ──────────────────────────────────────────────────────────────────
node("a1_hills", "THE HILLS ABOVE SALTMERE", [
    "It is your third night in the hills. The boats came back light this autumn, the reeve still wants his tithe, and meat would carry you and {sister} past the first frost. Your snares run along the pine ridge, past the old shrine of Lavrith where nobody leaves offerings any more.",
    "The last snare holds a vixen. Her foreleg is torn to the bone, and three kits watch you from the bracken without a sound. A good pelt fetches twenty crowns at the market. You kneel and draw your knife.",
    "That is when you see the light below. Fire on the coast. Not one fire but a string of them, six or seven, glowing along the shore from south to north. The nearest is Saltmere.",
], [
    c("run", "Leave everything and run", "a1_return", effects=["flag ran_at_once"],
      result="You leave the snares, the vixen and the night behind, and run."),
    c("free", "Cut the vixen free, then run", "a1_return", effects=["mercy +1", "flag freed_vixen"],
      result="She limps into the bracken, and her kits go after her. Then you run."),
    c("pelt", "Kill her cleanly and take the pelt", "a1_return", effects=["crowns +20", "flag took_pelt"],
      result="Twenty crowns of fur, rolled under your arm. The kits watch you go."),
    c("watch", "Watch the fires before you go", "a1_return",
      needs="attr.insight >= 12", needsLabel="Insight 12",
      effects=["leads +1", "journal The coast fires were lit south to north, hours apart. Someone is working up the coast."],
      result="They were lit in order, south to north, a few hours apart. Someone is working their way up the coast."),
])

# ─── Scene 2: the hub ─────────────────────────────────────────────────────────
node("a1_return", "SALTMERE AT DAWN", [
    p("You run the goat path down in the dark, falling twice. You reach the dunes before dawn. Out in the cove a last longboat is pulling away, its lantern hooded.", "ran_at_once && " + FIRST_VISIT),
    p("You run the goat path down in the dark, falling twice. By the time you reach the dunes the sun is up, and the sea is empty.", "!ran_at_once && " + FIRST_VISIT),
    p("Saltmere is still burning. The jetty is gone to the waterline and every boat that floated is holed or taken. Garrick the cooper sits on his own doorstep as if resting, and does not answer when you say his name.", FIRST_VISIT),
    p("Your door hangs from one hinge. {sister}'s bed is empty and her shawl is on the floor, trodden into the ashes. From the square you hear Old Brena counting names aloud, and someone weeping. Down at the cove, the sand is churned with footprints and the long grooves of keels.", FIRST_VISIT),
    p("You stand in the lane between the burnt houses. Smoke still hangs over the roofs, and the day is wearing on.", "!(" + FIRST_VISIT + ")"),
], [
    c("house", "Search your house", "a1_house", **{"if": "!seen.a1_house"}),
    c("square", "Go to the square, to the survivors", "a1_square", **{"if": "!seen.a1_square"}),
    c("cove", "Follow the tracks down to the cove", "a1_cove", **{"if": "!seen.a1_cove"}),
    c("shout", "Shout {sister}'s name until your voice breaks", "a1_square_tam", once=True,
      effects=["sanity -5", "bond.tam +1"], result="Nobody answers but Tam, who comes running across the ashes.",
      **{"if": "!seen.a1_square"}),
    c("night_cove", "Wait for nightfall", "a1_dusk", **{"if": "seen.a1_cove"}),
    c("night", "Wait for nightfall", "a1_pyre", **{"if": "!seen.a1_cove"}),
], on_enter=["sanity -5"])

# ─── Scene 3: your house, in short beats ─────────────────────────────────────
HOUSE_DONE = "house_frame || house_chest || house_hearth"
node("a1_house", "YOUR HOUSE", [
    p("The table is split and every pot is smashed. Someone turned this house over in a hurry, looking for something, or someone.", "!(" + HOUSE_DONE + ")"),
    p("You stand in the middle of the room your family lived in. It is very quiet.", HOUSE_DONE),
], [
    c("frame", "Kneel by the doorframe", "a1_house_frame", **{"if": "!house_frame"}),
    c("chest", "Open your mother's chest", "a1_house_chest", **{"if": "!house_chest"}),
    c("hearth", "Lift the hearthstone", "a1_house_hearth", **{"if": "!house_hearth"}),
    c("out", "Go back outside", "a1_return", **{"if": HOUSE_DONE}),
])

node("a1_house_frame", "YOUR HOUSE", [
    "Low on the doorframe, where {sister} marks her height each spring, there are fresh scratches. She must have done it with a nail while they held her, the letters crooked and deep: THEY HAD A LIST.",
    "Not a raid for plunder, then. They came for particular people, and she was one of them. Her shawl lies at your feet, trodden into the ash.",
], [
    c("shawl", "Take her shawl", "a1_house",
      effects=["sanity +5", "flag has_shawl"], result="It still smells of woodsmoke and of her."),
    c("leave_shawl", "Leave it where it fell", "a1_house"),
], on_enter=["flag house_frame", "leads +1", "flag knows_list",
             "journal They had a list. The raiders came for particular people."])

node("a1_house_chest", "YOUR HOUSE", [
    "Your mother's chest has been forced open and its blankets thrown out. At the bottom lies the one thing she never let you touch: a black iron pin, plain and heavy, that she wore at her throat and never explained.",
    "The morning is cold, but the pin is warm in your hand.",
], [
    c("pin", "Pin it at your throat, where she wore it", "a1_house",
      effects=["flag has_iron_pin"], result="It stays warm against your skin."),
    c("leave_pin", "Put it back and close the lid", "a1_house"),
], on_enter=["flag house_chest"])

node("a1_house_hearth", "YOUR HOUSE", [
    "The tin under the hearthstone is still there, coins and all: thirty-five crowns, everything your family saved. Whoever came here was not looking for money.",
], [
    c("tin", "Take the coins", "a1_house", effects=["crowns +35"], result="Thirty-five crowns, heavy in your pocket."),
    c("leave_tin", "Leave them for whoever comes back", "a1_house", effects=["mercy +1"],
      result="Somebody in Saltmere will need them more than you."),
], on_enter=["flag house_hearth"])

# ─── Scene 4: the square, in short beats ─────────────────────────────────────
SQ_DONE = "sq_brena || sq_tam"
node("a1_square", "THE SQUARE", [
    p("The living have gathered around the well: maybe forty of them, sooty and quiet. Old Brena sits on the well's lip with a slate, scratching marks. Nine dead. Seven children taken. When she sees you, she adds no mark, which is how you learn {sister} is not among the dead.", "!sq_brena"),
    p("The wounded lie in a row under the net-shed roof.", "!sq_brena"),
    p("Tam sits apart from everyone, both hands wrapped in wet sailcloth.", "!sq_tam"),
    p("The square has gone quiet. Brena is back at her slate.", "sq_brena"),
], [
    c("help", "Help with the wounded", "a1_square_help", **{"if": "!sq_brena"}),
    c("ask", "Ask Brena what she saw", "a1_square_ask", **{"if": "!sq_brena"}),
    c("tam", "Go and sit with Tam", "a1_square_tam", **{"if": "!sq_tam"}),
    c("steal", "Slip into the common store while everyone is busy", "a1_square", once=True,
      **{"if": SQ_DONE}, check="attr.dexterity >= 11",
      effects=["flag stole_from_store", "flag has_food"], result="Three days of food in a sack, and nobody saw.",
      failEffects=["flag stole_from_store", "flag has_food", "rep.fisherfolk -2"],
      failResult="Brena sees you, and says nothing. Everyone else sees her see you."),
    c("back", "Go back", "a1_return", **{"if": SQ_DONE}),
])

node("a1_square_help", "THE SQUARE", [
    "Nobody has boiled water yet, so you do. By noon your hands are red to the wrist and two of the burned are sleeping instead of screaming.",
    "Brena brings you a cup of broth and sits beside you on the step. \"There was a clerk with them,\" she says quietly. \"Grey coat. An iron-bound ledger. He read names off it, and they went to those doors.\" She looks at her slate. \"Every child they took had lived through the fever. Every one.\"",
], [
    c("well", "Go back to the well", "a1_square"),
], on_enter=["flag sq_brena", "rep.fisherfolk +1", "sanity -5", "leads +2", "flag knows_fever_link",
             "journal A clerk in a grey coat read names from an iron-bound ledger.",
             "journal Every child taken had survived the night fever."])

node("a1_square_ask", "THE SQUARE", [
    "Brena doesn't look up from her slate. \"A clerk,\" she says. \"Grey coat. Iron-bound ledger. He read names.\"",
    "When you ask what names, she rubs out a mark and makes it again, harder. \"I have nine to bury, {name}. Ask me tomorrow.\"",
], [
    c("well", "Leave her to it", "a1_square"),
], on_enter=["flag sq_brena", "leads +1",
             "journal A clerk in a grey coat read names from an iron-bound ledger."])

node("a1_square_tam", "THE SQUARE", [
    "Tam's little brother was one of the seven. Tam doesn't look at you, only at the sea. \"{name}. They went from house to house like they knew which doors to kick.\"",
    "\"I'm going after them. With you or without you.\"",
], [
    c("promise", "\"We'll bring them back. All seven.\"", "a1_square_tam_reply",
      effects=["mercy +1", "bond.tam +1", "flag promised_tam"]),
    c("vengeance", "\"They'll pay for this. Every one of them.\"", "a1_square_tam_reply",
      effects=["mercy -1", "bond.tam +1", "flag swore_vengeance"]),
    c("stay", "\"Stay. Your mother has already lost one child.\"", "a1_square_tam_reply",
      effects=["bond.tam -1", "flag told_tam_to_stay"]),
], on_enter=["flag sq_tam", "bond.tam +1", "flag tam_wants_to_come"])

node("a1_square_tam_reply", "THE SQUARE", [
    p("Tam looks at you then, properly, for the first time. \"All seven. I'll hold you to that.\"", "promised_tam"),
    p("Tam's jaw sets. \"Every one,\" Tam says, and you are of one mind.", "swore_vengeance"),
    p("Tam stares at you as if you had struck them. \"She lost two. You don't get to decide which of us she keeps.\"", "told_tam_to_stay"),
], [
    c("well", "Get up and leave Tam to the sea", "a1_square"),
])

# ─── Scene 5: the cove, as a conversation ────────────────────────────────────
ASKED_ALL = "cove_asked_name && cove_asked_sister && cove_asked_threat"
node("a1_cove", "THE COVE", [
    "The footprints go down to the waterline and stop. Four keels, maybe five.",
    p("Far out, the last longboat's sail catches the light: a red hand painted on grey canvas, heading north.", "ran_at_once"),
    "Among the rocks at the cove's mouth lies a raider his crew left behind, a fishing gaff through his thigh. Someone in Saltmere fought back. He is young, younger than you, with a grinning mouth tattooed on his wrist: Tenudaq's mark, the thieves' god. He sees your knife and lifts empty hands.",
    "\"Please. I only rowed. I know where they're going. I'll tell you, just don't leave me for the tide.\"",
], [
    c("name", "\"What's your name?\"", "a1_cove_name"),
    c("sister", "\"My sister was in one of those boats.\"", "a1_cove_sister"),
    c("threat", "\"Give me one reason not to drown you.\"", "a1_cove_threat"),
], on_enter=[{"if": "ran_at_once", "do": ["leads +1", "journal A red hand on a grey sail, heading north."]}])

# The rest of the conversation: whatever you haven't said yet, or the question that matters.
def cove_talk():
    return [
        c("name", "\"What's your name?\"", "a1_cove_name", **{"if": "!cove_asked_name"}),
        c("sister", "\"My sister was in one of those boats.\"", "a1_cove_sister", **{"if": "!cove_asked_sister"}),
        c("threat", "\"Give me one reason not to drown you.\"", "a1_cove_threat", **{"if": "!cove_asked_threat"}),
        c("where", "\"Where are they taking them?\"", "a1_cove_where"),
    ]

node("a1_cove_name", "THE COVE", [
    "\"Corrin.\" He tries to smile and it goes wrong. \"I'm not a fighter. I row. A woman came out of a doorway with that gaff and I didn't even see her.\"",
    "He has a name now, and so does whatever you do next.",
], cove_talk(), on_enter=["flag cove_asked_name", "flag knows_rowers_name", "mercy +1"])

node("a1_cove_sister", "THE COVE", [
    "He goes pale under the dirt. \"The children are kept apart from the others. Nobody's allowed to touch them. The buyer's men want them whole, not a mark on them.\"",
    "She is alive, then. For now.",
], cove_talk(), on_enter=["flag cove_asked_sister", "sanity +5", "leads +1",
                          "journal The children are kept apart. The buyer's men want them whole and unmarked."])

node("a1_cove_threat", "THE COVE", [
    "\"Because I'm no Rowgan!\" It comes out of him in a rush. \"I owed money in Riverend. They bought my debt and chained me to an oar. I've been rowing for them since spring.\"",
    "He might be lying. The tide is coming in either way.",
], cove_talk(), on_enter=["flag cove_asked_threat", "flag rower_pressganged", "mercy -1"])

node("a1_cove_where", "THE COVE", [
    "He looks at the water creeping up the rocks, then at you. \"The old salt works. Three days up the coast, past the river mouth. That's where the buyer's men collect.\"",
    "\"That's all I know. I swear it on Tenudaq's teeth.\"",
], [
    c("bind", "Bind his leg", "a1_cove_after", effects=["mercy +2", "flag bound_rower"],
      result="You tie off the wound with a strip of your shirt. He weeps a little."),
    c("swear", "Knife to his throat: \"Swear it again.\"", "a1_cove_after", effects=["mercy -1", "flag threatened_rower"],
      result="He swears it again, and again, until you take the knife away."),
    c("kill", "He has told you everything. Kill him.", "a1_return",
      effects=["mercy -3", "sanity -10", "flag killed_rower"],
      result="Afterwards you wash your knife in the sea for a long time."),
], on_enter=["leads +2", "journal " + SALT_WORKS])

node("a1_cove_after", "THE COVE", [
    "The water is at the rocks' feet now. He can't walk, and he knows it.",
    p("\"Please,\" he says again, softer.", "!bound_rower"),
    p("\"They'll come back for me,\" he says. \"Tonight, maybe. If they find me alive, I'll tell them you spared me.\"", "bound_rower"),
], [
    c("leave", "Leave him on the rocks", "a1_return",
      effects=[{"if": "bound_rower", "do": ["flag spared_rower"]},
               {"if": "!bound_rower", "do": ["mercy -2", "flag left_rower_to_tide"]}]),
    c("drag", "Drag him to the square for the village to judge", "a1_return",
      needs="attr.strength >= 12", needsLabel="Strength 12",
      effects=["rep.fisherfolk +1", "flag rower_to_village"],
      result="Brena looks at him for a long time. The village hangs him at noon."),
])

# ─── Scene 6 ──────────────────────────────────────────────────────────────────
node("a1_dusk", "THE COVE AT DUSK", [
    "At dusk you go back to the cove, and a longboat is already grinding onto the sand. Two raiders climb out: a broad man with a falchion, and a woman with a red hand tattooed across her throat. They have come back for their own.",
    p("Corrin is sitting up against the rocks where you left him, leg bound. \"Leave it!\" he shouts to them. \"This one let me live.\" The woman looks at you a long time.", "spared_rower && knows_rowers_name"),
    p("The rower is sitting up against the rocks where you left him, leg bound. \"Leave it!\" he shouts to them. \"This one let me live.\" The woman looks at you a long time.", "spared_rower && !knows_rowers_name"),
    p("They find their friend dead, or gone, and draw their blades.", "!spared_rower"),
], [
    c("let_go", "Let them take him and go", "a1_pyre", **{"if": "spared_rower"},
      effects=["mercy +1", "leads +1", "flag rowgan_debt", "journal At the salt works, ask for the clerk, not the captain."],
      result="The woman nods once. \"You'll want the salt works. Ask for the clerk, not the captain.\""),
    c("ask_woman", "Ask the woman about the children", "a1_pyre", **{"if": "spared_rower"},
      needs="attr.insight >= 11", needsLabel="Insight 11",
      effects=["leads +1", "flag knows_buyers_sign", "journal The buyer's sign: a measuring rod crossed with a sickle."],
      result="\"They're not for us. We only carry.\" She draws the buyer's sign in the sand: a measuring rod crossed with a sickle."),
    c("attack", "Attack them on the rocks",
      effects=[{"if": "spared_rower", "do": ["mercy -2", "flag betrayed_corrin"]}],
      triggerEvent="combat_a1_cove", victoryNodeId="a1_dusk_won", defeatNodeId="a1_dusk_lost"),
    c("village", "Shout for the village, then fight",
      needs="bond.tam >= 1", needsLabel="Tam's trust",
      triggerEvent="combat_a1_cove_village", victoryNodeId="a1_dusk_won", defeatNodeId="a1_dusk_lost"),
    c("hide", "Hide in the rocks and let them go", "a1_pyre",
      effects=["sanity -5", "flag last_boat_burned"],
      result="On their way out they fire the last boat on the beach. You watch it burn."),
])

node("a1_dusk_won", "THE COVE AT DUSK", [
    "The broad man's falchion lies in the surf, notched and rusted but heavier than anything you have held. Their longboat sits drawn up on the sand, a red hand on its folded sail.",
], [
    c("up", "Walk back up to the village", "a1_pyre"),
], on_enter=["item rusted falchion", "flag has_raider_boat"])

node("a1_dusk_lost", "THE SQUARE", [
    "You wake by the well with Brena binding your head. The raiders are gone, and so is their boat.",
    "\"Brave,\" she says, tying the knot too tight. \"Brave is how your father died.\"",
], [
    c("up", "Get up", "a1_pyre"),
], on_enter=["flag lost_at_cove"])

# ─── Scene 7 ──────────────────────────────────────────────────────────────────
node("a1_pyre", "THE BURNING OF THE DEAD", [
    "Saltmere burns its dead on the tideline, so the sea can take what is left. Nine bodies lie on the driftwood, wrapped in sailcloth. Garrick is at the end of the row, his cooper's mallet on his chest.",
    "Brena hands you the torch. \"Your mother said the words at the last burning. There's no one else of your blood to say them now.\" The whole village is watching you.",
    p("As the pyre catches, the pin at your throat turns hot, and for a moment the flames stand up in the shape of a crown.", "has_iron_pin"),
], [
    c("vitruv", "Say the temple words: \"Vitruv, measure them kindly.\"", "a1_counsel",
      effects=["rep.temple +1", "flag prayed_vitruv"], result="The proper words. The village is comforted."),
    c("lavrith", "Say the old words, to Lavrith of the pines: \"Undo their pain.\"", "a1_counsel",
      effects=["sanity +5", "flag old_ways"], result="Only the oldest remember those words. Brena weeps."),
    c("vow", "Say: \"I will bring back the ones they took.\"", "a1_counsel",
      effects=["rep.fisherfolk +1", "flag public_vow"], result="A vow, in front of everyone. Nobody here will forget it."),
    c("curse", "Say: \"What god let this happen?\" and throw the torch", "a1_counsel",
      effects=["mercy -1", "sanity +5", "flag cursed_gods"], result="The anger holds you up. Some of the village turn away."),
    c("silent", "Light the pyre and say nothing", "a1_counsel",
      effects=["sanity -5"], result="Brena says the words for you."),
])

# ─── Scene 8 ──────────────────────────────────────────────────────────────────
node("a1_counsel", "BRENA'S COUNSEL", [
    "The village meets in the net-shed because it is the only roof left whole. A rider from the reeve came through at dawn: every village from here to the river mouth was hit the same week, and the crown's riders are three days behind the raiders and losing ground. The army is raising men at a recruitment post up the coast, the rider said, for anyone who can hold a spear.",
    "Nobody here can follow. The nets are ash, the boats are gone, and winter is coming. Brena turns to you. \"You've been to the cove and the hills and your mother's house, {name}. What do you know, and what will you do?\"",
], [
    c("all", "Tell them everything: the list, the fever children, the salt works", "a1_leaving",
      needs="leads >= 3", needsLabel="3 leads",
      effects=["rep.fisherfolk +1", "flag brena_contact", "journal Brena's cousin in the next village north owes her a life."],
      result="The room goes cold. Afterwards Brena gives you a name: her cousin in the next village north, who owes her a life."),
    c("only", "Tell them only that you are going after her", "a1_leaving",
      effects=["flag kept_secrets"], result="Brena studies you, but asks nothing more."),
    c("arm", "Say: \"Arm yourselves and come with me.\"", "a1_leaving",
      effects=["rep.fisherfolk -1", {"if": "bond.tam >= 2", "do": ["flag tam_stood_up"]}],
      result="Nobody moves. They have nothing left to fight with."),
    c("skiff", "Ask Brena for the old skiff and food for the road", "a1_leaving",
      needs="rep.fisherfolk >= 1", needsLabel="Fisherfolk: Known",
      effects=["flag blessing_granted", "flag has_food"], result="She gives them. The village's blessing goes with you."),
    c("post", "Ask the rider's way to the recruitment post", "a1_counsel", once=True,
      effects=["flag knows_recruitment_post", "journal The army is raising men at a recruitment post up the coast."],
      result="Two days up the coast road, where it crosses the river."),
])

# ─── Scene 9: key event ──────────────────────────────────────────────────────
TAM_WAITING = "tam_wants_to_come && !tam_decided"
node("a1_leaving", "LEAVING SALTMERE", [
    "You pack what you have: your knife, the boat hook, whatever you took from the house. The tide turns at dusk. Behind you the village is already rebuilding the first net-shed, slow and quiet.",
    p("Tam is waiting at the end of the burnt jetty with a bundle and a gutting knife, and says nothing, only waits to hear what you'll say.", TAM_WAITING),
    p("It is time to go.", "!(" + TAM_WAITING + ")"),
], [
    c("get_in", "Say: \"Get in.\"", "a1_leaving", **{"if": TAM_WAITING},
      effects=["flag tam_decided", "flag tam_joined", "bond.tam +1"], result="Tam climbs in without a word."),
    c("go_home", "Say: \"Go home, Tam.\"", "a1_leaving", **{"if": TAM_WAITING},
      effects=["flag tam_decided", "bond.tam -1",
               {"if": "promised_tam", "do": ["bond.tam -1", "flag broke_promise_tam"]},
               {"if": "bond.tam >= 3", "do": ["flag tam_follows"]}],
      result="Tam turns and walks back up the beach without looking round."),
    c("blessing", "Take the skiff Brena gave you, with the village on the shore", "a1_first_night",
      **{"if": "!(" + TAM_WAITING + ")"}, needs="blessing_granted", needsLabel="Brena's blessing",
      effects=["rep.fisherfolk +1", "flag left_with_blessing", "flag left_by_boat"],
      result="The village sings you out, the old rowing song, until you are past the point."),
    c("raider_boat", "Take the raiders' longboat from the cove", "a1_first_night",
      **{"if": "!(" + TAM_WAITING + ")"}, needs="has_raider_boat", needsLabel="The raiders' boat",
      effects=["flag sails_red_hand", "flag left_by_boat"],
      result="Fast and seaworthy, with a red hand on the sail. Up the coast, people will take you for a Rowgan."),
    c("steal_skiff", "Steal the old skiff in the night", "a1_first_night",
      **{"if": "!(" + TAM_WAITING + ") && !blessing_granted && !last_boat_burned"},
      effects=["rep.fisherfolk -2", "mercy -1", "flag stole_skiff", "flag left_by_boat"],
      result="It was the last boat they had."),
    c("walk", "Walk the coast road alone", "a1_first_night",
      **{"if": "!(" + TAM_WAITING + ")"},
      effects=["flag left_on_foot"], result="On foot, the raiders gain a day on you."),
])

# ─── Scene 10 ─────────────────────────────────────────────────────────────────
node("a1_first_night", "THE FIRST NIGHT OUT", [
    p("You beach in a sandy cove a few hours north and make no fire. Saltmere is a single orange point behind you, then nothing.", "left_by_boat"),
    p("You stop where the coast road climbs into the first pines, and look back once. Saltmere is a single orange point, then nothing.", "!left_by_boat"),
    p("Tam falls asleep sitting up, gutting knife still in hand.", "tam_joined"),
    p("You dream of {sister} in a room with iron walls. She says your name, very clearly, and you wake with the pin hot against your skin.", "has_iron_pin"),
    "Before you sleep, you say something aloud, to the dark or to Tam. You will remember it later.",
], [
    c("cost", "Say: \"I'll find her, whatever it costs.\"", "a1_end", effects=["mercy -1", "flag whatever_it_costs"]),
    c("self", "Say: \"I'll find her, and she'll still know who I am.\"", "a1_end", effects=["mercy +1", "flag stay_yourself"]),
    c("brother", "Ask Tam about their brother", "a1_end", **{"if": "tam_joined"},
      effects=["bond.tam +1", "sanity +5"], result="Tam talks until nearly dawn."),
    c("sleep", "Say nothing and sleep", "a1_end"),
])

node("a1_end", "END OF ACT I", [
    "The tide goes out and comes back. Somewhere north, a red sail is a day ahead of you.",
    "Act I ends here. Act II, the road, is still being written.",
])

chapter = {"id": "act1", "title": "ACT I — SALTMERE", "startNodeId": "a1_hills", "nodes": nodes}
with open("assets/story/act1.json", "w", encoding="utf-8") as f:
    json.dump(chapter, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(len(nodes), "scenes,", sum(len(n["choices"]) for n in nodes.values()), "choices")
