"""권한 매트릭스: 실제 firestore.rules가 사용자마다 · 권한마다 어떻게 답하는지 측정해 JSON으로 남긴다.

테스트 교회(fs.CID)에서만 일한다. 시나리오마다 기본 직급 문서(positions/staff · member)와 몇몇 교인의 권한을 바꾸고,
끝나면 직급 문서를 지우고(기본값으로 복귀) 교인 권한을 비운다. 만든 글 · 일정은 지운 표시로 정리한다.
"""
import json
import os
import sys
import time
import urllib.parse
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone

import fs

CID = fs.CID
BASE = fs.BASE + 'churches/%s/' % CID
A = 'VIMoqM0rqVGtPXGXGyt7'  # plc1 · 3 · 4 · 5 · 7 · 9 · 10 · 14가 속한 소속
ALL_KEYS = ['member.manage', 'affiliation.edit', 'prayer.post', 'prayer.engage', 'prayer.private',
            'devotion.post', 'devotion.engage', 'devotion.private', 'meeting.manage',
            'meeting.participants', 'meeting.join']
SCOPED = ['prayer.post', 'prayer.engage', 'devotion.post', 'devotion.engage', 'meeting.manage',
          'meeting.participants']
USERS = [1, 2, 3, 5, 9, 10, 13, 14, 12, 15]
RUN = uuid.uuid4().hex[:6]


class T(str):
    pass


def enc(v):
    if isinstance(v, T):
        return {'timestampValue': str(v)}
    if v is None:
        return {'nullValue': None}
    if isinstance(v, bool):
        return {'booleanValue': v}
    if isinstance(v, int):
        return {'integerValue': str(v)}
    if isinstance(v, str):
        return {'stringValue': v}
    if isinstance(v, list):
        return {'arrayValue': {'values': [enc(i) for i in v]}}
    if isinstance(v, dict):
        return {'mapValue': {'fields': {k: enc(x) for k, x in v.items()}}}
    raise TypeError(v)


def now(days=0):
    t = datetime.now(timezone.utc) + timedelta(days=days)
    return T(t.strftime('%Y-%m-%dT%H:%M:%S.000Z'))


def ok(r):
    return isinstance(r, dict) and 'error' not in r


def create(tok, parent, data, doc_id=None):
    url = BASE + parent + ('?documentId=' + doc_id if doc_id else '')
    r = fs.call(url, {'fields': {k: enc(v) for k, v in data.items()}}, tok)
    return r


def patch(tok, path, data):
    mask = '&'.join('updateMask.fieldPaths=' + urllib.parse.quote(k) for k in data)
    url = BASE + path + '?' + mask
    return fs.call(url, {'fields': {k: enc(v) for k, v in data.items()}}, tok, 'PATCH')


def get(tok, path):
    return fs.call(BASE + path, token=tok)


def doc_id(r):
    return r['name'].split('/')[-1]


# ---------------------------------------------------------------------------
class Ctx:
    pass


def login_all():
    c = Ctx()
    c.uid, c.tok = {}, {}
    for n in range(1, 16):
        c.uid[n], c.tok[n] = fs.login(n)
    c.admin = c.tok[1]
    c.cleanup = []  # (kind, path)
    return c


def soft_delete_fields(uid):
    return {'deleted': True, 'deletedAt': now(), 'deletedBy': uid}


# ---- 고정 비공개 글 (읽기 확인용) ----
def make_fixed(c):
    a = c.admin
    uid = c.uid[1]
    r = create(a, 'prayers', {'authorId': uid, 'authorName': '권한테스트', 'content': '비공개 기도 ' + RUN,
                              'visibility': 'private', 'createdAt': now(), 'updatedAt': now(),
                              'deleted': False, 'affiliationId': A, 'views': 0})
    assert ok(r), r
    c.pp = doc_id(r)
    c.cleanup.append(('prayer', 'prayers/' + c.pp))
    r = create(a, 'devotions', dev_data(uid, 'private'))
    assert ok(r), r
    c.dp = doc_id(r)
    c.cleanup.append(('dev', 'devotions/' + c.dp))


def dev_data(uid, vis='public'):
    return {'title': '권한테스트 1:1', 'body': '본문', 'meditation': '묵상 열 글자 이상입니다 ' + RUN, 'extras': [],
            'date': now(), 'views': 0, 'likedBy': [], 'createdBy': uid, 'authorName': '권한테스트',
            'authorPhotoUrl': '', 'affiliationId': A, 'visibility': vis, 'createdAt': now()}


def prayer_fixture(c, public=True):
    r = create(c.admin, 'prayers', {'authorId': c.uid[1], 'authorName': '권한테스트', 'content': '공개 기도 ' + RUN,
                                    'visibility': 'public' if public else 'private', 'createdAt': now(),
                                    'updatedAt': now(), 'deleted': False, 'affiliationId': A, 'views': 0})
    assert ok(r), r
    pid = doc_id(r)
    c.cleanup.append(('prayer', 'prayers/' + pid))
    return pid


def meeting_data(uid):
    return {'title': '권한테스트', 'description': '', 'place': '테스트', 'date': now(30), 'capacity': 20,
            'imageUrl': '', 'leaderId': uid, 'leaderName': '권한테스트', 'participantIds': [], 'pendingIds': [],
            'fee': 0, 'needsApproval': False, 'likedBy': [], 'views': 0, 'deleted': False, 'createdAt': now(),
            'affiliationIds': [A]}


def meeting_fixture(c, joined=False):
    r = create(c.admin, 'meetings', meeting_data(c.uid[1]))
    assert ok(r), r
    mid = doc_id(r)
    c.cleanup.append(('meeting', 'meetings/' + mid))
    if joined:
        r = patch(c.admin, 'meetings/' + mid, {'participantIds': [c.uid[1]]})
        assert ok(r), r
    return mid


# ---------------------------------------------------------------------------
def probe_user(c, n):
    """한 사용자가 지금 설정에서 각 권한을 어떻게 받는지 측정한다."""
    tok, uid = c.tok[n], c.uid[n]
    res = {}

    def put(key, **kw):
        res.setdefault(key, {}).update(kw)

    # 중보기도: 글
    r = create(tok, 'prayers', {'authorId': uid, 'authorName': '권한테스트', 'content': '기도 ' + RUN,
                                'visibility': 'public', 'createdAt': now(), 'updatedAt': now(),
                                'deleted': False, 'affiliationId': A, 'views': 0})
    if ok(r):
        c.cleanup.append(('prayer', 'prayers/' + doc_id(r)))
    put('prayer.post', can=ok(r))
    pid = prayer_fixture(c)
    r = patch(tok, 'prayers/' + pid, dict(soft_delete_fields(uid), deleteReason='권한 테스트'))
    put('prayer.post', all=ok(r))
    # 중보기도: 반응 · 댓글
    pid = prayer_fixture(c)
    r = create(tok, 'prayers/%s/reactions' % pid,
               {'uid': uid, 'type': 'pray', 'active': True, 'createdAt': now()}, uid + '_pray')
    r2 = create(tok, 'prayers/%s/comments' % pid, {'authorId': uid, 'authorName': '권한테스트',
                                                  'content': '댓글', 'createdAt': now()})
    put('prayer.engage', can=ok(r), can_comment=ok(r2))
    cm = create(c.admin, 'prayers/%s/comments' % pid, {'authorId': c.uid[1], 'authorName': '권한테스트',
                                                        'content': '관리자 댓글', 'createdAt': now()})
    assert ok(cm), cm
    r = patch(tok, 'prayers/%s/comments/%s' % (pid, doc_id(cm)), soft_delete_fields(uid))
    put('prayer.engage', all=ok(r))
    r = get(tok, 'prayers/' + c.pp)
    put('prayer.private', all=ok(r))
    # 말씀묵상
    r = create(tok, 'devotions', dev_data(uid))
    if ok(r):
        c.cleanup.append(('dev', 'devotions/' + doc_id(r)))
    put('devotion.post', can=ok(r))
    r = create(c.admin, 'devotions', dev_data(c.uid[1]))
    assert ok(r), r
    did = doc_id(r)
    c.cleanup.append(('dev', 'devotions/' + did))
    r = patch(tok, 'devotions/' + did, soft_delete_fields(uid))
    put('devotion.post', all=ok(r))
    r = create(c.admin, 'devotions', dev_data(c.uid[1]))
    did = doc_id(r)
    c.cleanup.append(('dev', 'devotions/' + did))
    r = patch(tok, 'devotions/' + did, {'likedBy': [uid]})
    put('devotion.engage', can=ok(r))
    if ok(r):
        patch(tok, 'devotions/' + did, {'likedBy': []})
    r = get(tok, 'devotions/' + c.dp)
    put('devotion.private', all=ok(r))
    # 일정
    r = create(tok, 'meetings', meeting_data(uid))
    if ok(r):
        c.cleanup.append(('meeting', 'meetings/' + doc_id(r)))
    put('meeting.manage', can=ok(r))
    mid = meeting_fixture(c)
    r = patch(tok, 'meetings/' + mid, soft_delete_fields(uid))
    put('meeting.manage', all=ok(r))
    mid = meeting_fixture(c, joined=True)
    r = patch(tok, 'meetings/' + mid, {'participantIds': []})
    put('meeting.participants', all=ok(r))
    mid = meeting_fixture(c)
    r = patch(tok, 'meetings/' + mid, {'participantIds': [uid]})
    put('meeting.join', can=ok(r))
    if ok(r):
        patch(tok, 'meetings/' + mid, {'participantIds': []})
    # 인원 · 소속
    r = patch(tok, 'members/' + c.uid[13], {'affiliationIds': [A]})
    put('member.manage', can=ok(r))
    patch(c.admin, 'members/' + c.uid[13], {'affiliationIds': []})
    r = create(c.admin, 'affiliations', {'name': 'zz권한테스트' + RUN, 'createdBy': c.uid[1], 'createdAt': now()})
    assert ok(r), r
    aid = doc_id(r)
    c.cleanup.append(('aff', 'affiliations/' + aid))
    r = patch(tok, 'affiliations/' + aid, soft_delete_fields(uid))
    put('affiliation.edit', can=ok(r))
    # 권한과 무관하게 승인된 교인이 늘 할 수 있어야 하는 일 (읽음 · 조회수 · 좋아요 · 댓글)
    base = {}
    pid = prayer_fixture(c)
    base['prayer.views'] = ok(patch(tok, 'prayers/' + pid, {'views': 1}))
    base['prayer.readBy'] = ok(patch(tok, 'prayers/' + pid, {'readBy': [uid]}))
    r = create(c.admin, 'devotions', dev_data(c.uid[1]))
    did = doc_id(r)
    c.cleanup.append(('dev', 'devotions/' + did))
    base['devotion.views'] = ok(patch(tok, 'devotions/' + did, {'views': 1}))
    base['devotion.readBy'] = ok(patch(tok, 'devotions/' + did, {'readBy': [uid]}))
    mid = meeting_fixture(c)
    base['meeting.views'] = ok(patch(tok, 'meetings/' + mid, {'views': 1}))
    base['meeting.like'] = ok(patch(tok, 'meetings/' + mid, {'likedBy': [uid]}))
    base['meeting.comment'] = ok(create(tok, 'meetings/%s/comments' % mid, {
        'authorId': uid, 'authorName': '권한테스트', 'text': '댓글', 'createdAt': now()}))
    res['baseline'] = base
    return res


# ---------------------------------------------------------------------------
def set_positions(c, staff, member):
    """staff · member: None이면 문서를 지운다 (기본값), 아니면 {'permissions': [...], 'scopes': {...}}."""
    for pid, cfg in (('staff', staff), ('member', member)):
        path = 'positions/' + pid
        if cfg is None:
            fs.call(BASE + path, token=c.admin, method='DELETE')
            continue
        data = {'name': '교역자' if pid == 'staff' else '회원', 'permissions': cfg['permissions'],
                'scopes': {k: ['@mine'] for k in cfg.get('mine', [])}, 'builtIn': True, 'updatedAt': now()}
        r = fs.call(BASE + path, {'fields': {k: enc(v) for k, v in data.items()}}, c.admin, 'PATCH')
        assert ok(r), r


def set_member(c, n, permissions, mine):
    r = patch(c.admin, 'members/' + c.uid[n], {
        'positionId': None, 'permissions': permissions,
        'permissionScopes': {k: ['@mine'] for k in mine}})
    assert ok(r), r


def member_snapshot(c, n):
    d = get(c.admin, 'members/' + c.uid[n])
    f = fs.fields(d)
    return {'role': f.get('role'), 'status': f.get('status'), 'permissions': f.get('permissions') or [],
            'permissionScopes': f.get('permissionScopes') or {}}


def run_scenario(c, name, staff, member, direct=None):
    set_positions(c, staff, member)
    for n in (9, 10):
        set_member(c, n, [], [])
    for n, (perms, mine) in (direct or {}).items():
        set_member(c, n, perms, mine)
    time.sleep(1.0)
    with ThreadPoolExecutor(max_workers=5) as ex:
        out = list(ex.map(lambda n: (n, probe_user(c, n)), USERS))
    members = {n: member_snapshot(c, n) for n in USERS}
    return {'name': name, 'staff': staff, 'member': member, 'members': members,
            'results': {str(n): r for n, r in out}}


def cleanup(c):
    for kind, path in c.cleanup:
        patch(c.admin, path, soft_delete_fields(c.uid[1]))
    c.cleanup.clear()


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else ''
    c = login_all()
    make_fixed(c)
    scenarios = []
    allp = {'permissions': ALL_KEYS}
    allmine = {'permissions': ALL_KEYS, 'mine': SCOPED}
    none = {'permissions': []}
    scenarios.append(('기본 (직급 문서 없음)', None, None, None))
    scenarios.append(('직급 문서: 아무 권한 없음', none, none, None))
    scenarios.append(('직급 문서: 모든 권한 전체', allp, allp, None))
    scenarios.append(('직급 문서: 모든 권한 본인만', allmine, allmine, None))
    scenarios.append(('교역자 전체 · 회원 없음, 개별 부여', allp, none,
                      {9: (ALL_KEYS, []), 10: (ALL_KEYS, SCOPED)}))
    for k in ALL_KEYS:
        one = {'permissions': [k]}
        scenarios.append(('단독 %s (전체)' % k, one, one, None))
        if k in SCOPED:
            mine = {'permissions': [k], 'mine': [k]}
            scenarios.append(('단독 %s (본인만)' % k, mine, mine, None))
    results = []
    try:
        for name, st, mem, direct in scenarios:
            if only and only not in name:
                continue
            t = time.time()
            results.append(run_scenario(c, name, st, mem, direct))
            print('%-40s %.0fs' % (name, time.time() - t), flush=True)
    finally:
        set_positions(c, None, None)
        for n in (9, 10):
            set_member(c, n, [], [])
        cleanup(c)
    out = os.environ.get('OUT', 'live_matrix.json')
    json.dump({'run': RUN, 'scenarios': results}, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('saved', out)


if __name__ == '__main__':
    main()
