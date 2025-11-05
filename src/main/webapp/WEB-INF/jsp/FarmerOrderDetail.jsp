<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"  %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />

<c:if test="${empty ctx}">
  <c:set var="ctx" value="${pageContext.request.contextPath}"/>
</c:if>
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>รายละเอียดคำสั่งซื้อ • เกษตรกรบ้านเรา</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --ink:#0f172a; --muted:#6b7280; --border:#e5e7eb; }
    *{ font-family:'Prompt',system-ui,Segoe UI,Roboto,sans-serif }
    body{ color:var(--ink) }
    .page-wrap{ background:linear-gradient(180deg,#f0fdfa 0%,#ffffff 22%,#ffffff 100%) }

    /* Header (ดำเหมือนหน้าอื่น) */
    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    /* Cards / Buttons (ขาว) */
    .card{ background:#fff; border:1px solid var(--border); border-radius:18px; box-shadow:0 10px 25px rgba(2,8,23,.06) }
    .btn{ display:inline-flex; align-items:center; gap:.55rem; padding:.6rem 1rem; border-radius:.8rem; font-weight:700; border:1px solid #e5e7eb; background:#fff }
    .btn:hover{ filter:brightness(0.98) }
    .btn-sm{ padding:.45rem .75rem; font-weight:600; }
    .btn-emerald{ color:#fff; background:#16a34a; border-color:#16a34a }
    .btn-amber{   color:#fff; background:#f59e0b; border-color:#f59e0b }
    .btn-sky{     color:#fff; background:#0284c7; border-color:#0284c7 }
    .btn-teal{    color:#fff; background:#14b8a6; border-color:#14b8a6 }
    .btn-danger{  color:#fff; background:#ef4444; border-color:#ef4444 }

    /* Stats */
    .stats{ display:grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap:14px }
    @media(min-width:768px){ .stats{ grid-template-columns: repeat(4,minmax(0,1fr)); } }
    .stat{ background:#fff; border:1px solid var(--border); border-radius:14px; padding:14px; box-shadow:0 6px 14px rgba(2,8,23,.05) }
    .stat .k{ font-size:.8rem; color:var(--muted) }
    .stat .v.big{ font-size:1.4rem; line-height:1.2; font-weight:800 }

    /* Timeline (สว่าง) */
    .timeline{ margin-top:12px }
    .step{ display:flex; align-items:center; gap:.6rem; position:relative; padding:.35rem 0 }
    .step:before{ content:""; position:absolute; left:10px; top:20px; bottom:-10px; width:2px; background:#e5e7eb }
    .step:last-child:before{ display:none }
    .dot{ width:16px; height:16px; border-radius:9999px; border:2px solid #10b981; background:#fff; box-shadow:0 0 0 5px rgba(16,185,129,.12) }
    .step.live .dot{ background:#10b981; box-shadow:0 0 0 6px rgba(16,185,129,.22) }
    .step.done .dot{ background:#10b981; opacity:.9 }
    .ico{ width:18px; text-align:center; opacity:.9 }
    .progress{ height:8px; background:#e5e7eb; border-radius:999px; overflow:hidden; margin-top:.7rem }
    .progress .bar{ height:100%; width:0; background:linear-gradient(90deg,#34d399,#10b981); transition:width .6s cubic-bezier(.22,.8,.2,1) }

    /* Table */
    table{ width:100% } thead{ color:#334155 } tbody td{ color:#0f172a }
    tr{ border-bottom:1px solid #e5e7eb } tr:hover{ background:#f8fafc }

    /* Image */
    .img-card{ position:relative; overflow:hidden; border-radius:12px; border:1px solid #e5e7eb; background:#fff }
    .img-fit{ width:100%; height:100%; object-fit:cover; display:block }

    /* Footer */
    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb } .footer-dark a:hover{ color:#a7f3d0 }

    /* Alerts */
    .alert{ border-radius:14px; padding:12px 14px; display:flex; gap:12px; align-items:flex-start; box-shadow:0 6px 16px rgba(2,8,23,.08) }
    .alert-info{ background:#eff6ff; border:1px solid #bfdbfe; color:#1e3a8a; border-left-width:6px; border-left-color:#60a5fa }
  </style>
</head>

<body class="page-wrap min-h-screen">
  <!-- ================= Header ================= -->
  <header class="header shadow-md text-white">
    <div class="container mx-auto px-6 py-3 grid grid-cols-[auto_1fr_auto] items-center gap-3">
      <div class="flex items-center gap-3">
        <a href="${ctx}/main" class="flex items-center gap-3 shrink-0">
          <img src="https://cdn-icons-png.flaticon.com/512/2909/2909763.png" class="h-8 w-8" alt="logo"/>
          <span class="hidden sm:inline font-bold">เกษตรกรบ้านเรา</span>
        </a>
        <nav class="nav-scroll ml-2">
          <div class="flex items-center gap-2 md:gap-3 whitespace-nowrap text-[13px] md:text-sm">
            <a href="${ctx}/product/list/Farmer" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-rectangle-list"></i> สินค้าของฉัน</a>
            <a href="${ctx}/farmer/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-truck"></i> ออเดอร์</a>
            <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-basket-shopping"></i> ตะกร้า <span class="badge">${cartCount}</span></a>
          </div>
        </nav>
      </div>

      <form method="get" action="${ctx}/catalog/list" class="hidden sm:block w-full max-w-xl justify-self-center">
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
  <!-- ================= /Header ================= -->

  <main class="container mx-auto px-4 sm:px-6 py-6 lg:py-10">
    <!-- ไม่พบบิล -->
    <c:if test="${empty orderHeader}">
      <div class="card p-6">
        <h2 class="text-xl font-semibold mb-2">ไม่พบบิล หรือคุณไม่มีสิทธิ์เข้าถึง</h2>
        <a href="${ctx}/farmer/orders" class="btn">← กลับไปหน้าออเดอร์</a>
      </div>
    </c:if>

    <!-- พบบิล -->
    <c:if test="${not empty orderHeader}">
      <c:set var="ost" value="${orderHeader.orderStatus}"/>
      <c:set var="pst" value="${orderHeader.paymentStatus}"/>
      <c:set var="OST" value="${fn:toUpperCase(ost)}"/>
      <c:set var="PST" value="${fn:toUpperCase(pst)}"/>

      <!-- Step 1–6 -->
      <c:set var="hasSlip" value="${not empty orderReceipts and fn:length(orderReceipts) gt 0}"/>
      <c:set var="cur6" value="1"/>
      <c:choose>
        <c:when test="${OST == 'COMPLETED' || OST == 'REJECTED' || OST == 'CANCELED'}"><c:set var="cur6" value="6"/></c:when>
        <c:when test="${OST == 'SHIPPED'}"><c:set var="cur6" value="5"/></c:when>
        <c:when test="${OST == 'PREPARING_SHIPMENT' || PST == 'PAID_CONFIRMED'}"><c:set var="cur6" value="4"/></c:when>
        <c:when test="${hasSlip}"><c:set var="cur6" value="3"/></c:when>
        <c:when test="${OST != 'SENT_TO_FARMER'}"><c:set var="cur6" value="2"/></c:when>
        <c:otherwise><c:set var="cur6" value="1"/></c:otherwise>
      </c:choose>
      <c:set var="prog" value="${(cur6-1)*20}"/>

      <!-- Next action -->
      <c:set var="next" value="none"/>
      <c:choose>
        <c:when test="${OST == 'SENT_TO_FARMER'}"><c:set var="next" value="confirm"/></c:when>
        <c:when test="${PST != 'PAID_CONFIRMED'}"><c:set var="next" value="verify"/></c:when>
        <c:when test="${OST == 'FARMER_CONFIRMED'}"><c:set var="next" value="prepare"/></c:when>
        <c:when test="${OST == 'PREPARING_SHIPMENT'}"><c:set var="next" value="ship"/></c:when>
        <c:when test="${OST == 'SHIPPED'}"><c:set var="next" value="complete"/></c:when>
        <c:otherwise><c:set var="next" value="none"/></c:otherwise>
      </c:choose>

      <!-- แถบหัวเรื่อง -->
      <div class="card p-6 mb-6">
        <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-6">
          <div>
            <div class="text-xs text-slate-500">คำสั่งซื้อ</div>
            <div class="text-2xl font-extrabold">#<span class="font-mono"><c:out value="${orderHeader.orderId}" default="-"/></span></div>

            <div class="stats mt-4">
              <div class="stat">
                <div class="k">วันที่สั่ง</div>
                <div class="v big">
                  <c:choose>
                    <c:when test="${not empty orderHeader.orderDate}">
                      <fmt:formatDate value="${orderHeader.orderDate}" pattern="dd/MM/yyyy"/>
                    </c:when>
                    <c:otherwise>-</c:otherwise>
                  </c:choose>
                </div>
              </div>
              <div class="stat">
                <div class="k">ยอดรวม</div>
                <div class="v big text-emerald-700">฿<fmt:formatNumber value="${orderHeader.totalPrice}" minFractionDigits="2" maxFractionDigits="2"/></div>
              </div>
              <div class="stat">
                <div class="k">สถานะออเดอร์</div>
                <div class="v"><span class="inline-flex items-center gap-2 px-2 py-1 rounded-full border text-sm bg-white"><span>🧾</span><c:out value="${ost}" default="-"/></span></div>
              </div>
              <div class="stat">
                <div class="k">สถานะชำระเงิน</div>
                <div class="v"><span class="inline-flex items-center gap-2 px-2 py-1 rounded-full border text-sm bg-white"><span>💳</span><c:out value="${pst}" default="-"/></span></div>
              </div>
            </div>

            <!-- Timeline -->
            <div class="timeline mt-5 text-[0.98rem]">
              <div class="step ${cur6 >= 1 ? (cur6==1?'live':'done') : ''}">
                <span class="dot"></span><span class="ico">✅</span><span>1) ร้านยืนยัน</span>
              </div>
              <div class="step ${cur6 >= 2 ? (cur6==2?'live':'done') : ''}">
                <span class="dot"></span><span class="ico">💳</span><span>2) ผู้ซื้อชำระ/อัปโหลดสลิป</span>
              </div>
              <div class="step ${cur6 >= 3 ? (cur6==3?'live':'done') : ''}">
                <span class="dot"></span><span class="ico">🔍</span><span>3) ร้านตรวจสลิป</span>
              </div>
              <div class="step ${cur6 >= 4 ? (cur6==4?'live':'done') : ''}">
                <span class="dot"></span><span class="ico">📦</span><span>4) เตรียมจัดส่ง</span>
              </div>
              <div class="step ${cur6 >= 5 ? (cur6==5?'live':'done') : ''}">
                <span class="dot"></span><span class="ico">🚚</span><span>5) จัดส่งแล้ว</span>
              </div>
              <div class="step ${cur6 >= 6 ? 'live' : ''}">
                <span class="dot"></span><span class="ico">🏁</span>
                <span><c:choose><c:when test="${OST == 'REJECTED' || OST == 'CANCELED'}">6) ยกเลิก</c:when><c:otherwise>6) เสร็จสิ้น</c:otherwise></c:choose></span>
              </div>
              <div class="progress"><div id="stepBar" class="bar" data-target="${prog}"></div></div>
            </div>
          </div>

          <!-- ปุ่มการกระทำ (จัดชิดขวาสุด) -->
          <div class="w-full lg:w-auto lg:ml-auto flex flex-col items-end gap-1 text-right">
            <div class="flex flex-wrap gap-2 justify-end">
              <a href="${ctx}/farmer/orders" class="btn">← กลับ</a>

              <c:if test="${next == 'confirm'}">
                <form action="${ctx}/farmer/orders/${orderHeader.orderId}/confirm" method="post">
                  <c:if test="${not empty _csrf}"><input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/></c:if>
                  <button class="btn btn-emerald"><i class="fa-solid fa-check"></i> ยืนยันคำสั่งซื้อ</button>
                </form>
              </c:if>

              <!-- กดยืนยันรับชำระได้เสมอ -->
              <c:if test="${next == 'verify'}">
                <form action="${ctx}/farmer/orders/${orderHeader.orderId}/verify-payment" method="post">
                  <c:if test="${not empty _csrf}"><input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/></c:if>
                  <button class="btn btn-amber"><i class="fa-solid fa-receipt"></i> ยืนยันรับชำระเงินแล้ว</button>
                </form>
              </c:if>

              <c:if test="${next == 'prepare'}">
                <form action="${ctx}/farmer/orders/${orderHeader.orderId}/prepare" method="post">
                  <c:if test="${not empty _csrf}"><input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/></c:if>
                  <button class="btn btn-sky"><i class="fa-solid fa-boxes-packing"></i> เริ่มเตรียมจัดส่ง</button>
                </form>
              </c:if>

              <c:if test="${next == 'ship'}">
                <button onclick="openModal('modalShip')" class="btn btn-teal">
                  <i class="fa-solid fa-calendar-check"></i> บันทึกกำหนดส่งให้ลูกค้า
                </button>
              </c:if>

              <c:if test="${next == 'complete'}">
                <form action="${ctx}/farmer/orders/${orderHeader.orderId}/complete" method="post">
                  <c:if test="${not empty _csrf}"><input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/></c:if>
                  <button class="btn btn-emerald"><i class="fa-solid fa-flag-checkered"></i> ปิดงาน (สำเร็จ)</button>
                </form>
              </c:if>
            </div>

            <!-- ข้อความแจ้งเตือนชิดขวา -->
            <c:if test="${next == 'verify' && not hasSlip}">
              <div class="text-xs text-slate-500 mt-1">ยังไม่พบสลิปจากลูกค้า แต่คุณยังสามารถยืนยันรับชำระได้</div>
            </c:if>
          </div>
        </div>

        <div class="mt-3 alert alert-info">
          <i class="fa-solid fa-circle-info mt-0.5"></i>
          <div>ลำดับงาน: ยืนยัน → ตรวจ/ยืนยันเงิน → เตรียม → กำหนดวันส่ง → ปิดงาน</div>
        </div>
      </div>

      <!-- Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- ซ้าย -->
        <div class="lg:col-span-2 space-y-6">
          <!-- รายการสินค้า -->
          <div class="card p-6">
            <h3 class="text-lg font-semibold mb-4">รายการสินค้า</h3>
            <c:if test="${empty orderItems}">
              <div class="text-slate-600 text-sm">ไม่มีสินค้าในบิลนี้</div>
            </c:if>
            <c:if test="${not empty orderItems}">
              <div class="overflow-x-auto">
                <table class="text-sm">
                  <thead class="text-left">
                    <tr class="border-b">
                      <th class="py-2">สินค้า</th>
                      <th class="py-2 text-center">จำนวน</th>
                      <th class="py-2 text-right">รวม</th>
                    </tr>
                  </thead>
                  <tbody>
                    <c:forEach var="it" items="${orderItems}">
                      <tr class="border-b hover:bg-slate-50">
                        <td class="py-3">
                          <div class="flex items-center gap-3">
                            <c:set var="pimg" value="${not empty it.img ? it.img : (not empty it.imageUrl ? it.imageUrl : it.image)}"/>
                            <div class="img-card w-16 h-16">
                              <c:choose>
                                <c:when test="${not empty pimg}">
                                  <img data-raw="${fn:escapeXml(pimg)}" class="img-fit" loading="lazy"
                                       alt="${it.productName}" src="https://via.placeholder.com/80x80?text=Loading..."
                                       onerror="this.onerror=null;this.src='https://via.placeholder.com/120?text=No+Image';"/>
                                </c:when>
                                <c:otherwise><img class="img-fit" alt="no-image" src="https://via.placeholder.com/120?text=No+Image"/></c:otherwise>
                              </c:choose>
                            </div>
                            <div>
                              <div class="font-medium"><c:out value="${it.productName}"/></div>
                              <div class="text-[11px] text-slate-500">฿<fmt:formatNumber value="${it.price}" minFractionDigits="2" maxFractionDigits="2"/> /หน่วย</div>
                            </div>
                          </div>
                        </td>
                        <td class="py-3 text-center"><c:out value="${it.qty}"/></td>
                        <td class="py-3 text-right">฿<fmt:formatNumber value="${it.lineTotal}" minFractionDigits="2" maxFractionDigits="2"/></td>
                      </tr>
                    </c:forEach>
                  </tbody>
                  <tfoot>
                    <tr>
                      <td class="pt-4 text-right font-semibold" colspan="2">ยอดรวม</td>
                      <td class="pt-4 text-right font-extrabold text-emerald-700">฿<fmt:formatNumber value="${orderHeader.totalPrice}" minFractionDigits="2" maxFractionDigits="2"/></td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </c:if>
          </div>

          <!-- สลิป -->
          <div class="card p-6">
            <div class="flex items-center justify-between mb-3">
              <h3 class="text-lg font-semibold">สลิปชำระเงิน</h3>
              <span class="text-xs text-slate-500">
                <c:choose>
                  <c:when test="${not empty orderReceipts}"><c:out value="${fn:length(orderReceipts)}"/> ไฟล์</c:when>
                  <c:otherwise>ไม่มีสลิป</c:otherwise>
                </c:choose>
              </span>
            </div>

            <c:if test="${empty orderReceipts}">
              <div class="text-slate-600 text-sm">ยังไม่มีการอัปโหลดสลิปจากลูกค้า</div>
            </c:if>

            <c:if test="${not empty orderReceipts}">
              <div class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-3">
                <c:forEach var="rc" items="${orderReceipts}">
                  <c:set var="raw" value="${not empty rc.img ? rc.img : (not empty rc.imageUrl ? rc.imageUrl : rc.receiptImage)}"/>
                  <a class="block" href="javascript:void(0)"
                     data-raw="${fn:escapeXml(raw)}" data-oid="${orderHeader.orderId}" data-rid="${rc.receiptId}"
                     onclick="openReceiptFromAnchor(this)">
                    <div class="img-card aspect-[4/3]">
                      <img data-raw="${fn:escapeXml(raw)}" alt="receipt" class="img-fit" loading="lazy"
                           src="https://via.placeholder.com/600x400?text=Loading..."
                           onerror="this.onerror=null;this.src='https://via.placeholder.com/600x400?text=No+Image';"/>
                    </div>
                    <div class="mt-1 text-[11px] text-slate-500 flex items-center justify-between">
                      <span class="truncate">Ref: <c:out value="${rc.referenceId}" default="-"/></span>
                      <span class="opacity-80">#<c:out value="${rc.receiptId}" default="-"/></span>
                    </div>
                  </a>
                </c:forEach>
              </div>
            </c:if>
          </div>
        </div>

        <!-- ขวา -->
        <aside class="space-y-6">
          <!-- ข้อมูลลูกค้า -->
          <div class="card p-6">
            <h3 class="text-lg font-semibold mb-3">ข้อมูลลูกค้า</h3>
            <div class="space-y-1 text-sm">
              <div><span class="text-slate-500">ชื่อ: </span><span class="font-medium"><c:out value="${orderHeader.customerName}" default="-"/></span></div>
              <div><span class="text-slate-500">อีเมล: </span><span class="font-medium"><c:out value="${orderHeader.customerEmail}" default="-"/></span></div>
              <div><span class="text-slate-500">โทร: </span><span class="font-medium"><c:out value="${orderHeader.customerPhone}" default="-"/></span></div>
              <div><span class="text-slate-500">ที่อยู่:</span>
                <div class="font-medium whitespace-pre-line mt-1"><c:out value="${orderHeader.customerAddr}" default="-"/></div>
              </div>
            </div>
            <div class="mt-4 flex items-center gap-2">
              <button onclick="window.print()" class="btn btn-sm"><i class="fa-solid fa-print"></i> พิมพ์สรุป</button>
              <a href="${ctx}/farmer/orders" class="btn btn-sm">↩️ กลับหน้าออเดอร์</a>
            </div>
          </div>

          <!-- หมายเหตุ -->
          <div class="card p-6">
            <h3 class="text-lg font-semibold mb-2">หมายเหตุจากลูกค้า</h3>
            <c:catch var="__noteErr1"><c:set var="__note" value="${orderHeader.note}"/></c:catch>
            <c:if test="${empty __note}"><c:catch var="__noteErr2"><c:set var="__note" value="${orderHeader.orderNote}"/></c:catch></c:if>
            <c:if test="${empty __note}"><c:catch var="__noteErr3"><c:set var="__note" value="${orderHeader.remark}"/></c:catch></c:if>
            <c:if test="${empty __note}"><c:catch var="__noteErr4"><c:set var="__note" value="${orderHeader.customerNote}"/></c:catch></c:if>

            <c:choose>
              <c:when test="${not empty __note}">
                <div id="noteBox" class="text-sm whitespace-pre-line"></div>
                <script>
                  (function(){ var text = "<c:out value='${__note}'/>"; var el = document.getElementById('noteBox');
                    var i=0; (function t(){ el.textContent=text.slice(0, i++); if(i<=text.length) setTimeout(t, 18); })(); })();
                </script>
              </c:when>
              <c:otherwise>
                <div class="text-xs text-slate-500 mb-1">ยังไม่มีหมายเหตุจากลูกค้า</div>
                <ul class="list-disc pl-5 text-sm text-slate-700 space-y-1">
                  <li>ยืนยันคำสั่งซื้อ → ลูกค้าจึงชำระเงิน</li>
                  <li>กด “ยืนยันรับชำระเงินแล้ว” ได้แม้ยังไม่มีสลิป</li>
                  <li>ตั้งวันส่งแล้วแจ้งลูกค้าพร้อมเลขพัสดุภายหลัง (ถ้ามี)</li>
                </ul>
              </c:otherwise>
            </c:choose>
          </div>
        </aside>
      </div>
    </c:if>
  </main>

  <!-- ================= Footer ================= -->
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
        <a class="btn btn-emerald text-white shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <!-- ===== Modal: กำหนดวันส่ง (ปรับข้อความ + ตัดช่องบริษัท/เลขพัสดุ) ===== -->
  <div id="modalShip" class="fixed inset-0 z-50 hidden">
    <div class="absolute inset-0 bg-black/60" onclick="closeModal('modalShip')"></div>
    <div class="relative max-w-md mx-auto mt-24 card p-6">
      <h3 class="text-lg font-semibold mb-2">บันทึกกำหนดส่งให้ลูกค้า</h3>
      <form action="${ctx}/farmer/orders/${orderHeader.orderId}/ship" method="post" class="space-y-4">
        <c:if test="${not empty _csrf}"><input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/></c:if>
        <div>
          <label class="block text-sm text-slate-700 mb-1">กำหนดวันส่ง</label>
          <input type="date" name="deliveryDate" class="w-full border border-slate-300 bg-white text-slate-800 rounded-md px-3 py-2"/>
        </div>
        <div class="flex justify-end gap-2">
          <button type="button" class="btn" onclick="closeModal('modalShip')">ยกเลิก</button>
          <button class="btn btn-teal">บันทึกกำหนดส่ง</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ===== Viewer เต็มจอ ===== -->
  <div id="viewerModal" class="fixed inset-0 z-50 hidden">
    <div class="absolute inset-0 bg-black/80" onclick="closeViewer()"></div>
    <div class="absolute inset-0 flex flex-col">
      <div class="p-2 sm:p-3 flex items-center gap-2 justify-between text-white">
        <div class="flex items-center gap-2"><span id="viewerTitle" class="text-sm sm:text-base font-semibold"></span></div>
        <div class="flex items-center gap-2">
          <button class="btn btn-sm" onclick="viewerZoom(1)">+</button>
          <button class="btn btn-sm" onclick="viewerZoom(-1)">−</button>
          <button class="btn btn-sm" onclick="viewerResetZoom()">100%</button>
          <button class="btn btn-sm" onclick="viewerRotate()">⤾</button>
          <a id="viewerDownload" class="btn btn-sm" download>⬇</a>
          <button class="btn btn-sm" onclick="closeViewer()">✕</button>
        </div>
      </div>
      <div id="viewerStage" class="flex-1 flex items-center justify-center overflow-hidden select-none">
        <img id="viewerImg" alt="preview" class="max-h-full max-w-full transition-transform duration-150 ease-out will-change-transform"/>
      </div>
    </div>
  </div>

  <script>
    /* Profile dropdown */
    function toggleProfileMenu(e){
      e && e.stopPropagation();
      var m = document.getElementById('profileMenu');
      var b = document.getElementById('profileBtn');
      if(!m||!b) return;
      var hidden = m.classList.toggle('hidden');
      b.setAttribute('aria-expanded', hidden ? 'false' : 'true');
    }
    document.addEventListener('click',function(e){
      var b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return;
      if(!b.contains(e.target) && !m.contains(e.target)){ m.classList.add('hidden'); b.setAttribute('aria-expanded','false'); }
    });
    document.addEventListener('keydown',function(e){ if(e.key==='Escape'){ var m=document.getElementById('profileMenu'); var b=document.getElementById('profileBtn'); if(m) m.classList.add('hidden'); if(b) b.setAttribute('aria-expanded','false'); } });

    /* Progress */
    (function(){ var b=document.getElementById('stepBar'); if(b){ var t=+b.dataset.target||0; requestAnimationFrame(function(){ b.style.width=t+'%'; }); } })();

    /* Modal */
    function openModal(id){ var el=document.getElementById(id); if(el){ el.classList.remove('hidden'); document.body.style.overflow='hidden'; } }
    function closeModal(id){ var el=document.getElementById(id); if(el){ el.classList.add('hidden'); document.body.style.overflow=''; } }

    /* Viewer */
    var ZOOM=1, ROT=0, ORIGIN_X=0, ORIGIN_Y=0;
    function openViewer(url,title){ ZOOM=1; ROT=0; ORIGIN_X=0; ORIGIN_Y=0; applyTransform();
      document.getElementById('viewerImg').removeAttribute('src');
      document.getElementById('viewerTitle').textContent=title||'รูปภาพ';
      document.getElementById('viewerDownload').href=url;
      document.getElementById('viewerImg').src=url;
      document.getElementById('viewerModal').classList.remove('hidden');
      document.body.style.overflow='hidden';
    }
    function closeViewer(){ document.getElementById('viewerModal').classList.add('hidden'); document.body.style.overflow=''; }
    function applyTransform(){ document.getElementById('viewerImg').style.transform='translate('+ORIGIN_X+'px,'+ORIGIN_Y+'px) scale('+ZOOM+') rotate('+ROT+'deg)'; }
    function viewerZoom(d){ var step=.15; ZOOM=Math.min(8,Math.max(.2,ZOOM+(d>0?step:-step))); applyTransform(); }
    function viewerResetZoom(){ ZOOM=1; ORIGIN_X=0; ORIGIN_Y=0; applyTransform(); }
    function viewerRotate(){ ROT=(ROT+90)%360; applyTransform(); }
    (function pan(){
      var stage=document.getElementById('viewerStage'); var drag=false,sx=0,sy=0;
      if(!stage) return;
      stage.addEventListener('mousedown',function(e){ drag=true; sx=e.clientX-ORIGIN_X; sy=e.clientY-ORIGIN_Y; });
      window.addEventListener('mousemove',function(e){ if(!drag) return; ORIGIN_X=e.clientX-sx; ORIGIN_Y=e.clientY-sy; applyTransform(); });
      window.addEventListener('mouseup',function(){ drag=false; });
      stage.addEventListener('wheel',function(e){ e.preventDefault(); viewerZoom(e.deltaY>0?-1:1); }, {passive:false});
    })();

    /* Image resolver (เรียบง่าย ปลอด control-char) */
    var ctx = '${ctx}';
    function isAbs(u){ return /^https?:\/\//i.test(u); }
    function resolvePath(raw){
      if(!raw) return '';
      var s = String(raw).trim().replace(/\\/g,'/');
      if(isAbs(s)) return s;
      if(s.indexOf('/uploads/')===0) return ctx + s;
      if(s[0] === '/') return ctx + s;
      return ctx + '/uploads/' + s;
    }
    function resolveAllImgs(){
      var imgs=document.querySelectorAll('img[data-raw]');
      imgs.forEach(function(img){
        var raw=img.getAttribute('data-raw')||'';
        var url=resolvePath(raw);
        if(url) img.src=url;
      });
    }
    window.addEventListener('DOMContentLoaded', resolveAllImgs);
    function openReceiptFromAnchor(a){
      var img=a.querySelector('img[data-raw]'); var url=img && img.src; var title='สลิป #' + (a.dataset.rid||'');
      if(url) openViewer(url, title);
    }
  </script>
</body>
</html>
