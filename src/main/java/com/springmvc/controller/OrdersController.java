 package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.BuyerOrdersService;
import com.springmvc.service.BuyerOrdersService.OrderDetail;
import com.springmvc.service.BuyerOrdersService.OrderLine;
import com.springmvc.service.BuyerOrdersService.ReceiptInfo;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Controller
@RequestMapping("/orders")
public class OrdersController {

    @Autowired
    private BuyerOrdersService ordersService;

    /** หน้า “รายละเอียดคำสั่งซื้อของฉัน” */
    @GetMapping("/{orderId}")
    public String viewDetail(@PathVariable String orderId,
                             HttpSession session,
                             HttpServletRequest req,
                             Model model) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null) return "redirect:/login";

        // อนุญาตเฉพาะผู้ซื้อ
        if (!"MEMBER".equalsIgnoreCase(current.getStatus())) {
            model.addAttribute("error", "เฉพาะผู้ซื้อเท่านั้นที่ดูรายละเอียดคำสั่งซื้อนี้ได้");
            return "redirect:/orders";
        }

        OrderDetail od = ordersService.getDetail(current.getMemberId(), orderId);
        if (od == null) {
            model.addAttribute("error", "ไม่พบคำสั่งซื้อหรือไม่มีสิทธิ์เข้าถึง");
            return "redirect:/orders";
        }

        List<OrderLine> items     = ordersService.getLines(current.getMemberId(), orderId);
        List<ReceiptInfo> receipts = ordersService.getReceipts(current.getMemberId(), orderId);

        // ใช้ค่าแบบ getter ทั้งหมด
        final String ost = od.getOrderStatus();
        final String pst = od.getPaymentStatus();

        boolean canUpload = "FARMER_CONFIRMED".equalsIgnoreCase(ost)
                && "AWAITING_BUYER_PAYMENT".equalsIgnoreCase(pst);

        boolean canCancel = "SENT_TO_FARMER".equalsIgnoreCase(ost)
                || ("FARMER_CONFIRMED".equalsIgnoreCase(ost)
                    && "AWAITING_BUYER_PAYMENT".equalsIgnoreCase(pst));

        boolean showPayArea = "FARMER_CONFIRMED".equalsIgnoreCase(ost);

        model.addAttribute("order", od);
        model.addAttribute("items", items);
        model.addAttribute("receipts", receipts);
        model.addAttribute("hasQtyKg", ordersService.hasQuantityKgColumn());
        model.addAttribute("canUpload", canUpload);
        model.addAttribute("canCancel", canCancel);
        model.addAttribute("showPayArea", showPayArea);
        model.addAttribute("ctx", req.getContextPath());

        // ให้ตรงกับ ViewResolver ของคุณ เช่น /WEB-INF/jsp/OrderDetail.jsp
        return "OrderDetail";
    }
    @GetMapping("/order/{productId}")
    public String startOrder(@PathVariable("productId") Long productId,
                             HttpSession session,
                             HttpServletRequest req,
                             RedirectAttributes ra) {
        Object user = (session != null) ? session.getAttribute("loggedInUser") : null;
        if (user == null) {
            String next = req.getRequestURI() + (req.getQueryString() != null ? "?" + req.getQueryString() : "");
            ra.addFlashAttribute("error", "กรุณาเข้าสู่ระบบก่อนทำรายการสั่งซื้อ");
            return "redirect:/login?next=" + URLEncoder.encode(next, StandardCharsets.UTF_8);
        }

        // … โหลดสินค้า/ตรวจสต็อก/ไปหน้ากรอกที่อยู่จัดส่งต่อไป
        return "redirect:/checkout?productId=" + productId;
    }
}
