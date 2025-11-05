<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />
<c:set var="isLoggedIn" value="${not empty sessionScope.loggedInUser}" />
<c:set var="userRole"   value="${isLoggedIn ? sessionScope.loggedInUser.status : ''}" />

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>เกษตรกรบ้านเรา • สดจากฟาร์ม ถึงบ้านคุณ</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{
      --emerald:#10b981; --emerald600:#059669; --ink:#0f172a; --muted:#64748b; --border:#e5e7eb;
      --sky:#0ea5e9; --amber:#f59e0b; --violet:#8b5cf6; --rose:#ef4444;
      --ease:cubic-bezier(.2,.7,.2,1);
    }
    html,body{ font-family:'Prompt',system-ui,-apple-system,Segoe UI,Roboto,Arial; color:var(--ink) }

    /* ===== Ambient bg ===== */
    body.bg-ambient{ min-height:100vh; background:#f8fafc; position:relative; overflow-x:hidden; }
    body.bg-ambient::before,
    body.bg-ambient::after{
      content:""; position:fixed; inset:-20vmax -10vmax auto auto; z-index:-1; pointer-events:none;
      width:90vmax; height:90vmax; border-radius:50%;
      background:
        radial-gradient(closest-side, rgba(16,185,129,.16), transparent 65%),
        radial-gradient(closest-side, rgba(14,165,233,.12), transparent 60%),
        radial-gradient(closest-side, rgba(139,92,246,.10), transparent 55%);
      filter:blur(40px); animation:blob 26s var(--ease) infinite alternate;
    }
    body.bg-ambient::after{
      inset:auto auto -22vmax -14vmax; width:80vmax; height:80vmax;
      background:
        radial-gradient(closest-side, rgba(245,158,11,.15), transparent 60%),
        radial-gradient(closest-side, rgba(16,185,129,.12), transparent 55%);
      animation-duration:28s;
    }
    @keyframes blob{ 0%{transform:translate3d(0,0,0) scale(1)} 100%{transform:translate3d(6vmax,-2vmax,0) scale(1.06)} }

    /* ===== Header ===== */
    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    /* ===== Hero ===== */
    .hero{ height:480px; position:relative; overflow:hidden }
    .hero-slide{ position:absolute; inset:0; width:100%; height:100%; object-fit:cover; opacity:0; transform:scale(1.06); transition:opacity .6s var(--ease), transform 7s var(--ease) }
    .hero-slide.active{ opacity:1; transform:scale(1.02) }
    .hero-mask{ position:absolute; inset:0; background:linear-gradient(180deg, rgba(0,0,0,.45), rgba(0,0,0,.18)) }

    /* ===== Cards + chips ===== */
    .card{ background:#fff; border:1px solid var(--border); border-radius:16px; box-shadow:0 12px 26px rgba(2,8,23,.06) }
    .imgwrap{ aspect-ratio:4/3; overflow:hidden; border-radius:12px; border:1px solid #eef2f7; background:#f8fafc; position:relative }
    .imgwrap img{ width:100%; height:100%; object-fit:cover; transition:transform .35s var(--ease) }
    .product-card:hover .imgwrap img{ transform:scale(1.04) }
    .chip{ position:absolute; left:10px; top:10px; padding:.3rem .55rem; font-size:.75rem; color:#fff; border-radius:9999px; display:flex; gap:.4rem; align-items:center; box-shadow:0 8px 16px rgba(2,8,23,.16) }
    .chip-emerald{ background:#059669 } /* พรีออเดอร์ได้แล้ว */
    .chip-sky{ background:#0ea5e9 }     /* พร้อมสั่งซื้อแล้ว */
    .chip-gray{ background:#64748b }    /* กำลังผลิต */
    .chip-rose{ background:#ef4444 }    /* ปิดรับจอง */

    .btn{display:inline-flex;align-items:center;gap:.5rem;padding:.6rem .9rem;border-radius:12px;border:1px solid var(--border);background:#fff;transition:transform .12s var(--ease), box-shadow .2s var(--ease), border-color .2s var(--ease)}
    .btn:hover{transform:translateY(-1px); box-shadow:0 10px 20px rgba(16,185,129,.12); border-color:#d1fae5}
    .btn-primary{ background:linear-gradient(135deg,var(--emerald),var(--emerald600)); color:#fff; border-color:transparent }
    .btn-primary:hover{ filter:brightness(1.05) }
    .btn:disabled{ opacity:.55; cursor:not-allowed }

    /* ===== Reveal on scroll ===== */
    .reveal{ opacity:0; transform:translateY(12px); transition:opacity .5s var(--ease), transform .5s var(--ease) }
    .reveal.in{ opacity:1; transform:none }

    /* ===== Footer ===== */
    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb } .footer-dark a:hover{ color:#a7f3d0 }

    /* ===== Back-to-top ===== */
    .toTop{ position:fixed; right:1rem; bottom:5.5rem; z-index:55; transform:translateY(12px); opacity:0; pointer-events:none; transition:.25s var(--ease) }
    .toTop.show{ transform:none; opacity:1; pointer-events:auto }

    /* ===== Modal (promo) ===== */
    .modal-root{position:fixed; inset:0; z-index:60; display:grid; place-items:center; pointer-events:none}
    .modal-backdrop{position:fixed; inset:0; background:rgba(15,23,42,.6); backdrop-filter:blur(4px); opacity:0; transition:opacity .35s var(--ease); pointer-events:none}
    .modal-backdrop.show{opacity:1; pointer-events:auto}
    .modal{width:min(720px,92vw); border-radius:22px; background:#fff; border:1px solid #eef2f7;
           box-shadow:0 30px 80px rgba(2,8,23,.30); transform:translateY(14px) scale(.96);
           opacity:0; transition:transform .35s var(--ease), opacity .35s var(--ease); pointer-events:auto; position:relative; overflow:hidden}
    .modal.show{transform:translateY(0) scale(1); opacity:1}
    .modal-header{padding:16px 20px; display:flex; align-items:center; gap:10px; background:linear-gradient(135deg,#ecfdf5,#dbeafe,#fae8ff)}
    .modal-body{padding:20px}
    .modal-footer{padding:14px 20px; background:#fafafa; border-top:1px solid #eee; display:flex; gap:8px; justify-content:flex-end}
    .close-x{position:absolute; right:10px; top:10px; border-radius:10px; background:#000; color:#fff; width:34px; height:34px; display:grid; place-items:center; opacity:.9}
    .close-x:hover{opacity:1; transform:translateY(-1px)}

    /* ===== Promo FAB (left) ===== */
    .btn-glow{
      color:#fff; border:0;
      background:linear-gradient(90deg,#10b981,#0ea5e9,#8b5cf6,#fb923c);
      background-size:300% 100%;
      animation:gradMove 7s linear infinite;
      box-shadow:0 12px 30px rgba(2,8,23,.25)
    }
    @keyframes gradMove{0%{background-position:0% 50%}100%{background-position:300% 50%}}

    /* ====== Auth Gate Modal (namespaced ag-) ====== */
    .ag-root{position:fixed; inset:0; z-index:80; display:none; place-items:center}
    .ag-backdrop{position:fixed; inset:0; background:rgba(15,23,42,.6); backdrop-filter:blur(3px); opacity:0; transition:.25s}
    .ag-wrap{width:min(600px,92vw); background:#fff; border-radius:20px; box-shadow:0 30px 80px rgba(2,8,23,.35);
             transform:translateY(10px) scale(.98); opacity:0; transition:.25s; position:relative; overflow:hidden}
    .ag-show .ag-backdrop{opacity:1}
    .ag-show .ag-wrap{transform:none; opacity:1}
    .ag-head{padding:14px 18px; display:flex; gap:10px; align-items:center; background:linear-gradient(135deg,#ecfdf5,#dbeafe,#fae8ff)}
    .ag-ico{width:56px;height:56px;border-radius:9999px;display:grid;place-items:center;background:#fff;font-size:24px}
    .ag-body{padding:16px 18px;color:#0f172a}
    .ag-foot{padding:14px 18px;background:#fafafa;border-top:1px solid #eee;display:flex;gap:8px;justify-content:flex-end}
    .ag-x{position:absolute;right:10px;top:10px;border-radius:10px;background:#000;color:#fff;width:34px;height:34px;display:grid;place-items:center;opacity:.9}
    .ag-x:hover{opacity:1}
  </style>
</head>

<body class="bg-ambient min-h-screen flex flex-col">
  <!-- ========= Header ========= -->
  <header class="header shadow-md text-white">
    <div class="container mx-auto px-6 py-3 topbar">
      <div class="flex items-center gap-3">
        <a href="${ctx}/main" class="flex items-center gap-3 shrink-0">
          <img src="https://cdn-icons-png.flaticon.com/512/2909/2909763.png" class="h-8 w-8" alt="logo"/>
          <span class="hidden sm:inline font-bold">เกษตรกรบ้านเรา</span>
        </a>

        <nav class="nav-scroll ml-2">
          <c:choose>
            <c:when test="${isLoggedIn && sessionScope.loggedInUser.status eq 'FARMER'}">
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
                <a href="${ctx}/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-clock"></i> ประวัติการสั่งจอง</a>
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
          <c:when test="${isLoggedIn}">
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
                <img src="${avatarUrl}?t=${now.time}" alt="โปรไฟล์" class="h-8 w-8 rounded-full border-2 border-white shadow-md mr-2 object-cover"/>
                สวัสดี, ${sessionScope.loggedInUser.fullname}
                <svg class="w-4 h-4 ml-1 text-white transform transition-transform group-hover:rotate-180" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
              </button>

              <div id="profileMenu" class="hidden absolute right-0 mt-2 w-56 bg-white text-gray-800 rounded-lg shadow-xl overflow-hidden z-50">
                <ul class="divide-y divide-gray-200">
                  <li><a href="https://www.blacklistseller.com/report/report_preview/447043" class="flex items-center px-4 py-3 hover:bg-green-50 transition-colors" target="_blank" rel="noopener"><span class="mr-2">❓</span> เช็คบัญชีคนโกง</a></li>
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
                        <li><a href="${ctx}/logout" class="flex items-center px-4 py-3 hover:bg-red-50 transition-colors"><span class="mr-2">🚪</span> ออกจากระบบ</a></li>
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

  <!-- ========= HERO ========= -->
  <section class="hero">
    <div class="absolute inset-0">
      <c:choose>
        <c:when test="${not empty heroImages}">
          <c:forEach var="img" items="${heroImages}" varStatus="st">
            <img class="hero-slide ${st.first ? 'active' : ''}" src="${img}" alt="hero ${st.index+1}" loading="eager"/>
          </c:forEach>
        </c:when>
        <c:otherwise>
          <img class="hero-slide active" src="https://images.unsplash.com/photo-1537640538966-79f369143f8f?q=80&w=1600&auto=format&fit=crop" alt="farm1" loading="eager"/>
          <img class="hero-slide" src="https://images.unsplash.com/photo-1506617420156-8e4536971650?q=80&w=1600&auto=format&fit=crop" alt="farm2"/>
          <img class="hero-slide" src="https://images.unsplash.com/photo-1514517220035-9f3b0f52f16e?q=80&w=1600&auto=format&fit=crop" alt="farm3"/>
        </c:otherwise>
      </c:choose>
      <div class="hero-mask"></div>
    </div>

    <div class="relative z-10 h-full flex items-center">
      <div class="container mx-auto px-6">
        <h1 class="text-4xl md:text-5xl font-extrabold text-white drop-shadow">สดจากฟาร์ม ถึงบ้านคุณ</h1>
        <p class="mt-2 text-lg md:text-xl text-white/90">พรีออเดอร์ของดีชุมชน ผัก-ผลไม้ปลอดภัย โปร่งใส ยุติธรรม</p>
        <div class="mt-4 flex items-center gap-3">
          <a href="${ctx}/catalog/list" class="btn btn-primary" onclick="ripple(event)">เลือกดูสินค้า</a>
          <a href="#why" class="btn" onclick="ripple(event)">ทำไมต้องพรีออเดอร์</a>
        </div>
      </div>
    </div>

    <button id="heroPrev" class="absolute left-3 top-1/2 -translate-y-1/2 z-30 bg-white/85 hover:bg-white text-gray-800 rounded-full p-2" type="button"><i class="fa-solid fa-chevron-left"></i></button>
    <button id="heroNext" class="absolute right-3 top-1/2 -translate-y-1/2 z-30 bg-white/85 hover:bg-white text-gray-800 rounded-full p-2" type="button"><i class="fa-solid fa-chevron-right"></i></button>

    <div class="absolute bottom-4 left-0 right-0 z-30 flex items-center justify-center gap-2">
      <button class="hero-dot w-2.5 h-2.5 rounded-full bg-white" type="button"></button>
      <button class="hero-dot w-2.5 h-2.5 rounded-full bg-white/40" type="button"></button>
      <button class="hero-dot w-2.5 h-2.5 rounded-full bg-white/40" type="button"></button>
    </div>
  </section>

  <!-- ========= Quick tags ========= -->
  <section class="container mx-auto px-6 mt-8 mb-4 reveal">
    <div class="flex items-center gap-2 flex-wrap">
      <a href="${ctx}/catalog/list?kw=ผัก" class="px-3 py-1.5 rounded-full border bg-white text-sm">🥬 ผัก</a>
      <a href="${ctx}/catalog/list?kw=ผลไม้" class="px-3 py-1.5 rounded-full border bg-white text-sm">🍎 ผลไม้</a>
      <a href="${ctx}/catalog/list?kw=ออร์แกนิก" class="px-3 py-1.5 rounded-full border bg-white text-sm">🌱 ออร์แกนิก</a>
      <a href="${ctx}/catalog/list?kw=ไข่" class="px-3 py-1.5 rounded-full border bg-white text-sm">🥚 ไข่</a>
      <a href="${ctx}/catalog/list?kw=โปร" class="px-3 py-1.5 rounded-full border bg-white text-sm">🔥 โปรโมชัน</a>
    </div>
  </section>

  <!-- ========= สินค้าแนะนำ ========= -->
  <section class="container mx-auto py-8 px-6">
    <div class="flex items-end justify-between mb-4">
      <h2 class="text-2xl md:text-3xl font-bold text-emerald-800">สินค้าแนะนำ</h2>
      <a href="${ctx}/catalog/list" class="text-sm text-emerald-700 hover:underline">ดูทั้งหมด</a>
    </div>

    <c:choose>
      <c:when test="${empty products}">
        <div class="card p-10 text-center reveal">
          <div class="text-5xl mb-2">🛒</div>
          <div class="text-lg font-semibold">ตอนนี้ยังไม่มีสินค้าแนะนำ</div>
          <p class="text-slate-600 mt-1">ลองค้นหาจากหมวดหมู่หรือดูสินค้าทั้งหมด</p>
          <div class="mt-4">
            <a href="${ctx}/catalog/list" class="btn btn-primary" onclick="ripple(event)">ไปหน้าสินค้า</a>
          </div>
        </div>
      </c:when>
      <c:otherwise>
        <div id="productGrid" class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          <c:forEach var="p" items="${products}" varStatus="st">
            <c:set var="imgUrl" value=""/>
            <c:choose>
              <c:when test="${not empty p.img and fn:startsWith(p.img,'http')}"><c:set var="imgUrl" value="${p.img}"/></c:when>
              <c:when test="${not empty p.img and fn:startsWith(p.img,'/uploads/')}"><c:set var="imgUrl" value="${ctx}${p.img}"/></c:when>
              <c:when test="${not empty p.img}"><c:set var="imgUrl" value="${ctx}/uploads/${p.img}"/></c:when>
              <c:otherwise><c:set var="imgUrl" value="https://via.placeholder.com/800x600?text=No+Image"/></c:otherwise>
            </c:choose>

            <c:set var="statusRaw" value="${empty p.status ? '' : p.status}"/>
            <c:set var="chipClass" value="chip-gray"/>
            <c:choose>
              <c:when test="${statusRaw eq 'พรีออเดอร์ได้แล้ว'}"><c:set var="chipClass" value="chip-emerald"/></c:when>
              <c:when test="${statusRaw eq 'พร้อมสั่งซื้อแล้ว' || statusRaw eq 'พร้อมส่ง'}"><c:set var="chipClass" value="chip-sky"/></c:when>
              <c:when test="${statusRaw eq 'กำลังผลิต'}"><c:set var="chipClass" value="chip-gray"/></c:when>
              <c:when test="${statusRaw eq 'ปิดรับจอง'}"><c:set var="chipClass" value="chip-rose"/></c:when>
            </c:choose>
            <c:set var="stockNum" value="${empty p.stock ? 0 : p.stock}"/>
            <c:set var="allowBuyThis" value="${(statusRaw eq 'พรีออเดอร์ได้แล้ว' || statusRaw eq 'พร้อมสั่งซื้อแล้ว' || statusRaw eq 'พร้อมส่ง') && stockNum gt 0}"/>

            <div class="card p-3 product-card reveal" style="transition-delay:${st.index * 40}ms">
              <div class="imgwrap">
                <a href="${ctx}/catalog/view/${p.productId}" class="block" aria-label="ดูสินค้า: ${fn:escapeXml(p.productname)}">
                  <img src="${imgUrl}" alt="${p.productname}" loading="lazy" onerror="this.onerror=null;this.src='https://via.placeholder.com/800x600?text=No+Image';">
                </a>
                <c:if test="${not empty statusRaw}">
                  <div class="chip ${chipClass}"><i class="fa-solid fa-leaf"></i><span>${statusRaw}</span></div>
                </c:if>
              </div>

              <div class="pt-3">
                <a href="${ctx}/catalog/view/${p.productId}" class="font-semibold hover:underline line-clamp-2 text-gray-900">
                  <c:out value="${p.productname}"/>
                </a>

                <div class="mt-1 text-emerald-700 font-extrabold">
                  ฿ <c:choose><c:when test="${not empty p.price}"><fmt:formatNumber value="${p.price}" minFractionDigits="2"/></c:when><c:otherwise>0.00</c:otherwise></c:choose>
                </div>

                <div class="mt-1 flex flex-wrap items-center gap-2 text-sm text-slate-600">
                  <span><i class="fa-solid fa-weight-scale mr-1"></i>คงเหลือ: <fmt:formatNumber value="${stockNum}" type="number" maxFractionDigits="0" groupingUsed="false"/> กก.</span>
                </div>

                <div class="mt-3 flex items-center gap-2">
                  <a href="${ctx}/catalog/view/${p.productId}" class="btn"><i class="fa-regular fa-eye"></i> ดูสินค้า</a>

                  <c:choose>
                    <%-- 1) ยังไม่ล็อกอิน --%>
                    <c:when test="${!isLoggedIn}">
                      <button type="button"
                              class="btn btn-primary"
                              data-next="${ctx}/order/${p.productId}"
                              onclick="agLoginRequired(event)">
                        <i class="fa-solid fa-right-to-bracket"></i> เข้าสู่ระบบก่อนสั่งซื้อ
                      </button>
                    </c:when>

                    <%-- 2) เป็นเกษตรกร/ฟาร์มเมอร์ --%>
                    <c:when test="${userRole eq 'FARMER'}">
                      <button type="button"
                              class="btn btn-primary"
                              data-next="${ctx}/order/${p.productId}"
                              onclick="agRoleRequired(event)">
                        <i class="fa-solid fa-circle-exclamation"></i> สำหรับผู้ซื้อเท่านั้น
                      </button>
                    </c:when>

                    <%-- 3) ผู้ซื้อ --%>
                    <c:otherwise>
                      <form action="${ctx}/cart/add" method="post" class="inline"
                            onsubmit="return confirmAdd(event, '${fn:escapeXml(p.productname)}')">
                        <input type="hidden" name="productId" value="${p.productId}">
                        <input type="hidden" name="qty" value="1">
                        <button type="submit" class="btn btn-primary" <c:if test="${!allowBuyThis}">disabled</c:if>>
                          <i class="fa-solid fa-cart-plus"></i> หยิบใส่ตะกร้า
                        </button>
                      </form>
                    </c:otherwise>
                  </c:choose>

                </div>
              </div>
            </div>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </section>

  <!-- ========= Why preorder ========= -->
  <section id="why" class="py-12 bg-white">
    <div class="container mx-auto px-6">
      <div class="text-center mb-8 reveal">
        <div class="inline-flex items-center gap-2 text-emerald-700 font-semibold bg-emerald-50 border border-emerald-100 px-3 py-1 rounded-full">เหตุผลที่ควรพรีออเดอร์</div>
        <h3 class="text-2xl md:text-3xl font-extrabold mt-2">สดกว่า ยุติธรรมกว่า และช่วยชุมชนได้จริง</h3>
      </div>
      <div class="grid md:grid-cols-2 gap-6">
        <div class="card p-5 flex gap-4 items-start reveal"><div class="text-3xl">🤝</div><div><div class="font-bold text-lg">เงินถึงเกษตรกร</div><p class="text-slate-600">ช่วยรายได้ครัวเรือนท้องถิ่นโดยตรง</p></div></div>
        <div class="card p-5 flex gap-4 items-start reveal"><div class="text-3xl">🔍</div><div><div class="font-bold text-lg">ตรวจสอบได้</div><p class="text-slate-600">รู้แหล่งผลิตและวิธีปลูกชัดเจน</p></div></div>
        <div class="card p-5 flex gap-4 items-start reveal"><div class="text-3xl">♻️</div><div><div class="font-bold text-lg">ลดของเสีย</div><p class="text-slate-600">ผลิตเท่าที่สั่ง เก็บเกี่ยวแม่นยำ</p></div></div>
        <div class="card p-5 flex gap-4 items-start reveal"><div class="text-3xl">💬</div><div><div class="font-bold text-lg">โปร่งใส</div><p class="text-slate-600">คุยรายละเอียดกับเกษตรกรโดยตรง</p></div></div>
      </div>
    </div>
  </section>

  <!-- ========= Steps ========= -->
  <section class="py-12">
    <div class="container mx-auto px-6">
      <div class="text-center mb-8 reveal">
        <div class="inline-flex items-center gap-2 text-emerald-700 font-semibold bg-emerald-50 border border-emerald-100 px-3 py-1 rounded-full">วิธีสั่งจอง</div>
        <h3 class="text-2xl md:text-3xl font-extrabold mt-2">ง่าย 3 ขั้นตอน</h3>
      </div>
      <div class="grid md:grid-cols-3 gap-6">
        <div class="card border p-6 text-center reveal"><div class="mx-auto rounded-full w-14 h-14 grid place-items-center font-extrabold bg-emerald-50 border text-emerald-700 mb-3">1</div><h4 class="font-bold mb-1">ค้นหาเร็ว</h4><p class="text-slate-600 text-sm">เลือกหมวด/ค้นหาคำสำคัญ</p></div>
        <div class="card border p-6 text-center reveal"><div class="mx-auto rounded-full w-14 h-14 grid place-items-center font-extrabold bg-emerald-50 border text-emerald-700 mb-3">2</div><h4 class="font-bold mb-1">คุยกับเกษตรกร</h4><p class="text-slate-600 text-sm">ทราบรายละเอียดครบถ้วนก่อนสั่ง</p></div>
        <div class="card border p-6 text-center reveal"><div class="mx-auto rounded-full w-14 h-14 grid place-items-center font-extrabold bg-emerald-50 border text-emerald-700 mb-3">3</div><h4 class="font-bold mb-1">ยืนยันสบายใจ</h4><p class="text-slate-600 text-sm">เลือกวิธีชำระเงินที่ปลอดภัย</p></div>
      </div>
    </div>
  </section>

  <!-- ========= Footer ========= -->
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

  <!-- Back to top -->
  <button id="toTop" class="toTop bg-emerald-600 hover:bg-emerald-700 text-white rounded-full px-3 py-2 shadow-lg" onclick="window.scrollTo({top:0,behavior:'smooth'})">
    <i class="fa-solid fa-arrow-up"></i>
  </button>

  <!-- ======= Toast root ======= -->
  <div id="toastRoot" class="fixed right-3 bottom-3 z-50 grid gap-2"></div>

  <!-- ======= Floating buttons (ขวา/ซ้าย) ======= -->
  <!-- ขวาล่าง: เช็คบัญชีคนโกง -->
  <a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50"
     href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
    <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
  </a>

  <!-- ซ้ายล่าง: โปรสดจากฟาร์ม -->
  <button id="openPromoFab" type="button"
          class="fixed left-4 bottom-4 rounded-full px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50 btn-glow"
          onclick="openPromo()">
    🎁 โปรสดจากฟาร์ม
  </button>

  <!-- ======= Promo Modal ======= -->
  <div id="promoRoot" class="modal-root" aria-hidden="true" style="display:none">
    <div id="promoBackdrop" class="modal-backdrop"></div>
    <div id="promoModal" class="modal" role="dialog" aria-modal="true" aria-labelledby="promoTitle" aria-describedby="promoDesc" tabindex="-1">
      <button class="close-x" type="button" aria-label="ปิด" onclick="closePromo()">✕</button>
      <div class="modal-header">
        <span class="text-sm px-2 py-1 rounded-full border bg-white">🎉 Limited</span>
        <h4 id="promoTitle" class="font-bold text-lg">โปรเปิดฤดู — ส่งฟรี/พรีออเดอร์ช่วยชาวสวนวางแผนเก็บเกี่ยว</h4>
      </div>
      <div class="modal-body">
        <div class="grid sm:grid-cols-2 gap-4 items-center">
          <div>
            <p id="promoDesc" class="text-gray-700">
              สั่งพรีออเดอร์วันนี้ รับสิทธิพิเศษสำหรับผัก ผลไม้ และไข่ออร์แกนิกจากชุมชน
              คัดสดจากฟาร์มจริง โปร่งใส ยุติธรรมต่อเกษตรกร
            </p>
            <ul class="list-disc pl-5 mt-3 text-sm text-gray-600 space-y-1">
              <li>🚚 ส่งฟรีเมื่อครบ 499 บาท (โซนที่ร่วมรายการ)</li>
              <li>🎫 พรีออเดอร์ช่วยชาวสวนวางแผนเก็บเกี่ยว ลดเหลือทิ้ง</li>
              <li>🧊 แพ็กเย็นรักษาความสดตลอดการขนส่ง</li>
              <li>🔁 การันตีความสด เปลี่ยน/คืนได้เมื่อไม่ตรงปก</li>
            </ul>
          </div>
          <div class="imgwrap">
            <img src="https://images.unsplash.com/photo-1506617420156-8e4536971650?q=80&w=1200&auto=format&fit=crop" alt="โปรสดจากฟาร์ม"/>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <a href="${ctx}/catalog/list?kw=โปร" class="btn btn-primary" onclick="ripple(event)">ดูสินค้าโปร</a>
        <button type="button" class="btn" onclick="ripple(event); closePromo()">ภายหลัง</button>
      </div>
    </div>
  </div>

  <!-- ======= Auth Gate Modal (namespaced ag-) ======= -->
  <div id="agAuthRoot" class="ag-root" aria-hidden="true">
    <div id="agBackdrop" class="ag-backdrop"></div>
    <div id="agWrap" class="ag-wrap" role="dialog" aria-modal="true" aria-labelledby="agTitle">
      <button class="ag-x" type="button" aria-label="ปิด" onclick="agCloseAuth()">✕</button>
      <div class="ag-head">
        <div id="agIcon" class="ag-ico">🔒</div>
        <div>
          <div id="agTitle" style="font-weight:700">เข้าสู่ระบบก่อนสั่งซื้อ</div>
          <div id="agKicker" style="font-size:12px;color:#475569">เพื่อความปลอดภัยของคำสั่งซื้อและการติดตามสถานะ</div>
        </div>
      </div>
      <div class="ag-body">
        <p id="agDesc">โปรดเข้าสู่ระบบเพื่อดำเนินการสั่งซื้อ ระบบจะช่วยเก็บประวัติ ออกใบสรุป และแจ้งสถานะออเดอร์แบบเรียลไทม์</p>
      </div>
      <div class="ag-foot">
        <a id="agPrimary"   href="#" class="btn btn-primary">เข้าสู่ระบบเพื่อสั่งซื้อ</a>
        <a id="agSecondary" href="#" class="btn">ดูสินค้าอื่นต่อ</a>
        <a id="agDanger"    href="#" class="btn" style="display:none;border-style:dashed">ออกจากระบบ</a>
      </div>
    </div>
  </div>

  <!-- ========= Scripts ========= -->
  <script>
    /* Profile menu */
    function toggleProfileMenu(e){
      e && e.stopPropagation();
      const m = document.getElementById('profileMenu');
      const b = document.getElementById('profileBtn');
      if(!m||!b) return;
      const hidden = m.classList.toggle('hidden');
      b.setAttribute('aria-expanded', hidden ? 'false' : 'true');
    }
    document.addEventListener('click',(e)=>{
      const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return;
      if(!b.contains(e.target) && !m.contains(e.target)){ m.classList.add('hidden'); b.setAttribute('aria-expanded','false'); }
    });

    /* Hero slider */
    (function(){
      const slides=document.querySelectorAll('.hero-slide');
      const dots  =document.querySelectorAll('.hero-dot');
      const prev  =document.getElementById('heroPrev');
      const next  =document.getElementById('heroNext');
      if(!slides.length) return;
      let i=0, timer=null;
      function show(n){
        const old=i; i=(n+slides.length)%slides.length;
        slides[old].classList.remove('active');
        slides[i].classList.add('active');
        if(dots.length){
          dots[old]?.classList.remove('bg-white'); dots[old]?.classList.add('bg-white/40');
          dots[i]?.classList.add('bg-white');      dots[i]?.classList.remove('bg-white/40');
        }
        restart();
      }
      function nextFn(){ show(i+1); }
      function prevFn(){ show(i-1); }
      function restart(){ if(timer) clearInterval(timer); timer=setInterval(nextFn, 5200); }
      prev && prev.addEventListener('click', prevFn);
      next && next.addEventListener('click', nextFn);
      dots.forEach((d,idx)=> d && d.addEventListener('click', ()=>show(idx)));
      show(0); restart();
    })();

    /* Reveal on scroll */
    (function(){
      const els = document.querySelectorAll('.reveal');
      if(!('IntersectionObserver' in window)){ els.forEach(e=>e.classList.add('in')); return; }
      const io = new IntersectionObserver((entries)=>{
        entries.forEach(en=>{ if(en.isIntersecting){ en.target.classList.add('in'); io.unobserve(en.target); } });
      }, { threshold:.18 });
      els.forEach(e=>io.observe(e));
    })();

    /* Back to top show/hide */
    (function(){
      const b = document.getElementById('toTop');
      const on = ()=>{ if(window.scrollY>300) b.classList.add('show'); else b.classList.remove('show'); };
      on(); window.addEventListener('scroll', on, {passive:true});
    })();

    /* Ripple effect */
    function ripple(e){
      const btn=e.currentTarget, rect=btn.getBoundingClientRect();
      const r=document.createElement('span');
      r.style.position='absolute'; r.style.borderRadius='9999px'; r.style.transform='scale(0)'; r.style.animation='ripple .6s linear';
      r.style.background='rgba(255,255,255,.55)'; r.style.pointerEvents='none';
      const d=Math.max(rect.width,rect.height);
      r.style.width=r.style.height=d+'px';
      r.style.left=(e.clientX-rect.left-d/2)+'px';
      r.style.top =(e.clientY-rect.top -d/2)+'px';
      btn.style.position='relative';
      btn.appendChild(r); setTimeout(()=>r.remove(),600);
    }
    (function(){ const s=document.createElement('style'); s.textContent='@keyframes ripple{to{transform:scale(8);opacity:0}}'; document.head.appendChild(s); })();

    /* Add-to-cart (AJAX + fallback) */
    function confirmAdd(e, productName){
      e.preventDefault();
      const form = e.currentTarget;
      const btn = form.querySelector('button[type="submit"]');
      try{
        const body = new URLSearchParams(new FormData(form)).toString();
        btn && (btn.disabled=true, btn.style.opacity='.7');
        fetch(form.action, {method:'POST', headers:{'X-Requested-With':'XMLHttpRequest','Content-Type':'application/x-www-form-urlencoded'}, body})
          .then(r=>r.text().then(t=>{let j=null;try{j=JSON.parse(t)}catch{};return {ok:r.ok, j, status:r.status}}))
          .then(({ok,j})=>{
            if(!ok) throw 0;
            const count = j && typeof j.cartCount!=='undefined' ? parseInt(j.cartCount,10) : null;
            const b = document.querySelector('a[href$="/cart"] .badge'); if(b){ b.textContent = count!=null?count:String((+b.textContent||0)+1); }
            showToast('เพิ่มลงตะกร้าแล้ว', productName||'สินค้า');
            btn && (btn.disabled=false, btn.style.opacity='');
          }).catch(()=>{ btn && (btn.disabled=false, btn.style.opacity=''); form.submit(); });
      }catch(_){ form.submit(); }
      return false;
    }
    function showToast(title, desc){
      const host=document.getElementById('toastRoot'); if(!host) return;
      const el=document.createElement('div');
      el.className='bg-white border border-emerald-200 rounded-xl shadow-xl px-3 py-2 flex items-start gap-2';
      el.innerHTML='<div>✅</div><div><div class="font-bold text-emerald-700">'+(title||'สำเร็จ')+'</div><div class="text-sm">'+(desc||'เพิ่มลงตะกร้าแล้ว')+'</div></div>';
      host.appendChild(el); setTimeout(()=>{ el.style.opacity='.0'; el.style.transform='translateY(6px)'; setTimeout(()=>el.remove(),250); },2200);
    }

    /* ===== Promo modal open/close + a11y ===== */
    const promoRoot = document.getElementById('promoRoot');
    const promoBackdrop = document.getElementById('promoBackdrop');
    const promoModal = document.getElementById('promoModal');

    function openPromo(){
      if(!promoRoot) return;
      promoRoot.style.display='grid';
      requestAnimationFrame(()=>{ promoBackdrop.classList.add('show'); promoModal.classList.add('show'); });
      document.body.style.overflow='hidden';
      trapFocus(promoModal);
    }
    function closePromo(){
      if(!promoRoot) return;
      promoBackdrop.classList.remove('show'); promoModal.classList.remove('show');
      setTimeout(()=>{ promoRoot.style.display='none'; document.body.style.overflow=''; }, 220);
    }
    document.getElementById('openPromoFab')?.addEventListener('click', openPromo);
    promoBackdrop?.addEventListener('click', closePromo);
    document.addEventListener('keydown', e => { if(e.key==='Escape') closePromo(); });

    function trapFocus(root){
      try{
        const f = root.querySelectorAll('a,button,input,select,textarea,[tabindex]:not([tabindex="-1"])');
        if(!f.length) return; let first=f[0], last=f[f.length-1]; first.focus();
        root.addEventListener('keydown', (e)=>{
          if(e.key!=='Tab') return;
          if(e.shiftKey){ if(document.activeElement===first){ e.preventDefault(); last.focus(); } }
          else{ if(document.activeElement===last){ e.preventDefault(); first.focus(); } }
        });
      }catch(_){}
    }

    /* ===== Auth Gate (namespaced ag-) ===== */
    const agRoot = document.getElementById('agAuthRoot');
    const agBackdrop = document.getElementById('agBackdrop');
    const agWrap = document.getElementById('agWrap');
    function agOpenAuth(mode, next){
      if(!agRoot) return;
      mode = mode || 'guest';
      next = next || (location.pathname + location.search);

      const t=document.getElementById('agTitle');
      const k=document.getElementById('agKicker');
      const d=document.getElementById('agDesc');
      const ic=document.getElementById('agIcon');
      const p=document.getElementById('agPrimary');
      const s=document.getElementById('agSecondary');
      const g=document.getElementById('agDanger');

      agRoot.style.display='grid';
      requestAnimationFrame(()=>{ agRoot.classList.add('ag-show'); });

      if(mode==='guest'){
        ic.textContent='🔒';
        t.textContent='เข้าสู่ระบบก่อนสั่งซื้อ';
        k.textContent='เพื่อความปลอดภัยของคำสั่งซื้อและการติดตามสถานะ';
        d.textContent='กรุณาเข้าสู่ระบบก่อนสั่งซื้อ เพื่อผูกออเดอร์กับบัญชีของคุณและรับการแจ้งเตือน';
        p.textContent='เข้าสู่ระบบเพื่อสั่งซื้อ';
        p.href='${ctx}/login?next='+encodeURIComponent(next);
        s.textContent='ดูสินค้าอื่นต่อ';
        s.href='${ctx}/catalog/list';
        g.style.display='none';
      }
      if(mode==='farmer'){
        ic.textContent='👨‍🌾';
        t.textContent='สำหรับผู้ซื้อเท่านั้น';
        k.textContent='บัญชีเกษตรกรไม่สามารถทำรายการสั่งซื้อได้';
        d.textContent='หากต้องการสั่งซื้อ โปรดออกจากระบบ และเข้าสู่ระบบด้วยบัญชีผู้ซื้อ';
        p.textContent='เข้าสู่ระบบผู้ซื้อ';
        p.href='${ctx}/login?next='+encodeURIComponent(next);
        s.textContent='กลับไปดูสินค้า';
        s.href='${ctx}/catalog/list';
        g.style.display='inline-flex';
        g.textContent='ออกจากระบบ';
        g.href='${ctx}/logout';
      }

      agBackdrop.onclick=agCloseAuth;
      document.addEventListener('keydown', agEscOnce);
      trapFocus(agWrap);
    }
    function agCloseAuth(){
      if(!agRoot) return;
      agRoot.classList.remove('ag-show');
      setTimeout(()=>{ agRoot.style.display='none'; }, 220);
      document.removeEventListener('keydown', agEscOnce);
    }
    function agEscOnce(e){ if(e.key==='Escape') agCloseAuth(); }
    function agLoginRequired(e){
      e.preventDefault();
      const next = e.currentTarget?.dataset?.next || (location.pathname + location.search);
      agOpenAuth('guest', next);
    }
    function agRoleRequired(e){
      e.preventDefault();
      const next = e.currentTarget?.dataset?.next || (location.pathname + location.search);
      agOpenAuth('farmer', next);
    }
  </script>
</body>
</html>
