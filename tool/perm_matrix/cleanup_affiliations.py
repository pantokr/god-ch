"""권한 매트릭스가 테스트 교회에 남긴 `zz권한테스트…` 소속을 지운 표시로 정리한다.

규칙이 문서 삭제를 막으므로 지우지 않고 deleted 표시만 남긴다 (앱은 이 표시가 있는 소속을 목록에서 뺀다).
기본은 목록만 보여 주고, `--apply`를 주면 실제로 표시한다. 환경변수 PLC_PW(테스트 계정 비밀번호)가 필요하다.

    PLC_PW=... python tool/perm_matrix/cleanup_affiliations.py          # 남은 소속 목록
    PLC_PW=... python tool/perm_matrix/cleanup_affiliations.py --apply  # 지운 표시
"""
import sys
import urllib.parse
from datetime import datetime, timezone

import fs

PREFIX = 'zz권한테스트'
PARENT = 'churches/%s/affiliations' % fs.CID


def main():
    apply = '--apply' in sys.argv
    if not fs.PW:
        sys.exit('환경변수 PLC_PW가 필요합니다.')
    uid, tok = fs.login(1)  # plc1: 테스트 교회의 교회 운영자
    docs = fs.list_docs(PARENT, tok)
    if isinstance(docs, dict):
        sys.exit('목록을 읽지 못했습니다: %s' % docs)
    left = []
    for d in docs:
        f = fs.fields(d)
        if str(f.get('name', '')).startswith(PREFIX) and f.get('deleted') is not True:
            left.append((d['name'].split('/')[-1], f.get('name')))
    print('전체 소속 %d개, 정리할 테스트 소속 %d개' % (len(docs), len(left)))
    if not apply:
        for i, n in left[:50]:
            print(' ', i, n)
        if len(left) > 50:
            print('  … 외 %d개' % (len(left) - 50))
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
    for i, _ in left:
        r = fs.call(fs.BASE + PARENT + '/' + i + '?' + mask, body, tok, 'PATCH')
        if isinstance(r, dict) and 'error' not in r:
            done += 1
        else:
            failed += 1
            print('실패', i, r)
    print('지운 표시 %d개, 실패 %d개' % (done, failed))


if __name__ == '__main__':
    main()
