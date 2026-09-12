"""KP30 marked historical-role registers and modern meaning-preserving transfer."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp30():
    rows=[
      ('G6:-거들랑1',loc('친밀한 말에서 조건을 붙여 부탁해요. 조건이 이미 성립했다고 단정하지 않아요.','Attach a condition to a familiar request without assuming it is fulfilled.','Verbinde eine vertraute Bitte mit einer Bedingung, ohne deren Erfüllung vorauszusetzen.'),('[반말 합의 친구] 소식을 듣거들랑 나에게도 알려 줘.','소식을 들을 경우 알림 부탁','이미 소식을 들었다는 확정'),('[반말 합의 친구] 시간이 나거들랑 같이 확인하자.','시간이 날 경우 공동 확인 제안','반드시 지금 확인하라는 명령')),
      ('G6:-거들랑2',loc('상대가 모르던 배경을 친밀하게 보태는 종결 용례예요. 조건 연결과 구별합니다.','Add background the listener may not know in a familiar sentence-final use, distinct from a conditional connective.','Ergänze vertraulich möglicherweise unbekannten Hintergrund am Satzende, anders als bei der Bedingungsverknüpfung.'),('[반말 합의 친구] 나도 그 사정은 잘 알거들랑. 어제 직접 들었어.','화자의 앎을 배경으로 제시','앞으로 알게 되면이라는 조건'),('[반말 합의 친구] 나도 그 기록을 읽었거들랑. 그래서 질문하는 거야.','이미 읽은 경험을 배경으로 제시','아직 읽지 않았다고 진술')),
      ('G6:-네1',loc('이 역할극의 하게체 평서형입니다. 관계·주변 말과 함께 읽으며 새 정보 감탄 네와 표기만으로 합치지 않아요.','A hage declarative in this role-play. Read its relationship and surrounding speech, not merely the spelling shared with exclamatory 네.','Ein Hage-Aussagesatz im Rollenspiel. Beachte Beziehung und Umgebung statt nur die gleiche Schreibung wie beim Ausruf 네.'),('[극중 선임 기록관→견습 기록관, 하게체 관계 설정] 나는 그 설명을 이해하겠네.','극중 하게체 이해 진술','처음 본 비를 감탄하는 해요체'),('[같은 극중 관계] 그 자료는 내가 보관하겠네.','극중 화자의 보관 의지 진술','견습에게 보관 의무 전가')),
      ('G6:-나2',loc('설정된 하게체 관계에서 정보나 생각을 묻습니다. 나이가 많다는 이유만으로 누구에게나 쓰지 않아요.','Ask for information or views within the specified hage relationship, not automatically on grounds of age.','Frage innerhalb der festgelegten Hage-Beziehung nach Information oder Meinung, nicht automatisch aufgrund des Alters.'),('[극중 선임→견습] 자네는 어떻게 생각하나?','상대 생각을 묻는 하게체 질문','상대 동의를 이미 확정'),('[극중 선임→견습] 자네는 이 자료를 읽었나?','상대 독서 여부 질문','읽었다는 사실 보고')),
      ('G6:-게3',loc('극중 하게체 명령입니다. 읽기 지시를 승인·복제 권한으로 넓히지 않으며 현대 동료에게는 상황에 맞게 다시 표현해요.','A hage instruction in the play. Do not extend reading into approval or copying authority; recast for a contemporary peer.','Eine Hage-Anweisung im Stück. Erweitere Lesen nicht zu Genehmigungs- oder Kopierbefugnis und formuliere für heutige Kollegen um.'),('[극중 선임→견습] 이 자료부터 읽어 보게. 승인 여부는 별도일세.','읽기 지시, 승인 별도','읽으면 승인까지 완료'),('[극중 선임→견습] 이 항목부터 확인하게. 담당 결정은 아직 없네.','항목 확인 지시, 담당 미결','확인 지시로 담당 확정')),
      ('G6:-게4',loc('이것 보게처럼 먼저 상대의 주의를 끄는 말입니다. 별도 과제 명령의 내용과 주의 환기를 나누어요.','In 이것 보게, first attract attention; separate the attention call from the content of a task instruction.','Lenke mit 이것 보게 zuerst Aufmerksamkeit und trenne dies vom Inhalt einer Arbeitsanweisung.'),('[극중 선임→견습] 이것 보게, 순서가 바뀌었네.','순서 변화로 주의를 환기','순서를 반드시 바꾸라는 명령'),('[극중 선임→견습] 여보게, 이름이 빠졌네.','빠진 이름으로 주의를 환기','지금 이름을 삭제하라는 명령')),
      ('G6:-는구만',loc('알게 된 사실에 감탄하는 표시적 구어예요. 말끝만으로 화자의 세대·성별·직위를 정하지 않습니다.','A marked spoken exclamation on noticing something. The ending alone identifies no generation, gender or role.','Ein markierter mündlicher Ausruf beim Bemerken. Das Satzende bestimmt weder Generation noch Geschlecht oder Rolle.'),('[극중 말투] 생각보다 일이 복잡하구만.','복잡함을 알아차린 감탄','화자의 나이와 직위를 확정'),('[극중 말투] 이제 내용을 이해하는구만.','이해를 알아차린 감탄','반드시 이해하라는 새 명령')),
      ('G6:-는구먼',loc('감탄과 상대 대우는 주변 문맥으로 함께 읽어요. -구만과 모든 상황의 서열을 고정하지 않습니다.','Read exclamation and address style in context, without fixing a universal hierarchy with 구만.','Lies Ausruf und Anrede im Kontext, ohne eine allgemeine Rangfolge gegenüber 구만 festzulegen.'),('이제야 서로 뜻이 통하는구먼. 서로의 뜻을 이해했다는 말이다.','뜻이 통한 데 대한 감탄','모든 실행안에 동의 완료'),('생각보다 기록이 많구먼. 전부 읽은 것은 아니다.','많은 기록을 알아차린 감탄','모든 기록 검토 완료')),
      ('G6:-소',loc('이 극중 하오체의 진술입니다. 동의 부정의 극성을 유지하고 말투를 새 권위로 읽지 않아요.','A hao statement in this play. Preserve negated agreement and do not infer new authority from style.','Eine Hao-Aussage im Stück. Erhalte verneinte Zustimmung und leite keine neue Befugnis aus dem Stil ab.'),('[극중 동등한 기록관 둘, 하오체 설정] 나는 그 의견에 동의하지 않소.','화자의 의견 불동의','상대 의견 승인'),('[같은 극중 관계] 나는 그 자료를 아직 읽지 않았소.','화자의 미독 상태','자료 검토 완료')),
      ('G6:-으오',loc('읽으오처럼 받침 뒤의 하오체 형태를 확인합니다. 여기서는 극중 읽기 지시이며 현대 일상의 기본 말투로 권하지 않아요.','Recognise the hao form after a consonant, as in 읽으오. This is a reading instruction in the play, not a recommended everyday default.','Erkenne die Hao-Form nach Konsonant wie 읽으오. Hier ist sie eine Leseanweisung im Stück, kein empfohlener Alltagsstandard.'),('[극중 하오체] 이 책을 먼저 읽으오. 복제하라는 말은 아니오.','책 읽기 지시, 복제 아님','복제 권한 부여'),('[극중 하오체] 이 쪽지를 먼저 받으오. 동의를 뜻하지는 않소.','쪽지 받기 지시, 동의 별개','쪽지를 받으면 동의 확정')),
      ('G6:-구려2',loc('극중 상대에게 행동을 권하거나 시키는 용례예요. 감탄 -는구려와 화행을 구별합니다.','This dramatic use requests or directs an action. Distinguish its speech act from exclamatory 는구려.','Diese Bühnenverwendung bittet um oder veranlasst eine Handlung. Unterscheide den Sprechakt vom Ausruf 는구려.'),('[극중 하오체] 날이 추우니 어서 들어오구려.','안으로 들어오라는 권유','이미 들어왔음을 알아차린 감탄'),('[극중 하오체] 잠시 쉬어 가구려. 서두를 필요는 없소.','쉬어 가라는 권유','이미 쉼이 끝났다는 보고')),
      ('G6:-는구려',loc('극중 새롭게 알게 된 데 대한 감탄입니다. 듣는 사람에게 새 행동을 명령하지 않아요.','An exclamation of noticing in the play, not a new command to the listener.','Ein Ausruf des Erkennens im Stück, kein neuer Befehl an das Gegenüber.'),('[극중 하오체] 이제야 까닭을 알겠구려.','까닭을 알게 된 감탄','상대에게 알아내라고 명령'),('[극중 하오체] 생각보다 이야기가 길어지는구려.','길어짐을 알아차린 감탄','반드시 말을 더 길게 하라는 지시')),
      ('G6:-그려',loc('하게체 말끝에 덧붙여 태도를 부드럽게 하는 이 용례를 읽어요. 부드러움이 합의·허가의 내용을 새로 만들지는 않습니다.','Here an addition to a hage ending softens stance without adding agreement or permission.','Hier mildert eine Ergänzung zum Hage-Satzende die Haltung, ohne Zustimmung oder Erlaubnis hinzuzufügen.'),('[극중 하게체] 오늘은 이야기가 길어졌네그려.','길어진 이야기의 부드러운 언급','새 시행안의 승인'),('[극중 하게체] 자네 뜻은 알겠네그려. 동의 여부는 아직 말하지 않았네.','뜻 이해, 동의 미표명','상대 안에 전면 동의')),
      ('G2:-네',loc('현대 해요체에서 새 정보를 알아차리는 감탄입니다. 하게체 평서형과 관계·요의 결합·문맥을 함께 비교해요.','Notice new information in modern polite speech, comparing context, 요 and relationship with a hage statement.','Bemerke neue Information im heutigen höflichen Stil und vergleiche Kontext, 요 und Beziehung mit Hage-Aussagen.'),('밖에 비가 오네요. 창문을 보고 처음 알았어요.','새롭게 안 비 소식의 감탄','극중 견습에게 내리는 명령'),('문이 열려 있네요. 지금 보고 알았어요.','열린 상태를 새롭게 알아차림','문을 연 행위자를 확인')),
      ('G5:-네2',loc('감탄에 평가가 더해져요. 구체 문맥 없이 감정이나 관계를 확정하지 않습니다.','Evaluation accompanies an exclamation; do not establish emotion or relationship without context.','Wertung begleitet den Ausruf; bestimme Gefühl oder Beziehung nicht ohne Kontext.'),('[반말 합의 친구] 이렇게 조용할 수가 없네! 집중하기 좋겠어.','고요함에 대한 긍정 평가','말끝만으로 냉소 확정'),('[반말 합의 친구] 생각보다 꼼꼼하네! 덕분에 찾기 편해.','꼼꼼함과 유용성의 긍정 평가','상대의 모든 행동에 전면 동의')),
      ('G1:-으시-',loc('청자와 반말·해요체로 말하더라도 제삼자 높임을 따로 유지합니다. 높임과 출처·확신도 별개예요.','Maintain third-person subject honorification independently of casual or polite address. Honorification is also separate from source and certainty.','Erhalte die Subjekthonorifikation für Dritte unabhängig von vertrauter oder höflicher Anrede. Auch Quelle und Gewissheit bleiben davon getrennt.'),('[반말 합의 친구] 선생님이 오셨어. 내가 직접 뵈었어.','친구에게 반말, 선생님 높임과 직접 경험','친구에게 반말이므로 선생님 높임도 없음'),('[새 동료에게] 선생님이 기다리신다고 들었어요. 직접 확인한 것은 아니에요.','해요체와 제삼자 높임, 전언 유지','직접 기다림을 확인한 사실')),
    ]
    tasks=[grammar_task('KP30',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G6:-거들랑1',('반말 합의 친구 / 소식 듣게 되면 내게도 알림 부탁 / 듣거들랑','소식을 듣거들랑 나에게도 알려 줘.','이미 소식을 들었으니 지금 보고해.'),('반말 합의 친구 / 시간 나면 같이 확인 제안 / 나거들랑','시간이 나거들랑 같이 확인하자.','반드시 지금 확인해.')),
      ('G6:-거들랑2',('반말 합의 친구 / 나도 그 사정 잘 앎 배경 / 알거들랑','나도 그 사정은 잘 알거들랑.','앞으로 그 사정을 알게 되면 말할게.'),('반말 합의 친구 / 나도 그 기록 읽은 경험 배경 / 읽었거들랑','나도 그 기록을 읽었거들랑.','그 기록을 아직 읽지 않았어.')),
      ('G6:-네1',('극중 선임→견습 대사 재현만 / 나 그 설명 이해 / 이해하겠네','나는 그 설명을 이해하겠네.','상대는 그 설명에 반드시 동의해야 한다.'),('극중 선임→견습 대사 재현만 / 그 자료 내가 보관 의지 / 보관하겠네','그 자료는 내가 보관하겠네.','그 자료는 자네가 반드시 보관해야 하네.')),
      ('G6:-나2',('극중 선임→견습 대사만 / 자네 생각 묻기 / 생각하나','자네는 어떻게 생각하나?','자네는 이미 동의했네.'),('극중 선임→견습 대사만 / 자네 이 자료 읽었는지 / 읽었나','자네는 이 자료를 읽었나?','자네는 이 자료를 읽었네.')),
      ('G6:-게3',('극중 선임→견습 대사만 / 이 자료 먼저 읽기 지시 / 읽어 보게','이 자료부터 읽어 보게.','이 자료의 사용을 승인하네.'),('극중 선임→견습 대사만 / 이 항목 먼저 확인 지시 / 확인하게','이 항목부터 확인하게.','자네를 최종 담당자로 정하네.')),
      ('G6:-게4',('극중 선임→견습 주의 환기 / 이것 보게 / 순서 바뀜','이것 보게, 순서가 바뀌었네.','이 순서를 지금 바꾸게.'),('극중 선임→견습 주의 환기 / 여보게 / 이름 빠짐','여보게, 이름이 빠졌네.','그 이름을 지금 삭제하게.')),
      ('G6:-는구만',('극중 표시적 감탄 대사만 / 생각보다 일 복잡 / 복잡하구만','생각보다 일이 복잡하구만.','이 일이 앞으로 반드시 복잡해져야 하네.'),('극중 표시적 감탄 대사만 / 이제 내용 이해 / 이해하는구만','이제 내용을 이해하는구만.','지금 반드시 내용을 이해하게.')),
      ('G6:-는구먼',('극중 감탄 대사만 / 이제 서로 뜻 통함 / 통하는구먼','이제야 서로 뜻이 통하는구먼.','모든 실행안에 동의가 끝났네.'),('극중 감탄 대사만 / 생각보다 기록 많음 / 많구먼','생각보다 기록이 많구먼.','모든 기록 검토를 끝냈네.')),
      ('G6:-소',('극중 동등한 기록관 둘 하오체 대사만 / 나 그 의견 동의 안 함 / 않소','나는 그 의견에 동의하지 않소.','나는 그 의견에 동의하오.'),('극중 동등한 기록관 둘 하오체 대사만 / 나 그 자료 아직 안 읽음 / 않았소','나는 그 자료를 아직 읽지 않았소.','나는 그 자료를 모두 읽었소.')),
      ('G6:-으오',('극중 하오체 읽기 지시 대사만 / 이 책 먼저 읽다 / 읽으오','이 책을 먼저 읽으오.','이 책을 복제해도 좋소.'),('극중 하오체 받기 지시 대사만 / 이 쪽지 먼저 받다 / 받으오','이 쪽지를 먼저 받으오.','이 쪽지를 받았으니 동의가 확정되었소.')),
      ('G6:-구려2',('극중 하오체 권유 대사만 / 날 추움 / 어서 들어오다 / 들어오구려','날이 추우니 어서 들어오구려.','이미 안으로 들어왔구려.'),('극중 하오체 권유 대사만 / 잠시 쉬어 가다 / 가구려','잠시 쉬어 가구려.','이미 쉼이 끝났구려.')),
      ('G6:-는구려',('극중 하오체 감탄 대사만 / 이제 까닭 알게 됨 / 알겠구려','이제야 까닭을 알겠구려.','지금 그 까닭을 알아내시오.'),('극중 하오체 감탄 대사만 / 생각보다 이야기 길어짐 / 길어지는구려','생각보다 이야기가 길어지는구려.','이야기를 더 길게 하시오.')),
      ('G6:-그려',('극중 하게체 부드러운 언급 대사만 / 오늘 이야기 길어짐 / 길어졌네그려','오늘은 이야기가 길어졌네그려.','새 시행안을 승인하네.'),('극중 하게체 부드러운 언급 대사만 / 자네 뜻 이해 / 알겠네그려','자네 뜻은 알겠네그려.','자네 안에 전면 동의하네.')),
      ('G2:-네',('현대 해요체 새로 본 비 감탄 / 밖에 비 오다 / 오네요','밖에 비가 오네요.','비가 오도록 하세요.'),('현대 해요체 열린 문 새로 봄 감탄 / 문 열려 있다 / 있네요','문이 열려 있네요.','제가 문을 열었어요.')),
      ('G5:-네2',('반말 합의 친구에게 고요함 평가 / 이렇게 조용할 수가 없다 / 없네','이렇게 조용할 수가 없네!','여기는 전혀 조용하지 않네.'),('반말 합의 친구에게 꼼꼼함 긍정 평가 / 생각보다 꼼꼼하다 / 하네','생각보다 꼼꼼하네!','생각보다 전혀 꼼꼼하지 않네.')),
      ('G1:-으시-',('반말 합의 친구에게 제삼자 선생님 높임 / 오셨음 / 내가 직접 뵘','선생님이 오셨어. 내가 직접 뵈었어.','선생님이 오신다고 들었지만 직접 보지는 못했어.'),('새 동료 해요체 / 선생님 기다린다는 전언 높임 / 직접 확인 아님','선생님이 기다리신다고 들었어요. 직접 확인한 것은 아니에요.','선생님이 기다리시는 것을 직접 확인했어요.')),
    ]
    tasks+=production('KP30',tasks,prod)
    h=loc('관계·채널·화행과 출처를 함께 보세요. 하게체·하오체는 설정된 역할에서 인식하고 현대 말투로 옮깁니다. 나이·성별로 말투를 정하지 않으며 부드러운 말이 허가를 만들지 않아요.','Read relationship, channel, speech act and source together. Recognise hage/hao in assigned roles and recast them in modern style. Neither age nor gender determines style; softness creates no permission.','Prüfe Beziehung, Kanal, Sprechakt und Quelle gemeinsam. Erkenne Hage/Hao in festgelegten Rollen und formuliere modern um. Alter oder Geschlecht bestimmen den Stil nicht; Freundlichkeit schafft keine Erlaubnis.')
    p=('가람문헌관',6,'수요일','교실')
    a=('솔빛기록관',9,'금요일','회의실')
    def scenes(args):
        name,count,day,room=args
        return f'''[가상 시대극: {name}. 실제 시대나 모든 세대의 말투를 재현한 자료가 아니다.]
장면 하나. 선임 기록관과 견습 기록관은 극의 관계 설정에 따라 하게체를 사용한다.
선임: 자네는 이 자료를 읽었나?
견습: 아직 읽지 않았습니다. 먼저 볼 수 있겠습니까?
선임: 이 자료부터 읽어 보게. 원본은 이 방에서만 볼 수 있고 복제는 안 되네. 이것 보게, 순서가 바뀌었네. 자네는 어떻게 생각하나?
견습: 바뀐 까닭은 아직 모르겠습니다.
선임: 자네 뜻은 알겠네그려. 이해한다는 말이지 복제를 허가한다는 말은 아니네.
장면 둘. 동등한 기록관 두 사람은 다른 극중 관계 설정에서 하오체를 쓴다.
기록관 하나: 이 책을 먼저 읽으오. 복제 권한을 준 것은 아니오.
기록관 둘: 나는 복제 허용 의견에 동의하지 않소. 이제야 까닭을 알겠구려.
기록관 하나: 날이 추우니 어서 들어오구려. 먼저 읽고 다시 이야기합시다.
장면 셋. 세대가 다른 동등한 현대 동료 둘은 서로 해요체로 말하기로 했다. 나이만으로 하게체를 쓰는 장면이 아니다.
동료 하나: 선생님이 {day}에 오신다고 들었어요. 제가 직접 확인한 것은 아니에요. 자료 {count}개는 {room}에서 볼 수 있어요. 복제는 허용되지 않아요.
동료 둘: 문이 열려 있네요. 지금 보고 알았어요. 선생님 참석은 확인할 항목으로 남겨 둘게요.
장면 넷. 반말에 합의한 가까운 성인 친구 둘.
친구 하나: 소식을 듣거들랑 나에게도 알려 줘. 나도 그 사정은 잘 알거들랑. 어제 설명을 들었어.
친구 둘: 생각보다 일이 복잡하구만. 일부러 고른 말투이지 내 나이나 성별을 표시하려는 게 아니야. 이제야 서로 뜻이 통하는구먼.
친구 하나: 그렇다고 복제 허용에 동의한 건 아니야. 선생님은 그날 오신대. 전해 들은 말이야.
장면 다섯. 같은 내용의 공개 안내.
발표자: 자료 {count}개는 지정된 {room}에서 열람할 수 있습니다. 복제는 허용되지 않습니다. 선생님의 {day} 참석은 전해 들은 정보이며 확인이 필요합니다. 모르는 질문은 추가 확인 사항으로 남기겠습니다.'''
    def listen(args):
        return packet(scenes(args),[
          choice('relationship',loc('하게체 판단의 근거는?','What supports identifying hage?','Was stützt die Einordnung als Hage?'),['극의 관계 설정과 나·네·게의 실제 발화','나이가 많으면 누구에게나 자동 사용'],h),
          choice('acts',loc('읽으오·들어오구려·알겠구려의 차이는?','How do reading, entering and noticing differ?','Wie unterscheiden sich Lesen, Hereinbitten und Erkennen?'),['읽기 지시·입장 권유·알게 된 감탄','셋 다 복제 승인'],h),
          choice('proposition',loc('장면들에서 유지되는 범위는?','Which scope remains across scenes?','Welcher Umfang bleibt über die Szenen erhalten?'),['지정 공간 열람 가능, 복제 불가','공손한 문체이면 복제 허용'],h),
          choice('honorific',loc('친구에게 선생님 소식을 전할 때는?','How is teacher information conveyed to a friend?','Wie wird Freunden die Lehrpersoneninformation vermittelt?'),['반말 안에서도 제삼자 높임과 전언 유지','반말이므로 높임과 전언 모두 삭제'],h),
          choice('modern',loc('세대가 다른 현대 동료의 말투 근거는?','What determines the modern colleagues’ style?','Worauf beruht der Stil heutiger Kollegen verschiedener Generationen?'),['서로 해요체로 말하기로 한 관계','연령만으로 한쪽 하게체 의무'],h),
          choice('condition',loc('두 거들랑 용례의 차이는?','How do the two 거들랑 uses differ?','Wie unterscheiden sich die beiden 거들랑-Verwendungen?'),['소식 들을 경우의 조건 / 이미 아는 배경','둘 다 이미 소식을 들었다는 확정'],h),
          choice('unknown',loc('공개 안내에서 미확인 정보는?','What remains unconfirmed in the notice?','Was bleibt in der Ansage unbestätigt?'),['선생님의 실제 참석','제시된 자료 수와 열람 장소'],h),
        ],'audio')
    tasks.append(task('KP30','listening:01','listening',loc('시대극·세대 간 대화·공개 안내','Period drama, intergenerational dialogue and public notice','Historisches Spiel, Generationengespräch und öffentliche Ansage'),h,listen(p),listen(a)))
    def lecture(args):
        return f'''[가상 문체 강연: {args[0]} 자료의 현대적 재구성]
같은 명제를 다른 말투로 옮기려면 관계·채널·화행을 먼저 확인합니다. 선임과 견습의 극중 설정에서 읽어 보게는 지시이고 이것 보게는 주의 환기입니다. 같은 게를 보았다고 하나의 업무 명령으로 합치면 안 됩니다. 하게체 평서 네와 현대 해요체 오네요의 새 정보 감탄도 주변 맥락과 요의 결합을 함께 봅니다.
이제 하오체입니다. 읽으오는 읽기 지시, 들어오구려는 입장 권유, 알겠구려는 알게 된 감탄으로 제시했습니다. 실제 문장과 관계가 분류의 근거입니다. 낡게 들리는 말투가 새 권위를 만들거나 특정 연령·성별만 낼 수 있는 목소리를 뜻하지 않습니다.
다음은 명제 보존입니다. 원본을 지정 공간에서 볼 수 있다는 허용과 복제 불가라는 제한을 함께 유지합니다. 계약의 조항, 문학 인물의 발언, 공개 안내는 같은 내용을 담아도 근거의 종류가 다릅니다. 문학 대사는 실제 이용 권한을 발급하는 문서가 아닙니다. 격식을 갖추는 것과 승인 권한을 갖는 것은 별개입니다.
마지막으로 주체 높임과 상대 높임을 나누겠습니다. 선생님이 오신대라고 친구에게 말해도 제삼자 높임이 남습니다. 전언을 직접 확인으로 바꾸면 안 됩니다. {args[2]} 참석은 아직 확인 사항입니다. 뜻이 통한다는 감탄이나 뜻을 알겠다는 말도 복제 허용의 동의와 별개입니다. 말을 가려 하고 뜻을 헤아리는 일은 빠진 사실을 꾸미는 일이 아닙니다. 가교 역할을 하려면 근거와 한계를 함께 전해야 합니다.'''
    def lecture_packet(args):
        return packet(lecture(args),[
          choice('structure',loc('강연의 전개는?','How does the lecture develop?','Wie entwickelt sich der Vortrag?'),['관계·화행 → 하오체 대비 → 명제·장르 → 높임·출처','낡은 말끝 → 자동 승인 권한'],h),
          choice('attention',loc('읽어 보게와 이것 보게의 차이는?','How do the two 게 expressions differ?','Wie unterscheiden sich die beiden 게-Ausdrücke?'),['읽기 지시 / 주의 환기','둘 다 새 복제 허가'],h),
          choice('genre',loc('같은 명제가 있어도 다른 것은?','What differs despite the same proposition?','Was unterscheidet sich trotz gleicher Aussage?'),['계약 문언·극중 발언·안내의 근거 종류','문학 대사도 실제 권한 발급'],h),
          choice('agreement',loc('뜻을 알겠다는 말의 범위는?','What does understanding the point cover?','Was umfasst das Verstehen des Gedankens?'),['내용 이해, 복제 허용 동의 아님','이해하면 모든 조건에 동의'],h),
        ],'audio')
    tasks.append(task('KP30','listening:02','listening',loc('말투·권한·출처를 구별하는 강연','Lecture separating style, authority and source','Vortrag über Stil, Befugnis und Quelle'),h,lecture_packet(p),lecture_packet(a)))
    def literary(args):
        return scenes(args)+'''\n[창작 단편: 문 앞에서]
견습 기록관은 읽어 보게라는 말을 듣고 책을 폈다. 이것 보게라는 두 번째 말에는 고개를 들었다. 첫 말은 읽기 지시였고 두 번째는 순서 변화로 향하는 주의 환기였다. 선임이 자네 뜻은 알겠네그려라고 덧붙이자 견습은 거리가 조금 줄었다고 느꼈다. 그 느낌이 실제 복제 허가를 뜻하지는 않았다.
옆방의 두 기록관은 서로 하오체를 썼다. 한 사람은 동의하지 않소라고 말한 뒤에도 상대에게 자리를 권했다. 불동의와 환대는 함께 있을 수 있었다. 서술자는 그들이 언제나 갈등한다고 쓰지 않았고, 정확한 시대와 나이도 제시하지 않았다.
현대의 독자는 원본을 볼 수 있다는 문장을 편하게 고쳐 읽었다. 그러나 복제 불가라는 단서를 지우려다 멈췄다. 문어의 열람할 수 있다라는 문장은 특정 청자에게 반말을 건네는 장면과 다르다는 것을 알아차렸다. 명제 보존과 관계 변화는 따로 설명해야 했다.
[비평 메모]
장점은 불동의와 환대, 이해와 허가를 한 장면 안에서 분리한 데 있다. 한계는 내면 반응이 견습의 느낌으로만 주어져 상대의 거리감은 알 수 없다는 것이다. 문체 효과의 평가 기준을 구체 발화에 두면 호칭 체계와 화용적 함축을 설명하면서도 관계 전체를 단정하지 않을 수 있다.'''
    def literary_packet(args):
        return packet(literary(args),[
          choice('distance',loc('거리가 줄었다는 느낌의 주체는?','Whose feeling is the reduced distance?','Wer empfindet die verringerte Distanz?'),['견습 기록관, 상대 느낌은 미상','두 사람의 같은 감정 검증'],h),
          choice('acts',loc('불동의 뒤 자리 권유는?','What does hospitality after disagreement show?','Was zeigt Gastlichkeit nach Widerspruch?'),['불동의와 환대의 공존','불동의 자동 취소'],h),
          choice('written',loc('문어 열람할 수 있다의 기능은?','What is the written statement’s function?','Welche Funktion hat die schriftliche Aussage?'),['문서의 범위 서술','특정 독자를 무조건 낮추는 반말'],h),
          choice('limit',loc('서술이 확정하지 않은 것은?','What does the narration leave open?','Was lässt die Erzählung offen?'),['정확한 시대·나이와 상대의 내면','책을 펴고 고개를 든 행동'],h),
        ])
    tasks.append(task('KP30','reading:01','reading',loc('문학 대화의 거리와 화행','Distance and speech acts in literary dialogue','Distanz und Sprechakte im literarischen Dialog'),h,literary_packet(p),literary_packet(a)))
    def documents(args):
        name,count,day,room=args
        return f'''[가상 {name} 학습용 열람 약정. 실제 법적 효력을 판단하는 과제가 아니다.]
제1조 적용 대상. 열람 승인을 받은 이용자는 자료 {count}개를 지정된 {room}에서 볼 수 있다. 열람은 현장에서 보는 행위이며 복제와 반출을 포함하지 않는다.
제2조 의무와 예외. 이용자는 원본을 반출하거나 복제하지 않는다. 자료원이 별도의 복제 허가 문서를 발급한 경우에만 그 문서에 적힌 자료와 방식의 복제를 허용한다. 이 과제에는 발급된 허가 문서가 없다. 구두로 뜻을 이해한다고 말한 것은 그 문서를 대신하지 않는다.
제3조 확인 사항. 자료 상태 확인은 안내 담당자가 맡는다. 최종 열람 승인 절차와 복제 허가 발급 책임자는 발췌문에 없다. 선생님의 {day} 참석은 전언이며 계약상 의무나 일정 보증에 포함하지 않는다.
[현대 안내문]
열람 승인을 받으신 분은 자료 {count}개를 {room}에서 보실 수 있어요. 복제와 반출은 허용되지 않아요. 별도 복제 허가 문서가 있다면 그 문서의 범위를 확인해야 해요. 지금 제시된 허가 문서는 없어요. 자료 상태는 안내 담당자에게 확인하실 수 있어요.
[공개 발표 원고]
승인된 이용자의 현장 열람과 복제·반출 제한을 안내합니다. 별도 허가의 예외는 문서의 대상과 방식 안에서만 적용됩니다. 선생님 참석은 확인되지 않은 전언입니다. 미상 승인 책임자는 추가 확인하겠습니다.
[전문 비교 메모]
약정 조항은 이 학습 자료 안의 권리·의무·조건을 정의한다. 문학 인물의 읽으오는 인물 간 지시다. 공개 발표는 제시된 약정을 옮긴다. 같은 명제가 있어도 근거와 발언 책임은 같아지지 않는다. 친절한 호칭이나 격식 있는 말끝이 예외 문서를 대신하지 않는다.
[잘못된 문체 전환]
뜻을 알겠네그려라는 말이 있었으므로 누구나 모든 자료를 복제할 수 있다. 선생님은 반드시 참석하시며 안내 담당자가 모든 승인을 맡는다.
[수정 기준]
이해를 허가로, 한정 열람을 무제한 복제로, 전언을 참석 보증으로, 상태 확인을 승인 책임으로 바꾼 오류를 각각 원문으로 고친다.'''
    def terms_packet(args):
        return packet(documents(args),[
          choice('scope',loc('열람의 대상과 장소는?','Who may inspect, and where?','Wer darf wo Einsicht nehmen?'),[f'승인 이용자, {args[1]}개, 지정 {args[3]}','누구나 모든 자료 어디서나 복제'],h),
          choice('exception',loc('복제 예외에 필요한 것은?','What does the copying exception require?','Was verlangt die Kopierausnahme?'),['별도 허가 문서와 대상·방식 범위','부드러운 이해 표현'],h),
          choice('current',loc('현재 제시된 허가 증거는?','What permission evidence is supplied?','Welcher Erlaubnisbeleg liegt vor?'),['발급된 복제 허가 문서는 없음','모든 자료 허가 발급 완료'],h),
          choice('responsibility',loc('안내 담당자의 명시된 책임은?','What is the guide’s stated responsibility?','Welche Zuständigkeit ist genannt?'),['자료 상태 확인, 최종 승인자는 미상','모든 열람·복제 승인'],h),
          choice('hearsay',loc('선생님 참석 소식의 상태는?','What is the status of teacher attendance?','Welchen Status hat die Teilnahme der Lehrperson?'),['미확인 전언, 계약상 보증 아님','높임을 썼으므로 참석 확정'],h),
          choice('genre',loc('세 장르에서 유지할 구분은?','What distinction remains across genres?','Welche Unterscheidung bleibt über Genres erhalten?'),['같은 명제와 서로 다른 근거·발언 책임','공손도만 바뀌면 권한도 동일'],h),
        ])
    tasks.append(task('KP30','reading:02','reading',loc('약정·안내·발표의 같은 명제','One proposition in terms, notices and briefings','Eine Aussage in Bedingungen, Hinweisen und Vortrag'),h,terms_packet(p),terms_packet(a)))
    rubric=loc('여섯 칸에 실제 글을 쓰세요. 평가 기준·장점·한계·구절을 갖춘 비평, 목적·근거·결론·실행 조건을 갖춘 보고서, 요점·근거·한계를 전하는 발표 원고를 각각 완성합니다. 수량·장소·권리·의무·예외·전언·미상 승인자를 보존하세요. 옛 말투를 현대 표현으로 바꾸면서 지시·질문·감탄·주의 환기와 이해·동의·허가를 나눕니다. 문어 하다체와 청자 반말은 다릅니다. KP25–KP30에서 자신이 쓴 글 하나를 골라 원문 칸에 붙이고 수정본을 씁니다. 마지막 칸에는 원문 구절→수정 구절→이유의 문체 전환표와 의미 감사표를 만드세요. 주체 높임·청자 대우·호칭은 따로 기록하고 극성·시간·출처·책임·선택권이 바뀐 곳을 고칩니다. 남은 모호성과 다른 읽기를 표시하세요. 이는 자기 감사이며 C2 전체 인증이 아닙니다. 자유 의미·문체 효과는 미채점입니다.',
      'Write actual texts in six fields: a complete critique with criteria, strengths, limits and passages; a report with purpose, evidence, conclusion and implementation conditions; and a presentation with points, grounds and limits. Preserve quantity, place, rights, duties, exceptions, hearsay and unknown approvers. Recast older style while separating instructions, questions, exclamations, attention calls and understanding, agreement and permission. Written plain prose is not casual address. Select your own KP25–KP30 text, paste the original and write a revision. In the final field make a source passage→revision→reason style-change and meaning-audit table. Track subject honorification, address and titles separately; repair changed polarity, time, source, responsibility or choice. Mark remaining ambiguity and alternative readings. This is self-audit, not whole-C2 certification; free meaning and stylistic effects remain unscored.',
      'Schreibe echte Texte in sechs Felder: eine vollständige Kritik mit Kriterien, Stärken, Grenzen und Belegen; einen Bericht mit Zweck, Begründung, Schluss und Ausführungsbedingungen; sowie einen Vortrag mit Punkten, Belegen und Grenzen. Erhalte Menge, Ort, Rechte, Pflichten, Ausnahmen, Hörensagen und unbekannte Genehmigende. Übertrage ältere Stile und trenne Anweisung, Frage, Ausruf, Aufmerksamkeit sowie Verstehen, Zustimmung und Erlaubnis. Schriftlicher Aussagestil ist keine vertrauliche Anrede. Wähle einen eigenen KP25–KP30-Text, füge das Original ein und überarbeite ihn. Erstelle zuletzt eine Tabelle Ausgangsstelle→Neufassung→Grund für Stilwechsel und Bedeutungsprüfung. Erfasse Subjekthonorifikation, Anrede und Titel getrennt und korrigiere veränderte Polarität, Zeit, Quelle, Verantwortung oder Wahlfreiheit. Markiere Mehrdeutigkeit und Alternativlesarten. Dies ist Selbstprüfung, keine Gesamt-C2-Zertifizierung; Inhalt und Stileffekte bleiben unbewertet.')
    def writing(args):
        return packet(literary(args)+'\n'+documents(args),[
          free_text('critique',loc('완결된 비평문','Complete critique','Vollständige Kritik'),rubric),
          free_text('report',loc('완결된 검토 보고서','Complete review report','Vollständiger Prüfbericht'),rubric),
          free_text('presentation',loc('공개 발표 원고','Public presentation script','Öffentliches Vortragsmanuskript'),rubric),
          free_text('original',loc('선택한 C2 글의 원문','Original of your selected C2 text','Original deines gewählten C2-Texts'),rubric),
          free_text('revision',loc('전체 수정본','Complete revision','Vollständige Überarbeitung'),rubric),
          free_text('audit',loc('문체·의미 감사표와 남은 해석','Style and meaning audit with open readings','Stil- und Bedeutungsprüfung mit offenen Lesarten'),rubric),
        ],'form')
    tasks.append(task('KP30','writing:01','writing',loc('비평·보고·발표와 C2 자기 감사','Critique, report, presentation and C2 self-audit','Kritik, Bericht, Vortrag und C2-Selbstprüfung'),rubric,writing(p),writing(a)))
    speech=loc('같은 내용을 반말 합의한 가까운 사람, 처음 만난 동료, 공개 청중에게 친밀체·해요체·합쇼체로 각각 전하고 선택 이유를 설명하세요. 선생님 높임과 전언은 따로 유지합니다. 옛 대사를 듣고 현대 해요체로 지시·주의 환기·권유·감탄을 나누어 재구성합니다. 하게체·하오체를 쓴다면 명시된 극중 역할 대사로만 한정하고 나이·성별 흉내를 기준으로 삼지 않아요. 이해와 허가를 혼동한 두 참여자를 중개해 열람 범위·복제 예외·미상 승인자를 설명합니다. 공개 발표는 요점·근거·한계 순으로 하고 모르는 질문은 확인 과제로 남기세요. 모어가 다른 동료에게 한국어로 높임을 참석 보증으로, 문체 권위를 승인 권한으로 바꾼 오류를 짚습니다. 녹음·재생 후 선택권과 화행이 달라진 휴지·종결을 고쳐 다시 말하세요. 발음과 의미·문체 숙달은 별개이며 자유 의미·억양은 미채점입니다.',
      'Convey identical content casually to an agreed close contact, politely to a new colleague and formally to an audience, explaining choices. Preserve teacher honorification and hearsay separately. Listen to older lines and recast instructions, attention calls, invitations and exclamations in modern polite style. Any hage/hao production is limited to assigned dramatic lines; age or gender imitation is no criterion. Mediate confusion between understanding and permission through inspection scope, copying exceptions and unknown approvers. Present points, grounds and limits and leave unknown questions for checking. In Korean explain to a colleague with another first language errors turning honorification into guaranteed attendance and stylistic authority into approval powers. Record, replay and revise pauses/endings that alter choice or speech act. Pronunciation is separate from meaning/register mastery; free meaning and prosody remain unscored.',
      'Vermittle identischen Inhalt vertraulich an eine Person mit vereinbartem informellem Register, höflich an neue Kollegen und förmlich an ein Publikum und begründe die Wahl. Erhalte Lehrpersonen-Honorifikation und Hörensagen getrennt. Höre ältere Zeilen und übertrage Anweisungen, Aufmerksamkeitsrufe, Einladungen und Ausrufe in modernen höflichen Stil. Eigene Hage/Hao-Formen bleiben auf zugewiesene Bühnenzeilen begrenzt; Alters- oder Geschlechtsimitation ist kein Kriterium. Vermittle bei Verwechslung von Verstehen und Erlaubnis anhand von Einsichtsumfang, Kopierausnahme und unbekannten Zuständigen. Präsentiere Kernpunkte, Belege und Grenzen und lasse unbekannte Fragen zur Klärung offen. Erkläre einer Person anderer Erstsprache auf Koreanisch Fehler, die Honorifikation zur Teilnahmegarantie und stilistische Autorität zur Genehmigungsbefugnis machen. Nimm auf, höre zu und korrigiere Pausen oder Endungen mit veränderter Wahlfreiheit oder Sprechhandlung. Aussprache ist von Bedeutung und Registerbeherrschung getrennt; freier Inhalt und Prosodie bleiben unbewertet.')
    tasks.append(task('KP30','speaking:01','speaking',loc('가까운 사람·새 동료·공개 청중 사이의 전환','Switch between close contact, new colleague and audience','Zwischen vertrauter Person, neuen Kollegen und Publikum wechseln'),speech,packet(scenes(p)+'\n'+documents(p),[]),packet(scenes(a)+'\n'+documents(a),[])))

    return tasks


if __name__=='__main__':
    write_source('KP30',kp30())
