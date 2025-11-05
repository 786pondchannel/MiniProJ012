<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>

<jsp:useBean id="now" class="java.util.Date" />
<c:if test="${empty ctx}">
  <c:set var="ctx" value="${pageContext.request.contextPath}"/>
</c:if>
<c:set var="user" value="${sessionScope.loggedInUser}"/>

<%-- ===== URL โปรไฟล์เกษตรกร (ใช้ในเมนู) ===== --%>
<c:set var="farmerIdForUrl"
       value="${not empty sessionScope.farmerId ? sessionScope.farmerId
                : (not empty param.farmerId ? param.farmerId
                   : (not empty farmer.farmerId ? farmer.farmerId : ''))}"/>
<c:url var="farmerProfileUrl" value="/farmer/profile">
  <c:if test="${not empty farmerIdForUrl}">
    <c:param name="farmerId" value="${farmerIdForUrl}"/>
  </c:if>
</c:url>

<%-- badge ตะกร้า --%>
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />

<%-- ===== คะแนนเฉลี่ย 1 ตำแหน่ง ===== --%>
<c:set var="avgRaw" value="${not empty avgRating ? avgRating : farmer.rating}"/>
<fmt:parseNumber var="avgScore" value="${empty avgRaw ? 0 : avgRaw}" type="number"/>
<fmt:formatNumber var="avgOneDigit" value="${avgScore}" maxFractionDigits="1" minFractionDigits="1"/>

<%-- ===== URL รูปสลิป/QR ===== --%>
<c:set var="qrRaw" value="${not empty paymentSlipUrl ? paymentSlipUrl : farmer.slipUrl}"/>
<c:if test="${qrRaw == 'null' || qrRaw == 'NULL'}"><c:set var="qrRaw" value=""/></c:if>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>โปรไฟล์ร้าน • เกษตรกรบ้านเรา</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --emerald:#10b981; --emerald600:#059669; --ink:#0f172a; --border:#e5e7eb; }
    body{ font-family:'Prompt',sans-serif; color:var(--ink) }
    .bg-farm{
      min-height:100vh;
      background:
        radial-gradient(1200px 600px at 15% 10%, rgba(255,140,0,.06), transparent 60%),
        radial-gradient(1400px 700px at 85% 20%, rgba(34,197,94,.10), transparent 65%),
        linear-gradient(160deg, #ffffff 0%, #f3fff8 48%, #eafff1 100%);
    }
    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    .card{ border:1px solid var(--border); border-radius:16px; background:#fff; padding:16px; box-shadow:0 10px 26px rgba(2,8,23,.06) }

    /* ====== แกลเลอรี ====== */
    .hero-wrap{ position:relative }
    .hero-img{ width:100%; height:340px; border-radius:16px; object-fit:cover; background:#eef2f7; user-select:none }

    .thumb{ width:80px; height:80px; border-radius:12px; overflow:hidden; border:1px solid #e5e7eb; cursor:pointer }
    .thumb img{ width:100%; height:100%; object-fit:cover }
    .thumb.active{ outline:3px solid var(--emerald); outline-offset:2px }

    .chip{ border-radius:9999px; padding:.35rem .65rem; font-weight:700; font-size:.8rem; display:inline-flex; align-items:center; gap:.35rem }

    /* ====== การ์ดคะแนนมุมบนขวา ====== */
    .rating-box{
      position:absolute; right:12px; top:-14px;
      background:linear-gradient(145deg,#ffffff 0%,#f5fbff 100%);
      border:1px solid rgba(16,185,129,.25);
      border-radius:14px; padding:10px 14px;
      display:flex; align-items:center; gap:10px;
      box-shadow:0 14px 36px rgba(2,8,23,.10);
    }
    .rating-num{ font-size:36px; font-weight:900; line-height:1 }
    .rating-den{ font-weight:800; margin-left:2px }
    .rating-stars i{ color:#f59e0b; margin-right:2px }

    /* ====== ตัดบรรทัดแบบสวย ๆ ====== */
    .clamp-2{ display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden }
  </style>
</head>

<body class="bg-farm">
  <!-- ================= Header ================= -->
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
                <a href="${farmerProfileUrl}" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-store"></i> โปรไฟล์ร้าน</a>
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

      <form id="search" method="get" action="${ctx}/catalog/list" class="justify-self-center lg:justify-self-start w-full max-w-2xl mx-4 hidden sm:block">
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
              <button id="profileBtn" onclick="toggleProfileMenu()" class="inline-flex items-center ml-2 px-3 py-1 bg-white/20 hover:bg-white/35 backdrop-blur rounded-full text-sm font-medium transition group" type="button">
                <img src="${avatarUrl}?t=${now.time}" alt="โปรไฟล์" class="h-8 w-8 rounded-full border-2 border-white shadow-md mr-2 object-cover"/>
                สวัสดี, ${sessionScope.loggedInUser.fullname}
                <svg class="w-4 h-4 ml-1 text-white transform transition-transform group-hover:rotate-180" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
              </button>

              <div id="profileMenu" class="hidden absolute right-0 mt-2 w-56 bg-white text-gray-800 rounded-lg shadow-xl overflow-hidden z-50">
                <ul class="divide-y divide-gray-200">
                  <li><a href="https://www.blacklistseller.com/report/report_preview/447043" class="flex items-center px-4 py-3 hover:bg-green-50 transition-colors" target="_blank" rel="noopener">❓ เช็คบัญชีคนโกง</a></li>
                  <li>
                    <c:choose>
                      <c:when test="${sessionScope.loggedInUser.status eq 'FARMER'}">
                        <a href="${ctx}/farmer/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50 transition-colors">👨‍🌾 แก้ไขโปรไฟล์เกษตรกร</a>
                      </c:when>
                      <c:otherwise>
                        <a href="${ctx}/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50 transition-colors">👤 แก้ไขโปรไฟล์ส่วนตัว</a>
                      </c:otherwise>
                    </c:choose>
                  </li>
                  <li><a href="${ctx}/logout" class="flex items-center px-4 py-3 hover:bg-red-50 transition-colors">🚪 ออกจากระบบ</a></li>
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

  <!-- ================= Main ================= -->
  <main class="max-w-6xl mx-auto px-4 py-6 space-y-6">

    <c:if test="${not empty error}">
      <div class="card bg-red-50 border-red-200 text-red-700">${error}</div>
    </c:if>

    <c:if test="${not empty farmer}">
      <section class="card relative"><!-- relative สำหรับวางกล่องคะแนน -->
        <!-- กล่องคะแนนมุมบนขวา -->
        <div class="rating-box">
          <div class="rating-num">${avgOneDigit}<span class="rating-den">/5</span></div>
          <div class="rating-stars">
            <c:forEach var="i" begin="1" end="5">
              <i class="${i <= avgScore ? 'fa-solid fa-star' : (i-1 < avgScore ? 'fa-solid fa-star-half-stroke' : 'fa-regular fa-star')}"></i>
            </c:forEach>
          </div>
        </div>

        <div class="grid lg:grid-cols-12 gap-6">
          <!-- ซ้าย: แกลเลอรี -->
          <div class="lg:col-span-7">
            <%-- heroUrl: รูปแรกในแกลเลอรี ถ้าไม่มีใช้ imageF --%>
            <c:set var="rawHero" value="${not empty gallery ? gallery[0] : farmer.imageF}" />
            <c:set var="heroUrl" value=""/>
            <c:choose>
              <c:when test="${empty rawHero}"><c:set var="heroUrl" value="https://via.placeholder.com/800x600?text=No+Image"/></c:when>
              <c:when test="${fn:startsWith(rawHero,'http')}"><c:set var="heroUrl" value="${rawHero}"/></c:when>
              <c:when test="${fn:startsWith(rawHero,'/')}"><c:set var="heroUrl" value="${ctx}${rawHero}"/></c:when>
              <c:otherwise><c:set var="heroUrl" value="${ctx}/uploads/${rawHero}"/></c:otherwise>
            </c:choose>

            <div class="hero-wrap">
              <img id="hero" class="hero-img" src="${heroUrl}" alt="ภาพหน้าปก" onclick="openLBWith(PICS,0)"/>
            </div>

            <!-- แถบรูปย่อย -->
            <div class="mt-3 flex flex-wrap gap-2" id="gbar">
              <c:forEach var="g" items="${gallery}" varStatus="st">
                <c:set var="thumbU" value=""/>
                <c:choose>
                  <c:when test="${empty g}"><c:set var="thumbU" value=""/></c:when>
                  <c:when test="${fn:startsWith(g,'http')}"><c:set var="thumbU" value="${g}"/></c:when>
                  <c:when test="${fn:startsWith(g,'/')}"><c:set var="thumbU" value="${ctx}${g}"/></c:when>
                  <c:otherwise><c:set var="thumbU" value="${ctx}/uploads/${g}"/></c:otherwise>
                </c:choose>

                <div class="thumb ${st.index == 0 ? 'active' : ''}" onclick="pick(${st.index}, this)">
                  <img src="${thumbU}" alt="gallery"/>
                </div>
              </c:forEach>
            </div>
          </div>

          <!-- ขวา: ข้อมูลร้าน + สลิป -->
          <div class="lg:col-span-5 space-y-4">
            <div>
              <div class="text-xs text-gray-500"><i class="fa-solid fa-store mr-1"></i> ฟาร์ม</div>
              <h2 class="text-2xl font-extrabold"><c:out value="${farmer.farmName}"/></h2>
              <div class="mt-2 flex flex-wrap items-center gap-2">
                <span class="chip bg-gray-100 text-gray-800"><i class="fa-regular fa-comment-dots"></i>
                  <c:out value="${empty reviewCount ? (empty reviews ? 0 : fn:length(reviews)) : reviewCount}"/> รีวิว
                </span>
                <c:if test="${not empty farmer.status}">
                  <span class="chip bg-sky-100 text-sky-800"><i class="fa-solid fa-circle-check"></i> <c:out value="${farmer.status}"/></span>
                </c:if>
              </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div class="card"><div class="text-xs text-gray-500"><i class="fa-solid fa-location-dot mr-1"></i> ที่อยู่</div><div class="font-semibold"><c:out value="${farmer.address}"/></div></div>
              <div class="card"><div class="text-xs text-gray-500"><i class="fa-solid fa-map-pin mr-1"></i> พิกัดฟาร์ม</div><div class="font-semibold"><c:out value="${farmer.farmLocation}"/></div></div>
              <div class="card"><div class="text-xs text-gray-500"><i class="fa-solid fa-phone mr-1"></i> โทรศัพท์</div><div class="font-semibold"><c:out value="${farmer.phoneNumber}"/></div></div>
              <div class="card"><div class="text-xs text-gray-500"><i class="fa-regular fa-envelope mr-1"></i> อีเมล</div><div class="font-semibold"><c:out value="${farmer.email}"/></div></div>
            </div>

            <div>
              <div class="text-sm text-gray-600 mb-1 font-semibold"><i class="fa-solid fa-qrcode mr-1"></i> ชำระเงินด้วย QR (ถ้ามี)</div>
              <div class="w-[220px] h-[220px] rounded-xl overflow-hidden border bg-white flex items-center justify-center">
                <c:set var="slipU" value=""/>
                <c:choose>
                  <c:when test="${empty qrRaw}"><c:set var="slipU" value=""/></c:when>
                  <c:when test="${fn:startsWith(qrRaw,'http')}"><c:set var="slipU" value="${qrRaw}"/></c:when>
                  <c:when test="${fn:startsWith(qrRaw,'/')}"><c:set var="slipU" value="${ctx}${qrRaw}"/></c:when>
                  <c:when test="${fn:startsWith(qrRaw,'uploads/')}"><c:set var="slipU" value="${ctx}/${qrRaw}"/></c:when>
                  <c:otherwise><c:set var="slipU" value="${ctx}/uploads/${qrRaw}"/></c:otherwise>
                </c:choose>

                <c:choose>
                  <c:when test="${not empty slipU}">
                    <a href="javascript:void(0)" onclick="openLBWith(['${fn:escapeXml(slipU)}'],0)" class="block w-full h-full" title="ดูสลิปแบบขยาย">
                      <img src="${slipU}" alt="QR" class="w-full h-full object-contain"
                           onerror="this.onerror=null;this.src='https://via.placeholder.com/220x220?text=QR+not+found';"/>
                    </a>
                  </c:when>
                  <c:otherwise><div class="text-gray-400 text-xs p-4 text-center">ยังไม่อัปโหลด</div></c:otherwise>
                </c:choose>
              </div>
            </div>
          </div>
        </div>
      </section>
    </c:if>

    <!-- ================= สินค้า ================= -->
    <section class="card">
      <div class="flex items-end justify-between gap-3">
        <div>
          <div class="text-xs text-gray-500"><i class="fa-solid fa-basket-shopping mr-1"></i> สินค้าในร้านนี้</div>
          <h3 class="text-lg font-bold">รายการสินค้า</h3>
        </div>
        <c:if test="${not empty products}">
          <div class="text-sm text-gray-600">ทั้งหมด <span class="font-bold"><c:out value="${fn:length(products)}"/></span> รายการ</div>
        </c:if>
      </div>

      <c:choose>
        <c:when test="${empty products}">
          <div class="py-8 text-center text-gray-500">ร้านนี้ยังไม่มีสินค้า</div>
        </c:when>
        <c:otherwise>
          <div class="mt-4 grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
            <c:forEach var="p" items="${products}" varStatus="st">
              <c:if test="${st.index < 9}">
                <div class="border rounded-xl overflow-hidden bg-white hover:shadow-lg transition hover:-translate-y-[2px] h-full flex flex-col">
                  <c:set var="imgUrl" value=""/>
                  <c:choose>
                    <c:when test="${not empty p.img and fn:startsWith(p.img,'http')}"><c:set var="imgUrl" value="${p.img}"/></c:when>
                    <c:when test="${not empty p.img and fn:startsWith(p.img,'/')}"><c:set var="imgUrl" value="${ctx}${p.img}"/></c:when>
                    <c:when test="${not empty p.img}"><c:set var="imgUrl" value="${ctx}/uploads/${p.img}"/></c:when>
                  </c:choose>

                  <c:choose>
                    <c:when test="${not empty imgUrl}">
                      <a href="${ctx}/catalog/view/${p.productId}" class="block">
                        <img src="${imgUrl}" alt="${fn:escapeXml(p.productname)}" class="w-full h-40 object-cover" loading="lazy"/>
                      </a>
                    </c:when>
                    <c:otherwise>
                      <a href="${ctx}/catalog/view/${p.productId}" class="block w-full h-40 bg-gray-100 flex items-center justify-center text-gray-400 text-sm">ไม่มีรูป</a>
                    </c:otherwise>
                  </c:choose>

                  <div class="p-3 flex flex-col flex-1">
                    <div class="font-semibold truncate" title="${fn:escapeXml(p.productname)}"><c:out value="${p.productname}"/></div>

                    <c:set var="desc" value="${p.description}"/>
                    <div class="text-sm text-gray-600 clamp-2 mt-0.5">
                      <c:choose>
                        <c:when test="${not empty desc}">
                          <c:out value="${fn:length(desc) > 120 ? fn:substring(desc,0,120).concat('…') : desc}"/>
                        </c:when>
                        <c:otherwise></c:otherwise>
                      </c:choose>
                    </div>

                    <div class="mt-2 font-bold text-emerald-700">
                      <c:choose>
                        <c:when test="${not empty p.price}">
                          <fmt:formatNumber value="${p.price}" type="currency" currencySymbol="฿" maxFractionDigits="2"/>
                        </c:when>
                        <c:otherwise>—</c:otherwise>
                      </c:choose>
                    </div>

                    <div class="mt-auto pt-3">
                      <a href="${ctx}/catalog/view/${p.productId}" class="inline-flex items-center justify-center w-full sm:w-auto px-3 py-2 rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 transition">
                        <i class="fa-regular fa-eye mr-1"></i> ดูสินค้า
                      </a>
                    </div>
                  </div>
                </div>
              </c:if>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </section>

    <!-- ================= รีวิว ================= -->
    <section class="card">
      <div class="flex items-end justify-between gap-3">
        <div>
          <div class="text-xs text-gray-500"><i class="fa-regular fa-comments mr-1"></i> รีวิวจากผู้ซื้อ</div>
          <h3 class="text-lg font-bold">รีวิวจากผู้ซื้อ</h3>
        </div>

        <!-- ขวา: ทั้งหมด (N) + คะแนนเฉลี่ย + ดาว -->
        <div class="flex items-center gap-3 text-sm">
          <div>ทั้งหมด (<span class="font-semibold">
            <c:out value="${empty reviewCount ? (empty reviews ? 0 : fn:length(reviews)) : reviewCount}"/>
          </span>)</div>
          <div class="flex items-center gap-2">
            <strong class="text-lg">${avgOneDigit}</strong><span>/5</span>
            <span class="text-yellow-500">
              <c:forEach var="i" begin="1" end="5">
                <i class="${i <= avgScore ? 'fa-solid fa-star' : (i-1 < avgScore ? 'fa-solid fa-star-half-stroke' : 'fa-regular fa-star')}"></i>
              </c:forEach>
            </span>
          </div>
        </div>
      </div>

      <div class="mt-4 divide-y">
        <c:choose>
          <c:when test="${empty reviews}">
            <div class="py-8 text-center text-gray-500">ยังไม่มีรีวิว</div>
          </c:when>
          <c:otherwise>
            <c:forEach var="rv" items="${reviews}">
              <article class="py-4">
                <div class="flex items-start gap-3">
                  <div class="h-10 w-10 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold">
                    <c:out value="${fn:substring(rv.memberId,0,1)}"/>
                  </div>
                  <div class="flex-1">
                    <div class="flex flex-wrap items-center gap-2">
                      <div class="text-sm font-semibold"><i class="fa-regular fa-user mr-1"></i> ผู้ซื้อ: <span class="font-mono"><c:out value="${rv.memberId}"/></span></div>
                      <div class="text-xs text-gray-500"><i class="fa-regular fa-clipboard mr-1"></i> ออเดอร์: <span class="font-mono"><c:out value="${rv.orderId}"/></span></div>
                      <c:if test="${not empty rv.productId}">
                        <div class="text-xs text-gray-500"><i class="fa-solid fa-tag mr-1"></i> สินค้า: <span class="font-mono"><c:out value="${rv.productId}"/></span></div>
                      </c:if>
                      <div class="text-xs text-gray-500">
                        <i class="fa-regular fa-clock mr-1"></i>
                        <c:choose>
                          <c:when test="${not empty rv.reviewDate}">
                            <c:catch var="fmtErr"><fmt:formatDate value="${rv.reviewDate}" pattern="dd/MM/yyyy HH:mm"/></c:catch>
                            <c:if test="${not empty fmtErr}"><c:out value="${rv.reviewDate}"/></c:if>
                          </c:when>
                          <c:otherwise>-</c:otherwise>
                        </c:choose>
                      </div>
                    </div>
                    <div class="mt-1 flex items-center text-yellow-500">
                      <c:forEach var="i" begin="1" end="5">
                        <i class="${i <= rv.rating ? 'fa-solid fa-star' : 'fa-regular fa-star'}"></i>
                      </c:forEach>
                    </div>
                    <div class="mt-2 text-[15px] text-gray-800 whitespace-pre-wrap"><c:out value="${rv.comment}"/></div>
                  </div>
                </div>
              </article>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>
    </section>

    <div class="flex justify-between items-center">
      <a href="${ctx}/orders" class="chip bg-gray-100 text-gray-900"><i class="fa-solid fa-arrow-left mr-1"></i> กลับคำสั่งซื้อ</a>
      <c:if test="${not empty farmer.farmerId}">
        <span class="text-xs text-gray-500">รหัสฟาร์ม: <span class="font-mono"><c:out value="${farmer.farmerId}"/></span></span>
      </c:if>
    </div>
  </main>

  <!-- ================= Footer (พื้นดำเหมือนหน้าอื่น) ================= -->
  <style>.footer-dark{ background:#000; color:#e5e7eb } .footer-dark a{ color:#e5e7eb } .footer-dark a:hover{ color:#a7f3d0 }</style>
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
        <a class="inline-flex items-center gap-2 px-3 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
    <div class="bg-black/90">
      <div class="container mx-auto px-6 py-4 text-xs text-gray-400 flex items-center justify-between">
        <span>© <fmt:formatDate value="${now}" pattern="yyyy"/> เกษตรกรบ้านเรา</span>
        <span>Made with ☘️</span>
      </div>
    </div>
  </footer>

  <!-- ===== Lightbox (กดปิดได้แน่นอน) ===== -->
  <div id="lightbox" class="lb" aria-modal="true" role="dialog" style="position:fixed;inset:0;background:rgba(0,0,0,.86);display:none;z-index:70">
    <div class="lb-toolbar" style="position:absolute;top:12px;right:12px;display:flex;gap:8px;z-index:10">
      <button class="lb-btn" id="lbPrev" title="ก่อนหน้า"><i class="fa-solid fa-chevron-left"></i></button>
      <button class="lb-btn" id="lbNext" title="ถัดไป"><i class="fa-solid fa-chevron-right"></i></button>
      <button class="lb-btn" id="lbZoomIn" title="ซูมเข้า"><i class="fa-solid fa-magnifying-glass-plus"></i></button>
      <button class="lb-btn" id="lbZoomOut" title="ซูมออก"><i class="fa-solid fa-magnifying-glass-minus"></i></button>
      <button class="lb-btn" id="lbReset" title="รีเซ็ต"><i class="fa-solid fa-rotate-right"></i></button>
      <button class="lb-btn" id="lbClose" title="ปิด (Esc)"><i class="fa-solid fa-xmark"></i></button>
    </div>
    <div class="lb-stage" id="lbStage" style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;overflow:hidden;touch-action:none">
      <img id="lbImg" class="lb-img" alt="preview" style="max-width:none;user-select:none;-webkit-user-drag:none;will-change:transform">
    </div>
  </div>

  <!-- ================= Scripts ================= -->
  <script>
    /* ===== เมนูโปรไฟล์ ===== */
    function toggleProfileMenu(){ const m=document.getElementById('profileMenu'); if(!m) return; m.classList.toggle('hidden'); }
    document.addEventListener('click',(e)=>{ const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu'); if(!b||!m) return; if(!b.contains(e.target) && !m.contains(e.target)) m.classList.add('hidden'); });

    /* ===== สร้างรายการรูป (Hero + Gallery) ===== */
    const IMAGES=[];
    <c:if test="${not empty heroUrl}"> IMAGES.push('${fn:escapeXml(heroUrl)}'); </c:if>
    <c:forEach var="g" items="${gallery}">
      <c:choose>
        <c:when test="${fn:startsWith(g,'http')}">IMAGES.push('${fn:escapeXml(g)}');</c:when>
        <c:when test="${fn:startsWith(g,'/')}">IMAGES.push('${fn:escapeXml(ctx)}${fn:escapeXml(g)}');</c:when>
        <c:otherwise>IMAGES.push('${fn:escapeXml(ctx)}/uploads/${fn:escapeXml(g)}');</c:otherwise>
      </c:choose>
    </c:forEach>
    const PICS=Array.from(new Set(IMAGES));
    if(!PICS.length) PICS.push('https://via.placeholder.com/800x600?text=No+Image');

    /* ===== DOM refs ===== */
    const hero = document.getElementById('hero');

    /* ===== แกลเลอรี ===== */
    let cur=0;
    function show(i){ cur=(i+PICS.length)%PICS.length; hero.src=PICS[cur]; document.querySelectorAll('#gbar .thumb').forEach((el,idx)=> el.classList.toggle('active', idx===cur)); }
    function pick(i){ show(i); }
    window.pick = pick;
    show(0);

    /* ===== Lightbox (สำหรับสลิป + แกลเลอรี) ===== */
    const lb=document.getElementById('lightbox'), lbImg=document.getElementById('lbImg'), lbStage=document.getElementById('lbStage');
    const lbPrev=document.getElementById('lbPrev'), lbNext=document.getElementById('lbNext');
    const lbIn=document.getElementById('lbZoomIn'), lbOut=document.getElementById('lbZoomOut'), lbReset=document.getElementById('lbReset'), lbClose=document.getElementById('lbClose');

    let LB_IMAGES=[], li=0, scale=1, tx=0, ty=0;
    function apply(){ lbImg.style.transform=`translate(${tx}px,${ty}px) scale(${scale})`; }
    function setSrc(url){ lbImg.src=url; scale=1; tx=ty=0; apply(); toggleArrows(); }
    function toggleArrows(){ const one=LB_IMAGES.length<=1; [lbPrev,lbNext].forEach(b=>{ if(!b)return; b.disabled=one; b.style.opacity=one?.35:1; }); }

    function openLBWith(arr, index){
      LB_IMAGES = Array.isArray(arr)? arr.filter(Boolean) : [arr];
      li = typeof index==='number'? index : 0;
      setSrc(LB_IMAGES[li]);
      lb.style.display='block';
    }
    function closeLB(){ lb.style.display='none'; }
    window.openLBWith=openLBWith;

    lbClose.addEventListener('click', closeLB);
    lb.addEventListener('click', (e)=>{ if(e.target===lb) closeLB(); });
    document.addEventListener('keydown', (e)=>{ if(lb.style.display!=='block') return;
      if(e.key==='Escape') closeLB();
      if(e.key==='ArrowLeft') prev();
      if(e.key==='ArrowRight') next();
      if(e.key==='+' || e.key==='=') zoom(.2);
      if(e.key==='-') zoom(-.2);
      if(e.key==='0') reset();
    });

    function prev(){ if(LB_IMAGES.length<2) return; li=(li-1+LB_IMAGES.length)%LB_IMAGES.length; setSrc(LB_IMAGES[li]); }
    function next(){ if(LB_IMAGES.length<2) return; li=(li+1)%LB_IMAGES.length; setSrc(LB_IMAGES[li]); }
    lbPrev.addEventListener('click', prev); lbNext.addEventListener('click', next);

    function zoom(d){ scale=Math.min(5,Math.max(.8,scale+d)); apply(); }
    function reset(){ scale=1; tx=ty=0; apply(); }
    lbIn.addEventListener('click', ()=>zoom(.2));
    lbOut.addEventListener('click', ()=>zoom(-.2));
    lbReset.addEventListener('click', reset);

    // ลากรูป
    let dragging=false, sx=0, sy=0;
    lbStage.addEventListener('mousedown', (e)=>{ if(e.target!==lbImg) return; dragging=true; sx=e.clientX; sy=e.clientY; });
    window.addEventListener('mousemove', (e)=>{ if(!dragging) return; tx+=e.clientX-sx; ty+=e.clientY-sy; sx=e.clientX; sy=e.clientY; apply(); });
    window.addEventListener('mouseup', ()=> dragging=false);
    lbStage.addEventListener('wheel', (e)=>{ e.preventDefault(); zoom(e.deltaY<0? .15 : -.15); }, {passive:false});

    // ดับเบิลคลิกภาพหลักเพื่อเปิดดู
    hero.addEventListener('dblclick', ()=>openLBWith(PICS,cur));
  </script>
</body>
</html>
