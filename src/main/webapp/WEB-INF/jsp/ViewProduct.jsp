<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />

<%-- ================== ค่าพื้นฐาน ================== --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />
<c:set var="p"   value="${product}" />
<c:set var="imgs" value="${images}" />

<%-- หา farmerId แบบปลอดภัย เพื่อทำลิงก์ “ดูโปรไฟล์ร้าน” --%>
<c:set var="fid"
       value="${not empty sessionScope.farmerId ? sessionScope.farmerId
               : (not empty param.farmerId ? param.farmerId
                  : (not empty p.farmerId ? p.farmerId
                     : (not empty farmer.farmerId ? farmer.farmerId : '')))}" />
<c:url var="farmerProfileUrl" value="/farmer/profile/view">
  <c:if test="${not empty fid}"><c:param name="farmerId" value="${fid}"/></c:if>
</c:url>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title><c:out value="${empty p.productname ? 'รายละเอียดสินค้า' : p.productname}"/></title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --ease:cubic-bezier(.22,.61,.36,1); --ink:#0f172a; --border:#e5e7eb; --emerald:#10b981; --emerald600:#059669; }
    body{ font-family:'Prompt',sans-serif; color:var(--ink); background:#f7fafc }

    /* Header */
    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    /* Card & Buttons */
    .card{ background:#fff; border:1px solid var(--border); border-radius:18px; box-shadow:0 10px 25px rgba(2,8,23,.06) }
    .btn{ display:inline-flex; align-items:center; gap:.55rem; padding:.75rem 1rem; border-radius:14px; border:1px solid var(--border); background:#fff; transition:transform .12s var(--ease), box-shadow .2s var(--ease), border-color .2s var(--ease); position:relative; overflow:hidden }
    .btn:hover{ transform:translateY(-1px); box-shadow:0 12px 22px rgba(16,185,129,.12); border-color:#c7eadf }
    .btn-primary{ background:linear-gradient(135deg,var(--emerald),var(--emerald600)); color:#fff; border-color:transparent }
    .btn-primary:hover{ filter:brightness(1.05) }
    .btn-outline{ background:#fff; border:1px solid var(--border) }
    .btn-green{ background:#059669; color:#fff; border-color:#059669 }
    .btn-green:hover{ filter:brightness(1.05) }
    .btn:disabled{ opacity:.55; transform:none; box-shadow:none; cursor:not-allowed }

    /* Gallery */
    .hero{ position:relative; aspect-ratio:4/3; background:#fff; border:1px solid var(--border); border-radius:16px; overflow:hidden; user-select:none }
    .hero-img{ max-width:100%; max-height:100%; object-fit:contain; display:block; transition:opacity .28s var(--ease), transform .35s var(--ease) }
    .hero.fade .hero-img{ opacity:0 }
    .nav-btn{ position:absolute; top:50%; transform:translateY(-50%); background:rgba(255,255,255,.92); width:44px; height:44px; border-radius:9999px; display:flex; align-items:center; justify-content:center; box-shadow:0 6px 16px rgba(0,0,0,.15) }
    .nav-prev{ left:10px } .nav-next{ right:10px }
    .index-dot{ position:absolute; left:12px; bottom:12px; background:rgba(17,24,39,.78); color:#fff; font-size:.8rem; padding:.25rem .55rem; border-radius:9999px }
    .tools{ position:absolute; right:10px; bottom:10px; display:flex; gap:8px }
    .tool-btn{ width:40px; height:40px; border-radius:10px; background:rgba(255,255,255,.95); display:flex; align-items:center; justify-content:center; box-shadow:0 6px 16px rgba(0,0,0,.12) }

    .thumbs{ display:flex; gap:8px; overflow:auto; padding:2px 2px 4px 2px; scroll-snap-type:x mandatory }
    .thumb{ min-width:86px; height:64px; border:1px solid var(--border); border-radius:12px; overflow:hidden; cursor:pointer; position:relative; scroll-snap-align:start; transition:transform .2s var(--ease), border-color .2s var(--ease) }
    .thumb:hover{ transform:translateY(-2px) }
    .thumb img{ width:100%; height:100%; object-fit:cover; display:block }
    .thumb.active{ outline:3px solid #10b981; outline-offset:2px }

    .chip{ display:inline-flex; gap:.5rem; align-items:center; color:#065f46; background:#ecfdf5; border:1px solid #a7f3d0; border-radius:9999px; padding:.25rem .7rem; font-size:.8rem }
    .chip i{ color:#059669 }
    .chip-amber{ background:#fff7ed; border-color:#ffedd5; color:#9a6700 }
    .chip-amber i{ color:#f59e0b }
    .chip-sky{ background:#eff6ff; border-color:#dbeafe; color:#0c4a6e }
    .chip-rose{ background:#fff1f2; border-color:#ffe4e6; color:#9f1239 }

    .price{ font-size:clamp(22px,3vw,34px); color:#059669; font-weight:800 }
    .unit{ font-size:clamp(13px,2.2vw,14px); color:#065f46; }

    /* Alert (กรอบแดง + พื้นแดงอ่อน) */
    .alert-red{ border:2px solid #ef4444; background:#fee2e2; border-radius:16px; }

    /* Lightbox */
    .lb{ position:fixed; inset:0; background:rgba(0,0,0,.86); display:none; z-index:60 }
    .lb.open{ display:block }
    .lb-toolbar{ position:absolute; top:12px; right:12px; display:flex; gap:8px; z-index:10 }
    .lb-btn{ background:rgba(255,255,255,.92); border:0; width:42px; height:42px; border-radius:10px; display:flex; align-items:center; justify-content:center; cursor:pointer }
    .lb-stage{ position:absolute; inset:0; display:flex; align-items:center; justify-content:center; overflow:hidden; touch-action:none }
    .lb-img{ max-width:none; user-select:none; -webkit-user-drag:none; will-change:transform }

    /* Toast */
    .toast{ position:fixed; left:50%; transform:translateX(-50%); bottom:22px; background:#065f46; color:#ecfdf5; border:1px solid #34d399; padding:.6rem .9rem; border-radius:12px; box-shadow:0 12px 24px rgba(0,0,0,.18); opacity:0; pointer-events:none; transition:opacity .25s var(--ease), transform .25s var(--ease); z-index:70 }
    .toast.show{ opacity:1; transform:translateX(-50%) translateY(-4px) }

    /* Footer */
    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }
  </style>
</head>

<body>
  <!-- =============== Header =============== -->
  <header class="header text-white shadow-md">
    <div class="container mx-auto px-6 py-3 grid grid-cols-1 md:grid-cols-[auto,1fr,auto] gap-3 items-center">
      <!-- Left: Logo -->
      <a href="${ctx}/main" class="flex items-center gap-3">
        <img src="https://cdn-icons-png.flaticon.com/512/2909/2909763.png" class="h-8 w-8" alt="logo"/>
        <span class="font-bold text-lg">เกษตรกรบ้านเรา</span>
      </a>

      <!-- Center: Search -->
      <form id="search" method="get" action="${ctx}/catalog/list" class="w-full hidden md:block">
        <div class="relative">
          <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-white/70"></i>
          <input name="kw" placeholder="ค้นหาผลผลิต/ร้าน/คำสำคัญ…" class="w-full rounded-lg pl-9 pr-3 py-2 text-white/90 bg-white/10 outline-none focus:ring-2 focus:ring-emerald-400 placeholder-white/70"/>
        </div>
      </form>

      <!-- Right: Nav + Profile (เดิม) -->
      <div class="flex items-center gap-3 justify-self-end">
        <c:choose>
          <c:when test="${not empty sessionScope.loggedInUser && sessionScope.loggedInUser.status eq 'FARMER'}">
            <a href="${ctx}/product/create" class="nav-a">สร้างสินค้า</a>
            <a href="${farmerProfileUrl}" class="nav-a">โปรไฟล์ร้าน</a>
            <a href="${ctx}/product/list/Farmer" class="nav-a">สินค้าของฉัน</a>
            <a href="${ctx}/farmer/orders" class="nav-a">ออเดอร์</a>
          </c:when>
          <c:otherwise>
            <a href="${ctx}/catalog/list" class="nav-a">สินค้าทั้งหมด</a>
            <a href="${ctx}/orders" class="nav-a">ประวัติการสั่งจอง</a>
            <a href="${ctx}/cart" class="nav-a flex items-center gap-1">ตะกร้า <span class="badge">${cartCount}</span></a>
          </c:otherwise>
        </c:choose>

        <c:choose>
          <c:when test="${not empty sessionScope.loggedInUser}">
            <c:set var="rawAvatar" value="${sessionScope.loggedInUser.imageUrl}" />
            <c:set var="avatarUrl" value="" />
            <c:choose>
              <c:when test="${not empty rawAvatar and fn:startsWith(rawAvatar,'http')}"><c:set var="avatarUrl" value="${rawAvatar}" /></c:when>
              <c:when test="${not empty rawAvatar and fn:startsWith(rawAvatar,'/')}"><c:set var="avatarUrl" value="${ctx}${rawAvatar}" /></c:when>
              <c:when test="${not empty rawAvatar}"><c:set var="avatarUrl" value="${ctx}/${rawAvatar}" /></c:when>
              <c:otherwise><c:set var="avatarUrl" value="https://thumb.ac-illust.com/c9/c91fc010def4643287c0cc34cef449e0_t.jpeg" /></c:otherwise>
            </c:choose>

            <div class="relative">
              <button id="profileBtn" type="button" class="inline-flex items-center px-3 py-1 bg-white/20 hover:bg-white/35 backdrop-blur rounded-full text-sm font-medium transition">
                <img src="${avatarUrl}?t=${now.time}" class="h-8 w-8 rounded-full border-2 border-white shadow-md mr-2 object-cover" alt="avatar"/>
                สวัสดี, ${sessionScope.loggedInUser.fullname}
                <i class="fa-solid fa-chevron-down ml-1"></i>
              </button>
              <div id="profileMenu" class="hidden absolute right-0 mt-2 w-56 bg-white text-gray-800 rounded-lg shadow-xl overflow-hidden z-50">
                <ul class="divide-y divide-gray-200">
                  <li><a href="https://www.blacklistseller.com/report/report_preview/447043" class="flex items-center px-4 py-3 hover:bg-green-50" target="_blank" rel="noopener">❓ เช็คบัญชีคนโกง</a></li>
                  <li>
                    <c:choose>
                      <c:when test="${sessionScope.loggedInUser.status eq 'FARMER'}">
                        <a href="${ctx}/farmer/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50">👨‍🌾 แก้ไขโปรไฟล์เกษตรกร</a>
                      </c:when>
                      <c:otherwise>
                        <a href="${ctx}/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50">👤 แก้ไขโปรไฟล์ส่วนตัว</a>
                      </c:otherwise>
                    </c:choose>
                  </li>
                  <li><a href="${ctx}/logout" class="flex items-center px-4 py-3 hover:bg-red-50">🚪 ออกจากระบบ</a></li>
                </ul>
              </div>
            </div>
          </c:when>
          <c:otherwise>
            <a href="${ctx}/login" class="bg-emerald-600 hover:bg-emerald-700 px-4 py-1.5 rounded text-white shadow-lg transition">เข้าสู่ระบบ</a>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </header>

  <c:if test="${not empty error}">
    <div class="container mx-auto px-6 mt-6">
      <div class="bg-red-50 text-red-700 border border-red-200 px-4 py-3 rounded">✖ ${error}</div>
    </div>
  </c:if>

  <!-- =============== เนื้อหาหลัก: หน้ารายละเอียดสินค้า =============== -->
  <main class="container mx-auto px-4 py-8 grid lg:grid-cols-2 gap-8">
    <!-- ซ้าย: แกลเลอรี -->
    <section class="card p-4 md:p-6">
      <div id="hero" class="hero">
        <img id="bigImg" alt="product" class="hero-img" src="https://via.placeholder.com/800x600?text=No+Image">
        <button id="prevBtn" type="button" class="nav-btn nav-prev" aria-label="ก่อนหน้า"><i class="fa-solid fa-chevron-left"></i></button>
        <button id="nextBtn" type="button" class="nav-btn nav-next" aria-label="ถัดไป"><i class="fa-solid fa-chevron-right"></i></button>
        <div id="indexDot" class="index-dot">1 / 1</div>
        <div class="tools">
          <button id="playBtn" class="tool-btn" title="เล่นสไลด์"><i class="fa-solid fa-play"></i></button>
          <button id="zoomBtn" class="tool-btn" title="ขยายดูใหญ่"><i class="fa-solid fa-magnifying-glass-plus"></i></button>
          <button id="fsBtn" class="tool-btn" title="เต็มจอ"><i class="fa-solid fa-maximize"></i></button>
        </div>
      </div>
      <div class="mt-3"><div id="thumbs" class="thumbs"></div></div>
    </section>

    <!-- ขวา: รายละเอียด -->
    <section class="card p-6 md:p-8">
      <a href="${ctx}/catalog/list" class="text-gray-500 hover:text-gray-700 inline-flex items-center gap-2 mb-3">
        <i class="fa-solid fa-arrow-left"></i> กลับไปหน้ารวมสินค้า
      </a>

      <h1 class="text-2xl md:text-3xl font-bold text-gray-800 leading-snug"><c:out value="${p.productname}"/></h1>

      <div class="mt-2 flex flex-wrap items-center gap-2">
        <span class="text-xs md:text-sm inline-flex items-center gap-1 px-2 py-1 rounded-full border">
          หมวด: <c:out value="${empty categoryName ? p.categoryId : categoryName}"/>
        </span>

        <span class="text-xs md:text-sm inline-flex items-center gap-1 px-2 py-1 rounded-full border">
          สต๊อก:
          <fmt:formatNumber value="${empty p.stock ? 0 : p.stock}" type="number" maxFractionDigits="0" groupingUsed="false"/> กก.
        </span>

        <c:if test="${not empty p.status}">
          <c:set var="statusClass" value="chip"/>
          <c:choose>
            <c:when test="${p.status == 'กำลังเปิดรับจอง'}"><c:set var="statusClass" value="chip chip-amber"/></c:when>
            <c:when test="${p.status == 'พร้อมส่ง'}"><c:set var="statusClass" value="chip"/></c:when>
            <c:when test="${p.status == 'ปิดรับจอง'}"><c:set var="statusClass" value="chip chip-rose"/></c:when>
            <c:otherwise><c:set var="statusClass" value="chip chip-sky"/></c:otherwise>
          </c:choose>
          <span class="${statusClass}">
            <i class="fa-solid fa-leaf"></i> สถานะ: <c:out value="${p.status}"/>
          </span>
        </c:if>
      </div>

      <!-- ราคา/หน่วย (บาทต่อ 1 กิโล) -->
      <div class="mt-4">
        <div class="price">฿ <fmt:formatNumber value="${p.price}" minFractionDigits="2"/> <span class="unit">/ 1 กิโลกรัม</span></div>
        <div class="mt-1 text-sm text-emerald-700">หน่วยขาย: กิโลกรัม (กก.)</div>
      </div>

      <div class="my-6 h-px bg-gradient-to-r from-transparent via-gray-200 to-transparent"></div>

      <div>
        <h3 class="font-semibold text-gray-800 mb-2">รายละเอียด</h3>
        <p class="text-gray-700 leading-relaxed whitespace-pre-line">
          <c:out value="${empty p.description ? '—' : p.description}"/>
        </p>

        <form id="addForm" action="${ctx}/cart/add" method="post" class="space-y-4 mt-6">
          <input type="hidden" name="productId" value="${p.productId}">

          <div class="flex flex-wrap items-center gap-3">
            <label for="qty" class="text-sm text-gray-600">จำนวน (กก.)</label>
            <button type="button" class="btn" id="btnMinus" aria-label="ลดจำนวน"><i class="fa-solid fa-minus"></i></button>
            <input id="qty" name="qty" type="number" class="w-24 text-center border rounded-lg py-2" min="1" step="1" value="1" inputmode="numeric">
            <button type="button" class="btn" id="btnPlus" aria-label="เพิ่มจำนวน"><i class="fa-solid fa-plus"></i></button>
          </div>

          <!-- รวมเงินตามจำนวนกิโล -->
          <div class="rounded-xl border p-3 bg-emerald-50">
            <div class="text-sm text-emerald-900 flex items-center gap-2">
              <i class="fa-solid fa-calculator"></i>
              รวมชำระ (ประมาณ): <strong id="totalStr" class="ml-1">฿ 0.00</strong>
              <span class="text-emerald-700">[ราคาอ้างอิง: ฿ <span id="unitStr"><fmt:formatNumber value="${p.price}" minFractionDigits="2"/></span> / 1 กก.]</span>
            </div>
          </div>

          <c:set var="stockNum" value="${empty p.stock ? 0 : p.stock}"/>
          <c:set var="canAdd" value="${stockNum gt 0 and (empty p.status or p.status ne 'ปิดรับจอง')}"/>

          <div class="flex flex-wrap gap-2">
            <button id="btnAdd" class="btn btn-primary" <c:if test="${not canAdd}">disabled</c:if>>
              <i class="fa-solid fa-cart-plus"></i> หยิบใส่ตะกร้า
            </button>

            <button type="button" id="shareBtn" class="btn btn-outline">
              <i class="fa-solid fa-share-nodes"></i> แชร์ลิงก์
            </button>

            <c:if test="${not empty fid}">
              <a href="${farmerProfileUrl}" class="btn btn-outline" title="ดูโปรไฟล์ร้าน">
                <i class="fa-regular fa-eye"></i> ดูโปรไฟล์ร้าน
              </a>
            </c:if>
          </div>

          <c:if test="${not canAdd}">
            <div class="text-sm text-red-600">สินค้าหมดหรือปิดรับจองชั่วคราว</div>
          </c:if>
        </form>
      </div>
    </section>
  </main>

  <!-- ===== แบนเนอร์ความปลอดภัย: กรอบแดง พื้นแดงอ่อน + ปุ่มสีเขียว ===== -->
  <section class="container mx-auto px-4 pb-10">
    <div class="alert-red p-4 md:p-6">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div class="flex items-start gap-3">
          <div class="shrink-0 w-12 h-12 rounded-xl bg-white border border-red-300 flex items-center justify-center text-red-600 shadow">
            <i class="fa-solid fa-triangle-exclamation"></i>
          </div>
          <div>
            <h3 class="font-bold text-lg text-red-800">ตรวจสอบก่อนโอน • ป้องกันโดนโกง</h3>
            <p class="text-sm leading-relaxed text-red-700">
              เพื่อความสบายใจ โปรดเช็กบัญชี/เบอร์โทรในฐานข้อมูลผู้ถูกร้องเรียนจากชุมชนผู้ซื้อก่อนทำรายการ
            </p>
          </div>
        </div>
        <a class="btn btn-green shadow-md"
           href="https://www.blacklistseller.com/report/report_preview/447043"
           target="_blank" rel="noopener">
          <i class="fa-solid fa-up-right-from-square"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </section>

  <!-- =============== Footer =============== -->
  <footer class="footer-dark">
    <div class="container mx-auto px-6 py-10 grid md:grid-cols-3 gap-6 text-sm">
      <div>
        <h4 class="font-bold mb-2">เกี่ยวกับเรา</h4>
        <p class="text-gray-300">ตลาดออนไลน์สำหรับสินค้าเกษตรคุณภาพ ส่งตรงจากฟาร์มท้องถิ่น</p>
      </div>
      <div>
        <h4 class="font-bold mb-2">ลิงก์ด่วน</h4>
        <ul class="space-y-1">
          <li><a href="${ctx}/main">หน้าหลัก</a></li>
          <li><a href="${ctx}/catalog/list">สินค้าทั้งหมด</a></li>
          <li><a href="${ctx}/preorder/list">สั่งจองสินค้า</a></li>
        </ul>
      </div>
      <div>
        <h4 class="font-bold mb-2">ความปลอดภัย</h4>
        <p class="text-gray-300 mb-2">ตรวจสอบรายชื่อผู้ค้าต้องสงสัยก่อนชำระเงิน</p>
        <a class="btn btn-green shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <!-- ปุ่มลอยเช็คบัญชีคนโกง -->
  <a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50"
     href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
    <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
  </a>

  <!-- Toast -->
  <div id="toast" class="toast">เพิ่มลงตะกร้าแล้ว</div>

  <!-- =============== Scripts =============== -->
  <script>
    // โปรไฟล์ดรอปดาวน์
    function toggleProfileMenu(){ const m=document.getElementById('profileMenu'); if(!m) return; m.classList.toggle('hidden'); }
    document.getElementById('profileBtn')?.addEventListener('click', toggleProfileMenu);
    document.addEventListener('click',(e)=>{ const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu'); if(!b||!m) return; if(!b.contains(e.target) && !m.contains(e.target)) m.classList.add('hidden'); });

    // ===== รวมรูปจาก server =====
    const ctx='${ctx}';
    const IMAGES=[];
    <c:if test="${not empty p.img}">
      <c:choose>
        <c:when test="${fn:startsWith(p.img,'http')}">IMAGES.push('${fn:escapeXml(p.img)}');</c:when>
        <c:when test="${fn:startsWith(p.img,'/uploads/')}">IMAGES.push('${fn:escapeXml(ctx)}${fn:escapeXml(p.img)}');</c:when>
        <c:otherwise>IMAGES.push('${fn:escapeXml(ctx)}/uploads/${fn:escapeXml(p.img)}');</c:otherwise>
      </c:choose>
    </c:if>
    <c:forEach var="im" items="${imgs}">
      <c:choose>
        <c:when test="${fn:startsWith(im.imageUrl,'http')}">IMAGES.push('${fn:escapeXml(im.imageUrl)}');</c:when>
        <c:when test="${fn:startsWith(im.imageUrl,'/uploads/')}">IMAGES.push('${fn:escapeXml(ctx)}${fn:escapeXml(im.imageUrl)}');</c:when>
        <c:otherwise>IMAGES.push('${fn:escapeXml(ctx)}/uploads/${fn:escapeXml(im.imageUrl)}');</c:otherwise>
      </c:choose>
    </c:forEach>
    const PICS=Array.from(new Set(IMAGES));
    if(!PICS.length) PICS.push('https://via.placeholder.com/800x600?text=No+Image');

    // ===== DOM =====
    const hero = document.getElementById('hero');
    const big  = document.getElementById('bigImg');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    const zoomBtn = document.getElementById('zoomBtn');
    const fsBtn   = document.getElementById('fsBtn');
    const playBtn = document.getElementById('playBtn');
    const thumbs  = document.getElementById('thumbs');
    const indexDot= document.getElementById('indexDot');
    const qty     = document.getElementById('qty');
    const btnMinus= document.getElementById('btnMinus');
    const btnPlus = document.getElementById('btnPlus');
    const btnAdd  = document.getElementById('btnAdd');
    const toast   = document.getElementById('toast');

    // ===== แคโรเซล =====
    let cur=0, timer=null, autoplay=false, D=4200;
    function preload(i){ if(i>=0&&i<PICS.length){ const x=new Image(); x.src=PICS[i]; } }
    function setIndex(){ indexDot.textContent=(cur+1)+' / '+PICS.length; }
    function render(){
      hero.classList.add('fade');
      requestAnimationFrame(()=>{ big.src=PICS[cur]; setIndex(); setTimeout(()=>hero.classList.remove('fade'),60); });
      thumbs.innerHTML='';
      PICS.forEach((url,i)=>{
        const t=document.createElement('div'); t.className='thumb'+(i===cur?' active':'');
        const img=document.createElement('img'); img.src=url; img.loading='lazy'; t.appendChild(img);
        t.addEventListener('click',()=>{cur=i; render();});
        thumbs.appendChild(t);
      });
      preload((cur+1)%PICS.length); preload((cur-1+PICS.length)%PICS.length);
    }
    function go(d){ cur=(cur+d+PICS.length)%PICS.length; render(); }
    prevBtn.addEventListener('click',()=>go(-1));
    nextBtn.addEventListener('click',()=>go(1));
    window.addEventListener('keydown',e=>{ if(e.key==='ArrowLeft') go(-1); if(e.key==='ArrowRight') go(1); });

    // swipe
    let sx=0,sy=0,dx=0,dy=0,sw=false;
    hero.addEventListener('touchstart',e=>{ if(e.touches.length!==1) return; sw=true; sx=e.touches[0].clientX; sy=e.touches[0].clientY; },{passive:true});
    hero.addEventListener('touchmove',e=>{ if(!sw) return; dx=e.touches[0].clientX-sx; dy=e.touches[0].clientY-sy; },{passive:true});
    hero.addEventListener('touchend',()=>{ if(!sw) return; if(Math.abs(dx)>40 && Math.abs(dx)>Math.abs(dy)) go(dx<0?1:-1); sw=false; dx=dy=0; });

    // autoplay
    function tick(){ if(!autoplay) return; go(1); timer=setTimeout(tick,D); }
    function startAuto(){ if(autoplay) return; autoplay=true; playBtn.innerHTML='<i class="fa-solid fa-pause"></i>'; timer=setTimeout(tick,D); }
    function stopAuto(){ autoplay=false; playBtn.innerHTML='<i class="fa-solid fa-play"></i>'; clearTimeout(timer); timer=null; }
    playBtn.addEventListener('click',()=> autoplay?stopAuto():startAuto());

    // fullscreen
    fsBtn.addEventListener('click',()=>{ const el=hero; if(!document.fullscreenElement){el.requestFullscreen?.();} else{document.exitFullscreen?.();} });

    // Lightbox
    const lb=document.createElement('div'); lb.id='lightbox'; lb.className='lb'; lb.innerHTML=
      '<div class="lb-toolbar">\
         <button class="lb-btn" id="lbPrev"><i class="fa-solid fa-chevron-left"></i></button>\
         <button class="lb-btn" id="lbNext"><i class="fa-solid fa-chevron-right"></i></button>\
         <button class="lb-btn" id="lbZoomIn"><i class="fa-solid fa-magnifying-glass-plus"></i></button>\
         <button class="lb-btn" id="lbZoomOut"><i class="fa-solid fa-magnifying-glass-minus"></i></button>\
         <button class="lb-btn" id="lbReset"><i class="fa-solid fa-rotate-right"></i></button>\
         <button class="lb-btn" id="lbClose"><i class="fa-solid fa-xmark"></i></button>\
       </div>\
       <div class="lb-stage" id="lbStage"><img id="lbImg" class="lb-img" alt="preview"></div>';
    document.body.appendChild(lb);
    const lbImg=document.getElementById('lbImg'), lbStage=document.getElementById('lbStage');
    function openLB(index){ cur=index??cur; lb.classList.add('open'); setLB(PICS[cur], true); }
    function closeLB(){ lb.classList.remove('open'); }
    document.getElementById('lbClose').addEventListener('click',closeLB);
    window.addEventListener('keydown',e=>{ if(!lb.classList.contains('open')) return; if(e.key==='Escape') closeLB(); if(e.key==='ArrowLeft') document.getElementById('lbPrev').click(); if(e.key==='ArrowRight') document.getElementById('lbNext').click(); });
    document.getElementById('lbPrev').addEventListener('click',()=>{ cur=(cur-1+PICS.length)%PICS.length; setLB(PICS[cur],true); });
    document.getElementById('lbNext').addEventListener('click',()=>{ cur=(cur+1)%PICS.length; setLB(PICS[cur],true); });
    function setLB(url,reset){ lbImg.src=url; if(reset){ scale=1; tx=ty=0; apply(); } }
    document.getElementById('zoomBtn').addEventListener('click',()=>openLB(cur));
    big.addEventListener('click',()=>openLB(cur));
    lb.addEventListener('click',e=>{ if(e.target===lb) closeLB(); });

    // zoom/pan
    let scale=1,minS=1,maxS=4,tx=0,ty=0,px=0,py=0,dragging=false,touches=[];
    function apply(){ lbImg.style.transform=`translate(${tx}px,${ty}px) scale(${scale})`; }
    function clamp(){ const r=lbStage.getBoundingClientRect(); const iw=lbImg.naturalWidth||1000, ih=lbImg.naturalHeight||1000; const sw=iw*scale, sh=ih*scale; const maxX=Math.max(0,(sw-r.width)/2)+40; const maxY=Math.max(0,(sh-r.height)/2)+40; tx=Math.max(-maxX,Math.min(maxX,tx)); ty=Math.max(-maxY,Math.min(maxY,ty)); }
    document.getElementById('lbZoomIn').addEventListener('click',()=>{ scale=Math.min(maxS,scale+.5); clamp(); apply(); });
    document.getElementById('lbZoomOut').addEventListener('click',()=>{ scale=Math.max(minS,scale-.5); clamp(); apply(); });
    document.getElementById('lbReset').addEventListener('click',()=>{ scale=1; tx=ty=0; apply(); });
    lbStage.addEventListener('wheel',e=>{ e.preventDefault(); const d=e.deltaY<0?.2:-.2; const old=scale; scale=Math.min(maxS,Math.max(minS,scale+d)); const rect=lbStage.getBoundingClientRect(); const mx=e.clientX-rect.left-rect.width/2; const my=e.clientY-rect.top-rect.height/2; tx-=mx*(scale/old-1); ty-=my*(scale/old-1); clamp(); apply(); },{passive:false});
    lbStage.addEventListener('mousedown',e=>{ dragging=true; px=e.clientX; py=e.clientY; });
    window.addEventListener('mousemove',e=>{ if(!dragging) return; tx+=e.clientX-px; ty+=e.clientY-py; px=e.clientX; py=e.clientY; clamp(); apply(); });
    window.addEventListener('mouseup',()=>dragging=false);
    lbStage.addEventListener('pointerdown',e=>{ lbStage.setPointerCapture(e.pointerId); touches.push(e); });
    lbStage.addEventListener('pointerup',e=>{ touches=touches.filter(t=>t.pointerId!==e.pointerId); });
    lbStage.addEventListener('pointermove',e=>{ touches=touches.map(t=>t.pointerId===e.pointerId?e:t); if(touches.length===2){ const[a,b]=touches; const d1=Math.hypot(a.clientX-b.clientX,a.clientY-b.clientY); if(!lbStage._d0){ lbStage._d0=d1; lbStage._s0=scale; } scale=Math.min(maxS,Math.max(minS,lbStage._s0*d1/lbStage._d0)); clamp(); apply(); }});
    lbStage.addEventListener('pointercancel',()=>{ touches=[]; lbStage._d0=null; });

    // ===== คำนวณรวมเงิน (บาทต่อ 1 กิโล) =====
    const UNIT_PRICE = Number('${p.price}');
    const unitStrEl  = document.getElementById('unitStr');
    const totalStrEl = document.getElementById('totalStr');

    function toMoney(n){ return (isFinite(n)?n:0).toLocaleString(undefined,{minimumFractionDigits:2, maximumFractionDigits:2}); }
    function clampQty(){
      const stockStr='${empty p.stock ? "0" : p.stock}';
      const MAX_STOCK=/^\d+$/.test(stockStr)?parseInt(stockStr,10):999999;
      let v=parseInt(qty.value||'1',10);
      if(isNaN(v)||v<1) v=1;
      if(MAX_STOCK>0) v=Math.min(v,MAX_STOCK);
      qty.value=v;
      const total = UNIT_PRICE * v;
      totalStrEl.textContent = '฿ ' + toMoney(total);
      if(unitStrEl) unitStrEl.textContent = toMoney(UNIT_PRICE);
    }
    clampQty();

    // Qty + Toast
    function ripple(e){ const btn=e.currentTarget; const rect=btn.getBoundingClientRect(); const r=document.createElement('span'); r.style.position='absolute'; r.style.borderRadius='9999px'; const d=Math.max(rect.width,rect.height); r.style.width=r.style.height=d+'px'; r.style.left=(e.clientX-rect.left-d/2)+'px'; r.style.top=(e.clientY-rect.top-d/2)+'px'; r.style.background='rgba(255,255,255,.55)'; r.style.transform='scale(0)'; r.style.animation='ripple .6s linear'; r.style.pointerEvents='none'; btn.appendChild(r); setTimeout(()=>r.remove(),600); }
    document.getElementById('btnMinus').addEventListener('click',e=>{ ripple(e); qty.value=(parseInt(qty.value||'1',10)-1)||1; clampQty(); });
    document.getElementById('btnPlus').addEventListener('click',e=>{ ripple(e); qty.value=(parseInt(qty.value||'1',10)+1)||1; clampQty(); });

    document.getElementById('addForm').addEventListener('submit',e=>{
      const t=e.submitter||btnAdd;
      const fake={currentTarget:t,clientX:t.getBoundingClientRect().left+10,clientY:t.getBoundingClientRect().top+10};
      ripple(fake);
      toast.textContent='เพิ่มลงตะกร้าแล้ว';
      toast.classList.add('show');
      setTimeout(()=>toast.classList.remove('show'),1400);
    });

    // แชร์ลิงก์
    document.getElementById('shareBtn')?.addEventListener('click', async (e)=>{
      ripple(e);
      const url=window.location.href;
      try{
        if(navigator.share){ await navigator.share({title:document.title,url}); }
        else{ await navigator.clipboard.writeText(url); toast.textContent='คัดลอกลิงก์แล้ว'; toast.classList.add('show'); setTimeout(()=>toast.classList.remove('show'),1200); }
      }catch(_){}
    });

    // เริ่มต้น
    render();
  </script>
</body>
</html>
