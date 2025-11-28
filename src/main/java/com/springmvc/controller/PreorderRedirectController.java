package com.springmvc.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class PreorderRedirectController {

    /**
     * URL เก่า: /preorder/product/edit/{id}?updated=1
     * → บังคับไป URL ใหม่ที่ต้องการ (แนบ back คงที่ และ 'ตัด updated' ทิ้ง)
     */
    @GetMapping("/preorder/product/edit/{id}")
    public String redirectEdit(@PathVariable String id) {
        return "redirect:/preorder/edit-product/" + id + "?back=%2fproduct%2flist%2fFarmer";
    }

    /**
     * URL ใหม่ (alias): /preorder/edit-product/{id}
     * → forward ไปใช้ logic เดิมของ /edit-product/{id}
     * ถ้ายังไม่มีพารามิเตอร์ back ให้เติมค่าเริ่มต้นให้ก่อน
     */
    @GetMapping("/preorder/edit-product/{id}")
    public String aliasEdit(@PathVariable String id,
                            @RequestParam(value = "back", required = false) String back) {
        if (back == null || back.isBlank()) {
            return "redirect:/preorder/edit-product/" + id + "?back=%2fproduct%2flist%2fFarmer";
        }
        return "forward:/edit-product/" + id;
    }

    @GetMapping("/preorder/list")
    public String redirectToList() {
        return "redirect:/product/list";
    }

    @GetMapping("/preorder/product/create")
    public String redirectCreate() {
        return "redirect:/product/create";
    }

    @GetMapping("/preorder/product/list")
    public String redirectProductList() {
        return "redirect:/product/list";
    }
}
