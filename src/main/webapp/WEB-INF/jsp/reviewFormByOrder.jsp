<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<jsp:useBean id="now" class="java.util.Date" />

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="cartCount" value="${empty sessionScope.cartCount ? 0 : sessionScope.cartCount}" />

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>รีวิวคำสั่งซื้อ • เกษตรกรบ้านเรา</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700;800&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{
      --ink:#0f172a; --muted:#6b7280; --border:#e5e7eb;
      --emerald:#10b981; --emerald-600:#059669; --sky:#0ea5e9; --amber:#f59e0b; --rose:#f43f5e;
    }
    *{ font-family:'Prompt',ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif }

    /* ===== Animated Background ===== */
    body{
      color:var(--ink);
      background: linear-gradient(120deg, #f0fff4, #f0f9ff, #fff1f2);
      background-size: 200% 200%;
      animation: gradientFlow 14s ease infinite;
      overflow-x:hidden;
    }
    @keyframes gradientFlow{
      0%{background-position:0% 50%} 50%{background-position:100% 50%} 100%{background-position:0% 50%}
    }
    /* floating blobs */
    .blob{
      position:fixed; inset:auto; border-radius:999px; filter:blur(40px); opacity:.45; z-index:0; pointer-events:none;
      animation:floaty 18s ease-in-out infinite;
    }
    .b1{ width:320px;height:320px; background:#a7f3d0; top:-80px; left:-60px; animation-delay:0s }
    .b2{ width:360px;height:360px; background:#bfdbfe; bottom:-120px; right:-60px; animation-delay:2s }
    .b3{ width:260px;height:260px; background:#fecaca; top:40%; left:-120px; animation-delay:4s }
    @keyframes floaty{
      0%,100%{ transform:translateY(0) translateX(0) scale(1)}
      50%{transform:translateY(30px) translateX(20px) scale(1.05)}
    }

    /* ===== Header / Footer (เหมือนหน้าอื่น) ===== */
    .header{ background:#000; position:sticky; top:0; z-index:40; backdrop-filter:saturate(140%) blur(4px) }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }
    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb } .footer-dark a:hover{ color:#a7f3d0 }

    /* ===== Cards / Buttons ===== */
    .card{
      position:relative; background:#fff; border:1px solid var(--border); border-radius:20px;
      box-shadow: 0 18px 60px rgba(2,8,23,.09);
      animation:popIn .55s cubic-bezier(.22,.61,.36,1) both;
    }
    @keyframes popIn{ from{opacity:0; transform:translateY(12px) scale(.98)} to{opacity:1; transform:translateY(0) scale(1)} }

    .btn{ display:inline-flex; align-items:center; gap:.55rem; padding:.78rem 1.05rem; border-radius:12px; border:1px solid var(--border); background:#fff;
      transition:transform .12s, box-shadow .2s, border-color .2s; position:relative; overflow:hidden; font-weight:700 }
    .btn:hover{ transform:translateY(-1px); box-shadow:0 14px 28px rgba(16,185,129,.12); border-color:#c7eadf }
    .btn-primary{ background:linear-gradient(135deg,var(--emerald),var(--emerald-600)); color:#fff; border-color:transparent }
    .btn-ghost{ background:transparent }
    .btn:disabled{ opacity:.6; transform:none; box-shadow:none; cursor:not-allowed }

    /* Ripple */
    .ripple{ position:absolute; border-radius:9999px; transform:scale(0); background:rgba(255,255,255,.55); animation:ripple .6s linear; pointer-events:none }
    @keyframes ripple{ to{ transform:scale(4); opacity:0 } }

    /* ===== “สินค้าในใบเสร็จ” ก้อนเดียว ===== */
    .list{ border:1px solid var(--border); border-radius:16px; overflow:hidden; background:#fff }
    .list-head,
    .list-row{ display:grid; gap:1rem; align-items:center }
    @media (min-width: 640px){
      .list-head,.list-row{ grid-template-columns: 140px 1fr auto; }
    }
    @media (max-width: 639.98px){
      .list-head{ grid-template-columns: 1fr auto }
      .list-row{ grid-template-columns: 140px 1fr }
    }
    .list-head{ background:linear-gradient(180deg,#f9fafb,#fff); padding:.9rem 1rem; border-bottom:1px solid var(--border); font-weight:800; color:#334155; position:relative }
    .list-row{
      padding:.85rem 1rem; border-bottom:1px dashed #e5e7eb; transition:background .15s, transform .15s, box-shadow .2s;
    }
    .list-row:last-child{ border-bottom:0 }
    .list-row:hover{ background:#fbfefd; transform:translateY(-1px); box-shadow:0 8px 18px rgba(2,8,23,.06) }

    /* Image + shimmer */
    .imgwrap{ width:140px; height:96px; border:1px solid var(--border); border-radius:12px; overflow:hidden; position:relative; background:#f8fafc }
    .imgwrap img{ width:100%; height:100%; object-fit:cover; opacity:0; transform:scale(1.02); transition:opacity .35s ease, transform .35s ease }
    .imgwrap.loaded img{ opacity:1; transform:scale(1) }
    .shimmer::before{
      content:""; position:absolute; inset:0;
      background:linear-gradient(120deg, rgba(255,255,255,0) 0%, rgba(255,255,255,.75) 50%, rgba(255,255,255,0) 100%);
      transform:translateX(-100%); animation:shimmer 1.2s infinite;
    }
    @keyframes shimmer{ 100%{ transform:translateX(100%) } }

    /* Stars */
    .stars .star{
      font-size:36px; cursor:pointer; color:#e5e7eb; filter:drop-shadow(0 1px 0 #fff); transition:transform .12s ease, color .12s ease
    }
    .stars .star.on{ color:var(--amber); text-shadow:0 0 18px rgba(245,158,11,.35) }
    .stars .star:hover{ transform:translateY(-1px) scale(1.07) }
    .sparkle{
      position:absolute; pointer-events:none; font-size:14px; animation:spark .6s ease forwards; opacity:.85
    }
    @keyframes spark{
      from{ transform:translateY(0) scale(1); opacity:1 }
      to{ transform:translateY(-16px) scale(0.6); opacity:0 }
    }

    /* Section title line */
    .sec-title{
      display:flex; align-items:center; gap:.6rem; font-weight:800;
    }
    .sec-title::after{
      content:""; flex:1; height:1px; background:linear-gradient(90deg, #d1fae5, #e5e7eb 40%, transparent);
    }

    /* Stagger reveal for rows */
    .reveal{ opacity:0; transform:translateY(10px); transition:opacity .35s ease, transform .35s ease }
    .reveal.on{ opacity:1; transform:translateY(0) }
  </style>
</head>

<body>
  <!-- background blobs -->
  <div class="blob b1"></div>
  <div class="blob b2"></div>
  <div class="blob b3"></div>

  <!-- =============== Header =============== -->
  <header class="header text-white shadow-md">
    <div class="max-w-7xl mx-auto px-6 py-3 grid grid-cols-[auto,1fr,auto] items-center gap-3">
      <div class="flex items-center gap-3">
        <a href="${ctx}/main" class="flex items-center gap-3">
          <img src="https://cdn-icons-png.flaticon.com/512/2909/2909763.png" class="h-8 w-8" alt="logo"/>
          <span class="hidden sm:inline font-bold">เกษตรกรบ้านเรา</span>
        </a>
        <nav class="ml-2 hidden md:block">
          <div class="flex items-center gap-3 text-[13px] md:text-sm">
            <a href="${ctx}/catalog/list" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-list mr-1"></i> สินค้าทั้งหมด</a>
            <a href="${ctx}/orders" class="nav-a px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-regular fa-clock mr-1"></i> คำสั่งซื้อของฉัน</a>
          </div>
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
                      class="inline-flex items-center px-3 py-1 bg-white/20 hover:bg-white/35 backdrop-blur rounded-full text-sm font-medium focus:outline-none focus:ring-2 focus:ring-green-300 group">
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
            <a href="${ctx}/login" class="btn btn-primary px-4 py-1.5 text-white shadow-lg hover:-translate-y-0.5 inline-block">เข้าสู่ระบบ</a>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </header>

  <!-- ================= Main ================= -->
  <main class="relative z-10 max-w-4xl mx-auto px-4 py-8">
    <div class="card p-6 md:p-8">
      <div class="flex items-start justify-between gap-4">
        <div>
          <h1 class="text-2xl md:text-3xl font-extrabold">รีวิวคำสั่งซื้อ</h1>
          <div class="text-sm text-gray-500 mt-1">1 รีวิวต่อ 1 ใบเสร็จ • อนุญาตเฉพาะขั้นที่ 3 หรือ 4</div>
        </div>
        <div class="hidden md:block text-emerald-700 font-semibold">
          <i class="fa-solid fa-seedling mr-1"></i> เกษตรกรบ้านเรา
        </div>
      </div>

      <c:if test="${not empty error}">
        <div class="mt-4 border border-red-200 bg-red-50 text-red-700 px-4 py-2 rounded animate-[popIn_.4s_ease]">${error}</div>
      </c:if>
      <c:if test="${not empty msg}">
        <div class="mt-4 border border-emerald-200 bg-emerald-50 text-emerald-700 px-4 py-2 rounded animate-[popIn_.4s_ease]">${msg}</div>
      </c:if>

      <!-- ===== สินค้าในใบเสร็จ: ก้อนเดียว ===== -->
      <section class="mt-6">
        <div class="sec-title mb-2"><i class="fa-solid fa-receipt text-emerald-600"></i> สินค้าในใบเสร็จ #<c:out value="${orderId}"/></div>

        <div class="list">
          <div class="list-head">
            <div class="hidden sm:block">รูป</div>
            <div>สินค้า</div>
            <div class="hidden sm:block text-right pr-1">จำนวน</div>
          </div>

          <c:forEach var="it" items="${items}" varStatus="vs">
            <c:set var="imgUrl" value="" />
            <c:choose>
              <c:when test="${not empty it.img and fn:startsWith(it.img,'http')}">
                <c:set var="imgUrl" value="${it.img}"/>
              </c:when>
              <c:when test="${not empty it.img and fn:startsWith(it.img,'/')}">
                <c:set var="imgUrl" value="${ctx}${it.img}"/>
              </c:when>
              <c:otherwise>
                <c:set var="imgUrl" value="${ctx}/uploads/${it.img}"/>
              </c:otherwise>
            </c:choose>

            <div class="list-row reveal" style="transition-delay:${vs.index * 60}ms">
              <div class="imgwrap shimmer">
                <img src="<c:out value='${imgUrl}'/>"
                     alt="product"
                     loading="lazy"
                     onload="this.parentElement.classList.add('loaded'); this.parentElement.classList.remove('shimmer');"
                     onerror="this.onerror=null; this.src='https://via.placeholder.com/300x200?text=No+Image'; this.parentElement.classList.add('loaded'); this.parentElement.classList.remove('shimmer');">
              </div>

              <div class="min-w-0">
                <div class="font-semibold text-slate-800 truncate"><c:out value="${it.productname}"/></div>
                <div class="text-xs text-gray-500 break-words mt-0.5">
                  productId: <span class="font-mono"><c:out value="${it.productId}"/></span>
                </div>
                <div class="mt-2 inline-flex items-center gap-2 text-emerald-700 text-xs font-semibold">
                  <i class="fa-solid fa-leaf"></i> ของแท้จากเกษตรกร
                </div>
              </div>

              <div class="hidden sm:block text-right font-semibold pr-1">
                x<c:out value="${it.quantity}"/>
              </div>
            </div>
          </c:forEach>
        </div>

        <div class="mt-2 text-xs text-gray-500">
          * ระบบจะบันทึกรีวิวลง “สินค้าตัวแรก” ของใบเสร็จนี้
        </div>
      </section>

      <!-- ===== ฟอร์มรีวิว ===== -->
      <form class="mt-8" method="post" action="${ctx}/reviews/create-by-order" onsubmit="return onSubmitReview(event)">
        <input type="hidden" name="orderId" value="${orderId}">
        <input type="hidden" name="rating" id="rating" value="5">

        <div class="mb-4">
          <div class="text-sm text-gray-600 mb-1">ให้คะแนน</div>
          <div id="stars" class="stars relative flex items-center gap-1 select-none">
            <span data-v="1" class="star on">★</span>
            <span data-v="2" class="star on">★</span>
            <span data-v="3" class="star on">★</span>
            <span data-v="4" class="star on">★</span>
            <span data-v="5" class="star on">★</span>
          </div>
        </div>

        <div class="mb-6">
          <label class="block text-sm mb-1">ความคิดเห็น</label>
          <textarea name="comment" class="w-full border rounded-lg px-3 py-3 min-h-[120px] focus:outline-none focus:ring-2 focus:ring-emerald-300"
                    placeholder="เขียนประสบการณ์เกี่ยวกับคุณภาพ ความคุ้มค่า การบริการ ฯลฯ"></textarea>
        </div>

        <div class="flex items-center gap-3">
          <a href="${ctx}/orders" class="btn btn-ghost" onclick="mkRipple(event)"><i class="fa-solid fa-arrow-left-long"></i> ย้อนกลับ</a>
          <button id="btnSubmit" class="btn btn-primary text-white" onclick="mkRipple(event)">
            <i class="fa-solid fa-paper-plane-top"></i> ส่งรีวิว
          </button>
        </div>
      </form>
    </div>
  </main>

  <!-- =============== Footer =============== -->
  <footer class="footer-dark mt-10 relative z-10">
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

  <!-- ===== Confetti Canvas ===== -->
  <canvas id="confetti" class="pointer-events-none fixed inset-0 z-30"></canvas>

  <script>
    // ===== Profile dropdown =====
    function toggleProfileMenu(e){
      e && e.stopPropagation();
      const m=document.getElementById('profileMenu'), b=document.getElementById('profileBtn');
      if(!m||!b) return;
      const hide=!m.classList.contains('hidden');
      m.classList.toggle('hidden');
      b.setAttribute('aria-expanded', hide?'false':'true');
    }
    document.addEventListener('click',(e)=>{
      const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return;
      if(!b.contains(e.target) && !m.contains(e.target)){
        m.classList.add('hidden'); b.setAttribute('aria-expanded','false');
      }
    });

    // ===== Stagger reveal for rows =====
    const reveals = document.querySelectorAll('.reveal');
    const io = new IntersectionObserver(entries=>{
      entries.forEach(en=>{
        if(en.isIntersecting){ en.target.classList.add('on'); io.unobserve(en.target); }
      })
    }, {threshold:.08});
    reveals.forEach(el=>io.observe(el));

    // ===== Stars with sparkles =====
    const stars = document.querySelectorAll('#stars .star');
    const rating = document.getElementById('rating');
    const starBox = document.getElementById('stars');

    function sparkleAt(x,y){
      const s=document.createElement('div');
      s.className='sparkle'; s.textContent='✦';
      s.style.left=x+'px'; s.style.top=y+'px';
      starBox.appendChild(s);
      setTimeout(()=>s.remove(), 650);
    }
    stars.forEach(s=>{
      s.addEventListener('click', (e)=>{
        const v = parseInt(s.dataset.v,10)||5;
        rating.value = v;
        stars.forEach(t=> t.classList.toggle('on', parseInt(t.dataset.v,10) <= v));
        const rect = starBox.getBoundingClientRect();
        sparkleAt(e.clientX-rect.left, e.clientY-rect.top);
      });
    });

    // ===== Button ripple =====
    function mkRipple(e){
      const btn = e.currentTarget;
      const r = document.createElement('span');
      const rect = btn.getBoundingClientRect();
      const d = Math.max(rect.width, rect.height);
      r.className = 'ripple';
      r.style.width = r.style.height = d+'px';
      r.style.left = (e.clientX - rect.left - d/2) + 'px';
      r.style.top  = (e.clientY - rect.top  - d/2) + 'px';
      btn.appendChild(r);
      setTimeout(()=>r.remove(), 600);
    }

    // ===== Confetti (lightweight) =====
    const cf = document.getElementById('confetti');
    const ctx = cf.getContext('2d');
    let pieces = [];
    function resize(){ cf.width = innerWidth; cf.height = innerHeight; }
    addEventListener('resize', resize); resize();

    function makeConfetti(n=120){
      const colors = ['#10b981','#059669','#22d3ee','#f59e0b','#f43f5e','#6366f1'];
      for(let i=0;i<n;i++){
        pieces.push({
          x: Math.random()*cf.width,
          y: -20 - Math.random()*60,
          s: 4+Math.random()*6,
          c: colors[(Math.random()*colors.length)|0],
          vx: -1+Math.random()*2,
          vy: 2+Math.random()*3,
          a: Math.random()*Math.PI
        });
      }
    }
    function loop(){
      ctx.clearRect(0,0,cf.width,cf.height);
      pieces.forEach(p=>{
        p.x += p.vx; p.y += p.vy; p.a += 0.07;
        ctx.save();
        ctx.translate(p.x,p.y); ctx.rotate(Math.sin(p.a));
        ctx.fillStyle = p.c;
        ctx.fillRect(-p.s/2,-p.s/2,p.s,p.s);
        ctx.restore();
      });
      pieces = pieces.filter(p=>p.y < cf.height + 20);
      requestAnimationFrame(loop);
    }
    loop();

    // ===== Submit + confetti =====
    function onSubmitReview(e){
      const btn=document.getElementById('btnSubmit');
      btn.setAttribute('disabled','disabled');
      btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> กำลังส่ง...';
      mkRipple({currentTarget:btn, clientX:btn.getBoundingClientRect().left+10, clientY:btn.getBoundingClientRect().top+10});

      // ปล่อยคอนเฟตติก่อนส่งจริง (ไม่ขัดการ submit)
      makeConfetti(140);
      return true; // ให้ฟอร์มส่งตามปกติ
    }
  </script>
</body>
</html>
