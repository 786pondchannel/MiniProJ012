<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />

<!-- ===== Context & Shortcuts ===== -->
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />
<c:set var="p" value="${product}" />
<c:set var="images" value="${images}" />
<c:set var="fe" value="${fieldErrors}" /> <!-- Map<String,String> field error (ถ้ามี) -->
<c:set var="errList" value="${errors}" />  <!-- List<String> errorรวม (ถ้ามี) -->

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>
    <c:choose>
      <c:when test="${not empty p.productId}">แก้ไขสินค้า</c:when>
      <c:otherwise>สร้างสินค้า</c:otherwise>
    </c:choose>
  </title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --ink:#0f172a; --muted:#6b7280; --border:#e5e7eb; --emerald:#10b981; }
    body{ font-family:'Prompt',system-ui,Segoe UI,Roboto,sans-serif; color:var(--ink); }
    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }
    .page-wrap{ background:linear-gradient(180deg,#f0fdfa 0%,#ffffff 22%,#ffffff 100%) }
    .card{ background:#fff; border:1px solid var(--border); border-radius:18px; box-shadow:0 10px 25px rgba(2,8,23,.06) }
    .hint{ font-size:.82rem; color:var(--muted) }
    .igroup{ position:relative }
    .igroup .i{ position:absolute; left:.75rem; top:50%; transform:translateY(-50%); color:#9ca3af }
    .igroup input,.igroup textarea,.igroup select{ padding-left:2.25rem }

    .dropzone{ border:2px dashed #d1d5db; border-radius:14px; transition:.2s }
    .dropzone.active{ border-color:#10b981; background:#ecfdf5 }
    .thumb{ position:relative; border-radius:12px; overflow:hidden; border:1px solid #e5e7eb }
    .thumb img{ display:block; width:100%; height:100%; object-fit:cover }
    .thumb-btn{ position:absolute; top:6px; right:6px; background:rgba(0,0,0,.6); color:#fff; border-radius:8px; padding:4px 8px; font-size:.75rem }

    .btn{ display:inline-flex; align-items:center; gap:.55rem; padding:.7rem 1.1rem; border-radius:.8rem; font-weight:600 }
    .btn-save{ position:relative; overflow:hidden; color:#fff; background:#16a34a }
    .btn-save:hover{ filter:brightness(1.05) }
    .btn-save:after{ content:""; position:absolute; inset:0; transform:translateX(-120%) skewX(-15deg);
      background:linear-gradient(90deg,transparent,rgba(255,255,255,.35),transparent); transition:transform .6s }
    .btn-save:hover:after{ transform:translateX(120%) skewX(-15deg) }

    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }

    /* ===== Alerts ===== */
    .alert{ border-radius:14px; padding:12px 14px; display:flex; gap:12px; align-items:flex-start; box-shadow:0 6px 16px rgba(2,8,23,.08) }
    .alert-error{ background:#fef2f2; border:1px solid #fecaca; color:#991b1b; border-left-width:6px; border-left-color:#f87171 }
    .alert-success{ background:#ecfdf5; border:1px solid #a7f3d0; color:#065f46; border-left-width:6px; border-left-color:#34d399 }
    .alert-info{ background:#eff6ff; border:1px solid #bfdbfe; color:#1e3a8a; border-left-width:6px; border-left-color:#60a5fa }

    /* ===== Modal + confetti ===== */
    @keyframes overlayIn { from{opacity:0} to{opacity:1} }
    @keyframes popIn { 0%{transform:translateY(8px) scale(.96);opacity:0} 100%{transform:none;opacity:1} }
    @keyframes floatUp { 0%{transform:translateY(8px);opacity:0} 100%{transform:none;opacity:1} }
    @keyframes barOut { from{transform:scaleX(1)} to{transform:scaleX(0)} }
    .animate-overlay{ animation: overlayIn .25s ease-out both }
    .animate-pop{ animation: popIn .35s cubic-bezier(.16,1,.3,1) both }
    .animate-float{ animation: floatUp .5s .08s ease-out both }
    .animate-bar{ transform-origin:left; animation: barOut 2.5s linear forwards }
    .btn-ghost{ background:#f1f5f9 }
    .btn-ghost:hover{ background:#e2e8f0 }
    .confetti{position:absolute;inset:0;overflow:hidden;pointer-events:none}
    .confetti i{position:absolute;width:10px;height:14px;opacity:0.95;border-radius:2px;animation:drop linear forwards}
    @keyframes drop{ 0%{transform:translateY(-20vh) rotate(0deg); opacity:.95}
                     100%{transform:translateY(80vh) rotate(360deg); opacity:0} }
  </style>
</head>

<body
  class="page-wrap min-h-screen"
  data-is-edit="<c:out value='${not empty p.productId}'/>"
  data-updated-param="<c:out value='${param.updated}'/>"
  data-just-updated="<c:out value='${(not empty requestScope.justUpdated) and requestScope.justUpdated}'/>"
>
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
                <a href="${ctx}/product/create" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-solid fa-plus"></i> สร้างสินค้า
                </a>
                <a href="${ctx}/farmer/profile" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-solid fa-store"></i> โปรไฟล์ร้าน
                </a>
                <a href="${ctx}/product/list/Farmer" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-regular fa-rectangle-list"></i> สินค้าของฉัน
                </a>
                <a href="${ctx}/farmer/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-solid fa-truck"></i> ออเดอร์
                </a>
              </div>
            </c:when>
            <c:otherwise>
              <div class="flex items-center gap-2 md:gap-3 whitespace-nowrap text-[13px] md:text-sm">
                <a href="${ctx}/main" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-solid fa-house"></i> หน้าหลัก
                </a>
                <a href="${ctx}/catalog/list" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-solid fa-list"></i> สินค้าทั้งหมด
                </a>
                <a href="${ctx}/orders" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10">
                  <i class="fa-regular fa-clock"></i> ประวัติการสั่งจองสินค้า
                </a>
                <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10 icon-btn">
                  <i class="fa-solid fa-basket-shopping"></i> ตะกร้า <span class="badge">${cartCount}</span>
                </a>
              </div>
            </c:otherwise>
          </c:choose>
        </nav>
      </div>

      <form method="get" action="${ctx}/catalog/list" class="justify-self-center lg:justify-self-start w-full max-w-2xl mx-4 hidden sm:block">
        <div class="relative">
          <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-white/70"></i>
          <input name="kw" placeholder="ค้นหาผลผลิต/ร้าน/คำสำคัญ…"
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
  <!-- ================= /Header ================= -->

  <!-- ================= Flash / Error Pretty ================= -->
  <div class="max-w-6xl mx-auto mt-6 px-4 space-y-3">
    <c:if test="${not empty msg}">
      <div class="alert alert-success" id="flashOk">
        <i class="fa-solid fa-circle-check mt-0.5"></i>
        <div class="flex-1"><strong>สำเร็จ:</strong> <c:out value="${msg}"/></div>
        <button type="button" aria-label="ปิด" class="px-2 py-1 rounded hover:bg-emerald-100" onclick="dismiss('flashOk')">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>
    </c:if>

    <c:if test="${not empty error}">
      <div class="alert alert-error" id="flashErr">
        <i class="fa-solid fa-triangle-exclamation mt-0.5"></i>
        <div class="flex-1">
          <strong>เกิดข้อผิดพลาด:</strong> <c:out value="${error}"/>
          <c:if test="${not empty errList}">
            <button type="button" class="ml-3 underline hover:opacity-80" onclick="toggleErrorDetails()">ดูรายละเอียด</button>
          </c:if>
        </div>
        <button type="button" aria-label="ปิด" class="px-2 py-1 rounded hover:bg-red-100" onclick="dismiss('flashErr')">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>
    </c:if>

    <c:if test="${not empty errList}">
      <div class="card p-4 border border-red-200 border-l-4 border-l-red-400" id="errorDetails" style="display:none">
        <div class="flex items-center justify-between">
          <div class="font-semibold text-red-700 flex items-center gap-2">
            <i class="fa-regular fa-circle-xmark"></i> รายละเอียดข้อผิดพลาด
          </div>
          <button type="button" class="px-3 py-1 text-sm rounded bg-red-50 hover:bg-red-100 border border-red-200"
                  onclick="copyErrors()">คัดลอกทั้งหมด</button>
        </div>
        <ul class="mt-2 list-disc pl-6 space-y-1">
          <c:forEach var="t" items="${errList}">
            <li><c:out value="${t}"/></li>
          </c:forEach>
        </ul>
      </div>
    </c:if>
  </div>

  <!-- ================= Main ================= -->
  <main class="container mx-auto px-4 py-8 grid xl:grid-cols-3 gap-8">
    <!-- ฟอร์มหลัก: รวมอัปโหลด + ข้อมูล -->
    <div class="xl:col-span-2">
      <div class="card p-6">
        <c:choose>
          <c:when test="${empty p.productId}">
            <c:set var="formAction" value="${ctx}/product/create"/>
          </c:when>
          <c:otherwise>
            <c:set var="formAction" value="${ctx}/product/update"/>
          </c:otherwise>
        </c:choose>

        <!-- ===== Normalize สถานะ ===== -->
        <c:set var="stRaw"  value="${empty p.status ? '' : p.status}" />
        <c:set var="stNorm" value="${fn:trim(stRaw)}" />
        <c:set var="statusCompact" value="${stNorm}" />
        <c:if test="${stNorm == 'กำลังเปิดรับจอง' or stNorm == 'เปิดรับจอง' or stNorm == 'พรีออเดอร์' or stNorm == 'preorder' or stNorm == 'pre-order'}">
          <c:set var="statusCompact" value="พรีออเดอร์ได้แล้ว" />
        </c:if>
        <c:if test="${stNorm == 'สินค้าหมดชั่วคราว' or stNorm == 'หมด' or stNorm == 'out of stock' or stNorm == 'out-of-stock' or stNorm == 'oos'}">
          <c:set var="statusCompact" value="ปิดรับจอง" />
        </c:if>
        <c:if test="${stNorm == 'พร้อมส่ง'}">
          <c:set var="statusCompact" value="พร้อมสั่งซื้อแล้ว" />
        </c:if>
        <c:if test="${empty statusCompact}">
          <c:set var="statusCompact" value="พรีออเดอร์ได้แล้ว"/>
        </c:if>

        <!-- กติกาใหม่: availability = 1 เมื่อสถานะเป็น "พรีออเดอร์ได้แล้ว" หรือ "พร้อมสั่งซื้อแล้ว" -->
        <c:set var="derivedAvailability"
               value="${(statusCompact == 'พรีออเดอร์ได้แล้ว') or (statusCompact == 'พร้อมสั่งซื้อแล้ว')}" />

        <form id="productForm" action="${formAction}" method="post" enctype="multipart/form-data" class="space-y-8">
          <input type="hidden" name="productId" value="${p.productId}" />
          <input type="hidden" name="img" value="${p.img}" />
          <input type="hidden" name="availability" id="availabilityHidden" value="${derivedAvailability}" />

          <!-- แถบอธิบายกติกา -->
          <div class="alert alert-info items-center">
            <i class="fa-solid fa-circle-info mt-0.5"></i>
            <div class="flex-1">
              <b>กติกา:</b> “พรีออเดอร์ได้แล้ว/พร้อมสั่งซื้อแล้ว” = เปิดขาย (availability=1) <b>แต่ถ้า Stock=0 จะแสดงเป็น “ปิดการขายอยู่”</b>
            </div>
            <span id="saleModePreview" class="inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full border bg-gray-50 text-gray-700 border-gray-200">โหมดการขาย: -</span>
          </div>

          <!-- อัปโหลดรูป -->
          <div class="card p-6">
            <div class="flex items-start justify-between">
              <div>
                <div class="text-lg font-semibold text-gray-800">รูปสินค้า</div>
                <div class="hint mt-1">เลือกได้หลายไฟล์ สูงสุด 10 (.JPG .PNG .WEBP ≤ 5MB/ไฟล์)</div>
              </div>
              <span class="text-sm border rounded-full px-3 py-1 bg-white">
                เลือกแล้ว: <span id="countNow">0</span> / 10
              </span>
            </div>

            <div class="mt-4">
              <label for="imageFiles" class="inline-flex items-center gap-2 px-3 py-2 rounded border cursor-pointer bg-white hover:bg-gray-50">
                <i class="fa-solid fa-upload"></i> เลือกรูปหลายรูป
              </label>
              <input id="imageFiles" name="imageFiles" type="file" accept="image/png,image/jpeg,image/webp" class="hidden" multiple>

              <div id="imgDrop" class="dropzone mt-3 p-5 text-center text-sm text-gray-600">
                หรือลากรูปมาวางที่นี่
              </div>
              <div id="limitMsg" class="text-xs text-red-600 mt-2 hidden">ถึงจำนวนสูงสุด 10 รูปแล้ว</div>
            </div>

            <!-- รูปเดิม (ติ๊กเพื่อลบ) -->
            <c:if test="${not empty p.productId}">
              <c:catch var="imgErr">
                <c:if test="${not empty images}">
                  <div class="mt-6">
                    <div class="text-sm font-medium text-gray-700 mb-2">รูปเดิม (ติ๊กเพื่อลบ)</div>
                    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                      <c:forEach var="im" items="${images}">
                        <div class="thumb h-24">
                          <c:set var="imgUrl" value="" />
                          <c:choose>
                            <c:when test="${not empty im.imageUrl and fn:startsWith(im.imageUrl,'http')}">
                              <c:set var="imgUrl" value="${im.imageUrl}" />
                            </c:when>
                            <c:when test="${not empty im.imageUrl and fn:startsWith(im.imageUrl,'/uploads/')}">
                              <c:set var="imgUrl" value="${ctx}${im.imageUrl}" />
                            </c:when>
                            <c:otherwise>
                              <c:set var="imgUrl" value="${ctx}/uploads/${im.imageUrl}" />
                            </c:otherwise>
                          </c:choose>
                          <img src="${imgUrl}" alt="">
                          <label class="thumb-btn cursor-pointer">
                            <input type="checkbox" name="deleteImageIds" value="${im.imageId}" class="mr-1"> ลบ
                          </label>
                        </div>
                      </c:forEach>
                    </div>
                  </div>
                </c:if>
              </c:catch>
              <c:if test="${not empty imgErr}">
                <div class="mt-3 alert alert-error">
                  <i class="fa-regular fa-circle-xmark mt-0.5"></i>
                  <div>โหลดรูปเดิมผิดพลาด: <c:out value='${imgErr}'/></div>
                </div>
              </c:if>
            </c:if>
          </div>

          <!-- ข้อมูลสินค้า -->
          <div class="card p-6">
            <div class="grid md:grid-cols-2 gap-5">
              <!-- ชื่อสินค้า -->
              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-1">ชื่อสินค้า</label>
                <div class="igroup">
                  <i class="fa-solid fa-seedling i"></i>
                  <input type="text" name="productname" value="${p.productname}" placeholder="เช่น ผักสลัดปลอดสาร"
                         class="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-3 ${not empty fe && not empty fe.productname ? 'border-red-500 ring-1 ring-red-300 focus:ring-red-400' : ''}"
                         maxlength="100" required/>
                </div>
                <c:if test="${not empty fe and not empty fe.productname}">
                  <div class="text-red-600 text-xs mt-1"><c:out value="${fe.productname}"/></div>
                </c:if>
              </div>

              <!-- หมวดหมู่ -->
              <c:catch var="catErr">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">หมวดหมู่</label>
                  <div class="igroup">
                    <i class="fa-solid fa-list i"></i>
                    <select name="categoryId"
                            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-3 ${not empty fe && not empty fe.categoryId ? 'border-red-500 ring-1 ring-red-300 focus:ring-red-400' : ''}"
                            required>
                      <option value="">-- เลือกหมวดหมู่ --</option>
                      <c:forEach var="cat" items="${categories}">
                        <option value="${cat.categoryId}" <c:if test="${p.categoryId == cat.categoryId}">selected</c:if>>
                          ${cat.name}
                        </option>
                      </c:forEach>
                    </select>
                  </div>
                  <c:if test="${not empty fe and not empty fe.categoryId}">
                    <div class="text-red-600 text-xs mt-1"><c:out value="${fe.categoryId}"/></div>
                  </c:if>
                </div>
              </c:catch>
              <c:if test="${not empty catErr}">
                <div class="md:col-span-2 alert alert-error">
                  <i class="fa-regular fa-circle-xmark mt-0.5"></i>
                  <div>โหลดหมวดหมู่ผิดพลาด: <c:out value='${catErr}'/></div>
                </div>
              </c:if>

              <!-- ราคา -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">ราคา (฿)</label>
                <div class="igroup">
                  <i class="fa-solid fa-tag i"></i>
                  <input id="price" type="number" name="price" step="0.01" min="0" max="9999999"
                         value="<c:out value='${p.price}'/>"
                         class="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-3 ${not empty fe && not empty fe.price ? 'border-red-500 ring-1 ring-red-300 focus:ring-red-400' : ''}"
                         required/>
                </div>
                <c:if test="${not empty fe and not empty fe.price}">
                  <div class="text-red-600 text-xs mt-1"><c:out value="${fe.price}"/></div>
                </c:if>
              </div>

              <!-- สต๊อก -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">จำนวนในสต๊อก (กิโลกรัม)</label>
                <div class="igroup">
                  <i class="fa-solid fa-boxes-stacked i"></i>
                  <input id="stockQty" type="number" min="0" max="999999" name="stock"
                         value="<c:out value='${p.stock}'/>"
                         class="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-3 ${not empty fe && not empty fe.stock ? 'border-red-500 ring-1 ring-red-300 focus:ring-red-400' : ''}"
                         step="1"/>
                </div>
                <c:if test="${not empty fe and not empty fe.stock}">
                  <div class="text-red-600 text-xs mt-1"><c:out value="${fe.stock}"/></div>
                </c:if>
              </div>

              <!-- สถานะ -->
              <c:set var="statusErr" value="${not empty fe and not empty fe.status}" />
              <div class="md:col-span-2">
                <label for="status" class="block text-sm font-medium text-gray-700 mb-1">สถานะพรีออเดอร์</label>
                <div class="igroup">
                  <i class="fa-solid fa-bullhorn i"></i>
                  <select id="status" name="status"
                          class="mt-1 block w-full border-gray-300 rounded-xl shadow-sm p-3 pr-10
                                 ${statusErr ? 'border-red-500 ring-1 ring-red-300 focus:ring-red-400 focus:border-red-400' : 'focus:ring-2 focus:ring-emerald-400 focus:border-emerald-400'}">
                    <option value="">— เลือกสถานะ —</option>
                    <option value="พรีออเดอร์ได้แล้ว"  <c:if test="${statusCompact == 'พรีออเดอร์ได้แล้ว'}">selected</c:if>>พรีออเดอร์ได้แล้ว</option>
                    <option value="กำลังผลิต"           <c:if test="${statusCompact == 'กำลังผลิต'}">selected</c:if>>กำลังผลิต</option>
                    <option value="พร้อมสั่งซื้อแล้ว"    <c:if test="${statusCompact == 'พร้อมสั่งซื้อแล้ว'}">selected</c:if>>พร้อมสั่งซื้อแล้ว</option>
                    <option value="ปิดรับจอง"           <c:if test="${statusCompact == 'ปิดรับจอง'}">selected</c:if>>ปิดรับจอง</option>
                  </select>
                </div>

                <details class="mt-3 group">
                  <summary class="flex items-center gap-2 cursor-pointer text-sm text-gray-700 select-none">
                    <i class="fa-regular fa-circle-question text-emerald-600"></i>
                    <span class="font-medium">อธิบายสถานะ (คลิกเพื่อดู/ซ่อน)</span>
                    <i class="fa-solid fa-chevron-down ml-1 text-gray-400 transition-transform group-open:rotate-180"></i>
                  </summary>
                  <div class="mt-2 grid sm:grid-cols-2 gap-2 text-sm">
                    <div class="p-3 rounded-lg border bg-emerald-50/60 border-emerald-100">
                      <div class="font-semibold text-emerald-800 flex items-center gap-2">🌱 พรีออเดอร์ได้แล้ว</div>
                      <div class="text-emerald-900/90 mt-1">เปิดรับจองล่วงหน้า—ยังไม่ส่งทันที</div>
                    </div>
                    <div class="p-3 rounded-lg border bg-amber-50/60 border-amber-100">
                      <div class="font-semibold text-amber-800 flex items-center gap-2">🛠️ กำลังผลิต</div>
                      <div class="text-amber-900/90 mt-1">กำลังปลูก/เลี้ยง/เก็บเกี่ยว</div>
                    </div>
                    <div class="p-3 rounded-lg border bg-blue-50/60 border-blue-100">
                      <div class="font-semibold text-blue-800 flex items-center gap-2">🛒 พร้อมสั่งซื้อแล้ว</div>
                      <div class="text-blue-900/90 mt-1">ของพร้อมขายและส่งได้ตามปกติ</div>
                    </div>
                    <div class="p-3 rounded-lg border bg-red-50/60 border-red-100">
                      <div class="font-semibold text-red-800 flex items-center gap-2">⛔ ปิดรับจอง</div>
                      <div class="text-red-900/90 mt-1">ของหมดชั่วคราว/หยุดรับคำสั่งซื้อ</div>
                    </div>
                  </div>
                </details>

                <c:if test="${statusErr}">
                  <div class="mt-2 alert alert-error">
                    <i class="fa-solid fa-circle-exclamation mt-0.5"></i>
                    <span><c:out value="${fe.status}"/></span>
                  </div>
                </c:if>
              </div>

              <!-- รายละเอียด -->
              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-1">รายละเอียดสินค้า</label>
                <div class="igroup">
                  <i class="fa-regular fa-note-sticky i"></i>
                  <textarea name="description" rows="5"
                            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-3 ${not empty fe && not empty fe.description ? 'border-red-500 ring-1 ring-red-300 focus:ring-red-400' : ''}"
                            maxlength="1000"
                            placeholder="คำอธิบาย จุดเด่น วิธีการปลูก/เลี้ยง ฯลฯ"><c:out value='${p.description}'/></textarea>
                </div>
                <c:if test="${not empty fe and not empty fe.description}">
                  <div class="text-red-600 text-xs mt-1"><c:out value="${fe.description}"/></div>
                </c:if>
              </div>
            </div>

            <div class="flex items-center justify-between pt-2">
              <a href="${ctx}/product/list/Farmer" class="btn bg-gray-200 hover:bg-gray-300 text-gray-800">
                <i class="fa-solid fa-arrow-left"></i> ยกเลิก
              </a>
              <button type="submit" class="btn btn-save">
                <i class="fa-solid fa-floppy-disk"></i>
                <c:choose><c:when test="${empty p.productId}">บันทึก</c:when><c:otherwise>อัปเดต</c:otherwise></c:choose>
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>

    <!-- พรีวิว (ขวา) -->
    <div class="card p-6">
      <div class="flex items-center justify-between mb-2">
        <div class="text-gray-700 font-semibold">พรีวิวรูป (รวมรูปเดิม+ใหม่)</div>
        <div class="text-xs text-gray-500">คลิกรูปใหม่เพื่อลบ | ลาก-วางเพิ่มได้</div>
      </div>

      <div id="carousel" class="relative aspect-[4/3] bg-white border rounded-xl flex items-center justify-center overflow-hidden">
        <img id="bigPreview" src="https://via.placeholder.com/640x480?text=กำลังโหลดรูป..." class="max-w-full max-h-full object-contain" alt="">
        <button id="prevBtn" type="button" class="absolute left-2 top-1/2 -translate-y-1/2 bg-white/85 hover:bg-white shadow rounded-full w-9 h-9 flex items-center justify-center">
          <i class="fa-solid fa-chevron-left"></i>
        </button>
        <button id="nextBtn" type="button" class="absolute right-2 top-1/2 -translate-y-1/2 bg-white/85 hover:bg-white shadow rounded-full w-9 h-9 flex items-center justify-center">
          <i class="fa-solid fa-chevron-right"></i>
        </button>
      </div>

      <div id="thumbs" class="grid grid-cols-5 gap-2 mt-3"></div>

      <div class="mt-4 text-sm text-gray-600">
        <i class="fa-regular fa-lightbulb mr-1"></i> รูปแรกจะถูกใช้เป็นรูปหน้าปกของสินค้าอัตโนมัติ
      </div>
    </div>
  </main>
  <!-- ================= /Main ================= -->

  <!-- ================= Footer ================= -->
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
        <a class="btn bg-emerald-600 hover:bg-emerald-700 text-white shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <!-- ===== Success Modal (โชว์เมื่ออัปเดตสำเร็จ) ===== -->
  <div id="updateModal" class="fixed inset-0 z-[60] hidden items-center justify-center" role="dialog" aria-modal="true" aria-labelledby="updateTitle">
    <div class="absolute inset-0 backdrop-blur-[2px] bg-black/45 animate-overlay"></div>

    <div class="relative bg-white rounded-2xl shadow-2xl p-6 w-[min(92vw,520px)] animate-pop">
      <div id="confetti" class="confetti"></div>

      <div class="flex items-start gap-4 animate-float">
        <div class="w-14 h-14 rounded-full bg-emerald-100 flex items-center justify-center shrink-0">
          <i class="fa-solid fa-check text-emerald-600 text-2xl" aria-hidden="true"></i>
        </div>
        <div class="flex-1">
          <div id="updateTitle" class="text-xl font-bold">อัปเดตสินค้าสำเร็จ 🎉</div>
          <div class="text-sm text-gray-600 mt-1">
            จะพากลับไปที่รายการสินค้าของฉันภายใน <span id="countdown">3</span> วินาที
          </div>
        </div>
      </div>

      <div class="mt-5 h-2 bg-gray-100 rounded-full overflow-hidden" aria-hidden="true">
        <div class="h-full bg-emerald-500 animate-bar"></div>
      </div>

      <div class="mt-5 flex items-center justify-end gap-2">
        <button type="button" class="btn btn-ghost rounded-lg"
                onclick="document.getElementById('updateModal').classList.add('hidden')">
          อยู่หน้านี้ต่อ
        </button>
        <a id="goNowBtn" href="${ctx}/preorder/product/list/Farmer"
           class="btn bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg shadow">
          กลับตอนนี้
        </a>
      </div>
    </div>
  </div>

  <!-- ========== JSON (รูปเดิมจากฝั่งเซิร์ฟเวอร์) นอก <script> หลัก เพื่อกัน LSP แจ้งเตือน ========== -->
  <script id="existingUrlsData" type="application/json">
[
  <c:choose>
    <c:when test="${not empty images}">
      <c:forEach var="im" items="${images}" varStatus="s">
        <c:set var="imgUrl" value="" />
        <c:choose>
          <c:when test="${not empty im.imageUrl and fn:startsWith(im.imageUrl,'http')}">
            <c:set var="imgUrl" value="${im.imageUrl}" />
          </c:when>
          <c:when test="${not empty im.imageUrl and fn:startsWith(im.imageUrl,'/uploads/')}">
            <c:set var="imgUrl" value="${ctx}${im.imageUrl}" />
          </c:when>
          <c:otherwise>
            <c:set var="imgUrl" value="${ctx}/uploads/${im.imageUrl}" />
          </c:otherwise>
        </c:choose>
        "<c:out value='${imgUrl}'/>"<c:if test="${!s.last}">,</c:if>
      </c:forEach>
    </c:when>
    <c:when test="${empty images and not empty p.img}">
      <c:set var="coverUrl" value="" />
      <c:choose>
        <c:when test="${fn:startsWith(p.img,'http')}"><c:set var="coverUrl" value="${p.img}" /></c:when>
        <c:when test="${fn:startsWith(p.img,'/uploads/')}"><c:set var="coverUrl" value="${ctx}${p.img}" /></c:when>
        <c:otherwise><c:set var="coverUrl" value="${ctx}/uploads/${p.img}" /></c:otherwise>
      </c:choose>
      "<c:out value='${coverUrl}'/>"
    </c:when>
  </c:choose>
]
  </script>

  <!-- ================= Scripts ================= -->
  <script>
    /* ===== โปรไฟล์ดรอปดาวน์ ===== */
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
    document.addEventListener('keydown',(e)=>{ if(e.key==='Escape'){ const m=document.getElementById('profileMenu'); const b=document.getElementById('profileBtn'); if(m) m.classList.add('hidden'); if(b) b.setAttribute('aria-expanded','false'); }});

    /* ===== Flash helpers ===== */
    function dismiss(id){ const el=document.getElementById(id); if(el){ el.style.display='none'; } }
    function toggleErrorDetails(){
      const box=document.getElementById('errorDetails');
      if(box){ box.style.display= (box.style.display==='none'||!box.style.display)?'block':'none'; }
    }
    function copyErrors(){
      const box=document.getElementById('errorDetails'); if(!box) return;
      const items=[...box.querySelectorAll('li')].map(li=>li.textContent.trim()).filter(Boolean);
      const text = items.join('\n'); if(!text) return;
      navigator.clipboard.writeText(text).then(()=>{
        const btn = box.querySelector('button'); if(btn){ btn.textContent='คัดลอกแล้ว!'; setTimeout(()=>btn.textContent='คัดลอกทั้งหมด',1200); }
      }).catch(()=>{ alert('คัดลอกไม่สำเร็จ'); });
    }
    setTimeout(()=>{ const ok=document.getElementById('flashOk'); if(ok){ ok.style.display='none'; } }, 4000);

    /* ===== Preview รูป (รวมรูปเดิม + รูปใหม่) ===== */
    const input   = document.getElementById('imageFiles');
    const drop    = document.getElementById('imgDrop');
    const thumbs  = document.getElementById('thumbs');
    const big     = document.getElementById('bigPreview');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    const countNow= document.getElementById('countNow');
    const limitMsg= document.getElementById('limitMsg');

    const MAX = 5*1024*1024, ALLOWED = ['image/png','image/jpeg','image/webp'], LIMIT=10;
    let newFiles = [];
    let existingUrls = [];
    let cur = 0;

    // ดึง URL รูปเดิมจากบล็อก JSON (ไม่มี JSTL ใน JS)
    (function injectExisting(){
      try{
        const node = document.getElementById('existingUrlsData');
        const raw = (node && node.textContent || '[]').trim();
        const arr = JSON.parse(raw || '[]');
        if(Array.isArray(arr) && arr.length){ existingUrls.push(...arr); }
      }catch(e){ /* ignore */ }
    })();

    function toastLimit(){ if(limitMsg){ limitMsg.classList.remove('hidden'); setTimeout(()=>limitMsg.classList.add('hidden'), 1600); } }
    function validate(f){
      if(!ALLOWED.includes(f.type)) return 'ต้องเป็น JPG/PNG/WEBP';
      if(f.size > MAX) return 'ไฟล์ใหญ่เกินไป (≤5MB)';
      return '';
    }
    function rebuildInputFromFiles(){
      if(!input) return;
      const dt = new DataTransfer();
      newFiles.forEach(f=>dt.items.add(f));
      input.files = dt.files;
      if(countNow) countNow.textContent = String(newFiles.length);
    }
    function listDisplayItems(){
      const olds = existingUrls.map(u => ({type:'old', url: u}));
      const news = newFiles.map((f,idx) => ({type:'new', file: f, idx}));
      return olds.concat(news);
    }
    function render(){
      const items = listDisplayItems();
      if(items.length === 0){
        if(big) big.src = 'https://via.placeholder.com/640x480?text=เลือกรูป';
        cur = 0;
      } else {
        if(cur >= items.length) cur = items.length-1;
        const it = items[cur];
        if(it.type === 'old'){
          if(big) big.src = it.url;
        } else {
          const url = URL.createObjectURL(it.file);
          if(big) big.src = url;
          setTimeout(()=>URL.revokeObjectURL(url), 1500);
        }
      }

      if(!thumbs) return;
      thumbs.innerHTML = '';
      listDisplayItems().forEach((it,idx)=>{
        const wrap = document.createElement('div');
        wrap.className = 'thumb h-20 cursor-pointer';
        const img = document.createElement('img');

        if(it.type === 'old'){
          img.src = it.url;
        } else {
          const u = URL.createObjectURL(it.file);
          img.src = u;
          img.onload = ()=>URL.revokeObjectURL(u);
          const del = document.createElement('button');
          del.className = 'thumb-btn'; del.textContent = 'ลบ';
          del.addEventListener('click', (e)=>{ e.preventDefault(); e.stopPropagation(); removeNewAt(it.idx); });
          wrap.appendChild(del);
        }

        wrap.appendChild(img);
        wrap.addEventListener('click', ()=>{ cur = idx; render(); });
        thumbs.appendChild(wrap);
      });
    }
    function pushFiles(list){
      for(const f of list){
        if(newFiles.length >= LIMIT){ toastLimit(); break; }
        const err = validate(f);
        if(err){ alert(err + ': ' + (f.name||'')); continue; }
        newFiles.push(f);
      }
      rebuildInputFromFiles();
      render();
    }
    function removeNewAt(i){
      newFiles.splice(i,1);
      rebuildInputFromFiles();
      render();
    }
    input && input.addEventListener('change', ()=>{
      const picked = Array.from(input.files||[]);
      input.value = '';
      pushFiles(picked);
    });
    if(drop){
      ['dragenter','dragover'].forEach(t=>drop.addEventListener(t,e=>{e.preventDefault(); e.stopPropagation(); drop.classList.add('active');}));
      ['dragleave','drop'].forEach(t=>drop.addEventListener(t,e=>{e.preventDefault(); e.stopPropagation(); drop.classList.remove('active');}));
      drop.addEventListener('drop', e=>{
        const dt=e.dataTransfer; if(!dt||!dt.files||!dt.files.length) return;
        pushFiles(dt.files);
      });
    }
    prevBtn && prevBtn.addEventListener('click', ()=>{ const items = listDisplayItems(); if(items.length){ cur = (cur-1+items.length)%items.length; render(); }});
    nextBtn && nextBtn.addEventListener('click', ()=>{ const items = listDisplayItems(); if(items.length){ cur = (cur+1)%items.length; render(); }});

    /* ===== โหมดการขาย + hidden availability ===== */
    const statusSel = document.getElementById('status');
    const stockInput = document.getElementById('stockQty');
    const saleModePreview = document.getElementById('saleModePreview');
    const availabilityHidden = document.getElementById('availabilityHidden');

    function computeAvailability(st){ return (st === 'พรีออเดอร์ได้แล้ว') || (st === 'พร้อมสั่งซื้อแล้ว'); }
    function paintSaleMode(){
      const st = statusSel ? statusSel.value : '';
      const stock = stockInput && stockInput.value ? parseInt(stockInput.value,10) : 0;

      let text='โหมดการขาย: -';
      let cls='inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full border bg-gray-50 text-gray-700 border-gray-200';

      if ((st === 'พรีออเดอร์ได้แล้ว' || st === 'พร้อมสั่งซื้อแล้ว') && stock <= 0){
        text='โหมดการขาย: ปิดการขายอยู่ (สต๊อกหมด) 🔴';
        cls='inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full border bg-red-50 text-red-700 border-red-200';
      } else if (st === 'พรีออเดอร์ได้แล้ว'){
        text='โหมดการขาย: เปิดรับจอง 🟡';
        cls='inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full border bg-amber-50 text-amber-700 border-amber-200';
      } else if (st === 'พร้อมสั่งซื้อแล้ว'){
        text='โหมดการขาย: เปิดขาย 🟢';
        cls='inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full border bg-emerald-50 text-emerald-700 border-emerald-200';
      } else if (st === 'กำลังผลิต'){
        text='โหมดการขาย: ยังไม่เปิด (กำลังผลิต) 🔴';
        cls='inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full border bg-red-50 text-red-700 border-red-200';
      } else {
        text='โหมดการขาย: ปิดรับจอง 🔴';
        cls='inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full border bg-red-50 text-red-700 border-red-200';
      }

      if(saleModePreview){ saleModePreview.className = cls; saleModePreview.textContent = text; }
      if(availabilityHidden){ availabilityHidden.value = computeAvailability(st); }
    }
    statusSel && statusSel.addEventListener('change', paintSaleMode);
    stockInput && stockInput.addEventListener('input', paintSaleMode);
    paintSaleMode();

    // Validate ก่อน submit
    document.getElementById('productForm').addEventListener('submit', (e)=>{
      rebuildInputFromFiles();
      const price = document.getElementById('price');
      const stock = document.getElementById('stockQty');
      if(price && (+price.value < 0 || +price.value > 9999999)){ e.preventDefault(); alert('ราคาต้องอยู่ในช่วง 0 - 9,999,999'); return; }
      if(stock && (+stock.value < 0 || +stock.value > 999999)){ e.preventDefault(); alert('สต๊อกต้องอยู่ในช่วง 0 - 999,999'); return; }
      paintSaleMode();
    });

    /* ===== Success Modal on update ===== */
    const isEditMode     = (document.body.dataset.isEdit === 'true');
    const updatedParam   = (document.body.dataset.updatedParam === '1' || document.body.dataset.updatedParam === 'true');
    const justUpdatedAttr= (document.body.dataset.justUpdated === 'true');
    const ABS_REDIRECT_URL = `${location.origin}${'${ctx}'}/preorder/product/list/Farmer`.replace('${ctx}', '<c:out value="${ctx}"/>');

    function spawnConfetti(n=80){
      const box = document.getElementById('confetti'); if(!box) return;
      box.innerHTML = '';
      const colors = ['#34d399','#10b981','#059669','#fde047','#60a5fa','#f472b6','#f87171'];
      for(let i=0;i<n;i++){
        const el = document.createElement('i');
        el.style.left = (Math.random()*100)+'%';
        el.style.animationDuration = (1.2 + Math.random()*1.3)+'s';
        el.style.animationDelay = (Math.random()*.15)+'s';
        el.style.background = colors[Math.floor(Math.random()*colors.length)];
        el.style.transform = `translateY(-20vh) rotate(${Math.random()*360}deg)`;
        box.appendChild(el);
      }
      setTimeout(()=>{ box.innerHTML=''; }, 1800);
    }
    function openSuccessModal(){
      const modal = document.getElementById('updateModal');
      const cd = document.getElementById('countdown');
      const goBtn = document.getElementById('goNowBtn');
      if(!modal) return;
      modal.classList.remove('hidden'); modal.classList.add('flex');
      if(goBtn) goBtn.setAttribute('href', ABS_REDIRECT_URL);
      spawnConfetti();

      let left = 3;
      const tick = setInterval(()=>{ left = Math.max(0,left-1); if(cd) cd.textContent = String(left); if(left===0){ clearInterval(tick);} }, 1000);
      setTimeout(()=>{ window.location.href = ABS_REDIRECT_URL; }, 2500);
    }
    if (isEditMode && (updatedParam || justUpdatedAttr)) { openSuccessModal(); }

    // เริ่มต้น
    render();
  </script>
</body>
</html>
