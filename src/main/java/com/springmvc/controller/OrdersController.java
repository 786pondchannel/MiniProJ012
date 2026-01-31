package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.model.Farmer;
import com.springmvc.service.BuyerOrdersService;
import com.springmvc.service.BuyerOrdersService.OrderDetail;
import com.springmvc.service.BuyerOrdersService.OrderLine;
import com.springmvc.service.BuyerOrdersService.ReceiptInfo;
import com.springmvc.service.FarmerService;

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

    // ✅ เพิ่มอันนี้
    @Autowired
    private FarmerService farmerService;

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

        List<OrderLine> items      = ordersService.getLines(current.getMemberId(), orderId);
        List<ReceiptInfo> receipts = ordersService.getReceipts(current.getMemberId(), orderId);

        final String ost = od.getOrderStatus();
        final String pst = od.getPaymentStatus();

        boolean canUpload = "FARMER_CONFIRMED".equalsIgnoreCase(ost)
                && "AWAITING_BUYER_PAYMENT".equalsIgnoreCase(pst);

        boolean canCancel = "SENT_TO_FARMER".equalsIgnoreCase(ost)
                || ("FARMER_CONFIRMED".equalsIgnoreCase(ost)
                    && "AWAITING_BUYER_PAYMENT".equalsIgnoreCase(pst));

        boolean showPayArea = "FARMER_CONFIRMED".equalsIgnoreCase(ost);

        // =========================
        // ✅ เพิ่มส่วนนี้: ส่ง QR/สลิปของร้านให้ JSP
        // =========================
        String farmerId = null;
        try {
            farmerId = od.getFarmerId(); // ต้องมีใน OrderDetail (ใน JSP คุณใช้ order.farmerId อยู่แล้ว)
        } catch (Exception ignore) {}

        Farmer farmer = null;
        String paymentSlipUrl = null;
        if (farmerId != null && !farmerId.isBlank()) {
            farmer = farmerService.getFarmer(farmerId);
            paymentSlipUrl = farmerService.getPaymentSlipUrlFromFarmer(farmer);
        }

        // =========================

        model.addAttribute("order", od);
        model.addAttribute("items", items);
        model.addAttribute("receipts", receipts);
        model.addAttribute("hasQtyKg", ordersService.hasQuantityKgColumn());
        model.addAttribute("canUpload", canUpload);
        model.addAttribute("canCancel", canCancel);
        model.addAttribute("showPayArea", showPayArea);
        model.addAttribute("ctx", req.getContextPath());

        // ✅ สำคัญ: ให้ JSP ใช้ได้
        model.addAttribute("farmer", farmer);
        model.addAttribute("paymentSlipUrl", paymentSlipUrl);

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
        return "redirect:/checkout?productId=" + productId;
    }
}
