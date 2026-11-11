"""권한 매트릭스가 테스트 교회에 남긴 테스트 데이터를 지운 표시로 정리한다.

대상: 소속(`zz권한테스트…`), 중보기도·말씀묵상(작성자 `권한테스트`), 모임(모임장 `권한테스트`).
규칙이 문서 삭제를 막으므로 지우지 않고 deleted 표시만 남긴다 (앱은 이 표시가 있는 글을 목록에서 뺀다).
기본은 목록만 보여 주고, `--apply`를 주면 실제로 표시한다. 환경변수 PLC_PW(테스트 계정 비밀번호)가 필요하다.

    PLC_PW=... python tool/perm_matrix/cleanup_affiliations.py          # 남은 테스트 데이터 목록
    PLC_PW=... python tool/perm_matrix/cleanup_affiliations.py --apply  # 지운 표시
"""
import sys
import urllib.parse
from datetime import datetime, timezone

import fs

# (컬렉션, 테스트 데이터인지 알아보는 함수)
TARGETS = [
    ('affiliations', lambda f: str(f.get('name', '')).startswith('zz권한테스트')),
    ('prayers', lambda f: f.get('authorName') == '권한테스트'),
    ('devotions', lambda f: f.get('authorName') == '권한테스트'),
    ('meetings', lambda f: f.get('leaderName') == '권한테스트'),
]


def main():
    apply = '--apply' in sys.argv
    if not fs.PW:
        sys.exit('환경변수 PLC_PW가 필요합니다.')
    uid, tok = fs.login(1)  # plc1: 테스트 교회의 교회 운영자
    found = []  # (컬렉션, 문서 id, 이름표)
    for coll, is_test in TARGETS:
        path = 'churches/%s/%s' % (fs.CID, coll)
        docs = fs.list_docs(path, tok)
        if isinstance(docs, dict):
            sys.exit('%s 목록을 읽지 못했습니다: %s' % (coll, docs))
        left = []
        for d in docs:
            f = fs.fields(d)
            if is_test(f) and f.get('deleted') is not True:
                left.append((coll, d['name'].split('/')[-1], f.get('name') or f.get('title') or f.get('content') or ''))
        print('%-13s 전체 %d개, 정리할 테스트 데이터 %d개' % (coll, len(docs), len(left)))
        found += left
    if not apply:
        for coll, i, label in found[:50]:
            print(' ', coll, i, str(label)[:30])
        if len(found) > 50:
            print('  … 외 %d개' % (len(found) - 50))
        print('실제로 표시하려면 --apply')
        return
    stamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')
    body = {'fields': {
        'deleted': {'booleanValue': True},
        'deletedAt': {'timestampValue': stamp},
        'deletedBy': {'stringValue': uid},
    }}
    mask = '&'.join('updateMask.fieldPaths=' + urllib.parse.quote(k) for k in body['fields'])
    done = failed = 0
    for coll, i, _ in found:
        url = fs.BASE + 'churches/%s/%s/%s?%s' % (fs.CID, coll, i, mask)
        r = fs.call(url, body, tok, 'PATCH')
        if isinstance(r, dict) and 'error' not in r:
            done += 1
        else:
            failed += 1
            print('실패', coll, i, r)
    print('지운 표시 %d개, 실패 %d개' % (done, failed))


if __name__ == '__main__':
    main()
