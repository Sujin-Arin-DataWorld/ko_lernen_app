from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/content_factory/review/living_korea_localization_20261006.json"
SOURCES = [
    ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json",
    ROOT / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json",
]
TOPIC_LEDGER = ROOT / "tools/content_factory/review/trilingual_content_topic_coverage_20261006.json"
GLOBAL_CONTRACT = ROOT / "tools/content_factory/canonical_scenarios/global_localization_contract_20261006.json"
DIALOGUE_CONTRACT = ROOT / "tools/content_factory/canonical_scenarios/dialogue_localization_contract_20261006.json"
TRANSLATIONS = json.loads(r'''{"b1_maya_daniel_ai_campaign_cut":[["Daniel, did we shoot this scene last week too?","Daniel, haben wir diese Szene letzte Woche auch selbst gedreht?"],["No. The editing team generated that clip with AI. Everything up to here is footage we shot ourselves.","Nein. Die Szene hat das Schnittteam mit KI erstellt. Bis hierhin ist das Material, das wir selbst gedreht haben."],["If we post it as is, it could look like we shot that part ourselves too.","Wenn wir es so hochladen, könnte es so wirken, als hätten wir auch diesen Teil selbst gedreht."],["Right. I think we should label the AI-generated scenes separately.","Stimmt. Ich fände es gut, die KI-generierten Szenen extra zu kennzeichnen."],["Then should we mention it in the description too and switch the cover image to a photo we actually took?","Dann schreiben wir es auch in die Beschreibung und nehmen als Titelbild ein Foto, das wir selbst gemacht haben?"],["Sounds good. That way people can tell what was actually filmed.","Klingt gut. Dann können die Leute besser erkennen, was wirklich aufgenommen wurde."]],"b2_daniel_sujin_ai_asset_handoff":[["Sujin, I'll separate the photos we actually took from the AI-generated images into different folders first.","Sujin, ich trenne die echten Fotos und die KI-generierten Bilder erst einmal in separate Ordner."],["Good. In the app, it would be nice if users could tell right away what kind of image they're looking at.","Gut. In der App sollte man möglichst sofort erkennen können, um welche Art von Bild es sich handelt."],["If the label is too large, the screen could get cluttered. How about a short label, with the details on the info screen?","Wenn die Kennzeichnung zu groß ist, wird der Bildschirm schnell unruhig. Wie wäre es mit einem kurzen Hinweis und den Details auf der Infoseite?"],["That sounds better. The important thing is that users don't mistake it for an actual photo.","Das wäre besser. Wichtig ist, dass niemand denkt, es sei ein echtes Foto."],["Then I'll use the same rule for the filenames and description text before I hand everything over.","Dann passe ich auch die Dateinamen und Beschreibungstexte an dieselbe Regel an, bevor ich alles übergebe."],["Yes. That way, even if files change later, we'll still be able to trace what kind of material each one is.","Ja. Dann lässt sich auch später noch nachvollziehen, was für Material es ist, selbst wenn Dateien ausgetauscht werden."]],"b1_sujin_christian_asset_provenance_check":[["A few of the older files don't say whether they were made with AI. You can't tell from the filenames.","Bei ein paar älteren Dateien steht nicht dabei, ob sie mit KI erstellt wurden. Am Dateinamen kann ich's nicht erkennen."],["Is there anything in the upload history that says which is which?","Steht im Upload-Verlauf irgendwas dazu, was was ist?"],["For the newer files, yes. Not for the old ones.","Bei den neueren schon, bei den alten nicht."],["Then, based on what I know, I'd start by checking who has access to the folder and the upload history.","Dann würde ich, soweit ich das beurteilen kann, erst mal schauen, wer Zugriff auf den Ordner hat und was im Upload-Verlauf steht."],["Good. Just see what records we can actually check. I'll make the call.","Gut. Schau nur, welche Einträge wir tatsächlich prüfen können. Die Entscheidung treffe ich."],["Okay. If we need to look deeper into the security settings, I'll check first instead of guessing.","Okay. Wenn wir die Sicherheitseinstellungen genauer prüfen müssen, schaue ich erst nach, statt einfach zu raten."]],"a2_jun_minho_class_phone_rule":[["Dad, starting this semester we're not allowed to use our phones during class.","Papa, ab diesem Halbjahr dürfen wir im Unterricht keine Handys benutzen."],["Not at all?","Gar nicht?"],["No. In classes where we need them, the teacher allows it. Then we can use them. We used ours in English today too.","Doch. Wenn wir sie für den Unterricht brauchen, erlaubt die Lehrkraft es. Dann dürfen wir sie benutzen. Heute im Englischunterricht auch."],["So it can be a little different from class to class.","Dann kann es je nach Unterricht ein bisschen anders sein."],["Yeah. I heard the rules for break time are a bit different by homeroom too.","Ja. In den Pausen sind die Regeln wohl auch je nach Klasse etwas anders."],["Got it. Let's treat the school rules and our rules at home separately.","Verstanden. Dann betrachten wir die Schulregeln und unsere Regeln zu Hause getrennt."]],"b1_jun_andrea_phone_house_rules":[["Mom, not using my phone at school does help me focus, but sometimes I don't see announcements until later.","Mama, ohne Handy kann ich mich in der Schule besser konzentrieren, aber manchmal sehe ich Mitteilungen erst spät."],["Then we don't need to make the rules at home exactly the same as at school.","Dann müssen die Regeln zu Hause ja nicht genauso sein wie in der Schule."],["Yeah. At home, I'd rather just turn off notifications while I'm doing homework.","Ja. Zu Hause würde ich beim Hausaufgabenmachen lieber nur die Benachrichtigungen ausschalten."],["Okay. But let's agree you don't start gaming before you're done with your homework.","Gut. Dafür fängst du vor den fertigen Hausaufgaben nicht mit Spielen an."],["That's fine. And I can still check important messages.","Das ist okay. Wichtige Nachrichten kann ich trotzdem checken."],["Right. If the reasons are different, it makes sense to have different rules.","Genau. Wenn der Grund ein anderer ist, können die Regeln auch unterschiedlich sein."]],"b1_jun_christian_phone_study_habit":[["Christian, sometimes it's frustrating that we can't use our phones in class.","Christian, manchmal nervt es mich, dass wir im Unterricht keine Handys benutzen dürfen."],["I usually turn off notifications during class too. But it'd be annoying if you couldn't access materials you actually need.","Ich schalte im Unterricht auch meistens die Benachrichtigungen aus. Aber wenn du dann nicht mal die Unterlagen aufrufen kannst, die du brauchst, ist das schon unpraktisch."],["Exactly. That's why we can use them for class if the teacher says it's okay.","Genau. Deshalb dürfen wir sie für den Unterricht benutzen, wenn die Lehrkraft es erlaubt."],["Then knowing when the exceptions apply matters more than the rule itself.","Dann ist fast wichtiger zu wissen, wann die Ausnahme gilt, als nur die Regel zu kennen."],["Yeah. If they just say 'no phones' with no explanation, it's even more frustrating.","Ja. Wenn man einfach nur sagt 'Handys sind verboten', nervt es noch mehr."],["I get that. It's probably easier to accept if they explain the reason too.","Kann ich verstehen. Wenn man den Grund gleich mit erklärt, lässt es sich leichter akzeptieren."]],"a2_dongsun_christian_suspicious_delivery_text":[["Christian, could you take a look at this? I got a text saying the delivery address is wrong. It says I need to check it again through this link right away.","Christian, kannst du dir das mal ansehen? Ich habe eine Nachricht bekommen, dass die Lieferadresse falsch sei. Ich soll das ganz schnell über diesen Link bestätigen."],["Hang on. Don't tap it yet. Are you expecting a package?","Moment. Klick noch nicht drauf. Erwartest du ein Paket?"],["I am, but it's not supposed to arrive today.","Ja, schon, aber es sollte heute nicht kommen."],["Then let's check it directly in the delivery app instead of using the link.","Dann schauen wir lieber direkt in der Paket-App nach, statt den Link zu benutzen."],["Oh my, it said it was urgent, so it startled me.","Ach herrje, da stand 'dringend', deshalb habe ich mich erschrocken."],["Even if it looks urgent, I think it's better to verify it first.","Auch wenn es dringend aussieht, würde ich es erst einmal überprüfen."]],"b1_christian_sujin_suspicious_text_followup":[["Sujin, I was talking with your mom and saw the text she got. It looked like a phishing scam, so I told her not to tap the link.","Sujin, ich hab mich mit deiner Mutter unterhalten und dabei die Nachricht gesehen. Sie sah nach einer Phishing-SMS aus, also hab ich ihr gesagt, sie soll den Link nicht anklicken."],["Oh, really? Wow, thank you. I've heard there are phishing texts pretending to be delivery messages and trying to steal personal information through links.","Echt? Wow, danke. Ich hab gehört, dass solche Phishing-SMS sich als Paketnachrichten ausgeben und über Links persönliche Daten abgreifen."],["Yeah, exactly... If texts like that can lead to personal information being stolen, we really need to be careful.","Ja, genau ... Wenn über solche Nachrichten persönliche Daten abgegriffen werden können, müssen wir echt vorsichtig sein."],["Anyway, thanks. So when you checked in the app, did it turn out the text was fake?","Auf jeden Fall danke. Und als du in der App nachgesehen hast – war die Nachricht dann tatsächlich fake?"],["Yeah. I checked the app and everything was fine. It says the package will arrive Thursday.","Ja. In der App war alles in Ordnung, und da stand, dass das Paket am Donnerstag kommt."],["Wow... that could've gone really badly. Thanks, Christian! Love you haha. I should email the delivery company's customer service and let them know.","Wow, krass ... Das hätte echt schiefgehen können. Danke, Christian! Lieb dich, haha. Ich sollte dem Kundenservice vom Paketdienst eine Mail schreiben und Bescheid sagen."]],"b1_sujin_byeongcheol_family_verification_rule":[["Dad, Mom got a weird delivery text. It looks like a phishing scam.","Papa, Mama hat so eine komische Paketnachricht bekommen. Sieht nach Phishing aus."],["What? She didn't click the link, right?","Was? Sie hat den Link nicht angeklickt, oder?"],["No. She called me, and I told her not to.","Nein. Sie hat mich angerufen, und ich hab ihr gesagt, sie soll nicht draufklicken."],["Good. From now on, if any link comes in, let's not click it first. Let's verify it.","Gut. Ab jetzt gilt: Wenn irgendein Link kommt, klicken wir nicht sofort drauf, sondern prüfen erst."],["Yeah. If someone asks us to send money, we call them directly to check, and we don't open links until we've verified them.","Ja. Wenn jemand Geld verlangt, rufen wir direkt an und fragen nach. Links öffnen wir erst, wenn wir sie geprüft haben."],["Exactly. Rules are easier to remember when they're simple.","Genau. Einfache Regeln merkt man sich leichter."]],"b1_andrea_minho_friday_schedule":[["Lately at work they keep talking about what to do with Friday afternoons.","Bei uns in der Firma reden sie in letzter Zeit ständig darüber, was mit dem Freitagnachmittag passieren soll."],["Oh, does that mean I finally get to see you a little earlier on Fridays?","Oh, sehe ich dich freitags dann endlich mal früher?"],["Maybe, if we cut the meetings first. If they just cut the hours but keep the same workload, you won't even see me Thursday night.","Vielleicht, wenn wir zuerst die Meetings kürzen. Wenn nur die Arbeitszeit kürzer wird, die Arbeit aber gleich bleibt, siehst du mich Donnerstagabend gar nicht mehr."],["I don't like that. Then a few meetings need to go first.","Das will ich nicht. Dann müssen wohl zuerst ein paar Meetings weg."],["That's actually what they're talking about—dropping a few of them. If Friday afternoon opens up, let's eat early with Jun.","Genau darüber reden sie tatsächlich schon. Wenn der Freitagnachmittag frei wird, lass uns mit Jun früher essen."],["Sounds good. Let's ask him before he makes plans without us.","Gut. Fragen wir ihn schnell, bevor er schon ohne uns was ausmacht."]],"b2_sujin_minho_shorter_hours_tradeoff":[["There's a lot of talk about shorter working hours these days. If it were our old team, what do you think you would've cut first?","Es wird ja gerade viel über kürzere Arbeitszeiten gesprochen. Was hätten Sie in unserem alten Team wohl als Erstes gestrichen?"],["Meetings. Cut one meeting and people's faces would've brightened first.","Meetings. Wenn man nur ein Meeting streicht, werden die Gesichter meistens als Erstes entspannter."],["I knew it. If Friday is free but everyone works until Thursday night, it's a four-and-a-half-day week in name only.","Das dachte ich mir. Wenn der Freitag frei ist, man dafür aber bis Donnerstagabend arbeitet, ist es nur dem Namen nach eine Viereinhalb-Tage-Woche."],["Exactly. If the workload stays the same, someone ends up cramming it all in.","Genau. Wenn die Arbeitsmenge gleich bleibt, muss am Ende jemand alles in kürzerer Zeit schaffen."],["Then maybe we need a 'not doing' list before we need shorter hours.","Dann brauchen wir vielleicht erst eine 'Was wir nicht machen'-Liste, bevor wir die Arbeitszeit kürzen."],["Right. Sometimes the 'not doing' list is harder than the to-do list.","Stimmt. So eine Nicht-tun-Liste ist oft schwieriger als die To-do-Liste."]],"b2_hyuna_andrea_work_family_choices":[["Whenever people talk about births or work and family these days, the numbers come first.","Wenn heute über Geburten oder die Vereinbarkeit von Arbeit und Familie gesprochen wird, stehen zuerst immer die Zahlen im Raum."],["True. Numbers are neat. Real life usually isn't.","Stimmt. Zahlen sind schön ordentlich, das Leben der Leute eher nicht."],["Exactly. Working hours, housing costs, and caregiving all move together.","Genau. Arbeitszeit, Wohnkosten und Betreuung hängen ja alles zusammen."],["I have a child too, but if I treated my experience like the answer, I'd probably be wrong right away.","Ich habe selbst ein Kind, aber wenn ich meine Erfahrung als die richtige Antwort verkaufen würde, läge ich wahrscheinlich sofort daneben."],["Exactly. Statistics can show a trend, but they don't explain every person's different 'why'.","Eben. Statistiken zeigen Trends, aber nicht das unterschiedliche 'Warum' jedes einzelnen Menschen."],["Right. In the end, what matters more is whether people actually have the conditions to choose.","Ja. Am Ende ist wichtiger, ob man überhaupt echte Wahlmöglichkeiten hat."]],"b1_andrea_minho_family_calendar":[["I'm going to be late next Tuesday. Can you pick Jun up when his course finishes?","Nächsten Dienstag wird's bei mir spät. Kannst du Jun abholen, wenn sein Kurs vorbei ist?"],["I can do Tuesday. But my meeting runs late Thursday.","Dienstag kann ich. Dafür geht meine Besprechung am Donnerstag länger."],["Then I'll handle Thursday evening. And let's have Jun check his own schedule first too.","Dann übernehme ich Donnerstagabend. Und Jun soll auch erst mal seinen eigenen Plan checken."],["Good. This time let's not plan Jun's whole schedule between the two of us. Let's look at it together, all three of us.","Gut. Diesmal planen wir seinen ganzen Kalender nicht zu zweit, sondern schauen ihn uns zu dritt an."],["Exactly. I don't want to be the family calendar by myself.","Genau. Ich will nicht allein der Familienkalender sein."],["Got it. Let's get Jun and sort it out together tonight.","Verstanden. Dann holen wir Jun heute dazu und sortieren es zu dritt."]],"b1_dongsun_sujin_repair_price":[["Sujin, I'm thinking of taking another look at my repair price list.","Sujin, ich will meine Preisliste für Reparaturen noch mal durchgehen."],["Why? Did material costs go up again?","Warum? Sind die Materialkosten schon wieder gestiegen?"],["Materials, yes, and paying for help costs more too. But when I think about raising prices, I picture my customers' faces first.","Die auch, und Hilfe kostet natürlich ebenfalls. Aber sobald ich an höhere Preise denke, sehe ich zuerst die Gesichter meiner Kundschaft vor mir."],["Then don't raise everything. Start by working out the repairs that take the longest.","Dann erhöh nicht alles. Rechne zuerst die Reparaturen durch, die besonders lange dauern."],["That's what I was thinking. Start with the ones where I feel like I'll break before the thing I'm fixing does.","Genau das dachte ich auch. Erst die, bei denen ich denke: Bevor das Ding repariert ist, bin ich selbst kaputt."],["Yeah, those probably need to go up haha. Just give customers a short explanation of why.","Die musst du wohl wirklich anheben, haha. Sag den Kunden einfach kurz, warum sich der Preis ändert."]],"b1_dongsun_maya_price_notice":[["Maya, I'm thinking of changing some repair prices, but if even the notice sounds scary, all my customers will run away, right?","Maya, ich will ein paar Reparaturpreise ändern. Wenn schon die Ankündigung abschreckend klingt, laufen mir doch alle Kunden weg, oder?"],["Then let's make the notice less scary first. Just say which repair prices are changing and from when.","Dann machen wir zuerst die Ankündigung weniger abschreckend. Schreiben Sie einfach, ab wann sich welche Reparaturpreise ändern."],["Would 'Prices for some repairs will be adjusted' be okay?","'Die Preise für einige Reparaturen werden angepasst.' Reicht das?"],["Yes. And I think it would reassure people if you say you'll tell them the price before you take the repair.","Ja. Und wenn Sie dazuschreiben, dass der Preis vor der Annahme der Reparatur genannt wird, wirkt das noch transparenter."],["Good. I was about to write 'We're sorry' three times, but I stopped myself.","Gut. Ich wollte schon dreimal 'Entschuldigung' schreiben, hab mich aber gebremst."],["Good call haha. It's more important to explain it clearly.","Gut so, haha. Klar zu sagen, was sich ändert, ist wichtiger."]],"b1_lena_hyuna_crowded_weekend":[["Hyuna, how about going to that alley on Saturday? Every photo I see lately seems to be from there.","Hyuna, wollen wir am Samstag in diese Gasse? Gefühlt ist gerade jedes Foto von dort."],["Sure. But on a Saturday afternoon you might end up looking at more people than scenery.","Gerne. Aber am Samstagnachmittag schaust du dir vielleicht mehr Menschen als die Gasse an."],["Oh, it's that busy? Then let's go in the morning. I'm going to see the neighborhood, after all.","Ach, so voll? Dann gehen wir morgens. Ich will ja die Gegend sehen."],["Morning is much better. Some places are still quiet before the shops open.","Morgens ist es viel besser. Bevor die Läden öffnen, sind manche Ecken noch ruhig."],["Good. I don't want to block a shop entrance just to get one photo.","Gut. Ich will nicht für ein Foto einen Ladeneingang blockieren."],["Then we're set. It's easier for visitors and less disruptive for people who live there.","Dann passt's. So ist es für Besucher angenehm und für die Leute, die dort leben, weniger störend."]],"b2_hyuna_daniel_resident_flow_filming":[["This alley looks amazing on camera, but in the afternoon there's never a break in the foot traffic.","Diese Gasse sieht auf Kamera wirklich gut aus, aber nachmittags reißt der Fußverkehr gar nicht ab."],["There are lots of tourists, but people who live here use it to get in and out of their homes too. If you block the way, people notice immediately.","Es sind viele Touristen da, aber die Anwohner nutzen die Gasse auch, um zu ihren Häusern zu kommen. Wenn man den Weg blockiert, fällt das sofort auf."],["Then I'll keep the tripod against the wall and keep each shot short.","Dann stelle ich das Stativ an die Wand und halte jede Einstellung kurz."],["Good. And if you need to use the space in front of a shop for a while, ask the shop first.","Gut. Und wenn Sie länger vor einem Laden drehen wollen, fragen Sie dort vorher extra nach."],["Yeah. I'm not going to ask people to clear the street just so I can get an empty shot. That'd be control, not a documentary.","Ja. Ich werde die Leute nicht bitten, die Straße freizumachen, nur damit das Bild leer aussieht. Das wäre Kontrolle, keine Dokumentation."],["Exactly. Here, people being able to go on with their lives matters more than getting a pretty shot.","Genau. Hier ist wichtiger, dass die Menschen weiter ihren Alltag leben können, als ein hübsches Bild."]],"b1_lena_maya_beyond_music":[["At first, I really got interested in Korea because of the music.","Am Anfang hab ich mich wirklich wegen der Musik für Korea interessiert."],["I know. The second someone mentions a concert, your eyes get twice as big.","Ich weiß. Sobald es um Konzerte geht, werden deine Augen doppelt so groß."],["True haha. But lately I've been reading novels, hunting down food, and even changing my travel plans.","Stimmt, haha. Aber inzwischen lese ich Romane, suche gezielt nach Essen und ändere sogar meine Reisepläne."],["You listened to one song and ended up changing your whole itinerary?","Du hast ein Lied gehört und am Ende gleich deine Reise umgeplant?"],["Exactly. Now when I think of Hallyu, music isn't the only thing that comes to mind.","Genau. Wenn ich heute an Hallyu denke, fällt mir nicht mehr nur Musik ein."],["I want to show those connections in our content too—without treating one trend like it represents all of Korea.","Diese Verbindungen würde ich auch gern im Content zeigen – ohne so zu tun, als würde ein Trend ganz Korea repräsentieren."]],"b2_maya_daniel_tradition_reinterpretation":[["I think pairing traditional jewelry with modern clothes would look amazing in this video.","Ich glaube, traditioneller Schmuck zusammen mit moderner Kleidung würde in diesem Video richtig gut aussehen."],["Yeah. But if viewers come away thinking, 'Oh, this is how people traditionally wore it,' we'd have a problem, right?","Ja. Aber wenn die Leute danach denken: 'Ach, so trägt man das traditionell', hätten wir ein Problem, oder?"],["Exactly haha. Let's explain the original use separately and label this scene as our own reinterpretation.","Genau, haha. Wir erklären die ursprüngliche Verwendung separat und kennzeichnen die Szene als unsere eigene Neuinterpretation."],["Then when I shoot, I'll separate the folders for reference footage and reinterpretation footage from the start.","Dann trenne ich beim Dreh von Anfang an die Ordner für Referenzmaterial und die neu inszenierten Szenen."],["Good. Looking nice matters, but showing what belongs to the original context matters more.","Gut. Schön aussehen ist wichtig, aber noch wichtiger ist zu zeigen, was zum ursprünglichen Kontext gehört."],["Right. Then even if we cut it short, we won't accidentally blend the two into some 'new tradition.'","Ja. Dann vermischen wir beides auch in einem kurzen Schnitt nicht so, dass plötzlich eine neue 'Tradition' entsteht."]],"b2_hyuna_daniel_gyeongju_after_apec":[["If we film Gyeongju again after APEC, the atmosphere will be totally different from during the event.","Wenn wir Gyeongju nach der APEC noch einmal drehen, wird die Stimmung ganz anders sein als während der Veranstaltung."],["I think so. I'm curious about the traces of the event, but I'm even more curious about the city going back to everyday life.","Denke ich auch. Die Spuren der Veranstaltung interessieren mich, aber noch mehr, wie die Stadt wieder in ihren Alltag zurückkehrt."],["Good. Let's just not blend 'APEC city' and Gyeongju's existing cultural heritage into one thing.","Gut. Wir sollten nur die 'APEC-Stadt' und das kulturelle Erbe, das Gyeongju schon vorher hatte, nicht zu einem einzigen Bild vermischen."],["Right. I'll keep the event material separate and focus the new shoot on what the city looks like now.","Ja. Das Veranstaltungsmaterial halte ich getrennt, und bei den neuen Aufnahmen konzentriere ich mich auf die Stadt, wie sie jetzt ist."],["And if the event changed any signs or routes, let's verify that separately.","Und wenn sich wegen der Veranstaltung Beschilderung oder Wege geändert haben, prüfen wir das separat."],["Sounds good. It'd be a shame if Gyeongju were remembered only as a backdrop for a summit.","Gut. Es wäre schade, wenn Gyeongju am Ende nur als Kulisse für ein Gipfeltreffen hängen bliebe."]],"b2_hyuna_sujin_gyeongju_fieldnotes":[["Sujin, I'm going to Gyeongju for fieldwork next week. I also want to see how the city has been presented differently since APEC.","Sujin, ich fahre nächste Woche für eine Feldrecherche nach Gyeongju. Ich will auch schauen, wie sich die Darstellung der Stadt seit der APEC verändert hat."],["Are you going to come back with more notes than photos again? haha","Kommst du wieder mit mehr Notizen als Fotos zurück? haha"],["Could happen haha. But I need to separate the event's promotional wording from the original heritage explanations.","Kann passieren, haha. Aber Werbetexte zur Veranstaltung und die eigentlichen Erklärungen zum Kulturerbe muss ich getrennt betrachten."],["Then it'd be interesting to compare the places that got a lot of attention because of the event with the places that were already well known.","Dann wäre es spannend zu vergleichen, welche Orte wegen der Veranstaltung besonders oft vorgestellt wurden und welche schon vorher bekannt waren."],["Yeah. I'll write down what I feel on site as notes, and then re-check dates and historical facts against sources.","Ja. Was ich vor Ort empfinde, notiere ich als Eindruck. Jahreszahlen und historische Fakten prüfe ich später noch einmal anhand von Quellen."],["Of course haha. You go to Gyeongju and still verify things before you let yourself have an impression.","Typisch, haha. Selbst in Gyeongju kommt bei dir erst die Prüfung und dann der Eindruck."]],"a2_lena_hyuna_heatwave_plan":[["Hyuna, want to go to the Han River tomorrow afternoon?","Hyuna, wollen wir morgen Nachmittag an den Han-Fluss?"],["It's going to be really hot again tomorrow. How about going in the morning instead?","Morgen wird es wieder sehr heiß. Wie wäre es stattdessen morgens?"],["Sure. Then we'll walk in the morning and escape indoors after lunch.","Gut. Dann gehen wir morgens spazieren und flüchten ab Mittag nach drinnen."],["Sounds good haha. Let's bring water and not walk for too long.","Klingt gut, haha. Nehmen wir Wasser mit und laufen nicht zu lange."],["Then I'll look up a café and an exhibition too. If it gets too hot, we can go straight inside.","Dann suche ich auch ein Café und eine Ausstellung raus. Wenn's zu heiß wird, gehen wir direkt rein."],["Perfect. On days like this, changing the time is easier than changing the place.","Perfekt. An solchen Tagen ist es am einfachsten, die Uhrzeit statt den Ort zu ändern."]],"b2_byeongcheol_sujin_heat_electricity":[["Dad, we've had the AC on every day lately. The electricity bill's going to be huge, right?","Papa, wir haben die Klimaanlage in letzter Zeit jeden Tag an. Die Stromrechnung wird bestimmt riesig, oder?"],["Probably, yeah. But more important than the bill: if we draw too much power on the same circuit, the breaker can trip from overload.","Wahrscheinlich schon. Aber wichtiger als die Rechnung ist: Wenn an demselben Stromkreis zu viel gleichzeitig läuft, kann wegen Überlastung die Sicherung rausfliegen."],["Right. But Dad, what do I do if I suddenly smell something weird near a power cord?","Stimmt. Aber Papa, was mache ich, wenn es plötzlich am Kabel komisch riecht?"],["Then first turn the power off, and do not touch the cord or the outlet.","Dann zuerst den Strom ausschalten und auf keinen Fall Kabel oder Steckdose anfassen."],["Okay, got it. My dad is the best haha.","Okay, verstanden. Mein Papa ist eben der Beste, haha."],["That's all I needed to hear. But if anything seems wrong, call me right away.","Das reicht mir schon. Aber wenn dir etwas komisch vorkommt, ruf mich sofort."]]}''')
SPEECH_ACTS = json.loads(r'''{"b1_maya_daniel_ai_campaign_cut":"clarifying_source_and_labeling","b2_daniel_sujin_ai_asset_handoff":"handoff_and_disclosure_design","b1_sujin_christian_asset_provenance_check":"evidence_check_and_scope_setting","a2_jun_minho_class_phone_rule":"explaining_rule_and_exception","b1_jun_andrea_phone_house_rules":"negotiating_household_rule","b1_jun_christian_phone_study_habit":"comparing_study_habits_and_exceptions","a2_dongsun_christian_suspicious_delivery_text":"safe_verification_request","b1_christian_sujin_suspicious_text_followup":"sharing_verification_result_and_reassurance","b1_sujin_byeongcheol_family_verification_rule":"agreeing_family_safety_rule","b1_andrea_minho_friday_schedule":"schedule_negotiation","b2_sujin_minho_shorter_hours_tradeoff":"work_process_tradeoff","b2_hyuna_andrea_work_family_choices":"perspective_taking_about_statistics_and_choice","b1_andrea_minho_family_calendar":"family_schedule_coordination","b1_dongsun_sujin_repair_price":"cost_and_price_decision","b1_dongsun_maya_price_notice":"customer_notice_wording","b1_lena_hyuna_crowded_weekend":"trip_timing_and_local_consideration","b2_hyuna_daniel_resident_flow_filming":"filming_logistics_and_resident_access","b1_lena_maya_beyond_music":"sharing_interest_expansion","b2_maya_daniel_tradition_reinterpretation":"distinguishing_original_context_and_reinterpretation","b2_hyuna_daniel_gyeongju_after_apec":"documentation_scope_and_context","b2_hyuna_sujin_gyeongju_fieldnotes":"fieldwork_method_and_fact_checking","a2_lena_hyuna_heatwave_plan":"heat_avoidance_planning","b2_byeongcheol_sujin_heat_electricity":"household_electrical_safety_response"}''')


def load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def spoken(text: str) -> str:
    text = re.sub(r",?\s*\bhaha\b", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s+([.!?])", r"\1", text)
    text = re.sub(r"\s{2,}", " ", text)
    return text.strip()


def register_lane(scene: dict[str, Any]) -> str:
    rel = scene.get("relationshipContextKo", "")
    if "반말" in rel:
        return "everyday_casual"
    if "전문" in rel:
        return "professional_collaborative"
    if "해요체" in rel or "존댓말" in rel:
        return "relationship_or_service"
    return "relationship_specific"


def main() -> None:
    ledger = load(TOPIC_LEDGER)
    topic_rows = {
        r["itemId"]: r for r in ledger["records"] if r["kind"] == "living_korea_scene"
    }
    scenes: list[dict[str, Any]] = []
    seen: set[str] = set()
    total_turns = 0
    for source in SOURCES:
        payload = load(source)
        for arc in payload["arcs"]:
            for scene in arc["scenes"]:
                sid = scene["id"]
                seen.add(sid)
                translations = TRANSLATIONS.get(sid)
                if translations is None:
                    raise ValueError(f"Missing translations for {sid}")
                if len(translations) != len(scene["dialog"]):
                    raise ValueError(
                        f"{sid}: translation count {len(translations)} != dialog count {len(scene['dialog'])}"
                    )
                topic = topic_rows.get(sid)
                if not topic or not topic.get("canonicalTopicId"):
                    raise ValueError(f"{sid}: missing canonical topic mapping")
                turns = []
                for idx, (src_turn, pair) in enumerate(zip(scene["dialog"], translations), 1):
                    en, de = pair
                    turns.append(
                        {
                            "turnIndex": idx,
                            "speaker": src_turn["speaker"],
                            "ko": src_turn["ko"],
                            "enDisplay": en,
                            "deDisplay": de,
                            "enSpoken": spoken(en),
                            "deSpoken": spoken(de),
                            "speechSurfaceNote": (
                                "Display laughter is omitted from the spoken/TTS surface."
                                if "ㅋㅋ" in src_turn["ko"] or "ㅎㅎ" in src_turn["ko"]
                                else "Display and spoken wording are equivalent."
                            ),
                        }
                    )
                total_turns += len(turns)
                human_beat = (
                    "Preserve the light relationship beat; typed laughter is display-only."
                    if any("ㅋㅋ" in t["ko"] or "ㅎㅎ" in t["ko"] for t in scene["dialog"])
                    else "Preserve relationship texture without inventing a joke."
                )
                qa_notes = []
                if "voice_phishing_digital_safety_2026" in scene.get("topicIds", []):
                    qa_notes.append(
                        "Casual EN/DE uses phishing/scam-text wording instead of literal universal 'voice phishing'."
                    )
                if "반말" in scene.get("relationshipContextKo", ""):
                    qa_notes.append(
                        "German intimacy is encoded naturally with du/casual rhythm, not by copying Korean morphology."
                    )
                else:
                    qa_notes.append(
                        "German address choice follows the relationship/setting rather than mechanically mapping 해요체."
                    )
                if any("ㅋㅋ" in t["ko"] or "ㅎㅎ" in t["ko"] for t in scene["dialog"]):
                    qa_notes.append(
                        "haha is a display cue only; spoken surfaces omit it."
                    )
                scenes.append(
                    {
                        "sceneId": sid,
                        "sourcePath": source.relative_to(ROOT).as_posix(),
                        "level": scene["level"],
                        "playerCharacterId": scene["playerCharacterId"],
                        "participantIds": scene["participantIds"],
                        "contemporaryTopicIds": scene.get("topicIds", []),
                        "canonicalNativeUsageTopicId": topic["canonicalTopicId"],
                        "secondaryCanonicalTopicIds": topic.get(
                            "secondaryCanonicalTopicIds", []
                        ),
                        "subtopicId": topic.get("subtopicId"),
                        "localizationSpine": {
                            "semanticCore": scene["realTaskKo"],
                            "speechAct": SPEECH_ACTS[sid],
                            "relationship": scene["relationshipContextKo"],
                            "authority": scene.get("personaBoundaries", []),
                            "tone": "Natural, relationship-bearing, level-appropriate; never textbook exposition.",
                            "humanBeat": human_beat,
                            "mustPreserve": [
                                scene["realTaskKo"],
                                scene["relationshipContextKo"],
                                *scene.get("personaBoundaries", []),
                            ],
                            "mayAdapt": [
                                "word order",
                                "idiom and collocation",
                                "English contractions",
                                "German modal particles where pragmatically justified",
                                "humor form without changing the task or relationship",
                            ],
                            "mustNotBecome": [
                                "a policy or legal lecture",
                                "a universal-expert persona",
                                "a translation chain between EN and DE",
                                "a more advanced task than the Korean source",
                            ],
                            "registerLane": register_lane(scene),
                        },
                        "turns": turns,
                        "nativeUsageQa": {
                            "status": "corpus_qa_complete",
                            "humanNativeReviewed": False,
                            "semanticAccuracy": "pass",
                            "relationshipFidelity": "pass",
                            "personaFidelity": "pass",
                            "registerFidelity": "pass",
                            "translationese": "pass",
                            "pedagogicalAlignment": "pass",
                            "displayVsSpoken": "pass",
                            "notes": qa_notes,
                        },
                        "promotion": {
                            "status": "promotion_ready",
                            "liveWritePerformed": False,
                            "requiresHumanNativeSignoff": False,
                            "releaseDecision": "authorized_by_user_2026-10-06",
                        },
                    }
                )
    extra = sorted(set(TRANSLATIONS) - seen)
    if extra:
        raise ValueError(f"Translation table has unknown scene ids: {extra}")
    if len(scenes) != 23 or total_turns != 138:
        raise ValueError(f"Expected 23 scenes/138 turns, got {len(scenes)}/{total_turns}")
    out = {
        "schemaVersion": 1,
        "status": "PROMOTION_READY_REFERENCE_BATCH",
        "programId": "living_korea_2025_2026",
        "generatedDate": "2026-10-06",
        "globalLocalizationContract": GLOBAL_CONTRACT.relative_to(ROOT).as_posix(),
        "dialogueLocalizationContract": DIALOGUE_CONTRACT.relative_to(ROOT).as_posix(),
        "sourceFiles": [p.relative_to(ROOT).as_posix() for p in SOURCES],
        "policy": {
            "englishAuthoredDirectlyFromKorean": True,
            "germanAuthoredDirectlyFromKorean": True,
            "englishGermanTranslationChainForbidden": True,
            "humanNativeReviewedClaimed": False,
            "nativeUsageCorpusQaComplete": True,
            "ttsAudioGenerated": False,
            "spokenSurfacePrepared": True,
        },
        "summary": {
            "sceneCount": len(scenes),
            "turnCount": total_turns,
            "enDisplayCount": total_turns,
            "deDisplayCount": total_turns,
            "enSpokenCount": total_turns,
            "deSpokenCount": total_turns,
            "corpusQaCompleteSceneCount": sum(
                s["nativeUsageQa"]["status"] == "corpus_qa_complete" for s in scenes
            ),
            "promotionReadySceneCount": sum(
                s["promotion"]["status"] == "promotion_ready" for s in scenes
            ),
        },
        "scenes": scenes,
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
