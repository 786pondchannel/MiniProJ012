package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.model.Product;
import com.springmvc.service.EditProductService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/edit-product")
public class EditProductController {

    @Autowired private EditProductService editService;

    @GetMapping("/{id}")
    public String showEdit(@PathVariable("id") String id, HttpSession session, Model model) {
        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null || !"FARMER".equalsIgnoreCase(current.getStatus())) return "redirect:/login";
        var p = editService.getEditable(id, current.getMemberId());
        model.addAttribute("product", p);
        model.addAttribute("p", p);
        model.addAttribute("categories", editService.getAllCategories());
        model.addAttribute("images", editService.getImages(id));
        return "EditProduct";
    }

    @PostMapping("/update")
    public String update(@ModelAttribute Product product,
                         @RequestParam(value="imageFiles", required=false) MultipartFile[] newImages,
                         @RequestParam(value="deleteImageIds", required=false) String[] deleteImageIds,
                         @RequestParam(value="back", required=false) String back,
                         HttpServletRequest req, HttpSession session, RedirectAttributes ra) {

        Member current = (Member) session.getAttribute("loggedInUser");
        if (current == null || !"FARMER".equalsIgnoreCase(current.getStatus())) return "redirect:/login";
        try {
            editService.update(product, newImages, current.getMemberId(), deleteImageIds);
            ra.addFlashAttribute("msg", "อัปเดตสินค้าเรียบร้อย");

            if (back != null && !back.isBlank() && !back.contains("://")) {
                String b = back.trim();
                String cp = req.getContextPath();
                if (cp.length() > 1 && b.startsWith(cp + "/")) b = b.substring(cp.length());
                if (!b.startsWith("/")) b = "/" + b;
                return "redirect:" + b;
            }
            return "redirect:/product/list/Farmer";

        } catch (Exception e) {
            ra.addFlashAttribute("error", "บันทึกไม่สำเร็จ: " + e.getMessage());
            String b = (back == null ? "" : back.trim());
            String cp = req.getContextPath();
            if (cp.length() > 1 && b.startsWith(cp + "/")) b = b.substring(cp.length());
            if (!b.isEmpty() && !b.startsWith("/")) b = "/" + b;
            String pid = (product != null && product.getProductId() != null) ? product.getProductId() : "";
            return "redirect:/edit-product/" + pid + (b.isEmpty() ? "" : "?back=" + b);
        }
    }
}
