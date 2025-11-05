<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<fmt:setLocale value="th_TH"/>

<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>คำสั่งซื้อของร้าน</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    *{ font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', 'Liberation Sans', sans-serif }
    body{ background:#f8fafc }
    .card{ border:1px solid #e5e7eb; border-radius:16px; background:#fff; padding:16px; box-shadow:0 10px 26px rgba(0,0,0,.06) }
    .chip{ border-radius:9999px; padding:.25rem .6rem; font-weight:700; font-size:.8rem; display:inline-flex; align-items:center }
  </style>
</head>
<body class="text-slate-800">

<c:if test="${empty ctx}">
  <c:set var="ctx" value="${pageContext.request.contextPath}"/>
</c:if>

<header class="bg-black text-white">
  <div class="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
    <h1 class="text-xl font-bold">คำสั่งซื้อของร้าน</h1>
    <nav class="flex items-center gap-3 text-sm">
      <a href="${ctx}/main" class="hover:underline">หน้าหลัก</a>
      <a href="${ctx}/farmer/profile" class="hover:underline">โปรไฟล์ร้าน</a>
      <a href="${ctx}/logout" class="chip bg-white/10">ออกจากระบบ</a>
    </nav>
  </div>
</header>

<main class="max-w-6xl mx-auto px-4 py-6 space-y-6">

  <!-- debug เล็ก ๆ ถ้าต้องการ ลองเปิดด้วย ?debug=1 -->
  <c:if test="${param.debug == '1'}">
    <div class="card text-xs text-gray-600">
      DEBUG — orders size: <c:out value="${empty orders ? 0 : fn:length(orders)}"/>
    </div>
  </c:if>

  <section class="card">
    <div class="flex items-end justify-between">
      <div>
        <div class="text-xs text-gray-500">ออเดอร์ทั้งหมด</div>
        <h2 class="text-lg font-bold">คำสั่งซื้อ</h2>
      </div>
      <c:if test="${not empty orders}">
        <div class="text-sm text-gray-600">
          ทั้งหมด <span class="font-semibold"><c:out value="${fn:length(orders)}"/></span> รายการ
        </div>
      </c:if>
    </div>

    <c:choose>
      <c:when test="${empty orders}">
        <div class="py-10 text-center text-gray-500">ยังไม่มีคำสั่งซื้อ</div>
      </c:when>
      <c:otherwise>
        <div class="mt-4 overflow-x-auto">
          <table class="min-w-full border-separate" style="border-spacing:0">
            <thead>
              <tr class="text-left text-sm text-gray-600">
                <th class="py-2 px-3">รหัสออเดอร์</th>
                <th class="py-2 px-3">วันที่</th>
                <th class="py-2 px-3">ลูกค้า</th>
                <th class="py-2 px-3">จำนวนสินค้า</th>
                <th class="py-2 px-3">ยอดรวม</th>
                <th class="py-2 px-3">สถานะ</th>
                <th class="py-2 px-3"></th>
              </tr>
            </thead>
            <tbody class="text-sm">
              <c:forEach var="o" items="${orders}">
                <tr class="border-t">
                  <td class="py-2 px-3 font-mono">
                    <c:out value="${o.orderId}"/>
                  </td>
                  <td class="py-2 px-3">
                    <c:choose>
                      <c:when test="${not empty o.orderDate}">
                        <fmt:formatDate value="${o.orderDate}" pattern="dd/MM/yyyy HH:mm"/>
                      </c:when>
                      <c:otherwise>-</c:otherwise>
                    </c:choose>
                  </td>
                  <td class="py-2 px-3">
                    <c:out value="${empty o.customerName ? (empty o.memberId ? '-' : o.memberId) : o.customerName}"/>
                  </td>
                  <td class="py-2 px-3">
                    <c:out value="${empty o.itemsCount ? (empty o.quantity ? 0 : o.quantity) : o.itemsCount}"/>
                  </td>
                  <td class="py-2 px-3 font-semibold text-emerald-700">
                    <c:choose>
                      <c:when test="${not empty o.total}">
                        <fmt:formatNumber value="${o.total}" type="currency" currencySymbol="฿" maxFractionDigits="2"/>
                      </c:when>
                      <c:otherwise>฿0</c:otherwise>
                    </c:choose>
                  </td>
                  <td class="py-2 px-3">
                    <c:set var="st" value="${fn:toUpperCase(empty o.status ? '' : o.status)}"/>
                    <c:choose>
                      <c:when test="${st=='PAID' || st=='COMPLETED' || st=='SUCCESS'}">
                        <span class="chip bg-emerald-100 text-emerald-800">ชำระแล้ว</span>
                      </c:when>
                      <c:when test="${st=='CANCEL' || st=='CANCELED' || st=='CANCELLED'}">
                        <span class="chip bg-rose-100 text-rose-800">ยกเลิก</span>
                      </c:when>
                      <c:otherwise>
                        <span class="chip bg-amber-100 text-amber-800">
                          <c:out value="${empty o.status ? 'รอดำเนินการ' : o.status}"/>
                        </span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td class="py-2 px-3">
                    <c:if test="${not empty o.orderId}">
                      <a href="${ctx}/farmer/orders/${o.orderId}"
                         class="px-3 py-1 rounded-lg bg-emerald-600 text-white text-sm hover:bg-emerald-700">ดูรายละเอียด</a>
                    </c:if>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </c:otherwise>
    </c:choose>
  </section>
</main>

<%-- ================= Footer ================= --%>
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
</body>
</html>
