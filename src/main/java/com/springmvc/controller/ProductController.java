package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.model.Product;
import com.springmvc.service.CategoryService;
import com.springmvc.service.CreateProductService;
import com.springmvc.service.ProductService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Controller
@RequestMapping("/product")
public class ProductController {

    @Autowired private ProductService productService;
    @Autowired private CategoryService categoryService;
    @Autowired private CreateProductService createProductService;

    @GetMapping("/create")
    public String showCreate(HttpSession session, Model model) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null || !"FARMER".equalsIgnoreCase(current.getStatus())) return "redirect:/login";
        model.addAttribute("product", new Product());
        model.addAttribute("categories", categoryService.getAllCategories());
        // หน้าเดียวกับแก้ไข: "Createproduct.jsp"
        return "Createproduct";
    }

    @GetMapping("/edit/{id}")
    public String showEdit(@PathVariable("id") String id,
                           HttpSession session, Model model, RedirectAttributes ra) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null || !"FARMER".equalsIgnoreCase(current.getStatus())) return "redirect:/login";

        Product p = productService.getProduct(id);
        if (p == null) {
            ra.addFlashAttribute("error","ไม่พบสินค้า");
            return "redirect:/product/list/Farmer";
        }
        if (!Objects.equals(current.getMemberId(), p.getFarmerId())) {
            ra.addFlashAttribute("error","คุณไม่มีสิทธิ์แก้ไขสินค้านี้");
            return "redirect:/product/list/Farmer";
        }

        // ----- เตรียมข้อมูลหน้าแก้ไข -----
        model.addAttribute("product", p);
        model.addAttribute("categories", categoryService.getAllCategories());
        model.addAttribute("images", createProductService.getImages(id));

        // จำนวนการอ้างอิงสำหรับซ่อนปุ่มลบ + แสดงเหตุผล
        Map<String, Long> ref = createProductService.countReferencesForUi(id);
        model.addAttribute("orderRefCounts", ref);

        return "Createproduct";
    }

    @PostMapping("/create")
    public String create(@ModelAttribute Product product,
                         @RequestParam(value="availability", required=false) String availabilityStr,
                         @RequestParam(value="status", required=false) String statusStr,
                         @RequestParam(value="imageFiles", required=false) MultipartFile[] imageFiles,
                         HttpSession session, RedirectAttributes ra) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null || !"FARMER".equalsIgnoreCase(current.getStatus())) return "redirect:/login";

        try {
            product.setProductname(trimMax(product.getProductname(), 100));
            product.setDescription(trimMax(product.getDescription(), 1000));
            product.setPrice(sanitizePrice(product.getPrice()));
            product.setStock(Math.max(0, product.getStock()));
            if (availabilityStr != null) product.setAvailability("true".equalsIgnoreCase(availabilityStr));
            if (statusStr != null) product.setStatus(statusStr);

            List<MultipartFile> files = (imageFiles != null) ? Arrays.asList(imageFiles) : Collections.emptyList();
            createProductService.saveNew(product, files, current.getMemberId());

            ra.addFlashAttribute("msg", "สร้างสินค้าเรียบร้อย");
            return "redirect:/product/list/Farmer";
        } catch (Exception e) {
            ra.addFlashAttribute("error", "บันทึกสินค้าไม่สำเร็จ: " + e.getMessage());
            return "redirect:/product/create";
        }
    }

    @PostMapping("/update")
    public String update(@ModelAttribute Product product,
                         @RequestParam(value="availability", required=false) String availabilityStr,
                         @RequestParam(value="status", required=false) String statusStr,
                         @RequestParam(value="imageFiles", required=false) MultipartFile[] newImages,
                         @RequestParam(value="deleteImageIds", required=false) String[] deleteImageIds,
                         HttpSession session, RedirectAttributes ra) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null || !"FARMER".equalsIgnoreCase(current.getStatus())) return "redirect:/login";

        try {
            product.setProductname(trimMax(product.getProductname(), 100));
            product.setDescription(trimMax(product.getDescription(), 1000));
            product.setPrice(sanitizePrice(product.getPrice()));
            product.setFarmerId(current.getMemberId());
            product.setStock(Math.max(0, product.getStock()));
            if (availabilityStr != null) product.setAvailability("true".equalsIgnoreCase(availabilityStr));
            if (statusStr != null) product.setStatus(statusStr);

            List<MultipartFile> files = (newImages != null) ? Arrays.asList(newImages) : Collections.emptyList();
            createProductService.update(product, files, current.getMemberId(), deleteImageIds);

            ra.addFlashAttribute("msg", "อัปเดตสินค้าเรียบร้อย");
            // ส่งกลับหน้า edit เพื่อโชว์ modal + redirect หรือกลับ list ก็ได้
            return "redirect:/product/edit/" + product.getProductId() + "?updated=1";
        } catch (Exception e) {
            ra.addFlashAttribute("error", "อัปเดตไม่สำเร็จ: " + e.getMessage());
            return "redirect:/product/edit/" + (product.getProductId() == null ? "" : product.getProductId());
        }
    }

    @PostMapping("/delete")
    public String delete(@RequestParam("productId") String productId,
                         HttpSession session, RedirectAttributes ra) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null || !"FARMER".equalsIgnoreCase(current.getStatus())) return "redirect:/login";

        try {
            // เช็กก่อนลบ
            Map<String, Long> ref = createProductService.countReferencesForUi(productId);
            long per = ref.getOrDefault("perorder", 0L);
            long pre = ref.getOrDefault("preorderdetail", 0L);
            if (per + pre > 0) {
                ra.addFlashAttribute("error", "ลบสินค้าไม่ได้: มีคำสั่งซื้อ/พรีออเดอร์อ้างอิงอยู่ (perorder: " + per + ", preorderdetail: " + pre + ")");
                return "redirect:/product/edit/" + productId;
            }

            // ไม่มีอ้างอิง -> ลบจริง
            createProductService.deleteProduct(productId, current.getMemberId());
            ra.addFlashAttribute("msg", "ลบสินค้าเรียบร้อย");
            return "redirect:/product/list/Farmer";

        } catch (Exception e) {
            ra.addFlashAttribute("error", "ลบไม่สำเร็จ: " + e.getMessage());
            return "redirect:/product/edit/" + productId;
        }
    }

    /** เหลือแค่ /product/list อย่างเดียว — แล้วพาไปที่ /product/list/Farmer ของคอนโทรลเลอร์เดิม */
    @GetMapping("/list")
    public String listAlias() {
        return "redirect:/product/list/Farmer";
    }

    // ---------- helpers ----------
    private BigDecimal sanitizePrice(BigDecimal p) {
        if (p == null) return new BigDecimal("0.00");
        if (p.compareTo(BigDecimal.ZERO) < 0) p = BigDecimal.ZERO;
        if (p.compareTo(new BigDecimal("9999999")) > 0) p = new BigDecimal("9999999");
        return p.setScale(2, RoundingMode.HALF_UP);
    }
    private String trimMax(String s, int max) {
        if (s == null) return null;
        String t = s.trim();
        return t.length() <= max ? t : t.substring(0, max);
    }
}
