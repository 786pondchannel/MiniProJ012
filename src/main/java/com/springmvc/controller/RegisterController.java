package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.MemberService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.LinkedHashMap;
import java.util.Map;

@Controller
public class RegisterController {

    @Autowired
    private MemberService memberService;

    @GetMapping("/register")
    public String showRegister(@RequestParam(value = "status", required = false) String status,
                               Model model) {
        model.addAttribute("mode", "FARMER".equalsIgnoreCase(status) ? "FARMER" : "MEMBER");
        return "Register"; // /WEB-INF/jsp/Register.jsp
    }

    @PostMapping("/registerUser")
    public String registerUser(@ModelAttribute Member form,
                               @RequestParam("confirmPassword") String confirmPassword,
                               RedirectAttributes ra) {
        form.setStatus("MEMBER");
        Map<String,String> fe = validate(form, confirmPassword);
        if (!fe.isEmpty()) {
            ra.addFlashAttribute("flash_fieldErrors", fe);
            ra.addFlashAttribute("flash_error", "กรุณาแก้ไขข้อมูลที่ไฮไลต์สีแดง");
            return "redirect:/register?status=MEMBER";
        }
        try {
            memberService.register(form);
            ra.addFlashAttribute("flash_success", "สมัครสมาชิกสำเร็จ");
        } catch (Exception ex) {
            ra.addFlashAttribute("flash_error", "สมัครไม่สำเร็จ: " + safe(ex.getMessage()));
        }
        return "redirect:/register?status=MEMBER";
    }

    @PostMapping("/registerFarmer")
    public String registerFarmer(@ModelAttribute Member form,
                                 @RequestParam("confirmPassword") String confirmPassword,
                                 RedirectAttributes ra) {
        form.setStatus("FARMER");
        Map<String,String> fe = validate(form, confirmPassword);
        if (!fe.isEmpty()) {
            ra.addFlashAttribute("flash_fieldErrors", fe);
            ra.addFlashAttribute("flash_error", "กรุณาแก้ไขข้อมูลที่ไฮไลต์สีแดง");
            return "redirect:/register?status=FARMER";
        }
        try {
            memberService.register(form);
            ra.addFlashAttribute("flash_success", "สมัครสมาชิก (เกษตรกร) สำเร็จ");
        } catch (Exception ex) {
            ra.addFlashAttribute("flash_error", "สมัครไม่สำเร็จ: " + safe(ex.getMessage()));
        }
        return "redirect:/register?status=FARMER";
    }

    /* ===== helpers ===== */
    private Map<String,String> validate(Member m, String confirm) {
        Map<String,String> fe = new LinkedHashMap<>();
        if (blank(m.getFullname()))                      fe.put("fullname","กรอกชื่อ-นามสกุล");
        if (blank(m.getEmail()) || !m.getEmail().contains("@"))
                                                         fe.put("email","อีเมลไม่ถูกต้อง");
        if (blank(m.getAddress()))                       fe.put("address","กรอกที่อยู่");
        if (blank(m.getPhoneNumber()) || !m.getPhoneNumber().trim().matches("^0\\d{9}$"))
                                                         fe.put("phoneNumber","ใส่เบอร์ให้ถูกต้อง 10 หลัก");
        if (blank(m.getPassword()) || m.getPassword().length() < 8)
                                                         fe.put("password","รหัสผ่านอย่างน้อย 8 ตัวอักษร");
        if (confirm == null || !confirm.equals(m.getPassword()))
                                                         fe.put("confirmPassword","ยืนยันรหัสผ่านไม่ตรงกัน");
        if ("FARMER".equalsIgnoreCase(m.getStatus())) {
            if (blank(m.getFarmName()))                  fe.put("farmName","กรอกชื่อฟาร์ม");
            if (blank(m.getFarmLocation()))              fe.put("farmLocation","กรอกที่ตั้งฟาร์ม");
        }
        return fe;
    }
    private boolean blank(String s){ return s==null || s.trim().isEmpty(); }
    private String safe(String s){ return s==null? "" : s; }
}
