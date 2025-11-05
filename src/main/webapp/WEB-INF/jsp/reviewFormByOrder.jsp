<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>รีวิวคำสั่งซื้อ • เกษตรกรบ้านเรา</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <style>
    *{ font-family:'Prompt',sans-serif }
    body{ background:linear-gradient(180deg,#f7fff9,#ffffff) }
    .card{ background:#fff; border:1px solid #e5e7eb; border-radius:16px; box-shadow:0 8px 26px rgba(2,6,23,.06) }
    .btn{ display:inline-flex; align-items:center; gap:.55rem; padding:.7rem 1rem; border-radius:12px; border:1px solid #e5e7eb; background:#fff; font-weight:700 }
    .btn-primary{ background:linear-gradient(135deg,#10b981,#059669); color:#fff; border-color:transparent }
    .btn:disabled{ opacity:.65; cursor:not-allowed }
    .star{ font-size:26px; cursor:pointer; color:#e5e7eb } .star.on{ color:#f59e0b }
    .imgwrap{ width:84px; height:64px; border:1px solid #e5e7eb; border-radius:10px; overflow:hidden; background:#fff }
    .imgwrap img{ width:100%; height:100%; object-fit:cover }
  </style>
</head>
<body class="text-slate-800">
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<header class="bg-black text-white">
  <div class="max-w-5xl mx-auto px-6 py-3 flex items-center justify-between">
    <a href="${ctx}/main" class="text-lg font-bold">เกษตรกรบ้านเรา</a>
    <nav class="text-sm"><a href="${ctx}/orders" class="hover:underline">คำสั่งซื้อของฉัน</a></nav>
  </div>
</header>

<main class="max-w-3xl mx-auto px-4 py-8">
  <div class="card p-6 md:p-8">
    <h1 class="text-2xl md:text-3xl font-extrabold">รีวิวคำสั่งซื้อ</h1>
    <div class="text-sm text-gray-500 mt-1">1 รีวิวต่อ 1 ใบเสร็จ • อนุญาตเฉพาะขั้นที่ 3 หรือ 4</div>

    <c:if test="${not empty error}">
      <div class="mt-4 border border-red-200 bg-red-50 text-red-700 px-4 py-2 rounded">${error}</div>
    </c:if>
    <c:if test="${not empty msg}">
      <div class="mt-4 border border-emerald-200 bg-emerald-50 text-emerald-700 px-4 py-2 rounded">${msg}</div>
    </c:if>

    <!-- สินค้าในใบเสร็จ -->
    <section class="mt-5">
      <div class="font-semibold mb-2">สินค้าในใบเสร็จ #<c:out value="${orderId}"/></div>
      <div class="space-y-2">
        <c:forEach var="it" items="${items}">
          <div class="flex items-center gap-3">
            <div class="imgwrap">
              <img src="<c:out value='${it.img}'/>"
                   onerror="this.src='https://via.placeholder.com/160x120?text=No+Image'">
            </div>
            <div class="flex-1">
              <div class="font-medium"><c:out value="${it.productname}"/></div>
              <div class="text-xs text-gray-500">productId: <c:out value="${it.productId}"/></div>
            </div>
            <div class="text-sm text-gray-600">x<c:out value="${it.quantity}"/></div>
          </div>
        </c:forEach>
      </div>
      <div class="mt-2 text-xs text-gray-500">
        * ระบบจะบันทึกรีวิวลงสินค้าตัวแรกของใบเสร็จนี้
      </div>
    </section>

    <!-- ฟอร์มรีวิว -->
    <form class="mt-6" method="post" action="${ctx}/reviews/create-by-order" onsubmit="lockBtn()">
      <input type="hidden" name="orderId" value="${orderId}">
      <input type="hidden" name="rating" id="rating" value="5">

      <div class="mb-3">
        <div class="text-sm text-gray-600 mb-1">ให้คะแนน</div>
        <div id="stars" class="flex items-center gap-1">
          <span data-v="1" class="star on">★</span>
          <span data-v="2" class="star on">★</span>
          <span data-v="3" class="star on">★</span>
          <span data-v="4" class="star on">★</span>
          <span data-v="5" class="star on">★</span>
        </div>
      </div>

      <div class="mb-4">
        <label class="block text-sm mb-1">ความคิดเห็น</label>
        <textarea name="comment" class="w-full border rounded-lg px-3 py-3 min-h-[120px]"
                  placeholder="เขียนประสบการณ์เกี่ยวกับคุณภาพ ความคุ้มค่า การบริการ ฯลฯ"></textarea>
      </div>

      <div class="flex items-center gap-3">
        <a href="${ctx}/orders" class="btn">ย้อนกลับ</a>
        <button id="btnSubmit" class="btn btn-primary">ส่งรีวิว</button>
      </div>
    </form>
  </div>
</main>

<footer class="border-t bg-white mt-10">
  <div class="max-w-5xl mx-auto px-6 py-6 text-sm text-gray-600">© 2025 เกษตรกรบ้านเรา</div>
</footer>

<script>
  // ดาวให้คะแนน
  const stars = document.querySelectorAll('#stars .star');
  const rating = document.getElementById('rating');
  stars.forEach(s=>{
    s.addEventListener('click', ()=>{
      const v = parseInt(s.dataset.v,10)||5;
      rating.value = v;
      stars.forEach(t=> t.classList.toggle('on', parseInt(t.dataset.v,10) <= v));
    });
  });
  function lockBtn(){
    const b=document.getElementById('btnSubmit');
    b.setAttribute('disabled','disabled');
    b.textContent='กำลังส่ง...';
  }
</script>
</body>
</html>
