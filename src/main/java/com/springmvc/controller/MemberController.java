package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.MemberService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/member")   // ✅ แยก namespace ของ MemberController
public class MemberController {

    @Autowired
    private MemberService memberService;

    /** 1) แสดงฟอร์มสมัครสมาชิก GET /member/register */
    @GetMapping("/register")
    public String showRegistrationForm(Model model) {
        model.addAttribute("member", new Member());
        return "Register";  // /WEB-INF/jsp/Register.jsp
    }

    /** 2) หน้า main ของสมาชิก GET /member/main */
    @GetMapping("/main")
    public String showMainPage(Model m) {
        // โหลดสินค้า/ข้อมูลเฉพาะสมาชิก
        return "memberMain"; // ✅ ใช้ view แยกต่างหาก เช่น memberMain.jsp
    }

    /** 3) สมัครสมาชิกทั่วไป POST /member/registerUser */
    @PostMapping("/registerUser")
    public String registerUser(@ModelAttribute Member member) {
        member.setStatus("MEMBER");
        memberService.register(member);
        return "redirect:/login";
    }

    /** 4) สมัครสมาชิกเกษตรกร POST /member/registerFarmer */
    @PostMapping("/registerFarmer")
    public String registerFarmer(
            @ModelAttribute Member member,
            @RequestParam String farmName,
            @RequestParam String farmLocation) {

        member.setStatus("FARMER");
        member.setFarmName(farmName);
        member.setFarmLocation(farmLocation);
        memberService.register(member);
        return "redirect:/login";
    }

    /** 5) รายการสมาชิกทั้งหมด (admin) GET /member/list */
    @GetMapping("/list")
    public String listMembers(Model model) {
        model.addAttribute("members", memberService.getAll());
        return "List";  // /WEB-INF/jsp/List.jsp
    }

    /** 6) ดูรายละเอียดสมาชิก (admin) GET /member/{id} */
    @GetMapping("/{id}")
    public String viewMember(
            @PathVariable String id,
            Model model) {

        Member m = memberService.getById(id);
        if (m == null) {
            return "redirect:/member/list";
        }
        model.addAttribute("member", m);
        return "View";  // /WEB-INF/jsp/View.jsp
    }

    /** 7) แสดงฟอร์มแก้ไข (admin) GET /member/{id}/edit */
    @GetMapping("/{id}/edit")
    public String showEditForm(
            @PathVariable String id,
            Model model) {

        Member m = memberService.getById(id);
        if (m == null) {
            return "redirect:/member/list";
        }
        model.addAttribute("member", m);
        return "Edit";  // /WEB-INF/jsp/Edit.jsp
    }

    /** 8) ประมวลผลแก้ไขสมาชิก (admin) POST /member/edit */
    @PostMapping("/edit")
    public String updateMember(@ModelAttribute Member member) {
        memberService.update(member);
        return "redirect:/member/" + member.getMemberId();
    }

    /** 9) ลบสมาชิก (admin) GET /member/{id}/delete */
    @GetMapping("/{id}/delete")
    public String deleteMember(@PathVariable String id) {
        memberService.delete(id);
        return "redirect:/member/list";
    }

    // --- จบส่วน admin/registration/member flow ---
}
