#!/bin/bash

API_URL="http://apis.data.go.kr/1320000/LostGoodsInfoInqireService/getLostGoodsInfoAccToClAreaPd"
DETAIL_URL="http://apis.data.go.kr/1320000/LostGoodsInfoInqireService/getLostGoodsDetailInfo"
SERVICE_KEY="" #서비스키 입력

#1~5행 해석 [API 주소 및 키 설정] : 공공데이터 포털의 분실물 목록 조회 API와 분실물 상세 정보 API URL을 설정.
#SERVICE_KEY는 사용자 인증용 API키

START_YMD=$(date -d "30 days ago" +%Y%m%d)
END_YMD=$(date +%Y%m%d)
PARAMS="START_YMD=$START_YMD&END_YMD=$END_YMD&PRDT_CL_CD_01=PRA000&PRDT_CL_CD_02=PRA300&LST_LCT_CD=LCA000&pageNo=1&numOfRows=100"
#9~11행 해석 [날짜 계신 및 파라미터 구성] : 최근 30일간의 데이터 조회를 위해 날짜를 계산
#API 요청 파라미터(PARAMS)를 문자열로 구성(품목 대분류/중분류 코드와 위치 코드 포함)

curl -s "$API_URL?$PARAMS&serviceKey=$SERVICE_KEY" -o /tmp/lost.xml
#curl을 사용하여 XML 데이터를 받아 /tmp/lost.xml로 저장

OUTFILE="/data/index.html" #HTML 출력을 /data/index.html 파일에 저장할 준비

cat <<EOF > "$OUTFILE" # cat <EOF 구문으로 이후의 HTML 문서를 한꺼번에 작성


<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>최근 분실물 목록</title>
  <style>
    body { font-family: 'Segoe UI', sans-serif; padding: 40px; background: #f7f9fc; color: #333; }
    h1 { text-align: center; }
    table {
      width: 100%;
      border-collapse: collapse;
      background: white;
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
      margin-top: 20px;
    }
    th, td {
      padding: 12px;
      border-bottom: 1px solid #ddd;
      text-align: center;
    }
    th { background: #0077cc; color: white; }
    img { width: 80px; border-radius: 4px; }
    .filter-box {
      display: flex;
      justify-content: center;
      gap: 10px;
      flex-wrap: wrap;
      margin-bottom: 20px;
    }
    .filter-box input, .filter-box select {
      padding: 5px;
      font-size: 14px;
    }
    .pagination {
      text-align: center;
      margin-top: 20px;
    }
    .pagination button {
      margin: 3px;
      padding: 5px 10px;
      border: none;
      background: #eee;
      border-radius: 4px;
      cursor: pointer;
    }
    .pagination button.active {
      background-color: #0077cc;
      color: white;
    }
  </style>
</head>
<body>
  <h1>최근 분실물 목록</h1>
  <div class="filter-box">
    <div>
      기간<br>
      <input type="date" id="startDate" value="${START_YMD:0:4}-${START_YMD:4:2}-${START_YMD:6:2}">
      ~
      <input type="date" id="endDate" value="${END_YMD:0:4}-${END_YMD:4:2}-${END_YMD:6:2}">
    </div>
    <div>
      습득물명<br>
      <input type="text" id="nameInput" placeholder="예: 지갑, 우산 등">
    </div>
    <div>
      습득지역<br>
      <input type="text" id="placeInput" placeholder="예: 서울역, 도서관 등">
    </div>
  </div>
  <table id="lostTable">
    <thead>
      <tr>
        <th>사진</th>
        <th>제목</th>
        <th>이름</th>
        <th>장소</th>
        <th>날짜</th>
        <th>분류</th>
      </tr>
    </thead>
    <tbody>
EOF
#23~104행 해석 [head 및 스타일링] : HTML 구조와 CSS 스타일을 선언
#UI 요소 : 필터 박스, 테이블 스타일, 입력창, 페이지네이션 버튼

count=$(xmllint --xpath "count(//item)" /tmp/lost.xml) #XML에서 <item>의 개수를 세어 반복 횟수를 정함
for i in $(seq 1 $count); do #xmllint로 반복적으로 XML 파싱하여, 각 항목의 제목, 이름, 장소, 날짜, 분류, 고유ID 등을 추출
  title=$(xmllint --xpath "string((//item)[$i]/lstSbjt)" /tmp/lost.xml)
  name=$(xmllint --xpath "string((//item)[$i]/lstPrdtNm)" /tmp/lost.xml)
  place=$(xmllint --xpath "string((//item)[$i]/lstPlace)" /tmp/lost.xml)
  date=$(xmllint --xpath "string((//item)[$i]/lstYmd)" /tmp/lost.xml)
  category=$(xmllint --xpath "string((//item)[$i]/prdtClNm)" /tmp/lost.xml)
  atcId=$(xmllint --xpath "string((//item)[$i]/atcId)" /tmp/lost.xml)

  curl -s "$DETAIL_URL?ATC_ID=$atcId&serviceKey=$SERVICE_KEY" -o /tmp/detail.xml
  image=$(xmllint --xpath "string(//item/lstFilePathImg)" /tmp/detail.xml)
  #상세 정보를 추가로 요청하여 이미지 주소 얻음

  if [[ -z "$image" || "$image" == *"no_img.gif" ]]; then
    image="https://dummyimage.com/100x100/cccccc/000000&text=No+Image"
  fi
  #이미지가 없거나 기본 이미지일 경우, 더미 이미지를 대신 사용

  echo "<tr data-name='$name' data-place='$place' data-date='$date'>" >> "$OUTFILE"
  echo "  <td><img src='$image'></td>" >> "$OUTFILE"
  echo "  <td>$title</td><td>$name</td><td>$place</td><td>$date</td><td>$category</td>" >> "$OUTFILE"
  echo "</tr>" >> "$OUTFILE"
  #각 데이터를 HTML <tr> 테이블 row로 생성하여 HTML 파일에 저장
done

cat <<EOF >> "$OUTFILE"
    </tbody>
  </table>
  <div class="pagination" id="pagination"></div>
  <script>
    const rows = [...document.querySelectorAll('#lostTable tbody tr')];
    const pagination = document.getElementById('pagination');
    let currentPage = 1;
    const rowsPerPage = 5;

    function filterTable() {
      const name = document.getElementById('nameInput').value.toLowerCase();
      const place = document.getElementById('placeInput').value.toLowerCase();
      const start = new Date(document.getElementById('startDate').value);
      const end = new Date(document.getElementById('endDate').value);

      const filtered = rows.filter(row => {
        const rowName = row.dataset.name.toLowerCase();
        const rowPlace = row.dataset.place.toLowerCase();
        const rowDate = new Date(row.dataset.date);
        return rowName.includes(name) &&
               rowPlace.includes(place) &&
               rowDate >= start && rowDate <= end;
      });

      rows.forEach(row => row.style.display = 'none');
      filtered.slice((currentPage - 1) * rowsPerPage, currentPage * rowsPerPage)
              .forEach(row => row.style.display = '');

      renderPagination(filtered.length);
    }

    function renderPagination(total) {
      pagination.innerHTML = '';
      const pageCount = Math.ceil(total / rowsPerPage);
      for (let i = 1; i <= pageCount; i++) {
        const btn = document.createElement('button');
        btn.innerText = i;
        if (i === currentPage) btn.classList.add('active');
        btn.addEventListener('click', () => {
          currentPage = i;
          filterTable();
        });
        pagination.appendChild(btn);
      }
    }

    document.getElementById('nameInput').addEventListener('input', () => { currentPage = 1; filterTable(); });
    document.getElementById('placeInput').addEventListener('input', () => { currentPage = 1; filterTable(); });
    document.getElementById('startDate').addEventListener('change', () => { currentPage = 1; filterTable(); });
    document.getElementById('endDate').addEventListener('change', () => { currentPage = 1; filterTable(); });

    filterTable();
  </script>
</body>
</html>
EOF
#134~136행 : HTML 닫기 태그들과 페이지네이션 버튼들이 들어갈 <div> 요소
#137~139행 : row : 테이블 내의 모든 <tr> 요소를 배열로 저장, pagination : 페이지네이션 버튼이 들어갈 DOM 요소 참조
#140~141행 : 현재 페이지 번호와 한 페이지당 보여줄 행(row)의 수를 정의
#143~147행 : 사용자가 입력한 이름/장소/기간 필터 조건을 받아옴
#149~156행 : 각 <tr>에 저장된 데이터셋을 기준으로 필터링 수행 (includes:부분 문자열 포함 여부 확인)
#158~160행 : 필터된 행 중에서 현재 페이지에 해당하는 행만 표시 (나머지는 display: none으로 숨김 처리)
#162행 : 페이지네이션 버튼을 다시 그림
#165~167행 : 기존 버튼을 초기화하고, 페이지 개수를 계산
#168~171행 : 페이지 수만큼 <button> 요소를 생성하고, 현재 페이지일 경우 active 클래스 추가
#170~178행 : 각 버튼에 클릭 이벤트 리스너 추가 → 클릭 시 해당 페이지로 이동 + 필터 재적용
#180~183행 : nameInput, placeInput, startDate, endDate라는 아이디를 가진 HTML 입력 요소들에 이벤트 리스너를 붙임
#각각의 입력 요소에서 사용자가 입력하거나 변경할 때마다 currentPage를 1로 초기화하고, filterTable() 함수를 호출해서 테이블 데이터를 필터링함
#180~183행 한줄 요약 : 입력값이 바뀔 때마다 페이지를 1페이지로 돌리고, 필터링 작업을 다시 수행하는 기능