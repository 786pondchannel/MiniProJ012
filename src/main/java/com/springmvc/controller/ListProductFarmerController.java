package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.model.Product;
import com.springmvc.service.ProductService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;

@Controller
@RequestMapping("/product")
public class ListProductFarmerController {

    @Autowired private ProductService productService;

    /** แสดง “สินค้าของฉัน” */
    @GetMapping("/list/Farmer")
    public String myList(HttpSession session, Model model) {
        Member me = (Member) session.getAttribute("loggedInUser");
        if (me == null || !"FARMER".equalsIgnoreCase(me.getStatus())) {
            return "redirect:/login";
        }
        List<Product> list = productService.getProductsByFarmer(me.getMemberId());
        model.addAttribute("products", list);         // ✅ ชื่อ key = products
        model.addAttribute("productList", list);      // ✅ เผื่อ JSP เก่าเรียก productList
        System.out.println("[MyProducts] farmer=" + me.getMemberId() + " size=" + (list==null?0:list.size()));
        return "productFarmer";                       // ✅ ชี้ไป JSP: /WEB-INF/jsp/productFarmer.jsp
    }
}
