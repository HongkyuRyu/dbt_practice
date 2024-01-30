# DBT 도입의 필요성

![image](https://github.com/HongkyuRyu/dbt_practice/assets/69923886/973bfbe7-0e89-4744-9bf5-8f397c742561)

> ### 1. SQL쿼리를 코드로 관리
> ### 2. 데이터 오너십
> ### 3. 데이터 의존성 파악 용이

---
- 데이터 변경 사항에 대한 이해가 쉽다. 
- 과거 데이터로 롤백 가능
- 데이터간 Lineage 가능
- 데이터 품질 테스트 및 오류 보고 가능
- Fact 테이블의 증분 로드 (Incremental Update)
- Dimension 테이블 변경 추적 (히스토리 테이블)
- 용이한 문서 작성
---
(DW)
Redshift / Spark / Snowflake / Bigquery <=======> dbt <----airflow/dagster 등등 (Scheduling)

ETL을 하는 이유는 ELT를 하기 위함이며, 데이터 품질 검증이 중요해졌다.

# 배경지식
## Database Normalization
데이터베이스의 정합성을 쉽게 유지하고 레코드들을 수정/적재/삭제를 용이하게 하는 것을 말한다. (1NF, 2NF, 3NF 등등)

## Slowly Changing Dimensions
DW(Data Warehouse)나 DL(Data Lake)에서는 모든 테이블들의 `히스토리를 유지하는 것이 중요`하다.
이를 위해, `두개의 timestamp 필드`를 가지는 것이 좋다.

- 1.created_at: 생성시간
    - 한번 만들어지면 고정됨
- 2.updated_at
    - 꼭 필요하다. (necessary)
    - 마지막 수정 시간을 나타낸다.
> 해당 경우, 컬럼의 성격에 따라 어떻게 유지할지 방법이 달라진다. 
- SCP Type0, SCD Type1, SCD Type2, SCD Type3, SCD Type4

> 그렇다면 히스토리를 유지하기 위해 어떻게 할 것인가?

즉, 일부 속성은 시간을 두고 `변하게 되는데` 변경 사항을 DW Table에 어떻게 반영해야하나?

- SCP Type 0
    - 한번 Write시, 바꿀 이유가 없는 것
    - 갱신 되지 않고 고정되는 필드
    - ex) 제품 첫 구매일
- SCP Type 1
    - 데이터가 새로 생기면 `덮어쓰면` 되는 컬럼들
- SCP Type 2
    - 특정 엔티티에 대한 데이터가 새로운 레코드로 추가되어야 하는 경우
    - ex) 회원의 등급이 Gold에서 Plantinum으로 상승되었을 경우, 변경시간도 함께 추가되어야 한다.
- SCP Type 3
    - SCP Type 2의 대안
    - 특정 엔티티 데이터가 새로운 `컬럼` 으로 추가되어야 하는 경우
    - ex) 회원의 등급이 Gold에서 Plantinum으로 상승되었을 경우, `이전 등급이라는 컬럼을 생성`
- SCP Type 4
    - 특정 엔티티에 대한 데이터를 `새로운 Dimension테이블에 저장`하는 경우
    - 별도의 테이블로 저장한다.

----

## Models
Raw -> Staging -> Core (dim, fct)

### Source(=raw)
원천테이블 또는 서드파티 데이터(소스 테이블 스키마를 따라간다.)
- raw는 `CTE`로 정의한다.

### Staging(=src)
데이터 모델링의 가장 작은 단위이다. 각 모델은 Source테이블과 `1:1 관계`를 갖는다.
- Staging Model 규칙
    - `stg_` 접두사로 구분한다.
    - 컬럼 네이밍, 타입을 일관적인 방법으로 정리되어야 한다.
    - `데이터 클렌징이 완료`되어야 한다.
    - `PK가 Unique`하고, `Not-null`이어야 한다.
### Mart
비즈니스와 맞닿아 있는 데이터를 다루는 모델
- Mart 모델은 `Fact`와 `Dimension` 모델로 구성된다.
    - `fct_<동사>`: 길고 좁은 테이블
    (컬럼이 적고 로우가 많은)
    >Sessions, Transactions, Orders, Stories, votes
    - `dim_<명사>`: 짧고 넓은 테이블(컬럼이 많고 로우가 적은)
    > 각 Row가 변경이 가능하지만, 변경주기가 긴 것들이 온다. (ex) 고객, 상품, 직원

## Materializations
- View
    - 가볍게 사용할 때
    - 데이터 재사용이 많지 않을 때
    > 데이터 Read가 많은 경우는 사용하지 않는 것이 좋다.
- Table (`create` or `recreate`)
    - 반복적으로 자주 데이터를 읽어야 하는 상황일 때
    - 데이터가 쌓이고 있는 경우는 사용하지 않는다. (Table 생성하면서, Truncate Create 되므로, Table이 재생성된다.(데이터 손실됨))
- Incremental (`Table Append`)
    - Fact 테이블 
    - `과거 레코드를 수정할 필요가 없는 경우`
- Ephemeral
    - 같은 모델을 반복적으로 읽을 때는 사용하지 않는다.
    - 한 SELECT문에 자주 사용되는 데이터를 모듈화할 때 사용한다.
    > 개발이 어느정도 끝나고나서, Ephemeral상태로 변경하고 `dbt run`을 하면, 해당 view는 demolished된다. 그러나, 주의할점은 해당 view가 Table이나, Incremental이나 연계가 되어있다고 판단하면, DW에서 지우지 않는다. 해당 경우는 `DROP VIEW  [VIEW명]`을 해주면 된다.

## Seeds
### Seeds와 Sources의 차이점
- `Seeds`
    - dbt로부터 DW에 로컬 파일을 업로드할 때 사용된다.
    - `작은 파일` 형태로 DW에 로드하는 방법
    - ex) csv파일
    - `dbt seed` 를 실행해서 빌드
---
staging 테이블을 만들 때 입력테이블이 자주 바뀌면, models 밑의 .sql파일을 찾아 일일히 변경해주어야 하는 번거로움이 있다.
=> 해당 번거로움을 해결하기 위해 나온 것이 Sources
=> 입력 테이블에 Alias를 주고, staging 테이블에서 사용

- `Sources`
    - 추상화를 통한 변경처리를 용이하게 한다.
        - source 이름과 새 테이블 이름 두가지로 구성된다.
        > raw_data.user_metadata => hongkyu, metadata
    -  자동으로 레코드 체크 기능을 제공한다.

- `Source Freshness(최신성)`
    - 특정 데이터가 소스와 비교해서 얼마나 최신성이 떨어지는지 체크하는 기능이다.
    > dbt source freshness 명령으로 수행한다.
    ```yaml
    - name: event
      identifier: user_event
      loaded_at_field: datastamp
        freshness:
          warn_after: {count: 1, period: hour}
          error_after: {count: 24, period: hour}
    ```
    이 경우, `INSERT INTO` 할 때, 1시간 이상의 차이가 있다면, WARN이 나오고, 24시간 이상 차이가 있다면, ERROR가 나온다.
![image](https://github.com/HongkyuRyu/dbt_practice/assets/69923886/768b84f7-c4b5-4734-9461-13865e841b11)

![image](https://github.com/HongkyuRyu/dbt_practice/assets/69923886/0951c161-4f46-499a-85a3-b6e9a13f2b34)

---

## Snapshots
Dimension 테이블은 성격에 따라 변경이 자주 발생할 수 있다.
> dbt에서는 테이블의 변화를 지속적으로 기록함으로써 과거 어느 시점이든 다시 돌아가서 테이블의 내용을 볼 수 있는 기능을 말한다.

=> 테이블에 문제가 있을 경우 과거 데이터로 `롤백` 가능
=> 데이터 관련 문제에 관해 `디버깅`이 쉬워진다.
>Dimension 테이블에서 특정 엔티티에 대한 데이터가 변경되는 경우

ex) employee_jobs테이블에서 특정 employee_id의 job_code가 바뀌는 경우
| employee_id | job_code|
|----------| -------|
| E001 | J01|
| E002 | J02|
| E003 | J02|

- SCP Type 2 => 새로운 Dimension테이블 생성 (history, snapshot 테이블)
    - 변경된 레코드가 history테이블에 저장

|employee_id|job_code|DBT_VALID_FROM|DBT_VALID_TO|
|---|---|---|---|
|E002|J02|2024-01-29|2024-01-30|
|E002|J03|2024-01-30|NULL|

- strategies
    - Timestamp: A `unique Key` and an `updated_at` 필드가 source model에 정의되어야 한다. 해당 필드를 통해, 변경 사항을 정의한다.
    - Check: 컬럼에 대한 변경사항이 있을 때 업데이트 진행




