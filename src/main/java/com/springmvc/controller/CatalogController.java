package com.springmvc.controller;

import com.springmvc.model.Product;
import com.springmvc.service.CategoryService;
import com.springmvc.service.ProductService;
import com.springmvc.service.CreateProductService;
import com.springmvc.service.CatalogQueryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@Controller
@RequestMapping("/catalog")
public class CatalogController {

    @Autowired private ProductService productService;              // ดึงรายละเอียดสินค้าเดี่ยว
    @Autowired private CategoryService categoryService;            // โหลดหมวดหมู่ไปยังตัวกรอง
    @Autowired private CreateProductService createProductService;  // โหลดรูปทั้งหมดของสินค้า
    @Autowired private CatalogQueryService catalogQueryService;    // ดึงรายการสินค้าสาธารณะทั้งหมด

    /** หน้ารวมสินค้า (สาธารณะ) -> JSP: ListProduct.jsp */
    @GetMapping("/list")
    public String list(
            @RequestParam(value = "kw", required = false) String kw,
            @RequestParam(value = "categoryId", required = false) String categoryId,
            @RequestParam(value = "min", required = false) BigDecimal minPrice,
            @RequestParam(value = "max", required = false) BigDecimal maxPrice,
            @RequestParam(value = "sort", required = false, defaultValue = "latest") String sort,
            @RequestParam(value = "page", required = false, defaultValue = "1") int page,
            @RequestParam(value = "size", required = false, defaultValue = "24") int size,
            Model model
    ) {
        model.addAttribute("categories", categoryService.getAllCategories());

        // ให้ service ใช้ได้ทั้งแบบ _ และ -
        String normalizedSort = (sort == null) ? "latest" : sort.replace('_','-');

        List<Product> products = catalogQueryService.searchPublicProducts(
                kw, categoryId, minPrice, maxPrice, normalizedSort, page, size
        );

        model.addAttribute("products", products);
        model.addAttribute("kw", kw);
        model.addAttribute("categoryId", categoryId);
        model.addAttribute("min", minPrice);
        model.addAttribute("max", maxPrice);
        model.addAttribute("sort", sort);   // เก็บรูปแบบเดิมไว้ให้ select
        model.addAttribute("page", page);
        model.addAttribute("size", size);

        return "ListProduct";
    }

    /** หน้าดูรายละเอียดสินค้า (สาธารณะ) -> JSP: ViewProduct.jsp */
    @GetMapping("/view/{id}")
    public String view(@PathVariable("id") String id, Model model) {
        Product p = productService.getProduct(id);
        if (p == null) {
            model.addAttribute("error", "ไม่พบสินค้า");
            return "ViewProduct";
        }

        model.addAttribute("product", p);

        // ===== FIX จุดที่พังเพราะ isBlank() กับ Integer =====
         String pid = firstNonEmpty(
                toNonEmptyString(p.getProductId()),
                toNonEmptyString(getPossiblyIntegerId(p)), // แปลงเป็น String ถ้าเป็น Integer
                toNonEmptyString(id)
        );

        model.addAttribute("images", createProductService.getImages(pid));
        return "ViewProduct";
    }

    /* ===================== helpers (ไม่ผูกกับ Java 11) ===================== */

    /** แปลง Object เป็น String แบบ trim และคืน null ถ้าว่าง */
    private static String toNonEmptyString(Object o) {
        if (o == null) return null;
        String s = String.valueOf(o).trim();
        return s.isEmpty() ? null : s;
    }

    /** รองรับกรณี entity มีทั้ง getProductId() (String) และ getId() (อาจเป็น Integer/String) */
    private static Object getPossiblyIntegerId(Product p) {
        try {
            // ถ้ามีเมธอด getId() ให้ใช้ (อาจเป็น Integer หรือ String แล้วแต่ model)
            return p.getClass().getMethod("getId").invoke(p);
        } catch (Exception ignore) {
            return null;
        }
    }

    /** คืนค่าตัวแรกที่ไม่ null และไม่ว่าง */
    private static String firstNonEmpty(String... vals) {
        if (vals == null) return null;
        for (String v : vals) if (v != null && !v.trim().isEmpty()) return v.trim();
        return null;
    }
}
