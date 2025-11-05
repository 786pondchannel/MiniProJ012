<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<fmt:setLocale value="th_TH"/>
<jsp:useBean id="now" class="java.util.Date" />
<%
  request.setCharacterEncoding("UTF-8");
%>

<c:if test="${empty ctx}">
  <c:set var="ctx" value="${pageContext.request.contextPath}"/>
</c:if>
<c:set var="user" value="${sessionScope.loggedInUser}"/>

<!-- คำนวณ badge จำนวนในตะกร้า -->
<c:set var="cartCount" value="0"/>
<c:forEach var="entry" items="${cart.byFarmer}">
  <c:set var="vcart" value="${entry.value}"/>
  <c:forEach var="it" items="${vcart.items}">
    <c:set var="cartCount" value="${cartCount + it.qty}"/>
  </c:forEach>
</c:forEach>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <title>ส่งคำสั่งพรีออเดอร์สำเร็จ • เกษตรกรบ้านเรา</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>

  <style>
    :root{ --emerald:#10b981; --emerald600:#059669; --ink:#0f172a; --muted:#6b7280; --border:#e5e7eb; }
    *{ font-family:'Prompt',system-ui,-apple-system,'Segoe UI',Roboto,'Helvetica Neue',Arial,'Noto Sans',sans-serif }
    body{ color:var(--ink); }

    .bg-farm{
      background:
        radial-gradient(1200px 600px at 15% 5%, rgba(16,185,129,.10), transparent 60%),
        radial-gradient(1200px 600px at 85% 10%, rgba(59,130,246,.10), transparent 60%),
        linear-gradient(180deg,#ffffff 0%, #f7fff9 50%, #ecfff5 100%);
    }

    .header{ background:#000; position:sticky; top:0; z-index:50 }
    .topbar{ display:grid; grid-template-columns:auto 1fr auto; align-items:center; gap:.75rem }
    .nav-a{ color:#fff; opacity:.92; white-space:nowrap }
    .nav-a:hover{ opacity:1; text-decoration:underline }
    .nav-scroll{ overflow-x:auto; -webkit-overflow-scrolling:touch }
    .nav-scroll::-webkit-scrollbar{ display:none }
    .badge{ min-width:18px;height:18px;padding:0 6px;font-size:.7rem;border-radius:9999px;background:#10b981;color:#fff;display:inline-flex;align-items:center;justify-content:center }

    .btn{display:inline-flex;align-items:center;gap:.5rem;padding:.6rem .9rem;border-radius:12px;border:1px solid var(--border);background:#fff;transition:transform .12s, box-shadow .2s, border-color .2s; position:relative; overflow:hidden}
    .btn:hover{transform:translateY(-1px); box-shadow:0 10px 20px rgba(16,185,129,.12); border-color:#d1fae5}
    .btn-primary{ background:linear-gradient(135deg,var(--emerald),var(--emerald600)); color:#fff; border-color:transparent }
    .r{ position:absolute; border-radius:9999px; transform:scale(0); animation:ripple .6s linear; background:rgba(255,255,255,.55); pointer-events:none }
    @keyframes ripple{ to{ transform:scale(8); opacity:0 } }

    @keyframes pop { 0%{transform:scale(.96);opacity:0} 100%{transform:scale(1);opacity:1} }
    .animate-pop { animation: pop .22s ease-out }

    .ring-wrap{ position:relative; width:90px; height:90px }
    .ring{ position:absolute; inset:-12px; border-radius:9999px; background:
      conic-gradient(from 0deg, rgba(16,185,129,.0), rgba(16,185,129,.35), rgba(16,185,129,.0) 70%);
      filter: blur(8px); animation:spin 6s linear infinite; opacity:.9
    }
    @keyframes spin{ to{ transform:rotate(360deg) } }

    .spark{
      position:absolute; width:6px; height:6px; border-radius:9999px; background:#fff;
      box-shadow:0 0 12px rgba(255,255,255,.9);
      animation: fly 900ms ease-out forwards;
      mix-blend-mode: screen;
    }
    @keyframes fly {
      0%{ transform: translate(0,0) scale(1); opacity:1 }
      100%{ transform: translate(var(--tx),var(--ty)) scale(.4); opacity:0 }
    }

    .float-emoji{
      position:absolute; font-size:22px; animation:floatY 4s ease-in-out infinite; opacity:.95;
      filter: drop-shadow(0 6px 10px rgba(0,0,0,.25));
    }
    @keyframes floatY{ 0%,100%{ transform:translateY(0) } 50%{ transform:translateY(-10px) } }

    .toast-enter{ animation:pop .18s ease-out }

    .footer-dark{ background:#000; color:#e5e7eb }
    .footer-dark a{ color:#e5e7eb }
    .footer-dark a:hover{ color:#a7f3d0 }
  </style>
</head>

<body class="bg-farm min-h-screen flex flex-col">
  <!-- ============== Header ============== -->
  <header class="header text-white shadow-md">
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
                <a href="${ctx}/cart" class="nav-a inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/10"><i class="fa-solid fa-basket-shopping"></i> ตะกร้า <span class="badge">${cartCount}</span></a>
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

  <!-- Confetti Overlay -->
  <canvas id="confetti" class="fixed inset-0 pointer-events-none z-40"></canvas>

  <!-- อีโมจิลอยฉลอง -->
  <div class="pointer-events-none fixed inset-0 z-30">
    <div class="float-emoji" style="left:40px;bottom:60px; animation-delay:.1s">🥳</div>
    <div class="float-emoji" style="left:100px;bottom:140px; animation-delay:.6s">🎉</div>
    <div class="float-emoji" style="right:80px;top:120px; animation-delay:.3s">🎊</div>
    <div class="float-emoji" style="right:20px;bottom:100px; animation-delay:.9s">✨</div>
  </div>

  <!-- Main -->
  <main class="flex-1 relative z-10">
    <div class="max-w-4xl mx-auto px-5 py-8">
      <div class="bg-white rounded-2xl shadow p-6 md:p-8 animate-pop">
        <div class="flex items-start md:items-center gap-4 md:gap-6">
          <div class="shrink-0 ring-wrap">
            <div class="ring"></div>
            <div class="h-20 w-20 rounded-full bg-gradient-to-br from-emerald-500 to-emerald-600 text-white grid place-items-center text-3xl shadow-lg relative">
              ✓
              <div id="fw-src" class="absolute inset-0"></div>
            </div>
          </div>
          <div>
            <h1 class="text-2xl md:text-3xl font-extrabold text-gray-900">ส่งคำสั่งพรีออเดอร์สำเร็จ!</h1>
            <p class="text-gray-600 mt-1">ระบบส่งคำสั่งซื้อไปยังร้านแล้ว กรุณารอร้านกดยืนยันก่อนจึงจะเปิดให้ชำระเงิน</p>
          </div>
        </div>

        <!-- กล่องสรุป -->
        <div class="mt-6 grid md:grid-cols-2 gap-4">
          <div class="border rounded-xl p-4 bg-gray-50">
            <div class="text-sm text-gray-500">หมายเลขคำสั่งซื้อ</div>
            <div class="font-mono text-lg md:text-xl mt-1 flex items-center gap-3">
              <span id="orderIdBox"><c:out value="${orderId}" /></span>
              <button id="copyOid" class="text-emerald-700 hover:text-emerald-800 text-sm border rounded px-2 py-1">คัดลอก</button>
            </div>
          </div>
          <div class="border rounded-xl p-4 bg-gray-50">
            <div class="text-sm text-gray-500">สถานะปัจจุบัน</div>
            <div class="mt-1">
              <span class="px-2.5 py-1 rounded-full text-xs md:text-sm bg-amber-100 text-amber-700">
                ส่งไปยังร้าน / รอร้านยืนยัน
              </span>
            </div>
          </div>
        </div>

        <!-- ปุ่มการกระทำ -->
        <div class="mt-8 flex flex-col sm:flex-row gap-3">
          <a href="${ctx}/orders" class="btn">
            <i class="fa-regular fa-clipboard"></i><span>ดูคำสั่งซื้อของฉัน</span>
          </a>

          <!-- แทนที่ปุ่มแชทด้วยปุ่มกลับหน้าสินค้าทั้งหมด -->
          <a href="http://localhost:8081/MiniProJ01/catalog/list" class="btn btn-primary shadow" onclick="ripple(event)">
            ← กลับไปหน้าสินค้าทั้งหมด
          </a>
        </div>

        <!-- คำแนะนำ -->
        <div class="mt-8 border-t pt-6 text-sm text-gray-600 space-y-2">
          <div class="flex items-center gap-2"><span>•</span> ร้านจะตรวจดูคำสั่งและกดยืนยัน จากนั้นระบบจะเปิดให้ชำระเงิน</div>
          <div class="flex items-center gap-2"><span>•</span> ติดตามสถานะ/อัปโหลดสลิปได้ที่ “คำสั่งซื้อของฉัน”</div>
          <div class="flex items-center gap-2"><span>•</span> หากมีข้อสงสัย พิมพ์คุยกับร้านผ่านห้องแชทของคำสั่งซื้อนี้ได้</div>
        </div>
      </div>
    </div>
  </main>

  <!-- Footer -->
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
        <a class="btn btn-primary shadow-lg" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener" onclick="ripple(event)">
          <i class="fa-solid fa-shield-halved"></i> ไปยังเว็บบัญชีคนโกง
        </a>
      </div>
    </div>
  </footer>

  <!-- ปุ่มลอยตรวจสอบบัญชีโกง -->
  <a class="fixed right-4 bottom-4 rounded-full bg-emerald-600 hover:bg-emerald-700 px-4 py-3 inline-flex items-center gap-2 text-white shadow-lg z-50" href="https://www.blacklistseller.com/report/report_preview/447043" target="_blank" rel="noopener">
    <i class="fa-solid fa-shield-halved"></i> เช็คบัญชีคนโกง
  </a>

  <!-- Toast -->
  <div id="toast" class="fixed bottom-5 right-5 hidden">
    <div id="toastBox" class="px-4 py-2 rounded-lg shadow text-white bg-emerald-600 toast-enter">ส่งสำเร็จแล้ว ✓</div>
  </div>

  <script>
    // เมนูโปรไฟล์
    function toggleProfileMenu(){
      const m=document.getElementById('profileMenu'); if(!m) return;
      m.classList.toggle('hidden');
    }
    document.addEventListener('click',(e)=>{
      const b=document.getElementById('profileBtn'), m=document.getElementById('profileMenu');
      if(!b||!m) return; if(!b.contains(e.target) && !m.contains(e.target)) m.classList.add('hidden');
    });

    // Ripple
    function ripple(e){
      const btn=e.currentTarget, rect=btn.getBoundingClientRect();
      const r=document.createElement('span'); r.className='r';
      const d=Math.max(rect.width,rect.height);
      r.style.width=r.style.height=d+'px';
      r.style.left=(e.clientX-rect.left-d/2)+'px';
      r.style.top =(e.clientY-rect.top -d/2)+'px';
      btn.appendChild(r); setTimeout(()=>r.remove(),600);
    }

    // EL ที่จำเป็น
    const ORDER_ID = (document.getElementById('orderIdBox') && document.getElementById('orderIdBox').textContent || '').trim();

    // คัดลอกหมายเลขคำสั่งซื้อ + พลุเล็ก
    (function(){
      var btn = document.getElementById('copyOid');
      if(!btn) return;
      btn.addEventListener('click', async function(){
        try{
          await navigator.clipboard.writeText(ORDER_ID);
          burstAtButton(btn);
          showToast('คัดลอกหมายเลขคำสั่งซื้อแล้ว', true);
        }catch(e){ showToast('คัดลอกไม่สำเร็จ', false); }
      });
    })();

    // Confetti
    const $canvas = document.getElementById('confetti');
    const ctx2d = $canvas.getContext('2d');
    let W,H; let pieces=[];
    function resize(){ W = $canvas.width = window.innerWidth; H = $canvas.height = window.innerHeight; }
    window.addEventListener('resize', resize); resize();

    function spawnConfettiBurst(cx,cy,count){
      const colors = ['#10b981','#34d399','#6ee7b7','#a7f3d0','#60a5fa','#93c5fd','#fbbf24','#f59e0b','#ef4444','#f472b6'];
      for(let i=0;i<count;i++){
        pieces.push({ x:cx, y:cy, r:4+Math.random()*6, s:2+Math.random()*4, a:Math.random()*Math.PI*2, g:.05+.02*Math.random(), rot:Math.random()*Math.PI, rotS:(Math.random()-.5)*.2, col:colors[(Math.random()*colors.length)|0], life:60+Math.random()*40 });
      }
    }
    function draw(){
      ctx2d.clearRect(0,0,W,H);
      for(let i=pieces.length-1;i>=0;i--){
        const p=pieces[i];
        p.x += Math.cos(p.a)*p.s;
        p.y += Math.sin(p.a)*p.s + p.g*(60-p.life)/2;
        p.rot += p.rotS;
        p.life -= 1;
        ctx2d.save(); ctx2d.translate(p.x,p.y); ctx2d.rotate(p.rot);
        ctx2d.fillStyle=p.col; ctx2d.fillRect(-p.r/2,-p.r/2,p.r,p.r); ctx2d.restore();
        if(p.life<=0 || p.y>H+30) pieces.splice(i,1);
      }
      requestAnimationFrame(draw);
    }
    requestAnimationFrame(draw);

    function runConfettiBurst(){
      const rect = document.querySelector('.ring-wrap')?.getBoundingClientRect();
      const cx = rect ? rect.left + rect.width/2 : W/2;
      const cy = rect ? rect.top  + rect.height/2 + window.scrollY : 180;
      spawnConfettiBurst(cx, cy, 140);
      setTimeout(()=>spawnConfettiBurst(cx+80, cy-30, 100), 200);
      setTimeout(()=>spawnConfettiBurst(cx-120, cy+10, 120), 380);
    }
    function burstAtButton(btn){
      const r = btn.getBoundingClientRect();
      const cx = r.left + r.width/2; const cy = r.top;
      spawnConfettiBurst(cx, cy + window.scrollY, 80);
    }

    window.addEventListener('load', function(){
      runConfettiBurst();
      microFirework('#fw-src');
    });

    // พลุเล็กตรงไอคอนติ๊ก
    function microFirework(sel){
      const root = document.querySelector(sel);
      if(!root) return;
      for(let i=0;i<18;i++){
        const s = document.createElement('span');
        s.className='spark';
        const ang = (i/18)*Math.PI*2;
        const dist = 80 + Math.random()*40;
        s.style.setProperty('--tx', Math.cos(ang)*dist+'px');
        s.style.setProperty('--ty', Math.sin(ang)*dist+'px');
        s.style.left='50%'; s.style.top='50%';
        s.style.transform='translate(-50%,-50%)';
        s.style.background = i%3? '#fff' : '#fde047';
        s.style.animationDelay = (Math.random()*150)+'ms';
        root.appendChild(s);
        setTimeout(()=>s.remove(), 1000);
      }
    }

    // Toast
    var toastTimer=null;
    function showToast(msg, ok){
      var wrap = document.getElementById('toast');
      var box  = document.getElementById('toastBox');
      box.textContent = msg;
      box.className = 'px-4 py-2 rounded-lg shadow text-white ' + (ok?'bg-emerald-600':'bg-red-600') + ' toast-enter';
      wrap.classList.remove('hidden');
      clearTimeout(toastTimer);
      toastTimer=setTimeout(function(){ wrap.classList.add('hidden'); }, 1800);
    }
  </script>
</body>
</html>
