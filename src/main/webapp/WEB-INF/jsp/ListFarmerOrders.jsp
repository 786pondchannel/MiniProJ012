<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%> 
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />

<c:if test="${empty ctx}">
  <c:set var="ctx" value="${pageContext.request.contextPath}"/>
</c:if>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>รายการออเดอร์ของร้าน • เกษตรกรบ้านเรา</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --ink:#0f172a; --muted:#64748b; --border:#e5e7eb }
    *{font-family:'Prompt',system-ui,-apple-system,'Segoe UI',Roboto,'Helvetica Neue',Arial}
    body{background:#f8fafc; color:var(--ink)}
    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    .card{border:1px solid var(--border);border-radius:16px;background:#fff;padding:16px;box-shadow:0 10px 26px rgba(0,0,0,.05)}
    .chip{border-radius:9999px;padding:.2rem .55rem;font-size:.78rem;font-weight:700;display:inline-flex;align-items:center;gap:.35rem}
    .tbl th,.tbl td{padding:.7rem .8rem; vertical-align: top}
    .tbl tr{border-top:1px solid var(--border); transition: transform .18s ease, box-shadow .18s ease, background-color .18s ease}
    .tbl tbody tr:hover{transform:translateY(-1px); box-shadow:0 8px 22px rgba(0,0,0,.05); background:#f9fafb}

    .btn{display:inline-flex;align-items:center;gap:.4rem;border-radius:.7rem;padding:.5rem .85rem}
    .btn-ghost{background:#f1f5f9}
    .btn-ghost:hover{background:#e2e8f0}

    .btn-cta-sm{
      background:linear-gradient(135deg,#10b981 0%, #0ea5e9 100%);
      color:#fff;border-radius:.7rem;padding:.45rem .8rem;
      display:inline-flex;align-items:center;gap:.45rem;
      box-shadow:0 6px 16px rgba(16,185,129,.18);
      transition:transform .15s ease, box-shadow .15s ease, background-position .2s ease;
      font-weight:700; font-size:.9rem; line-height:1;
      background-size:200% 100%; background-position:0 0;
    }
    .btn-cta-sm:hover{transform:translateY(-1px); box-shadow:0 10px 22px rgba(16,185,129,.25); background-position:100% 0}
    .btn-cta-sm svg{width:16px;height:16px;transition:transform .2s ease}
    .btn-cta-sm:hover svg{transform:translateX(2px)}

    @keyframes fadeUp{from{opacity:0; transform:translateY(8px)} to{opacity:1; transform:translateY(0)}}
    .fadeUp{animation:fadeUp .45s var(--delay,0s) both}
    @keyframes pulseDot{0%,100%{transform:scale(1); opacity:.9} 50%{transform:scale(1.25); opacity:1}}
    .pulseDot{animation:pulseDot 1.6s ease-in-out infinite}

    #topProgress{position:fixed;left:0;top:0;height:3px;width:0;background:linear-gradient(90deg,#10b981,#0ea5e9);z-index:60;box-shadow:0 0 10px rgba(16,185,129,.6)}

    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }
  </style>
</head>
<body class="min-h-screen">
<div id="topProgress"></div>

<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />
<header class="header shadow-md text-white">
  <div class="container mx-auto px-6 py-3 topbar">
    <div class="flex items-center gap-3">
      <a href="${ctx}/main" class="flex items-center gap-3 shrink-0">
        <img src="https://cdn-icons-png.flaticon.com/512/2909/2909763.png" class="h-8 w-8" alt="logo"/>
        <span class="hidden sm:inline font-bold">เกษตรกรบ้านเรา</span>
      </a>

      <nav class="nav-scroll ml-2">
        <div class="flex items-center gap-2 md:gap-3 whitespace-nowrap text-[13px] md:text-sm">
          <a href="${ctx}/product/create" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-plus"></i> สร้างสินค้า</a>
          <a href="${ctx}/farmer/profile" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-store"></i> โปรไฟล์ร้าน</a>
          <a href="${ctx}/product/list/Farmer" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-rectangle-list"></i> สินค้าของฉัน</a>
          <a href="${ctx}/farmer/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-truck"></i> ออเดอร์</a>
        </div>
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
              <img src="${avatarUrl}?t=${now.time}" alt="โปรไฟล์" class="h-8 w-8 rounded-full border-2 border-white shadow-md mr-2 object-cover"/>
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
                  <a href="${ctx}/farmer/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50 transition-colors"><span class="mr-2">👨‍🌾</span> แก้ไขโปรไฟล์เกษตรกร</a>
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

<main class="max-w-6xl mx-auto px-4 py-6 space-y-6">

  <c:if test="${not empty msg}">
    <div class="card bg-emerald-50 border-emerald-200 text-emerald-800 fadeUp">${msg}</div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="card bg-rose-50 border-rose-200 text-rose-700 fadeUp">${error}</div>
  </c:if>

  <%-- สรุปนับจาก orders: row=[0]=orderId,[1]=orderDate,[2]=totalPrice,[3]=orderStatus,[4]=paymentStatus,[5]=customerName --%>
  <c:set var="cntAll" value="${empty orders ? 0 : fn:length(orders)}"/>
  <c:set var="cntStep1" value="0"/>
  <c:set var="cntPaidPending" value="0"/>
  <c:set var="cntPaidConf" value="0"/>
  <c:set var="cntPrep" value="0"/>
  <c:set var="cntShip" value="0"/>
  <c:set var="cntDone" value="0"/>

  <c:forEach var="oo" items="${orders}">
    <c:set var="L" value="${fn:length(oo)}"/>
    <c:set var="stt" value="${L gt 3 ? oo[3] : ''}"/>
    <c:set var="pstt" value="${L gt 4 ? oo[4] : ''}"/>

    <c:if test="${stt=='FARMER_CONFIRMED'}"><c:set var="cntStep1" value="${cntStep1+1}"/></c:if>
    <c:if test="${pstt=='PAID_PENDING_VERIFY'}"><c:set var="cntPaidPending" value="${cntPaidPending+1}"/></c:if>
    <c:if test="${pstt=='PAID_CONFIRMED'}"><c:set var="cntPaidConf" value="${cntPaidConf+1}"/></c:if>
    <c:if test="${stt=='PREPARING_SHIPMENT'}"><c:set var="cntPrep" value="${cntPrep+1}"/></c:if>
    <c:if test="${stt=='SHIPPED'}"><c:set var="cntShip" value="${cntShip+1}"/></c:if>
    <c:if test="${stt=='COMPLETED'}"><c:set var="cntDone" value="${cntDone+1}"/></c:if>
  </c:forEach>

  <section class="grid gap-3 sm:grid-cols-3">
    <div class="card fadeUp" style="--delay:.02s">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-xs text-slate-500">ทั้งหมด</div>
          <div class="text-2xl font-extrabold"><c:out value="${cntAll}"/></div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <i class="fa-solid fa-list-check"></i>
        </div>
      </div>
    </div>
    <div class="card fadeUp" style="--delay:.06s">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-xs text-slate-500">Step 1: ร้านยืนยัน</div>
          <div class="text-2xl font-extrabold text-emerald-700"><c:out value="${cntStep1}"/></div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <i class="fa-solid fa-circle-check"></i>
        </div>
      </div>
    </div>
    <div class="card fadeUp" style="--delay:.1s">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-xs text-slate-500">Step 2–3: มีการชำระเงิน</div>
          <div class="text-2xl font-extrabold text-blue-700"><c:out value="${cntPaidPending + cntPaidConf}"/></div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
          <i class="fa-solid fa-money-check-dollar"></i>
        </div>
      </div>
    </div>
  </section>

  <%-- ===== ฟอร์มค้นหา/กรอง ===== --%>
  <section class="card fadeUp" style="--delay:.14s">
    <form id="filterForm" method="get" class="grid sm:grid-cols-4 gap-3">
      <div class="sm:col-span-2">
        <label class="text-xs text-gray-500">ค้นหา</label>
        <div class="relative">
          <input id="q" type="text" name="q" value="${fn:escapeXml(q)}"
                 class="w-full border rounded-lg px-3 py-2 pl-9"
                 placeholder="เลขออเดอร์ / ชื่อผู้ซื้อ"/>
          <span class="absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400">
            <i class="fa-solid fa-magnifying-glass"></i>
          </span>
        </div>
      </div>

      <div>
        <label class="text-xs text-gray-500">สถานะออเดอร์</label>
        <select id="status" name="status" class="w-full border rounded-lg px-3 py-2">
          <option value="">-- ทั้งหมด --</option>
          <option value="SENT_TO_FARMER"      ${status=='SENT_TO_FARMER'?'selected':''}>ส่งถึงร้าน</option>
          <option value="FARMER_CONFIRMED"    ${status=='FARMER_CONFIRMED'?'selected':''}>ร้านยืนยัน</option>
          <option value="PREPARING_SHIPMENT"  ${status=='PREPARING_SHIPMENT'?'selected':''}>เตรียมจัดส่ง</option>
          <option value="SHIPPED"             ${status=='SHIPPED'?'selected':''}>จัดส่งแล้ว</option>
          <option value="COMPLETED"           ${status=='COMPLETED'?'selected':''}>เสร็จสิ้น</option>
          <option value="CANCELED"            ${status=='CANCELED'?'selected':''}>ยกเลิก</option>
        </select>
      </div>

      <div>
        <label class="text-xs text-gray-500">สถานะชำระเงิน</label>
        <select id="pay" name="pay" class="w-full border rounded-lg px-3 py-2">
          <option value="">-- ทั้งหมด --</option>
          <option value="UNPAID"                 ${pay=='UNPAID'?'selected':''}>ยังไม่ชำระ</option>
          <option value="AWAITING_BUYER_PAYMENT" ${pay=='AWAITING_BUYER_PAYMENT'?'selected':''}>รอผู้ซื้อชำระ</option>
          <option value="PAID_PENDING_VERIFY"    ${pay=='PAID_PENDING_VERIFY'?'selected':''}>ชำระแล้ว (รอตรวจ)</option>
          <option value="PAID_CONFIRMED"         ${pay=='PAID_CONFIRMED'?'selected':''}>ยืนยันรับเงิน</option>
          
        </select>
      </div>
      <div class="hidden"><button type="submit">submit</button></div>
    </form>
    <div class="mt-2 text-xs text-gray-500">
      * พิมพ์ค้นหา/เลือกสถานะแล้วระบบจะกรองให้ทันที
    </div>
  </section>

  <%-- ===== ตารางออเดอร์ ===== --%>
  <section class="card fadeUp" style="--delay:.18s">
    <div class="flex items-center justify-between mb-3">
      <div class="text-sm text-gray-500">รายการออเดอร์</div>
      <c:if test="${not empty orders}">
        <div class="text-sm text-gray-600">ทั้งหมด <span class="font-bold"><c:out value="${fn:length(orders)}"/></span> ออเดอร์</div>
      </c:if>
    </div>

    <c:choose>
      <c:when test="${empty orders}">
        <div class="py-12 text-center text-gray-500">
          <div class="mx-auto w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-3 animate-pulse">
            <i class="fa-regular fa-folder-open text-slate-400 text-2xl"></i>
          </div>
          ไม่พบออเดอร์ตามเงื่อนไข
        </div>
      </c:when>

      <c:otherwise>
        <div class="overflow-x-auto">
          <table class="tbl w-full text-sm">
            <thead class="text-gray-500">
              <tr>
                <th>เลขออเดอร์</th>
                <th>ผู้ซื้อ</th>
                <th class="text-right">ยอดรวม</th>
                <th>สถานะออเดอร์</th>
                <th>ชำระเงิน</th>
                <th>สร้างเมื่อ</th>
                <th class="text-right">การทำงาน</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="o" items="${orders}" varStatus="stx">
                <c:set var="L" value="${fn:length(o)}"/>
                <c:set var="oid" value="${fn:trim(L gt 0 ? o[0] : '')}"/>
                <c:set var="created" value="${L gt 1 ? o[1] : ''}"/>
                <c:set var="total"   value="${L gt 2 ? o[2] : null}"/>
                <c:set var="st"  value="${fn:toUpperCase(fn:trim(L gt 3 ? o[3] : ''))}"/>
                <c:set var="paySt"   value="${L gt 4 ? o[4] : ''}"/>
                <c:set var="buyer"   value="${L gt 5 ? o[5] : ''}"/>

                <tr class="fadeUp" id="row-${fn:escapeXml(oid)}" style="--delay:${stx.index * 0.03}s"
                    data-oid="${fn:escapeXml(oid)}">

                  <td class="font-mono">
                    <div class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-emerald-500 pulseDot"></span>
                      <c:out value="${oid}"/>
                    </div>
                  </td>

                  <td>
                    <div class="flex items-center gap-2">
                      <span class="inline-flex items-center justify-center w-6 h-6 rounded-full bg-slate-100 text-slate-600">
                        <c:out value="${empty buyer ? '?' : fn:substring(buyer,0,1)}"/>
                      </span>
                      <span class="font-medium"><c:out value="${buyer}"/></span>
                    </div>
                  </td>

                  <td class="text-right font-semibold text-emerald-700">
                    <c:choose>
                      <c:when test="${not empty total}">
                        <fmt:formatNumber value="${total}" type="currency" currencySymbol="฿" maxFractionDigits="2"/>
                      </c:when>
                      <c:otherwise>—</c:otherwise>
                    </c:choose>
                  </td>

                  <td>
                    <c:choose>
                      <c:when test="${st=='SENT_TO_FARMER'}"><span class="chip bg-slate-100 text-slate-700">📨 ส่งถึงร้าน</span></c:when>
                      <c:when test="${st=='FARMER_CONFIRMED'}"><span class="chip bg-emerald-100 text-emerald-800">✅ ร้านยืนยัน</span></c:when>
                      <c:when test="${st=='PREPARING_SHIPMENT'}"><span class="chip bg-amber-100 text-amber-800">📦 เตรียมจัดส่ง</span></c:when>
                      <c:when test="${st=='SHIPPED'}"><span class="chip bg-indigo-100 text-indigo-800">🚚 จัดส่งแล้ว</span></c:when>
                      <c:when test="${st=='COMPLETED'}"><span class="chip bg-emerald-100 text-emerald-800">🏁 เสร็จสิ้น</span></c:when>       
                      <c:when test="${st=='CANCELED'}"><span class="chip bg-rose-50 text-rose-700">🚫 ยกเลิก</span></c:when>
                      <c:otherwise><span class="chip bg-slate-100 text-slate-700"><c:out value="${st}"/></span></c:otherwise>
                    </c:choose>
                  </td>

                  <td>
                    <c:choose>
                      <c:when test="${paySt=='PAID_CONFIRMED'}"><span class="chip bg-emerald-100 text-emerald-800">🔍 ยืนยันรับเงิน</span></c:when>
                      <c:when test="${paySt=='PAID_PENDING_VERIFY'}"><span class="chip bg-blue-100 text-blue-800">💳 ชำระแล้ว (รอตรวจ)</span></c:when>
                      <c:when test="${paySt=='AWAITING_BUYER_PAYMENT'}"><span class="chip bg-slate-100 text-slate-700">💳 รอผู้ซื้อชำระ</span></c:when>
                      <c:when test="${paySt=='UNPAID'}"><span class="chip bg-slate-100 text-slate-700">⏳ ยังไม่ชำระ</span></c:when>
                      <c:otherwise><span class="chip bg-slate-100 text-slate-700"><c:out value="${empty paySt ? '—' : paySt}"/></span></c:otherwise>
                    </c:choose>
                  </td>

                  <td class="text-gray-600">
                    <c:out value="${created}"/>
                  </td>

                  <td class="text-right">
                    <div class="flex justify-end gap-2">
                      <a class="btn-cta-sm" href="${ctx}/farmer/orders/${fn:escapeXml(oid)}" title="ดูรายละเอียดออเดอร์ ${fn:escapeXml(oid)}">
                        <span>ดูรายละเอียด</span>
                        <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M9 6l6 6-6 6"/></svg>
                      </a>
                    </div>
                  </td>

                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </c:otherwise>
    </c:choose>
  </section>

  <div class="flex justify-between items-center">
    <a href="${ctx}/farmer/profile" class="btn btn-ghost">← กลับโปรไฟล์ร้าน</a>
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
      <a class="btn bg-emerald-600 hover:bg-emerald-700 text-white shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
        <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
      </a>
    </div>
  </div>
</footer>

<a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50"
   href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
  <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
</a>

<script>
  // ===== โปรไฟล์ดรอปดาวน์ =====
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

  // ===== Auto-submit ฟิลเตอร์ + Progress bar =====
  (function(){
    var f  = document.getElementById('filterForm');
    var q  = document.getElementById('q');
    var st = document.getElementById('status');
    var py = document.getElementById('pay');
    var bar = document.getElementById('topProgress');

    function startBar(){
      if(!bar) return;
      bar.style.transition = 'none';
      bar.style.width = '0';
      bar.offsetHeight;
      bar.style.transition = 'width .4s ease';
      bar.style.width = '60%';
      setTimeout(function(){ bar.style.width='100%'; }, 350);
    }
    function submitSafe(){
      startBar();
      if (f.requestSubmit) f.requestSubmit(); else f.submit();
    }
    if (st) st.addEventListener('change', submitSafe);
    if (py) py.addEventListener('change', submitSafe);

    if (q) {
      var t=null;
      q.addEventListener('input', function(){
        if (t) clearTimeout(t);
        t = setTimeout(submitSafe, 420);
      });
    }
    window.addEventListener('pageshow', function(){
      if(bar){ bar.style.transition='width .25s ease'; bar.style.width='100%'; setTimeout(function(){ bar.style.width='0' }, 250); }
    });
  })();
</script>
</body>
</html>
