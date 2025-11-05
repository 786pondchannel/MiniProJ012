package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.ReviewService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import jakarta.servlet.http.HttpSession;
import java.util.List;
import java.util.Map;

@Controller
public class ReviewController {

    // ใช้ service แบบ new ตรง ๆ (ถ้ามี DI อยู่แล้วจะเปลี่ยนเป็น @Autowired ก็ได้)
    private final ReviewService reviewService = new ReviewService();

    /** เปิดฟอร์มรีวิวจากออเดอร์ */
    // GET /reviews/new-by-order?orderId=xxxx
    @GetMapping("/reviews/new-by-order")
    public String newByOrder(@RequestParam("orderId") String orderId,
                             HttpSession session,
                             Model model,
                             RedirectAttributes ra) {

        Member user = (Member) session.getAttribute("loggedInUser");
        if (user == null) {
            ra.addFlashAttribute("error", "กรุณาเข้าสู่ระบบก่อน");
            return "redirect:/login";
        }

        String memberId = user.getMemberId();

        try {
            boolean allowed = reviewService.canBuyerReviewOrder(orderId, memberId);
            if (!allowed) {
                ra.addFlashAttribute("error", "รีวิวได้เฉพาะออเดอร์ขั้นที่ 3 หรือ 4 และต้องเป็นเจ้าของออเดอร์");
                return "redirect:/orders";
            }

            if (reviewService.hasReviewedThisOrder(orderId, memberId)) {
                ra.addFlashAttribute("error", "คุณได้รีวิวใบเสร็จนี้ไปแล้ว");
                return "redirect:/orders";
            }

            List<Map<String, Object>> items = reviewService.getOrderProducts(orderId);
            if (items == null || items.isEmpty()) {
                ra.addFlashAttribute("error", "ไม่พบสินค้าในออเดอร์นี้");
                return "redirect:/orders";
            }

            Map<String, Object> first = items.get(0);
            model.addAttribute("orderId", orderId);
            model.addAttribute("items", items);
            model.addAttribute("targetProductId",   first.get("productId"));
            model.addAttribute("targetProductName", first.get("productname"));
            model.addAttribute("targetImg",         first.get("img"));

            // ใช้ view-name ให้ตรง resolver:  /WEB-INF/jsp/reviewFormByOrder.jsp
            return "reviewFormByOrder";

        } catch (Exception e) {
            ra.addFlashAttribute("error", "เกิดข้อผิดพลาด: " + e.getMessage());
            return "redirect:/orders";
        }
    }

    /** บันทึกรีวิว */
    // POST /reviews/create-by-order
    @PostMapping("/reviews/create-by-order")
    public String createByOrder(@RequestParam("orderId") String orderId,
                                @RequestParam("rating") int rating,
                                @RequestParam(value = "comment", required = false) String comment,
                                HttpSession session,
                                RedirectAttributes ra) {

        Member user = (Member) session.getAttribute("loggedInUser");
        if (user == null) {
            ra.addFlashAttribute("error", "กรุณาเข้าสู่ระบบก่อน");
            return "redirect:/login";
        }

        String memberId = user.getMemberId();

        try {
            String rid = reviewService.createReviewForOrder(orderId, memberId, rating, comment);
            ra.addFlashAttribute("msg", "ขอบคุณสำหรับรีวิว (#" + rid + ")");
            return "redirect:/orders";
        } catch (IllegalStateException ise) {
            ra.addFlashAttribute("error", ise.getMessage());
            return "redirect:/reviews/new-by-order?orderId=" + orderId;
        } catch (Exception ex) {
            ra.addFlashAttribute("error", "ไม่สามารถบันทึกรีวิวได้: " + ex.getMessage());
            return "redirect:/reviews/new-by-order?orderId=" + orderId;
        }
    }

    /** API สรุปรีวิวสินค้า (option) */
    @GetMapping("/reviews/summary/product/{pid}")
    @ResponseBody
    public Map<String, Object> summary(@PathVariable("pid") String productId) {
        return reviewService.getProductReviewSummary(productId);
    }
}
