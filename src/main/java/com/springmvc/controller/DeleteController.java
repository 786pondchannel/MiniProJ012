package com.springmvc.controller;

import com.springmvc.service.DeleteProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.ui.Model;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.HashMap;
import java.util.Map;

@Controller
@RequestMapping("/product")
public class DeleteController {

    @Autowired
    private DeleteProductService deleteProductService;

    /** POST: ลบสินค้า (ห้ามลบถ้ามีออเดอร์ผูก) */
    @PostMapping("/delete/{id}")
    public String delete(@PathVariable("id") String productId,
                         RedirectAttributes ra) {
        DeleteProductService.DeleteResult r = deleteProductService.hardDeleteByProductId(productId);
        if (r.success()) {
            ra.addFlashAttribute("msg", "ลบสินค้าสำเร็จ");
        } else {
            ra.addFlashAttribute("error", r.message());
        }
        return "redirect:/product/list/Farmer";
    }

    /** GET: ใช้ให้หน้า JSP/AJAX เช็คว่าลบได้ไหมและมีออเดอร์ผูกอยู่กี่รายการ */
    @GetMapping("/delete/check")
    @ResponseBody
    public Map<String,Object> canDelete(@RequestParam("productId") String productId){
        long ref = deleteProductService.countPreorderRefs(productId);
        Map<String,Object> m = new HashMap<>();
        m.put("canDelete", ref == 0);
        m.put("refCount", ref);
        return m;
    }

    /* 
     * ถ้าคุณมีหน้าแก้ไขสินค้าที่ Controller อื่น เราสามารถแนบ flag ให้ JSP ได้
     * ตัวอย่าง (ถ้าใช้ controller นี้ render หน้าแก้ไขเอง):
     *
     * @GetMapping("/edit/{id}")
     * public String edit(@PathVariable String id, Model model){
     *     // ... ใส่ product/images ปกติ ...
     *     long ref = deleteProductService.countPreorderRefs(id);
     *     model.addAttribute("canDelete", ref == 0);
     *     model.addAttribute("refCount", ref);
     *     return "ProductEdit"; // ชื่อ JSP ของคุณ
     * }
     */
}
