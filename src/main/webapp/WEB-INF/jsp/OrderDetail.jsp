<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<jsp:useBean id="now" class="java.util.Date" />

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>รายละเอียดคำสั่งซื้อ • เกษตรกรบ้านเรา</title>

  <!-- Tailwind / Fonts / Icons -->
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700;800&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <c:if test="${empty ctx}">
    <c:set var="ctx" value="${pageContext.request.contextPath}"/>
  </c:if>

  <!-- ===== สถานะ/ตัวแปรป้องกันค่าว่าง ===== -->
  <c:set var="OST" value="${not empty order && not empty order.orderStatus ? fn:toUpperCase(order.orderStatus) : ''}"/>
  <c:set var="PST" value="${not empty order && not empty order.paymentStatus ? fn:toUpperCase(order.paymentStatus) : ''}"/>
  <c:set var="buyerOk" value="false"/><c:catch><c:set var="buyerOk" value="${order.buyerConfirmed}"/></c:catch>
  <c:set var="finished" value="false"/><c:catch><c:set var="finished" value="${order.finished}"/></c:catch>

  <c:set var="isRejected" value="${OST == 'REJECTED'}"/>
  <c:set var="isCanceled" value="${OST == 'CANCELED' or OST == 'CANCELLED'}"/>

  <c:set var="postConfirm"
         value="${OST=='FARMER_CONFIRMED' or OST=='PREPARING_SHIPMENT' or OST=='SHIPPED' or OST=='COMPLETED'}"/>
  <c:set var="awaitBuyerPay" value="${postConfirm and PST == 'AWAITING_BUYER_PAYMENT'}"/>
  <c:set var="paidPending"   value="${postConfirm and (PST == 'PAID_PENDING_VERIFY' or PST == 'PAID_PENDING_VERIFICATION')}"/>
  <c:set var="paidConfirmed" value="${(postConfirm and (PST == 'PAID_CONFIRMED' or PST == 'PAID_VERIFIED')) or (OST=='SHIPPED' or OST=='COMPLETED')}"/>
  <c:set var="readyForBuyerConfirm" value="${(paidConfirmed or OST=='SHIPPED' or OST=='COMPLETED') and (not buyerOk) and (not finished)}"/>

  <!-- ป้าย -->
  <c:set var="orderBadgeCls" value="bg-sky-100 text-sky-800"/>
  <c:choose>
    <c:when test="${OST=='FARMER_CONFIRMED'}"><c:set var="orderBadgeCls" value="bg-emerald-100 text-emerald-800"/></c:when>
    <c:when test="${OST=='PREPARING_SHIPMENT'}"><c:set var="orderBadgeCls" value="bg-indigo-100 text-indigo-800"/></c:when>
    <c:when test="${OST=='SHIPPED'}"><c:set var="orderBadgeCls" value="bg-amber-100 text-amber-800"/></c:when>
    <c:when test="${OST=='COMPLETED'}"><c:set var="orderBadgeCls" value="bg-gray-900 text-white"/></c:when>
    <c:when test="${OST=='REJECTED'}"><c:set var="orderBadgeCls" value="bg-rose-100 text-rose-800"/></c:when>
    <c:when test="${isCanceled}"><c:set var="orderBadgeCls" value="bg-gray-200 text-gray-900"/></c:when>
  </c:choose>
  <c:set var="payBadgeCls" value="bg-gray-100 text-gray-800"/>
  <c:choose>
    <c:when test="${PST=='AWAITING_BUYER_PAYMENT'}"><c:set var="payBadgeCls" value="bg-amber-100 text-amber-800"/></c:when>
    <c:when test="${PST=='PAID_PENDING_VERIFY' or PST=='PAID_PENDING_VERIFICATION'}"><c:set var="payBadgeCls" value="bg-violet-100 text-violet-800"/></c:when>
    <c:when test="${PST=='PAID_CONFIRMED' or PST=='PAID_VERIFIED'}"><c:set var="payBadgeCls" value="bg-emerald-100 text-emerald-800"/></c:when>
  </c:choose>

  <!-- Stepper (6 ขั้น) -->
  <c:set var="step1Cls" value="${postConfirm ? 'done' : 'now'}"/>
  <c:set var="step2Cls" value="${postConfirm ? (awaitBuyerPay ? 'now' : 'done') : ''}"/>
  <c:set var="step3Cls" value="${paidPending ? 'now' : (paidConfirmed ? 'done' : '')}"/>
  <c:set var="step4Cls" value="${paidConfirmed and (not buyerOk) ? 'now' : (paidConfirmed ? 'done' : '')}"/>
  <c:set var="step5Cls" value="${buyerOk and (not finished) ? 'now' : (buyerOk ? 'done' : '')}"/>
  <c:set var="step6Cls" value="${finished or OST=='COMPLETED' ? 'done' : ''}"/>

  <c:set var="dueText" value="${not empty order && not empty order.deliveryDate ? order.deliveryDate : 'TBD'}"/>

  <style>
    *{ font-family:'Prompt',sans-serif }
    body{
      background:
        radial-gradient(1200px 600px at -10% -10%, #ecfdf5 0%, transparent 60%),
        radial-gradient(1200px 600px at 110% -10%, #f0f9ff 0%, transparent 60%), #ffffff;
      color:#0f172a;
    }
    .card{ border-radius:22px; background:#fff; border:1px solid #e5e7eb; box-shadow:0 12px 40px rgba(2,6,23,.08) }
    .chip{ padding:.48rem .78rem; border-radius:9999px; font-weight:800; display:inline-flex; align-items:center; gap:.45rem }
    .name-1line{ white-space:nowrap; overflow:hidden; text-overflow:ellipsis }

    /* ปุ่มแบบเดียวกับหน้า /orders */
    .btn{ display:inline-flex; align-items:center; gap:.6rem; border:1px solid #e5e7eb; background:#fff; padding:.78rem 1.05rem; border-radius:14px; font-weight:800; transition:transform .04s, box-shadow .2s, filter .15s }
    .btn:hover{ box-shadow:0 10px 26px rgba(2,6,23,.08) }
    .btn:active{ transform:translateY(1px) }
    .btn-outline{ background:#fff; color:#0f172a; border:1px solid #e5e7eb }
    .btn-emerald{ background:linear-gradient(90deg,#10b981,#059669); color:#fff; border:0; box-shadow:0 16px 40px rgba(16,185,129,.28) }
    .btn-emerald:hover{ filter:brightness(.96) }
    .btn-emerald:disabled{ opacity:.65; cursor:not-allowed; filter:none }
    .btn-danger{ background:linear-gradient(90deg,#ef4444,#dc2626); color:#fff; border:0; box-shadow:0 16px 40px rgba(239,68,68,.28) }
    .btn-sm{ padding:.52rem .82rem; font-size:.96rem; border-radius:12px }

    thead th{ letter-spacing:.2px }
    tbody tr{ transition: background .15s } tbody tr:hover{ background:#f8fafc }

    .dot{ width:18px; height:18px; border-radius:9999px; border:2px solid #e5e7eb; background:#fff }
    .step{ display:flex; align-items:center; gap:.68rem }
    .step.done .dot{ background:#10b981; border-color:#10b981 }
    .step.now  .dot{ background:#34d399; border-color:#10b981; box-shadow:0 0 0 5px rgba(16,185,129,.2) }

    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    .due-badge{ display:inline-flex; align-items:center; gap:.55rem; padding:.55rem .9rem; border-radius:14px; font-weight:900;
      background:linear-gradient(90deg,#fef3c7,#fde68a); color:#92400e; border:2px solid #f59e0b66; box-shadow:0 10px 26px rgba(245,158,11,.18)}

    /* ===== Celebrate Modal: ให้เหมือนหน้า /orders ===== */
    #celeModal{ position:fixed; inset:0; background:rgba(0,0,0,.65); z-index:10000; display:none }
    #celeModal.show{ display:block }
    #celeWrap{ position:absolute; inset:0; display:flex; align-items:center; justify-content:center; padding:16px }
    .cele-enter{ opacity:0; transform:scale(.98) translateY(6px) }
    .cele-enter-active{ opacity:1; transform:none; transition:all .35s cubic-bezier(.2,.8,.2,1) }
    .cele-title{ letter-spacing:.2px; background:linear-gradient(90deg,#34d399,#10b981,#22c55e,#06b6d4); -webkit-background-clip:text; color:transparent }
    #celeCard{ --d-in:2.2s; --d-drop:.5s; --d-out:1.6s; --d-zoom:.5s; --d-stay:1.2s; --zoom:1.3;
      width:min(92vw,1000px); border-radius:24px; background:#fff; border:1px solid #bbf7d0; box-shadow:0 24px 80px rgba(2,6,23,.45); padding:18px; overflow:hidden; text-align:center }
    #celeCard .deliver-card{ width:100%; aspect-ratio:25/14; position:relative; overflow:hidden; background:linear-gradient(#ffffff,#eef9ff); border-radius:20px; box-shadow:0 40px 120px rgba(2,8,23,.2) }
    #celeCard .camera{position:absolute; inset:0; overflow:hidden}
    #celeCard .scene{position:absolute; inset:0; transform-origin:75% 70%}
    #celeCard .deliver-sky{position:absolute; inset:0}
    #celeCard .deliver-grass{position:absolute; left:0; right:0; bottom:0; height:38%; background:linear-gradient(180deg,#d5f5e6,#bfead4); box-shadow:inset 0 10px 20px rgba(0,0,0,.06)}
    #celeCard .deliver-road{position:absolute; left:0; right:0; bottom:18%; height:18%; background:#1f2937; box-shadow:inset 0 10px 24px rgba(0,0,0,.35)}
    #celeCard .deliver-lane{position:absolute; left:6%; right:6%; top:50%; height:6px; transform:translateY(-50%); background:linear-gradient(90deg,#e5e7eb 0 180px,transparent 180px 280px) repeat-x / 280px 6px}
    #celeCard .house{position:absolute; right:8%; bottom:18%; width:34%; aspect-ratio:1/0.76; filter:drop-shadow(0 22px 30px rgba(2,8,23,.2))}
    #celeCard .house-roof{position:absolute; left:4%; right:4%; top:0; height:42%; background:linear-gradient(180deg,#ffc24d,#f59e0b); clip-path:polygon(50% 0,100% 56%,0 56%)}
    #celeCard .house-body{position:absolute; inset:18% 4% 0 4%; background:#ffffff; border-radius:18px}
    #celeCard .window{position:absolute; left:12%; bottom:18%; width:26%; height:26%; background:#e6f6ff; border:4px solid #7dd3fc; border-radius:8px}
    #celeCard .door{position:absolute; right:10%; bottom:0; width:16%; height:48%; background:#0f172a; border-radius:10px 10px 0 0}
    #celeCard .house-step{position:absolute; left:8%; right:8%; bottom:-5%; height:5%; background:#7fbf5a; border-radius:9999px; filter:brightness(.95)}
    #celeCard .yard-shadow{position:absolute; left:46%; right:2%; bottom:15%; height:3.2%; background:rgba(0,0,0,.22); filter:blur(6px); border-radius:9999px}
    #celeCard .tree{position:absolute; bottom:18%}
    #celeCard .tree .crown{width:140px;height:140px;background:#10b981;border-radius:50%;filter:drop-shadow(0 18px 22px rgba(16,185,129,.35))}
    #celeCard .tree .trunk{width:20px;height:110px;background:#7c4a1d;margin:0 auto;border-radius:6px}
    #celeCard .tree.left{left:6%}
    #celeCard .tree.right{right:36%}
    #celeCard .tree.back{scale:.8; opacity:.9; filter:saturate(.9); z-index:2}
    #celeCarRig{position:absolute; bottom:18%; left:16%; width:36%; aspect-ratio:26/11; transform:translateX(-140%); z-index:20}
    #celeCarRig .car-top{width:32%; height:0; position:absolute; top:11%; left:29%; border:2px solid #333; border-bottom:none;border-right:none;border-left:none}
    #celeCarRig .car-body{width:85%;height:35%;position:absolute;top:43%;left:8%;border:2px solid #333;border-top:none;border-radius:20px 5px 30px 30px;background:firebrick}
    #celeCarRig .wheels{width:7%;height:16%;position:absolute;border:25px double #000;border-radius:50%;top:61%;z-index:1;background:#999}
    #celeCarRig .first-tyre{left:20%} .second-tyre{left:70%}
    @keyframes cele-wheel-drive{to{transform:rotate(360deg)}} 
    #celeCarRig.moving .wheels{animation:cele-wheel-drive .45s linear infinite}
    #celeBox{position:absolute; width:9%; aspect-ratio:1/1; z-index:22; background:linear-gradient(180deg,#ffd188,#f59e0b); border-radius:10px; box-shadow:0 18px 48px rgba(2,8,23,.22); transform-origin:50% 100%; opacity:0; left:78%; bottom:29%}
    #celeBox::before,#celeBox::after{content:"";position:absolute;inset:0}
    #celeBox::before{left:44%;right:44%;background:linear-gradient(180deg,rgba(255,255,255,.75),rgba(255,255,255,.45))}
    #celeBox::after{top:40%;bottom:40%;background:linear-gradient(90deg,rgba(255,255,255,.7),rgba(255,255,255,.45))}
    #celeBoxShadow{position:absolute; width:12%; height:2.6%; border-radius:9999px; background:rgba(0,0,0,.28); filter:blur(4px); z-index:1; opacity:0; left:78.5%; bottom:27.4%}
    #celeCard.play #celeCarRig{animation:cele-car-in var(--d-in) cubic-bezier(.17,.9,.12,1) forwards, cele-car-out-left var(--d-out) cubic-bezier(.13,.7,.07,1) calc(var(--d-in) + var(--d-drop) + .2s) forwards}
    #celeCard.play .scene{animation:cele-zoom-in var(--d-zoom) ease-out calc(var(--d-in) + .4s) forwards, cele-zoom-hold var(--d-stay) linear calc(var(--d-in) + .4s + var(--d-zoom)) forwards}
    #celeCard.play #celeBox{animation:cele-box-appear .18s linear var(--d-in) forwards, cele-box-bounce var(--d-drop) ease-out calc(var(--d-in) + .02s) forwards}
    #celeCard.play #celeBoxShadow{animation:cele-shadow-grow var(--d-drop) ease-out calc(var(--d-in) + .02s) forwards}
    @keyframes cele-car-in{from{transform:translateX(-140%)}to{transform:translateX(0)}}
    @keyframes cele-car-out-left{from{transform:translateX(0)}to{transform:translateX(-140%)}}
    @keyframes cele-zoom-in{from{transform:scale(1)}to{transform:scale(var(--zoom))}}
    @keyframes cele-zoom-hold{to{}}
    @keyframes cele-box-appear{to{opacity:1}}
    @keyframes cele-box-bounce{0%{transform:translate(0,-10%) scale(1.05) rotate(-3deg)}55%{transform:translate(0,0) scale(1.22)}80%{transform:translate(0,-4%) scale(1.18)}100%{transform:translate(0,0) scale(1.2)}}
    @keyframes cele-shadow-grow{from{opacity:0; transform:scale(.6)} to {opacity:.7; transform:scale(1.15)}}

    /* Loader overlay เวลาเปิดลิงก์ใหม่ */
    #pageLoader{ position:fixed; inset:0; display:none; align-items:center; justify-content:center; background:rgba(255,255,255,.75); z-index:9999 }
    #pageLoader.show{ display:flex }

    /* ===== Viewer (ยกจาก /orders) ===== */
    #viewerModal{ position:fixed; inset:0; z-index:9999; display:none }
    #viewerModal.show{ display:block }
  </style>
</head>
<body class="text-slate-800">

  <!-- Loader -->
  <div id="pageLoader"><div class="animate-pulse rounded-2xl border bg-white p-4 shadow"><i class="fa-solid fa-rotate fa-spin mr-2"></i> กำลังโหลด…</div></div>

  <!-- ================= Header ================= -->
  <header class="header shadow-md text-white">
    <div class="max-w-7xl mx-auto px-6 py-3 topbar">
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
                <a href="${ctx}/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-clock"></i> คำสั่งซื้อของฉัน</a>
                <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-solid fa-basket-shopping"></i> ตะกร้า
                  <span class="badge">${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}</span>
                </a>
              </div>
            </c:otherwise>
          </c:choose>
        </nav>
      </div>

      <!-- ขวา: โปรไฟล์ -->
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
            <a href="${ctx}/login" class="ml-2 btn-emerald btn">เข้าสู่ระบบ</a>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </header>
  <!-- ================= /Header ================= -->

  <!-- ================= Main ================= -->
  <main id="page"
        class="max-w-7xl mx-auto px-4 sm:px-6 py-6 lg:py-10 space-y-6"
        data-ctx="${ctx}"
        data-orderid="${empty order.orderId ? '' : order.orderId}"
        data-farmerid="${empty order.farmerId ? '' : order.farmerId}"
        data-ost="${OST}" data-pst="${PST}"
        data-buyerok="${buyerOk}" data-finished="${finished}">

    <!-- สรุปคำสั่งซื้อ -->
    <section class="card p-6 md:p-7">
      <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-6">
        <div class="space-y-2">
          <div class="text-xs text-gray-500">Order ID</div>
          <div class="text-2xl md:text-3xl font-extrabold font-mono break-all"><c:out value="${order.orderId}"/></div>

          <div class="flex flex-wrap gap-2">
            <span class="chip bg-gray-100 text-gray-900">วันที่: <fmt:formatDate value="${order.orderDate}" pattern="dd/MM/yyyy HH:mm"/></span>
            <span class="chip bg-emerald-100 text-emerald-800">ยอดรวม: ฿<fmt:formatNumber value="${order.totalPrice}" type="number" maxFractionDigits="0"/></span>
            <span class="due-badge"><i class="fa-solid fa-truck-fast"></i> กำหนดส่ง: <strong><c:out value="${dueText}"/></strong></span>
          </div>

          <div class="flex flex-wrap gap-2">
            <span class="chip ${orderBadgeCls}">ORDER: <c:out value="${OST}"/></span>
            <span class="chip ${payBadgeCls}">PAYMENT: <c:out value="${PST}"/></span>
          </div>

          <c:if test="${isRejected}">
            <div class="mt-1 px-3 py-2 rounded-xl border-2 border-rose-300 bg-rose-50 text-rose-900">ร้านปฏิเสธคำสั่งซื้อ • เหตุผลจะแสดงที่ “แจ้งเตือนด่วน”</div>
          </c:if>
        </div>

        <!-- ปุ่มหลัก -->
        <div class="grid sm:grid-cols-2 gap-2 w-full lg:w-[420px]">
          <a href="${ctx}/reviews/new-by-order?orderId=${order.orderId}" class="btn btn-emerald w-full ${(paidPending or paidConfirmed) ? '' : 'opacity-50 pointer-events-none'}">⭐ รีวิวออเดอร์นี้</a>

          <!-- แก้ตัวแปร farmerId ให้ถูกต้อง -->
          <a href="${ctx}/farmer/profile/view?farmerId=${order.farmerId}" class="btn btn-outline w-full" title="ดูรีวิวทั้งหมดของร้าน">
            <svg viewBox="0 0 24 24" class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/>
              <circle cx="12" cy="12" r="3" fill="currentColor"/>
            </svg>
            ดูรีวิว
          </a>

          <c:if test="${(OST == 'SENT_TO_FARMER') or (postConfirm and PST == 'AWAITING_BUYER_PAYMENT')}">
            <button type="button" class="btn btn-danger w-full" onclick="openCancel()">❌ ยกเลิกคำสั่งซื้อ</button>
          </c:if>
        </div>
      </div>
    </section>

    <!-- รายการสินค้า -->
    <section class="card p-6">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-2xl md:text-3xl font-extrabold">รายการสินค้า</h2>
        <div class="text-sm text-gray-500">คลิกที่รูปเพื่อขยาย</div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-full align-middle" style="table-layout:fixed">
          <colgroup>
            <col style="width:230px"><col><col style="width:160px"><col style="width:220px"><col style="width:220px"><col style="width:200px">
          </colgroup>
          <thead class="sticky top-0 bg-white/95 backdrop-blur border-b z-10">
          <tr class="text-left">
            <th class="py-4 px-3 text-xl md:text-2xl font-extrabold">รูป</th>
            <th class="py-4 px-3 text-xl md:text-2xl font-extrabold">ชื่อสินค้า</th>
            <th class="py-4 px-3 text-xl md:text-2xl font-extrabold text-center">จำนวน</th>
            <th class="py-4 px-3 text-xl md:text-2xl font-extrabold">ราคา/ต่อกิโลกรัม</th>
            <th class="py-4 px-3 text-xl md:text-2xl font-extrabold">รวม</th>
            <th class="py-4 px-3 text-xl md:text-2xl font-extrabold">สถานะย่อย</th>
          </tr>
          </thead>
          <tbody>
          <c:choose>
            <c:when test="${empty items}">
              <tr><td colspan="6" class="py-10 text-center text-gray-500">ไม่มีรายการสินค้า</td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="it" items="${items}" varStatus="st">
                <!-- รูปสินค้า: ครอบคลุมทุก path + onerror fallback -->
                <c:set var="rawImg" value="${empty it.img ? (empty it.imageUrl ? '' : it.imageUrl) : it.img}"/>
                <c:set var="imgUrl" value=""/>
                <c:choose>
                  <c:when test="${not empty rawImg and fn:startsWith(rawImg,'http')}"><c:set var="imgUrl" value="${rawImg}"/></c:when>
                  <c:when test="${not empty rawImg and fn:startsWith(rawImg,'/')}"><c:set var="imgUrl" value="${ctx}${rawImg}"/></c:when>
                  <c:when test="${not empty rawImg and fn:startsWith(rawImg,'uploads/')}"><c:set var="imgUrl" value="${ctx}/${rawImg}"/></c:when>
                  <c:when test="${not empty rawImg}"><c:set var="imgUrl" value="${ctx}/uploads/${rawImg}"/></c:when>
                  <c:otherwise><c:set var="imgUrl" value="https://via.placeholder.com/900x900?text=No+Image"/></c:otherwise>
                </c:choose>

                <c:set var="chipCls" value="bg-gray-100 text-gray-800"/>
                <c:choose>
                  <c:when test="${it.preOrderStatus == 'กำลังผลิต' or it.preOrderStatus == 'กำลังเตรียม'}"><c:set var="chipCls" value="bg-indigo-100 text-indigo-800"/></c:when>
                  <c:when test="${it.preOrderStatus == 'พร้อมส่ง'}"><c:set var="chipCls" value="bg-emerald-100 text-emerald-800"/></c:when>
                  <c:when test="${it.preOrderStatus == 'ปิดรับจอง' or it.preOrderStatus == 'ยกเลิก'}"><c:set var="chipCls" value="bg-rose-100 text-rose-800"/></c:when>
                </c:choose>

                <tr class="${st.index % 2 == 1 ? 'bg-gray-50/60' : ''}">
                  <td class="py-5 px-3 align-middle">
                    <img
                      src="${imgUrl}"
                      alt="${fn:escapeXml(it.productName)}"
                      loading="lazy"
                      onerror="this.onerror=null;this.src='https://via.placeholder.com/900x900?text=No+Image';"
                      class="rounded-2xl border object-cover cursor-zoom-in w-48 h-48 lg:w-56 lg:h-56"
                      onclick="openViewer(this.src,'รูปสินค้า: ${fn:escapeXml(it.productName)}')"/>
                  </td>
                  <td class="py-5 px-3 align-middle">
                    <a href="${ctx}/catalog/view/${it.productId}" class="block name-1line text-2xl md:text-3xl font-extrabold hover:underline">
                      <c:out value="${it.productName}"/>
                    </a>
                    <div class="text-xs text-gray-500 mt-1 font-mono">#<c:out value="${it.productId}"/></div>
                  </td>
                  <td class="py-5 px-3 align-middle text-center">
                    <div class="text-3xl md:text-4xl font-extrabold text-gray-900"><c:out value="${it.qty}"/></div>
                    <div class="text-sm text-gray-500">กก.</div>
                  </td>
                  <td class="py-5 px-3 align-middle">
                    <div class="text-2xl md:text-3xl font-bold text-gray-900">฿<fmt:formatNumber value="${it.price}" type="number" maxFractionDigits="0"/></div>
                  </td>
                  <td class="py-5 px-3 align-middle">
                    <div class="text-3xl md:text-4xl font-extrabold text-emerald-700">฿<fmt:formatNumber value="${it.lineTotal}" type="number" maxFractionDigits="0"/></div>
                  </td>
                  <td class="py-5 px-3 align-middle">
                    <span class="inline-flex items-center px-3 py-1.5 rounded-full text-base md:text-lg font-extrabold ${chipCls}">
                      <c:out value="${it.preOrderStatus}"/>
                    </span>
                  </td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
          </tbody>
        </table>
      </div>
    </section>

    <!-- สเต็ป + แจ้งเตือน/ชำระเงิน -->
    <section class="grid lg:grid-cols-2 gap-6">
      <div class="card p-6">
        <div class="text-sm text-gray-500">สถานะตอนนี้</div>
        <div id="stepTag" class="mt-1 chip bg-gray-100 text-gray-800">กำลังประมวลผล…</div>

        <div class="mt-4 grid gap-2" id="stepper">
          <div class="step ${step1Cls}"><div class="dot"></div><div class="font-semibold">1) ร้านยืนยันออเดอร์</div></div>
          <div class="step ${step2Cls}"><div class="dot"></div><div class="font-semibold">2) ผู้ซื้อชำระเงิน/อัปโหลดสลิป</div></div>
          <div class="step ${step3Cls}"><div class="dot"></div><div class="font-semibold">3) รอร้านตรวจสอบสลิป</div></div>
          <div class="step ${step4Cls}"><div class="dot"></div><div class="font-semibold">4) ร้านยืนยันการชำระแล้ว</div></div>
          <div class="step ${step5Cls}"><div class="dot"></div><div class="font-semibold">5) ผู้ซื้อยืนยันได้รับสินค้าแล้ว</div></div>
          <div class="step ${step6Cls}"><div class="dot"></div><div class="font-semibold">6) เสร็จสิ้น</div></div>
        </div>
      </div>

      <div class="card p-0 overflow-hidden">
        <div class="px-6 py-3 bg-gradient-to-r from-emerald-600 to-green-600 text-white flex items-center justify-between">
          <h3 class="text-xl font-extrabold">แจ้งเตือนด่วน</h3>
          <span class="text-xs text-white/80 font-semibold">#<c:out value="${order.orderId}"/></span>
        </div>

        <div class="p-6">
          <c:if test="${isRejected}">
            <div id="rejectBox" class="rounded-xl border-2 border-rose-300 bg-rose-50 text-rose-900 p-3 mb-4">
              <div class="font-bold">ร้านยกเลิกคำสั่งซื้อ</div>
              <div id="rejectReason" class="text-sm mt-1">กำลังดึงเหตุผล…</div>
            </div>
          </c:if>

          <div class="grid sm:grid-cols-2 gap-2">
            <button class="btn w-full" onclick="openChat()">เปิดแชท/แจ้งเตือน</button>
            <button class="btn w-full" onclick="sendQuick('ORDER_STATUS')">ถามสถานะ</button>
            <button class="btn w-full" onclick="sendQuick('STORE_CONTACT')">ข้อมูลติดต่อร้าน</button>
            <button class="btn w-full" onclick="sendQuick('STORE_ADDRESS')">ขอที่อยู่ฟาร์ม</button>
            <button class="btn w-full ${(OST=='FARMER_CONFIRMED') ? '' : 'opacity-50 pointer-events-none'}" onclick="sendQuick('REQUEST_PAYMENT_QR')">ขอชำระ/QR</button>
            <button class="btn w-full" onclick="sendQuick('HOW_TO_UPLOAD')">วิธีอัปโหลดสลิป</button>
          </div>

          <div class="mt-6 border-t pt-4">
            <h4 class="font-extrabold text-lg mb-2">ชำระเงิน / สลิป</h4>

            <div class="flex flex-wrap gap-2 mb-3">
              <button class="btn btn-emerald ${(OST=='FARMER_CONFIRMED') ? '' : 'opacity-50 pointer-events-none'}" onclick="openQr()">ชำระเงินด้วย QR (เต็มจอ)</button>
              <button class="btn" onclick="openReceipt()">ดูสลิปของออเดอร์นี้ (เต็มจอ)</button>
            </div>

            <c:choose>
              <c:when test="${postConfirm and PST == 'AWAITING_BUYER_PAYMENT'}">
                <div class="rounded-xl border-2 border-emerald-300 bg-emerald-50 text-emerald-900 p-3">
                  <div class="font-semibold mb-2">อัปโหลดสลิปเพื่อแจ้งชำระ</div>
                  <form class="flex flex-wrap items-center gap-2" method="post" action="${ctx}/orders/${order.orderId}/upload-receipt" enctype="multipart/form-data">
                    <input type="text" name="reference" placeholder="อ้างอิง (ถ้ามี)" class="flex-1 min-w-[120px] px-3 py-2 border rounded-md"/>
                    <input type="file" name="file" accept="image/*" class="flex-1 min-w-[220px] text-sm"/>
                    <button class="btn btn-sm" type="submit">อัปโหลดสลิป</button>
                  </form>
                </div>
              </c:when>

              <c:when test="${paidPending}">
                <div class="rounded-xl border-2 border-violet-300 bg-violet-50 text-violet-900 p-3"><div class="font-semibold">รับสลิปแล้ว • รอร้านตรวจสอบสลิป</div></div>
              </c:when>

              <c:when test="${readyForBuyerConfirm}">
                <div class="rounded-xl border-2 border-emerald-400 bg-emerald-50 text-emerald-900 p-3">
                  <div class="font-semibold mb-2">ร้านยืนยันการชำระแล้ว • โปรดยืนยันว่าได้รับสินค้าเรียบร้อย</div>
                  <button class="btn btn-emerald" onclick="buyerConfirm('<c:out value="${order.orderId}"/>')" data-once="true">
                    <i class="fa-solid fa-check-double"></i> ฉันได้รับสินค้าแล้ว (ยืนยัน)
                  </button>
                </div>
              </c:when>

              <c:when test="${buyerOk and not finished}">
                <div class="rounded-xl border-2 border-emerald-400 bg-emerald-50 text-emerald-900 p-3"><div class="font-semibold">ผู้ซื้อยืนยันได้รับสินค้าแล้ว • รอดำเนินการปิดออเดอร์</div></div>
              </c:when>

              <c:when test="${finished or OST=='COMPLETED'}">
                <div class="rounded-xl border-2 border-emerald-400 bg-emerald-50 text-emerald-900 p-3"><div class="font-semibold">เสร็จสิ้น ✔</div></div>
              </c:when>

              <c:otherwise>
                <div class="rounded-xl border-2 border-gray-200 bg-gray-50 text-gray-700 p-3">
                  <div class="font-semibold">กำลังรอขั้นตอนถัดไป…</div>
                  <div class="text-xs opacity-90">เมื่อร้านยืนยันออเดอร์ ระบบจะแจ้งให้คุณอัปโหลดสลิป</div>
                </div>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>
    </section>
  </main>

  <!-- ================= Footer ================= -->
  <footer class="mt-10 bg-black text-gray-300">
    <div class="max-w-7xl mx-auto px-6 py-10 grid md:grid-cols-3 gap-6 text-sm">
      <div>
        <h4 class="font-bold text-white mb-2">เกี่ยวกับเรา</h4>
        <p>ตลาดออนไลน์สำหรับสินค้าเกษตรคุณภาพ ส่งตรงจากฟาร์มท้องถิ่น</p>
      </div>
      <div>
        <h4 class="font-bold text-white mb-2">ลิงก์ด่วน</h4>
        <ul class="space-y-1">
          <li><a class="hover:text-emerald-300" href="${ctx}/main">หน้าหลัก</a></li>
          <li><a class="hover:text-emerald-300" href="${ctx}/catalog/list">สินค้าทั้งหมด</a></li>
          <li><a class="hover:text-emerald-300" href="${ctx}/preorder/list">สั่งจองสินค้า</a></li>
        </ul>
      </div>
      <div>
        <h4 class="font-bold text-white mb-2">ความปลอดภัย</h4>
        <p class="mb-2">ตรวจสอบรายชื่อผู้ค้าต้องสงสัยก่อนชำระเงิน</p>
        <a class="inline-flex items-center gap-2 rounded-xl px-4 py-2 btn-emerald text-white" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <!-- ปุ่มลอย -->
  <a class="fixed right-4 bottom-4 rounded-full btn-emerald px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50"
     href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
    <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
  </a>

  <!-- ===== Celebrate Modal (เหมือน /orders) ===== -->
  <div id="celeModal" onclick="closeCelebrate()">
    <div id="celeWrap">
      <div id="celeCard" class="cele-enter" role="dialog" aria-modal="true" aria-label="ยืนยันรับสินค้าแล้ว" onclick="event.stopPropagation()">
        <div class="text-2xl sm:text-3xl font-extrabold cele-title">รับสินค้าเรียบร้อยแล้ว!</div>
        <div class="mt-1 text-sm text-emerald-900/90">ระบบจะปิดออเดอร์ให้โดยอัตโนมัติ</div>
        <div class="deliver-card mt-4">
          <div class="camera">
            <div class="scene" id="celeScene">
              <div class="deliver-sky"></div>
              <div class="deliver-grass"></div>
              <div class="deliver-road"><div class="deliver-lane"></div></div>

              <div class="house">
                <div class="house-roof"></div>
                <div class="house-body"></div>
                <div class="window"></div>
                <div class="door"></div>
                <div class="house-step"></div>
              </div>
              <div class="yard-shadow"></div>

              <div class="tree left back"><div class="crown"></div><div class="trunk"></div></div>
              <div class="tree right"><div class="crown"></div><div class="trunk"></div></div>

              <div id="celeCarRig">
                <div class="car-top"></div>
                <div class="car-body"></div>
                <div class="wheels first-tyre"></div>
                <div class="wheels second-tyre"></div>
              </div>

              <div id="celeBox"></div>
              <div id="celeBoxShadow"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- ===== Image Viewer (ยกจาก /orders + เพิ่มลาก/หมุน) ===== -->
  <div id="viewerModal">
    <div class="absolute inset-0 bg-black/80" onclick="closeViewer()"></div>
    <div class="absolute inset-0 flex flex-col">
      <div class="p-2 sm:p-3 flex items-center gap-2 justify-between text-white">
        <div class="flex items-center gap-2"><span id="viewerTitle" class="text-sm sm:text-base font-semibold"></span></div>
        <div class="flex items-center gap-2">
          <button class="px-2 py-1 rounded-md border border-white/25 hover:bg-white/10" onclick="viewerZoom(1)">+</button>
          <button class="px-2 py-1 rounded-md border border-white/25 hover:bg-white/10" onclick="viewerZoom(-1)">−</button>
          <button class="px-2 py-1 rounded-md border border-white/25 hover:bg-white/10" onclick="viewerResetZoom()">100%</button>
          <button class="px-2 py-1 rounded-md border border-white/25 hover:bg-white/10" onclick="viewerRotate()">↻</button>
          <a id="viewerDownload" class="px-2 py-1 rounded-md border border-white/25 hover:bg-white/10" download>⬇</a>
          <button class="px-2 py-1 rounded-md border border-white/25 hover:bg-white/10" onclick="closeViewer()">✕</button>
        </div>
      </div>
      <div id="viewerStage" class="flex-1 flex items-center justify-center overflow-hidden select-none">
        <img id="viewerImg" alt="preview" class="max-h-full max-w-full transition-transform duration-150 ease-out will-change-transform"/>
      </div>
    </div>
  </div>

  <!-- ===== Cancel Modal ===== -->
  <div id="cancelModal" class="fixed inset-0 z-50 hidden">
    <div class="absolute inset-0 bg-black/50" onclick="closeCancel()"></div>
    <div class="absolute inset-0 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-2xl shadow-xl border">
        <div class="px-5 py-4 border-b flex items-center justify-between">
          <div class="font-bold text-lg">ยกเลิกคำสั่งซื้อ</div>
          <button class="text-gray-500 hover:text-gray-700" onclick="closeCancel()">✕</button>
        </div>
        <form id="cancelForm" method="post" action="${ctx}/orders/${order.orderId}/cancel">
          <div class="p-5">
            <div class="text-gray-700">ยืนยันการยกเลิกออเดอร์ <span class="font-mono px-2 py-0.5 rounded bg-gray-100"><c:out value="${order.orderId}"/></span> หรือไม่?</div>
            <div class="text-sm text-gray-500 mt-1">ยกเลิกได้เฉพาะช่วงขั้นที่ 1–2 เท่านั้น</div>
            <div class="mt-5 flex items-center justify-end gap-2">
              <button type="button" class="btn" onclick="closeCancel()">ปิด</button>
              <button type="submit" class="btn btn-danger">ยืนยันยกเลิก</button>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>

  <!-- ===== Chat Modal ===== -->
  <div id="chatModal" class="fixed inset-0 z-50 hidden">
    <div class="absolute inset-0 bg-black/60" onclick="closeChat()"></div>
    <div class="absolute inset-0 flex items-center justify-center p-4">
      <div class="w-full max-w-2xl bg-white rounded-2xl shadow-xl border overflow-hidden">
        <div class="px-4 py-3 bg-gradient-to-r from-green-600 to-emerald-600 text-white flex items-center justify-between">
          <div class="font-semibold">แชทกับร้าน</div>
          <div class="text-xs">#<span class="font-mono"><c:out value="${order.orderId}"/></span></div>
        </div>
        <div id="chatBody" class="h-[420px] overflow-y-auto p-4 space-y-2 bg-gradient-to-b from-emerald-50/40 to-white">
          <div id="chatEmpty" class="text-center text-gray-400 text-sm mt-16">กดปุ่มด้านล่างเพื่อส่งข้อความด่วน</div>
        </div>
        <div class="p-3 border-t bg-white grid grid-cols-2 sm:grid-cols-3 gap-2">
          <button class="btn btn-sm" onclick="sendQuick('ORDER_STATUS')">ถามสถานะ</button>
          <button class="btn btn-sm" onclick="sendQuick('STORE_CONTACT')">ข้อมูลติดต่อร้าน</button>
          <button class="btn btn-sm" onclick="sendQuick('STORE_ADDRESS')">ขอที่อยู่ฟาร์ม</button>
          <button class="btn btn-sm ${(OST=='FARMER_CONFIRMED') ? '' : 'opacity-50 pointer-events-none'}" onclick="sendQuick('REQUEST_PAYMENT_QR')">ขอชำระ/QR</button>
          <button class="btn btn-sm" onclick="sendQuick('HOW_TO_UPLOAD')">วิธีอัปโหลดสลิป</button>
          <button class="btn btn-sm" onclick="closeChat()">ปิด</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ================= Scripts ================= -->
  <script>
    // ===== โปรไฟล์ดรอปดาวน์ =====
    function toggleProfileMenu(e){
      e && e.stopPropagation();
      const m = document.getElementById('profileMenu');
      const b = document.getElementById('profileBtn');
      if(!m || !b) return;
      const willHide = !m.classList.contains('hidden');
      m.classList.toggle('hidden');
      b.setAttribute('aria-expanded', willHide ? 'false' : 'true');
    }
    document.addEventListener('click',(e)=>{
      const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return;
      if(!b.contains(e.target) && !m.contains(e.target)){
        m.classList.add('hidden'); b.setAttribute('aria-expanded','false');
      }
    });
    document.addEventListener('keydown',(e)=>{ if(e.key==='Escape'){ const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu'); if(m) m.classList.add('hidden'); if(b) b.setAttribute('aria-expanded','false'); } });

    // ===== Globals =====
    const ROOT = document.getElementById('page');
    const ctx  = ROOT.dataset.ctx || '';
    const ORDER_ID  = ROOT.dataset.orderid || '';
    const FARMER_ID = ROOT.dataset.farmerid || '';

    // ===== Loader overlay for slow links (optional) =====
    const pageLoader = document.getElementById('pageLoader');
    document.addEventListener('click', (e)=>{
      const a = e.target.closest('a.with-loader');
      if(!a) return;
      pageLoader.classList.add('show');
      setTimeout(()=>pageLoader.classList.remove('show'), 6000);
    });

    // ===== Step tag + Stepper =====
    function setStepTag(text, cls){
      const el = document.getElementById('stepTag'); if(!el) return;
      el.className = 'chip ' + (cls||'bg-gray-100 text-gray-800');
      el.textContent = text;
    }
    function updateStepTagAndStepper(){
      const ost=(ROOT.dataset.ost||'').toUpperCase();
      const pst=(ROOT.dataset.pst||'').toUpperCase();
      const buyerOk=(ROOT.dataset.buyerok||'false')==='true';
      const finished=(ROOT.dataset.finished||'false')==='true';
      const postConfirm = ['FARMER_CONFIRMED','PREPARING_SHIPMENT','SHIPPED','COMPLETED'].includes(ost);

      let text='กำลังประมวลผล…', cls='bg-gray-100 text-gray-800';
      if (ost==='REJECTED'){ text='คำสั่งซื้อถูกปฏิเสธโดยร้าน'; cls='bg-rose-100 text-rose-800'; }
      else if (ost==='CANCELED' || ost==='CANCELLED'){ text='คำสั่งซื้อถูกยกเลิก'; cls='bg-gray-200 text-gray-900'; }
      else if (!postConfirm){ text='ตอนนี้: ขั้นที่ 1 • รอร้านยืนยัน'; cls='bg-sky-100 text-sky-800'; }
      else if (pst==='AWAITING_BUYER_PAYMENT'){ text='ตอนนี้: ขั้นที่ 2 • รอผู้ซื้อชำระ/อัปโหลดสลิป'; cls='bg-amber-100 text-amber-800'; }
      else if (pst==='PAID_PENDING_VERIFY' || pst==='PAID_PENDING_VERIFICATION'){ text='ตอนนี้: ขั้นที่ 3 • รอร้านตรวจสอบสลิป'; cls='bg-violet-100 text-violet-800'; }
      else if (finished || ost==='COMPLETED'){ text='ตอนนี้: ขั้นที่ 6 • เสร็จสิ้น'; cls='bg-emerald-100 text-emerald-800'; }
      else if (buyerOk){ text='ตอนนี้: ขั้นที่ 5 • ผู้ซื้อยืนยันได้รับสินค้าแล้ว'; cls='bg-emerald-50 text-emerald-900'; }
      else { text='ตอนนี้: ขั้นที่ 4 • ร้านยืนยันการชำระแล้ว'; cls='bg-emerald-50 text-emerald-900'; }
      setStepTag(text, cls);

      const box=document.getElementById('stepper'); if(!box) return;
      const steps=[...box.querySelectorAll('.step')]; steps.forEach(s=>s.classList.remove('done','now'));
      if(!postConfirm){ steps[0].classList.add('now'); return; }
      steps[0].classList.add('done');
      if(pst==='AWAITING_BUYER_PAYMENT'){ steps[1].classList.add('now'); return; }
      steps[1].classList.add('done');
      if(pst==='PAID_PENDING_VERIFY' || pst==='PAID_PENDING_VERIFICATION'){ steps[2].classList.add('now'); return; }
      steps[2].classList.add('done');
      if(!buyerOk){ steps[3].classList.add('now'); return; }
      steps[3].classList.add('done');
      if(!finished){ steps[4].classList.add('now'); return; }
      steps[4].classList.add('done');
      steps[5].classList.add('done');
    }

    // ===== Image viewer (ซูม/ลาก/หมุน/ดาวน์โหลด/ปิด) =====
    const viewer = document.getElementById('viewerModal');
    const viewerImg = document.getElementById('viewerImg');
    const viewerTitle = document.getElementById('viewerTitle');
    const viewerDownload = document.getElementById('viewerDownload');
    const viewerStage = document.getElementById('viewerStage');

    let ZOOM=1, ROT=0, ORIGIN_X=0, ORIGIN_Y=0, DRAG=false, PX=0, PY=0;

    function applyTransform(){ viewerImg.style.transform = `translate(${ORIGIN_X}px,${ORIGIN_Y}px) scale(${ZOOM}) rotate(${ROT}deg)`; }
    function viewerZoom(d){ const step=.15; ZOOM=Math.min(8,Math.max(.2,ZOOM+(d>0?step:-step))); applyTransform(); }
    function viewerResetZoom(){ ZOOM=1; ORIGIN_X=0; ORIGIN_Y=0; ROT=0; applyTransform(); }
    function viewerRotate(){ ROT=(ROT+90)%360; applyTransform(); }
    function openViewer(url,title){
      viewerTitle.textContent = title || 'รูปภาพ';
      viewerDownload.href = url;
      viewerImg.src = url + (url.includes('?') ? '&' : '?') + 't=' + Date.now();
      ZOOM=1; ROT=0; ORIGIN_X=0; ORIGIN_Y=0; applyTransform();
      viewer.classList.add('show'); document.body.style.overflow='hidden';
    }
    function closeViewer(){ viewer.classList.remove('show'); document.body.style.overflow=''; }
    viewerStage.addEventListener('mousedown', (e)=>{ DRAG=true; PX=e.clientX; PY=e.clientY; });
    window.addEventListener('mousemove', (e)=>{ if(!DRAG) return; ORIGIN_X += e.clientX-PX; ORIGIN_Y += e.clientY-PY; PX=e.clientX; PY=e.clientY; applyTransform(); });
    window.addEventListener('mouseup', ()=> DRAG=false);
    viewerStage.addEventListener('wheel', (e)=>{ e.preventDefault(); viewerZoom(e.deltaY<0?1:-1); }, {passive:false});
    document.addEventListener('keydown', (e)=>{ if(e.key==='Escape') closeViewer(); });

    // ===== Cancel =====
    function openCancel(){ document.getElementById('cancelModal').classList.remove('hidden'); document.body.style.overflow='hidden'; }
    function closeCancel(){ document.getElementById('cancelModal').classList.add('hidden'); document.body.style.overflow=''; }

    // ===== Chat quick =====
    function openChat(){ document.getElementById('chatModal').classList.remove('hidden'); document.body.style.overflow='hidden'; }
    function closeChat(){ document.getElementById('chatModal').classList.add('hidden'); document.body.style.overflow=''; }
    function renderBubble(role, title, message){
      const mine = role==='BUYER';
      const wrap=document.createElement('div'); wrap.className='flex '+(mine?'justify-end':'justify-start');
      const col=document.createElement('div'); col.className='max-w-[86%]';
      const box=document.createElement('div'); box.className='rounded-xl px-3 py-2 shadow '+(mine?'bg-emerald-600 text-white':'bg-white border');
      if(title){ const t=document.createElement('div'); t.className='text-sm font-semibold'; t.textContent=title; box.appendChild(t); }
      if(message){ const m=document.createElement('div'); m.className='text-sm mt-1 whitespace-pre-wrap'; m.textContent=message; box.appendChild(m); }
      col.appendChild(box); wrap.appendChild(col); document.getElementById('chatBody').appendChild(wrap);
      document.getElementById('chatEmpty').classList.add('hidden');
      document.getElementById('chatBody').scrollTop=document.getElementById('chatBody').scrollHeight;
    }
    function sendQuick(action){
      openChat();
      const A = String(action||'').toUpperCase();
      const titleMap = { ORDER_STATUS:'สถานะคำสั่งซื้อ', STORE_CONTACT:'ข้อมูลติดต่อร้าน', STORE_ADDRESS:'ที่อยู่ฟาร์ม', REQUEST_PAYMENT_QR:'ชำระเงินด้วย QR', HOW_TO_UPLOAD:'วิธีอัปโหลดสลิป' };
      const msgMap   = { ORDER_STATUS:'สอบถามสถานะคำสั่งซื้อครับ/ค่ะ', STORE_CONTACT:'ขอข้อมูลติดต่อร้านด้วยครับ/ค่ะ', STORE_ADDRESS:'ขอที่อยู่ฟาร์มสำหรับจัดส่ง/ติดต่อครับ/ค่ะ', REQUEST_PAYMENT_QR:'ขอวิธีชำระเงินหรือ QR ครับ/ค่ะ', HOW_TO_UPLOAD:'ขอวิธีอัปโหลดสลิปชำระเงินครับ/ค่ะ' };
      renderBubble('BUYER', titleMap[A]||'ข้อความ', msgMap[A]||'ข้อความ');

      if(A==='ORDER_STATUS'){
        renderBubble('SYSTEM','สถานะคำสั่งซื้อ','ORDER: '+(ROOT.dataset.ost||'-')+'\nPAYMENT: '+(ROOT.dataset.pst||'-'));
      }

      fetch(ctx + '/orders/' + encodeURIComponent(ORDER_ID) + '/quick', {
        method:'POST',
        headers:{ 'Content-Type':'application/x-www-form-urlencoded', 'Accept':'application/json' },
        body: new URLSearchParams({ action:A })
      }).then(r=>r.json()).then(list=>{
        if(Array.isArray(list)){ list.forEach(n=>renderBubble(n.senderRole||'FARMER', n.title||'', n.message||'')); }
      }).catch(()=>{});
    }

    // ===== QR / Receipt (fallback หลายจุดแบบ /orders) =====
    function probeImage(u){ return new Promise(r=>{ const i=new Image(); i.onload=()=>r(true); i.onerror=()=>r(false); i.src=u+(u.includes('?')?'&':'?')+'t='+Date.now(); }); }
    async function resolveQrUrl(){
      try{ const a = ctx + '/orders/' + encodeURIComponent(ORDER_ID) + '/payment-qr'; const r = await fetch(a,{headers:{'Accept':'application/json'}}); if(r.ok){ const j=await r.json(); if(j?.url && await probeImage(j.url)) return j.url; } }catch(_){}
      if(FARMER_ID){ const b = ctx + '/payment/qr/' + encodeURIComponent(FARMER_ID); if(await probeImage(b)) return b; }
      return null;
    }
    async function resolveReceiptUrl(){
      try{ const a = ctx + '/orders/' + encodeURIComponent(ORDER_ID) + '/receipt'; const r = await fetch(a,{headers:{'Accept':'application/json'}}); if(r.ok){ const j=await r.json(); if(j?.url && await probeImage(j.url)) return j.url; } }catch(_){}
      const b = ctx + '/orders/' + encodeURIComponent(ORDER_ID) + '/receipt/image'; if(await probeImage(b)) return b;
      const c = ctx + '/payment/receipt/' + encodeURIComponent(ORDER_ID); return (await probeImage(c)) ? c : null;
    }
    async function openQr(){ const url = await resolveQrUrl(); if(!url){ alert('ยังไม่พบ QR ของร้าน'); return; } openViewer(url,'ชำระเงินด้วย QR'); }
    async function openReceipt(){ const url = await resolveReceiptUrl(); if(!url){ alert('ยังไม่พบบันทึกสลิป'); return; } openViewer(url,'สลิปการชำระเงิน #'+ORDER_ID); }

    // ===== Celebrate control =====
    const CELE_DUR_IN=2200, CELE_DUR_DROP=500, CELE_DUR_OUT=1600, CELE_TOTAL=6000; let CELE_TIMER=null;
    function celeRefs(){ return { modal:document.getElementById('celeModal'), card:document.getElementById('celeCard'), scene:document.getElementById('celeScene'), car:document.getElementById('celeCarRig') }; }
    function celeReset(){ const {modal,card,car}=celeRefs(); if(!modal||!card) return; clearTimeout(CELE_TIMER); modal.classList.remove('show'); card.classList.remove('play','cele-enter-active'); car&&car.classList.remove('moving'); car&&(car.style.transform='translateX(-140%)'); }
    function celePlay(){ const {card,car}=celeRefs(); if(!card) return; card.classList.remove('play','cele-enter-active'); void card.offsetWidth; card.classList.add('play','cele-enter-active'); if(car){ car.classList.add('moving'); setTimeout(()=>car.classList.remove('moving'), CELE_DUR_IN); setTimeout(()=>car.classList.add('moving'), CELE_DUR_IN + CELE_DUR_DROP + 200); setTimeout(()=>car.classList.remove('moving'), CELE_DUR_IN + CELE_DUR_DROP + CELE_DUR_OUT); } }
    function openCelebrate(){ const {modal}=celeRefs(); if(!modal) return; celeReset(); modal.classList.add('show'); requestAnimationFrame(()=>{ celePlay(); }); CELE_TIMER=setTimeout(closeCelebrate, CELE_TOTAL); }
    function closeCelebrate(){ const {modal}=celeRefs(); if(!modal) return; clearTimeout(CELE_TIMER); modal.classList.remove('show'); }

    // ===== Buyer confirm: ครั้งเดียว + อัปเดตขั้น 6 แน่ ๆ =====
    const CONFIRM_LOCK = new Set();
    window.buyerConfirm = async function(oid){
      if(!oid || CONFIRM_LOCK.has(oid)) return;
      CONFIRM_LOCK.add(oid);

      // ซ่อนปุ่มทุกตัวที่ตั้ง data-once
      document.querySelectorAll('button[data-once="true"]').forEach(b=>{ b.disabled=true; b.style.display='none'; });

      // ดันสถานะในหน้า → ขั้น 5 และจำฝั่ง client
      ROOT.dataset.buyerok = 'true';
      ROOT.dataset.finished = 'false';
      localStorage.setItem('orders:buyerOk:'+oid,'1');
      localStorage.removeItem('orders:finished:'+oid);
      updateStepTagAndStepper();

      // เล่นฉาก Celebrate
      openCelebrate();

      // ยิงบันทึกไป server แบบ fire-and-forget
      try{
        fetch(ctx + '/orders/' + encodeURIComponent(oid) + '/buyer-confirm', {
          method:'POST',
          headers:{ 'Content-Type':'application/x-www-form-urlencoded','Accept':'application/json' },
          body:'done=1'
        }).catch(()=>{});
      }catch(_){}

      // หลังจบอนิเมชัน → ขั้น 6
      setTimeout(()=>{
        ROOT.dataset.finished = 'true';
        localStorage.setItem('orders:finished:'+oid,'1');
        updateStepTagAndStepper();
      }, CELE_TOTAL + 50);
    };

    // ===== โหลดเหตุผล reject (ถ้ามี) =====
    (async function(){
      const box = document.getElementById('rejectReason'); if(!box) return;
      const tryUrls = [
        ctx + '/orders/' + encodeURIComponent(ORDER_ID) + '/reject-reason',
        ctx + '/orders/' + encodeURIComponent(ORDER_ID) + '/cancel-reason',
        ctx + '/orders/' + encodeURIComponent(ORDER_ID) + '/reason',
        ctx + '/farmer/orders/' + encodeURIComponent(ORDER_ID) + '/reject-reason'
      ];
      for(const u of tryUrls){
        try{
          const r = await fetch(u, {headers:{'Accept':'application/json, text/plain, */*'}}); if(!r.ok) continue;
          const ct=(r.headers.get('content-type')||'').toLowerCase();
          if(ct.includes('application/json')){ const j=await r.json(); box.textContent = j?.reasonThai || j?.reason || j?.message || j?.note || j?.remark || j?.data?.reason || '—'; return; }
          const t=(await r.text()).trim(); if(t){ box.textContent=t; return; }
        }catch(_){}
      }
      box.textContent='ร้านยกเลิกออเดอร์นี้ แต่ไม่ได้ระบุเหตุผล';
    })();

    // ===== Seed จาก localStorage (กันเคสรีเฟรชแล้วขั้น 6 ไม่ขึ้น) =====
    (function seedLocal(){
      const ok = localStorage.getItem('orders:buyerOk:'+ORDER_ID)==='1';
      const fin = localStorage.getItem('orders:finished:'+ORDER_ID)==='1';
      if(ok)  ROOT.dataset.buyerok='true';
      if(fin) ROOT.dataset.finished='true';
      updateStepTagAndStepper();
      // ซ่อนปุ่มยืนยันถ้าเคยยืนยันหรือจบแล้ว
      if(ok || fin){
        document.querySelectorAll('button[onclick^="buyerConfirm"]').forEach(btn=>{ btn.style.display='none'; btn.disabled=true; });
      }
    })();

    // เริ่มต้น
    updateStepTagAndStepper();

    // Expose for HTML buttons
    window.openCancel = openCancel; window.closeCancel = closeCancel;
    window.openChat = openChat; window.closeChat = closeChat;
    window.openQr = openQr; window.openReceipt = openReceipt;
    window.openViewer = openViewer; window.closeViewer = closeViewer;
    window.viewerZoom = viewerZoom; window.viewerResetZoom = viewerResetZoom; window.viewerRotate = viewerRotate;
  </script>
</body>
</html>
