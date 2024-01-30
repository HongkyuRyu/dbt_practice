# DBT 도입의 필요성
> ### 1. SQL쿼리를 코드로 관리
> ### 2. 데이터 오너십
> ### 3. 데이터 의존성 파악 용이

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



