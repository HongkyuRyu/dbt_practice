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





