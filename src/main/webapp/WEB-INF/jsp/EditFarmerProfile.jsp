<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<jsp:useBean id="now" class="java.util.Date" />

<%
  response.setHeader("Cache-Control","no-store, no-cache, must-revalidate, max-age=0");
  response.setHeader("Pragma","no-cache");
%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="f"   value="${farmer}" />
<c:set var="gal" value="${not empty farmerImages ? farmerImages : images}" />
<c:set var="galCount" value="${empty gal ? 0 : fn:length(gal)}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>แก้ไขโปรไฟล์เกษตรกร</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --emerald:#10b981; --emerald-600:#059669; --ink:#0f172a; --muted:#6b7280; --card:#fff; --border:#e5e7eb; }
    body{ font-family:'Prompt',sans-serif; color:var(--ink); background:linear-gradient(180deg,#f6faf8 0,#f2fdf7 100%); }

    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }

    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem; }
    .nav-scroll{ overflow-x:auto; }
    .icon-btn .badge{ margin-left:.5rem; font-size:.75rem; background:#fff; color:#000; border-radius:999px; padding:.05rem .4rem; }

    .card{ background:var(--card); border:1px solid var(--border); border-radius:16px; box-shadow:0 10px 26px rgba(2,8,23,.05) }
    .section-title{display:flex;align-items:center;gap:.6rem;font-weight:700}
    .section-title i{color:var(--emerald)}
    .sub{color:#64748b;font-size:.92rem}

    .btn{display:inline-flex;align-items:center;gap:.55rem;padding:.68rem 1rem;border-radius:.7rem;border:1px solid var(--border);background:#fff;transition:transform .12s, box-shadow .2s, border-color .2s}
    .btn:hover{transform:translateY(-1px); box-shadow:0 10px 20px rgba(16,185,129,.12); border-color:#d1fae5}
    .btn-emerald{color:#fff;background:linear-gradient(135deg,var(--emerald),var(--emerald-600)); border-color:transparent}
    .btn-emerald:hover{filter:brightness(1.05)}
    .btn-ghost{display:inline-flex;align-items:center;gap:.5rem;border:1px solid #e5e7eb;border-radius:.7rem;padding:.55rem .95rem;background:#fff}

    .igroup{position:relative} .igroup .i{position:absolute;left:.75rem;top:50%;transform:translateY(-50%);color:#9ca3af}
    .igroup input,.igroup textarea,.igroup select{padding-left:2.25rem}

    .dropzone{border:2px dashed #e5e7eb;border-radius:14px;transition:.2s}
    .dropzone.active{border-color:#10b981;background:#ecfdf5}

    .g-thumb{position:relative;border-radius:14px;overflow:hidden;border:1px solid #e5e7eb}
    .g-thumb img{width:100%;height:100%;object-fit:cover;display:block}
    .g-thumb .del{position:absolute;top:6px;right:6px;background:rgba(0,0,0,.65);color:#fff;font-size:.8rem;padding:.28rem .5rem;border-radius:.5rem}
    .g-thumb .cover{position:absolute;left:6px;top:6px;background:rgba(16,185,129,.9);color:#fff;font-size:.75rem;padding:.2rem .45rem;border-radius:.5rem}
    .g-thumb.dragging{opacity:.6;transform:scale(.98)}
    .g-thumb.selected{outline:3px solid #10b981;outline-offset:2px}

    .toast{position:fixed;right:12px;bottom:12px;background:#0f172a;color:#fff;border-radius:12px;padding:.6rem .9rem;opacity:0;transform:translateY(8px);transition:.25s;z-index:70}
    .toast.show{opacity:1;transform:none}

    .err{ border-color:#ef4444 !important; background:#fff1f2 }
    .err-text{ font-size:.85rem; color:#b91c1c; margin-top:.35rem }

    .hr{height:1px;background:linear-gradient(90deg,transparent,#e5e7eb,transparent)}
    .hint{font-size:.8rem;color:#64748b}
  </style>
</head>

<body>
<!-- ================= Header ================= -->
<header class="header shadow-md text-white">
  <div class="container mx-auto px-6 py-3 topbar">

    <c:if test="${empty isLoggedIn}">
      <c:set var="isLoggedIn" value="${not empty sessionScope.loggedInUser}" />
    </c:if>

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
              <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10 icon-btn"><i class="fa-solid fa-basket-shopping"></i> ตะกร้า <span class="badge">${cartCount}</span></a>
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
        <c:when test="${isLoggedIn}">
          <c:set var="rawAvatar" value="${not empty sessionScope.loggedInUser.imageUrl ? sessionScope.loggedInUser.imageUrl : f.imageF}" />
          <c:set var="avatarUrl" value="${empty rawAvatar ? '' : rawAvatar}" />
          <c:if test="${not empty avatarUrl && !fn:startsWith(avatarUrl,'http')}">
            <c:if test="${!fn:startsWith(avatarUrl,'/')}">
              <c:set var="avatarUrl" value="/${avatarUrl}"/>
            </c:if>
            <c:url value="${avatarUrl}" var="avatarUrl"/>
          </c:if>

          <c:set var="displayName" value="${not empty f.farmName ? f.farmName : sessionScope.loggedInUser.fullname}" />

          <div class="relative">
            <button id="profileBtn" onclick="document.getElementById('profileMenu').classList.toggle('hidden')" class="inline-flex items-center ml-2 px-3 py-1 bg-white/20 hover:bg-white/35 backdrop-blur rounded-full text-sm font-medium transition focus:outline-none focus:ring-2 focus:ring-green-300 group" type="button">
              <img src="${empty avatarUrl ? 'https://thumb.ac-illust.com/c9/c91fc010def4643287c0cc34cef449e0_t.jpeg' : avatarUrl}?t=${now.time}" alt="โปรไฟล์" class="h-8 w-8 rounded-full border-2 border-white shadow-md mr-2 object-cover"/>
              สวัสดี, ${displayName}
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

<!-- ====== Layout ====== -->
<main class="container mx-auto px-4 py-8 grid xl:grid-cols-3 gap-8">
  <!-- ===== Left: Form ===== -->
  <div class="xl:col-span-2">
    <div class="card p-6 md:p-8">
      <div class="section-title text-2xl md:text-3xl"><i class="fa-solid fa-wheat-awn"></i> แก้ไขโปรไฟล์เกษตรกร</div>
      <p class="sub mt-1">อัปเดตรูปฟาร์ม ข้อมูลติดต่อ พิกัด และสลิป/QR (เฉพาะฟิลด์ที่อนุญาตให้แก้)</p>

      <c:if test="${not empty error}">
        <div class="mt-4 bg-red-50 text-red-700 border border-red-200 px-4 py-2 rounded">${error}</div>
      </c:if>
      <c:if test="${not empty msg}">
        <div class="mt-4 bg-emerald-50 text-emerald-700 border border-emerald-200 px-4 py-2 rounded">✔ <c:out value="${msg}"/></div>
      </c:if>

      <form id="farmerForm" action="${ctx}/farmer/profile/edit" method="post" enctype="multipart/form-data" class="mt-6" novalidate>
        <c:if test="${not empty _csrf}">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
        </c:if>

        <!-- รูปโปรไฟล์ฟาร์ม -->
        <div class="section-title text-lg"><i class="fa-regular fa-image"></i> รูปโปรไฟล์ฟาร์ม</div>
        <p class="hint mb-3">เลือกรูปใหม่หรือวางไฟล์ได้ — ไม่เปิดให้แก้ path/URL โดยตรง</p>

        <div class="flex flex-col items-center">
          <div class="w-40 h-40 rounded-full overflow-hidden border">
            <c:set var="profileImgSrc" value="${f.imageF}" />
            <c:if test="${empty profileImgSrc}">
              <c:set var="profileImgSrc" value="https://images.unsplash.com/photo-1498654200943-1088dd4438ae?auto=format&fit=crop&w=320&q=60"/>
            </c:if>
            <c:if test="${not fn:startsWith(profileImgSrc,'http')}">
              <c:if test="${!fn:startsWith(profileImgSrc,'/')}">
                <c:set var="profileImgSrc" value="/${profileImgSrc}"/>
              </c:if>
              <c:url value="${profileImgSrc}" var="profileImgSrc"/>
            </c:if>
            <img id="farmImg" src="${profileImgSrc}" class="w-full h-full object-cover"
                 onerror="this.src='https://via.placeholder.com/320x320?text=No+Image';" alt="farm">
          </div>

          <div class="mt-3 text-sm text-gray-600">อัปโหลดรูปโปรไฟล์ร้าน</div>
          <div class="mt-2 flex items-center gap-3">
            <label for="farmImage" class="inline-flex items-center gap-2 px-3 py-1.5 rounded border cursor-pointer bg-gray-50 hover:bg-gray-100">
              <i class="fa-solid fa-upload"></i><span>เลือกไฟล์</span>
            </label>
            <span id="farmFileName" class="text-xs text-gray-500">ไม่มีไฟล์ที่เลือก</span>
          </div>
          <input id="farmImage" name="farmImage" type="file" accept="image/png,image/jpeg,image/webp" class="hidden">
          <div id="farmDrop" class="dropzone mt-3 p-3 text-center text-sm text-gray-600 w-full max-w-md">ลากไฟล์มาวางที่นี่ได้</div>
        </div>

        <div class="my-8 hr"></div>

        <!-- แกลเลอรีฟาร์ม -->
        <div class="section-title text-lg"><i class="fa-solid fa-images"></i> แกลเลอรีฟาร์ม</div>
        <p class="hint mb-3">สูงสุด 10 รูป | เลือกรูปใหม่ / ติ๊กเพื่อลบ / ลากสลับเรียงรูปเดิม</p>

        <section>
          <div class="bg-white border border-gray-200 rounded-2xl p-4 md:p-5 shadow-sm">
            <div class="flex items-start justify-between gap-3">
              <div class="text-sm border rounded-full px-3 py-1 bg-white">เลือกแล้ว: <span id="countNow"><c:out value="${galCount}"/></span> / 10</div>
            </div>

            <div class="mt-2">
              <label for="galleryFiles" class="inline-flex items-center gap-2 px-3 py-2 rounded border cursor-pointer bg-white hover:bg-gray-50">
                <i class="fa-solid fa-upload"></i> เลือกรูปใหม่ (หลายไฟล์)
              </label>
              <input id="galleryFiles" name="galleryFiles" type="file" accept="image/png,image/jpeg,image/webp" class="hidden" multiple>
              <div id="galleryDrop" class="dropzone mt-3 p-5 text-center text-sm text-gray-600">ลากรูปใหม่มาวางที่นี่ก็ได้</div>
            </div>

            <c:if test="${not empty gal}">
              <div class="mt-6">
                <div class="text-sm font-medium text-gray-700 mb-2">รูปเดิม (ติ๊กเพื่อลบ / ลากเพื่อเรียง / คลิก “หน้าปก”)</div>
                <div id="oldThumbs" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                  <c:forEach var="im" items="${gal}">
                    <%-- ปลอดภัยต่อทุกชนิด: FarmerImage / Map / String --%>
                    <c:set var="__id"  value=""/>
                    <c:set var="__url" value=""/>

                    <c:catch><c:set var="__id"  value="${im.id}"/></c:catch>
                    <c:if test="${empty __id}"><c:catch><c:set var="__id" value="${im.imageId}"/></c:catch></c:if>

                    <c:catch><c:set var="__url" value="${im.imageUrl}"/></c:catch>
                    <c:if test="${empty __url}"><c:catch><c:set var="__url" value="${im.url}"/></c:catch></c:if>
                    <c:if test="${empty __url}"><c:catch><c:set var="__url" value="${im.img}"/></c:catch></c:if>
                    <c:if test="${empty __url}">
                      <%-- ถ้าเป็น String ตรง ๆ --%>
                      <c:catch><c:set var="__url" value="${im}"/></c:catch>
                    </c:if>

                    <%-- ทำให้เป็น URL ที่ใช้ได้เสมอ --%>
                    <c:set var="__src" value="${__url}"/>
                    <c:if test="${not empty __src && !fn:startsWith(__src,'http')}">
                      <c:if test="${fn:startsWith(__src,'uploads/')}">
                        <c:set var="__src" value="/${__src}"/>
                      </c:if>
                      <c:if test="${!fn:startsWith(__src,'/')}">
                        <c:set var="__src" value="/${__src}"/>
                      </c:if>
                      <c:url value="${__src}" var="__src"/>
                    </c:if>

                    <div class="g-old g-thumb w-28 h-28 sm:w-36 sm:h-36 md:w-44 md:h-44" data-id="${__id}">
                      <img src="${empty __src ? 'https://via.placeholder.com/300x300?text=No+Image' : __src}"
                           onerror="this.src='https://via.placeholder.com/300x300?text=No+Image';" alt="">
                      <label class="del cursor-pointer"><input type="checkbox" name="deleteImageIds" value="${__id}" class="mr-1"> ลบ</label>
                      <button type="button" class="cover" onclick="makeCoverOld(this)">หน้าปก</button>
                    </div>
                  </c:forEach>
                </div>
                <input type="hidden" name="sortImageIds" id="sortImageIds" value="">
              </div>
            </c:if>
          </div>
        </section>

        <div class="my-8 hr"></div>

        <!-- ข้อมูลฟาร์ม -->
        <div class="section-title text-lg"><i class="fa-solid fa-pen-to-square"></i> ข้อมูลฟาร์ม</div>
        <p class="hint mb-3">กรอกเฉพาะช่องที่ต้องการแก้ไข</p>

        <div class="grid md:grid-cols-2 gap-5">
          <div class="md:col-span-2">
            <label class="block text-sm mb-1">Farmer ID</label>
            <div class="igroup">
              <i class="fa-regular fa-id-card i"></i>
              <input type="text" class="w-full rounded-lg border px-3 py-3 bg-gray-50" value="${f != null ? f.farmerId : ''}" readonly>
            </div>
          </div>

          <div class="md:col-span-2">
            <label class="block text-sm mb-1">ชื่อฟาร์ม</label>
            <div class="igroup">
              <i class="fa-solid fa-seedling i"></i>
              <input id="farmName" name="farmName" type="text" class="w-full rounded-lg border px-3 py-3" value="${f != null ? f.farmName : ''}" placeholder="เช่น ฟาร์มผักปลอดสาร">
            </div>
            <p class="err-text hidden" id="err_farmName"></p>
          </div>

          <div class="md:col-span-2">
            <label class="block text-sm mb-1">อีเมล</label>
            <div class="igroup">
              <i class="fa-solid fa-envelope i"></i>
              <input id="email" name="email" type="email" class="w-full rounded-lg border px-3 py-3 pr-9" value="${f != null ? f.email : ''}" placeholder="example@email.com">
              <i id="okEmail" class="fa-solid fa-check absolute right-3 top-1/2 -translate-y-1/2 text-emerald-600 hidden"></i>
            </div>
            <p class="err-text hidden" id="err_email"></p>
          </div>

          <div class="md:col-span-2">
            <label class="block text-sm mb-1">ที่อยู่</label>
            <div class="igroup">
              <i class="fa-solid fa-location-dot i"></i>
              <textarea id="address" name="address" class="w-full rounded-lg border px-3 py-3 min-h-[120px] resize-y" placeholder="บ้านเลขที่ ถนน ตำบล/แขวง อำเภอ/เขต จังหวัด รหัสไปรษณีย์">${f != null ? f.address : ''}</textarea>
            </div>
            <p class="err-text hidden" id="err_address"></p>
            <div class="flex gap-2 mt-2 flex-wrap">
              <button type="button" class="btn btn-ghost" onclick="open('https://www.google.com/maps/search/?api=1&query='+encodeURIComponent(document.getElementById('address').value||''),'_blank')"><i class="fa-solid fa-map-location-dot"></i> เปิด Google Maps</button>
              <button type="button" class="btn btn-ghost" onclick="navigator.clipboard?.readText().then(t=>{if(t)document.getElementById('address').value=t.trim();}).catch(()=>alert('ต้องใช้ผ่าน HTTPS หรือ localhost'))">วางที่อยู่</button>
            </div>
          </div>

          <div class="md:col-span-2">
            <label class="block text-sm mb-1">ตำแหน่งที่ตั้งฟาร์ม</label>
            <div class="flex gap-2 flex-wrap">
              <div class="igroup flex-1">
                <i class="fa-solid fa-map-pin i"></i>
                <input id="farmLocation" name="farmLocation" type="text" class="w-full rounded-lg border px-3 py-3" value="${f != null ? f.farmLocation : ''}" placeholder="13.7563,100.5018 หรือชื่อสถานที่">
              </div>
              <button type="button" class="btn btn-ghost" onclick="open('https://www.google.com/maps/search/?api=1&query='+encodeURIComponent(document.getElementById('farmLocation').value||''),'_blank')"><i class="fa-solid fa-map"></i> เปิด Google Maps</button>
              <button type="button" class="btn btn-ghost" onclick="navigator.clipboard?.readText().then(t=>{if(t)document.getElementById('farmLocation').value=t.trim();}).catch(()=>alert('ต้องใช้ผ่าน HTTPS หรือ localhost'))">วางพิกัด/ที่อยู่</button>
            </div>
            <p class="err-text hidden" id="err_farmLocation"></p>
          </div>

          <div>
            <label class="block text-sm mb-1">เบอร์โทรศัพท์</label>
            <div class="igroup">
              <i class="fa-solid fa-phone i"></i>
              <input id="phoneNumber" name="phoneNumber" type="text" class="w-full rounded-lg border px-3 py-3" value="${f != null ? f.phoneNumber : ''}" placeholder="เช่น 0812345678">
            </div>
            <p class="err-text hidden" id="err_phoneNumber"></p>
          </div>

          <div>
            <label class="block text-sm mb-1">รหัสผ่านใหม่ (ถ้าต้องการเปลี่ยน)</label>
            <div class="igroup">
              <i class="fa-solid fa-lock i"></i>
              <input id="pwd" name="password" type="password" class="w-full rounded-lg border px-3 py-3" value="" placeholder="เว้นว่างถ้าไม่เปลี่ยน (อย่างน้อย 8 ตัว)">
            </div>
            <p class="err-text hidden" id="err_password"></p>
            <div class="igroup mt-2">
              <i class="fa-solid fa-lock i"></i>
              <input id="confirmPassword" name="confirmPassword" type="password" class="w-full rounded-lg border px-3 py-3" placeholder="ยืนยันรหัสผ่านใหม่ให้ตรงกัน">
            </div>
            <p class="err-text hidden" id="err_confirm"></p>
          </div>
        </div>

        <div class="my-8 hr"></div>

        <!-- สลิป / QR -->
        <div class="section-title text-lg"><i class="fa-solid fa-qrcode"></i>QR Code / ช่องทางชำระเงินบัญชีของร้าน</div>
        <p class="hint mb-3">อัปโหลดไฟล์ QR Code เพื่อชำระเงินบัญชีของร้าน</p>

        <div class="bg-white border border-gray-200 rounded-2xl p-4 md:p-5 shadow-sm">
          <div class="flex items-center justify-between">
            <div class="text-sm text-gray-700">ตัวอย่าง QR Code ปัจจุบัน</div>
            <div class="flex items-center gap-2">
              <button type="button" id="openSlip" class="btn-ghost"><i class="fa-regular fa-image"></i> เปิดเต็มจอ</button>
              <label for="slipImage" class="btn-ghost cursor-pointer"><i class="fa-solid fa-upload"></i> เลือกสลิป/QR</label>
              <input id="slipImage" name="slipImage" type="file" accept="image/png,image/jpeg,image/webp" class="hidden">
            </div>
          </div>
          <div class="mt-4 grid md:grid-cols-3 gap-5">
            <div class="md:col-span-2 border rounded-xl p-3">
              <div class="min-h-[220px] flex items-center justify-center">
                <c:set var="slipSrc" value="${f.slipUrl}" />
                <c:if test="${not empty slipSrc && !fn:startsWith(slipSrc,'http')}">
                  <c:if test="${fn:startsWith(slipSrc,'uploads/')}">
                    <c:set var="slipSrc" value="/${slipSrc}"/>
                  </c:if>
                  <c:if test="${!fn:startsWith(slipSrc,'/')}">
                    <c:set var="slipSrc" value="/${slipSrc}"/>
                  </c:if>
                  <c:url value="${slipSrc}" var="slipSrc"/>
                </c:if>
                <img id="slipImg" src="${empty slipSrc ? 'https://via.placeholder.com/420x320?text=QR%2FSlip' : slipSrc}" class="max-w-[420px] max-h-[420px] rounded-lg shadow"
                     onerror="this.src='https://via.placeholder.com/420x320?text=QR%2FSlip';" alt="slip">
              </div>
            </div>
            <div>
              <div class="text-sm text-gray-600">รองรับไฟล์ .JPG .PNG .WEBP ขนาดไม่เกิน 5MB</div>
              <div class="text-xs text-gray-500 mt-2" id="slipFileName">ไม่มีไฟล์ที่เลือก</div>
            </div>
          </div>
        </div>

        <!-- ปุ่ม -->
        <div class="mt-8 flex justify-end gap-3">
          <a href="${ctx}/farmer/profile" class="px-4 py-3 rounded-lg border bg-white hover:bg-gray-50">ยกเลิก</a>
          <button id="btnSave" class="btn btn-emerald" type="submit"><i class="fa-solid fa-floppy-disk"></i> บันทึก</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ===== Right: Preview ===== -->
  <aside class="space-y-4">
    <div class="card p-6 sticky top-20">
      <div class="flex items-center justify-between mb-2">
        <div class="text-gray-700 font-semibold">พรีวิวรูปใหม่/เดิม</div>
        <div class="text-xs text-gray-500">คลิกรูปเพื่อลบ | ลาก-วางได้ (ฝั่งซ้าย)</div>
      </div>

      <div id="gCarousel" class="relative aspect-[10/10] bg-white border rounded-xl flex items-center justify-center overflow-hidden">
        <img id="gBig" src="https://via.placeholder.com/640x480?text=เลือกรูป" class="max-w-full max-h-full object-contain" alt="">
        <button id="gPrev" type="button" class="absolute left-2 top-1/2 -translate-y-1/2 bg-white/85 hover:bg-white shadow rounded-full w-9 h-9 flex items-center justify-center">
          <i class="fa-solid fa-chevron-left"></i>
        </button>
        <button id="gNext" type="button" class="absolute right-2 top-1/2 -translate-y-1/2 bg-white/85 hover:bg-white shadow rounded-full w-9 h-9 flex items-center justify-center">
          <i class="fa-solid fa-chevron-right"></i>
        </button>
      </div>

      <div id="gThumbs" class="grid grid-cols-3 sm:grid-cols-4 gap-3 mt-3"></div>

      <div class="mt-4 text-sm text-gray-600">
        <i class="fa-regular fa-lightbulb mr-1"></i> รูปแรกจะถูกใช้เป็นรูปหน้าปกอัตโนมัติ
      </div>
    </div>
  </aside>
</main>

<footer class="bg-black text-gray-200">
  <div class="container mx-auto px-6 py-8 grid md:grid-cols-3 gap-6 text-sm">
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
      <a class="btn btn-emerald shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
        <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
      </a>
    </div>
  </div>
</footer>

<a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50"
   href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
  <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
</a>

<div id="toast" class="toast">ถึงจำนวนสูงสุด 10 รูปแล้ว</div>

<script>
  // toggle profile menu outside click
  document.addEventListener('click',(e)=>{
    const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
    if(!b||!m) return; if(!b.contains(e.target) && !m.contains(e.target)) m.classList.add('hidden');
  });

  const form=document.getElementById('farmerForm');
  const emailInput=document.getElementById('email'), okEmail=document.getElementById('okEmail');
  const farmInput=document.getElementById('farmImage'), farmImg=document.getElementById('farmImg'), farmFN=document.getElementById('farmFileName'), farmDrop=document.getElementById('farmDrop');
  const slipInput=document.getElementById('slipImage'), slipImg=document.getElementById('slipImg'), slipFN=document.getElementById('slipFileName');
  const MAX=5*1024*1024, ALLOWED=['image/png','image/jpeg','image/webp'], LIMIT=10;

  const fileInput=document.getElementById('galleryFiles');
  const dropZone=document.getElementById('galleryDrop');
  const countChip=document.getElementById('countNow');
  const oldWrap=document.getElementById('oldThumbs');
  const sortHidden=document.getElementById('sortImageIds');

  const gBig=document.getElementById('gBig'), gPrev=document.getElementById('gPrev'), gNext=document.getElementById('gNext'), gThumbs=document.getElementById('gThumbs');
  const toast=document.getElementById('toast');

  const validEmail=s=>!!s && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(s);
  function toggleOk(){ if(okEmail) okEmail.classList.toggle('hidden', !validEmail(emailInput?.value||'')); }
  emailInput?.addEventListener('input', toggleOk); toggleOk();

  function chk(f){ if(!f) return {ok:true}; if(!ALLOWED.includes(f.type)) return {ok:false,err:'ต้องเป็น JPG/PNG/WEBP'}; if(f.size>MAX) return {ok:false,err:'ไฟล์ใหญ่เกินไป (≤5MB)'}; return {ok:true}; }
  function previewSingle(input,img,label){const f=input.files&&input.files[0]?input.files[0]:null; if(!f){if(label) label.textContent='ไม่มีไฟล์ที่เลือก'; return;} if(label) label.textContent=(f.name||''); const url=URL.createObjectURL(f); img.src=url; setTimeout(()=>URL.revokeObjectURL(url),1500);}

  farmInput?.addEventListener('change', ()=>{ const c=chk(farmInput.files[0]); if(!c.ok){ alert(c.err); farmInput.value=''; return;} previewSingle(farmInput,farmImg,farmFN); });
  ;['dragenter','dragover'].forEach(t=>farmDrop?.addEventListener(t,e=>{e.preventDefault(); e.stopPropagation(); farmDrop.classList.add('active');}));
  ;['dragleave','drop'].forEach(t=>farmDrop?.addEventListener(t,e=>{e.preventDefault(); e.stopPropagation(); farmDrop.classList.remove('active');}));
  farmDrop?.addEventListener('drop', e=>{ const dt=e.dataTransfer; if(!dt||!dt.files||!dt.files.length) return; const f=dt.files[0]; const v=chk(f); if(!v.ok){ alert(v.err); return;} const list=new DataTransfer(); list.items.add(f); farmInput.files=list.files; farmInput.dispatchEvent(new Event('change')); });

  function slipPreview(input){ const f=input.files&&input.files[0]?input.files[0]:null; if(!f){ slipFN.textContent='ไม่มีไฟล์ที่เลือก'; return;} const c=chk(f); if(!c.ok){ alert(c.err); input.value=''; return;} slipFN.textContent=f.name||'ไฟล์ที่เลือก'; const url=URL.createObjectURL(f); slipImg.src=url; setTimeout(()=>URL.revokeObjectURL(url),1500); }
  document.getElementById('slipImage')?.addEventListener('change', ()=>slipPreview(slipInput));
  document.getElementById('openSlip')?.addEventListener('click', ()=>{ if(slipImg?.src) window.open(slipImg.src,'_blank','noopener'); });

  let files=[], cur=0, slides=[];
  function showToast(){ toast.classList.add('show'); setTimeout(()=>toast.classList.remove('show'), 1600); }
  function validateFile(f){ if(!ALLOWED.includes(f.type)) return 'ต้องเป็น JPG/PNG/WEBP'; if(f.size>MAX) return 'ไฟล์ใหญ่เกินไป (≤5MB)'; return ''; }

  function oldKept(){
    const boxes=document.querySelectorAll('[name="deleteImageIds"]');
    if(!boxes.length) return (oldWrap?.children?.length||0);
    let k=0; boxes.forEach(b=>{ if(!b.checked) k++; }); return k;
  }
  function rebuildInput(){ const dt=new DataTransfer(); files.forEach(f=>dt.items.add(f)); fileInput.files=dt.files; }
  function refreshCounter(){
    const total=oldKept()+files.length; countChip.textContent=String(total);
    if(total>LIMIT){ showToast(); const canAdd=LIMIT-oldKept(); files=files.slice(0,Math.max(0,canAdd)); rebuildInput(); }
  }

  function buildSlides(){
    slides=[]; if(oldWrap){ Array.from(oldWrap.querySelectorAll('.g-old')).forEach(el=>{ const chk=el.querySelector('input[type=checkbox]'); if(!chk||!chk.checked){ const img=el.querySelector('img'); slides.push({kind:'old',src:img?.src||''}); }});}
    files.forEach(f=>slides.push({kind:'new',file:f}));
    if(cur>=slides.length) cur=Math.max(0,slides.length-1);
  }
  function renderUnified(){
    buildSlides();
    if(slides.length===0){ gBig.src='https://via.placeholder.com/640x480?text=เลือกรูป'; cur=0; }
    else{
      const s=slides[cur];
      if(s.kind==='new'){ const u=URL.createObjectURL(s.file); gBig.src=u; gBig.onload=()=>URL.revokeObjectURL(u); }
      else gBig.src=s.src;
    }
    gThumbs.innerHTML='';
    slides.forEach((s,idx)=>{
      const wrap=document.createElement('div'); wrap.className='g-thumb w-24 h-24 sm:w-28 sm:h-28 md:w-32 md:h-32 cursor-pointer'; wrap.setAttribute('draggable','false');
      const img=document.createElement('img');
      if(s.kind==='new'){ const u=URL.createObjectURL(s.file); img.src=u; img.onload=()=>URL.revokeObjectURL(u); }
      else img.src=s.src;
      wrap.appendChild(img);
      const badge=document.createElement('span'); badge.className='cover'; badge.textContent=(s.kind==='new')?'ใหม่':'เดิม'; wrap.appendChild(badge);
      if(s.kind==='new'){ const del=document.createElement('button'); del.className='del'; del.type='button'; del.textContent='ลบ'; del.addEventListener('click',(e)=>{e.stopPropagation(); const i=files.indexOf(s.file); if(i>-1){ files.splice(i,1);} rebuildInput(); refreshCounter(); renderUnified();}); wrap.appendChild(del); }
      if(idx===cur) wrap.classList.add('selected'); wrap.addEventListener('click',()=>{cur=idx; renderUnified();}); gThumbs.appendChild(wrap);
    });
    refreshCounter();
  }

  function pushPicked(list){
    const remain=Math.max(0,LIMIT-oldKept()-files.length);
    if(remain<=0){ showToast(); return; }
    for(const f of Array.from(list)){ if(files.length>=LIMIT) break; const err=validateFile(f); if(err){ alert(err+(f.name?': '+f.name:'')); continue;} if(files.length>=LIMIT-oldKept()){ showToast(); break;} files.push(f); }
    rebuildInput(); renderUnified();
  }
  fileInput?.addEventListener('change', ()=>{ const picked=Array.from(fileInput.files); fileInput.value=''; pushPicked(picked); });
  if(dropZone){
    ['dragenter','dragover'].forEach(t=>dropZone.addEventListener(t,(e)=>{e.preventDefault();dropZone.classList.add('active');}));
    ['dragleave','drop'].forEach(t=>dropZone.addEventListener(t,(e)=>{e.preventDefault();dropZone.classList.remove('active');}));
    dropZone.addEventListener('drop',(e)=>{ const dt=e.dataTransfer; if(!dt||!dt.files) return; pushPicked(dt.files); });
  }
  gPrev?.addEventListener('click', ()=>{ if(!slides.length) return; cur=(cur-1+slides.length)%slides.length; renderUnified(); });
  gNext?.addEventListener('click', ()=>{ if(!slides.length) return; cur=(cur+1)%slides.length; renderUnified(); });

  function refreshSortHidden(){
    if(!oldWrap || !sortHidden) return;
    const ids=Array.from(oldWrap.querySelectorAll('.g-old'))
      .filter(el=>!el.querySelector('input[type=checkbox]')?.checked)
      .map(el=>el.dataset.id);
    sortHidden.value=ids.join(',');
  }
  window.makeCoverOld=function(btn){
    const cell=btn.closest('.g-old'); if(!cell||!oldWrap) return;
    const chk=cell.querySelector('input[type=checkbox]'); if(chk && chk.checked){ alert('รูปนี้ถูกทำเครื่องหมายลบอยู่'); return; }
    oldWrap.insertBefore(cell, oldWrap.firstChild); refreshSortHidden(); renderUnified();
  };
  if(oldWrap){
    let dragEl=null;
    oldWrap.querySelectorAll('.g-old').forEach(el=>{
      el.setAttribute('draggable','true');
      el.addEventListener('dragstart',()=>{dragEl=el; el.classList.add('dragging');});
      el.addEventListener('dragend',()=>{dragEl=null; el.classList.remove('dragging'); refreshSortHidden(); renderUnified();});
      el.addEventListener('dragover',(e)=>e.preventDefault());
      el.addEventListener('drop',(e)=>{e.preventDefault(); if(!dragEl||dragEl===el) return; oldWrap.insertBefore(dragEl, el.nextSibling);});
    });
    oldWrap.addEventListener('change',(e)=>{ if(e.target && e.target.name==='deleteImageIds'){ const box=e.target.closest('.g-old'); if(box) box.style.opacity = e.target.checked ? .35 : 1; refreshCounter(); refreshSortHidden(); renderUnified(); }});
    refreshSortHidden();
  }

  document.getElementById('phoneNumber')?.addEventListener('input', function(){ this.value=this.value.replace(/\D/g,''); });
  (function init(){ renderUnified(); })();
</script>
</body>
</html>
