<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />

<c:set var="page" value="${empty page ? (empty param.page ? 1 : param.page) : page}" />
<c:set var="size" value="${empty size ? (empty param.size ? 12 : param.size) : size}" />
<c:set var="kw" value="${empty kw ? param.kw : kw}" />
<c:set var="categoryId" value="${empty categoryId ? param.categoryId : categoryId}" />
<c:set var="min" value="${empty min ? param.min : min}" />
<c:set var="max" value="${empty max ? param.max : max}" />
<c:set var="sort" value="${empty sort ? (empty param.sort ? 'latest' : param.sort) : sort}" />

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>สินค้าทั้งหมด • เกษตรกรบ้านเรา</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --ease:cubic-bezier(.22,.8,.2,1); --border:#e5e7eb }
    html,body{font-family:'Prompt',system-ui,-apple-system,Segoe UI,Roboto,Arial}
    body{background:#f8fafc; color:#0f172a}

    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    .card { background:#fff; border:1px solid var(--border); border-radius:16px; box-shadow:0 10px 26px rgba(0,0,0,.06) }
    .imgwrap{ aspect-ratio:4/3; overflow:hidden; border-radius:12px; border:1px solid #eef; position:relative }
    .imgwrap img{ width:100%; height:100%; object-fit:cover; display:block; transition:transform .35s var(--ease) }
    .product-card:hover .imgwrap img{ transform:scale(1.04) }
    .badgeX { font-size:.75rem; border:1px solid #e5e7eb; border-radius:9999px; padding:.15rem .55rem; background:#fff }
    .muted { color:#6b7280 }
    .btn{display:inline-flex;align-items:center;gap:.5rem;padding:.6rem .9rem;border-radius:12px;border:1px solid #e5e7eb;background:#fff;transition:transform .12s var(--ease), box-shadow .2s var(--ease), border-color .2s var(--ease)}
    .btn:hover{transform:translateY(-1px); box-shadow:0 10px 20px rgba(16,185,129,.12); border-color:#d1fae5}
    .btn i{font-size:.95rem}
    .btn-primary{ background:linear-gradient(135deg,#10b981,#059669); color:#fff; border-color:transparent }
    .btn-primary:disabled{ opacity:.55; cursor:not-allowed; }

    .chip { position:absolute; left:10px; top:10px; padding:.35rem .55rem; font-size:.75rem; border-radius:9999px; color:#fff; display:flex; align-items:center; gap:.4rem; box-shadow:0 8px 16px rgba(0,0,0,.12) }
    .chip-emerald{ background:#059669 }
    .chip-sky{ background:#0284c7 }
    .chip-gray{ background:#6b7280 }
    .chip-rose{ background:#dc2626 }

    @keyframes fadeUp { from{opacity:0; transform:translateY(12px)} to{opacity:1; transform:none} }
    .fadeUp{ animation: fadeUp .5s var(--ease) both }
    .stagger > *{ animation: fadeUp .55s var(--ease) both }
    .stagger > *:nth-child(1){ animation-delay:.02s }
    .stagger > *:nth-child(2){ animation-delay:.05s }
    .stagger > *:nth-child(3){ animation-delay:.08s }
    .stagger > *:nth-child(4){ animation-delay:.11s }
    .stagger > *:nth-child(5){ animation-delay:.14s }
    .stagger > *:nth-child(6){ animation-delay:.17s }
    .stagger > *:nth-child(7){ animation-delay:.20s }
    .stagger > *:nth-child(8){ animation-delay:.23s }
    .stagger > *:nth-child(9){ animation-delay:.26s }
    .stagger > *:nth-child(10){ animation-delay:.29s }

    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }

    /* รองรับ line-clamp-2 บน CDN */
    .line-clamp-2{ display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden }
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

      <!-- IMPORTANT: ค้นหาบนหน้านี้ให้ชี้ /preorder/catalog/list -->
      <form method="get" action="${ctx}/preorder/catalog/list" class="justify-self-center lg:justify-self-start w-full max-w-2xl mx-4 hidden sm:block">
        <input type="hidden" name="categoryId" value="${categoryId}"/>
        <input type="hidden" name="min" value="${min}"/>
        <input type="hidden" name="max" value="${max}"/>
        <input type="hidden" name="sort" value="${sort}"/>
        <input type="hidden" name="page" value="${page}"/>
        <input type="hidden" name="size" value="${size}"/>
        <div class="relative">
          <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-white/70"></i>
          <input name="kw" value="${kw}" placeholder="ค้นหาผลผลิต/ร้าน/คำสำคัญ…"
                 class="w-full rounded-lg pl-9 pr-3 py-2 text-white/90 bg-white/10 outline-none focus:ring-2 focus:ring-emerald-400 placeholder-white/70"/>
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

  <div class="container mx-auto px-4">
    <c:if test="${not empty error}">
      <div class="mt-4 px-4 py-2 rounded border border-red-200 bg-red-50 text-red-700 fadeUp">✖ ${error}</div>
    </c:if>
    <c:if test="${not empty msg}">
      <div class="mt-4 px-4 py-2 rounded border border-emerald-200 bg-emerald-50 text-emerald-800 fadeUp">✓ ${msg}</div>
    </c:if>
  </div>

  <main class="flex-1">
    <div class="container mx-auto px-4 py-6 grid grid-cols-12 gap-6">
      <!-- Sidebar -->
      <aside class="col-span-12 md:col-span-3 space-y-4">
        <div class="card p-4 fadeUp">
          <h3 class="font-bold mb-2">หมวดหมู่</h3>
          <select id="catSel" class="w-full border rounded-lg py-2.5 px-3"
                  onchange="applyFilter({categoryId:this.value,page:1})">
            <option value="">ทั้งหมด</option>
            <c:forEach var="cat" items="${categories}">
              <option value="${cat.categoryId}" <c:if test="${categoryId == cat.categoryId}">selected</c:if>>
                <c:out value="${empty cat.name ? cat.categoryId : cat.name}"/>
              </option>
            </c:forEach>
          </select>
        </div>

        <div class="card p-4 fadeUp">
          <h3 class="font-bold mb-2">ช่วงราคา</h3>
          <label class="flex gap-2 items-center mb-1"><input type="checkbox" class="pricechk" data-min="0"  data-max="50"> ฿0 - ฿50</label>
          <label class="flex gap-2 items-center mb-1"><input type="checkbox" class="pricechk" data-min="50" data-max="100"> ฿50 - ฿100</label>
          <label class="flex gap-2 items-center"><input type="checkbox" class="pricechk" data-min="100" data-max=""> ฿100 ขึ้นไป</label>
          <div class="mt-3 flex gap-2">
            <input id="minBox" type="number" step="0" min="0" placeholder="min" value="${min}" class="w-full border rounded px-2 py-1.5">
            <input id="maxBox" type="number" step="0" min="0" placeholder="max" value="${max}" class="w-full border rounded px-2 py-1.5">
          </div>
          <button class="mt-2 w-full border rounded-lg py-2 hover:bg-gray-50"
                  onclick="applyFilter({min:document.getElementById('minBox').value,max:document.getElementById('maxBox').value,page:1})">
            ใช้ช่วงราคา
          </button>
        </div>

        <div class="card p-4 fadeUp">
          <h3 class="font-bold mb-2">สถานะสินค้า (กรองบนหน้า)</h3>
          <label class="flex gap-2 items-center mb-1"><input type="checkbox" class="statuschk all" value=""> ทั้งหมด</label>
          <label class="flex gap-2 items-center mb-1"><input type="checkbox" class="statuschk" value="พรีออเดอร์ได้แล้ว"> พรีออเดอร์ได้แล้ว</label>
          <label class="flex gap-2 items-center mb-1"><input type="checkbox" class="statuschk" value="พร้อมสั่งซื้อแล้ว"> พร้อมสั่งซื้อแล้ว</label>
          <label class="flex gap-2 items-center mb-1"><input type="checkbox" class="statuschk" value="กำลังผลิต"> กำลังผลิต</label>
          <label class="flex gap-2 items-center"><input type="checkbox" class="statuschk" value="ปิดรับจอง"> ปิดรับจอง</label>
          <p class="text-xs muted mt-2">* ต้องการกรองจากฐานข้อมูลจริง ให้เพิ่มเงื่อนไขฝั่ง Service/Controller</p>
        </div>
      </aside>

      <!-- Products -->
      <section class="col-span-12 md:col-span-9">
        <div class="flex items-center justify-between mb-3 fadeUp">
          <h2 class="text-xl font-bold">สินค้าทั้งหมด</h2>
          <div class="flex items-center gap-2">
            <span class="text-sm muted hidden md:inline">เรียงตาม</span>
            <!-- ใช้ client-side sort -->
            <select id="sortSel" class="border rounded-lg py-2.5 px-3">
              <option value="latest"     <c:if test="${sort=='latest'}">selected</c:if>>ล่าสุด</option>
              <option value="price_asc"  <c:if test="${sort=='price_asc'}">selected</c:if>>ราคาต่ำ→สูง</option>
              <option value="price_desc" <c:if test="${sort=='price_desc'}">selected</c:if>>ราคาสูง→ต่ำ</option>
              <option value="name_asc"   <c:if test="${sort=='name_asc'}">selected</c:if>>ชื่อ ก-ฮ</option>
              <option value="name_desc"  <c:if test="${sort=='name_desc'}">selected</c:if>>ชื่อ ฮ-ก</option>
            </select>
          </div>
        </div>

        <c:choose>
          <c:when test="${empty products}">
            <div class="card p-8 text-center muted fadeUp">ยังไม่มีสินค้า</div>
          </c:when>
          <c:otherwise>
            <div id="grid" class="grid sm:grid-cols-2 lg:grid-cols-3 gap-5 stagger">
              <c:forEach var="p" items="${products}" varStatus="st">
                <c:set var="pid" value="${p.productId}"/>
                <c:set var="pname" value="${p.productname}"/>
                <c:set var="price" value="${empty p.price ? 0 : p.price}"/>
                <c:set var="status" value="${p.status}"/>
                <c:set var="stockNum" value="${empty p.stock ? 0 : p.stock}"/>

                <%-- เลือกรูปจากหลายฟิลด์: img, imageUrl, imageURL, image, imagePath --%>
                <c:set var="rawImg0" value="${p.img}" />
                <c:if test="${empty rawImg0}"><c:set var="rawImg0" value="${p.imageUrl}" /></c:if>
                <c:if test="${empty rawImg0}"><c:set var="rawImg0" value="${p.imageURL}" /></c:if>
                <c:if test="${empty rawImg0}"><c:set var="rawImg0" value="${p.image}" /></c:if>
                <c:if test="${empty rawImg0}"><c:set var="rawImg0" value="${p.imagePath}" /></c:if>

                <%-- เดา URL เบื้องต้นฝั่งเซิร์ฟเวอร์ เพื่อช่วยให้โหลดติดในทีแรก --%>
                <c:set var="rawNorm" value="${fn:replace(empty rawImg0 ? '' : rawImg0, '\\\\', '/')}" />
                <c:set var="imgGuess" value="" />
                <c:choose>
                  <c:when test="${not empty rawNorm and fn:startsWith(rawNorm,'http')}">
                    <c:set var="imgGuess" value="${rawNorm}" />
                  </c:when>
                  <c:when test="${not empty rawNorm and fn:startsWith(rawNorm,'/uploads/')}">
                    <c:set var="imgGuess" value="${ctx}${rawNorm}" />
                  </c:when>
                  <c:when test="${not empty rawNorm and fn:startsWith(rawNorm,'uploads/')}">
                    <c:set var="imgGuess" value="${ctx}/${rawNorm}" />
                  </c:when>
                  <c:when test="${not empty rawNorm and fn:contains(rawNorm,'/uploads/')}">
                    <c:set var="iUp" value="${fn:indexOf(rawNorm,'/uploads/')}" />
                    <c:set var="pathAfter" value="${fn:substring(rawNorm, iUp, fn:length(rawNorm))}" />
                    <c:set var="imgGuess" value="${ctx}${pathAfter}" />
                  </c:when>
                </c:choose>

                <%-- ชื่อหมวดหมู่ --%>
                <c:set var="catName" value="${p.categoryId}"/>
                <c:forEach var="cat" items="${categories}">
                  <c:if test="${cat.categoryId == p.categoryId}">
                    <c:set var="catName" value="${empty cat.name ? p.categoryId : cat.name}"/>
                  </c:if>
                </c:forEach>

                <%-- อนุญาตซื้อ --%>
                <c:set var="okStatus" value="${status eq 'พรีออเดอร์ได้แล้ว' or status eq 'พร้อมสั่งซื้อแล้ว' or status eq 'พร้อมส่ง'}"/>
                <c:set var="denyStatus" value="${status eq 'กำลังผลิต' or status eq 'ปิดรับจอง'}"/>
                <c:set var="allowBuy" value="${okStatus and (not denyStatus) and (stockNum gt 0)}"/>

                <%-- สีชิป --%>
                <c:set var="chipClass" value="chip-gray"/>
                <c:choose>
                  <c:when test="${status eq 'พรีออเดอร์ได้แล้ว'}"><c:set var="chipClass" value="chip-emerald"/></c:when>
                  <c:when test="${status eq 'พร้อมสั่งซื้อแล้ว' or status eq 'พร้อมส่ง'}"><c:set var="chipClass" value="chip-sky"/></c:when>
                  <c:when test="${status eq 'ปิดรับจอง'}"><c:set var="chipClass" value="chip-rose"/></c:when>
                  <c:when test="${status eq 'กำลังผลิต'}"><c:set var="chipClass" value="chip-gray"/></c:when>
                </c:choose>

                <!-- การ์ดสินค้า -->
                <div class="card p-3 product-card"
                     data-status="${fn:escapeXml(status)}"
                     data-price="${price}"
                     data-name="${fn:toLowerCase(fn:escapeXml(pname))}"
                     data-order="${st.index}"
                     style="animation-delay:${st.index * 40}ms">
                  <div class="imgwrap">
                    <a href="${ctx}/catalog/view/${pid}" class="block" aria-label="ดูสินค้า: ${fn:escapeXml(pname)}">
                      <img class="prod-img"
                           data-raw="${fn:escapeXml(rawImg0)}"
                           data-guess="${fn:escapeXml(imgGuess)}"
                           src="https://via.placeholder.com/600x400?text=No+Image"
                           alt="${fn:escapeXml(pname)}"
                           loading="lazy"
                           referrerpolicy="no-referrer"
                           onerror="this.onerror=null;this.src='https://via.placeholder.com/600x400?text=No+Image'"/>
                    </a>
                    <c:if test="${not empty status}">
                      <div class="chip ${chipClass}">
                        <i class="fa-solid fa-leaf"></i>
                        <span>${status}</span>
                      </div>
                    </c:if>
                  </div>

                  <div class="pt-3">
                    <a href="${ctx}/catalog/view/${pid}" class="font-semibold hover:underline line-clamp-2 text-gray-900">
                      <c:out value="${pname}"/>
                    </a>

                    <div class="mt-1 text-emerald-700 font-extrabold">
                      ฿ <fmt:formatNumber value="${price}" minFractionDigits="2"/>
                    </div>

                    <div class="mt-1 flex flex-wrap items-center gap-2 text-sm">
                      <span class="badgeX"><i class="fa-regular fa-folder-open mr-1"></i><c:out value="${catName}"/></span>
                      <span class="badgeX"><i class="fa-solid fa-weight-scale mr-1"></i>คงเหลือ: <fmt:formatNumber value="${stockNum}" type="number" maxFractionDigits="0" groupingUsed="false"/> กก.</span>
                      <span class="badgeX">
                        <c:choose>
                          <c:when test="${allowBuy}"><i class="fa-solid fa-circle-check mr-1 text-emerald-500"></i>พร้อม</c:when>
                          <c:otherwise><i class="fa-solid fa-circle-xmark mr-1 text-rose-500"></i>หมด</c:otherwise>
                        </c:choose>
                      </span>
                    </div>

                    <div class="mt-3 flex items-center gap-2">
                      <a href="${ctx}/catalog/view/${pid}" class="btn"><i class="fa-regular fa-eye"></i> ดูสินค้า</a>
                      <form action="${ctx}/cart/add" method="post" class="inline" onsubmit="return true;">
                        <input type="hidden" name="productId" value="${pid}">
                        <input type="hidden" name="qty" value="1">
                        <button type="submit" class="btn btn-primary" <c:if test="${!allowBuy}">disabled</c:if>>
                          <i class="fa-solid fa-cart-plus"></i> หยิบใส่ตะกร้า
                        </button>
                      </form>
                    </div>

                    <p class="muted text-sm mt-2 line-clamp-2"><c:out value="${p.description}"/></p>
                  </div>
                </div>
              </c:forEach>
            </div>

            <!-- Pagination -->
            <div class="flex items-center justify-center gap-2 mt-6 fadeUp">
              <c:set var="hasPrev" value="${page > 1}"/>
              <c:set var="hasNext" value="${not empty products and fn:length(products) >= size}"/>

              <button class="px-3 py-1.5 rounded border bg-white hover:bg-gray-50"
                      onclick="gotoPage(${page-1})" <c:if test="${!hasPrev}">disabled</c:if>>ก่อนหน้า</button>

              <c:set var="p1" value="${page-1}"/>
              <c:set var="p2" value="${page}"/>
              <c:set var="p3" value="${page+1}"/>

              <c:if test="${p1 >= 1}">
                <button class="px-3 py-1.5 rounded border bg-white hover:bg-gray-50" onclick="gotoPage(${p1})">${p1}</button>
              </c:if>
              <button class="px-3 py-1.5 rounded border bg-emerald-600 text-white">${p2}</button>
              <c:if test="${hasNext}">
                <button class="px-3 py-1.5 rounded border bg-white hover:bg-gray-50" onclick="gotoPage(${p3})">${p3}</button>
              </c:if>

              <button class="px-3 py-1.5 rounded border bg-white hover:bg-gray-50"
                      onclick="gotoPage(${page+1})" <c:if test="${!hasNext}">disabled</c:if>>ถัดไป</button>
            </div>
          </c:otherwise>
        </c:choose>
      </section>
    </div>
  </main>

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

  <!-- Floating: เช็คบัญชีคนโกง (ขวาล่าง) -->
  <a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50"
     href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
    <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
  </a>

  <!-- Hidden filter form (ใช้รักษา state/URL) — ชี้กลับมาหน้านี้ -->
  <form id="flt" method="get" action="${ctx}/preorder/catalog/list" class="hidden">
    <input type="hidden" name="kw" value="${kw}">
    <input type="hidden" name="categoryId" value="${categoryId}">
    <input type="hidden" name="min" value="${min}">
    <input type="hidden" name="max" value="${max}">
    <input type="hidden" name="sort" value="${sort}">
    <input type="hidden" name="page" value="${page}">
    <input type="hidden" name="size" value="${size}">
  </form>

  <script>
    /* ===== โปรไฟล์เมนู ===== */
    function toggleProfileMenu(e){
      e && e.stopPropagation();
      const m = document.getElementById('profileMenu');
      const b = document.getElementById('profileBtn');
      if(!m || !b) return;
      const hidden = m.classList.toggle('hidden');
      b.setAttribute('aria-expanded', hidden ? 'false' : 'true');
    }
    document.addEventListener('click',(e)=>{
      const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return;
      if(!b.contains(e.target) && !m.contains(e.target)){
        m.classList.add('hidden'); b.setAttribute('aria-expanded','false');
      }
    });
    document.addEventListener('keydown',(e)=>{
      if(e.key==='Escape'){
        const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
        if(m) m.classList.add('hidden'); if(b) b.setAttribute('aria-expanded','false');
      }
    });

    /* ===== helper ===== */
    function setHidden(name, val){ const inp=document.querySelector('#flt [name="'+name+'"]'); if(inp) inp.value = (val ?? ''); }
    function applyFilter(obj){
      if(obj.kw !== undefined) setHidden('kw', obj.kw);
      if(obj.categoryId !== undefined) setHidden('categoryId', obj.categoryId);
      if(obj.min !== undefined) setHidden('min', obj.min);
      if(obj.max !== undefined) setHidden('max', obj.max);
      if(obj.sort !== undefined) setHidden('sort', obj.sort);
      if(obj.page !== undefined) setHidden('page', obj.page);
      if(obj.size !== undefined) setHidden('size', obj.size);
      document.getElementById('flt').submit();
    }
    function gotoPage(p){ applyFilter({page:p}); }
    function updateUrlParams(kv){
      const url = new URL(window.location);
      Object.keys(kv).forEach(k => { if(kv[k]===null || kv[k]===''){ url.searchParams.delete(k); } else { url.searchParams.set(k, kv[k]); }});
      history.replaceState(null, '', url);
    }

    /* ===== กรองสถานะบนหน้า ===== */
    (function statusFilter(){
      const all = document.querySelector('.statuschk.all');
      const cbs = Array.from(document.querySelectorAll('.statuschk')).filter(x=>!x.classList.contains('all'));
      function apply(){
        const chosen = new Set(cbs.filter(cb=>cb.checked).map(cb=>cb.value));
        const cards = document.querySelectorAll('.product-card');
        let anyShow=false;
        cards.forEach(card=>{
          if(all.checked || chosen.size===0){ card.style.display=''; anyShow=true; return; }
          const st = (card.getAttribute('data-status')||'').trim();
          const show = chosen.has(st);
          card.style.display = show ? '' : 'none';
          if(show) anyShow=true;
        });
        let emptyMsg = document.getElementById('emptyLocalFilter');
        if(!anyShow){
          if(!emptyMsg){
            emptyMsg = document.createElement('div');
            emptyMsg.id='emptyLocalFilter';
            emptyMsg.className='card p-6 text-center muted mt-4';
            emptyMsg.textContent='ไม่พบสินค้าตรงกับตัวกรองบนหน้า';
            document.getElementById('grid')?.after(emptyMsg);
          }
        }else{
          emptyMsg && emptyMsg.remove();
        }
      }
      if(all){ all.checked = true; }
      cbs.forEach(cb=>cb.addEventListener('change',()=>{
        all.checked = cbs.every(x=>!x.checked);
        apply();
      }));
      all && all.addEventListener('change', ()=>{ if(all.checked){ cbs.forEach(x=>x.checked=false); } apply(); });
      apply();
    })();

    /* ===== ช่วงราคาแบบคลิกเดียว ===== */
    (function pricePreset(){
      const minNow = '${min}' || '';
      const maxNow = '${max}' || '';
      document.querySelectorAll('.pricechk').forEach(ch=>{
        const mn = ch.dataset.min ?? '', mx = ch.dataset.max ?? '';
        ch.checked = (String(minNow)===String(mn) && String(maxNow)===String(mx));
        ch.addEventListener('change', ()=>{
          document.querySelectorAll('.pricechk').forEach(c=>{ if(c!==ch) c.checked=false; });
          const m1 = ch.checked ? ch.dataset.min : '';
          const m2 = ch.checked ? ch.dataset.max : '';
          document.getElementById('minBox').value = m1 || '';
          document.getElementById('maxBox').value = m2 || '';
          applyFilter({min:m1, max:m2, page:1});
        });
      });
    })();

    /* ===== ซ่อม URL รูปภาพอัตโนมัติ (เวอร์ชัน robust เฉพาะหน้านี้) ===== */
    (function fixProductImages(){
      const ctx = '${ctx}';              // context root ของแอป
      const ts  = '${now.time}';         // กัน cache
      const imgs = document.querySelectorAll('img.prod-img');

      imgs.forEach(img=>{
        const clean = s => (s||'').trim().replace(/^['"]|['"]$/g,'').replace(/\\/g,'/');
        let raw   = clean(img.getAttribute('data-raw'));
        let guess = clean(img.getAttribute('data-guess'));

        if(!raw && !guess) return;

        if(/^data:image\//i.test(raw)){ img.src = raw; return; }
        if(/^data:image\//i.test(guess)){ img.src = guess; return; }

        const toUploads = s => {
          const f = clean(s).split('/').pop();
          return f ? (ctx + '/uploads/' + f) : '';
        };

        const cand = [];
        if(guess) cand.push(guess);

        if(/^https?:\/\//i.test(raw)) cand.push(raw);
        if(/^\/uploads\//i.test(raw)) cand.push(ctx + raw);
        if(/^uploads\//i.test(raw))   cand.push(ctx + '/' + raw);

        const iUp = raw.toLowerCase().indexOf('/uploads/');
        if(iUp >= 0) cand.push(ctx + raw.slice(iUp));

        if(/^file:\/\//i.test(raw)) cand.push(toUploads(raw));
        if(/^[a-z]:\//i.test(raw))  cand.push(toUploads(raw));
        if(!/^https?:\/\//i.test(raw)
          && !/^\/uploads\//i.test(raw)
          && !/^uploads\//i.test(raw)) {
          cand.push(toUploads(raw));
        }

        if(guess && !/^https?:\/\//i.test(guess) && !/^\/uploads\//i.test(guess))
          cand.push(toUploads(guess));

        const seen = new Set();
        const list = cand.filter(u=>{
          if(!u) return false;
          const k = u.toLowerCase();
          if(seen.has(k)) return false;
          seen.add(k);
          return true;
        });

        tryLoad(0);
        function tryLoad(i){
          if(i >= list.length){
            img.src='https://via.placeholder.com/600x400?text=No+Image';
            return;
          }
          const base = list[i];
          const url  = base + (base.includes('?')?'&':'?') + 't=' + ts;

          const probe = new Image();
          probe.onload  = ()=>{ img.src = url; };
          probe.onerror = ()=> tryLoad(i+1);
          probe.referrerPolicy = 'no-referrer';
          probe.src = url;
        }
      });
    })();

    /* ===== เรียงตาม (Client-side guaranteed) ===== */
    function sortGrid(key, isInit){
      const grid = document.getElementById('grid');
      if(!grid) return;
      const items = Array.from(grid.children);
      items.forEach((el,idx)=>{ if(!el.dataset.orig) el.dataset.orig = String(idx); });

      let coll = items.filter(el => el.style.display !== 'none');
      let hidden = items.filter(el => el.style.display === 'none');

      const parseNum = v => {
        const n = parseFloat(v);
        return isNaN(n) ? 0 : n;
      };

      const cmpName = (a,b,dir)=> a.localeCompare(b, 'th', {sensitivity:'base'}) * dir;

      if(key === 'price_asc' || key === 'price_desc'){
        const dir = key === 'price_asc' ? 1 : -1;
        coll.sort((A,B)=>{
          const a = parseNum(A.dataset.price), b = parseNum(B.dataset.price);
          if(a === b) return (parseInt(A.dataset.order||'0') - parseInt(B.dataset.order||'0'));
          return (a<b ? -1 : 1) * dir;
        });
      }else if(key === 'name_asc' || key === 'name_desc'){
        const dir = key === 'name_asc' ? 1 : -1;
        coll.sort((A,B)=>{
          const a = (A.dataset.name||''); const b=(B.dataset.name||'');
          const c = cmpName(a,b,dir);
          return c === 0 ? (parseInt(A.dataset.order||'0') - parseInt(B.dataset.order||'0')) : c;
        });
      }else{
        coll.sort((A,B)=> parseInt(A.dataset.orig||'0') - parseInt(B.dataset.orig||'0'));
      }

      const frag = document.createDocumentFragment();
      coll.concat(hidden).forEach(el=>frag.appendChild(el));
      grid.appendChild(frag);

      setHidden('sort', key);
      if(!isInit){ updateUrlParams({sort:key, page:1}); }
    }

    (function initSort(){
      const sel = document.getElementById('sortSel');
      if(!sel) return;
      sortGrid(sel.value || 'latest', true);
      sel.addEventListener('change', ()=> sortGrid(sel.value, false));
    })();
  </script>
</body>
</html>
