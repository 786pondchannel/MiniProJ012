<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />
<%
  request.setCharacterEncoding("UTF-8");
%>

<!-- ===== ctx / user ===== -->
<c:if test="${empty ctx}">
  <c:set var="ctx" value="${pageContext.request.contextPath}"/>
</c:if>
<c:set var="user" value="${sessionScope.loggedInUser}"/>

<!-- ===== cartCount: คำนวณจาก cart ก่อนเสมอ (ไม่มีค่อย fallback session) ===== -->
<c:set var="cartCount" value="0"/>
<c:if test="${not empty cart and not empty cart.byFarmer}">
  <c:forEach var="entry" items="${cart.byFarmer}">
    <c:set var="vcart" value="${entry.value}"/>
    <c:if test="${not empty vcart and not empty vcart.items}">
      <c:forEach var="it" items="${vcart.items}">
        <c:set var="qtySafe" value="${empty it.qty ? 0 : it.qty}"/>
        <c:set var="cartCount" value="${cartCount + qtySafe}"/>
      </c:forEach>
    </c:if>
  </c:forEach>
</c:if>
<c:if test="${cartCount == 0 && not empty sessionScope.cartCount}">
  <c:set var="cartCount" value="${sessionScope.cartCount}"/>
</c:if>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>ร้านเกษตรกรบ้านเรา • ตะกร้า</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --emerald:#10b981; --emerald600:#059669; --ink:#0f172a; --muted:#6b7280; --border:#e5e7eb; }
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
    .icon-btn{position:relative; display:inline-flex; align-items:center; gap:.4rem}
    .card{ background:#fff; border:1px solid var(--border); border-radius:16px; box-shadow:0 10px 26px rgba(2,8,23,.05) }
    .imgwrap{ width:64px;height:64px; overflow:hidden; border-radius:12px; border:1px solid #eef2f7; background:#f8fafc; display:grid; place-items:center }
    .imgwrap img{ width:100%; height:100%; object-fit:cover }
    .btn{display:inline-flex;align-items:center;gap:.5rem;padding:.6rem .9rem;border-radius:12px;border:1px solid var(--border);background:#fff;transition:transform .12s, box-shadow .2s, border-color .2s}
    .btn:hover{transform:translateY(-1px); box-shadow:0 10px 20px rgba(16,185,129,.12); border-color:#d1fae5}
    .btn-primary{ background:linear-gradient(135deg,var(--emerald),var(--emerald600)); color:#fff; border-color:transparent }
    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }
  </style>
</head>

<body class="bg-farm min-h-screen flex flex-col">

  <!-- ============== Header ============== -->
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
                <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10 icon-btn">
                  <i class="fa-solid fa-basket-shopping"></i> ตะกร้า <span class="badge">${cartCount}</span>
                </a>
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
              <button id="profileBtn" onclick="toggleProfileMenu()" class="inline-flex items-center ml-2 px-3 py-1 bg-white/20 hover:bg-white/35 backdrop-blur rounded-full text-sm font-medium transition focus:outline-none focus:ring-2 focus:ring-green-300 group" type="button">
                <img src="${avatarUrl}?t=${now.time}" alt="โปรไฟล์" class="h-8 w-8 rounded-full border-2 border-white shadow-md mr-2 object-cover"/>
                สวัสดี, ${sessionScope.loggedInUser.fullname}
                <svg class="w-4 h-4 ml-1 text-white transform transition-transform group-hover:rotate-180" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
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

  <!-- Flash -->
  <c:if test="${not empty msg}">
    <div class="container mx-auto px-6 mt-6">
      <div class="bg-emerald-50 text-emerald-800 border border-emerald-200 px-4 py-3 rounded">
        <i class="fa-solid fa-circle-check mr-2"></i> ${msg}
      </div>
    </div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="container mx-auto px-6 mt-6">
      <div class="bg-red-50 text-red-700 border border-red-200 px-4 py-3 rounded">
        <i class="fa-solid fa-triangle-exclamation mr-2"></i> ${error}
      </div>
    </div>
  </c:if>

  <!-- ============== Main ============== -->
  <main class="container mx-auto px-6 py-8 flex-1">
    <div class="flex flex-col lg:flex-row gap-8">
      <!-- ตะกร้า -->
      <div class="lg:w-2/3">
        <div class="bg-white p-6 rounded-lg shadow-md">
          <div class="flex items-center justify-between mb-6">
            <a href="${ctx}/catalog/list" class="text-emerald-700 hover:underline inline-flex items-center">
              <i class="fa-solid fa-chevron-left mr-2"></i> กลับไปเลือกสินค้า
            </a>
            <form action="${ctx}/cart/clear" method="post">
              <c:if test="${not empty _csrf}">
                <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
              </c:if>
              <button class="text-sm text-gray-500 hover:text-red-600" onclick="return confirm('ล้างตะกร้าทั้งหมด?');">
                ล้างตะกร้าทั้งหมด
              </button>
            </form>
          </div>

          <h2 class="text-2xl font-semibold mb-4">ตะกร้าสินค้าของคุณ</h2>

          <c:if test="${empty cart or empty cart.byFarmer}">
            <div class="border border-dashed border-gray-300 rounded p-12 text-center text-gray-500">
              ยังไม่มีสินค้าในตะกร้า
              <div class="mt-4">
                <a href="${ctx}/catalog/list" class="btn btn-primary shadow-lg">
                  <i class="fa-solid fa-bag-shopping"></i> เริ่มเลือกสินค้า
                </a>
              </div>
            </div>
          </c:if>

          <!-- วนทีละร้าน -->
          <c:forEach var="entry" items="${cart.byFarmer}">
            <c:set var="farmerId" value="${entry.key}"/>
            <c:set var="vcart" value="${entry.value}"/>

            <div class="rounded-xl border bg-gray-50 p-5 mb-6">
              <div class="flex items-start justify-between mb-4">
                <div>
                  <h3 class="text-xl font-bold flex items-center">
                    <i class="fa-solid fa-store mr-2 text-emerald-600"></i>
                    <c:out value="${empty vcart.farmerName ? 'ร้านไม่ระบุชื่อ' : vcart.farmerName}"/>
                  </h3>
                  <p class="text-sm text-gray-500">รหัสร้าน: <span class="font-mono"><c:out value="${farmerId}"/></span></p>
                </div>
                <div class="text-right">
                  <p class="text-sm text-gray-500">รวมร้านนี้</p>
                  <p class="text-xl font-semibold text-emerald-700">
                    <c:set var="subtotalSafe" value="${empty vcart.subtotal ? 0 : vcart.subtotal}"/>
                    ฿<fmt:formatNumber value="${subtotalSafe}" type="number" maxFractionDigits="0" groupingUsed="false"/>
                  </p>
                </div>
              </div>

              <!-- รายการสินค้า -->
              <div class="space-y-3">
                <c:forEach var="it" items="${vcart.items}">
                  <c:set var="pname" value="${empty it.productName ? (empty it.name ? 'สินค้าของฉัน' : it.name) : it.productName}"/>
                  <c:set var="priceSafe" value="${empty it.price ? 0 : it.price}"/>
                  <c:set var="qtySafe" value="${empty it.qty ? 1 : it.qty}"/>
                  <c:set var="lineTotal" value="${priceSafe * qtySafe}"/>
                  <c:set var="pid" value="${empty it.productId ? it.id : it.productId}"/>

                  <!-- ดักรูปต่อรายการ: ไม่มีรูป = ไม่แสดง <img> -->
                  <c:set var="imgUrl" value=""/>
                  <c:catch var="imgErr">
                    <c:set var="imgRaw" value="${empty it.img ? (empty it.imageUrl ? '' : it.imageUrl) : it.img}"/>
                    <c:if test="${not empty imgRaw}">
                      <c:choose>
                        <c:when test="${fn:startsWith(imgRaw,'http')}"><c:set var="imgUrl" value="${imgRaw}"/></c:when>
                        <c:when test="${fn:startsWith(imgRaw,'/uploads/')}"><c:set var="imgUrl" value='${ctx}${imgRaw}'/></c:when>
                        <c:when test="${fn:startsWith(imgRaw,'uploads/')}"><c:set var="imgUrl" value='${ctx}/${imgRaw}'/></c:when>
                        <c:otherwise><c:set var="imgUrl" value='${ctx}/uploads/${imgRaw}'/></c:otherwise>
                      </c:choose>
                    </c:if>
                  </c:catch>
                  <c:if test="${not empty imgErr}"><c:set var="imgUrl" value=""/></c:if>

                  <div class="flex items-center justify-between bg-white p-4 rounded-lg shadow-sm product-card">
                    <div class="flex items-center">
                      <div class="imgwrap">
                        <c:choose>
                          <c:when test="${not empty imgUrl}">
                            <img src="${imgUrl}" alt="${fn:escapeXml(pname)}" onerror="this.remove();"/>
                          </c:when>
                          <c:otherwise>
                            <i class="fa-regular fa-image text-gray-300 text-xl" aria-hidden="true"></i>
                          </c:otherwise>
                        </c:choose>
                      </div>
                      <div class="ml-4">
                        <p class="font-medium"><c:out value="${pname}"/></p>
                        <p class="text-gray-500 text-sm">
                          ราคา/ต่อ 1 กิโลกรัม:
                          <b>฿<fmt:formatNumber value="${priceSafe}" type="number" maxFractionDigits="0" groupingUsed="false"/></b>
                        </p>
                      </div>
                    </div>

                    <!-- จำนวน -->
                    <div class="flex items-center space-x-2">
                      <!-- ลด -->
                      <form action="${ctx}/cart/update" method="post" class="inline">
                        <c:if test="${not empty _csrf}">
                          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
                        </c:if>
                        <input type="hidden" name="farmerId" value="${farmerId}"/>
                        <input type="hidden" name="productId" value="${pid}"/>
                        <input type="hidden" name="qty" value="${qtySafe - 1}"/>
                        <button class="bg-gray-200 text-gray-700 px-3 py-1 rounded hover:bg-gray-300"
                                title="ลดจำนวน" <c:if test="${qtySafe <= 1}">disabled</c:if>>
                          <i class="fa-solid fa-minus"></i>
                        </button>
                      </form>

                      <span class="w-8 text-center select-none"><c:out value="${qtySafe}"/></span>

                      <!-- เพิ่ม -->
                      <form action="${ctx}/cart/update" method="post" class="inline">
                        <c:if test="${not empty _csrf}">
                          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
                        </c:if>
                        <input type="hidden" name="farmerId" value="${farmerId}"/>
                        <input type="hidden" name="productId" value="${pid}"/>
                        <input type="hidden" name="qty" value="${qtySafe + 1}"/>
                        <button class="bg-gray-200 text-gray-700 px-3 py-1 rounded hover:bg-gray-300" title="เพิ่มจำนวน">
                          <i class="fa-solid fa-plus"></i>
                        </button>
                      </form>
                    </div>

                    <!-- รวมต่อรายการ + ลบ -->
                    <div class="text-right">
                      <p class="text-lg font-semibold text-emerald-700">
                        ฿<fmt:formatNumber value="${lineTotal}" type="number" maxFractionDigits="0" groupingUsed="false"/>
                      </p>
                      <form action="${ctx}/cart/remove" method="post" onsubmit="return confirm('ลบสินค้านี้ออกจากตะกร้า?');">
                        <c:if test="${not empty _csrf}">
                          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
                        </c:if>
                        <input type="hidden" name="farmerId" value="${farmerId}"/>
                        <input type="hidden" name="productId" value="${pid}"/>
                        <button class="text-red-500 hover:text-red-700 text-sm mt-1">
                          <i class="fa-solid fa-trash-can mr-1"></i> ลบ
                        </button>
                      </form>
                    </div>
                  </div>
                </c:forEach>
              </div>

              <!-- ส่งพรีออเดอร์ร้านนี้ -->
              <div class="mt-5 flex items-center justify-between">
                <div class="text-sm text-gray-500">
                  ระบบจะ <b>ส่งคำสั่งพรีออเดอร์</b> ให้ร้านนี้ก่อน (เกษตรกรกดยืนยัน → จึงชำระเงิน)
                </div>
                <form action="${ctx}/cart/checkout" method="post">
                  <c:if test="${not empty _csrf}">
                    <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
                  </c:if>
                  <input type="hidden" name="farmerId" value="${farmerId}"/>
                  <button class="btn btn-primary shadow-lg">
                    <i class="fa-solid fa-paper-plane mr-2"></i> ส่งคำสั่งพรีออเดอร์ให้ร้านนี้
                  </button>
                </form>
              </div>
            </div>
          </c:forEach>
        </div>
      </div>

      <!-- สรุปยอด -->
      <div class="lg:w-1/3">
        <div class="bg-white p-6 rounded-lg shadow-md sticky top-8">
          <h2 class="text-xl font-semibold mb-4">สรุปยอดชำระ</h2>

          <c:set var="grandSafe" value="${empty cart.grandTotal ? 0 : cart.grandTotal}"/>
          <div class="flex justify-between text-gray-700 mb-2">
            <span>ยอดรวมทุกบิล:</span>
            <span class="font-semibold text-lg text-emerald-700">
              ฿<fmt:formatNumber value="${grandSafe}" type="number" maxFractionDigits="0" groupingUsed="false"/>
            </span>
          </div>
          <p class="text-xs text-gray-500 mb-4">ออกใบสั่งซื้อ <b>แยกตามร้าน</b></p>

          <h3 class="text-lg font-semibold mb-2">ที่อยู่สำหรับจัดส่ง</h3>

          <c:choose>
            <c:when test="${not empty user && not empty user.address}">
              <div class="border rounded-lg p-4 bg-gray-50">
                <p class="font-medium"><c:out value="${user.fullname}"/></p>
                <p class="text-gray-600"><c:out value="${user.address}"/></p>
                <p class="text-gray-600">โทร: <c:out value="${user.phoneNumber}"/></p>
              </div>
              <div class="text-xs text-gray-500 mt-2">สามารถแก้ไขได้ที่หน้าโปรไฟล์</div>
            </c:when>
            <c:otherwise>
              <button onclick="location.href='${ctx}/profile/edit';"
                      class="bg-blue-500 text-white px-4 py-2 rounded mb-4 hover:bg-blue-600 w-full">
                <i class="fa-solid fa-plus mr-1"></i> เพิ่ม/แก้ไขที่อยู่
              </button>
              <div class="flex flex-col items-center justify-center bg-gray-100 p-6 rounded-lg">
                <i class="fa-solid fa-location-dot text-gray-300 text-6xl mb-4"></i>
                <p class="text-gray-500">ยังไม่มีที่อยู่จัดส่ง</p>
              </div>
            </c:otherwise>
          </c:choose>

          <div class="mt-6 space-y-2 text-sm text-gray-500">
            <div class="flex items-center"><i class="fa-solid fa-truck-fast mr-2"></i> จัดส่งหลังรอบพรีออเดอร์</div>
            <div class="flex items-center"><i class="fa-regular fa-comments mr-2"></i> คุยรายละเอียดกับร้านได้หลังส่งคำสั่ง</div>
            <div class="flex items-center"><i class="fa-solid fa-receipt mr-2"></i> ร้านจะกดยืนยันก่อน แล้วจึงชำระเงิน</div>
          </div>
        </div>
      </div>
    </div>
  </main>

  <!-- ============== Footer ============== -->
  <footer class="footer-dark mt-10 mt-auto">
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
        <a class="btn btn-primary shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
    <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
  </a>

  <!-- ============== Scripts ============== -->
  <script>
    function toggleProfileMenu(){
      const m=document.getElementById('profileMenu'); if(!m) return;
      m.classList.toggle('hidden');
    }
    document.addEventListener('click',(e)=>{
      const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return; if(!b.contains(e.target) && !m.contains(e.target)) m.classList.add('hidden');
    });
  </script>
</body>
</html>
