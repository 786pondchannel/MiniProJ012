<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
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
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>คำสั่งซื้อของฉัน • เกษตรกรบ้านเรา</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <c:if test="${not empty _csrf}">
    <meta name="_csrf" content="${_csrf.token}"/>
    <meta name="_csrf_header" content="${_csrf.headerName}"/>
  </c:if>

  <c:set var="statAllServer"     value="${empty totalCount ? null : totalCount}" />
  <c:set var="statPendingServer" value="${empty pendingVerifyCount ? null : pendingVerifyCount}" />
  <c:set var="statAwaitServer"   value="${empty awaitingBuyerCount ? null : awaitingBuyerCount}" />
  <c:set var="statSumServer"     value="${empty approximateSum ? null : approximateSum}" />

  <c:set var="reviewedStr" value=","/>
  <c:if test="${not empty reviewedOrders}">
    <c:forEach var="rid" items="${reviewedOrders}">
      <c:set var="reviewedStr" value="${reviewedStr}${rid},"/>
    </c:forEach>
  </c:if>
  <c:set var="justReviewedOrderId"
         value="${not empty param.reviewed ? param.reviewed :
                 (not empty param.reviewedOrderId ? param.reviewedOrderId :
                 (not empty param.rvok ? param.rvok : null))}" />
  <c:if test="${not empty justReviewedOrderId}">
    <c:set var="reviewedStr" value="${reviewedStr}${justReviewedOrderId},"/>
  </c:if>

  <style>
    *{ font-family:'Prompt',system-ui,-apple-system,Segoe UI,Roboto,Arial }
    body{ background:linear-gradient(180deg,#ecfdf5,#ffffff); color:#0f172a }
    .hidden{ display:none!important }

    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    .card{ border-radius:18px; background:#fff; border:1px solid #e5e7eb; padding:18px; box-shadow:0 8px 30px rgba(2,6,23,.06) }
    .btn{ display:inline-flex; align-items:center; gap:.55rem; border:1px solid #e5e7eb; background:#fff; padding:.72rem 1rem; border-radius:.9rem; font-weight:800; transition:background .15s,transform .03s,box-shadow .15s }
    .btn:hover:not(.btn-emerald):not(.btn-danger){ background:#f8fafc }
    .btn:active{ transform:translateY(1px) }
    .btn-emerald{ background:linear-gradient(90deg,#10b981,#059669); color:#fff; border:0; box-shadow:0 12px 30px rgba(16,185,129,.28) }
    .btn.btn-emerald:hover{ filter:brightness(1.05) }
    .btn-danger{ background:linear-gradient(90deg,#ef4444,#dc2626); color:#fff; border:0; box-shadow:0 12px 30px rgba(239,68,68,.28) }
    .btn.btn-danger:hover{ filter:brightness(1.05) }
    .btn-outline{ background:#fff; color:#0f172a; border:1px solid #e5e7eb }
    .btn-outline:hover{ background:#f1f5f9 }
    .btn-sm{ padding:.5rem .8rem; font-size:.94rem }
    .chip{ padding:.44rem .7rem; border-radius:9999px; font-size:.9rem; font-weight:800; display:inline-flex; align-items:center; gap:.35rem }

    /* ===== Stepper ===== */
    .steps{ display:grid; gap:.45rem }
    .steps .step{ display:flex; align-items:center; gap:.6rem }
    .steps .step .dot{ width:18px; height:18px; border-radius:9999px; border:2px solid #e5e7eb; background:#fff; transition:all .18s ease }
    .steps .step.done .dot{ background:#10b981; border-color:#10b981 }
    .steps .step.now  .dot{ background:#34d399; border-color:#10b981; box-shadow:0 0 0 4px rgba(16,185,129,.18) }
    .steps .step .t{ font-size:.92rem }

    .alert-red{ border:2px solid #ef4444; background:linear-gradient(180deg,#fff1f2,#ffffff); }
    .alert-title{ display:flex; align-items:center; gap:.5rem; font-weight:900; color:#991b1b }
    .alert-dot{ width:12px; height:12px; background:#ef4444; border-radius:9999px; box-shadow:0 0 0 6px rgba(239,68,68,.25) }
    @keyframes pulseBorder{ 0%{ box-shadow:0 0 0 0 rgba(239,68,68,.45) } 70%{ box-shadow:0 0 0 10px rgba(239,68,68,0) } 100%{ box-shadow:0 0 0 0 rgba(239,68,68,0) } }
    .row-alert{ animation:pulseBorder 1.6s ease-out infinite }
    .badge-danger{ background:#fee2e2; color:#991b1b }

    /* ซ่อนปุ่มยืนยันถ้าเคยกดแล้ว หรือเสร็จสิ้น */
    #tbody tr[data-buyerok="true"] button[onclick^="buyerConfirm"],
    #tbody tr[data-finished="true"] button[onclick^="buyerConfirm"]{
      display:none!important;
    }

    /* ====== CELEBRATE Modal (6s) ====== */
    #celeModal{ position:fixed; inset:0; background:rgba(0,0,0,.65); z-index:10000; display:none; }
    #celeModal.show{ display:block; }
    #celeWrap{ position:absolute; inset:0; display:flex; align-items:center; justify-content:center; padding:16px; }
    .cele-enter{ opacity:0; transform:scale(.98) translateY(6px) }
    .cele-enter-active{ opacity:1; transform:none; transition:all .35s cubic-bezier(.2,.8,.2,1) }
    .cele-title{ letter-spacing:.2px; background: linear-gradient(90deg,#34d399,#10b981,#22c55e,#06b6d4); -webkit-background-clip:text; color:transparent; }

    #celeCard{
      --d-in:2.2s;   --d-drop:.5s;  --d-out:1.6s;  --d-zoom:.5s; --d-stay:1.2s; --zoom:1.3;
      width:min(92vw,1000px); border-radius:24px; background:#fff; border:1px solid #bbf7d0;
      box-shadow:0 24px 80px rgba(2,6,23,.45); padding:18px; overflow:hidden; text-align:center;
    }
    #celeCard .deliver-card{
      width:100%; aspect-ratio:25/14; position:relative; overflow:hidden;
      background:linear-gradient(#ffffff,#eef9ff); border-radius:20px; box-shadow:0 40px 120px rgba(2,8,23,.2)
    }
    #celeCard .camera{position:absolute; inset:0; overflow:hidden}
    #celeCard .scene{position:absolute; inset:0; transform-origin:75% 70%}

    #celeCard .deliver-sky{position:absolute; inset:0}
    #celeCard .deliver-grass{position:absolute; left:0; right:0; bottom:0; height:38%;
      background:linear-gradient(180deg,#d5f5e6,#bfead4); box-shadow:inset 0 10px 20px rgba(0,0,0,.06)}
    #celeCard .deliver-road{position:absolute; left:0; right:0; bottom:18%; height:18%;
      background:#1f2937; box-shadow:inset 0 10px 24px rgba(0,0,0,.35)}
    #celeCard .deliver-lane{position:absolute; left:6%; right:6%; top:50%; height:6px; transform:translateY(-50%);
      background:linear-gradient(90deg,#e5e7eb 0 180px,transparent 180px 280px) repeat-x / 280px 6px}

    #celeCard .house{position:absolute; right:8%; bottom:18%; width:34%; aspect-ratio:1/0.76; filter:drop-shadow(0 22px 30px rgba(2,8,23,.2))}
    #celeCard .house-roof{position:absolute; left:4%; right:4%; top:0; height:42%; background:linear-gradient(180deg,#ffc24d,#f59e0b); clip-path:polygon(50% 0,100% 56%,0 56%)}
    #celeCard .house-body{position:absolute; inset:18% 4% 0 4%; background:#ffffff; border-radius:18px}
    #celeCard .window{position:absolute; left:12%; bottom:18%; width:26%; height:26%; background:#e6f6ff; border:4px solid #7dd3fc; border-radius:8px; box-shadow:inset 0 0 30px rgba(14,165,233,.25)}
    #celeCard .door{position:absolute; right:10%; bottom:0; width:16%; height:48%; background:#0f172a; border-radius:10px 10px 0 0; box-shadow:inset 0 8px 0 rgba(255,255,255,.25)}
    /* เปลี่ยนชื่อคลาส step ของบ้าน → .house-step กันชนกับ stepper */
    #celeCard .house-step{position:absolute; left:8%; right:8%; bottom:-5%; height:5%; background:#7fbf5a; border-radius:9999px; filter:brightness(.95)}
    #celeCard .yard-shadow{position:absolute; left:46%; right:2%; bottom:15%; height:3.2%; background:rgba(0,0,0,.22); filter:blur(6px); border-radius:9999px}

    #celeCard .tree{position:absolute; bottom:18%}
    #celeCard .tree .crown{width:140px;height:140px;background:#10b981;border-radius:50%;filter:drop-shadow(0 18px 22px rgba(16,185,129,.35))}
    #celeCard .tree .trunk{width:20px;height:110px;background:#7c4a1d;margin:0 auto;border-radius:6px}
    #celeCard .tree.left{left:6%}
    #celeCard .tree.right{right:36%}
    #celeCard .tree.back{scale:.8; opacity:.9; filter:saturate(.9); z-index:2}

    #celeCarRig{position:absolute; bottom:18%; left:16%; width:36%; aspect-ratio:26/11; transform:translateX(-140%); z-index:20}
    #celeCarRig .car{position:absolute; inset:0}
    #celeCarRig .car-top{width:32%; height:0; position:absolute; top:11%; left:29%; border:2px solid #333; border-bottom:none;border-right:none;border-left:none}
    #celeCarRig .car-body{width:85%;height:35%;position:absolute;top:43%;left:8%;border:2px solid #333;border-top:none;border-radius:20px 5px 30px 30px;background:firebrick}
    #celeCarRig .designer-line{height:15px;width:80%;background:#fff;position:absolute;left:10%;bottom:42%;border-radius:50px 0 50px 0}
    #celeCarRig .door-handles{position:absolute;width:5%;height:2%;border:2px solid yellow}
    #celeCarRig .handle1{top:46%;left:52%}
    #celeCarRig .handle2{top:46%;left:30%}
    #celeCarRig .side-mirror{width:10%;height:10%;position:absolute;top:37%;right:22%;border:3px solid #333;border-radius:10px 20px 30px 10px;transform:rotateY(70deg);background:yellow;z-index:1}
    #celeCarRig .sits{position:absolute;background:rgba(0,0,0,.8);z-index:1}
    #celeCarRig .sit1{height:15%;width:8%;left:51%;top:27%;border-radius:20% 80% 0 0}
    #celeCarRig .sit2{height:15%;width:13%;left:26%;top:27%;border-radius:30px 60px 0 0}
    #celeCarRig .starring{width:2%;height:8%;position:absolute;border:4px double #000;border-radius:50%;top:32%;right:32%;transform:rotateY(60deg) rotateX(-40deg)}
    #celeCarRig .starring-attach{background:#fff;height:5%;border:3px double #333;position:absolute;right:32%;top:36%;transform:rotate(-41deg);border-radius:35px 0 0 50px}
    #celeCarRig .front-light{height:14%;width:1%;position:absolute;border:2px solid #333;border-radius:50%;top:46%;right:6%;background:#c0c0c0;box-shadow:10px 0 15px #c1c1c1}
    #celeCarRig .back-light{height:9%;width:1%;position:absolute;border:1px solid #333;border-radius:20%;top:49%;left:7%;background:red;box-shadow:-5px 0 20px red}
    #celeCarRig .wheels{width:7%;height:16%;position:absolute;border:25px double #000;border-radius:50%;top:61%;z-index:1;background:#999;animation:none}
    #celeCarRig .first-tyre{left:20%} .second-tyre{left:70%}
    @keyframes cele-wheel-drive{to{transform:rotate(360deg)}}
    #celeCarRig.moving .wheels{animation:cele-wheel-drive .45s linear infinite}

    #celeBox{position:absolute; width:9%; aspect-ratio:1/1; z-index:22;
      background:linear-gradient(180deg,#ffd188,#f59e0b); border-radius:10px;
      box-shadow:0 18px 48px rgba(2,8,23,.22), inset 0 0 0 10px rgba(255,255,255,.25);
      transform-origin:50% 100%; opacity:0; left:78%; bottom:29%;
    }
    #celeBox::before,#celeBox::after{content:"";position:absolute;inset:0}
    #celeBox::before{left:44%;right:44%;background:linear-gradient(180deg,rgba(255,255,255,.75),rgba(255,255,255,.45))}
    #celeBox::after{top:40%;bottom:40%;background:linear-gradient(90deg,rgba(255,255,255,.7),rgba(255,255,255,.45))}
    #celeBoxShadow{position:absolute; width:12%; height:2.6%; border-radius:9999px; background:rgba(0,0,0,.28); filter:blur(4px); z-index:1; opacity:0;
      left:78.5%; bottom:27.4%;
    }

    #celeCard.play #celeCarRig{
      animation:
        cele-car-in var(--d-in) cubic-bezier(.17,.9,.12,1) forwards,
        cele-car-out-left var(--d-out) cubic-bezier(.13,.7,.07,1) calc(var(--d-in) + var(--d-drop) + .2s) forwards;
    }
    #celeCard.play .scene{
      animation:
        cele-zoom-in var(--d-zoom) ease-out calc(var(--d-in) + var(--d-drop) + .4s) forwards,
        cele-zoom-hold var(--d-stay) linear calc(var(--d-in) + var(--d-drop) + .4s + var(--d-zoom)) forwards;
    }
    #celeCard.play #celeBox{
      animation:
        cele-box-appear .18s linear var(--d-in) forwards,
        cele-box-bounce var(--d-drop) ease-out calc(var(--d-in) + .02s) forwards;
    }
    #celeCard.play #celeBoxShadow{animation:cele-shadow-grow var(--d-drop) ease-out calc(var(--d-in) + .02s) forwards}

    @keyframes cele-car-in{from{transform:translateX(-140%)}to{transform:translateX(0)}}
    @keyframes cele-car-out-left{from{transform:translateX(0)}to{transform:translateX(-140%)}}
    @keyframes cele-zoom-in{from{transform:scale(1)}to{transform:scale(var(--zoom))}}
    @keyframes cele-zoom-hold{to{}}
    @keyframes cele-box-appear{to{opacity:1}}
    @keyframes cele-box-bounce{
      0%  {transform:translate(0,-10%) scale(1.05) rotate(-3deg)}
      55% {transform:translate(0,0)     scale(1.22)}
      80% {transform:translate(0,-4%)   scale(1.18)}
      100%{transform:translate(0,0)     scale(1.20)}
    }
    @keyframes cele-shadow-grow{from{opacity:0; transform:scale(.6)} to {opacity:.7; transform:scale(1.15)}}
  </style>
</head>
<body class="text-slate-800">

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
                <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-basket-shopping"></i> ตะกร้า <span class="badge">${cartCount}</span></a>
              </div>
            </c:otherwise>
          </c:choose>
        </nav>
      </div>

      <!-- โปรไฟล์ย่อ -->
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

  <!-- ================= Main ================= -->
  <main id="app" class="max-w-7xl mx-auto px-4 sm:px-6 py-6 lg:py-10 space-y-6" data-ctx="${ctx}">
    <!-- สรุป + ค้นหา -->
    <section class="bg-white rounded-2xl shadow p-6">
      <div class="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-6">
        <div>
          <div class="text-xs text-gray-500">ประวัติ</div>
          <h2 class="text-3xl font-extrabold">คำสั่งซื้อของฉัน</h2>
          <div class="mt-2 text-sm text-gray-600">ดูสถานะ อัปโหลด/ดูสลิป ขอ QR แจ้งเตือนด่วน รีวิว และยืนยันรับสินค้า</div>

          <c:if test="${not empty error}">
            <div class="mt-3 bg-red-50 text-red-700 border border-red-200 px-4 py-2 rounded">✖ ${error}</div>
          </c:if>
          <c:if test="${not empty msg}">
            <div class="mt-3 bg-emerald-50 text-emerald-700 border border-emerald-200 px-4 py-2 rounded">✔ ${msg}</div>
          </c:if>
        </div>

        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 w-full lg:w-auto">
          <div class="card"><div class="text-gray-500 text-sm">จำนวนคำสั่งซื้อ</div><div class="text-3xl font-extrabold" id="statAll"><c:out value="${empty statAllServer ? 0 : statAllServer}"/></div></div>
          <div class="card"><div class="text-gray-500 text-sm">รอยืนยันการชำระ</div><div class="text-3xl font-extrabold" id="statPending"><c:out value="${empty statPendingServer ? 0 : statPendingServer}"/></div></div>
          <div class="card"><div class="text-gray-500 text-sm">ยังไม่ชำระ</div><div class="text-3xl font-extrabold" id="statAwait"><c:out value="${empty statAwaitServer ? 0 : statAwaitServer}"/></div></div>
          <div class="card">
            <div class="text-gray-500 text-sm">ยอดรวมโดยประมาณ</div>
            <div class="text-3xl font-extrabold" id="statSum">
              <c:choose>
                <c:when test="${not empty statSumServer}">฿<fmt:formatNumber value="${statSumServer}" type="number" maxFractionDigits="0"/></c:when>
                <c:otherwise>฿0</c:otherwise>
              </c:choose>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-5 grid md:grid-cols-2 gap-3">
        <div class="relative">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" viewBox="0 0 24 24" fill="none">
            <path d="m21 21-3.8-3.8m-7.2 1.8a7 7 0 1 1 0-14 7 7 0 0 1 0 14Z" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
          </svg>
          <input id="q" type="text" placeholder="ค้นหา: OrderID / สถานะ / ชำระเงิน"
                 class="w-full pl-10 pr-10 py-3 border rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-300" autocomplete="off"/>
          <button id="qclear" class="hidden absolute right-2 top-1/2 -translate-y-1/2 px-2 text-gray-400 hover:text-gray-600" title="ล้าง">✕</button>
        </div>
        <div class="flex flex-wrap gap-2">
          <button class="btn" onclick="sortBy('date')">เรียงตามวันที่</button>
          <button class="btn" onclick="sortBy('total')">เรียงตามยอดรวม</button>
          <button class="btn" onclick="sortBy('status')">เรียงตามสถานะ</button>
        </div>
      </div>
    </section>

    <!-- ตาราง -->
    <section class="bg-white rounded-2xl shadow p-0">
      <table class="w-full text-[16px]" role="table" aria-label="ตารางคำสั่งซื้อ" style="table-layout:fixed">
        <colgroup>
          <col style="width:13%">
          <col style="width:14%">
          <col style="width:10%">
          <col style="width:15%">
          <col style="width:24%">
          <col style="width:24%">
        </colgroup>
        <thead class="sticky top-0 bg-white/95 backdrop-blur border-b z-10">
          <tr class="text-left">
            <th class="py-4 px-3">OrderID</th>
            <th class="py-4 px-3">วันที่</th>
            <th class="py-4 px-3">ยอดรวม</th>
            <th class="py-4 px-3">สถานะ</th>
            <th class="py-4 px-3">แจ้งเตือนด่วน</th>
            <th class="py-4 px-3">ชำระเงิน/สลิป/ยืนยัน</th>
          </tr>
        </thead>
        <tbody id="tbody">
          <c:choose>
            <c:when test="${empty orders}">
              <tr><td colspan="6" class="py-10 text-center text-gray-500">ยังไม่มีคำสั่งซื้อ</td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="r" items="${orders}" varStatus="st">
                <c:set var="oid"   value="${r[0]}"/>
                <c:set var="odate" value="${r[1]}"/>
                <c:set var="total" value="${r[2]}"/>
                <c:set var="ost"   value="${r[3]}"/>
                <c:set var="pstat" value="${r[4]}"/>
                <c:set var="fid"   value="${r[5]}"/>

                <c:set var="buyerOk" value="false"/><c:catch><c:set var="buyerOk" value="${r[6]}"/></c:catch>
                <c:if test="${not buyerOk}"><c:catch><c:set var="buyerOk" value="${r.buyerConfirmed}"/></c:catch></c:if>
                <c:set var="finished" value="false"/><c:catch><c:set var="finished" value="${r[7]}"/></c:catch>
                <c:if test="${not finished}"><c:catch><c:set var="finished" value="${r.finished}"/></c:catch></c:if>

                <c:set var="orderCls"
                  value="${
                    ost eq 'SENT_TO_FARMER'      ? 'bg-sky-100 text-sky-800' :
                    ost eq 'FARMER_CONFIRMED'    ? 'bg-emerald-100 text-emerald-800' :
                    ost eq 'PREPARING_SHIPMENT'  ? 'bg-indigo-100 text-indigo-800' :
                    ost eq 'SHIPPED'             ? 'bg-amber-100 text-amber-800' :
                    ost eq 'COMPLETED'           ? 'bg-gray-900 text-white' :
                    ost eq 'REJECTED'            ? 'bg-red-100 text-red-800' :
                    ost eq 'CANCELED' || ost eq 'CANCELLED' ? 'bg-gray-200 text-gray-800' :
                                                             'bg-gray-100 text-gray-700'
                  }"/>

                <c:set var="canCancel" value="${ost == 'SENT_TO_FARMER' or (ost == 'FARMER_CONFIRMED' and pstat == 'AWAITING_BUYER_PAYMENT')}"/>
                <c:set var="canUpload" value="${ost == 'FARMER_CONFIRMED' and pstat == 'AWAITING_BUYER_PAYMENT'}"/>
                <c:set var="showPayArea" value="${ost == 'FARMER_CONFIRMED'}"/>

                <c:set var="readyForBuyerConfirm"
                       value="${
                         (pstat == 'PAID_CONFIRMED' or pstat == 'PAID_VERIFIED' or ost == 'SHIPPED' or ost == 'COMPLETED')
                         and (not buyerOk) and (not finished)
                       }"/>

                <c:set var="needle" value=",${oid},"/>
                <c:set var="alreadyReviewed" value="${fn:contains(reviewedStr, needle)}"/>

                <tr class="<c:out value='${st.index % 2 == 1 ? "bg-gray-50/45" : ""}'/> hover:bg-emerald-50/40 transition-colors
                           <c:out value='${ost == "REJECTED" ? "row-alert ring-2 ring-red-400/60" : ""}'/>"
                    data-oid="${oid}" data-ost="${ost}" data-pstat="${pstat}" data-total="${total}"
                    data-date="${odate}" data-farmer="${fid}" data-buyerok="${buyerOk}" data-finished="${finished}">
                  <td class="py-4 px-3 font-mono text-slate-900 text-[13.8px] leading-5 break-all"><c:out value="${oid}"/></td>
                  <td class="py-4 px-3"><span class="chip bg-gray-100 text-gray-900"><c:out value="${odate}"/></span></td>
                  <td class="py-4 px-3"><span class="chip bg-gray-100 text-gray-900">฿<fmt:formatNumber value="${total}" type="number" maxFractionDigits="0"/></span></td>
                  <td class="py-4 px-3">
                    <span class="chip ${orderCls}"><c:out value="${ost}"/></span>
                  </td>

                  <!-- แจ้งเตือนด่วน -->
                  <td class="py-4 px-3 align-top min-w-[420px]">
                    <div class="space-y-2">
                      <!-- ร้านยกเลิก -->
                      <div id="alert-${oid}" class="<c:out value='${ost=="REJECTED"?"":"hidden"}'/> alert-red rounded-xl p-3">
                        <div class="alert-title">
                          <span class="alert-dot"></span>
                          <span>ร้านยกเลิกคำสั่งซื้อ</span>
                          <span class="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs badge-danger">REJECTED</span>
                        </div>
                        <div id="alert-text-${oid}" class="mt-2 text-sm text-red-800 whitespace-pre-wrap">กำลังดึงเหตุผลจากร้าน…</div>
                        <div class="mt-2 text-xs text-red-700/80">
                          ต้องการคุยกับร้าน?
                          <button type="button" class="underline hover:text-red-900"
                                  onclick="openStoreContact('<c:out value="${oid}"/>')">ติดต่อร้าน</button>
                        </div>
                      </div>

                      <button type="button" class="btn w-full btn-emerald" onclick="openChat('<c:out value="${oid}"/>')">เปิดแจ้งเตือน (แชท)</button>
                      <div class="rounded-xl border-2 border-emerald-300 bg-emerald-50 p-2.5">
                        <div class="text-xs text-emerald-900 mb-1.5 font-semibold">เลือกข้อความด่วน</div>
                        <div class="flex flex-wrap gap-2">
                          <button class="btn btn-sm" onclick="sendQuick('<c:out value="${oid}"/>','ORDER_STATUS')">ถามสถานะ</button>
                          <button class="btn btn-sm" onclick="sendQuick('<c:out value="${oid}"/>','STORE_CONTACT')">ข้อมูลติดต่อร้าน</button>
                          <button class="btn btn-sm" onclick="sendQuick('<c:out value="${oid}"/>','STORE_ADDRESS')">ขอที่อยู่ฟาร์ม</button>
                          <c:choose>
                            <c:when test="${showPayArea}"><button class="btn btn-sm btn-emerald" onclick="sendQuick('<c:out value="${oid}"/>','REQUEST_PAYMENT_QR')">ขอชำระ/QR</button></c:when>
                            <c:otherwise><button class="btn btn-sm opacity-50 cursor-not-allowed" disabled title="รอร้านยืนยันก่อน">ขอชำระ/QR</button></c:otherwise>
                          </c:choose>
                          <button class="btn btn-sm" onclick="sendQuick('<c:out value="${oid}"/>','HOW_TO_UPLOAD')">วิธีอัปโหลดสลิป</button>
                        </div>
                      </div>
                    </div>
                  </td>

                  <!-- ชำระเงิน/สลิป/สเต็ป/ยืนยัน -->
                  <td class="py-4 px-3 align-top min-w-[620px]">
                    <div class="mb-2">
                      <span id="stepTag-${oid}" class="chip bg-gray-100 text-gray-800">ระบุสถานะ…</span>
                    </div>

                    <!-- stepper 6 ขั้น -->
                    <div class="steps mb-3" data-stepper-for="${oid}">
                      <div class="step step-1"><div class="dot"></div><div class="t">1) ร้านยืนยันออเดอร์</div></div>
                      <div class="step step-2"><div class="dot"></div><div class="t">2) ผู้ซื้อชำระเงิน/อัปโหลดสลิป</div></div>
                      <div class="step step-3"><div class="dot"></div><div class="t">3) รอร้านตรวจสอบสลิป</div></div>
                      <div class="step step-4"><div class="dot"></div><div class="t">4) ร้านยืนยันการชำระแล้ว</div></div>
                      <div class="step step-5"><div class="dot"></div><div class="t">5) ผู้ซื้อยืนยันได้รับสินค้าแล้ว</div></div>
                      <div class="step step-6"><div class="dot"></div><div class="t">6) เสร็จสิ้น</div></div>
                    </div>

                    <div class="flex flex-wrap gap-2 mb-3">
                      <a href="${ctx}/orders/${oid}" class="btn btn-outline" title="ดูรายละเอียดคำสั่งซื้อ" aria-label="ดูรายละเอียดคำสั่งซื้อ ${oid}">
                        <svg viewBox="0 0 24 24" class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3" fill="currentColor"/></svg>
                        ดูรายละเอียด
                      </a>

                      <c:choose>
                        <c:when test="${showPayArea}">
                          <button class="btn btn-emerald" onclick="openQr('<c:out value="${oid}"/>')">ชำระเงินด้วย QR (เต็มจอ)</button>
                          <button class="btn" onclick="openReceipt('<c:out value="${oid}"/>')">ดูสลิปของออเดอร์นี้ (เต็มจอ)</button>
                        </c:when>
                        <c:otherwise>
                          <button class="btn opacity-50 cursor-not-allowed" disabled title="รอร้านยืนยันก่อน">ชำระเงินด้วย QR</button>
                          <button class="btn opacity-50 cursor-not-allowed" disabled title="รอร้านยืนยันก่อน">ดูสลิปของออเดอร์นี้</button>
                        </c:otherwise>
                      </c:choose>
                    </div>

                    <!-- โซนอัปโหลด/แจ้งผล/ยืนยัน -->
                    <c:choose>
                      <c:when test="${canUpload}">
                        <div class="rounded-xl border-2 border-emerald-300 bg-emerald-50 text-emerald-900 p-3">
                          <div class="font-semibold mb-2">อัปโหลดสลิปเพื่อแจ้งชำระ</div>
                          <form class="flex flex-wrap items-center gap-2" method="post" action="${ctx}/orders/${oid}/upload-receipt" enctype="multipart/form-data">
                            <input type="text" name="reference" placeholder="อ้างอิง (ถ้ามี)" class="flex-1 min-w-[120px] px-3 py-2 border rounded-md"/>
                            <input type="file" name="file" accept="image/*" class="flex-1 min-w-[220px] text-sm"/>
                            <button class="btn btn-sm" type="submit">อัปโหลดสลิป</button>
                          </form>
                        </div>
                      </c:when>

                      <c:when test="${pstat == 'PAID_PENDING_VERIFY' or pstat == 'PAID_PENDING_VERIFICATION'}">
                        <div class="rounded-xl border-2 border-violet-300 bg-violet-50 text-violet-900 p-3">
                          <div class="font-semibold">รับสลิปแล้ว • รอร้านตรวจสอบสลิป</div>
                        </div>
                      </c:when>

                      <c:when test="${readyForBuyerConfirm}">
                        <div class="rounded-xl border-2 border-emerald-400 bg-emerald-50 text-emerald-900 p-3">
                          <div class="font-semibold mb-2">ร้านยืนยันการชำระแล้ว • โปรดยืนยันว่าได้รับสินค้าเรียบร้อย</div>
                          <button class="btn btn-emerald" onclick="buyerConfirm('<c:out value="${oid}"/>')" data-once="1">
                            <i class="fa-solid fa-check-double"></i>
                            ฉันได้รับสินค้าแล้ว (ยืนยัน)
                          </button>
                        </div>
                      </c:when>

                      <c:when test="${buyerOk and not finished}">
                        <div class="rounded-xl border-2 border-emerald-400 bg-emerald-50 text-emerald-900 p-3">
                          <div class="font-semibold">ผู้ซื้อยืนยันได้รับสินค้าแล้ว • รอดำเนินการปิดออเดอร์</div>
                        </div>
                      </c:when>

                      <c:when test="${finished or ost=='COMPLETED'}">
                        <div class="rounded-xl border-2 border-emerald-400 bg-emerald-50 text-emerald-900 p-3">
                          <div class="font-semibold">เสร็จสิ้น ✔</div>
                        </div>
                      </c:when>

                      <c:otherwise>
                        <div class="rounded-xl border-2 border-gray-200 bg-gray-50 text-gray-700 p-3">
                          <div class="font-semibold">กำลังรอขั้นตอนถัดไป…</div>
                          <div class="text-xs opacity-90">เมื่อร้านยืนยันออเดอร์ ระบบจะแจ้งให้คุณอัปโหลดสลิป</div>
                        </div>
                      </c:otherwise>
                    </c:choose>

                    <!-- ยกเลิก + รีวิว -->
                    <div class="mt-3">
                      <c:if test="${canCancel}">
                        <button class="btn btn-sm btn-danger" onclick="openCancel('<c:out value="${oid}"/>')">ยกเลิกคำสั่งซื้อ</button>
                      </c:if>
                    </div>

                    <div class="mt-3" id="reviewCell-${oid}">
                      <div class="flex flex-wrap gap-2">
                        <c:if test="${(pstat == 'PAID_CONFIRMED' or pstat == 'PAID_VERIFIED' or ost=='SHIPPED' or ost=='COMPLETED') and not alreadyReviewed}">
                          <a href="${ctx}/reviews/new-by-order?orderId=${oid}" class="btn btn-emerald" title="รีวิวได้ 1 ครั้งต่อ 1 ใบเสร็จ">
                            <svg viewBox="0 0 24 24" class="w-4 h-4" fill="currentColor" aria-hidden="true"><path d="M12 2l2.95 6.3 6.95 1.01-5 4.88 1.18 6.9L12 18.77 5.92 21.1 7.1 14.2l-5-4.88 6.95-1.01L12 2z"/></svg>
                            รีวิวออเดอร์นี้
                          </a>
                        </c:if>

                        <a href="${ctx}/farmer/profile/view?farmerId=${fid}" class="btn btn-outline" title="ดูรีวิวทั้งหมดของร้าน">
                          <svg viewBox="0 0 24 24" class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3" fill="currentColor"/>
                          </svg>
                          ดูรีวิว
                        </a>

                        <c:if test="${alreadyReviewed}">
                          <span class="chip bg-emerald-100 text-emerald-800">
                            <svg viewBox="0 0 24 24" class="w-4 h-4" fill="currentColor" aria-hidden="true"><path d="M9 16.2l-3.5-3.5L4 14.2 9 19l11-11-1.5-1.5z"/></svg>
                            รีวิวแล้ว
                          </span>
                        </c:if>
                      </div>
                    </div>

                  </td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </tbody>
      </table>

      <div class="flex flex-wrap items-center justify-between gap-3 text-sm text-gray-600 p-4 border-t">
        <div>เคล็ดลับ: ค้นหา <span class="px-2 py-0.5 rounded-full bg-gray-100">PAID_CONFIRMED</span> หรือเลขออเดอร์</div>
        <div>เขตเวลา: <span id="tz" class="px-2 py-0.5 rounded-full bg-gray-100">th-TH</span></div>
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
        <a class="inline-flex items-center gap-2 rounded-xl px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <!-- ปุ่มลอย -->
  <a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50"
     href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
    <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
  </a>

  <!-- ===== Celebrate Modal (FULL scene) ===== -->
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

              <!-- บ้าน + เงา -->
              <div class="house">
                <div class="house-roof"></div>
                <div class="house-body"></div>
                <div class="window"></div>
                <div class="door"></div>
                <div class="house-step"></div>
              </div>
              <div class="yard-shadow"></div>

              <!-- ต้นไม้ -->
              <div class="tree left back"><div class="crown"></div><div class="trunk"></div></div>
              <div class="tree right"><div class="crown"></div><div class="trunk"></div></div>

              <!-- รถ -->
              <div id="celeCarRig">
                <div class="car">
                  <div class="car-top"></div>
                  <div class="car-body"></div>
                  <div class="designer-line"></div>
                  <div class="door-handles handle1"></div>
                  <div class="door-handles handle2"></div>
                  <div class="back-light"></div>
                  <div class="front-light"></div>
                  <div class="side-mirror"></div>
                  <div class="sits sit1"></div>
                  <div class="sits sit2"></div>
                  <div class="starring"></div>
                  <div class="starring-attach"></div>
                  <div class="wheels first-tyre"></div>
                  <div class="wheels second-tyre"></div>
                </div>
              </div>

              <!-- กล่องวางหน้าบ้าน -->
              <div id="celeBox"></div>
              <div id="celeBoxShadow"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- ===== Viewer Modal (QR/สลิป) ===== -->
  <div id="viewerModal" class="fixed inset-0 z-[9999] hidden">
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
      <div class="flex-1 flex items-center justify-center overflow-hidden select-none">
        <img id="viewerImg" alt="preview" class="max-h-full max-w-full transition-transform duration-150 ease-out will-change-transform"/>
      </div>
    </div>
  </div>

  <!-- ===== Chat Modal (ขั้นต่ำให้ปุ่มแชทใช้งานได้) ===== -->
  <div id="chatModal" class="fixed inset-0 z-[9998] hidden">
    <div class="absolute inset-0 bg-black/60" onclick="closeChat()"></div>
    <div class="absolute inset-0 flex items-center justify-center p-4">
      <div class="w-full max-w-lg bg-white rounded-2xl shadow-xl border flex flex-col max-h-[80vh]">
        <div class="px-5 py-3 border-b flex items-center justify-between">
          <div class="font-bold">แจ้งเตือนด่วน • ออเดอร์ <span id="chatOrder">-</span></div>
          <button class="text-gray-500 hover:text-gray-700" onclick="closeChat()">✕</button>
        </div>
        <div id="chatBody" class="p-4 overflow-auto space-y-2">
          <div id="chatEmpty" class="text-center text-gray-500">เริ่มสนทนาได้เลย…</div>
        </div>
        <div class="p-3 border-t text-xs text-gray-500">* ตัวอย่างหน้าต่างแชทสำหรับข้อความด่วน</div>
      </div>
    </div>
  </div>

  <!-- ===== Cancel Modal ===== -->
  <div id="cancelModal" class="fixed inset-0 z-[9998] hidden">
    <div class="absolute inset-0 bg-black/50" onclick="closeCancel()"></div>
    <div class="absolute inset-0 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-2xl shadow-xl border">
        <div class="px-5 py-4 border-b flex items-center justify-between">
          <div class="font-bold text-lg">ยกเลิกคำสั่งซื้อ</div>
          <button class="text-gray-500 hover:text-gray-700" onclick="closeCancel()">✕</button>
        </div>
        <form id="cancelForm" method="post">
          <div class="p-5">
            <div class="text-gray-700">ยืนยันการยกเลิกออเดอร์ <span id="cancelId" class="font-mono px-2 py-0.5 rounded bg-gray-100">-</span> หรือไม่?</div>
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

  <!-- ================= Scripts ================= -->
  <script>
    const ctx   = '${ctx}';
    const tzEl  = document.getElementById('tz');
    const tbody = document.getElementById('tbody');
    const qInput = document.getElementById('q');
    const qClear = document.getElementById('qclear');
    const CSRF_TOKEN = (document.querySelector('meta[name="_csrf"]')||{}).content || null;
    const CSRF_HEADER = (document.querySelector('meta[name="_csrf_header"]')||{}).content || null;

    if(tzEl){ tzEl.textContent = Intl.DateTimeFormat().resolvedOptions().timeZone || 'th-TH'; }

    /* ===== เมนูโปรไฟล์ ===== */
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
        m.classList.add('hidden');
        b.setAttribute('aria-expanded','false');
      }
    });
    document.addEventListener('keydown',(e)=>{
      if(e.key==='Escape'){
        const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
        if(m) m.classList.add('hidden');
        if(b) b.setAttribute('aria-expanded','false');
      }
    });

    /* ===== Utils ===== */
    function setTxt(id,v){ const el=document.getElementById(id); if(el) el.textContent=String(v); }
    function debounce(fn,ms){ let t; return (...a)=>{ clearTimeout(t); t=setTimeout(()=>fn.apply(this,a),ms); }; }
    function normalizeEpoch(t){
      if(t==null) return null;
      if(typeof t==='number') return t<1e12 ? t*1000 : t;
      const s=String(t).trim(); if(/^\d{9,16}$/.test(s)){ const n=Number(s); return n<1e12 ? n*1000 : n; }
      const iso=Date.parse(s.replace(' ','T')); if(!Number.isNaN(iso)) return iso;
      const m=s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$/);
      if(m){ const[,d,M,Y,hh='0',mm='0',ss='0']=m; const ms=new Date(+Y,+M-1,+d,+hh,+mm,+ss).getTime(); if(!Number.isNaN(ms)) return ms; }
      return null;
    }
    function toast(msg,timeout=2400){
      const toasts=document.getElementById('toasts')||document.body.appendChild(Object.assign(document.createElement('div'),{id:'toasts',className:'fixed right-4 bottom-4 flex flex-col gap-2 z-[10001]'}));
      while(toasts.children.length>=3) toasts.removeChild(toasts.firstChild);
      const el=document.createElement('div'); el.className='px-4 py-2 rounded-xl shadow-lg text-white bg-gray-900'; el.textContent=msg;
      toasts.appendChild(el); setTimeout(()=>{ el.style.opacity='0'; el.style.transform='translateY(6px)'; setTimeout(()=>el.remove(),180); }, timeout);
    }
    async function fetchJSON(url,opt={},timeout=8000){
      const ctrl=new AbortController(); const id=setTimeout(()=>ctrl.abort(),timeout);
      try{ const res=await fetch(url,{...opt,signal:ctrl.signal,headers:{'Accept':'application/json',...(opt.headers||{})}}); if(!res.ok) return null; return await res.json(); }
      catch{ return null } finally{ clearTimeout(id) }
    }
    function probeImage(u){ return new Promise(r=>{ const i=new Image(); i.onload=()=>r(true); i.onerror=()=>r(false); i.src=u+(u.includes('?')?'&':'?')+'t='+Date.now(); }); }

    /* ===== overlay flags from localStorage ===== */
    function applyLocalFlags(tr){
      const oid=String(tr.dataset.oid);
      const lk1 = localStorage.getItem('orders:buyerOk:'+oid);
      const lk2 = localStorage.getItem('orders:finished:'+oid);
      if(lk1==='1') tr.dataset.buyerok = 'true';
      if(lk2==='1') tr.dataset.finished = 'true';
    }

    function hideBuyerOnceButton(tr){
      const btn = tr.querySelector('button[onclick^="buyerConfirm"]');
      if(!btn) return;
      const buyerOk = (tr.dataset.buyerok||'false')==='true';
      const finished = (tr.dataset.finished||'false')==='true';
      if(buyerOk || finished){ btn.style.display='none'; btn.disabled=true; }
    }

    (function seed(){
      const rows=tbody?.querySelectorAll('tr[data-oid]')||[];
      rows.forEach(tr=>{
        applyLocalFlags(tr);
        tr.dataset.ts = String(normalizeEpoch(tr.dataset.date||'') || 0);
        toggleRowUI(tr);
        hideBuyerOnceButton(tr);
      });
      loadAllCancelReasons();
      refreshStats();
    })();

    function refreshStats(){
      const rows=Array.from(tbody.querySelectorAll('tr')).filter(tr=>!tr.id && tr.style.display!=='none');
      const all=rows.length; let sum=0,pending=0,awaitPay=0;
      rows.forEach(tr=>{
        sum += (parseFloat(tr.dataset.total||'0')||0);
        const p=(tr.dataset.pstat||'').toUpperCase();
        if(p==='PAID_PENDING_VERIFY' || p==='PAID_PENDING_VERIFICATION') pending++;
        if(p==='AWAITING_BUYER_PAYMENT') awaitPay++;
      });
      setTxt('statAll', all);
      setTxt('statPending', pending);
      setTxt('statAwait', awaitPay);
      const sumEl=document.getElementById('statSum'); if(sumEl){ sumEl.textContent='฿'+(sum||0).toLocaleString(undefined,{maximumFractionDigits:0}); }
    }

    const doFilterDebounced = debounce(filterRows, 120);
    qInput?.addEventListener('input', ()=>{ qClear.classList.toggle('hidden', !qInput.value); doFilterDebounced(); });
    qInput?.addEventListener('keydown', e=>{ if(e.key==='Escape'){ clearSearch(); qInput.blur(); }});
    qClear?.addEventListener('click', clearSearch);
    function clearSearch(){ qInput.value=''; qClear.classList.add('hidden'); filterRows(); }
    function filterRows(){
      const q=(qInput.value||'').trim().toLowerCase();
      const rows=tbody.querySelectorAll('tr'); let shown=0;
      rows.forEach(tr=>{
        if(tr.id==='nores'){ tr.remove(); return; }
        const t=(tr.dataset.oid+' '+tr.dataset.ost+' '+tr.dataset.pstat).toLowerCase();
        const hit=!q || t.includes(q); tr.style.display = hit ? '' : 'none'; if(hit) shown++;
      });
      if(shown===0){
        const tr=document.createElement('tr'); tr.id='nores';
        const td=document.createElement('td'); td.colSpan=6; td.className='py-6 text-center text-gray-500'; td.textContent='ไม่พบผลลัพธ์ที่ตรงกับ "'+q+'"';
        tr.appendChild(td); tbody.appendChild(tr);
      }
      refreshStats();
    }
    let sortDir = { date:'desc', total:'desc', status:'asc' };
    window.sortBy = function(k){
      const rows=Array.from(tbody.querySelectorAll('tr')).filter(tr=>!tr.id);
      const get=tr=>k==='date'?parseInt(tr.dataset.ts||'0',10):k==='total'?parseFloat(tr.dataset.total||'0'):k==='status'?(tr.dataset.ost||'')+' '+(tr.dataset.pstat||''):tr.dataset.oid||'';
      const dir = sortDir[k]==='asc'?1:-1;
      rows.sort((a,b)=>{ const A=get(a),B=get(b); if(typeof A==='number'&&typeof B==='number') return (A-B)*dir; return String(A).localeCompare(String(B))*dir; });
      rows.forEach(tr=>tbody.appendChild(tr)); sortDir[k]=sortDir[k]==='asc'?'desc':'asc'; toast('เรียงตาม: '+k+(dir===1?' ↑':' ↓'));
      refreshStats();
    }

    function updateStepTag(tr){
      const ost=(tr.dataset.ost||'').toUpperCase();
      const pst=(tr.dataset.pstat||'').toUpperCase();
      const buyerOk=(tr.dataset.buyerok||'false')==='true';
      const finished=(tr.dataset.finished||'false')==='true';
      const el=document.getElementById('stepTag-'+tr.dataset.oid);
      if(!el) return;

      let text='กำลังประมวลผล…', cls='bg-gray-100 text-gray-800';
      const postConfirm = ['FARMER_CONFIRMED','PREPARING_SHIPMENT','SHIPPED','COMPLETED'].includes(ost);

      if (ost==='REJECTED'){ text='คำสั่งซื้อถูกปฏิเสธโดยร้าน'; cls='badge-danger'; }
      else if (ost==='CANCELED' || ost==='CANCELLED'){ text='คำสั่งซื้อถูกยกเลิก'; cls='bg-gray-200 text-gray-900'; }
      else if (!postConfirm){ text='ตอนนี้: ขั้นที่ 1 • รอร้านยืนยัน'; cls='bg-sky-100 text-sky-800'; }
      else if (pst==='AWAITING_BUYER_PAYMENT'){ text='ตอนนี้: ขั้นที่ 2 • รอผู้ซื้อชำระ/อัปโหลดสลิป'; cls='bg-amber-100 text-amber-800'; }
      else if (pst==='PAID_PENDING_VERIFY' || pst==='PAID_PENDING_VERIFICATION'){ text='ตอนนี้: ขั้นที่ 3 • รอร้านตรวจสอบสลิป'; cls='bg-violet-100 text-violet-800'; }
      else if (finished || ost==='COMPLETED'){ text='ตอนนี้: ขั้นที่ 6 • เสร็จสิ้น'; cls='bg-emerald-100 text-emerald-800'; }
      else if (buyerOk){ text='ตอนนี้: ขั้นที่ 5 • ผู้ซื้อยืนยันได้รับสินค้าแล้ว'; cls='bg-emerald-50 text-emerald-900'; }
      else { text='ตอนนี้: ขั้นที่ 4 • ร้านยืนยันการชำระแล้ว'; cls='bg-emerald-50 text-emerald-900'; }

      el.className='chip '+cls; el.textContent=text;
    }

    function applyStepperForRow(tr){
      const box=document.querySelector('[data-stepper-for="'+tr.dataset.oid+'"]'); if(!box) return;
      const s1=box.querySelector('.step-1'), s2=box.querySelector('.step-2'), s3=box.querySelector('.step-3'), s4=box.querySelector('.step-4'), s5=box.querySelector('.step-5'), s6=box.querySelector('.step-6');
      [s1,s2,s3,s4,s5,s6].forEach(s=>{ s.classList.remove('done','now'); });

      const ost=(tr.dataset.ost||'').toUpperCase();
      const pst=(tr.dataset.pstat||'').toUpperCase();
      const buyerOk=(tr.dataset.buyerok||'false')==='true';
      const finished=(tr.dataset.finished||'false')==='true';
      const postConfirm = ['FARMER_CONFIRMED','PREPARING_SHIPMENT','SHIPPED','COMPLETED'].includes(ost);

      if (ost==='REJECTED'){ return; }
      if (!postConfirm){ s1.classList.add('now'); return; }
      s1.classList.add('done');

      if (pst==='AWAITING_BUYER_PAYMENT'){ s2.classList.add('now'); return; }
      s2.classList.add('done');

      if (pst==='PAID_PENDING_VERIFY' || pst==='PAID_PENDING_VERIFICATION'){ s3.classList.add('now'); return; }
      s3.classList.add('done');

      if (!buyerOk){ s4.classList.add('now'); return; }
      s4.classList.add('done');

      if (!finished){ s5.classList.add('now'); return; }
      s5.classList.add('done'); s6.classList.add('done');
    }

    function toggleCancelButton(tr){
      const ost=(tr.dataset.ost||'').toUpperCase();
      const pst=(tr.dataset.pstat||'').toUpperCase();
      const allowed=(ost==='SENT_TO_FARMER') || (ost==='FARMER_CONFIRMED' && pst==='AWAITING_BUYER_PAYMENT');
      const btn = tr.querySelector('button.btn-danger');
      if(btn) btn.style.display = allowed ? '' : 'none';
    }
    function toggleQRButtons(tr){
      const ost=(tr.dataset.ost||'').toUpperCase();
      const show = (ost==='FARMER_CONFIRMED');
      const cell = tr.querySelector('td:last-child');
      if(!cell) return;
      const btns = cell.querySelectorAll('.btn');
      btns.forEach(b=>{
        if(b.textContent.includes('QR') || b.textContent.includes('สลิปของออเดอร์นี้')){
          if(show){ b.classList.remove('opacity-50','cursor-not-allowed'); b.disabled=false; }
          else     { b.classList.add('opacity-50','cursor-not-allowed'); b.disabled=true; }
        }
      });
    }
    function toggleRowUI(tr){
      applyStepperForRow(tr);
      updateStepTag(tr);
      toggleCancelButton(tr);
      toggleQRButtons(tr);
      hideBuyerOnceButton(tr);
    }

    async function loadCancelReason(oid){
      const targets = [
        ctx + '/orders/' + encodeURIComponent(oid) + '/reject-reason',
        ctx + '/orders/' + encodeURIComponent(oid) + '/cancel-reason',
        ctx + '/orders/' + encodeURIComponent(oid) + '/reason',
        ctx + '/orders/' + encodeURIComponent(oid) + '/note',
        ctx + '/farmer/orders/' + encodeURIComponent(oid) + '/reject-reason'
      ];
      let txt = null;
      for(const url of targets){
        try{
          const res = await fetch(url, { headers:{'Accept':'application/json, text/plain, */*'} });
          if(!res.ok) continue;
          const ct = (res.headers.get('content-type')||'').toLowerCase();
          if(ct.includes('application/json')){
            const j = await res.json();
            txt = j?.reasonThai || j?.reason || j?.message || j?.note || j?.remark || j?.data?.reason;
          }else{
            txt = (await res.text()).trim();
          }
          if(txt){ break; }
        }catch(_){}
      }
      if(!txt) txt = 'ร้านยกเลิกออเดอร์นี้ แต่ไม่ได้ระบุเหตุผล';
      const box = document.getElementById('alert-text-'+oid);
      if(box){ box.textContent = txt; }
    }
    function loadAllCancelReasons(){
      const rows = Array.from(tbody.querySelectorAll('tr'));
      rows.forEach(tr=>{
        if((tr.dataset.ost||'').toUpperCase()==='REJECTED'){
          const oid = tr.dataset.oid;
          const alertBox = document.getElementById('alert-'+oid);
          if(alertBox){ alertBox.classList.remove('hidden'); }
          loadCancelReason(oid);
        }
      });
    }

    /* ===== แชท / ด่วน ===== */
    let CUR_ORDER = null;
    function openChat(orderId){
      CUR_ORDER = orderId;
      const chatModal=document.getElementById('chatModal');
      if(!chatModal) return;
      document.getElementById('chatOrder').textContent=String(orderId||'-');
      const chatBody=document.getElementById('chatBody');
      const chatEmpty=document.getElementById('chatEmpty');
      chatBody.innerHTML=''; chatBody.appendChild(chatEmpty); chatEmpty.classList.remove('hidden');
      chatModal.classList.remove('hidden'); document.body.style.overflow='hidden';
    }
    function closeChat(){ const m=document.getElementById('chatModal'); if(m){ m.classList.add('hidden'); document.body.style.overflow=''; } }
    window.openChat=openChat; window.closeChat=closeChat;

    function renderBubble(n){
      const mine=String(n.senderRole||'').toUpperCase()==='BUYER';
      const wrap=document.createElement('div'); wrap.className='flex '+(mine?'justify-end':'justify-start');
      const col=document.createElement('div'); col.className='max-w-[86%]';
      const box=document.createElement('div'); box.className='rounded-xl px-3 py-2 shadow '+(mine?'bg-emerald-600 text-white':'bg-white border');
      if(n.title){ const t=document.createElement('div'); t.className='text-sm font-semibold'; t.textContent=n.title; box.appendChild(t); }
      if(n.imageUrl){ const img=new Image(); img.src=n.imageUrl; img.alt='แนบรูป'; img.className='mt-2 rounded-md border cursor-zoom-in'; img.style.maxWidth='360px'; img.onclick=()=>openViewer(n.imageUrl, n.title||'รูปแนบ'); box.appendChild(img); }
      if(n.message){ const m=document.createElement('div'); m.className='text-sm mt-1 whitespace-pre-wrap'; m.textContent=n.message; box.appendChild(m); }
      col.appendChild(box); wrap.appendChild(col); document.getElementById('chatBody').appendChild(wrap);
      document.getElementById('chatEmpty').classList.add('hidden');
      document.getElementById('chatBody').scrollTop=document.getElementById('chatBody').scrollHeight;
    }
    function tFrom(a){ switch(String(a||'').toUpperCase()){
      case 'ORDER_STATUS':return 'สถานะคำสั่งซื้อ';
      case 'STORE_CONTACT':return 'ข้อมูลติดต่อร้าน';
      case 'STORE_ADDRESS':return 'ที่อยู่ฟาร์ม';
      case 'REQUEST_PAYMENT_QR':
      case 'REQUEST_PAYMENT':return 'ชำระเงินด้วย QR';
      case 'HOW_TO_UPLOAD':return 'วิธีอัปโหลดสลิป';
      default:return 'ข้อความ'; } }
    function mFrom(a){ switch(String(a||'').toUpperCase()){
      case 'ORDER_STATUS':return 'สอบถามสถานะคำสั่งซื้อครับ/ค่ะ';
      case 'STORE_CONTACT':return 'ขอข้อมูลติดต่อร้านด้วยครับ/ค่ะ';
      case 'STORE_ADDRESS':return 'ขอที่อยู่ฟาร์มสำหรับจัดส่ง/ติดต่อครับ/ค่ะ';
      case 'REQUEST_PAYMENT_QR':
      case 'REQUEST_PAYMENT':return 'ขอวิธีชำระเงินหรือ QR ครับ/ค่ะ';
      case 'HOW_TO_UPLOAD':return 'ขอวิธีอัปโหลดสลิปชำระเงินครับ/ค่ะ';
      default:return 'ข้อความ'; } }
    window.sendQuick = async (orderId, action)=>{
      const oid = orderId || CUR_ORDER; if(!oid){ toast('ยังไม่มีหมายเลขออเดอร์'); return; }
      if (document.getElementById('chatModal').classList.contains('hidden')) openChat(oid);
      document.getElementById('chatOrder').textContent = String(oid);
      renderBubble({ senderRole:'BUYER', title:tFrom(action), message:mFrom(action) });

      if (String(action).toUpperCase()==='ORDER_STATUS'){
        const tr = Array.from(tbody.querySelectorAll('tr')).find(x=>x.dataset.oid===String(oid));
        const ost=tr?.dataset.ost || '-'; const pst=tr?.dataset.pstat || '-';
        renderBubble({ senderRole:'SYSTEM', title:'สถานะคำสั่งซื้อ', message:'ORDER: '+ost+'\nPAYMENT: '+pst });
      }
      if (String(action).toUpperCase()==='REQUEST_PAYMENT_QR' || String(action).toUpperCase()==='REQUEST_PAYMENT'){
        const tr = Array.from(tbody.querySelectorAll('tr')).find(x=>x.dataset.oid===String(oid));
        const allow = tr ? (tr.dataset.ost||'').toUpperCase()==='FARMER_CONFIRMED' : false;
        if(!allow){
          renderBubble({ senderRole:'SYSTEM', title:'ชำระเงินด้วย QR', message:'รอร้านยืนยันก่อน จึงจะขอ QR ได้' });
        }else{
          const url = await resolveQrUrl(oid);
          renderBubble({ senderRole:'FARMER', title:'ชำระเงินด้วย QR', message:url?'สแกน QR เพื่อโอนได้เลย':'ยังไม่พบ QR ของร้าน', imageUrl:url||undefined });
        }
      }

      try{
        const body=new URLSearchParams({ action:String(action||'').toUpperCase() });
        const headers = {'Content-Type':'application/x-www-form-urlencoded','Accept':'application/json'};
        if(CSRF_HEADER && CSRF_TOKEN) headers[CSRF_HEADER]=CSRF_TOKEN;
        fetch(ctx + '/orders/' + encodeURIComponent(oid) + '/quick', { method:'POST', headers, body }).catch(()=>{});
      }catch(_){}
    };

    function findAnyOrderId(){
      const row = Array.from(tbody.querySelectorAll('tr[data-oid]')).find(tr=>tr.style.display!=='none') || tbody.querySelector('tr[data-oid]');
      return row ? row.dataset.oid : null;
    }
    function openStoreContact(oid){
      const id = oid || findAnyOrderId();
      if(!id){ toast('ยังไม่มีคำสั่งซื้อเพื่อเปิดแชท'); return; }
      openChat(id);
      renderBubble({ senderRole:'FARMER', title:'ข้อมูลติดต่อร้าน (ตัวอย่าง)', message:'โทร: 081-234-5678\nอีเมล: farm@example.com' });
    }
    window.openStoreContact = openStoreContact;

    async function resolveQrUrl(orderId){
      const d1=await fetchJSON(ctx + '/orders/' + encodeURIComponent(orderId) + '/payment-qr');
      if (d1?.url && await probeImage(d1.url)) return d1.url;
      const tr=Array.from(tbody.querySelectorAll('tr')).find(x=>x.dataset.oid===String(orderId));
      const fid=tr?(tr.dataset.farmer||'').trim():'';
      if(fid){
        const d2=ctx + '/payment/qr/' + encodeURIComponent(fid);
        if(await probeImage(d2)) return d2;
      }
      return null;
    }
    async function resolveReceiptUrl(orderId){
      const d=await fetchJSON(ctx + '/orders/' + encodeURIComponent(orderId) + '/receipt');
      if(d?.url && await probeImage(d.url)) return d.url + (d.url.includes('?')?'&':'?') + 't=' + Date.now();
      const fb2=ctx + '/orders/' + encodeURIComponent(orderId) + '/receipt/image?ts=' + Date.now();
      if(await probeImage(fb2)) return fb2;
      const fb3=ctx + '/payment/receipt/' + encodeURIComponent(orderId) + '?t=' + Date.now();
      return (await probeImage(fb3)) ? fb3 : null;
    }
    function openViewer(url,title){
      ZOOM=1; ROT=0; ORIGIN_X=0; ORIGIN_Y=0; applyTransform();
      const viewerModal=document.getElementById('viewerModal');
      const img=document.getElementById('viewerImg');
      const titleEl=document.getElementById('viewerTitle');
      const dl=document.getElementById('viewerDownload');
      if(!viewerModal || !img || !titleEl || !dl) return;
      img.removeAttribute('src');
      titleEl.textContent=title||'รูปภาพ';
      dl.href=url;
      img.src=url;
      viewerModal.classList.remove('hidden'); document.body.style.overflow='hidden';
    }
    function closeViewer(){ const m=document.getElementById('viewerModal'); if(m){ m.classList.add('hidden'); document.body.style.overflow=''; } }
    let ZOOM=1, ROT=0, ORIGIN_X=0, ORIGIN_Y=0;
    function applyTransform(){ const img=document.getElementById('viewerImg'); if(img) img.style.transform='translate('+ORIGIN_X+'px,'+ORIGIN_Y+'px) scale('+ZOOM+') rotate('+ROT+'deg)'; }
    function viewerZoom(d){ const step=.15; ZOOM=Math.min(8,Math.max(.2,ZOOM+(d>0?step:-step))); applyTransform(); }
    function viewerResetZoom(){ ZOOM=1; ORIGIN_X=0; ORIGIN_Y=0; applyTransform(); }
    function viewerRotate(){ ROT=(ROT+90)%360; applyTransform(); }
    window.viewerZoom=viewerZoom; window.viewerResetZoom=viewerResetZoom; window.viewerRotate=viewerRotate;
    window.openQr=async (orderId)=>{ const url=await resolveQrUrl(orderId); if(!url){ toast('ยังไม่พบ QR ของร้าน'); return; } openViewer(url,'ชำระเงินด้วย QR'); };
    window.openReceipt=async (orderId)=>{ const url=await resolveReceiptUrl(orderId); if(!url){ toast('ยังไม่พบบันทึกสลิป'); return; } openViewer(url,'สลิปการชำระเงิน #'+orderId); };

    /* ===== Celebrate: scene control (6s) ===== */
    const CELE_DUR_IN   = 2200;
    const CELE_DUR_DROP =  500;
    const CELE_DUR_OUT  = 1600;
    const CELE_TOTAL    = 6000;

    let CELE_TIMER=null;

    function celeRefs(){
      return {
        modal: document.getElementById('celeModal'),
        card:  document.getElementById('celeCard'),
        scene: document.getElementById('celeScene'),
        car:   document.getElementById('celeCarRig'),
        box:   document.getElementById('celeBox'),
        sh:    document.getElementById('celeBoxShadow'),
      };
    }
    function celeReset(){
      const {modal,card,scene,car,box,sh}=celeRefs();
      if(!modal || !card) return;
      clearTimeout(CELE_TIMER);
      modal.classList.remove('show');
      card.classList.remove('play','cele-enter-active');
      car && car.classList.remove('moving');
      scene && (scene.style.transform='');
      car && (car.style.transform='translateX(-140%)');
      if(box){ box.style.opacity=0; box.style.transform=''; }
      if(sh){  sh.style.opacity=0;  sh.style.transform=''; }
    }
    function celePlay(){
      const {card,car}=celeRefs();
      if(!card) return;
      card.classList.remove('play','cele-enter-active');
      void card.offsetWidth; // reflow
      card.classList.add('play','cele-enter-active');

      if(car){
        car.classList.add('moving');
        setTimeout(()=>car.classList.remove('moving'), CELE_DUR_IN);
        setTimeout(()=>car.classList.add('moving'),  CELE_DUR_IN + CELE_DUR_DROP + 200);
        setTimeout(()=>car.classList.remove('moving'), CELE_DUR_IN + CELE_DUR_DROP + CELE_DUR_OUT);
      }
    }
    function openCelebrate(){
      const {modal}=celeRefs();
      if(!modal) return;
      celeReset();
      modal.classList.add('show');
      requestAnimationFrame(()=>{ celePlay(); });
      CELE_TIMER=setTimeout(closeCelebrate, CELE_TOTAL);
    }
    function closeCelebrate(){
      const {modal}=celeRefs();
      if(!modal) return;
      clearTimeout(CELE_TIMER);
      modal.classList.remove('show');
    }
    window.closeCelebrate=closeCelebrate;

    /* ===== Buyer confirm flow ===== */
    const CONFIRM_LOCK = new Set();
    window.buyerConfirm = async function(oid){
      if(!oid || CONFIRM_LOCK.has(oid)) return;
      CONFIRM_LOCK.add(oid);

      const tr = Array.from(tbody.querySelectorAll('tr')).find(x=>x.dataset.oid===String(oid));
      if(!tr) return;

      // ซ่อนปุ่มทันที (กดครั้งเดียว)
      const btn = tr.querySelector('[onclick^="buyerConfirm"]');
      if(btn){ btn.disabled = true; btn.style.display='none'; }

      // 1) ดันสถานะในหน้า → ขั้น 5 + จำฝั่ง client
      tr.dataset.buyerok = 'true';
      tr.dataset.finished = 'false';
      localStorage.setItem('orders:buyerOk:'+oid,'1');
      localStorage.removeItem('orders:finished:'+oid);
      toggleRowUI(tr);

      // 2) เล่นอนิเมชันฉากเต็ม
      openCelebrate();

      // 3) ยิงบันทึกไป server (fire-and-forget)
      try{
        const headers = {'Content-Type':'application/x-www-form-urlencoded','Accept':'application/json'};
        if(CSRF_HEADER && CSRF_TOKEN) headers[CSRF_HEADER]=CSRF_TOKEN;
        fetch(ctx + '/orders/' + encodeURIComponent(oid) + '/buyer-confirm', {
          method:'POST', headers, body:'done=1'
        }).catch(()=>{});
      }catch(_){}

      // 4) Fallback: หลังจบอนิเมชัน → ขั้น 6
      setTimeout(()=>{
        tr.dataset.finished = 'true';
        localStorage.setItem('orders:finished:'+oid,'1');
        toggleRowUI(tr);
      }, CELE_TOTAL + 50);
    };

    // init stepper display
    document.querySelectorAll('#tbody tr[data-oid]').forEach(toggleRowUI);
  </script>
</body>
</html>
