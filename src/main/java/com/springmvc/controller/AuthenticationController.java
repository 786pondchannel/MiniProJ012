package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.MemberService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class AuthenticationController {

    @Autowired
    private MemberService memberService; // <-- ของเดิมคุณเป็น @Service class JDBC

    // GET: หน้า Login
    @GetMapping("/login")
    public String showLoginForm(@RequestParam(value = "error", required = false) String error,
                                Model model) {
        if (error != null) {
            model.addAttribute("error", "อีเมลหรือรหัสผ่านไม่ถูกต้อง");
        }
        return "login"; // /WEB-INF/jsp/login.jsp
    }

    // POST: ประมวลผล Login
    @PostMapping("/login")
    public String doLogin(@RequestParam String email,
                          @RequestParam String password,
                          HttpSession session) {

        // NOTE: ถ้ารหัสใน DB สั้น < 6 จะโดน JS หน้า login บล็อก เดี๋ยวเราแก้ใน login.jsp ให้ส่งได้เสมอ
        Member m = memberService.authenticateByEmail(email, password);
        if (m != null) {
            session.setAttribute("loggedInUser", m);
            return "redirect:/main";
        }
        return "redirect:/login?error";
    }

    // GET: Logout
    @GetMapping("/logout")
    public String doLogout(HttpSession session) {
        session.invalidate();
        return "redirect:/login";
    }
}
