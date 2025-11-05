// src/main/java/com/springmvc/controller/FarmerOrderController.java
package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.FarmerOrdersService;
import com.springmvc.service.FarmerOrdersService.OrderHeader;
import com.springmvc.service.FarmerOrdersService.DeleteResult;
import com.springmvc.service.OrderService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Collections;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/farmer/orders")
public class FarmerOrderController {

    @Autowired
    private FarmerOrdersService ordersService;

    @Autowired
    private OrderService orderService; // ใช้ตอนยืนยันชำระเงิน

    /* ===== ต้องเป็น FARMER เท่านั้น ===== */
    private Member requireFarmer(HttpSession session) {
        Object u = session.getAttribute("loggedInUser");
        if (u instanceof Member m && "FARMER".equalsIgnoreCase(m.getStatus())) {
            return m;
        }
        return null;
    }

    /* ===== หน้า "รายการออเดอร์" =====
       คืนค่า view = "FarmerOrders" ให้ตรงกับไฟล์ /WEB-INF/views/FarmerOrders.jsp
    */
    @GetMapping
    public String list(HttpServletRequest req,
                       HttpSession session,
                       @RequestParam(value = "q", required = false) String q,
                       @RequestParam(value = "status", required = false) String status,
                       @RequestParam(value = "pay", required = false) String pay,
                       Model model) {

        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";

        List<Object[]> rows = ordersService.listOrders(cur.getMemberId(), q, status, pay);

        model.addAttribute("orders", rows);
        model.addAttribute("q", q);
        model.addAttribute("status", status);
        model.addAttribute("pay", pay);
        model.addAttribute("ctx", req.getContextPath()); // เผื่อ JSP ใช้สร้างลิงก์

        return "ListFarmerOrders";
    }

    /* ===== หน้า "รายละเอียดออเดอร์" =====
       ปล่อยชื่อวิวตามไฟล์ที่คุณมี เช่น FarmerOrderDetail.jsp
    */
    @GetMapping("/{orderId}")
    public String detail(@PathVariable("orderId") String orderId,
                         HttpServletRequest req,
                         HttpSession session,
                         Model model) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";
        String fid = cur.getMemberId();

        OrderHeader header = ordersService.getOrderHeader(fid, orderId);
        var items    = (header == null) ? Collections.emptyList()
                                        : ordersService.getOrderItems(fid, orderId);
        var receipts = (header == null) ? Collections.<FarmerOrdersService.ReceiptInfo>emptyList()
                                        : ordersService.getReceipts(fid, orderId);

        model.addAttribute("orderHeader", header);
        model.addAttribute("orderItems", items);
        model.addAttribute("orderReceipts", receipts);
        model.addAttribute("ctx", req.getContextPath());

        return "FarmerOrderDetail";
    }

    /* ===== เปลี่ยนสถานะ ===== */

    @PostMapping("/{orderId}/confirm")
    public String confirm(@PathVariable String orderId,
                          HttpSession session,
                          RedirectAttributes ra) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";
        ordersService.confirmOrder(cur.getMemberId(), orderId);
        ra.addFlashAttribute("msg", "ร้านยืนยันออเดอร์แล้ว");
        return "redirect:/farmer/orders/" + orderId;
    }

    /** ยืนยันรับเงิน + ตัดสต๊อกเป็นกิโล */
    @PostMapping("/{orderId}/verify-payment")
    public String verify(@PathVariable String orderId,
                         HttpSession session,
                         RedirectAttributes ra) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";

        try {
            orderService.farmerVerifyPayment(orderId, cur.getMemberId());
            ra.addFlashAttribute("msg", "ยืนยันชำระเงินสำเร็จ และตัดสต๊อกตามกิโลแล้ว");
        } catch (Exception e) {
            ra.addFlashAttribute("error", "ยืนยันชำระเงินไม่สำเร็จ: " + e.getMessage());
        }
        return "redirect:/farmer/orders/" + orderId;
    }

    @PostMapping("/{orderId}/prepare")
    public String prepare(@PathVariable String orderId,
                          HttpSession session,
                          RedirectAttributes ra) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";
        ordersService.startPrepare(cur.getMemberId(), orderId);
        ra.addFlashAttribute("msg", "เริ่มเตรียมจัดส่งแล้ว");
        return "redirect:/farmer/orders/" + orderId;
    }

    @PostMapping("/{orderId}/ship")
    public String ship(@PathVariable String orderId,
                       @RequestParam(value = "deliveryDate", required = false) String dd,
                       HttpSession session,
                       RedirectAttributes ra) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";
        ordersService.markShipped(cur.getMemberId(), orderId, dd);
        ra.addFlashAttribute("msg", "ทำเครื่องหมายจัดส่งแล้ว");
        return "redirect:/farmer/orders/" + orderId;
    }

    @PostMapping("/{orderId}/complete")
    public String complete(@PathVariable String orderId,
                           HttpSession session,
                           RedirectAttributes ra) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";
        ordersService.complete(cur.getMemberId(), orderId);
        ra.addFlashAttribute("msg", "ปิดงานออเดอร์แล้ว");
        return "redirect:/farmer/orders/" + orderId;
    }

    @PostMapping("/{orderId}/reject")
    public String reject(@PathVariable String orderId,
                         @RequestParam(value = "reason", required = false) String reason,
                         HttpSession session,
                         RedirectAttributes ra) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";
        ordersService.rejectOrder(cur.getMemberId(), orderId, reason);
        ra.addFlashAttribute("msg", "ปฏิเสธออเดอร์แล้ว");
        return "redirect:/farmer/orders/" + orderId;
    }

    /* ===== ลบคำสั่งซื้อฝั่งร้าน ===== */

    // HTML Form → redirect ไปหน้า list
    @PostMapping(
        value = "/{orderId}/delete",
        consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE
    )
    public String deleteOrderHtml(@PathVariable String orderId,
                                  HttpSession session,
                                  RedirectAttributes ra) {
        Member cur = requireFarmer(session);
        if (cur == null) return "redirect:/login";

        DeleteResult r = ordersService.deleteOrderByFarmer(cur.getMemberId(), orderId);
        if (r.ok) {
            ra.addFlashAttribute("msg", "ลบคำสั่งซื้อเรียบร้อย");
        } else {
            ra.addFlashAttribute("error",
                (r.reasonThai == null || r.reasonThai.isBlank()) ? "ลบไม่สำเร็จ" : r.reasonThai);
        }
        return "redirect:/farmer/orders";
    }

    // JSON (AJAX)
    @PostMapping(
        value = "/{orderId}/delete.json",
        produces = "application/json; charset=UTF-8"
    )
    @ResponseBody
    public Map<String, Object> deleteOrderJson(@PathVariable String orderId,
                                               HttpSession session) {
        Member cur = requireFarmer(session);
        if (cur == null) {
            return Map.of("ok", false, "reasonThai", "ยังไม่ได้เข้าสู่ระบบ");
        }
        DeleteResult r = ordersService.deleteOrderByFarmer(cur.getMemberId(), orderId);
        return r.ok ? Map.of("ok", true)
                    : Map.of("ok", false, "reasonThai",
                             r.reasonThai == null ? "ลบไม่สำเร็จ" : r.reasonThai);
    }
}
