"""Level-aware example frames that keep the Korean headword visible."""

from __future__ import annotations

from .rr import eul_reul, eun_neun, euro_ro, i_ga, ieyo_yeyo


def example_for(level: str, pos: str, korean: str, german: str, english: str, index: int) -> tuple[str, str, str]:
    level = level.upper()
    pos = pos.lower()
    frames = _frames(level, pos, korean, german, english)
    return frames[index % len(frames)]


def _frames(level: str, pos: str, ko: str, de: str, en: str, /) -> list[tuple[str, str, str]]:
    eul = eul_reul(ko)
    i = i_ga(ko)
    eun = eun_neun(ko)
    euro = euro_ro(ko)
    ieyo = ieyo_yeyo(ko)
    if pos == "verb":
        return _verb_frames(level, ko, de, en)
    if pos == "adjektiv":
        return _adj_frames(level, ko, de, en, eun, i)
    if pos == "adverb":
        return _adv_frames(level, ko, de, en)
    if pos == "ausdruck":
        return _expr_frames(level, ko, de, en)
    return _noun_frames(level, ko, de, en, eul, i, eun, euro, ieyo)


def _noun_frames(level: str, ko: str, de: str, en: str, eul: str, i: str, eun: str, euro: str, ieyo: str) -> list[tuple[str, str, str]]:
    common = [
        (f"오늘 {ko}{eul} 샀어요.", f"Heute habe ich {de} gekauft.", f"I bought {en} today."),
        (f"지금 {ko} 필요해요.", f"Ich brauche jetzt {de}.", f"I need {en} now."),
        (f"이 {ko} 얼마예요?", f"Was kostet {de}?", f"How much is {en}?"),
        (f"집에 {ko}{i} 있어요.", f"Zu Hause gibt es {de}.", f"There is {en} at home."),
        (f"{ko} 어디 있어요?", f"Wo ist {de}?", f"Where is {en}?"),
        (f"저는 {ko}{i} 좋아요.", f"Ich mag {de}.", f"I like {en}."),
        (f"친구에게 {ko}{eul} 줬어요.", f"Ich habe einer Freundin {de} gegeben.", f"I gave a friend {en}."),
        (f"이건 {ko}{ieyo}.", f"Das ist {de}.", f"This is {en}."),
        (f"매일 {ko}{eul} 봐요.", f"Ich sehe {de} jeden Tag.", f"I see {en} every day."),
        (f"{ko} 하나 주세요.", f"Bitte geben Sie mir {de}.", f"Please give me {en}."),
        (f"어제 {ko}{eul} 썼어요.", f"Gestern habe ich {de} benutzt.", f"I used {en} yesterday."),
        (f"학교 앞에 {ko}{i} 있어요.", f"Vor der Schule gibt es {de}.", f"There is {en} in front of the school."),
    ]
    if level == "A1":
        return common
    if level == "A2":
        return [
            (f"오늘 {ko}{eul} 먼저 확인했어요.", f"Heute habe ich zuerst {de} geprüft.", f"I checked {en} first today."),
            (f"{ko} 때문에 조금 늦었어요.", f"Wegen {de} bin ich etwas zu spät.", f"I was a bit late because of {en}."),
            (f"내일 {ko}{eul} 가져갈게요.", f"Morgen nehme ich {de} mit.", f"I will take {en} along tomorrow."),
            (f"{ko}{eun} 여기보다 저기가 더 싸요.", f"{de} ist dort günstiger als hier.", f"{en} is cheaper there than here."),
            (f"혹시 {ko} 있어요?", f"Haben Sie {de}?", f"Do you have {en}?"),
            (f"{ko}{euro} 갈까요?", f"Sollen wir zu {de} gehen?", f"Shall we go to {en}?"),
            (f"저는 {ko}{eul} 자주 써요.", f"Ich benutze {de} oft.", f"I use {en} often."),
            (f"{ko} 어떻게 해요?", f"Wie macht man das mit {de}?", f"How do you do that with {en}?"),
            *common[:4],
        ]
    if level == "B1":
        return [
            (f"{ko}{eul} 다시 확인해 주시겠어요?", f"Könnten Sie {de} bitte noch einmal prüfen?", f"Could you check {en} again?"),
            (f"{ko} 때문에 일정을 바꿨어요.", f"Wegen {de} habe ich den Termin geändert.", f"I changed the schedule because of {en}."),
            (f"오늘은 {ko}{eul} 먼저 처리하려고 해요.", f"Heute möchte ich zuerst {de} erledigen.", f"Today I want to take care of {en} first."),
            (f"{ko}{eun} 생각보다 시간이 더 걸렸어요.", f"{de} hat länger gedauert als gedacht.", f"{en} took longer than I expected."),
            (f"{ko}에 대해 더 알고 싶어요.", f"Ich möchte mehr über {de} wissen.", f"I want to know more about {en}."),
            (f"문제가 생기면 {ko}{eul} 바로 알려 주세요.", f"Wenn ein Problem auftritt, sagen Sie mir bitte sofort Bescheid zu {de}.", f"If a problem comes up, please tell me about {en} right away."),
            (f"{ko}{eul} 사진으로 남겨 두었어요.", f"Ich habe {de} als Foto festgehalten.", f"I saved {en} as a photo."),
            (f"지금은 {ko}보다 설명이 더 필요해요.", f"Gerade brauche ich eine Erklärung mehr als {de}.", f"Right now I need an explanation more than {en}."),
        ]
    if level == "B2":
        return [
            (f"{ko}{eul} 기준으로 일정을 다시 조정했습니다.", f"Wir haben den Zeitplan anhand von {de} neu abgestimmt.", f"We readjusted the schedule based on {en}."),
            (f"{ko}와 관련해 서면으로 남겨 주시면 좋겠습니다.", f"Bitte halten Sie {de} schriftlich fest.", f"Please put {en} in writing."),
            (f"{ko}{eun} 이번 결정의 전제입니다.", f"{de} ist die Voraussetzung für diese Entscheidung.", f"{en} is the premise of this decision."),
            (f"{ko}{eul} 빠뜨리면 나중에 이의가 생길 수 있습니다.", f"Wenn {de} fehlt, kann später ein Einwand entstehen.", f"If {en} is missing, an objection may arise later."),
            (f"회의에서는 {ko}부터 분명히 합시다.", f"Lassen Sie uns in der Sitzung zuerst {de} klären.", f"Let us clarify {en} first in the meeting."),
            (f"{ko}에 따라 범위가 달라집니다.", f"Der Umfang ändert sich je nach {de}.", f"The scope changes depending on {en}."),
            (f"{ko}{eul} 검토한 뒤에 답변드리겠습니다.", f"Ich antworte, nachdem ich {de} geprüft habe.", f"I will reply after reviewing {en}."),
            (f"지금은 {ko}보다 근거가 더 중요합니다.", f"Gerade ist die Begründung wichtiger als {de}.", f"Right now the rationale matters more than {en}."),
        ]
    if level == "C1":
        return [
            (f"{ko}{eul} 한계와 함께 설명해야 오해가 줄어듭니다.", f"Wenn wir {de} zusammen mit den Grenzen erklären, sinkt das Risiko von Missverständnissen.", f"Explaining {en} together with its limits reduces misunderstanding."),
            (f"{ko}만 강조하면 다른 이해관계자의 부담이 가려집니다.", f"Wenn nur {de} betont wird, bleiben die Lasten anderer Beteiligter unsichtbar.", f"If only {en} is emphasized, other stakeholders' burdens stay hidden."),
            (f"{ko}{eun} 자료가 불완전할 때 결론의 강도를 낮추는 기준입니다.", f"{de} ist der Maßstab, die Stärke der Schlussfolgerung zu senken, wenn die Daten unvollständig sind.", f"{en} is the standard for softening a conclusion when the data are incomplete."),
            (f"공개 설명에서는 {ko}{eul} 숫자와 예외를 같이 밝혀야 합니다.", f"In der öffentlichen Erklärung müssen {de}, Zahlen und Ausnahmen gemeinsam genannt werden.", f"A public explanation must state {en}, the numbers, and the exceptions together."),
            (f"{ko}{eul} 빼고 성공만 말하면 신뢰가 떨어집니다.", f"Wenn wir {de} weglassen und nur den Erfolg nennen, sinkt das Vertrauen.", f"Leaving out {en} and reporting only success weakens trust."),
            (f"지역 여건을 보면 {ko}{eul} 그대로 옮길 수 없습니다.", f"Angesichts der örtlichen Bedingungen lässt sich {de} nicht einfach übertragen.", f"Given local conditions, {en} cannot be copied as-is."),
        ]
    return [
        (f"{ko}{eun} 책임을 어디에 둘지를 가리는 표현이 되기 쉽습니다.", f"{de} kann leicht zu einer Formulierung werden, die Verantwortlichkeit verschleiert.", f"{en} can easily become wording that hides where responsibility sits."),
        (f"{ko}{eul} 제도의 전제로 두면 이의 제기 경로가 좁아집니다.", f"Wenn {de} als institutionelle Voraussetzung gilt, verengt sich der Weg zum Einspruch.", f"Treating {en} as an institutional given narrows the path to appeal."),
        (f"기록에는 {ko}와 결정 권한의 소재를 함께 남겨야 합니다.", f"In der Akte müssen {de} und die Entscheidungsbefugnis gemeinsam festgehalten werden.", f"The record must keep {en} together with who holds decision authority."),
        (f"{ko}만으로 절차가 공정하다고 말할 수는 없습니다.", f"Allein mit {de} lässt sich nicht behaupten, das Verfahren sei fair.", f"{en} alone cannot justify calling the procedure fair."),
        (f"{ko}{eul} 해석의 틀로 쓰면 어떤 기억이 남고 어떤 기억이 지워지는지 물어야 합니다.", f"Wenn {de} als Deutungrahmen dient, müssen wir fragen, welche Erinnerung bleibt und welche gelöscht wird.", f"If {en} is used as an interpretive frame, we must ask which memories stay and which are erased."),
        (f"자동 결정에서도 {ko}{eul} 사람이 철회할 수 있어야 합니다.", f"Auch bei automatisierten Entscheidungen muss eine Person {de} zurücknehmen können.", f"Even in automated decisions, a person must be able to withdraw {en}."),
    ]


def _verb_frames(level: str, ko: str, de: str, en: str) -> list[tuple[str, str, str]]:
    # Keep the dictionary headword visible so Cloze can blank it.
    if level in {"A1", "A2"}:
        return [
            (f"오늘은 {ko} 연습을 해요.", f"Heute übe ich {de}.", f"Today I practice {en}."),
            (f"친구에게 {ko} 방법을 물어봤어요.", f"Ich habe eine Freundin nach der Art von {de} gefragt.", f"I asked a friend how to do {en}."),
            (f"저는 {ko}가 아직 어려워요.", f"{de} fällt mir noch schwer.", f"{en} is still hard for me."),
            (f"내일 {ko}를 다시 해 볼게요.", f"Morgen versuche ich {de} noch einmal.", f"Tomorrow I will try {en} again."),
            (f"교실에서 {ko} 표현을 배웠어요.", f"Im Unterricht habe ich den Ausdruck für {de} gelernt.", f"In class I learned the expression for {en}."),
            (f"{ko} 전에 이름을 말해 주세요.", f"Sagen Sie bitte den Namen, bevor Sie {de}.", f"Please say the name before you {en}."),
        ]
    if level == "B1":
        return [
            (f"지금은 {ko}보다 이유를 먼저 말하고 싶어요.", f"Gerade möchte ich zuerst den Grund nennen, bevor ich {de}.", f"Right now I want to give the reason before I {en}."),
            (f"{ko} 실수를 줄이려면 메모가 필요해요.", f"Um Fehler bei {de} zu vermeiden, brauche ich Notizen.", f"I need notes to make fewer mistakes with {en}."),
            (f"상대가 바쁠 때는 {ko}를 미루는 편이 좋아요.", f"Wenn die andere Person beschäftigt ist, ist es besser, {de} zu verschieben.", f"When the other person is busy, it is better to postpone {en}."),
            (f"{ko} 다음에는 결과를 짧게 공유할게요.", f"Nach {de} teile ich das Ergebnis kurz.", f"After {en} I will share the result briefly."),
        ]
    if level == "B2":
        return [
            (f"{ko} 범위를 서면에 남겨 주세요.", f"Bitte halten Sie den Umfang von {de} schriftlich fest.", f"Please put the scope of {en} in writing."),
            (f"{ko}를 전제로 일정을 잡지 않겠습니다.", f"Ich werde den Termin nicht unter der Voraussetzung von {de} festlegen.", f"I will not set the schedule on the assumption of {en}."),
            (f"{ko}와 관련한 책임을 분명히 합시다.", f"Lassen Sie uns die Verantwortung im Zusammenhang mit {de} klären.", f"Let us clarify responsibility related to {en}."),
            (f"{ko} 전에는 근거를 같이 봐야 합니다.", f"Vor {de} müssen wir uns die Begründung gemeinsam ansehen.", f"Before {en} we need to look at the rationale together."),
        ]
    return [
        (f"{ko}를 허용하는 조건과 철회 조건을 같이 적어야 합니다.", f"Die Bedingungen, {de} zuzulassen und zurückzunehmen, müssen gemeinsam festgehalten werden.", f"The conditions for allowing and withdrawing {en} must be written together."),
        (f"{ko}만으로 절차가 끝났다고 말할 수 없습니다.", f"Allein durch {de} ist das Verfahren nicht abgeschlossen.", f"{en} alone does not mean the procedure is finished."),
        (f"공개 기록에는 {ko}의 한계를 남겨야 합니다.", f"In der öffentlichen Akte muss die Grenze von {de} stehen.", f"The public record must keep the limits of {en}."),
        (f"{ko}가 자동으로 이뤄져도 사람이 이의를 제기할 수 있어야 합니다.", f"Auch wenn {de} automatisch geschieht, muss eine Person Einspruch einlegen können.", f"Even if {en} happens automatically, a person must be able to object."),
    ]


def _adj_frames(level: str, ko: str, de: str, en: str, eun: str, i: str) -> list[tuple[str, str, str]]:
    return [
        (f"오늘 날씨가 {ko}예요.", f"Das Wetter ist heute {de}.", f"The weather is {en} today."),
        (f"이 방이 {ko}해요.", f"Dieser Raum ist {de}.", f"This room is {en}."),
        (f"{ko}{eun} 느낌이 달라요.", f"{de} fühlt sich anders an.", f"{en} feels different."),
        (f"너무 {ko}하지 않아요.", f"Es ist nicht zu {de}.", f"It is not too {en}."),
        (f"저는 {ko}한 곳을 좋아해요.", f"Ich mag Orte, die {de} sind.", f"I like places that are {en}."),
        (f"설명이 {ko}해서 이해가 됐어요.", f"Die Erklärung war {de}, deshalb habe ich sie verstanden.", f"The explanation was {en}, so I understood it."),
    ]


def _adv_frames(level: str, ko: str, de: str, en: str) -> list[tuple[str, str, str]]:
    return [
        (f"오늘은 {ko} 갈게요.", f"Heute gehe ich {de}.", f"I will go {en} today."),
        (f"{ko} 말해 주세요.", f"Bitte sprechen Sie {de}.", f"Please speak {en}."),
        (f"저는 {ko} 일어나요.", f"Ich stehe {de} auf.", f"I get up {en}."),
        (f"{ko} 걸으면 더 편해요.", f"Wenn man {de} läuft, ist es angenehmer.", f"It is more comfortable to walk {en}."),
        (f"지금은 {ko} 결정하고 싶어요.", f"Gerade möchte ich {de} entscheiden.", f"I want to decide {en} right now."),
        (f"{ko} 생각하면 답이 보여요.", f"Wenn man {de} nachdenkt, sieht man die Antwort.", f"If you think {en}, the answer appears."),
    ]


def _expr_frames(level: str, ko: str, de: str, en: str) -> list[tuple[str, str, str]]:
    return [
        (f"그 자리에서 {ko}라고 말했어요.", f"In der Situation habe ich {de} gesagt.", f"In that situation I said {en}."),
        (f"처음에는 {ko}가 자연스러워요.", f"Am Anfang ist {de} natürlich.", f"{en} feels natural at first."),
        (f"마지막에는 {ko}로 마무리했어요.", f"Am Ende habe ich mit {de} geschlossen.", f"I closed with {en} at the end."),
        (f"친구가 {ko}라고 해서 웃었어요.", f"Eine Freundin sagte {de}, und ich habe gelacht.", f"A friend said {en}, and I laughed."),
        (f"공손할 때는 {ko}를 씁니다.", f"In höflichen Lagen benutzt man {de}.", f"In polite situations people use {en}."),
        (f"문자에는 {ko}라고 남겼어요.", f"In der Nachricht habe ich {de} geschrieben.", f"I left {en} in the message."),
    ]
