<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <title>เข้าสู่ระบบ - ระบบเกษตรชุมชน</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700&display=swap"/>
  <style>
    :root{
      --ink:#0f172a; --muted:#6b7280; --emerald:#10b981; --emerald600:#059669;
      --night:#0b0f14; --pump:#ff7a1a; --accent:#22c55e;
    }
    body{ font-family:'Prompt',sans-serif; }

    /* พื้นหลัง: เขียว-ขาว + ฮาโลวีนเบาๆ */
    .bg-farm{
      min-height:100vh;
      background:
        radial-gradient(1200px 600px at 15% 10%, rgba(255,140,0,.08), transparent 60%),
        radial-gradient(1400px 700px at 85% 20%, rgba(34,197,94,.10), transparent 65%),
        linear-gradient(160deg, #ffffff 0%, #f3fff8 48%, #eafff1 100%);
      position:relative;
      overflow-x:hidden;
    }

    /* เงาใยแมงมุม + ค้างคาวบิน */
    .web{
      position:absolute; inset:0; pointer-events:none; overflow:hidden;
    }
    .web:before, .web:after{
      content:""; position:absolute; width:380px; height:380px; opacity:.16;
      background:
        radial-gradient(circle at 50% 50%, transparent 42%, rgba(0,0,0,.35) 43% 44%, transparent 45%),
        radial-gradient(circle at 50% 50%, transparent 58%, rgba(0,0,0,.28) 59% 60%, transparent 61%),
        radial-gradient(circle at 50% 50%, transparent 74%, rgba(0,0,0,.22) 75% 76%, transparent 77%),
        radial-gradient(circle at 50% 50%, transparent 90%, rgba(0,0,0,.18) 91% 92%, transparent 93%);
      filter: drop-shadow(0 12px 28px rgba(0,0,0,.12));
    }
    .web:before{ top:-120px; left:-80px; transform:rotate(12deg) }
    .web:after { top:-100px; right:-60px; transform:rotate(-18deg) }

    .bat{ position:absolute; top:18%; left:-15%; font-size:26px; opacity:.9; animation:batFly 16s linear infinite }
    .bat.b2{ top:48%; animation-delay:3s; animation-duration:18s; font-size:30px }
    .bat.b3{ top:72%; animation-delay:5.5s; animation-duration:17s; font-size:24px }
    @keyframes batFly{
      0%{ transform: translateX(0) translateY(0) scale(1); opacity:0 }
      10%{ opacity:1 }
      50%{ transform: translateX(85vw) translateY(-20px) scale(1.05) }
      100%{ transform: translateX(120vw) translateY(6px) scale(1.07); opacity:0 }
    }

    /* การ์ด/ปุ่ม */
    .card{ background:#fff; border:1px solid #e5e7eb; border-radius:26px; box-shadow:0 20px 46px rgba(2,8,23,.10); overflow:hidden }
    .btn{ display:inline-flex; align-items:center; justify-content:center; gap:.6rem;
      padding:.75rem 1rem; border-radius:12px; background:#111; color:#fff;
      border:1px solid #0f172a; transition:transform .1s ease, box-shadow .2s ease, filter .2s ease }
    .btn:hover{ transform:translateY(-1px); box-shadow:0 12px 26px rgba(0,0,0,.18); filter:brightness(1.02) }
    .btn[disabled]{ opacity:.7; cursor:not-allowed; transform:none; box-shadow:none }

    /* input */
    .input{ width:100%; padding:.75rem .95rem .75rem 2.6rem; border:1px solid #e5e7eb; border-radius:14px; outline:none; transition:border .15s, box-shadow .15s }
    .input:focus{ border-color:#a7f3d0; box-shadow:0 0 0 3px rgba(16,185,129,.18) }
    .input.error{ border-color:#fca5a5; box-shadow:0 0 0 3px rgba(239,68,68,.15) }
    .icon-left{ position:absolute; left:.8rem; top:50%; transform:translateY(-50%) }
    .icon-right{ position:absolute; right:.8rem; top:50%; transform:translateY(-50%); cursor:pointer }

    .help{ font-size:.8rem; color:var(--muted) }
    .help.error{ color:#b91c1c }

    /* Toast/Alert */
    .toast{ position:fixed; right:16px; top:16px; z-index:50; min-width:260px; padding:.8rem 1rem; border-radius:14px; color:#fff;
      box-shadow:0 14px 34px rgba(0,0,0,.22); animation:slideIn .35s ease both }
    .toast-err{ background:#ef4444 }
    .toast-ok{ background:#10b981 }
    @keyframes slideIn{ from{opacity:0; transform:translateY(-10px)} to{opacity:1; transform:none} }
    .alert{ border:1px solid #fecaca; background:#fef2f2; color:#b91c1c; padding:.75rem 1rem; border-radius:12px; display:flex; gap:.6rem }

    /* Pane ดำฝั่งขวาพร้อมฟักทอง */
    .right-pane{ background:linear-gradient(160deg, var(--night) 0%, #111827 100%); color:#e5e7eb; position:relative; overflow:hidden }
    .pump{ position:absolute; bottom:18px; left:20px; font-size:32px; filter:drop-shadow(0 6px 10px rgba(0,0,0,.45)); animation:floatY 3.8s ease-in-out infinite }
    .pump.p2{ left:62px; animation-delay:.18s }
    .pump.p3{ left:104px; animation-delay:.36s }
    @keyframes floatY{ 0%,100%{ transform:translateY(0) } 50%{ transform:translateY(-8px) } }
    .glow{ text-shadow:0 0 14px rgba(255,140,0,.5), 0 0 24px rgba(255,140,0,.35) }

    /* เขย่าเวลา error */
    .shake{ animation:shake .35s ease }
    @keyframes shake{ 10%,90%{transform:translateX(-1px)} 20%,80%{transform:translateX(2px)} 30%,50%,70%{transform:translateX(-4px)} 40%,60%{transform:translateX(4px)} }
  </style>
</head>
<body class="bg-farm flex items-center justify-center">

  <!-- ใยแมงมุม/ค้างคาว บนพื้นหลัง -->
  <div class="web"></div>
  <span class="bat">🦇</span>
  <span class="bat b2">🦇</span>
  <span class="bat b3">🦇</span>

  <!-- Toast จากฝั่งเซิร์ฟเวอร์ -->
  <c:if test="${not empty error}">
    <div class="toast toast-err">⚠️ ${error}</div>
  </c:if>
  <c:if test="${not empty param.error}">
    <div class="toast toast-err">⚠️ อีเมลหรือรหัสผ่านไม่ถูกต้อง</div>
  </c:if>
  <c:if test="${not empty msg}">
    <div class="toast toast-ok">✅ ${msg}</div>
  </c:if>

  <!-- กล่องหลัก -->
  <div class="w-full max-w-5xl card grid grid-cols-1 md:grid-cols-2 border border-gray-200 mx-4">
    <!-- ซ้าย: Form -->
    <div class="p-8 md:p-10">
      <div class="flex items-center justify-between mb-2">
        <h1 class="text-3xl font-extrabold text-[color:var(--ink)]">สวัสดี 👋</h1>
        <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[color:var(--ink)] text-white text-xs">
          🎃 ฮาโลวีน
        </span>
      </div>
      <p class="text-sm text-[color:var(--muted)] mb-6">กรุณาเข้าสู่ระบบเพื่อใช้งานระบบเกษตรชุมชน</p>

      <c:if test="${not empty error}">
        <div id="serverAlert" class="alert mb-4">
          <span>❗</span>
          <div>
            <div class="font-semibold">ไม่สามารถเข้าสู่ระบบได้</div>
            <div class="text-sm">${error}</div>
          </div>
        </div>
      </c:if>

      <form id="loginForm" action="${ctx}/login" method="post" class="space-y-5" novalidate>
        <!-- Email -->
        <div class="relative">
          <span class="icon-left text-[color:var(--emerald600)]">📧</span>
          <input id="email" name="email" type="text" autocomplete="username"
                 placeholder="อีเมลของคุณ (ห้ามพิมพ์ภาษาไทย)" class="input"
                 aria-describedby="emailHelp" aria-invalid="false"/>
          <small id="emailHelp" class="help mt-1 block"></small>
        </div>

        <!-- Password -->
        <div class="relative">
          <span class="icon-left text-[color:var(--emerald600)]">🔒</span>
          <input id="password" name="password" type="password" autocomplete="current-password"
                 placeholder="รหัสผ่าน" class="input pr-10" aria-describedby="capsWarn"/>
          <span id="togglePass" class="icon-right text-gray-400 select-none" title="แสดง/ซ่อนรหัสผ่าน">👁️</span>
          <small id="capsWarn" class="help hidden text-amber-600">⚠️ Caps Lock เปิดอยู่</small>
        </div>

        <div class="flex items-center justify-between text-sm text-[color:var(--muted)]">
          <label class="select-none">
            <input type="checkbox" name="remember" class="mr-1"> จำฉันไว้
          </label>
         
        </div>

        <button id="btnLogin" type="submit" class="btn w-full">
          <span id="btnIcon">🔑</span><span id="btnText">เข้าสู่ระบบ</span>
        </button>
      </form>

       <p class="text-center text-sm text-gray-500">
    ยังไม่มีบัญชี? <a href="${ctx}/register" class="font-semibold hover:underline">สมัครสมาชิก</a>
  </p>
  
    </div>

    <!-- ขวา: พื้นหลังดำ + ฟักทอง -->
    <div class="right-pane p-10 flex flex-col items-center justify-center text-center">
      <div class="text-5xl mb-3 glow">🎃</div>
      <h2 class="text-2xl font-semibold mb-2">ยินดีต้อนรับสู่ระบบเกษตรชุมชน</h2>
      <p class="text-sm text-gray-300 leading-relaxed">
        แพลตฟอร์มสำหรับเกษตรกรและผู้สนใจสินค้าเกษตร<br/>เพื่อการสั่งจองสินค้าแบบ Pre-order อย่างง่ายดาย
      </p>
      <!-- กลุ่มฟักทองมุมซ้ายล่าง -->
      <span class="pump">🎃</span>
      <span class="pump p2">🎃</span>
      <span class="pump p3">🎃</span>
    </div>
  </div>

  <script>
    const emailEl = document.getElementById('email');
    const passEl  = document.getElementById('password');
    const emailHelp = document.getElementById('emailHelp');
    const capsWarn  = document.getElementById('capsWarn');
    const form   = document.getElementById('loginForm');
    const btn    = document.getElementById('btnLogin');
    const btnIcon= document.getElementById('btnIcon');
    const btnText= document.getElementById('btnText');
    const togglePass = document.getElementById('togglePass');

    // ตรวจอักษรไทย
    function hasThai(str){ return /[\u0E00-\u0E7F]/.test(str); }
    // ตรวจรูปแบบอีเมล (เบาๆ แต่พอ)
    function isValidEmail(str){
      // ไม่มีเว้นวรรค, ต้องมี '@' และจุด, โดเมนท้ายอย่างน้อย 2 ตัว
      return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(str);
    }
    // helper set error state
    function setEmailError(msg){
      emailEl.classList.toggle('error', !!msg);
      emailEl.setAttribute('aria-invalid', !!msg);
      emailHelp.textContent = msg || '';
      emailHelp.classList.toggle('error', !!msg);
    }

    // live validate
    emailEl.addEventListener('input', ()=>{
      const v = (emailEl.value || '').trim();
      if(!v){
        setEmailError('');
        return;
      }
      if(hasThai(v)){
        setEmailError('ห้ามพิมพ์ภาษาไทยในอีเมล');
        return;
      }
      if(!isValidEmail(v)){
        // ถ้าพิมพ์ “กกกกก” หรือข้อความที่ไม่ใช่อีเมล
        setEmailError('รูปแบบอีเมลไม่ถูกต้อง');
        return;
      }
      setEmailError('');
    });

    // CapsLock
    passEl.addEventListener('keyup', e=>{
      const on = e.getModifierState && e.getModifierState('CapsLock');
      capsWarn.classList.toggle('hidden', !on);
    });

    // show/hide password
    togglePass.addEventListener('click', ()=>{
      passEl.type = passEl.type === 'password' ? 'text' : 'password';
    });

    // Submit
    form.addEventListener('submit', (e)=>{
      const email = (emailEl.value || '').trim();

      // ตรวจอีเมลอีกชั้น
      if(!email){
        setEmailError('กรุณากรอกอีเมล');
      }else if(hasThai(email)){
        setEmailError('ห้ามพิมพ์ภาษาไทยในอีเมล');
      }else if(!isValidEmail(email)){
        setEmailError('รูปแบบอีเมลไม่ถูกต้อง');
      }else{
        setEmailError('');
      }

      // ถ้ามี error ไม่ให้ส่ง
      if(emailHelp.textContent){
        e.preventDefault();
        form.classList.add('shake');
        setTimeout(()=>form.classList.remove('shake'), 420);
        return;
      }

      // ล็อก UI
      btn.setAttribute('disabled', 'disabled');
      btnIcon.textContent = '⏳';
      btnText.textContent = 'กำลังเข้าสู่ระบบ...';
    });
  </script>
</body>
</html>
