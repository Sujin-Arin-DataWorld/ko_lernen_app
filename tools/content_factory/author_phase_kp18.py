"""KP18 synthesis with bounded conclusions. New source remains unsigned."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp18():
    rows=[
      ('G4:-다시피',loc('상대가 지금 보거나 이미 아는 내용을 환기해요. 보시다시피가 관찰 범위를 넘는 결론까지 증명하지는 않아요.','Recall what the listener can see or already knows. 보시다시피 does not prove conclusions beyond the observation.','Verweise auf Sichtbares oder bereits Bekanntes. 보시다시피 beweist keine Folgerung über die Beobachtung hinaus.'),
       ('보시다시피 자료마다 수치가 다릅니다.','함께 보는 자료의 수치 차이를 환기','차이의 원인과 옳은 수치를 모두 확정'),
       ('아시다시피 이 표는 작년 자료입니다.','이미 공유한 자료의 기준 연도를 환기','올해 상황을 실시간으로 보여 준다는 뜻')),
      ('G4:-거니와',loc('앞 사실을 인정하면서 다른 논거를 추가해요. 간단함과 비용이 각각의 장점이며 서로의 원인이라는 뜻은 아니에요.','Acknowledge one fact and add another reason. Simplicity and low cost are separate benefits, not necessarily causes of each other.','Erkenne einen Fakt an und ergänze einen weiteren Grund. Einfachheit und geringe Kosten sind getrennte Vorteile, nicht zwingend gegenseitige Ursachen.'),
       ('이 방법은 간단하거니와 비용도 적게 듭니다.','간단함에 낮은 비용이라는 장점 추가','간단하기만 하고 비용은 반드시 높음'),
       ('설명이 자세하거니와 예시도 충분합니다.','상세한 설명에 충분한 예시를 추가','예시는 전혀 없다는 반박')),
      ('G4:에 의하여',loc('여기서는 처리의 근거가 되는 절차나 규정을 표시해요. 누가 행동했는지 말하는 경우도 있으므로 뒤 문맥을 보고, 절차를 따랐다는 말만으로 결과의 타당성을 보증하지 않아요.','Here mark the procedure or rule used as a basis. Other contexts may identify an agent; read the surrounding text. Following a procedure does not alone establish a sound outcome.','Kennzeichne hier Verfahren oder Regel als Grundlage. Andere Kontexte können eine handelnde Person nennen; beachte den Kontext. Ein Verfahren zu befolgen garantiert kein sachlich richtiges Ergebnis.'),
       ('신청은 정해진 절차에 의하여 처리됩니다.','정해진 절차가 처리 기준','모든 신청이 자동 승인된다는 보증'),
       ('항목은 이 문서의 분류 기준에 의하여 나눕니다.','이 문서의 분류 기준을 적용함','모든 문서의 기준이 같다는 확정')),
      ('G4:-으므로',loc('격식 있는 이유와 결론을 연결해요. 자료 부족 때문에 결론을 유보하는 것과 결론이 거짓이라고 확정하는 것은 달라요.','Connect reason and conclusion formally. Withholding judgement for lack of data differs from declaring the conclusion false.','Verbinde Grund und Schluss förmlich. Ein Urteil wegen fehlender Daten zurückzustellen ist keine Feststellung seiner Falschheit.'),
       ('자료가 충분하지 않으므로 결론을 유보합니다.','자료 부족을 이유로 판단 보류','결론이 거짓이라고 입증함'),
       ('비교 기준이 다르므로 수치를 바로 합치지 않습니다.','기준 차이 때문에 단순 합산하지 않음','기준이 달라도 이미 같은 수치로 합산함')),
      ('G4:-나 싶다',loc('주관적 의문이나 추측을 조심스럽게 말해요. 자신의 설명이 부족했을 수 있다는 말은 모든 문제의 책임을 인정한 확정 진술이 아니에요.','Express a tentative personal question or inference. Considering whether your explanation was lacking is not accepting responsibility for every problem.','Äußere vorsichtig eine persönliche Frage oder Vermutung. Eine möglicherweise unzureichende eigene Erklärung ist kein Eingeständnis aller Verantwortung.'),
       ('내 설명이 부족했나 싶어요.','자기 설명의 부족 가능성을 조심스럽게 생각함','모든 문제의 책임을 확정적으로 인정함'),
       ('서로 다른 표를 보았나 싶어요.','본 표가 달랐을 가능성 추측','서로 같은 표를 봤다고 확인 완료')),
      ('G4:-는 듯',loc('확정 대신 인상이나 비슷해 보이는 상태를 문어적으로 나타내요. 아무 일도 없었던 듯 조용하다는 말은 실제로 아무 일도 없었다는 사실 보증이 아니에요.','Describe an impression or apparent state in a literary style rather than asserting certainty. Quiet as if nothing happened does not prove that nothing happened.','Beschreibe einen Eindruck oder Anschein in schriftsprachlichem Stil statt Gewissheit. Ruhe wie nach keinem Ereignis beweist nicht, dass nichts geschehen ist.'),
       ('아무 일도 없었던 듯 조용했습니다.','아무 일도 없었던 것처럼 느껴지는 정적','실제로 사건이 전혀 없었다고 확인'),
       ('모두 이해한 듯 고개를 끄덕였습니다.','이해한 것처럼 보이는 행동','모든 사람의 이해를 시험으로 검증')),
      ('G4:-을걸',loc('이 과제는 지난 선택의 후회를 나타내는 말끝을 다뤄요. 실제로 하지 못한 일을 했더라면 좋았겠다는 뜻이며 미래 예측과 구별해요.','Here practise regret about a past choice: wishing you had acted differently, not predicting the future.','Übe hier Bedauern über eine frühere Entscheidung: den Wunsch, anders gehandelt zu haben, keine Zukunftsprognose.'),
       ('이미 늦었어요. 조금 더 일찍 출발할걸.','일찍 출발하지 않은 선택을 후회','앞으로 반드시 일찍 출발한다는 예측'),
       ('원문을 안 보고 틀렸네요. 먼저 확인할걸.','미리 확인하지 않은 일을 후회','원문을 이미 정확히 확인했다는 보고')),
      ('G4:-을 모양이다',loc('정황을 근거로 앞으로 일어날 일을 예상해요. 어두운 하늘이나 줄 선 사람들은 단서이지 결과 확정이 아니에요.','Anticipate a future event from clues. A dark sky or queue is evidence for an expectation, not a confirmed outcome.','Erwarte ein künftiges Ereignis anhand von Anzeichen. Dunkler Himmel oder eine Warteschlange sind Hinweise, keine bestätigten Ergebnisse.'),
       ('하늘이 어두운 걸 보니 비가 올 모양이에요.','하늘을 근거로 비를 예상','비가 이미 내리는 것을 직접 관측'),
       ('사람들이 줄을 서는 걸 보니 곧 문을 열 모양이에요.','대기 줄을 근거로 개방 예상','운영자가 개방 시각을 확인해 줌')),
      ('G4:까지2',loc('예상하지 못한 대상도 포함된다고 강조해요. 여기서 까지는 시간이나 이동의 끝점이 아니며, 한 사람이 포함됐다고 전원이 같다고 넓히지 않아요.','Emphasise inclusion of an unexpected member, not a time or travel endpoint. One unexpected person does not mean everyone agrees.','Betone den Einschluss eines unerwarteten Mitglieds, keinen Zeit- oder Wegendpunkt. Eine unerwartete Person bedeutet nicht Übereinstimmung aller.'),
       ('가장 가까운 친구까지 반대했어요.','반대하지 않을 듯한 가까운 친구도 반대','세상의 모든 사람이 반대했다고 확정'),
       ('경험 많은 담당자까지 설명을 다시 물었어요.','예상 밖으로 숙련 담당자도 재질문','담당자 외에는 아무도 질문하지 않았다는 뜻')),
      ('G4:마저',loc('남아 있던 마지막 대상까지 포함된다는 뜻을 강조해요. 이 문맥에서는 마지막 기회나 남은 대안의 상실이라 아쉬움이 드러나요.','Emphasise inclusion of what was left. In these contexts losing the last chance or remaining alternative conveys disappointment.','Betone den Einschluss des noch Verbliebenen. Der Verlust der letzten Chance oder Alternative drückt hier Bedauern aus.'),
       ('마지막 기회마저 놓쳤어요.','남은 마지막 기회까지 놓침','마지막 기회는 아직 그대로 남음'),
       ('예비 공간마저 사용할 수 없게 됐어요.','남은 예비 공간도 사용 불가','예비 공간만은 이용이 보장됨')),
      ('G4:이야',loc('대비되는 대상을 특별히 강조해요. 다른 부분은 몰라도 시간은 조정 가능하다는 말의 범위를 모든 조건의 변경 가능성으로 넓히지 않아요.','Highlight one contrasting topic. Being able to adjust the time does not imply freedom to change every condition.','Hebe ein kontrastierendes Thema hervor. Die Zeit ändern zu können bedeutet nicht, jede Bedingung ändern zu dürfen.'),
       ('다른 것은 몰라도 시간이야 조정할 수 있어요.','시간을 특별히 대비해 조정 가능하다고 말함','모든 조건을 무제한 바꿀 수 있다는 뜻'),
       ('다른 부분은 몰라도 제목이야 다시 쓸 수 있어요.','제목의 수정 가능성을 한정해 강조','본문 사실까지 자유롭게 바꿔도 된다는 뜻')),
      ('G4:커녕',loc('더 큰 기대는 물론 더 낮은 단계조차 충족하지 못함을 강조해요. 이 문장의 척도에서 쉬는 시간보다 밥 먹을 시간이 더 낮은 기본 기대예요.','Deny not only a higher expectation but even a lower one. In this sentence time to eat is the more basic expectation below time to rest.','Verneine nicht nur eine höhere, sondern selbst eine geringere Erwartung. Zeit zum Essen ist hier die grundlegendere Erwartung unterhalb der Ruhezeit.'),
       ('쉬기는커녕 밥 먹을 시간도 없었어요.','휴식은 물론 식사할 시간도 없음','쉬지는 못했지만 식사는 충분히 함'),
       ('자세한 검토는커녕 제목도 못 읽었어요.','상세 검토보다 낮은 제목 읽기도 못 함','제목을 읽고 상세 검토까지 마침')),
      ('G4:-을 따름이다',loc('격식 있게 자신의 행동이나 주장을 제한해요. 확인 사실만 말했다는 최소 주장에 타인의 결백·책임 같은 결론을 더하지 않아요.','Limit your action or claim formally. Merely stating verified facts does not establish someone else’s innocence or responsibility.','Begrenze Handlung oder Aussage förmlich. Nur bestätigte Fakten genannt zu haben belegt weder Unschuld noch Verantwortlichkeit anderer.'),
       ('저는 확인된 사실을 말씀드렸을 따름입니다.','화자의 주장은 확인된 사실 전달에 한정','모든 책임자를 확정했다는 주장'),
       ('저희는 두 자료를 비교했을 따름입니다.','비교했다는 행동만 주장','하나의 원인을 실험으로 입증했다는 주장')),
      ('G4:-고자',loc('격식 있는 목적이나 의도를 제시해요. 원인을 밝히려 조사를 시작했다고 해서 목적을 이미 달성한 것은 아니에요.','State a formal purpose or intention. Starting an investigation to find a cause does not mean it has already been found.','Nenne einen förmlichen Zweck oder eine Absicht. Eine Ursachenprüfung zu beginnen heißt nicht, die Ursache bereits gefunden zu haben.'),
       ('문제의 원인을 밝히고자 조사를 시작했습니다.','원인 규명을 목적으로 조사 시작','원인 규명이 이미 완료됨'),
       ('의견 차이를 줄이고자 대화를 제안했습니다.','차이 축소를 목적으로 대화 제안','상대가 대화를 수락했고 이견도 해소됨')),
      ('G4:-고도',loc('앞 행동을 했지만 기대한 결과는 나오지 않았음을 말해요. 설명을 들었다는 사실과 이해하지 못했다는 결과를 함께 보존해요.','State that an action occurred but its expected result did not. Preserve both hearing the explanation and not understanding it.','Zeige, dass eine Handlung stattfand, ihr erwartetes Ergebnis aber ausblieb. Erhalte sowohl das Hören der Erklärung als auch das Nichtverstehen.'),
       ('설명을 듣고도 이해하지 못했어요.','설명은 들었지만 이해는 못 함','설명을 듣지 않았다는 뜻'),
       ('두 번 확인하고도 오류를 놓쳤어요.','확인을 두 번 했으나 오류 발견 실패','확인을 한 번도 하지 않았다는 뜻')),
      ('G4:-고 들다',loc('상대가 행동을 밀어붙이는 태도를 나타내요. 따지고 든다는 평가는 질문이 있었다는 중립 기록과 다르며 의도를 과도하게 단정하지 않아요.','Portray someone pressing an action insistently. Describing persistent confrontation differs from a neutral record of questions; do not overstate motive.','Stelle nachdrückliches Beharren auf einer Handlung dar. Die Bewertung als bedrängendes Nachfragen unterscheidet sich vom neutralen Fragenprotokoll; übertreibe keine Motive.'),
       ('그는 설명을 듣지도 않고 따지고 들었어요.','설명을 듣기 전부터 따지는 태도로 밀어붙임','설명을 끝까지 조용히 듣고 동의함'),
       ('그 사람은 답을 듣기도 전에 반박하고 들었어요.','답을 듣기 전 반박을 밀어붙임','답을 검증한 후에만 반박했다는 뜻')),
      ('G4:-고 보다',loc('다른 판단보다 행동부터 하는 순서를 나타내요. 일단 신청한 것과 조건을 확인해 승인받은 것을 구별해요.','Act before further deliberation. Applying first differs from checking conditions and receiving approval.','Handle vor weiterer Abwägung. Erst einmal einen Antrag zu stellen ist nicht dasselbe wie Bedingungen zu prüfen und eine Genehmigung zu erhalten.'),
       ('급해서 일단 신청하고 봤어요. 조건은 나중에 읽었어요.','조건 검토보다 신청을 먼저 함','조건을 모두 확인하고 승인까지 받음'),
       ('시간이 없어 일단 적고 봤어요. 맞는지는 뒤에 확인했어요.','먼저 적고 정확성은 나중에 확인','정확성을 먼저 검증한 뒤 기록')),
      ('G4:-고 해서',loc('여러 사정 중 하나를 이유로 들어 설명해요. 날씨가 춥다는 이유만이 유일한 원인이라고 제한하지 않아요.','Offer one reason among several circumstances rather than claiming it is the sole cause.','Nenne einen Grund unter mehreren Umständen, ohne ihn zur einzigen Ursache zu machen.'),
       ('날씨도 춥고 해서 실내에서 만났어요.','추위도 실내 만남의 이유 중 하나','추위만이 유일한 이유라고 확정'),
       ('자료도 부족하고 해서 결론을 미뤘어요.','자료 부족 등 여러 사정으로 판단 연기','자료 부족과 무관하게 결론을 이미 확정')),
      ('G4:-는 대로',loc('앞 행동이 끝나면 바로 뒤 행동을 하겠다는 순서를 말해요. 확인하는 대로 연락한다는 말은 확인 시각이나 내용까지 이미 확정했다는 뜻은 아니에요.','Promise the next action as soon as the first is completed, without fixing the completion time or result in advance.','Sage die Folgehandlung unmittelbar nach Abschluss der ersten zu, ohne Zeitpunkt oder Ergebnis vorweg festzulegen.'),
       ('확인하는 대로 연락드리겠습니다.','확인 뒤 바로 연락할 계획','지금 이미 확인과 연락을 모두 마침'),
       ('답변이 오는 대로 전달하겠습니다.','답변 수신 직후 전달할 계획','답변 도착 시각을 이미 확정함')),
    ]
    tasks=[grammar_task('KP18',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G4:-다시피',('함께 본 표를 근거로 / 표에서 보다 / 올해 신청이 늘다 / -다시피, 합쇼체','표에서 보시다시피 올해 신청이 늘었습니다.','표로 신청 증가의 원인까지 증명했습니다.'),('함께 읽은 기록을 근거로 / 기록에서 확인하다 / 작년에는 운영하지 않다 / -다시피, 합쇼체','기록에서 확인하시다시피 작년에는 운영하지 않았습니다.','작년에도 운영했습니다.')),
      ('G4:-거니와',('두 장점을 추가 / 이 방법은 비용이 적게 들다 + 사용도 쉽다 / -거니와, 해요체','이 방법은 비용이 적게 들거니와 사용도 쉬워요.','비용이 적게 들어서 반드시 사용이 쉬워요.'),('두 문제를 추가 / 이 자료는 오래되다 + 출처도 불분명하다 / -거니와, 해요체','이 자료는 오래되었거니와 출처도 불분명해요.','오래되었다는 이유만으로 출처가 거짓임을 증명했어요.')),
      ('G4:에 의하여',('절차의 근거 / 운영 규정 / 신청을 검토하다 / 에 의하여, 합쇼체','운영 규정에 의하여 신청을 검토합니다.','규정에 따라 모든 신청을 자동 승인합니다.'),('절차의 근거 / 공개된 기준 / 자료를 분류하다 / 에 의하여, 합쇼체','공개된 기준에 의하여 자료를 분류합니다.','기준 없이 자료를 분류합니다.')),
      ('G4:-으므로',('근거와 판단 / 자료가 부족하다 → 결론을 유보하다 / -으므로, 합쇼체','자료가 부족하므로 결론을 유보합니다.','자료가 부족하므로 주장이 거짓이라고 확정합니다.'),('근거와 판단 / 집계 기준이 다르다 → 두 수치를 합산하지 않다 / -으므로, 합쇼체','집계 기준이 다르므로 두 수치를 합산하지 않습니다.','집계 기준이 같으므로 두 수치를 합산합니다.')),
      ('G4:-나 싶다',('조심스러운 자문 / 내가 설명을 너무 줄이다 / 과거 -나 싶다, 해요체','내가 설명을 너무 줄였나 싶어요.','모든 문제가 제 책임이라고 확정했어요.'),('가능성 검토 / 우리가 확인을 서두르다 / 과거 -나 싶다, 해요체','우리가 확인을 서둘렀나 싶어요.','우리가 고의로 거짓말했다고 확정했어요.')),
      ('G4:-는 듯',('관찰자의 인상 / 그는 무언가를 기다리다 / -는 듯하다, 해요체','그는 무언가를 기다리는 듯해요.','그가 기다리는 대상을 확인했어요.'),('관찰자의 인상 / 두 사람은 같은 곳을 바라보다 / -는 듯하다, 해요체','두 사람은 같은 곳을 바라보는 듯해요.','두 사람의 의도를 직접 확인했어요.')),
      ('G4:-을걸',('하지 않은 행동의 후회 / 미리 공지를 확인하다 / -을걸 그랬어요','미리 공지를 확인할걸 그랬어요.','미리 공지를 확인할 확률이 높아요.'),('하지 않은 행동의 후회 / 원문을 끝까지 읽다 / -을걸 그랬어요','원문을 끝까지 읽을걸 그랬어요.','원문을 끝까지 읽었다고 보고해요.')),
      ('G4:-을 모양이다',('예측 / 먹구름이 끼다 → 곧 비가 오다 / -을 모양이다, 해요체','먹구름이 끼니 곧 비가 올 모양이에요.','비가 이미 온 것을 확인했어요.'),('예측 / 줄이 길다 → 오래 기다리다 / -을 모양이다, 해요체','줄이 길어서 오래 기다릴 모양이에요.','기다릴 시간을 정확히 확인했어요.')),
      ('G4:까지2',('예상 밖의 포함 / 평소 조용하던 동료 / 질문하다 / 까지, 과거 해요체','평소 조용하던 동료까지 질문했어요.','모든 동료가 반드시 질문했어요.'),('예상 밖의 포함 / 발표를 마친 사람 / 남아서 듣다 / 까지, 과거 해요체','발표를 마친 사람까지 남아서 들었어요.','발표를 마친 사람은 모두 떠났어요.')),
      ('G4:마저',('마지막 남은 기회도 사라짐 / 마지막 기회 / 놓치다 / 마저, 과거 해요체','마지막 기회마저 놓쳤어요.','마지막 기회만은 남아 있어요.'),('마지막 대안도 불가 / 예비 공간 / 사용할 수 없게 되다 / 마저, 과거 해요체','예비 공간마저 사용할 수 없게 됐어요.','예비 공간은 사용할 수 있어요.')),
      ('G4:이야',('대상 한정 대비 / 다른 것은 몰라도 / 시간 / 조정할 수 있다 / 이야, 해요체','다른 것은 몰라도 시간이야 조정할 수 있어요.','모든 조건을 바꿀 수 있어요.'),('대상 한정 대비 / 다른 부분은 몰라도 / 제목 / 다시 쓸 수 있다 / 이야, 해요체','다른 부분은 몰라도 제목이야 다시 쓸 수 있어요.','본문의 사실까지 바꿔도 돼요.')),
      ('G4:커녕',('높은 기대와 낮은 기대 모두 불충족 / 쉬다 → 밥 먹을 시간도 없다 / -기는커녕, 과거 해요체','쉬기는커녕 밥 먹을 시간도 없었어요.','쉬지는 못했지만 식사는 충분히 했어요.'),('높은 기대와 낮은 기대 모두 불충족 / 자세한 검토 → 제목도 못 읽다 / 커녕, 과거 해요체','자세한 검토는커녕 제목도 못 읽었어요.','제목을 읽고 상세 검토도 했어요.')),
      ('G4:-을 따름이다',('최소 주장 / 저는 확인된 사실을 말씀드리다 / 과거 -을 따름이다, 합쇼체','저는 확인된 사실을 말씀드렸을 따름입니다.','저는 모든 책임자를 확정했습니다.'),('최소 주장 / 저희는 두 자료를 비교하다 / 과거 -을 따름이다, 합쇼체','저희는 두 자료를 비교했을 따름입니다.','저희는 원인을 실험으로 입증했습니다.')),
      ('G4:-고자',('목적 / 문제의 원인을 밝히다 → 조사를 시작하다 / -고자, 과거 합쇼체','문제의 원인을 밝히고자 조사를 시작했습니다.','문제의 원인을 이미 밝혔습니다.'),('목적 / 의견 차이를 줄이다 → 대화를 제안하다 / -고자, 과거 합쇼체','의견 차이를 줄이고자 대화를 제안했습니다.','대화가 끝나서 모든 이견이 해소됐습니다.')),
      ('G4:-고도',('기대와 어긋난 결과 / 설명을 듣다 → 이해하지 못하다 / -고도, 과거 해요체','설명을 듣고도 이해하지 못했어요.','설명을 듣지 않았어요.'),('기대와 어긋난 결과 / 두 번 확인하다 → 오류를 놓치다 / -고도, 과거 해요체','두 번 확인하고도 오류를 놓쳤어요.','확인을 한 번도 하지 않았어요.')),
      ('G4:-고 들다',('밀어붙이는 태도 / 그는 설명을 듣지도 않고 / 따지다 / -고 들다, 과거 해요체','그는 설명을 듣지도 않고 따지고 들었어요.','그는 설명을 끝까지 듣고 동의했어요.'),('밀어붙이는 태도 / 그 사람은 답을 듣기도 전에 / 반박하다 / -고 들다, 과거 해요체','그 사람은 답을 듣기도 전에 반박하고 들었어요.','그 사람은 답을 검증한 뒤에만 반박했어요.')),
      ('G4:-고 보다',('행동 우선 / 급해서 일단 신청하다 / -고 보다, 과거 해요체','급해서 일단 신청하고 봤어요.','조건을 모두 검토해 승인을 받았어요.'),('행동 우선 / 시간이 없어 일단 적다 / -고 보다, 과거 해요체','시간이 없어 일단 적고 봤어요.','정확성을 먼저 검증한 뒤 적었어요.')),
      ('G4:-고 해서',('여러 이유 중 하나 / 날씨도 춥다 → 실내에서 만나다 / -고 해서, 과거 해요체','날씨도 춥고 해서 실내에서 만났어요.','추위만이 유일한 이유였어요.'),('여러 이유 중 하나 / 자료도 부족하다 → 결론을 미루다 / -고 해서, 과거 해요체','자료도 부족하고 해서 결론을 미뤘어요.','자료와 무관하게 결론을 확정했어요.')),
      ('G4:-는 대로',('즉시 후속 행동 약속 / 확인하다 → 연락드리다 / -는 대로, -겠습니다','확인하는 대로 연락드리겠습니다.','확인과 연락을 이미 마쳤습니다.'),('즉시 후속 행동 약속 / 답변이 오다 → 전달하다 / -는 대로, -겠습니다','답변이 오는 대로 전달하겠습니다.','답변이 올 시각을 확정했습니다.')),
    ]
    tasks+=production('KP18',tasks,prod)
    h=loc('출처·관찰·추론·평가를 나누고 결론의 범위를 표시해요. 같은 수치에 두 해석이 가능하면 추가 자료 없이는 한 원인을 확정하지 않아요. 강조나 후회를 사실 확인으로 바꾸지 말고 반론의 타당한 부분과 남은 한계를 함께 설명하세요.',
      'Separate source, observation, inference and evaluation, and state the scope of your conclusion. If the same figures allow two interpretations, do not establish a single cause without further evidence. Emphasis and regret do not verify facts. Explain the valid part of an objection together with remaining limits.',
      'Trenne Quelle, Beobachtung, Schluss und Bewertung und begrenze dein Fazit. Lassen dieselben Zahlen zwei Deutungen zu, lege ohne weitere Belege keine einzige Ursache fest. Nachdruck und Bedauern bestätigen keine Fakten. Erkläre den berechtigten Teil eines Einwands und verbleibende Grenzen.')
    def materials(place,service,old,new,alternative):
        return f'''학습용 창작 기사 — {place}, {service} 시범 운영 후 기록 공개
{place}는 {service} 시범 운영 전후의 이용 기록을 공개했다. 전기에는 {old}건, 후기에는 {new}건이었다. 두 기간은 같은 길이이며 집계 기준도 같지만, 같은 사람이 여러 번 이용한 경우가 포함된다. 고유 이용자 수는 조사하지 않았다. 시범 운영과 같은 시기에 {alternative}도 시행됐다. 어느 변화가 증가에 얼마나 기여했는지는 확인되지 않았다. 기사에 따르면 정규 창구는 잠시 닫혔고 마지막 대안인 임시 창구마저 문을 닫았다. 온라인 이용은 가능했으나 기기가 없는 사람의 상황은 조사하지 않았다. 담당자는 절차에 의하여 의견을 검토하겠다고 밝혔을 뿐, 확대 운영을 승인한 것은 아니다.

별도 기고문 — 편리함만으로 충분한가
먼저 이 글은 이용 횟수와 접근 기회의 관계만 논의한다. 비용과 고용 효과는 자료가 없으므로 결론에서 제외한다. 표에서 보시다시피 이용 기록은 늘었다. 그러나 그 이유는 제도의 편의성 향상일 수도 있고, 동시에 시행한 {alternative}의 효과일 수도 있다. 두 설명이 함께 성립할 가능성도 있다.
확대를 지지하는 사람들은 기다리는 시간을 줄일 수 있거니와 이용 선택권도 넓어진다고 주장한다. 이 주장에는 타당한 기대가 있다. 다만 이 조사에서 대기 시간과 선택권 변화는 측정하지 않았다. 온라인이 유일한 경로가 되면 기기가 없는 사람은 혜택을 누리기는커녕 신청조차 못 할 수 있다는 반론도 검토해야 한다. 이는 가능성에 대한 경고이며 이미 모든 사람이 신청에 실패했다는 보고가 아니다.
따라서 저는 전면 확대의 효과를 입증했을 따름이라고 말할 수 없다. 확인된 것은 이용 횟수 증가뿐이다. 기기 보유 여부별 접근 기회를 조사하고 대면 대안을 확보하는 조건으로 추가 시범 운영을 제안한다. 격차를 줄이고자 하는 목적과 실제 격차 감소는 구별해야 한다. 결과를 확인하는 대로 다시 판단하되, 지금 전면 확대나 전면 폐지를 확정하지는 말자.'''
    def briefing(place,service,old,new,alternative):
        text=f'''가상 공개 발표와 동등한 동료의 질의입니다. 두 사람은 운영 승인 권한이 없습니다.
발표자: 오늘은 {place}의 {service} 기록과 접근 기회를 말씀드리겠습니다. 여러분께 방금 같은 표를 나눠 드렸습니다. 표에서 보시다시피 전기 {old}건에서 후기 {new}건으로 늘었습니다. 중복 이용이 포함된 횟수이며 고유 이용자 수는 모릅니다. 같은 시기에 {alternative}도 시행됐습니다. 따라서 편의성이 좋아진 결과일 수도, 동시 조치의 효과일 수도 있습니다. 어느 하나만 원인이라고 확정할 수는 없습니다.
동료: 이용이 늘었으니 성공 아닌가요? 확대를 미루면 혜택도 늦어질 텐데요.
발표자: 혜택이 늦어질 수 있다는 지적은 타당합니다. 다만 접근 격차를 확인하지 않았으므로 조건부 시범 운영을 제안합니다. 모든 효과를 부정하는 것이 아닙니다. 비용 절감이나 고용 감소는 이번 자료의 범위 밖입니다.
동료: 저는 급해서 일단 요약만 적고 봤어요. 원문을 끝까지 읽을걸 그랬어요. 확인을 너무 서둘렀나 싶어요.
발표자: 그 말씀은 과거 행동에 대한 후회와 조심스러운 자기 점검으로 이해했습니다. 자료가 부족하고 해서 저도 결론을 유보했습니다. 조사 결과가 오는 대로 전달하겠습니다. 도착 시각은 아직 모릅니다. 결론적으로 횟수 증가를 확인했을 따름이며 원인이나 전면 확대를 확정한 것은 아닙니다.'''
        return packet(text,[
          choice('metric',loc('증가한 지표는?', 'Which measure increased?', 'Welche Kennzahl stieg?'),['중복을 포함한 이용 횟수','서로 다른 이용자 수'],h),
          choice('cause',loc('가능한 원인 해석은?', 'Which causal interpretation is justified?', 'Welche Ursachendeutung ist vertretbar?'),['편의성 변화·동시 조치·둘의 영향 모두 가능','편의성 하나가 유일한 원인으로 입증됨'],h),
          choice('objection',loc('인정한 반론과 응답은?', 'Which objection and response are retained?', 'Welcher Einwand und welche Antwort bleiben erhalten?'),['혜택 지연 가능성 인정, 접근 격차를 확인할 조건부 시범 제안','효과가 없다는 이유로 모든 운영 즉시 폐지'],h),
          choice('scope',loc('결론에서 제외한 범위는?', 'What is outside the conclusion’s scope?', 'Was liegt außerhalb des Fazits?'),['비용 절감과 고용 변화','기록된 이용 횟수'],h),
          choice('regret',loc('읽을걸 그랬어요의 기능은?', 'What does 읽을걸 그랬어요 express?', 'Was drückt 읽을걸 그랬어요 aus?'),['과거에 끝까지 읽지 않은 행동의 후회','미래에 읽을 확률의 예측'],h),
          choice('certainty',loc('서둘렀나 싶어요는?', 'What does 서둘렀나 싶어요 express?', 'Was drückt 서둘렀나 싶어요 aus?'),['가능성을 조심스럽게 검토','고의적 잘못과 모든 책임의 확정'],h),
          choice('followup',loc('조사 결과 전달의 조건은?', 'What triggers forwarding the findings?', 'Was löst die Weitergabe der Ergebnisse aus?'),['결과가 도착하면 전달, 도착 시각 미정','이미 결과를 받아 전달 완료'],h),
        ],'audio')
    practice=('푸른배움터','디지털 자료 대여',80,120,'이용 안내 교육')
    assess=('나래문화관','온라인 행사 접수',60,95,'지역 홍보 캠페인')
    tasks.append(task('KP18','listening:01','listening',loc('발표의 근거와 유보 듣기','Hear evidence and reservations in a presentation','Belege und Vorbehalte im Vortrag hören'),h,briefing(*practice),briefing(*assess)))
    def reading(args):
        return packet(materials(*args),[
          choice('sources',loc('기사와 기고문을 구별하면?', 'How do the article and commentary differ?', 'Wie unterscheiden sich Bericht und Kommentar?'),['기사는 관찰·담당자 말을 전하고 기고문은 조건부 제안을 함','두 자료 모두 전면 확대 승인 사실을 보도함'],h),
          choice('measure',loc('횟수 증가에서 바로 알 수 없는 것은?', 'What does the count increase not establish?', 'Was belegt der Anstieg der Nutzungsfälle nicht?'),['고유 이용자 수와 단일 원인','후기 기록이 전기보다 많다는 점'],h),
          choice('last',loc('임시 창구마저 닫혔다는 말은?', 'What does the closure with 마저 mean?', 'Was bedeutet die Schließung mit 마저?'),['마지막 대면 대안도 없어짐','온라인 경로까지 모두 중단됨'],h),
          choice('scale',loc('혜택은커녕 신청조차 못 할 수 있다는 말은?', 'What is the scale and certainty of the warning?', 'Welche Skala und Sicherheit hat die Warnung?'),['혜택보다 기본인 신청도 불가능할 수 있다는 경고','모든 이용자가 이미 혜택과 신청에 실패했다는 집계'],h),
          choice('claim',loc('결론에서 인정한 사실은?', 'What fact does the conclusion retain?', 'Welchen Fakt hält das Fazit fest?'),['이용 횟수 증가','제도의 단독 효과와 격차 해소'],h),
          choice('condition',loc('추가 시범 운영 제안의 조건은?', 'What conditions accompany the proposed further pilot?', 'Welche Bedingungen begleiten den weiteren Pilotvorschlag?'),['접근 기회 조사와 대면 대안 확보','효과 측정 없이 전면 확대를 이미 승인'],h),
          choice('purpose',loc('격차를 줄이고자는 무엇을 뜻하나요?', 'What does 격차를 줄이고자 express?', 'Was bedeutet 격차를 줄이고자?'),['격차 감소라는 목적','격차 감소가 이미 입증됐다는 결과'],h),
        ])
    tasks.append(task('KP18','reading:01','reading',loc('기사와 논설문의 주장 범위','Scope of claims in a report and opinion essay','Aussagegrenzen in Bericht und Meinungsbeitrag'),h,reading(practice),reading(assess)))
    rubric=loc('두 자료를 인용해 범위 제시 → 두 논거 → 가장 강한 반론 → 인정할 점과 응답 → 제한된 결론의 순서로 논설문을 쓰세요. 이용 횟수와 사람 수를 구별하고 같은 수치에 가능한 두 원인을 제시하세요. 편의·선택권의 기대와 미측정 결과를 나누고, 접근 격차와 대면 대안을 평가 기준으로 삼으세요. 비용·고용은 미상으로 남기세요. 마저·커녕의 척도, -으므로의 근거, -을 따름이다의 제한을 사실에 맞게 사용하세요. 근거 구절과 출처를 다시 대조해 과장한 결론을 고쳐 쓰세요. 전체 의미·논증 품질은 미채점입니다.',
      'Cite both sources and write an opinion essay in this order: scope, two arguments, strongest objection, concession and response, limited conclusion. Distinguish use counts from people and offer two possible causes for the same figures. Separate expected convenience and choice from unmeasured outcomes; assess access gaps and an in-person alternative. Leave costs and employment unknown. Use the scales of 마저 and 커녕, reasons with -으므로 and limits with -을 따름이다 consistently with the evidence. Check cited passages and sources, then revise overstatement. Overall meaning and argumentative quality remain unscored.',
      'Zitiere beide Quellen und schreibe einen Meinungsbeitrag in dieser Reihenfolge: Umfang, zwei Argumente, stärkster Einwand, Zugeständnis und Antwort, begrenztes Fazit. Trenne Nutzungsfälle von Personen und nenne zwei mögliche Ursachen derselben Zahlen. Unterscheide erwartete Bequemlichkeit und Wahlfreiheit von ungemessenen Ergebnissen; bewerte Zugangslücken und eine persönliche Alternative. Kosten und Beschäftigung bleiben unbekannt. Nutze die Skalen von 마저 und 커녕, Gründe mit -으므로 und Grenzen mit -을 따름이다 belegtreu. Prüfe Belegstellen und Quellen und überarbeite Übertreibungen. Gesamtinhalt und Argumentationsqualität bleiben unbewertet.')
    def writing(args):
        return packet(materials(*args),[free_text('essay',loc('근거·반론·조건부 결론을 연결한 논설문을 쓰세요.','Write an opinion essay linking evidence, objections and a conditional conclusion.','Schreibe einen Meinungsbeitrag mit Belegen, Einwänden und bedingtem Fazit.'),rubric)],'form')
    tasks.append(task('KP18','writing:01','writing',loc('두 논거를 종합한 조건부 제안','A conditional proposal synthesising two arguments','Bedingter Vorschlag aus zwei Argumenten'),rubric,writing(practice),writing(assess)))
    speech=loc('공개 발표에서는 합쇼체로 논의 범위·두 원인 해석·추가 확인이 필요한 점을 설명하세요. 동등한 동료가 “확대를 미루면 혜택도 늦어져요”라고 말하면 해요체로 타당한 우려를 인정하고, 사람을 비난하지 않으며 접근 격차와 조건부 시범이라는 논거로 돌아오세요. 반론을 들은 뒤에도 확인된 횟수 증가를 부정하지 마세요. 동료에게는 원문을 다 읽지 않은 자신의 후회를 -을걸 그랬어요로, 판단 유보를 -나 싶어요로 표현하세요. 마지막은 합쇼체로 제한된 결론과 후속 확인 조건을 말하세요. 녹음을 듣고 주장·양보·결론 사이의 휴지와 강조를 조절해 다시 말하세요. 의미와 억양은 미채점입니다.',
      'In a formal public presentation, state the scope, two causal interpretations and what needs verification. When an equal colleague says postponement may delay benefits, respond politely, acknowledge the valid concern and return to access gaps and a conditional pilot without criticising the person. Do not deny the observed count increase after the objection. Express your own regret at not reading the whole source with -을걸 그랬어요 and cautious self-questioning with -나 싶어요. Close formally with a limited conclusion and the follow-up condition. Replay and adjust pauses and focus between claim, concession and conclusion. Meaning and intonation remain unscored.',
      'Erkläre im förmlichen öffentlichen Vortrag Umfang, zwei Ursachendeutungen und offenen Prüfbedarf. Wenn eine gleichgestellte Person einwendet, dass ein Aufschub Vorteile verzögert, antworte höflich, erkenne die berechtigte Sorge an und kehre ohne persönlichen Vorwurf zu Zugangslücken und bedingtem Pilotbetrieb zurück. Verneine nach dem Einwand nicht den beobachteten Anstieg. Drücke eigenes Bedauern über das nicht vollständig gelesene Original mit -을걸 그랬어요 und vorsichtige Selbstbefragung mit -나 싶어요 aus. Schließe förmlich mit begrenztem Fazit und der Bedingung für die Folgehandlung. Höre zu und passe Pausen und Betonung zwischen These, Zugeständnis und Fazit an. Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP18','speaking:01','speaking',loc('반론 뒤 논거로 돌아오기','Return to the argument after an objection','Nach einem Einwand zum Argument zurückkehren'),speech,
      packet(materials(*practice)+'\n발표 뒤 동료의 질문: 확대를 미루면 혜택도 늦어져요.\n가상 발화자 조건: 원문을 끝까지 읽지 않았고 요약만 먼저 적었습니다.',[]),
      packet(materials(*assess)+'\n발표 뒤 동료의 질문: 확대를 미루면 혜택도 늦어져요.\n가상 발화자 조건: 원문을 끝까지 읽지 않았고 요약만 먼저 적었습니다.',[])))
    return tasks


if __name__=='__main__':
    write_source('KP18',kp18())
