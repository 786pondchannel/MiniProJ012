package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.model.Farmer;
import com.springmvc.model.Product;
import com.springmvc.model.Review;
import com.springmvc.service.FarmerService;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

/**
 * หน้าโปรไฟล์ร้าน (public view) + เพิ่มรีวิวอย่างง่าย
 * ไม่มีส่วนใดพาไป /preorder/product/edit/... เช่นกัน
 */
@Controller
@RequestMapping("/farmer")
public class FarmerController {

    @Autowired
    private FarmerService farmerService;

    /** หน้าโปรไฟล์ร้าน (public view) */
    @GetMapping("/profile")
    public String profile(@RequestParam(value = "farmerId", required = false) String farmerId,
                          HttpSession session, Model model) {

        // 1) จากพารามิเตอร์, 2) จาก session.farmerId, 3) จาก loggedInUser (ถ้าเป็น FARMER)
        if (!StringUtils.hasText(farmerId)) {
            Object sFarmerId = session.getAttribute("farmerId");
            if (sFarmerId instanceof String s && StringUtils.hasText(s)) {
                farmerId = s;
            }
        }
        if (!StringUtils.hasText(farmerId)) {
            Member logged = (Member) session.getAttribute("loggedInUser");
            if (logged != null && "FARMER".equalsIgnoreCase(logged.getStatus())) {
                farmerId = farmerService.resolveFarmerIdFromMember(logged);
            }
        }

        if (!StringUtils.hasText(farmerId)) {
            model.addAttribute("error", "✖ ไม่พบรหัสฟาร์ม (เติม ?farmerId=... หรือเข้าสู่ระบบเป็นเกษตรกร)");
            session.setAttribute("cartCount", farmerService.computeCartCount(session.getAttribute("CART")));
            return "FarmerProfile";
        }

        Farmer farmer = farmerService.getFarmer(farmerId);
        if (farmer == null) {
            model.addAttribute("error", "✖ ไม่พบข้อมูลฟาร์มรหัส: " + farmerId);
            session.setAttribute("cartCount", farmerService.computeCartCount(session.getAttribute("CART")));
            return "FarmerProfile";
        }

        session.setAttribute("farmerId", farmerId);

        List<String> gallery = farmerService.getFarmerGallery(farmerId);
        List<Product> products = farmerService.getProductsOfFarmer(farmerId);
        List<Review> reviews = farmerService.getReviews(farmerId);
        Double avgRating = farmerService.getAvgRating(farmerId);
        Integer reviewCount = farmerService.getReviewCount(farmerId);
        String paymentSlipUrl = farmerService.getPaymentSlipUrlFromFarmer(farmer);

        model.addAttribute("farmer", farmer);
        model.addAttribute("gallery", gallery);
        model.addAttribute("products", products);
        model.addAttribute("reviews", reviews);
        model.addAttribute("avgRating", avgRating == null ? 0d : avgRating);
        model.addAttribute("reviewCount", reviewCount == null ? 0 : reviewCount);
        model.addAttribute("paymentSlipUrl", paymentSlipUrl);

        session.setAttribute("cartCount", farmerService.computeCartCount(session.getAttribute("CART")));

        return "FarmerProfile";
    }

    /** POST เพิ่มรีวิวจริง (อย่างง่าย) */
    @PostMapping("/review/add")
    public String addReview(@RequestParam String farmerId,
                            @RequestParam(required=false) String productId,
                            @RequestParam int rating,
                            @RequestParam(required=false) String comment,
                            @RequestParam(required=false) String orderId,
                            HttpSession session, RedirectAttributes ra) {
        try {
            Member user = (Member) session.getAttribute("loggedInUser");
            String memberId = (user != null ? user.getMemberId() : "demo");
            String rid = farmerService.addReviewSimple(farmerId, memberId, orderId, productId, rating, comment);
            ra.addFlashAttribute("msg", "เพิ่มรีวิวเรียบร้อย #" + rid);
        } catch (Exception e) {
            ra.addFlashAttribute("error", "เพิ่มรีวิวไม่สำเร็จ: " + e.getMessage());
        }
        return "redirect:/farmer/profile?farmerId=" + farmerId;
    }

    /** GET สร้างรีวิวตัวอย่างเร็วๆ เพื่อทดสอบ */
    @GetMapping("/review/quickAdd")
    public String quickAdd(@RequestParam String farmerId,
                           HttpSession session, RedirectAttributes ra) {
        try {
            Member user = (Member) session.getAttribute("loggedInUser");
            String memberId = (user != null ? user.getMemberId() : "demo");
            String rid = farmerService.addReviewSimple(
                    farmerId, memberId, null, null, 5,
                    "สินค้าคุณภาพดี ส่งไว ประทับใจมาก 😊"
            );
            ra.addFlashAttribute("msg", "เพิ่มรีวิวตัวอย่างแล้ว #" + rid);
        } catch (Exception e) {
            ra.addFlashAttribute("error", "เพิ่มรีวิวตัวอย่างไม่สำเร็จ: " + e.getMessage());
        }
        return "redirect:/farmer/profile?farmerId=" + farmerId;
    }
}
