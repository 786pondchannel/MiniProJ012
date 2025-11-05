<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />

<!-- รวมลิสต์สินค้าให้ตัวแปรเดียวชื่อ rows -->
<c:set var="rows"
       value="${not empty products ? products :
               (not empty myProducts ? myProducts :
               (not empty productList ? productList :
               (not empty list ? list : items)))}"/>

<!-- (ออปชัน) แผนที่จำนวนการอ้างอิงต่อสินค้า: orderRefCounts[productId] = {perorder:Long, preorderdetail:Long} -->
<c:set var="refMap" value="${orderRefCounts}"/>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>สินค้าของฉัน • เกษตรกรบ้านเรา</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --ease:cubic-bezier(.22,.8,.2,1) }
    html,body{font-family:'Prompt',system-ui,-apple-system,Segoe UI,Roboto,Arial}
    body{background:#f8fafc; color:#0f172a}

    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    .card { background:#fff; border:1px solid #e5e7eb; border-radius:16px; box-shadow:0 10px 26px rgba(0,0,0,.06) }
    .imgwrap{ aspect-ratio:4/3; overflow:hidden; border-radius:12px; border:1px solid #eef; position:relative }
    .imgwrap img{ width:100%; height:100%; object-fit:cover; display:block; transition:transform .35s var(--ease) }
    .product-card:hover .imgwrap img{ transform:scale(1.04) }
    .badgeX { font-size:.8rem; border:1px solid #e5e7eb; border-radius:9999px; padding:.2rem .7rem; background:#fff }
    .muted { color:#6b7280 }
    .btn{display:inline-flex;align-items:center;gap:.6rem;padding:.7rem 1rem;border-radius:14px;border:1px solid #e5e7eb;background:#fff;transition:transform .12s var(--ease), box-shadow .2s var(--ease), border-color .2s var(--ease); position:relative; overflow:hidden}
    .btn:hover{transform:translateY(-1px); box-shadow:0 10px 20px rgba(16,185,129,.12); border-color:#d1fae5}
    .btn i{font-size:1rem}
    .btn-primary{ background:linear-gradient(135deg,#10b981,#059669); color:#fff; border-color:transparent }
    .btn-danger{ background:linear-gradient(135deg,#ef4444,#dc2626); color:#fff; border-color:transparent }
    .btn-danger:hover{ filter:brightness(1.03); box-shadow:0 12px 24px rgba(220,38,38,.18); }

    .qchip{display:inline-flex;align-items:center;gap:.6rem;padding:.7rem 1rem;border-radius:9999px;border:2px solid #e5e7eb;background:#fff;font-weight:900;font-size:.98rem}
    .qchip:hover{border-color:#a7f3d0; box-shadow:0 14px 26px rgba(16,185,129,.12)}
    .qchip.is-active{border-color:#10b981; box-shadow:0 16px 40px rgba(16,185,129,.18)}
    .qchip .count{background:#10b981;color:#fff;border-radius:9999px;padding:.15rem .55rem;font-size:.85rem}

    .statX{display:flex;align-items:center;gap:14px;padding:16px 18px;border-radius:18px;border:1px solid #e5e7eb;background:#fff;box-shadow:0 18px 40px rgba(2,6,23,.06)}
    .statX .icon{width:56px;height:56px;border-radius:14px;display:grid;place-items:center;font-size:1.4rem}
    .statX .ttl{font-size:.9rem;color:#6b7280}
    .statX .num{font-size:2rem;line-height:1.1;font-weight:900}
    .ic-emerald{background:linear-gradient(135deg,#34d399,#10b981);color:#fff}
    .ic-sky{background:linear-gradient(135deg,#38bdf8,#0284c7);color:#fff}
    .ic-amber{background:linear-gradient(135deg,#fbbf24,#d97706);color:#fff}
    .ic-rose{background:linear-gradient(135deg,#fb7185,#dc2626);color:#fff}

    .tools{position:sticky;top:68px;z-index:30;background:#ffffffa6;backdrop-filter:blur(10px);border:1px solid #e5e7eb;border-radius:16px;padding:12px}
    .tools .ipt{height:46px;border-radius:12px}

    @keyframes fadeUp { from{opacity:0; transform:translateY(12px)} to{opacity:1; transform:none} }
    .fadeUp{ animation: fadeUp .45s var(--ease) both }
    .stagger > *{ animation: fadeUp .55s var(--ease) both }

    .toast{animation:toastIn .22s var(--ease) both}
    @keyframes toastIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:none}}

    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }

    /* ===== BIG SUCCESS POPUP ===== */
    .okpop{position:fixed;inset:0;display:none;place-items:center;z-index:70}
    .okpop.show{display:grid}
    .okveil{position:absolute;inset:0;background:rgba(0,0,0,.5);backdrop-filter:blur(2px)}
    .okcard{position:relative;width:min(720px,94vw);background:#fff;border:1px solid #e5e7eb;border-radius:26px;padding:34px 28px;box-shadow:0 50px 140px rgba(2,6,23,.4)}
    .oktop{display:flex;flex-direction:column;align-items:center}
    .okicon{width:120px;height:120px;border-radius:9999px;display:grid;place-items:center;margin-bottom:10px;background:linear-gradient(135deg,#34d399,#10b981);color:#fff;box-shadow:0 18px 60px rgba(16,185,129,.35)}
    .oktitle{font-weight:900;font-size:30px}
    .okdesc{margin-top:6px;color:#475569;font-size:18px;text-align:center}

    /* ===== BLOCKED MODAL (ใหญ่ กลางจอ) ===== */
    #blockModal{position:fixed;inset:0;display:none;place-items:center;z-index:80}
    #blockModal.show{display:grid!important}
    #blockModal .veil{position:absolute;inset:0;background:rgba(0,0,0,.65);backdrop-filter:blur(2px)}
    .cardPop{position:relative;width:min(780px,94vw);background:#fff;border:1px solid #e5e7eb;border-radius:26px;padding:26px;box-shadow:0 50px 140px rgba(2,6,23,.45);animation:popIn .24s var(--ease) both}
    @keyframes popIn{from{opacity:0;transform:translateY(10px) scale(.97)}to{opacity:1;transform:none}}
    .ringPulse:before{content:"";position:absolute;inset:-8px;border-radius:9999px;border:3px solid rgba(239,68,68,.35);animation:ring 1.6s ease-out infinite}
    @keyframes ring{0%{opacity:.9;transform:scale(1)}100%{opacity:0;transform:scale(1.5)}}
    .hint{background:#f8fafc;border:1px dashed #d1d5db;border-radius:12px;padding:.8rem 1rem;margin-top:.6rem}
  </style>
</head>

<body class="min-h-screen flex flex-col">

  <!-- Header -->
  <header class="header shadow-md text-white">
    <div class="container mx-auto px-6 py-3 topbar">
      <div class="flex items-center gap-3">
        <a href="${ctx}/main" class="flex items-center gap-3 shrink-0">
          <img src="https://cdn-icons-png.flaticon.com/512/2909/2909763.png" class="h-8 w-8" alt="logo"/>
          <span class="hidden sm:inline font-bold">เกษตรกรบ้านเรา</span>
        </a>

        <nav class="nav-scroll ml-2">
          <c:choose>
            <c:when test="${not empty sessionScope.loggedInUser && sessionScope.loggedInUser.status eq 'FARMER'}">
              <div class="flex items-center gap-2 md:gap-3 whitespace-nowrap text-[13px] md:text-sm">
                <a href="${ctx}/product/create" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-plus"></i> สร้างสินค้า</a>
                <a href="${ctx}/farmer/profile" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-store"></i> โปรไฟล์ร้าน</a>
                <a href="${ctx}/product/list/Farmer" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-rectangle-list"></i> สินค้าของฉัน</a>
                <a href="${ctx}/farmer/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-truck"></i> ออเดอร์</a>
              </div>
            </c:when>
            <c:otherwise>
              <div class="flex items-center gap-2 md:gap-3 whitespace-nowrap text-[13px] md:text-sm">
                <a href="${ctx}/main" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-house"></i> หน้าหลัก</a>
                <a href="${ctx}/catalog/list" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-list"></i> สินค้าทั้งหมด</a>
                <a href="${ctx}/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-clock"></i> ประวัติการสั่งจองสินค้า</a>
                <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-basket-shopping"></i> ตะกร้า <span class="badge">${cartCount}</span></a>
              </div>
            </c:otherwise>
          </c:choose>
        </nav>
      </div>

      <form method="get" action="${ctx}/catalog/list" class="justify-self-center lg:justify-self-start w-full max-w-2xl mx-4 hidden sm:block">
        <div class="relative">
          <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-white/70"></i>
          <input name="kw" placeholder="ค้นหาผลผลิต/ร้าน/คำสำคัญ…" class="w-full rounded-lg pl-9 pr-3 py-2 text-white/90 bg-white/10 outline-none focus:ring-2 focus:ring-emerald-400 placeholder-white/70"/>
        </div>
      </form>

      <div class="flex items-center justify-end">
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
              <button id="profileBtn" type="button" onclick="toggleProfileMenu(event)"
                      class="inline-flex items-center ml-2 px-3 py-1 bg-white/20 hover:bg-white/35 backdrop-blur rounded-full text-sm font-medium transition focus:outline-none focus:ring-2 focus:ring-green-300 group"
                      aria-expanded="false" aria-controls="profileMenu">
                <img src="${avatarUrl}?t=${now.time}" alt="โปรไฟล์"
                     class="h-8 w-8 rounded-full border-2 border-white shadow-md mr-2 object-cover"/>
                สวัสดี, ${sessionScope.loggedInUser.fullname}
                <svg class="w-4 h-4 ml-1 text-white transform transition-transform group-hover:rotate-180" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                </svg>
              </button>

              <div id="profileMenu" class="hidden absolute right-0 mt-2 w-56 bg-white text-gray-800 rounded-lg shadow-xl overflow-hidden z-50">
                <ul class="divide-y divide-gray-200">
                  <li>
                    <a href="https://www.blacklistseller.com/report/report_preview/447043" class="flex items-center px-4 py-3 hover:bg-green-50 transition-colors" target="_blank" rel="noopener">
                      <span class="mr-2">❓</span> เช็คบัญชีคนโกง
                    </a>
                  </li>
                  <li>
                    <c:choose>
                      <c:when test="${sessionScope.loggedInUser.status eq 'FARMER'}">
                        <a href="${ctx}/farmer/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50 transition-colors"><span class="mr-2">👨‍🌾</span> แก้ไขโปรไฟล์เกษตรกร</a>
                      </c:when>
                      <c:otherwise>
                        <a href="${ctx}/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50 transition-colors"><span class="mr-2">👤</span> แก้ไขโปรไฟล์ส่วนตัว</a>
                      </c:otherwise>
                    </c:choose>
                  </li>
                  <li>
                    <a href="${ctx}/logout" class="flex items-center px-4 py-3 hover:bg-red-50 transition-colors"><span class="mr-2">🚪</span> ออกจากระบบ</a>
                  </li>
                </ul>
              </div>
            </div>
          </c:when>
          <c:otherwise>
            <a href="${ctx}/login" class="ml-2 bg-emerald-600 hover:bg-emerald-700 px-4 py-1.5 rounded text-white shadow-lg transition">เข้าสู่ระบบ</a>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </header>
  <!-- /Header -->

  <!-- นับสถิติจาก rows -->
  <c:set var="cntAll" value="${fn:length(rows)}"/>
  <c:set var="cntReady" value="0"/>
  <c:set var="cntPre" value="0"/>
  <c:set var="cntOpen" value="0"/>
  <c:set var="cntClose" value="0"/>
  <c:forEach var="pp" items="${rows}">
    <c:if test="${pp.status=='พร้อมสั่งซื้อแล้ว'}"><c:set var="cntReady" value="${cntReady+1}"/></c:if>
    <c:if test="${pp.status=='พรีออเดอร์ได้แล้ว'}"><c:set var="cntPre" value="${cntPre+1}"/></c:if>
    <c:if test="${pp.status=='กำลังผลิต'}"><c:set var="cntOpen" value="${cntOpen+1}"/></c:if>
    <c:if test="${pp.status=='ปิดรับจอง'}"><c:set var="cntClose" value="${cntClose+1}"/></c:if>
  </c:forEach>

  <main class="flex-1">
    <!-- Stats -->
    <div class="container mx-auto px-4 mt-5">
      <div class="grid md:grid-cols-4 gap-4">
        <div class="statX fadeUp">
          <div class="icon ic-emerald"><i class="fa-solid fa-basket-shopping"></i></div>
          <div><div class="ttl">ทั้งหมด</div><div class="num"><c:out value="${cntAll}"/></div></div>
        </div>
        <div class="statX fadeUp" style="animation-delay:.06s">
          <div class="icon ic-sky"><i class="fa-solid fa-truck-ramp-box"></i></div>
          <div><div class="ttl">พร้อมสั่งซื้อแล้ว</div><div class="num text-emerald-600"><c:out value="${cntReady}"/></div></div>
        </div>
        <div class="statX fadeUp" style="animation-delay:.12s">
          <div class="icon ic-amber"><i class="fa-solid fa-seedling"></i></div>
          <div><div class="ttl">พรีออเดอร์ได้แล้ว</div><div class="num text-amber-600"><c:out value="${cntPre}"/></div></div>
        </div>
        <div class="statX fadeUp" style="animation-delay:.18s">
          <div class="icon ic-rose"><i class="fa-solid fa-industry"></i></div>
          <div><div class="ttl">กำลังผลิต</div><div class="num text-rose-600"><c:out value="${cntOpen}"/></div></div>
        </div>
      </div>
    </div>

    <!-- Tools -->
    <div class="container mx-auto px-4 mt-5">
      <div class="tools fadeUp">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex items-center gap-3">
            <h2 class="text-2xl md:text-3xl font-extrabold">สินค้าของฉัน</h2>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <div class="relative">
              <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"></i>
              <input id="q" placeholder="ค้นหาชื่อ/ID…" class="ipt w-64 md:w-80 rounded-lg pl-9 pr-3 text-black outline-none focus:ring-2 focus:ring-emerald-400 border"/>
            </div>
            <select id="sortSel" class="ipt border rounded-lg py-2.5 px-3">
              <option value="latest">ID ใหม่→เก่า</option>
              <option value="name_asc">ชื่อ ก-ฮ</option>
              <option value="name_desc">ชื่อ ฮ-ก</option>
              <option value="price_asc">ราคาต่ำ→สูง</option>
              <option value="price_desc">ราคาสูง→ต่ำ</option>
            </select>
            <a id="btnAdd" class="btn btn-primary" href="${ctx}/product/create"><i class="fa-solid fa-plus"></i> เพิ่มสินค้า</a>
          </div>
        </div>

        <div class="mt-3 flex flex-wrap gap-2">
          <button class="qchip is-active" data-st=""><i class="fa-solid fa-layer-group"></i> ทั้งหมด <span class="count"><c:out value="${cntAll}"/></span></button>
          <button class="qchip" data-st="พรีออเดอร์ได้แล้ว"><i class="fa-solid fa-seedling"></i> พรีออเดอร์ได้แล้ว <span class="count"><c:out value="${cntPre}"/></span></button>
          <button class="qchip" data-st="พร้อมสั่งซื้อแล้ว"><i class="fa-solid fa-circle-check"></i> พร้อมสั่งซื้อแล้ว <span class="count"><c:out value="${cntReady}"/></span></button>
          <button class="qchip" data-st="กำลังผลิต"><i class="fa-solid fa-industry"></i> กำลังผลิต <span class="count"><c:out value="${cntOpen}"/></span></button>
          <button class="qchip" data-st="ปิดรับจอง"><i class="fa-solid fa-lock"></i> ปิดรับจอง <span class="count"><c:out value="${cntClose}"/></span></button>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="container mx-auto px-4 py-6">
      <c:if test="${empty rows}">
        <div class="card p-10 text-center text-gray-600 fadeUp">
          <div class="text-2xl mb-2">ยังไม่มีสินค้า</div>
          <a href="${ctx}/product/create" class="btn btn-primary"><i class="fa-solid fa-plus"></i> เพิ่มสินค้าแรกของคุณ</a>
        </div>
      </c:if>

      <c:if test="${not empty rows}">
        <div id="grid" class="grid sm:grid-cols-2 lg:grid-cols-3 gap-5 stagger">
          <c:forEach var="p" items="${rows}" varStatus="st">
            <!-- URL รูป -->
            <c:set var="imgUrl" value=""/>
            <c:choose>
              <c:when test="${not empty p.img and fn:startsWith(p.img,'http')}"><c:set var="imgUrl" value="${p.img}"/></c:when>
              <c:when test="${not empty p.img and fn:startsWith(p.img,'/uploads/')}"><c:set var="imgUrl" value="${ctx}${p.img}"/></c:when>
              <c:when test="${not empty p.img}"><c:set var="imgUrl" value="${ctx}/uploads/${p.img}"/></c:when>
              <c:otherwise><c:set var="imgUrl" value="https://via.placeholder.com/600x400?text=No+Image"/></c:otherwise>
            </c:choose>

            <!-- อ้างอิง (ออปชัน) -->
            <c:set var="ref" value="${empty refMap ? null : refMap[p.productId]}"/>
            <c:set var="cPer" value="${empty ref ? 0 : (empty ref.perorder ? 0 : ref.perorder)}"/>
            <c:set var="cPre" value="${empty ref ? 0 : (empty ref.preorderdetail ? 0 : ref.preorderdetail)}"/>
            <c:set var="locked" value="${cPer gt 0 or cPre gt 0}"/>

            <!-- สต๊อก -->
            <c:set var="stockVal" value="${empty p.stock ? 0 : p.stock}"/>

            <div class="card p-3 product-card"
                 data-id="${p.productId}"
                 data-name="${fn:escapeXml(p.productname)}"
                 data-status="${fn:escapeXml(p.status)}"
                 data-price="<c:out value='${empty p.price ? 0 : p.price}'/>"
                 data-per="${cPer}" data-pre="${cPre}" data-locked="${locked}"
                 style="animation: fadeUp .45s var(--ease) both; animation-delay:${st.index * 40}ms">

              <div class="imgwrap">
                <img src="${imgUrl}" alt="${p.productname}" loading="lazy"/>
                <c:if test="${not empty p.status}">
                  <div class="badgeX" style="position:absolute; left:10px; top:10px; background:#111827; color:#fff; border-color:transparent">
                    <i class="fa-solid fa-leaf mr-1"></i> <c:out value="${p.status}"/>
                  </div>
                </c:if>
                <c:if test="${locked}">
                  <div class="badgeX badge-lock" style="position:absolute; right:10px; top:10px; background:#ef4444; color:#fff; border-color:transparent" title="ลบไม่ได้: มีรายการอ้างอิง">
                    <i class="fa-solid fa-ban mr-1"></i> มีออเดอร์
                  </div>
                </c:if>
              </div>

              <div class="pt-3">
                <div class="font-semibold line-clamp-2 text-gray-900"><c:out value="${p.productname}"/></div>

                <div class="mt-1 text-emerald-700 font-extrabold text-lg">
                  ฿
                  <c:choose>
                    <c:when test="${not empty p.price}"><fmt:formatNumber value="${p.price}" minFractionDigits="2"/></c:when>
                    <c:otherwise>0.00</c:otherwise>
                  </c:choose>
                </div>

                <div class="mt-1 flex flex-wrap items-center gap-2 text-sm">
                  <span class="badgeX"><i class="fa-regular fa-id-card mr-1"></i>ID: <c:out value="${p.productId}"/></span>
                  <span class="badgeX"><i class="fa-solid fa-weight-scale mr-1"></i>คงเหลือ: <fmt:formatNumber value="${stockVal}" type="number" maxFractionDigits="0" groupingUsed="false"/> กก.</span>
                </div>

                <div class="mt-3 flex flex-wrap items-center gap-2">
                  <a href="${ctx}/catalog/view/${p.productId}" class="btn"><i class="fa-regular fa-eye"></i> ดูหน้า</a>

                  <c:url var="editUrl" value="/edit-product/${p.productId}">
                    <c:param name="back" value="/product/list/Farmer"/>
                  </c:url>
                  <a href="${editUrl}" class="btn btn-primary"><i class="fa-regular fa-pen-to-square"></i> แก้ไข</a>

                  <!-- ปุ่มลบ: แสดงเสมอ (แม้ locked) เพื่อให้เด้งป็อปอัพใหญ่ -->
                  <form class="inline del-form" method="post" action="${ctx}/product/delete">
                    <input type="hidden" name="productId" value="${p.productId}"/>
                    <c:if test="${not empty _csrf}">
                      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
                    </c:if>
                    <button type="button"
                            class="btn btn-danger del-btn"
                            data-name="${fn:escapeXml(p.productname)}"
                            data-locked="${locked}"
                            data-perorder="${cPer}"
                            data-preorderdetail="${cPre}">
                      <i class="fa-solid fa-trash-can"></i> ลบ
                    </button>
                  </form>
                </div>

                <p class="muted text-sm mt-2"><c:out value="${p.description}"/></p>
              </div>
            </div>
          </c:forEach>
        </div>
      </c:if>
    </div>
  </main>

  <!-- Footer -->
  <footer class="footer-dark mt-10">
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
        <a class="btn btn-primary text-white shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <!-- Modal ยืนยันลบ -->
  <div id="delModal" class="fixed inset-0 z-50 hidden">
    <div class="absolute inset-0 bg-black/40"></div>
    <div class="absolute inset-0 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-2xl shadow-2xl border">
        <div class="p-5">
          <div class="flex items-start gap-3">
            <div class="shrink-0 w-10 h-10 rounded-full bg-rose-100 text-rose-600 grid place-items-center">
              <i class="fa-solid fa-triangle-exclamation"></i>
            </div>
            <div>
              <div class="text-lg font-bold">ยืนยันการลบสินค้า</div>
              <div class="text-sm text-gray-600 mt-1">ต้องการลบ <span id="delName" class="font-semibold text-gray-900"></span> ใช่ไหม? การกระทำนี้ไม่สามารถย้อนกลับได้</div>
            </div>
          </div>
          <div class="mt-5 flex justify-end gap-2">
            <button id="delCancel" type="button" class="btn">ยกเลิก</button>
            <button id="delYes" type="button" class="btn btn-danger"><i class="fa-solid fa-trash-can"></i> ลบเลย</button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- BIG Blocked Popup -->
  <div id="blockModal" aria-hidden="true">
    <div class="veil"></div>
    <div class="cardPop" role="dialog" aria-modal="true" aria-labelledby="blkTitle">
      <div class="relative z-10 p-2">
        <div class="flex items-start gap-4">
          <div class="relative shrink-0 w-16 h-16 rounded-full bg-rose-100 text-rose-600 grid place-items-center ringPulse">
            <i class="fa-solid fa-lock fa-lg"></i>
          </div>
          <div class="flex-1">
            <div id="blkTitle" class="text-2xl font-black text-rose-600">ลบสินค้าไม่สำเร็จ</div>
            <div class="mt-1 text-gray-700">
              <span class="font-semibold" id="blockName">-</span> ไม่สามารถลบได้ เนื่องจากมีการสั่งซื้อ (ออเดอร์/พรีออเดอร์) อยู่ในระบบแล้ว
            </div>
            <div id="blockCounts" class="text-sm text-rose-700/90 mt-2 hidden"></div>

            <div class="hint text-sm text-gray-700">
              <div class="font-semibold text-gray-800 mb-1">ไม่สามารถลบได้ </div>
              <ul class="list-disc ml-5 space-y-1">
                <li>เพื่อความถูกต้องของประวัติคำสั่งซื้อและความปลอดภัย ระบบไม่เปิดให้ลบสินค้าออกจากระบบ</li>
                <li>พิจารณา <b>ปิดรับจอง</b> หรือ <b>ซ่อนจากแคตตาล็อก</b> แทนการลบ</li>
              </ul>
            </div>

            <div class="mt-4 flex flex-wrap gap-2">
              <a id="goOrdersBtn" href="${ctx}/farmer/orders" class="btn"><i class="fa-solid fa-receipt"></i> ดูออเดอร์ที่เกี่ยวข้อง</a>
              <button id="blockOk" type="button" class="btn btn-primary"><i class="fa-regular fa-circle-xmark"></i> ปิด</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Big Success Popup -->
  <div id="okpop" class="okpop" aria-hidden="true">
    <div class="okveil"></div>
    <div class="okcard">
      <div class="oktop">
        <div class="okicon"><i class="fa-solid fa-check fa-2xl"></i></div>
        <div class="oktitle">ลบสินค้าสำเร็จ</div>
        <div class="okdesc">ระบบกำลังอัปเดตรายการของคุณ…</div>
      </div>
    </div>
  </div>

  <!-- Toast holder -->
  <div id="toasts" class="fixed right-4 bottom-4 flex flex-col gap-2 z-50"></div>

  <!-- Scripts -->
  <script>
    const ctx='${ctx}';

    // โปรไฟล์เมนู
    function toggleProfileMenu(e){
      e && e.stopPropagation();
      const m=document.getElementById('profileMenu');
      const b=document.getElementById('profileBtn');
      if(!m||!b) return;
      const hidden=m.classList.toggle('hidden');
      b.setAttribute('aria-expanded', hidden?'false':'true');
    }
    document.addEventListener('click',(e)=>{
      const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return;
      if(!b.contains(e.target) && !m.contains(e.target)){
        m.classList.add('hidden'); b.setAttribute('aria-expanded','false');
      }
    });

    // ฟิลเตอร์/ค้นหา/เรียง
    const q=document.getElementById('q');
    const sortSel=document.getElementById('sortSel');
    const chips=[...document.querySelectorAll('.qchip[data-st]')];
    let statusFilter='';

    function applyFilter(){
      const kw=(q.value||'').trim().toLowerCase();
      document.querySelectorAll('#grid .product-card').forEach(card=>{
        const name=(card.dataset.name||'').toLowerCase();
        const id=(card.dataset.id||'').toLowerCase();
        const st=(card.dataset.status||'').trim();
        const passKw=!kw || name.includes(kw) || id.includes(kw);
        const passSt=!statusFilter || st===statusFilter;
        card.style.display=(passKw && passSt)?'':'none';
      });
    }
    function applySort(){
      const by=sortSel.value;
      const grid=document.getElementById('grid'); if(!grid) return;
      const cards=[...grid.children];
      cards.sort((a,b)=>{
        const pa=parseFloat(a.dataset.price||'0'), pb=parseFloat(b.dataset.price||'0');
        const na=(a.dataset.name||'').localeCompare(b.dataset.name||'th');
        const idA=(a.dataset.id||''), idB=(b.dataset.id||'');
        switch(by){
          case 'price_asc':  return pa - pb;
          case 'price_desc': return pb - pa;
          case 'name_asc':   return na;
          case 'name_desc':  return -na;
          default:           return idB.localeCompare(idA);
        }
      });
      cards.forEach(c=>grid.appendChild(c));
    }
    chips.forEach(ch=>{
      ch.addEventListener('click', ()=>{
        chips.forEach(c=>c.classList.remove('is-active'));
        ch.classList.add('is-active');
        statusFilter = ch.dataset.st || '';
        applyFilter();
      });
    });
    q?.addEventListener('input', applyFilter);
    sortSel?.addEventListener('change', applySort);
    window.addEventListener('load', applySort);

    // Toast
    function toast(msg, ok=true){
      const wrap = document.getElementById('toasts') || (()=>{ const d=document.createElement('div'); d.id='toasts'; d.className='fixed right-4 bottom-4 flex flex-col gap-2 z-50'; document.body.appendChild(d); return d; })();
      while (wrap.children.length >= 3) wrap.removeChild(wrap.firstChild);
      const el = document.createElement('div');
      el.className = 'toast px-4 py-2 rounded-xl shadow-lg text-white ' + (ok?'bg-gray-900':'bg-red-600');
      el.textContent = msg;
      wrap.appendChild(el);
      setTimeout(()=>{ el.style.opacity='0'; el.style.transform='translateY(6px)'; setTimeout(()=>el.remove(),180); }, 2600);
    }

    // ===== Blocked Popup helpers =====
    const blockModal=document.getElementById('blockModal');
    const blockOk=document.getElementById('blockOk');
    const blockName=document.getElementById('blockName');
    const blockCounts=document.getElementById('blockCounts');
    function openBlockModal(opts){
      const name = opts?.name || 'สินค้านี้';
      const per  = parseInt(opts?.per||0,10);
      const pre  = parseInt(opts?.pre||0,10);
      blockName.textContent = name;
      const hasCount = (per>0 || pre>0);
      blockCounts.classList.toggle('hidden', !hasCount);
      if(hasCount){ blockCounts.textContent = 'อ้างอิง: perorder '+per+' รายการ • preorderdetail '+pre+' รายการ'; }
      blockModal.classList.add('show');
      blockModal.setAttribute('aria-hidden','false');
      document.body.classList.add('overflow-hidden');
    }
    function closeBlockModal(){
      blockModal.classList.remove('show');
      blockModal.setAttribute('aria-hidden','true');
      document.body.classList.remove('overflow-hidden');
    }
    blockOk?.addEventListener('click', closeBlockModal);
    blockModal?.addEventListener('click', (e)=>{ if(e.target===blockModal || e.target.classList.contains('veil')) closeBlockModal(); });

    // ===== Confirm Delete Modal =====
    let currentDelForm=null, currentCard=null, currentName='', currentId='';
    const delModal=document.getElementById('delModal');
    const delNameEl=document.getElementById('delName');
    const delCancel=document.getElementById('delCancel');
    const delYes=document.getElementById('delYes');
    const okpopEl=document.getElementById('okpop');
    function openDelModal(){ delModal.classList.remove('hidden'); }
    function closeDelModal(){ delModal.classList.add('hidden'); }
    function showOK(){ okpopEl?.classList.add('show'); }

    // คลิกปุ่มลบ
    document.querySelectorAll('.del-btn').forEach(btn=>{
      btn.addEventListener('click', ()=>{
        const form=btn.closest('form.del-form');
        const card=btn.closest('.product-card');
        const name=btn.getAttribute('data-name')||'สินค้านี้';
        const per = parseInt(btn.getAttribute('data-perorder')||card?.dataset.per||'0',10);
        const pre = parseInt(btn.getAttribute('data-preorderdetail')||card?.dataset.pre||'0',10);
        const lockedAttr = String(btn.getAttribute('data-locked')||card?.dataset.locked||'').toLowerCase()==='true';
        const locked = lockedAttr || per>0 || pre>0;

        currentDelForm=form; currentCard=card; currentName=name; currentId=card?.dataset.id||'';
        if(locked){
          // ถ้ารู้อยู่แล้วว่าลบไม่ได้ → เด้งป็อปอัพใหญ่ทันที
          openBlockModal({name, per, pre});
          return;
        }
        // ไม่ล็อก → เด้งยืนยันก่อน
        if(delNameEl) delNameEl.textContent=name;
        openDelModal();
      });
    });

    delCancel?.addEventListener('click', closeDelModal);
    delModal?.addEventListener('click', (e)=>{ if(e.target===delModal) closeDelModal(); });
    document.addEventListener('keydown', (e)=>{ if(e.key==='Escape'){ closeDelModal(); closeBlockModal(); }});

    // ยิงลบแบบระวังสุด → ถ้าไม่ใช่ OK ชัดเจน ให้ถือเป็น BLOCKED แล้วโชว์ป็อปอัพใหญ่
    delYes?.addEventListener('click', async ()=>{
      if(!currentDelForm) return;
      try{
        const base = currentDelForm.getAttribute('action') || (ctx + '/product/delete');
        const url  = base + (base.includes('?')?'&':'?') + 'ajax=1';
        const fd   = new FormData(currentDelForm);

        const res = await fetch(url, { method:'POST', headers:{'Accept':'application/json, text/plain, */*'}, body:fd });
        const ct  = (res.headers.get('content-type')||'').toLowerCase();

        let isOK=false, status='fail', per=0, pre=0;
        if(ct.includes('application/json')){
          const data = await res.json().catch(()=>({}));
          status = String(data.status||'').toLowerCase();
          isOK   = (status==='ok');
          per = data.perorder||0; pre=data.preorderdetail||0;
        }else{
          const t = (await res.text()).trim().toLowerCase();
          isOK = (t==='ok') || t.includes('"status":"ok"');
          if(/(blocked|มีออเดอร์|ลบไม่ได้|อ้างอิง)/.test(t)) status='blocked';
          else if(t.includes('notfound')) status='notfound';
          else if(t.includes('noauth')) status='noauth';
        }
        if(res.status>=400) isOK=false;

        closeDelModal();

        if(isOK){
          if(currentCard) currentCard.remove();
          showOK();
          setTimeout(()=>{ location.href = ctx + '/product/list/Farmer?del=ok'; }, 900);
          return;
        }

        if(status==='notfound'){
          if(currentCard) currentCard.remove();
          toast('ไม่พบสินค้า — อัปเดตรายการแล้ว');
          setTimeout(()=>{ location.href = ctx + '/product/list/Farmer?del=notfound'; }, 600);
          return;
        }
        if(status==='noauth'){
          toast('ไม่สามารถลบ: ไม่มีสิทธิ์', false);
          return;
        }

        // ทุกกรณีที่ไม่ใช่ OK → โชว์ป็อปอัพใหญ่
        openBlockModal({
          name: currentName,
          per: per || parseInt(currentCard?.dataset.per||'0',10),
          pre: pre || parseInt(currentCard?.dataset.pre||'0',10)
        });
      }catch(e){
        closeDelModal();
        openBlockModal({name: currentName}); // เครือข่ายพังก็ให้ขึ้นใหญ่ไปเลย
      }
    });

    // Flash/Query param
    (function(){
      const params = new URLSearchParams(location.search);
      if(params.get('del')==='ok'){ toast('ลบสินค้าสำเร็จ'); }
      if(params.get('del')==='noauth'){ toast('ไม่สามารถลบ: ไม่มีสิทธิ์', false); }
      if(params.get('del')==='notfound'){ toast('ไม่พบสินค้า', false); }
      if(params.get('del')==='fail'){ toast('ลบไม่สำเร็จ', false); }
    })();
  </script>

  <!-- Flash (ถ้ามี) -->
  <c:if test="${not empty msg}"><script>toast('<c:out value="${msg}"/>');</script></c:if>
  <c:if test="${not empty error}"><script>toast('<c:out value="${error}"/>', false);</script></c:if>

</body>
</html>
