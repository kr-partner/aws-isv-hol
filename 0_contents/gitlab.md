# [Vault] AWS-ISV-HOL GiatLab with Vault


## 1. Gitlab SaaS 가입 , 그룹 및 프로젝트 생성

### 1) [Gitlab SaaS](https://gitlab.com/users/sign_in) 접속 후 화면 중앙에 `Register now` 선택 

- First name , Last name, Username  입력 : 중복 불가
- Email 주소, Password입력
- `Register` 클릭 

### 2) Help us keep GitLab secure 단계

- 앞의 단계에서 기입한 이메일에 `Verification code` 확인 
- 코드 입력 후 `Verify email address` 클릭

### 3) Welcome to GitLab 단계

- Role : 예시로 `DevOpsEngineer` 선택
- I'm signing up for GitLab because: 예시로 `I want to store my code`선택
- Who will be using GitLab? : 예시로 `Just me` 선택
- What would you like to do? : 반드시 `Create a new project` 선택
- `Continue` 클릭

### 4) Create or import your first project 단계

- Group name : 예) HashiCorp
- Project name: 예) vault
- `Incloud a Getting Started README` 체크 

### 5) GitLab is better with colleagues! 단계

- `Cancel` 클릭하여 취소 

## 2. Gitlab 구성

### 1) 대상 프로젝트로 이동

- 왼쪽 메뉴에서 - Project - <내가 생성한 project명>으로 이동

### 2) Vault variable 설정

- <내가 생성한 project명> - Settings - CI/CD - variable 메뉴에서 `Expand`선택 - Add variable 

#### (1) VAULT_SERVER_URL 설정 
- key : VAULT_SERVER_URL , value : "<vault_url>:8200" `Add variable`

#### (2)VAULT_AUTH_ROLE 설정 : Vault에서 설정할 role 이름
- key : VAULT_AUTH_ROLE  , value :  예시 `mypjt-prd-role`  설정 후 Add variable

#### (3)VAULT_AUTH_PATH 설정  : Vault에서 설정할 Auth Method에대한 path 
- key : VAULT_AUTH_PATH  , value :  `jwt`  설정 후 Add variable

## 3. Vault 구성

### 1) Vault 변수설정

```bash
export VAULT_ADDR="http://127.0.0.1:8200"

export VAULT_TOKEN=<token>
```

### 2) jwt Auth Method 구성

```bash
#명령어
$ vault auth enable jwt

#결과
Success! Enabled jwt auth method at: jwt/

#명령어 : jwks_url과 , bound_issuer 는 본인의 gitlab 환경에 맞게 설정 
$ vault write auth/jwt/config \
  jwks_url="https://gitlab.com/-/jwks" \
  bound_issuer="https://gitlab.com"

#결과
Success! Data written to: auth/jwt/config
```

### 3) policy 구성

```bash
vault policy write myproject-production - <<EOF
# Read-only permission on 'ops/data/production/*' path

path "ops/data/production/*" {
  capabilities = [ "read" ]
}
EOF
```

### 4) role 구성

- role name : 본 가이드는 `mypjt-prd-role` 라고 설정
- project_id : gitlab에서 생성한 `project의 id`값

```bash
vault write auth/jwt/role/mypjt-prd-role - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-production"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_claims_type": "glob",
  "bound_claims": {
    "project_id": "49180643",
    "ref_type": "branch",
    "ref": "main"
  }
}
EOF

#결과
Success! Data written to: auth/jwt/role/mypjt-prd-role

```
- role 확인

```bash
#명령어
vault read auth/jwt/role/mypjt-prd-role

#결과
Key                        Value
---                        -----
allowed_redirect_uris      <nil>
bound_audiences            <nil>
bound_claims               map[project_id:2027 ref:main ref_type:branch]
bound_claims_type          glob
bound_subject              n/a
claim_mappings             <nil>
clock_skew_leeway          0
expiration_leeway          0
groups_claim               n/a
max_age                    0
not_before_leeway          0
oidc_scopes                <nil>
policies                   [myproject-production]
role_type                  jwt
token_bound_cidrs          []
token_explicit_max_ttl     1m
token_max_ttl              0s
token_no_default_policy    false
token_num_uses             0
token_period               0s
token_policies             [myproject-production]
token_ttl                  0s
token_type                 default
user_claim                 user_email
user_claim_json_pointer    false
verbose_oidc_logging       false
```

### 5) kv engine 2 구성

-  `ops` 라는 이름으로 kv version 2 시크릿 엔진 enable : 

```bash
#명령어
vault secrets enable -path=ops kv-v2

#결과
Success! Enabled the kv-v2 secrets engine at: ops/
```

- kv 시크릿 엔진 패스 생성 및 데이터 입력

```bash
#명령어
vault kv put ops/production/db password='hashicatpass'

#결과
===== Secret Path =====
ops/data/production/db
======= Metadata =======
Key                Value
---                -----
created_time       2023-09-07T06:27:26.147620298Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

- 입력한 데이터 확인 

```bash
#명령어
vault kv get ops/production/db

#결과
===== Secret Path =====
ops/data/production/db

======= Metadata =======
Key                Value
---                -----
created_time       2023-09-07T06:27:26.147620298Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1

====== Data ======
Key         Value
---         -----
password    hashicatpass
```

## 4. gitla CI 설정

### 1)gitlab ci 파일 생성

- <내가 생성한 project명> 프로젝트에서 `+` 선택 - `new file` 선택
- filename : .gitlab-ci.yml
- 파일 내용 
```yaml
stages:
  - getsecret

variables:
  VAULT_ADDR: $VAULT_SERVER_URL

get_password: 
  stage: getsecret
  image: 
    name: hashicorp/vault:latest
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://gitlab.com
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
  tags:
  - gitlab-org-docker
  script:
    - echo $DATABASE_PASSWORD #DATABASE_PASSWORD 변수를 활용할 수 있다. 
    # gitlab runner의 시크릿 변수인 DATABASE_PASSWORD는 실제 노출되지 않음, 하지만 핸즈온 세션에서 해당 값 확인을 위하여 다음과 같은 Vault 명령어를 실행 
    - export VAULT_TOKEN=$(vault write -field=token auth/$VAULT_AUTH_PATH/login role=$VAULT_AUTH_ROLE jwt=$VAULT_ID_TOKEN)
    - vault kv get -field=password ops/production/db
```

- commit message : 예시로 `first gitlab ci` 라고 입력 
- Target Branch : main
- `Commit change`

### 2)runner 결과 확인

<내가 생성한 project명> - Build - Pipelines 

```결과예시
Running with gitlab-runner 15.5.0 (0d4137b8)
  on shared-runner vTjg371N
Resolving secrets
00:00
Resolving secret "DATABASE_PASSWORD"...
Using "vault" secret resolver...
Preparing the "docker" executor
00:04
Using Docker executor with image hashicorp/vault:latest ...
Pulling docker image hashicorp/vault:latest ...
Using docker image sha256:f8b694b6959d15b4316651c0620ee1c541942d688326982734d56f79086e92c4 for hashicorp/vault:latest with digest hashicorp/vault@sha256:4aae09a941ffada937957577b3bd9660c3aba0bc95017e7da277f01ced567277 ...
Preparing environment
00:01
Running on runner-vtjg371n-project-2027-concurrent-0 via 42c404871b42...
Getting source from Git repository
00:02
Fetching changes with git depth set to 20...
Reinitialized existing Git repository in /builds/ctc/devops/hashicorp-team/hc-1-part/cicd/secret-vault/.git/
Checking out d9ce8f05 as main...
Skipping Git submodules setup
Executing "step_script" stage of the job script
00:01
Using docker image sha256:f8b694b6959d15b4316651c0620ee1c541942d688326982734d56f79086e92c4 for hashicorp/vault:latest with digest hashicorp/vault@sha256:4aae09a941ffada937957577b3bd9660c3aba0bc95017e7da277f01ced567277 ...
$ echo $DATABASE_PASSWORD
/builds/ctc/devops/hashicorp-team/hc-1-part/cicd/secret-vault.tmp/DATABASE_PASSWORD
Cleaning up project directory and file based variables
00:01
Job succeeded
```
