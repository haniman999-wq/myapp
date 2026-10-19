# 공유 서버(Supabase) 준비하기

접수 PC 1대와 직원 3명이 같은 환자 데이터를 실시간으로 보려면, 데이터를 둘 서버가 필요해요.
아래는 **원장님(관리자)이 한 번만** 하면 되는 준비 단계예요. 15~20분 정도 걸려요.

> 계정 가입과 비밀번호 입력은 직접 해 주셔야 해요.

## 1. Supabase 가입과 프로젝트 만들기

1. https://supabase.com 에 접속해 **Start your project**를 누르고 가입해요. (구글 계정이나 이메일)
2. **New project**를 눌러요.
   - Name: `my-patients` (아무 이름이나 괜찮아요)
   - Database Password: 길고 어려운 비밀번호를 만들고 **안전한 곳에 적어 두세요.** (앱에는 쓰지 않아요)
   - **Region: `Northeast Asia (Seoul)`**: 꼭 서울을 고르세요. 데이터가 한국 서버에 저장돼요.
   - Plan: Free
3. **Create new project**를 누르고 1~2분 기다려요.

## 2. 데이터 구조 만들기

1. 왼쪽 메뉴 **SQL Editor** → **New query**를 눌러요.
2. 이 폴더의 `schema.sql` 파일 내용을 전부 복사해 붙여넣고 **Run**을 눌러요.
3. "Success. No rows returned"가 나오면 끝이에요.

## 3. 아무나 가입하지 못하게 막기 (중요)

1. 왼쪽 메뉴 **Authentication** → **Sign In / Providers**(또는 Settings)를 열어요.
2. **Allow new users to sign up**을 **끄고** 저장해요.
   → 이제 관리자가 만든 계정만 로그인할 수 있어요.
3. **Email** 로그인은 켜 둔 채로 두세요.

## 4. 직원 계정 만들기 (4개)

1. **Authentication** → **Users** → **Add user** → **Create new user**를 눌러요.
2. 이메일과 비밀번호를 넣고 **Auto Confirm User**를 체크해요.
3. 4번 반복해요. 예:
   - 접수 PC: `desk@우리병원.kr`
   - 직원 1~3: 각자 이메일
4. 각 직원에게 이메일과 비밀번호를 **직접** 알려 주세요. (단체방에 올리지 마세요)

## 5. 앱에 연결 정보 알려 주기

1. 왼쪽 아래 **Project Settings** → **API**(또는 Data API)를 열어요.
2. 아래 두 값을 복사해 Claude에게 알려 주세요.
   - **Project URL**: `https://xxxx.supabase.co`
   - **anon public** 키: `eyJ...`로 시작하는 긴 글자
3. ⚠️ **service_role** 키(secret)는 **절대 알려 주지도, 어디에도 붙여넣지도 마세요.** 모든 보안을 무시하는 관리자 열쇠예요.

> anon 키는 앱 안에 들어가는 공개용 열쇠예요. 3번(가입 막기)과 schema.sql의 접근 규칙 덕분에
> 이 키만으로는 로그인하지 않은 사람이 아무것도 볼 수 없어요.

## 6. (PC 버전용) Visual Studio 설치

접수 PC용 Windows 프로그램을 만들려면 개발 PC에 Visual Studio가 필요해요.

1. https://visualstudio.microsoft.com/ko/ 에서 **Visual Studio Community**(무료)를 받아요.
2. 설치 화면에서 **"C++를 사용한 데스크톱 개발"**을 체크하고 설치해요. (수 GB, 시간이 걸려요)

## 개인정보 관련 권장 사항

- 실제 환자 데이터를 넣기 전에 개인정보 처리방침 갱신과 위탁(클라우드 사용) 고지가 필요한지
  전문가에게 한 번 확인하세요.
- 직원이 그만두면 **Authentication → Users**에서 그 계정을 바로 삭제하세요.
- 비밀번호는 직원마다 다르게, 길게 만드세요.
