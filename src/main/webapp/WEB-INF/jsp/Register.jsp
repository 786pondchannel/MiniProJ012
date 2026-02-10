<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>

<c:if test="${empty ctx}">
  <c:set var="ctx" value="${pageContext.request.contextPath}"/>
</c:if>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>สมัครสมาชิก • เกษตรกรบ้านเรา</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600;700;800&display=swap"/>

  <style>
    html,body{font-family:'Prompt',system-ui;-webkit-font-smoothing:antialiased}
    .card{border:1px solid rgba(255,255,255,.08)}
    .input{width:100%;padding:.75rem;border-radius:.75rem;border:1px solid #e5e7eb;outline:none;transition:box-shadow .15s,border-color .15s,background-color .15s}
    .input:focus{box-shadow:0 0 0 2px #22c55e55;border-color:#22c55e}
    .invalid{border-color:#ef4444!important;background:#fff1f2;box-shadow:0 0 0 2px rgba(239,68,68,.25)}
    .err-msg{margin-top:.375rem;font-size:.875rem;color:#b91c1c}
    .err-alert{border:1px solid #fecaca;background:#fef2f2;color:#991b1b}
    .err-badge{display:inline-flex;align-items:center;gap:.5rem;font-weight:700}

    /* BG + Halloween bits */
    body.halloween{background:radial-gradient(1200px 600px at 10% 10%,#f0fff4 0%,#d1fae5 30%,#0f172a 100%)}
    .web-overlay::before{content:"";position:fixed;inset:0;pointer-events:none;background-image:
      repeating-radial-gradient(circle at 10% 10%,rgba(255,255,255,.06) 0 1px,transparent 1px 80px),
      repeating-radial-gradient(circle at 90% 20%,rgba(255,255,255,.04) 0 1px,transparent 1px 70px)}
    @keyframes fly{from{transform:translateX(0) translateY(0) rotate(0deg);opacity:.8}50%{transform:translateX(20px) translateY(-10px) rotate(-8deg)}to{transform:translateX(0) translateY(0) rotate(0deg)}}
    .bat{position:fixed;font-size:28px;opacity:.6;animation:fly 4s ease-in-out infinite}
    .bat.b2{left:20%;top:12%;animation-duration:5.2s}
    .bat.b3{right:12%;top:18%;animation-duration:3.8s}

    /* Success Modal + Confetti */
    .modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;z-index:60}
    .modal-card{width:min(560px,92vw);border-radius:1.25rem;background:#0b0b0b;color:#fff;box-shadow:0 20px 50px rgba(0,0,0,.45);position:relative;overflow:hidden}
    .modal-glow{position:absolute;inset:-40%;background:radial-gradient(600px 300px at 50% 0,#22c55e55,transparent 60%);filter:blur(20px);pointer-events:none}
    .confetti-wrap{position:absolute;inset:0;overflow:hidden;pointer-events:none}
    .confetti{position:absolute;width:8px;height:14px;opacity:.9;border-radius:2px}
    @keyframes confFall{0%{transform:translateY(-40vh) rotate(0)}100%{transform:translateY(60vh) rotate(720deg)}}
    @keyframes popIn{0%{transform:scale(.6);opacity:0}60%{transform:scale(1.05);opacity:1}100%{transform:scale(1)}}

    /* Busy overlay */
    .busy{position:fixed;inset:0;z-index:40;background:rgba(15,23,42,.55);display:flex;align-items:center;justify-content:center}
    .spinner{width:52px;height:52px;border:6px solid #fff;border-right-color:transparent;border-radius:50%;animation:spin .9s linear infinite}
    @keyframes spin{to{transform:rotate(360deg)}}
  </style>

  <script>
    // ======= CONFIG =======
    var REDIRECT_DELAY = 5000; // ms (แก้เวลาตรงนี้)

    // ปิด tooltip validation ของ browser
    document.addEventListener('invalid', function(e){ e.preventDefault(); }, true);

    function toggleFarmerForm(){
      var userForm=document.getElementById('userForm');
      var farmerForm=document.getElementById('farmerForm');
      var modeLabel=document.getElementById('modeLabel');
      userForm.classList.toggle('hidden');
      farmerForm.classList.toggle('hidden');
      modeLabel.textContent=userForm.classList.contains('hidden')?'สมัครสมาชิก (เกษตรกร)':'สมัครสมาชิก (ผู้ใช้ทั่วไป)';
      clearClientErrors(userForm); clearClientErrors(farmerForm);
      var sum=document.getElementById('clientErrorSummary'); if(sum) sum.classList.add('hidden');
    }
    function clearClientErrors(form){
      if(!form) return;
      var inputs=form.querySelectorAll('.input'); for(var i=0;i<inputs.length;i++) inputs[i].classList.remove('invalid');
      var msgs=form.querySelectorAll('.client-err'); for(var j=0;j<msgs.length;j++){ msgs[j].textContent=''; msgs[j].classList.add('hidden'); }
    }
    function markInvalid(input,msg){
      input.classList.add('invalid');
      var holder=input.closest('div'); if(!holder) return;
      var slot=holder.querySelector('[data-error-for="'+input.name+'"]');
      if(slot){ slot.textContent=msg; slot.classList.remove('hidden'); }
    }
    function escapeHtml(s){ if(s==null) return ''; return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/\"/g,'&quot;').replace(/'/g,'&#39;'); }

    // ======= CLIENT VALIDATION =======
    function validateForms(e){
      var form=e.target; clearClientErrors(form);

      var pwd=form.querySelector('input[name="password"]');
      var conf=form.querySelector('input[name="confirmPassword"]');
      var phone=form.querySelector('input[name="phoneNumber"]');
      var email=form.querySelector('input[name="email"]');
      var address=form.querySelector('input[name="address"]');
      var farmLoc=form.querySelector('input[name="farmLocation"]'); // เฉพาะเกษตรกร

      var errs=[];

      // อีเมล
      if(email){
        var em=email.value.trim();
        if(!em){ markInvalid(email,'กรุณากรอกอีเมล'); errs.push('กรุณากรอกอีเมล'); }
        else if (/[\u0E00-\u0E7F]/.test(em)) { markInvalid(email,'ห้ามใช้อักษรไทยในอีเมล'); errs.push('อีเมลห้ามมีอักษรไทย'); }
        else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em)) { markInvalid(email,'รูปแบบอีเมลไม่ถูกต้อง'); errs.push('อีเมลไม่ถูกต้อง'); }
      }

      // เบอร์
      if (phone) {
        phone.value = phone.value.replace(/\D/g,'');
        if (!/^0[0-9]{9}$/.test(phone.value)) {
          markInvalid(phone,'เบอร์โทรศัพท์ต้อง 10 หลักและขึ้นต้นด้วย 0');
          errs.push('เบอร์โทรศัพท์ไม่ถูกต้อง');
        }
      }

      // ที่อยู่ (ทุกฟอร์ม)
      if (address) {
        var ad = address.value.trim();
        if (!ad) { markInvalid(address,'กรุณากรอกที่อยู่'); errs.push('กรุณากรอกที่อยู่'); }
        else if (ad.length < 5) { markInvalid(address,'ที่อยู่สั้นเกินไป อย่างน้อย 10 ตัวอักษร'); errs.push('ที่อยู่สั้นเกินไป  อย่างน้อย 10 ตัวอักษร '); }
      }

      // ที่ตั้งฟาร์ม (เฉพาะฟอร์มเกษตรกร)
      if (farmLoc) {
        var fl = farmLoc.value.trim();
        if (!fl) { markInvalid(farmLoc,'กรุณากรอกที่ตั้งฟาร์ม'); errs.push('กรุณากรอกที่ตั้งฟาร์ม'); }
        else if (fl.length < 3) { markInvalid(farmLoc,'ที่ตั้งฟาร์มสั้นเกินไป'); errs.push('ที่ตั้งฟาร์มสั้นเกินไป'); }
      }

      // รหัสผ่าน
      if (pwd && pwd.value.length < 8) {
        markInvalid(pwd,'รหัสผ่านอย่างน้อย 8 ตัวอักษร'); errs.push('รหัสผ่านสั้นเกินไป');
      }
      if (conf && pwd && conf.value !== pwd.value) {
        markInvalid(conf,'ยืนยันรหัสผ่านไม่ตรงกัน'); errs.push('ยืนยันรหัสผ่านไม่ตรงกัน');
      }

      // สรุปด้านบน
      var sum=document.getElementById('clientErrorSummary');
      if (errs.length) {
        var items = errs.map(function(t){ return '<li>'+escapeHtml(t)+'</li>'; }).join('');
        sum.innerHTML = '<div class="err-badge"><span>❌</span><span>กรุณาแก้ไขข้อผิดพลาดต่อไปนี้</span></div>'
                      + '<ul class="mt-2 list-disc pl-6 text-sm">'+items+'</ul>';
        sum.classList.remove('hidden');
        e.preventDefault(); return false;
      }
      sum.classList.add('hidden');

      // แสดง Busy overlay ระหว่างโพสต์
      var busy=document.getElementById('busy'); if(busy) busy.classList.remove('hidden');
      return true;
    }

    // ======= CONFETTI =======
    function launchConfetti(container){
      if(!container) return;
      var colors=['#22c55e','#10b981','#a3e635','#fde047','#fb923c','#f43f5e','#60a5fa','#a78bfa'];
      for(var i=0;i<120;i++){
        var c=document.createElement('span');
        c.className='confetti';
        c.style.left=(Math.random()*100)+'%';
        c.style.top=('-'+(Math.random()*30+10)+'vh');
        c.style.backgroundColor=colors[Math.floor(Math.random()*colors.length)];
        c.style.transform='rotate('+ (Math.random()*360) +'deg)';
        c.style.animation='confFall '+(1.8+Math.random()*1.2)+'s ease-out forwards';
        c.style.animationDelay=(Math.random()*0.4)+'s';
        c.style.width=(6+Math.random()*6)+'px';
        c.style.height=(10+Math.random()*14)+'px';
        container.appendChild(c);
      }
    }

    // ======= BOOT =======
    document.addEventListener('DOMContentLoaded',function(){
      // bind validation + input handlers
      ['userForm','farmerForm'].forEach(function(id){
        var f=document.getElementById(id);
        if(f){
          f.addEventListener('submit',validateForms);
          var all=f.querySelectorAll('.input');
          for(var i=0;i<all.length;i++){
            all[i].addEventListener('input',function(ev){
              var el=ev.target; el.classList.remove('invalid');
              var slot=f.querySelector('[data-error-for="'+el.name+'"]');
              if(slot){ slot.textContent=''; slot.classList.add('hidden'); }
              if (el.name==='phoneNumber') { el.value = el.value.replace(/\D/g,''); }
            });
          }
        }
      });

      // toggle by query
      var isFarmer=new URLSearchParams(location.search).get('status')==='FARMER';
      if(isFarmer){
        var u=document.getElementById('userForm'); var ff=document.getElementById('farmerForm');
        if(ff.classList.contains('hidden')){ u.classList.add('hidden'); ff.classList.remove('hidden'); }
        document.getElementById('modeLabel').textContent='สมัครสมาชิก (เกษตรกร)';
      }

      // เปิด modal สำเร็จ + redirect
      var modal=document.getElementById('successModal');
      if(modal){
        var wrap=modal.querySelector('.confetti-wrap');
        launchConfetti(wrap);
        var base=document.body.getAttribute('data-ctx')||'';
        setTimeout(function(){ window.location.href = base + '/login'; }, REDIRECT_DELAY);
      }
    });
  </script>
</head>

<body class="halloween web-overlay font-sans" data-ctx="${ctx}">
  <!-- เตรียมค่า flashSuccess: รองรับทั้ง request scope และ session -->
  <c:set var="flashSuccess" value="${not empty requestScope.flash_success ? requestScope.flash_success : sessionScope.flash_success}"/>

  <!-- Success Modal -->
  <c:if test="${not empty flashSuccess}">
    <div id="successModal" class="modal-overlay">
      <div class="modal-card animate-[popIn_.5s_ease]">
        <div class="modal-glow"></div>
        <div class="confetti-wrap"></div>
        <div class="p-8 md:p-10 relative z-10 text-center">
          <div class="text-5xl mb-4">🎉</div>
          <h3 class="text-2xl md:text-3xl font-extrabold mb-2">ยินดีด้วย! สมัครสมาชิกสำเร็จ</h3>
          <p class="text-white/80 text-sm md:text-base">
            กำลังพาคุณไปยังหน้า <span class="font-semibold">เข้าสู่ระบบ</span> ภายใน 5 วินาที<br/>
            เพลิดเพลินกับเอฟเฟกต์ฉลองสั้น ๆ ก่อนนะ ✨
          </p>
          <div class="mt-6">
            <a href="${ctx}/login" class="inline-block px-5 py-3 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold">ไปหน้าเข้าสู่ระบบทันที</a>
          </div>
        </div>
      </div>
    </div>
    <!-- ล้างค่าใน session ถ้ามี -->
    <c:if test="${not empty sessionScope.flash_success}">
      <c:remove var="flash_success" scope="session"/>
    </c:if>
  </c:if>

  <!-- Busy overlay ระหว่างโพสต์ -->
  <div id="busy" class="busy hidden">
    <div class="bg-white/90 text-slate-800 px-6 py-5 rounded-2xl shadow-2xl flex items-center gap-4">
      <div class="spinner"></div>
      <div class="font-semibold">กำลังบันทึกข้อมูลของคุณ…</div>
    </div>
  </div>

  <div class="bat">🦇</div><div class="bat b2">🦇</div><div class="bat b3">🦇</div>

  <!-- WRAPPER: การ์ดกลางหน้าจอเสมอ -->
  <div class="min-h-[100svh] min-h-screen flex flex-col">
    <main class="flex-1 grid place-items-center px-4 py-10">
      <div class="w-full max-w-5xl rounded-3xl shadow-2xl overflow-hidden card grid grid-cols-1 md:grid-cols-2 bg-white/95 backdrop-blur">

        <!-- ซ้าย: ฟอร์มสมัคร -->
        <section class="p-8 md:p-10">
          <h2 id="modeLabel" class="text-3xl font-extrabold text-gray-900 mb-6 text-center">สมัครสมาชิก (ผู้ใช้ทั่วไป)</h2>

          <!-- สรุป error จาก server -->
          <c:set var="errors"      value="${requestScope.errors != null ? requestScope.errors : sessionScope.flash_errors}"/>
          <c:set var="error"       value="${empty requestScope.error ? (empty sessionScope.flash_error ? param.error : sessionScope.flash_error) : requestScope.error}"/>
          <c:set var="fieldErrors" value="${requestScope.fieldErrors != null ? requestScope.fieldErrors : sessionScope.flash_fieldErrors}"/>

          <c:if test="${not empty error || not empty errors || not empty fieldErrors}">
            <div class="mb-6 rounded-xl p-4 err-alert" role="alert" aria-live="assertive">
              <div class="err-badge"><span>❌</span><span>ตรวจพบข้อผิดพลาด</span></div>
              <div class="text-sm mt-2">
                <ul class="list-disc pl-5 space-y-1">
                  <c:if test="${not empty errors}">
                    <c:forEach var="e" items="${errors}"><li>${fn:escapeXml(e)}</li></c:forEach>
                  </c:if>
                  <c:if test="${not empty fieldErrors}">
                    <c:forEach var="fe" items="${fieldErrors}"><li><strong>${fe.key}:</strong> ${fn:escapeXml(fe.value)}</li></c:forEach>
                  </c:if>
                  <c:if test="${empty errors && empty fieldErrors && not empty error}">
                    <li>${fn:escapeXml(error)}</li>
                  </c:if>
                </ul>
              </div>
            </div>
            <c:remove var="flash_error" scope="session"/>
            <c:remove var="flash_errors" scope="session"/>
            <c:remove var="flash_fieldErrors" scope="session"/>
          </c:if>

          <!-- Client summary -->
          <div id="clientErrorSummary" class="hidden mb-6 rounded-xl p-4 err-alert" role="alert" aria-live="assertive"></div>

          <c:set var="isFarmer" value="${param.status == 'FARMER' or requestScope.mode == 'FARMER'}"/>
          <c:choose>
            <c:when test="${isFarmer}"><c:set var="userHidden" value="hidden"/><c:set var="farmerHidden" value=""/></c:when>
            <c:otherwise><c:set var="userHidden" value=""/><c:set var="farmerHidden" value="hidden"/></c:otherwise>
          </c:choose>

          <!-- ผู้ใช้ทั่วไป -->
          <form id="userForm" action="${ctx}/registerUser" method="post" novalidate class="space-y-5 ${userHidden}">
            <input type="hidden" name="status" value="MEMBER"/>

            <div>
              <input name="fullname" class="input${not empty fieldErrors['fullname'] ? ' invalid' : ''}" placeholder="ชื่อ-นามสกุล" type="text" required value="${fn:escapeXml(param.fullname)}"/>
              <c:if test="${not empty fieldErrors['fullname']}"><p class="err-msg">${fieldErrors['fullname']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="fullname"></p>
            </div>

            <div>
              <input name="phoneNumber" class="input${not empty fieldErrors['phoneNumber'] ? ' invalid' : ''}" placeholder="เบอร์โทรศัพท์" type="tel" required pattern="^0[0-9]{9}$" inputmode="numeric" value="${fn:escapeXml(param.phoneNumber)}"/>
              <c:if test="${not empty fieldErrors['phoneNumber']}"><p class="err-msg">${fieldErrors['phoneNumber']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="phoneNumber"></p>
            </div>

            <div>
              <input name="email" class="input${not empty fieldErrors['email'] ? ' invalid' : ''}" placeholder="อีเมลของคุณ (ห้ามพิมพ์ภาษาไทย)" type="email" inputmode="email" autocomplete="email" required value="${fn:escapeXml(param.email)}"/>
              <c:if test="${not empty fieldErrors['email']}"><p class="err-msg">${fieldErrors['email']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="email"></p>
            </div>

            <div>
              <input name="address" class="input${not empty fieldErrors['address'] ? ' invalid' : ''}" placeholder="ที่อยู่" type="text" required value="${fn:escapeXml(param.address)}"/>
              <c:if test="${not empty fieldErrors['address']}"><p class="err-msg">${fieldErrors['address']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="address"></p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <input name="password" class="input${not empty fieldErrors['password'] ? ' invalid' : ''}" placeholder="รหัสผ่าน (อย่างน้อย 8 ตัวอักษร)" type="password" required minlength="8"/>
                <c:if test="${not empty fieldErrors['password']}"><p class="err-msg">${fieldErrors['password']}</p></c:if>
                <p class="client-err err-msg hidden" data-error-for="password"></p>
              </div>
              <div>
                <input name="confirmPassword" class="input" placeholder="ยืนยันรหัสผ่าน" type="password" required/>
                <p class="client-err err-msg hidden" data-error-for="confirmPassword"></p>
              </div>
            </div>

            <button type="submit" class="w-full p-3 rounded-lg bg-emerald-600 text-white font-bold hover:bg-emerald-700 transition">สมัครสมาชิก</button>
            <button type="button" class="w-full p-3 rounded-lg bg-indigo-600 text-white font-bold hover:bg-indigo-700 transition" onclick="toggleFarmerForm()">สมัครเป็นเกษตรกร</button>
          </form>

          <!-- เกษตรกร -->
          <form id="farmerForm" action="${ctx}/registerFarmer" method="post" novalidate class="space-y-5 ${farmerHidden}">
            <input type="hidden" name="status" value="FARMER"/>

            <div>
              <input name="farmName" class="input${not empty fieldErrors['farmName'] ? ' invalid' : ''}" placeholder="ชื่อฟาร์ม" type="text" required value="${fn:escapeXml(param.farmName)}"/>
              <c:if test="${not empty fieldErrors['farmName']}"><p class="err-msg">${fieldErrors['farmName']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="farmName"></p>
            </div>

            <div>
              <input name="fullname" class="input${not empty fieldErrors['fullname'] ? ' invalid' : ''}" placeholder="ชื่อ-นามสกุล" type="text" required value="${fn:escapeXml(param.fullname)}"/>
              <c:if test="${not empty fieldErrors['fullname']}"><p class="err-msg">${fieldErrors['fullname']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="fullname"></p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <input name="email" class="input${not empty fieldErrors['email'] ? ' invalid' : ''}" placeholder="อีเมลของคุณ (ห้ามพิมพ์ภาษาไทย)" type="email" inputmode="email" autocomplete="email" required value="${fn:escapeXml(param.email)}"/>
                <c:if test="${not empty fieldErrors['email']}"><p class="err-msg">${fieldErrors['email']}</p></c:if>
                <p class="client-err err-msg hidden" data-error-for="email"></p>
              </div>
              <div>
                <input name="phoneNumber" class="input${not empty fieldErrors['phoneNumber'] ? ' invalid' : ''}" placeholder="เบอร์โทรศัพท์" type="tel" required pattern="^0[0-9]{9}$" inputmode="numeric" value="${fn:escapeXml(param.phoneNumber)}"/>
                <c:if test="${not empty fieldErrors['phoneNumber']}"><p class="err-msg">${fieldErrors['phoneNumber']}</p></c:if>
                <p class="client-err err-msg hidden" data-error-for="phoneNumber"></p>
              </div>
            </div>

            <div>
              <input name="address" class="input${not empty fieldErrors['address'] ? ' invalid' : ''}" placeholder="ที่อยู่" type="text" required value="${fn:escapeXml(param.address)}"/>
              <c:if test="${not empty fieldErrors['address']}"><p class="err-msg">${fieldErrors['address']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="address"></p>
            </div>

            <div>
              <input name="farmLocation" class="input${not empty fieldErrors['farmLocation'] ? ' invalid' : ''}" placeholder="ที่ตั้งฟาร์ม" type="text" required value="${fn:escapeXml(param.farmLocation)}"/>
              <c:if test="${not empty fieldErrors['farmLocation']}"><p class="err-msg">${fieldErrors['farmLocation']}</p></c:if>
              <p class="client-err err-msg hidden" data-error-for="farmLocation"></p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <input name="password" class="input${not empty fieldErrors['password'] ? ' invalid' : ''}" placeholder="รหัสผ่าน (อย่างน้อย 8 ตัวอักษร)" type="password" required minlength="8"/>
                <c:if test="${not empty fieldErrors['password']}"><p class="err-msg">${fieldErrors['password']}</p></c:if>
                <p class="client-err err-msg hidden" data-error-for="password"></p>
              </div>
              <div>
                <input name="confirmPassword" class="input" placeholder="ยืนยันรหัสผ่าน" type="password" required/>
                <p class="client-err err-msg hidden" data-error-for="confirmPassword"></p>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <button type="submit" class="p-3 rounded-lg bg-emerald-600 text-white font-bold hover:bg-emerald-700 transition">สมัครสมาชิก (เกษตรกร)</button>
              <button type="button" class="p-3 rounded-lg bg-gray-600 text-white font-bold hover:bg-gray-700 transition" onclick="toggleFarmerForm()">ย้อนกลับ</button>
            </div>
          </form>
        </section>

        <!-- ขวา -->
        <aside class="bg-[#0b0b0b] text-white p-10 flex flex-col justify-center items-center text-center">
          <div class="text-6xl mb-4">🎃</div>
          <h2 class="text-2xl font-semibold mb-4">ยินดีต้อนรับสู่ระบบเกษตรชุมชน</h2>
          <p class="text-sm text-gray-300 leading-relaxed">
            แพลตฟอร์มสำหรับเกษตรกรและผู้สนใจสินค้าเกษตร<br/>
            เพื่อการสั่งจองสินค้าแบบ Pre-order อย่างง่ายดาย
          </p>
          <p class="mt-6 text-sm text-gray-400">
            มีบัญชีอยู่แล้ว? <a href="${ctx}/login" class="underline">เข้าสู่ระบบ</a>
          </p>
        </aside>
      </div>
    </main>

    <footer class="mt-0 pb-10 text-center text-sm text-white/80">
      <div>© เกษตรกรบ้านเรา • โทนฮาโลวีน</div>
      <a href="https://www.blacklistseller.com/" target="_blank" rel="noopener" class="fixed right-4 bottom-4 px-4 py-2 rounded-full shadow-lg bg-white/90 backdrop-blur border border-gray-200 hover:bg-white">🔎 ตรวจเว็บ/บัญชีคนโกง</a>
    </footer>
  </div>
</body>
</html>
