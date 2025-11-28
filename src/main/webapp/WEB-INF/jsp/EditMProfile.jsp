<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<jsp:useBean id="now" class="java.util.Date" />
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <title>แก้ไขโปรไฟล์</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700;800&display=swap"/>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
  <style>
    :root{ --ink:#0f172a; --muted:#6b7280; --border:#e5e7eb; --emerald:#10b981; --emerald-600:#059669; }
    *{ font-family:'Prompt',ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif }
    body{ background:#f3f4f6 }
    .card{ background:#fff; border:1px solid var(--border); border-radius:20px; box-shadow:0 16px 40px rgba(2,8,23,.06) }
    .input{ width:100%; padding:.65rem .9rem; border:1px solid var(--border); border-radius:12px; outline:none; background:#fff }
    .input:focus{ border-color:#a7f3d0; box-shadow:0 0 0 3px rgba(16,185,129,.2) }
    .btn-primary{ background:linear-gradient(135deg,var(--emerald),var(--emerald-600)); color:#fff }
    .btn-primary:hover{ filter:brightness(1.05) }
    .hint{ font-size:.8rem; color:var(--muted) }
    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center;transform:translate(-2px,-6px) }
    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }
    input[list]{ appearance:none; -webkit-appearance:none; background-image:none!important }
    input[list]::-webkit-calendar-picker-indicator{ display:none!important; opacity:0!important }
  </style>
</head>
<body>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="m"   value="${member}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />

<!-- ================= Header ================= -->
<header class="header text-white shadow-md">
  <div class="max-w-7xl mx-auto px-6 py-3 grid grid-cols-[auto_1fr_auto] items-center gap-3">
    <div class="flex items-center gap-3">
      <a href="${ctx}/main" class="flex items-center gap-3">
        <img src="https://cdn-icons-png.flaticon.com/512/2909/2909763.png" class="h-8 w-8" alt="logo"/>
        <span class="hidden sm:inline font-bold">เกษตรกรบ้านเรา</span>
      </a>
      <nav class="nav-scroll ml-2">
        <c:choose>
          <c:when test="${not empty sessionScope.loggedInUser && sessionScope.loggedInUser.status eq 'FARMER'}">
            <div class="flex items-center gap-2 md:gap-3 text-[13px] md:text-sm">
              <a href="${ctx}/product/create" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-plus mr-1.5"></i>สร้างสินค้า</a>
              <a href="${ctx}/farmer/profile" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-store mr-1.5"></i>โปรไฟล์ร้าน</a>
              <a href="${ctx}/product/list/Farmer" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-rectangle-list mr-1.5"></i>สินค้าของฉัน</a>
              <a href="${ctx}/farmer/orders" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-truck mr-1.5"></i>ออเดอร์</a>
            </div>
          </c:when>
          <c:otherwise>
            <div class="flex items-center gap-2 md:gap-3 text-[13px] md:text-sm">
              <a href="${ctx}/main" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-house mr-1.5"></i>หน้าหลัก</a>
              <a href="${ctx}/catalog/list" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-list mr-1.5"></i>สินค้าทั้งหมด</a>
              <a href="${ctx}/orders" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-clock mr-1.5"></i>คำสั่งซื้อของฉัน</a>
              <a href="${ctx}/cart" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10 icon-btn"><i class="fa-solid fa-basket-shopping mr-1.5"></i>ตะกร้า <span class="badge">${cartCount}</span></a>
            </div>
          </c:otherwise>
        </c:choose>
      </nav>
    </div>

    <form method="get" action="${ctx}/catalog/list" class="hidden sm:block w-full max-w-2xl mx-4">
      <div class="relative">
        <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-white/70"></i>
        <input name="kw" placeholder="ค้นหาผลผลิต/ร้าน/คำสำคัญ…"
               class="w-full rounded-lg pl-9 pr-3 py-2 text-white/90 bg-white/10 outline-none focus:ring-2 focus:ring-emerald-400 placeholder-white/70"/>
      </div>
    </form>

    <div class="justify-self-end">
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
                    class="inline-flex items-center px-3 py-1 bg-white/20 hover:bg-white/35 backdrop-blur rounded-full text-sm font-medium focus:outline-none focus:ring-2 focus:ring-green-300 group"
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
                  <c:choose>
                    <c:when test="${sessionScope.loggedInUser.status eq 'FARMER'}">
                      <a href="${ctx}/farmer/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50">👨‍🌾 แก้ไขโปรไฟล์เกษตรกร</a>
                    </c:when>
                    <c:otherwise>
                      <a href="${ctx}/profile/edit" class="flex items-center px-4 py-3 hover:bg-blue-50">👤 แก้ไขโปรไฟล์ส่วนตัว</a>
                    </c:otherwise>
                  </c:choose>
                </li>
                <li><a href="${ctx}/logout" class="flex items-center px-4 py-3 hover:bg-red-50">🚪 ออกจากระบบ</a></li>
              </ul>
            </div>
          </div>
        </c:when>
        <c:otherwise>
          <a href="${ctx}/login" class="btn-primary px-4 py-1.5 rounded text-white shadow-lg hover:-translate-y-0.5 inline-block">เข้าสู่ระบบ</a>
        </c:otherwise>
      </c:choose>
    </div>
  </div>
</header>
<!-- ================= /Header ================= -->

<main class="max-w-4xl mx-auto px-4 py-8">
  <div class="card p-6 md:p-8">
    <form id="profileForm" action="${ctx}/profile/edit" method="post" enctype="multipart/form-data">
      <!-- Avatar -->
      <div class="flex flex-col items-center">
        <div class="w-28 h-28 rounded-full overflow-hidden border">
          <c:set var="raw" value="${m.imageUrl}" />
          <c:set var="avatar" value="" />
          <c:choose>
            <c:when test="${not empty raw and fn:startsWith(raw,'http')}"><c:set var="avatar" value="${raw}" /></c:when>
            <c:when test="${not empty raw and fn:startsWith(raw,'/')}"><c:set var="avatar" value="${ctx}${raw}" /></c:when>
            <c:when test="${not empty raw}"><c:set var="avatar" value="${ctx}/${raw}" /></c:when>
            <c:otherwise><c:set var="avatar" value="https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=240&q=60" /></c:otherwise>
          </c:choose>
          <img id="avatarImg" src="${avatar}?t=${now.time}" class="w-full h-full object-cover" alt="avatar">
        </div>

        <div class="mt-3 text-sm text-gray-600">อัปโหลดรูปภาพโปรไฟล์ (.JPG .PNG .WEBP ≤ 5MB)</div>
        <div class="mt-2 flex items-center gap-3">
          <label for="imageFile" class="inline-flex items-center gap-2 px-3 py-1.5 rounded border cursor-pointer bg-gray-50 hover:bg-gray-100">
            <i class="fa-solid fa-upload"></i><span>เลือกไฟล์</span>
          </label>
          <input id="imageFile" name="imageFile" type="file" accept="image/png,image/jpeg,image/webp" class="hidden">
          <span id="fileName" class="text-xs text-gray-500">ไม่มีไฟล์ที่เลือก</span>
        </div>
      </div>

      <!-- Flash -->
      <c:if test="${not empty msg}">
        <div class="mt-5 bg-emerald-50 text-emerald-700 border border-emerald-200 px-4 py-2 rounded">${msg}</div>
      </c:if>
      <c:if test="${not empty error}">
        <div class="mt-5 bg-red-50 text-red-700 border border-red-200 px-4 py-2 rounded">${error}</div>
      </c:if>

      <!-- Fields -->
      <div class="mt-6 grid md:grid-cols-2 gap-5">
        <div>
          <label class="block text-sm mb-1">ชื่อจริง</label>
          <input id="firstName" type="text" class="input" value="">
        </div>
        <div>
          <label class="block text-sm mb-1">นามสกุล</label>
          <input id="lastName" type="text" class="input" value="">
        </div>

        <!-- fullname ที่บันทึกจริง -->
        <input type="hidden" name="fullname" id="fullnameHidden" value="${m.fullname}">

        <div class="md:col-span-2">
          <label class="block text-sm mb-1">อีเมล</label>
          <div class="relative">
            <input id="email" name="email" type="email" class="input pr-9" value="${m.email}">
            <i id="okEmail" class="fa-solid fa-check absolute right-3 top-1/2 -translate-y-1/2 text-emerald-600 hidden"></i>
          </div>
          <div class="hint mt-1">อีเมลต้องเป็นรูปแบบสากล (ไม่รองรับภาษาไทยในส่วน @domain)</div>
        </div>

        <div class="md:col-span-2">
          <label class="block text-sm mb-1">ที่อยู่</label>
          <div class="flex gap-2 flex-wrap">
            <input id="address" name="address" type="text" class="input flex-1" value="${m.address}" placeholder="เช่น บ้านเลขที่/ถนน/ตำบล-แขวง ฯลฯ">
            <button type="button" class="px-3 rounded bg-gray-900 text-white hover:bg-black" onclick="openGoogleMaps()">
              <i class="fa-solid fa-map-location-dot mr-1"></i> เปิด Google Maps
            </button>
            <button type="button" class="px-3 rounded border bg-white hover:bg-gray-50" onclick="pasteFromClipboard()">วางที่อยู่</button>
          </div>
        </div>

        <div>
          <label class="block text-sm mb-1">เบอร์โทรศัพท์</label>
          <input name="phoneNumber" type="text" class="input" value="${m.phoneNumber}" placeholder="เช่น 08x-xxx-xxxx">
        </div>

        <div>
          <label class="block text-sm mb-1">รหัสผ่าน</label>
          <div class="relative">
            <input id="pwd" name="password" type="password" class="input pr-9" value="${m.password}">
            <i class="fa-solid fa-lock text-gray-400 absolute right-3 top-1/2 -translate-y-1/2"></i>
          </div>
        </div>

        <input type="hidden" id="lat" name="lat" value="">
        <input type="hidden" id="lng" name="lng" value="">
      </div>

      <div class="mt-8 flex justify-end gap-3">
        <a href="${ctx}/main" class="px-4 py-2 rounded border bg-gray-50 hover:bg-gray-100">ยกเลิก</a>
        <button id="btnSave" class="px-5 py-2 rounded bg-emerald-600 hover:bg-emerald-700 text-white">บันทึก</button>
      </div>
    </form>
  </div>
</main>

<!-- ================= Footer ================= -->
<footer class="footer-dark mt-10">
  <div class="max-w-7xl mx-auto px-6 py-10 grid md:grid-cols-3 gap-6 text-sm">
    <div>
      <h4 class="font-bold mb-2">เกี่ยวกับเรา</h4>
      <p class="text-gray-300">ตลาดออนไลน์สำหรับสินค้าเกษตรคุณภาพ ส่งตรงจากฟาร์มท้องถิ่น</p>
    </div>
    <div>
      <h4 class="font-bold mb-2">ลิงก์ด่วน</h4>
      <ul class="space-y-1">
        <li><a href="${ctx}/main">หน้าหลัก</a></li>
        <li><a href="${ctx}/catalog/list">สินค้าทั้งหมด</a></li>
        <li><a href="${ctx}/orders">คำสั่งซื้อของฉัน</a></li>
      </ul>
    </div>
    <div>
      <h4 class="font-bold mb-2">ความปลอดภัย</h4>
      <p class="text-gray-300 mb-2">ตรวจสอบรายชื่อผู้ค้าต้องสงสัยก่อนชำระเงิน</p>
      <a class="inline-flex items-center gap-2 px-3 py-2 rounded bg-emerald-600 hover:bg-emerald-700 text-white"
         href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
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

  // ====== Refs ======
  const imageInput = document.getElementById('imageFile');
  const fileName   = document.getElementById('fileName');
  const avatarImg  = document.getElementById('avatarImg');
  const emailInput = document.getElementById('email');
  const okEmail    = document.getElementById('okEmail');
  const firstName  = document.getElementById('firstName');
  const lastName   = document.getElementById('lastName');
  const fullnameH  = document.getElementById('fullnameHidden');
  const addressEl  = document.getElementById('address');
  const districtEl = document.getElementById('district');
  const zipcodeEl  = document.getElementById('zipcode');

  // split fullname -> first/last (เพื่อ UX อย่างเดียว)
  (function(){
    var full = (fullnameH?.value || '').trim().replace(/\s+/g,' ');
    if(!full){ firstName.value=''; lastName.value=''; return; }
    var parts = full.split(' ');
    if(parts.length === 1){ firstName.value = full; lastName.value=''; }
    else { lastName.value = parts.pop(); firstName.value = parts.join(' '); }
  })();

  // preview + ตรวจไฟล์เบื้องต้นฝั่งหน้าเว็บ
  imageInput?.addEventListener('change', function(){
    const f = imageInput.files?.[0];
    fileName.textContent = f ? (f.name || 'ไฟล์ที่เลือก') : 'ไม่มีไฟล์ที่เลือก';
    if(!f) return;
    const okType = ['image/jpeg','image/png','image/webp'].includes(f.type);
    const okSize = f.size <= 5*1024*1024;
    if(!okType){ alert('อัปโหลดได้เฉพาะไฟล์ .jpg .png .webp'); imageInput.value=''; return; }
    if(!okSize){ alert('ไฟล์รูปต้องไม่เกิน 5MB'); imageInput.value=''; return; }
    const url = URL.createObjectURL(f); avatarImg.src = url; setTimeout(()=>URL.revokeObjectURL(url), 1500);
  });

  // email ok icon
  function validEmail(s){ return !!s && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(s); }
  function toggleOkEmail(){ okEmail?.classList.toggle('hidden', !validEmail(emailInput.value)); }
  emailInput?.addEventListener('input', toggleOkEmail); toggleOkEmail();

  // รวม first+last -> fullname ก่อน submit
  document.getElementById('profileForm').addEventListener('submit', function(){
    const fn = (firstName.value || '').trim();
    const ln = (lastName.value || '').trim();
    fullnameH.value = ln ? (fn + ' ' + ln) : fn;
  });

  // Google Maps helper + paste
  function openGoogleMaps(){
    const q = (addressEl?.value || '').trim();
    const url = 'https://www.google.com/maps/search/?api=1' + (q ? '&query=' + encodeURIComponent(q) : '');
    window.open(url, '_blank', 'noopener');
  }
  async function pasteFromClipboard(){
    if (!navigator.clipboard?.readText) { alert('เบราว์เซอร์บล็อกการอ่านคลิปบอร์ด — วางเองด้วย Ctrl+V / ⌘+V'); return; }
    try{
      const text = await navigator.clipboard.readText();
      if(!text) return;
      addressEl.value = text.trim();
      smartParseThaiAddress(text);
    }catch(e){ alert('ต้องใช้ผ่าน HTTPS หรือ localhost ถึงจะอ่านคลิปบอร์ดอัตโนมัติได้'); }
  }
  window.openGoogleMaps = openGoogleMaps;
  window.pasteFromClipboard = pasteFromClipboard;

  addressEl?.addEventListener('paste', () => setTimeout(()=> smartParseThaiAddress(addressEl.value), 0));
  addressEl?.addEventListener('blur',  () => smartParseThaiAddress(addressEl.value));

  function smartParseThaiAddress(s){
    if(!s) return;
    const zip = s.match(/(\d{5})(?!\d)/); if(zip && zipcodeEl) zipcodeEl.value = zip[1];
    const m   = s.match(/(?:อ\.|อำเภอ|เขต)\s*([ก-๙A-Za-z]+?)(?:\s|,|$)/);
    if(m && m[1] && districtEl) districtEl.value = m[1].trim();
  }
</script>
</body>
</html>
