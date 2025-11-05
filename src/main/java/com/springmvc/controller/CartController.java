// src/main/java/com/springmvc/controller/CartController.java
package com.springmvc.controller;

import com.springmvc.cart.VendorCart;
import com.springmvc.model.Cart;
import com.springmvc.model.Member;
import com.springmvc.model.Product;
import com.springmvc.model.CartItem;
import com.springmvc.service.CartService;
import com.springmvc.service.FarmerService;
import com.springmvc.service.OrderService;
import com.springmvc.service.ProductService;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;

@Controller
@RequestMapping("/cart")
public class CartController {

    @Autowired private CartService cartService;
    @Autowired private ProductService productService;
    @Autowired private FarmerService farmerService;
    @Autowired private OrderService orderService;

    /** ดูตะกร้า */
    @GetMapping
    public String viewCart(HttpSession session, Model model) {
        Cart cart = cartService.getOrCreateCart(session.getAttribute("CART"));
        session.setAttribute("CART", cart);
        model.addAttribute("cart", cart);
        return "Cart"; // /WEB-INF/jsp/Cart.jsp
    }

    /**
     * หยิบใส่ตะกร้า
     * รับทั้งจำนวนชิ้น (qty) และ "กิโลกรัม" (qtyKg) จากฟอร์ม
     * - ไม่ตัดสต๊อกที่นี่ (จะตัดตอนยืนยันชำระเงินใน OrderService)
     */
    @PostMapping("/add")
    public String addToCart(@RequestParam("productId") String productId,
                            @RequestParam(value = "qty", required = false, defaultValue = "1") int qty,
                            @RequestParam(value = "qtyKg", required = false) BigDecimal qtyKg,
                            HttpSession session,
                            RedirectAttributes ra) {

        if (qty < 1) qty = 1;
        if (qtyKg != null && qtyKg.signum() < 0) qtyKg = BigDecimal.ZERO;

        Product p = productService.getProduct(productId);
        if (p == null || Boolean.FALSE.equals(p.getAvailability())) {
            ra.addFlashAttribute("error", "ไม่พบสินค้าหรือสินค้ายังไม่พร้อมจำหน่าย");
            return "redirect:/product/list";
        }

        // เพิ่มเข้าตะกร้า
        String farmerName = farmerService.getFarmName(p.getFarmerId());
        if (farmerName == null || farmerName.isBlank()) {
            farmerName = "ร้าน " + p.getFarmerId();
        }

        Cart cart = cartService.getOrCreateCart(session.getAttribute("CART"));
        cartService.addItem(cart, p, qty, farmerName);

        // เซ็ต "กิโลกรัม" ลงไปใน CartItem ที่เพิ่งเพิ่ม
        trySetQtyKg(cart, p.getFarmerId(), productId, qtyKg);

        session.setAttribute("CART", cart);

        String msg = (qtyKg != null && qtyKg.signum() > 0)
                ? ("หยิบใส่ตะกร้าแล้ว (" + qtyKg.stripTrailingZeros().toPlainString() + " กก.)")
                : ("หยิบใส่ตะกร้าแล้ว (" + qty + " ชิ้น)");
        ra.addFlashAttribute("msg", msg);

        return "redirect:/cart";
    }

    /**
     * อัปเดตจำนวน (รองรับทั้งชิ้น และกิโล)
     * - ถ้ามีส่ง qtyKg มาด้วยจะอัปเดตลง CartItem เช่นกัน
     */
    @PostMapping("/update")
    public String updateQty(@RequestParam String farmerId,
                            @RequestParam String productId,
                            @RequestParam int qty,
                            @RequestParam(value = "qtyKg", required = false) BigDecimal qtyKg,
                            HttpSession session,
                            RedirectAttributes ra) {
        if (qty < 1) qty = 1;
        if (qtyKg != null && qtyKg.signum() < 0) qtyKg = BigDecimal.ZERO;

        Cart cart = cartService.getOrCreateCart(session.getAttribute("CART"));
        cartService.updateQty(cart, farmerId, productId, qty);

        // อัปเดตกิโลในรายการเดิม (ถ้าส่งมา)
        trySetQtyKg(cart, farmerId, productId, qtyKg);

        session.setAttribute("CART", cart);
        ra.addFlashAttribute("msg", "อัปเดตจำนวนแล้ว");
        return "redirect:/cart";
    }

    /** ลบสินค้า (ยังไม่คืนสต๊อกที่นี่ เพราะเราเลือกตัดสต๊อกตอนยืนยันชำระเงิน) */
    @PostMapping("/remove")
    public String remove(@RequestParam String farmerId,
                         @RequestParam String productId,
                         HttpSession session) {
        Cart cart = cartService.getOrCreateCart(session.getAttribute("CART"));
        cartService.removeItem(cart, farmerId, productId);
        session.setAttribute("CART", cart);
        return "redirect:/cart";
    }

    /** ล้างตะกร้าทั้งหมด */
    @PostMapping("/clear")
    public String clearAll(HttpSession session) {
        Cart cart = cartService.getOrCreateCart(session.getAttribute("CART"));
        cart.clearAll();
        session.setAttribute("CART", cart);
        return "redirect:/cart";
    }

    /**
     * ส่งคำสั่งพรีออเดอร์ "ทีละร้าน" (เฉพาะ MEMBER)
     * หมายเหตุ: ไม่ตัดสต๊อกที่นี่ — ระบบจะตัดตาม "กิโลจริง" ตอนยืนยันชำระเงินของร้าน
     */
    @PostMapping("/checkout")
    public String checkoutVendor(@RequestParam String farmerId,
                                 HttpSession session,
                                 Model model,
                                 RedirectAttributes ra) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null) return "redirect:/login";

        if (!"MEMBER".equalsIgnoreCase(current.getStatus())) {
            ra.addFlashAttribute("error", "ต้องใช้บัญชีผู้ซื้อ (MEMBER) ในการส่งคำสั่งพรีออเดอร์");
            return "redirect:/cart";
        }

        Cart cart = cartService.getOrCreateCart(session.getAttribute("CART"));
        VendorCart vc = cart.getByFarmer().get(farmerId);
        if (vc == null || vc.getItems().isEmpty()) {
            ra.addFlashAttribute("error", "ตะกร้าร้านนี้ว่าง");
            return "redirect:/cart";
        }

        try {
            String orderId = orderService.checkoutOneVendor(current.getMemberId(), vc);
            cart.clearVendor(farmerId);
            session.setAttribute("CART", cart);

            model.addAttribute("orderId", orderId);
            return "CheckoutSuccess";
        } catch (Exception e) {
            ra.addFlashAttribute("error", "ส่งคำสั่งพรีออเดอร์ไม่สำเร็จ: " + e.getMessage());
            return "redirect:/cart";
        }
    }

    /* ===================== Helpers ===================== */

    /**
     * ใส่/อัปเดตค่า "กิโลกรัม" ลง CartItem ในตะกร้าตาม farmerId + productId
     * ไม่แก้จำนวนชิ้น (qty) — UI จะใช้สองค่าคนละหน้าที่กัน
     */
    private void trySetQtyKg(Cart cart, String farmerId, String productId, BigDecimal qtyKg) {
        if (cart == null || farmerId == null || productId == null) return;

        VendorCart vc = cart.getByFarmer() == null ? null : cart.getByFarmer().get(farmerId);
        if (vc == null || vc.getItems() == null) return;

        for (CartItem it : vc.getItems()) {
            if (productId.equals(it.getProductId())) {
                // ถ้าไม่ส่งมาหรือส่งค่าติดลบ จะไม่เซ็ต (คงค่าเดิมไว้)
                if (qtyKg != null && qtyKg.signum() > 0) {
                    it.setQtyKg(qtyKg);
                }
                break;
            }
        }
    }
}
