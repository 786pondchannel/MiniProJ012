package com.springmvc.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class PreorderRedirectController {

   
    @GetMapping("/preorder/list")
    public String redirectToCatalog() {
        return "redirect:/catalog/list";
    }
}
