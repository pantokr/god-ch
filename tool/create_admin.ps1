<#
  앱 운영자(admin) 계정을 만들거나 비밀번호를 다시 정한다.

  - 아이디 `admin`으로 로그인하는 계정을 Firebase Auth에 가져오기(import)한다.
  - 운영자 권한은 계정의 커스텀 클레임 platformAdmin 이다 (Firestore 문서가 필요 없다).
  - 이미 있으면 같은 계정(localId)을 덮어쓰므로 비밀번호 재설정으로도 쓴다.
  - 비밀번호는 무작위로 만들어 마지막에 한 번만 출력한다. 저장소에는 남기지 않는다.

  사전 조건: firebase CLI 로그인(`firebase login`) 과 프로젝트 접근 권한.
  사용: powershell -File tool\create_admin.ps1 [-Password '직접정한비밀번호']
#>
param(
  [string]$Project = 'god-ch',
  [string]$Password
)

$ErrorActionPreference = 'Stop'

# 로그인 ID `admin` 의 가상 이메일 (lib/features/auth/data/login_id.dart 의 aliasEmail 과 같아야 한다)
$email = 'admin@id.god-ch.local'
$localId = 'app-operator-admin'

$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
if (-not $Password) {
  $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
  $bytes = New-Object byte[] 16
  $rng.GetBytes($bytes)
  $Password = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}
if ($Password.Length -lt 8) { throw '비밀번호는 8자 이상이어야 합니다.' }

# Firebase auth:import 의 PBKDF2_SHA256 형식으로 해시한다.
$rounds = 100000
$salt = New-Object byte[] 16
$rng.GetBytes($salt)
$kdf = New-Object Security.Cryptography.Rfc2898DeriveBytes(
  $Password, $salt, $rounds, [Security.Cryptography.HashAlgorithmName]::SHA256)
$hash = $kdf.GetBytes(32)

$user = [ordered]@{
  localId          = $localId
  email            = $email
  emailVerified    = $true
  displayName      = '앱 운영자'
  passwordHash     = [Convert]::ToBase64String($hash)
  salt             = [Convert]::ToBase64String($salt)
  customAttributes = '{"platformAdmin":true}'
}
$json = @{ users = @($user) } | ConvertTo-Json -Depth 5

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("admin-import-" + [Guid]::NewGuid().ToString('N') + '.json')
try {
  [IO.File]::WriteAllText($tmp, $json, (New-Object Text.UTF8Encoding($false)))
  firebase auth:import $tmp --hash-algo=PBKDF2_SHA256 --rounds=$rounds --project $Project
  if ($LASTEXITCODE -ne 0) { throw 'firebase auth:import 실패' }
}
finally {
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host '앱 운영자 계정을 만들었습니다.'
Write-Host '  아이디    : admin'
Write-Host "  비밀번호  : $Password"
Write-Host '이 비밀번호는 다시 볼 수 없으니 안전한 곳에 저장하세요.'
Write-Host '(이메일/비밀번호 로그인이 Firebase 콘솔에서 켜져 있어야 로그인됩니다.)'
