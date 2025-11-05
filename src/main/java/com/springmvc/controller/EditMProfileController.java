package com.springmvc.controller;

import com.springmvc.model.Member;
import com.springmvc.service.EditMyProfileService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/profile")
public class EditMProfileController {

    @Autowired
    private EditMyProfileService editService;

    /** แสดงฟอร์มแก้ไขโปรไฟล์ของผู้ใช้ที่ล็อกอิน */
    @GetMapping("/edit")
    public String showEditForm(HttpSession session, Model model) {
        Member user = (Member) session.getAttribute("loggedInUser");
        if (user == null) return "redirect:/login";

        Member fresh = editService.getCurrentProfile(user.getMemberId());
        model.addAttribute("member", fresh != null ? fresh : user);
        return "EditMProfile"; // /WEB-INF/jsp/EditMyProfile.jsp
    }

    /** รับบันทึกโปรไฟล์ + อัปโหลดรูป */
    @PostMapping("/edit")
    public String updateProfile(@ModelAttribute Member member,
                                @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                                HttpSession session,
                                RedirectAttributes ra) {
        Member user = (Member) session.getAttribute("loggedInUser");
        if (user == null) return "redirect:/login";

        // บังคับแก้ได้เฉพาะของตัวเอง
        member.setMemberId(user.getMemberId());

        try {
            editService.updateProfile(member, imageFile);

            // refresh session เพื่อให้ header เห็นรูปใหม่ทันที
            Member updated = editService.getCurrentProfile(user.getMemberId());
            session.setAttribute("loggedInUser", updated);

            ra.addFlashAttribute("msg", "บันทึกโปรไฟล์เรียบร้อย");
        } catch (RuntimeException ex) {
            ra.addFlashAttribute("error", "บันทึกไม่สำเร็จ: " + ex.getMessage());
        }
        return "redirect:/profile/edit";
    }
    @Value("${google.maps.apiKey}") String gmapsKey;
    @GetMapping("/profile/edit")
    public String edit(Model model) {
      model.addAttribute("googleMapsApiKey", gmapsKey);
      return "ProfileEdit";
    }
}
